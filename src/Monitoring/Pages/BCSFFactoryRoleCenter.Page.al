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
        // The dashboard has its own tab bar; a blank part caption suppresses the page caption above it.
        Caption = ' ', Locked = true;
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
          Visible = false;
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
        action(ExportPackage)
        {
          Caption = 'Prepare data export package';
          ToolTip = 'Creates or completes the export package in the current company and opens it. Includes full master data, documents and posted entries. Use Export to Excel to inspect current data.';
          ApplicationArea = All;
          Image = Export;
          RunObject = codeunit "BCSF Config Export";
        }
      }
    }
  }
}
