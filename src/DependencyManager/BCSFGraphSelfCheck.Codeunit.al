namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;

codeunit 90207 "BCSF Graph Self Check"
{
  Access = Internal;

  procedure Check()
  var
    TempNodes: Record "BCSF Plan Node" temporary;
    TempEdges: Record "BCSF Dependency" temporary;
    Planner: Codeunit "BCSF Dependency Planner";
    Sorter: Codeunit "BCSF Graph Sorter";
  begin
    AddNode(TempNodes, 'FINANCE');
    AddNode(TempNodes, 'MASTER');
    AddNode(TempNodes, 'PURCHASING');
    AddNode(TempNodes, 'INVENTORY');
    AddNode(TempNodes, 'SALES');
    Planner.AddEdge(TempEdges, 'MASTER', 'FINANCE', "BCSF Dependency Kind"::Required);
    Planner.AddEdge(TempEdges, 'PURCHASING', 'MASTER', "BCSF Dependency Kind"::Required);
    Planner.AddEdge(TempEdges, 'INVENTORY', 'PURCHASING', "BCSF Dependency Kind"::Required);
    Planner.AddEdge(TempEdges, 'SALES', 'INVENTORY', "BCSF Dependency Kind"::Required);
    Planner.AddEdge(TempEdges, 'SALES', 'NOT.SELECTED', "BCSF Dependency Kind"::Optional);
    if not Sorter.Sort(TempNodes, TempEdges) or Planner.HasBlockers(TempNodes) then
      Error(CheckErr);
    CheckPosition(TempNodes, 'FINANCE', 1);
    CheckPosition(TempNodes, 'MASTER', 2);
    CheckPosition(TempNodes, 'PURCHASING', 3);
    CheckPosition(TempNodes, 'INVENTORY', 4);
    CheckPosition(TempNodes, 'SALES', 5);
    Planner.AddEdge(TempEdges, 'SALES', 'REQUIRED.MISSING', "BCSF Dependency Kind"::Required);
    if not Sorter.Sort(TempNodes, TempEdges) or not Planner.HasBlockers(TempNodes) then
      Error(CheckErr);
    TempNodes.Get('SALES');
    if TempNodes.Issue <> "BCSF Plan Issue"::MissingDependency then
      Error(CheckErr);
    TempEdges.Get('SALES', 'REQUIRED.MISSING');
    TempEdges.Delete();
    Planner.AddEdge(TempEdges, 'FINANCE', 'SALES', "BCSF Dependency Kind"::Required);
    if Sorter.Sort(TempNodes, TempEdges) or not Planner.HasBlockers(TempNodes) then
      Error(CheckErr);
    TempNodes.Reset();
    TempNodes.SetRange("Sequence No.", 0);
    if TempNodes.Count() <> 5 then
      Error(CheckErr);
  end;

  local procedure AddNode(var TempNodes: Record "BCSF Plan Node" temporary; Code: Code[30])
  begin
    TempNodes.Init();
    TempNodes."Node Code" := Code;
    TempNodes.Insert();
  end;

  local procedure CheckPosition(var TempNodes: Record "BCSF Plan Node" temporary; Code: Code[30]; Position: Integer)
  begin
    TempNodes.Get(Code);
    if TempNodes."Sequence No." <> Position then
      Error(CheckErr);
  end;

  var
    CheckErr: Label 'The dependency graph self-check failed. No run or business records were changed.';
}
