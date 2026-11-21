namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.Finance;
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
    ScenarioId: Guid;
  begin
    if Setup."Company Initialized" then begin
      Setup.TestField("Generation Enabled", true);
      if Setup."Industry Finance Mode" <> Packages.GetAppliedMode() then
        Error(ChartErr);
    end else
      Catalog.InitializeFoundation(Setup."Industry Finance Mode");
    if Setup."Industry Process Mode".AsInteger() >= 2 then begin
      Setup.TestField("Industry Posting Approved", true);
      Packages.PreparePostingFoundation();
    end;
    if Setup."Industry Process Mode" = "BCSF Process Mode"::FollowUpProcesses then
      Payments.PrepareFoundation();
    ScenarioId := Profile.CreateTemplate(Setup."Industry Size", Setup."Industry Process Mode", Setup."Industry Date");
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
  var
    Setup: Record "BCSF Factory Setup";
    Scenario: Record "BCSF Scenario";
    Job: Record "Job Queue Entry";
    SetupMgt: Codeunit "BCSF Setup Management";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Profile: Codeunit "BCSF Wholesale Profile";
    Guard: Codeunit "BCSF Environment Guard";
    Enqueue: Codeunit "Job Queue - Enqueue";
  begin
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
    Setup."Industry Process Mode" := ProcessMode;
    Setup."Industry Date" := WorkDate();
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
      Rec.TestField("Industry Process Mode", Previous."Industry Process Mode");
      Rec.TestField("Industry Date", Previous."Industry Date");
      Rec.TestField("Industry Posting Approved", Previous."Industry Posting Approved");
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
        Rec.TestField("Industry Run Id", CreateEmptyGuid());
        Rec.TestField("Industry Date");
        Profile.CheckSelection(Rec."Industry Size", Rec."Industry Process Mode");
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
  begin
    if IsNullGuid(Setup."Industry Job Id") and IsNullGuid(Setup."Industry Run Id") then
      exit;
    if IsNullGuid(Setup."Industry Run Id") then
      Error(ExistingErr);
    Execution.Get(Setup."Industry Run Id");
    if not (Execution.Status in [Execution.Status::Completed, Execution.Status::CompletedWithWarnings]) then
      Error(ExistingErr);
  end;

  local procedure CreateEmptyGuid(): Guid
  var
    EmptyId: Guid;
  begin
    exit(EmptyId);
  end;

  var
    ApprovalErr: Label 'Explicitly approve standard posting and, for follow-up mode, payments and application before starting.';
    JobLbl: Label 'Scenario Factory company initialization';
    JobErr: Label 'Company initialization requires an authorized standard background job. Review job queue permissions and its current status.';
    ExistingErr: Label 'A company initialization request already exists. Review its progress or error in the dashboard; do not start a duplicate.';
    ChartErr: Label 'This company already has a chart of accounts. Reuse it; another chart requires a new sandbox company.';
}
