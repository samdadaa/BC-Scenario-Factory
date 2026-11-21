namespace BCScenarioFactory.ProcessEngine;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;

codeunit 90275 "BCSF Process Coordinator"
{
  Access = Internal;

  // 0 = unposted, 1 = fully invoiced, 2 = partially shipped and invoiced.
  procedure Disposition(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Integer
  var
    Policy: Codeunit "BCSF Scenario Policy";
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    Posted: Integer;
    Partial: Integer;
    TargetQuantity: Integer;
  begin
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do begin
      Target := Token.AsObject();
      if Policy.GetEntityCode("BCSF Entity Type".FromInteger(Contract.GetInteger(Target, 'entity'))) = EntityCode then begin
        TargetQuantity := Contract.GetInteger(Target, 'quantity');
        if (LogicalKey < 1) or (LogicalKey > TargetQuantity) then
          Error(ContractErr);
        Posted := Round(TargetQuantity * Contract.GetDecimal(Target, 'postedPercent') / 100, 1, '<');
        Partial := Round(TargetQuantity * Contract.GetDecimal(Target, 'partialPercent') / 100, 1, '<');
        if LogicalKey <= Posted then
          exit(1);
        if LogicalKey <= Posted + Partial then
          exit(2);
        exit(0);
      end;
    end;
    Error(ContractErr);
  end;

  procedure Quantity(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Decimal
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    // Even base quantities allow a true, non-zero half shipment.
    exit(2 * Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'SALES-QUANTITY', 1, 4));
  end;

  procedure PurchaseDate(Context: JsonObject; LogicalKey: Integer): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    StartingDate: Date;
  begin
    if Disposition(Context, 'PURCHASE.ORDER', LogicalKey) > 0 then begin
      Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
      if Contract.GetDatePolicyVersion(Context) = 1 then
        exit(Seed.SampleDate(Context, 'PURCHASE.ORDER', Format(LogicalKey, 0, 9), 'PURCHASE-DATE', StartingDate, EarliestSaleDate(Context, LogicalKey), false));
      exit(StartingDate);
    end;
    exit(DocumentDate(Context, 'PURCHASE.ORDER', LogicalKey));
  end;

  local procedure EarliestSaleDate(Context: JsonObject; PurchaseKey: Integer): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Policy: Codeunit "BCSF Scenario Policy";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    ItemCount: Integer;
    SourceCount: Integer;
    ItemKey: Integer;
    SalesKey: Integer;
    EntityCode: Code[30];
    LatestDate: Date;
    SalesDate: Date;
  begin
    Evaluate(LatestDate, Contract.GetText(Context, 'endingDate'), 9);
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do
      if Contract.GetInteger(Token.AsObject(), 'entity') = "BCSF Entity Type"::Item.AsInteger() then
        ItemCount := Contract.GetInteger(Token.AsObject(), 'quantity');
    if ItemCount < 1 then
      Error(ContractErr);
    SourceCount := ItemCount;
    if SourceCount > 100 then
      SourceCount := 100;
    ItemKey := 1 + ((PurchaseKey - 1) mod ItemCount);
    if ItemKey > SourceCount then
      exit(LatestDate);
    foreach Token in Targets.AsArray() do begin
      Target := Token.AsObject();
      EntityCode := Policy.GetEntityCode("BCSF Entity Type".FromInteger(Contract.GetInteger(Target, 'entity')));
      if EntityCode in ['SALES.ORDER', 'SALES.INVOICE'] then begin
        SalesKey := ItemKey;
        while SalesKey <= Contract.GetInteger(Target, 'quantity') do begin
          if Disposition(Context, EntityCode, SalesKey) > 0 then begin
            SalesDate := DocumentDate(Context, EntityCode, SalesKey);
            if SalesDate < LatestDate then
              LatestDate := SalesDate;
          end;
          SalesKey += SourceCount;
        end;
      end;
    end;
    exit(LatestDate);
  end;

  procedure PurchaseQuantity(Context: JsonObject; LogicalKey: Integer): Decimal
  var
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    Entity: Integer;
    ItemCount: Integer;
    SourceCount: Integer;
    ItemKey: Integer;
    SalesKey: Integer;
    SalesCount: Integer;
    Mode: Integer;
    Demand: Decimal;
    BaseQuantity: Decimal;
    EntityCode: Code[30];
  begin
    BaseQuantity := Quantity(Context, 'PURCHASE.ORDER', LogicalKey);
    Mode := Disposition(Context, 'PURCHASE.ORDER', LogicalKey);
    if Mode = 0 then
      exit(BaseQuantity);
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do
      if Contract.GetInteger(Token.AsObject(), 'entity') = "BCSF Entity Type"::Item.AsInteger() then
        ItemCount := Contract.GetInteger(Token.AsObject(), 'quantity');
    if ItemCount < 1 then
      Error(ContractErr);
    SourceCount := ItemCount;
    if SourceCount > 100 then
      SourceCount := 100;
    ItemKey := 1 + ((LogicalKey - 1) mod ItemCount);
    if ItemKey <= SourceCount then
      foreach Token in Targets.AsArray() do begin
        Target := Token.AsObject();
        Entity := Contract.GetInteger(Target, 'entity');
        if Entity in ["BCSF Entity Type"::SalesOrder.AsInteger(), "BCSF Entity Type"::SalesInvoice.AsInteger()] then begin
          if Entity = "BCSF Entity Type"::SalesOrder.AsInteger() then
            EntityCode := 'SALES.ORDER'
          else
            EntityCode := 'SALES.INVOICE';
          SalesCount := Contract.GetInteger(Target, 'quantity');
          SalesKey := ItemKey;
          while SalesKey <= SalesCount do begin
            case Disposition(Context, EntityCode, SalesKey) of
              1: Demand += Quantity(Context, EntityCode, SalesKey);
              2: Demand += Quantity(Context, EntityCode, SalesKey) / 2;
            end;
            SalesKey += SourceCount;
          end;
        end;
      end;
    // Real standard receipts cover the planned same-run sales and leave a small deterministic reserve.
    if Mode = 2 then
      exit(2 * (Demand + BaseQuantity));
    exit(Demand + BaseQuantity);
  end;

  procedure DocumentDate(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    StartingDate: Date;
    EndingDate: Date;
  begin
    Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(StartingDate + Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'SALES-DATE', 0, EndingDate - StartingDate));
  end;

  var
    ContractErr: Label 'The captured sales quantity or distribution is inconsistent. Capture a new run.';
}
