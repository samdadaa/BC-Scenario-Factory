namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90136 "BCSF Scenario Modules"
{
  ApplicationArea = All;
  Caption = 'Scenario Modules';
  PageType = ListPart;
  SourceTable = "BCSF Scenario Module";
  DelayedInsert = true;
  layout
  {
    area(Content)
    {
      repeater(Modules)
      {
        field(Module; Rec.Module) { }
        field(Enabled; Rec.Enabled)
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
      }
    }
  }
  trigger OnNewRecord(BelowxRec: Boolean)
  begin
    if Rec.GetFilter("Scenario Id") <> '' then
      Rec."Scenario Id" := Rec.GetRangeMin("Scenario Id");
  end;
}
