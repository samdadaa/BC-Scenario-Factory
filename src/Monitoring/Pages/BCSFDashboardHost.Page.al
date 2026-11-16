namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.ScenarioManagement;

page 90363 "BCSF Dashboard Host"
{
  ApplicationArea = All;
  UsageCategory = Tasks;
  Caption = 'Scenario Factory Dashboard';
  PageType = Card;
  SourceTable = "BCSF Run Header";
  SourceTableView = sorting("Created At", "Run Id") order(descending);
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      part(Workspace; "BCSF Dashboard Part")
      {
        ApplicationArea = All;
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  begin
    CurrPage.Workspace.Page.SetRunId(Rec."Run Id");
  end;
}
