namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.ScenarioManagement;

pageextension 90312 "BCSF Run Queue" extends "BCSF Run Card"
{
  layout
  {
    modify(Status)
    {
      Caption = 'Captured Initial Status';
      ToolTip = 'Shows the immutable initial status. The current processing status is shown separately under Execution.';
    }
    addlast(Content)
    {
      group(ExecutionOverview)
      {
        Caption = 'Execution';
        field(ExecutionStatus; ExecutionStatus)
        {
          ApplicationArea = All;
          Caption = 'Current Execution Status';
          ToolTip = 'Shows the persisted execution state. Completed with Warnings means batch execution ended; overall quality validation remains separate.';
          Editable = false;
        }
      }
    }
  }
  actions
  {
    addlast(Processing)
    {
      action(PrepareBatches)
      {
        ApplicationArea = All;
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
      action(ViewExecution)
      {
        ApplicationArea = All;
        Caption = 'View Execution';
        ToolTip = 'Shows the current execution status, confirmed batch counts, requested start and current job reference.';
        Image = View;
        RunObject = page "BCSF Execution List";
        RunPageLink = "Run Id" = field("Run Id");
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
  begin
    ExecutionStatus := NotPreparedLbl;
    if Execution.Get(Rec."Run Id") then
      ExecutionStatus := Format(Execution.Status);
  end;
  var
    ExecutionStatus: Text;
    NotPreparedLbl: Label 'Not prepared';
    ScheduleQst: Label 'Schedule this prepared execution in the approved sandbox? It will run in the background and may create business data. Posting remains blocked.';
}
