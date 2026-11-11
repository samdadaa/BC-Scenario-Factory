namespace BCScenarioFactory.Core;

using BCScenarioFactory.Lifecycle;

permissionset 90105 "BCSF ADMIN"
{
  Assignable = true;
  Caption = 'Scenario Factory Setup Admin';
  Permissions =
    tabledata "BCSF Factory Setup" = RIM,
    table "BCSF Factory Setup" = X,
    page "BCSF Factory Setup Card" = X,
    codeunit "BCSF Setup Management" = X,
    codeunit "BCSF Run State Mgt" = X,
    codeunit "BCSF Environment Guard" = X;
}
