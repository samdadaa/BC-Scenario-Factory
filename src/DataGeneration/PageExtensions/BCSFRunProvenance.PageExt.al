namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.ScenarioManagement;

pageextension 90255 "BCSF Run Provenance" extends "BCSF Run Card"
{
  actions
  {
    addlast(Diagnostics)
    {
      action(ViewProvenance)
      {
        ApplicationArea = All;
        Caption = 'View Generated Results';
        ToolTip = 'Shows the immutable result identities and parent relationships recorded for this run.';
        Image = LedgerEntries;
        RunObject = page "BCSF Generated Records";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
  }
}
