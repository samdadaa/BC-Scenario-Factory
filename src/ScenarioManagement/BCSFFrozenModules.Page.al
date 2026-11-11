namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90141 "BCSF Frozen Modules"
{
  ApplicationArea = All;
  Caption = 'Captured Modules';
  PageType = ListPart;
  SourceTable = "BCSF Scenario Module";
  SourceTableTemporary = true;
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Modules)
      {
        field(Module; Rec.Module) { }
        field(Enabled; Rec.Enabled) { }
      }
    }
  }
  procedure LoadRun(RunId: Guid)
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Manager.LoadFrozenModules(RunId, Rec);
    CurrPage.Update(false);
  end;
}
