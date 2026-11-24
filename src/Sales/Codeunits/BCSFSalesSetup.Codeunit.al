namespace BCScenarioFactory.Sales;

using Microsoft.Sales.Posting;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ProcessEngine;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 90429 "BCSF Sales Setup"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCaptureSalesSetup', '', false, false)]
  local procedure Capture(Scenario: Record "BCSF Scenario"; InventorySettings: JsonObject; MasterBinding: JsonObject; var Settings: JsonObject)
  var
    Target: Record "BCSF Data Target";
    Sales: Record "Sales & Receivables Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Binding: JsonObject;
    SourceContext: JsonObject;
    Token: JsonToken;
    LocationCode: Code[10];
  begin
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Entity, '%1|%2|%3|%4', Target.Entity::SalesQuote, Target.Entity::SalesOrder, Target.Entity::SalesInvoice, Target.Entity::SalesBlanketOrder);
    Target.SetFilter(Quantity, '>0');
    if Target.IsEmpty() then
      exit;
    if not InventorySettings.Contains('location') then
      Error(SameRunErr);
    if (Scenario."Item Second Vendor No." <> '') or not Contract.GetBoolean(InventorySettings, 'generatedVendors') then
      Error(SameRunErr);
    LocationCode := CopyStr(Contract.GetText(InventorySettings, 'location'), 1, MaxStrLen(LocationCode));
    if Scenario."Generation Kind" = Scenario."Generation Kind"::Transactions then
      Settings.Add('version', 4)
    else
      if Scenario."Purchase Posting Approved" then
        Settings.Add('version', 3)
      else
        Settings.Add('version', 2);
    Settings.Add('location', LocationCode);
    Settings.Add('postingApproved', Scenario."Sales Posting Approved");
    Sales.Get();
    Settings.Add('quoteSeries', Sales."Quote Nos.");
    // Additive: runs captured before blanket orders existed have no blanket series and never plan blanket orders.
    Settings.Add('blanketSeries', Sales."Blanket Order Nos.");
    Settings.Add('orderSeries', Sales."Order Nos.");
    Settings.Add('invoiceSeries', Sales."Invoice Nos.");
    Settings.Add('postedInvoiceSeries', Sales."Posted Invoice Nos.");
    Settings.Add('shipmentSeries', Sales."Posted Shipment Nos.");
    if Scenario."Generation Kind" = Scenario."Generation Kind"::Transactions then begin
      // Reuse the exact binding captured once by Snapshot Writer.
      Binding := Contract.Clone(MasterBinding);
      Settings.Add('sourceRunId', Format(Scenario."Master Source Run Id", 0, 4));
      Binding.Get('customers', Token);
      Settings.Add('customers', Token.AsArray());
      Binding.Get('items', Token);
      Settings.Add('items', Token.AsArray());
      Binding.Get('shipToIds', Token);
      Settings.Add('shipToIds', Token.AsArray());
      SourceContext.Add('salesSetup', Contract.Clone(Settings));
      SourceContext.Add('masterDataSource', Binding);
      Settings.Add('masterFingerprint', MasterFingerprint(SourceContext));
    end;
  end;

  procedure UsesRunMasters(Context: JsonObject): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
  begin
    if not Context.Get('salesSetup', Token) then
      exit(false);
    exit(Contract.GetInteger(Token.AsObject(), 'version') in [2, 3]);
  end;

  procedure WithRunMasters(Context: JsonObject): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    Result: JsonObject;
    RunId: Guid;
    Ids: JsonArray;
    Addresses: JsonArray;
  begin
    if not UsesRunMasters(Context) then
      exit(Context);
    Result := Contract.Clone(Context);
    Settings := ReadSettings(Result);
    Evaluate(RunId, Contract.GetText(Result, 'runId'));
    Settings.Add('sourceRunId', Format(RunId, 0, 4));
    ReadRunIdentities(Result, RunId, "BCSF Entity Type"::Customer, Database::Customer, Ids, Addresses);
    Settings.Add('customers', Ids);
    Settings.Add('shipToIds', Addresses);
    Clear(Ids);
    ReadRunIdentities(Result, RunId, "BCSF Entity Type"::Item, Database::Item, Ids, Addresses);
    Settings.Add('items', Ids);
    Result.Replace('salesSetup', Settings);
    exit(Result);
  end;

  local procedure ReadRunIdentities(Context: JsonObject; RunId: Guid; Entity: Enum "BCSF Entity Type"; TableId: Integer; var Ids: JsonArray; var Addresses: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Delivery: Record "BCSF Generated Record";
    Contract: Codeunit "BCSF Contract JSON";
    Policy: Codeunit "BCSF Scenario Policy";
    Registry: Codeunit "BCSF Record Registry";
    NodeCode: Code[30];
    LogicalKey: Integer;
    CandidateCount: Integer;
  begin
    Entry.SecurityFiltering(SecurityFilter::Disallowed);
    Delivery.SecurityFiltering(SecurityFilter::Disallowed);
    NodeCode := Policy.GetEntityCode(Entity);
    CandidateCount := TargetQuantity(Context, Entity);
    if (Entity = Entity::Item) and (Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') in ['5', '6']) then begin
      // V6 includes every generated item; V5 snapshots retain their historical
      // candidate cap, which is part of the immutable selection contract.
      if (Contract.GetText(Context, 'profileVersion') = '5') and
        (CandidateCount > TargetQuantity(Context, Entity::Vendor) * 4) then
        CandidateCount := TargetQuantity(Context, Entity::Vendor) * 4;
    end else
      if CandidateCount > 100 then
        CandidateCount := 100;
    for LogicalKey := 1 to CandidateCount do begin
      Entry.Get(RunId, NodeCode, LogicalKey, NodeCode);
      Entry.TestField("Table Id", TableId);
      if not Contract.IsDocumentIsolation(Context) then
        if not Registry.ExistsByIdentity(Entry) then
          Error(DriftErr);
      Ids.Add(Format(Entry."Record SystemId", 0, 4));
      if Entity = Entity::Customer then
        if Delivery.Get(RunId, NodeCode, LogicalKey, 'DELIVERY') then begin
          Delivery.TestField("Table Id", Database::"Ship-to Address");
          Delivery.TestField("Parent Entry Id", Entry."Entry Id");
          if not Contract.IsDocumentIsolation(Context) then
            if not Registry.ExistsByIdentity(Delivery) then
              Error(DriftErr);
          Addresses.Add(Format(Delivery."Record SystemId", 0, 4));
        end;
    end;
  end;

  local procedure TargetQuantity(Context: JsonObject; Entity: Enum "BCSF Entity Type"): Integer
  var
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Target: JsonToken;
  begin
    Context.Get('targets', Targets);
    foreach Target in Targets.AsArray() do
      if Contract.GetInteger(Target.AsObject(), 'entity') = Entity.AsInteger() then
        exit(Contract.GetInteger(Target.AsObject(), 'quantity'));
    exit(0);
  end;

  procedure ReadSettings(Context: JsonObject): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
  begin
    if not Context.Get('salesSetup', Token) then
      Error(SourceErr);
    if not (Contract.GetInteger(Token.AsObject(), 'version') in [1, 2, 3, 4]) then
      Error(SourceErr);
    exit(Token.AsObject());
  end;

  procedure CustomerFor(Context: JsonObject; LogicalKey: Integer; var Customer: Record Customer)
  begin
    Customer.SecurityFiltering(SecurityFilter::Disallowed);
    Customer.GetBySystemId(Identity(Context, 'customers', LogicalKey));
    CheckProvenance(Context, Database::Customer, Customer.SystemId);
  end;

  procedure ItemFor(Context: JsonObject; LogicalKey: Integer; var Item: Record Item)
  begin
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    Item.GetBySystemId(Identity(Context, 'items', LogicalKey));
    CheckProvenance(Context, Database::Item, Item.SystemId);
  end;

  local procedure Identity(Context: JsonObject; Name: Text; LogicalKey: Integer): Guid
  var
    Token: JsonToken;
    Id: Guid;
  begin
    ReadSettings(Context).Get(Name, Token);
    Token.AsArray().Get((LogicalKey - 1) mod Token.AsArray().Count(), Token);
    Evaluate(Id, Token.AsValue().AsText());
    exit(Id);
  end;

  local procedure CheckProvenance(Context: JsonObject; TableId: Integer; Id: Guid)
  var
    Entry: Record "BCSF Generated Record";
    Contract: Codeunit "BCSF Contract JSON";
    Source: Codeunit "BCSF Master Data Source";
    SourceRunId: Guid;
  begin
    if Source.IsExistingPool(Context) then
      exit;
    Evaluate(SourceRunId, Contract.GetText(ReadSettings(Context), 'sourceRunId'));
    Entry.SetCurrentKey("Table Id", "Record SystemId");
    Entry.SetRange("Table Id", TableId);
    Entry.SetRange("Record SystemId", Id);
    Entry.FindFirst();
    Entry.TestField("Run Id", SourceRunId);
  end;

  procedure Check(Context: JsonObject; Target: JsonObject)
  var
    Customer: Record Customer;
    Item: Record Item;
    Location: Record Location;
    Sales: Record "Sales & Receivables Setup";
    GL: Record "General Ledger Setup";
    Inventory: Record "Inventory Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    Guard: Codeunit "BCSF Environment Guard";
    Source: Codeunit "BCSF Master Data Source";
    Values: JsonObject;
    PurchaseToken: JsonToken;
    Ids: JsonToken;
    DateFrom: Date;
    DateTo: Date;
    Index: Integer;
    Posting: Boolean;
    Code: Code[30];
  begin
    Contract.CheckTarget(Context, Target);
    Source.Validate(Context);
    Values := ReadSettings(Context);
    if UsesRunMasters(Context) then begin
      if (TargetQuantity(Context, "BCSF Entity Type"::Customer) < 1) or
        (TargetQuantity(Context, "BCSF Entity Type"::Vendor) < 2) or
        (TargetQuantity(Context, "BCSF Entity Type"::Item) < 1) then
        Error(SameRunErr);
      if Contract.GetInteger(Target, 'processMode') = 2 then begin
        if (Contract.GetInteger(Values, 'version') <> 3) or not Context.Get('purchaseSetup', PurchaseToken) then
          Error(ReceiptRequiredErr);
        if (Contract.GetInteger(PurchaseToken.AsObject(), 'version') <> 2) or
          not Contract.GetBoolean(PurchaseToken.AsObject(), 'postingApproved') then
          Error(ReceiptRequiredErr);
      end;
    end else
      if not Contract.IsDocumentIsolation(Context) then
        if Contract.GetText(Values, 'masterFingerprint') <> MasterFingerprint(Context) then
          Error(DriftErr);
    Code := Contract.GetCode(Target, 'entityCode');
    if not (Code in ['SALES.QUOTE', 'SALES.ORDER', 'SALES.INVOICE', 'SALES.BLANKET']) or
      (Contract.GetCode(Target, 'moduleCode') <> 'SALES') or not (Contract.GetInteger(Target, 'processMode') in [1, 2]) then
      Error(UnsupportedErr);
    Evaluate(DateFrom, Contract.GetText(Context, 'startingDate'), 9);
    Evaluate(DateTo, Contract.GetText(Context, 'endingDate'), 9);
    Posting := Contract.GetInteger(Target, 'processMode') = 2;
    if Posting and not Contract.GetBoolean(Values, 'postingApproved') then
      Error(ApprovalErr);
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Location.Get(Contract.GetText(Values, 'location'));
    Location.TestField("Use As In-Transit", false);
    Location.TestField("Bin Mandatory", false);
    Location.TestField("Require Shipment", false);
    Location.TestField("Require Pick", false);
    Location.TestField("Directed Put-away and Pick", false);
    Sales.Get();
    Sales.TestField("Quote Nos.", Contract.GetText(Values, 'quoteSeries'));
    Sales.TestField("Order Nos.", Contract.GetText(Values, 'orderSeries'));
    Sales.TestField("Invoice Nos.", Contract.GetText(Values, 'invoiceSeries'));
    Sales.TestField("Posted Invoice Nos.", Contract.GetText(Values, 'postedInvoiceSeries'));
    Sales.TestField("Posted Shipment Nos.", Contract.GetText(Values, 'shipmentSeries'));
    case Code of
      'SALES.QUOTE': CheckSeries(CopyStr(Contract.GetCode(Values, 'quoteSeries'), 1, 20), DateFrom, DateTo);
      'SALES.BLANKET':
        begin
          if not Values.Contains('blanketSeries') then
            Error(UnsupportedErr);
          Sales.TestField("Blanket Order Nos.", Contract.GetText(Values, 'blanketSeries'));
          CheckSeries(CopyStr(Contract.GetCode(Values, 'blanketSeries'), 1, 20), DateFrom, DateTo);
        end;
      'SALES.ORDER':
        begin
          Guard.EnsureCodeunitAccess(Codeunit::"Sales-Quote to Order");
          Sales.TestField("Archive Quotes", Sales."Archive Quotes"::Never);
          CheckSeries(CopyStr(Contract.GetCode(Values, 'quoteSeries'), 1, 20), DateFrom, DateTo);
          CheckSeries(CopyStr(Contract.GetCode(Values, 'orderSeries'), 1, 20), DateFrom, DateTo);
        end;
      'SALES.INVOICE': CheckSeries(CopyStr(Contract.GetCode(Values, 'invoiceSeries'), 1, 20), DateFrom, DateTo);
    end;
    CheckPermission(Database::"Sales Header", true);
    CheckPermission(Database::"Sales Line", true);
    if Posting then begin
      Guard.EnsureCodeunitAccess(Codeunit::"Sales-Post");
      if Contract.GetInteger(Values, 'version') in [3, 4] then begin
        Inventory.Get();
        Inventory.TestField("Automatic Cost Posting", true);
      end;
      if Payments.Enabled(Context) then begin
        Payments.Check(Context);
        if Credits.Enabled(Context) then begin
          Credits.CheckSetup(true);
          Guard.EnsurePostingTableAccess(Database::"Sales Cr.Memo Header", false);
        end;
      end;
      CheckSeries(CopyStr(Contract.GetCode(Values, 'postedInvoiceSeries'), 1, 20), DateFrom, DateTo);
      if Code = 'SALES.ORDER' then
        CheckSeries(CopyStr(Contract.GetCode(Values, 'shipmentSeries'), 1, 20), DateFrom, DateTo);
      Guard.EnsurePostingTableAccess(Database::"Sales Invoice Header", false);
      Guard.EnsurePostingTableAccess(Database::"Sales Invoice Line", false);
      if Code = 'SALES.ORDER' then begin
        Guard.EnsurePostingTableAccess(Database::"Sales Shipment Header", false);
        Guard.EnsurePostingTableAccess(Database::"Sales Shipment Line", false);
      end;
      Guard.EnsurePostingTableAccess(Database::"Cust. Ledger Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Detailed Cust. Ledg. Entry", false);
      Guard.EnsurePostingTableAccess(Database::"G/L Entry", false);
      Guard.EnsurePostingTableAccess(Database::"VAT Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Item Ledger Entry", false);
      Guard.EnsurePostingTableAccess(Database::"Value Entry", false);
      GL.Get();
      if ((GL."Allow Posting From" <> 0D) and (DateFrom < GL."Allow Posting From")) or
        ((GL."Allow Posting To" <> 0D) and (DateTo > GL."Allow Posting To")) then
        Error(DateErr);
    end;
    if Contract.IsDocumentIsolation(Context) then
      exit; // Per-document read-only inspection checks the chosen masters.
    if UsesRunMasters(Context) then begin
      if not Context.Contains('batchId') then
        exit;
      Context := WithRunMasters(Context);
      Values := ReadSettings(Context);
    end;
    Values.Get('customers', Ids);
    for Index := 1 to Ids.AsArray().Count() do begin
      CustomerFor(Context, Index, Customer);
      CheckCustomer(Customer);
    end;
    Values.Get('items', Ids);
    for Index := 1 to Ids.AsArray().Count() do begin
      ItemFor(Context, Index, Item);
      CheckItem(Item);
      CheckCombinations(Context, Item, Posting);
      if Posting then
        CheckRemainingStock(Context, Item, Index, Ids.AsArray().Count());
    end;
  end;

  procedure CheckFrozenMasters(Context: JsonObject; Customer: Record Customer; Item: Record Item)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    Subset: JsonObject;
    Ids: JsonArray;
    EmptyIds: JsonArray;
    Actual: JsonArray;
    Captured: JsonArray;
    ActualToken: JsonToken;
    CapturedToken: JsonToken;
    ActualText: Text;
    CapturedText: Text;
    Found: Boolean;
  begin
    if UsesRunMasters(Context) then
      exit;
    Settings := Contract.Clone(ReadSettings(Context));
    Captured.ReadFrom(Contract.GetText(Settings, 'masterFingerprint'));
    Subset := Contract.Clone(Context);
    Ids.Add(Format(Customer.SystemId, 0, 4));
    Settings.Replace('customers', Ids);
    Clear(Ids);
    Ids.Add(Format(Item.SystemId, 0, 4));
    Settings.Replace('items', Ids);
    Settings.Replace('shipToIds', EmptyIds);
    Subset.Replace('salesSetup', Settings);
    Actual.ReadFrom(MasterFingerprint(Subset));
    foreach ActualToken in Actual do begin
      Found := false;
      foreach CapturedToken in Captured do
        if Contract.GetText(CapturedToken.AsObject(), 'id') = Contract.GetText(ActualToken.AsObject(), 'id') then begin
          ActualToken.WriteTo(ActualText);
          CapturedToken.WriteTo(CapturedText);
          if ActualText <> CapturedText then
            Error(DriftErr);
          Found := true;
          break;
        end;
      if not Found then
        Error(DriftErr);
    end;
  end;

  procedure CheckCustomer(Customer: Record Customer)
  var
    Terms: Record "Payment Terms";
    Method: Record "Payment Method";
    Group: Record "Customer Posting Group";
  begin
    CheckDefaultDimensions(Database::Customer, Customer."No.");
    Customer.TestField(Blocked, Customer.Blocked::" ");
    if Customer.Reserve = Customer.Reserve::Always then
      Error(UnsupportedErr);
    Customer.TestField("Currency Code", '');
    Customer.TestField("IC Partner Code", '');
    if (Customer."Bill-to Customer No." <> '') and (Customer."Bill-to Customer No." <> Customer."No.") then
      Error(UnsupportedErr);
    Customer.TestField("Payment Terms Code");
    Terms.Get(Customer."Payment Terms Code");
    Customer.TestField("Shipping Advice", Customer."Shipping Advice"::Partial);
    if Customer."Payment Method Code" <> '' then begin
      Method.Get(Customer."Payment Method Code");
      Method.TestField("Bal. Account No.", '');
      Method.TestField("Direct Debit", false);
    end;
    Group.Get(Customer."Customer Posting Group");
    CheckAccount(Group."Receivables Account");
  end;

  procedure CheckItem(Item: Record Item)
  var
    Unit: Record "Item Unit of Measure";
    InventorySetup: Record "Inventory Setup";
  begin
    CheckDefaultDimensions(Database::Item, Item."No.");
    Item.TestField(Type, Item.Type::Inventory);
    Item.TestField(Blocked, false);
    Item.TestField("Sales Blocked", false);
    if Item.Reserve = Item.Reserve::Always then
      Error(UnsupportedErr);
    Item.TestField("Replenishment System", Item."Replenishment System"::Purchase);
    Item.TestField("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Stock");
    Item.TestField("Item Tracking Code", '');
    InventorySetup.Get();
    if (Item."Variant Mandatory if Exists" = Item."Variant Mandatory if Exists"::Yes) or
      ((Item."Variant Mandatory if Exists" = Item."Variant Mandatory if Exists"::Default) and InventorySetup."Variant Mandatory if Exists") then
      Error(UnsupportedErr);
    Item.TestField("Base Unit of Measure");
    Unit.Get(Item."No.", Item."Base Unit of Measure");
    Unit.TestField("Qty. per Unit of Measure", 1);
    if Item."Unit Price" <= 0 then
      Error(PriceErr);
  end;

  local procedure CheckCombinations(Context: JsonObject; Item: Record Item; Posting: Boolean)
  var
    Customer: Record Customer;
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Inventory: Record "Inventory Posting Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Ids: JsonToken;
    Index: Integer;
  begin
    ReadSettings(Context).Get('customers', Ids);
    for Index := 1 to Ids.AsArray().Count() do begin
      CustomerFor(Context, Index, Customer);
      General.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
      General.TestField(Blocked, false);
      VAT.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
      VAT.TestField(Blocked, false);
      VAT.TestField("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
      if Posting then begin
        CheckAccount(General."Sales Account");
        CheckAccount(General."COGS Account");
        CheckAccount(General."Inventory Adjmt. Account");
        if VAT."VAT %" <> 0 then
          CheckAccount(VAT."Sales VAT Account");
      end;
    end;
    Inventory.Get(Contract.GetText(ReadSettings(Context), 'location'), Item."Inventory Posting Group");
    CheckAccount(Inventory."Inventory Account");
  end;

  local procedure CheckRemainingStock(Context: JsonObject; var Item: Record Item; ItemIndex: Integer; ItemCount: Integer)
  var
    Entry: Record "BCSF Generated Record";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Policy: Codeunit "BCSF Scenario Policy";
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    RunId: Guid;
    EntityCode: Code[30];
    FirstKey: Integer;
    LogicalKey: Integer;
    Mode: Integer;
    Demand: Decimal;
    Quantity: Decimal;
  begin
    // Wholesale multi-position sales verify availability immediately before posting
    // each line. The old modulo-based forecast is invalid for this assortment.
    // Existing company data is not required to have stock for every item.
    // The actual generated document decides whether posting is possible.
    if Context.Contains('masterDataSource') then
      exit;
    if Coordinator.IsWholesaleQualityProfile(Context) and
      (TargetQuantity(Context, "BCSF Entity Type"::PurchaseOrder) > 0) then
      exit;
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do begin
      Target := Token.AsObject();
      EntityCode := Policy.GetEntityCode("BCSF Entity Type".FromInteger(Contract.GetInteger(Target, 'entity')));
      if EntityCode in ['SALES.ORDER', 'SALES.INVOICE'] then begin
        FirstKey := 1;
        Entry.Reset();
        Entry.SetRange("Run Id", RunId);
        Entry.SetRange("Node Code", EntityCode);
        if Entry.FindLast() then
          FirstKey := Entry."Logical Key" + 1;
        LogicalKey := ItemIndex;
        if LogicalKey < FirstKey then
          LogicalKey += ((FirstKey - LogicalKey + ItemCount - 1) div ItemCount) * ItemCount;
        while LogicalKey <= Contract.GetInteger(Target, 'quantity') do begin
          Mode := Coordinator.Disposition(Context, EntityCode, LogicalKey);
          Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
          if Mode = 1 then
            Demand += Quantity;
          if Mode = 2 then
            Demand += Quantity / 2;
          LogicalKey += ItemCount;
        end;
      end;
    end;
    if Coordinator.IsWholesaleQualityProfile(Context) then
      Demand := Coordinator.WholesaleRemainingDemand(Context, ItemIndex);
    CheckStock(Context, Item, Demand, 0D);
  end;

  procedure HasStock(Context: JsonObject; var Item: Record Item; Required: Decimal; AsOfDate: Date): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
    Reserved: Decimal;
    Available: Decimal;
  begin
    Item.LockTable();
    Item.Get(Item."No.");
    Item.SetRange("Location Filter", Contract.GetText(ReadSettings(Context), 'location'));
    Item.SetRange("Variant Filter", '');
    Item.SetRange("Date Filter");
    Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
    Reserved := Item."Reserved Qty. on Inventory";
    Available := Item.Inventory - Reserved;
    Item.SetFilter("Date Filter", '..%1', AsOfDate);
    Item.CalcFields(Inventory);
    if Item.Inventory - Reserved < Available then
      Available := Item.Inventory - Reserved;
    exit(Available >= Required);
  end;

  procedure CheckStock(Context: JsonObject; var Item: Record Item; Required: Decimal; AsOfDate: Date)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Available: Decimal;
    Reserved: Decimal;
  begin
    // Match the standard item posting lock before checking consumable stock.
    Item.LockTable();
    Item.Get(Item."No.");
    if AsOfDate = 0D then
      if Contract.GetDatePolicyVersion(Context) = 1 then
        Evaluate(AsOfDate, Contract.GetText(Context, 'endingDate'), 9)
      else
        Evaluate(AsOfDate, Contract.GetText(Context, 'startingDate'), 9);
    Item.SetRange("Location Filter", Contract.GetText(ReadSettings(Context), 'location'));
    Item.SetRange("Variant Filter", '');
    Item.SetRange("Date Filter");
    Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
    Reserved := Item."Reserved Qty. on Inventory";
    Available := Item.Inventory - Reserved;
    Item.SetFilter("Date Filter", '..%1', AsOfDate);
    Item.CalcFields(Inventory);
    if Item.Inventory - Reserved < Available then
      Available := Item.Inventory - Reserved;
    if Available < Required then
      Error(StockErr, Item."No.", Required, Available);
  end;

  local procedure CheckDefaultDimensions(TableId: Integer; No: Code[20])
  var
    Defaults: Record "Default Dimension";
    Value: Record "Dimension Value";
  begin
    Defaults.SecurityFiltering(SecurityFilter::Disallowed);
    Defaults.SetRange("Table ID", TableId);
    Defaults.SetRange("No.", No);
    if Defaults.FindSet() then
      repeat
        if Defaults."Dimension Value Code" <> '' then begin
          Value.Get(Defaults."Dimension Code", Defaults."Dimension Value Code");
          Value.TestField(Blocked, false);
          Value.TestField("Dimension Value Type", Value."Dimension Value Type"::Standard);
        end;
      until Defaults.Next() = 0;
  end;

  local procedure MasterFingerprint(Context: JsonObject): Text
  var
    Address: Record "Ship-to Address";
    Customer: Record Customer;
    Item: Record Item;
    Values: JsonObject;
    Row: JsonObject;
    Rows: JsonArray;
    Ids: JsonToken;
    Index: Integer;
    Text: Text;
    AddressId: Guid;
  begin
    Values := ReadSettings(Context);
    Values.Get('customers', Ids);
    for Index := 1 to Ids.AsArray().Count() do begin
      CustomerFor(Context, Index, Customer);
      Clear(Row);
      Row.Add('id', Format(Customer.SystemId, 0, 4));
      Row.Add('no', Customer."No.");
      Row.Add('general', Customer."Gen. Bus. Posting Group");
      Row.Add('vat', Customer."VAT Bus. Posting Group");
      Row.Add('posting', Customer."Customer Posting Group");
      Row.Add('terms', Customer."Payment Terms Code");
      Row.Add('method', Customer."Payment Method Code");
      Row.Add('dimension1', Customer."Global Dimension 1 Code");
      Row.Add('dimension2', Customer."Global Dimension 2 Code");
      Rows.Add(Row);
    end;
    Values.Get('items', Ids);
    for Index := 1 to Ids.AsArray().Count() do begin
      ItemFor(Context, Index, Item);
      Clear(Row);
      Row.Add('id', Format(Item.SystemId, 0, 4));
      Row.Add('no', Item."No.");
      Row.Add('general', Item."Gen. Prod. Posting Group");
      Row.Add('vat', Item."VAT Prod. Posting Group");
      Row.Add('inventory', Item."Inventory Posting Group");
      Row.Add('unit', Item."Base Unit of Measure");
      Row.Add('price', Item."Unit Price");
      Rows.Add(Row);
    end;
    Values.Get('shipToIds', Ids);
    for Index := 0 to Ids.AsArray().Count() - 1 do begin
      Ids.AsArray().Get(Index, Ids);
      Evaluate(AddressId, Ids.AsValue().AsText());
      Address.SecurityFiltering(SecurityFilter::Disallowed);
      Address.GetBySystemId(AddressId);
      CheckProvenance(Context, Database::"Ship-to Address", Address.SystemId);
      Clear(Row);
      Row.Add('id', Format(Address.SystemId, 0, 4));
      Row.Add('customer', Address."Customer No.");
      Row.Add('code', Address.Code);
      Row.Add('address', Address.Address);
      Row.Add('postCode', Address."Post Code");
      Row.Add('city', Address.City);
      Rows.Add(Row);
      Values.Get('shipToIds', Ids);
    end;
    Rows.WriteTo(Text);
    exit(Text);
  end;

  local procedure CheckAccount(No: Code[20])
  var
    Account: Record "G/L Account";
  begin
    Account.Get(No);
    Account.TestField(Blocked, false);
    Account.TestField("Account Type", Account."Account Type"::Posting);
  end;

  local procedure CheckSeries(Code: Code[20]; DateFrom: Date; DateTo: Date)
  var
    Series: Record "No. Series";
    Numbers: Codeunit "No. Series";
  begin
    Series.Get(Code);
    Series.TestField("Default Nos.", true);
    // Date-order series can force commits inside Sales-Post and are not supported.
    Series.TestField("Date Order", false);
    if (Numbers.PeekNextNo(Code, DateFrom) = '') or (Numbers.PeekNextNo(Code, DateTo) = '') then
      Error(DateErr);
  end;

  procedure CheckPermission(TableId: Integer; WriteRequired: Boolean)
  var
    Row: RecordRef;
  begin
    Row.Open(TableId);
    Row.SecurityFiltering(SecurityFilter::Disallowed);
    if not Row.ReadPermission() or (WriteRequired and not Row.WritePermission()) then
      Error(PermissionErr, Row.Caption());
    Row.Close();
  end;

  var
    DriftErr: Label 'Source sales master data has changed since capture. Review the source and capture a new run.';
    SourceErr: Label 'The captured sales setup is missing or unsupported. Start the template again after checking its sales and item targets.';
    SameRunErr: Label 'Sales requires at least one customer, two vendors and one item from the same template. Use the technical wholesale assortment and leave the existing item vendors blank.';
    ReceiptRequiredErr: Label 'Posted sales from newly generated items require approved standard purchase receipts in the same run. Review purchase targets, quotas and posting approval.';
    UnsupportedErr: Label 'This sales process supports quotes, orders and invoices in local currency with a simple location and no tracking, mandatory variant, intercompany or automatic payment.';
    ApprovalErr: Label 'Approve sales posting on this template and enable posting in Factory Setup before capturing a posted run.';
    DateErr: Label 'The sales dates or captured number series are unavailable or incompatible with atomic posting.';
    PriceErr: Label 'A source item requires a positive sales price.';
    PermissionErr: Label 'Read or write permission is missing for %1. Review standard permissions; no rights are granted.', Comment = '%1 = table caption';
    StockErr: Label 'Item %1 needs %2 base units at the selected location; only %3 unreserved units are available. Prepare stock through a standard BC process or use unposted mode.', Comment = '%1 = item number, %2 = required quantity, %3 = available quantity';
}
