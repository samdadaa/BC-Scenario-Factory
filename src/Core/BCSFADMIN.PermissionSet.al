namespace BCScenarioFactory.Core;

using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ModuleRegistry;
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
    codeunit "BCSF Scenario Guard" = X,
    tabledata "BCSF Run Step" = Ri,
    table "BCSF Run Step" = X,
    table "BCSF Generator Registry" = X,
    table "BCSF Dependency" = X,
    table "BCSF Plan Node" = X,
    page "BCSF Generator Catalog" = X,
    page "BCSF Plan Preview" = X,
    page "BCSF Saved Run Steps" = X,
    codeunit "BCSF Contract JSON" = X,
    codeunit "BCSF Generator Registry Mgt" = X,
    codeunit "BCSF Customer Probe" = X,
    codeunit "BCSF Vendor Probe" = X,
    codeunit "BCSF Missing Generator" = X,
    codeunit "BCSF Probe Support" = X,
    codeunit "BCSF Contract Self Check" = X,
    codeunit "BCSF Dependency Planner" = X,
    codeunit "BCSF Graph Sorter" = X,
    codeunit "BCSF Plan Writer" = X,
    codeunit "BCSF Graph Self Check" = X,
    codeunit "BCSF Planning Guard" = X;
}
