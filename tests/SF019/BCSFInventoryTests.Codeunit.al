#if BCSFTESTS
namespace BCScenarioFactory.Inventory.Tests;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Sales;
using BCScenarioFactory.Purchasing;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Finance;
using BCScenarioFactory.ProcessEngine;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.Monitoring;
using Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.Receivables;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Bank.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

codeunit 90700 "BCSF Inventory Tests"
{
  Subtype = Test;

  [Test]
  procedure DashboardMarksRetainExistingFilters()
  var
    TempCustomer: Record Customer temporary;
    TempView: Record Customer temporary;
    Rows: RecordRef;
  begin
    TempCustomer.Init();
    TempCustomer."No." := 'VISIBLE';
    TempCustomer.Name := 'Visible';
    TempCustomer.Insert();
    TempCustomer."No." := 'HIDDEN';
    TempCustomer.Name := 'Hidden';
    TempCustomer.Insert();
    TempView.Copy(TempCustomer, true);
    Rows.GetTable(TempCustomer);
    Rows.FindSet();
    repeat
      Rows.Mark(true);
    until Rows.Next() = 0;
    TempCustomer.SetRange(Name, 'Visible');
    Rows.SetView(TempCustomer.GetView());
    Rows.MarkedOnly(true);
    Rows.SetTable(TempView, false);
    Assert(TempView.MarkedOnly(), 'Standard-list record must retain the marks filter.');
    Assert(TempView.Count() = 1, 'Existing filters must intersect the marked identities.');
    Rows.Close();
  end;

  [Test]
  procedure CompletedMediumDashboardShowsLiveCounts()
  var
    Setup: Record "BCSF Factory Setup";
    Execution: Record "BCSF Run Execution";
    Entry: Record "BCSF Generated Record";
    Stock: Codeunit "BCSF Dashboard Stock";
    Rows: RecordRef;
    View: JsonObject;
    Metrics: JsonToken;
    Metric: JsonToken;
    Value: JsonToken;
    TableIds: array[5] of Integer;
    Keys: array[5] of Text;
    Index: Integer;
    Visible: Integer;
    Found: Boolean;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Size", 1);
    Execution.Get(Setup."Industry Run Id");
    Execution.TestField(Status, Execution.Status::Completed);
    TableIds[1] := Database::Customer;
    TableIds[2] := Database::Item;
    TableIds[3] := Database::"Item Unit of Measure";
    TableIds[4] := Database::"Item Reference";
    TableIds[5] := Database::"Item Attribute Value Mapping";
    Keys[1] := 'customer';
    Keys[2] := 'item';
    Keys[3] := 'itemUnit';
    Keys[4] := 'itemReference';
    Keys[5] := 'attributeMapping';
    View := Stock.Build('master', false, Setup."Industry Run Id");
    View.Get('metrics', Metrics);
    for Index := 1 to ArrayLen(TableIds) do begin
      Entry.Reset();
      Entry.SecurityFiltering(SecurityFilter::Filtered);
      Entry.SetRange("Run Id", Setup."Industry Run Id");
      Entry.SetRange("Table Id", TableIds[Index]);
      Rows.Open(TableIds[Index]);
      Rows.SecurityFiltering(SecurityFilter::Filtered);
      Visible := 0;
      if Entry.FindSet() then
        repeat
          if Rows.GetBySystemId(Entry."Record SystemId") then
            Visible += 1;
        until Entry.Next() = 0;
      Rows.Close();
      Found := false;
      foreach Metric in Metrics.AsArray() do begin
        Metric.AsObject().Get('key', Value);
        if Value.AsValue().AsText() = Keys[Index] then begin
          Assert(Metric.AsObject().Get('count', Value), 'A medium run must not lose its live count.');
          Assert(Value.AsValue().AsInteger() = Visible, 'Run count must match visible surviving provenance identities.');
          Metric.AsObject().Get('canOpen', Value);
          Assert(Value.AsValue().AsBoolean() = (Visible > 0), 'Each nonempty readable result must have a list route.');
          Found := true;
        end;
      end;
      Assert(Found, 'Missing dashboard metric.');
    end;
  end;

  [Test]
  procedure StandardPostingAcceptsAssignedIndirectRights()
  var
    TempPermission: Record "Expanded Permission" temporary;
    Guard: Codeunit "BCSF Environment Guard";
  begin
    TempPermission."Insert Permission" := TempPermission."Insert Permission"::Indirect;
    TempPermission."Modify Permission" := TempPermission."Modify Permission"::Indirect;
    Assert(Guard.AllowsStandardPosting(TempPermission, true), 'Standard posting must accept assigned indirect insert and modify rights.');
    TempPermission."Modify Permission" := TempPermission."Modify Permission"::" ";
    Assert(Guard.AllowsStandardPosting(TempPermission, false), 'Posting new evidence does not require direct modify rights.');
    Assert(not Guard.AllowsStandardPosting(TempPermission, true), 'Application requires assigned modify rights.');
    TempPermission."Insert Permission" := TempPermission."Insert Permission"::" ";
    Assert(not Guard.AllowsStandardPosting(TempPermission, false), 'Missing insert permission must remain blocked.');
    TempPermission."Insert Permission" := TempPermission."Insert Permission"::Yes;
    TempPermission."Modify Permission" := TempPermission."Modify Permission"::Yes;
    Assert(Guard.AllowsStandardPosting(TempPermission, true), 'Assigned direct permissions must also work.');
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompanyWizardRetainsAdditionalModules()
  var
    Setup: Record "BCSF Factory Setup";
    Wizard: TestPage "BCSF Factory Setup Card";
    EmptyId: Guid;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Company Initialized", true);
    Wizard.OpenEdit();
    Wizard.InitializeSetup.Invoke();
    Wizard.NextStep.Invoke();
    Wizard.NextStep.Invoke();
    Wizard.CompanyModules.GoToKey(EmptyId, "BCSF Module Type"::Sales);
    Assert(not Wizard.CompanyModules.Enabled.Editable(), 'Required modules must be locked.');
    Wizard.CompanyModules.GoToKey(EmptyId, "BCSF Module Type"::Warehouse);
    Assert(Wizard.CompanyModules.Enabled.Editable(), 'Additional modules must be selectable.');
    Wizard.CompanyModules.Enabled.SetValue(true);
    Wizard.NextStep.Invoke();
    Wizard.PreviousStep.Invoke();
    Wizard.CompanyModules.GoToKey(EmptyId, "BCSF Module Type"::Warehouse);
    Wizard.CompanyModules.Enabled.AssertEquals(true);
    Wizard.NextStep.Invoke();
    Wizard.NextStep.Invoke();
    asserterror Wizard.StartingDate.SetValue(Today());
    Wizard.StartingDate.SetValue(Today() - 90);
    Wizard.EndingDate.AssertEquals(Today() - 1);
    Wizard.NextStep.Invoke();
    Assert(StrPos(Wizard.Review.Value(), Format(Today() - 90)) > 0, 'Summary must show the chosen starting date.');
    Assert(StrPos(Wizard.Review.Value(), Format("BCSF Module Type"::Warehouse)) > 0, 'Summary must retain the planning selection.');
    Wizard.Close();
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompanyRequestDateRangeCannotChangeWithoutTriggers()
  var
    Setup: Record "BCSF Factory Setup";
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Job Id");
    Setup."Industry Ending Date" += 1;
    asserterror Setup.Modify(false);
    Setup.Get(Setup.GetSetupKey());
    Setup."Industry Date" += 1;
    asserterror Setup.Modify(false);
  end;

  [Test]
  procedure CompanyDateRangeRejectsEmptyTodayAndFuture()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
    LatestDate: Date;
  begin
    LatestDate := Today() - 1;
    Profile.CheckDateRange(LatestDate, LatestDate, LatestDate);
    Profile.CheckDateRange(CalcDate('<-1Y>', LatestDate), LatestDate, LatestDate);
    asserterror Profile.CheckDateRange(0D, LatestDate, LatestDate);
    asserterror Profile.CheckDateRange(Today(), LatestDate, LatestDate);
    asserterror Profile.CheckDateRange(Today() + 1, LatestDate, LatestDate);
    asserterror Profile.CheckDateRange(LatestDate, 0D, LatestDate);
    asserterror Profile.CheckDateRange(LatestDate, Today(), LatestDate);
  end;

  [Test]
  procedure BusinessDatesAreReproducibleAndRespectInvoiceDate()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Payments: Codeunit "BCSF Payment Processor";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    OtherRun: JsonObject;
    StartingDate: Date;
    EndingDate: Date;
    Date: Date;
    PaidOn: Date;
    LogicalKey: Integer;
    EntityCode: Code[30];
    Entity: Integer;
    Dates: Dictionary of [Date, Boolean];
  begin
    StartingDate := DMY2Date(1, 1, 2026);
    EndingDate := DMY2Date(20, 11, 2026);
    Context := ContextFixture();
    Context.Add('startingDate', Format(StartingDate, 0, 9));
    Context.Add('endingDate', Format(EndingDate, 0, 9));
    Assert(Payments.PaymentDate(Context, 'SALES.ORDER', 1, StartingDate) = StartingDate, 'Legacy payments must retain the captured invoice date.');
    Context.Add('datePolicyVersion', 1);
    OtherRun := Contract.Clone(Context);
    OtherRun.Replace('runId', Format(CreateGuid(), 0, 4));
    for Entity := 0 to 3 do begin
      case Entity of
        0: EntityCode := 'SALES.QUOTE';
        1: EntityCode := 'SALES.ORDER';
        2: EntityCode := 'SALES.INVOICE';
        3: EntityCode := 'PURCHASE.ORDER';
      end;
      Clear(Dates);
      for LogicalKey := 1 to 40 do begin
        Date := Coordinator.DocumentDate(Context, EntityCode, LogicalKey);
        Assert((Date >= StartingDate) and (Date <= EndingDate), 'Business date escaped the captured period.');
        Assert(Date = Coordinator.DocumentDate(OtherRun, EntityCode, LogicalKey), 'Run identity must not change dates.');
        Dates.Set(Date, true);
        PaidOn := Payments.PaymentDate(Context, EntityCode, LogicalKey, Date);
        Assert((PaidOn >= Date) and (PaidOn <= EndingDate), 'Payment must be between invoice and period end.');
        Assert(PaidOn = Payments.PaymentDate(OtherRun, EntityCode, LogicalKey, Date), 'Payment date must be reproducible.');
      end;
      Assert(Dates.Count() > 1, 'A multi-day period must produce varied dates for this fixture.');
    end;
    Context.Replace('endingDate', Format(StartingDate, 0, 9));
    Assert(Coordinator.DocumentDate(Context, 'SALES.ORDER', 1) = StartingDate, 'A one-day period is valid.');
    Assert(Payments.PaymentDate(Context, 'SALES.ORDER', 1, StartingDate) = StartingDate, 'One-day payment must remain in range.');
    Context.Replace('datePolicyVersion', 99);
    asserterror Contract.CheckContext(Context);
  end;

  [Test]
  procedure RandomReceiptsPrecedeDependentSalesAcrossSizes()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    LatestReceipt: Dictionary of [Integer, Date];
    Size: Integer;
    LogicalKey: Integer;
    Items: Integer;
    SourceItems: Integer;
    ItemKey: Integer;
    Kind: Integer;
    SalesCount: Integer;
    EntityCode: Code[30];
    StartingDate: Date;
    EndingDate: Date;
    ReceiptDate: Date;
    Date: Date;
    VariedReceipt: Boolean;
  begin
    StartingDate := DMY2Date(1, 1, 2026);
    EndingDate := DMY2Date(20, 11, 2026);
    for Size := 0 to 2 do begin
      Clear(LatestReceipt);
      VariedReceipt := false;
      Context := ContextFixture();
      Context.Replace('processMode', 3);
      Context.Add('datePolicyVersion', 1);
      Context.Add('startingDate', Format(StartingDate, 0, 9));
      Context.Add('endingDate', Format(EndingDate, 0, 9));
      Items := Profile.Quantity(Size, "BCSF Entity Type"::Item);
      Clear(Targets);
      AddMixedTarget(Targets, "BCSF Entity Type"::Item, Items, 0, 0);
      AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, Profile.Quantity(Size, "BCSF Entity Type"::PurchaseOrder), 60, 20);
      AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, Profile.Quantity(Size, "BCSF Entity Type"::SalesOrder), 50, 25);
      AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, Profile.Quantity(Size, "BCSF Entity Type"::SalesInvoice), 67, 0);
      Context.Replace('targets', Targets);
      for LogicalKey := 1 to Profile.Quantity(Size, "BCSF Entity Type"::PurchaseOrder) do
        if Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey) > 0 then begin
          ReceiptDate := Coordinator.PurchaseDate(Context, LogicalKey);
          Assert((ReceiptDate >= StartingDate) and (ReceiptDate <= EndingDate), 'Receipt escaped the captured period.');
          VariedReceipt := VariedReceipt or (ReceiptDate > StartingDate);
          ItemKey := 1 + ((LogicalKey - 1) mod Items);
          if LatestReceipt.Get(ItemKey, Date) then begin
            if ReceiptDate > Date then
              LatestReceipt.Set(ItemKey, ReceiptDate);
          end else
            LatestReceipt.Add(ItemKey, ReceiptDate);
        end;
      Assert(VariedReceipt, 'Posted receipts must no longer all use the first period day.');
      SourceItems := Items;
      if SourceItems > 100 then
        SourceItems := 100;
      for Kind := 0 to 1 do begin
        if Kind = 0 then begin
          EntityCode := 'SALES.ORDER';
          SalesCount := Profile.Quantity(Size, "BCSF Entity Type"::SalesOrder);
        end else begin
          EntityCode := 'SALES.INVOICE';
          SalesCount := Profile.Quantity(Size, "BCSF Entity Type"::SalesInvoice);
        end;
        for LogicalKey := 1 to SalesCount do
          if Coordinator.Disposition(Context, EntityCode, LogicalKey) > 0 then begin
            ItemKey := 1 + ((LogicalKey - 1) mod SourceItems);
            Assert(LatestReceipt.Get(ItemKey, ReceiptDate), 'Posted sale has no planned receipt.');
            Assert(ReceiptDate <= Coordinator.DocumentDate(Context, EntityCode, LogicalKey), 'A sale precedes its stock receipt.');
          end;
      end;
    end;
  end;

  [Test]
  procedure CompanyModulesKeepRequiredIndustryScope()
  var
    TempModules: Record "BCSF Scenario Module" temporary;
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    Profile.LoadModules('', TempModules);
    Assert(TempModules.Count() = 12, 'All existing business module types must be visible.');
    TempModules.SetRange(Enabled, true);
    Assert(TempModules.Count() = 4, 'Wholesale must include Sales, Purchasing, Inventory and Finance.');
    Assert(Profile.EncodeAdditionalModules(TempModules) = '', 'Default package has no planning additions.');
    TempModules.Module := TempModules.Module::Inventory;
    TempModules.Get(TempModules."Scenario Id", TempModules.Module);
    TempModules.Enabled := false;
    TempModules.Modify();
    asserterror Profile.EncodeAdditionalModules(TempModules);
  end;

  [Test]
  procedure CompanyModulesRoundTripAndRejectInvalidRequests()
  var
    TempModules: Record "BCSF Scenario Module" temporary;
    Profile: Codeunit "BCSF Wholesale Profile";
    Encoded: Text;
  begin
    Encoded := 'WAREHOUSE|MANUFACTURING|ASSEMBLY|PROJECTS|SERVICE|FIXEDASSETS|CRM|PLANNING';
    Profile.LoadModules(Encoded, TempModules);
    Assert(Profile.EncodeAdditionalModules(TempModules) = Encoded, 'All planning choices must survive request transport.');
    TempModules.SetRange(Enabled, true);
    Assert(TempModules.Count() = 12, 'All optional modules must remain selected.');
    Profile.LoadModules('', TempModules);
    Assert(Profile.EncodeAdditionalModules(TempModules) = '', 'Clearing additions must restore the base package.');
    asserterror Profile.LoadModules('UNKNOWN', TempModules);
    asserterror Profile.LoadModules('WAREHOUSE|WAREHOUSE', TempModules);
    asserterror Profile.LoadModules('SALES', TempModules);
    asserterror Profile.LoadModules('CRM|WAREHOUSE', TempModules);
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompanyPlanningModulesRemainTargetlessAndCaptured()
  var
    Setup: Record "BCSF Factory Setup";
    Selection: Record "BCSF Scenario Module";
    TempCaptured: Record "BCSF Scenario Module" temporary;
    Target: Record "BCSF Data Target";
    Scenario: Record "BCSF Scenario";
    Header: Record "BCSF Run Header";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Profile: Codeunit "BCSF Wholesale Profile";
    Writer: Codeunit "BCSF Snapshot Writer";
    Manager: Codeunit "BCSF Scenario Manager";
    ScenarioId: Guid;
    RunId: Guid;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Company Initialized", true);
    ScenarioId := Profile.CreateTemplateForId(CreateGuid(), 0, "BCSF Process Mode"::UnpostedDocuments, Today() - 90, Today() - 1, 'WAREHOUSE|CRM');
    Selection.SetRange("Scenario Id", ScenarioId);
    Assert(Selection.Count() = 6, 'Four required and two planning modules must be saved.');
    Target.SetRange("Scenario Id", ScenarioId);
    Assert(Target.Count() = 7, 'Planning additions must not invent targets.');
    Target.SetFilter(Module, '%1|%2', "BCSF Module Type"::Warehouse, "BCSF Module Type"::CRM);
    Assert(Target.IsEmpty(), 'Planned modules must have no work or generated result promise.');
    RunId := Writer.CreateSnapshot(ScenarioId);
    Selection.Get(ScenarioId, "BCSF Module Type"::CRM);
    Selection.Enabled := false;
    Selection.Modify(true);
    Header.Get(RunId);
    Header.TestField("Starting Date", Today() - 90);
    Header.TestField("Ending Date", Today() - 1);
    Manager.ReadSnapshot(RunId, Context);
    Assert(Contract.GetDatePolicyVersion(Context) = 1, 'New snapshot must capture the date policy.');
    Manager.LoadFrozenModules(RunId, TempCaptured);
    TempCaptured.Get(RunId, "BCSF Module Type"::CRM);
    TempCaptured.TestField(Enabled, true);
    Scenario.Get(ScenarioId);
    Scenario.TestField("Starting Date", Today() - 90);
    Scenario.TestField("Ending Date", Today() - 1);
    Scenario.TestField("Payment Posting Approved", false);
    Manager.RequireExecutableTargets(Scenario);
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompanyModuleStarterPreservesCustomValues()
  var
    Scenario: Record "BCSF Scenario";
    Selection: Record "BCSF Scenario Module";
    Target: Record "BCSF Data Target";
    Removed: Record "BCSF Removed Template";
    Catalog: Codeunit "BCSF Starter Catalog";
    Id: Guid;
    WasPresent: Boolean;
    CountBefore: Integer;
    RevisionBefore: Integer;
  begin
    Evaluate(Id, '{B55C4500-AB51-4045-9C00-000000000004}');
    WasPresent := Scenario.Get(Id);
    Catalog.Seed();
    if Removed.Get(Id) then begin
      Assert(not Scenario.Get(Id), 'An intentionally removed starter must not be recreated.');
      exit;
    end;
    Scenario.Get(Id);
    if WasPresent then
      exit;
    Scenario.TestField("Sales Posting Approved", false);
    Scenario.TestField("Purchase Posting Approved", false);
    Scenario.TestField("Payment Posting Approved", false);
    Scenario.TestField("Starting Date", CalcDate('<-1Y>', Today()));
    Scenario.TestField("Ending Date", Today() - 1);
    Selection.SetRange("Scenario Id", Id);
    Assert(Selection.Count() = 6, 'Module starter must include the base and Warehouse/CRM planning selections.');
    Target.SetRange("Scenario Id", Id);
    Assert(Target.Count() = 7, 'Only the seven supported wholesale targets are executable.');
    Scenario.Description := 'CUSTOM MODULE STARTER';
    Scenario.Modify(true);
    RevisionBefore := Scenario.Revision;
    CountBefore := Scenario.Count();
    Catalog.Seed();
    Assert(Scenario.Count() = CountBefore, 'Reload must not duplicate templates.');
    Scenario.Get(Id);
    Scenario.TestField(Description, 'CUSTOM MODULE STARTER');
    Scenario.TestField(Revision, RevisionBefore);
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure CompanyRequestModulesCannotChangeWithoutTriggers()
  var
    Setup: Record "BCSF Factory Setup";
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Job Id");
    if Setup."Industry Additional Modules" = '' then
      Setup."Industry Additional Modules" := 'WAREHOUSE'
    else
      Clear(Setup."Industry Additional Modules");
    asserterror Setup.Modify(false);
  end;

  [Test]
  procedure WholesaleQuantitiesAreIndustryRatios()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    Assert(Profile.Quantity(0, "BCSF Entity Type"::Customer) = 20, 'Small customer count.');
    Assert(Profile.Quantity(0, "BCSF Entity Type"::Vendor) = 5, 'Small vendor count.');
    Assert(Profile.Quantity(0, "BCSF Entity Type"::Item) = 40, 'Small item count.');
    Assert(Profile.Quantity(0, "BCSF Entity Type"::PurchaseOrder) = 15, 'Small purchase count.');
    Assert(Profile.Quantity(1, "BCSF Entity Type"::Item) = 400, 'Medium item count.');
    Assert(Profile.Quantity(2, "BCSF Entity Type"::Item) = 4000, 'Large item count.');
    asserterror Profile.Quantity(-1, "BCSF Entity Type"::Item);
    asserterror Profile.Quantity(3, "BCSF Entity Type"::Item);
  end;

  [Test]
  procedure WholesaleRejectsUnknownProcessMode()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    asserterror Profile.CheckSelection(0, "BCSF Process Mode".FromInteger(99));
  end;

  [Test]
  procedure PurchaseCapabilityAllowsOnlySupportedModes()
  var
    Capabilities: Record "BCSF Generator Registry" temporary;
    Generator: Codeunit "BCSF Purchase Generator";
  begin
    Generator.DescribeCapabilities(Capabilities);
    Capabilities.Get('PURCHASE.DOCUMENT', 'PURCHASE.ORDER');
    Capabilities.TestField("Contract Probe", false);
    Capabilities.TestField("Minimum Mode", "BCSF Process Mode"::UnpostedDocuments);
    Capabilities.TestField("Maximum Mode", "BCSF Process Mode"::PostedMovements);
    Assert(Capabilities.Count() = 1, 'Only supported purchase orders may be registered.');
  end;

  [Test]
  procedure WholesaleReferenceHasNoExternalFinanceGate()
  var
    Setup: Record "BCSF Factory Setup";
    Nodes: Record "BCSF Plan Node" temporary;
    Edges: Record "BCSF Dependency" temporary;
    Planner: Codeunit "BCSF Dependency Planner";
    RunId: Guid;
  begin
    Setup.Get(Setup.GetSetupKey());
    RunId := Setup."Industry Run Id";
    Assert(not IsNullGuid(RunId), 'First run the documented fresh wholesale company reference.');
    Assert(Planner.BuildFromRun(RunId, Nodes, Edges), 'Wholesale must have an executable dependency graph.');
    Assert(not Nodes.Get('FINANCE.SETUP'), 'Company foundation is checked by the existing setup gate, not a missing finance generator.');
    Edges.Get('PURCHASE.ORDER', 'ITEM');
    Edges.Get('PURCHASE.ORDER', 'VENDOR');
    Edges.Get('SALES.ORDER', 'ITEM');
    Edges.Get('SALES.ORDER', 'PURCHASE.ORDER');
  end;

  [Test]
  procedure CompletedSmallWholesaleReferenceUsesSameRunSources()
  var
    Setup: Record "BCSF Factory Setup";
    Header: Record "BCSF Run Header";
    Execution: Record "BCSF Run Execution";
    Entry: Record "BCSF Generated Record";
    Source: Record "BCSF Generated Record";
    Order: Record "Purchase Header";
    Line: Record "Purchase Line";
    Item: Record Item;
    Supplier: Record Vendor;
    RunId: Guid;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Size", 0);
    Setup.TestField("Industry Process Mode", "BCSF Process Mode"::UnpostedDocuments);
    RunId := Setup."Industry Run Id";
    Header.Get(RunId);
    Header.TestField("Profile Code", 'TRADE');
    Assert(Header."Profile Version" in ['3', '4'], 'Wholesale reference must use its supported immutable version.');
    Execution.Get(RunId);
    Execution.TestField(Status, Execution.Status::Completed);
    AssertWholesaleCount(RunId, 'CUSTOMER', 'CUSTOMER', 20);
    AssertWholesaleCount(RunId, 'VENDOR', 'VENDOR', 5);
    AssertWholesaleCount(RunId, 'ITEM', 'ITEM', 40);
    AssertWholesaleCount(RunId, 'PURCHASE.ORDER', 'DOCUMENT', 15);
    AssertWholesaleCount(RunId, 'SALES.QUOTE', 'DOCUMENT', 5);
    AssertWholesaleCount(RunId, 'SALES.ORDER', 'DOCUMENT', 12);
    AssertWholesaleCount(RunId, 'SALES.INVOICE', 'DOCUMENT', 3);
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'PURCHASE.ORDER');
    Entry.FindSet();
    repeat
      Order.GetBySystemId(Entry."Record SystemId");
      Line.Get(Order."Document Type", Order."No.", 10000);
      Line.TestField("Quantity Received", 0);
      Line.TestField("Quantity Invoiced", 0);
      Item.Get(Line."No.");
      Order.TestField("Buy-from Vendor No.", Item."Vendor No.");
      Supplier.Get(Item."Vendor No.");
      Source.Reset();
      Source.SetRange("Run Id", RunId);
      Source.SetRange("Node Code", 'VENDOR');
      Source.SetRange("Record SystemId", Supplier.SystemId);
      Assert(not Source.IsEmpty(), 'Supplier must originate in the same run.');
      Source.SetRange("Node Code", 'ITEM');
      Source.SetRange("Record SystemId", Item.SystemId);
      Assert(not Source.IsEmpty(), 'Item must originate in the same run.');
    until Entry.Next() = 0;
    Entry.Reset();
    Entry.SetRange("Run Id", RunId);
    Entry.SetFilter("Table Id", '%1|%2|%3', Database::"G/L Entry", Database::"Item Ledger Entry", Database::"VAT Entry");
    Assert(Entry.IsEmpty(), 'Unposted company must not register posting entries.');
  end;

  [Test]
  procedure PlannedReceiptsCoverSalesAcrossAllSizes()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    Received: Dictionary of [Integer, Decimal];
    Size: Integer;
    LogicalKey: Integer;
    ItemKey: Integer;
    Items: Integer;
    SourceItems: Integer;
    Orders: Integer;
    Invoices: Integer;
    Quantity: Decimal;
    Total: Decimal;
    Required: Decimal;
  begin
    for Size := 0 to 2 do begin
      Clear(Received);
      Context := ContextFixture();
      Context.Replace('processMode', 3);
      Context.Add('startingDate', Format(WorkDate(), 0, 9));
      Context.Add('endingDate', Format(WorkDate() + 30, 0, 9));
      Items := Profile.Quantity(Size, "BCSF Entity Type"::Item);
      Orders := Profile.Quantity(Size, "BCSF Entity Type"::SalesOrder);
      Invoices := Profile.Quantity(Size, "BCSF Entity Type"::SalesInvoice);
      Clear(Targets);
      AddMixedTarget(Targets, "BCSF Entity Type"::Item, Items, 0, 0);
      AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, Profile.Quantity(Size, "BCSF Entity Type"::PurchaseOrder), 60, 20);
      AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, Orders, 50, 25);
      AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, Invoices, 67, 0);
      Context.Replace('targets', Targets);
      for LogicalKey := 1 to Profile.Quantity(Size, "BCSF Entity Type"::PurchaseOrder) do
        if Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey) > 0 then begin
          Quantity := Coordinator.PurchaseQuantity(Context, LogicalKey);
          if Coordinator.Disposition(Context, 'PURCHASE.ORDER', LogicalKey) = 2 then
            Quantity /= 2;
          ItemKey := 1 + ((LogicalKey - 1) mod Items);
          if not Received.Get(ItemKey, Total) then
            Total := 0;
          Received.Set(ItemKey, Total + Quantity);
          Assert(Coordinator.PurchaseDate(Context, LogicalKey) = WorkDate(), 'Receipts must precede all dated sales.');
        end;
      SourceItems := Items;
      if SourceItems > 100 then
        SourceItems := 100;
      for ItemKey := 1 to SourceItems do begin
        Required := SalesDemandFor(Context, Coordinator, 'SALES.ORDER', ItemKey, SourceItems, Orders) +
          SalesDemandFor(Context, Coordinator, 'SALES.INVOICE', ItemKey, SourceItems, Invoices);
        if not Received.Get(ItemKey, Total) then
          Total := 0;
        Assert(Total >= Required, 'Confirmed planned receipts must cover every stock-consuming sales item.');
      end;
    end;
  end;

  [Test]
  procedure PaymentContractWithoutApprovalIsRejected()
  var
    Payments: Codeunit "BCSF Payment Processor";
    Context: JsonObject;
    Settings: JsonObject;
  begin
    Context := ContextFixture();
    Assert(not Payments.Enabled(Context), 'An old snapshot never enables payments.');
    Settings.Add('version', 1);
    Settings.Add('approved', false);
    Context.Add('paymentSetup', Settings);
    Assert(not Payments.Enabled(Context), 'Absent consent must stay disabled.');
    asserterror Payments.Check(Context);
    Settings.Replace('version', 99);
    Settings.Replace('approved', true);
    Context.Replace('paymentSetup', Settings);
    Assert(not Payments.Enabled(Context), 'Unknown payment contract must stay disabled.');
  end;

  [Test]
  procedure CompletedSmallPostedCompanyHasStandardEvidence()
  var
    Setup: Record "BCSF Factory Setup";
    Execution: Record "BCSF Run Execution";
    Entry: Record "BCSF Generated Record";
    Invoice: Record "Purch. Inv. Header";
    VendorEntry: Record "Vendor Ledger Entry";
    BankEntry: Record "Bank Account Ledger Entry";
    RunId: Guid;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Size", 0);
    Assert(Setup."Industry Process Mode".AsInteger() >= 2, 'First complete the small posted or follow-up company reference.');
    RunId := Setup."Industry Run Id";
    Execution.Get(RunId);
    Execution.TestField(Status, Execution.Status::Completed);
    AssertWholesaleCount(RunId, 'PURCHASE.ORDER', 'INVOICE', 12);
    AssertWholesaleCount(RunId, 'PURCHASE.ORDER', 'RECEIPT', 12);
    AssertWholesaleCount(RunId, 'PURCHASE.ORDER', 'DOCUMENT', 6);
    AssertWholesaleCount(RunId, 'SALES.ORDER', 'INVOICE', 9);
    AssertWholesaleCount(RunId, 'SALES.INVOICE', 'INVOICE', 2);
    AssertWholesaleCount(RunId, 'SALES.QUOTE', 'DOCUMENT', 5);
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'PURCHASE.ORDER');
    Entry.SetRange("Artifact Code", 'INVOICE');
    Entry.FindSet();
    repeat
      Invoice.GetBySystemId(Entry."Record SystemId");
      VendorEntry.Get(Invoice."Vendor Ledger Entry No.");
      VendorEntry.TestField("Document No.", Invoice."No.");
      VendorEntry.TestField("Vendor No.", Invoice."Pay-to Vendor No.");
      VendorEntry.TestField(Open, Setup."Industry Process Mode" <> "BCSF Process Mode"::FollowUpProcesses);
    until Entry.Next() = 0;
    if Setup."Industry Process Mode" = "BCSF Process Mode"::FollowUpProcesses then begin
      AssertWholesaleCount(RunId, 'PURCHASE.ORDER', 'PAYMENT', 12);
      AssertWholesaleCount(RunId, 'SALES.ORDER', 'PAYMENT', 9);
      AssertWholesaleCount(RunId, 'SALES.INVOICE', 'PAYMENT', 2);
      Entry.Reset();
      Entry.SetRange("Run Id", RunId);
      Entry.SetRange("Table Id", Database::"Bank Account Ledger Entry");
      Assert(Entry.Count() = 23, 'Each of the 23 posted invoices requires a standard bank payment.');
      Entry.FindSet();
      repeat
        BankEntry.GetBySystemId(Entry."Record SystemId");
        BankEntry.TestField("Bank Account No.", 'BCSF-PAY');
      until Entry.Next() = 0;
    end;
  end;

  [Test]
  procedure CompletedPaymentCannotBeReplayedOutsideClaim()
  var
    Setup: Record "BCSF Factory Setup";
    Entry: Record "BCSF Generated Record";
    Invoice: Record "Purch. Inv. Header";
    Batch: Record "BCSF Batch";
    GL: Record "G/L Entry";
    Manager: Codeunit "BCSF Scenario Manager";
    Payments: Codeunit "BCSF Payment Processor";
    Context: JsonObject;
    BatchJson: JsonObject;
    BeforeCount: Integer;
  begin
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Industry Process Mode", "BCSF Process Mode"::FollowUpProcesses);
    Entry.SetRange("Run Id", Setup."Industry Run Id");
    Entry.SetRange("Node Code", 'PURCHASE.ORDER');
    Entry.SetRange("Artifact Code", 'INVOICE');
    Entry.FindFirst();
    Invoice.GetBySystemId(Entry."Record SystemId");
    Manager.ReadSnapshot(Entry."Run Id", Context);
    Context.Add('batchId', Format(Entry."Batch Id", 0, 4));
    Batch.Get(Entry."Batch Id");
    BatchJson.Add('batchKey', Batch."Batch Key");
    BatchJson.Add('firstKey', Batch."First Key");
    BatchJson.Add('lastKey', Batch."Last Key");
    Context.Add('executingBatch', BatchJson);
    BeforeCount := GL.Count();
    asserterror Payments.Pay(Context, Entry."Run Id", Entry."Node Code", Entry."Logical Key", Entry."Batch Id",
      Invoice."Vendor Ledger Entry No.", false, Entry."Entry Id");
    Assert(GL.Count() = BeforeCount, 'An unclaimed/completed payment must not create any new ledger entry.');
  end;

  local procedure AddMixedTarget(var Targets: JsonArray; Entity: Enum "BCSF Entity Type"; Quantity: Integer; Posted: Decimal; Partial: Decimal)
  var
    Target: JsonObject;
  begin
    Target.Add('entity', Entity.AsInteger());
    Target.Add('quantity', Quantity);
    Target.Add('postedPercent', Posted);
    Target.Add('partialPercent', Partial);
    Targets.Add(Target);
  end;

  local procedure SalesDemandFor(Context: JsonObject; Coordinator: Codeunit "BCSF Process Coordinator"; EntityCode: Code[30]; FirstKey: Integer; ItemCount: Integer; Quantity: Integer): Decimal
  var
    LogicalKey: Integer;
    Required: Decimal;
  begin
    LogicalKey := FirstKey;
    while LogicalKey <= Quantity do begin
      case Coordinator.Disposition(Context, EntityCode, LogicalKey) of
        1: Required += Coordinator.Quantity(Context, EntityCode, LogicalKey);
        2: Required += Coordinator.Quantity(Context, EntityCode, LogicalKey) / 2;
      end;
      LogicalKey += ItemCount;
    end;
    exit(Required);
  end;

  local procedure AssertWholesaleCount(RunId: Guid; NodeCode: Code[30]; Artifact: Code[30]; Expected: Integer)
  var
    Entry: Record "BCSF Generated Record";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Artifact Code", Artifact);
    Assert(Entry.Count() = Expected, StrSubstNo('Unexpected count for %1.', NodeCode));
  end;

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

  [Test]
  procedure SalesDistributionPreservesFlooredQuotas()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    Target: JsonObject;
    Index: Integer;
    Counts: array[3] of Integer;
  begin
    Context := ContextFixture();
    Target.Add('entity', 4);
    Target.Add('quantity', 7);
    Target.Add('postedPercent', 50);
    Target.Add('partialPercent', 25);
    Targets.Add(Target);
    Context.Replace('targets', Targets);
    for Index := 1 to 7 do
      Counts[Coordinator.Disposition(Context, 'SALES.ORDER', Index) + 1] += 1;
    Assert((Counts[1] = 3) and (Counts[2] = 3) and (Counts[3] = 1), 'Sales quota rounding differs from scenario policy.');
    asserterror Coordinator.Disposition(Context, 'SALES.ORDER', 8);
  end;

  [Test]
  procedure SalesQuantityAndDatesAreStableAcrossRunAndBatchOrder()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    FirstQuantity: Decimal;
    Index: Integer;
    FirstDate: Date;
  begin
    Context := ContextFixture();
    Context.Add('startingDate', '2026-11-01');
    Context.Add('endingDate', '2026-11-20');
    FirstQuantity := Coordinator.Quantity(Context, 'SALES.ORDER', 3);
    FirstDate := Coordinator.DocumentDate(Context, 'SALES.ORDER', 3);
    for Index := 100 downto 1 do begin
      Assert(Coordinator.Quantity(Context, 'SALES.ORDER', Index) mod 2 = 0, 'Partial quantities must be integral base units.');
      Assert((Coordinator.DocumentDate(Context, 'SALES.ORDER', Index) >= 20261101D) and
        (Coordinator.DocumentDate(Context, 'SALES.ORDER', Index) <= 20261120D), 'Sales date escaped the scenario period.');
    end;
    Context.Replace('runId', Format(CreateGuid(), 0, 4));
    Assert((Coordinator.Quantity(Context, 'SALES.ORDER', 3) = FirstQuantity) and
      (Coordinator.DocumentDate(Context, 'SALES.ORDER', 3) = FirstDate), 'Sales values depend on run identity or invocation order.');
  end;

  [Test]
  procedure SalesCapabilitiesAndMissingSourceFailClosed()
  var
    TempCapabilities: Record "BCSF Generator Registry" temporary;
    Generator: Codeunit "BCSF Sales Generator";
    Setup: Codeunit "BCSF Sales Setup";
  begin
    Generator.DescribeCapabilities(TempCapabilities);
    Assert(TempCapabilities.Count() = 3, 'Sales must expose exactly quote, order and invoice targets.');
    TempCapabilities.Get('SALES.DOCUMENT', 'SALES.QUOTE');
    TempCapabilities.TestField("Maximum Mode", "BCSF Process Mode"::UnpostedDocuments);
    asserterror Setup.ReadSettings(ContextFixture());
  end;

  [Test]
  procedure SalesCannotExecuteWithoutOwnedBackgroundBatch()
  var
    Header: Record "Sales Header";
    Generator: Codeunit "BCSF Sales Generator";
    Context: JsonObject;
    Target: JsonObject;
    Batch: JsonObject;
    Result: JsonObject;
    CountBefore: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('processMode', 1);
    Target.Add('entityCode', 'SALES.ORDER');
    Target.Add('moduleCode', 'SALES');
    Target.Add('quantity', 1);
    Target.Add('processMode', 1);
    Batch.Add('batchKey', 'SALES.ORDER/1-1');
    Batch.Add('firstKey', 1);
    Batch.Add('lastKey', 1);
    CountBefore := Header.Count();
    asserterror Generator.ExecuteBatch(Context, Target, Batch, Result);
    Assert(Header.Count() = CountBefore, 'Direct invocation created a sales header before verifying worker ownership.');
  end;

  [Test]
  procedure SalesUnpostedReferenceHasNoRegisteredLedger()
  var
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    Document: Record "Sales Header";
    Customer: Record Customer;
    Item: Record Item;
    Master: Record "BCSF Generated Record";
    RunStep: Record "BCSF Run Step";
    MasterStep: Record "BCSF Run Step";
    Line: Record "Sales Line";
    CustomerEntry: Record "Cust. Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    Ledger: Record "Item Ledger Entry";
    Value: Record "Value Entry";
    Manager: Codeunit "BCSF Scenario Manager";
    Setup: Codeunit "BCSF Sales Setup";
    Context: JsonObject;
  begin
    RequireSalesRun("BCSF Process Mode"::UnpostedDocuments, Header);
    Manager.ReadSnapshot(Header."Run Id", Context);
    Assert(Setup.UsesRunMasters(Context), 'Use the new same-run sales reference template.');
    Entry.SetRange("Run Id", Header."Run Id");
    Entry.SetRange("Table Id", Database::"Sales Header");
    Assert(Entry.Count() = 8, 'Use the documented 2-quote/4-order/2-invoice unposted reference.');
    Entry.FindSet();
    repeat
      Entry.TestField("Table Id", Database::"Sales Header");
      Document.GetBySystemId(Entry."Record SystemId");
      Line.Get(Document."Document Type", Document."No.", 10000);
      RunStep.Get(Header."Run Id", Entry."Node Code");
      MasterStep.Get(Header."Run Id", 'VENDOR');
      Assert(MasterStep."Sequence No." < RunStep."Sequence No.", 'Vendor generation must precede sales.');
      MasterStep.Get(Header."Run Id", 'CUSTOMER');
      Assert(MasterStep."Sequence No." < RunStep."Sequence No.", 'Customer generation must precede sales.');
      MasterStep.Get(Header."Run Id", 'ITEM');
      Assert(MasterStep."Sequence No." < RunStep."Sequence No.", 'Item generation must precede sales.');
      Customer.Get(Document."Sell-to Customer No.");
      Item.Get(Line."No.");
      Master.SetRange("Run Id", Header."Run Id");
      Master.SetRange("Table Id", Database::Customer);
      Master.SetRange("Record SystemId", Customer.SystemId);
      Assert(not Master.IsEmpty(), 'The sales customer is outside this run.');
      Master.SetRange("Table Id", Database::Item);
      Master.SetRange("Record SystemId", Item.SystemId);
      Assert(not Master.IsEmpty(), 'The sales item is outside this run.');
      Line.TestField("Quantity Shipped", 0);
      Line.TestField("Quantity Invoiced", 0);
      CustomerEntry.SetRange("Document No.", Document."No.");
      GL.SetRange("Document No.", Document."No.");
      VAT.SetRange("Document No.", Document."No.");
      Ledger.SetRange("Document No.", Document."No.");
      Value.SetRange("Document No.", Document."No.");
      Assert(CustomerEntry.IsEmpty() and GL.IsEmpty() and VAT.IsEmpty() and Ledger.IsEmpty() and Value.IsEmpty(), 'An unposted sales document has ledger evidence.');
      if Document."Document Type" = Document."Document Type"::Order then
        Document.TestField("Quote No.");
    until Entry.Next() = 0;
  end;

  [Test]
  procedure SalesPostedReferenceKeepsOpenPartialRemainder()
  var
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    Document: Record "Sales Header";
    Line: Record "Sales Line";
    CustomerEntry: Record "Cust. Ledger Entry";
    TempTarget: Record "BCSF Data Target" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
    Policy: Codeunit "BCSF Scenario Policy";
    ExpectedInvoices: Integer;
    ExpectedPartial: Integer;
    Unposted: Integer;
    Posted: Integer;
    Partial: Integer;
    PartialFound: Boolean;
  begin
    RequireSalesRun("BCSF Process Mode"::PostedMovements, Header);
    Manager.LoadFrozenTargets(Header."Run Id", TempTarget);
    if TempTarget.FindSet() then
      repeat
        Policy.GetDistribution(TempTarget, Unposted, Posted, Partial);
        if TempTarget.Entity in [TempTarget.Entity::SalesOrder, TempTarget.Entity::SalesInvoice] then
          ExpectedInvoices += Posted + Partial;
        if TempTarget.Entity = TempTarget.Entity::SalesOrder then
          ExpectedPartial += Partial;
      until TempTarget.Next() = 0;
    Assert((ExpectedInvoices > 0) and (ExpectedPartial > 0), 'Use a mixed posted reference with partial orders.');
    Entry.SetRange("Run Id", Header."Run Id");
    Entry.SetRange("Table Id", Database::"Sales Invoice Header");
    Assert(Entry.Count() = ExpectedInvoices, 'Posted invoice count differs from captured quotas.');
    Entry.SetRange("Table Id", Database::"Cust. Ledger Entry");
    Assert(Entry.Count() = ExpectedInvoices, 'Each invoice requires its own open customer entry.');
    Entry.FindSet();
    repeat
      CustomerEntry.GetBySystemId(Entry."Record SystemId");
      CustomerEntry.TestField(Open, true);
      CustomerEntry.CalcFields("Remaining Amount");
      Assert(CustomerEntry."Remaining Amount" > 0, 'Customer invoice is unexpectedly balanced.');
    until Entry.Next() = 0;
    Entry.SetRange("Table Id", Database::"Sales Header");
    Entry.FindSet();
    repeat
      Document.GetBySystemId(Entry."Record SystemId");
      if Document."Document Type" = Document."Document Type"::Order then begin
        Line.Get(Document."Document Type", Document."No.", 10000);
        if Line."Quantity Invoiced" > 0 then begin
          Line.TestField("Outstanding Quantity", Line.Quantity / 2);
          Line.TestField("Quantity Invoiced", Line.Quantity / 2);
          PartialFound := true;
        end;
      end;
    until Entry.Next() = 0;
    Assert(PartialFound, 'No half-invoiced order remains open.');
  end;

  [Test]
  procedure PostedDefaultsSeparateOrdersInvoicesAndQuotes()
  var
    Target: Record "BCSF Data Target" temporary;
    Policy: Codeunit "BCSF Scenario Policy";
    Unposted: Integer;
    Posted: Integer;
    Partial: Integer;
  begin
    Target.Entity := Target.Entity::SalesOrder;
    Target.Quantity := 10;
    Target."Process Mode" := "BCSF Process Mode"::PostedMovements;
    Policy.ApplyDocumentModeDefaults(Target);
    Policy.GetDistribution(Target, Unposted, Posted, Partial);
    Assert((Unposted = 3) and (Posted = 5) and (Partial = 2), 'Posted orders need unposted, fully posted and partial examples.');
    Target.Entity := Target.Entity::SalesInvoice;
    Policy.ApplyDocumentModeDefaults(Target);
    Target.TestField("Unposted Percent", 25);
    Target.TestField("Posted Percent", 75);
    Target.TestField("Partial Percent", 0);
    Target.Entity := Target.Entity::SalesQuote;
    Policy.ApplyDocumentModeDefaults(Target);
    Target.TestField("Process Mode", "BCSF Process Mode"::UnpostedDocuments);
    Target.TestField("Unposted Percent", 100);
  end;

  [Test]
  procedure DecimalSalesSharesMatchTheScenarioDistribution()
  var
    Target: Record "BCSF Data Target" temporary;
    Coordinator: Codeunit "BCSF Process Coordinator";
    Policy: Codeunit "BCSF Scenario Policy";
    Context: JsonObject;
    Value: JsonObject;
    Targets: JsonArray;
    Counts: array[3] of Integer;
    Index: Integer;
    Unposted: Integer;
    Posted: Integer;
    Partial: Integer;
  begin
    Target.Entity := Target.Entity::SalesOrder;
    Target.Quantity := 11;
    Target."Unposted Percent" := 60;
    Target."Posted Percent" := 27.5;
    Target."Partial Percent" := 12.5;
    Value.Add('entity', Target.Entity.AsInteger());
    Value.Add('quantity', Target.Quantity);
    Value.Add('postedPercent', Target."Posted Percent");
    Value.Add('partialPercent', Target."Partial Percent");
    Targets.Add(Value);
    Context := ContextFixture();
    Context.Replace('targets', Targets);
    for Index := 1 to Target.Quantity do
      Counts[Coordinator.Disposition(Context, 'SALES.ORDER', Index) + 1] += 1;
    Policy.GetDistribution(Target, Unposted, Posted, Partial);
    Assert((Counts[1] = Unposted) and (Counts[2] = Posted) and (Counts[3] = Partial), 'Fractional percentages were changed during execution.');
    Assert((Posted = 3) and (Partial = 1) and (Unposted = 7), 'Unexpected decimal quota coverage.');
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure NewTemplateHasAUsableMasterTargetUnderHigherCeiling()
  var
    Scenario: Record "BCSF Scenario";
    Target: Record "BCSF Data Target";
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Scenario.Get(Manager.CreateScenario());
    Scenario.TestField("Profile Code", 'GENERAL');
    Scenario.TestField("Profile Version", '1');
    Target.Get(Scenario."Scenario Id", Target.Entity::Customer);
    Target.TestField(Quantity, 1);
    Manager.ChangeProcessScope(Scenario."Scenario Id", "BCSF Process Mode"::FollowUpProcesses);
    Scenario.Get(Scenario."Scenario Id");
    Assert(Manager.IsPartnerTemplate(Scenario), 'A higher ceiling blocked the actual supported master target.');
    Manager.RequireExecutableTargets(Scenario);
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure ScopeChangesKeepTargetsAndSharesConsistent()
  var
    Scenario: Record "BCSF Scenario";
    Target: Record "BCSF Data Target";
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Scenario.Get(Manager.CreateScenario());
    Manager.ChangeProcessScope(Scenario."Scenario Id", "BCSF Process Mode"::UnpostedDocuments);
    Target.Init();
    Target."Scenario Id" := Scenario."Scenario Id";
    Target.Validate(Entity, Target.Entity::SalesOrder);
    Target.Quantity := 10;
    Target.Insert(true);
    Manager.ChangeProcessScope(Scenario."Scenario Id", "BCSF Process Mode"::PostedMovements);
    Target.Get(Scenario."Scenario Id", Target.Entity::SalesOrder);
    Target.TestField("Process Mode", "BCSF Process Mode"::PostedMovements);
    Target.TestField("Unposted Percent", 30);
    Target.TestField("Posted Percent", 50);
    Target.TestField("Partial Percent", 20);
    Manager.ChangeProcessScope(Scenario."Scenario Id", "BCSF Process Mode"::UnpostedDocuments);
    Target.Get(Scenario."Scenario Id", Target.Entity::SalesOrder);
    Target.TestField("Process Mode", "BCSF Process Mode"::UnpostedDocuments);
    Target.TestField("Unposted Percent", 100);
    Target.TestField("Posted Percent", 0);
    Target.TestField("Partial Percent", 0);
    Scenario.Get(Scenario."Scenario Id");
    Scenario.TestField("Sales Posting Approved", false);
  end;

  [Test]
  [HandlerFunctions('AcceptTemplateRemoval')]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure NewTemplateCanBeRemovedThroughTheSafeAction()
  var
    Scenario: Record "BCSF Scenario";
    Selection: Record "BCSF Scenario";
    Target: Record "BCSF Data Target";
    Module: Record "BCSF Scenario Module";
    Manager: Codeunit "BCSF Scenario Manager";
    Id: Guid;
  begin
    Id := Manager.CreateScenario();
    Selection.SetRange("Scenario Id", Id);
    Assert(Manager.RemoveSelection(Selection), 'The confirmed remove action was not performed.');
    Assert(not Scenario.Get(Id), 'Unused template was not removed.');
    Target.SetRange("Scenario Id", Id);
    Module.SetRange("Scenario Id", Id);
    Assert(Target.IsEmpty() and Module.IsEmpty(), 'Template children were retained after safe removal.');
  end;

  [ConfirmHandler]
  procedure AcceptTemplateRemoval(Question: Text[1024]; var Reply: Boolean)
  begin
    Reply := true;
  end;

  [Test]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure StarterRefreshIsIdempotentAndIncludesMixedSales()
  var
    Scenario: Record "BCSF Scenario";
    Target: Record "BCSF Data Target";
    Removed: Record "BCSF Removed Template";
    Catalog: Codeunit "BCSF Starter Catalog";
    Id: Guid;
    CountBefore: Integer;
    RevisionBefore: Integer;
    WasPresent: Boolean;
  begin
    Evaluate(Id, '{B55C2100-AB51-4021-9C00-000000000002}');
    WasPresent := Scenario.Get(Id);
    Catalog.Seed();
    CountBefore := Scenario.Count();
    if not Removed.Get(Id) then begin
      Scenario.Get(Id);
      if not Scenario.Archived and not WasPresent then begin
        Target.Get(Id, Target.Entity::SalesOrder);
        Target.TestField("Unposted Percent", 30);
        Target.TestField("Posted Percent", 50);
        Target.TestField("Partial Percent", 20);
      end;
      RevisionBefore := Scenario.Revision;
    end;
    Catalog.Seed();
    Assert(Scenario.Count() = CountBefore, 'Repeated refresh created duplicate starters.');
    if Scenario.Get(Id) then
      Scenario.TestField(Revision, RevisionBefore);
  end;

  [Test]
  [HandlerFunctions('AcceptTemplateRemoval')]
  [TransactionModel(TransactionModel::AutoRollback)]
  procedure UsedTemplateIsArchivedAndItsSnapshotRetained()
  var
    Scenario: Record "BCSF Scenario";
    Header: Record "BCSF Run Header";
    Selection: Record "BCSF Scenario";
    Manager: Codeunit "BCSF Scenario Manager";
    Writer: Codeunit "BCSF Snapshot Writer";
    ScenarioId: Guid;
    RunId: Guid;
  begin
    ScenarioId := Manager.CreateScenario();
    RunId := Writer.CreateSnapshot(ScenarioId);
    Selection.SetRange("Scenario Id", ScenarioId);
    Assert(Manager.RemoveSelection(Selection), 'The confirmed archive action was not performed.');
    Scenario.Get(ScenarioId);
    Scenario.TestField(Archived, true);
    Header.Get(RunId);
    Header.TestField("Scenario Id", ScenarioId);
  end;

  local procedure RequireSalesRun(Mode: Enum "BCSF Process Mode"; var Header: Record "BCSF Run Header")
  var
    Execution: Record "BCSF Run Execution";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    Header.SetCurrentKey("Created At", "Run Id");
    Header.SetRange("Profile Code", 'TECH-SALES');
    Header.SetRange("Process Mode", Mode);
    if Header.FindLast() then
      repeat
        if Execution.Get(Header."Run Id") then
          if Execution.Status = Execution.Status::Completed then
            exit;
      until Header.Next(-1) = 0;
    Error('First complete the documented TECH-SALES reference run in mode %1.', Mode);
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
