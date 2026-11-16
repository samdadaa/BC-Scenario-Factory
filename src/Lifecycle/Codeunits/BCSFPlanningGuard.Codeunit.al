namespace BCScenarioFactory.Lifecycle;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;
using System.Environment;

codeunit 90378 "BCSF Planning Guard"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Step", 'OnBeforeInsertEvent', '', false, false)]
  local procedure StepInsert(var Rec: Record "BCSF Run Step"; RunTrigger: Boolean)
  var
    Header: Record "BCSF Run Header";
    Guard: Codeunit "BCSF Environment Guard";
    EnvironmentInformation: Codeunit "Environment Information";
  begin
    if Rec.IsTemporary() then
      exit;
    Guard.EnsureCanConfigure(Rec.CurrentCompany());
    Header.Get(Rec."Run Id");
    Header.TestField("Company Name", CompanyName());
    Header.TestField("Environment Name", EnvironmentInformation.GetEnvironmentName());
    Header.TestField(Status, "BCSF Run Status"::Draft);
    Rec.TestField("Node Code");
    Rec.TestField("Module Code");
    Rec.TestField("Entity Code");
    Rec.TestField("Plan Version", 1);
    if (Rec."Work Units" <= 0) or (Rec."Sequence No." < 0) then
      Error(PlanErr);
    if not (Rec.Issue in ["BCSF Plan Issue"::None, "BCSF Plan Issue"::MissingGenerator,
      "BCSF Plan Issue"::MissingModule, "BCSF Plan Issue"::MissingDependency, "BCSF Plan Issue"::UnsupportedMode,
      "BCSF Plan Issue"::Cycle, "BCSF Plan Issue"::ExternalPreflight, "BCSF Plan Issue"::TestOnly, "BCSF Plan Issue"::Prerequisite])
    then
      Error(PlanErr);
    if Rec.Issue = "BCSF Plan Issue"::None then begin
      Rec.TestField("Generator Code");
      Rec.TestField("Generator Version");
      Rec.TestField("Contract Version", 1);
      if Rec."External Check" or (Rec."Sequence No." = 0) then
        Error(PlanErr);
    end;
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Step", 'OnBeforeModifyEvent', '', false, false)]
  local procedure StepModify(var Rec: Record "BCSF Run Step"; var xRec: Record "BCSF Run Step"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Step", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure StepDelete(var Rec: Record "BCSF Run Step"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Run Step", 'OnBeforeRenameEvent', '', false, false)]
  local procedure StepRename(var Rec: Record "BCSF Run Step"; var xRec: Record "BCSF Run Step"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(ImmutableErr);
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Generator Registry Mgt", 'OnBeforeContractProbe', '', false, false)]
  local procedure CheckProbe(TargetCompanyName: Text)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(TargetCompanyName);
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Plan Writer", 'OnBeforeRunStart', '', false, false)]
  local procedure CheckRun(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    FactorySetup: Record "BCSF Factory Setup";
    Guard: Codeunit "BCSF Environment Guard";
    SetupManagement: Codeunit "BCSF Setup Management";
    EnvironmentInformation: Codeunit "Environment Information";
    BatchSize: Integer;
  begin
    Header.Get(RunId);
    Header.TestField("Company Name", CompanyName());
    Header.TestField("Environment Name", EnvironmentInformation.GetEnvironmentName());
    SetupManagement.GetSetup(FactorySetup);
    Step.SetRange("Run Id", RunId);
    if Step.FindSet() then
      repeat
        BatchSize := Header."Batch Size";
        if BatchSize > Step."Work Units" then
          BatchSize := Step."Work Units";
        // No posting approval exists in this ticket. Posted starts must remain blocked until approved snapshots/worker contracts exist.
        Guard.EnsureCanGenerate(Header.CurrentCompany(), Step."Process Mode", Step."Work Units", BatchSize, false);
      until Step.Next() = 0;
  end;

  var
    ImmutableErr: Label 'Saved planning steps cannot be changed or deleted. Capture a new run to compute a different plan.';
    PlanErr: Label 'The planning step is invalid or claims an unverified prerequisite as ready.';
}
