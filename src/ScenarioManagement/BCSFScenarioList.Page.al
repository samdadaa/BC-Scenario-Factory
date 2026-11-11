namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90133 "BCSF Scenario List"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Scenarios';
  PageType = List;
  SourceTable = "BCSF Scenario";
  UsageCategory = Lists;
  CardPageId = "BCSF Scenario Card";
  InsertAllowed = false;
  DeleteAllowed = false;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Scenarios)
      {
        field(Description; Rec.Description) { }
        field(Revision; Rec.Revision) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Process Mode"; Rec."Process Mode") { }
        field("Data Language"; Rec."Data Language") { }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(CreateScenario)
      {
        ApplicationArea = All;
        Caption = 'New Scenario';
        ToolTip = 'Creates a new template from the factory defaults.';
        Image = New;
        trigger OnAction()
        var
          Scenario: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          Scenario.Get(Manager.CreateScenario());
          Page.Run(Page::"BCSF Scenario Card", Scenario);
        end;
      }
      action(CopyScenario)
      {
        ApplicationArea = All;
        Caption = 'Copy Scenario';
        ToolTip = 'Creates an independent copy of this template, including modules and targets.';
        Image = Copy;
        trigger OnAction()
        var
          Scenario: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SaveRecord();
          Scenario.Get(Manager.CopyScenario(Rec."Scenario Id"));
          Page.Run(Page::"BCSF Scenario Card", Scenario);
        end;
      }
      action(CapturedRuns)
      {
        ApplicationArea = All;
        Caption = 'Captured Runs';
        ToolTip = 'Opens the captured configuration history.';
        Image = History;
        RunObject = page "BCSF Run List";
      }
    }
  }
}
