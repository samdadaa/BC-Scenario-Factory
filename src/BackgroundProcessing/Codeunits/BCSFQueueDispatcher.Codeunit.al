namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;
using System.Threading;

codeunit 90302 "BCSF Queue Dispatcher"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Execution" = IM, tabledata "BCSF Batch" = IM;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Prepare(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Step: Record "BCSF Run Step";
    Writer: Codeunit "BCSF Plan Writer";
    Manager: Codeunit "BCSF Scenario Manager";
    Context: JsonObject;
    SequenceNo: Integer;
  begin
    Header.LockTable();
    Header.Get(RunId);
    Execution.LockTable();
    if Execution.Get(RunId) then
      Error(ExistingErr);
    Writer.CheckExecution(RunId);
    Manager.ReadSnapshot(RunId, Context);
    Execution.Init();
    Execution."Run Id" := RunId;
    Execution.Status := "BCSF Run Status"::Preflight;
    Execution."Created At" := CurrentDateTime();
    Execution.Insert(true);
    Step.SetCurrentKey("Run Id", "Sequence No.", "Node Code");
    Step.SetRange("Run Id", RunId);
    if Step.FindSet() then
      repeat
        PlanStep(Context, Step, SequenceNo);
      until Step.Next() = 0;
    // Base the Ready update on the stored row, including the persisted Created At value.
    Execution.Get(RunId);
    Execution."Total Batches" := SequenceNo;
    Execution.Status := "BCSF Run Status"::Ready;
    Execution.Modify(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Schedule(RunId: Guid; EarliestStart: DateTime)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Writer: Codeunit "BCSF Plan Writer";
  begin
    Header.LockTable();
    Header.Get(RunId);
    Execution.LockTable();
    Execution.Get(RunId);
    Execution.TestField(Status, "BCSF Run Status"::Ready);
    Writer.CheckExecution(RunId);
    if EarliestStart = 0DT then
      EarliestStart := CurrentDateTime();
    Execution."Earliest Start" := EarliestStart;
    if EarliestStart > CurrentDateTime() then
      Execution.Status := "BCSF Run Status"::Scheduled
    else
      Execution.Status := "BCSF Run Status"::Queued;
    ScheduleNext(Execution);
    Execution.Modify(true);
  end;

  /// <summary>Caller holds the run lock. Scheduling and completion share the caller transaction.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure ScheduleNext(var Execution: Record "BCSF Run Execution")
  var
    Batch: Record "BCSF Batch";
    Job: Record "Job Queue Entry";
    Enqueue: Codeunit "Job Queue - Enqueue";
    Writer: Codeunit "BCSF Plan Writer";
    Recovery: Codeunit "BCSF Batch Recovery";
    Quality: Codeunit "BCSF Run Quality";
  begin
    if Recovery.ApplyBoundary(Execution, CreateGuid()) then
      exit;
    Writer.CheckExecution(Execution."Run Id");
    Batch.SetCurrentKey("Run Id", "Sequence No.");
    Batch.SetRange("Run Id", Execution."Run Id");
    Batch.SetRange(Status, Batch.Status::Pending);
    if not Batch.FindFirst() then begin
      if Execution."Completed Batches" <> Execution."Total Batches" then
        Error(IncompleteErr);
      Quality.FinalizeRun(Execution);
      exit;
    end;
    if not IsNullGuid(Batch."Job Queue Entry Id") then
      Error(ExistingErr);
    if Batch."Schedule Attempts" >= 3 then
      Error(ExistingErr);
    if not Job.WritePermission() then
      Error(QueuePermissionErr);
    Job.CheckRequiredPermissions();
    Job.Init();
    Job."Object Type to Run" := Job."Object Type to Run"::Codeunit;
    Job."Object ID to Run" := Codeunit::"BCSF Batch Worker";
    Job."Record ID to Process" := Batch.RecordId();
    Job.Description := QueueDescriptionLbl;
    Job."User Language ID" := GlobalLanguage();
    Job."Earliest Start Date/Time" := Execution."Earliest Start";
    Job."Job Queue Category Code" := 'BCSF.SER';
    Job."Maximum No. of Attempts to Run" := 0;
    Job."Recurring Job" := false;
    Job."Job Timeout" := 600000;
    // No Boolean Run result: no implicit success-commit boundary is requested here.
    Enqueue.Run(Job);
    Job.TestField(ID);
    Job.TestField("System Task ID");
    Job.TestField(Status, Job.Status::Ready);
    Batch."Schedule Attempts" += 1;
    Batch."Job Queue Entry Id" := Job.ID;
    Batch.Modify(true);
    Execution."Job Queue Entry Id" := Job.ID;
  end;

  procedure MakeTarget(Step: Record "BCSF Run Step"): JsonObject
  var
    Target: JsonObject;
  begin
    Target.Add('entityCode', Step."Entity Code");
    Target.Add('moduleCode', Step."Module Code");
    Target.Add('quantity', Step."Work Units");
    Target.Add('processMode', Step."Process Mode".AsInteger());
    exit(Target);
  end;

  local procedure PlanStep(Context: JsonObject; Step: Record "BCSF Run Step"; var SequenceNo: Integer)
  var
    Batch: Record "BCSF Batch";
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Contract: Codeunit "BCSF Contract JSON";
    Generator: Interface "BCSF Generator";
    Target: JsonObject;
    Planned: JsonArray;
    Findings: JsonArray;
    Token: JsonToken;
    Item: JsonObject;
    FirstKey: Integer;
    LastKey: Integer;
    BatchKey: Text;
    Done: Boolean;
    BatchFields: List of [Text];
  begin
    Target := MakeTarget(Step);
    Generator := Registry.Resolve(Step."Generator Code", Step."Entity Code", TempCapability);
    if TempCapability."Contract Probe" or (TempCapability.Version <> Step."Generator Version") then
      Error(PlanErr);
    Generator.CheckPrerequisites(Contract.Clone(Context), Contract.Clone(Target), Findings);
    if Findings.Count() <> 0 then
      Error(PlanErr);
    FirstKey := 1;
    while not Done do begin
      Clear(Planned);
      Generator.PlanBatches(Contract.Clone(Context), Contract.Clone(Target), FirstKey, 100, Planned);
      if (Planned.Count() = 0) or (Planned.Count() > 100) then
        Error(PlanErr);
      foreach Token in Planned do begin
        if Done then
          Error(PlanErr);
        Item := Token.AsObject();
        BatchFields := Item.Keys();
        if BatchFields.Count() <> 3 then
          Error(PlanErr);
        Contract.CheckBatch(Context, Target, Item);
        if Contract.GetInteger(Item, 'firstKey') <> FirstKey then
          Error(PlanErr);
        LastKey := Contract.GetInteger(Item, 'lastKey');
        BatchKey := Contract.GetText(Item, 'batchKey');
        if (StrLen(BatchKey) > MaxStrLen(Batch."Batch Key")) or (SequenceNo >= 10000) then
          Error(PlanErr);
        SequenceNo += 1;
        Batch.Init();
        Batch."Batch Id" := CreateGuid();
        Batch."Run Id" := Step."Run Id";
        Batch."Node Code" := Step."Node Code";
        Batch."Sequence No." := SequenceNo;
        Batch."Batch Key" := CopyStr(BatchKey, 1, MaxStrLen(Batch."Batch Key"));
        Batch."First Key" := FirstKey;
        Batch."Last Key" := LastKey;
        Batch.Insert(true);
        Done := LastKey = Step."Work Units";
        if not Done then
          FirstKey := LastKey + 1;
      end;
    end;
  end;

  var
    ExistingErr: Label 'This run already has prepared execution or scheduled work. Review the existing entries instead of creating duplicates.';
    IncompleteErr: Label 'Execution has unfinished or unconfirmed work. Automatic retry is disabled; review the batch and job queue history.';
    QueuePermissionErr: Label 'Effective job queue write and execution permissions are required. Ask an administrator to review the standard job queue role.';
    QueueDescriptionLbl: Label 'Scenario Factory serial batch';
    PlanErr: Label 'The generator returned an invalid, overlapping, incomplete or oversized batch plan. At most 10000 batches per run are supported by this dispatcher.';
}
