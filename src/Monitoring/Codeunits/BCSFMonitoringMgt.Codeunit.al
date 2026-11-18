namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Threading;

codeunit 90356 "BCSF Monitoring Mgt"
{
  Access = Internal;

  procedure FindFirstError(RunId: Guid; var FirstLog: Record "Job Queue Log Entry"): Boolean
  var
    Batch: Record "BCSF Batch";
    Log: Record "Job Queue Log Entry";
    History: Record "BCSF Run Event";
    Found: Boolean;
  begin
    if not Log.ReadPermission() then
      exit(false);
    Log.SecurityFiltering(SecurityFilter::Disallowed);
    Batch.SetRange("Run Id", RunId);
    if Batch.FindSet() then
      repeat
        Log.Reset();
        Log.SecurityFiltering(SecurityFilter::Disallowed);
        Log.SetCurrentKey("Start Date/Time", ID);
        Log.SetRange("Object Type to Run", Log."Object Type to Run"::Codeunit);
        Log.SetRange("Object ID to Run", Codeunit::"BCSF Batch Worker");
        Log.SetRange(Status, Log.Status::Error);
        Log.SetRange(ID, Batch."Job Queue Entry Id");
        if Log.FindFirst() then
          ChooseFirstError(Log, FirstLog, Found);
        if not IsNullGuid(Batch."Previous Job Id") then begin
          Log.SetRange(ID, Batch."Previous Job Id");
          if Log.FindFirst() then
            ChooseFirstError(Log, FirstLog, Found);
        end;
      until Batch.Next() = 0;
    History.SetRange("Run Id", RunId);
    if History.FindSet() then
      repeat
        if not IsNullGuid(History."Job Queue Entry Id") then begin
          Log.SetRange(ID, History."Job Queue Entry Id");
          if Log.FindFirst() then
            ChooseFirstError(Log, FirstLog, Found);
        end;
      until History.Next() = 0;
    exit(Found);
  end;

  local procedure ChooseFirstError(Log: Record "Job Queue Log Entry"; var FirstLog: Record "Job Queue Log Entry"; var Found: Boolean)
  begin
    if not Found or (Log."Start Date/Time" < FirstLog."Start Date/Time") or
      ((Log."Start Date/Time" = FirstLog."Start Date/Time") and (Log."Entry No." < FirstLog."Entry No.")) then
      FirstLog := Log;
    Found := true;
  end;

  procedure FindFailureBatch(RunId: Guid; JobId: Guid; var Batch: Record "BCSF Batch"): Boolean
  var
    History: Record "BCSF Run Event";
  begin
    Batch.Reset();
    Batch.SetRange("Run Id", RunId);
    if Batch.FindSet() then
      repeat
        if (Batch."Job Queue Entry Id" = JobId) or (Batch."Previous Job Id" = JobId) then
          exit(true);
      until Batch.Next() = 0;
    History.SetRange("Run Id", RunId);
    History.SetRange("Job Queue Entry Id", JobId);
    History.SetFilter("Batch Id", '<>%1', EmptyGuid());
    if History.FindFirst() then begin
      Batch.Reset();
      exit(Batch.Get(History."Batch Id"));
    end;
    exit(false);
  end;

  local procedure EmptyGuid(): Guid
  var
    Value: Guid;
  begin
    exit(Value);
  end;

  procedure ShowFailure(RunId: Guid)
  var
    Log: Record "Job Queue Log Entry";
    Finding: Record "BCSF Validation Result";
    Batch: Record "BCSF Batch";
  begin
    if FindFirstError(RunId, Log) then begin
      // Use standard registered error details; do not copy raw error data into our audit.
      Log.ShowErrorMessage();
      Log.SetRange("Entry No.", Log."Entry No.");
      Page.Run(Page::"Job Queue Log Entries", Log);
      exit;
    end;
    Finding.SetRange("Run Id", RunId);
    Finding.SetRange(Severity, Finding.Severity::Error);
    if not Finding.IsEmpty() then begin
      Page.Run(Page::"BCSF Validation Results", Finding);
      exit;
    end;
    Message(MissingErrorLbl);
    Batch.SetRange("Run Id", RunId);
    Batch.SetFilter(Status, '%1|%2|%3', Batch.Status::Failed, Batch.Status::NeedsReview, Batch.Status::Running);
    Page.Run(Page::"BCSF Batch List", Batch);
  end;

  procedure OpenPartners(RunId: Guid; Customers: Boolean)
  var
    Entry: Record "BCSF Generated Record";
    Customer: Record Customer;
    Vendor: Record Vendor;
  begin
    Entry.SetRange("Run Id", RunId);
    if Customers then
      Entry.SetRange("Table Id", Database::Customer)
    else
      Entry.SetRange("Table Id", Database::Vendor);
    if not Entry.FindSet() then
      Error(NoResultsErr);
    repeat
      if Customers then begin
        if Customer.GetBySystemId(Entry."Record SystemId") then
          Customer.Mark(true);
      end else
        if Vendor.GetBySystemId(Entry."Record SystemId") then
          Vendor.Mark(true);
    until Entry.Next() = 0;
    if Customers then begin
      Customer.MarkedOnly(true);
      if Customer.IsEmpty() then
        Error(NoResultsErr);
      Page.Run(Page::"Customer List", Customer);
    end else begin
      Vendor.MarkedOnly(true);
      if Vendor.IsEmpty() then
        Error(NoResultsErr);
      Page.Run(Page::"Vendor List", Vendor);
    end;
  end;

  procedure CountPartners(RunId: Guid; TableId: Integer): Integer
  var
    Entry: Record "BCSF Generated Record";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Table Id", TableId);
    exit(Entry.Count());
  end;

  procedure LoadSteps(RunId: Guid; var TempMetric: Record "BCSF Step Metric" temporary)
  var
    Step: Record "BCSF Run Step";
    Batch: Record "BCSF Batch";
    TempTarget: Record "BCSF Data Target" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    TempMetric.Reset();
    TempMetric.DeleteAll();
    if IsNullGuid(RunId) then
      exit;
    Step.SetRange("Run Id", RunId);
    if Step.FindSet() then
      repeat
        TempMetric.Init();
        TempMetric."Run Id" := RunId;
        TempMetric."Node Code" := Step."Node Code";
        TempMetric."Module Code" := Step."Module Code";
        TempMetric."Entity Code" := Step."Entity Code";
        TempMetric."Planned Units" := Step."Work Units";
        TempMetric.Issue := Step.Issue;
        TempMetric."Reference Code" := Step."Reference Code";
        TempMetric."External Check" := Step."External Check";
        TempMetric."Plan Saved" := true;
        TempMetric.Insert();
      until Step.Next() = 0
    else begin
      Manager.LoadFrozenTargets(RunId, TempTarget);
      TempTarget.SetFilter(Quantity, '>0');
      if TempTarget.FindSet() then
        repeat
          TempMetric.Init();
          TempMetric."Run Id" := RunId;
          TempMetric."Node Code" := Policy.GetEntityCode(TempTarget.Entity);
          TempMetric."Entity Code" := TempMetric."Node Code";
          TempMetric."Module Code" := Policy.GetModuleCode(TempTarget.Module);
          TempMetric."Planned Units" := TempTarget.Quantity;
          TempMetric.Insert();
        until TempTarget.Next() = 0;
    end;
    Batch.SetCurrentKey("Run Id", "Sequence No.");
    Batch.SetRange("Run Id", RunId);
    if Batch.FindSet() then
      repeat
        if TempMetric.Get(RunId, Batch."Node Code") then begin
          TempMetric."Total Batches" += 1;
          case Batch.Status of
            Batch.Status::Completed:
              begin
                TempMetric."Completed Batches" += 1;
                TempMetric."Confirmed Units" += Batch."Processed Units";
                TempMetric."Created Artifacts" += Batch."Created Records";
              end;
            Batch.Status::Running:
              TempMetric."Running Batches" += 1;
            Batch.Status::Cancelled:
              TempMetric."Cancelled Batches" += 1;
            Batch.Status::Failed, Batch.Status::NeedsReview:
              TempMetric."Review Batches" += 1;
          end;
          TempMetric.Modify();
        end;
      until Batch.Next() = 0;
    if TempMetric.FindSet() then
      repeat
        TempMetric."Remaining Units" := TempMetric."Planned Units" - TempMetric."Confirmed Units";
        if not TempMetric."External Check" and (TempMetric."Planned Units" > 0) then
          TempMetric."Progress Percent" := Round(100 * TempMetric."Confirmed Units" / TempMetric."Planned Units", 0.01);
        TempMetric.State := WaitingLbl;
        if not TempMetric."Plan Saved" then
          TempMetric.State := NoPlanLbl
        else
          if TempMetric."External Check" or (TempMetric.Issue <> "BCSF Plan Issue"::None) then
            TempMetric.State := BlockedLbl
          else
            if TempMetric."Review Batches" > 0 then
              TempMetric.State := ReviewLbl
            else
              if TempMetric."Running Batches" > 0 then
                TempMetric.State := RunningLbl
              else
                if TempMetric."Cancelled Batches" > 0 then
                  TempMetric.State := CancelledLbl
                else
                  if (TempMetric."Total Batches" > 0) and (TempMetric."Completed Batches" = TempMetric."Total Batches") and
                    (TempMetric."Confirmed Units" = TempMetric."Planned Units")
                  then
                    TempMetric.State := BatchCompleteLbl;
        TempMetric.Modify();
      until TempMetric.Next() = 0;
  end;

  var
    NoResultsErr: Label 'This run has no visible generated partners of the selected type. Review its result provenance.';
    MissingErrorLbl: Label 'The original queue error is not available. Review the affected batch and obtain the earliest failed standard job queue log, including its full error and call stack. Do not repeat claimed work without a verified checkpoint.';
    RunningLbl: Label 'Running; unconfirmed work remains';
    CancelledLbl: Label 'Cancelled work remains outstanding';
    WaitingLbl: Label 'Unconfirmed work remains';
    NoPlanLbl: Label 'No saved plan';
    BlockedLbl: Label 'Plan blocked / prerequisite unverified';
    ReviewLbl: Label 'Batch review required';
    BatchCompleteLbl: Label 'Batches confirmed';
}
