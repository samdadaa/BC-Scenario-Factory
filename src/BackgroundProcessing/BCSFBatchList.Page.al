namespace BCScenarioFactory.BackgroundProcessing;

using System.Threading;

page 90311 "BCSF Batch List"
{
  PageType = List;
  SourceTable = "BCSF Batch";
  SourceTableView = sorting("Run Id", "Sequence No.");
  Caption = 'Scenario Factory Batches';
  ApplicationArea = All;
  UsageCategory = Lists;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Batches)
      {
        field("Run Id"; Rec."Run Id") { ApplicationArea = All; }
        field("Sequence No."; Rec."Sequence No.") { ApplicationArea = All; }
        field("Node Code"; Rec."Node Code") { ApplicationArea = All; }
        field("Batch Id"; Rec."Batch Id") { ApplicationArea = All; }
        field("Batch Key"; Rec."Batch Key") { ApplicationArea = All; }
        field("First Key"; Rec."First Key") { ApplicationArea = All; }
        field("Last Key"; Rec."Last Key") { ApplicationArea = All; }
        field("Status"; Rec."Status") { ApplicationArea = All; }
        field("Processed Units"; Rec."Processed Units") { ApplicationArea = All; }
        field("Created Records"; Rec."Created Records") { ApplicationArea = All; }
        field("Job Queue Entry Id"; Rec."Job Queue Entry Id") { ApplicationArea = All; }
        field("Started At"; Rec."Started At") { ApplicationArea = All; }
        field("Finished At"; Rec."Finished At") { ApplicationArea = All; }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(ViewJob)
      {
        ApplicationArea = All;
        Caption = 'View Job Queue Entry';
        ToolTip = 'Opens the standard queue entry if it still exists. Successful one-time jobs may already have been removed by BC.';
        Image = View;
        trigger OnAction()
        var
          Job: Record "Job Queue Entry";
        begin
          if not Job.Get(Rec."Job Queue Entry Id") then
            Error(MissingJobErr);
          Job.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
          Page.Run(Page::"Job Queue Entry Card", Job);
        end;
      }
    }
  }
  var
    MissingJobErr: Label 'This standard job queue entry no longer exists. Review the batch and standard job queue log instead.';
}
