namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90138 "BCSF Run List"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Captured Runs';
  PageType = List;
  SourceTable = "BCSF Run Header";
  UsageCategory = History;
  CardPageId = "BCSF Run Card";
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Runs)
      {
        field("Run Id"; Rec."Run Id") { }
        field(Description; Rec.Description) { }
        field("Scenario Revision"; Rec."Scenario Revision") { }
        field(Status; Rec.Status) { }
        field("Data Language"; Rec."Data Language") { }
        field("Created At"; Rec."Created At") { }
      }
    }
  }
}
