namespace BCScenarioFactory.Validation;

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

  var
    NotValidatedLbl: Label 'Not validated';
}
