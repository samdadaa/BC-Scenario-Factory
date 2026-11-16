namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.ScenarioManagement;

pageextension 90358 "BCSF Run Monitoring" extends "BCSF Run Card"
{
  layout
  {
    addlast(Content)
    {
      part(Monitoring; "BCSF Run Overview")
      {
        ApplicationArea = All;
        SubPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  actions
  {
    addlast(Processing)
    {
      action(MonitorProgress)
      {
        ApplicationArea = All;
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
      action(Dashboard)
      {
        ApplicationArea = All;
        Caption = 'Dashboard';
        ToolTip = 'Opens persisted monitoring without starting any work.';
        Image = Statistics;
        RunObject = page "BCSF Dashboard Host";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
  }
}
