namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Validation;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Threading;

pageextension 90358 "BCSF Run Monitoring" extends "BCSF Run Card"
{
  layout
  {
    addfirst(Content)
    {
      group(RunResults)
      {
        Caption = 'Progress and Results';
        field(CurrentStatus; StatusText)
        {
          ApplicationArea = All;
          Caption = 'Current Execution Status';
          ToolTip = 'Shows the current background execution state. Refresh this page to read the latest persisted progress.';
          Style = Strong;
        }
        field(ConfirmedBatches; BatchText)
        {
          ApplicationArea = All;
          Caption = 'Confirmed Batches';
          ToolTip = 'Shows confirmed completed batches compared with all prepared batches.';
        }
        field(Quality; QualityText)
        {
          ApplicationArea = All;
          Caption = 'Final Validation';
          ToolTip = 'Shows the saved final validation result for this run.';
        }
        field(Customers; CustomerCount)
        {
          ApplicationArea = All;
          Caption = 'Generated Customers';
          ToolTip = 'Opens only customers whose stable identities were recorded for this run.';
          DrillDown = true;
          trigger OnDrillDown()
          var
            Monitor: Codeunit "BCSF Monitoring Mgt";
          begin
            Monitor.OpenPartners(Rec."Run Id", true);
          end;
        }
        field(Vendors; VendorCount)
        {
          ApplicationArea = All;
          Caption = 'Generated Vendors';
          ToolTip = 'Opens only vendors whose stable identities were recorded for this run.';
          DrillDown = true;
          trigger OnDrillDown()
          var
            Monitor: Codeunit "BCSF Monitoring Mgt";
          begin
            Monitor.OpenPartners(Rec."Run Id", false);
          end;
        }
        field(AffectedBatch; AffectedBatchText)
        {
          ApplicationArea = All;
          Caption = 'Affected Batch';
          ToolTip = 'Opens the batch associated with the original queue error or the first unconfirmed failure.';
          Visible = CanShowErrors;
          DrillDown = true;
          trigger OnDrillDown()
          var
            Batch: Record "BCSF Batch";
          begin
            if IsNullGuid(AffectedBatchId) then
              exit;
            Batch.SetRange("Batch Id", AffectedBatchId);
            Page.Run(Page::"BCSF Batch List", Batch);
          end;
        }
        field(Failure; ErrorText)
        {
          ApplicationArea = All;
          Caption = 'Original Queue Error';
          ToolTip = 'Shows the earliest available failed queue message. Use Show Errors for its full registered details and call stack.';
          Visible = CanShowErrors;
          MultiLine = true;
        }
        field(NextStep; NextStepText)
        {
          ApplicationArea = All;
          Caption = 'Next Step';
          ToolTip = 'Explains the safe next action without authorizing an automatic retry.';
          Visible = CanShowErrors;
          MultiLine = true;
        }
      }
    }
    addlast(Content)
    {
      part(Monitoring; "BCSF Run Overview")
      {
        ApplicationArea = All;
        SubPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  actions
  {
    addfirst(Processing)
    {
      action(StartRun)
      {
        ApplicationArea = All;
        Caption = 'Start';
        ToolTip = 'Checks, prepares and starts this captured partner run with one confirmation.';
        Image = Start;
        Visible = CanStart;
        trigger OnAction()
        var
          QuickRun: Codeunit "BCSF Quick Scenario Run";
        begin
          QuickRun.StartCaptured(Rec."Run Id");
          CurrPage.Update(false);
        end;
      }
      action(ViewProgress)
      {
        ApplicationArea = All;
        Caption = 'View Progress';
        ToolTip = 'Refreshes the run and opens its confirmed step progress.';
        Image = Statistics;
        Visible = CanViewProgress;
        trigger OnAction()
        var
          ProgressPage: Page "BCSF Step Progress";
        begin
          CurrPage.Update(false);
          ProgressPage.SetRunId(Rec."Run Id");
          ProgressPage.Run();
        end;
      }
      action(ShowErrors)
      {
        ApplicationArea = All;
        Caption = 'Show Errors';
        ToolTip = 'Opens this run''s original queue error or failed validation, with the affected batch retained for safe review.';
        Image = ErrorLog;
        Visible = CanShowErrors;
        trigger OnAction()
        var
          Monitor: Codeunit "BCSF Monitoring Mgt";
        begin
          Monitor.ShowFailure(Rec."Run Id");
        end;
      }
      action(OpenResults)
      {
        ApplicationArea = All;
        Caption = 'Open Results';
        ToolTip = 'Opens the provenance of records created by this run. Each partner result opens its exact standard record.';
        Image = View;
        Visible = HasResults and not CanViewProgress and not CanShowErrors;
        RunObject = page "BCSF Generated Records";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
    addlast(Promoted)
    {
      actionref(StartRunPromoted; StartRun) { }
      actionref(ViewProgressPromoted; ViewProgress) { }
      actionref(ShowErrorsPromoted; ShowErrors) { }
      actionref(OpenResultsPromoted; OpenResults) { }
    }
    addlast(Diagnostics)
    {
      action(MonitorProgress)
      {
        ApplicationArea = All;
        Caption = 'View Step Progress';
        ToolTip = 'Compares frozen entity targets with confirmed completed batches. Cancelled or uncertain work remains outstanding.';
        Image = Statistics;
        trigger OnAction()
        var
          ProgressPage: Page "BCSF Step Progress";
        begin
          ProgressPage.SetRunId(Rec."Run Id");
          ProgressPage.Run();
        end;
      }
      action(Dashboard)
      {
        ApplicationArea = All;
        Caption = 'Dashboard';
        ToolTip = 'Opens persisted monitoring without starting any work.';
        Image = Statistics;
        RunObject = page "BCSF Dashboard Host";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Execution: Record "BCSF Run Execution";
    Log: Record "Job Queue Log Entry";
    Batch: Record "BCSF Batch";
    Header: Record "BCSF Run Header";
    TempTarget: Record "BCSF Data Target" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Monitor: Codeunit "BCSF Monitoring Mgt";
    Validation: Codeunit "BCSF Validation Manager";
    PartnerOnly: Boolean;
    Prepared: Boolean;
  begin
    Header := Rec;
    Prepared := Execution.Get(Rec."Run Id");
    StatusText := NotStartedLbl;
    if Prepared then
      StatusText := Format(Execution.Status);
    BatchText := StrSubstNo(BatchCountLbl, Execution."Completed Batches", Execution."Total Batches");
    QualityText := Validation.Describe(Rec."Run Id");
    CustomerCount := Monitor.CountPartners(Rec."Run Id", Database::Customer);
    VendorCount := Monitor.CountPartners(Rec."Run Id", Database::Vendor);
    HasResults := CustomerCount + VendorCount > 0;
    CanShowErrors := Prepared and (Execution.Status in [Execution.Status::Failed, Execution.Status::ValidationFailed]);
    CanViewProgress := Prepared and (Execution.Status in [Execution.Status::Queued, Execution.Status::Scheduled, Execution.Status::Running]);
    CanStart := not Prepared or (Execution.Status = Execution.Status::Ready);
    if CanStart then begin
      Manager.LoadFrozenTargets(Rec."Run Id", TempTarget);
      TempTarget.SetFilter(Quantity, '>0');
      PartnerOnly := not TempTarget.IsEmpty() and (Header."Process Mode" = "BCSF Process Mode"::SetupAndMasterData);
      if TempTarget.FindSet() then
        repeat
          PartnerOnly := PartnerOnly and (TempTarget.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor]);
        until TempTarget.Next() = 0;
      CanStart := CanStart and PartnerOnly;
    end;
    Clear(ErrorText);
    Clear(AffectedBatchId);
    Clear(AffectedBatchText);
    NextStepText := ReviewLbl;
    if CanShowErrors then begin
      if Monitor.FindFirstError(Rec."Run Id", Log) then begin
        ErrorText := Log."Error Message";
        if Monitor.FindFailureBatch(Rec."Run Id", Log.ID, Batch) then
          AffectedBatchId := Batch."Batch Id";
      end;
      if IsNullGuid(AffectedBatchId) then begin
        Batch.Reset();
        Batch.SetRange("Run Id", Rec."Run Id");
        Batch.SetFilter(Status, '%1|%2', Batch.Status::Failed, Batch.Status::NeedsReview);
        if Batch.FindFirst() then
          AffectedBatchId := Batch."Batch Id";
      end;
      if not IsNullGuid(AffectedBatchId) then begin
        Batch.Get(AffectedBatchId);
        AffectedBatchText := Batch."Batch Key";
        if Batch.Status = Batch.Status::Failed then
          NextStepText := UnclaimedLbl;
      end;
      if Execution.Status = Execution.Status::ValidationFailed then
        NextStepText := ValidationFailedLbl;
    end;
  end;
  var
    AffectedBatchId: Guid;
    AffectedBatchText: Text;
    StatusText: Text;
    BatchText: Text;
    QualityText: Text;
    ErrorText: Text;
    NextStepText: Text;
    CustomerCount: Integer;
    VendorCount: Integer;
    CanStart: Boolean;
    CanViewProgress: Boolean;
    CanShowErrors: Boolean;
    HasResults: Boolean;
    NotStartedLbl: Label 'Not started';
    BatchCountLbl: Label '%1 of %2', Comment = '%1 = completed batches, %2 = total batches';
    UnclaimedLbl: Label 'The batch failed before claim. Read the original error, correct setup or permissions, then use Diagnostics, Batches, Retry Unclaimed Failure. The server checks that no work was claimed or recorded.';
    ValidationFailedLbl: Label 'Open Show Errors to inspect the failed final validation. Existing results are retained; do not repeat generation to repair an unverified result.';
    ReviewLbl: Label 'Open Show Errors and review the affected batch. Claimed work must not be repeated without a verified checkpoint. Recovery actions are under Diagnostics.';
}
