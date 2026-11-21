namespace BCScenarioFactory.Purchasing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
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
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
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
    Capabilities."Maximum Mode" := "BCSF Process Mode"::UnpostedDocuments;
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
    Settings.Add('version', 1);
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
    ItemSetup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Numbers: Codeunit "No. Series";
    Token: JsonToken;
    Settings: JsonObject;
    DateFrom: Date;
    DateTo: Date;
  begin
    Contract.CheckTarget(Context, Target);
    if (Contract.GetCode(Target, 'entityCode') <> 'PURCHASE.ORDER') or
      (Contract.GetCode(Target, 'moduleCode') <> 'PURCHASING') or
      (Contract.GetInteger(Target, 'processMode') <> 1) then
      Error(SetupErr);
    if not Context.Get('purchaseSetup', Token) then
      Error(SetupErr);
    Settings := Token.AsObject();
    if (Contract.GetInteger(Settings, 'version') <> 1) or
      (ItemSetup.Quantity(Context, "BCSF Entity Type"::Vendor) < 2) or
      (ItemSetup.Quantity(Context, "BCSF Entity Type"::Item) < 1) then
      Error(SetupErr);
    Purchases.Get();
    Purchases.TestField("Order Nos.", Contract.GetText(Settings, 'orderSeries'));
    Purchases.TestField("Invoice Rounding", false);
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

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  var
    Requirement: JsonObject;
  begin
    Clear(Dependencies);
    Requirement.Add('entityCode', 'VENDOR');
    Requirement.Add('moduleCode', 'PURCHASING');
    Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
    Requirement.Add('minimumMode', 1);
    Requirement.Add('maximumMode', 1);
    Dependencies.Add(Requirement);
    Clear(Requirement);
    Requirement.Add('entityCode', 'ITEM');
    Requirement.Add('moduleCode', 'INVENTORY');
    Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
    Requirement.Add('minimumMode', 1);
    Requirement.Add('maximumMode', 1);
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
    ItemKey: Integer;
  begin
    // Follow each generated item's actual primary supplier, never an unrelated random vendor.
    ItemKey := 1 + ((LogicalKey - 1) mod ItemSetup.Quantity(Context, "BCSF Entity Type"::Item));
    Entry.SecurityFiltering(SecurityFilter::Disallowed);
    Entry.Get(RunId, 'ITEM', ItemKey, 'ITEM');
    Entry.TestField("Table Id", Database::Item);
    if not Registry.ExistsByIdentity(Entry) then
      Error(ResultErr);
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    Item.GetBySystemId(Entry."Record SystemId");
    Vendor.SecurityFiltering(SecurityFilter::Disallowed);
    Vendor.Get(Item."Vendor No.");
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

  local procedure CreateOrder(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer)
  var
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    Vendor: Record Vendor;
    Item: Record Item;
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    ItemVendor: Record "Item Vendor";
    Registry: Codeunit "BCSF Record Registry";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Contract: Codeunit "BCSF Contract JSON";
    Dimensions: Codeunit DimensionManagement;
    Token: JsonToken;
    NoParent: Guid;
    Date: Date;
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
    Date := Coordinator.DocumentDate(Context, 'PURCHASE.ORDER', LogicalKey);
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
    Header.Modify(true);
    Line.Init();
    Line.Validate("Document Type", Header."Document Type");
    Line.Validate("Document No.", Header."No.");
    Line.Validate("Line No.", 10000);
    Line.Insert(true);
    Line.Validate(Type, Line.Type::Item);
    Line.Validate("No.", Item."No.");
    Line.Validate("Location Code", Header."Location Code");
    Line.Validate("Unit of Measure Code", Item."Base Unit of Measure");
    Line.Validate(Quantity, Coordinator.Quantity(Context, 'PURCHASE.ORDER', LogicalKey));
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
    Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT', BatchId, Header.RecordId(), NoParent);
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    Item: Record Item;
    Vendor: Record Vendor;
    Contract: Codeunit "BCSF Contract JSON";
    Coordinator: Codeunit "BCSF Process Coordinator";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    Count: Integer;
    Token: JsonToken;
  begin
    Clear(Findings);
    Contract.CheckBatch(Context, Target, Batch);
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Evaluate(BatchId, Contract.GetText(Context, 'batchId'));
    Context.Get('purchaseSetup', Token);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      Entry.Get(RunId, 'PURCHASE.ORDER', LogicalKey, 'DOCUMENT');
      Entry.TestField("Batch Id", BatchId);
      Entry.TestField("Table Id", Database::"Purchase Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::Order);
      Header.TestField("Location Code", Contract.GetText(Token.AsObject(), 'location'));
      Header.TestField("Posting Date", Coordinator.DocumentDate(Context, 'PURCHASE.ORDER', LogicalKey));
      Sources(Context, RunId, LogicalKey, Item, Vendor);
      Header.TestField("Buy-from Vendor No.", Vendor."No.");
      Line.Get(Header."Document Type", Header."No.", 10000);
      Line.TestField(Type, Line.Type::Item);
      Line.TestField("No.", Item."No.");
      Line.TestField("Unit of Measure Code", Item."Base Unit of Measure");
      Line.TestField(Quantity, Coordinator.Quantity(Context, 'PURCHASE.ORDER', LogicalKey));
      Line.TestField("Quantity Received", 0);
      Line.TestField("Quantity Invoiced", 0);
      Count += 1;
    end;
    if (Count <> Contract.GetInteger(Result, 'processedUnits')) or (Count <> Contract.GetInteger(Result, 'createdRecords')) then
      Error(ResultErr);
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(ResultErr);
  end;

  var
    NameLbl: Label 'Unposted Purchase Orders';
    SetupErr: Label 'Purchase orders require unposted mode, two vendors and items from this run, a simple location and valid captured purchase numbering.';
    PermissionErr: Label 'Read or write permission is missing for %1. Review standard purchase permissions.', Comment = '%1 = table caption';
    ResultErr: Label 'The purchase order or its source relationship is missing, changed or already recorded. Review the batch; uncertain work is not repeated.';
}
