namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Environment;

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
    Batch: Record "BCSF Batch";
    Writer: Codeunit "BCSF Plan Writer";
    StateManagement: Codeunit "BCSF Run State Mgt";
    Mutable: List of [Integer];
    Valid: Boolean;
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    Mutable.Add(Rec.FieldNo(Status));
    Mutable.Add(Rec.FieldNo("Earliest Start"));
    Mutable.Add(Rec.FieldNo("Job Queue Entry Id"));
    Mutable.Add(Rec.FieldNo("Started At"));
    Mutable.Add(Rec.FieldNo("Finished At"));
    Mutable.Add(Rec.FieldNo("Total Batches"));
    Mutable.Add(Rec.FieldNo("Completed Batches"));
    CheckImmutable(Rec, xRec, Mutable);
    StateManagement.CheckTransition(xRec.Status, Rec.Status);
    case xRec.Status of
      "BCSF Run Status"::Preflight: Valid := Rec.Status = "BCSF Run Status"::Ready;
      "BCSF Run Status"::Ready: Valid := Rec.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled];
      "BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled: Valid := Rec.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::Failed];
      "BCSF Run Status"::Running: Valid := Rec.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::Failed];
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
      Rec.TestField("Completed Batches", 0);
    end;
    if xRec.Status <> "BCSF Run Status"::Ready then
      Rec.TestField("Earliest Start", xRec."Earliest Start");
    if not (xRec.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled]) then
      Rec.TestField("Started At", xRec."Started At");
    if not (Rec.Status in ["BCSF Run Status"::Failed, "BCSF Run Status"::CompletedWithWarnings]) then begin
      Rec.TestField("Finished At", 0DT);
      if Rec.Status <> "BCSF Run Status"::Ready then
        Rec.TestField("Job Queue Entry Id");
    end;
    if xRec.Status <> "BCSF Run Status"::Preflight then begin
      Rec.TestField("Total Batches", xRec."Total Batches");
      if Rec."Completed Batches" < xRec."Completed Batches" then
        Error(StateErr);
    end;
    if Rec.Status = "BCSF Run Status"::Running then
      Rec.TestField("Started At");
    if Rec.Status = "BCSF Run Status"::CompletedWithWarnings then begin
      Rec.TestField("Completed Batches", Rec."Total Batches");
      Rec.TestField("Finished At");
      if not IsNullGuid(Rec."Job Queue Entry Id") then
        Error(StateErr);
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
    Rec.TestField("Processed Units", 0);
    Rec.TestField("Created Records", 0);
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
    Mutable: List of [Integer];
    Valid: Boolean;
  begin
    if Rec.IsTemporary() then
      exit;
    CheckEnvironment(Rec."Run Id", Rec.CurrentCompany());
    Mutable.Add(Rec.FieldNo(Status));
    Mutable.Add(Rec.FieldNo("Job Queue Entry Id"));
    Mutable.Add(Rec.FieldNo("Started At"));
    Mutable.Add(Rec.FieldNo("Finished At"));
    Mutable.Add(Rec.FieldNo("Processed Units"));
    Mutable.Add(Rec.FieldNo("Created Records"));
    CheckImmutable(Rec, xRec, Mutable);
    case xRec.Status of
      xRec.Status::Pending: Valid := Rec.Status in [Rec.Status::Pending, Rec.Status::Running, Rec.Status::Failed];
      xRec.Status::Running: Valid := Rec.Status in [Rec.Status::Completed, Rec.Status::NeedsReview];
    end;
    if not Valid then
      Error(StateErr);
    if not IsNullGuid(xRec."Job Queue Entry Id") then
      Rec.TestField("Job Queue Entry Id", xRec."Job Queue Entry Id");
    if xRec.Status = xRec.Status::Running then
      Rec.TestField("Started At", xRec."Started At");
    if Rec.Status <> Rec.Status::Completed then
      Rec.TestField("Finished At", xRec."Finished At");
    if Rec.Status = Rec.Status::Running then begin
      xRec.TestField("Job Queue Entry Id");
      Rec.TestField("Started At");
      Rec.TestField("Job Queue Entry Id");
    end;
    if Rec.Status = Rec.Status::Completed then begin
      Rec.TestField("Finished At");
      CheckCoverage(Rec);
    end else
      if (Rec."Processed Units" <> 0) or (Rec."Created Records" <> 0) then
        Error(StateErr);
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
              (Batch.Status <> Batch.Status::Pending) or not IsNullGuid(Batch."Job Queue Entry Id")
            then
              Error(CoverageErr);
            LastKey := Batch."Last Key";
          until Batch.Next() = 0;
        if LastKey <> Step."Work Units" then
          Error(CoverageErr);
      until Step.Next() = 0;
  end;

  local procedure CheckImmutable(NewRecord: Variant; OldRecord: Variant; Mutable: List of [Integer])
  var
    NewRef: RecordRef;
    OldRef: RecordRef;
    NewField: FieldRef;
    OldField: FieldRef;
    Index: Integer;
  begin
    NewRef.GetTable(NewRecord);
    OldRef.GetTable(OldRecord);
    for Index := 1 to NewRef.FieldCount() do begin
      NewField := NewRef.FieldIndex(Index);
      if (NewField.Number < 2000000000) and not Mutable.Contains(NewField.Number) then begin
        OldField := OldRef.Field(NewField.Number);
        if NewField.Value <> OldField.Value then
          Error(ImmutableErr);
      end;
    end;
  end;

  var
    StateErr: Label 'The execution or batch state is inconsistent. Stop and review the saved work; do not retry it automatically.';
    ImmutableErr: Label 'Saved execution identity and batch plans cannot be changed, deleted or renamed.';
    CoverageErr: Label 'The batch results do not cover every planned logical unit with matching immutable provenance.';
}
