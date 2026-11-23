namespace BCScenarioFactory.Purchasing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.Finance;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ProcessEngine;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Vendor;

codeunit 90451 "BCSF Purchase Generator" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  begin
    Capabilities.Init();
    Capabilities."Generator Code" := 'PURCHASE.DOCUMENT';
    Capabilities."Entity Code" := 'PURCHASE.ORDER';
    Capabilities."Module Code" := 'PURCHASING';
    Capabilities.Name := NameLbl;
    Capabilities.Version := '1';
    Capabilities."Contract Version" := 1;
    Capabilities."Minimum Mode" := "BCSF Process Mode"::UnpostedDocuments;
    Capabilities."Maximum Mode" := "BCSF Process Mode"::PostedMovements;
    Capabilities."Maximum Batch Size" := 100;
    Capabilities.Insert();
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCapturePurchaseSetup', '', false, false)]
  local procedure Capture(Scenario: Record "BCSF Scenario"; InventorySettings: JsonObject; var Settings: JsonObject)
  var
    Target: Record "BCSF Data Target";
    Purchases: Record "Purchases & Payables Setup";
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetRange(Entity, Target.Entity::PurchaseOrder);
    Target.SetFilter(Quantity, '>0');
    if Target.IsEmpty() then
      exit;
    if not InventorySettings.Contains('generatedVendors') then
      Error(SetupErr);
    if not Contract.GetBoolean(InventorySettings, 'generatedVendors') then
      Error(SetupErr);
    Purchases.Get();
    Settings.Add('version', 2);
    Settings.Add('postingApproved', Scenario."Purchase Posting Approved");
    Settings.Add('invoiceSeries', Purchases."Posted Invoice Nos.");
    Settings.Add('receiptSeries', Purchases."Posted Receipt Nos.");
    Settings.Add('orderSeries', Purchases."Order Nos.");
    Settings.Add('location', Contract.GetText(InventorySettings, 'location'));
  end;

  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray)
  var
    Finding: JsonObject;
  begin
    Clear(Findings);
    if not TryCheck(Context, Target) then begin
      Finding.Add('code', 'PURCHASE.SETUP');
      Finding.Add('message', GetLastErrorText());
      ClearLastError();
      Findings.Add(Finding);
    end;
  end;

  [TryFunction]
  local procedure TryCheck(Context: JsonObject; Target: JsonObject)
  begin
    Check(Context, Target);
  end;

  procedure Check(Context: JsonObject; Target: JsonObject)
  var
    Purchases: Record "Purchases & Payables Setup";
    Location: Record Location;
    Series: Record "No. Series";
    GL: Record "General Ledger Setup";
    Inventory: Record "Inventory Setup";
    ItemSetup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Numbers: Codeunit "No. Series";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    Guard: Codeunit "BCSF Environment Guard";
    Source: Codeunit "BCSF Master Data Source";
    Token: JsonToken;
    Settings: JsonObject;
    DateFrom: Date;
    DateTo: Date;
  begin
    Contract.CheckTarget(Context, Target);
    Source.Validate(Context);
    if (Contract.GetCode(Target, 'entityCode') <> 'PURCHASE.ORDER') or
      (Contract.GetCode(Target, 'moduleCode') <> 'PURCHASING') or
      not (Contract.GetInteger(Target, 'processMode') in [1, 2]) then
      Error(SetupErr);
    if not Context.Get('purchaseSetup', Token) then
      Error(SetupErr);
    Settings := Token.AsObject();
    if not (Contract.GetInteger(Settings, 'version') in [1, 2]) or
      (ItemSetup.Quantity(Context, "BCSF Entity Type"::Vendor) < 1) or
      (ItemSetup.Quantity(Context, "BCSF Entity Type"::Item) < 1) then
      Error(SetupErr);
    Purchases.Get();
    Purchases.TestField("Order Nos.", Contract.GetText(Settings, 'orderSeries'));
    Location.Get(Contract.GetText(Settings, 'location'));
    Location.TestField("Use As In-Transit", false);
    Location.TestField("Bin Mandatory", false);
    Location.TestField("Require Receive", false);
    Location.TestField("Require Put-away", false);
    Location.TestField("Directed Put-away and Pick", false);
    Series.Get(Purchases."Order Nos.");
    Series.TestField("Default Nos.", true);
    Series.TestField("Date Order", false);
    Evaluate(DateFrom, Contract.GetText(Context, 'startingDate'), 9);
    Evaluate(DateTo, Contract.GetText(Context, 'endingDate'), 9);
    if (Numbers.PeekNextNo(Series.Code, DateFrom) = '') or (Numbers.PeekNextNo(Series.Code, DateTo) = '') then
      Error(SetupErr);
    CheckPermission(Database::"Purchase Header");
    CheckPermission(Database::"Purchase Line");
    if Contract.GetInteger(Target, 'processMode') = 2 then begin
      Guard.EnsureCodeunitAccess(Codeunit::"Purch.-Post");
      Inventory.Get();
      Inventory.TestField("Automatic Cost Posting", true);
      if (Contract.GetInteger(Settings, 'version') <> 2) or not Contract.GetBoolean(Settings, 'postingApproved') then
        Error(ApprovalErr);
      Purchases.TestField("Posted Invoice Nos.", Contract.GetText(Settings, 'invoiceSeries'));
      Purchases.TestField("Posted Receipt Nos.", Contract.GetText(Settings, 'receiptSeries'));
      CheckSeries(Purchases."Posted Invoice Nos.", DateFrom, DateTo);
      CheckSeries(Purchases."Posted Receipt Nos.", DateFrom, DateTo);
      Guard.EnsurePostingTableAccess(Database::"Purch. Inv. Header", false);
      Guard.EnsurePostingTableAccess(Database::"Purch. Inv. Line", false);
      Guard.EnsurePostingTableAccess(Database::"Purch. Rcpt. Header", false);
      Guard.EnsurePostingTableAccess(Database::"Purch. Rcpt. Line", false);
      Guard.EnsurePostingTableAccess(Database::"Vendor Ledger Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Detailed Vendor Ledg. Entry", false);
      Guard.EnsurePostingTableAccess(Database::"G/L Entry", false);
      Guard.EnsurePostingTableAccess(Database::"VAT Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Item Ledger Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Value Entry", false);
      GL.Get();
      if ((GL."Allow Posting From" <> 0D) and (DateFrom < GL."Allow Posting From")) or
        ((GL."Allow Posting To" <> 0D) and (DateTo > GL."Allow Posting To")) then
        Error(SetupErr);
      if Payments.Enabled(Context) then begin
        Payments.Check(Context);
        if Credits.Enabled(Context) then begin
          Credits.CheckSetup(false);
          Guard.EnsurePostingTableAccess(Database::"Purch. Cr. Memo Hdr.", false);
        end;
      end;
    end;

  end;

  local procedure CheckSeries(Code: Code[20]; DateFrom: Date; DateTo: Date)
  var
    Series: Record "No. Series";
    Numbers: Codeunit "No. Series";
  begin
    Series.Get(Code);
    Series.TestField("Date Order", false);
    Series.TestField("Default Nos.", true);
    if (Numbers.PeekNextNo(Code, DateFrom) = '') or (Numbers.PeekNextNo(Code, DateTo) = '') then
      Error(SetupErr);
  end;

  local procedure CheckPermission(TableId: Integer)
  var
    Row: RecordRef;
  begin
    Row.Open(TableId);
    Row.SecurityFiltering(SecurityFilter::Disallowed);
    if not Row.ReadPermission() or not Row.WritePermission() then
      Error(PermissionErr, Row.Caption());
    Row.Close();
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Partner Rules", 'OnInspectDocument', '', false, false)]
  local procedure InspectDocument(Context: JsonObject; Target: JsonObject; LogicalKey: Integer; var Reason: Code[30])
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    if Contract.GetCode(Target, 'entityCode') <> 'PURCHASE.ORDER' then
      exit;
    Reason := 'SOURCE';
    if TryInspectDocument(Context, LogicalKey, Reason) then
      Clear(Reason)
    else
      ClearLastError();
  end;

  [TryFunction]
  local procedure TryInspectDocument(Context: JsonObject; LogicalKey: Integer; var Reason: Code[30])
  var
    Item: Record Item;
    Vendor: Record Vendor;
    Foundation: Codeunit "BCSF Demo Partner Setup";
    Source: Codeunit "BCSF Master Data Source";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    RunId: Guid;
    LineIndex: Integer;
    LocationCode: Code[10];
  begin
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Context.Get('purchaseSetup', Token);
    LocationCode := CopyStr(Contract.GetText(Token.AsObject(), 'location'), 1, 10);
    Sources(Context, RunId, LogicalKey, Item, Vendor);
    Reason := 'VENDOR';
    Vendor.TestField(Blocked, Vendor.Blocked::" ");
    if Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey) > 0 then
      Foundation.CheckInvoiceRounding(false, Vendor."Vendor Posting Group");
    for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', LogicalKey) do begin
      Reason := 'ITEM';
      if Coordinator.IsWholesaleQualityProfile(Context) then
        WholesaleLineItem(Context, RunId, LogicalKey, LineIndex, Vendor."No.", Item);
      Reason := 'DIMENSION';
      Source.CheckPurchaseCandidate(Vendor, Item, LocationCode);
    end;
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  var
    Requirement: JsonObject;
  begin
    Clear(Dependencies);
    if Context.Contains('masterDataSource') then
      exit;
    Requirement.Add('entityCode', 'VENDOR');
    Requirement.Add('moduleCode', 'PURCHASING');
    Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
    Requirement.Add('minimumMode', 1);
    Requirement.Add('maximumMode', 2);
    Dependencies.Add(Requirement);
    Clear(Requirement);
    Requirement.Add('entityCode', 'ITEM');
    Requirement.Add('moduleCode', 'INVENTORY');
    Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
    Requirement.Add('minimumMode', 1);
    Requirement.Add('maximumMode', 2);
    Dependencies.Add(Requirement);
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Rules: Codeunit "BCSF Partner Rules";
  begin
    Rules.Plan('PURCHASE.ORDER', Context, Target, FirstKey, MaximumBatches, Batches);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Entry: Record "BCSF Generated Record";
    Rules: Codeunit "BCSF Partner Rules";
    Contract: Codeunit "BCSF Contract JSON";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
  begin
    Rules.EnsureExecution(Context, Target, Batch, 'PURCHASE.DOCUMENT', RunId, BatchId);
    Check(Context, Target);
    Context.Add('executingBatch', Contract.Clone(Batch));
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'PURCHASE.ORDER');
    Entry.SetRange("Logical Key", Contract.GetInteger(Batch, 'firstKey'), Contract.GetInteger(Batch, 'lastKey'));
    if not Entry.IsEmpty() then
      Error(ResultErr);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      if Entry.Get(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT') then
        Error(ResultErr);
      CreateOrder(Context, RunId, BatchId, LogicalKey);
    end;
    Result.Add('generatorCode', 'PURCHASE.DOCUMENT');
    Result.Add('runId', Contract.GetText(Context, 'runId'));
    Result.Add('batchKey', Contract.GetText(Batch, 'batchKey'));
    Result.Add('processedUnits', Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1);
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    Result.Add('createdRecords', Entry.Count());
    Result.Add('dataLanguage', Contract.GetInteger(Context, 'dataLanguage'));
    Result.Add('completed', true);
    Result.Add('contractProbe', false);
  end;

  local procedure Sources(Context: JsonObject; RunId: Guid; LogicalKey: Integer; var Item: Record Item; var Vendor: Record Vendor)
  var
    Entry: Record "BCSF Generated Record";
    Registry: Codeunit "BCSF Record Registry";
    ItemSetup: Codeunit "BCSF Item Setup";
    Source: Codeunit "BCSF Master Data Source";
    Coordinator: Codeunit "BCSF Process Coordinator";
    ItemKey: Integer;
  begin
    RunId := Source.RunId(Context);
    // Follow each generated item's actual primary supplier, never an unrelated random vendor.
    if Coordinator.IsWholesaleQualityProfile(Context) then
      ItemKey := Coordinator.WholesalePurchaseItemKey(Context, LogicalKey, 1)
    else
      ItemKey := 1 + ((LogicalKey - 1) mod ItemSetup.Quantity(Context, "BCSF Entity Type"::Item));
    Entry.SecurityFiltering(SecurityFilter::Disallowed);
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    if Source.IsExistingPool(Context) then
      Source.ItemFromPool(Context, ItemKey, Item)
    else begin
      Entry.Get(RunId, 'ITEM', ItemKey, 'ITEM');
      Entry.TestField("Table Id", Database::Item);
      if not Registry.ExistsByIdentity(Entry) then
        Error(ResultErr);
      Item.GetBySystemId(Entry."Record SystemId");
    end;
    Vendor.SecurityFiltering(SecurityFilter::Disallowed);
    Vendor.Get(Item."Vendor No.");
    if Source.IsExistingPool(Context) then
      exit;
    Entry.Reset();
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'VENDOR');
    Entry.SetRange("Artifact Code", 'VENDOR');
    Entry.SetRange("Record SystemId", Vendor.SystemId);
    if not Entry.FindFirst() then
      Error(ResultErr);
    Entry.TestField("Table Id", Database::Vendor);
    if not Registry.ExistsByIdentity(Entry) then
      Error(ResultErr);
  end;

  local procedure WholesaleLineItem(Context: JsonObject; RunId: Guid; PurchaseKey: Integer; LineIndex: Integer; VendorNo: Code[20]; var Item: Record Item)
  var
    Entry: Record "BCSF Generated Record";
    Registry: Codeunit "BCSF Record Registry";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Source: Codeunit "BCSF Master Data Source";
  begin
    RunId := Source.RunId(Context);
    Entry.SecurityFiltering(SecurityFilter::Disallowed);
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    if Source.IsExistingPool(Context) then
      Source.ItemFromPool(Context, Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex), Item)
    else begin
      Entry.Get(RunId, 'ITEM', Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex), 'ITEM');
      Entry.TestField("Table Id", Database::Item);
      if not Registry.ExistsByIdentity(Entry) then
        Error(ResultErr);
      Item.GetBySystemId(Entry."Record SystemId");
    end;
    Item.TestField("Vendor No.", VendorNo);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure CreateOrder(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer)
  var
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    Vendor: Record Vendor;
    Item: Record Item;
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    ItemVendor: Record "Item Vendor";
    Invoice: Record "Purch. Inv. Header";
    Receipt: Record "Purch. Rcpt. Header";
    Foundation: Codeunit "BCSF Demo Partner Setup";
    Registry: Codeunit "BCSF Record Registry";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Contract: Codeunit "BCSF Contract JSON";
    Dimensions: Codeunit DimensionManagement;
    Evidence: Codeunit "BCSF Purchase Evidence";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    PurchasePost: Codeunit "Purch.-Post";
    Token: JsonToken;
    NoParent: Guid;
    ParentId: Guid;
    HeaderId: Guid;
    Mode: Integer;
    Quantity: Decimal;
    PostingQuantity: Decimal;
    Date: Date;
    LineIndex: Integer;
    LineCount: Integer;
    Tables: array[10] of Integer;
    Nos: array[10] of Code[20];
  begin
    Sources(Context, RunId, LogicalKey, Item, Vendor);
    Vendor.TestField(Blocked, Vendor.Blocked::" ");
    Vendor.TestField("Currency Code", '');
    Vendor.TestField("IC Partner Code", '');
    Vendor.TestField("Pay-to Vendor No.", '');
    Item.TestField(Blocked, false);
    Item.TestField("Purchasing Blocked", false);
    Item.TestField("Item Tracking Code", '');
    ItemVendor.Get(Vendor."No.", Item."No.", '');
    General.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
    General.TestField(Blocked, false);
    VAT.Get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
    VAT.TestField(Blocked, false);
    VAT.TestField("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
    Mode := Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey);
    if Mode > 0 then
      Foundation.CheckInvoiceRounding(false, Vendor."Vendor Posting Group");
    Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
    LineCount := Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', LogicalKey);
    Date := Coordinator.PurchaseDate(Context, LogicalKey);
    Header.Init();
    Header.SetHideValidationDialog(true);
    Header."Document Type" := Header."Document Type"::Order;
    Header."Posting Date" := Date;
    Header.Insert(true);
    Header.Validate("Buy-from Vendor No.", Vendor."No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Order Date", Date);
    Header.Validate("Expected Receipt Date", Date);
    Context.Get('purchaseSetup', Token);
    Header.Validate("Location Code", CopyStr(Contract.GetText(Token.AsObject(), 'location'), 1, 10));
    Header.Validate("Vendor Invoice No.", Header."No.");
    Header.Modify(true);
    HeaderId := Header.SystemId;
    for LineIndex := 1 to LineCount do begin
      if Coordinator.IsWholesaleQualityProfile(Context) then begin
        WholesaleLineItem(Context, RunId, LogicalKey, LineIndex, Vendor."No.", Item);
        Quantity := Coordinator.WholesalePurchaseLineQuantity(Context, LogicalKey, LineIndex);
      end else
        Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
      Item.TestField(Blocked, false);
      Item.TestField("Purchasing Blocked", false);
      Item.TestField("Item Tracking Code", '');
      ItemVendor.Get(Vendor."No.", Item."No.", '');
      General.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
      General.TestField(Blocked, false);
      VAT.Get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
      VAT.TestField(Blocked, false);
      Line.Init();
      Line.Validate("Document Type", Header."Document Type");
      Line.Validate("Document No.", Header."No.");
      Line.Validate("Line No.", LineIndex * 10000);
      Line.Insert(true);
      Line.Validate(Type, Line.Type::Item);
      Line.Validate("No.", Item."No.");
      Line.Validate("Location Code", Header."Location Code");
      Line.Validate("Unit of Measure Code", Item."Base Unit of Measure");
      Line.Validate(Quantity, Quantity);
      Line.Validate("Direct Unit Cost", Item."Unit Cost");
      if Line."Line Amount" <= 0 then
        Error(ResultErr);
      Tables[1] := Database::Vendor;
      Nos[1] := Vendor."No.";
      Tables[2] := Database::Item;
      Nos[2] := Item."No.";
      if not Dimensions.CheckDimIDComb(Header."Dimension Set ID") or
        not Dimensions.CheckDimIDComb(Line."Dimension Set ID") or
        not Dimensions.CheckDimValuePosting(Tables, Nos, Line."Dimension Set ID") then
        Error(ResultErr);
      Line.Modify(true);
    end;
    if Mode = 0 then begin
      Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT', BatchId, Header.RecordId(), NoParent);
      exit;
    end;
    for LineIndex := 1 to LineCount do begin
      Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
      PostingQuantity := Line.Quantity;
      if Mode = 2 then
        PostingQuantity := Line.Quantity / 2;
      Line.Validate("Qty. to Receive", PostingQuantity);
      Line.Validate("Qty. to Invoice", PostingQuantity);
      Line.Modify(true);
    end;
    Header.Receive := true;
    Header.Invoice := true;
    PurchasePost.SetSuppressCommit(true);
    PurchasePost.Run(Header);
    Invoice.Get(Header."Last Posting No.");
    Receipt.Get(Header."Last Receiving No.");
    Invoice.TestField("Buy-from Vendor No.", Vendor."No.");
    ParentId := Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'INVOICE', BatchId, Invoice.RecordId(), NoParent);
    Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'RECEIPT', BatchId, Receipt.RecordId(), ParentId);
    if Mode = 2 then begin
      Header.GetBySystemId(HeaderId);
      Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT', BatchId, Header.RecordId(), ParentId);
    end;
    Evidence.RegisterPosting(RunId, LogicalKey, BatchId, Invoice, Receipt, ParentId);
    if Payments.Enabled(Context) then begin
      Payments.Pay(Context, RunId, 'PURCHASE.ORDER', LogicalKey, BatchId, Invoice."Vendor Ledger Entry No.", false, ParentId);
      // Optional follow-up of the same stage: unposted or posted credit memo for this invoice.
      if Credits.Enabled(Context) then
        Credits.CreateForPurchaseInvoice(Context, RunId, 'PURCHASE.ORDER', LogicalKey, BatchId, Invoice, ParentId);
    end;
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    Invoice: Record "Purch. Inv. Header";
    InvoiceLine: Record "Purch. Inv. Line";
    Receipt: Record "Purch. Rcpt. Header";
    ReceiptLine: Record "Purch. Rcpt. Line";
    Item: Record Item;
    Vendor: Record Vendor;
    Contract: Codeunit "BCSF Contract JSON";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Registry: Codeunit "BCSF Record Registry";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    Mode: Integer;
    Count: Integer;
    LineIndex: Integer;
    Quantity: Decimal;
    PostedQuantity: Decimal;
    Token: JsonToken;
  begin
    Clear(Findings);
    Contract.CheckBatch(Context, Target, Batch);
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Evaluate(BatchId, Contract.GetText(Context, 'batchId'));
    Context.Get('purchaseSetup', Token);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      Mode := Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey);
      Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
      PostedQuantity := Quantity;
      if Mode = 2 then
        PostedQuantity := Quantity / 2;
      Sources(Context, RunId, LogicalKey, Item, Vendor);
      if Mode > 0 then begin
        Entry.Get(RunId, 'PURCHASE.ORDER', LogicalKey, 'INVOICE');
        Entry.TestField("Batch Id", BatchId);
        Invoice.GetBySystemId(Entry."Record SystemId");
        Invoice.TestField("Buy-from Vendor No.", Vendor."No.");
        Invoice.TestField("Posting Date", Coordinator.PurchaseDate(Context, LogicalKey));
        if Contract.GetDatePolicyVersion(Context) = 1 then
          Invoice.TestField("Document Date", Coordinator.PurchaseDate(Context, LogicalKey));
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', LogicalKey) do begin
          if Coordinator.IsWholesaleQualityProfile(Context) then begin
            WholesaleLineItem(Context, RunId, LogicalKey, LineIndex, Vendor."No.", Item);
            Quantity := Coordinator.WholesalePurchaseLineQuantity(Context, LogicalKey, LineIndex);
          end else
            Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
          PostedQuantity := Quantity;
          if Mode = 2 then
            PostedQuantity := Quantity / 2;
          InvoiceLine.Get(Invoice."No.", LineIndex * 10000);
          InvoiceLine.TestField(Type, InvoiceLine.Type::Item);
          InvoiceLine.TestField("No.", Item."No.");
          InvoiceLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
          InvoiceLine.TestField(Quantity, PostedQuantity);
        end;
        Entry.Get(RunId, 'PURCHASE.ORDER', LogicalKey, 'RECEIPT');
        Receipt.GetBySystemId(Entry."Record SystemId");
        if Contract.GetDatePolicyVersion(Context) = 1 then
          Receipt.TestField("Posting Date", Coordinator.PurchaseDate(Context, LogicalKey));
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', LogicalKey) do begin
          if Coordinator.IsWholesaleQualityProfile(Context) then begin
            WholesaleLineItem(Context, RunId, LogicalKey, LineIndex, Vendor."No.", Item);
            Quantity := Coordinator.WholesalePurchaseLineQuantity(Context, LogicalKey, LineIndex);
          end else
            Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
          PostedQuantity := Quantity;
          if Mode = 2 then
            PostedQuantity := Quantity / 2;
          ReceiptLine.Get(Receipt."No.", LineIndex * 10000);
          ReceiptLine.TestField("No.", Item."No.");
          ReceiptLine.TestField(Quantity, PostedQuantity);
        end;
        if Payments.Enabled(Context) then begin
          Payments.ValidatePayment(RunId, 'PURCHASE.ORDER', LogicalKey, Invoice."Vendor Ledger Entry No.", false);
          if Credits.Enabled(Context) then
            Credits.ValidateForPurchaseInvoice(Context, RunId, 'PURCHASE.ORDER', LogicalKey, Invoice);
        end;
      end;
      if Mode <> 1 then begin
        Entry.Get(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT');
        Entry.TestField("Batch Id", BatchId);
        Entry.TestField("Table Id", Database::"Purchase Header");
        Header.GetBySystemId(Entry."Record SystemId");
        Header.TestField("Document Type", Header."Document Type"::Order);
        Header.TestField("Location Code", Contract.GetText(Token.AsObject(), 'location'));
        Header.TestField("Posting Date", Coordinator.PurchaseDate(Context, LogicalKey));
        if Contract.GetDatePolicyVersion(Context) = 1 then begin
          Header.TestField("Document Date", Coordinator.PurchaseDate(Context, LogicalKey));
          Header.TestField("Order Date", Coordinator.PurchaseDate(Context, LogicalKey));
        end;
        Header.TestField("Buy-from Vendor No.", Vendor."No.");
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', LogicalKey) do begin
          if Coordinator.IsWholesaleQualityProfile(Context) then begin
            WholesaleLineItem(Context, RunId, LogicalKey, LineIndex, Vendor."No.", Item);
            Quantity := Coordinator.WholesalePurchaseLineQuantity(Context, LogicalKey, LineIndex);
          end else
            Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
          PostedQuantity := Quantity;
          if Mode = 2 then
            PostedQuantity := Quantity / 2;
          Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
          Line.TestField(Type, Line.Type::Item);
          Line.TestField("No.", Item."No.");
          Line.TestField("Unit of Measure Code", Item."Base Unit of Measure");
          Line.TestField(Quantity, Quantity);
          if Mode = 0 then begin
            Line.TestField("Quantity Received", 0);
            Line.TestField("Quantity Invoiced", 0);
          end else begin
            Line.TestField("Quantity Received", PostedQuantity);
            Line.TestField("Quantity Invoiced", PostedQuantity);
            Line.TestField("Outstanding Quantity", Quantity - PostedQuantity);
          end;
        end;
      end;
      Count += 1;
    end;
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    if (Count <> Contract.GetInteger(Result, 'processedUnits')) or (Entry.Count() <> Contract.GetInteger(Result, 'createdRecords')) then
      Error(ResultErr);
    if Entry.FindSet() then
      repeat
        if not Registry.ExistsByIdentity(Entry) then
          Error(ResultErr);
      until Entry.Next() = 0;
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(ResultErr);
  end;

  var
    NameLbl: Label 'Purchase Orders, Receipts and Invoices';
    ApprovalErr: Label 'Approve purchase posting on this template and enable posting in Factory Setup before capturing a posted run.';
    SetupErr: Label 'Purchase orders require a supported document mode, two vendors and items from this run, a simple location and valid captured purchase numbering.';
    PermissionErr: Label 'Read or write permission is missing for %1. Review standard purchase permissions.', Comment = '%1 = table caption';
    ResultErr: Label 'The purchase order or its source relationship is missing, changed or already recorded. Review the batch; uncertain work is not repeated.';
}
