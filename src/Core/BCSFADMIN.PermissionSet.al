namespace BCScenarioFactory.Core;

using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Environment.Configuration;

permissionset 90105 "BCSF ADMIN"
{
  Assignable = true;
  Caption = 'Scenario Factory Setup Admin';
  Permissions =
    tabledata "BCSF Factory Setup" = RIM,
    table "BCSF Factory Setup" = X,
    page "BCSF Factory Setup Card" = X,
    page "User Settings" = X,
    codeunit "BCSF Setup Management" = X,
    codeunit "BCSF Run State Mgt" = X,
    codeunit "BCSF Environment Guard" = X,
    codeunit "BCSF Language Mgt" = X,
    tabledata "BCSF Scenario" = RIM,
    tabledata "BCSF Scenario Module" = RIMD,
    tabledata "BCSF Data Target" = RIMD,
    tabledata "BCSF Run Header" = Ri,
    tabledata "BCSF Run Snapshot" = Ri,
    table "BCSF Scenario" = X,
    table "BCSF Scenario Module" = X,
    table "BCSF Data Target" = X,
    table "BCSF Run Header" = X,
    table "BCSF Run Snapshot" = X,
    page "BCSF Scenario List" = X,
    page "BCSF Scenario Card" = X,
    page "BCSF Scenario Modules" = X,
    page "BCSF Data Targets" = X,
    page "BCSF Run List" = X,
    page "BCSF Run Card" = X,
    page "BCSF Frozen Targets" = X,
    page "BCSF Frozen Modules" = X,
    codeunit "BCSF Scenario Manager" = X,
    codeunit "BCSF Scenario Policy" = X,
    codeunit "BCSF Snapshot Writer" = X,
    codeunit "BCSF Scenario DB Events" = X,
    codeunit "BCSF Scenario Guard" = X;
}
