namespace BCScenarioFactory.Manufacturing;

using BCScenarioFactory.Assembly;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.History;

/// <summary>
/// Manufacturing (module Manufacturing) for standard-posted purchases of the same run, in the approved follow-up stage.
/// Per purchase invoice (about 12 %) a synthetic manufactured item with a certified production BOM (the first one or two item
/// lines of the purchase) and a released production order are created: 1 the order stays released and unposted, 2 consumption
/// and output are posted through the standard item journal posting and the order is finished with the standard status
/// management. No routing and no capacity are used. Component use is capped by the movement unit rule, so the stock reserve for
/// later sales stays intact. Unsuitable cases are skipped before any write (STOCK, SOURCE). Assembly is a separate module.
/// </summary>
codeunit 90490 "BCSF Production Processor"
{
  Access = Internal;

  /// <summary>Additive marker: manufacturing is offered only when number series and journal source codes are usable.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    ManufacturingSetup: Record "Manufacturing Setup";
    InventorySetup: Record "Inventory Setup";
    SourceCode: Record "Source Code Setup";
  begin
    if not ManufacturingSetup.Get() or not InventorySetup.Get() or not SourceCode.Get() then
      exit;
    if (ManufacturingSetup."Production BOM Nos." = '') or (ManufacturingSetup."Released Order Nos." = '') or
      (SourceCode."Consumption Journal" = '') or (SourceCode."Output Journal" = '') or (InventorySetup."Item Nos." = '') or
      not InventorySetup."Automatic Cost Posting"
    then
      exit;
    Settings.Add('productionVersion', 1);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'productionVersion'));
  end;

  /// <summary>Deterministic: 0 no production for this invoice, 1 released order (unposted), 2 posted and finished (12 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PRODUCTION-PLAN', 1, 100) > 12 then
      exit(0);
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'PRODUCTION-MODE', 1, 2));
  end;

  /// <summary>
  /// A posted order consumes components. When the stock movements of the same invoice already use the planned stock reserve
  /// (any movement kind), the order stays released and unposted, so the reserve for later sales is never used twice.
  /// </summary>
  procedure EffectiveKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"): Integer
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Movements: Codeunit "BCSFInventoryMovementProcessor";
    Kind: Integer;
  begin
    Kind := PlanKind(Context, NodeCode, LogicalKey);
    if Kind <> 2 then
      exit(Kind);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindFirst() then
      exit(1);
    if Movements.PlanKind(Context, NodeCode, LogicalKey, InvoiceLine."Location Code") <> 0 then
      exit(1);
    exit(2);
  end;

  local procedure UsableAccount(AccountNo: Code[20]): Boolean
  var
    Account: Record "G/L Account";
  begin
    if AccountNo = '' then
      exit(false);
    if not Account.Get(AccountNo) then
      exit(false);
    exit((Account."Account Type" = Account."Account Type"::Posting) and not Account.Blocked);
  end;

  /// <summary>Read-only prerequisites. Returns a skip reason or an empty text.</summary>
  local procedure Preflight(Kind: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Date: Date): Code[30]
  var
    Item: Record Item;
    Variant: Record "Item Variant";
    Posting: Record "General Posting Setup";
    BomHeader: Record "Production BOM Header";
    Order: Record "Production Order";
    Index: Integer;
  begin
    if not BomHeader.WritePermission() or not Order.WritePermission() or (Count = 0) then
      exit('SOURCE');
    // Components of one order share the order location.
    if (Count = 2) and (Locations[1] <> Locations[2]) then
      exit('SOURCE');
    for Index := 1 to Count do begin
      Item.Get(ItemNos[Index]);
      if Item.Blocked or (Item.Type <> Item.Type::Inventory) or (Item."Item Tracking Code" <> '') then
        exit('SOURCE');
      Variant.SetRange("Item No.", ItemNos[Index]);
      if not Variant.IsEmpty() then
        exit('SOURCE');
      if Kind = 2 then begin
        if not Posting.Get('', Item."Gen. Prod. Posting Group") or not UsableAccount(Posting."Inventory Adjmt. Account") or
          not UsableAccount(Posting."Direct Cost Applied Account") or not UsableAccount(Posting."COGS Account")
        then
          exit('SOURCE');
        Item.SetRange("Location Filter", Locations[Index]);
        Item.SetRange("Date Filter", 0D, Date);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        if Item.Inventory - Item."Reserved Qty. on Inventory" < Quantity then
          exit('STOCK');
      end;
    end;
    exit('');
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Assembly: Codeunit "BCSF Assembly Processor";
    Registry: Codeunit "BCSF Record Registry";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Count: Integer;
    Quantity: Decimal;
    Kind: Integer;
    SkipReason: Code[30];
  begin
    Kind := EffectiveKind(Context, NodeCode, LogicalKey, Invoice);
    if Kind = 0 then
      exit;
    Count := Assembly.Components(Invoice, ItemNos, Locations, Measures);
    Quantity := Assembly.AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    SkipReason := Preflight(Kind, Quantity, Count, ItemNos, Locations, Date);
    if SkipReason = '' then
      Build(RunId, NodeCode, LogicalKey, BatchId, Date, ParentId, Kind, Quantity, Count, ItemNos, Locations, Measures, Context)
    else
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PRODUCTION-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
  end;

  local procedure Build(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Date: Date; ParentId: Guid; Kind: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Measures: array[2] of Code[10]; Context: JsonObject)
  var
    Product: Record Item;
    Component: Record Item;
    BomHeader: Record "Production BOM Header";
    BomLine: Record "Production BOM Line";
    Order: Record "Production Order";
    InventorySetup: Record "Inventory Setup";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Numbers: Codeunit "No. Series";
    CreateLines: Codeunit "Create Prod. Order Lines";
    StatusManagement: Codeunit "Prod. Order Status Management";
    StartDate: Date;
    Index: Integer;
    Cost: Decimal;
    OrderNo: Code[20];
  begin
    InventorySetup.Get();
    Evaluate(StartDate, Contract.GetText(Context, 'startingDate'), 9);
    Component.Get(ItemNos[1]);
    BomHeader.Init();
    BomHeader.Insert(true);
    BomHeader.Validate(Description, CopyStr(StrSubstNo(ProductLbl, Component.Description), 1, MaxStrLen(BomHeader.Description)));
    BomHeader.Validate("Unit of Measure Code", Component."Base Unit of Measure");
    BomHeader.Modify(true);
    for Index := 1 to Count do begin
      Component.Get(ItemNos[Index]);
      BomLine.Init();
      BomLine."Production BOM No." := BomHeader."No.";
      BomLine."Line No." := Index * 10000;
      BomLine.Validate(Type, BomLine.Type::Item);
      BomLine.Validate("No.", Component."No.");
      BomLine.Validate("Unit of Measure Code", Measures[Index]);
      BomLine.Validate("Quantity per", 1);
      BomLine.Insert(true);
      Cost += Component."Unit Cost";
    end;
    BomHeader.Validate(Status, BomHeader.Status::Certified);
    BomHeader.Modify(true);
    Component.Get(ItemNos[1]);
    Product.Init();
    Product."No. Series" := InventorySetup."Item Nos.";
    Product."No." := Numbers.GetNextNo(InventorySetup."Item Nos.", StartDate);
    Product.Validate(Type, Product.Type::Inventory);
    Product.Validate(Description, CopyStr(StrSubstNo(ProductLbl, Component.Description), 1, MaxStrLen(Product.Description)));
    Product.Validate("Costing Method", Product."Costing Method"::FIFO);
    Product.Validate("Gen. Prod. Posting Group", Component."Gen. Prod. Posting Group");
    Product.Validate("VAT Prod. Posting Group", Component."VAT Prod. Posting Group");
    Product.Validate("Inventory Posting Group", Component."Inventory Posting Group");
    Product.Insert(true);
    Product.Validate("Base Unit of Measure", Component."Base Unit of Measure");
    Product.Validate("Replenishment System", Product."Replenishment System"::"Prod. Order");
    Product.Validate("Production BOM No.", BomHeader."No.");
    Product.Validate("Unit Cost", Round(Cost, 0.01));
    Product.Validate("Unit Price", Round(Cost * 1.4, 0.01));
    Product.Modify(true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PRODUCTION-ITEM', BatchId, Product.RecordId(), ParentId);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PRODUCTION-BOM', BatchId, BomHeader.RecordId(), ParentId);
    Order.Init();
    Order.Status := Order.Status::Released;
    Order.Insert(true);
    OrderNo := Order."No.";
    Order.Validate("Source Type", Order."Source Type"::Item);
    Order.Validate("Source No.", Product."No.");
    Order.Validate("Location Code", Locations[1]);
    Order.Validate(Quantity, Quantity);
    Order.Validate("Due Date", Date);
    Order.Modify(true);
    if not CreateLines.Copy(Order, 1, '', false) then
      Error(ResultErr);
    if Kind = 2 then begin
      PostConsumptionAndOutput(Order, Date);
      Order.Get(Order.Status::Released, OrderNo);
      StatusManagement.ChangeProdOrderStatus(Order, Order.Status::Finished, Date, false);
      Order.Get(Order.Status::Finished, OrderNo);
    end;
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PRODUCTION-ORDER', BatchId, Order.RecordId(), ParentId);
  end;

  /// <summary>Consumption of every component line, then the output of the line. The journal lines are temporary; persistent writes belong to the standard posting codeunit.</summary>
  local procedure PostConsumptionAndOutput(Order: Record "Production Order"; Date: Date)
  var
    OrderLine: Record "Prod. Order Line";
    OrderComponent: Record "Prod. Order Component";
    TempLine: Record "Item Journal Line" temporary;
    SourceCode: Record "Source Code Setup";
    PostLine: Codeunit "Item Jnl.-Post Line";
    LineNo: Integer;
  begin
    SourceCode.Get();
    OrderLine.SetRange(Status, Order.Status);
    OrderLine.SetRange("Prod. Order No.", Order."No.");
    OrderLine.FindFirst();
    OrderComponent.SetRange(Status, Order.Status);
    OrderComponent.SetRange("Prod. Order No.", Order."No.");
    OrderComponent.SetRange("Prod. Order Line No.", OrderLine."Line No.");
    if not OrderComponent.FindSet() then
      Error(ResultErr);
    repeat
      LineNo += 10000;
      TempLine.Init();
      TempLine."Line No." := LineNo;
      TempLine."Document No." := Order."No.";
      TempLine."Source Code" := SourceCode."Consumption Journal";
      TempLine.Validate("Posting Date", Date);
      TempLine.Validate("Document Date", Date);
      TempLine.Validate("Entry Type", TempLine."Entry Type"::Consumption);
      TempLine.Validate("Order Type", TempLine."Order Type"::Production);
      TempLine.Validate("Order No.", Order."No.");
      TempLine.Validate("Order Line No.", OrderLine."Line No.");
      TempLine.Validate("Prod. Order Comp. Line No.", OrderComponent."Line No.");
      TempLine.Validate("Item No.", OrderComponent."Item No.");
      TempLine.Validate("Location Code", OrderComponent."Location Code");
      TempLine.Validate(Quantity, OrderComponent."Expected Quantity");
      TempLine.Insert();
      PostLine.RunWithCheck(TempLine);
      TempLine.Delete();
    until OrderComponent.Next() = 0;
    LineNo += 10000;
    TempLine.Init();
    TempLine."Line No." := LineNo;
    TempLine."Document No." := Order."No.";
    TempLine."Source Code" := SourceCode."Output Journal";
    TempLine.Validate("Posting Date", Date);
    TempLine.Validate("Document Date", Date);
    TempLine.Validate("Entry Type", TempLine."Entry Type"::Output);
    TempLine.Validate("Order Type", TempLine."Order Type"::Production);
    TempLine.Validate("Order No.", Order."No.");
    TempLine.Validate("Order Line No.", OrderLine."Line No.");
    TempLine.Validate("Item No.", OrderLine."Item No.");
    TempLine.Validate("Location Code", OrderLine."Location Code");
    TempLine.Validate("Output Quantity", OrderLine.Quantity);
    TempLine.Insert();
    PostLine.RunWithCheck(TempLine);
  end;

  /// <summary>Read-only validation: BOM, order status and quantity, and for posted orders the standard consumption/output entries.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Date: Date)
  var
    Assembly: Codeunit "BCSF Assembly Processor";
    Entry: Record "BCSF Generated Record";
    Order: Record "Production Order";
    BomHeader: Record "Production BOM Header";
    ItemEntry: Record "Item Ledger Entry";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Kind: Integer;
    Quantity: Decimal;
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'PRODUCTION*');
    Kind := EffectiveKind(Context, NodeCode, LogicalKey, Invoice);
    if Kind = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'PRODUCTION-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Purch. Inv. Header");
      if not (Entry."Skip Reason Code" in ['STOCK', 'SOURCE']) then
        Error(ResultErr);
      exit;
    end;
    Assembly.Components(Invoice, ItemNos, Locations, Measures);
    Quantity := Assembly.AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    Entry.SetRange("Artifact Code", 'PRODUCTION-BOM');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Production BOM Header");
    BomHeader.GetBySystemId(Entry."Record SystemId");
    BomHeader.TestField(Status, BomHeader.Status::Certified);
    Entry.SetRange("Artifact Code", 'PRODUCTION-ORDER');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Production Order");
    Order.GetBySystemId(Entry."Record SystemId");
    Order.TestField(Quantity, Quantity);
    Order.TestField("Location Code", Locations[1]);
    if Kind = 1 then begin
      Order.TestField(Status, Order.Status::Released);
      exit;
    end;
    Order.TestField(Status, Order.Status::Finished);
    ItemEntry.SetRange("Order Type", ItemEntry."Order Type"::Production);
    ItemEntry.SetRange("Order No.", Order."No.");
    ItemEntry.SetRange("Entry Type", ItemEntry."Entry Type"::Output);
    ItemEntry.SetRange("Posting Date", Date);
    ItemEntry.CalcSums(Quantity);
    if ItemEntry.Quantity <> Quantity then
      Error(ResultErr);
    ItemEntry.SetRange("Entry Type", ItemEntry."Entry Type"::Consumption);
    if ItemEntry.IsEmpty() then
      Error(ResultErr);
  end;

  var
    ProductLbl: Label 'Produced %1', Comment = '%1 = description of the first component';
    ResultErr: Label 'Manufacturing results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
