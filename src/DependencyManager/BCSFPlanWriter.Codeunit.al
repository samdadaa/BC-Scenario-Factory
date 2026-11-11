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
    if Step.FindSet() then
      repeat
        Step.TestField("Plan Version", 1);
        if Step.Issue <> "BCSF Plan Issue"::None then
          Error(BlockedErr, Step."Node Code", Planner.GetIssueText(Step.Issue, Step."Reference Code"));
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
    Header.TestField(Status, "BCSF Run Status"::Ready);
    OnBeforeRunStart(RunId);
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
