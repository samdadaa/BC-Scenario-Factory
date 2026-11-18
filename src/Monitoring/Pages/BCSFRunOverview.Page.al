namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using System.Threading;

page 90355 "BCSF Run Overview"
{
  ApplicationArea = All;
  Caption = 'Persisted Execution Overview';
  PageType = CardPart;
  SourceTable = "BCSF Run Header";
  Editable = false;
  layout
  {
    area(Content)
    {
      group(State)
      {
        Caption = 'Execution and Quality';
        field(ExecutionState; ExecutionState)
        {
          Caption = 'Current Execution Status';
          ToolTip = 'Shows persisted execution status. An unprepared run has no execution state.';
        }
        field(Quality; QualityText)
        {
          Caption = 'Overall Quality';
          ToolTip = 'Shows the recorded result of final validation. Drill down to see individual checks.';
          trigger OnDrillDown()
          var
            Result: Record "BCSF Validation Result";
          begin
            Result.SetRange("Run Id", Rec."Run Id");
            Page.RunModal(Page::"BCSF Validation Results", Result);
          end;
        }
        field(PauseRequested; PauseRequested)
        {
          Caption = 'Pause Requested';
          ToolTip = 'Shows the saved request separately from the effective execution status.';
        }
        field(CancelRequested; CancelRequested)
        {
          Caption = 'Cancel Requested';
          ToolTip = 'Shows an irreversible cancellation request; existing results remain.';
        }
        field(QueueState; QueueState)
        {
          Caption = 'Current Queue Status';
          ToolTip = 'Shows the current standard job status, a missing entry, or absent read permission. No new job is created.';
        }
      }
      cuegroup(BatchCounts)
      {
        Caption = 'Persisted Batches';
        field(TotalBatches; TotalBatches)
        {
          Caption = 'Total Batches';
          ToolTip = 'Shows all persisted batches for the selected run.';
          trigger OnDrillDown()
          begin
            OpenBatches(false);
          end;
        }
        field(CompleteBatches; CompleteBatches)
        {
          Caption = 'Completed Batches';
          ToolTip = 'Shows confirmed complete batches, without implying overall quality approval.';
        }
        field(ReviewBatches; ReviewBatches)
        {
          Caption = 'Review Required';
          ToolTip = 'Shows failed and uncertain batches. Open for investigation before any retry.';
          trigger OnDrillDown()
          begin
            OpenBatches(true);
          end;
        }
      }
      group(Timing)
      {
        Caption = 'Persisted Times';
        field(EarliestStart; EarliestStart)
        {
          Caption = 'Earliest Start';
          ToolTip = 'Shows the requested earliest start. Scheduler availability may delay processing.';
        }
        field(StartedAt; StartedAt)
        {
          Caption = 'Started At';
          ToolTip = 'Shows the persisted execution start, if claimed.';
        }
        field(FinishedAt; FinishedAt)
        {
          Caption = 'Finished At';
          ToolTip = 'Shows the persisted execution finish, if recorded.';
        }
        field(Elapsed; Elapsed)
        {
          Caption = 'Elapsed Time';
          ToolTip = 'Shows wall-clock time since start, including pauses and queue waits. No remaining-time estimate is promised.';
        }
        field(LastActivity; LastActivity)
        {
          Caption = 'Last Recorded Activity';
          ToolTip = 'Shows the latest persisted execution, control, batch or monitoring change; this is not a worker heartbeat.';
        }
      }
    }
  }
  trigger OnAfterGetRecord()
  var
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Control: Record "BCSF Run Control";
    Job: Record "Job Queue Entry";
    Entry: Record "BCSF Run Event";
    Validation: Codeunit "BCSF Validation Manager";
    EndTime: DateTime;
  begin
    QualityText := Validation.Describe(Rec."Run Id");
    Clear(EarliestStart);
    Clear(StartedAt);
    Clear(FinishedAt);
    Clear(Elapsed);
    TotalBatches := 0;
    CompleteBatches := 0;
    ReviewBatches := 0;
    PauseRequested := false;
    CancelRequested := false;
    LastActivity := Rec."Created At";
    ExecutionState := NotPreparedLbl;
    QueueState := NoJobLbl;
    if Execution.Get(Rec."Run Id") then begin
      ExecutionState := Format(Execution.Status);
      EarliestStart := Execution."Earliest Start";
      StartedAt := Execution."Started At";
      FinishedAt := Execution."Finished At";
      LastActivity := Execution.SystemModifiedAt;
      EndTime := FinishedAt;
      if EndTime = 0DT then
        EndTime := CurrentDateTime();
      if (StartedAt <> 0DT) and (EndTime >= StartedAt) then
        Elapsed := EndTime - StartedAt;
      if not IsNullGuid(Execution."Job Queue Entry Id") then
        if not Job.ReadPermission() then
          QueueState := NoQueueReadLbl
        else
          if Job.Get(Execution."Job Queue Entry Id") then
            QueueState := Format(Job.Status)
          else
            QueueState := MissingJobLbl;
    end;
    if Control.Get(Rec."Run Id") then begin
      PauseRequested := Control."Pause Requested";
      CancelRequested := Control."Cancel Requested";
      if Control.SystemModifiedAt > LastActivity then
        LastActivity := Control.SystemModifiedAt;
    end;
    Batch.SetCurrentKey("Run Id", "Sequence No.");
    Batch.SetRange("Run Id", Rec."Run Id");
    if Batch.FindSet() then
      repeat
        TotalBatches += 1;
        if Batch.Status = Batch.Status::Completed then
          CompleteBatches += 1;
        if Batch.Status in [Batch.Status::Failed, Batch.Status::NeedsReview] then
          ReviewBatches += 1;
        if Batch.SystemModifiedAt > LastActivity then
          LastActivity := Batch.SystemModifiedAt;
      until Batch.Next() = 0;
    Entry.SetCurrentKey("Run Id", "Occurred At", "Entry Id");
    Entry.SetRange("Run Id", Rec."Run Id");
    if Entry.FindLast() then
      if Entry."Occurred At" > LastActivity then
        LastActivity := Entry."Occurred At";
  end;

  local procedure OpenBatches(ReviewOnly: Boolean)
  var
    Batch: Record "BCSF Batch";
  begin
    Batch.SetRange("Run Id", Rec."Run Id");
    if ReviewOnly then
      Batch.SetFilter(Status, '%1|%2', Batch.Status::Failed, Batch.Status::NeedsReview);
    Page.Run(Page::"BCSF Batch List", Batch);
  end;

  var
    ExecutionState: Text;
    QueueState: Text;
    TotalBatches: Integer;
    CompleteBatches: Integer;
    ReviewBatches: Integer;
    EarliestStart: DateTime;
    StartedAt: DateTime;
    FinishedAt: DateTime;
    LastActivity: DateTime;
    Elapsed: Duration;
    PauseRequested: Boolean;
    CancelRequested: Boolean;
    QualityText: Text;
    NotPreparedLbl: Label 'Not prepared';
    NoJobLbl: Label 'No current queue reference';
    NoQueueReadLbl: Label 'Queue read permission missing';
    MissingJobLbl: Label 'Queue entry absent or not visible; review standard logs';
}
