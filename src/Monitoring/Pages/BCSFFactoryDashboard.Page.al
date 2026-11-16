namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.ScenarioManagement;

page 90351 "BCSF Factory Dashboard"
{
  ApplicationArea = All;
  UsageCategory = Lists;
  Caption = 'Scenario Factory Run Monitor';
  PageType = List;
  SourceTable = "BCSF Run Header";
  CardPageId = "BCSF Run Card";
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Runs)
      {
        field("Run Id"; Rec."Run Id") { }
        field(Description; Rec.Description) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Profile Version"; Rec."Profile Version") { }
        field("Usage Mode"; Rec."Usage Mode") { }
        field("Process Mode"; Rec."Process Mode") { }
        field("Created At"; Rec."Created At") { }
        field(ExecutionState; ExecutionState)
        {
          Caption = 'Current Execution Status';
          ToolTip = 'Shows current persisted execution status, independently of the captured initial status. Use executions for status filtering.';
        }
      }
    }
    area(FactBoxes)
    {
      part(Overview; "BCSF Run Overview")
      {
        SubPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(Workspace)
      {
        Caption = 'Dashboard';
        ToolTip = 'Opens the JavaScript workspace with scenario creation, navigation and run actions.';
        Image = Statistics;
        RunObject = page "BCSF Dashboard Host";
      }

      action(Progress)
      {
        Caption = 'View Step Progress';
        ToolTip = 'Compares frozen entity targets with confirmed completed batches. Cancelled or uncertain work remains outstanding.';
        Image = Statistics;
        trigger OnAction()
        var
          ProgressPage: Page "BCSF Step Progress";
        begin
          ProgressPage.SetRunId(Rec."Run Id");
          ProgressPage.Run();
        end;
      }
      action(Batches)
      {
        Caption = 'View Batches';
        ToolTip = 'Shows persisted batches for the selected run and links to standard queue diagnostics.';
        Image = List;
        RunObject = page "BCSF Batch List";
        RunPageLink = "Run Id" = field("Run Id");
      }
      action(History)
      {
        Caption = 'View Status History';
        ToolTip = 'Shows immutable technical transitions recorded since monitoring was installed. No business values or raw error text are copied.';
        Image = History;
        RunObject = page "BCSF Run Events";
        RunPageLink = "Run Id" = field("Run Id");
      }
      action(Executions)
      {
        Caption = 'Filter Executions';
        ToolTip = 'Opens persisted execution states with native status filtering.';
        Image = Filter;
        RunObject = page "BCSF Execution List";
      }
      action(Scenarios)
      {
        Caption = 'Scenarios';
        ToolTip = 'Opens scenario templates for guided planning or detailed configuration.';
        Image = Planning;
        RunObject = page "BCSF Scenario List";
      }
      action(Refresh)
      {
        Caption = 'Refresh';
        ToolTip = 'Rereads persisted states without starting or retrying work.';
        Image = Refresh;
        trigger OnAction()
        begin
          CurrPage.Update(false);
        end;
      }
    }
  }
  trigger OnAfterGetRecord()
  var
    Execution: Record "BCSF Run Execution";
  begin
    ExecutionState := NotPreparedLbl;
    if Execution.Get(Rec."Run Id") then
      ExecutionState := Format(Execution.Status);
  end;
  var
    ExecutionState: Text;
    NotPreparedLbl: Label 'Not prepared';
}
