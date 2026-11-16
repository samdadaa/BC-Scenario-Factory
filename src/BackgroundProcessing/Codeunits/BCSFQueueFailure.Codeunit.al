namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
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
  begin
    if (JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit) or
      (JobQueueEntry."Object ID to Run" <> Codeunit::"BCSF Batch Worker") or
      (JobQueueEntry.Status <> JobQueueEntry.Status::Error)
    then
      exit;
    Batch.SetRange("Job Queue Entry Id", JobQueueEntry.ID);
    if not Batch.FindFirst() then
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
    Execution.Status := "BCSF Run Status"::Failed;
    Execution.Modify(true);
    // No raw BC error text or record data is copied into Scenario Factory tables.
  end;
}
