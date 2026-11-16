namespace BCScenarioFactory.SetupManager;

page 90227 "BCSF Setup Diff Preview"
{
  PageType = List;
  SourceTable = "BCSF Setup Diff";
  SourceTableTemporary = true;
  Caption = 'Setup Preflight and Proposed Actions';
  ApplicationArea = All;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Findings)
      {
        field(Requirement; Rec.Requirement) { ApplicationArea = All; }
        field(Blocked; Rec.Blocked) { ApplicationArea = All; }
        field(Finding; Rec.Finding) { ApplicationArea = All; }
        field(ProposedAction; Rec.Action) { ApplicationArea = All; }
      }
    }
  }
  procedure SetRunId(RunId: Guid)
  var
    Manager: Codeunit "BCSF Setup Manager";
  begin
    Manager.BuildFromRun(RunId, Rec);
  end;
}
