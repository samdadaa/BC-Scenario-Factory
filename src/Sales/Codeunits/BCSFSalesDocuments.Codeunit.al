namespace BCScenarioFactory.Sales;

using BCScenarioFactory.Planning;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.ProcessEngine;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

codeunit 90430 "BCSF Sales Documents"
{
  Access = Internal;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Create(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer; RunId: Guid; BatchId: Guid)
  var
    Header: Record "Sales Header";
    Line: Record "Sales Line";
    Customer: Record Customer;
    Item: Record Item;
    Shipment: Record "Sales Shipment Header";
    Invoice: Record "Sales Invoice Header";
    Credit: Record "Sales Cr.Memo Header";
    Receipt: Record "Return Receipt Header";
    Entry: Record "Item Ledger Entry";
    Foundation: Codeunit "BCSF Demo Partner Setup";
    Setup: Codeunit "BCSF Sales Setup";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Contract: Codeunit "BCSF Contract JSON";
    Registry: Codeunit "BCSF Record Registry";
    Evidence: Codeunit "BCSF Sales Evidence";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    PlanningProcessor: Codeunit "BCSF Planning Processor";
    Selection: Codeunit "BCSF Module Selection";
    SalesPost: Codeunit "Sales-Post";
    QuoteToOrder: Codeunit "Sales-Quote to Order";
    ParentId: Guid;
    NoParent: Guid;
    HeaderId: Guid;
    Mode: Integer;
    Date: Date;
    Quantity: Decimal;
    PostingQuantity: Decimal;
    LineIndex: Integer;
    LineCount: Integer;
    CheckIndex: Integer;
    RequiredStock: Decimal;
    SkipReason: Code[30];
    StockItems: array[10] of Code[20];
    StockQuantities: array[10] of Decimal;
  begin
    Mode := Coordinator.Disposition(Context, EntityCode, LogicalKey);
    Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
    PostingQuantity := Quantity;
    if Mode = 2 then
      PostingQuantity := Quantity / 2;
    Date := Coordinator.DocumentDate(Context, EntityCode, LogicalKey);
    Setup.CustomerFor(Context, LogicalKey, Customer);
    Setup.CheckCustomer(Customer);
    if Mode > 0 then
      Foundation.CheckInvoiceRounding(true, Customer."Customer Posting Group");
    // Reused customer data can contain articles with no stock. Do not
    // abort the whole sales run during setup; leave that document unposted.
    if Mode > 0 then
      Entry.LockTable();
    if (Mode > 0) and Context.Contains('masterDataSource') then
      for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, LogicalKey) do begin
        if Coordinator.IsWholesaleQualityProfile(Context) then begin
          Setup.ItemFor(Context, Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex), Item);
          Quantity := Coordinator.WholesaleSalesLineQuantity(Context, EntityCode, LogicalKey, LineIndex);
        end else begin
          Setup.ItemFor(Context, LogicalKey, Item);
          Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
        end;
        if Mode = 2 then
          Quantity := Quantity / 2;
        RequiredStock := Quantity;
        // Sum demand of repeated items within this same document; inventory
        // has not yet been reduced by its earlier unposted lines.
        for CheckIndex := 1 to LineIndex - 1 do
          if StockItems[CheckIndex] = Item."No." then
            RequiredStock += StockQuantities[CheckIndex];
        StockItems[LineIndex] := Item."No.";
        StockQuantities[LineIndex] := Quantity;
        if not Setup.HasStock(Context, Item, RequiredStock, Date) then
          SkipReason := 'STOCK';
      end;
    if SkipReason <> '' then
      Mode := 0;
    if Mode > 0 then
      // Serialize this app's stock-consuming batches, then check each generated position.
      Entry.LockTable();
    Header.Init();
    Header.SetHideValidationDialog(true);
    case EntityCode of
      'SALES.QUOTE': Header."Document Type" := Header."Document Type"::Quote;
      'SALES.ORDER': Header."Document Type" := Header."Document Type"::Quote;
      'SALES.INVOICE': Header."Document Type" := Header."Document Type"::Invoice;
    end;
    Header."Posting Date" := Date;
    Header.Insert(true);
    Header.Validate("Sell-to Customer No.", Customer."No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Order Date", Date);
    Header.Validate("Shipment Date", Date);
    ApplyShipTo(Context, Header, Customer);
    Header.Validate("Location Code", CopyStr(Contract.GetText(Setup.ReadSettings(Context), 'location'), 1, MaxStrLen(Header."Location Code")));
    Header.Validate("Shipment Date", Date);
    Header.Modify(true);
    HeaderId := Header.SystemId;
    LineCount := Coordinator.WholesaleLineCount(Context, EntityCode, LogicalKey);
    for LineIndex := 1 to LineCount do begin
      if Coordinator.IsWholesaleQualityProfile(Context) then begin
        Setup.ItemFor(Context, Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex), Item);
        Quantity := Coordinator.WholesaleSalesLineQuantity(Context, EntityCode, LogicalKey, LineIndex);
      end else begin
        Setup.ItemFor(Context, LogicalKey, Item);
        Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
      end;
      PostingQuantity := Quantity;
      if Mode = 2 then
        PostingQuantity := Quantity / 2;
      Setup.CheckItem(Item);
      if Mode > 0 then
        Setup.CheckStock(Context, Item, PostingQuantity, Date);
      Line.Init();
      Line.SetHideValidationDialog(true);
      Line.Validate("Document Type", Header."Document Type");
      Line.Validate("Document No.", Header."No.");
      Line.Validate("Line No.", LineIndex * 10000);
      Line.Insert(true);
      Line.Validate(Type, Line.Type::Item);
      Line.Validate("No.", Item."No.");
      Line.Validate("Location Code", Header."Location Code");
      Line.Validate("Unit of Measure Code", Item."Base Unit of Measure");
      Line.Validate(Quantity, Quantity);
      if (Line."Unit Price" <= 0) or (Line."Line Amount" <= 0) then
        Error(PriceErr);
      CheckDimensions(Header, Line, Customer, Item);
      Line.Modify(true);
    end;
    if EntityCode = 'SALES.ORDER' then begin
      // Fresh quotes have no linked opportunity; the standard converter preserves
      // the quote number and transfers prices, dimensions and source line data.
      QuoteToOrder.Run(Header);
      QuoteToOrder.GetSalesOrderHeader(Header);
      Header.TestField("Document Type", Header."Document Type"::Order);
      Header.TestField("Quote No.");
      Header.Validate("Posting Date", Date);
      Header.Validate("Document Date", Date);
      Header.Validate("Order Date", Date);
      Header.Modify(true);
      HeaderId := Header.SystemId;
      for LineIndex := 1 to LineCount do begin
        Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
        if Coordinator.IsWholesaleQualityProfile(Context) then
          Setup.ItemFor(Context, Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex), Item)
        else
          Setup.ItemFor(Context, LogicalKey, Item);
        CheckDimensions(Header, Line, Customer, Item);
      end;
    end;
    if Mode = 0 then begin
      ParentId := Registry.RegisterResult(RunId, EntityCode, LogicalKey, 'DOCUMENT', BatchId, Header.RecordId(), NoParent, SkipReason);
      exit;
    end;
    for LineIndex := 1 to LineCount do begin
      Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
      PostingQuantity := Line.Quantity;
      if Mode = 2 then
        PostingQuantity := Line.Quantity / 2;
      if Header."Document Type" = Header."Document Type"::Order then
        Line.Validate("Qty. to Ship", PostingQuantity);
      Line.Validate("Qty. to Invoice", PostingQuantity);
      Line.Modify(true);
    end;
    Header.Ship := Header."Document Type" = Header."Document Type"::Order;
    Header.Invoice := true;
    SalesPost.SetSuppressCommit(true);
    // The public OnRun calls internal RunWithCheck. No Boolean return: no implicit success commit.
    SalesPost.Run(Header);
    SalesPost.GetGlobaDocumentsHeaders(Shipment, Invoice, Credit, Receipt);
    Invoice.TestField("No.");
    Invoice.TestField("Bill-to Customer No.", Customer."No.");
    ParentId := Registry.RegisterResult(RunId, EntityCode, LogicalKey, 'INVOICE', BatchId, Invoice.RecordId(), NoParent);
    if Shipment."No." <> '' then
      Registry.RegisterResult(RunId, EntityCode, LogicalKey, 'SHIPMENT', BatchId, Shipment.RecordId(), ParentId);
    if Mode = 2 then begin
      Header.GetBySystemId(HeaderId);
      Registry.RegisterResult(RunId, EntityCode, LogicalKey, 'DOCUMENT', BatchId, Header.RecordId(), ParentId);
      for LineIndex := 1 to LineCount do begin
        Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
        Line.TestField("Outstanding Quantity", Line.Quantity / 2);
        Line.TestField("Quantity Shipped", Line.Quantity / 2);
        Line.TestField("Quantity Invoiced", Line.Quantity / 2);
      end;
    end;
    Evidence.RegisterPosting(Context, RunId, EntityCode, LogicalKey, BatchId, Invoice, Shipment, ParentId);
    if Payments.Enabled(Context) then begin
      Payments.Pay(Context, RunId, EntityCode, LogicalKey, BatchId, Invoice."Cust. Ledger Entry No.", true, ParentId);
      // Optional follow-up of the same stage: unposted or posted credit memo for this invoice.
      if Credits.Enabled(Context) then
        Credits.CreateForSalesInvoice(Context, RunId, EntityCode, LogicalKey, BatchId, Invoice, ParentId);
      // Optional planning proposals for the sold items (proposals only, no purchase is created).
      if PlanningProcessor.Enabled(Context) then
        PlanningProcessor.RunForSalesInvoice(Context, RunId, EntityCode, LogicalKey, BatchId, Invoice, ParentId);
      // Optional modules of the same stage (CRM, service), each only when selected in the setup.
      Selection.RunForSalesInvoice(Context, RunId, EntityCode, LogicalKey, BatchId, Invoice, ParentId);
    end;
  end;

  local procedure ApplyShipTo(Context: JsonObject; var Header: Record "Sales Header"; Customer: Record Customer)
  var
    Address: Record "Ship-to Address";
    Setup: Codeunit "BCSF Sales Setup";
    Values: JsonObject;
    Ids: JsonToken;
    Token: JsonToken;
    Id: Guid;
  begin
    Values := Setup.ReadSettings(Context);
    Values.Get('shipToIds', Ids);
    foreach Token in Ids.AsArray() do begin
      Evaluate(Id, Token.AsValue().AsText());
      Address.SecurityFiltering(SecurityFilter::Disallowed);
      Address.GetBySystemId(Id);
      if Address."Customer No." = Customer."No." then begin
        Header.Validate("Ship-to Code", Address.Code);
        exit;
      end;
    end;
  end;

  local procedure CheckDimensions(Header: Record "Sales Header"; Line: Record "Sales Line"; Customer: Record Customer; Item: Record Item)
  var
    Dimensions: Codeunit DimensionManagement;
    TableIds: array[10] of Integer;
    Nos: array[10] of Code[20];
  begin
    TableIds[1] := Database::Customer;
    Nos[1] := Customer."No.";
    TableIds[2] := Database::Item;
    Nos[2] := Item."No.";
    if not Dimensions.CheckDimIDComb(Header."Dimension Set ID") or
      not Dimensions.CheckDimIDComb(Line."Dimension Set ID") or
      not Dimensions.CheckDimValuePosting(TableIds, Nos, Line."Dimension Set ID") then
      Error(DimensionErr);
  end;

  var
    PriceErr: Label 'The standard sales price or line amount is not positive. Review source prices and customer price agreements.';
    DimensionErr: Label 'The standard sales dimensions are blocked or required dimensions are missing. Review customer and item defaults.';
}
