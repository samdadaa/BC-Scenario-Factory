namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.Core;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.ScenarioManagement;

pageextension 90368 "BCSF Scenario Actions" extends "BCSF Scenario List"
{
  actions
  {
    addfirst(Promoted)
    {
      actionref(RunPartnerPromoted; RunPartnerScenario) { }
    }
    addfirst(Processing)
    {
      action(RunPartnerScenario)
      {
        ApplicationArea = All;
        Caption = 'Run Template';
        ToolTip = 'Starts the selected template in the background using this company''s initialized setup.';
        Image = Task;
        Enabled = CanRunPartnerScenario;

        trigger OnAction()
        var
          Header: Record "BCSF Run Header";
          QuickRun: Codeunit "BCSF Quick Scenario Run";
          RunId: Guid;
        begin
          RunId := QuickRun.RunScenario(Rec);
          if not IsNullGuid(RunId) then begin
            Header.Get(RunId);
            Page.Run(Page::"BCSF Run Card", Header);
          end;
        end;
      }
      action(LoadStarterScenarios)
      {
        ApplicationArea = All;
        Caption = 'Load Starter Scenarios';
        ToolTip = 'Adds missing built-in starter scenarios without replacing existing templates or starting a run.';
        Image = Setup;

        trigger OnAction()
        var
          Catalog: Codeunit "BCSF Starter Catalog";
        begin
          Catalog.Seed();
          CurrPage.Update(false);
        end;
      }
      action(RestoreStarterScenarios)
      {
        ApplicationArea = All;
        Caption = 'Restore Removed Starter Templates';
        ToolTip = 'Explicitly restores removed and archived built-in starters without resetting custom names.';
        Image = Restore;
        trigger OnAction()
        var
          Catalog: Codeunit "BCSF Starter Catalog";
        begin
          Catalog.RestoreStarters();
          CurrPage.Update(false);
        end;
      }
      action(ExportScenarioBundle)
      {
        ApplicationArea = All;
        Caption = 'Export Selected Scenarios';
        ToolTip = 'Downloads the selected scenarios and their settings together in one JSON file.';
        Image = Export;

        trigger OnAction()
        var
          Selection: Record "BCSF Scenario";
          Transfer: Codeunit "BCSF Scenario Transfer";
        begin
          CurrPage.SetSelectionFilter(Selection);
          Transfer.ExportSelection(Selection);
        end;
      }
      action(ImportScenarioBundle)
      {
        ApplicationArea = All;
        Caption = 'Import Scenario Bundle';
        ToolTip = 'Imports multiple scenarios from a JSON file as new copies without starting any runs.';
        Image = Import;

        trigger OnAction()
        var
          Transfer: Codeunit "BCSF Scenario Transfer";
        begin
          Transfer.ImportSelection();
          CurrPage.Update(false);
        end;
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    CanRunPartnerScenario := not IsNullGuid(Rec."Scenario Id") and Manager.IsPartnerTemplate(Rec);
  end;

  var
    CanRunPartnerScenario: Boolean;
}
