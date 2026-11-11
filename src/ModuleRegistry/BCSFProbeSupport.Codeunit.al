namespace BCScenarioFactory.ModuleRegistry;

using BCScenarioFactory.Core;

codeunit 90183 "BCSF Probe Support"
{
  Access = Internal;

  procedure Describe(var Capability: Record "BCSF Generator Registry" temporary; Code: Code[30]; Entity: Code[30]; Module: Code[30]; Name: Text[100])
  begin
    Capability.Init();
    Capability."Generator Code" := Code;
    Capability."Entity Code" := Entity;
    Capability."Module Code" := Module;
    Capability.Name := Name;
    Capability.Version := '1';
    Capability."Contract Version" := 1;
    Capability."Maximum Batch Size" := 1000;
    Capability."Contract Probe" := true;
    Capability.Insert();
  end;

  procedure Plan(Code: Code[30]; Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Batch: JsonObject;
    Quantity: Integer;
    BatchSize: Integer;
    LastKey: Integer;
  begin
    Contract.CheckTarget(Context, Target);
    Clear(Batches);
    if (FirstKey <= 0) or (MaximumBatches <= 0) or (MaximumBatches > 100) then
      Error(RangeErr);
    Quantity := Contract.GetInteger(Target, 'quantity');
    BatchSize := Contract.GetInteger(Context, 'batchSize');
    while (FirstKey <= Quantity) and (Batches.Count() < MaximumBatches) do begin
      LastKey := Quantity;
      if Quantity - FirstKey + 1 > BatchSize then
        LastKey := FirstKey + BatchSize - 1;
      Clear(Batch);
      Batch.Add('batchKey', Code + '/' + Format(FirstKey, 0, 9) + '-' + Format(LastKey, 0, 9));
      Batch.Add('firstKey', FirstKey);
      Batch.Add('lastKey', LastKey);
      Batches.Add(Batch);
      if LastKey = Quantity then
        exit;
      FirstKey := LastKey + 1;
    end;
  end;

  procedure Execute(Code: Code[30]; Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Contract.CheckBatch(Context, Target, Batch);
    Clear(Result);
    Result.Add('generatorCode', Code);
    Result.Add('runId', Contract.GetText(Context, 'runId'));
    Result.Add('batchKey', Contract.GetText(Batch, 'batchKey'));
    Result.Add('processedUnits', Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1);
    Result.Add('createdRecords', 0);
    Result.Add('dataLanguage', Contract.GetInteger(Context, 'dataLanguage'));
    Result.Add('completed', true);
    Result.Add('contractProbe', true);
  end;

  procedure Validate(Code: Code[30]; Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject)
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Contract.CheckBatch(Context, Target, Batch);
    if (Contract.GetCode(Result, 'generatorCode') <> Code) or
      (Contract.GetText(Result, 'runId') <> Contract.GetText(Context, 'runId')) or
      (Contract.GetText(Result, 'batchKey') <> Contract.GetText(Batch, 'batchKey')) or
      (Contract.GetInteger(Result, 'createdRecords') <> 0) or
      (Contract.GetInteger(Result, 'processedUnits') <> Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1) or
      (Contract.GetInteger(Result, 'dataLanguage') <> Contract.GetInteger(Context, 'dataLanguage')) or
      not Contract.GetBoolean(Result, 'completed') or not Contract.GetBoolean(Result, 'contractProbe')
    then
      Error(ResultErr);
  end;

  var
    RangeErr: Label 'Plan between 1 and 100 batches at a time using a positive first logical key.';
    ResultErr: Label 'The read-only contract probe returned an inconsistent result.';
}
