namespace BCScenarioFactory.Validation;

page 90328 "BCSF Validation Results"
{
  ApplicationArea = All;
  PageType = List;
  SourceTable = "BCSF Validation Result";
  Caption = 'Validation Results';
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;

  layout
  {
    area(Content)
    {
      repeater(Results)
      {
        field("Batch Id"; Rec."Batch Id") { }
        field("Node Code"; Rec."Node Code") { }
        field("Rule Code"; Rec."Rule Code") { }
        field(Severity; Rec.Severity) { }
        field(MandatoryCheck; Rec."Rule Code" in ['RUN', 'REQUIRED-OUTPUT'])
        {
          Caption = 'Mandatory Check';
          ToolTip = 'Specifies whether a failure blocks successful completion. Optional checks can issue warnings only.';
        }
        field("Expected Units"; Rec."Expected Units") { }
        field("Reported Units"; Rec."Reported Units") { }
        field("Checked At"; Rec."Checked At") { }
      }
    }
  }
}
