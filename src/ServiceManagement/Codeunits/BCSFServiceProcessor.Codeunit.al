namespace BCScenarioFactory.ServiceManagement;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;

/// <summary>
/// Service management (module Service Management) for standard-posted sales invoices of the same run, in the approved
/// follow-up stage. Per sales invoice (about 20 %) the invoiced item of the customer becomes a service item (serial number,
/// installation date from the invoice) and an unposted service order with one service item line and one spare part line is
/// created for it. Posting of service orders (shipment, consumption, invoice) is not part of this module version.
/// Existing service items and service setup are never changed. Cases without service number series, unblocked customer or a
/// suitable invoiced item are skipped before any write (SOURCE).
/// </summary>
codeunit 90491 "BCSF Service Processor"
{
  Access = Internal;

  /// <summary>Additive marker: service is offered only when the service item and service order number series exist.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    ServiceSetup: Record "Service Mgt. Setup";
  begin
    if not ServiceSetup.Get() then
      exit;
    // The service item line calculates the response date with the base calendar of the service setup; it is never invented here.
    if (ServiceSetup."Service Item Nos." = '') or (ServiceSetup."Service Order Nos." = '') or (ServiceSetup."Base Calendar Code" = '') then
      exit;
    Settings.Add('serviceVersion', 1);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'serviceVersion'));
  end;

  /// <summary>Deterministic: 0 no service case for this invoice, 1 service item with unposted service order (20 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'SERVICE-PLAN', 1, 100) <= 20 then
      exit(1);
    exit(0);
  end;

  /// <summary>First invoiced inventory item without tracking or variants.</summary>
  local procedure SourceItem(Invoice: Record "Sales Invoice Header"; var Item: Record Item; var InvoiceLine: Record "Sales Invoice Line"): Boolean
  var
    Variant: Record "Item Variant";
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindSet() then
      exit(false);
    repeat
      if Item.Get(InvoiceLine."No.") then
        if not Item.Blocked and (Item.Type = Item.Type::Inventory) and (Item."Item Tracking Code" = '') then begin
          Variant.SetRange("Item No.", Item."No.");
          if Variant.IsEmpty() then
            exit(true);
        end;
    until InvoiceLine.Next() = 0;
    exit(false);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure RunForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; ParentId: Guid)
  var
    ServiceSetup: Record "Service Mgt. Setup";
    Customer: Record Customer;
    Item: Record Item;
    InvoiceLine: Record "Sales Invoice Line";
    ServiceItem: Record "Service Item";
    Header: Record "Service Header";
    ItemLine: Record "Service Item Line";
    Line: Record "Service Line";
    Registry: Codeunit "BCSF Record Registry";
    SkipReason: Code[30];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    // Read-only preflight before any write.
    if not ServiceSetup.Get() or (ServiceSetup."Base Calendar Code" = '') or not Customer.Get(Invoice."Bill-to Customer No.") or (Customer.Blocked <> Customer.Blocked::" ") or
      not SourceItem(Invoice, Item, InvoiceLine) or not ServiceItem.WritePermission() or not Header.WritePermission()
    then
      SkipReason := 'SOURCE';
    if SkipReason <> '' then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'SERVICE-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
      exit;
    end;
    ServiceItem.Init();
    ServiceItem.Insert(true);
    ServiceItem.Validate("Customer No.", Customer."No.");
    ServiceItem.Validate("Item No.", Item."No.");
    ServiceItem.Validate("Serial No.", SerialNo(Invoice));
    ServiceItem.Validate("Installation Date", Invoice."Posting Date");
    ServiceItem.Modify(true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'SERVICE-ITEM', BatchId, ServiceItem.RecordId(), ParentId);
    Header.Init();
    Header."Document Type" := Header."Document Type"::Order;
    Header.Insert(true);
    Header.Validate("Customer No.", Customer."No.");
    Header.Validate("Order Date", Invoice."Posting Date");
    Header.Modify(true);
    ItemLine.Init();
    ItemLine."Document Type" := Header."Document Type";
    ItemLine."Document No." := Header."No.";
    ItemLine."Line No." := 10000;
    ItemLine.Insert(true);
    ItemLine.Validate("Service Item No.", ServiceItem."No.");
    ItemLine.Modify(true);
    Line.Init();
    Line."Document Type" := Header."Document Type";
    Line."Document No." := Header."No.";
    Line."Line No." := 10000;
    Line.Insert(true);
    Line.Validate("Service Item Line No.", ItemLine."Line No.");
    Line.Validate(Type, Line.Type::Item);
    Line.Validate("No.", Item."No.");
    Line.Validate(Quantity, 1);
    Line.Modify(true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'SERVICE-ORDER', BatchId, Header.RecordId(), ParentId);
  end;

  procedure SerialNo(Invoice: Record "Sales Invoice Header"): Code[50]
  begin
    exit(CopyStr('SN-' + Invoice."No.", 1, 50));
  end;

  /// <summary>Read-only validation: service item of the invoice customer and an open service order that references it.</summary>
  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Entry: Record "BCSF Generated Record";
    ServiceItem: Record "Service Item";
    Header: Record "Service Header";
    ItemLine: Record "Service Item Line";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'SERVICE*');
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'SERVICE-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Sales Invoice Header");
      if Entry."Skip Reason Code" <> 'SOURCE' then
        Error(ResultErr);
      exit;
    end;
    Entry.SetRange("Artifact Code", 'SERVICE-ITEM');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Service Item");
    ServiceItem.GetBySystemId(Entry."Record SystemId");
    ServiceItem.TestField("Customer No.", Invoice."Bill-to Customer No.");
    ServiceItem.TestField("Serial No.", SerialNo(Invoice));
    Entry.SetRange("Artifact Code", 'SERVICE-ORDER');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Service Header");
    Header.GetBySystemId(Entry."Record SystemId");
    Header.TestField("Document Type", Header."Document Type"::Order);
    Header.TestField("Customer No.", Invoice."Bill-to Customer No.");
    ItemLine.SetRange("Document Type", Header."Document Type");
    ItemLine.SetRange("Document No.", Header."No.");
    ItemLine.SetRange("Service Item No.", ServiceItem."No.");
    if ItemLine.IsEmpty() then
      Error(ResultErr);
  end;

  var
    ResultErr: Label 'Service results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain step.';
}
