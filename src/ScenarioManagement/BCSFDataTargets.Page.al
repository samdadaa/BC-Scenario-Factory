namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90137 "BCSF Data Targets"
{
  ApplicationArea = All;
  Caption = 'Entity Targets';
  PageType = ListPart;
  SourceTable = "BCSF Data Target";
  DelayedInsert = true;
  layout
  {
    area(Content)
    {
      field(SelectedPreset; SelectedPreset)
      {
        Caption = 'Quantity Preset';
        ToolTip = 'Specifies a quantity preset for the currently selected entity only.';
      }
      repeater(Targets)
      {
        field(Entity; Rec.Entity) { }
        field(Module; Rec.Module) { }
        field(Quantity; Rec.Quantity)
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
        field("Process Mode"; Rec."Process Mode")
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
        field("Unposted Percent"; Rec."Unposted Percent")
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
        field("Posted Percent"; Rec."Posted Percent")
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
        field("Partial Percent"; Rec."Partial Percent")
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
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
  actions
  {
    area(Processing)
    {
      action(ApplyPreset)
      {
        ApplicationArea = All;
        Caption = 'Apply Preset to Entity';
        ToolTip = 'Applies the selected quantity preset to the current entity only, subject to the factory limit.';
        Image = Apply;
        trigger OnAction()
        var
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SaveRecord();
          Manager.ApplyPreset(Rec."Scenario Id", Rec.Entity, SelectedPreset);
          CurrPage.Update(false);
        end;
      }
    }
  }
  trigger OnNewRecord(BelowxRec: Boolean)
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if Rec.GetFilter("Scenario Id") <> '' then
      Rec."Scenario Id" := Rec.GetRangeMin("Scenario Id");
    Policy.ApplyEntityDefaults(Rec);
  end;

  trigger OnAfterGetRecord()
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    Policy.GetDistribution(Rec, EstimatedUnposted, EstimatedPosted, EstimatedPartial);
  end;

  var
    SelectedPreset: Enum "BCSF Quantity Preset";
    EstimatedUnposted: Integer;
    EstimatedPosted: Integer;
    EstimatedPartial: Integer;
}
