namespace BCScenarioFactory.Validation;

using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;

codeunit 90326 "BCSF Validation Manager"
{
  Access = Internal;
  Permissions = tabledata "BCSF Validation Result" = I;

  procedure RecordCheck(RunId: Guid; BatchId: Guid; NodeCode: Code[30]; RuleCode: Code[30]; Severity: Enum "BCSF Validation Severity"; Expected: Integer; Reported: Integer)
  var
    Result: Record "BCSF Validation Result";
  begin
    Result.Init();
    Result."Run Id" := RunId;
    Result."Batch Id" := BatchId;
    Result."Node Code" := NodeCode;
    Result."Rule Code" := RuleCode;
    Result.Severity := Severity;
    Result."Checked At" := CurrentDateTime();
    Result."Expected Units" := Expected;
    Result."Reported Units" := Reported;
    Result.Insert(true);
  end;

  procedure GetSummary(RunId: Guid; var Severity: Enum "BCSF Validation Severity"): Boolean
  var
    Result: Record "BCSF Validation Result";
    NoBatch: Guid;
  begin
    if not Result.Get(RunId, NoBatch, 'RUN') then
      exit(false);
    Severity := Result.Severity;
    exit(true);
  end;

  procedure Describe(RunId: Guid): Text
  var
    Severity: Enum "BCSF Validation Severity";
  begin
    if GetSummary(RunId, Severity) then
      exit(Format(Severity));
    exit(NotValidatedLbl);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Validation Result", 'OnBeforeInsertEvent', '', false, false)]
  local procedure CheckInsert(var Rec: Record "BCSF Validation Result"; RunTrigger: Boolean)
  var
    Header: Record "BCSF Run Header";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if Rec.IsTemporary() then
      exit;
    Guard.EnsureCanConfigure(Rec.CurrentCompany());
    Header.LockTable();
    Header.Get(Rec."Run Id");
    Header.TestField("Company Name", CompanyName());
    Rec.TestField("Rule Code");
    Rec.TestField("Checked At");
    if not (Rec.Severity in [Rec.Severity::Passed, Rec.Severity::Warning, Rec.Severity::Error]) or
      (Rec."Expected Units" < 0) or (Rec."Reported Units" < 0)
    then
      Error(InvalidResultErr);
    OnCheckResult(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Validation Result", 'OnBeforeModifyEvent', '', false, false)]
  local procedure CheckModify(var Rec: Record "BCSF Validation Result"; var xRec: Record "BCSF Validation Result"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(InvalidResultErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Validation Result", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure CheckDelete(var Rec: Record "BCSF Validation Result"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(InvalidResultErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Validation Result", 'OnBeforeRenameEvent', '', false, false)]
  local procedure CheckRename(var Rec: Record "BCSF Validation Result"; var xRec: Record "BCSF Validation Result"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(InvalidResultErr);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnCheckResult(Result: Record "BCSF Validation Result")
  begin
  end;

  var
    InvalidResultErr: Label 'Validation results must be valid, append-only evidence for the current run.';
    NotValidatedLbl: Label 'Not validated';
}
