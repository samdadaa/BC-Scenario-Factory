namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;

pageextension 90406 "BCSF Finance Setup" extends "BCSF Factory Setup Card"
{
  actions
  {
    addlast(Processing)
    {
      action(PreviewFinanceSetup)
      {
        ApplicationArea = All;
        Caption = 'Preview Finance Setup';
        ToolTip = 'Reviews existing finance setup or previews a test chart and its posting setup before any changes.';
        Image = Setup;

        trigger OnAction()
        var
          Selection: Page "BCSF Finance Selection";
          Preview: Page "BCSF Finance Preview";
        begin
          if Selection.RunModal() <> Action::OK then
            exit;
          Preview.SetMode(Selection.GetMode());
          Preview.RunModal();
        end;
      }
    }
  }
}
