namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.SetupManager;

pageextension 90359 "BCSF Wizard Execution" extends "BCSF Scenario Wizard"
{
  layout
  {
    addlast(Review)
    {
      field(EarliestStart; EarliestStart)
      {
        ApplicationArea = All;
        Caption = 'Earliest Start';
        ToolTip = 'Specifies the requested earliest queue start. Leave blank for now; scheduler availability may delay execution.';
      }
      field(ApproveExecution; ApproveExecution)
      {
        ApplicationArea = All;
        Caption = 'Approve Sandbox Execution';
        ToolTip = 'Specifies explicit consent to the captured run. Does not authorize posting, setup changes or override any start blocker.';
      }
    }
  }
  actions
  {
    addlast(Processing)
    {
      action(ReviewDependencies)
      {
        ApplicationArea = All;
        Caption = 'Review Dependencies';
        ToolTip = 'Shows the complete graph and concrete blockers from the captured run. Does not add missing targets or generate data.';
        Image = Planning;
        InFooterBar = true;
        Enabled = ReviewReady;
        trigger OnAction()
        var
          Preview: Page "BCSF Plan Preview";
        begin
          Preview.SetRunId(GetCapturedRunId());
          Preview.RunModal();
        end;
      }
      action(ReviewSetup)
      {
        ApplicationArea = All;
        Caption = 'Review Setup Preflight';
        ToolTip = 'Reads current setup and permissions for the captured targets. No setup changes or approvals are applied.';
        Image = Check;
        InFooterBar = true;
        Enabled = ReviewReady;
        trigger OnAction()
        var
          Preview: Page "BCSF Setup Diff Preview";
        begin
          Preview.SetRunId(GetCapturedRunId());
          Preview.RunModal();
        end;
      }
      action(SaveReviewPlan)
      {
        ApplicationArea = All;
        Caption = 'Save Review Plan';
        ToolTip = 'Persists the first immutable dependency plan, including blockers, without preparing or starting execution.';
        Image = Save;
        InFooterBar = true;
        Enabled = ReviewReady;
        trigger OnAction()
        var
          Writer: Codeunit "BCSF Plan Writer";
        begin
          Writer.SavePlan(GetCapturedRunId());
        end;
      }
      action(ApproveAndSchedule)
      {
        ApplicationArea = All;
        Caption = 'Approve and Schedule';
        ToolTip = 'Requires explicit approval, reruns current start gates and schedules through the existing dispatcher. Blockers prevent all work; posting stays blocked.';
        Image = Task;
        InFooterBar = true;
        Enabled = ReviewReady;
        trigger OnAction()
        var
          Execution: Record "BCSF Run Execution";
          Writer: Codeunit "BCSF Plan Writer";
          Dispatcher: Codeunit "BCSF Queue Dispatcher";
          RunId: Guid;
        begin
          RunId := GetCapturedRunId();
          if not ApproveExecution then
            Error(ApprovalErr);
          if not Confirm(ScheduleQst, false) then
            exit;
          Writer.SavePlan(RunId);
          if not Execution.Get(RunId) then
            Dispatcher.Prepare(RunId);
          Dispatcher.Schedule(RunId, EarliestStart);
          ApproveExecution := false;
          CurrPage.Update(false);
          Message(ScheduledLbl);
        end;
      }
      action(ViewDashboard)
      {
        ApplicationArea = All;
        Caption = 'Dashboard';
        ToolTip = 'Opens persisted monitoring without starting any work.';
        Image = Statistics;
        InFooterBar = true;
        Enabled = ReviewReady;
        trigger OnAction()
        var
          Header: Record "BCSF Run Header";
        begin
          Header.SetRange("Run Id", GetCapturedRunId());
          Page.Run(Page::"BCSF Dashboard Host", Header);
        end;
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  begin
    ReviewReady := IsReviewStep();
  end;
  var
    ReviewReady: Boolean;
    EarliestStart: DateTime;
    ApproveExecution: Boolean;
    ApprovalErr: Label 'Explicitly approve sandbox execution before scheduling the captured run.';
    ScheduleQst: Label 'Schedule this captured run in the approved sandbox? Current checks must pass. No setup changes or posting are approved.';
    ScheduledLbl: Label 'Execution scheduled. Review persisted progress on the dashboard.';
}
