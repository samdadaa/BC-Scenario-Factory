namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90128 "BCSF Run Header"
{
  Access = Internal;
  Caption = 'Captured Run';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Run Id"; Guid)
    {
      Caption = 'Run ID';
      ToolTip = 'Specifies the stable identity of the captured run.';
    }
    field(2; "Scenario Id"; Guid)
    {
      Caption = 'Scenario ID';
      ToolTip = 'Specifies the source template identity retained after later template changes.';
    }
    field(3; "Scenario Revision"; Integer)
    {
      Caption = 'Scenario Revision';
      ToolTip = 'Specifies the captured source revision.';
    }
    field(4; "Description"; Text[100])
    {
      Caption = 'Description';
      ToolTip = 'Specifies the captured scenario description.';
    }
    field(5; "Status"; Enum "BCSF Run Status")
    {
      Caption = 'Status';
      ToolTip = 'Specifies the run state. Capturing a snapshot creates a draft and does not start processing.';
    }
    field(6; "Data Language"; Enum "BCSF Data Language")
    {
      Caption = 'Resolved Data Language';
      ToolTip = 'Specifies the fixed German or English language for this run, independent of worker language.';
    }
    field(7; "Seed"; Integer)
    {
      Caption = 'Seed';
      ToolTip = 'Specifies the captured seed.';
    }
    field(8; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Maximum Process Scope';
      ToolTip = 'Specifies the captured maximum process scope.';
    }
    field(9; "Usage Mode"; Enum "BCSF Usage Mode")
    {
      Caption = 'Usage Mode';
      ToolTip = 'Specifies the captured usage mode.';
    }
    field(10; "Starting Date"; Date)
    {
      Caption = 'Starting Date';
      ToolTip = 'Specifies the first captured scenario date.';
    }
    field(11; "Ending Date"; Date)
    {
      Caption = 'Ending Date';
      ToolTip = 'Specifies the last captured scenario date.';
    }
    field(12; "Batch Size"; Integer)
    {
      Caption = 'Batch Size';
      ToolTip = 'Specifies the captured batch size.';
    }
    field(13; "Created At"; DateTime)
    {
      Caption = 'Created At';
      ToolTip = 'Specifies when the configuration was captured.';
    }
    field(14; "Company Name"; Text[30])
    {
      Caption = 'Company';
      ToolTip = 'Specifies the company bound to this run.';
      DataClassification = OrganizationIdentifiableInformation;
    }
    field(15; "Environment Name"; Text[80])
    {
      Caption = 'Environment';
      ToolTip = 'Specifies the sandbox bound to this run.';
    }
    field(16; "Schema Version"; Integer)
    {
      Caption = 'Snapshot Schema Version';
      ToolTip = 'Specifies the schema used to reconstruct this run.';
      InitValue = 1;
    }
    field(17; "Profile Code"; Code[20])
    {
      Caption = 'Profile Code';
      ToolTip = 'Specifies the captured profile identifier.';
    }
    field(18; "Profile Version"; Code[20])
    {
      Caption = 'Profile Version';
      ToolTip = 'Specifies the captured profile version.';
    }
  }

  keys
  {
    key(PK; "Run Id") { Clustered = true; }
  }
}
