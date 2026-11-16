namespace BCScenarioFactory.Validation;

table 90325 "BCSF Validation Result"
{
  Access = Internal;
  DataClassification = SystemMetadata;
  Caption = 'Validation Result';

  fields
  {
    field(1; "Run Id"; Guid) { Caption = 'Run Id'; ToolTip = 'Specifies the captured run.'; }
    field(2; "Batch Id"; Guid) { Caption = 'Batch Id'; ToolTip = 'Specifies the validated batch. An empty ID identifies the run summary.'; }
    field(3; "Rule Code"; Code[30]) { Caption = 'Rule Code'; ToolTip = 'Specifies the stable technical validation rule.'; }
    field(4; Severity; Enum "BCSF Validation Severity") { Caption = 'Severity'; ToolTip = 'Specifies whether the check passed, issued a warning or failed.'; }
    field(5; "Node Code"; Code[30]) { Caption = 'Node Code'; ToolTip = 'Specifies the planned step associated with the check.'; }
    field(6; "Checked At"; DateTime) { Caption = 'Checked At'; ToolTip = 'Specifies when the check was recorded.'; }
    field(7; "Expected Units"; Integer) { Caption = 'Expected Units'; ToolTip = 'Specifies the expected logical units for this batch.'; }
    field(8; "Reported Units"; Integer) { Caption = 'Reported Units'; ToolTip = 'Specifies the recorded logical units before this check.'; }
  }
  keys
  {
    key(PK; "Run Id", "Batch Id", "Rule Code") { Clustered = true; }
  }
}
