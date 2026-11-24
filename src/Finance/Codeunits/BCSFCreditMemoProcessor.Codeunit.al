namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
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
/// Follow-up credit memos for standard-posted sales and purchase invoices of the same run.
/// Plan kinds: 0 none, 1 unposted credit memo, 2 posted partial credit memo, 3 posted full credit memo (sales only).
/// Credit memos are intentionally not applied to the invoice, so the payment plan and its exact remaining amounts stay valid.
/// </summary>
codeunit 90481 "BCSF Credit Memo Processor"
{
  Access = Internal;

  /// <summary>Credit memos belong to the approved follow-up stage and need the additive marker of new captures.</summary>
  procedure Enabled(Context: JsonObject): Boolean
  var
    Payments: Codeunit "BCSF Payment Processor";
    Token: JsonToken;
    Settings: JsonObject;
  begin
    if not Payments.Enabled(Context) then
      exit(false);
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    if not Settings.Get('creditVersion', Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(SetupErr);
    exit(true);
  end;

  /// <summary>True when both standard credit memo number series exist and credit memos post without separate return documents.</summary>

  procedure SetupUsable(): Boolean

  var

    SalesSetup: Record "Sales & Receivables Setup";

    PurchaseSetup: Record "Purchases & Payables Setup";

  begin

    if not SalesSetup.Get() or not PurchaseSetup.Get() then

      exit(false);

    exit((SalesSetup."Credit Memo Nos." <> '') and (SalesSetup."Posted Credit Memo Nos." <> '') and

      not SalesSetup."Return Receipt on Credit Memo" and

      (PurchaseSetup."Credit Memo Nos." <> '') and (PurchaseSetup."Posted Credit Memo Nos." <> '') and

      not PurchaseSetup."Return Shipment on Credit Memo");

  end;


  /// <summary>Read-only check of the standard number series and the supported posting setup.</summary>
  procedure CheckSetup(Sales: Boolean)
  var
    SalesSetup: Record "Sales & Receivables Setup";
    PurchaseSetup: Record "Purchases & Payables Setup";
  begin
    if Sales then begin
      SalesSetup.Get();
      SalesSetup.TestField("Credit Memo Nos.");
      SalesSetup.TestField("Posted Credit Memo Nos.");
      // A separate return receipt would need extra evidence; this contract supports the direct credit memo only.
      if SalesSetup."Return Receipt on Credit Memo" then
        Error(SetupErr);
    end else begin
      PurchaseSetup.Get();
      PurchaseSetup.TestField("Credit Memo Nos.");
      PurchaseSetup.TestField("Posted Credit Memo Nos.");
      if PurchaseSetup."Return Shipment on Credit Memo" then
        Error(SetupErr);
    end;
  end;

  /// <summary>Deterministic plan kind from the seed; independent of run id and batch order.</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Sales: Boolean): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    Roll: Integer;
  begin
    Roll := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'CREDIT-PLAN', 1, 100);
    case true of
      Roll <= 70:
        exit(0);
      Roll <= 80:
        exit(1);
      Roll <= 90:
        exit(2);
    end;
    if Sales then
      exit(3);
    exit(2);
  end;

  procedure CreditDate(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; InvoiceDate: Date): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    EndingDate: Date;
  begin
    if Contract.GetDatePolicyVersion(Context) = 0 then
      exit(InvoiceDate);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(Seed.SampleDate(Context, NodeCode, Format(LogicalKey, 0, 9), 'CREDIT-DATE', InvoiceDate, EndingDate, false));
  end;

  /// <summary>Whole units only. Full credit repeats the invoiced quantity; purchase credits stay at one unit so the planned stock reserve is never consumed.</summary>
  procedure CreditQuantity(Kind: Integer; InvoicedQuantity: Decimal; Sales: Boolean): Decimal
  var
    Quantity: Decimal;
  begin
    if Kind = 3 then
      exit(InvoicedQuantity);
    if Sales then
      Quantity := Round(InvoicedQuantity / 2, 1, '>')
    else
      Quantity := 1;
    if Quantity > InvoicedQuantity then
      Quantity := InvoicedQuantity;
    exit(Quantity);
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
    Kind := PlanKind(Context, NodeCode, LogicalKey, true);
    if Kind = 0 then
      exit;
    CheckSetup(true);
    Date := CreditDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    Header.Init();
    Header.SetHideValidationDialog(true);
    Header."Document Type" := Header."Document Type"::"Credit Memo";
    Header."Posting Date" := Date;
    Header.Insert(true);
    Header.Validate("Sell-to Customer No.", Invoice."Sell-to Customer No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Location Code", FirstSalesLocation(Invoice."No."));
    Header."External Document No." := CopyStr(Invoice."No.", 1, MaxStrLen(Header."External Document No."));
    Header.Modify(true);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      Error(ResultErr);
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
      Line.Validate(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, true));
      Line.Validate("Unit Price", InvoiceLine."Unit Price");
      Line.Validate("Line Discount %", InvoiceLine."Line Discount %");
      CheckSalesDimensions(Header, Line);
      Line.Modify(true);
    until InvoiceLine.Next() = 0;
    if Kind = 1 then begin
      // Unposted credit memo: a real standard document that stays open for review.
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT', BatchId, Header.RecordId(), ParentId);
      exit;
    end;
    SalesPost.SetSuppressCommit(true);
    // Public OnRun, no Boolean return value and therefore no implicit success commit.
    SalesPost.Run(Header);
    SalesPost.GetGlobaDocumentsHeaders(Shipment, Posted, Credit, Receipt);
    Credit.TestField("No.");
    Credit.TestField("Bill-to Customer No.", Invoice."Bill-to Customer No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT', BatchId, Credit.RecordId(), ParentId);
    RegisterSalesEvidence(RunId, NodeCode, LogicalKey, BatchId, Credit, ParentId);
  end;

  local procedure FirstSalesLocation(InvoiceNo: Code[20]): Code[10]
  var
    InvoiceLine: Record "Sales Invoice Line";
  begin
    InvoiceLine.SetRange("Document No.", InvoiceNo);
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindFirst();
    exit(InvoiceLine."Location Code");
  end;

  local procedure CheckSalesDimensions(Header: Record "Sales Header"; Line: Record "Sales Line")
  var
    Dimensions: Codeunit DimensionManagement;
  begin
    if not Dimensions.CheckDimIDComb(Header."Dimension Set ID") or
      not Dimensions.CheckDimIDComb(Line."Dimension Set ID")
    then
      Error(DimensionErr);
  end;

  local procedure RegisterSalesEvidence(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Credit: Record "Sales Cr.Memo Header"; ParentId: Guid)
  var
    CustomerEntry: Record "Cust. Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    ItemEntry: Record "Item Ledger Entry";
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    Registry: Codeunit "BCSF Record Registry";
  begin
    CustomerEntry.Get(Credit."Cust. Ledger Entry No.");
    CustomerEntry.TestField("Document No.", Credit."No.");
    CustomerEntry.TestField("Customer No.", Credit."Bill-to Customer No.");
    CustomerEntry.TestField("Document Type", CustomerEntry."Document Type"::"Credit Memo");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT-ENTRY', BatchId, CustomerEntry.RecordId(), ParentId);
    GL.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    GL.SetRange("Document No.", Credit."No.");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    VAT.SetRange("Document No.", Credit."No.");
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VAT', VAT."Entry No."), BatchId, VAT.RecordId(), ParentId);
      until VAT.Next() = 0;
    ItemEntry.SetRange("Document No.", Credit."No.");
    ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Sales Credit Memo");
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Customer);
    ItemEntry.SetRange("Source No.", Credit."Sell-to Customer No.");
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

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; ParentId: Guid)
  var
    Header: Record "Purchase Header";
    Line: Record "Purchase Line";
    InvoiceLine: Record "Purch. Inv. Line";
    Credit: Record "Purch. Cr. Memo Hdr.";
    Registry: Codeunit "BCSF Record Registry";
    PurchasePost: Codeunit "Purch.-Post";
    Kind: Integer;
    Date: Date;
    PreAssignedNo: Code[20];
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey, false);
    if Kind = 0 then
      exit;
    CheckSetup(false);
    Date := CreditDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    Header.Init();
    Header.SetHideValidationDialog(true);
    Header."Document Type" := Header."Document Type"::"Credit Memo";
    Header."Posting Date" := Date;
    Header.Insert(true);
    Header.Validate("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    Header.Validate("Posting Date", Date);
    Header.Validate("Document Date", Date);
    Header.Validate("Location Code", FirstPurchaseLocation(Invoice."No."));
    Header.Validate("Vendor Cr. Memo No.", Header."No.");
    Header.Modify(true);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      Error(ResultErr);
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
      Line.Validate(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, false));
      Line.Validate("Direct Unit Cost", InvoiceLine."Direct Unit Cost");
      CheckPurchaseDimensions(Header, Line);
      Line.Modify(true);
    until InvoiceLine.Next() = 0;
    if Kind = 1 then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT', BatchId, Header.RecordId(), ParentId);
      exit;
    end;
    PreAssignedNo := Header."No.";
    PurchasePost.SetSuppressCommit(true);
    PurchasePost.Run(Header);
    Credit.SetRange("Pre-Assigned No.", PreAssignedNo);
    if Credit.Count() <> 1 then
      Error(ResultErr);
    Credit.FindFirst();
    Credit.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT', BatchId, Credit.RecordId(), ParentId);
    RegisterPurchaseEvidence(RunId, NodeCode, LogicalKey, BatchId, Credit, ParentId);
  end;

  local procedure FirstPurchaseLocation(InvoiceNo: Code[20]): Code[10]
  var
    InvoiceLine: Record "Purch. Inv. Line";
  begin
    InvoiceLine.SetRange("Document No.", InvoiceNo);
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindFirst();
    exit(InvoiceLine."Location Code");
  end;

  local procedure CheckPurchaseDimensions(Header: Record "Purchase Header"; Line: Record "Purchase Line")
  var
    Dimensions: Codeunit DimensionManagement;
  begin
    if not Dimensions.CheckDimIDComb(Header."Dimension Set ID") or
      not Dimensions.CheckDimIDComb(Line."Dimension Set ID")
    then
      Error(DimensionErr);
  end;

  local procedure RegisterPurchaseEvidence(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Credit: Record "Purch. Cr. Memo Hdr."; ParentId: Guid)
  var
    VendorEntry: Record "Vendor Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    ItemEntry: Record "Item Ledger Entry";
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    Registry: Codeunit "BCSF Record Registry";
  begin
    VendorEntry.Get(Credit."Vendor Ledger Entry No.");
    VendorEntry.TestField("Document No.", Credit."No.");
    VendorEntry.TestField("Vendor No.", Credit."Pay-to Vendor No.");
    VendorEntry.TestField("Document Type", VendorEntry."Document Type"::"Credit Memo");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CREDIT-ENTRY', BatchId, VendorEntry.RecordId(), ParentId);
    GL.SetRange("Transaction No.", VendorEntry."Transaction No.");
    GL.SetRange("Document No.", Credit."No.");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", VendorEntry."Transaction No.");
    VAT.SetRange("Document No.", Credit."No.");
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VAT', VAT."Entry No."), BatchId, VAT.RecordId(), ParentId);
      until VAT.Next() = 0;
    ItemEntry.SetRange("Document No.", Credit."No.");
    ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Purchase Credit Memo");
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Vendor);
    ItemEntry.SetRange("Source No.", Credit."Buy-from Vendor No.");
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

  /// <summary>Read-only output validation against the invoice and the deterministic plan.</summary>
  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Sales Header";
    Credit: Record "Sales Cr.Memo Header";
    InvoiceLine: Record "Sales Invoice Line";
    CreditLine: Record "Sales Cr.Memo Line";
    Line: Record "Sales Line";
    Contract: Codeunit "BCSF Contract JSON";
    Kind: Integer;
    ExpectedDate: Date;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey, true);
    if Kind = 0 then begin
      if Entry.Get(RunId, NodeCode, LogicalKey, 'CREDIT') then
        Error(ResultErr);
      exit;
    end;
    Entry.Get(RunId, NodeCode, LogicalKey, 'CREDIT');
    ExpectedDate := CreditDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    if Kind = 1 then begin
      Entry.TestField("Table Id", Database::"Sales Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::"Credit Memo");
      Header.TestField("Sell-to Customer No.", Invoice."Sell-to Customer No.");
      Header.TestField("Posting Date", ExpectedDate);
      repeat
        Line.Get(Header."Document Type", Header."No.", InvoiceLine."Line No.");
        Line.TestField("No.", InvoiceLine."No.");
        Line.TestField(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, true));
      until InvoiceLine.Next() = 0;
      exit;
    end;
    Entry.TestField("Table Id", Database::"Sales Cr.Memo Header");
    Credit.GetBySystemId(Entry."Record SystemId");
    Credit.TestField("Sell-to Customer No.", Invoice."Sell-to Customer No.");
    Credit.TestField("Posting Date", ExpectedDate);
    if Contract.GetDatePolicyVersion(Context) = 1 then
      Credit.TestField("Document Date", ExpectedDate);
    repeat
      CreditLine.Get(Credit."No.", InvoiceLine."Line No.");
      CreditLine.TestField("No.", InvoiceLine."No.");
      CreditLine.TestField(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, true));
    until InvoiceLine.Next() = 0;
  end;

  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header")
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Purchase Header";
    Credit: Record "Purch. Cr. Memo Hdr.";
    InvoiceLine: Record "Purch. Inv. Line";
    CreditLine: Record "Purch. Cr. Memo Line";
    Line: Record "Purchase Line";
    Contract: Codeunit "BCSF Contract JSON";
    Kind: Integer;
    ExpectedDate: Date;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey, false);
    if Kind = 0 then begin
      if Entry.Get(RunId, NodeCode, LogicalKey, 'CREDIT') then
        Error(ResultErr);
      exit;
    end;
    Entry.Get(RunId, NodeCode, LogicalKey, 'CREDIT');
    ExpectedDate := CreditDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    if Kind = 1 then begin
      Entry.TestField("Table Id", Database::"Purchase Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Document Type", Header."Document Type"::"Credit Memo");
      Header.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
      Header.TestField("Posting Date", ExpectedDate);
      repeat
        Line.Get(Header."Document Type", Header."No.", InvoiceLine."Line No.");
        Line.TestField("No.", InvoiceLine."No.");
        Line.TestField(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, false));
      until InvoiceLine.Next() = 0;
      exit;
    end;
    Entry.TestField("Table Id", Database::"Purch. Cr. Memo Hdr.");
    Credit.GetBySystemId(Entry."Record SystemId");
    Credit.TestField("Buy-from Vendor No.", Invoice."Buy-from Vendor No.");
    Credit.TestField("Posting Date", ExpectedDate);
    if Contract.GetDatePolicyVersion(Context) = 1 then
      Credit.TestField("Document Date", ExpectedDate);
    repeat
      CreditLine.Get(Credit."No.", InvoiceLine."Line No.");
      CreditLine.TestField("No.", InvoiceLine."No.");
      CreditLine.TestField(Quantity, CreditQuantity(Kind, InvoiceLine.Quantity, false));
    until InvoiceLine.Next() = 0;
  end;

  local procedure Artifact(Prefix: Code[10]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    SetupErr: Label 'Credit memo setup is not supported: credit memo number series are missing, or returns are posted with a separate return document. Review the standard sales and purchase setup.';
    DimensionErr: Label 'The credit memo dimensions are blocked or required dimensions are missing. Review the customer, vendor and item defaults.';
    ResultErr: Label 'Credit memo results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
