namespace BCScenarioFactory.SetupManager;

table 90225 "BCSF Setup Diff"
{
  Access = Internal;
  TableType = Temporary;
  Caption = 'Setup Diff';
  DataClassification = SystemMetadata;
  fields
  {
    field(1; "Entry No."; Integer)
    {
      Caption = 'Entry No.';
      ToolTip = 'Specifies the temporary finding number.';
    }
    field(2; "Requirement"; Text[150])
    {
      Caption = 'Requirement';
      ToolTip = 'Specifies the prerequisite being checked.';
    }
    field(3; "Blocked"; Boolean)
    {
      Caption = 'Blocked';
      ToolTip = 'Specifies whether this finding prevents execution.';
    }
    field(4; "Finding"; Text[250])
    {
      Caption = 'Finding';
      ToolTip = 'Specifies the result without exposing business data.';
    }
    field(5; "Action"; Text[250])
    {
      Caption = 'Proposed Action';
      ToolTip = 'Specifies the manual action to review and authorize before changing setup.';
    }
  }
  keys
  {
    key(PK; "Entry No.") { Clustered = true; }
  }
}
