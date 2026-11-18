namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using System.Globalization;

codeunit 90365 "BCSF Dashboard Data"
{
  Access = Internal;

  procedure Build(var SelectedRunId: Guid): Text
  var
    Header: Record "BCSF Run Header";
    Scenario: Record "BCSF Scenario";
    Execution: Record "BCSF Run Execution";
    Language: Codeunit Language;
    Payload: JsonObject;
    Texts: JsonObject;
    Summary: JsonObject;
    Runs: JsonArray;
    Item: JsonObject;
    Result: Text;
    RunCount: Integer;
  begin
    Payload.Add('schemaVersion', 1);
    Payload.Add('locale', Language.GetCurrentCultureName());
    Payload.Add('language', Language.GetCultureName(GlobalLanguage()));
    AddTexts(Texts);
    Payload.Add('texts', Texts);
    Payload.Add('readAt', Format(CurrentDateTime()));
    Summary.Add('templates', Scenario.Count());
    Summary.Add('runs', Header.Count());
    Execution.SetFilter(Status, '%1|%2|%3|%4', "BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled,
      "BCSF Run Status"::Running, "BCSF Run Status"::ResumePending);
    Summary.Add('active', Execution.Count());
    Execution.SetFilter(Status, '%1|%2', "BCSF Run Status"::Failed, "BCSF Run Status"::ValidationFailed);
    Summary.Add('review', Execution.Count());
    Payload.Add('summary', Summary);
    Header.SetCurrentKey("Created At", "Run Id");
    Header.SetAscending("Created At", false);
    Header.SetAscending("Run Id", false);
    if Header.Find('-') then
      repeat
        Item := DescribeRun(Header);
        Runs.Add(Item);
        if IsNullGuid(SelectedRunId) then
          SelectedRunId := Header."Run Id";
        RunCount += 1;
      until (Header.Next() = 0) or (RunCount = 25);
    Payload.Add('runs', Runs);
    Payload.Add('hasSelection', not IsNullGuid(SelectedRunId));
    if not IsNullGuid(SelectedRunId) then begin
      Header.Get(SelectedRunId);
      Item := DescribeRun(Header);
      AddExecution(Header."Run Id", Item);
      Payload.Add('selected', Item);
      Payload.Add('steps', DescribeSteps(Header."Run Id"));
    end;
    Payload.WriteTo(Result);
    exit(Result);
  end;

  local procedure DescribeRun(Header: Record "BCSF Run Header"): JsonObject
  var
    Execution: Record "BCSF Run Execution";
    Item: JsonObject;
  begin
    Item.Add('id', Format(Header."Run Id", 0, 4));
    Item.Add('description', Header.Description);
    Item.Add('profile', Header."Profile Code");
    Item.Add('createdAt', Format(Header."Created At"));
    Item.Add('processMode', Format(Header."Process Mode"));
    if Execution.Get(Header."Run Id") then
      Item.Add('status', Format(Execution.Status))
    else
      Item.Add('status', NotPreparedLbl);
    exit(Item);
  end;

  local procedure AddExecution(RunId: Guid; var Item: JsonObject)
  var
    Execution: Record "BCSF Run Execution";
    Control: Record "BCSF Run Control";
    Batch: Record "BCSF Batch";
    Header: Record "BCSF Run Header";
    TempTarget: Record "BCSF Data Target" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Validation: Codeunit "BCSF Validation Manager";
    CanStart: Boolean;
  begin
    Header.Get(RunId);
    CanStart := Header."Process Mode" = "BCSF Process Mode"::SetupAndMasterData;
    Manager.LoadFrozenTargets(RunId, TempTarget);
    TempTarget.SetFilter(Quantity, '>0');
    CanStart := CanStart and not TempTarget.IsEmpty();
    if TempTarget.FindSet() then
      repeat
        CanStart := CanStart and (TempTarget.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor]);
      until TempTarget.Next() = 0;
    Item.Add('canStart', CanStart);
    Item.Add('quality', Validation.Describe(RunId));
    Item.Add('hasExecution', Execution.Get(RunId));
    Item.Add('statusCode', Execution.Status.AsInteger());
    Batch.SetRange("Run Id", RunId);
    Batch.SetFilter(Status, '%1|%2|%3', Batch.Status::Failed, Batch.Status::NeedsReview, Batch.Status::Running);
    Item.Add('canResume', (Execution.Status = Execution.Status::Paused) or
      ((Execution.Status = Execution.Status::Failed) and Batch.IsEmpty()));
    Item.Add('totalBatches', Execution."Total Batches");
    Item.Add('completedBatches', Execution."Completed Batches");
    Item.Add('earliest', Format(Execution."Earliest Start"));
    Item.Add('started', Format(Execution."Started At"));
    Item.Add('finished', Format(Execution."Finished At"));
    if Control.Get(RunId) then begin
      Item.Add('pauseRequested', Control."Pause Requested");
      Item.Add('cancelRequested', Control."Cancel Requested");
    end;
  end;

  local procedure DescribeSteps(RunId: Guid): JsonArray
  var
    TempMetric: Record "BCSF Step Metric" temporary;
    Monitor: Codeunit "BCSF Monitoring Mgt";
    Policy: Codeunit "BCSF Scenario Policy";
    Items: JsonArray;
    Item: JsonObject;
  begin
    Monitor.LoadSteps(RunId, TempMetric);
    if TempMetric.FindSet() then
      repeat
        Clear(Item);
        Item.Add('node', TempMetric."Node Code");
        Item.Add('module', Policy.GetModuleName(TempMetric."Module Code"));
        Item.Add('entity', Policy.GetEntityName(TempMetric."Entity Code"));
        Item.Add('target', TempMetric."Planned Units");
        Item.Add('confirmed', TempMetric."Confirmed Units");
        Item.Add('remaining', TempMetric."Remaining Units");
        Item.Add('artifacts', TempMetric."Created Artifacts");
        Item.Add('percent', TempMetric."Progress Percent");
        Item.Add('state', TempMetric.State);
        Item.Add('external', TempMetric."External Check");
        Items.Add(Item);
      until TempMetric.Next() = 0;
    exit(Items);
  end;

  local procedure AddTexts(var Texts: JsonObject)
  begin
    Texts.Add('primaryStart', PrimaryStartLbl);
    Texts.Add('primaryProgress', PrimaryProgressLbl);
    Texts.Add('primaryErrors', PrimaryErrorsLbl);
    Texts.Add('primaryResults', PrimaryResultsLbl);
    Texts.Add('diagnostics', DiagnosticsLbl);
    Texts.Add('title' , TitleLbl);
    Texts.Add('eyebrow', EyebrowLbl);
    Texts.Add('subtitle', SubtitleLbl);
    Texts.Add('new', NewLbl);
    Texts.Add('refresh', RefreshLbl);
    Texts.Add('navigation', NavigationLbl);
    Texts.Add('scenarios', ScenariosLbl);
    Texts.Add('scenariosHint', ScenariosHintLbl);
    Texts.Add('runs', RunsLbl);
    Texts.Add('runsHint', RunsHintLbl);
    Texts.Add('executions', ExecutionsLbl);
    Texts.Add('executionsHint', ExecutionsHintLbl);
    Texts.Add('allBatches', AllBatchesLbl);
    Texts.Add('allBatchesHint', AllBatchesHintLbl);
    Texts.Add('allRecords', AllRecordsLbl);
    Texts.Add('allRecordsHint', AllRecordsHintLbl);
    Texts.Add('catalog', CatalogLbl);
    Texts.Add('catalogHint', CatalogHintLbl);
    Texts.Add('setup', SetupLbl);
    Texts.Add('setupHint', SetupHintLbl);
    Texts.Add('monitor', MonitorLbl);
    Texts.Add('monitorHint', MonitorHintLbl);
    Texts.Add('templateCount', TemplateCountLbl);
    Texts.Add('runCount', RunCountLbl);
    Texts.Add('activeCount', ActiveCountLbl);
    Texts.Add('reviewCount', ReviewCountLbl);
    Texts.Add('recent', RecentLbl);
    Texts.Add('window', WindowLbl);
    Texts.Add('empty', EmptyLbl);
    Texts.Add('choose', ChooseLbl);
    Texts.Add('noSelection', NoSelectionLbl);
    Texts.Add('quality', QualityLbl);
    Texts.Add('planGroup', PlanGroupLbl);
    Texts.Add('executeGroup', ExecuteGroupLbl);
    Texts.Add('resultGroup', ResultGroupLbl);
    Texts.Add('run', RunLbl);
    Texts.Add('scenario', ScenarioLbl);
    Texts.Add('wizard', WizardLbl);
    Texts.Add('progress', ProgressLbl);
    Texts.Add('plan', PlanLbl);
    Texts.Add('savePlan', SavePlanLbl);
    Texts.Add('readiness', ReadinessLbl);
    Texts.Add('preflight', PreflightLbl);
    Texts.Add('synthetic', SyntheticLbl);
    Texts.Add('prepare', PrepareLbl);
    Texts.Add('schedule', ScheduleLbl);
    Texts.Add('pause', PauseLbl);
    Texts.Add('cancel', CancelLbl);
    Texts.Add('apply', ApplyLbl);
    Texts.Add('resume', ResumeLbl);
    Texts.Add('batches', BatchesLbl);
    Texts.Add('history', HistoryLbl);
    Texts.Add('records', RecordsLbl);
    Texts.Add('queue', QueueLbl);
    Texts.Add('steps', StepsLbl);
    Texts.Add('entity', EntityLbl);
    Texts.Add('target', TargetLbl);
    Texts.Add('confirmed', ConfirmedLbl);
    Texts.Add('remaining', RemainingLbl);
    Texts.Add('artifacts', ArtifactsLbl);
    Texts.Add('status', StatusLbl);
    Texts.Add('noSteps', NoStepsLbl);
    Texts.Add('external', ExternalLbl);
    Texts.Add('notPrepared', NotPreparedLbl);
    Texts.Add('completedBatches', CompletedBatchesLbl);
    Texts.Add('totalBatches', TotalBatchesLbl);
    Texts.Add('earliest', EarliestLbl);
    Texts.Add('started', StartedLbl);
    Texts.Add('finished', FinishedLbl);
    Texts.Add('pauseRequested', PauseRequestedLbl);
    Texts.Add('cancelRequested', CancelRequestedLbl);
    Texts.Add('updated', UpdatedLbl);
    Texts.Add('busy', BusyLbl);
    Texts.Add('error', ErrorLbl);
    Texts.Add('requirements', RequirementsLbl);
    Texts.Add('notRecorded', NotRecordedLbl);
    Texts.Add('selected', SelectedLbl);
  end;

  var
    PrimaryStartLbl: Label 'Start';
    PrimaryProgressLbl: Label 'View Progress';
    PrimaryErrorsLbl: Label 'Show Errors';
    PrimaryResultsLbl: Label 'Open Results';
    DiagnosticsLbl: Label 'Diagnostics';
    TitleLbl: Label 'Scenario Factory';
    EyebrowLbl: Label 'SCENARIO WORKSPACE';
    SubtitleLbl: Label 'Define scenarios. Plan with confidence. Follow every run.';
    NewLbl: Label 'New scenario';
    RefreshLbl: Label 'Refresh';
    NavigationLbl: Label 'Your workspace';
    ScenariosLbl: Label 'Scenario templates';
    ScenariosHintLbl: Label 'Define modules, targets, seed and process scope.';
    RunsLbl: Label 'Captured runs';
    RunsHintLbl: Label 'Open frozen configurations and run actions.';
    ExecutionsLbl: Label 'Executions';
    ExecutionsHintLbl: Label 'Review persisted execution states.';
    AllBatchesLbl: Label 'Batches & recovery';
    AllBatchesHintLbl: Label 'Inspect packages, retries and queue logs.';
    AllRecordsLbl: Label 'Generated records';
    AllRecordsHintLbl: Label 'Trace generated records and document chains.';
    CatalogLbl: Label 'Generator catalog';
    CatalogHintLbl: Label 'Inspect capabilities and contract checks.';
    SetupLbl: Label 'Factory setup';
    SetupHintLbl: Label 'Configure sandbox, company, limits and languages.';
    MonitorLbl: Label 'Run monitor';
    MonitorHintLbl: Label 'Open the native run list and execution FactBox.';
    TemplateCountLbl: Label 'Templates';
    RunCountLbl: Label 'Captured runs';
    ActiveCountLbl: Label 'Active executions';
    ReviewCountLbl: Label 'Failed executions';
    RecentLbl: Label 'Recent captured runs';
    WindowLbl: Label 'Up to 25 recent runs. Open Captured runs for full history.';
    EmptyLbl: Label 'No captured runs yet. Create a scenario to get started.';
    ChooseLbl: Label 'Selected run';
    NoSelectionLbl: Label 'Select a run to view progress and run-specific actions.';
    QualityLbl: Label 'Final validation is not recorded for this run.';
    PlanGroupLbl: Label 'Plan & inspect';
    ExecuteGroupLbl: Label 'Execute & control';
    ResultGroupLbl: Label 'Results & diagnostics';
    RunLbl: Label 'Run card';
    ScenarioLbl: Label 'Source template';
    WizardLbl: Label 'Configure with wizard';
    ProgressLbl: Label 'Step details';
    PlanLbl: Label 'Dependency preview';
    SavePlanLbl: Label 'Save dependency plan';
    ReadinessLbl: Label 'Check readiness';
    PreflightLbl: Label 'Setup preflight';
    SyntheticLbl: Label 'Synthetic input preview';
    PrepareLbl: Label 'Prepare batches';
    ScheduleLbl: Label 'Approve & schedule';
    PauseLbl: Label 'Request pause';
    CancelLbl: Label 'Request cancellation';
    ApplyLbl: Label 'Apply saved requests';
    ResumeLbl: Label 'Resume from checkpoints';
    BatchesLbl: Label 'Batches & queue logs';
    HistoryLbl: Label 'Status history';
    RecordsLbl: Label 'Provenance records';
    QueueLbl: Label 'Current queue entry';
    StepsLbl: Label 'Entity progress';
    EntityLbl: Label 'Module / entity';
    TargetLbl: Label 'Target';
    ConfirmedLbl: Label 'Confirmed units';
    RemainingLbl: Label 'Outstanding';
    ArtifactsLbl: Label 'Artifacts';
    StatusLbl: Label 'Status';
    NoStepsLbl: Label 'No positive entity targets are available.';
    ExternalLbl: Label 'External prerequisite';
    NotPreparedLbl: Label 'Not prepared';
    CompletedBatchesLbl: Label 'Confirmed batches';
    TotalBatchesLbl: Label 'Total batches';
    EarliestLbl: Label 'Earliest start';
    StartedLbl: Label 'Started';
    FinishedLbl: Label 'Finished';
    PauseRequestedLbl: Label 'Pause requested';
    CancelRequestedLbl: Label 'Cancellation requested';
    UpdatedLbl: Label 'Read at';
    BusyLbl: Label 'Working…';
    ErrorLbl: Label 'The action could not be completed. Review the Business Central message and try again.';
    RequirementsLbl: Label 'Missing generators or prerequisites block execution. Posting requires a separate authorization contract.';
    NotRecordedLbl: Label 'Not recorded';
    SelectedLbl: Label 'Selected';
}
