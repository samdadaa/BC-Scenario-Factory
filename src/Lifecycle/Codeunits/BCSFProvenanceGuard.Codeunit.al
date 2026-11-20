namespace BCScenarioFactory.Lifecycle;

using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;

codeunit 90379 "BCSF Provenance Guard"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Generated Record", 'OnBeforeInsertEvent', '', false, false)]
  local procedure CheckInsert(var Rec: Record "BCSF Generated Record"; RunTrigger: Boolean)
  var
    Step: Record "BCSF Run Step";
    Guard: Codeunit "BCSF Environment Guard";
    Manager: Codeunit "BCSF Scenario Manager";
    Registry: Codeunit "BCSF Record Registry";
  begin
    if Rec.IsTemporary() then
      exit;
    Step.Get(Rec."Run Id", Rec."Node Code");
    // Other generators receive no posting approval from the SF-021 contract.
    Guard.EnsureCanGenerate(Rec.CurrentCompany(), Step."Process Mode", Step."Work Units", 1, Manager.HasSalesPostingApproval(Rec."Run Id", Step."Node Code"));
    Registry.CheckEntry(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Generated Record", 'OnBeforeModifyEvent', '', false, false)]
  local procedure BlockModify(var Rec: Record "BCSF Generated Record"; var xRec: Record "BCSF Generated Record"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Generated Record", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure BlockDelete(var Rec: Record "BCSF Generated Record"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Generated Record", 'OnBeforeRenameEvent', '', false, false)]
  local procedure BlockRename(var Rec: Record "BCSF Generated Record"; var xRec: Record "BCSF Generated Record"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  var
    ImmutableErr: Label 'Provenance entries cannot be changed, deleted or renamed. Investigate the existing result before any retry.';
}
