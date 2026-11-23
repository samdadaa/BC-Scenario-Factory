namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.IndustryProfiles;
using System.Threading;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using System.Globalization;

codeunit 90365 "BCSF Dashboard Data"
{
  Access = Internal;

  procedure Build(var SelectedRunId: Guid; StockView: JsonObject; var RunStock: JsonObject; var SummaryViews: JsonObject): Text
  var
    Header: Record "BCSF Run Header";
    Setup: Record "BCSF Factory Setup";
    Stock: Codeunit "BCSF Dashboard Stock";
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
    Payload.Add('stock', StockView);
    Payload.Add('company', DescribeCompany());
    Payload.Add('readAt', Format(CurrentDateTime()));
    AddSummary(Summary, SummaryViews);
    Payload.Add('summaryViews', SummaryViews);
    Payload.Add('summary', Summary);
    if Setup.ReadPermission() then
      if Setup.Get(Setup.GetSetupKey()) then
        Payload.Add('initialized', Setup."Company Initialized");
    Header.SecurityFiltering(SecurityFilter::Filtered);
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
      RunStock := Stock.BuildRunResults(Header."Run Id");
      Payload.Add('runStock', RunStock);
    end;
    Payload.WriteTo(Result);
    exit(Result);
  end;

  local procedure DescribeCompany(): JsonObject
  var
    Setup: Record "BCSF Factory Setup";
    Job: Record "Job Queue Entry";
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Policy: Codeunit "BCSF Scenario Policy";
    Profile: Codeunit "BCSF Wholesale Profile";
    Company: JsonObject;
    JobId: Guid;
    EndingDate: Date;
  begin
    Company.Add('name', CompanyName());
    Company.Add('industry', '');
    Company.Add('modules', '');
    Company.Add('period', '');
    Company.Add('chart', '');
    Company.Add('status', NotPreparedLbl);
    Company.Add('error', '');
    Company.Add('phase', FoundationLbl);
    Company.Add('processMode', '');
    Company.Add('hasJob', false);
    if not Setup.ReadPermission() then
      exit(Company);
    if not Setup.Get(Setup.GetSetupKey()) then
      exit(Company);
    if Setup."Company Initialized" then begin
      Company.Replace('status', InitializedLbl);
      Company.Replace('chart', Format(Packages.GetAppliedMode()));
    end else
      if not IsNullGuid(Setup."Industry Job Id") then
        Company.Replace('chart', Format(Setup."Industry Finance Mode"));
    JobId := Setup."Industry Job Id";
    if not IsNullGuid(JobId) then begin
      Company.Replace('industry', WholesaleLbl);
      Company.Replace('modules', Profile.DescribeModules(Setup."Industry Additional Modules"));
      if Setup."Industry Generation Kind" = "BCSF Generation Kind"::Transactions then
        Company.Replace('modules', StrSubstNo(GenerationScopeLbl, Format(Setup."Industry Generation Kind"),
          Setup."Industry Purchase Selected", Setup."Industry Sales Selected", MasterSourceLabel(Setup."Industry Master Source Id")))
      else
        Company.Replace('modules', Format(Setup."Industry Generation Kind") + ' · ' + Profile.DescribeModules(Setup."Industry Additional Modules"));
      EndingDate := Setup."Industry Ending Date";
      if EndingDate = 0D then
        EndingDate := Setup."Industry Date";
      Company.Replace('period', StrSubstNo(PeriodLbl, Setup."Industry Date", EndingDate));
      case Setup."Industry Process Mode" of
        "BCSF Process Mode"::PostedMovements: Company.Replace('processMode', PostedWithoutPaymentsLbl);
        "BCSF Process Mode"::FollowUpProcesses: Company.Replace('processMode', PostedWithPaymentsLbl);
        else Company.Replace('processMode', Format(Setup."Industry Process Mode"));
      end;
    end;
    if not IsNullGuid(Setup."Industry Run Id") then begin
      Company.Add('runId', Format(Setup."Industry Run Id", 0, 4));
      Company.Add('steps', DescribeSteps(Setup."Industry Run Id"));
      if Execution.ReadPermission() then
        if Execution.Get(Setup."Industry Run Id") then begin
          Company.Replace('status', Format(Execution.Status));
          JobId := Execution."Job Queue Entry Id";
        end;
    end else
      if not IsNullGuid(JobId) then
        Company.Replace('status', InitializingLbl);
    if not IsNullGuid(Setup."Industry Run Id") and not IsNullGuid(JobId) then begin
      Batch.SetRange("Run Id", Setup."Industry Run Id");
      Batch.SetRange("Job Queue Entry Id", JobId);
      if Batch.ReadPermission() then
        if Batch.FindFirst() then
          Company.Replace('phase', Policy.GetEntityName(Batch."Node Code"));
    end;
    Job.SecurityFiltering(SecurityFilter::Filtered);
    if Job.ReadPermission() and not IsNullGuid(JobId) then
      if Job.Get(JobId) then begin
        Company.Replace('hasJob', true);
        if IsNullGuid(Setup."Industry Run Id") then
          Company.Replace('status', Format(Job.Status));
        if Job.Status = Job.Status::Error then begin
          Company.Replace('status', FailedLbl);
          Company.Replace('error', Job."Error Message");
        end;
      end else
        Company.Replace('status', MissingJobLbl);
    exit(Company);
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
    Severity: Enum "BCSF Validation Severity";
  begin
    Header.Get(RunId);
    AddMasterPool(RunId, Item);
    CanStart := true;
    Manager.LoadFrozenTargets(RunId, TempTarget);
    TempTarget.SetFilter(Quantity, '>0');
    CanStart := CanStart and not TempTarget.IsEmpty();
    if TempTarget.FindSet() then
      repeat
        CanStart := CanStart and Manager.SupportsTarget(TempTarget);
      until TempTarget.Next() = 0;
    Item.Add('canStart', CanStart);
    Item.Add('quality', Validation.Describe(RunId));
    if Validation.GetSummary(RunId, Severity) then
      Item.Add('qualityCode', Severity.AsInteger());
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
        Item.Add('entityCode', TempMetric."Entity Code");
        Item.Add('target', TempMetric."Planned Units");
        Item.Add('confirmed', TempMetric."Confirmed Units");
        Item.Add('remaining', TempMetric."Remaining Units");
        Item.Add('skipped', TempMetric."Skipped Units");
        Item.Add('reviewUnits', TempMetric."Review Units");
        Item.Add('artifacts', TempMetric."Created Artifacts");
        Item.Add('percent', TempMetric."Progress Percent");
        Item.Add('state', TempMetric.State);
        Item.Add('complete', (TempMetric."Total Batches" > 0) and
          (TempMetric."Completed Batches" = TempMetric."Total Batches") and
          (TempMetric."Confirmed Units" = TempMetric."Planned Units"));
        Item.Add('external', TempMetric."External Check");
        Items.Add(Item);
      until TempMetric.Next() = 0;
    exit(Items);
  end;

  local procedure AddSummary(var Summary: JsonObject; var Views: JsonObject)
  var
    Rows: RecordRef;
    View: JsonObject;
    MetricKey: Text;
    MetricKeys: List of [Text];
    Status: Text;
    Count: Integer;
    PageId: Integer;
    CanOpen: Boolean;
  begin
    Clear(Views);
    MetricKeys.Add('templates');
    MetricKeys.Add('runs');
    MetricKeys.Add('active');
    MetricKeys.Add('review');
    foreach MetricKey in MetricKeys do begin
      Clear(View);
      ReadSummary(MetricKey, Rows, PageId, Count, CanOpen, Status);
      if Count >= 0 then
        Summary.Add(MetricKey, Count);
      View.Add('count', Count);
      View.Add('canOpen', CanOpen);
      View.Add('status', Status);
      Views.Add(MetricKey, View);
      Rows.Close();
    end;
  end;

  procedure OpenSummary(MetricKey: Text; LastViews: JsonObject)
  var
    Header: Record "BCSF Run Header";
    Scenario: Record "BCSF Scenario";
    Rows: RecordRef;
    Previous: JsonToken;
    Value: JsonToken;
    Status: Text;
    Count: Integer;
    PageId: Integer;
    CanOpen: Boolean;
  begin
    if not LastViews.Get(MetricKey, Previous) then
      Error(SummaryChangedLbl);
    Previous.AsObject().Get('canOpen', Value);
    if not Value.AsValue().AsBoolean() then
      Error(SummaryChangedLbl);
    ReadSummary(MetricKey, Rows, PageId, Count, CanOpen, Status);
    Previous.AsObject().Get('count', Value);
    if not CanOpen or (Count <> Value.AsValue().AsInteger()) then
      Error(SummaryChangedLbl);
    if MetricKey = 'templates' then begin
      Rows.SetTable(Scenario);
      Page.Run(Page::"BCSF Scenario List", Scenario);
    end else begin
      Rows.SetTable(Header);
      Page.Run(Page::"BCSF Factory Dashboard", Header);
    end;
    Rows.Close();
  end;

  local procedure ReadSummary(MetricKey: Text; var Rows: RecordRef; var PageId: Integer; var Count: Integer; var CanOpen: Boolean; var Status: Text)
  var
    Header: Record "BCSF Run Header";
    Scenario: Record "BCSF Scenario";
    Execution: Record "BCSF Run Execution";
    Stock: Codeunit "BCSF Dashboard Stock";
    Ids: Text;
    Seen: Integer;
  begin
    Count := -1;
    CanOpen := false;
    Status := '';
    if MetricKey = 'templates' then begin
      Scenario.SecurityFiltering(SecurityFilter::Filtered);
      Scenario.FilterGroup(10);
      Scenario.SetRange(Archived, false);
      Scenario.FilterGroup(0);
      Rows.GetTable(Scenario);
      PageId := Page::"BCSF Scenario List";
    end else begin
      Header.SecurityFiltering(SecurityFilter::Filtered);
      Rows.GetTable(Header);
      PageId := Page::"BCSF Factory Dashboard";
    end;
    if not Rows.ReadPermission() or not Stock.CanExecutePage(PageId) then begin
      Status := NoAccessLbl;
      exit;
    end;
    if MetricKey in ['active', 'review'] then begin
      Execution.SecurityFiltering(SecurityFilter::Filtered);
      if not Execution.ReadPermission() then begin
        Status := NoAccessLbl;
        exit;
      end;
      if MetricKey = 'active' then
        Execution.SetFilter(Status, '%1|%2|%3|%4', "BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled,
          "BCSF Run Status"::Running, "BCSF Run Status"::ResumePending)
      else
        Execution.SetFilter(Status, '%1|%2', "BCSF Run Status"::Failed, "BCSF Run Status"::ValidationFailed);
      Count := Execution.Count();
      // A bounded exact ID filter matches the execution counter to the existing header list.
      // Above this bound keep the count readable, without an unfiltered substitute action.
      Execution.SetLoadFields("Run Id");
      if Execution.FindSet() then
        repeat
          Seen += 1;
          if Seen > 150 then begin
            Status := SummaryLimitLbl;
            exit;
          end;
          if Ids <> '' then
            Ids += '|';
          Ids += Format(Execution."Run Id", 0, 4);
        until Execution.Next() = 0;
      if Count = 0 then
        exit;
      Header.FilterGroup(10);
      Header.SetFilter("Run Id", Ids);
      Header.FilterGroup(0);
      Rows.GetTable(Header);
      if Rows.Count() <> Count then begin
        Status := SummaryUnavailableLbl;
        exit;
      end;
    end else
      Count := Rows.Count();
    CanOpen := Count > 0;
  end;

  local procedure AddTexts(var Texts: JsonObject)
  begin
    Texts.Add('dataTab', DataTabLbl);
    Texts.Add('runsTab', RunsTabLbl);
    Texts.Add('selectedRunScope', SelectedRunScopeLbl);
    Texts.Add('unavailableEntities', UnavailableEntitiesLbl);
    Texts.Add('created', CreatedLbl);
    Texts.Add('completed', CompletedLbl);
    Texts.Add('stockTitle', StockTitleLbl);
    Texts.Add('stockMore', StockMoreLbl);
    Texts.Add('stockGenerated', StockGeneratedLbl);
    Texts.Add('stockCompany', StockCompanyLbl);
    Texts.Add('stockAllRuns', StockAllRunsLbl);
    Texts.Add('stockScope', StockScopeLbl);
    Texts.Add('stockRun', StockRunLbl);
    Texts.Add('stockChoose', StockChooseLbl);
    Texts.Add('stockCount', StockCountLbl);
    Texts.Add('stockOpen', StockOpenLbl);
    Texts.Add('primaryStart', PrimaryStartLbl);
    Texts.Add('primaryProgress', PrimaryProgressLbl);
    Texts.Add('primaryErrors', PrimaryErrorsLbl);
    Texts.Add('primaryResults', PrimaryResultsLbl);
    Texts.Add('diagnostics', DiagnosticsLbl);
    Texts.Add('title' , TitleLbl);
    Texts.Add('eyebrow', EyebrowLbl);
    Texts.Add('subtitle', SubtitleLbl);
    Texts.Add('refresh', RefreshLbl);
    Texts.Add('navigation', NavigationLbl);
    Texts.Add('scenarios', ScenariosLbl);
    Texts.Add('scenariosHint', ScenariosHintLbl);
    Texts.Add('runs', RunsLbl);
    Texts.Add('runsHint', RunsHintLbl);
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
    Texts.Add('industrySetup', IndustrySetupLbl);
    Texts.Add('companyQueue', CompanyQueueLbl);
    Texts.Add('companyProgress', CompanyProgressLbl);
    Texts.Add('expertTools', ExpertToolsLbl);
    Texts.Add('workflow', WorkflowLbl);
    Texts.Add('exportPackage', ExportPackageLbl);
    Texts.Add('requirements', RequirementsLbl);
    Texts.Add('notRecorded', NotRecordedLbl);
    Texts.Add('selected', SelectedLbl);
    Texts.Add('skippedUnits', SkippedUnitsLbl);
    Texts.Add('reviewUnits', ReviewUnitsLbl);
  end;

  local procedure AddMasterPool(RunId: Guid; var Item: JsonObject)
  var
    Entry: Record "BCSF Generated Record";
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Binding: JsonObject;
    Token: JsonToken;
    Ids: JsonToken;
    Customers: Integer;
    Vendors: Integer;
    Items: Integer;
  begin
    Manager.ReadSnapshot(RunId, Context);
    if Context.Get('masterDataSource', Token) then begin
      Binding := Token.AsObject();
      if Contract.GetInteger(Binding, 'version') = 3 then begin
        Binding.Get('customers', Ids);
        Customers := Ids.AsArray().Count();
        Binding.Get('vendors', Ids);
        Vendors := Ids.AsArray().Count();
        Binding.Get('items', Ids);
        Items := Ids.AsArray().Count();
        Item.Add('masterPool', StrSubstNo(PoolSummaryLbl, Customers, Contract.GetInteger(Binding, 'checkedCustomers'),
          Vendors, Contract.GetInteger(Binding, 'checkedVendors'), Items, Contract.GetInteger(Binding, 'checkedItems')));
      end;
    end;
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Posting Skipped", true);
    if not Entry.IsEmpty() then
      Item.Add('postingSkips', StrSubstNo(PostingSkipsLbl, Entry.Count()));
  end;

  local procedure MasterSourceLabel(SourceId: Guid): Text
  begin
    if IsNullGuid(SourceId) then
      exit(ExistingMastersLbl);
    exit(Format(SourceId, 0, 4));
  end;

  var
    ExistingMastersLbl: Label 'Eligible existing company data';
    PoolSummaryLbl: Label 'Master data eligible/checked: customers %1/%2, vendors %3/%4, items %5/%6. Other checked records were excluded.', Comment = '%1/%2 = customers, %3/%4 = vendors, %5/%6 = items';
    PostingSkipsLbl: Label '%1 documents retained unposted because stock was insufficient. Review provenance for STOCK reasons and the unposted result lists.', Comment = '%1 = skipped posting count';
    GenerationScopeLbl: Label 'Generation: %1. Purchasing: %2; sales: %3. Master data source: %4.', Comment = '%1 = generation kind, %2 = purchasing selected, %3 = sales selected, %4 = source run';
    ExportPackageLbl: Label 'Prepare data export package';
    PeriodLbl: Label 'Business dates: %1 to %2 (inclusive).', Comment = '%1 = starting date, %2 = ending date';
    DataTabLbl: Label 'Data';
    RunsTabLbl: Label 'Runs';
    SelectedRunScopeLbl: Label 'Generated in selected run';
    UnavailableEntitiesLbl: Label 'Entities without a generator';
    CreatedLbl: Label 'Created';
    CompletedLbl: Label 'Completed';
    NoAccessLbl: Label 'No access';
    SummaryLimitLbl: Label 'List unavailable for more than 150 executions.';
    SummaryUnavailableLbl: Label 'The execution count cannot be matched to the visible run list.';
    SummaryChangedLbl: Label 'This count changed or its list is unavailable. Refresh the dashboard.';
    StockTitleLbl: Label 'Data in this company';
    StockMoreLbl: Label 'More modules';
    StockGeneratedLbl: Label 'Generated by Scenario Factory';
    StockCompanyLbl: Label 'Entire company';
    StockAllRunsLbl: Label 'All runs';
    StockScopeLbl: Label 'Data scope';
    StockRunLbl: Label 'Filter by run';
    StockChooseLbl: Label 'Select a group to load current counts.';
    StockCountLbl: Label 'Visible records';
    StockOpenLbl: Label 'Open standard list';
    PrimaryStartLbl: Label 'Start';
    PrimaryProgressLbl: Label 'View Progress';
    PrimaryErrorsLbl: Label 'Show Errors';
    PrimaryResultsLbl: Label 'Open Results';
    DiagnosticsLbl: Label 'Diagnostics';
    TitleLbl: Label 'Scenario Factory';
    EyebrowLbl: Label 'SCENARIO WORKSPACE';
    SubtitleLbl: Label 'Define scenarios. Plan with confidence. Follow every run.';
    RefreshLbl: Label 'Refresh';
    NavigationLbl: Label 'Your workspace';
    ScenariosLbl: Label 'Scenario templates';
    ScenariosHintLbl: Label 'Define modules, targets, seed and process scope.';
    RunsLbl: Label 'Captured runs';
    RunsHintLbl: Label 'Open frozen configurations and run actions.';
    SetupLbl: Label 'Factory setup';
    SetupHintLbl: Label 'Configure sandbox, company, limits and languages.';
    MonitorLbl: Label 'Run monitor';
    MonitorHintLbl: Label 'Open the native run list and execution FactBox.';
    TemplateCountLbl: Label 'Templates';
    RunCountLbl: Label 'Captured runs';
    ActiveCountLbl: Label 'Active executions';
    ReviewCountLbl: Label 'Failed executions';
    RecentLbl: Label 'Recent captured runs';
    WindowLbl: Label 'Up to 25 recent runs. Open the run monitor for full history.';
    EmptyLbl: Label 'No captured runs yet. Create a scenario to get started.';
    ChooseLbl: Label 'Selected run';
    NoSelectionLbl: Label 'Select a run to view progress and run-specific actions.';
    QualityLbl: Label 'Final validation is not recorded for this run.';
    PlanGroupLbl: Label 'Plan & inspect';
    ExecuteGroupLbl: Label 'Execute & control';
    ResultGroupLbl: Label 'Results & diagnostics';
    RunLbl: Label 'Run card';
    ScenarioLbl: Label 'Source template';
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
    SkippedUnitsLbl: Label 'Skipped before creation';
    ReviewUnitsLbl: Label 'Unconfirmed; review required';
    SelectedLbl: Label 'Selected';
    PostedWithoutPaymentsLbl: Label 'Posted documents without payments';
    PostedWithPaymentsLbl: Label 'Posted documents with payments and application';
    WorkflowLbl: Label 'Generate company data';
    CompanyQueueLbl: Label 'Current background job';
    CompanyProgressLbl: Label 'Company generation progress';
    FoundationLbl: Label 'Company foundation';
    MissingJobLbl: Label 'Background job unavailable - review the existing request before continuing';
    WholesaleLbl: Label 'Wholesale';
    InitializedLbl: Label 'Company initialized';
    InitializingLbl: Label 'Company setup queued or running';
    FailedLbl: Label 'Phase failed - review setup or the current batch before continuing';
    IndustrySetupLbl: Label 'Set up company';
    ExpertToolsLbl: Label 'Diagnostics and expert templates';

}
