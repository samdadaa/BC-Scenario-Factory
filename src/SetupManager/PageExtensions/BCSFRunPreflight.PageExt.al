namespace BCScenarioFactory.SetupManager;

using BCScenarioFactory.ScenarioManagement;

pageextension 90228 "BCSF Run Preflight" extends "BCSF Run Card"
{
  actions
  {
    addlast(Diagnostics)
    {
      action(SetupPreflight)
      {
        ApplicationArea = All;
        Caption = 'Review Setup Preflight';
        ToolTip = 'Reads current setup and effective permissions for the frozen targets and shows blockers and proposed manual actions. Does not change setup or approve execution.';
        Image = Check;
        trigger OnAction()
        var
          Preview: Page "BCSF Setup Diff Preview";
        begin
          Preview.SetRunId(Rec."Run Id");
          Preview.Run();
        end;
      }
    }
  }
}
