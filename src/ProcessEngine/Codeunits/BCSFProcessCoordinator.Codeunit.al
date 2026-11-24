namespace BCScenarioFactory.ProcessEngine;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
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
        // A movement-only run may omit an optional document target, or ask
        // planning code about a key outside that target. In either case no
        // document is planned: never reuse the master-data pool quantity as
        // the number of movement documents.
        if (LogicalKey < 1) or (LogicalKey > TargetQuantity) then
          exit(0);
        Posted := Round(TargetQuantity * Contract.GetDecimal(Target, 'postedPercent') / 100, 1, '<');
        Partial := Round(TargetQuantity * Contract.GetDecimal(Target, 'partialPercent') / 100, 1, '<');
        // Keep the distribution within the actual current-run target,
        // including very small quantities and rounded percentages.
        if Posted > TargetQuantity then
          Posted := TargetQuantity;
        if Partial > TargetQuantity - Posted then
          Partial := TargetQuantity - Posted;
        if LogicalKey <= Posted then
          exit(1);
        if LogicalKey <= Posted + Partial then
          exit(2);
        exit(0);
      end;
    end;
    // The selected module can be absent in a movement-only run. That is a
    // zero-document target rather than a corrupt historical run.
    exit(0);
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
    EndingDate: Date;
    PurchaseCount: Integer;
    Span: Integer;
    Offset: Integer;
  begin
    if IsWholesaleV6(Context) then begin
      Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
      Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
      PurchaseCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::PurchaseOrder);
      if (PurchaseCount <= 1) or (StartingDate = EndingDate) then
        exit(StartingDate);
      // Spread receipts over the captured period; sales dates are clamped to
      // the actual supplying receipt for posted scenarios below.
      Span := EndingDate - StartingDate;
      Offset := Round(Span * (LogicalKey - 1) / (PurchaseCount - 1), 1, '<');
      exit(StartingDate + Offset);
    end;
    if IsWholesaleQualityProfile(Context) and (Disposition(Context, 'PURCHASE.ORDER', LogicalKey) > 0) then begin
      Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
      exit(StartingDate);
    end;
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
    ItemSetup: Codeunit "BCSF Item Setup";
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
    // Transaction-only runs have no Item target; the captured master pool
    // is the authoritative item count for these planning calculations.
    ItemCount := ItemSetup.Quantity(Context, "BCSF Entity Type"::Item);
    if ItemCount < 1 then
      Error(ContractErr);
    Context.Get('targets', Targets);
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
    ItemSetup: Codeunit "BCSF Item Setup";
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
    // Transaction-only runs have no Item target; the captured master pool
    // is the authoritative item count for these planning calculations.
    ItemCount := ItemSetup.Quantity(Context, "BCSF Entity Type"::Item);
    if ItemCount < 1 then
      Error(ContractErr);
    Context.Get('targets', Targets);
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
    SaleDate: Date;
    ReceiptDate: Date;
    LineIndex: Integer;
    PurchaseKey: Integer;
  begin
    Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    SaleDate := StartingDate + Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'SALES-DATE', 0, EndingDate - StartingDate);
    if IsWholesaleV6(Context) and (WholesalePostedPurchaseCount(Context) > 0) and
      (EntityCode in ['SALES.ORDER', 'SALES.INVOICE']) and
      (Disposition(Context, EntityCode, LogicalKey) > 0) then
      for LineIndex := 1 to WholesaleLineCount(Context, EntityCode, LogicalKey) do begin
        PurchaseKey := WholesaleSalesPurchaseKey(Context, LogicalKey, LineIndex);
        ReceiptDate := PurchaseDate(Context, PurchaseKey);
        if ReceiptDate > SaleDate then
          SaleDate := ReceiptDate;
      end;
    exit(SaleDate);
  end;

  procedure IsWholesaleV6(Context: JsonObject): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    exit((Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') = '6'));
  end;

  procedure IsWholesaleQualityProfile(Context: JsonObject): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    exit((Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') in ['5', '6']));
  end;

  procedure WholesaleLineCount(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Integer
  begin
    if not IsWholesaleQualityProfile(Context) then
      exit(1);
    if EntityCode = 'PURCHASE.ORDER' then
      exit(2 + ((LogicalKey - 1) mod 3));
    // Blanket orders always carry at least three lines (three to five).
    if EntityCode = 'SALES.BLANKET' then
      exit(3 + ((LogicalKey - 1) mod 3));
    exit(2 + ((LogicalKey - 1) mod 4));
  end;

  local procedure WholesaleTargetQuantity(Context: JsonObject; Entity: Enum "BCSF Entity Type"): Integer
  var
    Setup: Codeunit "BCSF Item Setup";
  begin
    exit(Setup.Quantity(Context, Entity));
  end;

  local procedure WholesalePostedPurchaseCount(Context: JsonObject): Integer
  var
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    Count: Integer;
  begin
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do begin
      Target := Token.AsObject();
      if Contract.GetInteger(Target, 'entity') = "BCSF Entity Type"::PurchaseOrder.AsInteger() then begin
        Count := Contract.GetInteger(Target, 'quantity');
        exit(Round(Count * Contract.GetDecimal(Target, 'postedPercent') / 100, 1, '<') +
          Round(Count * Contract.GetDecimal(Target, 'partialPercent') / 100, 1, '<'));
      end;
    end;
    exit(0);
  end;

  procedure WholesalePurchaseItemKey(Context: JsonObject; PurchaseKey: Integer; LineIndex: Integer): Integer
  var
    Source: Codeunit "BCSF Master Data Source";
    ItemCount: Integer;
    VendorCount: Integer;
  begin
    if Source.UsesSelectedPool(Context) then
      exit(Source.PurchaseItemKey(Context, PurchaseKey, LineIndex));
    ItemCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Item);
    VendorCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor);
    if (ItemCount < 1) or (VendorCount < 1) or (PurchaseKey < 1) or (LineIndex < 1) then
      Error(ContractErr);
    // All positions on one order share a supplier. V6 visits the full item
    // assortment instead of resetting after the first supplier cycle.
    if IsWholesaleV6(Context) then
      exit(1 + (((PurchaseKey - 1) mod VendorCount) +
        (((PurchaseKey - 1) div VendorCount) * 3 + LineIndex - 1) * VendorCount) mod ItemCount);
    exit(1 + (((PurchaseKey - 1) mod VendorCount) + (LineIndex - 1) * VendorCount) mod ItemCount);
  end;

  procedure WholesaleSalesItemKey(Context: JsonObject; EntityCode: Code[30]; SalesKey: Integer; LineIndex: Integer): Integer
  var
    PurchaseKey: Integer;
    PurchaseLineIndex: Integer;
    PostedPurchases: Integer;
    ItemCount: Integer;
  begin
    ItemCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Item);
    if ItemCount < 1 then
      Error(ContractErr);
    // Unposted offers/orders may sample any article; only posted sales must
    // refer to supply guaranteed by this run's posted purchase orders.
    if IsWholesaleV6(Context) and (Disposition(Context, EntityCode, SalesKey) = 0) then
      exit(1 + ((SalesKey * 7 + LineIndex - 2) mod ItemCount));
    PostedPurchases := WholesalePostedPurchaseCount(Context);
    // V5 intentionally only used one cycle of suppliers; retain that rule
    // for immutable older snapshots. V6 uses all confirmed receipts.
    if not IsWholesaleV6(Context) and
      (PostedPurchases > WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor)) then
      PostedPurchases := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor);
    if PostedPurchases = 0 then begin
      if not IsWholesaleV6(Context) and
        (ItemCount > WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor) * 4) then
        ItemCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor) * 4;
      exit(1 + ((SalesKey * 7 + LineIndex - 2) mod ItemCount));
    end;
    // Different suppliers/assortments are selected without consulting run order.
    PurchaseKey := WholesaleSalesPurchaseKey(Context, SalesKey, LineIndex);
    PurchaseLineIndex := 1 + ((SalesKey + LineIndex - 2) mod WholesaleLineCount(Context, 'PURCHASE.ORDER', PurchaseKey));
    exit(WholesalePurchaseItemKey(Context, PurchaseKey, PurchaseLineIndex));
  end;

  local procedure WholesaleSalesPurchaseKey(Context: JsonObject; SalesKey: Integer; LineIndex: Integer): Integer
  var
    PostedPurchases: Integer;
  begin
    PostedPurchases := WholesalePostedPurchaseCount(Context);
    if not IsWholesaleV6(Context) and
      (PostedPurchases > WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor)) then
      PostedPurchases := WholesaleTargetQuantity(Context, "BCSF Entity Type"::Vendor);
    if PostedPurchases < 1 then
      Error(ContractErr);
    exit(1 + ((SalesKey * 7 + LineIndex - 2) mod PostedPurchases));
  end;

  procedure WholesaleSalesLineQuantity(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer; LineIndex: Integer): Decimal
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    exit(2 * Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9),
      'WHOLESALE.LINE.' + Format(LineIndex, 0, 9), 1, 6));
  end;

  procedure WholesalePurchaseLineQuantity(Context: JsonObject; PurchaseKey: Integer; LineIndex: Integer): Decimal
  var
    ItemKey: Integer;
    Demand: Decimal;
  begin
    ItemKey := WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex);
    Demand := WholesaleDemandForItem(Context, ItemKey, 1);
    // A partial purchase receipts half the ordered quantity. Both modes still
    // supply all planned sales plus a small safety stock.
    if Disposition(Context, 'PURCHASE.ORDER', PurchaseKey) = 2 then
      exit(2 * (Demand + 12));
    exit(Demand + 12);
  end;

  // FirstSalesKey is used by preflight to avoid counting already-posted demand.
  procedure WholesaleDemandForItem(Context: JsonObject; ItemKey: Integer; FirstSalesKey: Integer): Decimal
  var
    OrderCount: Integer;
    InvoiceCount: Integer;
    SalesKey: Integer;
    LineIndex: Integer;
    Mode: Integer;
    EntityCode: Code[30];
    TargetCount: Integer;
    Demand: Decimal;
  begin
    OrderCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::SalesOrder);
    InvoiceCount := WholesaleTargetQuantity(Context, "BCSF Entity Type"::SalesInvoice);
    for LineIndex := 1 to 2 do begin
      if LineIndex = 1 then begin
        EntityCode := 'SALES.ORDER';
        TargetCount := OrderCount;
      end else begin
        EntityCode := 'SALES.INVOICE';
        TargetCount := InvoiceCount;
      end;
      for SalesKey := FirstSalesKey to TargetCount do begin
        Mode := Disposition(Context, EntityCode, SalesKey);
        if Mode > 0 then
          Demand += WholesaleDemandFromDocument(Context, EntityCode, SalesKey, ItemKey, Mode);
      end;
    end;
    exit(Demand);
  end;

  procedure WholesaleRemainingDemand(Context: JsonObject; ItemKey: Integer): Decimal
  var
    Entry: Record "BCSF Generated Record";
    Contract: Codeunit "BCSF Contract JSON";
    RunId: Guid;
    EntityCode: Code[30];
    Entity: Enum "BCSF Entity Type";
    Node: Integer;
    SalesKey: Integer;
    FirstKey: Integer;
    Mode: Integer;
    Demand: Decimal;
  begin
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    for Node := 1 to 2 do begin
      if Node = 1 then begin
        Entity := Entity::SalesOrder;
        EntityCode := 'SALES.ORDER';
      end else begin
        Entity := Entity::SalesInvoice;
        EntityCode := 'SALES.INVOICE';
      end;
      Entry.Reset();
      Entry.SetRange("Run Id", RunId);
      Entry.SetRange("Node Code", EntityCode);
      FirstKey := 1;
      if Entry.FindLast() then
        FirstKey := Entry."Logical Key" + 1;
      for SalesKey := FirstKey to WholesaleTargetQuantity(Context, Entity) do begin
        Mode := Disposition(Context, EntityCode, SalesKey);
        if Mode > 0 then
          Demand += WholesaleDemandFromDocument(Context, EntityCode, SalesKey, ItemKey, Mode);
      end;
    end;
    exit(Demand);
  end;

  local procedure WholesaleDemandFromDocument(Context: JsonObject; EntityCode: Code[30]; SalesKey: Integer; ItemKey: Integer; Mode: Integer): Decimal
  var
    LineIndex: Integer;
    Demand: Decimal;
  begin
    for LineIndex := 1 to WholesaleLineCount(Context, EntityCode, SalesKey) do
      if WholesaleSalesItemKey(Context, EntityCode, SalesKey, LineIndex) = ItemKey then
        if Mode = 2 then
          Demand += WholesaleSalesLineQuantity(Context, EntityCode, SalesKey, LineIndex) / 2
        else
          Demand += WholesaleSalesLineQuantity(Context, EntityCode, SalesKey, LineIndex);
    exit(Demand);
  end;

  var
    ContractErr: Label 'The captured sales quantity or distribution is inconsistent. Capture a new run.';
}
