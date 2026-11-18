namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.SetupManager;
using System.Threading;

codeunit 90366 "BCSF Dashboard Commands"
{
  Access = Internal;

  procedure ParseRunId(Value: Text): Guid
  var
    Header: Record "BCSF Run Header";
    RunId: Guid;
  begin
    if (StrLen(Value) > 38) or not Evaluate(RunId, Value) then
      Error(InvalidRunErr);
    if IsNullGuid(RunId) then
      Error(InvalidRunErr);
    Header.Get(RunId);
    exit(RunId);
  end;

  procedure Execute(ActionCode: Text; RunIdText: Text)
  var
    Header: Record "BCSF Run Header";
    Scenario: Record "BCSF Scenario";
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    // No client-supplied page, table, method, company, filter or approval is accepted.
    case ActionCode of
      'new':
        begin
          Scenario.Get(Manager.CreateScenario());
          Page.Run(Page::"BCSF Scenario Wizard", Scenario);
        end;
      'scenarios': Page.Run(Page::"BCSF Scenario List");
      'runs': Page.Run(Page::"BCSF Run List");
      'monitor': Page.Run(Page::"BCSF Factory Dashboard");
      'executions': Page.Run(Page::"BCSF Execution List");
      'allBatches': Page.Run(Page::"BCSF Batch List");
      'allRecords': Page.Run(Page::"BCSF Generated Records");
      'catalog': Page.Run(Page::"BCSF Generator Catalog");
      'setup': Page.Run(Page::"BCSF Factory Setup Card");
      'run', 'scenario', 'wizard', 'progress', 'plan', 'savePlan', 'readiness', 'preflight', 'synthetic',
      'prepare', 'schedule', 'pause', 'cancel', 'apply', 'resume', 'batches', 'history', 'records', 'queue', 'primary':
        begin
          Header.Get(ParseRunId(RunIdText));
          ExecuteRunAction(ActionCode, Header);
        end;
      else
        Error(UnknownActionErr);
    end;
  end;

  local procedure ExecuteRunAction(ActionCode: Text; Header: Record "BCSF Run Header")
  var
    Scenario: Record "BCSF Scenario";
    Batch: Record "BCSF Batch";
    Entry: Record "BCSF Run Event";
    Generated: Record "BCSF Generated Record";
    Job: Record "Job Queue Entry";
    Execution: Record "BCSF Run Execution";
    Monitor: Codeunit "BCSF Monitoring Mgt";
    QuickRun: Codeunit "BCSF Quick Scenario Run";
    Writer: Codeunit "BCSF Plan Writer";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
    Recovery: Codeunit "BCSF Batch Recovery";
    ProgressPage: Page "BCSF Step Progress";
    Plan: Page "BCSF Plan Preview";
    Preflight: Page "BCSF Setup Diff Preview";
    ScheduleRequest: Page "BCSF Schedule Request";
  begin
    case ActionCode of
      'primary':
        begin
          if Execution.Get(Header."Run Id") then
            case Execution.Status of
              Execution.Status::Failed, Execution.Status::ValidationFailed:
                begin
                  Monitor.ShowFailure(Header."Run Id");
                  exit;
                end;
              Execution.Status::Completed, Execution.Status::CompletedWithWarnings:
                begin
                  Generated.SetRange("Run Id", Header."Run Id");
                  Page.Run(Page::"BCSF Generated Records", Generated);
                  exit;
                end;
              Execution.Status::Queued, Execution.Status::Scheduled, Execution.Status::Running, Execution.Status::ResumePending:
                begin
                  ProgressPage.SetRunId(Header."Run Id");
                  ProgressPage.Run();
                  exit;
                end;
              Execution.Status::Ready:
                begin
                  QuickRun.StartCaptured(Header."Run Id");
                  exit;
                end;
              else begin
                Page.Run(Page::"BCSF Run Card", Header);
                exit;
              end;
            end;
          QuickRun.StartCaptured(Header."Run Id");
        end;
      'run': Page.Run(Page::"BCSF Run Card", Header);
      'scenario', 'wizard':
        begin
          Scenario.Get(Header."Scenario Id");
          if ActionCode = 'wizard' then
            Page.Run(Page::"BCSF Scenario Wizard", Scenario)
          else
            Page.Run(Page::"BCSF Scenario Card", Scenario);
        end;
      'progress':
        begin
          ProgressPage.SetRunId(Header."Run Id");
          ProgressPage.Run();
        end;
      'plan':
        begin
          Plan.SetRunId(Header."Run Id");
          Plan.Run();
        end;
      'savePlan':
        if Confirm(SavePlanQst, false) then
          Writer.SavePlan(Header."Run Id");
      'readiness':
        begin
          Writer.CheckStart(Header."Run Id");
          Message(ReadyLbl);
        end;
      'preflight':
        begin
          Preflight.SetRunId(Header."Run Id");
          Preflight.Run();
        end;
      'synthetic': PreviewSynthetic(Header."Run Id");
      'prepare':
        if Confirm(PrepareQst, false) then
          Dispatcher.Prepare(Header."Run Id");
      'schedule':
        begin
          if ScheduleRequest.RunModal() <> Action::OK then
            exit;
          if Confirm(ScheduleQst, false) then
            Dispatcher.Schedule(Header."Run Id", ScheduleRequest.GetEarliestStart());
        end;
      'pause':
        if Confirm(PauseQst, false) then
          Recovery.RequestStop(Header."Run Id", false);
      'cancel':
        if Confirm(CancelQst, false) then
          Recovery.RequestStop(Header."Run Id", true);
      'apply':
        if Confirm(ApplyQst, false) then
          Recovery.ApplyRequests(Header."Run Id");
      'resume':
        if Confirm(ResumeQst, false) then
          Recovery.ResumeRun(Header."Run Id");
      'batches':
        begin
          Batch.SetRange("Run Id", Header."Run Id");
          Page.Run(Page::"BCSF Batch List", Batch);
        end;
      'history':
        begin
          Entry.SetRange("Run Id", Header."Run Id");
          Page.Run(Page::"BCSF Run Events", Entry);
        end;
      'records':
        begin
          Generated.SetRange("Run Id", Header."Run Id");
          Page.Run(Page::"BCSF Generated Records", Generated);
        end;
      'queue':
        begin
          Execution.Get(Header."Run Id");
          if IsNullGuid(Execution."Job Queue Entry Id") or not Job.Get(Execution."Job Queue Entry Id") then
            Error(MissingJobErr);
          Job.TestField("Object Type to Run", Job."Object Type to Run"::Codeunit);
          Job.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
          Page.Run(Page::"Job Queue Entry Card", Job);
        end;
    end;
  end;

  local procedure PreviewSynthetic(RunId: Guid)
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Engine: Codeunit "BCSF Seed Engine";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Values: JsonObject;
  begin
    Manager.ReadSnapshot(RunId, Context);
    Values := Engine.BuildValues(Context, 'ITEM', '1');
    Message(PreviewLbl, Contract.GetText(Values, 'companyName'), Contract.GetText(Values, 'personName'),
      Contract.GetText(Values, 'itemDescription'), Contract.GetText(Values, 'unitPrice'), Contract.GetText(Values, 'date'));
  end;

  var
    InvalidRunErr: Label 'Select an existing captured run in the current company.';
    UnknownActionErr: Label 'This dashboard action is not supported.';
    MissingJobErr: Label 'This run has no visible current queue entry. Review its batches and queue logs.';
    SavePlanQst: Label 'Save the first immutable plan for this captured run, including any blockers?';
    PrepareQst: Label 'Recheck all current start gates and prepare execution batches for this run? No job starts yet.';
    ScheduleQst: Label 'Schedule this prepared execution in the approved sandbox? It may create business data. Posting remains blocked.';
    PauseQst: Label 'Pause this execution before its next unclaimed batch?';
    CancelQst: Label 'Cancel all unstarted work? Existing results remain. This cancellation cannot be resumed.';
    ApplyQst: Label 'Apply pending pause or cancellation requests at a safe boundary?';
    ResumeQst: Label 'Recheck permissions, prerequisites and confirmed checkpoints, then resume only verified pending work?';
    ReadyLbl: Label 'Start checks passed. No processing was started.';
    PreviewLbl: Label 'Synthetic company: %1\Synthetic person: %2\Synthetic item: %3\Sample unit price: %4\Sample date: %5', Comment = '%1 = company, %2 = person, %3 = item, %4 = price, %5 = date';
}
