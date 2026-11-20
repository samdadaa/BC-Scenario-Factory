#if BCSFTESTS
namespace BCScenarioFactory.Inventory.Tests;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

codeunit 90700 "BCSF Inventory Tests"
{
  Subtype = Test;

  [Test]
  procedure ItemVendorLookupUsesActualStandardPrimaryKey()
  var
    TempSupplier: Record "Item Vendor" temporary;
    Relations: Codeunit "BCSF Item Relations";
  begin
    TempSupplier.Init();
    TempSupplier."Vendor No." := 'VENDOR-000018';
    TempSupplier."Item No." := 'ITEM-000001';
    TempSupplier.Insert();
    TempSupplier.Init();
    TempSupplier."Vendor No." := 'VENDOR-000018';
    TempSupplier."Item No." := 'ITEM-000001';
    TempSupplier."Variant Code" := 'ROT';
    TempSupplier.Insert();
    Relations.GetItemVendor(TempSupplier, 'VENDOR-000018', 'ITEM-000001', '');
    TempSupplier.TestField("Vendor No.", 'VENDOR-000018');
    TempSupplier.TestField("Item No.", 'ITEM-000001');
    Relations.GetItemVendor(TempSupplier, 'VENDOR-000018', 'ITEM-000001', 'ROT');
    TempSupplier.TestField("Variant Code", 'ROT');
  end;

  [Test]
  procedure CatalogIsDeterministicAcrossRunsAndOrder()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Context: JsonObject;
    Values: JsonObject;
    Again: JsonObject;
    First: Text;
    Second: Text;
    Index: Integer;
  begin
    Context := ContextFixture();
    Values := Catalog.BuildValues(Context, 3);
    Values.WriteTo(First);
    for Index := 100 downto 1 do
      Catalog.BuildValues(Context, Index);
    Context.Replace('runId', Format(CreateGuid(), 0, 4));
    Again := Catalog.BuildValues(Context, 3);
    Again.WriteTo(Second);
    Assert(First = Second, 'Catalog depends on execution order or run identity.');
  end;

  [Test]
  procedure SubstitutionCandidatesHaveSameDiameterAndMaterial()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    First: JsonObject;
    Second: JsonObject;
  begin
    First := Catalog.BuildValues(ContextFixture(), 1);
    Second := Catalog.BuildValues(ContextFixture(), 2);
    Assert(Contract.GetText(First, 'diameter') = Contract.GetText(Second, 'diameter'), 'Substitution diameter differs.');
    Assert(Contract.GetText(First, 'material') = Contract.GetText(Second, 'material'), 'Substitution material differs.');
    Assert(Contract.GetText(First, 'description') <> Contract.GetText(Second, 'description'), 'Two distinct assortment items are required.');
  end;

  [Test]
  procedure ProfilesShareAssortmentButDifferInBinMode()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Context: JsonObject;
    First: JsonObject;
    Second: JsonObject;
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Context := ContextFixture();
    First := Catalog.BuildValues(Context, 3);
    Context.Replace('profileCode', 'TECH-BINS');
    Second := Catalog.BuildValues(Context, 3);
    Assert(Contract.GetText(First, 'description') = Contract.GetText(Second, 'description'), 'Operating mode must not change the assortment.');
    Assert(not Catalog.UsesBins('TECH-TRADE') and Catalog.UsesBins('TECH-BINS'), 'Bin operating mode is not explicit.');
  end;

  [Test]
  procedure DependenciesDeclareGeneratedPartners()
  var
    Generator: Codeunit "BCSF Inventory Generator";
    Context: JsonObject;
    Settings: JsonObject;
    Dependencies: JsonArray;
  begin
    Context := ContextFixture();
    Settings.Add('version', 1);
    Settings.Add('generatedVendors', true);
    Context.Add('itemSetup', Settings);
    Generator.GetDependencies(Context, ItemTarget(), Dependencies);
    Assert(Dependencies.Count() = 2, 'Both supplied vendor and customer predecessor targets are required.');
  end;

  [Test]
  procedure UnsupportedProfileAndSettingVersionAreBlocked()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Setup: Codeunit "BCSF Item Setup";
    Context: JsonObject;
    Settings: JsonObject;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'UNSUPPORTED');
    asserterror Catalog.BuildValues(Context, 1);
    Settings.Add('version', 99);
    Context.Add('itemSetup', Settings);
    asserterror Setup.ReadSettings(Context);
  end;

  [Test]
  procedure DirectExecutionWithoutOwnedRunCannotCreateItems()
  var
    Item: Record Item;
    Generator: Codeunit "BCSF Inventory Generator";
    Batch: JsonObject;
    Result: JsonObject;
    CountBefore: Integer;
  begin
    CountBefore := Item.Count();
    Batch.Add('batchKey', 'ITEM:1:3');
    Batch.Add('firstKey', 1);
    Batch.Add('lastKey', 3);
    asserterror Generator.ExecuteBatch(ContextFixture(), ItemTarget(), Batch, Result);
    Assert(CountBefore = Item.Count(), 'Rejected execution created an item.');
  end;

  [Test]
  procedure ReferenceRunAndAllCheckpointRelationshipsAreValid()
  var
    Header: Record "BCSF Run Header";
    Batch: Record "BCSF Batch";
    Entry: Record "BCSF Generated Record";
    Recovery: Codeunit "BCSF Batch Recovery";
  begin
    RequireRun('TECH-TRADE', Header);
    Entry.SetRange("Run Id", Header."Run Id");
    Entry.SetRange("Artifact Code", 'ITEM');
    Assert(Entry.Count() = 8, 'Reference run must contain eight primary items.');
    Batch.SetRange("Run Id", Header."Run Id");
    Batch.FindSet();
    repeat
      Batch.TestField(Status, Batch.Status::Completed);
      Recovery.VerifyCheckpoint(Batch."Batch Id");
    until Batch.Next() = 0;
  end;

  [Test]
  procedure BinAndNonBinRunsHaveOnlyRequestedAssignments()
  var
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
  begin
    RequireRun('TECH-TRADE', Header);
    Entry.SetRange("Run Id", Header."Run Id");
    Entry.SetRange("Table Id", Database::Bin);
    Assert(Entry.IsEmpty(), 'Non-bin profile created bins.');
    RequireRun('TECH-BINS', Header);
    Entry.SetRange("Run Id", Header."Run Id");
    Assert(Entry.Count() = 2, 'Bin profile must create two selected bins.');
    Entry.SetRange("Table Id", Database::"Bin Content");
    Assert(Entry.Count() = 2, 'Bin profile must create two fixed assignments.');
    Entry.SetRange("Table Id", Database::"Stockkeeping Unit");
    Assert(Entry.Count() = 1, 'SKU creation must be selective.');
  end;

  [Test]
  procedure ReferenceMasterDataDoesNotCreateLedgerMovements()
  var
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    Item: Record Item;
    ItemEntry: Record "Item Ledger Entry";
    ValueEntry: Record "Value Entry";
    ApplicationEntry: Record "Item Application Entry";
    WarehouseEntry: Record "Warehouse Entry";
  begin
    RequireRun('TECH-BINS', Header);
    Entry.SetRange("Run Id", Header."Run Id");
    Entry.SetRange("Artifact Code", 'ITEM');
    Entry.FindSet();
    repeat
      Item.GetBySystemId(Entry."Record SystemId");
      ItemEntry.SetRange("Item No.", Item."No.");
      ValueEntry.SetRange("Item No.", Item."No.");
      ApplicationEntry.SetRange("Item No.", Item."No.");
      WarehouseEntry.SetRange("Item No.", Item."No.");
      Assert(ItemEntry.IsEmpty() and ValueEntry.IsEmpty() and ApplicationEntry.IsEmpty() and WarehouseEntry.IsEmpty(), 'Master data created ledger movements.');
      Item.CalcFields(Inventory);
      Item.TestField(Inventory, 0);
    until Entry.Next() = 0;
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure MissingLocationPostingCombinationIsConcreteBlocker()
  var
    Header: Record "BCSF Run Header";
    Posting: Record "Inventory Posting Setup";
    Manager: Codeunit "BCSF Scenario Manager";
    Setup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Settings: JsonObject;
    LocationCode: Code[10];
    ErrorText: Text;
  begin
    RequireRun('TECH-TRADE', Header);
    Manager.ReadSnapshot(Header."Run Id", Context);
    Settings := Setup.ReadSettings(Context);
    LocationCode := CopyStr(Contract.GetCode(Settings, 'location'), 1, 10);
    Posting.Get(LocationCode, Contract.GetCode(Settings, 'inventoryGroup'));
    Posting.Delete(true);
    asserterror Setup.CheckSetup(Context, ItemTarget());
    ErrorText := GetLastErrorText();
    Assert(StrPos(ErrorText, LocationCode) > 0, 'Blocker must identify the exact location.');
    Assert(StrPos(ErrorText, Contract.GetCode(Settings, 'inventoryGroup')) > 0, 'Blocker must identify the exact inventory group.');
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompletedRunCannotBeReplayed()
  var
    Header: Record "BCSF Run Header";
    Item: Record Item;
    Recovery: Codeunit "BCSF Batch Recovery";
    CountBefore: Integer;
  begin
    RequireRun('TECH-TRADE', Header);
    CountBefore := Item.Count();
    asserterror Recovery.ResumeRun(Header."Run Id");
    Assert(Item.Count() = CountBefore, 'Rejected replay changed item count.');
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure PurchaseReferenceAndSalesVariantResolveStandardUnits()
  var
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    Reference: Record "Item Reference";
    Customer: Record Customer;
    PurchaseHeader: Record "Purchase Header";
    PurchaseLine: Record "Purchase Line";
    SalesHeader: Record "Sales Header";
    SalesLine: Record "Sales Line";
    Item: Record Item;
  begin
    RequireRun('TECH-TRADE', Header);
    Entry.Get(Header."Run Id", 'ITEM', 3, 'VARIANT-REF');
    Reference.GetBySystemId(Entry."Record SystemId");
    PurchaseHeader.Init();
    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
    PurchaseHeader.Insert(true);
    PurchaseHeader.Validate("Buy-from Vendor No.", Reference."Reference Type No.");
    PurchaseHeader.Modify(true);
    Entry.Get(Header."Run Id", 'ITEM', 1, 'SUPPLIER1');
    Reference.GetBySystemId(Entry."Record SystemId");
    PurchaseLine.Init();
    PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
    PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
    PurchaseLine."Line No." := 10000;
    PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
    PurchaseLine.Validate("Item Reference No.", Reference."Reference No.");
    PurchaseLine.Validate(Quantity, 1);
    PurchaseLine.Insert(true);
    Assert(PurchaseLine."No." = Reference."Item No.", 'Vendor reference did not resolve item.');
    Assert(PurchaseLine."Quantity (Base)" = 24, 'One carton must resolve to 24 pieces.');
    Entry.Get(Header."Run Id", 'CUSTOMER', 1, 'CUSTOMER');
    Customer.GetBySystemId(Entry."Record SystemId");
    SalesHeader.Init();
    SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
    SalesHeader.Insert(true);
    SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
    SalesHeader.Modify(true);
    Entry.Get(Header."Run Id", 'ITEM', 3, 'ITEM');
    Item.GetBySystemId(Entry."Record SystemId");
    SalesLine.Init();
    SalesLine.Validate("Document Type", SalesHeader."Document Type");
    SalesLine.Validate("Document No.", SalesHeader."No.");
    SalesLine."Line No." := 10000;
    SalesLine.Validate(Type, SalesLine.Type::Item);
    SalesLine.Validate("No.", Item."No.");
    SalesLine.Validate("Variant Code", 'ROT');
    SalesLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
    SalesLine.Validate(Quantity, 2);
    SalesLine.Insert(true);
    Assert((SalesLine."Variant Code" = 'ROT') and (SalesLine."Quantity (Base)" = 2), 'Variant/piece resolution failed.');
  end;

  local procedure RequireRun(Profile: Code[20]; var Header: Record "BCSF Run Header")
  var
    Execution: Record "BCSF Run Execution";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    Header.SetCurrentKey("Created At", "Run Id");
    Header.SetRange("Profile Code", Profile);
    if Header.FindLast() then
      repeat
        if Execution.Get(Header."Run Id") then
          if Execution.Status = Execution.Status::Completed then
            exit;
      until Header.Next(-1) = 0;
    Error('First complete the documented fresh eight-item reference run for profile %1 in the approved sandbox.', Profile);
  end;

  local procedure ContextFixture(): JsonObject
  var
    Context: JsonObject;
    Targets: JsonArray;
    Target: JsonObject;
  begin
    Context.Add('schemaVersion', 1);
    Context.Add('runId', Format(CreateGuid(), 0, 4));
    Context.Add('companyName', CompanyName());
    Context.Add('dataLanguage', 1);
    Context.Add('seed', 1901);
    Context.Add('profileCode', 'TECH-TRADE');
    Context.Add('profileVersion', '1');
    Context.Add('processMode', 0);
    Context.Add('nameCatalogVersion', 1);
    Context.Add('seedEngineVersion', 1);
    Context.Add('batchSize', 3);
    Context.Add('maximumBatchSize', 1000);
    Context.Add('maximumRecordsPerEntity', 100000);
    Target.Add('entity', 1);
    Target.Add('quantity', 2);
    Targets.Add(Target);
    Clear(Target);
    Target.Add('entity', 0);
    Target.Add('quantity', 1);
    Targets.Add(Target);
    Context.Add('targets', Targets);
    exit(Context);
  end;

  local procedure ItemTarget(): JsonObject
  var
    Target: JsonObject;
  begin
    Target.Add('entityCode', 'ITEM');
    Target.Add('moduleCode', 'INVENTORY');
    Target.Add('quantity', 8);
    Target.Add('processMode', 0);
    exit(Target);
  end;

  local procedure Assert(Condition: Boolean; MessageText: Text)
  begin
    if not Condition then
      Error(MessageText);
  end;
}
#endif
