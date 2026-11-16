namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

codeunit 90356 "BCSF Monitoring Mgt"
{
  Access = Internal;

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
    RunningLbl: Label 'Running; unconfirmed work remains';
    CancelledLbl: Label 'Cancelled work remains outstanding';
    WaitingLbl: Label 'Unconfirmed work remains';
    NoPlanLbl: Label 'No saved plan';
    BlockedLbl: Label 'Plan blocked / prerequisite unverified';
    ReviewLbl: Label 'Batch review required';
    BatchCompleteLbl: Label 'Batches confirmed';
}
