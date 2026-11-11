namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;

codeunit 90201 "BCSF Dependency Planner"
{
  Access = Internal;

  procedure BuildFromRun(RunId: Guid; var Nodes: Record "BCSF Plan Node" temporary; var Edges: Record "BCSF Dependency" temporary): Boolean
  var
    TempTargets: Record "BCSF Data Target" temporary;
    TempModules: Record "BCSF Scenario Module" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Policy: Codeunit "BCSF Scenario Policy";
    Contract: Codeunit "BCSF Contract JSON";
    Sorter: Codeunit "BCSF Graph Sorter";
    Context: JsonObject;
    EntityCode: Code[30];
    MinimumMode: Enum "BCSF Process Mode";
    UnpostedCount: Integer;
    PostedCount: Integer;
    PartialCount: Integer;
  begin
    Nodes.Reset();
    Nodes.DeleteAll();
    Edges.Reset();
    Edges.DeleteAll();
    Manager.ReadSnapshot(RunId, Context);
    Contract.CheckContext(Context);
    Manager.LoadFrozenTargets(RunId, TempTargets);
    Manager.LoadFrozenModules(RunId, TempModules);
    TempTargets.SetFilter(Quantity, '>0');
    if TempTargets.FindSet() then
      repeat
        EntityCode := Policy.GetEntityCode(TempTargets.Entity);
        Nodes.Init();
        Nodes."Node Code" := EntityCode;
        Nodes."Entity Code" := EntityCode;
        Nodes."Module Code" := Policy.GetModuleCode(TempTargets.Module);
        Nodes."Work Units" := TempTargets.Quantity;
        Nodes."Process Mode" := TempTargets."Process Mode";
        if not IsModuleEnabled(TempModules, Nodes."Module Code") then begin
          Nodes.Issue := "BCSF Plan Issue"::MissingModule;
          Nodes."Reference Code" := Nodes."Module Code";
        end;
        Nodes.Insert();
      until TempTargets.Next() = 0;
    if Nodes.IsEmpty() then
      Error(EmptyPlanErr);
    // Setup is an unresolved external check, never an invented finance generator or setup success.
    EnsureExternal(Nodes, TempModules, 'FINANCE.SETUP', 'FINANCE', MinimumMode);
    TempTargets.Reset();
    TempTargets.SetFilter(Quantity, '>0');
    if TempTargets.FindSet() then
      repeat
        EntityCode := Policy.GetEntityCode(TempTargets.Entity);
        case TempTargets.Entity of
          "BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item:
            AddEdge(Edges, EntityCode, 'FINANCE.SETUP', "BCSF Dependency Kind"::External);
          "BCSF Entity Type"::SalesQuote, "BCSF Entity Type"::SalesOrder,
          "BCSF Entity Type"::SalesInvoice, "BCSF Entity Type"::SalesCreditMemo:
            begin
              AddEntityRequirement(Nodes, Edges, TempModules, EntityCode, 'CUSTOMER', 'SALES');
              AddEntityRequirement(Nodes, Edges, TempModules, EntityCode, 'ITEM', 'INVENTORY');
            end;
          "BCSF Entity Type"::PurchaseOrder, "BCSF Entity Type"::PurchaseInvoice,
          "BCSF Entity Type"::PurchaseCreditMemo:
            begin
              AddEntityRequirement(Nodes, Edges, TempModules, EntityCode, 'VENDOR', 'PURCHASING');
              AddEntityRequirement(Nodes, Edges, TempModules, EntityCode, 'ITEM', 'INVENTORY');
            end;
        end;
        Policy.GetDistribution(TempTargets, UnpostedCount, PostedCount, PartialCount);
        if (TempTargets.Entity in ["BCSF Entity Type"::SalesOrder, "BCSF Entity Type"::SalesInvoice]) and
          ((PostedCount > 0) or (PartialCount > 0))
        then begin
          EnsureExternal(Nodes, TempModules, 'INVENTORY.STOCK', 'INVENTORY', TempTargets."Process Mode");
          AddEntityRequirement(Nodes, Edges, TempModules, 'INVENTORY.STOCK', 'ITEM', 'INVENTORY');
          AddEdge(Edges, EntityCode, 'INVENTORY.STOCK', "BCSF Dependency Kind"::External);
        end;
      until TempTargets.Next() = 0;
    // Planned posted receipts precede the stock check; existing stock still requires independent preflight evidence.
    if Nodes.Get('INVENTORY.STOCK') then begin
      TempTargets.Reset();
      TempTargets.SetFilter(Quantity, '>0');
      if TempTargets.FindSet() then
        repeat
          Policy.GetDistribution(TempTargets, UnpostedCount, PostedCount, PartialCount);
          if (TempTargets.Entity in ["BCSF Entity Type"::PurchaseOrder, "BCSF Entity Type"::PurchaseInvoice]) and
            ((PostedCount > 0) or (PartialCount > 0))
          then
            AddEdge(Edges, 'INVENTORY.STOCK', Policy.GetEntityCode(TempTargets.Entity), "BCSF Dependency Kind"::Required);
        until TempTargets.Next() = 0;
    end;
    ResolveGenerators(Context, TempModules, Nodes, Edges);
    Sorter.Sort(Nodes, Edges);
    exit(not HasBlockers(Nodes));
  end;

  procedure HasBlockers(var Nodes: Record "BCSF Plan Node" temporary): Boolean
  var
    TempCheck: Record "BCSF Plan Node" temporary;
  begin
    TempCheck.Copy(Nodes, true);
    TempCheck.Reset();
    TempCheck.SetFilter(Issue, '<>%1', "BCSF Plan Issue"::None);
    exit(not TempCheck.IsEmpty());
  end;

  procedure IsModuleEnabled(var TempModules: Record "BCSF Scenario Module" temporary; Code: Code[30]): Boolean
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    TempModules.Reset();
    if TempModules.FindSet() then
      repeat
        if Policy.GetModuleCode(TempModules.Module) = Code then
          exit(TempModules.Enabled);
      until TempModules.Next() = 0;
    exit(false);
  end;

  procedure AddEdge(var Edges: Record "BCSF Dependency" temporary; NodeCode: Code[30]; PredecessorCode: Code[30]; Kind: Enum "BCSF Dependency Kind")
  begin
    if Edges.Get(NodeCode, PredecessorCode) then begin
      if (Edges.Kind = "BCSF Dependency Kind"::Optional) and (Kind <> Edges.Kind) then begin
        Edges.Kind := Kind;
        Edges.Modify();
      end;
      exit;
    end;
    Edges.Init();
    Edges."Node Code" := NodeCode;
    Edges."Predecessor Code" := PredecessorCode;
    Edges.Kind := Kind;
    Edges.Insert();
  end;

  procedure GetIssueText(Issue: Enum "BCSF Plan Issue"; ReferenceCode: Code[30]): Text
  begin
    case Issue of
      "BCSF Plan Issue"::None: exit(NoBlockerLbl);
      "BCSF Plan Issue"::MissingGenerator: exit(StrSubstNo(MissingGeneratorLbl, ReferenceCode));
      "BCSF Plan Issue"::MissingModule: exit(StrSubstNo(MissingModuleLbl, ReferenceCode));
      "BCSF Plan Issue"::MissingDependency: exit(StrSubstNo(MissingDependencyLbl, ReferenceCode));
      "BCSF Plan Issue"::UnsupportedMode: exit(StrSubstNo(UnsupportedModeLbl, ReferenceCode));
      "BCSF Plan Issue"::Cycle: exit(StrSubstNo(CycleLbl, ReferenceCode));
      "BCSF Plan Issue"::ExternalPreflight: exit(StrSubstNo(ExternalLbl, ReferenceCode));
      "BCSF Plan Issue"::TestOnly: exit(StrSubstNo(TestOnlyLbl, ReferenceCode));
      "BCSF Plan Issue"::Prerequisite: exit(StrSubstNo(PrerequisiteLbl, ReferenceCode));
    end;
    Error(ContractErr);
  end;

  local procedure EnsureExternal(var Nodes: Record "BCSF Plan Node" temporary; var TempModules: Record "BCSF Scenario Module" temporary; Code: Code[30]; ModuleCode: Code[30]; Mode: Enum "BCSF Process Mode")
  begin
    if Nodes.Get(Code) then begin
      if not Nodes."External Check" then
        Error(ContractErr);
      exit;
    end;
    Nodes.Init();
    Nodes."Node Code" := Code;
    Nodes."Entity Code" := Code;
    Nodes."Module Code" := ModuleCode;
    Nodes."Process Mode" := Mode;
    Nodes."Work Units" := 1;
    Nodes."External Check" := true;
    Nodes.Issue := "BCSF Plan Issue"::ExternalPreflight;
    Nodes."Reference Code" := Code;
    if not IsModuleEnabled(TempModules, ModuleCode) then begin
      Nodes.Issue := "BCSF Plan Issue"::MissingModule;
      Nodes."Reference Code" := ModuleCode;
    end;
    Nodes.Insert();
  end;

  local procedure AddEntityRequirement(var Nodes: Record "BCSF Plan Node" temporary; var Edges: Record "BCSF Dependency" temporary; var TempModules: Record "BCSF Scenario Module" temporary; NodeCode: Code[30]; EntityCode: Code[30]; ModuleCode: Code[30])
  var
    TempReferences: Record "BCSF Plan Node" temporary;
    ReferenceCode: Code[30];
    Mode: Enum "BCSF Process Mode";
  begin
    TempReferences.Copy(Nodes, true);
    if TempReferences.Get(EntityCode) then
      AddEdge(Edges, NodeCode, EntityCode, "BCSF Dependency Kind"::Required)
    else begin
      // Reusing existing records needs evidence; never silently add a generation quantity or claim that records exist.
      if StrLen(EntityCode) + StrLen('.REFERENCE') > MaxStrLen(ReferenceCode) then
        Error(ContractErr);
      ReferenceCode := CopyStr(EntityCode + '.REFERENCE', 1, MaxStrLen(ReferenceCode));
      EnsureExternal(TempReferences, TempModules, ReferenceCode, ModuleCode, Mode);
      AddEdge(Edges, ReferenceCode, 'FINANCE.SETUP', "BCSF Dependency Kind"::External);
      AddEdge(Edges, NodeCode, ReferenceCode, "BCSF Dependency Kind"::External);
    end;
  end;

  local procedure ResolveGenerators(Context: JsonObject; var TempModules: Record "BCSF Scenario Module" temporary; var Nodes: Record "BCSF Plan Node" temporary; var Edges: Record "BCSF Dependency" temporary)
  var
    TempCurrent: Record "BCSF Plan Node" temporary;
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Contract: Codeunit "BCSF Contract JSON";
    Generator: Interface "BCSF Generator";
    Target: JsonObject;
    Findings: JsonArray;
    Requirements: JsonArray;
  begin
    TempCurrent.Copy(Nodes, true);
    TempCurrent.Reset();
    TempCurrent.SetRange("External Check", false);
    if TempCurrent.FindSet() then
      repeat
        Nodes.Get(TempCurrent."Node Code");
        if Registry.SelectForTarget(Nodes."Entity Code", Nodes."Process Mode", false, TempCapability) then begin
          if (TempCapability."Module Code" <> Nodes."Module Code") or
            (Contract.GetInteger(Context, 'batchSize') > TempCapability."Maximum Batch Size")
          then
            SetIssue(Nodes, "BCSF Plan Issue"::UnsupportedMode, Nodes."Entity Code")
          else begin
            Nodes."Generator Code" := TempCapability."Generator Code";
            Nodes."Generator Version" := TempCapability.Version;
            Nodes."Contract Version" := TempCapability."Contract Version";
            Clear(Target);
            Target.Add('entityCode', Nodes."Entity Code");
            Target.Add('moduleCode', Nodes."Module Code");
            Target.Add('quantity', Nodes."Work Units");
            Target.Add('processMode', Nodes."Process Mode".AsInteger());
            Contract.CheckTarget(Context, Target);
            Generator := Registry.Resolve(TempCapability."Generator Code", TempCapability."Entity Code", TempCapability);
            Clear(Findings);
            Clear(Requirements);
            Generator.CheckPrerequisites(Contract.Clone(Context), Contract.Clone(Target), Findings);
            if Findings.Count() <> 0 then
              SetIssue(Nodes, "BCSF Plan Issue"::Prerequisite, TempCapability."Generator Code");
            Generator.GetDependencies(Contract.Clone(Context), Contract.Clone(Target), Requirements);
            AddDeclaredDependencies(Target, Requirements, TempModules, Nodes, Edges);
          end;
        end else
          if Registry.HasRealEntity(Nodes."Entity Code") then
            SetIssue(Nodes, "BCSF Plan Issue"::UnsupportedMode, Nodes."Entity Code")
          else
            SetIssue(Nodes, "BCSF Plan Issue"::MissingGenerator, Nodes."Entity Code");
        Nodes.Modify();
      until TempCurrent.Next() = 0;
    Nodes.Reset();
  end;

  local procedure AddDeclaredDependencies(Target: JsonObject; Requirements: JsonArray; var TempModules: Record "BCSF Scenario Module" temporary; var Nodes: Record "BCSF Plan Node" temporary; var Edges: Record "BCSF Dependency" temporary)
  var
    TempExternalNodes: Record "BCSF Plan Node" temporary;
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Requirement: JsonObject;
    Kind: Enum "BCSF Dependency Kind";
    MinimumMode: Integer;
    MaximumMode: Integer;
    Mode: Integer;
    NodeCode: Code[30];
    PredecessorCode: Code[30];
  begin
    TempExternalNodes.Copy(Nodes, true);
    Mode := Contract.GetInteger(Target, 'processMode');
    NodeCode := Contract.GetCode(Target, 'entityCode');
    foreach Token in Requirements do begin
      Requirement := Token.AsObject();
      MinimumMode := Contract.GetInteger(Requirement, 'minimumMode');
      MaximumMode := Contract.GetInteger(Requirement, 'maximumMode');
      if (MinimumMode < 0) or (MaximumMode > 3) or (MaximumMode < MinimumMode) then
        Error(ContractErr);
      if (Mode >= MinimumMode) and (Mode <= MaximumMode) then begin
        PredecessorCode := Contract.GetCode(Requirement, 'entityCode');
        Kind := "BCSF Dependency Kind".FromInteger(Contract.GetInteger(Requirement, 'kind'));
        if not (Kind in ["BCSF Dependency Kind"::Required, "BCSF Dependency Kind"::Optional, "BCSF Dependency Kind"::External]) then
          Error(ContractErr);
        if Kind = "BCSF Dependency Kind"::External then
          EnsureExternal(TempExternalNodes, TempModules, PredecessorCode, Contract.GetCode(Requirement, 'moduleCode'), "BCSF Process Mode".FromInteger(Mode));
        AddEdge(Edges, NodeCode, PredecessorCode, Kind);
      end;
    end;
  end;

  local procedure SetIssue(var Node: Record "BCSF Plan Node" temporary; Issue: Enum "BCSF Plan Issue"; ReferenceCode: Code[30])
  begin
    if Node.Issue = "BCSF Plan Issue"::None then begin
      Node.Issue := Issue;
      Node."Reference Code" := ReferenceCode;
    end;
  end;

  var
    EmptyPlanErr: Label 'The captured run has no positive entity targets.';
    ContractErr: Label 'A generator dependency declaration or planning contract is invalid.';
    NoBlockerLbl: Label 'No structural blocker. Separate setup and execution authorization is still required.';
    MissingGeneratorLbl: Label 'No real generator is registered for %1. Contract probes are excluded.', Comment = '%1 = entity code';
    MissingModuleLbl: Label 'Select and enable required module %1 in a new scenario snapshot.', Comment = '%1 = module code';
    MissingDependencyLbl: Label 'Required planned entity %1 is missing. No quantities were added automatically.', Comment = '%1 = prerequisite code';
    UnsupportedModeLbl: Label 'The selected generator does not support the process mode or batch size for %1.', Comment = '%1 = entity code';
    CycleLbl: Label 'Node %1 is cyclic or depends on a cyclic prerequisite.', Comment = '%1 = node code';
    ExternalLbl: Label 'External prerequisite %1 has not been verified. No setup, reference or stock success is assumed.', Comment = '%1 = external prerequisite';
    TestOnlyLbl: Label 'Generator %1 is a read-only contract probe and cannot generate business data.', Comment = '%1 = generator code';
    PrerequisiteLbl: Label 'Generator %1 reported an unmet prerequisite.', Comment = '%1 = generator code';
}
