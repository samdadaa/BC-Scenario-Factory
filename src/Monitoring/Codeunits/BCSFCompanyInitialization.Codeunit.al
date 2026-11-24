namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Assembly;
using BCScenarioFactory.Planning;
using BCScenarioFactory.CRM;
using BCScenarioFactory.Warehouse;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Threading;

codeunit 90361 "BCSF Company Initialization"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Setup: Record "BCSF Factory Setup";
        Scenario: Record "BCSF Scenario";
        StoredJob: Record "Job Queue Entry";
        TempModules: Record "BCSF Scenario Module" temporary;
        Profile: Codeunit "BCSF Wholesale Profile";
        Guard: Codeunit "BCSF Environment Guard";
    begin
        // Standard scheduler owns this job. Validate persisted state, not just the supplied record.
        StoredJob.SecurityFiltering(SecurityFilter::Disallowed);
        StoredJob.Get(Rec.ID);
        StoredJob.TestField(Status, StoredJob.Status::"In Process");
        StoredJob.TestField("Object Type to Run", StoredJob."Object Type to Run"::Codeunit);
        StoredJob.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
        StoredJob.TestField("User Session ID", SessionId());
        StoredJob.TestField("User Service Instance ID", ServiceInstanceId());
        StoredJob.TestField("Maximum No. of Attempts to Run", 0);
        StoredJob.TestField("Recurring Job", false);
        if StoredJob."Record ID to Process" <> Rec."Record ID to Process" then
            Error(JobErr);
        Rec.TestField("Object Type to Run", Rec."Object Type to Run"::Codeunit);
        Rec.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
        Rec.TestField("System Task ID");
        Rec.TestField(Status, Rec.Status::"In Process");
        Rec.TestField("User Session ID", SessionId());
        Rec.TestField("User Service Instance ID", ServiceInstanceId());
        if GuiAllowed() then
            Error(JobErr);
        Scenario.LockTable();
        Setup.LockTable();
        Setup.Get(Setup.GetSetupKey());
        Guard.EnsureCanConfigure(CompanyName());
        Setup.TestField("Industry Job Id", Rec.ID);
        if Rec."Record ID to Process" <> Setup.RecordId() then
            Error(JobErr);
        if not IsNullGuid(Setup."Industry Run Id") then
            exit;
        Profile.CheckSelection(Setup."Industry Size", Setup."Industry Process Mode");
        Profile.LoadModules(Setup."Industry Additional Modules", TempModules);
        CheckGenerationRequest(Setup."Industry Generation Kind", Setup."Industry Master Source Id", Setup."Industry Process Mode",
          Setup."Industry Purchase Selected", Setup."Industry Sales Selected", Setup."Industry Purchase Quantity",
          Setup."Industry Sales Order Quantity", Setup."Industry Sales Quote Quantity", Setup."Industry Sales Inv Quantity", Setup);
        if Setup."Industry Ending Date" <> 0D then
            Profile.CheckDateRange(Setup."Industry Date", Setup."Industry Ending Date", Today() - 1);
        // Setup, snapshot and first batch job form one atomic transaction. Failure leaves no half company.
        InitializeAndSchedule(Setup);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure InitializeAndSchedule(var Setup: Record "BCSF Factory Setup")
    var
        Scenario: Record "BCSF Scenario";
        Catalog: Codeunit "BCSF Starter Catalog";
        Packages: Codeunit "BCSF Finance Package Mgt";
        Profile: Codeunit "BCSF Wholesale Profile";
        QuickRun: Codeunit "BCSF Quick Scenario Run";
        Payments: Codeunit "BCSF Payment Processor";
        Movements: Codeunit "BCSFInventoryMovementProcessor";
        AssemblyProcessor: Codeunit "BCSF Assembly Processor";
        PlanningProcessor: Codeunit "BCSF Planning Processor";
        CrmProcessor: Codeunit "BCSF CRM Processor";
        WarehouseProcessor: Codeunit "BCSF Warehouse Processor";
        Selection: Codeunit "BCSF Module Selection";
        ScenarioId: Guid;
        EndingDate: Date;
    begin
        if Setup."Company Initialized" then begin
            Setup.TestField("Generation Enabled", true);
            if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then
                Packages.InitializeCompany("BCSF Finance Mode"::Existing);
            if Setup."Industry Finance Mode" <> Packages.GetAppliedMode() then
                Error(ChartErr);
        end else
            Catalog.InitializeFoundation(Setup."Industry Finance Mode");
        if Setup."Industry Process Mode".AsInteger() >= 2 then begin
            Setup.TestField("Industry Posting Approved", true);
            Packages.PreparePostingFoundation();
        end;
        if Setup."Industry Process Mode" = "BCSF Process Mode"::FollowUpProcesses then begin
            Payments.PrepareFoundation();
            Movements.PrepareFoundation();
            // Additive foundation of the optional modules; only the modules selected in the setup are prepared.
            if Selection.IsCodeSelected(Setup."Industry Additional Modules", "BCSF Module Type"::Assembly) then
                AssemblyProcessor.PrepareFoundation();
            if Selection.IsCodeSelected(Setup."Industry Additional Modules", "BCSF Module Type"::Planning) then
                PlanningProcessor.PrepareFoundation();
            if Selection.IsCodeSelected(Setup."Industry Additional Modules", "BCSF Module Type"::CRM) then
                CrmProcessor.PrepareFoundation();
            if Selection.IsCodeSelected(Setup."Industry Additional Modules", "BCSF Module Type"::Warehouse) then
                WarehouseProcessor.PrepareFoundation();
        end;
        EndingDate := Setup."Industry Ending Date";
        if EndingDate = 0D then
            EndingDate := Setup."Industry Date"; // Preserve already scheduled legacy requests.
        ScenarioId := Profile.CreateTemplateForId(CreateGuid(), Setup."Industry Size", Setup."Industry Process Mode", Setup."Industry Date", EndingDate, Setup."Industry Additional Modules");
        Profile.ConfigureGeneration(ScenarioId, Setup."Industry Generation Kind", Setup."Industry Master Source Id",
          Setup."Industry Purchase Selected", Setup."Industry Sales Selected", Setup."Industry Purchase Quantity",
          Setup."Industry Sales Order Quantity", Setup."Industry Sales Quote Quantity", Setup."Industry Sales Inv Quantity");
        Scenario.Get(ScenarioId);
        if Setup."Industry Process Mode".AsInteger() >= 2 then begin
            Scenario."Sales Posting Approved" := Setup."Industry Posting Approved";
            Scenario."Purchase Posting Approved" := Setup."Industry Posting Approved";
            Scenario."Payment Posting Approved" := Setup."Industry Process Mode" = "BCSF Process Mode"::FollowUpProcesses;
            Scenario.Modify(true);
        end;
        Setup.Get(Setup.GetSetupKey());
        Setup."Industry Run Id" := QuickRun.RunScenario(Scenario);
        Setup.Modify(true);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Start(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode")
    begin
        Start(Mode, Size, ProcessMode, false);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Start(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode"; PostingApproved: Boolean)
    begin
        Start(Mode, Size, ProcessMode, PostingApproved, '');
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Start(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode"; PostingApproved: Boolean; AdditionalModules: Text)
    begin
        Start(Mode, Size, ProcessMode, PostingApproved, AdditionalModules, CalcDate('<-1Y>', Today()), Today() - 1);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Start(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode"; PostingApproved: Boolean; AdditionalModules: Text; StartingDate: Date; EndingDate: Date)
    var
        Profile: Codeunit "BCSF Wholesale Profile";
        SourceId: Guid;
    begin
        StartConfigured(Mode, Size, ProcessMode, PostingApproved, AdditionalModules, StartingDate, EndingDate,
          "BCSF Generation Kind"::Complete, SourceId, true, true,
          Profile.Quantity(Size, "BCSF Entity Type"::PurchaseOrder), Profile.Quantity(Size, "BCSF Entity Type"::SalesOrder),
          Profile.Quantity(Size, "BCSF Entity Type"::SalesQuote), Profile.Quantity(Size, "BCSF Entity Type"::SalesInvoice));
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure StartConfigured(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode"; PostingApproved: Boolean; AdditionalModules: Text; StartingDate: Date; EndingDate: Date; Kind: Enum "BCSF Generation Kind"; SourceId: Guid; PurchaseSelected: Boolean; SalesSelected: Boolean; Purchases: Integer; Orders: Integer; Quotes: Integer; Invoices: Integer)
    var
        Setup: Record "BCSF Factory Setup";
        Scenario: Record "BCSF Scenario";
        Job: Record "Job Queue Entry";
        TempModules: Record "BCSF Scenario Module" temporary;
        SetupMgt: Codeunit "BCSF Setup Management";
        Packages: Codeunit "BCSF Finance Package Mgt";
        Profile: Codeunit "BCSF Wholesale Profile";
        Guard: Codeunit "BCSF Environment Guard";
        Enqueue: Codeunit "Job Queue - Enqueue";
    begin
        // Zero document quantities intentionally disable that process without invalidating the request.
        PurchaseSelected := PurchaseSelected and (Purchases > 0);
        SalesSelected := SalesSelected and ((Orders > 0) or (Quotes > 0) or (Invoices > 0));
        Profile.CheckDateRange(StartingDate, EndingDate, Today() - 1);
        if EndingDate <> Today() - 1 then
            Error(PeriodChangedErr);
        Profile.LoadModules(AdditionalModules, TempModules);
        // Fixed lock order shared with snapshots, configuration editors and the bootstrap job.
        Scenario.LockTable();
        SetupMgt.InitializeSetup();
        Guard.EnsureCanConfigure(CompanyName());
        Setup.LockTable();
        Setup.Get(Setup.GetSetupKey());
        EnsureCanStartNewRequest(Setup);
        if (ProcessMode.AsInteger() >= 2) and not PostingApproved then
            Error(ApprovalErr);
        Profile.CheckSelection(Size, ProcessMode);
        if Setup."Company Initialized" then begin
            Setup.TestField("Generation Enabled", true);
            if Mode <> Packages.GetAppliedMode() then
                Error(ChartErr);
        end;
        CheckGenerationRequest(Kind, SourceId, ProcessMode, PurchaseSelected, SalesSelected, Purchases, Orders, Quotes, Invoices, Setup);
        // Read-only finance preflight before accepting the background request.
        Packages.CheckInitialization(Mode);
        if Setup."Company Initialized" and (ProcessMode.AsInteger() >= 2) then
            Packages.CheckPostingFoundation();
        Job.CheckRequiredPermissions();
        if not Job.WritePermission() then
            Error(JobErr);
        Clear(Setup."Industry Run Id");
        Setup."Industry Posting Approved" := PostingApproved and (ProcessMode.AsInteger() >= 2);
        if Setup."Industry Posting Approved" then
            Setup.Validate("Posting Enabled", true);
        Setup."Industry Finance Mode" := Mode;
        Setup."Industry Size" := Size;
        Setup."Industry Additional Modules" := CopyStr(AdditionalModules, 1, MaxStrLen(Setup."Industry Additional Modules"));
        Setup."Industry Generation Kind" := Kind;
        Setup."Industry Master Source Id" := SourceId;
        Setup."Industry Purchase Selected" := PurchaseSelected;
        Setup."Industry Sales Selected" := SalesSelected;
        Setup."Industry Purchase Quantity" := Purchases;
        Setup."Industry Sales Order Quantity" := Orders;
        Setup."Industry Sales Quote Quantity" := Quotes;
        Setup."Industry Sales Inv Quantity" := Invoices;
        Setup."Industry Process Mode" := ProcessMode;
        Setup."Industry Date" := StartingDate;
        Setup."Industry Ending Date" := EndingDate;
        Job.Init();
        Job."Object Type to Run" := Job."Object Type to Run"::Codeunit;
        Job."Object ID to Run" := Codeunit::"BCSF Company Initialization";
        Job."Record ID to Process" := Setup.RecordId();
        Job.Description := JobLbl;
        Job."User Language ID" := GlobalLanguage();
        Job."Maximum No. of Attempts to Run" := 0;
        Job."Recurring Job" := false;
        Job."Earliest Start Date/Time" := CurrentDateTime();
        Enqueue.Run(Job);
        Job.TestField(ID);
        Job.TestField("System Task ID");
        Setup."Industry Job Id" := Job.ID;
        Setup.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ProtectRequest(var Rec: Record "BCSF Factory Setup"; var xRec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
    var
        Previous: Record "BCSF Factory Setup";
        TempModules: Record "BCSF Scenario Module" temporary;
        Job: Record "Job Queue Entry";
        Profile: Codeunit "BCSF Wholesale Profile";
    begin
        if Rec.IsTemporary() then
            exit;
        Previous.LockTable();
        Previous.Get(Rec.GetSetupKey());
        if (Previous."Industry Job Id" = Rec."Industry Job Id") and not IsNullGuid(Previous."Industry Job Id") then begin
            Rec.TestField("Industry Finance Mode", Previous."Industry Finance Mode");
            Rec.TestField("Industry Size", Previous."Industry Size");
            Rec.TestField("Industry Additional Modules", Previous."Industry Additional Modules");
            Rec.TestField("Industry Process Mode", Previous."Industry Process Mode");
            Rec.TestField("Industry Date", Previous."Industry Date");
            Rec.TestField("Industry Ending Date", Previous."Industry Ending Date");
            Rec.TestField("Industry Posting Approved", Previous."Industry Posting Approved");
            Rec.TestField("Industry Generation Kind", Previous."Industry Generation Kind");
            Rec.TestField("Industry Master Source Id", Previous."Industry Master Source Id");
            Rec.TestField("Industry Purchase Selected", Previous."Industry Purchase Selected");
            Rec.TestField("Industry Sales Selected", Previous."Industry Sales Selected");
            Rec.TestField("Industry Purchase Quantity", Previous."Industry Purchase Quantity");
            Rec.TestField("Industry Sales Order Quantity", Previous."Industry Sales Order Quantity");
            Rec.TestField("Industry Sales Quote Quantity", Previous."Industry Sales Quote Quantity");
            Rec.TestField("Industry Sales Inv Quantity", Previous."Industry Sales Inv Quantity");

            if not IsNullGuid(Previous."Industry Run Id") then
                Rec.TestField("Industry Run Id", Previous."Industry Run Id")
            else
                if not IsNullGuid(Rec."Industry Run Id") then begin
                    Job.Get(Previous."Industry Job Id");
                    Job.TestField(Status, Job.Status::"In Process");
                    Job.TestField("User Session ID", SessionId());
                    Job.TestField("User Service Instance ID", ServiceInstanceId());
                end;
        end else
            if not IsNullGuid(Rec."Industry Job Id") then begin
                EnsureCanStartNewRequest(Previous);
                Profile.LoadModules(Rec."Industry Additional Modules", TempModules);
                Rec.TestField("Industry Run Id", CreateEmptyGuid());
                Rec.TestField("Industry Date");
                Profile.CheckDateRange(Rec."Industry Date", Rec."Industry Ending Date", Today() - 1);
                if Rec."Industry Ending Date" <> Today() - 1 then
                    Error(PeriodChangedErr);
                Profile.CheckSelection(Rec."Industry Size", Rec."Industry Process Mode");
                CheckGenerationRequest(Rec."Industry Generation Kind", Rec."Industry Master Source Id", Rec."Industry Process Mode",
                  Rec."Industry Purchase Selected", Rec."Industry Sales Selected", Rec."Industry Purchase Quantity",
                  Rec."Industry Sales Order Quantity", Rec."Industry Sales Quote Quantity", Rec."Industry Sales Inv Quantity", Rec);
                if Rec."Industry Process Mode".AsInteger() >= 2 then
                    Rec.TestField("Industry Posting Approved", true);
                Job.Get(Rec."Industry Job Id");
                Job.TestField("Object Type to Run", Job."Object Type to Run"::Codeunit);
                Job.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
                Job.TestField("Maximum No. of Attempts to Run", 0);
                Job.TestField("Recurring Job", false);
                if Job."Record ID to Process" <> Rec.RecordId() then
                    Error(JobErr);
            end else
                if not IsNullGuid(Previous."Industry Job Id") then
                    Error(ExistingErr);
    end;

    local procedure EnsureCanStartNewRequest(Setup: Record "BCSF Factory Setup")
    var
        Execution: Record "BCSF Run Execution";
        Batch: Record "BCSF Batch";
        Job: Record "Job Queue Entry";
    begin
        if IsNullGuid(Setup."Industry Job Id") and IsNullGuid(Setup."Industry Run Id") then
            exit;

        // An initialization that failed before creating its run must not lock the company forever.
        // A queued, paused or running job still owns the request and must not be duplicated.
        if not IsNullGuid(Setup."Industry Job Id") then
            if Job.Get(Setup."Industry Job Id") then
                if not (Job.Status in [Job.Status::Error, Job.Status::Finished]) then
                    Error(ExistingErr);

        if IsNullGuid(Setup."Industry Run Id") then
            exit;

        if not Execution.Get(Setup."Industry Run Id") then
            Error(ExistingErr);
        if not (Execution.Status in [Execution.Status::Completed, Execution.Status::CompletedWithWarnings,
          Execution.Status::Failed, Execution.Status::ValidationFailed, Execution.Status::Cancelled]) then
            Error(ExistingErr);
        Batch.SetRange("Run Id", Setup."Industry Run Id");
        Batch.SetRange(Status, Batch.Status::Running);
        if not Batch.IsEmpty() then
            Error(ExistingErr);
    end;

    local procedure CheckGenerationRequest(Kind: Enum "BCSF Generation Kind"; SourceId: Guid; ProcessMode: Enum "BCSF Process Mode"; PurchaseSelected: Boolean; SalesSelected: Boolean; Purchases: Integer; Orders: Integer; Quotes: Integer; Invoices: Integer; Setup: Record "BCSF Factory Setup")
    var
        Header: Record "BCSF Run Header";
        Source: Codeunit "BCSF Master Data Source";
    begin
        if not (Kind in [Kind::Complete, Kind::MasterData, Kind::Transactions]) then
            Error(RequestErr);
        if Kind = Kind::MasterData then
            if ProcessMode <> ProcessMode::SetupAndMasterData then
                Error(RequestErr);
        if Kind <> Kind::Transactions then begin
            if not IsNullGuid(SourceId) then
                Error(RequestErr);
            exit;
        end;
        Setup.TestField("Company Initialized", true);
        // Quantities are independent: invoice-only sales and purchase-only runs are valid.
        // Hidden quantities of unselected modules must not invalidate a request.
        if (ProcessMode = ProcessMode::SetupAndMasterData) or
          (PurchaseSelected and ((Purchases < 0) or (Purchases > Setup."Maximum Records per Entity"))) or
          (SalesSelected and ((Orders < 0) or (Quotes < 0) or (Invoices < 0) or
            (Orders > Setup."Maximum Records per Entity") or (Quotes > Setup."Maximum Records per Entity") or
            (Invoices > Setup."Maximum Records per Entity"))) or
          (not (PurchaseSelected and (Purchases > 0)) and
            not (SalesSelected and ((Orders > 0) or (Quotes > 0) or (Invoices > 0)))) then
            Error(RequestErr);
        if IsNullGuid(SourceId) then
            Source.CaptureExisting(PurchaseSelected and (Purchases > 0), SalesSelected and ((Orders > 0) or (Quotes > 0) or (Invoices > 0)))
        else begin
            Header.Get(SourceId);
            Source.Capture(SourceId, 'TRADE', Header."Profile Version");
        end;
    end;

    [TryFunction]
    local procedure CanUseSource(SourceId: Guid)
    var
        Header: Record "BCSF Run Header";
        Source: Codeunit "BCSF Master Data Source";
    begin
        Header.Get(SourceId);
        Source.Capture(SourceId, 'TRADE', Header."Profile Version");
    end;

    procedure SelectMasterSource(var SourceId: Guid): Boolean
    var
        Header: Record "BCSF Run Header";
        Lookup: Page "BCSF Factory Dashboard";
    begin
        Header.SetRange("Profile Code", 'TRADE');
        Header.SetFilter("Profile Version", '5|6');
        if Header.FindSet() then
            repeat
                if CanUseSource(Header."Run Id") then
                    Header.Mark(true)
                else
                    ClearLastError();
            until Header.Next() = 0;
        Header.MarkedOnly(true);
        Lookup.SetTableView(Header);
        Lookup.LookupMode(true);
        if Lookup.RunModal() <> Action::LookupOK then
            exit(false);
        Lookup.GetRecord(Header);
        SourceId := Header."Run Id";
        exit(true);
    end;

    local procedure CreateEmptyGuid(): Guid
    var
        EmptyId: Guid;
    begin
        exit(EmptyId);
    end;

    var
        RequestErr: Label 'Select a valid generation kind, executable modules and document quantities within the company limits. Existing company master data may be used without a source run.';
        PeriodChangedErr: Label 'The period must end yesterday. Reopen company initialization to refresh the displayed period.';
        ApprovalErr: Label 'Explicitly approve standard posting and, for follow-up mode, payments and application before starting.';
        JobLbl: Label 'Scenario Factory company initialization';
        JobErr: Label 'Company initialization requires an authorized standard background job. Review job queue permissions and its current status.';
        ExistingErr: Label 'A company initialization request already exists. Review its progress or error in the dashboard; do not start a duplicate.';
        ChartErr: Label 'This company already has a chart of accounts. Reuse it; another chart requires a new sandbox company.';
}
