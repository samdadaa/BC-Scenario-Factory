namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

/// <summary>
/// Return orders for standard-posted sales and purchase invoices of the same run, in the approved follow-up stage.
/// Plan kinds: 0 none, 1 open return order, 2 posted return order (return receipt or return shipment and credit memo, partial quantity).
/// Sales returns restock the sold items; purchase returns ship one unit back and are only posted when enough free stock remains.
/// Returns are not applied to the invoice, so the payment plan and its exact remaining amounts stay valid.
/// Cases without return number series or stock are skipped before any write (SOURCE, STOCK).
/// </summary>
codeunit 90492 "BCSF Return Processor"
{
  Access = Internal;

  /// <summary>Additive marker: returns are offered when the return number series of both areas exist.</summary>
  procedure AddSettings(var Settings: JsonObject)
  begin
    if SetupUsable(true) and SetupUsable(false) then
      Settings.Add('returnVersion', 1);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'returnVersion'));
  end;

  procedure SetupUsable(Sales: Boolean): Boolean
  var
    SalesSetup: Record "Sales & Receivables Setup";
    PurchaseSetup: Record "Purchases & Payables Setup";
  begin
    if Sales then begin
      if not SalesSetup.Get() then
        exit(false);
      exit((SalesSetup."Return Order Nos." <> '') and (SalesSetup."Posted Return Receipt Nos." <> '') and
        (SalesSetup."Credit Memo Nos." <> '') and (SalesSetup."Posted Credit Memo Nos." <> ''));
    end;
    if not PurchaseSetup.Get() then
      exit(false);
    exit((PurchaseSetup."Return Order Nos." <> '') and (PurchaseSetup."Posted Return Shpt. Nos." <> '') and
      (PurchaseSetup."Credit Memo Nos." <> '') and (PurchaseSetup."Posted Credit Memo Nos." <> ''));
  end;

  /// <summary>Deterministic plan from the seed (about 12 % of the invoices); independent of run id and batch order.</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    Roll: Integer;
  begin
    Roll := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'RETURN-PLAN', 1, 100);
    if Roll <= 88 then
      exit(0);
    if Roll <= 94 then
      exit(1);
    exit(2);
  end;

  procedure ReturnDate(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; InvoiceDate: Date): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    EndingDate: Date;
  begin
    if Contract.GetDatePolicyVersion(Context) = 0 then
      exit(InvoiceDate);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(Seed.SampleDate(Context, NodeCode, Format(LogicalKey, 0, 9), 'RETURN-DATE', InvoiceDate, EndingDate, false));
  end;

  /// <summary>Whole units: sales returns half of the invoiced quantity (rounded up), purchase returns one unit.</summary>
  procedure ReturnQuantity(InvoicedQuantity: Decimal; Sales: Boolean): Decimal
  var
    Quantity: Decimal;
  begin
    Quantity := 1;
    if Sales then
      Quantity := Round(InvoicedQuantity / 2, 1, '>');
    if Quantity > InvoicedQuantity then
      Quantity := InvoicedQuantity;
    exit(Quantity);
  end;

  local procedure CheckDimensions(DimensionSetId: Integer)
  var
    Dimensions: Codeunit DimensionManagement;
  begin
    if not Dimensions.CheckDimIDComb(DimensionSetId) then
      Error(DimensionErr);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; ParentId: Guid)
  var
    Header: Record "Sales Header";
    Line: Record "Sales Line";
    InvoiceLine: Record "Sales Invoice Line";
    Credit: Record "Sales Cr.Memo Header";
    Shipment: Record "Sales Shipment Header";
    Posted: Record "Sales Invoice Header";
    Receipt: Record "Return Receipt Header";
    Registry: Codeunit "BCSF Record Registry";
    SalesPost: Codeunit "Sales-Post";
    Kind: Integer;
    Date: Date;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey);
    if Kind = 0 then
      exit;
    if not SetupUsable(true) or not Header.WritePermission() then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-SKIP', BatchId, Invoice.RecordId(), ParentId, 'SOURCE');
      exit;
    end;
    Date := ReturnDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      Error(ResultErr);
    Header.Init();
    Header.SetHideValidationDialog(true);
    Header."Document Type" := Header."Document Type"::"Return Order";
    Header."Posting Date" := Date;
    Header.Insert(true);
    Header.Validate("Sell-to Customer No.", Invoice."Sell-to Customer No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Location Code", InvoiceLine."Location Code");
    Header."External Document No." := CopyStr(Invoice."No.", 1, MaxStrLen(Header."External Document No."));
    Header.Modify(true);
    repeat
      Line.Init();
      Line.SetHideValidationDialog(true);
      Line.Validate("Document Type", Header."Document Type");
      Line.Validate("Document No.", Header."No.");
      Line.Validate("Line No.", InvoiceLine."Line No.");
      Line.Insert(true);
      Line.Validate(Type, Line.Type::Item);
      Line.Validate("No.", InvoiceLine."No.");
      Line.Validate("Location Code", InvoiceLine."Location Code");
      Line.Validate("Unit of Measure Code", InvoiceLine."Unit of Measure Code");
      Line.Validate(Quantity, ReturnQuantity(InvoiceLine.Quantity, true));
      Line.Validate("Unit Price", InvoiceLine."Unit Price");
      Line.Validate("Line Discount %", InvoiceLine."Line Discount %");
      CheckDimensions(Line."Dimension Set ID");
      Line.Modify(true);
    until InvoiceLine.Next() = 0;
    CheckDimensions(Header."Dimension Set ID");
    if Kind = 1 then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN', BatchId, Header.RecordId(), ParentId);
      exit;
    end;
    Header.Receive := true;
    Header.Invoice := true;
    SalesPost.SetSuppressCommit(true);
    // Public OnRun, no Boolean return value and therefore no implicit success commit.
    SalesPost.Run(Header);
    SalesPost.GetGlobaDocumentsHeaders(Shipment, Posted, Credit, Receipt);
    Credit.TestField("No.");
    Receipt.TestField("No.");
    Credit.TestField("Bill-to Customer No.", Invoice."Bill-to Customer No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN', BatchId, Receipt.RecordId(), ParentId);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-CREDIT', BatchId, Credit.RecordId(), ParentId);
    RegisterSalesEvidence(RunId, NodeCode, LogicalKey, BatchId, Credit, Receipt, ParentId);
  end;

  local procedure RegisterSalesEvidence(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Credit: Record "Sales Cr.Memo Header"; Receipt: Record "Return Receipt Header"; ParentId: Guid)
  var
    CustomerEntry: Record "Cust. Ledger Entry";
    ItemEntry: Record "Item Ledger Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    CustomerEntry.Get(Credit."Cust. Ledger Entry No.");
    CustomerEntry.TestField("Document No.", Credit."No.");
    CustomerEntry.TestField("Customer No.", Credit."Bill-to Customer No.");
    CustomerEntry.TestField("Document Type", CustomerEntry."Document Type"::"Credit Memo");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-ENTRY', BatchId, CustomerEntry.RecordId(), ParentId);
    RegisterLedgers(RunId, NodeCode, LogicalKey, BatchId, CustomerEntry."Transaction No.", Credit."No.", ParentId);
    ItemEntry.SetRange("Document No.", Receipt."No.");
    ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Sales Return Receipt");
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Customer);
    ItemEntry.SetRange("Source No.", Receipt."Sell-to Customer No.");
    RegisterItemTrail(RunId, NodeCode, LogicalKey, BatchId, ItemEntry, ParentId);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; ParentId: Guid)
  var
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    InvoiceLine: Record "Purch. Inv. Line";
    Credit: Record "Purch. Cr. Memo Hdr.";
    Shipment: Record "Return Shipment Header";
    Item: Record Item;
    Registry: Codeunit "BCSF Record Registry";
    PurchasePost: Codeunit "Purch.-Post";
    Kind: Integer;
    Date: Date;
    OrderNo: Code[20];
    Quantity: Decimal;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey);
    if Kind = 0 then
      exit;
    Date := ReturnDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      Error(ResultErr);
    if not SetupUsable(false) or not Header.WritePermission() then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-SKIP', BatchId, Invoice.RecordId(), ParentId, 'SOURCE');
      exit;
    end;
    if Kind = 2 then
      repeat
        // Read-only stock check: the returned unit must be free, and one more unit stays for later sales.
        Item.Get(InvoiceLine."No.");
        Item.SetRange("Location Filter", InvoiceLine."Location Code");
        Item.SetRange("Date Filter", 0D, Date);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        if Item.Inventory - Item."Reserved Qty. on Inventory" < ReturnQuantity(InvoiceLine.Quantity, false) + 1 then begin
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-SKIP', BatchId, Invoice.RecordId(), ParentId, 'STOCK');
          exit;
        end;
      until InvoiceLine.Next() = 0;
    InvoiceLine.FindSet();
    Header.Init();
    Header.SetHideValidationDialog(true);
    Header."Document Type" := Header."Document Type"::"Return Order";
    Header."Posting Date" := Date;
    Header.Insert(true);
    OrderNo := Header."No.";
    Header.Validate("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Location Code", InvoiceLine."Location Code");
    Header.Validate("Vendor Cr. Memo No.", Header."No.");
    Header.Modify(true);
    repeat
      Line.Init();
      Line.Validate("Document Type", Header."Document Type");
      Line.Validate("Document No.", Header."No.");
      Line.Validate("Line No.", InvoiceLine."Line No.");
      Line.Insert(true);
      Line.Validate(Type, Line.Type::Item);
      Line.Validate("No.", InvoiceLine."No.");
      Line.Validate("Location Code", InvoiceLine."Location Code");
      Line.Validate("Unit of Measure Code", InvoiceLine."Unit of Measure Code");
      Quantity := ReturnQuantity(InvoiceLine.Quantity, false);
      Line.Validate(Quantity, Quantity);
      Line.Validate("Direct Unit Cost", InvoiceLine."Direct Unit Cost");
      CheckDimensions(Line."Dimension Set ID");
      Line.Modify(true);
    until InvoiceLine.Next() = 0;
    CheckDimensions(Header."Dimension Set ID");
    if Kind = 1 then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN', BatchId, Header.RecordId(), ParentId);
      exit;
    end;
    Header.Ship := true;
    Header.Invoice := true;
    PurchasePost.SetSuppressCommit(true);
    PurchasePost.Run(Header);
    Credit.SetRange("Return Order No.", OrderNo);
    if Credit.Count() <> 1 then
      Error(ResultErr);
    Credit.FindFirst();
    Shipment.SetRange("Return Order No.", OrderNo);
    if Shipment.Count() <> 1 then
      Error(ResultErr);
    Shipment.FindFirst();
    Credit.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN', BatchId, Shipment.RecordId(), ParentId);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-CREDIT', BatchId, Credit.RecordId(), ParentId);
    RegisterPurchaseEvidence(RunId, NodeCode, LogicalKey, BatchId, Credit, Shipment, ParentId);
  end;

  local procedure RegisterPurchaseEvidence(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Credit: Record "Purch. Cr. Memo Hdr."; Shipment: Record "Return Shipment Header"; ParentId: Guid)
  var
    VendorEntry: Record "Vendor Ledger Entry";
    ItemEntry: Record "Item Ledger Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    VendorEntry.Get(Credit."Vendor Ledger Entry No.");
    VendorEntry.TestField("Document No.", Credit."No.");
    VendorEntry.TestField("Vendor No.", Credit."Pay-to Vendor No.");
    VendorEntry.TestField("Document Type", VendorEntry."Document Type"::"Credit Memo");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'RETURN-ENTRY', BatchId, VendorEntry.RecordId(), ParentId);
    RegisterLedgers(RunId, NodeCode, LogicalKey, BatchId, VendorEntry."Transaction No.", Credit."No.", ParentId);
    ItemEntry.SetRange("Document No.", Shipment."No.");
    ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Purchase Return Shipment");
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Vendor);
    ItemEntry.SetRange("Source No.", Shipment."Buy-from Vendor No.");
    RegisterItemTrail(RunId, NodeCode, LogicalKey, BatchId, ItemEntry, ParentId);
  end;

  local procedure RegisterLedgers(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; TransactionNo: Integer; DocumentNo: Code[20]; ParentId: Guid)
  var
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    GL.SetRange("Transaction No.", TransactionNo);
    GL.SetRange("Document No.", DocumentNo);
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", TransactionNo);
    VAT.SetRange("Document No.", DocumentNo);
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VAT', VAT."Entry No."), BatchId, VAT.RecordId(), ParentId);
      until VAT.Next() = 0;
  end;

  /// <summary>Item, value and linked G/L entries of the return receipt or shipment. The caller sets the filters.</summary>
  local procedure RegisterItemTrail(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; var ItemEntry: Record "Item Ledger Entry"; ParentId: Guid)
  var
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    GL: Record "G/L Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    if not ItemEntry.FindSet() then
      Error(ResultErr);
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ITEM', ItemEntry."Entry No."), BatchId, ItemEntry.RecordId(), ParentId);
      Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
      if Value.FindSet() then
        repeat
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VALUE', Value."Entry No."), BatchId, Value.RecordId(), ParentId);
          Relation.SetRange("Value Entry No.", Value."Entry No.");
          if Relation.FindSet() then
            repeat
              GL.Get(Relation."G/L Entry No.");
              Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
            until Relation.Next() = 0;
        until Value.Next() = 0;
    until ItemEntry.Next() = 0;
  end;

  /// <summary>Read-only validation against the sales invoice and the deterministic plan.</summary>
  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Sales Header";
    Receipt: Record "Return Receipt Header";
    ReceiptLine: Record "Return Receipt Line";
    InvoiceLine: Record "Sales Invoice Line";
    Line: Record "Sales Line";
    Kind: Integer;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey);
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'RETURN*');
    if Kind = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'RETURN-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Sales Invoice Header");
      if Entry."Skip Reason Code" <> 'SOURCE' then
        Error(ResultErr);
      exit;
    end;
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    Entry.SetRange("Artifact Code", 'RETURN');
    Entry.FindFirst();
    if Kind = 1 then begin
      Entry.TestField("Table Id", Database::"Sales Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::"Return Order");
      Header.TestField("Sell-to Customer No.", Invoice."Sell-to Customer No.");
      repeat
        Line.Get(Header."Document Type", Header."No.", InvoiceLine."Line No.");
        Line.TestField("No.", InvoiceLine."No.");
        Line.TestField(Quantity, ReturnQuantity(InvoiceLine.Quantity, true));
      until InvoiceLine.Next() = 0;
      exit;
    end;
    Entry.TestField("Table Id", Database::"Return Receipt Header");
    Receipt.GetBySystemId(Entry."Record SystemId");
    Receipt.TestField("Sell-to Customer No.", Invoice."Sell-to Customer No.");
    repeat
      ReceiptLine.Get(Receipt."No.", InvoiceLine."Line No.");
      ReceiptLine.TestField("No.", InvoiceLine."No.");
      ReceiptLine.TestField(Quantity, ReturnQuantity(InvoiceLine.Quantity, true));
    until InvoiceLine.Next() = 0;
    Entry.SetRange("Artifact Code", 'RETURN-CREDIT');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Sales Cr.Memo Header");
  end;

  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header")
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Purchase Header";
    Shipment: Record "Return Shipment Header";
    ShipmentLine: Record "Return Shipment Line";
    InvoiceLine: Record "Purch. Inv. Line";
    Line: Record "Purchase Line";
    Kind: Integer;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey);
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'RETURN*');
    if Kind = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'RETURN-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Purch. Inv. Header");
      if not (Entry."Skip Reason Code" in ['SOURCE', 'STOCK']) then
        Error(ResultErr);
      exit;
    end;
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    Entry.SetRange("Artifact Code", 'RETURN');
    Entry.FindFirst();
    if Kind = 1 then begin
      Entry.TestField("Table Id", Database::"Purchase Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::"Return Order");
      Header.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
      repeat
        Line.Get(Header."Document Type", Header."No.", InvoiceLine."Line No.");
        Line.TestField("No.", InvoiceLine."No.");
        Line.TestField(Quantity, ReturnQuantity(InvoiceLine.Quantity, false));
      until InvoiceLine.Next() = 0;
      exit;
    end;
    Entry.TestField("Table Id", Database::"Return Shipment Header");
    Shipment.GetBySystemId(Entry."Record SystemId");
    Shipment.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    repeat
      ShipmentLine.Get(Shipment."No.", InvoiceLine."Line No.");
      ShipmentLine.TestField("No.", InvoiceLine."No.");
      ShipmentLine.TestField(Quantity, ReturnQuantity(InvoiceLine.Quantity, false));
    until InvoiceLine.Next() = 0;
    Entry.SetRange("Artifact Code", 'RETURN-CREDIT');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Purch. Cr. Memo Hdr.");
  end;

  local procedure Artifact(Prefix: Code[10]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr('R' + Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    DimensionErr: Label 'The return order dimensions are blocked or required dimensions are missing. Review the customer, vendor and item defaults.';
    ResultErr: Label 'Return results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
