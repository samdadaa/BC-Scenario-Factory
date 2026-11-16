namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;

page 90404 "BCSF Finance Selection"
{
    ApplicationArea = All;
    Caption = 'Select Finance Setup';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(FinanceMode; Mode)
            {
                Caption = 'Finance Setup';
                ToolTip = 'Selects existing setup or a versioned test chart for the current test company.';
            }
        }
    }

    internal procedure GetMode(): Enum "BCSF Finance Mode"
    begin
        exit(Mode);
    end;

    var
        Mode: Enum "BCSF Finance Mode";
}
