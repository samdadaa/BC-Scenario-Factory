namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ScenarioManagement;
using System.Threading;

codeunit 90308 "BCSF Queue Failure"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Execution" = M, tabledata "BCSF Batch" = M;

  [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterFinalizeRun', '', false, false)]
  local procedure MarkUnconfirmed(JobQueueEntry: Record "Job Queue Entry")
  var
    Header: Record "BCSF Run Header";
    Batch: Record "BCSF Batch";
    Execution: Record "BCSF Run Execution";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
  begin
    if (JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit) or
      (JobQueueEntry."Object ID to Run" <> Codeunit::"BCSF Batch Worker") or
      (JobQueueEntry.Status <> JobQueueEntry.Status::Error)
    then
      exit;
    Batch.SetRange("Job Queue Entry Id", JobQueueEntry.ID);
    if not Batch.FindFirst() then
      exit;
    JobQueueEntry.TestField("Maximum No. of Attempts to Run", 0);
    JobQueueEntry.TestField("Recurring Job", false);
    JobQueueEntry.TestField("Job Queue Category Code", 'BCSF.SER');
    if JobQueueEntry."Record ID to Process" <> Batch.RecordId() then
      exit;
    Header.LockTable();
    Header.Get(Batch."Run Id");
    Execution.LockTable();
    Execution.Get(Batch."Run Id");
    Batch.LockTable();
    Batch.Get(Batch."Batch Id");
    if not (Batch.Status in [Batch.Status::Pending, Batch.Status::Running]) then
      exit;
    if Execution."Job Queue Entry Id" <> JobQueueEntry.ID then
      exit;
    if Batch.Status = Batch.Status::Running then
      Batch.Status := Batch.Status::NeedsReview
    else
      Batch.Status := Batch.Status::Failed;
    Batch.Modify(true);
    // The standard queue has ended this job with an error in its separate
    // failure transaction. Preserve its claim as NeedsReview; schedule only
    // never-claimed independent units, never another attempt of this unit.
    if (Batch.Status = Batch.Status::NeedsReview) and Dispatcher.UsesIsolation(Batch."Run Id") and
      (Batch."First Key" = Batch."Last Key") and
      (Batch."Node Code" in ['SALES.QUOTE', 'SALES.ORDER', 'SALES.INVOICE', 'PURCHASE.ORDER']) and
      CanContinue(Batch."Run Id") then
      Dispatcher.ScheduleNext(Execution)
    else begin
      Execution.Status := "BCSF Run Status"::Failed;
      Execution."Finished At" := CurrentDateTime();
    end;
    Execution.Modify(true);
    // No raw BC error text or record data is copied into Scenario Factory tables.
  end;
  [TryFunction]
  local procedure CanContinue(RunId: Guid)
  var
    Job: Record "Job Queue Entry";
    Writer: Codeunit "BCSF Plan Writer";
  begin
    // Read-only setup recheck. Scheduling itself is never inside a TryFunction.
    Writer.CheckExecution(RunId);
    Job.CheckRequiredPermissions();
    if not Job.WritePermission() then
      Error(ContinuationPermissionErr);
  end;

  var
    ContinuationPermissionErr: Label 'Independent work cannot be scheduled with the current job queue permissions. The failed unit remains blocked for review.';
}
