namespace BCScenarioFactory.Sales;

using BCScenarioFactory.Planning;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ProcessEngine;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 90426 "BCSF Sales Generator" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  var
    Index: Integer;
  begin
    for Index := 1 to 4 do begin
      Capabilities.Init();
      Capabilities."Generator Code" := 'SALES.DOCUMENT';
      Capabilities."Entity Code" := CopyStr(SelectStr(Index, 'SALES.QUOTE,SALES.ORDER,SALES.INVOICE,SALES.BLANKET'), 1, 30);
      Capabilities."Module Code" := 'SALES';
      Capabilities.Name := NameLbl;
      Capabilities.Version := '1';
      Capabilities."Contract Version" := 1;
      Capabilities."Minimum Mode" := "BCSF Process Mode"::UnpostedDocuments;
      Capabilities."Maximum Mode" := "BCSF Process Mode"::PostedMovements;
      // Quotes and blanket orders are never posted.
      if Index in [1, 4] then
        Capabilities."Maximum Mode" := "BCSF Process Mode"::UnpostedDocuments;
      Capabilities."Maximum Batch Size" := 100;
      Capabilities."Contract Probe" := false;
      Capabilities.Insert();
    end;
  end;

  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray)
  var
    Finding: JsonObject;
  begin
    Clear(Findings);
    if not TryCheck(Context, Target) then begin
      Finding.Add('code', 'SALES.SETUP');
      Finding.Add('message', GetLastErrorText());
      ClearLastError();
      Findings.Add(Finding);
    end;
  end;

  [TryFunction]
  local procedure TryCheck(Context: JsonObject; Target: JsonObject)
  var
    Setup: Codeunit "BCSF Sales Setup";
  begin
    Setup.Check(Context, Target);
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Partner Rules", 'OnInspectDocument', '', false, false)]
  local procedure InspectDocument(Context: JsonObject; Target: JsonObject; LogicalKey: Integer; var Reason: Code[30])
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    if not (Contract.GetCode(Target, 'entityCode') in ['SALES.QUOTE', 'SALES.ORDER', 'SALES.INVOICE', 'SALES.BLANKET']) then
      exit;
    Reason := 'SOURCE';
    if TryInspectDocument(Context, Target, LogicalKey, Reason) then
      Clear(Reason)
    else
      ClearLastError();
  end;

  [TryFunction]
  local procedure TryInspectDocument(Context: JsonObject; Target: JsonObject; LogicalKey: Integer; var Reason: Code[30])
  var
    Customer: Record Customer;
    Item: Record Item;
    Foundation: Codeunit "BCSF Demo Partner Setup";
    Setup: Codeunit "BCSF Sales Setup";
    Source: Codeunit "BCSF Master Data Source";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Contract: Codeunit "BCSF Contract JSON";
    EntityCode: Code[30];
    LineIndex: Integer;
    ItemKey: Integer;
    LocationCode: Code[10];
  begin
    // No document, dimension-set creation, number consumption or posting here.
    Context := Setup.WithRunMasters(Context);
    EntityCode := Contract.GetCode(Target, 'entityCode');
    LocationCode := CopyStr(Contract.GetText(Setup.ReadSettings(Context), 'location'), 1, 10);
    Reason := 'CUSTOMER';
    Setup.CustomerFor(Context, LogicalKey, Customer);
    Setup.CheckCustomer(Customer);
    if Coordinator.Disposition(Context, EntityCode, LogicalKey) > 0 then
      Foundation.CheckInvoiceRounding(true, Customer."Customer Posting Group");
    for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, LogicalKey) do begin
      Reason := 'ITEM';
      ItemKey := LogicalKey;
      if Coordinator.IsWholesaleQualityProfile(Context) then
        ItemKey := Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex);
      Setup.ItemFor(Context, ItemKey, Item);
      Setup.CheckItem(Item);
      Reason := 'SOURCE';
      Setup.CheckFrozenMasters(Context, Customer, Item);
      Reason := 'DIMENSION';
      Source.CheckSalesCandidate(Customer, Item, LocationCode);
    end;
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  var
    Setup: Codeunit "BCSF Sales Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
  begin
    Clear(Dependencies);
    if not Setup.UsesRunMasters(Context) and not Context.Contains('masterDataSource') then
      exit;
    if Setup.UsesRunMasters(Context) then begin
      AddPredecessor(Dependencies, 'CUSTOMER', 'SALES');
      AddPredecessor(Dependencies, 'VENDOR', 'PURCHASING');
      AddPredecessor(Dependencies, 'ITEM', 'INVENTORY');
    end;
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do
      if (Contract.GetInteger(Token.AsObject(), 'entity') = "BCSF Entity Type"::PurchaseOrder.AsInteger()) and
        (Contract.GetInteger(Token.AsObject(), 'quantity') > 0) then
        AddPredecessor(Dependencies, 'PURCHASE.ORDER', 'PURCHASING');
  end;

  local procedure AddPredecessor(var Dependencies: JsonArray; EntityCode: Code[30]; ModuleCode: Code[30])
  var
    Requirement: JsonObject;
  begin
    Requirement.Add('entityCode', EntityCode);
    Requirement.Add('moduleCode', ModuleCode);
    Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
    Requirement.Add('minimumMode', 1);
    Requirement.Add('maximumMode', 2);
    Dependencies.Add(Requirement);
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Rules: Codeunit "BCSF Partner Rules";
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Rules.Plan(Contract.GetCode(Target, 'entityCode'), Context, Target, FirstKey, MaximumBatches, Batches);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Entry: Record "BCSF Generated Record";
    Rules: Codeunit "BCSF Partner Rules";
    Setup: Codeunit "BCSF Sales Setup";
    Documents: Codeunit "BCSF Sales Documents";
    Contract: Codeunit "BCSF Contract JSON";
    RunId: Guid;
    BatchId: Guid;
    EntityCode: Code[30];
    LogicalKey: Integer;
  begin
    Rules.EnsureExecution(Context, Target, Batch, 'SALES.DOCUMENT', RunId, BatchId);
    Setup.Check(Context, Target);
    Context := Setup.WithRunMasters(Context);
    Context.Add('executingBatch', Contract.Clone(Batch));
    EntityCode := Contract.GetCode(Target, 'entityCode');
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", EntityCode);
    Entry.SetRange("Logical Key", Contract.GetInteger(Batch, 'firstKey'), Contract.GetInteger(Batch, 'lastKey'));
    if not Entry.IsEmpty() then
      Error(ResultErr);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do
      Documents.Create(Context, EntityCode, LogicalKey, RunId, BatchId);
    Result.Add('generatorCode', 'SALES.DOCUMENT');
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

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Header: Record "Sales Header";
    Line: Record "Sales Line";
    Invoice: Record "Sales Invoice Header";
    InvoiceLine: Record "Sales Invoice Line";
    Customer: Record Customer;
    Item: Record Item;
    Setup: Codeunit "BCSF Sales Setup";
    Source: Codeunit "BCSF Master Data Source";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Payments: Codeunit "BCSF Payment Processor";
    Credits: Codeunit "BCSF Credit Memo Processor";
    PlanningProcessor: Codeunit "BCSF Planning Processor";
    Selection: Codeunit "BCSF Module Selection";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    Mode: Integer;
    EntityCode: Code[30];
    Quantity: Decimal;
    LineIndex: Integer;
  begin
    Clear(Findings);
    Contract.CheckBatch(Context, Target, Batch);
    Context := Setup.WithRunMasters(Context);
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Evaluate(BatchId, Contract.GetText(Context, 'batchId'));
    EntityCode := Contract.GetCode(Target, 'entityCode');
    if Contract.GetInteger(Result, 'processedUnits') <> Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1 then
      Error(ResultErr);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      Setup.CustomerFor(Context, LogicalKey, Customer);
      Mode := Coordinator.Disposition(Context, EntityCode, LogicalKey);
      // In movement-only runs an invoice without stock is retained as an
      // unposted document. Validate the persisted result, not planned posting.
      if (Mode > 0) and Context.Contains('masterDataSource') then
        if not Entry.Get(RunId, EntityCode, LogicalKey, 'INVOICE') then begin
          Entry.Get(RunId, EntityCode, LogicalKey, 'DOCUMENT');
          if Source.UsesSelectedPool(Context) then begin
            Entry.TestField("Posting Skipped", true);
            Entry.TestField("Skip Reason Code", 'STOCK');
          end;
          Mode := 0;
        end;
      Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
      if Mode > 0 then begin
        Entry.Get(RunId, EntityCode, LogicalKey, 'INVOICE');
        Entry.TestField("Batch Id", BatchId);
        Invoice.GetBySystemId(Entry."Record SystemId");
        Invoice.TestField("Posting Date", Coordinator.DocumentDate(Context, EntityCode, LogicalKey));
        if Contract.GetDatePolicyVersion(Context) = 1 then
          Invoice.TestField("Document Date", Coordinator.DocumentDate(Context, EntityCode, LogicalKey));
        Invoice.TestField("Sell-to Customer No.", Customer."No.");
        if Payments.Enabled(Context) then begin
          Payments.ValidatePayment(RunId, EntityCode, LogicalKey, Invoice."Cust. Ledger Entry No.", true);
          if Credits.Enabled(Context) then
            Credits.ValidateForSalesInvoice(Context, RunId, EntityCode, LogicalKey, Invoice);
          if PlanningProcessor.Enabled(Context) then
            PlanningProcessor.ValidateForSalesInvoice(Context, RunId, EntityCode, LogicalKey, Invoice);
          Selection.ValidateForSalesInvoice(Context, RunId, EntityCode, LogicalKey, Invoice);
        end;
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, LogicalKey) do begin
          if Coordinator.IsWholesaleQualityProfile(Context) then begin
            Setup.ItemFor(Context, Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex), Item);
            Quantity := Coordinator.WholesaleSalesLineQuantity(Context, EntityCode, LogicalKey, LineIndex);
          end else begin
            Setup.ItemFor(Context, LogicalKey, Item);
            Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
          end;
          InvoiceLine.Get(Invoice."No.", LineIndex * 10000);
          InvoiceLine.TestField(Type, InvoiceLine.Type::Item);
          InvoiceLine.TestField("No.", Item."No.");
          InvoiceLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
          if Mode = 1 then
            InvoiceLine.TestField(Quantity, Quantity)
          else
            InvoiceLine.TestField(Quantity, Quantity / 2);
        end;
      end;
      if Mode <> 1 then begin
        Entry.Get(RunId, EntityCode, LogicalKey, 'DOCUMENT');
        Entry.TestField("Batch Id", BatchId);
        Header.GetBySystemId(Entry."Record SystemId");
        if Contract.GetDatePolicyVersion(Context) = 1 then begin
          Header.TestField("Posting Date", Coordinator.DocumentDate(Context, EntityCode, LogicalKey));
          Header.TestField("Document Date", Coordinator.DocumentDate(Context, EntityCode, LogicalKey));
          Header.TestField("Order Date", Coordinator.DocumentDate(Context, EntityCode, LogicalKey));
        end;
        Header.TestField("Sell-to Customer No.", Customer."No.");
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, LogicalKey) do begin
          if Coordinator.IsWholesaleQualityProfile(Context) then begin
            Setup.ItemFor(Context, Coordinator.WholesaleSalesItemKey(Context, EntityCode, LogicalKey, LineIndex), Item);
            Quantity := Coordinator.WholesaleSalesLineQuantity(Context, EntityCode, LogicalKey, LineIndex);
          end else begin
            Setup.ItemFor(Context, LogicalKey, Item);
            Quantity := Coordinator.Quantity(Context, EntityCode, LogicalKey);
          end;
          Line.Get(Header."Document Type", Header."No.", LineIndex * 10000);
          Line.TestField("No.", Item."No.");
          Line.TestField("Unit of Measure Code", Item."Base Unit of Measure");
          Line.TestField(Quantity, Quantity);
          if Mode = 0 then begin
            Line.TestField("Quantity Shipped", 0);
            Line.TestField("Quantity Invoiced", 0);
          end else begin
            Line.TestField("Quantity Shipped", Quantity / 2);
            Line.TestField("Quantity Invoiced", Quantity / 2);
            Line.TestField("Outstanding Quantity", Quantity / 2);
          end;
        end;
      end;
    end;
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    if Entry.Count() <> Contract.GetInteger(Result, 'createdRecords') then
      Error(ResultErr);
    if Entry.FindSet() then
      repeat
        if not Registry.ExistsByIdentity(Entry) then
          Error(ResultErr);
      until Entry.Next() = 0;
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(ResultErr);
  end;

  var
    NameLbl: Label 'Sales Quotes, Blanket Orders, Orders and Invoices';
    ResultErr: Label 'Sales results are missing, changed or already registered. Review the batch and its checkpoint; do not repeat uncertain posting.';
}
