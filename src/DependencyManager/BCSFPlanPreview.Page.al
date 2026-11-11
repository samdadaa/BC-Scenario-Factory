namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.ScenarioManagement;

page 90205 "BCSF Plan Preview"
{
  ApplicationArea = All;
  Caption = 'Dependency Plan Preview';
  PageType = List;
  SourceTable = "BCSF Run Step";
  SourceTableView = sorting("Run Id", "Sequence No.", "Node Code");
  SourceTableTemporary = true;
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
  actions
  {
    area(Processing)
    {
      action(CheckGraph)
      {
        ApplicationArea = All;
        Caption = 'Run Graph Self-Check';
        ToolTip = 'Checks the finance-to-sales chain, missing requirements, optional edges and an intentional cycle using temporary records only.';
        Image = Check;
        trigger OnAction()
        var
          SelfCheck: Codeunit "BCSF Graph Self Check";
        begin
          SelfCheck.Check();
          Message(CheckedLbl);
        end;
      }
    }
  }
  procedure SetRunId(RunId: Guid)
  begin
    CurrentRunId := RunId;
  end;
  trigger OnOpenPage()
  var
    Writer: Codeunit "BCSF Plan Writer";
  begin
    Writer.LoadPreview(CurrentRunId, Rec);
  end;
  trigger OnAfterGetRecord()
  var
    Planner: Codeunit "BCSF Dependency Planner";
  begin
    IssueText := Planner.GetIssueText(Rec.Issue, Rec."Reference Code");
  end;
  var
    IssueText: Text;
    CurrentRunId: Guid;
    CheckedLbl: Label 'The dependency graph self-check passed. No run was changed.';
}
