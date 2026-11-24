namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using System.Environment;
using System.Threading;

codeunit 90306 "BCSF Execution Rules"
{
  Access = Internal;

  procedure CheckEnvironment(RunId: Guid; TargetCompany: Text)
  var
    Header: Record "BCSF Run Header";
    Guard: Codeunit "BCSF Environment Guard";
    Environment: Codeunit "Environment Information";
  begin
    Guard.EnsureCanConfigure(TargetCompany);
    Header.LockTable();
    Header.Get(RunId);
    Header.TestField("Company Name", CompanyName());
    Header.TestField("Environment Name", Environment.GetEnvironmentName());
  end;

  procedure CheckCoverage(Batch: Record "BCSF Batch")
  var
    Entry: Record "BCSF Generated Record";
    LastKey: Integer;
    Units: Integer;
  begin
    if Batch."Skipped Units" <> 0 then begin
      CheckSkipped(Batch);
      exit;
    end;
    Batch.TestField("Skip Reason Code", '');
    Entry.SetCurrentKey("Batch Id", "Logical Key");
    Entry.SetRange("Batch Id", Batch."Batch Id");
    Entry.SetLoadFields("Run Id", "Node Code", "Logical Key");
    if Entry.Count() <> Batch."Created Records" then
      Error(CoverageErr);
    LastKey := 0;
    Units := 0;
    if Entry.FindSet() then
      repeat
        if (Entry."Run Id" <> Batch."Run Id") or (Entry."Node Code" <> Batch."Node Code") then
          Error(CoverageErr);
        if Entry."Logical Key" <> LastKey then begin
          if Entry."Logical Key" <> Batch."First Key" + Units then
            Error(CoverageErr);
          Units += 1;
          LastKey := Entry."Logical Key";
        end;
      until Entry.Next() = 0;
    if (Units <> Batch."Last Key" - Batch."First Key" + 1) or (Batch."Processed Units" <> Units) then
      Error(CoverageErr);
  end;

  procedure CheckSkippingOwner(Batch: Record "BCSF Batch")
  var
    BatchJson: JsonObject;
  begin
    BatchJson.Add('batchKey', Batch."Batch Key");
    BatchJson.Add('firstKey', Batch."First Key");
    BatchJson.Add('lastKey', Batch."Last Key");
    CheckPartnerWorker(Batch."Run Id", Batch."Batch Id", Batch."Node Code", BatchJson);
  end;

  procedure CheckSkipped(Batch: Record "BCSF Batch")
  var
    Entry: Record "BCSF Generated Record";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
  begin
    if not Dispatcher.UsesIsolation(Batch."Run Id") or (Batch."First Key" <> Batch."Last Key") or
      not (Batch."Node Code" in ['SALES.QUOTE', 'SALES.BLANKET', 'SALES.ORDER', 'SALES.INVOICE', 'PURCHASE.ORDER']) or
      not (Batch."Skip Reason Code" in ['CUSTOMER', 'VENDOR', 'ITEM', 'DIMENSION', 'SOURCE']) then
      Error(CoverageErr);
    Batch.TestField("Skipped Units", 1);
    Batch.TestField("Processed Units", 0);
    Batch.TestField("Created Records", 0);
    Entry.SetRange("Batch Id", Batch."Batch Id");
    if not Entry.IsEmpty() then
      Error(CoverageErr);
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Partner Rules", 'OnCheckExecutingBatch', '', false, false)]
  local procedure CheckPartnerWorker(RunId: Guid; BatchId: Guid; NodeCode: Code[30]; Batch: JsonObject)
  var
    StoredBatch: Record "BCSF Batch";
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    Job: Record "Job Queue Entry";
    Execution: Record "BCSF Run Execution";
    Active: Record "Active Session";
    Contract: Codeunit "BCSF Contract JSON";
    Guard: Codeunit "BCSF Environment Guard";
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    CheckEnvironment(RunId, CompanyName());
    if GuiAllowed() then
      Error(StateErr);
    StoredBatch.LockTable();
    StoredBatch.Get(BatchId);
    StoredBatch.TestField("Run Id", RunId);
    StoredBatch.TestField("Node Code", NodeCode);
    StoredBatch.TestField(Status, StoredBatch.Status::Running);
    Header.Get(RunId);
    Step.Get(RunId, NodeCode);
    Guard.EnsureCanGenerate(Header."Company Name", Step."Process Mode",
      Step."Work Units", StoredBatch."Last Key" - StoredBatch."First Key" + 1, Manager.HasSalesPostingApproval(RunId, NodeCode));
    StoredBatch.TestField("Batch Key", Contract.GetText(Batch, 'batchKey'));
    StoredBatch.TestField("First Key", Contract.GetInteger(Batch, 'firstKey'));
    StoredBatch.TestField("Last Key", Contract.GetInteger(Batch, 'lastKey'));
    StoredBatch.TestField("Worker Session Id", SessionId());
    StoredBatch.TestField("Worker Server Id", ServiceInstanceId());
    Execution.Get(RunId);
    Execution.TestField(Status, Execution.Status::Running);
    Execution.TestField("Job Queue Entry Id", StoredBatch."Job Queue Entry Id");
    Job.Get(StoredBatch."Job Queue Entry Id");
    Job.TestField(Status, Job.Status::"In Process");
    Job.TestField("Object Type to Run", Job."Object Type to Run"::Codeunit);
    Job.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
    Job.TestField("Job Queue Category Code", 'BCSF.SER');
    Job.TestField("Recurring Job", false);
    Job.TestField("Maximum No. of Attempts to Run", 0);
    if Job."Record ID to Process" <> StoredBatch.RecordId() then
      Error(StateErr);
    Active.SecurityFiltering(SecurityFilter::Disallowed);
    Active.SetRange("Server Instance ID", ServiceInstanceId());
    Active.SetRange("Session ID", SessionId());
    Active.FindFirst();
    StoredBatch.TestField("Worker Session Guid", Active."Session Unique ID");
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Master Data Source", 'OnCheckSource', '', false, false)]
  local procedure CheckMasterSource(SourceId: Guid; var Confirmed: Boolean)
  var
    Execution: Record "BCSF Run Execution";
    Step: Record "BCSF Run Step";
    Batch: Record "BCSF Batch";
    Checkpoint: Record "BCSF Batch Checkpoint";
    Contract: Codeunit "BCSF Contract JSON";
    Envelope: JsonObject;
    Node: Text;
    Nodes: List of [Text];
    Units: Integer;
  begin
    Execution.SecurityFiltering(SecurityFilter::Disallowed);
    Execution.Get(SourceId);
    if not (Execution.Status in [Execution.Status::Completed, Execution.Status::CompletedWithWarnings,
      Execution.Status::Failed, Execution.Status::ValidationFailed]) then
      Error(StateErr);
    Batch.SetRange("Run Id", SourceId);
    Batch.SetRange(Status, Batch.Status::Running);
    if not Batch.IsEmpty() then
      Error(StateErr);
    Nodes.Add('CUSTOMER');
    Nodes.Add('VENDOR');
    Nodes.Add('ITEM');
    foreach Node in Nodes do begin
      Step.Get(SourceId, CopyStr(Node, 1, 30));
      Step.TestField("Work Units");
      Batch.Reset();
      Batch.SecurityFiltering(SecurityFilter::Disallowed);
      Batch.SetRange("Run Id", SourceId);
      Batch.SetRange("Node Code", Node);
      if not Batch.FindSet() then
        Error(CoverageErr);
      Units := 0;
      repeat
        Batch.TestField(Status, Batch.Status::Completed);
        Checkpoint.Get(Batch."Batch Id");
        Checkpoint.TestField("Run Id", SourceId);
        Checkpoint.TestField("Schema Version", 1);
        Checkpoint.TestField("Confirmed At");
        Envelope := Checkpoint.ReadStoredResult();
        if (Contract.GetInteger(Envelope, 'processedUnits') <> Batch."Processed Units") or
          not Contract.GetBoolean(Envelope, 'completed') then
          Error(CoverageErr);
        Batch.TestField("Processed Units", Batch."Last Key" - Batch."First Key" + 1);
        Units += Batch."Processed Units";
      until Batch.Next() = 0;
      if Units <> Step."Work Units" then
        Error(CoverageErr);
    end;
    Confirmed := true;
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Record Registry", 'OnCheckBatch', '', false, false)]
  local procedure CheckRegistryBatch(Entry: Record "BCSF Generated Record")
  var
    Batch: Record "BCSF Batch";
    Execution: Record "BCSF Run Execution";
  begin
    Batch.Get(Entry."Batch Id");
    Batch.TestField("Run Id", Entry."Run Id");
    Batch.TestField("Node Code", Entry."Node Code");
    Batch.TestField(Status, Batch.Status::Running);
    if (Entry."Logical Key" < Batch."First Key") or (Entry."Logical Key" > Batch."Last Key") then
      Error(CoverageErr);
    Execution.Get(Entry."Run Id");
    Execution.TestField(Status, "BCSF Run Status"::Running);
    Execution.TestField("Job Queue Entry Id", Batch."Job Queue Entry Id");
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ExecutionInsert(var Rec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    Rec.TestField(Status, "BCSF Run Status"::Preflight);
    Rec.TestField("Created At");
    Rec.TestField("Total Batches", 0);
    Rec.TestField("Completed Batches", 0);
    Rec.TestField("Started At", 0DT);
    Rec.TestField("Finished At", 0DT);
    Rec.TestField("Earliest Start", 0DT);
    if not IsNullGuid(Rec."Job Queue Entry Id") then
      Error(StateErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ExecutionModify(var Rec: Record "BCSF Run Execution"; var xRec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  var
    PreviousExecution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Control: Record "BCSF Run Control";
    Writer: Codeunit "BCSF Plan Writer";
    StateManagement: Codeunit "BCSF Run State Mgt";
    Validation: Codeunit "BCSF Validation Manager";
    Severity: Enum "BCSF Validation Severity";
    Valid: Boolean;
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    // Table modify events do not reliably carry the persisted values in xRec.
    PreviousExecution.LockTable();
    PreviousExecution.Get(Rec."Run Id");
    Rec.TestField("Run Id", PreviousExecution."Run Id");
    Rec.TestField("Created At", PreviousExecution."Created At");
    StateManagement.CheckTransition(PreviousExecution.Status, Rec.Status);
    case PreviousExecution.Status of
      "BCSF Run Status"::Preflight: Valid := Rec.Status = "BCSF Run Status"::Ready;
      "BCSF Run Status"::Ready: Valid := Rec.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled, "BCSF Run Status"::Paused, "BCSF Run Status"::Cancelled];
      "BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled: Valid := Rec.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::Failed, "BCSF Run Status"::Paused, "BCSF Run Status"::Cancelled];
      "BCSF Run Status"::Running: Valid := Rec.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::ValidationFailed, "BCSF Run Status"::Failed, "BCSF Run Status"::Paused, "BCSF Run Status"::Cancelled];
      "BCSF Run Status"::Paused: Valid := Rec.Status in ["BCSF Run Status"::ResumePending, "BCSF Run Status"::Cancelled];
      "BCSF Run Status"::Failed: Valid := Rec.Status in ["BCSF Run Status"::Failed, "BCSF Run Status"::ResumePending, "BCSF Run Status"::Cancelled];
      "BCSF Run Status"::ResumePending: Valid := Rec.Status in ["BCSF Run Status"::Preflight, "BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::ValidationFailed];
      "BCSF Run Status"::Cancelled: Valid := Rec.Status = "BCSF Run Status"::Cancelled;
    end;
    if not Valid then
      Error(StateErr);
    Batch.SetRange("Run Id", Rec."Run Id");
    if (Rec."Total Batches" <> Batch.Count()) or (Rec."Total Batches" <= 0) then
      Error(StateErr);
    Batch.SetRange(Status, Batch.Status::Completed);
    if Rec."Completed Batches" <> Batch.Count() then
      Error(StateErr);
    if Rec.Status = "BCSF Run Status"::Ready then begin
      Writer.CheckExecution(Rec."Run Id");
      CheckPlanCoverage(Rec."Run Id");
    end;
    if PreviousExecution.Status <> "BCSF Run Status"::Ready then
      Rec.TestField("Earliest Start", PreviousExecution."Earliest Start");
    if not (PreviousExecution.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled]) then
      Rec.TestField("Started At", PreviousExecution."Started At");
    if not (Rec.Status in ["BCSF Run Status"::Failed, "BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::ValidationFailed]) then begin
      Rec.TestField("Finished At", 0DT);
      if Rec.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled, "BCSF Run Status"::Running] then
        Rec.TestField("Job Queue Entry Id");
    end;
    if PreviousExecution.Status <> "BCSF Run Status"::Preflight then begin
      Rec.TestField("Total Batches", PreviousExecution."Total Batches");
      if Rec."Completed Batches" < PreviousExecution."Completed Batches" then
        Error(StateErr);
    end;
    if Rec.Status in ["BCSF Run Status"::Paused, "BCSF Run Status"::Cancelled] then begin
      Control.Get(Rec."Run Id");
      if Rec.Status = "BCSF Run Status"::Cancelled then
        Control.TestField("Cancel Requested", true)
      else
        Control.TestField("Pause Requested", true);
      Batch.Reset();
      Batch.SetRange("Run Id", Rec."Run Id");
      Batch.SetRange(Status, Batch.Status::Running);
      if not Batch.IsEmpty() or not IsNullGuid(Rec."Job Queue Entry Id") then
        Error(StateErr);
    end;
    if Rec.Status = "BCSF Run Status"::ResumePending then begin
      Control.Get(Rec."Run Id");
      Control.TestField("Cancel Requested", false);
      Control.TestField("Pause Requested", false);
    end;
    if Rec.Status = "BCSF Run Status"::Running then
      Rec.TestField("Started At");
    if Rec.Status in ["BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::ValidationFailed] then begin
      Rec.TestField("Completed Batches", Rec."Total Batches");
      Rec.TestField("Finished At");
      if not IsNullGuid(Rec."Job Queue Entry Id") or not Validation.GetSummary(Rec."Run Id", Severity) then
        Error(StateErr);
      case Severity of
        Severity::Passed: Rec.TestField(Status, Rec.Status::Completed);
        Severity::Warning: Rec.TestField(Status, Rec.Status::CompletedWithWarnings);
        Severity::Error: Rec.TestField(Status, Rec.Status::ValidationFailed);
      end;
    end;
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnBeforeInsertEvent', '', false, false)]
  local procedure BatchInsert(var Rec: Record "BCSF Batch"; RunTrigger: Boolean)
  var
    Step: Record "BCSF Run Step";
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    Header.Get(Rec."Run Id");
    Step.Get(Rec."Run Id", Rec."Node Code");
    Execution.Get(Rec."Run Id");
    Execution.TestField(Status, "BCSF Run Status"::Preflight);
    Rec.TestField("Batch Id");
    Rec.TestField("Batch Key");
    Rec.TestField(Status, Rec.Status::Pending);
    Rec.TestField("Schedule Attempts", 0);
    Rec.TestField("Worker Session Id", 0);
    Rec.TestField("Worker Server Id", 0);
    if not IsNullGuid(Rec."Worker Session Guid") or not IsNullGuid(Rec."Previous Job Id") then
      Error(StateErr);
    Rec.TestField("Processed Units", 0);
    Rec.TestField("Created Records", 0);
    Rec.TestField("Skipped Units", 0);
    Rec.TestField("Skip Reason Code", '');
    Rec.TestField("Started At", 0DT);
    Rec.TestField("Finished At", 0DT);
    if not IsNullGuid(Rec."Job Queue Entry Id") or (Rec."Sequence No." <= 0) or
      (Rec."First Key" <= 0) or (Rec."Last Key" < Rec."First Key") or
      (Rec."Last Key" > Step."Work Units") or (Rec."Last Key" - Rec."First Key" + 1 > Header."Batch Size")
    then
      Error(StateErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnBeforeModifyEvent', '', false, false)]
  local procedure BatchModify(var Rec: Record "BCSF Batch"; var xRec: Record "BCSF Batch"; RunTrigger: Boolean)
  var
    PreviousBatch: Record "BCSF Batch";
    Recovery: Codeunit "BCSF Batch Recovery";
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    // Table modify events do not reliably carry the persisted values in xRec.
    PreviousBatch.LockTable();
    PreviousBatch.Get(Rec."Batch Id");
    Rec.TestField("Batch Id", PreviousBatch."Batch Id");
    Rec.TestField("Run Id", PreviousBatch."Run Id");
    Rec.TestField("Node Code", PreviousBatch."Node Code");
    Rec.TestField("Sequence No.", PreviousBatch."Sequence No.");
    Rec.TestField("Batch Key", PreviousBatch."Batch Key");
    Rec.TestField("First Key", PreviousBatch."First Key");
    Rec.TestField("Last Key", PreviousBatch."Last Key");
    Recovery.CheckBatchChange(Rec, PreviousBatch);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure BatchDelete(var Rec: Record "BCSF Batch"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnBeforeRenameEvent', '', false, false)]
  local procedure BatchRename(var Rec: Record "BCSF Batch"; var xRec: Record "BCSF Batch"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ExecutionDelete(var Rec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ExecutionRename(var Rec: Record "BCSF Run Execution"; var xRec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  local procedure CheckPlanCoverage(RunId: Guid)
  var
    Step: Record "BCSF Run Step";
    Batch: Record "BCSF Batch";
    Recovery: Codeunit "BCSF Batch Recovery";
    LastKey: Integer;
    SequenceNo: Integer;
  begin
    SequenceNo := 0;
    Step.SetCurrentKey("Run Id", "Sequence No.", "Node Code");
    Step.SetRange("Run Id", RunId);
    if Step.FindSet() then
      repeat
        LastKey := 0;
        Batch.Reset();
        Batch.SetCurrentKey("Run Id", "Sequence No.");
        Batch.SetRange("Run Id", RunId);
        Batch.SetRange("Node Code", Step."Node Code");
        if Batch.FindSet() then
          repeat
            if LastKey >= Step."Work Units" then
              Error(CoverageErr);
            SequenceNo += 1;
            if (Batch."Sequence No." <> SequenceNo) or (Batch."First Key" <> LastKey + 1) or
              not (Batch.Status in [Batch.Status::Pending, Batch.Status::Completed])
            then
              Error(CoverageErr);
            if Batch.Status = Batch.Status::Completed then
              Recovery.VerifyCheckpoint(Batch."Batch Id")
            else
              if not IsNullGuid(Batch."Job Queue Entry Id") then
                Error(CoverageErr);
            LastKey := Batch."Last Key";
          until Batch.Next() = 0;
        if LastKey <> Step."Work Units" then
          Error(CoverageErr);
      until Step.Next() = 0;
  end;

  var
    StateErr: Label 'The execution or batch state is inconsistent. Stop and review the saved work; do not retry it automatically.';
    ImmutableErr: Label 'Saved execution identity and batch plans cannot be changed, deleted or renamed.';
    CoverageErr: Label 'The batch results do not cover every planned logical unit with matching immutable provenance.';
}
