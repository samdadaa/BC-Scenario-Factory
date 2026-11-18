namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Environment;

codeunit 90315 "BCSF Recovery Rules"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Control", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ControlInsert(var Rec: Record "BCSF Run Control"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      CheckControl(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Control", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ControlModify(var Rec: Record "BCSF Run Control"; var xRec: Record "BCSF Run Control"; RunTrigger: Boolean)
  var
    Execution: Record "BCSF Run Execution";
    PreviousControl: Record "BCSF Run Control";
  begin
    if Rec.IsTemporary() then
      exit;
    CheckControl(Rec);
    PreviousControl.LockTable();
    PreviousControl.Get(Rec."Run Id");
    Rec.TestField("Run Id", PreviousControl."Run Id");
    if PreviousControl."Cancel Requested" and not Rec."Cancel Requested" then
      Error(ImmutableErr);
    if PreviousControl."Pause Requested" and not Rec."Pause Requested" then begin
      Execution.ReadIsolation(IsolationLevel::ReadUncommitted);
      Execution.Get(Rec."Run Id");
      if not (Execution.Status in ["BCSF Run Status"::Paused, "BCSF Run Status"::Failed]) then
        Error(ImmutableErr);
    end;
  end;

  local procedure CheckControl(Control: Record "BCSF Run Control")
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Guard: Codeunit "BCSF Environment Guard";
    Environment: Codeunit "Environment Information";
  begin
    // No execution/header update lock here: requests must not wait for the fachliche batch lock.
    Guard.EnsureCanConfigure(Control.CurrentCompany());
    Header.Get(Control."Run Id");
    Header.TestField("Company Name", CompanyName());
    Header.TestField("Environment Name", Environment.GetEnvironmentName());
    Execution.ReadIsolation(IsolationLevel::ReadUncommitted);
    Execution.Get(Control."Run Id");
    Control.TestField("Requested At");
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Control", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ControlDelete(var Rec: Record "BCSF Run Control"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Control", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ControlRename(var Rec: Record "BCSF Run Control"; var xRec: Record "BCSF Run Control"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch Checkpoint", 'OnBeforeInsertEvent', '', false, false)]
  local procedure CheckpointInsert(var Rec: Record "BCSF Batch Checkpoint"; RunTrigger: Boolean)
  var
    Batch: Record "BCSF Batch";
    Recovery: Codeunit "BCSF Batch Recovery";
  begin
    if Rec.IsTemporary() then
      exit;
    Batch.Get(Rec."Batch Id");
    Batch.TestField(Status, Batch.Status::Running);
    Recovery.CheckCheckpoint(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch Checkpoint", 'OnBeforeModifyEvent', '', false, false)]
  local procedure CheckpointModify(var Rec: Record "BCSF Batch Checkpoint"; var xRec: Record "BCSF Batch Checkpoint"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch Checkpoint", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure CheckpointDelete(var Rec: Record "BCSF Batch Checkpoint"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Batch Checkpoint", 'OnBeforeRenameEvent', '', false, false)]
  local procedure CheckpointRename(var Rec: Record "BCSF Batch Checkpoint"; var xRec: Record "BCSF Batch Checkpoint"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  var
    ImmutableErr: Label 'Control identities, cancellation requests and confirmed checkpoints cannot be removed or rewritten. Resume only through the guarded recovery actions.';
}
