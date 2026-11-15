namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ScenarioManagement;
using System.Threading;

codeunit 90303 "BCSF Batch Worker"
{
  Access = Internal;
  TableNo = "Job Queue Entry";
  Permissions = tabledata "BCSF Run Execution" = M, tabledata "BCSF Batch" = M;

  trigger OnRun()
  var
    Batch: Record "BCSF Batch";
    Execution: Record "BCSF Run Execution";
    Header: Record "BCSF Run Header";
    Prior: Record "BCSF Batch";
    StoredJob: Record "Job Queue Entry";
    Writer: Codeunit "BCSF Plan Writer";
    Runner: Codeunit "BCSF Batch Runner";
    Reference: RecordRef;
  begin
    if GuiAllowed() then
      Error(BackgroundErr);
    Rec.TestField("Object Type to Run", Rec."Object Type to Run"::Codeunit);
    Rec.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
    if Rec."Record ID to Process".TableNo() <> Database::"BCSF Batch" then
      Error(JobErr);
    Reference.Get(Rec."Record ID to Process");
    Reference.SetTable(Batch);
    Reference.Close();
    Header.LockTable();
    Header.Get(Batch."Run Id");
    Execution.LockTable();
    Execution.Get(Batch."Run Id");
    Batch.LockTable();
    Batch.Get(Batch."Batch Id");
    Batch.TestField(Status, Batch.Status::Pending);
    Batch.TestField("Job Queue Entry Id", Rec.ID);
    Execution.TestField("Job Queue Entry Id", Rec.ID);
    if not (Execution.Status in ["BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled, "BCSF Run Status"::Running]) then
      Error(JobErr);
    StoredJob.Get(Rec.ID);
    StoredJob.TestField(Status, StoredJob.Status::"In Process");
    StoredJob.TestField("Object Type to Run", StoredJob."Object Type to Run"::Codeunit);
    StoredJob.TestField("Object ID to Run", Codeunit::"BCSF Batch Worker");
    StoredJob.TestField("Job Queue Category Code", 'BCSF.SER');
    StoredJob.TestField("Maximum No. of Attempts to Run", 0);
    StoredJob.TestField("Recurring Job", false);
    if StoredJob."Record ID to Process" <> Batch.RecordId() then
      Error(JobErr);
    if Execution."Earliest Start" > CurrentDateTime() then
      Error(JobErr);
    Prior.SetRange("Run Id", Batch."Run Id");
    Prior.SetFilter("Sequence No.", '<%1', Batch."Sequence No.");
    Prior.SetFilter(Status, '<>%1', Prior.Status::Completed);
    if not Prior.IsEmpty() then
      Error(JobErr);
    Writer.CheckExecution(Batch."Run Id");
    Batch.Status := Batch.Status::Running;
    Batch."Started At" := CurrentDateTime();
    Batch.Modify(true);
    Execution.Status := "BCSF Run Status"::Running;
    if Execution."Started At" = 0DT then
      Execution."Started At" := Batch."Started At";
    Execution.Modify(true);
    // Durable claim. Any later error must leave evidence instead of allowing another blind execution.
    Commit();
    Runner.Execute(Batch."Batch Id", Rec.ID);
  end;

  var
    BackgroundErr: Label 'Execute prepared Scenario Factory batches through the background job queue.';
    JobErr: Label 'The job does not own the next pending batch or its execution context is invalid. Review the saved execution; do not replay it.';
}
