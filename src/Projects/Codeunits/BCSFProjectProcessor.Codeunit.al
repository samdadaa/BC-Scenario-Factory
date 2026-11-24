namespace BCScenarioFactory.Projects;

using BCScenarioFactory.Assembly;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.Sales;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;

/// <summary>
/// Projects (jobs) for standard-posted purchases of the same run, in the approved follow-up stage. The material is the
/// first one or two item lines of the purchase, the labour is the synthetic assembly resource when usable.
/// Modes: 1 project and planning lines only, 2 usage posted and invoice created but unposted,
/// 3 usage posted and half of the quantity billed and posted, 4 usage posted and fully billed and posted.
/// Usage uses the same unit allowance as stock movements, so the planned stock reserve for later sales stays intact.
/// Unsuitable cases are skipped before any write (SOURCE, STOCK, DIMENSION). Projects are separate from service management.
/// </summary>
codeunit 90484 "BCSF Project Processor"
{
  Access = Internal;

  /// <summary>Additive marker: projects only when jobs setup, job source code, assembly resource and cost posting are usable.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    JobsSetup: Record "Jobs Setup";
    SourceCode: Record "Source Code Setup";
    InventorySetup: Record "Inventory Setup";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
  begin
    if not JobsSetup.Get() or not SourceCode.Get() or not InventorySetup.Get() then
      exit;
    if (JobsSetup."Job Nos." = '') or (SourceCode."Job Journal" = '') or not InventorySetup."Automatic Cost Posting" then
      exit;
    if not AssemblyProcessor.ResourceUsable() then
      exit;
    Settings.Add('projectVersion', 1);
  end;

  /// <summary>True for new captures with the project marker; an unknown marker stops.</summary>
  procedure Enabled(Context: JsonObject): Boolean
  var
    Token: JsonToken;
    Settings: JsonObject;
  begin
    if not Context.Get('paymentSetup', Token) then
      exit(false);
    Settings := Token.AsObject();
    if not Settings.Get('projectVersion', Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(SetupErr);
    exit(true);
  end;

  /// <summary>1 planning only, 2 usage and unposted invoice, 3 usage and posted partial billing, 4 usage and posted full billing.</summary>
  procedure Mode(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Quantity: Decimal): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    Result: Integer;
  begin
    Result := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PROJECT-MODE', 1, 4);
    if (Result = 3) and (Quantity < 2) then
      Result := 4;
    exit(Result);
  end;

  /// <summary>Quantity billed in a partial billing: half of the planned quantity in whole units, at least one.</summary>
  procedure BilledQuantity(Mode: Integer; Planned: Decimal): Decimal
  var
    Part: Decimal;
  begin
    if Mode <> 3 then
      exit(Planned);
    Part := Round(Planned / 2, 1, '>');
    if Part > Planned then
      Part := Planned;
    exit(Part);
  end;

  /// <summary>Project duration in days, reproducible from the seed (20 to 120).</summary>
  procedure DurationDays(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PROJECT-DURATION', 20, 120));
  end;

  local procedure ProjectName(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; City: Text): Text[100]
  var
    Seed: Codeunit "BCSF Seed Engine";
    Contract: Codeunit "BCSF Contract JSON";
    Index: Integer;
    Name: Text;
  begin
    Index := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PROJECT-NAME', 1, 6);
    if Contract.GetInteger(Context, 'dataLanguage') = 1 then
      Name := SelectStr(Index, 'Lagerhallenumbau,Heizungsmodernisierung,Werkstattausstattung,Sanierung Verwaltungsgebäude,Photovoltaikanlage,Rohrleitungsbau Betriebshof')
    else
      Name := SelectStr(Index, 'Warehouse conversion,Heating modernisation,Workshop equipment,Office building refurbishment,Photovoltaic installation,Plant yard piping');
    if City <> '' then
      Name += ' ' + City;
    exit(CopyStr(Name, 1, 100));
  end;

  local procedure TaskName(Context: JsonObject; Second: Boolean): Text[100]
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    if Contract.GetInteger(Context, 'dataLanguage') = 1 then begin
      if Second then
        exit('Montage und Inbetriebnahme');
      exit('Materiallieferung');
    end;
    if Second then
      exit('Installation and commissioning');
    exit('Material supply');
  end;

  /// <summary>The customer of the project is a customer of the same run (read-only, no write).</summary>
  [TryFunction]
  local procedure TryCustomer(Context: JsonObject; LogicalKey: Integer; var Customer: Record Customer)
  var
    SalesSetup: Codeunit "BCSF Sales Setup";
    Masters: JsonObject;
  begin
    Masters := SalesSetup.WithRunMasters(Context);
    SalesSetup.CustomerFor(Masters, LogicalKey, Customer);
    SalesSetup.CheckCustomer(Customer);
  end;

  /// <summary>Creates project, tasks, planning lines, usage and billing. Registers a documented skip when nothing could be written.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Customer: Record Customer;
    Registry: Codeunit "BCSF Record Registry";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Count: Integer;
    Quantity: Decimal;
    ProjectMode: Integer;
    SkipReason: Code[30];
  begin
    Count := AssemblyProcessor.Components(Invoice, ItemNos, Locations, Measures);
    Quantity := AssemblyProcessor.AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    ProjectMode := Mode(Context, NodeCode, LogicalKey, Quantity);
    SkipReason := Preflight(Context, LogicalKey, ProjectMode, Quantity, Count, ItemNos, Locations, Date, Customer);
    if SkipReason = '' then
      SkipReason := Build(Context, RunId, NodeCode, LogicalKey, BatchId, Date, ParentId, ProjectMode, Quantity, Count, ItemNos, Locations, Measures, Customer);
    if SkipReason <> '' then
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'MOVEMENT-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
  end;

  local procedure Preflight(Context: JsonObject; LogicalKey: Integer; ProjectMode: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Date: Date; var Customer: Record Customer): Code[30]
  var
    Item: Record Item;
    Variant: Record "Item Variant";
    JobsSetup: Record "Jobs Setup";
    Index: Integer;
  begin
    if not JobsSetup.Get() or (JobsSetup."Job Nos." = '') then
      exit('SOURCE');
    if not TryCustomer(Context, LogicalKey, Customer) then begin
      ClearLastError();
      exit('SOURCE');
    end;
    if Customer."Currency Code" <> '' then
      exit('SOURCE');
    for Index := 1 to Count do begin
      Item.Get(ItemNos[Index]);
      if Item.Blocked or (Item.Type <> Item.Type::Inventory) or (Item."Item Tracking Code" <> '') then
        exit('SOURCE');
      // Variants are not part of this contract: such components are skipped, never replaced.
      Variant.SetRange("Item No.", ItemNos[Index]);
      if not Variant.IsEmpty() then
        exit('SOURCE');
      if ProjectMode > 1 then begin
        Item.SetRange("Location Filter", Locations[Index]);
        Item.SetRange("Date Filter", 0D, Date);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        if Item.Inventory - Item."Reserved Qty. on Inventory" < Quantity then
          exit('STOCK');
      end;
    end;
    exit('');
  end;

  local procedure Build(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Date: Date; ParentId: Guid; ProjectMode: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Measures: array[2] of Code[10]; Customer: Record Customer): Code[30]
  var
    Job: Record Job;
    Task: Record "Job Task";
    PlanningLine: Record "Job Planning Line";
    Resource: Record Resource;
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    Registry: Codeunit "BCSF Record Registry";
    JobId: Guid;
    LineNo: Integer;
    Index: Integer;
    UseResource: Boolean;
    LastLine: Integer;
  begin
    UseResource := AssemblyProcessor.ResourceUsable() and Resource.Get(AssemblyProcessor.ResourceNo());
    Job.Init();
    Job.Insert(true);
    Job.Validate("Bill-to Customer No.", Customer."No.");
    Job.Validate(Description, ProjectName(Context, NodeCode, LogicalKey, Customer.City));
    Job.Validate("Starting Date", Date);
    Job.Validate("Ending Date", Date + DurationDays(Context, NodeCode, LogicalKey));
    Job."Apply Usage Link" := true;
    Job."Allow Schedule/Contract Lines" := true;
    Job.Validate(Status, Job.Status::Open);
    Job.Modify(true);
    JobId := Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT', BatchId, Job.RecordId(), ParentId);
    // Task 1 carries the material, task 2 the labour.
    CreateTask(Job."No.", 'T10', TaskName(Context, false), Task);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT-TASK-1', BatchId, Task.RecordId(), JobId);
    CreateTask(Job."No.", 'T20', TaskName(Context, true), Task);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT-TASK-2', BatchId, Task.RecordId(), JobId);
    for Index := 1 to Count do begin
      LineNo := Index * 10000;
      CreatePlanningLine(Job."No.", 'T10', LineNo, true, ItemNos[Index], Locations[Index], Measures[Index], Quantity, Date);
      PlanningLine.Get(Job."No.", 'T10', LineNo);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-PLAN', Index), BatchId, PlanningLine.RecordId(), JobId);
      LastLine := LineNo;
    end;
    if UseResource then begin
      LineNo := LastLine + 10000;
      CreatePlanningLine(Job."No.", 'T20', LineNo, false, Resource."No.", '', Resource."Base Unit of Measure", Quantity * 2, Date);
      PlanningLine.Get(Job."No.", 'T20', LineNo);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-PLAN', Count + 1), BatchId, PlanningLine.RecordId(), JobId);
    end;
    if ProjectMode = 1 then
      exit('');
    exit(PostUsageAndBill(Context, RunId, NodeCode, LogicalKey, BatchId, Date, JobId, Job, ProjectMode, Quantity));
  end;

  local procedure CreateTask(JobNo: Code[20]; TaskNo: Code[20]; Description: Text[100]; var Task: Record "Job Task")
  begin
    Task.Init();
    Task.Validate("Job No.", JobNo);
    Task.Validate("Job Task No.", TaskNo);
    Task.Validate(Description, Description);
    Task.Validate("Job Task Type", Task."Job Task Type"::Posting);
    Task.Insert(true);
  end;

  local procedure CreatePlanningLine(JobNo: Code[20]; TaskNo: Code[20]; LineNo: Integer; IsItem: Boolean; No: Code[20]; LocationCode: Code[10]; MeasureCode: Code[10]; Quantity: Decimal; Date: Date)
  var
    Line: Record "Job Planning Line";
  begin
    Line.Init();
    Line.Validate("Job No.", JobNo);
    Line.Validate("Job Task No.", TaskNo);
    Line."Line No." := LineNo;
    Line.Validate("Line Type", Line."Line Type"::"Both Budget and Billable");
    Line.Insert(true);
    Line.Validate("Planning Date", Date);
    if IsItem then
      Line.Validate(Type, Line.Type::Item)
    else
      Line.Validate(Type, Line.Type::Resource);
    Line.Validate("No.", No);
    if LocationCode <> '' then
      Line.Validate("Location Code", LocationCode);
    Line.Validate("Unit of Measure Code", MeasureCode);
    Line.Validate(Quantity, Quantity);
    Line.Modify(true);
  end;

  local procedure PostUsageAndBill(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Date: Date; JobId: Guid; Job: Record Job; ProjectMode: Integer; Quantity: Decimal): Code[30]
  var
    PlanningLine: Record "Job Planning Line";
    TempLine: Record "Job Journal Line" temporary;
    SourceCode: Record "Source Code Setup";
    Dimensions: Codeunit DimensionManagement;
    PostLine: Codeunit "Job Jnl.-Post Line";
    LineIndex: Integer;
  begin
    SourceCode.Get();
    PlanningLine.SetRange("Job No.", Job."No.");
    PlanningLine.FindSet();
    repeat
      LineIndex += 1;
      TempLine.Init();
      TempLine."Line No." := LineIndex * 10000;
      TempLine.Validate("Job No.", Job."No.");
      TempLine.Validate("Job Task No.", PlanningLine."Job Task No.");
      TempLine.Validate("Posting Date", Date);
      TempLine.Validate("Document Date", Date);
      TempLine."Document No." := UsageDocumentNo(Job."No.");
      if PlanningLine.Type = PlanningLine.Type::Item then
        TempLine.Validate(Type, TempLine.Type::Item)
      else
        TempLine.Validate(Type, TempLine.Type::Resource);
      TempLine.Validate("No.", PlanningLine."No.");
      if PlanningLine."Location Code" <> '' then
        TempLine.Validate("Location Code", PlanningLine."Location Code");
      TempLine.Validate("Unit of Measure Code", PlanningLine."Unit of Measure Code");
      TempLine.Validate(Quantity, PlanningLine.Quantity);
      TempLine.Validate("Job Planning Line No.", PlanningLine."Line No.");
      TempLine."Source Code" := SourceCode."Job Journal";
      // Temporary line without journal template/batch: the standard OnInsert would require both.
      TempLine.Insert();
      if not Dimensions.CheckDimIDComb(TempLine."Dimension Set ID") then
        exit('DIMENSION');
    until PlanningLine.Next() = 0;
    // From here on only the standard posting codeunit writes; no skip is possible any more.
    TempLine.FindSet();
    repeat
      PostLine.RunWithCheck(TempLine);
    until TempLine.Next() = 0;
    RegisterUsage(RunId, NodeCode, LogicalKey, BatchId, JobId, Job."No.");
    exit(Bill(RunId, NodeCode, LogicalKey, BatchId, Date, JobId, Job, ProjectMode));
  end;

  /// <summary>Document number of the usage posting: the project number, which is unique per project.</summary>
  procedure UsageDocumentNo(JobNo: Code[20]): Code[20]
  begin
    exit(JobNo);
  end;

  local procedure Bill(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Date: Date; JobId: Guid; Job: Record Job; ProjectMode: Integer): Code[30]
  var
    PlanningLine: Record "Job Planning Line";
    PlanningInvoice: Record "Job Planning Line Invoice";
    Header: Record "Sales Header";
    Posted: Record "Sales Invoice Header";
    Shipment: Record "Sales Shipment Header";
    Credit: Record "Sales Cr.Memo Header";
    Receipt: Record "Return Receipt Header";
    CreateInvoice: Codeunit "Job Create-Invoice";
    Registry: Codeunit "BCSF Record Registry";
    SalesPost: Codeunit "Sales-Post";
    Planned: Decimal;
  begin
    PlanningLine.SetRange("Job No.", Job."No.");
    PlanningLine.FindSet();
    repeat
      Planned := BilledQuantity(ProjectMode, PlanningLine.Quantity);
      if Planned <> PlanningLine."Qty. to Transfer to Invoice" then begin
        PlanningLine.Validate("Qty. to Transfer to Invoice", Planned);
        PlanningLine.Modify(true);
      end;
    until PlanningLine.Next() = 0;
    PlanningLine.Reset();
    PlanningLine.SetRange("Job No.", Job."No.");
    // Standard transfer of planning lines to a new sales invoice (no report, no commit).
    CreateInvoice.CreateSalesInvoiceLines(Job."No.", PlanningLine, '', true, Date, Date, false);
    PlanningInvoice.SetRange("Job No.", Job."No.");
    PlanningInvoice.SetRange("Document Type", PlanningInvoice."Document Type"::Invoice);
    if not PlanningInvoice.FindFirst() then
      exit('SOURCE');
    Header.Get(Header."Document Type"::Invoice, PlanningInvoice."Document No.");
    if ProjectMode = 2 then begin
      // Unposted invoice from the invoice proposal.
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT-INVOICE', BatchId, Header.RecordId(), JobId);
      exit('');
    end;
    SalesPost.SetSuppressCommit(true);
    SalesPost.Run(Header);
    SalesPost.GetGlobaDocumentsHeaders(Shipment, Posted, Credit, Receipt);
    Posted.TestField("No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT-INVOICE', BatchId, Posted.RecordId(), JobId);
    RegisterInvoiceEvidence(RunId, NodeCode, LogicalKey, BatchId, JobId, Posted, Job."No.");
    exit('');
  end;

  local procedure RegisterUsage(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; JobId: Guid; JobNo: Code[20])
  var
    JobEntry: Record "Job Ledger Entry";
    ItemEntry: Record "Item Ledger Entry";
    ResourceEntry: Record "Res. Ledger Entry";
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    GL: Record "G/L Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    JobEntry.SetRange("Job No.", JobNo);
    JobEntry.SetRange("Entry Type", JobEntry."Entry Type"::Usage);
    if not JobEntry.FindSet() then
      Error(ResultErr);
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-JLE', JobEntry."Entry No."), BatchId, JobEntry.RecordId(), JobId);
    until JobEntry.Next() = 0;
    ItemEntry.SetRange("Job No.", JobNo);
    if ItemEntry.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-ILE', ItemEntry."Entry No."), BatchId, ItemEntry.RecordId(), JobId);
        Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
        if Value.FindSet() then
          repeat
            Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-VAL', Value."Entry No."), BatchId, Value.RecordId(), JobId);
            Relation.SetRange("Value Entry No.", Value."Entry No.");
            if Relation.FindSet() then
              repeat
                GL.Get(Relation."G/L Entry No.");
                Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-GL', GL."Entry No."), BatchId, GL.RecordId(), JobId);
              until Relation.Next() = 0;
          until Value.Next() = 0;
      until ItemEntry.Next() = 0;
    ResourceEntry.SetRange("Document No.", UsageDocumentNo(JobNo));
    ResourceEntry.SetRange("Order No.", JobNo);
    if ResourceEntry.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-RES', ResourceEntry."Entry No."), BatchId, ResourceEntry.RecordId(), JobId);
      until ResourceEntry.Next() = 0;
    // Accounting entries of the usage posting (resource cost and inventory adjustment) share the document number.
    GL.Reset();
    GL.SetRange("Document No.", UsageDocumentNo(JobNo));
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-GL', GL."Entry No."), BatchId, GL.RecordId(), JobId);
      until GL.Next() = 0;
  end;

  local procedure RegisterInvoiceEvidence(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; JobId: Guid; Posted: Record "Sales Invoice Header"; JobNo: Code[20])
  var
    CustomerEntry: Record "Cust. Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    JobEntry: Record "Job Ledger Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    CustomerEntry.Get(Posted."Cust. Ledger Entry No.");
    CustomerEntry.TestField("Document No.", Posted."No.");
    CustomerEntry.TestField("Customer No.", Posted."Bill-to Customer No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PROJECT-CUSTENTRY', BatchId, CustomerEntry.RecordId(), JobId);
    GL.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    GL.SetRange("Document No.", Posted."No.");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-GL', GL."Entry No."), BatchId, GL.RecordId(), JobId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    VAT.SetRange("Document No.", Posted."No.");
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-VAT', VAT."Entry No."), BatchId, VAT.RecordId(), JobId);
      until VAT.Next() = 0;
    JobEntry.SetRange("Job No.", JobNo);
    JobEntry.SetRange("Entry Type", JobEntry."Entry Type"::Sale);
    if JobEntry.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PROJECT-JLE', JobEntry."Entry No."), BatchId, JobEntry.RecordId(), JobId);
      until JobEntry.Next() = 0;
  end;

  /// <summary>Read-only validation of the project against the plan: master data, usage, billing and stock.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Date: Date)
  var
    Entry: Record "BCSF Generated Record";
    Job: Record Job;
    PlanningLine: Record "Job Planning Line";
    JobEntry: Record "Job Ledger Entry";
    Header: Record "Sales Header";
    Posted: Record "Sales Invoice Header";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Count: Integer;
    Quantity: Decimal;
    ProjectMode: Integer;
    Index: Integer;
    Billed: Decimal;
  begin
    Count := AssemblyProcessor.Components(Invoice, ItemNos, Locations, Measures);
    Quantity := AssemblyProcessor.AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    ProjectMode := Mode(Context, NodeCode, LogicalKey, Quantity);
    Entry.Get(RunId, NodeCode, LogicalKey, 'PROJECT');
    Entry.TestField("Table Id", Database::Job);
    Job.GetBySystemId(Entry."Record SystemId");
    Job.TestField(Status, Job.Status::Open);
    Job.TestField("Starting Date", Date);
    Job.TestField("Ending Date", Date + DurationDays(Context, NodeCode, LogicalKey));
    Entry.Get(RunId, NodeCode, LogicalKey, 'PROJECT-TASK-1');
    Entry.Get(RunId, NodeCode, LogicalKey, 'PROJECT-TASK-2');
    // Planning lines: one per item component and at most one resource line.
    PlanningLine.SetRange("Job No.", Job."No.");
    PlanningLine.SetRange(Type, PlanningLine.Type::Item);
    if PlanningLine.Count() <> Count then
      Error(ResultErr);
    for Index := 1 to Count do begin
      PlanningLine.Get(Job."No.", 'T10', Index * 10000);
      PlanningLine.TestField("No.", ItemNos[Index]);
      PlanningLine.TestField(Quantity, Quantity);
      PlanningLine.TestField("Planning Date", Date);
      if ProjectMode > 1 then begin
        // Soll/Ist: the posted usage equals the plan.
        PlanningLine.TestField("Qty. Posted", Quantity);
        JobEntry.Reset();
        JobEntry.SetRange("Job No.", Job."No.");
        JobEntry.SetRange("Entry Type", JobEntry."Entry Type"::Usage);
        JobEntry.SetRange("No.", ItemNos[Index]);
        JobEntry.CalcSums(Quantity);
        if JobEntry.Quantity <> Quantity then
          Error(ResultErr);
        CheckNonNegative(ItemNos[Index], Locations[Index], Date);
      end;
    end;
    if ProjectMode = 1 then begin
      JobEntry.Reset();
      JobEntry.SetRange("Job No.", Job."No.");
      if not JobEntry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    Entry.Get(RunId, NodeCode, LogicalKey, 'PROJECT-INVOICE');
    if ProjectMode = 2 then begin
      Entry.TestField("Table Id", Database::"Sales Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::Invoice);
      Header.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");
      exit;
    end;
    Entry.TestField("Table Id", Database::"Sales Invoice Header");
    Posted.GetBySystemId(Entry."Record SystemId");
    Posted.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");
    Posted.TestField("Posting Date", Date);
    for Index := 1 to Count do begin
      PlanningLine.Get(Job."No.", 'T10', Index * 10000);
      Billed := BilledQuantity(ProjectMode, Quantity);
      PlanningLine.TestField("Qty. Transferred to Invoice", Billed);
    end;
  end;

  local procedure CheckNonNegative(ItemNo: Code[20]; LocationCode: Code[10]; Date: Date)
  var
    Item: Record Item;
  begin
    Item.Get(ItemNo);
    Item.SetRange("Location Filter", LocationCode);
    Item.SetRange("Date Filter", 0D, Date);
    Item.CalcFields(Inventory);
    if Item.Inventory < 0 then
      Error(ResultErr);
    Item.SetRange("Date Filter");
    Item.CalcFields(Inventory);
    if Item.Inventory < 0 then
      Error(ResultErr);
  end;

  local procedure Artifact(Prefix: Code[20]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    SetupErr: Label 'The project setup is not supported or changed. Review the project number series, the project journal source code and the synthetic assembly resource.';
    ResultErr: Label 'Project results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
