namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;

codeunit 90367 "BCSF Quick Scenario Run"
{
  Access = Internal;

  procedure StartCaptured(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
  begin
    Header.Get(RunId);
    if not Confirm(CapturedQst, false) then
      exit;
    StartCapturedConfirmed(RunId);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure StartCapturedConfirmed(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    SetupMgt: Codeunit "BCSF Setup Management";
    TempTarget: Record "BCSF Data Target" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Guard: Codeunit "BCSF Environment Guard";
    Plan: Codeunit "BCSF Plan Writer";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
  begin
    Header.LockTable();
    Header.Get(RunId);
    Header.TestField("Process Mode", "BCSF Process Mode"::SetupAndMasterData);
    Guard.EnsureCanConfigure(CompanyName());
    SetupMgt.EnsureInitialized();
    Manager.LoadFrozenTargets(RunId, TempTarget);
    TempTarget.SetFilter(Quantity, '>0');
    if not TempTarget.FindSet() then
      Error(PartnerOnlyErr);
    repeat
      if not (TempTarget.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]) then
        Error(PartnerOnlyErr);
    until TempTarget.Next() = 0;
    Execution.LockTable();
    if not Execution.Get(RunId) then begin
      Plan.SavePlan(RunId);
      Dispatcher.Prepare(RunId);
    end else
      Execution.TestField(Status, Execution.Status::Ready);
    Dispatcher.Schedule(RunId, CurrentDateTime());
  end;

  procedure RunScenario(Scenario: Record "BCSF Scenario"): Guid
  begin
    exit(StartConfirmed(Scenario."Scenario Id", Scenario.Revision));
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure StartConfirmed(ScenarioId: Guid; ConfirmedRevision: Integer): Guid
  var
    Scenario: Record "BCSF Scenario";
    SetupMgt: Codeunit "BCSF Setup Management";
    Guard: Codeunit "BCSF Environment Guard";
    Snapshot: Codeunit "BCSF Snapshot Writer";
    Plan: Codeunit "BCSF Plan Writer";
    Dispatcher: Codeunit "BCSF Queue Dispatcher";
    RunId: Guid;
  begin
    // Snapshot, configuration editors and module/target writes coordinate on the same scenario lock.
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
    Scenario.TestField(Revision, ConfirmedRevision);
    SetupMgt.EnsureInitialized();
    Guard.EnsureCanConfigure(Scenario.CurrentCompany());
    CheckTargets(Scenario);

    RunId := Snapshot.CreateSnapshot(ScenarioId);
    Plan.SavePlan(RunId);
    Dispatcher.Prepare(RunId);
    Dispatcher.Schedule(RunId, CurrentDateTime());
    exit(RunId);
  end;

  local procedure CheckTargets(Scenario: Record "BCSF Scenario")
  var
    Target: Record "BCSF Data Target";
    Found: Boolean;
  begin
    Scenario.TestField(Archived, false);
    if Scenario."Process Mode" <> "BCSF Process Mode"::SetupAndMasterData then
      Error(PartnerOnlyErr);
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if Target.FindSet() then
      repeat
        Found := true;
        if not (Target.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]) then
          Error(PartnerOnlyErr);
      until Target.Next() = 0;
    if not Found then
      Error(PartnerOnlyErr);
  end;

  var
    CapturedQst: Label 'Start this captured master-data run after rechecking its setup and permissions? Existing or uncertain batches are not repeated.';
    PartnerOnlyErr: Label 'Quick run supports customer, vendor and supported item master data. This template depends on generators that are not available yet.';
}
