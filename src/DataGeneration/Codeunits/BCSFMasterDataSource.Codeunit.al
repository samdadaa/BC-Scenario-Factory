namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
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
    Binding := Capture(Scenario."Master Source Run Id", Scenario."Profile Code", Scenario."Profile Version");
    Manager.ReadSnapshot(Scenario."Master Source Run Id", Context);
    Context.Get('itemSetup', Token);
    InventorySettings := Contract.Clone(Token.AsObject());
    InventorySettings.Add('sourceRunId', Format(Scenario."Master Source Run Id", 0, 4));
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
    if Context.Get('masterDataSource', Token) then
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
    SourceErr: Label 'Select a confirmed wholesale master-data source in this company with matching profile version and intact customer, vendor and item identities.';
}
