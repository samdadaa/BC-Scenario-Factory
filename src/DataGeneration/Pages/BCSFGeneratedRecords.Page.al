namespace BCScenarioFactory.DataGeneration;

page 90254 "BCSF Generated Records"
{
  PageType = List;
  SourceTable = "BCSF Generated Record";
  Caption = 'Generated Result Provenance';
  ApplicationArea = All;
  UsageCategory = Lists;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Results)
      {
        field("Run Id"; Rec."Run Id") { ApplicationArea = All; }
        field("Node Code"; Rec."Node Code") { ApplicationArea = All; }
        field("Logical Key"; Rec."Logical Key") { ApplicationArea = All; }
        field("Artifact Code"; Rec."Artifact Code") { ApplicationArea = All; }
        field("Entry Id"; Rec."Entry Id") { ApplicationArea = All; }
        field("Parent Entry Id"; Rec."Parent Entry Id") { ApplicationArea = All; }
        field("Batch Id"; Rec."Batch Id") { ApplicationArea = All; }
        field("Generator Code"; Rec."Generator Code") { ApplicationArea = All; }
        field("Generator Version"; Rec."Generator Version") { ApplicationArea = All; }
        field("Table Id"; Rec."Table Id") { ApplicationArea = All; }
        field("Record SystemId"; Rec."Record SystemId") { ApplicationArea = All; }
        field("Record Id"; Rec."Record Id") { ApplicationArea = All; }
        field("Created At"; Rec."Created At") { ApplicationArea = All; }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(CheckIdentity)
      {
        ApplicationArea = All;
        Caption = 'Check Result Identity';
        ToolTip = 'Checks whether the recorded SystemId still exists. Does not accept a reused primary key or change any record.';
        Image = Check;
        trigger OnAction()
        var
          Registry: Codeunit "BCSF Record Registry";
        begin
          if Registry.ExistsByIdentity(Rec) then
            Message(FoundLbl)
          else
            Message(MissingLbl);
        end;
      }
    }
  }
  var
    FoundLbl: Label 'The recorded stable result identity still exists. This does not validate the full business process.';
    MissingLbl: Label 'The recorded result is missing or not visible. Review it before retrying any creation or posting.';
}
