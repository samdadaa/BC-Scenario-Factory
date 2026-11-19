namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

page 90364 "BCSF Factory Role Center"
{
  ApplicationArea = All;
  Caption = 'BC Scenario Factory';
  PageType = RoleCenter;
  layout
  {
    area(RoleCenter)
    {
      part(Workspace; "BCSF Dashboard Part")
      {
        ApplicationArea = All;
      }
    }
  }
  actions
  {
    area(Sections)
    {
      group(Factory)
      {
        Caption = 'Scenario Factory';
        action(Scenarios)
        {
          Caption = 'Scenarios';
          ToolTip = 'Defines, copies and configures scenario templates and their entity targets.';
          ApplicationArea = All;
          RunObject = page "BCSF Scenario List";
        }
        action(Runs)
        {
          Caption = 'Captured Runs';
          ToolTip = 'Opens captured run configurations and all run-specific planning and execution actions.';
          ApplicationArea = All;
          RunObject = page "BCSF Factory Dashboard";
        }
        action(Setup)
        {
          Caption = 'Factory Setup';
          ToolTip = 'Opens sandbox, company, limits, language and operation settings.';
          ApplicationArea = All;
          RunObject = page "BCSF Factory Setup Card";
        }
      }
    }
  }
}
