namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;

table 90403 "BCSF Finance Package"
{
  Access = Internal;
  DataClassification = SystemMetadata;
  Caption = 'Applied Finance Package';

  fields
  {
    field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
    field(2; Mode; Enum "BCSF Finance Mode") { Caption = 'Finance Package'; }
    field(3; "Reference Year"; Integer) { Caption = 'Reference Year'; }
    field(4; Version; Code[20]) { Caption = 'Version'; }
  }
  keys
  {
    key(PK; "Primary Key") { Clustered = true; }
  }
}
