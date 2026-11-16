namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ModuleRegistry;
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
        action(Dashboard)
        {
          Caption = 'Dashboard';
          ToolTip = 'Opens the complete Scenario Factory workspace.';
          ApplicationArea = All;
          RunObject = page "BCSF Dashboard Host";
        }
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
          RunObject = page "BCSF Run List";
        }
        action(Executions)
        {
          Caption = 'Executions';
          ToolTip = 'Opens persisted execution states.';
          ApplicationArea = All;
          RunObject = page "BCSF Execution List";
        }
        action(Batches)
        {
          Caption = 'Batches and Recovery';
          ToolTip = 'Opens batches, standard queue diagnostics and guarded recovery actions.';
          ApplicationArea = All;
          RunObject = page "BCSF Batch List";
        }
        action(Records)
        {
          Caption = 'Generated Records';
          ToolTip = 'Opens the provenance registry for generated artifacts.';
          ApplicationArea = All;
          RunObject = page "BCSF Generated Records";
        }
        action(Generators)
        {
          Caption = 'Generator Catalog';
          ToolTip = 'Opens available generator capabilities and the contract check.';
          ApplicationArea = All;
          RunObject = page "BCSF Generator Catalog";
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
