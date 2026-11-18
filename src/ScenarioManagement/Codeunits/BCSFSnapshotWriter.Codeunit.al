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
    SyntheticRules: JsonObject;
    Targets: JsonArray;
    Modules: JsonArray;
    Item: JsonObject;
    Output: OutStream;
    PayloadText: Text;
    Unposted: Integer;
    Posted: Integer;
    Partial: Integer;
    HasPositiveTarget: Boolean;
    FinanceYear: Integer;
    FinanceVersion: Code[20];
  begin
    // All persistent child writes lock this same parent before changing a target or module.
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
    Scenario.TestField(Archived, false);
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
    OnCaptureFinancePackage(Scenario."Finance Mode", FinanceYear, FinanceVersion);
    if (Scenario."Finance Mode" <> "BCSF Finance Mode"::Existing) and ((FinanceYear <= 0) or (FinanceVersion = '')) then
      Error(FinancePackageErr);
    Payload.Add('financeMode', Scenario."Finance Mode".AsInteger());
    Payload.Add('financeYear', FinanceYear);
    Payload.Add('financeVersion', FinanceVersion);
    Payload.Add('partnerSetup', CapturePartners(Scenario));
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
    OnBuildSyntheticRules(SyntheticRules);
    Payload.Add('seedEngineVersion', 1);
    Payload.Add('syntheticRules', SyntheticRules);
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

  local procedure CapturePartners(Scenario: Record "BCSF Scenario"): JsonObject
  var
    Settings: JsonObject;
  begin
    Settings.Add('version', 2);
    Settings.Add('countryCode', Scenario."Partner Country Code");
    Settings.Add('customerPostingGroup', Scenario."Customer Posting Group");
    Settings.Add('vendorPostingGroup', Scenario."Vendor Posting Group");
    Settings.Add('genBusPostingGroup', Scenario."Gen. Bus. Posting Group");
    Settings.Add('vatBusPostingGroup', Scenario."VAT Bus. Posting Group");
    Settings.Add('cashTerms', Scenario."Cash Terms Code");
    Settings.Add('smallTerms', Scenario."Small Terms Code");
    Settings.Add('mediumTerms', Scenario."Medium Terms Code");
    Settings.Add('largeTerms', Scenario."Large Terms Code");
    Settings.Add('b2cPercent', Scenario."B2C Percent");
    Settings.Add('smallCreditLimit', Scenario."Small Credit Limit");
    Settings.Add('mediumCreditLimit', Scenario."Medium Credit Limit");
    Settings.Add('largeCreditLimit', Scenario."Large Credit Limit");
    Settings.Add('b2cCreditLimit', Scenario."B2C Credit Limit");
    Settings.Add('currencyCode', Scenario."Partner Currency Code");
    Settings.Add('paymentMethod', Scenario."Partner Payment Method");
    Settings.Add('dimension1', Scenario."Partner Dimension 1");
    Settings.Add('dimension2', Scenario."Partner Dimension 2");
    Settings.Add('paymentReady', false);
    OnCapturePartnerSetup(Scenario."Finance Mode", Settings);
    exit(Settings);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnCapturePartnerSetup(Mode: Enum "BCSF Finance Mode"; var Settings: JsonObject)
  begin
  end;

  [IntegrationEvent(false, false)]
  local procedure OnBuildSyntheticRules(var Rules: JsonObject)
  begin
  end;

  [IntegrationEvent(false, false)]
  local procedure OnCaptureFinancePackage(Mode: Enum "BCSF Finance Mode"; var Year: Integer; var PackageVersion: Code[20])
  begin
  end;

  var
    FinancePackageErr: Label 'The selected finance package could not be captured. Review the applied package before creating a run.';
    EmptyPlanErr: Label 'Enter at least one positive entity target before capturing a run.';
}
