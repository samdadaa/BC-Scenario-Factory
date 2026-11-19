namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;

codeunit 90307 "BCSF Batch Runner"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Execution" = M, tabledata "BCSF Batch" = M;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Execute(BatchId: Guid; JobId: Guid)
  var
    Header: Record "BCSF Run Header";
    Batch: Record "BCSF Batch";
    Execution: Record "BCSF Run Execution";
    Step: Record "BCSF Run Step";
    Entry: Record "BCSF Generated Record";
    TempCapability: Record "BCSF Generator Registry" temporary;
    Writer: Codeunit "BCSF Plan Writer";
    Manager: Codeunit "BCSF Scenario Manager";
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Contract: Codeunit "BCSF Contract JSON";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
    Rules: Codeunit "BCSF Execution Rules";
    Recovery: Codeunit "BCSF Batch Recovery";
    Generator: Interface "BCSF Generator";
    Context: JsonObject;
    Target: JsonObject;
    BatchJson: JsonObject;
    Result: JsonObject;
    Findings: JsonArray;
  begin
    Batch.Get(BatchId);
    Header.LockTable();
    Header.Get(Batch."Run Id");
    Execution.LockTable();
    Execution.Get(Batch."Run Id");
    Batch.LockTable();
    Batch.Get(BatchId);
    Batch.TestField(Status, Batch.Status::Running);
    Batch.TestField("Job Queue Entry Id", JobId);
    Batch.TestField("Worker Session Id", SessionId());
    Batch.TestField("Worker Server Id", ServiceInstanceId());
    Execution.TestField(Status, "BCSF Run Status"::Running);
    Execution.TestField("Job Queue Entry Id", JobId);
    Writer.CheckExecution(Batch."Run Id");
    Step.Get(Batch."Run Id", Batch."Node Code");
    Manager.ReadSnapshot(Batch."Run Id", Context);
    Context.Add('batchId', Format(BatchId, 0, 4));
    Target := Dispatcher.MakeTarget(Step);
    BatchJson.Add('batchKey', Batch."Batch Key");
    BatchJson.Add('firstKey', Batch."First Key");
    BatchJson.Add('lastKey', Batch."Last Key");
    Contract.CheckBatch(Context, Target, BatchJson);
    Entry.SetRange("Batch Id", BatchId);
    if not Entry.IsEmpty() then
      Error(ResultErr);
    Generator := Registry.Resolve(Step."Generator Code", Step."Entity Code", TempCapability);
    if TempCapability."Contract Probe" or (TempCapability.Version <> Step."Generator Version") then
      Error(ResultErr);
    Registry.RequirePrerequisites(Generator, Context, Target);
    Generator.ExecuteBatch(Contract.Clone(Context), Contract.Clone(Target), Contract.Clone(BatchJson), Result);
    if (Contract.GetCode(Result, 'generatorCode') <> Step."Generator Code") or
      (Contract.GetText(Result, 'runId') <> Contract.GetText(Context, 'runId')) or
      (Contract.GetText(Result, 'batchKey') <> Batch."Batch Key") or
      (Contract.GetInteger(Result, 'dataLanguage') <> Header."Data Language".AsInteger()) or
      not Contract.GetBoolean(Result, 'completed') or Contract.GetBoolean(Result, 'contractProbe')
    then
      Error(ResultErr);
    Batch."Processed Units" := Contract.GetInteger(Result, 'processedUnits');
    Batch."Created Records" := Contract.GetInteger(Result, 'createdRecords');
    Rules.CheckCoverage(Batch);
    Generator.ValidateOutput(Contract.Clone(Context), Contract.Clone(Target), Contract.Clone(BatchJson), Contract.Clone(Result), Findings);
    if Findings.Count() <> 0 then
      Error(ResultErr);
    Recovery.SaveCheckpoint(Batch, Result);
    Batch.Status := Batch.Status::Completed;
    Batch."Finished At" := CurrentDateTime();
    Batch.Modify(true);
    Execution."Completed Batches" += 1;
    Dispatcher.ScheduleNext(Execution);
    Execution.Modify(true);
    // Results, provenance, completion and the sole successor job persist together. No commit here.
  end;

  var
    ResultErr: Label 'The generator result is incomplete, inconsistent or already registered. Keep the batch blocked for review instead of retrying it.';
}
