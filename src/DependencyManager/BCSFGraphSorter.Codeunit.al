namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;

codeunit 90202 "BCSF Graph Sorter"
{
  Access = Internal;

  /// <summary>Kahn ordering with code-based ties. Required missing nodes and cycles remain blockers; no database writes.</summary>
  procedure Sort(var Nodes: Record "BCSF Plan Node" temporary; var Edges: Record "BCSF Dependency" temporary): Boolean
  var
    TempOther: Record "BCSF Plan Node" temporary;
    CurrentCode: Code[30];
    Position: Integer;
    Acyclic: Boolean;
  begin
    Nodes.Reset();
    TempOther.Copy(Nodes, true);
    if Nodes.FindSet() then
      repeat
        Nodes.Processed := false;
        Nodes."In Degree" := 0;
        Nodes."Sequence No." := 0;
        if Nodes.Issue in ["BCSF Plan Issue"::Cycle, "BCSF Plan Issue"::MissingDependency] then begin
          Nodes.Issue := "BCSF Plan Issue"::None;
          Nodes."Reference Code" := '';
        end;
        Nodes.Modify();
      until Nodes.Next() = 0;
    Edges.Reset();
    if Edges.FindSet() then
      repeat
        if not Nodes.Get(Edges."Node Code") then
          Error(InvalidEdgeErr, Edges."Node Code");
        if TempOther.Get(Edges."Predecessor Code") then begin
          Nodes."In Degree" := Nodes."In Degree" + 1;
          Nodes.Modify();
        end else
          if Edges.Kind <> "BCSF Dependency Kind"::Optional then
            if Nodes.Issue = "BCSF Plan Issue"::None then begin
              if Edges.Kind = "BCSF Dependency Kind"::External then
                Nodes.Issue := "BCSF Plan Issue"::ExternalPreflight
              else
                Nodes.Issue := "BCSF Plan Issue"::MissingDependency;
              Nodes."Reference Code" := Edges."Predecessor Code";
              Nodes.Modify();
            end;
      until Edges.Next() = 0;
    Nodes.Reset();
    Nodes.SetCurrentKey(Processed, "In Degree", "Node Code");
    Nodes.SetRange(Processed, false);
    Nodes.SetRange("In Degree", 0);
    while Nodes.FindFirst() do begin
      Position := Position + 1;
      CurrentCode := Nodes."Node Code";
      Nodes.Processed := true;
      Nodes."Sequence No." := Position;
      Nodes.Modify();
      Edges.Reset();
      Edges.SetCurrentKey("Predecessor Code", "Node Code");
      Edges.SetRange("Predecessor Code", CurrentCode);
      if Edges.FindSet() then
        repeat
          TempOther.Get(Edges."Node Code");
          TempOther."In Degree" := TempOther."In Degree" - 1;
          TempOther.Modify();
        until Edges.Next() = 0;
    end;
    Nodes.Reset();
    Nodes.SetRange(Processed, false);
    Acyclic := Nodes.IsEmpty();
    if Nodes.FindSet() then
      repeat
        Nodes.Issue := "BCSF Plan Issue"::Cycle;
        Nodes."Reference Code" := Nodes."Node Code";
        Nodes.Modify();
      until Nodes.Next() = 0;
    Nodes.Reset();
    Edges.Reset();
    exit(Acyclic);
  end;

  var
    InvalidEdgeErr: Label 'Dependency node %1 is not present in the plan.', Comment = '%1 = node code';
}
