namespace BCScenarioFactory.ModuleRegistry;

using BCScenarioFactory.Core;

codeunit 90178 "BCSF Customer Probe" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  var
    Support: Codeunit "BCSF Probe Support";
  begin
    Support.Describe(Capabilities, 'PROBE.CUSTOMER', 'CUSTOMER', 'SALES', NameLbl);
  end;

  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray)
  begin
    Clear(Findings);
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  var
    Requirement: JsonObject;
  begin
    Clear(Dependencies);
    Requirement.Add('entityCode', 'VENDOR');
    Requirement.Add('kind', 0);
    Requirement.Add('minimumMode', 0);
    Requirement.Add('maximumMode', 3);
    Dependencies.Add(Requirement);
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Support: Codeunit "BCSF Probe Support";
  begin
    Support.Plan('PROBE.CUSTOMER', Context, Target, FirstKey, MaximumBatches, Batches);
  end;

  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Support: Codeunit "BCSF Probe Support";
  begin
    Support.Execute('PROBE.CUSTOMER', Context, Target, Batch, Result);
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Support: Codeunit "BCSF Probe Support";
  begin
    Support.Validate('PROBE.CUSTOMER', Context, Target, Batch, Result);
    Clear(Findings);
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Support: Codeunit "BCSF Probe Support";
  begin
    Support.Execute('PROBE.CUSTOMER', Context, Target, Batch, Result);
  end;

  var
    NameLbl: Label 'Customer Contract Probe';
}
