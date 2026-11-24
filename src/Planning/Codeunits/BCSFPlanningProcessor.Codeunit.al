namespace BCScenarioFactory.Planning;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Lifecycle;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.History;

/// <summary>
/// Planning proposals (requisition lines) for items of standard-posted sales invoices, in the approved follow-up stage.
/// The standard planning engine (Inventory Profile Offsetting) combines demand, stock, reorder point and open supply per
/// item into proposals in a dedicated requisition worksheet. Proposals stay proposals: nothing is converted into a purchase order,
/// and an item that already has proposals in the worksheet is not planned again (no double coverage).
/// Unsuitable items are skipped before the calculation (SOURCE); an invoice whose items need no proposal is documented as COVERED.
/// </summary>
codeunit 90485 "BCSF Planning Processor"
{
  Access = Internal;

  procedure TemplateName(): Code[10]
  begin
    exit('BCSFPLAN');
  end;

  procedure WorksheetName(): Code[10]
  begin
    exit('BCSF');
  end;

  /// <summary>Additive marker: planning is offered only when a usable requisition worksheet exists for this synthetic data.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    Template: Record "Req. Wksh. Template";
    Worksheet: Record "Requisition Wksh. Name";
  begin
    if not Template.Get(TemplateName()) or (Template.Type <> Template.Type::"Req.") or Template.Recurring then
      exit;
    if not Worksheet.Get(TemplateName(), WorksheetName()) then
      exit;
    Settings.Add('planningVersion', 1);
  end;

  /// <summary>True for new captures with the planning marker; an unknown marker stops.</summary>
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
    if not Settings.Get('planningVersion', Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(SetupErr);
    exit(true);
  end;

  /// <summary>Additive foundation: a dedicated requisition worksheet. Existing templates and worksheets are never changed.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure PrepareFoundation()
  var
    Template: Record "Req. Wksh. Template";
    Worksheet: Record "Requisition Wksh. Name";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    // Optional stage: without write permission planning is simply not offered.
    if not Template.WritePermission() or not Worksheet.WritePermission() then
      exit;
    if not Template.Get(TemplateName()) then begin
      Template.Init();
      Template.Name := TemplateName();
      Template.Description := CopyStr(TemplateDescriptionLbl, 1, MaxStrLen(Template.Description));
      Template.Validate(Type, Template.Type::"Req.");
      Template.Insert(true);
    end;
    if (Template.Type <> Template.Type::"Req.") or Template.Recurring then
      exit;
    if not Worksheet.Get(TemplateName(), WorksheetName()) then begin
      Worksheet.Init();
      Worksheet."Worksheet Template Name" := TemplateName();
      Worksheet.Name := WorksheetName();
      Worksheet.Description := CopyStr(WorksheetDescriptionLbl, 1, MaxStrLen(Worksheet.Description));
      Worksheet.Insert(true);
    end;
  end;

  /// <summary>Deterministic: 0 no planning for this invoice, 1 plan the items of the invoice (45 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PLANNING-PLAN', 1, 100) <= 45 then
      exit(1);
    exit(0);
  end;

  procedure PlanningDate(Invoice: Record "Sales Invoice Header"): Date
  begin
    exit(Invoice."Posting Date");
  end;

  /// <summary>Item with usable planning parameters: purchased, reordering policy set, unblocked vendor, no tracking or variants.</summary>
  procedure ItemSuitable(ItemNo: Code[20]): Boolean
  var
    Item: Record Item;
    Vendor: Record Vendor;
    Variant: Record "Item Variant";
  begin
    if not Item.Get(ItemNo) then
      exit(false);
    if Item.Blocked or (Item.Type <> Item.Type::Inventory) or (Item."Item Tracking Code" <> '') then
      exit(false);
    if (Item."Reordering Policy" = Item."Reordering Policy"::" ") or (Item."Replenishment System" <> Item."Replenishment System"::Purchase) then
      exit(false);
    if (Item."Vendor No." = '') or not Vendor.Get(Item."Vendor No.") then
      exit(false);
    if Vendor.Blocked <> Vendor.Blocked::" " then
      exit(false);
    Variant.SetRange("Item No.", ItemNo);
    exit(Variant.IsEmpty());
  end;

  local procedure HasProposal(ItemNo: Code[20]): Boolean
  var
    Line: Record "Requisition Line";
  begin
    Line.SetRange("Worksheet Template Name", TemplateName());
    Line.SetRange("Journal Batch Name", WorksheetName());
    Line.SetRange(Type, Line.Type::Item);
    Line.SetRange("No.", ItemNo);
    exit(not Line.IsEmpty());
  end;

  /// <summary>Runs the standard planning per suitable item, registers the proposals or a documented COVERED/SOURCE skip.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure RunForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; ParentId: Guid)
  var
    InvoiceLine: Record "Sales Invoice Line";
    Item: Record Item;
    Line: Record "Requisition Line";
    Offsetting: Codeunit "Inventory Profile Offsetting";
    Registry: Codeunit "BCSF Record Registry";
    WorksheetType: Option Requisition,Planning;
    Planned: List of [Code[20]];
    PlannedItem: Code[20];
    FromDate: Date;
    ToDate: Date;
    Suitable: Integer;
    Created: Integer;
    SkipReason: Code[30];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    FromDate := PlanningDate(Invoice);
    ToDate := FromDate + 90;
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if InvoiceLine.FindSet() then
      repeat
        if not Planned.Contains(InvoiceLine."No.") then begin
          Planned.Add(InvoiceLine."No.");
          if ItemSuitable(InvoiceLine."No.") then begin
            Suitable += 1;
            // No double coverage: an item with proposals in this worksheet keeps them and is not calculated again.
            if not HasProposal(InvoiceLine."No.") then begin
              Item.Reset();
              Item.SetRange("No.", InvoiceLine."No.");
              if InvoiceLine."Location Code" <> '' then
                Item.SetRange("Location Filter", InvoiceLine."Location Code");
              Offsetting.SetParm('', 0D, WorksheetType::Requisition);
              Offsetting.CalculatePlanFromWorksheet(Item, TemplateName(), WorksheetName(), FromDate, ToDate, true, true);
            end;
          end;
        end;
      until InvoiceLine.Next() = 0;
    if Suitable = 0 then
      SkipReason := 'SOURCE';
    if SkipReason = '' then begin
      Line.SetRange("Worksheet Template Name", TemplateName());
      Line.SetRange("Journal Batch Name", WorksheetName());
      Line.SetRange(Type, Line.Type::Item);
      foreach PlannedItem in Planned do begin
        Line.SetRange("No.", PlannedItem);
        if Line.FindSet() then
          repeat
            // The first registration of a line wins; a line shared by two invoices of the run stays with the first.
            if not AlreadyRegistered(RunId, Line) then begin
              Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PLAN-LINE', Line."Line No."), BatchId, Line.RecordId(), ParentId);
              Created += 1;
            end;
          until Line.Next() = 0;
      end;
      if Created = 0 then
        SkipReason := 'COVERED';
    end;
    if SkipReason <> '' then
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PLANNING-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
  end;

  local procedure AlreadyRegistered(RunId: Guid; Line: Record "Requisition Line"): Boolean
  var
    Entry: Record "BCSF Generated Record";
  begin
    Entry.SetCurrentKey("Table Id", "Record SystemId");
    Entry.SetRange("Table Id", Database::"Requisition Line");
    Entry.SetRange("Record SystemId", Line.SystemId);
    Entry.SetRange("Run Id", RunId);
    exit(not Entry.IsEmpty());
  end;

  /// <summary>Read-only validation: proposals belong to invoice items and are real worksheet lines; no purchase was created from them.</summary>
  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Entry: Record "BCSF Generated Record";
    Line: Record "Requisition Line";
    InvoiceLine: Record "Sales Invoice Line";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'PLAN*');
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'PLANNING-SKIP');
    if Entry.FindFirst() then begin
      // A documented skip carries a stable reason and no proposal of this invoice.
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Sales Invoice Header");
      if not (Entry."Skip Reason Code" in ['COVERED', 'SOURCE']) then
        Error(ResultErr);
      exit;
    end;
    Entry.SetFilter("Artifact Code", 'PLAN-LINE*');
    Entry.FindSet();
    repeat
      Entry.TestField("Table Id", Database::"Requisition Line");
      Line.GetBySystemId(Entry."Record SystemId");
      Line.TestField("Worksheet Template Name", TemplateName());
      Line.TestField("Journal Batch Name", WorksheetName());
      Line.TestField(Type, Line.Type::Item);
      if Line.Quantity <= 0 then
        Error(ResultErr);
      InvoiceLine.SetRange("Document No.", Invoice."No.");
      InvoiceLine.SetRange("No.", Line."No.");
      if InvoiceLine.IsEmpty() then
        Error(ResultErr);
    until Entry.Next() = 0;
  end;

  local procedure Artifact(Prefix: Code[20]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    TemplateDescriptionLbl: Label 'Replenishment proposals';
    WorksheetDescriptionLbl: Label 'Proposals from sales demand';
    SetupErr: Label 'The planning setup is not supported or changed. Review the requisition worksheet for planning proposals.';
    ResultErr: Label 'Planning results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain calculation.';
}
