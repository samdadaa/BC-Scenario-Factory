namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.ScenarioManagement;

pageextension 90208 "BCSF Run Planning" extends "BCSF Run Card"
{
  layout
  {
    addlast(Content)
    {
      part(Plan; "BCSF Saved Run Steps")
      {
        ApplicationArea = All;
        SubPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  actions
  {
    addlast(Processing)
    {
      action(PreviewPlan)
      {
        ApplicationArea = All;
        Caption = 'Preview Dependency Plan';
        ToolTip = 'Computes a read-only plan from this frozen snapshot and the current generator catalog. No data is generated.';
        Image = View;
        trigger OnAction()
        var
          Preview: Page "BCSF Plan Preview";
        begin
          Preview.SetRunId(Rec."Run Id");
          Preview.Run();
        end;
      }
      action(SavePlan)
      {
        ApplicationArea = All;
        Caption = 'Save Dependency Plan';
        ToolTip = 'Saves the first immutable planning result for this run, including blockers. Existing plans are retained.';
        Image = Save;
        trigger OnAction()
        var
          Writer: Codeunit "BCSF Plan Writer";
        begin
          Writer.SavePlan(Rec."Run Id");
          CurrPage.Update(false);
        end;
      }
      action(CheckReadiness)
      {
        ApplicationArea = All;
        Caption = 'Check Run Readiness';
        ToolTip = 'Checks saved blockers, generator bindings and execution authorization. Does not start a queue or approve posting.';
        Image = Check;
        trigger OnAction()
        var
          Writer: Codeunit "BCSF Plan Writer";
        begin
          Writer.CheckStart(Rec."Run Id");
          Message(ReadyLbl);
        end;
      }
    }
  }
  var
    ReadyLbl: Label 'Start checks passed. No processing was started.';
}
