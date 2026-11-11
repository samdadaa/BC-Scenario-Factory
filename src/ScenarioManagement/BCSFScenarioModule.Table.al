namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90126 "BCSF Scenario Module"
{
  Access = Internal;
  Caption = 'Scenario Module';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Scenario Id"; Guid)
    {
      Caption = 'Scenario ID';
      ToolTip = 'Specifies the owning scenario.';
      TableRelation = "BCSF Scenario"."Scenario Id";
    }
    field(2; "Module"; Enum "BCSF Module Type")
    {
      Caption = 'Module';
      ToolTip = 'Specifies a selected business module. Selection does not imply an available generator.';
    }
    field(3; "Enabled"; Boolean)
    {
      Caption = 'Enabled';
      ToolTip = 'Specifies whether this module is included in the captured plan.';
      InitValue = true;
    }
  }

  keys
  {
    key(PK; "Scenario Id", Module) { Clustered = true; }
  }
}
