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

  procedure RunScenario(Scenario: Record "BCSF Scenario"): Guid
  var
    DemoSetup: Codeunit "BCSF Demo Partner Setup";
    Approval: Text;
  begin
    CheckTargets(Scenario);
    if DemoSetup.UsesDemoSetup(Scenario) then
      Approval := DemoQst
    else
      Approval := ExistingQst;
    if not Confirm(Approval, false, Scenario.Description, CompanyName()) then
      exit(EmptyId());
    exit(StartConfirmed(Scenario."Scenario Id", Scenario.Revision));
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure StartConfirmed(ScenarioId: Guid; ConfirmedRevision: Integer): Guid
  var
    Scenario: Record "BCSF Scenario";
    Setup: Record "BCSF Factory Setup";
    SetupMgt: Codeunit "BCSF Setup Management";
    DemoSetup: Codeunit "BCSF Demo Partner Setup";
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
    if DemoSetup.UsesDemoSetup(Scenario) then
      DemoSetup.EnsureSetup(Scenario);
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

  local procedure CheckTargets(Scenario: Record "BCSF Scenario")
  var
    Target: Record "BCSF Data Target";
    Found: Boolean;
  begin
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
    PartnerOnlyErr: Label 'Quick run supports only customer and vendor master data. Use guided planning to inspect other templates.';
    DemoQst: Label 'Start %1 in company %2? This prepares missing demo partner setup and enables test data generation in the company. No posting is approved.', Comment = '%1 = scenario description, %2 = company';
    ExistingQst: Label 'Start %1 in company %2 using its existing BC setup? This enables test data generation in the company. No posting is approved.', Comment = '%1 = scenario description, %2 = company';
}
