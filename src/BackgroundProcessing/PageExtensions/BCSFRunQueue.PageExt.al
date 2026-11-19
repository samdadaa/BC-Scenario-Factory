namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.ScenarioManagement;

pageextension 90312 "BCSF Run Queue" extends "BCSF Run Card"
{
  layout
  {
    modify(Status)
    {
      Caption = 'Historical Initial Status';
      Importance = Additional;
      ToolTip = 'Shows the immutable initial status. The current processing status is shown separately under Execution.';
    }
    addlast(Content)
    {
      group(ExecutionOverview)
      {
        Caption = 'Execution Diagnostics';
        field(PauseRequest; PauseRequestValue)
        {
          ApplicationArea = All;
          Caption = 'Pause Requested';
          ToolTip = 'Shows a saved pause request; current execution status changes only at a safe boundary.';
          Editable = false;
        }
        field(CancelRequest; CancelRequestValue)
        {
          ApplicationArea = All;
          Caption = 'Cancel Requested';
          ToolTip = 'Shows an irreversible cancellation request. Existing and uncertain results remain available for review.';
          Editable = false;
        }

      }
    }
  }
  actions
  {
    addlast(Diagnostics)
    {
      action(PauseExecution)
      {
        ApplicationArea = All;
        Visible = CanStop;
        Caption = 'Request Pause';
        ToolTip = 'Saves a pause request. A running batch completes before processing stops at a safe boundary.';
        Image = Action;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(PauseExecutionQst, false) then
            exit;
          Recovery.RequestStop(Rec."Run Id", false);
          CurrPage.Update(false);
        end;
      }
      action(CancelExecution)
      {
        ApplicationArea = All;
        Visible = CanStop;
        Caption = 'Request Cancellation';
        ToolTip = 'Cancels only unstarted work at a safe boundary. Existing records, postings and uncertain results are retained.';
        Image = Action;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(CancelExecutionQst, false) then
            exit;
          Recovery.RequestStop(Rec."Run Id", true);
          CurrPage.Update(false);
        end;
      }
      action(ApplyControl)
      {
        ApplicationArea = All;
        Visible = CanStop;
        Caption = 'Apply Pending Requests';
        ToolTip = 'Applies saved pause or cancellation requests when no batch is actively running. Does not terminate a worker.';
        Image = Action;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          Recovery.ApplyRequests(Rec."Run Id");
          CurrPage.Update(false);
        end;
      }
      action(ResumeExecution)
      {
        ApplicationArea = All;
        Visible = CanResume;
        Caption = 'Resume from Checkpoints';
        ToolTip = 'Revalidates completed checkpoints and schedules only pending work. Uncertain batches and exhausted retry limits remain blocked.';
        Image = Action;
        trigger OnAction()
        var
          Recovery: Codeunit "BCSF Batch Recovery";
        begin
          if not Confirm(ResumeExecutionQst, false) then
            exit;
          Recovery.ResumeRun(Rec."Run Id");
          CurrPage.Update(false);
        end;
      }
      action(PrepareBatches)
      {
        ApplicationArea = All;
        Visible = CanPrepare;
        Caption = 'Prepare Execution Batches';
        ToolTip = 'Rechecks the saved plan and all start gates, then atomically saves a serial batch plan. Blockers prevent preparation.';
        Image = Planning;
        trigger OnAction()
        var
          Dispatcher: Codeunit "BCSF Queue Dispatcher";
        begin
          Dispatcher.Prepare(Rec."Run Id");
          CurrPage.Update(false);
        end;
      }
      action(ScheduleExecution)
      {
        ApplicationArea = All;
        Visible = CanSchedule;
        Caption = 'Schedule Prepared Execution';
        ToolTip = 'Requests an earliest start for prepared work. Rechecks authorization and schedules one background batch at a time with automatic retry disabled.';
        Image = Task;
        trigger OnAction()
        var
          Dispatcher: Codeunit "BCSF Queue Dispatcher";
          Request: Page "BCSF Schedule Request";
        begin
          if Request.RunModal() <> Action::OK then
            exit;
          if not Confirm(ScheduleQst, false) then
            exit;
          Dispatcher.Schedule(Rec."Run Id", Request.GetEarliestStart());
          CurrPage.Update(false);
        end;
      }
      action(ViewBatches)
      {
        ApplicationArea = All;
        Caption = 'View Batches';
        ToolTip = 'Shows the persisted batches and their confirmed progress for this execution.';
        Image = List;
        RunObject = page "BCSF Batch List";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Execution: Record "BCSF Run Execution";
    Control: Record "BCSF Run Control";
    Batch: Record "BCSF Batch";
  begin
    PauseRequestValue := false;
    CancelRequestValue := false;
    if Control.Get(Rec."Run Id") then begin
      PauseRequestValue := Control."Pause Requested";
      CancelRequestValue := Control."Cancel Requested";
    end;
    ExecutionStatus := NotPreparedLbl;
    CanPrepare := not Execution.Get(Rec."Run Id");
    CanSchedule := not CanPrepare and (Execution.Status = Execution.Status::Ready);
    CanStop := not CanPrepare and (Execution.Status in [Execution.Status::Ready, Execution.Status::Queued, Execution.Status::Scheduled, Execution.Status::Running]);
    CanResume := not CanPrepare and (Execution.Status = Execution.Status::Paused);
    if not CanPrepare and (Execution.Status = Execution.Status::Failed) then begin
      Batch.SetRange("Run Id", Rec."Run Id");
      Batch.SetFilter(Status, '%1|%2|%3', Batch.Status::Failed, Batch.Status::NeedsReview, Batch.Status::Running);
      CanResume := Batch.IsEmpty();
    end;
    if not CanPrepare then
      ExecutionStatus := Format(Execution.Status);
  end;
  var
    ExecutionStatus: Text;
    CanPrepare: Boolean;
    CanSchedule: Boolean;
    CanStop: Boolean;
    CanResume: Boolean;
    PauseRequestValue: Boolean;
    CancelRequestValue: Boolean;
    PauseExecutionQst: Label 'Pause this execution before its next unclaimed batch?';
    CancelExecutionQst: Label 'Cancel all unstarted work? Existing results will remain and this cancellation cannot be resumed.';
    ResumeExecutionQst: Label 'Resume verified pending work after checking current permissions, prerequisites and confirmed checkpoints?';
    NotPreparedLbl: Label 'Not prepared';
    ScheduleQst: Label 'Schedule this prepared execution in the approved sandbox? It will run in the background and may create business data. Posting remains blocked.';
}
