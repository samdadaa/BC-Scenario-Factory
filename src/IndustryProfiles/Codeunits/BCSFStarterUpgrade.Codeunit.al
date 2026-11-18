namespace BCScenarioFactory.IndustryProfiles;

codeunit 90157 "BCSF Starter Upgrade"
{
  Access = Internal;
  Subtype = Upgrade;

  trigger OnUpgradePerCompany()
  begin
    // Starter scenarios are optional, not an upgrade migration.
    // Load them from the scenario list in an authorized interactive session.
  end;
}
