namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using BCScenarioFactory.Monitoring;

page 90133 "BCSF Scenario List"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Scenarios';
  PageType = List;
  SourceTable = "BCSF Scenario";
  SourceTableView = where(Archived = const(false));
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
        field(Description; DisplayName)
        {
          Caption = 'Description';
          ToolTip = 'Shows the template name in the session language when it is an unchanged built-in name.';
        }
        field(Availability; Availability)
        {
          Caption = 'Availability';
          ToolTip = 'Shows whether the actual entity targets have executable generators. Setup and permissions are checked on start.';
        }
        field(Archived; Rec.Archived) { }
        field(Revision; Rec.Revision) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Process Mode"; Rec."Process Mode") { }
        field("Data Language"; Rec."Data Language") { }
      }
    }
  }
  actions
  {
    area(Promoted)
    {
      actionref(CreateScenarioPromoted; CreateScenario) { }
      actionref(RemoveTemplatesPromoted; RemoveTemplates) { }
    }
    area(Processing)
    {
      action(RemoveTemplates)
      {
        ApplicationArea = All;
        Caption = 'Delete Selected Templates';
        ToolTip = 'Deletes unused selected templates and archives templates with captured runs after showing the counts and confirming.';
        Image = Delete;
        trigger OnAction()
        var
          Selection: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SetSelectionFilter(Selection);
          Manager.RemoveSelection(Selection);
          CurrPage.Update(false);
        end;
      }
      action(ShowArchived)
      {
        ApplicationArea = All;
        Caption = 'Show or Hide Archived Templates';
        ToolTip = 'Includes or hides archived templates. This does not resume jobs or restore removed starters.';
        Image = Filter;
        trigger OnAction()
        begin
          IncludeArchived := not IncludeArchived;
          Rec.FilterGroup(2);
          if IncludeArchived then
            Rec.SetRange(Archived)
          else
            Rec.SetRange(Archived, false);
          Rec.FilterGroup(0);
          CurrPage.Update(false);
        end;
      }
      action(RestoreTemplates)
      {
        ApplicationArea = All;
        Caption = 'Restore Selected Templates';
        ToolTip = 'Makes selected archived templates available for new runs after confirmation.';
        Image = Restore;
        trigger OnAction()
        var
          Selection: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SetSelectionFilter(Selection);
          Manager.RestoreSelection(Selection);
          CurrPage.Update(false);
        end;
      }
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
        RunObject = page "BCSF Factory Dashboard";
        RunPageLink = "Scenario Id" = field("Scenario Id");
      }
    }
  }
  trigger OnAfterGetRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    DisplayName := Manager.GetDisplayName(Rec);
    Availability := Manager.DescribeAvailability(Rec);
  end;
  var
    DisplayName: Text;
    Availability: Text;
    IncludeArchived: Boolean;
}
