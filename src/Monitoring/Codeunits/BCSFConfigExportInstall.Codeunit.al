namespace BCScenarioFactory.Monitoring;

codeunit 90372 "BCSF Config Export Install"
{
  Access = Internal;
  Subtype = Install;

  trigger OnInstallAppPerCompany()
  begin
    // Never build RapidStart fields in every company during installation.
    // The explicit export action provisions the package in the current company.
  end;
}
