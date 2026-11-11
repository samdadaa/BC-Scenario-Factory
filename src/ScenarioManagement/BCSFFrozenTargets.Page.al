namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90140 "BCSF Frozen Targets"
{
  ApplicationArea = All;
  Caption = 'Captured Entity Targets';
  PageType = ListPart;
  SourceTable = "BCSF Data Target";
  SourceTableTemporary = true;
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Targets)
      {
        field(Entity; Rec.Entity) { }
        field(Module; Rec.Module) { }
        field(Quantity; Rec.Quantity) { }
        field("Process Mode"; Rec."Process Mode") { }
        field("Unposted Percent"; Rec."Unposted Percent") { }
        field("Posted Percent"; Rec."Posted Percent") { }
        field("Partial Percent"; Rec."Partial Percent") { }
        field(EstimatedUnposted; EstimatedUnposted)
        {
          Caption = 'Estimated Unposted Documents';
          ToolTip = 'Shows the planned document count after rounding. Master data is not counted as documents.';
          Editable = false;
        }
        field(EstimatedPosted; EstimatedPosted)
        {
          Caption = 'Estimated Posted Documents';
          ToolTip = 'Shows the planned posted document count, not the number of ledger entries.';
          Editable = false;
        }
        field(EstimatedPartial; EstimatedPartial)
        {
          Caption = 'Estimated Partial Orders';
          ToolTip = 'Shows the planned partially processed order count.';
          Editable = false;
        }
      }
    }
  }
  procedure LoadRun(RunId: Guid)
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Manager.LoadFrozenTargets(RunId, Rec);
    CurrPage.Update(false);
  end;

  trigger OnAfterGetRecord()
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    Policy.GetDistribution(Rec, EstimatedUnposted, EstimatedPosted, EstimatedPartial);
  end;

  var
    EstimatedUnposted: Integer;
    EstimatedPosted: Integer;
    EstimatedPartial: Integer;
}
