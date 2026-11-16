namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

pageextension 90407 "BCSF Run Finance" extends "BCSF Run Card"
{
  layout
  {
    addlast(Configuration)
    {
      field(FrozenFinanceMode; FrozenMode)
      {
        ApplicationArea = All;
        Caption = 'Captured Finance Setup';
        ToolTip = 'Shows the finance setup mode in the immutable run snapshot.';
      }
      field(FrozenFinanceYear; FrozenYear)
      {
        ApplicationArea = All;
        Caption = 'Finance Reference Year';
        ToolTip = 'Shows the captured test chart reference year. It is empty for existing BC setup.';
        BlankZero = true;
      }
      field(FrozenFinanceVersion; FrozenVersion)
      {
        ApplicationArea = All;
        Caption = 'Finance Package Version';
        ToolTip = 'Shows the version of the applied finance package at capture.';
      }
    }
  }

  trigger OnAfterGetRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Context: JsonObject;
    Value: JsonToken;
  begin
    Clear(FrozenMode);
    Clear(FrozenYear);
    Clear(FrozenVersion);
    Manager.ReadSnapshot(Rec."Run Id", Context);
    if Context.Get('financeMode', Value) then
      FrozenMode := "BCSF Finance Mode".FromInteger(Value.AsValue().AsInteger());
    if Context.Get('financeYear', Value) then
      FrozenYear := Value.AsValue().AsInteger();
    if Context.Get('financeVersion', Value) then
      FrozenVersion := CopyStr(Value.AsValue().AsText(), 1, MaxStrLen(FrozenVersion));
  end;

  var
    FrozenMode: Enum "BCSF Finance Mode";
    FrozenYear: Integer;
    FrozenVersion: Code[20];
}
