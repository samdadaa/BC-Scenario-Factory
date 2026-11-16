namespace BCScenarioFactory.Core;

codeunit 90111 "BCSF Contract JSON"
{
  Access = Internal;

  procedure GetText(Value: JsonObject; FieldName: Text): Text
  var
    Token: JsonToken;
  begin
    if not Value.Get(FieldName, Token) then
      Error(MissingKeyErr, FieldName);
    exit(Token.AsValue().AsText());
  end;

  procedure GetCode(Value: JsonObject; FieldName: Text): Code[30]
  var
    Result: Text;
  begin
    Result := GetText(Value, FieldName);
    if (Result = '') or (StrLen(Result) > 30) then
      Error(InvalidKeyErr, FieldName);
    exit(CopyStr(Result, 1, 30));
  end;

  procedure GetInteger(Value: JsonObject; FieldName: Text): Integer
  var
    Token: JsonToken;
  begin
    if not Value.Get(FieldName, Token) then
      Error(MissingKeyErr, FieldName);
    exit(Token.AsValue().AsInteger());
  end;

  procedure GetBoolean(Value: JsonObject; FieldName: Text): Boolean
  var
    Token: JsonToken;
  begin
    if not Value.Get(FieldName, Token) then
      Error(MissingKeyErr, FieldName);
    exit(Token.AsValue().AsBoolean());
  end;

  procedure Clone(Value: JsonObject): JsonObject
  var
    Result: JsonObject;
    Serialized: Text;
  begin
    Value.WriteTo(Serialized);
    Result.ReadFrom(Serialized);
    exit(Result);
  end;

  procedure CheckContext(Context: JsonObject)
  var
    RunId: Guid;
    LanguageId: Integer;
    Size: Integer;
  begin
    if GetInteger(Context, 'schemaVersion') <> 1 then
      Error(ContextErr);
    if not Evaluate(RunId, GetText(Context, 'runId')) then
      Error(ContextErr);
    if IsNullGuid(RunId) then
      Error(ContextErr);
    if GetText(Context, 'companyName') = '' then
      Error(ContextErr);
    LanguageId := GetInteger(Context, 'dataLanguage');
    if not (LanguageId in [1, 2]) then
      Error(ContextErr);
    GetInteger(Context, 'seed');
    if (GetInteger(Context, 'processMode') < 0) or (GetInteger(Context, 'processMode') > 3) or
      (GetInteger(Context, 'nameCatalogVersion') <> 1)
    then
      Error(ContextErr);
    Size := GetInteger(Context, 'batchSize');
    if (Size <= 0) or (Size > GetInteger(Context, 'maximumBatchSize')) or
      (GetInteger(Context, 'maximumRecordsPerEntity') <= 0)
    then
      Error(ContextErr);
  end;

  procedure CheckTarget(Context: JsonObject; Target: JsonObject)
  var
    Quantity: Integer;
    Mode: Integer;
  begin
    CheckContext(Context);
    GetCode(Target, 'entityCode');
    GetCode(Target, 'moduleCode');
    Quantity := GetInteger(Target, 'quantity');
    if (Quantity <= 0) or (Quantity > GetInteger(Context, 'maximumRecordsPerEntity')) then
      Error(ContextErr);
    Mode := GetInteger(Target, 'processMode');
    if (Mode < 0) or (Mode > 3) or (Mode > GetInteger(Context, 'processMode')) then
      Error(ContextErr);
  end;

  procedure CheckBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject)
  var
    FirstKey: Integer;
    LastKey: Integer;
  begin
    CheckTarget(Context, Target);
    if GetText(Batch, 'batchKey') = '' then
      Error(ContextErr);
    FirstKey := GetInteger(Batch, 'firstKey');
    LastKey := GetInteger(Batch, 'lastKey');
    if (FirstKey <= 0) or (LastKey < FirstKey) or (LastKey > GetInteger(Target, 'quantity')) then
      Error(ContextErr);
    if LastKey - FirstKey + 1 > GetInteger(Context, 'batchSize') then
      Error(ContextErr);
  end;

  var
    MissingKeyErr: Label 'The generator contract is missing field %1.', Comment = '%1 = contract field name';
    InvalidKeyErr: Label 'Contract identifier %1 must contain between 1 and 30 characters.', Comment = '%1 = contract field name';
    ContextErr: Label 'The generator context, target or batch is invalid. Use the captured run configuration and valid logical ranges.';
}
