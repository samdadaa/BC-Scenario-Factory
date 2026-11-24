namespace BCScenarioFactory.Warehouse;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

/// <summary>
/// Warehouse process (module Warehouse): inbound receipt and put-away with bins, for standard-posted purchases of the same run.
/// Per purchase invoice (about 20 %) a purchase order for the same vendor and one invoiced item is received at the synthetic
/// location BCSF-WMS (receipt and put-away required, bins mandatory) through the standard warehouse receipt, and the put-away
/// is registered into a storage bin. Posting stays in the standard codeunits; there are no direct warehouse entries.
/// The location, its bins and the inventory posting setup are additive; existing locations are never changed. Cases without
/// warehouse number series, vendor/posting setup or permission are skipped before any write (SOURCE).
/// Pick, shipment and directed put-and-pick locations are not part of this module.
/// </summary>
codeunit 90489 "BCSF Warehouse Processor"
{
  Access = Internal;

  procedure LocationCode(): Code[10]
  begin
    exit('BCSF-WMS');
  end;

  procedure ReceiptBin(): Code[20]
  begin
    exit('RECEIVE');
  end;

  procedure StorageBin(): Code[20]
  begin
    exit('A-01');
  end;

  /// <summary>Additive marker: the module is offered only when the warehouse number series and the synthetic location are usable.</summary>
  procedure AddSettings(var Settings: JsonObject)
  begin
    if not SetupUsable() then
      exit;
    Settings.Add('warehouseVersion', 1);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'warehouseVersion'));
  end;

  local procedure SetupUsable(): Boolean
  var
    WarehouseSetup: Record "Warehouse Setup";
    Location: Record Location;
    PostingSetup: Record "Inventory Posting Setup";
    Bin: Record Bin;
  begin
    if not WarehouseSetup.Get() then
      exit(false);
    if (WarehouseSetup."Whse. Receipt Nos." = '') or (WarehouseSetup."Posted Whse. Receipt Nos." = '') or
      (WarehouseSetup."Whse. Put-away Nos." = '') or (WarehouseSetup."Registered Whse. Put-away Nos." = '')
    then
      exit(false);
    if not Location.Get(LocationCode()) then
      exit(false);
    if not (Location."Require Receive" and Location."Require Put-away" and Location."Bin Mandatory") or
      Location."Directed Put-away and Pick" or Location."Require Pick" or Location."Require Shipment" or
      (Location."Receipt Bin Code" <> ReceiptBin())
    then
      exit(false);
    if not Bin.Get(LocationCode(), ReceiptBin()) or not Bin.Get(LocationCode(), StorageBin()) then
      exit(false);
    PostingSetup.SetRange("Location Code", LocationCode());
    exit(not PostingSetup.IsEmpty());
  end;

  /// <summary>Additive foundation: the synthetic warehouse location, two bins and its inventory posting setup. Existing records stay unchanged.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure PrepareFoundation()
  var
    Location: Record Location;
    Bin: Record Bin;
    PostingSetup: Record "Inventory Posting Setup";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    // Optional stage: without write permission the module is simply not offered.
    if not Location.WritePermission() or not Bin.WritePermission() or not PostingSetup.WritePermission() then
      exit;
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    if not Location.Get(LocationCode()) then begin
      Location.Init();
      Location.Code := LocationCode();
      Location.Validate(Name, LocationLbl);
      Location.Insert(true);
      EnsureBin(ReceiptBin());
      EnsureBin(StorageBin());
      Location.Validate("Require Receive", true);
      Location.Validate("Require Put-away", true);
      Location.Validate("Bin Mandatory", true);
      Location.Validate("Receipt Bin Code", ReceiptBin());
      Location.Validate("Default Bin Code", StorageBin());
      Location.Modify(true);
    end;
    EnsureInventoryPostingSetup();
  end;

  local procedure EnsureBin(BinCode: Code[20])
  var
    Bin: Record Bin;
  begin
    if Bin.Get(LocationCode(), BinCode) then
      exit;
    Bin.Init();
    Bin."Location Code" := LocationCode();
    Bin.Code := BinCode;
    Bin.Description := CopyStr(BinLbl, 1, MaxStrLen(Bin.Description));
    Bin.Insert(true);
  end;

  local procedure EnsureInventoryPostingSetup()
  var
    InventoryGroup: Record "Inventory Posting Group";
    Setup: Record "Inventory Posting Setup";
    Source: Record "Inventory Posting Setup";
  begin
    InventoryGroup.SecurityFiltering(SecurityFilter::Disallowed);
    if InventoryGroup.FindSet() then
      repeat
        if not Setup.Get(LocationCode(), InventoryGroup.Code) then begin
          Source.Reset();
          Source.SetRange("Invt. Posting Group Code", InventoryGroup.Code);
          Source.SetFilter("Inventory Account", '<>%1', '');
          if Source.FindFirst() then begin
            Setup.Init();
            Setup.TransferFields(Source, false);
            Setup."Location Code" := LocationCode();
            Setup."Invt. Posting Group Code" := InventoryGroup.Code;
            Setup.Insert(true);
          end;
        end;
      until InventoryGroup.Next() = 0;
  end;

  /// <summary>Deterministic: 0 no warehouse process for this invoice, 1 receipt and put-away (20 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'WHSE-PLAN', 1, 100) <= 20 then
      exit(1);
    exit(0);
  end;

  /// <summary>One to three units; reproducible by the validator.</summary>
  procedure Units(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Decimal
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'WHSE-UNITS', 1, 3));
  end;

  /// <summary>First invoiced item without tracking or variants that can be purchased from the vendor of the invoice.</summary>
  local procedure SourceItem(Invoice: Record "Purch. Inv. Header"; var Item: Record Item; var Vendor: Record Vendor): Boolean
  var
    InvoiceLine: Record "Purch. Inv. Line";
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Variant: Record "Item Variant";
  begin
    if not Vendor.Get(Invoice."Buy-from Vendor No.") or (Vendor.Blocked <> Vendor.Blocked::" ") then
      exit(false);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      exit(false);
    repeat
      if Item.Get(InvoiceLine."No.") then
        if not Item.Blocked and not Item."Purchasing Blocked" and (Item.Type = Item.Type::Inventory) and (Item."Item Tracking Code" = '') then begin
          Variant.SetRange("Item No.", Item."No.");
          if Variant.IsEmpty() and General.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group") and
            VAT.Get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group")
          then
            if not General.Blocked and not VAT.Blocked then
              exit(true);
        end;
    until InvoiceLine.Next() = 0;
    exit(false);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Item: Record Item;
    Vendor: Record Vendor;
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    ReceiptLine: Record "Warehouse Receipt Line";
    ActivityLine: Record "Warehouse Activity Line";
    ActivityHeader: Record "Warehouse Activity Header";
    Receipt: Record "Purch. Rcpt. Header";
    Registered: Record "Registered Whse. Activity Hdr.";
    Registry: Codeunit "BCSF Record Registry";
    ReleaseDoc: Codeunit "Release Purchase Document";
    GetSource: Codeunit "Get Source Doc. Inbound";
    PostReceipt: Codeunit "Whse.-Post Receipt";
    PutAwayRegister: Codeunit "Whse.-Activity-Register";
    Quantity: Decimal;
    PutAwayNo: Code[20];
    SkipReason: Code[30];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    // Read-only preflight before any write.
    if not SetupUsable() or not SourceItem(Invoice, Item, Vendor) or not Header.WritePermission() or
      not ReceiptLine.WritePermission() or not EnsureEmployee(false)
    then
      SkipReason := 'SOURCE';
    if SkipReason <> '' then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'WHSE-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
      exit;
    end;
    EnsureEmployee(true);
    Quantity := Units(Context, NodeCode, LogicalKey);
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
    Header.Validate("Location Code", LocationCode());
    Header.Validate("Vendor Invoice No.", Header."No.");
    Header.Modify(true);
    Line.Init();
    Line.Validate("Document Type", Header."Document Type");
    Line.Validate("Document No.", Header."No.");
    Line.Validate("Line No.", 10000);
    Line.Insert(true);
    Line.Validate(Type, Line.Type::Item);
    Line.Validate("No.", Item."No.");
    Line.Validate("Location Code", LocationCode());
    Line.Validate("Unit of Measure Code", Item."Base Unit of Measure");
    Line.Validate(Quantity, Quantity);
    Line.Validate("Direct Unit Cost", Item."Unit Cost");
    Line.Modify(true);
    ReleaseDoc.PerformManualRelease(Header);
    if not GetSource.CreateFromPurchOrderHideDialog(Header) then
      Error(ResultErr);
    ReceiptLine.SetRange("Source Type", Database::"Purchase Line");
    ReceiptLine.SetRange("Source No.", Header."No.");
    ReceiptLine.FindFirst();
    ReceiptLine.TestField("Item No.", Item."No.");
    ReceiptLine.TestField("Location Code", LocationCode());
    ReceiptLine.TestField("Qty. to Receive", Quantity);
    PostReceipt.SetSuppressCommit(true);
    PostReceipt.Run(ReceiptLine);
    // The standard receipt posting creates the put-away document of this receipt.
    ActivityHeader.SetRange(Type, ActivityHeader.Type::"Put-away");
    ActivityHeader.SetRange("Location Code", LocationCode());
    ActivityHeader.SetRange("Source No.", Header."No.");
    if not ActivityHeader.FindFirst() then
      Error(ResultErr);
    PutAwayNo := ActivityHeader."No.";
    ActivityLine.SetRange("Activity Type", ActivityLine."Activity Type"::"Put-away");
    ActivityLine.SetRange("No.", PutAwayNo);
    ActivityLine.SetRange("Action Type", ActivityLine."Action Type"::Place);
    if not ActivityLine.FindSet(true) then
      Error(ResultErr);
    repeat
      if ActivityLine."Bin Code" = '' then
        ActivityLine.Validate("Bin Code", StorageBin());
      ActivityLine.Validate("Qty. to Handle", ActivityLine.Quantity);
      ActivityLine.Modify(true);
    until ActivityLine.Next() = 0;
    ActivityLine.SetRange("Action Type");
    ActivityLine.FindFirst();
    PutAwayRegister.SetSuppressCommit(true);
    PutAwayRegister.Run(ActivityLine);
    Receipt.SetRange("Order No.", Header."No.");
    Receipt.FindFirst();
    Registered.SetRange(Type, Registered.Type::"Put-away");
    Registered.SetRange("Whse. Activity No.", PutAwayNo);
    Registered.FindFirst();
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'WHSE-RECEIPT', BatchId, Receipt.RecordId(), ParentId);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'WHSE-PUTAWAY', BatchId, Registered.RecordId(), ParentId);
  end;

  /// <summary>
  /// The warehouse employee of the running user for the synthetic location. Read-only check, or additive creation
  /// restricted to the synthetic location. Returns false when it is missing and cannot be created.
  /// </summary>
  local procedure EnsureEmployee(Create: Boolean): Boolean
  var
    Employee: Record "Warehouse Employee";
  begin
    if Employee.Get(UserId(), LocationCode()) then
      exit(true);
    if not Create then
      exit(Employee.WritePermission());
    Employee.Init();
    Employee."User ID" := CopyStr(UserId(), 1, MaxStrLen(Employee."User ID"));
    Employee."Location Code" := LocationCode();
    Employee.Insert(true);
    exit(true);
  end;

  /// <summary>Read-only validation: posted receipt, registered put-away and warehouse entries at the synthetic location match the plan.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header")
  var
    Entry: Record "BCSF Generated Record";
    Receipt: Record "Purch. Rcpt. Header";
    ReceiptLine: Record "Purch. Rcpt. Line";
    Registered: Record "Registered Whse. Activity Hdr.";
    WarehouseEntry: Record "Warehouse Entry";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'WHSE*');
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'WHSE-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Purch. Inv. Header");
      if Entry."Skip Reason Code" <> 'SOURCE' then
        Error(ResultErr);
      exit;
    end;
    Entry.SetRange("Artifact Code", 'WHSE-RECEIPT');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Purch. Rcpt. Header");
    Receipt.GetBySystemId(Entry."Record SystemId");
    Receipt.TestField("Location Code", LocationCode());
    Receipt.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    ReceiptLine.SetRange("Document No.", Receipt."No.");
    ReceiptLine.SetRange(Type, ReceiptLine.Type::Item);
    ReceiptLine.FindFirst();
    ReceiptLine.TestField(Quantity, Units(Context, NodeCode, LogicalKey));
    Entry.SetRange("Artifact Code", 'WHSE-PUTAWAY');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Registered Whse. Activity Hdr.");
    Registered.GetBySystemId(Entry."Record SystemId");
    Registered.TestField("Location Code", LocationCode());
    // The put-away moved the received quantity into the storage bin.
    WarehouseEntry.SetRange("Location Code", LocationCode());
    WarehouseEntry.SetRange("Bin Code", StorageBin());
    WarehouseEntry.SetRange("Item No.", ReceiptLine."No.");
    WarehouseEntry.SetFilter(Quantity, '>0');
    if WarehouseEntry.IsEmpty() then
      Error(ResultErr);
  end;

  var
    LocationLbl: Label 'Scenario Factory warehouse';
    BinLbl: Label 'Scenario Factory bin';
    ResultErr: Label 'Warehouse results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
