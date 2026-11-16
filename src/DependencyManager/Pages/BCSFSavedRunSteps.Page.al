namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.ScenarioManagement;

page 90206 "BCSF Saved Run Steps"
{
  ApplicationArea = All;
  Caption = 'Saved Run Steps';
  PageType = ListPart;
  SourceTable = "BCSF Run Step";
  SourceTableView = sorting("Run Id", "Sequence No.", "Node Code");
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Steps)
      {
        field("Sequence No."; Rec."Sequence No.") { }
        field("Node Code"; Rec."Node Code") { }
        field("Module Code"; Rec."Module Code") { }
        field("Entity Code"; Rec."Entity Code") { }
        field("Process Mode"; Rec."Process Mode") { }
        field("Work Units"; Rec."Work Units") { }
        field("Generator Code"; Rec."Generator Code") { }
        field("Generator Version"; Rec."Generator Version") { }
        field("Contract Version"; Rec."Contract Version") { }
        field("External Check"; Rec."External Check") { }
        field("Issue"; Rec."Issue") { }
        field(IssueText; IssueText)
        {
          Caption = 'Blocker Description';
          ToolTip = 'Explains the stored blocker code in the current display language.';
        }
      }
    }
  }
  trigger OnAfterGetRecord()
  var
    Planner: Codeunit "BCSF Dependency Planner";
  begin
    IssueText := Planner.GetIssueText(Rec.Issue, Rec."Reference Code");
  end;
  var
    IssueText: Text;
}
