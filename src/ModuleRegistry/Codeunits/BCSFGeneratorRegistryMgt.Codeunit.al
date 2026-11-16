namespace BCScenarioFactory.ModuleRegistry;

using BCScenarioFactory.Core;

codeunit 90177 "BCSF Generator Registry Mgt"
{
  Access = Internal;

  procedure LoadCatalog(var TempCatalog: Record "BCSF Generator Registry" temporary)
  var
    TempDescription: Record "BCSF Generator Registry" temporary;
    TempExisting: Record "BCSF Generator Registry" temporary;
    Binding: Enum "BCSF Generator Type";
    Generator: Interface "BCSF Generator";
    Ordinal: Integer;
  begin
    TempCatalog.Reset();
    TempCatalog.DeleteAll();
    foreach Ordinal in Binding.Ordinals() do
      if Ordinal <> 0 then begin
        Binding := "BCSF Generator Type".FromInteger(Ordinal);
        Generator := Binding;
        TempDescription.Reset();
        TempDescription.DeleteAll();
        Generator.DescribeCapabilities(TempDescription);
        if TempDescription.IsEmpty() then
          Error(CapabilityErr);
        TempDescription.Reset();
        if TempDescription.FindSet() then
          repeat
            ValidateCapability(TempDescription);
            TempExisting.Copy(TempCatalog, true);
            TempExisting.SetRange("Generator Code", TempDescription."Generator Code");
            if TempExisting.FindFirst() then
              if TempExisting.Implementation <> Binding then
                Error(DuplicateErr, TempDescription."Generator Code");
            TempCatalog := TempDescription;
            TempCatalog.Implementation := Binding;
            if not TempCatalog.Insert() then
              Error(DuplicateErr, TempDescription."Generator Code");
          until TempDescription.Next() = 0;
      end;
    TempCatalog.Reset();
  end;

  procedure Resolve(Code: Code[30]; EntityCode: Code[30]; var TempCapability: Record "BCSF Generator Registry" temporary): Interface "BCSF Generator"
  var
    TempCatalog: Record "BCSF Generator Registry" temporary;
    Binding: Enum "BCSF Generator Type";
    Generator: Interface "BCSF Generator";
  begin
    LoadCatalog(TempCatalog);
    if not TempCatalog.Get(Code, EntityCode) then
      Error(UnavailableErr, Code);
    TempCapability := TempCatalog;
    Binding := TempCapability.Implementation;
    Generator := Binding;
    exit(Generator);
  end;

  procedure SelectForTarget(EntityCode: Code[30]; Mode: Enum "BCSF Process Mode"; AllowProbes: Boolean; var TempCapability: Record "BCSF Generator Registry" temporary): Boolean
  var
    TempCatalog: Record "BCSF Generator Registry" temporary;
    Found: Boolean;
  begin
    LoadCatalog(TempCatalog);
    TempCatalog.SetRange("Entity Code", EntityCode);
    if not AllowProbes then
      TempCatalog.SetRange("Contract Probe", false);
    if TempCatalog.FindSet() then
      repeat
        if SupportsMode(TempCatalog, Mode) then begin
          if Found then
            Error(AmbiguousErr, EntityCode);
          TempCapability := TempCatalog;
          Found := true;
        end;
      until TempCatalog.Next() = 0;
    exit(Found);
  end;

  procedure SupportsMode(TempCapability: Record "BCSF Generator Registry" temporary; Mode: Enum "BCSF Process Mode"): Boolean
  begin
    exit((Mode.AsInteger() >= TempCapability."Minimum Mode".AsInteger()) and
      (Mode.AsInteger() <= TempCapability."Maximum Mode".AsInteger()));
  end;

  procedure HasRealEntity(EntityCode: Code[30]): Boolean
  var
    TempCatalog: Record "BCSF Generator Registry" temporary;
  begin
    LoadCatalog(TempCatalog);
    TempCatalog.SetRange("Entity Code", EntityCode);
    TempCatalog.SetRange("Contract Probe", false);
    exit(not TempCatalog.IsEmpty());
  end;

  /// <summary>Only read-only contract probes may execute here. Real processing requires the later guarded worker and a valid saved plan.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure ExecuteContractProbe(Code: Code[30]; Context: JsonObject; Target: JsonObject; Batch: JsonObject; ResumeBatch: Boolean; var Result: JsonObject)
  var
    TempCapability: Record "BCSF Generator Registry" temporary;
    Contract: Codeunit "BCSF Contract JSON";
    Generator: Interface "BCSF Generator";
    Findings: JsonArray;
    ContextCopy: JsonObject;
    TargetCopy: JsonObject;
    BatchCopy: JsonObject;
  begin
    Contract.CheckBatch(Context, Target, Batch);
    Generator := Resolve(Code, Contract.GetCode(Target, 'entityCode'), TempCapability);
    if not TempCapability."Contract Probe" then
      Error(ProbeOnlyErr);
    if not SupportsMode(TempCapability, "BCSF Process Mode".FromInteger(Contract.GetInteger(Target, 'processMode'))) or
      (TempCapability."Module Code" <> Contract.GetCode(Target, 'moduleCode')) or
      (Contract.GetInteger(Context, 'batchSize') > TempCapability."Maximum Batch Size")
    then
      Error(CapabilityErr);
    OnBeforeContractProbe(Contract.GetText(Context, 'companyName'));
    ContextCopy := Contract.Clone(Context);
    TargetCopy := Contract.Clone(Target);
    BatchCopy := Contract.Clone(Batch);
    Generator.CheckPrerequisites(Contract.Clone(ContextCopy), Contract.Clone(TargetCopy), Findings);
    if Findings.Count() <> 0 then
      Error(PrerequisiteErr);
    if ResumeBatch then
      Generator.Resume(ContextCopy, TargetCopy, BatchCopy, Result)
    else
      Generator.ExecuteBatch(ContextCopy, TargetCopy, BatchCopy, Result);
    Generator.ValidateOutput(Contract.Clone(Context), Contract.Clone(Target), Contract.Clone(Batch), Contract.Clone(Result), Findings);
    if Findings.Count() <> 0 then
      Error(PrerequisiteErr);
  end;

  local procedure ValidateCapability(TempCapability: Record "BCSF Generator Registry" temporary)
  begin
    TempCapability.TestField("Generator Code");
    TempCapability.TestField("Entity Code");
    TempCapability.TestField("Module Code");
    TempCapability.TestField(Name);
    TempCapability.TestField(Version);
    if (TempCapability."Contract Version" <> 1) or (TempCapability."Maximum Batch Size" <= 0) or
      (TempCapability."Minimum Mode".AsInteger() < 0) or (TempCapability."Maximum Mode".AsInteger() > 3) or
      (TempCapability."Minimum Mode".AsInteger() > TempCapability."Maximum Mode".AsInteger())
    then
      Error(CapabilityErr);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnBeforeContractProbe(TargetCompanyName: Text)
  begin
  end;

  var
    CapabilityErr: Label 'A generator capability or its requested process scope is invalid.';
    DuplicateErr: Label 'Generator identity %1 is registered more than once or has conflicting implementations.', Comment = '%1 = generator code';
    UnavailableErr: Label 'Generator %1 is not available in the current compiled catalog.', Comment = '%1 = generator code';
    AmbiguousErr: Label 'More than one generator matches entity %1. Resolve the capability conflict before planning.', Comment = '%1 = entity code';
    ProbeOnlyErr: Label 'This entry point only executes read-only contract probes. Real generation requires a verified run plan and worker.';
    PrerequisiteErr: Label 'The generator prerequisite or result validation reported a blocker.';
}
