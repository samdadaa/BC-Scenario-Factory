namespace BCScenarioFactory.ModuleRegistry;

codeunit 90180 "BCSF Missing Generator" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  begin
    Error(UnavailableErr);
  end;

  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray)
  begin
    Error(UnavailableErr);
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  begin
    Error(UnavailableErr);
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  begin
    Error(UnavailableErr);
  end;

  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(UnavailableErr);
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  begin
    Error(UnavailableErr);
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(UnavailableErr);
  end;

  var
    UnavailableErr: Label 'This generator implementation is unavailable. Refresh the catalog and review the saved generator version.';
}
