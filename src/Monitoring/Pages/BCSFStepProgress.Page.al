namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ScenarioManagement;

page 90352 "BCSF Step Progress"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Step Progress';
  PageType = List;
  SourceTable = "BCSF Step Metric";
  SourceTableTemporary = true;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Steps)
      {
        field(ModuleName; ModuleName)
        {
          Caption = 'Module';
          ToolTip = 'Shows the module name in the session language.';
        }
        field(EntityName; EntityName)
        {
          Caption = 'Entity';
          ToolTip = 'Shows the entity name in the session language.';
        }
        field("Module Code"; Rec."Module Code") { Visible = false; }
        field("Entity Code"; Rec."Entity Code") { Visible = false; }
        field("Node Code"; Rec."Node Code") { }
        field("Planned Units"; Rec."Planned Units") { }
        field("Confirmed Units"; Rec."Confirmed Units") { }
        field("Remaining Units"; Rec."Remaining Units") { }
        field("Created Artifacts"; Rec."Created Artifacts") { }
        field("Progress Percent"; Rec."Progress Percent") { }
        field("Total Batches"; Rec."Total Batches") { }
        field("Completed Batches"; Rec."Completed Batches") { }
        field("Review Batches"; Rec."Review Batches") { }
        field("Running Batches"; Rec."Running Batches") { }
        field("Cancelled Batches"; Rec."Cancelled Batches") { }
        field(State; Rec.State) { }
        field("External Check"; Rec."External Check") { }
        field("Plan Saved"; Rec."Plan Saved") { }
        field(Blocker; BlockerText)
        {
          Caption = 'Blocker Explanation';
          ToolTip = 'Shows the saved planning blocker and its required corrective action.';
        }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(Batches)
      {
        Caption = 'View Batches';
        ToolTip = 'Shows persisted batches for the selected run and step, including uncertain and cancelled work.';
        Image = List;
        RunObject = page "BCSF Batch List";
        RunPageLink = "Run Id" = field("Run Id"), "Node Code" = field("Node Code");
      }
      action(Refresh)
      {
        Caption = 'Refresh';
        ToolTip = 'Rereads persisted states without starting or retrying work.';
        Image = Refresh;
        trigger OnAction()
        begin
          Load();
          CurrPage.Update(false);
        end;
      }
    }
  }
  trigger OnOpenPage()
  begin
    Load();
  end;

  trigger OnAfterGetRecord()
  var
    Planner: Codeunit "BCSF Dependency Planner";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    ModuleName := Policy.GetModuleName(Rec."Module Code");
    EntityName := Policy.GetEntityName(Rec."Entity Code");
    BlockerText := Planner.GetIssueText(Rec.Issue, Rec."Reference Code");
  end;

  procedure SetRunId(Value: Guid)
  begin
    RunId := Value;
  end;

  local procedure Load()
  var
    Monitor: Codeunit "BCSF Monitoring Mgt";
  begin
    Monitor.LoadSteps(RunId, Rec);
  end;

  var
    RunId: Guid;
    BlockerText: Text;
    ModuleName: Text;
    EntityName: Text;
}
