namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;

codeunit 90204 "BCSF Plan Writer"
{
  Access = Internal;
  Permissions = tabledata "BCSF Run Step" = I;

  [CommitBehavior(CommitBehavior::Error)]
  procedure SavePlan(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    TempNodes: Record "BCSF Plan Node" temporary;
    TempEdges: Record "BCSF Dependency" temporary;
    Planner: Codeunit "BCSF Dependency Planner";
  begin
    Header.LockTable();
    Header.Get(RunId);
    Step.SetRange("Run Id", RunId);
    if Step.FindFirst() then begin
      Step.TestField("Plan Version", 1);
      exit;
    end;
    Planner.BuildFromRun(RunId, TempNodes, TempEdges);
    if TempNodes.FindSet() then
      repeat
        FillStep(RunId, TempNodes, Step);
        Step.Insert(true);
      until TempNodes.Next() = 0;
  end;

  procedure LoadPreview(RunId: Guid; var Steps: Record "BCSF Run Step" temporary)
  var
    TempNodes: Record "BCSF Plan Node" temporary;
    TempEdges: Record "BCSF Dependency" temporary;
    Planner: Codeunit "BCSF Dependency Planner";
  begin
    if not Steps.IsTemporary() then
      Error(TemporaryErr);
    Steps.Reset();
    Steps.DeleteAll();
    Planner.BuildFromRun(RunId, TempNodes, TempEdges);
    if TempNodes.FindSet() then
      repeat
        FillStep(RunId, TempNodes, Steps);
        Steps.Insert(false);
      until TempNodes.Next() = 0;
    Steps.SetCurrentKey("Run Id", "Sequence No.", "Node Code");
  end;

  /// <summary>Fail-closed start gate. It never queues or executes a run and cannot make a draft ready.</summary>
  procedure CheckStart(RunId: Guid)
  begin
    // Readiness only. The dispatcher separately validates the persisted operational state.
    CheckExecution(RunId);
  end;

  /// <summary>Rechecks immutable plan bindings and all execution gates; operational status belongs to BackgroundProcessing.</summary>
  procedure CheckExecution(RunId: Guid)
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Planner: Codeunit "BCSF Dependency Planner";
  begin
    Header.Get(RunId);
    Step.SetRange("Run Id", RunId);
    if Step.IsEmpty() then
      Error(MissingPlanErr);
    // Give an actual target's blocker priority over the generic external planning barrier.
    Step.SetRange("External Check", false);
    Step.SetFilter(Issue, '<>%1', "BCSF Plan Issue"::None);
    if Step.FindFirst() then
      CheckSavedIssue(Step, Planner);
    Step.SetRange(Issue);
    Step.SetRange("External Check");
    if Step.FindSet() then
      repeat
        Step.TestField("Plan Version", 1);
        if Step.Issue <> "BCSF Plan Issue"::None then
          CheckSavedIssue(Step, Planner);
        if Step."External Check" then
          Error(ExternalErr);
        Registry.Resolve(Step."Generator Code", Step."Entity Code", TempCapability);
        if TempCapability."Contract Probe" or (TempCapability.Version <> Step."Generator Version") or
          (TempCapability."Contract Version" <> Step."Contract Version") or
          (Header."Batch Size" > TempCapability."Maximum Batch Size") or
          (TempCapability."Module Code" <> Step."Module Code") or not Registry.SupportsMode(TempCapability, Step."Process Mode")
        then
          Error(VersionErr);
      until Step.Next() = 0;
    OnBeforeRunStart(RunId);
  end;

  local procedure CheckSavedIssue(Step: Record "BCSF Run Step"; Planner: Codeunit "BCSF Dependency Planner")
  begin
    Step.TestField("Plan Version", 1);
    if Step.Issue = "BCSF Plan Issue"::Prerequisite then
      ExplainSavedPrerequisite(Step);
    Error(BlockedErr, Step."Node Code", Planner.GetIssueText(Step.Issue, Step."Reference Code"));
  end;

  local procedure ExplainSavedPrerequisite(Step: Record "BCSF Run Step")
  var
    TempCapability: Record "BCSF Generator Registry" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Generator: Interface "BCSF Generator";
    Context: JsonObject;
    Target: JsonObject;
  begin
    Generator := Registry.Resolve(Step."Generator Code", Step."Entity Code", TempCapability);
    if TempCapability."Contract Probe" or (TempCapability.Version <> Step."Generator Version") or
      (TempCapability."Contract Version" <> Step."Contract Version") or
      (TempCapability."Module Code" <> Step."Module Code") or not Registry.SupportsMode(TempCapability, Step."Process Mode")
    then
      Error(VersionErr);
    Manager.ReadSnapshot(Step."Run Id", Context);
    Target.Add('entityCode', Step."Entity Code");
    Target.Add('moduleCode', Step."Module Code");
    Target.Add('quantity', Step."Work Units");
    Target.Add('processMode', Step."Process Mode".AsInteger());
    Registry.RequirePrerequisites(Generator, Context, Target);
    // A corrected requirement cannot thaw an immutable blocked plan.
  end;

  local procedure FillStep(RunId: Guid; Node: Record "BCSF Plan Node" temporary; var Step: Record "BCSF Run Step")
  begin
    Step.Init();
    Step."Run Id" := RunId;
    Step."Node Code" := Node."Node Code";
    Step."Module Code" := Node."Module Code";
    Step."Entity Code" := Node."Entity Code";
    Step."Process Mode" := Node."Process Mode";
    Step."Work Units" := Node."Work Units";
    Step."Generator Code" := Node."Generator Code";
    Step."Generator Version" := Node."Generator Version";
    Step."Contract Version" := Node."Contract Version";
    Step."External Check" := Node."External Check";
    Step.Issue := Node.Issue;
    Step."Reference Code" := Node."Reference Code";
    Step."Sequence No." := Node."Sequence No.";
    Step."Plan Version" := 1;
  end;

  [IntegrationEvent(false, false)]
  local procedure OnBeforeRunStart(RunId: Guid)
  begin
  end;

  var
    TemporaryErr: Label 'Planning previews require temporary display records.';
    MissingPlanErr: Label 'Save a run plan before checking readiness.';
    BlockedErr: Label 'Run step %1 is blocked: %2', Comment = '%1 = step code, %2 = localized blocker';
    ExternalErr: Label 'External setup or stock evidence is missing. The run cannot start.';
    VersionErr: Label 'The saved generator binding no longer matches the compiled catalog. Capture a new run; do not silently replace the plan.';
}
