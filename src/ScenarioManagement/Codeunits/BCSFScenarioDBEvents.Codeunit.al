namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

codeunit 90145 "BCSF Scenario DB Events"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ScenarioInsert(var Rec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    Rec.Revision := 1;
    Policy.ValidateScenario(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ScenarioModify(var Rec: Record "BCSF Scenario"; var xRec: Record "BCSF Scenario"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    if xRec.Revision = 2147483647 then
      Error(RevisionErr);
    Rec.Revision := xRec.Revision + 1;
    Policy.ValidateScenario(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ScenarioDelete(var Rec: Record "BCSF Scenario"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ScenarioRename(var Rec: Record "BCSF Scenario"; var xRec: Record "BCSF Scenario"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeInsertEvent', '', false, false)]
  local procedure ScenarioModuleInsert(var Rec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    Policy.ValidateModule(Rec);
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ScenarioModuleModify(var Rec: Record "BCSF Scenario Module"; var xRec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    Policy.ValidateModule(Rec);
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure ScenarioModuleDelete(var Rec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    Policy.CheckModuleRemoval(Rec);
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Scenario Module", 'OnBeforeRenameEvent', '', false, false)]
  local procedure ScenarioModuleRename(var Rec: Record "BCSF Scenario Module"; var xRec: Record "BCSF Scenario Module"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeInsertEvent', '', false, false)]
  local procedure DataTargetInsert(var Rec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    Policy.ValidateTarget(Rec);
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeModifyEvent', '', false, false)]
  local procedure DataTargetModify(var Rec: Record "BCSF Data Target"; var xRec: Record "BCSF Data Target"; RunTrigger: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    Policy.ValidateTarget(Rec);
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure DataTargetDelete(var Rec: Record "BCSF Data Target"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    LockScenario(Rec."Scenario Id", Rec.CurrentCompany());
    TouchScenario(Rec."Scenario Id", Rec.CurrentCompany());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Data Target", 'OnBeforeRenameEvent', '', false, false)]
  local procedure DataTargetRename(var Rec: Record "BCSF Data Target"; var xRec: Record "BCSF Data Target"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeInsertEvent', '', false, false)]
  local procedure RunHeaderInsert(var Rec: Record "BCSF Run Header"; RunTrigger: Boolean)
  var
    Scenario: Record "BCSF Scenario";
  begin
    if Rec.IsTemporary() then
      exit;
    if IsNullGuid(Rec."Run Id") then
      Error(SnapshotErr);
    Scenario.Get(Rec."Scenario Id");
    if (Rec."Scenario Revision" <> Scenario.Revision) or (Rec."Schema Version" <> 1) then
      Error(SnapshotErr);
    if Rec.Status <> "BCSF Run Status"::Draft then
      Error(SnapshotErr);
    if not (Rec."Data Language" in ["BCSF Data Language"::German, "BCSF Data Language"::English]) then
      Error(SnapshotErr);
    Rec.TestField("Created At");
    Rec.TestField("Company Name", CompanyName());
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeModifyEvent', '', false, false)]
  local procedure RunHeaderModify(var Rec: Record "BCSF Run Header"; var xRec: Record "BCSF Run Header"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure RunHeaderDelete(var Rec: Record "BCSF Run Header"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Header", 'OnBeforeRenameEvent', '', false, false)]
  local procedure RunHeaderRename(var Rec: Record "BCSF Run Header"; var xRec: Record "BCSF Run Header"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeInsertEvent', '', false, false)]
  local procedure RunSnapshotInsert(var Rec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  var
    Header: Record "BCSF Run Header";
    Payload: JsonObject;
    Token: JsonToken;
  begin
    if Rec.IsTemporary() then
      exit;
    Header.Get(Rec."Run Id");
    if (Rec."Schema Version" <> 1) or not Rec.Payload.HasValue() then
      Error(SnapshotErr);
    Rec.ReadPayload(Payload);
    if not Payload.Get('schemaVersion', Token) then
      Error(SnapshotErr);
    if Token.AsValue().AsInteger() <> Rec."Schema Version" then
      Error(SnapshotErr);
    if not Payload.Get('runId', Token) then
      Error(SnapshotErr);
    if Token.AsValue().AsText() <> Format(Header."Run Id", 0, 4) then
      Error(SnapshotErr);
    if not Payload.Get('revision', Token) then
      Error(SnapshotErr);
    if Token.AsValue().AsInteger() <> Header."Scenario Revision" then
      Error(SnapshotErr);
    if not Payload.Get('dataLanguage', Token) then
      Error(SnapshotErr);
    if Token.AsValue().AsInteger() <> Header."Data Language".AsInteger() then
      Error(SnapshotErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeModifyEvent', '', false, false)]
  local procedure RunSnapshotModify(var Rec: Record "BCSF Run Snapshot"; var xRec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure RunSnapshotDelete(var Rec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Snapshot", 'OnBeforeRenameEvent', '', false, false)]
  local procedure RunSnapshotRename(var Rec: Record "BCSF Run Snapshot"; var xRec: Record "BCSF Run Snapshot"; RunTrigger: Boolean)
  begin
    if Rec.IsTemporary() then
      exit;
    Error(ImmutableErr);
  end;

  local procedure LockScenario(ScenarioId: Guid; TargetCompanyName: Text)
  var
    Scenario: Record "BCSF Scenario";
  begin
    if TargetCompanyName <> CompanyName() then
      Error(CompanyErr);
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
  end;

  local procedure TouchScenario(ScenarioId: Guid; TargetCompanyName: Text)
  var
    Scenario: Record "BCSF Scenario";
  begin
    if TargetCompanyName <> CompanyName() then
      Error(CompanyErr);
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
    if Scenario.Revision = 2147483647 then
      Error(RevisionErr);
    Scenario.Revision := Scenario.Revision + 1;
    Scenario.Modify(true);
  end;

  var
    ImmutableErr: Label 'Captured runs and snapshots cannot be changed or deleted. Template and entity keys cannot be renamed; create a copy or a new target instead.';
    RevisionErr: Label 'This template has reached its revision limit. Create a copy.';
    SnapshotErr: Label 'The captured configuration is incomplete or inconsistent. Create a new snapshot from a valid template.';
    CompanyErr: Label 'Edit scenarios only in the current approved company.';
}
