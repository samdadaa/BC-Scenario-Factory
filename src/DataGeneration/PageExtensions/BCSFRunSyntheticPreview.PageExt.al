namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

pageextension 90253 "BCSF Run Synthetic Preview" extends "BCSF Run Card"
{
  actions
  {
    addlast(Diagnostics)
    {
      action(SyntheticPreview)
      {
        ApplicationArea = All;
        Caption = 'Preview Synthetic Inputs';
        ToolTip = 'Shows sample names, a price and a date derived from the frozen seed, language and rules. Creates no business records.';
        Image = View;
        trigger OnAction()
        var
          Manager: Codeunit "BCSF Scenario Manager";
          Engine: Codeunit "BCSF Seed Engine";
          Contract: Codeunit "BCSF Contract JSON";
          Context: JsonObject;
          Values: JsonObject;
        begin
          Manager.ReadSnapshot(Rec."Run Id", Context);
          Values := Engine.BuildValues(Context, 'ITEM', '1');
          Message(PreviewLbl, Contract.GetText(Values, 'companyName'), Contract.GetText(Values, 'personName'),
            Contract.GetText(Values, 'itemDescription'), Contract.GetText(Values, 'unitPrice'), Contract.GetText(Values, 'date'));
        end;
      }
    }
  }
  var
    PreviewLbl: Label 'Synthetic company: %1\Synthetic person: %2\Synthetic item: %3\Sample unit price: %4\Sample date: %5', Comment = '%1 = company, %2 = person, %3 = item, %4 = price, %5 = date';
}
