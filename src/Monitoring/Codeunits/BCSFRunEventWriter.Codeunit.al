namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Lifecycle;

codeunit 90357 "BCSF Run Event Writer"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Event" = I;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnAfterInsertEvent', '', false, false)]
  local procedure ExecutionInserted(var Rec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      RecordExecution(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Execution", 'OnAfterModifyEvent', '', false, false)]
  local procedure ExecutionChanged(var Rec: Record "BCSF Run Execution"; var xRec: Record "BCSF Run Execution"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      if Rec.Status <> xRec.Status then
        RecordExecution(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnAfterInsertEvent', '', false, false)]
  local procedure BatchInserted(var Rec: Record "BCSF Batch"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      RecordBatch(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch", 'OnAfterModifyEvent', '', false, false)]
  local procedure BatchChanged(var Rec: Record "BCSF Batch"; var xRec: Record "BCSF Batch"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      if (Rec.Status <> xRec.Status) or (Rec."Job Queue Entry Id" <> xRec."Job Queue Entry Id") then
        RecordBatch(Rec);
  end;

  local procedure RecordExecution(Execution: Record "BCSF Run Execution")
  var
    Entry: Record "BCSF Run Event";
  begin
    Entry.Init();
    Entry."Entry Id" := CreateGuid();
    Entry."Run Id" := Execution."Run Id";
    Entry."Occurred At" := CurrentDateTime();
    Entry."Run Status" := Execution.Status;
    Entry."Job Queue Entry Id" := Execution."Job Queue Entry Id";
    Entry.Insert(true);
  end;

  local procedure RecordBatch(Batch: Record "BCSF Batch")
  var
    Entry: Record "BCSF Run Event";
  begin
    Entry.Init();
    Entry."Entry Id" := CreateGuid();
    Entry."Run Id" := Batch."Run Id";
    Entry."Batch Id" := Batch."Batch Id";
    Entry."Node Code" := Batch."Node Code";
    Entry."Occurred At" := CurrentDateTime();
    Entry."Batch Status" := Batch.Status;
    Entry."Job Queue Entry Id" := Batch."Job Queue Entry Id";
    Entry."Processed Units" := Batch."Processed Units";
    Entry."Created Records" := Batch."Created Records";
    Entry.Insert(true);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Event", 'OnBeforeInsertEvent', '', false, false)]
  local procedure CheckInsert(var Rec: Record "BCSF Run Event"; RunTrigger: Boolean)
  var
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if Rec.IsTemporary() then
      exit;
    Guard.EnsureCanConfigure(Rec.CurrentCompany());
    Rec.TestField("Entry Id");
    Rec.TestField("Occurred At");
    if IsNullGuid(Rec."Batch Id") then begin
      Execution.Get(Rec."Run Id");
      Rec.TestField("Run Status", Execution.Status);
      Rec.TestField("Job Queue Entry Id", Execution."Job Queue Entry Id");
      Rec.TestField("Node Code", '');
      Rec.TestField("Processed Units", 0);
      Rec.TestField("Created Records", 0);
    end else begin
      Batch.Get(Rec."Batch Id");
      Rec.TestField("Run Id", Batch."Run Id");
      Rec.TestField("Node Code", Batch."Node Code");
      Rec.TestField("Batch Status", Batch.Status);
      Rec.TestField("Job Queue Entry Id", Batch."Job Queue Entry Id");
      Rec.TestField("Processed Units", Batch."Processed Units");
      Rec.TestField("Created Records", Batch."Created Records");
    end;
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Event", 'OnBeforeModifyEvent', '', false, false)]
  local procedure BlockModify(var Rec: Record "BCSF Run Event"; var xRec: Record "BCSF Run Event"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Event", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure BlockDelete(var Rec: Record "BCSF Run Event"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Event", 'OnBeforeRenameEvent', '', false, false)]
  local procedure BlockRename(var Rec: Record "BCSF Run Event"; var xRec: Record "BCSF Run Event"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  var
    ImmutableErr: Label 'Monitoring events cannot be changed, deleted or renamed.';
}
