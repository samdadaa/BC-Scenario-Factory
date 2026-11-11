namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90125 "BCSF Scenario"
{
  Access = Internal;
  Caption = 'Scenario';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Scenario Id"; Guid)
    {
      Caption = 'Scenario ID';
      ToolTip = 'Specifies the stable identity of this template.';
      Editable = false;
    }
    field(2; "Description"; Text[100])
    {
      Caption = 'Description';
      ToolTip = 'Specifies the purpose of this scenario template.';
    }
    field(3; "Revision"; Integer)
    {
      Caption = 'Revision';
      ToolTip = 'Specifies the revision, including module and target changes.';
      Editable = false;
    }
    field(4; "Profile Code"; Code[20])
    {
      Caption = 'Profile Code';
      ToolTip = 'Specifies the intended industry profile identifier.';
    }
    field(5; "Profile Version"; Code[20])
    {
      Caption = 'Profile Version';
      ToolTip = 'Specifies the profile version captured with each run.';
    }
    field(6; "Usage Mode"; Enum "BCSF Usage Mode")
    {
      Caption = 'Usage Mode';
      ToolTip = 'Specifies whether the scenario is intended for demos, training or tests.';
    }
    field(7; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Maximum Process Scope';
      ToolTip = 'Specifies the highest process mode allowed for entity targets.';
    }
    field(8; "Seed"; Integer)
    {
      Caption = 'Seed';
      ToolTip = 'Specifies the seed captured for reproducible input data.';
    }
    field(9; "Starting Date"; Date)
    {
      Caption = 'Starting Date';
      ToolTip = 'Specifies the first date in the scenario period.';
    }
    field(10; "Ending Date"; Date)
    {
      Caption = 'Ending Date';
      ToolTip = 'Specifies the last date in the scenario period.';
    }
    field(11; "Data Language"; Enum "BCSF Data Language")
    {
      Caption = 'Generated Data Language';
      ToolTip = 'Specifies the data language. Automatic resolves German variants to German and all other languages to English when a run is captured.';
    }
    field(12; "Batch Size"; Integer)
    {
      Caption = 'Batch Size';
      ToolTip = 'Specifies the requested batch size, capped by the factory limits.';
    }
  }

  keys
  {
    key(PK; "Scenario Id") { Clustered = true; }
  }
}
