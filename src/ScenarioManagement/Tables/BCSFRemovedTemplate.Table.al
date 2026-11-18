namespace BCScenarioFactory.ScenarioManagement;

table 90148 "BCSF Removed Template"
{
  Access = Internal;
  DataClassification = SystemMetadata;
  Caption = 'Removed Scenario Template';
  fields
  {
    field(1; "Scenario Id"; Guid) { Caption = 'Scenario ID'; }
  }
  keys { key(PK; "Scenario Id") { Clustered = true; } }

}
