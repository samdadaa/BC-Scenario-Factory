namespace BCScenarioFactory.ModuleRegistry;

using BCScenarioFactory.Core;

codeunit 90181 "BCSF Contract Self Check"
{
  Access = Internal;

  procedure Check()
  var
    TempCatalog: Record "BCSF Generator Registry" temporary;
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Contract: Codeunit "BCSF Contract JSON";
    Generator: Interface "BCSF Generator";
    Context: JsonObject;
    Target: JsonObject;
    Batch: JsonObject;
    Result: JsonObject;
    Resumed: JsonObject;
    Token: JsonToken;
    Batches: JsonArray;
    Dependencies: JsonArray;
    Original: Text;
    AfterCall: Text;
    Count: Integer;
  begin
    Context.Add('schemaVersion', 1);
    Context.Add('runId', Format(CreateGuid(), 0, 4));
    Context.Add('companyName', CompanyName());
    Context.Add('dataLanguage', 1);
    Context.Add('nameCatalogVersion', 1);
    Context.Add('seed', 1);
    Context.Add('processMode', 0);
    Context.Add('batchSize', 3);
    Context.Add('maximumBatchSize', 1000);
    Context.Add('maximumRecordsPerEntity', 1000);
    Context.WriteTo(Original);
    Registry.LoadCatalog(TempCatalog);
    TempCatalog.SetRange("Contract Probe", true);
    if TempCatalog.FindSet() then
      repeat
        Clear(Target);
        Target.Add('entityCode', TempCatalog."Entity Code");
        Target.Add('moduleCode', TempCatalog."Module Code");
        Target.Add('quantity', 7);
        Target.Add('processMode', 0);
        Generator := Registry.Resolve(TempCatalog."Generator Code", TempCatalog."Entity Code", TempCapability);
        Generator.PlanBatches(Contract.Clone(Context), Contract.Clone(Target), 1, 2, Batches);
        if Batches.Count() <> 2 then
          Error(CheckErr);
        Batches.Get(0, Token);
        Batch := Token.AsObject();
        if (Contract.GetInteger(Batch, 'firstKey') <> 1) or (Contract.GetInteger(Batch, 'lastKey') <> 3) then
          Error(CheckErr);
        Registry.ExecuteContractProbe(TempCatalog."Generator Code", Context, Target, Batch, false, Result);
        Registry.ExecuteContractProbe(TempCatalog."Generator Code", Context, Target, Batch, true, Resumed);
        if (Contract.GetText(Result, 'generatorCode') <> TempCatalog."Generator Code") or
          (Contract.GetText(Result, 'batchKey') <> Contract.GetText(Resumed, 'batchKey')) or
          (Contract.GetInteger(Resumed, 'createdRecords') <> 0) or
          (Contract.GetInteger(Resumed, 'processedUnits') <> 3)
        then
          Error(CheckErr);
        Generator.PlanBatches(Contract.Clone(Context), Contract.Clone(Target), 7, 2, Batches);
        if Batches.Count() <> 1 then
          Error(CheckErr);
        Batches.Get(0, Token);
        if Contract.GetInteger(Token.AsObject(), 'lastKey') <> 7 then
          Error(CheckErr);
        Clear(Dependencies);
        Generator.GetDependencies(Contract.Clone(Context), Contract.Clone(Target), Dependencies);
        Count := Count + 1;
      until TempCatalog.Next() = 0;
    if Count < 2 then
      Error(CheckErr);
    Context.WriteTo(AfterCall);
    if Original <> AfterCall then
      Error(CheckErr);
  end;

  var
    CheckErr: Label 'The generator contract self-check failed. No business records were generated.';
}
