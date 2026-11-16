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
        field("Schedule Attempts"; Rec."Schedule Attempts") { ApplicationArea = All; }
        field("Previous Job Id"; Rec."Previous Job Id") { ApplicationArea = All; }
        field("Started At"; Rec."Started At") { ApplicationArea = All; }
        field("Finished At"; Rec."Finished At") { ApplicationArea = All; }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(ClassifyInterrupted)
      {
        ApplicationArea = All;
        Caption = 'Review Interrupted Claim';
        ToolTip = 'Marks a running batch as uncertain only after verifying that its unique worker session has ended. Does not authorize retry.';
        Image = Check;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(InterruptedQst, false) then
            exit;
          Recovery.ClassifyInterrupted(Rec."Batch Id");
          CurrPage.Update(false);
        end;
      }
      action(RetryUnclaimed)
      {
        ApplicationArea = All;
        Caption = 'Retry Unclaimed Failure';
        ToolTip = 'Retries only a failed batch that was never claimed, after safety checks. At most three schedules are allowed.';
        Image = Check;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(RetryUnclaimedQst, false) then
            exit;
          Recovery.RetryUnclaimed(Rec."Batch Id");
          CurrPage.Update(false);
        end;
      }
      action(ReconcileCheckpoint)
      {
        ApplicationArea = All;
        Caption = 'Reconcile Confirmed Checkpoint';
        ToolTip = 'Confirms an existing validated checkpoint after proving the previous worker is inactive. Never recreates or reposts uncertain work.';
        Image = Check;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(ReconcileCheckpointQst, false) then
            exit;
          Recovery.Reconcile(Rec."Batch Id");
          CurrPage.Update(false);
        end;
      }
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
    RetryUnclaimedQst: Label 'Retry this failed batch only if it was never claimed and all current safety checks pass?';
    ReconcileCheckpointQst: Label 'Revalidate the saved checkpoint and record existing results as complete without executing the generator again?';
    InterruptedQst: Label 'Classify this interrupted claim for manual review after proving that its unique worker session has ended? No work will be repeated.';
    MissingJobErr: Label 'This standard job queue entry no longer exists. Review the batch and standard job queue log instead.';
}
