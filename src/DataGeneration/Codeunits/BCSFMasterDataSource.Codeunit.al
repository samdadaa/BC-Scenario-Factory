namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 90259 "BCSF Master Data Source"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCaptureMasterSource', '', false, false)]
  local procedure CaptureSource(Scenario: Record "BCSF Scenario"; var Binding: JsonObject; var InventorySettings: JsonObject)
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Token: JsonToken;
  begin
    if Scenario."Generation Kind" <> Scenario."Generation Kind"::Transactions then begin
      if not IsNullGuid(Scenario."Master Source Run Id") then
        Error(SourceErr);
      exit;
    end;
    if IsNullGuid(Scenario."Master Source Run Id") then begin
      Binding := CaptureExisting();
      InventorySettings.Add('generatedVendors', true);
      InventorySettings.Add('location', ResolveExistingLocation());
      exit;
    end;
    Binding := Capture(Scenario."Master Source Run Id", Scenario."Profile Code", Scenario."Profile Version");
    Manager.ReadSnapshot(Scenario."Master Source Run Id", Context);
    Context.Get('itemSetup', Token);
    InventorySettings := Contract.Clone(Token.AsObject());
    InventorySettings.Add('sourceRunId', Format(Scenario."Master Source Run Id", 0, 4));
  end;

  // SF-048: Capture a stable, read-only pool from the current company. No historical run is required.
  procedure CaptureExisting(): JsonObject
  var
    Customer: Record Customer;
    Vendor: Record Vendor;
    Item: Record Item;
    Customers: JsonArray;
    Vendors: JsonArray;
    Items: JsonArray;
    Addresses: JsonArray;
    Binding: JsonObject;
    LocationCode: Code[10];
    MinItemsPerSupplier: Integer;
    Count: Integer;
    RoundIndex: Integer;
    ItemIndex: Integer;
    PostingPairs: List of [Text];
  begin
    LocationCode := ResolveExistingLocation();
    Vendor.SecurityFiltering(SecurityFilter::Disallowed);
    MinItemsPerSupplier := 501;
    if Vendor.FindSet() then
      repeat
        if EligibleVendor(Vendor) then begin
          Count := CountEligibleItems(Vendor."No.", LocationCode);
          // Multi-line wholesale purchasing needs four distinct articles per supplier.
          if Count >= 4 then begin
            Vendors.Add(Format(Vendor.SystemId, 0, 4));
            if Count < MinItemsPerSupplier then
              MinItemsPerSupplier := Count;
          end;
        end;
      until Vendor.Next() = 0;
    // Match the existing deterministic wholesale planner: positions are grouped
    // by vendor in round-robin order and every vendor has the same number of items.
    if Vendors.Count() >= 2 then
      for RoundIndex := 1 to MinItemsPerSupplier do begin
        Vendor.Reset();
        if Vendor.FindSet() then
          repeat
            if IsSelectedVendor(Vendors, Vendor.SystemId) then begin
              Item.Reset();
              Item.SetRange("Vendor No.", Vendor."No.");
              ItemIndex := 0;
              if Item.FindSet() then
                repeat
                  if EligibleItem(Item, LocationCode) then begin
                    ItemIndex += 1;
                    if ItemIndex = RoundIndex then
                      Items.Add(Format(Item.SystemId, 0, 4));
                  end;
                until (Item.Next() = 0) or (ItemIndex = RoundIndex);
            end;
          until Vendor.Next() = 0;
      end;
    CollectPostingPairs(Items, PostingPairs);
    Customer.SecurityFiltering(SecurityFilter::Disallowed);
    if Customer.FindSet() then
      repeat
        if EligibleCustomer(Customer) and CustomerSupportsItems(Customer, PostingPairs) then
          Customers.Add(Format(Customer.SystemId, 0, 4));
      until Customer.Next() = 0;
    if (Customers.Count() = 0) or (Vendors.Count() < 2) or (Items.Count() = 0) then
      Error(EmptyPoolErr);
    Binding.Add('version', 2);
    Binding.Add('profileCode', 'TRADE');
    Binding.Add('customers', Customers);
    Binding.Add('vendors', Vendors);
    Binding.Add('items', Items);
    Binding.Add('shipToIds', Addresses);
    exit(Binding);
  end;

  local procedure CountEligibleItems(VendorNo: Code[20]; LocationCode: Code[10]): Integer
  var
    Item: Record Item;
    Count: Integer;
  begin
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    Item.SetRange("Vendor No.", VendorNo);
    if Item.FindSet() then
      repeat
        if EligibleItem(Item, LocationCode) then
          Count += 1;
      until (Item.Next() = 0) or (Count >= 500);
    exit(Count);
  end;

  local procedure IsSelectedVendor(Vendors: JsonArray; Id: Guid): Boolean
  var
    Token: JsonToken;
  begin
    foreach Token in Vendors do
      if Token.AsValue().AsText() = Format(Id, 0, 4) then
        exit(true);
    exit(false);
  end;

  local procedure CollectPostingPairs(Items: JsonArray; var PostingPairs: List of [Text])
  var
    Item: Record Item;
    Token: JsonToken;
    Id: Guid;
    Pair: Text;
  begin
    foreach Token in Items do begin
      Evaluate(Id, Token.AsValue().AsText());
      Item.GetBySystemId(Id);
      Pair := Item."Gen. Prod. Posting Group" + '|' + Item."VAT Prod. Posting Group";
      if not PostingPairs.Contains(Pair) then
        PostingPairs.Add(Pair);
    end;
  end;

  local procedure CustomerSupportsItems(Customer: Record Customer; PostingPairs: List of [Text]): Boolean
  var
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Posting: Record "Customer Posting Group";
    Pair: Text;
    Divider: Integer;
    ProductGroup: Code[20];
    VATGroup: Code[20];
  begin
    if not Posting.Get(Customer."Customer Posting Group") then
      exit(false);
    if Posting."Receivables Account" = '' then
      exit(false);
    foreach Pair in PostingPairs do begin
      Divider := StrPos(Pair, '|');
      if Divider < 2 then
        exit(false);
      ProductGroup := CopyStr(Pair, 1, Divider - 1);
      VATGroup := CopyStr(Pair, Divider + 1, MaxStrLen(VATGroup));
      if not General.Get(Customer."Gen. Bus. Posting Group", ProductGroup) then
        exit(false);
      if General.Blocked or (General."Sales Account" = '') or
        (General."COGS Account" = '') or (General."Inventory Adjmt. Account" = '') then
        exit(false);
      if not VAT.Get(Customer."VAT Bus. Posting Group", VATGroup) then
        exit(false);
      if VAT.Blocked or (VAT."VAT Calculation Type" <> VAT."VAT Calculation Type"::"Normal VAT") then
        exit(false);
      if (VAT."VAT %" <> 0) and (VAT."Sales VAT Account" = '') then
        exit(false);
    end;
    exit(true);
  end;

  local procedure ResolveExistingLocation(): Code[10]
  var
    Location: Record Location;
  begin
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    if Location.Get('MAIN') then
      if not Location."Bin Mandatory" and not Location."Use As In-Transit" and
        not Location."Require Receive" and not Location."Require Shipment" then
        exit(Location.Code);
    Location.Reset();
    Location.SetRange("Bin Mandatory", false);
    Location.SetRange("Use As In-Transit", false);
    Location.SetRange("Require Receive", false);
    Location.SetRange("Require Shipment", false);
    Location.SetRange("Require Pick", false);
    Location.SetRange("Require Put-away", false);
    if Location.FindFirst() then
      exit(Location.Code);
    Error(LocationErr);
  end;

  local procedure EligibleCustomer(Customer: Record Customer): Boolean
  var
    Posting: Record "Customer Posting Group";
  begin
    if (Customer.Blocked <> Customer.Blocked::" ") or
      (Customer."Gen. Bus. Posting Group" = '') or (Customer."VAT Bus. Posting Group" = '') or
      (Customer."Customer Posting Group" = '') or (Customer."Currency Code" <> '') or
      (Customer."IC Partner Code" <> '') then
      exit(false);
    exit(Posting.Get(Customer."Customer Posting Group"));
  end;

  local procedure EligibleVendor(Vendor: Record Vendor): Boolean
  var
    Posting: Record "Vendor Posting Group";
  begin
    if (Vendor.Blocked <> Vendor.Blocked::" ") or
      (Vendor."Gen. Bus. Posting Group" = '') or (Vendor."VAT Bus. Posting Group" = '') or
      (Vendor."Vendor Posting Group" = '') or (Vendor."Currency Code" <> '') or
      (Vendor."IC Partner Code" <> '') or (Vendor."Pay-to Vendor No." <> '') then
      exit(false);
    exit(Posting.Get(Vendor."Vendor Posting Group"));
  end;

  local procedure EligibleItem(Item: Record Item; LocationCode: Code[10]): Boolean
  var
    Unit: Record "Item Unit of Measure";
    Relation: Record "Item Vendor";
    Vendor: Record Vendor;
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Inventory: Record "Inventory Posting Setup";
  begin
    if Item.Blocked or Item."Purchasing Blocked" or Item."Sales Blocked" or
      (Item.Type <> Item.Type::Inventory) or (Item."Item Tracking Code" <> '') or
      (Item."Base Unit of Measure" = '') or (Item."Vendor No." = '') or
      (Item."Unit Price" <= 0) or (Item."Gen. Prod. Posting Group" = '') or
      (Item."VAT Prod. Posting Group" = '') or (Item."Inventory Posting Group" = '') then
      exit(false);
    if not Unit.Get(Item."No.", Item."Base Unit of Measure") then
      exit(false);
    if Unit."Qty. per Unit of Measure" <> 1 then
      exit(false);
    if not Vendor.Get(Item."Vendor No.") then
      exit(false);
    if not EligibleVendor(Vendor) or not Relation.Get(Vendor."No.", Item."No.", '') then
      exit(false);
    if not General.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group") then
      exit(false);
    if General.Blocked or (General."Purch. Account" = '') then
      exit(false);
    if not VAT.Get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
      exit(false);
    if VAT.Blocked or (VAT."VAT Calculation Type" <> VAT."VAT Calculation Type"::"Normal VAT") then
      exit(false);
    if not Inventory.Get(LocationCode, Item."Inventory Posting Group") then
      exit(false);
    exit(Inventory."Inventory Account" <> '');
  end;

  procedure IsExistingPool(Context: JsonObject): Boolean
  var
    Token: JsonToken;
    Contract: Codeunit "BCSF Contract JSON";
  begin
    if not Context.Get('masterDataSource', Token) then
      exit(false);
    exit(Contract.GetInteger(Token.AsObject(), 'version') = 2);
  end;

  procedure ItemFromPool(Context: JsonObject; Index: Integer; var Item: Record Item)
  var
    Token: JsonToken;
    ArrayToken: JsonToken;
    Id: Guid;
  begin
    if not IsExistingPool(Context) then
      Error(SourceErr);
    Context.Get('masterDataSource', Token);
    Token.AsObject().Get('items', ArrayToken);
    ArrayToken.AsArray().Get((Index - 1) mod ArrayToken.AsArray().Count(), Token);
    Evaluate(Id, Token.AsValue().AsText());
    Item.GetBySystemId(Id);
    if not EligibleItem(Item, ResolveExistingLocation()) then
      Error(DriftErr);
  end;

  procedure Capture(SourceId: Guid; ProfileCode: Code[30]; ProfileVersion: Code[20]): JsonObject
  var
    Header: Record "BCSF Run Header";
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Binding: JsonObject;
    Context: JsonObject;
    Settings: JsonToken;
    Ids: JsonArray;
    Addresses: JsonArray;
    Confirmed: Boolean;
  begin
    if IsNullGuid(SourceId) then
      Error(SourceErr);
    Header.SecurityFiltering(SecurityFilter::Disallowed);
    Header.Get(SourceId);
    Header.TestField("Company Name", CompanyName());
    Header.TestField("Profile Code", ProfileCode);
    Header.TestField("Profile Version", ProfileVersion);
    if (ProfileCode <> 'TRADE') or not (ProfileVersion in ['5', '6']) then
      Error(SourceErr);
    Manager.ReadSnapshot(SourceId, Context);
    Contract.CheckContext(Context);
    if Context.Contains('masterDataSource') then
      Error(SourceErr);
    if not Context.Get('itemSetup', Settings) then
      Error(SourceErr);
    if not Contract.GetBoolean(Settings.AsObject(), 'generatedVendors') then
      Error(SourceErr);
    OnCheckSource(SourceId, Confirmed);
    if not Confirmed then
      Error(SourceErr);
    Binding.Add('version', 1);
    Binding.Add('sourceRunId', Format(SourceId, 0, 4));
    Binding.Add('profileCode', ProfileCode);
    Binding.Add('profileVersion', ProfileVersion);
    ReadEntity(Context, SourceId, "BCSF Entity Type"::Customer, 'CUSTOMER', Database::Customer, Ids, Addresses);
    Binding.Add('customers', Ids);
    Binding.Add('shipToIds', Addresses);
    Clear(Ids);
    ReadEntity(Context, SourceId, "BCSF Entity Type"::Vendor, 'VENDOR', Database::Vendor, Ids, Addresses);
    Binding.Add('vendors', Ids);
    Clear(Ids);
    ReadEntity(Context, SourceId, "BCSF Entity Type"::Item, 'ITEM', Database::Item, Ids, Addresses);
    Binding.Add('items', Ids);
    exit(Binding);
  end;

  local procedure ReadEntity(Context: JsonObject; SourceId: Guid; Entity: Enum "BCSF Entity Type"; NodeCode: Code[30]; TableId: Integer; var Ids: JsonArray; var Addresses: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Delivery: Record "BCSF Generated Record";
    Customer: Record Customer;
    Vendor: Record Vendor;
    Item: Record Item;
    Unit: Record "Item Unit of Measure";
    Relation: Record "Item Vendor";
    Registry: Codeunit "BCSF Record Registry";
    Index: Integer;
    Count: Integer;
  begin
    Count := TargetQuantity(Context, Entity);
    if Count <= 0 then
      Error(SourceErr);
    Entry.SecurityFiltering(SecurityFilter::Disallowed);
    for Index := 1 to Count do begin
      Entry.Get(SourceId, NodeCode, Index, NodeCode);
      Entry.TestField("Table Id", TableId);
      if not Registry.ExistsByIdentity(Entry) then
        Error(SourceErr);
      case Entity of
        Entity::Customer:
          begin
            Customer.GetBySystemId(Entry."Record SystemId");
            Customer.TestField(Blocked, Customer.Blocked::" ");
            if Delivery.Get(SourceId, NodeCode, Index, 'DELIVERY') then begin
              Delivery.TestField("Parent Entry Id", Entry."Entry Id");
              Delivery.TestField("Table Id", Database::"Ship-to Address");
              if not Registry.ExistsByIdentity(Delivery) then
                Error(SourceErr);
              Addresses.Add(Format(Delivery."Record SystemId", 0, 4));
            end;
          end;
        Entity::Vendor:
          begin
            Vendor.GetBySystemId(Entry."Record SystemId");
            Vendor.TestField(Blocked, Vendor.Blocked::" ");
          end;
        Entity::Item:
          begin
            Item.GetBySystemId(Entry."Record SystemId");
            Item.TestField(Blocked, false);
            Item.TestField(Type, Item.Type::Inventory);
            Unit.Get(Item."No.", Item."Base Unit of Measure");
            Unit.TestField("Qty. per Unit of Measure", 1);
            Vendor.Get(Item."Vendor No.");
            Relation.Get(Vendor."No.", Item."No.", '');
            Delivery.Reset();
            Delivery.SetRange("Run Id", SourceId);
            Delivery.SetRange("Node Code", 'VENDOR');
            Delivery.SetRange("Artifact Code", 'VENDOR');
            Delivery.SetRange("Record SystemId", Vendor.SystemId);
            if Delivery.IsEmpty() then
              Error(SourceErr);
          end;
      end;
      Ids.Add(Format(Entry."Record SystemId", 0, 4));
    end;
  end;

  procedure Validate(Context: JsonObject)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Binding: JsonObject;
    Current: JsonObject;
    SourceId: Guid;
    StoredText: Text;
    CurrentText: Text;
  begin
    if not Context.Get('masterDataSource', Token) then
      exit;
    if Contract.GetInteger(Context, 'generationKind') <> "BCSF Generation Kind"::Transactions.AsInteger() then
      Error(SourceErr);
    Binding := Token.AsObject();
    if Contract.GetInteger(Binding, 'version') = 2 then begin
      Current := CaptureExisting();
      Binding.WriteTo(StoredText);
      Current.WriteTo(CurrentText);
      if StoredText <> CurrentText then
        Error(DriftErr);
      exit;
    end;
    if Contract.GetInteger(Binding, 'version') <> 1 then
      Error(SourceErr);
    Evaluate(SourceId, Contract.GetText(Binding, 'sourceRunId'));
    Current := Capture(SourceId, Contract.GetCode(Context, 'profileCode'), CopyStr(Contract.GetText(Context, 'profileVersion'), 1, 20));
    Binding.WriteTo(StoredText);
    Current.WriteTo(CurrentText);
    if StoredText <> CurrentText then
      Error(SourceErr);
  end;

  procedure RunId(Context: JsonObject): Guid
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Id: Guid;
  begin
    if Context.Get('masterDataSource', Token) and not IsExistingPool(Context) then
      Evaluate(Id, Contract.GetText(Token.AsObject(), 'sourceRunId'))
    else
      Evaluate(Id, Contract.GetText(Context, 'runId'));
    exit(Id);
  end;

  procedure Quantity(Context: JsonObject; Entity: Enum "BCSF Entity Type"): Integer
  var
    Token: JsonToken;
    Ids: JsonToken;
    Name: Text;
  begin
    if Context.Get('masterDataSource', Token) then begin
      case Entity of
        Entity::Customer: Name := 'customers';
        Entity::Vendor: Name := 'vendors';
        Entity::Item: Name := 'items';
      end;
      if Name <> '' then begin
        Token.AsObject().Get(Name, Ids);
        exit(Ids.AsArray().Count());
      end;
    end;
    exit(TargetQuantity(Context, Entity));
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

  [IntegrationEvent(false, false)]
  local procedure OnCheckSource(SourceId: Guid; var Confirmed: Boolean)
  begin
  end;

  var
    EmptyPoolErr: Label 'Wholesale requires eligible customers and at least two suitable vendors with four valid inventory items each. Check posting setup and supplier relations.';
    LocationErr: Label 'No suitable non-bin location found for wholesale transactions.';
    DriftErr: Label 'The eligible master-data pool has changed since this run was planned. Start a new transactions run.';
    SourceErr: Label 'Select a confirmed wholesale master-data source in this company with matching profile version and intact customer, vendor and item identities.';
}
