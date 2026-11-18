namespace BCScenarioFactory.IndustryProfiles;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

codeunit 90156 "BCSF Starter Install"
{
    Access = Internal;
    Subtype = Install;
    Permissions = tabledata "BCSF Factory Setup" = RIM,
    tabledata "BCSF Scenario" = RIM,
    tabledata "BCSF Scenario Module" = RI,
    tabledata "BCSF Data Target" = RI;

    trigger OnInstallAppPerCompany()
    begin

    end;
}
