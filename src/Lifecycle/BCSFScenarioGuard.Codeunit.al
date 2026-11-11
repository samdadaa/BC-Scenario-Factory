namespace BCScenarioFactory.Lifecycle;

using BCScenarioFactory.ScenarioManagement;

codeunit 90377 "BCSF Scenario Guard"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ScenarioInsert(var Rec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ScenarioModify(var Rec: Record "BCSF Scenario"; var xRec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ScenarioDelete(var Rec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ScenarioRename(var Rec: Record "BCSF Scenario"; var xRec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ScenarioModuleInsert(var Rec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ScenarioModuleModify(var Rec: Record "BCSF Scenario Module"; var xRec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ScenarioModuleDelete(var Rec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ScenarioModuleRename(var Rec: Record "BCSF Scenario Module"; var xRec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeInsertEvent', '', false, false)]
  local procedure DataTargetInsert(var Rec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeModifyEvent', '', false, false)]
  local procedure DataTargetModify(var Rec: Record "BCSF Data Target"; var xRec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure DataTargetDelete(var Rec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeRenameEvent', '', false, false)]
  local procedure DataTargetRename(var Rec: Record "BCSF Data Target"; var xRec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeInsertEvent', '', false, false)]
  local procedure RunHeaderInsert(var Rec: Record "BCSF Run Header"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeModifyEvent', '', false, false)]
  local procedure RunHeaderModify(var Rec: Record "BCSF Run Header"; var xRec: Record "BCSF Run Header"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure RunHeaderDelete(var Rec: Record "BCSF Run Header"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeRenameEvent', '', false, false)]
  local procedure RunHeaderRename(var Rec: Record "BCSF Run Header"; var xRec: Record "BCSF Run Header"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeInsertEvent', '', false, false)]
  local procedure RunSnapshotInsert(var Rec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeModifyEvent', '', false, false)]
  local procedure RunSnapshotModify(var Rec: Record "BCSF Run Snapshot"; var xRec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure RunSnapshotDelete(var Rec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeRenameEvent', '', false, false)]
  local procedure RunSnapshotRename(var Rec: Record "BCSF Run Snapshot"; var xRec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not Rec.IsTemporary() then
      Guard.EnsureCanConfigure(Rec.CurrentCompany());
  end;

}
