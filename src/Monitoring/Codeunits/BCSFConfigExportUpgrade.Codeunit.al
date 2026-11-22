namespace BCScenarioFactory.Monitoring;

codeunit 90373 "BCSF Config Export Upgrade"
{
  Access = Internal;
  Subtype = Upgrade;

  trigger OnUpgradePerCompany()
  begin
    // Keep upgrades independent of company count and existing export packages.
    // Existing packages are retained; the explicit export action adds missing tables.
  end;
}
