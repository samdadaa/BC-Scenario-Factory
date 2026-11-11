namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using System.Environment;

codeunit 90144 "BCSF Snapshot Writer"
{
  Access = Internal;
  // Only this fixed writer receives indirect insert rights; the user cannot supply a payload or alter a captured run.
  Permissions = tabledata "BCSF Run Header" = I, tabledata "BCSF Run Snapshot" = I;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateSnapshot(ScenarioId: Guid): Guid
  var
    Scenario: Record "BCSF Scenario";
    Header: Record "BCSF Run Header";
    Snapshot: Record "BCSF Run Snapshot";
    Target: Record "BCSF Data Target";
    ScenarioModule: Record "BCSF Scenario Module";
    FactorySetup: Record "BCSF Factory Setup";
    SetupManagement: Codeunit "BCSF Setup Management";
    Policy: Codeunit "BCSF Scenario Policy";
    Languages: Codeunit "BCSF Language Mgt";
    EnvironmentInformation: Codeunit "Environment Information";
    Payload: JsonObject;
    Targets: JsonArray;
    Modules: JsonArray;
    Item: JsonObject;
    Output: OutStream;
    PayloadText: Text;
    Unposted: Integer;
    Posted: Integer;
    Partial: Integer;
    HasPositiveTarget: Boolean;
  begin
    // All persistent child writes lock this same parent before changing a target or module.
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
    FactorySetup.LockTable();
    SetupManagement.GetSetup(FactorySetup);
    Policy.ValidateScenario(Scenario);
    Scenario.TestField("Profile Code");
    Scenario.TestField("Profile Version");
    Header.Init();
    Header."Run Id" := CreateGuid();
    Header."Scenario Id" := ScenarioId;
    Header."Scenario Revision" := Scenario.Revision;
    Header.Description := Scenario.Description;
    Header.Status := "BCSF Run Status"::Draft;
    Header."Data Language" := Languages.ResolveDataLanguage(Scenario."Data Language");
    Header.Seed := Scenario.Seed;
    Header."Process Mode" := Scenario."Process Mode";
    Header."Usage Mode" := Scenario."Usage Mode";
    Header."Starting Date" := Scenario."Starting Date";
    Header."Ending Date" := Scenario."Ending Date";
    Header."Batch Size" := Scenario."Batch Size";
    Header."Created At" := CurrentDateTime();
    Header."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Header."Company Name"));
    Header."Environment Name" := CopyStr(EnvironmentInformation.GetEnvironmentName(), 1, MaxStrLen(Header."Environment Name"));
    Header."Profile Code" := Scenario."Profile Code";
    Header."Profile Version" := Scenario."Profile Version";
    Payload.Add('schemaVersion', 1);
    Payload.Add('runId', Format(Header."Run Id", 0, 4));
    Payload.Add('scenarioId', Format(ScenarioId, 0, 4));
    Payload.Add('revision', Scenario.Revision);
    Payload.Add('description', Scenario.Description);
    Payload.Add('profileCode', Scenario."Profile Code");
    Payload.Add('profileVersion', Scenario."Profile Version");
    Payload.Add('usageMode', Scenario."Usage Mode".AsInteger());
    Payload.Add('processMode', Scenario."Process Mode".AsInteger());
    Payload.Add('seed', Scenario.Seed);
    Payload.Add('startingDate', Format(Scenario."Starting Date", 0, 9));
    Payload.Add('endingDate', Format(Scenario."Ending Date", 0, 9));
    Payload.Add('batchSize', Scenario."Batch Size");
    Payload.Add('requestedDataLanguage', Scenario."Data Language".AsInteger());
    Payload.Add('dataLanguage', Header."Data Language".AsInteger());
    Payload.Add('nameCatalogVersion', Languages.GetCatalogVersion());
    Payload.Add('maximumBatchSize', FactorySetup."Maximum Batch Size");
    Payload.Add('maximumRecordsPerEntity', FactorySetup."Maximum Records per Entity");
    Payload.Add('companyName', Header."Company Name");
    Payload.Add('environmentName', Header."Environment Name");
    Payload.Add('capturedAt', Format(Header."Created At", 0, 9));
    ScenarioModule.SetRange("Scenario Id", ScenarioId);
    if ScenarioModule.FindSet() then
      repeat
        Policy.ValidateModule(ScenarioModule);
        Clear(Item);
        Item.Add('module', ScenarioModule.Module.AsInteger());
        Item.Add('enabled', ScenarioModule.Enabled);
        Modules.Add(Item);
      until ScenarioModule.Next() = 0;
    Target.SetRange("Scenario Id", ScenarioId);
    if Target.FindSet() then
      repeat
        Policy.ValidateTarget(Target);
        HasPositiveTarget := HasPositiveTarget or (Target.Quantity > 0);
        Clear(Item);
        Item.Add('entity', Target.Entity.AsInteger());
        Item.Add('module', Target.Module.AsInteger());
        Item.Add('quantity', Target.Quantity);
        Item.Add('processMode', Target."Process Mode".AsInteger());
        Item.Add('unpostedPercent', Target."Unposted Percent");
        Item.Add('postedPercent', Target."Posted Percent");
        Item.Add('partialPercent', Target."Partial Percent");
        Policy.GetDistribution(Target, Unposted, Posted, Partial);
        Item.Add('estimatedUnposted', Unposted);
        Item.Add('estimatedPosted', Posted);
        Item.Add('estimatedPartial', Partial);
        Targets.Add(Item);
      until Target.Next() = 0;
    if not HasPositiveTarget then
      Error(EmptyPlanErr);
    Payload.Add('modules', Modules);
    Payload.Add('targets', Targets);
    // Header and payload are inserted in the same transaction. No status update or queue start is performed.
    Header.Insert(true);
    Snapshot.Init();
    Snapshot."Run Id" := Header."Run Id";
    Snapshot."Schema Version" := 1;
    Snapshot.Payload.CreateOutStream(Output, TextEncoding::UTF8);
    Payload.WriteTo(PayloadText);
    Output.WriteText(PayloadText);
    Clear(Output);
    Snapshot.Insert(true);
    exit(Header."Run Id");
  end;

  var
    EmptyPlanErr: Label 'Enter at least one positive entity target before capturing a run.';
}
