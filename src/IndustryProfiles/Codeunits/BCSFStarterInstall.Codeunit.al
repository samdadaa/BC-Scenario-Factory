namespace BCScenarioFactory.IndustryProfiles;

codeunit 90156 "BCSF Starter Install"
{
  Access = Internal;
  Subtype = Install;

  trigger OnInstallAppPerCompany()
  begin
    // Optional starters are loaded explicitly from the scenario list, never during deployment.
  end;
}
