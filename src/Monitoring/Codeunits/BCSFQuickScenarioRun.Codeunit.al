namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Finance;
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
    Setup: Record "BCSF Factory Setup";
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
    Manager.LoadFrozenTargets(RunId, TempTarget);
    TempTarget.SetFilter(Quantity, '>0');
    if not TempTarget.FindSet() then
      Error(PartnerOnlyErr);
    repeat
      if not (TempTarget.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor]) then
        Error(PartnerOnlyErr);
    until TempTarget.Next() = 0;
    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    if not Setup."Generation Enabled" then begin
      Setup.Validate("Generation Enabled", true);
      Setup.Modify(true);
    end;
    Execution.LockTable();
    if not Execution.Get(RunId) then begin
      Plan.SavePlan(RunId);
      Dispatcher.Prepare(RunId);
    end else
      Execution.TestField(Status, Execution.Status::Ready);
    Dispatcher.Schedule(RunId, CurrentDateTime());
  end;

  procedure RunScenario(Scenario: Record "BCSF Scenario"): Guid
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Approval: Text;
  begin
    CheckTargets(Scenario);
    if not PrepareFinance(Scenario) then
      exit(EmptyId());
    Approval := ExistingQst;
    if not Confirm(Approval, false, Manager.GetDisplayName(Scenario), CompanyName()) then
      exit(EmptyId());
    exit(StartConfirmed(Scenario."Scenario Id", Scenario.Revision));
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure StartConfirmed(ScenarioId: Guid; ConfirmedRevision: Integer): Guid
  var
    Scenario: Record "BCSF Scenario";
    Setup: Record "BCSF Factory Setup";
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
    CheckTargets(Scenario);
    SetupMgt.InitializeSetup();
    Guard.EnsureCanConfigure(Scenario.CurrentCompany());

    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    if not Setup."Generation Enabled" then begin
      Setup.Validate("Generation Enabled", true);
      Setup.Modify(true);
    end;
    RunId := Snapshot.CreateSnapshot(ScenarioId);
    Plan.SavePlan(RunId);
    Dispatcher.Prepare(RunId);
    Dispatcher.Schedule(RunId, CurrentDateTime());
    exit(RunId);
  end;

  procedure PrepareFinance(var Scenario: Record "BCSF Scenario"): Boolean
  var
    Packages: Codeunit "BCSF Finance Package Mgt";
  begin
    if (Scenario."Finance Mode" = "BCSF Finance Mode"::Existing) and (Scenario."Customer Posting Group" <> 'BCSF-DEMO') then
      exit(true);
    if (Scenario."Finance Mode" = Packages.GetAppliedMode()) and (Scenario."Finance Mode" <> "BCSF Finance Mode"::Existing) then
      exit(true);
    exit(Packages.ConfigureScenario(Scenario));
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
        if not (Target.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor]) then
          Error(PartnerOnlyErr);
      until Target.Next() = 0;
    if not Found then
      Error(PartnerOnlyErr);
  end;

  local procedure EmptyId(): Guid
  var
    Result: Guid;
  begin
    exit(Result);
  end;

  var
    CapturedQst: Label 'Start this captured partner run after rechecking its setup and permissions? Test generation will be enabled. Existing or uncertain batches are not repeated.';
    PartnerOnlyErr: Label 'Quick run supports only customer and vendor master data. Use guided planning to inspect other templates.';
    ExistingQst: Label 'Start %1 in company %2 using its existing BC setup? This enables test data generation in the company. No posting is approved.', Comment = '%1 = scenario description, %2 = company';
}
