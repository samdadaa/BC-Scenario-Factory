namespace BCScenarioFactory.ModuleRegistry;

interface "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary);
  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray);
  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray);
  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray);
  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject);
  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray);
  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject);
}
