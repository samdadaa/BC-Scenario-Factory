#if BCSFTESTS
namespace BCScenarioFactory.Inventory.Tests;

using BCScenarioFactory.Assembly;
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
using BCScenarioFactory.SetupManager;
using Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.Dimension;
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
using System.IO;
using System.Security.AccessControl;

codeunit 90700 "BCSF Inventory Tests"
{
  Subtype = Test;

  [Test]
  procedure ExportCatalogIncludesPostingSideEffects()
  var
    ExportPackage: Codeunit "BCSF Config Export";
    TableIds: List of [Integer];
    UniqueIds: List of [Integer];
    TableId: Integer;
  begin
    ExportPackage.GetTableIds(TableIds);
    foreach TableId in TableIds do begin
      Assert(not UniqueIds.Contains(TableId), 'Export table IDs must be unique.');
      UniqueIds.Add(TableId);
    end;
    Assert(TableIds.Contains(Database::Customer), 'Customer must be exported.');
    Assert(TableIds.Contains(Database::Vendor), 'Vendor must be exported.');
    Assert(TableIds.Contains(Database::Item), 'Item must be exported.');
    Assert(TableIds.Contains(Database::"Sales Line"), 'Open sales lines must be exported.');
    Assert(TableIds.Contains(Database::"Purchase Line"), 'Open purchase lines must be exported.');
    Assert(TableIds.Contains(Database::"Sales Shipment Line"), 'Posted sales lines must be exported.');
    Assert(TableIds.Contains(Database::"Purch. Rcpt. Line"), 'Posted purchase lines must be exported.');
    Assert(TableIds.Contains(Database::"G/L - Item Ledger Relation"), 'Posting relations must be exported.');
    Assert(TableIds.Contains(Database::"Detailed Cust. Ledg. Entry"), 'Payment/application details must be exported.');
    Assert(TableIds.Contains(Database::"Detailed Vendor Ledg. Entry"), 'Vendor application details must be exported.');
    Assert(TableIds.Contains(Database::"Bank Account Ledger Entry"), 'Bank entries must be exported.');
  end;

  [Test]
  procedure ExportPackageIsIdempotent()
  var
    PackageTable: Record "Config. Package Table";
    PackageField: Record "Config. Package Field";
    SalesLine: Record "Sales Line";
    DimensionValue: Record "Dimension Value";
    ExportPackage: Codeunit "BCSF Config Export";
    TableIds: List of [Integer];
    TableId: Integer;
    OriginalCount: Integer;
  begin
    ExportPackage.EnsurePackage();
    PackageTable.SetRange("Package Code", ExportPackage.GetPackageCode());
    OriginalCount := PackageTable.Count();
    ExportPackage.EnsurePackage();
    Assert(PackageTable.Count() = OriginalCount, 'Repeated provision must not duplicate tables.');
    ExportPackage.GetTableIds(TableIds);
    foreach TableId in TableIds do
      Assert(PackageTable.Get(ExportPackage.GetPackageCode(), TableId), 'Every catalog table must exist in the package.');
    PackageField.Get(ExportPackage.GetPackageCode(), Database::"Sales Line", SalesLine.FieldNo("Dimension Set ID"));
    Assert(PackageField."Include Field", 'Dimension-set references must remain available for inspection.');
    PackageField.Get(ExportPackage.GetPackageCode(), Database::"Dimension Value", DimensionValue.FieldNo("Dimension Value ID"));
    Assert(PackageField."Include Field", 'The standard omission of Dimension Value ID must be supplemented for inspection.');
  end;

  [Test]
  procedure ExportPackagePreservesCustomizations()
  var
    PackageField: Record "Config. Package Field";
    PackageFilter: Record "Config. Package Filter";
    Item: Record Item;
    ExportPackage: Codeunit "BCSF Config Export";
    PackageManagement: Codeunit "Config. Package Management";
  begin
    ExportPackage.EnsurePackage();
    PackageField.Get(ExportPackage.GetPackageCode(), Database::Item, Item.FieldNo(Description));
    PackageField."Include Field" := false;
    PackageField.Modify(true);
    PackageManagement.InsertPackageFilter(PackageFilter, ExportPackage.GetPackageCode(), Database::Item, 0, Item.FieldNo("No."), 'SF046*');
    ExportPackage.EnsurePackage();
    PackageField.Get(ExportPackage.GetPackageCode(), Database::Item, Item.FieldNo(Description));
    Assert(not PackageField."Include Field", 'Provision must preserve an existing field choice.');
    PackageFilter.Get(ExportPackage.GetPackageCode(), Database::Item, 0, Item.FieldNo("No."));
    Assert(PackageFilter."Field Filter" = 'SF046*', 'Provision must preserve an existing filter.');
  end;

  [Test]
  procedure ExportPackageRejectsForeignMarker()
  var
    Package: Record "Config. Package";
    ExportPackage: Codeunit "BCSF Config Export";
  begin
    ExportPackage.EnsurePackage();
    Package.Get(ExportPackage.GetPackageCode());
    Package."Product Version" := 'SF046-FOREIGN';
    Package.Modify(true);
    asserterror ExportPackage.EnsurePackage();
    Assert(StrPos(GetLastErrorText(), ExportPackage.GetPackageCode()) > 0, 'The collision error must identify the conflicting package code.');
  end;

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
    Assert(Header."Profile Version" in ['3', '4', '5'], 'Wholesale reference must use its supported immutable version.');
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
  procedure PaymentPlanIsDeterministicExactAndLegacySafe()
  var
    Payments: Codeunit "BCSF Payment Processor";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    OtherRun: JsonObject;
    Settings: JsonObject;
    Kind: Integer;
    OtherKind: Integer;
    First: Decimal;
    Second: Decimal;
    OtherFirst: Decimal;
    OtherSecond: Decimal;
    Total: Decimal;
    LogicalKey: Integer;
    Seen: array[4] of Boolean;
    Sign: Integer;
    Direction: Integer;
  begin
    Context := ContextFixture();
    Settings.Add('version', 1);
    Settings.Add('approved', true);
    // Historical snapshots without a plan marker keep one full payment.
    Context.Add('paymentSetup', Settings);
    Payments.PlanAmounts(Context, 'SALES.INVOICE', 1, 119.5, Kind, First, Second);
    Assert((Kind = 0) and (First = 119.5) and (Second = 0), 'A missing plan marker must keep the single full payment.');
    Settings.Add('planVersion', 1);
    Context.Replace('paymentSetup', Settings);
    OtherRun := Contract.Clone(Context);
    OtherRun.Replace('runId', Format(CreateGuid(), 0, 4));
    for Direction := 0 to 1 do
      for LogicalKey := 1 to 200 do begin
        Sign := 1 - 2 * Direction;
        Total := Sign * (50 + LogicalKey * 7.31);
        Payments.PlanAmounts(Context, 'SALES.INVOICE', LogicalKey, Total, Kind, First, Second);
        Payments.PlanAmounts(OtherRun, 'SALES.INVOICE', LogicalKey, Total, OtherKind, OtherFirst, OtherSecond);
        Assert((Kind = OtherKind) and (First = OtherFirst) and (Second = OtherSecond), 'The payment plan must not depend on the run id.');
        Seen[Kind + 1] := true;
        case Kind of
          0:
            Assert((First = Total) and (Second = 0), 'Kind 0 pays the full amount.');
          1:
            begin
              Assert(First + Second = Total, 'Installments must clear the invoice exactly.');
              Assert((Abs(First) > 0) and (Abs(Second) > 0) and (Sign * First > 0) and (Sign * Second > 0), 'Installments keep the invoice sign.');
            end;
          2:
            Assert((Abs(First) > 0) and (Abs(First) < Abs(Total)) and (Sign * First > 0) and (Second = 0), 'A partial payment leaves an open rest.');
          3:
            Assert((First = 0) and (Second = 0), 'A planned open item has no payment.');
        end;
      end;
    Assert(Seen[1] and Seen[2] and Seen[3] and Seen[4], 'All four payment plan kinds must occur across 400 invoices.');
    // Tiny invoices cannot be split.
    Payments.PlanAmounts(Context, 'SALES.INVOICE', 5, 0.03, Kind, First, Second);
    Assert((Kind = 0) or (Kind = 3), 'An invoice too small to split is paid in full or left open.');
  end;

  [Test]
  procedure CreditPlanIsDeterministicAndPurchaseCreditsStayPartial()
  var
    Credits: Codeunit "BCSF Credit Memo Processor";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    OtherRun: JsonObject;
    Settings: JsonObject;
    LogicalKey: Integer;
    Kind: Integer;
    Seen: array[4] of Boolean;
  begin
    Context := ContextFixture();
    Settings.Add('version', 1);
    Settings.Add('approved', true);
    Context.Add('paymentSetup', Settings);
    Assert(not Credits.Enabled(Context), 'A missing credit marker must keep credit memos off.');
    Settings.Add('creditVersion', 1);
    Context.Replace('paymentSetup', Settings);
    Assert(Credits.Enabled(Context), 'The credit marker with approved payments enables credit memos.');
    OtherRun := Contract.Clone(Context);
    OtherRun.Replace('runId', Format(CreateGuid(), 0, 4));
    for LogicalKey := 1 to 300 do begin
      Kind := Credits.PlanKind(Context, 'SALES.INVOICE', LogicalKey, true);
      Assert(Kind = Credits.PlanKind(OtherRun, 'SALES.INVOICE', LogicalKey, true), 'The credit plan must not depend on the run id.');
      Seen[Kind + 1] := true;
      Assert(Credits.PlanKind(Context, 'PURCHASE.ORDER', LogicalKey, false) <> 3, 'Purchase credit memos are never full credits.');
    end;
    Assert(Seen[1] and Seen[2] and Seen[3] and Seen[4], 'All four sales credit plan kinds must occur.');
    Assert(Credits.CreditQuantity(3, 6, true) = 6, 'Full credit repeats the invoiced quantity.');
    Assert(Credits.CreditQuantity(2, 5, true) = 3, 'Partial sales credit uses whole units.');
    Assert(Credits.CreditQuantity(2, 8, false) = 1, 'Purchase credit stays at one unit.');
    Assert(Credits.CreditQuantity(2, 1, true) = 1, 'A credit never exceeds the invoiced quantity.');
    Settings.Replace('creditVersion', 2);
    Context.Replace('paymentSetup', Settings);
    asserterror Credits.Enabled(Context);
    Assert(GetLastErrorText() <> '', 'An unknown credit marker must stop.');
  end;

  [Test]
  procedure SyntheticPartnerBankIsSeedBasedAndChecksumValid()
  var
    Children: Codeunit "BCSF Partner Children";
    Context: JsonObject;
    BranchNo: Text[20];
    AccountNo: Text[30];
    Iban: Code[50];
    OtherBranch: Text[20];
    OtherAccount: Text[30];
    OtherIban: Code[50];
    Digits: Text;
    Remainder: Integer;
    Index: Integer;
    LogicalKey: Integer;
  begin
    Context := ContextFixture();
    for LogicalKey := 1 to 50 do begin
      Children.SyntheticBank(Context, 'CUSTOMER', LogicalKey, BranchNo, AccountNo, Iban);
      Children.SyntheticBank(Context, 'CUSTOMER', LogicalKey, OtherBranch, OtherAccount, OtherIban);
      Assert(Iban = OtherIban, 'The synthetic IBAN must be reproducible.');
      Assert((StrLen(Iban) = 22) and (CopyStr(Iban, 1, 2) = 'DE'), 'Synthetic bank data uses a 22 character German IBAN.');
      // ISO 13616 check: BBAN + country + check digits as numbers must be 1 modulo 97.
      Digits := CopyStr(Iban, 5) + '1314' + CopyStr(Iban, 3, 2);
      Remainder := 0;
      for Index := 1 to StrLen(Digits) do
        Remainder := (Remainder * 10 + Digits[Index] - 48) mod 97;
      Assert(Remainder = 1, 'The synthetic IBAN checksum must be valid.');
    end;
    Children.SyntheticBank(Context, 'VENDOR', 1, BranchNo, AccountNo, Iban);
    Children.SyntheticBank(Context, 'CUSTOMER', 1, OtherBranch, OtherAccount, OtherIban);
    Assert(Iban <> OtherIban, 'Customer and vendor bank accounts must not share the same synthetic number.');
  end;

  [Test]
  procedure MovementPlanIsDeterministicAndTransfersNeedCapturedLocations()
  var
    Movements: Codeunit "BCSFInventoryMovementProcessor";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    WithTransfer: JsonObject;
    OtherRun: JsonObject;
    Settings: JsonObject;
    TransferSettings: JsonObject;
    LogicalKey: Integer;
    Kind: Integer;
    Seen: array[6] of Boolean;
    AssemblyProc: Codeunit "BCSF Assembly Processor";
  begin
    Context := ContextFixture();
    Settings.Add('version', 1);
    Settings.Add('approved', true);
    Context.Add('paymentSetup', Settings);
    Assert(not Movements.Enabled(Context), 'A missing movement marker must keep stock movements off.');
    TransferSettings.Add('version', 1);
    TransferSettings.Add('approved', true);
    TransferSettings.Add('inventoryVersion', 1);
    TransferSettings.Add('transferTo', 'BCSF-AUX');
    TransferSettings.Add('transit', 'BCSF-TRN');
    TransferSettings.Add('assemblyVersion', 1);
    WithTransfer := Contract.Clone(Context);
    WithTransfer.Replace('paymentSetup', TransferSettings);
    Assert(Movements.Enabled(WithTransfer), 'The movement marker with approved payments enables stock movements.');
    OtherRun := Contract.Clone(WithTransfer);
    OtherRun.Replace('runId', Format(CreateGuid(), 0, 4));
    for LogicalKey := 1 to 300 do begin
      Kind := Movements.PlanKind(WithTransfer, 'PURCHASE.ORDER', LogicalKey, 'BCSF-MAIN');
      Assert(Kind = Movements.PlanKind(OtherRun, 'PURCHASE.ORDER', LogicalKey, 'BCSF-MAIN'), 'The movement plan must not depend on the run id.');
      Seen[Kind + 1] := true;
      Assert(Movements.PlanKind(WithTransfer, 'PURCHASE.ORDER', LogicalKey, 'BCSF-AUX') <> 4, 'No transfer onto the same location.');
      Assert(Movements.PlanKind(Context, 'PURCHASE.ORDER', LogicalKey, 'BCSF-MAIN') <> 4, 'No transfer without captured locations.');
      Assert(Movements.PlanKind(Context, 'PURCHASE.ORDER', LogicalKey, 'BCSF-MAIN') <> 5, 'No assembly without the captured marker.');
      Assert(AssemblyProc.SubKind(Context, 'PURCHASE.ORDER', LogicalKey, 1) <> 3, 'A partial assembly needs at least two units.');
      Assert(AssemblyProc.SubKind(Context, 'PURCHASE.ORDER', LogicalKey, 2) = AssemblyProc.SubKind(OtherRun, 'PURCHASE.ORDER', LogicalKey, 2), 'The assembly mode must not depend on the run id.');
    end;
    Assert(Seen[1] and Seen[2] and Seen[3] and Seen[4] and Seen[5] and Seen[6], 'All movement plan kinds including assembly must occur with the captured markers.');
    for LogicalKey := 1 to 100 do begin
      Assert((Movements.LineUnits(Context, 'PURCHASE.ORDER', LogicalKey, 1, 50) >= 1) and (Movements.LineUnits(Context, 'PURCHASE.ORDER', LogicalKey, 1, 50) <= 4),
        'Line units are 1 to 3 and never above half of the stock reserve.');
      Assert(Movements.LineUnits(Context, 'PURCHASE.ORDER', LogicalKey, 2, 1) = 1, 'Line units never exceed the posted quantity.');
      Assert(Movements.LineUnits(Context, 'PURCHASE.ORDER', LogicalKey, 1, 50) = Movements.LineUnits(OtherRun, 'PURCHASE.ORDER', LogicalKey, 1, 50),
        'Line units must not depend on the run id.');
    end;
    TransferSettings.Replace('inventoryVersion', 2);
    WithTransfer.Replace('paymentSetup', TransferSettings);
    asserterror Movements.Enabled(WithTransfer);
    Assert(GetLastErrorText() <> '', 'An unknown movement marker must stop.');
  end;

  [Test]
  procedure UnknownPaymentPlanVersionIsRejected()
  var
    Payments: Codeunit "BCSF Payment Processor";
    Context: JsonObject;
    Settings: JsonObject;
    Kind: Integer;
    First: Decimal;
    Second: Decimal;
  begin
    Context := ContextFixture();
    Settings.Add('version', 1);
    Settings.Add('approved', true);
    Settings.Add('planVersion', 2);
    Context.Add('paymentSetup', Settings);
    asserterror Payments.PlanAmounts(Context, 'SALES.INVOICE', 1, 100, Kind, First, Second);
    Assert(GetLastErrorText() <> '', 'An unknown payment plan version must stop before any posting.');
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
  procedure WholesaleV5HasFourHundredUniqueProductIdentities()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Values: JsonObject;
    Seen: Dictionary of [Text, Boolean];
    Description: Text;
    ItemKey: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '5');
    for ItemKey := 1 to 400 do begin
      Values := Catalog.BuildValues(Context, ItemKey);
      Description := Contract.GetText(Values, 'description');
      Assert(not Seen.ContainsKey(Description), 'Duplicate wholesale product identity at item key ' + Format(ItemKey));
      Seen.Add(Description, true);
      Assert(Contract.GetInteger(Values, 'reorderPoint') > 0, 'Invalid replenishment threshold.');
      Assert(Contract.GetText(Values, 'rating') <> '', 'Missing nominal pressure rating.');
    end;
    Assert(Seen.Count() = 400, 'Wholesale medium assortment does not contain 400 unique products.');
  end;

  [Test]
  procedure WholesaleV5RejectsExceedingPhysicalAssortmentCapacity()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Context: JsonObject;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '5');
    asserterror Catalog.BuildValues(Context, 6913);
  end;

  [Test]
  procedure WholesaleV4RetainsLegacyCatalogShape()
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Context: JsonObject;
    Values: JsonObject;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '4');
    Values := Catalog.BuildValues(Context, 1);
    Assert(not Values.Contains('dimension'), 'Immutable wholesale v4 catalog must not be rewritten.');
  end;

  [Test]
  procedure WholesaleV5MultiLinePurchaseCoversPostedSales()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    Received: Dictionary of [Integer, Decimal];
    ItemCount: Integer;
    PurchaseKey: Integer;
    SalesKey: Integer;
    LineIndex: Integer;
    ItemKey: Integer;
    Mode: Integer;
    Qty: Decimal;
    Available: Decimal;
    Required: Decimal;
    DocumentItems: Dictionary of [Integer, Boolean];
    EntityCode: Code[30];
    EntityIndex: Integer;
    MaxSales: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '5');
    Context.Add('startingDate', Format(WorkDate(), 0, 9));
    Context.Add('endingDate', Format(WorkDate() + 30, 0, 9));
    Clear(Targets);
    AddMixedTarget(Targets, "BCSF Entity Type"::Vendor, 5, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::Item, 40, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, 15, 60, 20);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, 12, 50, 25);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, 3, 67, 0);
    Context.Replace('targets', Targets);
    ItemCount := 40;
    for PurchaseKey := 1 to 15 do begin
      Assert(Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', PurchaseKey) >= 2, 'Wholesale purchase must contain multiple items.');
      Mode := Coordinator.Disposition(Context, 'PURCHASE.ORDER', PurchaseKey);
      if Mode > 0 then
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', PurchaseKey) do begin
          ItemKey := Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex);
          Assert(((ItemKey - 1) mod 5) = ((PurchaseKey - 1) mod 5), 'Purchase lines must share the primary supplier.');
          Qty := Coordinator.WholesalePurchaseLineQuantity(Context, PurchaseKey, LineIndex);
          if Mode = 2 then
            Qty /= 2;
          if not Received.Get(ItemKey, Available) then
            Available := 0;
          Received.Set(ItemKey, Available + Qty);
        end;
    end;
    for ItemKey := 1 to ItemCount do begin
      Required := Coordinator.WholesaleDemandForItem(Context, ItemKey, 1);
      if not Received.Get(ItemKey, Available) then
        Available := 0;
      Assert(Available >= Required, 'Wholesale purchase receipts do not cover planned posted sales.');
    end;
    for EntityIndex := 1 to 2 do begin
      if EntityIndex = 1 then begin
        EntityCode := 'SALES.ORDER';
        MaxSales := 12;
      end else begin
        EntityCode := 'SALES.INVOICE';
        MaxSales := 3;
      end;
      for SalesKey := 1 to MaxSales do begin
        Clear(DocumentItems);
        for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, SalesKey) do begin
          ItemKey := Coordinator.WholesaleSalesItemKey(Context, EntityCode, SalesKey, LineIndex);
          Assert(not DocumentItems.ContainsKey(ItemKey), 'A wholesale document repeats a product without a reason.');
          DocumentItems.Add(ItemKey, true);
        end;
      end;
    end;
  end;

  [Test]
  procedure WholesaleV6UsesExtendedAssortmentAndCoversPostedSales()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    Received: Dictionary of [Integer, Decimal];
    PurchaseKey: Integer;
    SalesKey: Integer;
    LineIndex: Integer;
    ItemKey: Integer;
    Mode: Integer;
    UsedBeyondOldLimit: Boolean;
    Required: Decimal;
    Available: Decimal;
    EntityCode: Code[30];
    Kind: Integer;
    Count: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Context.Add('startingDate', '2025-11-22');
    Context.Add('endingDate', '2026-11-21');
    Clear(Targets);
    AddMixedTarget(Targets, "BCSF Entity Type"::Vendor, 50, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::Item, 400, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, 150, 60, 20);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, 120, 50, 25);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, 30, 67, 0);
    Context.Replace('targets', Targets);
    for PurchaseKey := 1 to 150 do begin
      Mode := Coordinator.Disposition(Context, 'PURCHASE.ORDER', PurchaseKey);
      for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', PurchaseKey) do begin
        ItemKey := Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex);
        Assert((ItemKey >= 1) and (ItemKey <= 400), 'Item key escaped the 400-item catalog.');
        Assert(((ItemKey - 1) mod 50) = ((PurchaseKey - 1) mod 50), 'Purchase supplier assignment drifted.');
        if ItemKey > 200 then
          UsedBeyondOldLimit := true;
        if Mode > 0 then begin
          if not Received.Get(ItemKey, Available) then
            Available := 0;
          Required := Coordinator.WholesalePurchaseLineQuantity(Context, PurchaseKey, LineIndex);
          if Mode = 2 then
            Required /= 2;
          Received.Set(ItemKey, Available + Required);
        end;
      end;
    end;
    Assert(UsedBeyondOldLimit, 'V6 purchase planning must reach products beyond item 200.');
    for Kind := 1 to 2 do begin
      if Kind = 1 then begin
        EntityCode := 'SALES.ORDER';
        Count := 120;
      end else begin
        EntityCode := 'SALES.INVOICE';
        Count := 30;
      end;
      for SalesKey := 1 to Count do
        if Coordinator.Disposition(Context, EntityCode, SalesKey) > 0 then
          for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, SalesKey) do begin
            ItemKey := Coordinator.WholesaleSalesItemKey(Context, EntityCode, SalesKey, LineIndex);
            Assert(Received.ContainsKey(ItemKey), 'Posted sales item has no confirmed purchase receipt.');
          end;
    end;
    for ItemKey := 1 to 400 do begin
      Required := Coordinator.WholesaleDemandForItem(Context, ItemKey, 1);
      if not Received.Get(ItemKey, Available) then
        Available := 0;
      Assert(Available >= Required, 'Planned receipt quantity is less than posted demand.');
    end;
  end;

  [Test]
  procedure WholesaleV6PurchaseDatesAreDistributedBeforeRelatedSales()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    PurchaseKey: Integer;
    SalesKey: Integer;
    LineIndex: Integer;
    PurchaseLineIndex: Integer;
    SalesItemKey: Integer;
    EntityCode: Code[30];
    Kind: Integer;
    Count: Integer;
    FirstDate: Date;
    LatestDate: Date;
    HasPriorReceipt: Boolean;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Context.Add('startingDate', '2025-11-22');
    Context.Add('endingDate', '2026-11-21');
    Clear(Targets);
    AddMixedTarget(Targets, "BCSF Entity Type"::Vendor, 50, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::Item, 400, 0, 0);
    AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, 150, 60, 20);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, 120, 50, 25);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, 30, 67, 0);
    Context.Replace('targets', Targets);
    FirstDate := Coordinator.PurchaseDate(Context, 1);
    LatestDate := Coordinator.PurchaseDate(Context, 120);
    Assert((FirstDate = 20251122D) and (LatestDate > FirstDate) and
      (LatestDate <= 20261121D), 'V6 purchase dates must spread across the permitted period.');
    for Kind := 1 to 2 do begin
      if Kind = 1 then begin
        EntityCode := 'SALES.ORDER';
        Count := 120;
      end else begin
        EntityCode := 'SALES.INVOICE';
        Count := 30;
      end;
      for SalesKey := 1 to Count do
        if Coordinator.Disposition(Context, EntityCode, SalesKey) > 0 then
          for LineIndex := 1 to Coordinator.WholesaleLineCount(Context, EntityCode, SalesKey) do begin
            SalesItemKey := Coordinator.WholesaleSalesItemKey(Context, EntityCode, SalesKey, LineIndex);
            HasPriorReceipt := false;
            for PurchaseKey := 1 to 120 do
              if Coordinator.Disposition(Context, 'PURCHASE.ORDER', PurchaseKey) > 0 then
                if Coordinator.PurchaseDate(Context, PurchaseKey) <= Coordinator.DocumentDate(Context, EntityCode, SalesKey) then
                  for PurchaseLineIndex := 1 to Coordinator.WholesaleLineCount(Context, 'PURCHASE.ORDER', PurchaseKey) do
                    if Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, PurchaseLineIndex) = SalesItemKey then
                      HasPriorReceipt := true;
            Assert(HasPriorReceipt, 'A posted wholesale sale must not precede every available receipt.');
          end;
    end;
  end;

  [Test]
  procedure WholesaleV6CitiesCycleThroughAllTwentyLocations()
  var
    Catalog: Codeunit "BCSF Partner Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Settings: JsonObject;
    Address: JsonObject;
    Cities: Dictionary of [Text, Boolean];
    Index: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Settings.Add('countryCode', 'DE');
    Context.Add('partnerSetup', Settings);
    for Index := 1 to 200 do begin
      Address := Catalog.AddressValues(Context, 'CUSTOMER', Index, 'MAIN');
      Cities.Set(Contract.GetText(Address, 'city'), true);
    end;
    Assert(Cities.Count() = 20, '200 customers must visit all 20 synthetic city/postcode pairs.');
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

  [Test]
  procedure MovementSourceCountsRemainReferences()
  var
    Source: Codeunit "BCSF Master Data Source";
    Context: JsonObject;
    Binding: JsonObject;
    Targets: JsonArray;
    Ids: JsonArray;
  begin
    Context := ContextFixture();
    AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, 10, 60, 20);
    Context.Replace('targets', Targets);
    Ids.Add(Format(CreateGuid(), 0, 4));
    Binding.Add('customers', Ids.Clone());
    Ids.Add(Format(CreateGuid(), 0, 4));
    Binding.Add('vendors', Ids.Clone());
    Ids.Add(Format(CreateGuid(), 0, 4));
    Binding.Add('items', Ids);
    Context.Add('masterDataSource', Binding);
    Assert(Source.Quantity(Context, "BCSF Entity Type"::Customer) = 1, 'Customer quantity must describe the bound source.');
    Assert(Source.Quantity(Context, "BCSF Entity Type"::Vendor) = 2, 'Vendor quantity must describe the bound source.');
    Assert(Source.Quantity(Context, "BCSF Entity Type"::Item) = 3, 'Item quantity must describe the bound source.');
    Assert(Source.Quantity(Context, "BCSF Entity Type"::PurchaseOrder) = 10, 'Document targets must stay in the new run.');
    Assert(Targets.Count() = 1, 'Source counts must not add new master targets.');
  end;

  [Test]
  procedure ExistingMasterPoolHasNoHistoricalRunDependency()
  var
    Source: Codeunit "BCSF Master Data Source";
    Context: JsonObject;
    Binding: JsonObject;
    Ids: JsonArray;
    CurrentRun: Guid;
  begin
    Context := ContextFixture();
    CurrentRun := CreateGuid();
    Context.Add('runId', Format(CurrentRun, 0, 4));
    Binding.Add('version', 2);
    Ids.Add(Format(CreateGuid(), 0, 4));
    Binding.Add('customers', Ids.Clone());
    Binding.Add('vendors', Ids.Clone());
    Binding.Add('items', Ids.Clone());
    Context.Add('masterDataSource', Binding);
    Assert(Source.IsExistingPool(Context), 'Existing company master-data binding must not require a source run.');
    Assert(Source.RunId(Context) = CurrentRun, 'New documents must belong to the new movement run.');
    Assert(Source.Quantity(Context, "BCSF Entity Type"::Item) = 1, 'Bound existing articles must be available to the planner.');
  end;

  [Test]
  procedure SourceBindingRejectsUnknownContracts()
  var
    Source: Codeunit "BCSF Master Data Source";
    Context: JsonObject;
    Binding: JsonObject;
    EmptyId: Guid;
  begin
    Context := ContextFixture();
    Context.Add('generationKind', "BCSF Generation Kind"::Transactions.AsInteger());
    Binding.Add('version', 99);
    Context.Add('masterDataSource', Binding);
    asserterror Source.Validate(Context);
    asserterror Source.Capture(EmptyId, 'TRADE', '6');
    asserterror Source.Capture(CreateGuid(), 'TRADE', '6');
  end;

  [Test]
  procedure IndependentSalesOnlyAddsExplicitPurchases()
  var
    Generator: Codeunit "BCSF Sales Generator";
    Context: JsonObject;
    Binding: JsonObject;
    Settings: JsonObject;
    Targets: JsonArray;
    Dependencies: JsonArray;
  begin
    Context := ContextFixture();
    Binding.Add('version', 1);
    Settings.Add('version', 4);
    Context.Add('masterDataSource', Binding);
    Context.Add('salesSetup', Settings);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, 20, 50, 25);
    Context.Replace('targets', Targets);
    Generator.GetDependencies(Context, Settings, Dependencies);
    Assert(Dependencies.Count() = 0, 'Sales-only must not invent a purchasing or master-data generation step.');
    AddMixedTarget(Targets, "BCSF Entity Type"::PurchaseOrder, 15, 60, 20);
    Context.Replace('targets', Targets);
    Generator.GetDependencies(Context, Settings, Dependencies);
    Assert(Dependencies.Count() = 1, 'Explicit purchasing must precede dependent sales.');
  end;

  [Test]
  procedure IndependentSalesDateDoesNotInventReceipt()
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Targets: JsonArray;
    Date: Date;
  begin
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Context.Add('startingDate', '2025-11-22');
    Context.Add('endingDate', '2026-11-21');
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesOrder, 20, 100, 0);
    Context.Replace('targets', Targets);
    Date := Coordinator.DocumentDate(Context, 'SALES.ORDER', 1);
    Assert((Date >= 20251122D) and (Date <= 20261121D), 'Without selected purchasing, sales retain the period and require actual stock.');
  end;

  [Test]
  procedure ConfirmedSourceCaptureDoesNotDuplicateRegistry()
  var
    Setup: Record "BCSF Factory Setup";
    Header: Record "BCSF Run Header";
    Entry: Record "BCSF Generated Record";
    Source: Codeunit "BCSF Master Data Source";
    Binding: JsonObject;
    Again: JsonObject;
    SourceId: Guid;
    BeforeCount: Integer;
    First: Text;
    Second: Text;
  begin
    Setup.Get(Setup.GetSetupKey());
    SourceId := Setup."Industry Master Source Id";
    if IsNullGuid(SourceId) then
      SourceId := Setup."Industry Run Id";
    Header.Get(SourceId);
    BeforeCount := Entry.Count();
    Binding := Source.Capture(SourceId, Header."Profile Code", Header."Profile Version");
    Again := Source.Capture(SourceId, Header."Profile Code", Header."Profile Version");
    Binding.WriteTo(First);
    Again.WriteTo(Second);
    Assert(First = Second, 'Confirmed source identities must remain stable.');
    Assert(Entry.Count() = BeforeCount, 'Reading an existing source must never register the same records again.');
  end;

  [Test]
  procedure SelectedPoolAllowsSalesWithoutVendors()
  var
    Source: Codeunit "BCSF Master Data Source";
    Generator: Codeunit "BCSF Sales Generator";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Binding: JsonObject;
    Settings: JsonObject;
    Ids: JsonArray;
    EmptyIds: JsonArray;
    Targets: JsonArray;
    Dependencies: JsonArray;
  begin
    Context := ContextFixture();
    Context.Add('runId', Format(CreateGuid(), 0, 4));
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Ids.Add(Format(CreateGuid(), 0, 4));
    Binding.Add('version', 3);
    Binding.Add('customers', Ids.Clone());
    Binding.Add('items', Ids.Clone());
    Binding.Add('vendors', EmptyIds);
    Context.Add('masterDataSource', Binding);
    Settings.Add('version', 4);
    Context.Add('salesSetup', Settings);
    AddMixedTarget(Targets, "BCSF Entity Type"::SalesInvoice, 1, 100, 0);
    Context.Replace('targets', Targets);
    Generator.GetDependencies(Context, Settings, Dependencies);
    Assert(Dependencies.Count() = 0, 'One invoice must not add purchase or master-data targets.');
    Assert(Source.IsExistingPool(Context), 'Version 3 references existing company identities.');
    Assert(Source.Quantity(Context, "BCSF Entity Type"::Vendor) = 0, 'Sales-only must not require a vendor pool.');
    Assert(Coordinator.Disposition(Context, 'SALES.INVOICE', 1) = 1, 'One invoice at 100 percent must be posted.');
    Assert(Coordinator.Disposition(Context, 'SALES.ORDER', 1) = 0, 'Missing order means no order.');
    Assert(Coordinator.Disposition(Context, 'SALES.INVOICE', 2) = 0, 'Keys outside the target must not be planned.');
  end;

  [Test]
  procedure SelectedSupplierPoolsAllowUnequalCounts()
  var
    VendorA: Record Vendor;
    VendorB: Record Vendor;
    VendorC: Record Vendor;
    Item: Record Item;
    Source: Codeunit "BCSF Master Data Source";
    Coordinator: Codeunit "BCSF Process Coordinator";
    Context: JsonObject;
    Binding: JsonObject;
    Vendors: JsonArray;
    Items: JsonArray;
    ItemVendors: JsonArray;
    Index: Integer;
    PurchaseKey: Integer;
    LineIndex: Integer;
    ItemKey: Integer;
    Seen: List of [Integer];
  begin
    // Synthetic fixture only. The AL test transaction rolls back these
    // lightweight records; no posting or master-pool eligibility is bypassed.
    VendorA.Init();
    VendorA."No." := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
    VendorA.Insert(false);
    VendorB.Init();
    VendorB."No." := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
    VendorB.Insert(false);
    VendorC.Init();
    VendorC."No." := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
    VendorC.Insert(false);
    Vendors.Add(Format(VendorA.SystemId, 0, 4));
    Vendors.Add(Format(VendorB.SystemId, 0, 4));
    Vendors.Add(Format(VendorC.SystemId, 0, 4));
    for Index := 1 to 10 do begin
      Item.Init();
      Item."No." := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
      if Index <= 2 then
        Item."Vendor No." := VendorA."No."
      else
        if Index <= 7 then
          Item."Vendor No." := VendorB."No."
        else
          Item."Vendor No." := VendorC."No.";
      Item.Insert(false);
      Items.Add(Format(Item.SystemId, 0, 4));
      if Index <= 2 then
        ItemVendors.Add(Format(VendorA.SystemId, 0, 4))
      else
        if Index <= 7 then
          ItemVendors.Add(Format(VendorB.SystemId, 0, 4))
        else
          ItemVendors.Add(Format(VendorC.SystemId, 0, 4));
    end;
    Binding.Add('version', 3);
    Binding.Add('vendors', Vendors);
    Binding.Add('items', Items);
    Binding.Add('itemVendors', ItemVendors);
    Context := ContextFixture();
    Context.Replace('profileCode', 'TRADE');
    Context.Replace('profileVersion', '6');
    Context.Add('masterDataSource', Binding);
    for PurchaseKey := 1 to 30 do
      for LineIndex := 1 to 4 do begin
        ItemKey := Coordinator.WholesalePurchaseItemKey(Context, PurchaseKey, LineIndex);
        Assert((ItemKey >= 1) and (ItemKey <= 10), 'Every position must stay within the captured pool.');
        case PurchaseKey mod 3 of
          1: Assert(ItemKey <= 2, 'Supplier A positions must only use supplier A items.');
          2: Assert((ItemKey >= 3) and (ItemKey <= 7), 'Supplier B positions must only use supplier B items.');
          0: Assert(ItemKey >= 8, 'Supplier C positions must only use supplier C items.');
        end;
        if not Seen.Contains(ItemKey) then
          Seen.Add(ItemKey);
      end;
    Assert(Seen.Count() = 10, 'Unequal assortments must retain every selected article.');
    Vendors.RemoveAt(1);
    Vendors.RemoveAt(1);
    Binding.Replace('vendors', Vendors);
    Context.Replace('masterDataSource', Binding);
    for LineIndex := 1 to 4 do
      Assert(Source.PurchaseItemKey(Context, 1, LineIndex) >= 8, 'One supplier is sufficient and cycles its own assortment.');
    asserterror Source.PurchaseItemKey(Context, 0, 1);
    asserterror Source.PurchaseItemKey(Context, 1, 0);
  end;

  [Test]
  procedure SkippedDocumentsHaveNoPostingEvidence()
  var
    Setup: Record "BCSF Factory Setup";
    Entry: Record "BCSF Generated Record";
    InvoiceEntry: Record "BCSF Generated Record";
    Header: Record "Sales Header";
    Line: Record "Sales Line";
  begin
    Setup.Get(Setup.GetSetupKey());
    Entry.SetRange("Run Id", Setup."Industry Run Id");
    Entry.SetRange("Posting Skipped", true);
    Assert(Entry.FindSet(), 'Prepare the stock-shortage reference run before executing this native case.');
    repeat
      Entry.TestField("Skip Reason Code", 'STOCK');
      Entry.TestField("Artifact Code", 'DOCUMENT');
      Entry.TestField("Table Id", Database::"Sales Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Assert(not InvoiceEntry.Get(Entry."Run Id", Entry."Node Code", Entry."Logical Key", 'INVOICE'), 'A skipped document must not have a posted invoice identity.');
      Line.SetRange("Document Type", Header."Document Type");
      Line.SetRange("Document No.", Header."No.");
      Assert(Line.FindSet(), 'A retained document needs actual lines.');
      repeat
        Line.TestField("Quantity Shipped", 0);
        Line.TestField("Quantity Invoiced", 0);
      until Line.Next() = 0;
    until Entry.Next() = 0;
  end;

  [Test]
  procedure IsolatedDocumentPlansKeepLegacyMasterBatches()
  var
    Rules: Codeunit "BCSF Partner Rules";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Target: JsonObject;
    Plans: JsonArray;
    Token: JsonToken;
    UnitKey: Integer;
  begin
    Context := ContextFixture();
    Context.Replace('processMode', 2);
    Target.Add('entityCode', 'SALES.INVOICE');
    Target.Add('moduleCode', 'SALES');
    Target.Add('quantity', 8);
    Target.Add('processMode', 2);
    Rules.Plan('SALES.INVOICE', Context, Target, 1, 100, Plans);
    Assert(Plans.Count() = 3, 'Legacy snapshots keep their existing batch cuts.');
    Context.Add('executionPolicyVersion', 1);
    Rules.Plan('SALES.INVOICE', Context, Target, 1, 100, Plans);
    Assert(Plans.Count() = 8, 'Each new document has its own transaction and checkpoint.');
    UnitKey := 0;
    foreach Token in Plans do begin
      UnitKey += 1;
      Assert(Contract.GetInteger(Token.AsObject(), 'firstKey') = UnitKey, 'Singleton plans must cover every requested key exactly once.');
      Assert(Contract.GetInteger(Token.AsObject(), 'lastKey') = UnitKey, 'A document transaction must contain exactly one requested unit.');
    end;
    Rules.Plan('ITEM', Context, ItemTarget(), 1, 100, Plans);
    Assert(Plans.Count() = 3, 'Master generation keeps the captured batch size.');
    Context.Replace('executionPolicyVersion', 99);
    asserterror Contract.CheckContext(Context);
  end;

  [Test]
  procedure MissingDocumentSourceIsReadOnlySkip()
  var
    Header: Record "Sales Header";
    Line: Record "Sales Line";
    Rules: Codeunit "BCSF Partner Rules";
    Context: JsonObject;
    Settings: JsonObject;
    Binding: JsonObject;
    Target: JsonObject;
    Ids: JsonArray;
    BeforeHeaders: Integer;
    BeforeLines: Integer;
  begin
    Context := ContextFixture();
    Context.Add('executionPolicyVersion', 1);
    Settings.Add('version', 4);
    Settings.Add('location', '');
    Ids.Add(Format(CreateGuid(), 0, 4));
    Settings.Add('customers', Ids);
    Context.Add('salesSetup', Settings);
    Binding.Add('version', 3);
    Context.Add('masterDataSource', Binding);
    Target.Add('entityCode', 'SALES.INVOICE');
    Target.Add('moduleCode', 'SALES');
    BeforeHeaders := Header.Count();
    BeforeLines := Line.Count();
    Assert(Rules.InspectDocument(Context, Target, 1) = 'CUSTOMER', 'A missing selected customer must be classified before any document write.');
    Assert(Header.Count() = BeforeHeaders, 'Read-only inspection must not create a sales header.');
    Assert(Line.Count() = BeforeLines, 'Read-only inspection must not create sales lines.');
  end;

  [Test]
  procedure CompletedPreflightSkipsHaveNoBusinessEvidence()
  var
    Setup: Record "BCSF Factory Setup";
    TempMetric: Record "BCSF Step Metric" temporary;
    Monitoring: Codeunit "BCSF Monitoring Mgt";
    Batch: Record "BCSF Batch";
    Entry: Record "BCSF Generated Record";
    Checkpoint: Record "BCSF Batch Checkpoint";
    Recovery: Codeunit "BCSF Batch Recovery";
    Contract: Codeunit "BCSF Contract JSON";
    Result: JsonObject;
  begin
    Setup.Get(Setup.GetSetupKey());
    Batch.SetRange("Run Id", Setup."Industry Run Id");
    Batch.SetRange("Skipped Units", 1);
    Assert(Batch.FindSet(), 'Prepare the native blocked-master reference run before this case.');
    repeat
      Batch.TestField(Status, Batch.Status::Completed);
      Batch.TestField("Processed Units", 0);
      Batch.TestField("Created Records", 0);
      Entry.SetRange("Batch Id", Batch."Batch Id");
      Assert(Entry.IsEmpty(), 'A preflight skip must never fabricate standard provenance.');
      Checkpoint.Get(Batch."Batch Id");
      Result := Checkpoint.ReadStoredResult();
      Assert(Contract.GetInteger(Result, 'processedUnits') = 0, 'Skip checkpoint must not claim created work.');
      Recovery.VerifyCheckpoint(Batch."Batch Id");
    until Batch.Next() = 0;
    Monitoring.LoadSteps(Setup."Industry Run Id", TempMetric);
    if TempMetric.FindSet() then
      repeat
        Assert(TempMetric."Planned Units" = TempMetric."Confirmed Units" + TempMetric."Skipped Units" + TempMetric."Remaining Units", 'Requested work must equal created, skipped and outstanding units without double counting.');
      until TempMetric.Next() = 0;
  end;

  [Test]
  procedure UncertainDocumentIsNotRetriedWhileOthersFinish()
  var
    Setup: Record "BCSF Factory Setup";
    Failed: Record "BCSF Batch";
    Later: Record "BCSF Batch";
    Execution: Record "BCSF Run Execution";
  begin
    Setup.Get(Setup.GetSetupKey());
    Failed.SetRange("Run Id", Setup."Industry Run Id");
    Failed.SetRange(Status, Failed.Status::NeedsReview);
    Assert(Failed.FindFirst(), 'Prepare the native standard-posting failure reference run.');
    Failed.TestField("Schedule Attempts", 1);
    Later.SetRange("Run Id", Failed."Run Id");
    Later.SetRange("Node Code", Failed."Node Code");
    Later.SetFilter("Sequence No.", '>%1', Failed."Sequence No.");
    Later.SetRange(Status, Later.Status::Completed);
    Later.SetFilter("Processed Units", '>0');
    Assert(not Later.IsEmpty(), 'An uncertain document must not prevent independent later documents from finishing.');
    Execution.Get(Failed."Run Id");
    Execution.TestField(Status, Execution.Status::Failed);
    Failed.Get(Failed."Batch Id");
    Failed.TestField(Status, Failed.Status::NeedsReview);
  end;

  [Test]
  procedure ExistingFoundationAddsTechnicalSetupIdempotently()
  var
    TempDiff: Record "BCSF Setup Diff" temporary;
    Scenario: Record "BCSF Scenario";
    Location: Record Location;
    Account: Record "G/L Account";
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    InventoryPosting: Record "Inventory Posting Setup";
    Foundation: Codeunit "BCSF Demo Partner Setup";
    AccountCount: Integer;
    LocationCount: Integer;
    MappingCount: Integer;
  begin
    AccountCount := Account.Count();
    LocationCount := Location.Count();
    MappingCount := InventoryPosting.Count();
    Foundation.PrepareExisting(Today(), false, TempDiff);
    Assert(Location.Count() = LocationCount, 'Preview must not create a location.');
    Assert(InventoryPosting.Count() = MappingCount, 'Preview must not create posting mappings.');
    Foundation.PrepareExisting(Today(), true, TempDiff);
    Scenario.Init();
    Foundation.BindExistingScenario(Scenario);
    Location.Get(Scenario."Item Location Code");
    Location.TestField("Bin Mandatory", false);
    Location.TestField("Require Shipment", false);
    Location.TestField("Require Receive", false);
    General.Get(Scenario."Gen. Bus. Posting Group", Scenario."Item Product Group");
    VAT.Get(Scenario."VAT Bus. Posting Group", Scenario."Item VAT Product Group");
    InventoryPosting.Get(Location.Code, Scenario."Item Inventory Group");
    LocationCount := Location.Count();
    MappingCount := InventoryPosting.Count();
    Foundation.PrepareExisting(Today(), true, TempDiff);
    Assert(Location.Count() = LocationCount, 'Repeated preparation must not duplicate locations.');
    Assert(InventoryPosting.Count() = MappingCount, 'Repeated preparation must not duplicate mappings.');
    Assert(Account.Count() = AccountCount, 'Existing finance mode must never invent G/L accounts.');
    Scenario."Item Product Group" := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
    asserterror Foundation.BindExistingScenario(Scenario);
    Assert(Account.Count() = AccountCount, 'An explicit unmapped role must fail without creating substitute accounts.');
  end;

  local procedure Assert(Condition: Boolean; MessageText: Text)
  begin
    if not Condition then
      Error(MessageText);
  end;
}
#endif
