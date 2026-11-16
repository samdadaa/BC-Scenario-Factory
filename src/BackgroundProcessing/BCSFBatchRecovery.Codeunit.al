namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;
using System.Environment;
using System.Threading;

codeunit 90304 "BCSF Batch Recovery"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Control" = IM, tabledata "BCSF Batch Checkpoint" = I,
    tabledata "BCSF Batch" = M, tabledata "BCSF Run Execution" = M;

  /// <summary>Commit intent before taking the long-lived execution lock. Never interrupts a generator.</summary>
  procedure RequestStop(RunId: Guid; CancelWork: Boolean)
  var
    Execution: Record "BCSF Run Execution";
    Control: Record "BCSF Run Control";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    Execution.ReadIsolation(IsolationLevel::ReadUncommitted);
    Execution.Get(RunId);
    if Execution.Status in ["BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::Cancelled] then
      Error(ReviewErr);
    Control.LockTable();
    if not Control.Get(RunId) then begin
      Control.Init();
      Control."Run Id" := RunId;
      Control."Requested At" := CurrentDateTime();
      Control.Insert(true);
    end;
    if CancelWork then
      Control."Cancel Requested" := true
    else
      Control."Pause Requested" := true;
    Control."Requested At" := CurrentDateTime();
    Control.Modify(true);
    Commit();
    // A running worker observes the request itself. Other states can be stopped immediately.
    if Execution.Status <> "BCSF Run Status"::Running then
      ApplyRequests(RunId);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ApplyRequests(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
  begin
    LockExecution(RunId, Header, Execution);
    if ApplyBoundary(Execution, CreateGuid()) then
      Execution.Modify(true);
  end;

  /// <summary>Called under the execution lock, before claim and before scheduling a successor.</summary>
  procedure ApplyBoundary(var Execution: Record "BCSF Run Execution"; CurrentJobId: Guid): Boolean
  var
    Control: Record "BCSF Run Control";
    Batch: Record "BCSF Batch";
    Active: Record "BCSF Batch";
  begin
    Control.LockTable();
    if not Control.Get(Execution."Run Id") then
      exit(false);
    if not (Control."Pause Requested" or Control."Cancel Requested") then
      exit(false);
    if Execution.Status in ["BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::Cancelled] then
      exit(false);
    Active.SetRange("Run Id", Execution."Run Id");
    Active.SetRange(Status, Active.Status::Running);
    if not Active.IsEmpty() then
      exit(false);
    Batch.SetRange("Run Id", Execution."Run Id");
    Batch.SetRange(Status, Batch.Status::Pending);
    if Batch.FindSet(true) then
      repeat
        if not IsNullGuid(Batch."Job Queue Entry Id") then begin
          if Batch."Job Queue Entry Id" <> CurrentJobId then
            if not StopJob(Batch) then
              exit(false);
          RetireJob(Batch);
          Batch.Modify(true);
        end;
      until Batch.Next() = 0;
    if Control."Cancel Requested" then begin
      Batch.Reset();
      Batch.SetRange("Run Id", Execution."Run Id");
      Batch.SetFilter(Status, '%1|%2', Batch.Status::Pending, Batch.Status::Failed);
      if Batch.FindSet(true) then
        repeat
          if not IsNullGuid(Batch."Job Queue Entry Id") then begin
            if not StopJob(Batch) then
              exit(false);
            RetireJob(Batch);
          end;
          Batch.Status := Batch.Status::Cancelled;
          Batch.Modify(true);
        until Batch.Next() = 0;
      Execution.Status := "BCSF Run Status"::Cancelled;
    end else begin
      if Execution.Status in ["BCSF Run Status"::Paused, "BCSF Run Status"::Failed] then
        exit(false);
      Execution.Status := "BCSF Run Status"::Paused;
    end;
    Clear(Execution."Job Queue Entry Id");
    exit(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure RetryUnclaimed(BatchId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Entry: Record "BCSF Generated Record";
    Checkpoint: Record "BCSF Batch Checkpoint";
  begin
    Batch.Get(BatchId);
    LockExecution(Batch."Run Id", Header, Execution);
    Execution.TestField(Status, "BCSF Run Status"::Failed);
    Batch.LockTable();
    Batch.Get(BatchId);
    Batch.TestField(Status, Batch.Status::Failed);
    Batch.TestField("Started At", 0DT);
    Entry.SetRange("Batch Id", BatchId);
    if not Entry.IsEmpty() or Checkpoint.Get(BatchId) then
      Error(ReviewErr);
    if Batch."Schedule Attempts" >= 3 then
      Error(LimitErr);
    if not StopJob(Batch) then
      Error(BusyErr);
    RetireJob(Batch);
    Batch.Status := Batch.Status::Pending;
    Batch.Modify(true);
    ResumeRun(Batch."Run Id");
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ResumeRun(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Control: Record "BCSF Run Control";
    Batch: Record "BCSF Batch";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
    Writer: Codeunit "BCSF Plan Writer";
  begin
    LockExecution(RunId, Header, Execution);
    if not (Execution.Status in ["BCSF Run Status"::Paused, "BCSF Run Status"::Failed]) then
      Error(ReviewErr);
    Control.LockTable();
    if not Control.Get(RunId) then begin
      Control.Init();
      Control."Run Id" := RunId;
      Control."Requested At" := CurrentDateTime();
      Control.Insert(true);
    end;
    Control.TestField("Cancel Requested", false);
    Control."Pause Requested" := false;
    Control."Requested At" := CurrentDateTime();
    Control.Modify(true);
    Batch.SetRange("Run Id", RunId);
    if Batch.FindSet() then
      repeat
        case Batch.Status of
          Batch.Status::Completed: VerifyCheckpoint(Batch."Batch Id");
          Batch.Status::Pending:
            if not IsNullGuid(Batch."Job Queue Entry Id") then
              Error(ReviewErr);
          else Error(ReviewErr);
        end;
      until Batch.Next() = 0;
    Writer.CheckExecution(RunId);
    Clear(Execution."Job Queue Entry Id");
    Execution.Status := "BCSF Run Status"::ResumePending;
    Execution.Modify(true);
    if Execution."Completed Batches" = Execution."Total Batches" then begin
      Execution.Status := "BCSF Run Status"::CompletedWithWarnings;
      Execution."Finished At" := CurrentDateTime();
      Execution.Modify(true);
      exit;
    end;
    Execution.Status := "BCSF Run Status"::Preflight;
    Execution.Modify(true);
    Execution.Status := "BCSF Run Status"::Ready;
    Execution.Modify(true);
    Dispatcher.Schedule(RunId, CurrentDateTime());
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ClassifyInterrupted(BatchId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
  begin
    Batch.Get(BatchId);
    LockExecution(Batch."Run Id", Header, Execution);
    Batch.LockTable();
    Batch.Get(BatchId);
    Batch.TestField(Status, Batch.Status::Running);
    RequireDeadWorker(Batch);
    if not (Execution.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::Failed]) then
      Error(ReviewErr);
    Batch.Status := Batch.Status::NeedsReview;
    Batch.Modify(true);
    Execution.Status := "BCSF Run Status"::Failed;
    Execution.Modify(true);
  end;

  /// <summary>Confirms an already validated checkpoint, never invokes ExecuteBatch or Resume.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure Reconcile(BatchId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Checkpoint: Record "BCSF Batch Checkpoint";
    Contract: Codeunit "BCSF Contract JSON";
    Result: JsonObject;
  begin
    Batch.Get(BatchId);
    LockExecution(Batch."Run Id", Header, Execution);
    Batch.LockTable();
    Batch.Get(BatchId);
    if not (Batch.Status in [Batch.Status::Running, Batch.Status::NeedsReview]) or
      not (Execution.Status in ["BCSF Run Status"::Running, "BCSF Run Status"::Failed, "BCSF Run Status"::Cancelled])
    then
      Error(ReviewErr);
    RequireDeadWorker(Batch);
    if not StopJob(Batch) then
      Error(BusyErr);
    VerifyCheckpoint(BatchId);
    Checkpoint.Get(BatchId);
    Result := Checkpoint.ReadResult();
    Batch."Processed Units" := Contract.GetInteger(Result, 'processedUnits');
    Batch."Created Records" := Contract.GetInteger(Result, 'createdRecords');
    Batch.Status := Batch.Status::Completed;
    Batch."Finished At" := Checkpoint."Confirmed At";
    Batch.Modify(true);
    Execution."Completed Batches" += 1;
    if Execution.Status <> "BCSF Run Status"::Cancelled then
      Execution.Status := "BCSF Run Status"::Failed;
    Execution.Modify(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure SaveCheckpoint(Batch: Record "BCSF Batch"; Result: JsonObject)
  var
    Checkpoint: Record "BCSF Batch Checkpoint";
    Contract: Codeunit "BCSF Contract JSON";
    Envelope: JsonObject;
  begin
    Envelope.Add('generatorCode', Contract.GetText(Result, 'generatorCode'));
    Envelope.Add('runId', Contract.GetText(Result, 'runId'));
    Envelope.Add('batchKey', Contract.GetText(Result, 'batchKey'));
    Envelope.Add('processedUnits', Contract.GetInteger(Result, 'processedUnits'));
    Envelope.Add('createdRecords', Contract.GetInteger(Result, 'createdRecords'));
    Envelope.Add('dataLanguage', Contract.GetInteger(Result, 'dataLanguage'));
    Envelope.Add('completed', Contract.GetBoolean(Result, 'completed'));
    Envelope.Add('contractProbe', Contract.GetBoolean(Result, 'contractProbe'));
    Checkpoint.Init();
    Checkpoint."Batch Id" := Batch."Batch Id";
    Checkpoint."Run Id" := Batch."Run Id";
    Checkpoint."Schema Version" := 1;
    Checkpoint."Confirmed At" := CurrentDateTime();
    Checkpoint.WriteResult(Envelope);
    Checkpoint.Insert(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure VerifyCheckpoint(BatchId: Guid)
  var
    Checkpoint: Record "BCSF Batch Checkpoint";
  begin
    Checkpoint.Get(BatchId);
    CheckCheckpoint(Checkpoint);
  end;

  procedure CheckCheckpoint(var Checkpoint: Record "BCSF Batch Checkpoint")
  var
    Batch: Record "BCSF Batch";
    Step: Record "BCSF Run Step";
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Provenance: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Manager: Codeunit "BCSF Scenario Manager";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
    Rules: Codeunit "BCSF Execution Rules";
    Generator: Interface "BCSF Generator";
    Context: JsonObject;
    Target: JsonObject;
    BatchJson: JsonObject;
    Result: JsonObject;
    Findings: JsonArray;
    Fields: List of [Text];
  begin
    Batch.Get(Checkpoint."Batch Id");
    Rules.CheckEnvironment(Batch."Run Id", Checkpoint.CurrentCompany());
    Checkpoint.TestField("Run Id", Batch."Run Id");
    Checkpoint.TestField("Schema Version", 1);
    Checkpoint.TestField("Confirmed At");
    Header.Get(Batch."Run Id");
    Step.Get(Batch."Run Id", Batch."Node Code");
    Result := Checkpoint.ReadResult();
    Fields := Result.Keys();
    if (Fields.Count() <> 8) or (Contract.GetText(Result, 'runId') <> Format(Batch."Run Id", 0, 4)) or
      (Contract.GetCode(Result, 'generatorCode') <> Step."Generator Code") or
      (Contract.GetText(Result, 'batchKey') <> Batch."Batch Key") or
      (Contract.GetInteger(Result, 'dataLanguage') <> Header."Data Language".AsInteger()) or
      not Contract.GetBoolean(Result, 'completed') or Contract.GetBoolean(Result, 'contractProbe')
    then
      Error(ReviewErr);
    Batch."Processed Units" := Contract.GetInteger(Result, 'processedUnits');
    Batch."Created Records" := Contract.GetInteger(Result, 'createdRecords');
    Rules.CheckCoverage(Batch);
    Entry.SetRange("Batch Id", Batch."Batch Id");
    if Entry.FindSet() then
      repeat
        if not Provenance.ExistsByIdentity(Entry) then
          Error(ReviewErr);
      until Entry.Next() = 0;
    Manager.ReadSnapshot(Batch."Run Id", Context);
    Context.Add('batchId', Format(Batch."Batch Id", 0, 4));
    Target := Dispatcher.MakeTarget(Step);
    BatchJson.Add('batchKey', Batch."Batch Key");
    BatchJson.Add('firstKey', Batch."First Key");
    BatchJson.Add('lastKey', Batch."Last Key");
    Generator := Registry.Resolve(Step."Generator Code", Step."Entity Code", TempCapability);
    if TempCapability."Contract Probe" or (TempCapability.Version <> Step."Generator Version") or
      (TempCapability."Contract Version" <> Step."Contract Version")
    then
      Error(ReviewErr);
    Generator.ValidateOutput(Contract.Clone(Context), Contract.Clone(Target), Contract.Clone(BatchJson), Contract.Clone(Result), Findings);
    if Findings.Count() <> 0 then
      Error(ReviewErr);
  end;

  procedure RequireDeadWorker(Batch: Record "BCSF Batch")
  var
    Active: Record "Active Session";
  begin
    if (Batch."Worker Session Id" <= 0) or IsNullGuid(Batch."Worker Session Guid") or not Active.ReadPermission() then
      Error(BusyErr);
    Active.SetRange("Server Instance ID", Batch."Worker Server Id");
    Active.SetRange("Session ID", Batch."Worker Session Id");
    Active.SetRange("Session Unique ID", Batch."Worker Session Guid");
    if not Active.IsEmpty() then
      Error(BusyErr);
  end;

  procedure CheckUnclaimed(Batch: Record "BCSF Batch")
  var
    Entry: Record "BCSF Generated Record";
    Checkpoint: Record "BCSF Batch Checkpoint";
  begin
    Batch.TestField("Started At", 0DT);
    Batch.TestField("Worker Session Id", 0);
    if Batch."Schedule Attempts" >= 3 then
      Error(LimitErr);
    Entry.SetRange("Batch Id", Batch."Batch Id");
    if not Entry.IsEmpty() or Checkpoint.Get(Batch."Batch Id") then
      Error(ReviewErr);
  end;

  procedure CheckBatchChange(NewBatch: Record "BCSF Batch"; OldBatch: Record "BCSF Batch")
  var
    Control: Record "BCSF Run Control";
    Rules: Codeunit "BCSF Execution Rules";
    Valid: Boolean;
    RetiredAttempts: Integer;
  begin
    case OldBatch.Status of
      OldBatch.Status::Pending:
        Valid := NewBatch.Status in [NewBatch.Status::Pending, NewBatch.Status::Running, NewBatch.Status::Failed, NewBatch.Status::Cancelled];
      OldBatch.Status::Running:
        Valid := NewBatch.Status in [NewBatch.Status::Completed, NewBatch.Status::NeedsReview];
      OldBatch.Status::Failed:
        Valid := NewBatch.Status in [NewBatch.Status::Pending, NewBatch.Status::Cancelled];
      OldBatch.Status::NeedsReview:
        Valid := NewBatch.Status = NewBatch.Status::Completed;
    end;
    if not Valid then
      Error(ReviewErr);
    if (OldBatch.Status = OldBatch.Status::Failed) and (NewBatch.Status = NewBatch.Status::Pending) then begin
      CheckUnclaimed(OldBatch);
      CheckStoppedJob(OldBatch, false);
    end;
    if NewBatch.Status = NewBatch.Status::Cancelled then begin
      Control.Get(NewBatch."Run Id");
      Control.TestField("Cancel Requested", true);
      NewBatch.TestField("Started At", 0DT);
      if not IsNullGuid(NewBatch."Job Queue Entry Id") then
        Error(ReviewErr);
    end;
    if OldBatch."Job Queue Entry Id" <> NewBatch."Job Queue Entry Id" then begin
      if IsNullGuid(NewBatch."Job Queue Entry Id") then begin
        if not ((OldBatch.Status = OldBatch.Status::Failed) and (NewBatch.Status = NewBatch.Status::Pending)) then begin
          Control.Get(NewBatch."Run Id");
          if not (Control."Pause Requested" or Control."Cancel Requested") then
            Error(ReviewErr);
        end;
        OldBatch.TestField("Started At", 0DT);
        CheckStoppedJob(OldBatch, true);
        NewBatch.TestField("Previous Job Id", OldBatch."Job Queue Entry Id");
        RetiredAttempts := OldBatch."Schedule Attempts";
        if RetiredAttempts = 0 then
          RetiredAttempts := 1;
        NewBatch.TestField("Schedule Attempts", RetiredAttempts);
      end else begin
        OldBatch.TestField(Status, OldBatch.Status::Pending);
        NewBatch.TestField(Status, NewBatch.Status::Pending);
        if not IsNullGuid(OldBatch."Job Queue Entry Id") or (OldBatch."Schedule Attempts" >= 3) then
          Error(LimitErr);
        NewBatch.TestField("Schedule Attempts", OldBatch."Schedule Attempts" + 1);
        NewBatch.TestField("Previous Job Id", OldBatch."Previous Job Id");
      end;
    end else begin
      NewBatch.TestField("Schedule Attempts", OldBatch."Schedule Attempts");
      NewBatch.TestField("Previous Job Id", OldBatch."Previous Job Id");
    end;
    if (OldBatch.Status = OldBatch.Status::Pending) and (NewBatch.Status = NewBatch.Status::Running) then begin
      NewBatch.TestField("Job Queue Entry Id");
      OldBatch.TestField("Job Queue Entry Id", NewBatch."Job Queue Entry Id");
      NewBatch.TestField("Started At");
      NewBatch.TestField("Worker Session Id", SessionId());
      NewBatch.TestField("Worker Server Id", ServiceInstanceId());
      NewBatch.TestField("Worker Session Guid");
    end else begin
      NewBatch.TestField("Started At", OldBatch."Started At");
      NewBatch.TestField("Worker Session Id", OldBatch."Worker Session Id");
      NewBatch.TestField("Worker Server Id", OldBatch."Worker Server Id");
      NewBatch.TestField("Worker Session Guid", OldBatch."Worker Session Guid");
    end;
    if NewBatch.Status = NewBatch.Status::Completed then begin
      if OldBatch.Status = OldBatch.Status::NeedsReview then begin
        RequireDeadWorker(OldBatch);
        CheckStoppedJob(OldBatch, false);
      end;
      NewBatch.TestField("Finished At");
      Rules.CheckCoverage(NewBatch);
      VerifyCheckpoint(NewBatch."Batch Id");
    end else begin
      NewBatch.TestField("Finished At", OldBatch."Finished At");
      NewBatch.TestField("Processed Units", 0);
      NewBatch.TestField("Created Records", 0);
    end;
  end;

  local procedure CheckStoppedJob(Batch: Record "BCSF Batch"; AllowOwnUnclaimed: Boolean)
  var
    Job: Record "Job Queue Entry";
  begin
    if IsNullGuid(Batch."Job Queue Entry Id") or not Job.Get(Batch."Job Queue Entry Id") then
      exit;
    Job.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
    if Job.Status = Job.Status::"In Process" then begin
      if AllowOwnUnclaimed and (Batch."Started At" = 0DT) and
        (Job."User Session ID" = SessionId()) and (Job."User Service Instance ID" = ServiceInstanceId())
      then
        exit;
      Error(BusyErr);
    end;
    if not IsNullGuid(Job."System Task ID") then
      if TaskScheduler.TaskExists(Job."System Task ID") then
        Error(BusyErr);
  end;

  procedure StopJob(Batch: Record "BCSF Batch"): Boolean
  var
    Job: Record "Job Queue Entry";
  begin
    if IsNullGuid(Batch."Job Queue Entry Id") then
      exit(true);
    Job.LockTable();
    if not Job.Get(Batch."Job Queue Entry Id") then
      exit(true);
    Job.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
    if Job."Record ID to Process" <> Batch.RecordId() then
      Error(ReviewErr);
    if Job.Status = Job.Status::"In Process" then
      exit(false);
    if not Job.WritePermission() then
      Error(BusyErr);
    if not IsNullGuid(Job."System Task ID") then
      if TaskScheduler.TaskExists(Job."System Task ID") then
        if not TaskScheduler.CancelTask(Job."System Task ID") then
          exit(false);
    Clear(Job."System Task ID");
    Job.Status := Job.Status::"On Hold";
    Job.Modify(true);
    exit(true);
  end;

  local procedure RetireJob(var Batch: Record "BCSF Batch")
  begin
    if (Batch."Schedule Attempts" = 0) and not IsNullGuid(Batch."Job Queue Entry Id") then
      Batch."Schedule Attempts" := 1;
    Batch."Previous Job Id" := Batch."Job Queue Entry Id";
    Clear(Batch."Job Queue Entry Id");
  end;

  local procedure LockExecution(RunId: Guid; var Header: Record "BCSF Run Header"; var Execution: Record "BCSF Run Execution")
  var
    Rules: Codeunit "BCSF Execution Rules";
  begin
    Rules.CheckEnvironment(RunId, CompanyName());
    Header.LockTable();
    Header.Get(RunId);
    Execution.LockTable();
    Execution.Get(RunId);
  end;

  var
    ReviewErr: Label 'Recovery requires matching confirmed checkpoints or proof that a failed batch was never claimed. Uncertain work cannot be replayed; review the standard results and job history.';
    BusyErr: Label 'The worker or scheduled task is still active, cannot be cancelled safely, or its inactivity cannot be verified with the current permissions.';
    LimitErr: Label 'This batch has reached the limit of three job schedules. Resolve the cause and create a reviewed new scenario instead of bypassing the retry limit.';
}
