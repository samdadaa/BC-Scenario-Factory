namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90141 "BCSF Frozen Modules"
{
  ApplicationArea = All;
  Caption = 'Captured Modules';
  PageType = ListPart;
  SourceTable = "BCSF Scenario Module";
  SourceTableTemporary = true;
  Editable = true;
  InsertAllowed = false;
  ModifyAllowed = true;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Modules)
      {
        field(Module; Rec.Module) { Editable = false; }
        field(Enabled; Rec.Enabled)
        {
          Editable = CanSelect;
          trigger OnValidate()
          begin
            if SelectionMode and Rec.Enabled and not Selection.IsAvailable(Rec.Module) then
              Error(UnavailableErr);
            if SelectionMode and TempRequired.Get(Rec."Scenario Id", Rec.Module) and TempRequired.Enabled then
              Rec.TestField(Enabled, true);
          end;
        }
        field(CompanyScope; ModuleScope)
        {
          Caption = 'Company package scope';
          ToolTip = 'Shows whether the module is required by the industry package or an optional module that adds its own generated data in the follow-up stage.';
          Editable = false;
          Visible = SelectionMode;
        }
      }
    }
  }
  procedure LoadRun(RunId: Guid)
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    SelectionMode := false;
    Manager.LoadFrozenModules(RunId, Rec);
    CurrPage.Update(false);
  end;

  internal procedure LoadSelection(var TempModules: Record "BCSF Scenario Module" temporary; var TempBase: Record "BCSF Scenario Module" temporary)
  begin
    SelectionMode := true;
    Rec.Copy(TempModules, true);
    TempRequired.Copy(TempBase, true);
    // A module the license does not cover is never preselected.
    if Rec.FindSet(true) then
      repeat
        if Rec.Enabled and not Selection.IsAvailable(Rec.Module) then begin
          Rec.Enabled := false;
          Rec.Modify();
        end;
      until Rec.Next() = 0;
    Rec.FindFirst();
    CurrPage.Update(false);
  end;

  internal procedure GetSelection(var TempModules: Record "BCSF Scenario Module" temporary)
  begin
    CurrPage.SaveRecord();
    TempModules.Copy(Rec, true);
  end;

  trigger OnAfterGetRecord()
  begin
    CanSelect := SelectionMode and Selection.IsAvailable(Rec.Module);
    if TempRequired.Get(Rec."Scenario Id", Rec.Module) then
      CanSelect := SelectionMode and not TempRequired.Enabled;
    if SelectionMode and not Selection.IsAvailable(Rec.Module) then
      ModuleScope := UnavailableScopeLbl
    else
      if not CanSelect then
        ModuleScope := IncludedLbl
      else
        ModuleScope := PlanningLbl;
  end;

  var
    TempRequired: Record "BCSF Scenario Module" temporary;
    Selection: Codeunit "BCSF Module Selection";
    SelectionMode: Boolean;
    CanSelect: Boolean;
    ModuleScope: Text;
    IncludedLbl: Label 'Included in industry package';
    UnavailableScopeLbl: Label 'Not available: needs a Premium license or permissions';
    UnavailableErr: Label 'This module needs Business Central Premium objects that the current license or permissions do not provide.';
    PlanningLbl: Label 'Optional module; generates data in the follow-up stage';
}
