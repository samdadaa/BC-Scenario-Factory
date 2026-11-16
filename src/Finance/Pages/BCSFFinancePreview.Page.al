namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.SetupManager;

page 90405 "BCSF Finance Preview"
{
    ApplicationArea = All;
    Caption = 'Finance Setup Preview';
    PageType = List;
    SourceTable = "BCSF Setup Diff";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Findings)
            {
                field(Requirement; Rec.Requirement) { }
                field(Blocked; Rec.Blocked) { }
                field(Finding; Rec.Finding) { }
                field(ProposedAction; Rec.Action) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyFinancePackage)
            {
                ApplicationArea = All;
                Caption = 'Apply Test Package';
                ToolTip = 'Applies the reviewed package in the current approved sandbox company after confirmation and a fresh conflict check.';
                Image = Apply;
                Enabled = AllowApply;

                trigger OnAction()
                var
                    Packages: Codeunit "BCSF Finance Package Mgt";
                begin
                    if not Confirm(ConfirmLbl, false, Format(Mode), CompanyName()) then
                        exit;
                    Packages.Apply(Mode);
                    CurrPage.Close();
                end;
            }
        }
    }

    internal procedure SetMode(NewMode: Enum "BCSF Finance Mode")
    var
        Packages: Codeunit "BCSF Finance Package Mgt";
    begin
        Mode := NewMode;
        AllowApply := Packages.Preview(Mode, Rec) and (Mode <> Mode::Existing);
    end;

    var
        Mode: Enum "BCSF Finance Mode";
        AllowApply: Boolean;
        ConfirmLbl: Label 'Apply %1 in the current company %2? Existing records will not be overwritten.', Comment = '%1 = package, %2 = company';
}
