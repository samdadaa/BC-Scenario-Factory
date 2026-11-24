namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using System.Security.User;

codeunit 90369 "BCSF Dashboard Stock"
{
  Access = Internal;

  procedure Build(GroupKey: Text; EntireCompany: Boolean; StockRunId: Guid): JsonObject
  var
    Rows: RecordRef;
    Stock: JsonObject;
    Groups: JsonArray;
    Catalog: JsonArray;
    Metrics: JsonArray;
    Entry: JsonToken;
    Metric: JsonObject;
    View: JsonObject;
    Status: Text;
    Count: Integer;
    CanOpen: Boolean;
    RowsOpened: Boolean;
  begin
    AddGroup(Groups, 'master', MasterGroupLbl);
    AddGroup(Groups, 'sales', SalesGroupLbl);
    AddGroup(Groups, 'purchase', PurchaseGroupLbl);
    AddGroup(Groups, 'inventory', InventoryGroupLbl);
    AddGroup(Groups, 'assembly', AssemblyGroupLbl);
    AddGroup(Groups, 'entries', EntriesGroupLbl);
    AddGroup(Groups, 'finance', FinanceGroupLbl);
    AddGroup(Groups, 'warehouse', WarehouseGroupLbl);
    AddGroup(Groups, 'manufacturing', ManufacturingGroupLbl);
    AddGroup(Groups, 'projects', ProjectsGroupLbl);
    AddGroup(Groups, 'planning', PlanningGroupLbl);
    AddGroup(Groups, 'service', ServiceGroupLbl);
    AddGroup(Groups, 'assets', AssetsGroupLbl);
    AddGroup(Groups, 'contacts', ContactsGroupLbl);
    Stock.Add('groups', Groups);
    Stock.Add('group', GroupKey);
    Stock.Add('entireCompany', EntireCompany);
    Stock.Add('runId', FormatRunId(StockRunId, EntireCompany));
    if GroupKey <> '' then begin
      LoadCatalog(GroupKey, Catalog);
      foreach Entry in Catalog do begin
        Metric := Entry.AsObject();
        Clear(View);
        Count := 0;
        Status := '';
        CanOpen := false;
        if not TryBuildView(GroupKey, Metric, EntireCompany, StockRunId, Rows, Count, Status, CanOpen, RowsOpened) then begin
          Status := UnverifiedLbl;
          CanOpen := false;
          Count := -1;
          ClearLastError();
        end;
        CloseRows(Rows, RowsOpened);
        View.Add('key', TextProperty(Metric, 'key'));
        View.Add('caption', MetricCaption(Metric));
        View.Add('status', Status);
        View.Add('noGenerator', Status = NoGeneratorLbl);
        View.Add('canOpen', CanOpen);
        if Count >= 0 then
          View.Add('count', Count);
        Metrics.Add(View);
      end;
    end;
    Stock.Add('metrics', Metrics);
    exit(Stock);
  end;

  // Company data view: all groups in one payload. Keys carry the group prefix (like run results), so one
  // OpenMetric call resolves group and metric; only built while the company data view is active.
  procedure BuildView(AllGroups: Boolean; EntireCompany: Boolean; StockRunId: Guid): JsonObject
  var
    Stock: JsonObject;
    Part: JsonObject;
    Metric: JsonObject;
    Metrics: JsonArray;
    Groups: JsonToken;
    Group: JsonToken;
    Values: JsonToken;
    Value: JsonToken;
    GroupKey: Text;
  begin
    Stock := Build('', EntireCompany, StockRunId);
    if not AllGroups then
      exit(Stock);
    Stock.Get('groups', Groups);
    foreach Group in Groups.AsArray() do begin
      GroupKey := TextProperty(Group.AsObject(), 'key');
      Part := Build(GroupKey, EntireCompany, StockRunId);
      Part.Get('metrics', Values);
      foreach Value in Values.AsArray() do begin
        Metric := Value.AsObject();
        Metric.Add('group', GroupKey);
        if GroupKey <> 'master' then
          Metric.Replace('key', GroupKey + '/' + TextProperty(Metric, 'key'));
        Metrics.Add(Metric);
      end;
    end;
    Stock.Replace('metrics', Metrics);
    Stock.Add('all', true);
    exit(Stock);
  end;

  procedure BuildRunResults(RunId: Guid): JsonObject
  var
    Stock: JsonObject;
    Result: JsonObject;
    Values: JsonToken;
    Value: JsonToken;
    Metrics: JsonArray;
  begin
    Stock := Build('master', false, RunId);
    Stock.Get('metrics', Values);
    foreach Value in Values.AsArray() do
      if TextProperty(Value.AsObject(), 'key') in ['customer', 'vendor', 'shipTo', 'orderAddress', 'customerBank', 'vendorBank', 'item', 'category', 'itemUnit', 'attribute', 'attributeValue', 'attributeMapping', 'variant', 'itemReference', 'itemVendor', 'substitution', 'sku', 'bin', 'binContent'] then
        Metrics.Add(Value);
    AddRunMetrics('sales', RunId, Metrics);
    AddRunMetrics('purchase', RunId, Metrics);
    AddRunMetrics('inventory', RunId, Metrics);
    AddRunMetrics('assembly', RunId, Metrics);
    AddRunMetrics('projects', RunId, Metrics);
    AddRunMetrics('planning', RunId, Metrics);
    AddRunMetrics('warehouse', RunId, Metrics);
    AddRunMetrics('manufacturing', RunId, Metrics);
    AddRunMetrics('service', RunId, Metrics);
    AddRunMetrics('assets', RunId, Metrics);
    AddRunMetrics('contacts', RunId, Metrics);
    AddRunMetrics('entries', RunId, Metrics);
    Result.Add('metrics', Metrics);
    exit(Result);
  end;

  local procedure AddRunMetrics(GroupKey: Text; RunId: Guid; var Metrics: JsonArray)
  var
    Header: Record "BCSF Run Header";
    Stock: JsonObject;
    Values: JsonToken;
    Value: JsonToken;
    Metric: JsonObject;
    MetricKey: Text;
    ShowZero: Boolean;
  begin
    Header.Get(RunId);
    Stock := Build(GroupKey, false, RunId);
    Stock.Get('metrics', Values);
    foreach Value in Values.AsArray() do begin
      Metric := Value.AsObject();
      MetricKey := TextProperty(Metric, 'key');
      ShowZero := (Header."Process Mode" = "BCSF Process Mode"::FollowUpProcesses) and
        (GroupKey = 'entries') and (MetricKey in ['customerPayment', 'vendorPayment', 'bankEntry']);
      if (GroupKey in ['entries', 'inventory', 'assembly', 'projects', 'planning', 'warehouse', 'manufacturing', 'service', 'assets', 'contacts']) or (MetricKey in ['quote', 'blanket', 'order', 'invoice', 'postedShipment', 'postedReceipt', 'postedInvoice', 'credit', 'postedCredit', 'return', 'postedReturn']) then
        if IncludeRunMetric(Metric, ShowZero) then begin
          Metric.Replace('key', GroupKey + '/' + MetricKey);
          Metrics.Add(Metric);
        end;
    end;
  end;

  local procedure IncludeRunMetric(Metric: JsonObject; ShowZero: Boolean): Boolean
  begin
    if BoolProperty(Metric, 'noGenerator') then
      exit(false);
    if not Metric.Contains('count') then
      exit(true);
    exit(ShowZero or (IntProperty(Metric, 'count') > 0));
  end;

  procedure OpenMetric(GroupKey: Text; MetricKey: Text; EntireCompany: Boolean; StockRunId: Guid; LastStock: JsonObject)
  var
    Rows: RecordRef;
    Catalog: JsonArray;
    Item: JsonToken;
    Metric: JsonObject;
    Count: Integer;
    ExpectedCount: Integer;
    Status: Text;
    CanOpen: Boolean;
    RowsOpened: Boolean;
    Slash: Integer;
  begin
    if not GetDisplayedCount(LastStock, MetricKey, ExpectedCount) then
      Error(ChangedLbl);
    // Run results carry the module as key prefix (sales/, purchase/, entries/, inventory/, assembly/, projects/, planning/,
    // warehouse/, manufacturing/, service/, assets/, contacts/). The prefix selects the catalog group of the tile.
    if GroupKey = 'master' then begin
      Slash := StrPos(MetricKey, '/');
      if Slash > 1 then begin
        GroupKey := CopyStr(MetricKey, 1, Slash - 1);
        MetricKey := CopyStr(MetricKey, Slash + 1);
      end;
    end;
    LoadCatalog(GroupKey, Catalog);
    foreach Item in Catalog do begin
      Metric := Item.AsObject();
      if TextProperty(Metric, 'key') = MetricKey then begin
        if not TryBuildView(GroupKey, Metric, EntireCompany, StockRunId, Rows, Count, Status, CanOpen, RowsOpened) then begin
          ClearLastError();
          Error(UnverifiedLbl);
        end;
        if not CanOpen or (Count <> ExpectedCount) then
          Error(ChangedLbl);
        if Rows.Number() = Database::"Item Attribute Value Mapping" then
          OpenAttributeMappings(Rows)
        else
          OpenStandardPage(Rows, IntProperty(Metric, 'page'));
        CloseRows(Rows, RowsOpened);
        exit;
      end;
    end;
    Error(ChangedLbl);
  end;

  procedure IsGroup(GroupKey: Text): Boolean
  var
    Catalog: JsonArray;
  begin
    LoadCatalog(GroupKey, Catalog);
    exit(Catalog.Count() > 0);
  end;

  [TryFunction]
  local procedure TryBuildView(GroupKey: Text; Metric: JsonObject; EntireCompany: Boolean; StockRunId: Guid; var Rows: RecordRef; var Count: Integer; var Status: Text; var CanOpen: Boolean; var RowsOpened: Boolean)
  var
    Entry: Record "BCSF Generated Record";
    CustomerEntry: Record "Cust. Ledger Entry";
    VendorEntry: Record "Vendor Ledger Entry";
    ItemEntry: Record "Item Ledger Entry";
    JobEntry: Record "Job Ledger Entry";
    AssemblyItem: Record Item;
    FilterField: FieldRef;
    PageId: Integer;
  begin
    Count := -1;
    CanOpen := false;
    PageId := IntProperty(Metric, 'page');
    Rows.Open(IntProperty(Metric, 'table'));
    RowsOpened := true;
    Rows.SecurityFiltering(SecurityFilter::Filtered);
    if not Rows.ReadPermission() then begin
      Status := NoAccessLbl;
      exit;
    end;
    if PageId <> 0 then
      if not CanExecutePage(PageId) then begin
        Status := NoAccessLbl;
        exit;
      end;
    if not EntireCompany then begin
      if not BoolProperty(Metric, 'origin') then begin
        Status := NoGeneratorLbl;
        exit;
      end;
      Entry.SecurityFiltering(SecurityFilter::Filtered);
      if not Entry.ReadPermission() then begin
        Status := NoAccessLbl;
        exit;
      end;
    end;
    case TextProperty(Metric, 'key') of
      'customerPayment':
        begin
          FilterField := Rows.Field(CustomerEntry.FieldNo("Document Type"));
          FilterField.SetRange(CustomerEntry."Document Type"::Payment);
        end;
      'vendorPayment':
        begin
          FilterField := Rows.Field(VendorEntry.FieldNo("Document Type"));
          FilterField.SetRange(VendorEntry."Document Type"::Payment);
        end;
      'jobUsage':
        begin
          FilterField := Rows.Field(JobEntry.FieldNo("Entry Type"));
          FilterField.SetRange(JobEntry."Entry Type"::Usage);
        end;
      'jobSale':
        begin
          FilterField := Rows.Field(JobEntry.FieldNo("Entry Type"));
          FilterField.SetRange(JobEntry."Entry Type"::Sale);
        end;
      'positiveAdjustment':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::"Positive Adjmt.");
        end;
      'negativeAdjustment':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::"Negative Adjmt.");
        end;
      'transferEntry':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::Transfer);
        end;
      'assemblyConsumption':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::"Assembly Consumption");
        end;
      'assemblyOutput':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::"Assembly Output");
        end;
      'productionItem':
        begin
          FilterField := Rows.Field(AssemblyItem.FieldNo("Replenishment System"));
          FilterField.SetRange(AssemblyItem."Replenishment System"::"Prod. Order");
        end;
      'productionConsumption':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::Consumption);
        end;
      'productionOutput':
        begin
          FilterField := Rows.Field(ItemEntry.FieldNo("Entry Type"));
          FilterField.SetRange(ItemEntry."Entry Type"::Output);
        end;
      'assemblyItem':
        begin
          FilterField := Rows.Field(AssemblyItem.FieldNo("Replenishment System"));
          FilterField.SetRange(AssemblyItem."Replenishment System"::Assembly);
        end;
      'customerCredit':
        begin
          FilterField := Rows.Field(CustomerEntry.FieldNo("Document Type"));
          FilterField.SetRange(CustomerEntry."Document Type"::"Credit Memo");
        end;
      'vendorCredit':
        begin
          FilterField := Rows.Field(VendorEntry.FieldNo("Document Type"));
          FilterField.SetRange(VendorEntry."Document Type"::"Credit Memo");
        end;
    end;
    if not ApplyBaseFilters(GroupKey, PageId, Rows) then begin
      Status := UnverifiedLbl;
      exit;
    end;
    if not EntireCompany then
      ApplyOriginFilter(Rows, Entry, StockRunId);
    Count := Rows.Count();
    if PageId = 0 then
      Status := NoListLbl
    else
      CanOpen := Count > 0;
  end;

  // Marks avoid a bounded OR filter. Only identities that still exist are included.
  local procedure ApplyOriginFilter(var Rows: RecordRef; var Entry: Record "BCSF Generated Record"; StockRunId: Guid)
  begin
    if IsNullGuid(StockRunId) then
      Entry.SetCurrentKey("Table Id", "Record SystemId")
    else begin
      Entry.SetCurrentKey("Run Id");
      Entry.SetRange("Run Id", StockRunId);
    end;
    Entry.SetRange("Table Id", Rows.Number());
    Entry.SetLoadFields("Record SystemId");
    if Entry.FindSet() then
      repeat
        if not IsNullGuid(Entry."Record SystemId") then
          if Rows.GetBySystemId(Entry."Record SystemId") then
            Rows.Mark(true);
      until Entry.Next() = 0;
    // Existing document, responsibility and security filters stay in force.
    Rows.MarkedOnly(true);
  end;

  local procedure ApplyBaseFilters(GroupKey: Text; PageId: Integer; var Rows: RecordRef): Boolean
  var
    SalesHeader: Record "Sales Header";
    PurchHeader: Record "Purchase Header";
    AssemblyHeader: Record "Assembly Header";
    UserSetup: Codeunit "User Setup Management";
    FilterField: FieldRef;
    SalesType: Enum "Sales Document Type";
    PurchaseType: Enum "Purchase Document Type";
    Responsibility: Code[10];
    Index: Integer;
    Found: Boolean;
  begin
    Rows.FilterGroup(10);
    case Rows.Number() of
      Database::"Sales Header":
        begin
          case PageId of
            Page::"Sales Quotes": SalesType := SalesType::Quote;
            Page::"Blanket Sales Orders": SalesType := SalesType::"Blanket Order";
            Page::"Sales Order List": SalesType := SalesType::Order;
            Page::"Sales Invoice List": SalesType := SalesType::Invoice;
            Page::"Sales Credit Memos": SalesType := SalesType::"Credit Memo";
            Page::"Sales Return Order List": SalesType := SalesType::"Return Order";
            else exit(false);
          end;
          FilterField := Rows.Field(SalesHeader.FieldNo("Document Type"));
          FilterField.SetRange(SalesType);
        end;
      Database::"Purchase Header":
        begin
          case PageId of
            Page::"Purchase Quotes": PurchaseType := PurchaseType::Quote;
            Page::"Blanket Purchase Orders": PurchaseType := PurchaseType::"Blanket Order";
            Page::"Purchase Order List": PurchaseType := PurchaseType::Order;
            Page::"Purchase Invoices": PurchaseType := PurchaseType::Invoice;
            Page::"Purchase Credit Memos": PurchaseType := PurchaseType::"Credit Memo";
            Page::"Purchase Return Order List": PurchaseType := PurchaseType::"Return Order";
            else exit(false);
          end;
          FilterField := Rows.Field(PurchHeader.FieldNo("Document Type"));
          FilterField.SetRange(PurchaseType);
        end;
      Database::"Assembly Header":
        begin
          FilterField := Rows.Field(AssemblyHeader.FieldNo("Document Type"));
          FilterField.SetRange(AssemblyHeader."Document Type"::Order);
        end;
    end;

    if GroupKey = 'sales' then
      Responsibility := UserSetup.GetSalesFilter();
    if GroupKey = 'purchase' then
      Responsibility := UserSetup.GetPurchasesFilter();
    if Responsibility <> '' then begin
      for Index := 1 to Rows.FieldCount() do begin
        FilterField := Rows.FieldIndex(Index);
        if FilterField.Name() = 'Responsibility Center' then begin
          FilterField.SetRange(Responsibility);
          Found := true;
        end;
      end;
      if not Found then
        exit(false);
    end;
    Rows.FilterGroup(0);
    exit(true);
  end;

  procedure CanExecutePage(PageId: Integer): Boolean
  var
    TempPermission: Record "Expanded Permission" temporary;
    UserPermissions: Codeunit "User Permissions";
  begin
    TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Page, PageId);
    exit(TempPermission."Execute Permission" = TempPermission."Execute Permission"::Yes);
  end;

  local procedure GetDisplayedCount(LastStock: JsonObject; MetricKey: Text; var Count: Integer): Boolean
  var
    Data: JsonToken;
    Row: JsonToken;
    Metric: JsonObject;
  begin
    if not LastStock.Get('metrics', Data) then
      exit(false);
    foreach Row in Data.AsArray() do begin
      Metric := Row.AsObject();
      if (TextProperty(Metric, 'key') = MetricKey) and BoolProperty(Metric, 'canOpen') then begin
        Count := IntProperty(Metric, 'count');
        exit(true);
      end;
    end;
    exit(false);
  end;

  local procedure CloseRows(var Rows: RecordRef; var RowsOpened: Boolean)
  begin
    if RowsOpened then
      Rows.Close();
    RowsOpened := false;
    Clear(Rows);
  end;

  local procedure MetricCaption(Metric: JsonObject): Text
  var
    Rows: RecordRef;
    CaptionText: Text;
  begin
    CaptionText := TextProperty(Metric, 'caption');
    if CaptionText <> '' then
      exit(CaptionText);
    Rows.Open(IntProperty(Metric, 'table'));
    CaptionText := Rows.Caption();
    Rows.Close();
    exit(CaptionText);
  end;

  local procedure OpenStandardPage(var Rows: RecordRef; PageId: Integer)
  var
    Customer: Record "Customer";
    Vendor: Record "Vendor";
    Contact: Record "Contact";
    ShiptoAddress: Record "Ship-to Address";
    OrderAddress: Record "Order Address";
    CustomerBankAccount: Record "Customer Bank Account";
    VendorBankAccount: Record "Vendor Bank Account";
    GLAccount: Record "G/L Account";
    BankAccount: Record "Bank Account";
    ItemCategory: Record "Item Category";
    ItemUnit: Record "Item Unit of Measure";
    ItemAttribute: Record "Item Attribute";
    ItemAttributeValue: Record "Item Attribute Value";
    ItemVariant: Record "Item Variant";
    ItemReference: Record "Item Reference";
    ItemVendor: Record "Item Vendor";
    ItemSubstitution: Record "Item Substitution";
    StockkeepingUnit: Record "Stockkeeping Unit";
    Bin: Record "Bin";
    BinContent: Record "Bin Content";
    Item: Record "Item";
    Location: Record "Location";
    SalesHeader: Record "Sales Header";
    SalesShipmentHeader: Record "Sales Shipment Header";
    SalesInvoiceHeader: Record "Sales Invoice Header";
    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    ReturnReceiptHeader: Record "Return Receipt Header";
    PurchaseHeader: Record "Purchase Header";
    PurchRcptHeader: Record "Purch. Rcpt. Header";
    PurchInvHeader: Record "Purch. Inv. Header";
    PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    ReturnShipmentHeader: Record "Return Shipment Header";
    TransferShipmentHeader: Record "Transfer Shipment Header";
    TransferReceiptHeader: Record "Transfer Receipt Header";
    GLEntry: Record "G/L Entry";
    CustLedgerEntry: Record "Cust. Ledger Entry";
    VendorLedgerEntry: Record "Vendor Ledger Entry";
    BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    VATEntry: Record "VAT Entry";
    ItemLedgerEntry: Record "Item Ledger Entry";
    ValueEntry: Record "Value Entry";
    PaymentTerms: Record "Payment Terms";
    GeneralPostingSetup: Record "General Posting Setup";
    WarehouseEntry: Record "Warehouse Entry";
    ProductionBOMHeader: Record "Production BOM Header";
    AssemblyHeader: Record "Assembly Header";
    PostedAssemblyHeader: Record "Posted Assembly Header";
    ResLedgerEntry: Record "Res. Ledger Entry";
    Job: Record "Job";
    JobTaskRecord: Record "Job Task";
    JobPlanningRecord: Record "Job Planning Line";
    JobLedgerRecord: Record "Job Ledger Entry";
    RequisitionRecord: Record "Requisition Line";
    ServiceItem: Record "Service Item";
    FixedAsset: Record "Fixed Asset";
    AssetLedgerEntry: Record "FA Ledger Entry";
    RegisteredActivity: Record "Registered Whse. Activity Hdr.";
    ProductionOrderRecord: Record "Production Order";
    ServiceHeaderRecord: Record "Service Header";
    CampaignRecord: Record Campaign;
    OpportunityRecord: Record Opportunity;
    MaintenanceRecord: Record "Maintenance Ledger Entry";
    SegmentRecord: Record "Segment Header";
    TaskRecord: Record "To-do";
    ServiceInvoiceRecord: Record "Service Invoice Header";
    ServiceShipmentRecord: Record "Service Shipment Header";
  begin
    if not Rows.FindFirst() then
      Error(ChangedLbl);
    case Rows.Number() of
      Database::"Customer":
        begin
          Rows.SetTable(Customer, false);
          Page.Run(PageId, Customer);
        end;
      Database::"Vendor":
        begin
          Rows.SetTable(Vendor, false);
          Page.Run(PageId, Vendor);
        end;
      Database::"Contact":
        begin
          Rows.SetTable(Contact, false);
          Page.Run(PageId, Contact);
        end;
      Database::"Ship-to Address":
        begin
          Rows.SetTable(ShiptoAddress, false);
          Page.Run(PageId, ShiptoAddress);
        end;
      Database::"Order Address":
        begin
          Rows.SetTable(OrderAddress, false);
          Page.Run(PageId, OrderAddress);
        end;
      Database::"Customer Bank Account":
        begin
          Rows.SetTable(CustomerBankAccount, false);
          Page.Run(PageId, CustomerBankAccount);
        end;
      Database::"Vendor Bank Account":
        begin
          Rows.SetTable(VendorBankAccount, false);
          Page.Run(PageId, VendorBankAccount);
        end;
      Database::"G/L Account":
        begin
          Rows.SetTable(GLAccount, false);
          Page.Run(PageId, GLAccount);
        end;
      Database::"Bank Account":
        begin
          Rows.SetTable(BankAccount, false);
          Page.Run(PageId, BankAccount);
        end;
      Database::"Item":
        begin
          Rows.SetTable(Item, false);
          Page.Run(PageId, Item);
        end;
      Database::"Item Category":
        begin
          Rows.SetTable(ItemCategory, false);
          Page.Run(PageId, ItemCategory);
        end;
      Database::"Item Unit of Measure":
        begin
          Rows.SetTable(ItemUnit, false);
          Page.Run(PageId, ItemUnit);
        end;
      Database::"Item Attribute":
        begin
          Rows.SetTable(ItemAttribute, false);
          Page.Run(PageId, ItemAttribute);
        end;
      Database::"Item Attribute Value":
        begin
          Rows.SetTable(ItemAttributeValue, false);
          Page.Run(PageId, ItemAttributeValue);
        end;
      Database::"Item Variant":
        begin
          Rows.SetTable(ItemVariant, false);
          Page.Run(PageId, ItemVariant);
        end;
      Database::"Item Reference":
        begin
          Rows.SetTable(ItemReference, false);
          Page.Run(PageId, ItemReference);
        end;
      Database::"Item Vendor":
        begin
          Rows.SetTable(ItemVendor, false);
          Page.Run(PageId, ItemVendor);
        end;
      Database::"Item Substitution":
        begin
          Rows.SetTable(ItemSubstitution, false);
          Page.Run(PageId, ItemSubstitution);
        end;
      Database::"Stockkeeping Unit":
        begin
          Rows.SetTable(StockkeepingUnit, false);
          Page.Run(PageId, StockkeepingUnit);
        end;
      Database::"Bin":
        begin
          Rows.SetTable(Bin, false);
          Page.Run(PageId, Bin);
        end;
      Database::"Bin Content":
        begin
          Rows.SetTable(BinContent, false);
          Page.Run(PageId, BinContent);
        end;
      Database::"Location":
        begin
          Rows.SetTable(Location, false);
          Page.Run(PageId, Location);
        end;
      Database::"Sales Header":
        begin
          Rows.SetTable(SalesHeader, false);
          Page.Run(PageId, SalesHeader);
        end;
      Database::"Sales Shipment Header":
        begin
          Rows.SetTable(SalesShipmentHeader, false);
          Page.Run(PageId, SalesShipmentHeader);
        end;
      Database::"Sales Invoice Header":
        begin
          Rows.SetTable(SalesInvoiceHeader, false);
          Page.Run(PageId, SalesInvoiceHeader);
        end;
      Database::"Sales Cr.Memo Header":
        begin
          Rows.SetTable(SalesCrMemoHeader, false);
          Page.Run(PageId, SalesCrMemoHeader);
        end;
      Database::"Return Receipt Header":
        begin
          Rows.SetTable(ReturnReceiptHeader, false);
          Page.Run(PageId, ReturnReceiptHeader);
        end;
      Database::"Purchase Header":
        begin
          Rows.SetTable(PurchaseHeader, false);
          Page.Run(PageId, PurchaseHeader);
        end;
      Database::"Purch. Rcpt. Header":
        begin
          Rows.SetTable(PurchRcptHeader, false);
          Page.Run(PageId, PurchRcptHeader);
        end;
      Database::"Purch. Inv. Header":
        begin
          Rows.SetTable(PurchInvHeader, false);
          Page.Run(PageId, PurchInvHeader);
        end;
      Database::"Purch. Cr. Memo Hdr.":
        begin
          Rows.SetTable(PurchCrMemoHdr, false);
          Page.Run(PageId, PurchCrMemoHdr);
        end;
      Database::"Return Shipment Header":
        begin
          Rows.SetTable(ReturnShipmentHeader, false);
          Page.Run(PageId, ReturnShipmentHeader);
        end;
      Database::"Transfer Shipment Header":
        begin
          Rows.SetTable(TransferShipmentHeader, false);
          Page.Run(PageId, TransferShipmentHeader);
        end;
      Database::"Transfer Receipt Header":
        begin
          Rows.SetTable(TransferReceiptHeader, false);
          Page.Run(PageId, TransferReceiptHeader);
        end;
      Database::"G/L Entry":
        begin
          Rows.SetTable(GLEntry, false);
          Page.Run(PageId, GLEntry);
        end;
      Database::"Cust. Ledger Entry":
        begin
          Rows.SetTable(CustLedgerEntry, false);
          Page.Run(PageId, CustLedgerEntry);
        end;
      Database::"Vendor Ledger Entry":
        begin
          Rows.SetTable(VendorLedgerEntry, false);
          Page.Run(PageId, VendorLedgerEntry);
        end;
      Database::"Bank Account Ledger Entry":
        begin
          Rows.SetTable(BankAccountLedgerEntry, false);
          Page.Run(PageId, BankAccountLedgerEntry);
        end;
      Database::"VAT Entry":
        begin
          Rows.SetTable(VATEntry, false);
          Page.Run(PageId, VATEntry);
        end;
      Database::"Item Ledger Entry":
        begin
          Rows.SetTable(ItemLedgerEntry, false);
          Page.Run(PageId, ItemLedgerEntry);
        end;
      Database::"Value Entry":
        begin
          Rows.SetTable(ValueEntry, false);
          Page.Run(PageId, ValueEntry);
        end;
      Database::"Payment Terms":
        begin
          Rows.SetTable(PaymentTerms, false);
          Page.Run(PageId, PaymentTerms);
        end;
      Database::"General Posting Setup":
        begin
          Rows.SetTable(GeneralPostingSetup, false);
          Page.Run(PageId, GeneralPostingSetup);
        end;
      Database::"Warehouse Entry":
        begin
          Rows.SetTable(WarehouseEntry, false);
          Page.Run(PageId, WarehouseEntry);
        end;
      Database::"Production BOM Header":
        begin
          Rows.SetTable(ProductionBOMHeader, false);
          Page.Run(PageId, ProductionBOMHeader);
        end;
      Database::"Assembly Header":
        begin
          Rows.SetTable(AssemblyHeader, false);
          Page.Run(PageId, AssemblyHeader);
        end;
      Database::"Posted Assembly Header":
        begin
          Rows.SetTable(PostedAssemblyHeader, false);
          Page.Run(PageId, PostedAssemblyHeader);
        end;
      Database::"Res. Ledger Entry":
        begin
          Rows.SetTable(ResLedgerEntry, false);
          Page.Run(PageId, ResLedgerEntry);
        end;
      Database::"Job":
        begin
          Rows.SetTable(Job, false);
          Page.Run(PageId, Job);
        end;
      Database::"Job Task":
        begin
          Rows.SetTable(JobTaskRecord, false);
          Page.Run(PageId, JobTaskRecord);
        end;
      Database::"Job Planning Line":
        begin
          Rows.SetTable(JobPlanningRecord, false);
          Page.Run(PageId, JobPlanningRecord);
        end;
      Database::"Job Ledger Entry":
        begin
          Rows.SetTable(JobLedgerRecord, false);
          Page.Run(PageId, JobLedgerRecord);
        end;
      Database::"Requisition Line":
        begin
          Rows.SetTable(RequisitionRecord, false);
          Page.Run(PageId, RequisitionRecord);
        end;
      Database::"Service Item":
        begin
          Rows.SetTable(ServiceItem, false);
          Page.Run(PageId, ServiceItem);
        end;
      Database::"Fixed Asset":
        begin
          Rows.SetTable(FixedAsset, false);
          Page.Run(PageId, FixedAsset);
        end;
      Database::"FA Ledger Entry":
        begin
          Rows.SetTable(AssetLedgerEntry, false);
          Page.Run(PageId, AssetLedgerEntry);
        end;
      Database::"Registered Whse. Activity Hdr.":
        begin
          Rows.SetTable(RegisteredActivity, false);
          Page.Run(PageId, RegisteredActivity);
        end;
      Database::"Maintenance Ledger Entry":
        begin
          Rows.SetTable(MaintenanceRecord, false);
          Page.Run(PageId, MaintenanceRecord);
        end;
      Database::"Segment Header":
        begin
          Rows.SetTable(SegmentRecord, false);
          Page.Run(PageId, SegmentRecord);
        end;
      Database::"To-do":
        begin
          Rows.SetTable(TaskRecord, false);
          Page.Run(PageId, TaskRecord);
        end;
      Database::"Service Invoice Header":
        begin
          Rows.SetTable(ServiceInvoiceRecord, false);
          Page.Run(PageId, ServiceInvoiceRecord);
        end;
      Database::"Service Shipment Header":
        begin
          Rows.SetTable(ServiceShipmentRecord, false);
          Page.Run(PageId, ServiceShipmentRecord);
        end;
      Database::"Production Order":
        begin
          Rows.SetTable(ProductionOrderRecord, false);
          Page.Run(PageId, ProductionOrderRecord);
        end;
      Database::"Service Header":
        begin
          Rows.SetTable(ServiceHeaderRecord, false);
          Page.Run(PageId, ServiceHeaderRecord);
        end;
      Database::Campaign:
        begin
          Rows.SetTable(CampaignRecord, false);
          Page.Run(PageId, CampaignRecord);
        end;
      Database::Opportunity:
        begin
          Rows.SetTable(OpportunityRecord, false);
          Page.Run(PageId, OpportunityRecord);
        end;
      else Error(ChangedLbl);
    end;
  end;

  local procedure OpenAttributeMappings(var Rows: RecordRef)
  var
    Mapping: Record "Item Attribute Value Mapping";
    Results: Page "BCSF Attribute Assignments";
  begin
    Rows.SetTable(Mapping, false);
    Results.SetTableView(Mapping);
    Results.Run();
  end;

  local procedure LoadCatalog(GroupKey: Text; var Catalog: JsonArray)
  begin
    Clear(Catalog);
    case GroupKey of
      'master':
        begin
          AddMetric(Catalog, 'customer', Database::"Customer", Page::"Customer List", true, '');
          AddMetric(Catalog, 'vendor', Database::"Vendor", Page::"Vendor List", true, '');
          AddMetric(Catalog, 'contact', Database::"Contact", Page::"Contact List", false, '');
          AddMetric(Catalog, 'shipTo', Database::"Ship-to Address", Page::"Ship-to Address List", true, '');
          AddMetric(Catalog, 'orderAddress', Database::"Order Address", Page::"Order Address List", true, '');
          AddMetric(Catalog, 'customerBank', Database::"Customer Bank Account", Page::"Customer Bank Account List", true, '');
          AddMetric(Catalog, 'vendorBank', Database::"Vendor Bank Account", Page::"Vendor Bank Account List", true, '');
          AddMetric(Catalog, 'glAccount', Database::"G/L Account", Page::"Chart of Accounts", false, '');
          AddMetric(Catalog, 'bank', Database::"Bank Account", Page::"Bank Account List", false, '');
          AddMetric(Catalog, 'item', Database::"Item", Page::"Item List", true, '');
          AddMetric(Catalog, 'location', Database::"Location", Page::"Location List", false, '');
          AddMetric(Catalog, 'category', Database::"Item Category", Page::"Item Categories", true, '');
          AddMetric(Catalog, 'itemUnit', Database::"Item Unit of Measure", Page::"Item Units of Measure", true, '');
          AddMetric(Catalog, 'attribute', Database::"Item Attribute", Page::"Item Attributes", true, '');
          AddMetric(Catalog, 'attributeValue', Database::"Item Attribute Value", Page::"Item Attribute Values", true, '');
          AddMetric(Catalog, 'attributeMapping', Database::"Item Attribute Value Mapping", Page::"BCSF Attribute Assignments", true, '');
          AddMetric(Catalog, 'variant', Database::"Item Variant", Page::"Item Variants", true, '');
          AddMetric(Catalog, 'itemReference', Database::"Item Reference", Page::"Item Reference Entries", true, '');
          AddMetric(Catalog, 'itemVendor', Database::"Item Vendor", Page::"Item Vendor Catalog", true, '');
          AddMetric(Catalog, 'substitution', Database::"Item Substitution", Page::"Item Substitutions", true, '');
          AddMetric(Catalog, 'sku', Database::"Stockkeeping Unit", Page::"Stockkeeping Unit List", true, '');
          AddMetric(Catalog, 'bin', Database::"Bin", Page::"Bin List", true, '');
          AddMetric(Catalog, 'binContent', Database::"Bin Content", Page::"Bin Content", true, '');
        end;
      'sales':
        begin
          AddMetric(Catalog, 'quote', Database::"Sales Header", Page::"Sales Quotes", true, SalesQuoteLbl);
          AddMetric(Catalog, 'blanket', Database::"Sales Header", Page::"Blanket Sales Orders", true, SalesBlanketLbl);
          AddMetric(Catalog, 'order', Database::"Sales Header", Page::"Sales Order List", true, SalesOrderLbl);
          AddMetric(Catalog, 'invoice', Database::"Sales Header", Page::"Sales Invoice List", true, SalesInvoiceLbl);
          AddMetric(Catalog, 'credit', Database::"Sales Header", Page::"Sales Credit Memos", true, SalesCreditLbl);
          AddMetric(Catalog, 'return', Database::"Sales Header", Page::"Sales Return Order List", true, SalesReturnLbl);
          AddMetric(Catalog, 'postedShipment', Database::"Sales Shipment Header", Page::"Posted Sales Shipments", true, SalesShipmentLbl);
          AddMetric(Catalog, 'postedInvoice', Database::"Sales Invoice Header", Page::"Posted Sales Invoices", true, SalesPostedInvoiceLbl);
          AddMetric(Catalog, 'postedCredit', Database::"Sales Cr.Memo Header", Page::"Posted Sales Credit Memos", true, SalesPostedCreditLbl);
          AddMetric(Catalog, 'postedReturn', Database::"Return Receipt Header", Page::"Posted Return Receipts", true, SalesPostedReturnLbl);
        end;
      'purchase':
        begin
          AddMetric(Catalog, 'quote', Database::"Purchase Header", Page::"Purchase Quotes", false, PurchaseQuoteLbl);
          AddMetric(Catalog, 'blanket', Database::"Purchase Header", Page::"Blanket Purchase Orders", false, PurchaseBlanketLbl);
          AddMetric(Catalog, 'order', Database::"Purchase Header", Page::"Purchase Order List", true, PurchaseOrderLbl);
          AddMetric(Catalog, 'invoice', Database::"Purchase Header", Page::"Purchase Invoices", false, PurchaseInvoiceLbl);
          AddMetric(Catalog, 'credit', Database::"Purchase Header", Page::"Purchase Credit Memos", true, PurchaseCreditLbl);
          AddMetric(Catalog, 'return', Database::"Purchase Header", Page::"Purchase Return Order List", true, PurchaseReturnLbl);
          AddMetric(Catalog, 'postedReceipt', Database::"Purch. Rcpt. Header", Page::"Posted Purchase Receipts", true, PurchaseReceiptLbl);
          AddMetric(Catalog, 'postedInvoice', Database::"Purch. Inv. Header", Page::"Posted Purchase Invoices", true, PurchasePostedInvoiceLbl);
          AddMetric(Catalog, 'postedCredit', Database::"Purch. Cr. Memo Hdr.", Page::"Posted Purchase Credit Memos", true, PurchasePostedCreditLbl);
          AddMetric(Catalog, 'postedReturn', Database::"Return Shipment Header", Page::"Posted Return Shipments", true, PurchasePostedReturnLbl);
        end;
      'inventory':
        begin
          AddMetric(Catalog, 'positiveAdjustment', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, PositiveAdjustmentsLbl);
          AddMetric(Catalog, 'negativeAdjustment', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, NegativeAdjustmentsLbl);
          AddMetric(Catalog, 'transferEntry', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, TransferEntriesLbl);
          AddMetric(Catalog, 'transferShipment', Database::"Transfer Shipment Header", Page::"Posted Transfer Shipments", true, TransferShipmentsLbl);
          AddMetric(Catalog, 'transferReceipt', Database::"Transfer Receipt Header", Page::"Posted Transfer Receipts", true, TransferReceiptsLbl);
          AddMetric(Catalog, 'location', Database::"Location", Page::"Location List", false, '');
        end;
      'assembly':
        begin
          AddMetric(Catalog, 'assemblyItem', Database::"Item", Page::"Item List", true, AssemblyItemsLbl);
          AddMetric(Catalog, 'assemblyOrder', Database::"Assembly Header", Page::"Assembly Orders", true, AssemblyOrdersLbl);
          AddMetric(Catalog, 'postedAssembly', Database::"Posted Assembly Header", Page::"Posted Assembly Orders", true, PostedAssemblyLbl);
          AddMetric(Catalog, 'assemblyConsumption', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, AssemblyConsumptionLbl);
          AddMetric(Catalog, 'assemblyOutput', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, AssemblyOutputLbl);
          AddMetric(Catalog, 'resourceEntry', Database::"Res. Ledger Entry", Page::"Resource Ledger Entries", true, '');
        end;
      'entries':
        begin
          AddMetric(Catalog, 'glEntry', Database::"G/L Entry", Page::"General Ledger Entries", true, '');
          AddMetric(Catalog, 'customerEntry', Database::"Cust. Ledger Entry", Page::"Customer Ledger Entries", true, '');
          AddMetric(Catalog, 'vendorEntry', Database::"Vendor Ledger Entry", Page::"Vendor Ledger Entries", true, '');
          AddMetric(Catalog, 'bankEntry', Database::"Bank Account Ledger Entry", Page::"Bank Account Ledger Entries", true, '');
          AddMetric(Catalog, 'customerPayment', Database::"Cust. Ledger Entry", Page::"Customer Ledger Entries", true, CustomerPaymentsLbl);
          AddMetric(Catalog, 'vendorPayment', Database::"Vendor Ledger Entry", Page::"Vendor Ledger Entries", true, VendorPaymentsLbl);
          AddMetric(Catalog, 'customerCredit', Database::"Cust. Ledger Entry", Page::"Customer Ledger Entries", true, CustomerCreditsLbl);
          AddMetric(Catalog, 'vendorCredit', Database::"Vendor Ledger Entry", Page::"Vendor Ledger Entries", true, VendorCreditsLbl);
          AddMetric(Catalog, 'vatEntry', Database::"VAT Entry", Page::"VAT Entries", true, '');
          AddMetric(Catalog, 'itemEntry', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, '');
          AddMetric(Catalog, 'valueEntry', Database::"Value Entry", Page::"Value Entries", true, '');
        end;
      'finance':
        begin
          AddMetric(Catalog, 'paymentTerms', Database::"Payment Terms", Page::"Payment Terms", false, '');
          AddMetric(Catalog, 'postingSetup', Database::"General Posting Setup", Page::"General Posting Setup", false, '');
        end;
      'warehouse':
        begin
          AddMetric(Catalog, 'registeredPutAway', Database::"Registered Whse. Activity Hdr.", Page::"Registered Whse. Put-aways", true, RegisteredPutAwayLbl);
          AddMetric(Catalog, 'warehouseEntry', Database::"Warehouse Entry", Page::"Warehouse Entries", false, '');
        end;
      'manufacturing':
        begin
          AddMetric(Catalog, 'productionBom', Database::"Production BOM Header", Page::"Production BOM List", true, '');
          AddMetric(Catalog, 'productionOrder', Database::"Production Order", Page::"Production Order List", true, ProductionOrdersLbl);
          AddMetric(Catalog, 'productionItem', Database::"Item", Page::"Item List", true, ProductionItemsLbl);
          AddMetric(Catalog, 'productionConsumption', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, ProductionConsumptionLbl);
          AddMetric(Catalog, 'productionOutput', Database::"Item Ledger Entry", Page::"Item Ledger Entries", true, ProductionOutputLbl);
          AddMetric(Catalog, 'assembly', Database::"Assembly Header", Page::"Assembly Orders", false, '');
        end;
      'projects':
        begin
          AddMetric(Catalog, 'job', Database::"Job", Page::"Job List", true, '');
          AddMetric(Catalog, 'jobTask', Database::"Job Task", Page::"Job Task List", true, '');
          AddMetric(Catalog, 'jobPlanningLine', Database::"Job Planning Line", Page::"Job Planning Lines", true, '');
          AddMetric(Catalog, 'jobUsage', Database::"Job Ledger Entry", Page::"Job Ledger Entries", true, ProjectUsageLbl);
          AddMetric(Catalog, 'jobSale', Database::"Job Ledger Entry", Page::"Job Ledger Entries", true, ProjectSalesLbl);
        end;
      'planning':
        AddMetric(Catalog, 'requisitionLine', Database::"Requisition Line", Page::"Requisition Lines", true, PlanningProposalsLbl);
      'service':
        begin
          AddMetric(Catalog, 'serviceItem', Database::"Service Item", Page::"Service Item List", true, '');
          AddMetric(Catalog, 'serviceOrder', Database::"Service Header", Page::"Service Orders", true, ServiceOrdersLbl);
          AddMetric(Catalog, 'serviceInvoice', Database::"Service Invoice Header", Page::"Posted Service Invoices", true, ServiceInvoicesLbl);
          AddMetric(Catalog, 'serviceShipment', Database::"Service Shipment Header", Page::"Posted Service Shipments", true, ServiceShipmentsLbl);
        end;
      'assets':
        begin
          AddMetric(Catalog, 'asset', Database::"Fixed Asset", Page::"Fixed Asset List", true, '');
          AddMetric(Catalog, 'assetEntry', Database::"FA Ledger Entry", Page::"FA Ledger Entries", true, AssetEntriesLbl);
          AddMetric(Catalog, 'maintenanceEntry', Database::"Maintenance Ledger Entry", Page::"Maintenance Ledger Entries", true, MaintenanceEntriesLbl);
        end;
      'contacts':
        begin
          AddMetric(Catalog, 'relation', Database::"Contact Business Relation", 0, false, '');
          AddMetric(Catalog, 'campaign', Database::Campaign, Page::"Campaign List", true, CampaignsLbl);
          AddMetric(Catalog, 'opportunity', Database::Opportunity, Page::"Opportunity List", true, OpportunitiesLbl);
          AddMetric(Catalog, 'segment', Database::"Segment Header", Page::"Segment List", true, SegmentsLbl);
          AddMetric(Catalog, 'task', Database::"To-do", Page::"Task List", true, TasksLbl);
        end;
    end;
  end;

  local procedure AddGroup(var Groups: JsonArray; GroupCode: Text; Caption: Text)
  var
    GroupItem: JsonObject;
  begin
    GroupItem.Add('key', GroupCode);
    GroupItem.Add('caption', Caption);
    Groups.Add(GroupItem);
  end;

  local procedure AddMetric(var Catalog: JsonArray; MetricKey: Text; TableId: Integer; PageId: Integer; HasOrigin: Boolean; Caption: Text)
  var
    Metric: JsonObject;
  begin
    Metric.Add('key', MetricKey);
    Metric.Add('table', TableId);
    Metric.Add('page', PageId);
    Metric.Add('origin', HasOrigin);
    Metric.Add('caption', Caption);
    Catalog.Add(Metric);
  end;

  local procedure TextProperty(Obj: JsonObject; PropertyName: Text): Text
  var
    Item: JsonToken;
  begin
    Obj.Get(PropertyName, Item);
    exit(Item.AsValue().AsText());
  end;

  local procedure IntProperty(Obj: JsonObject; PropertyName: Text): Integer
  var
    Item: JsonToken;
  begin
    Obj.Get(PropertyName, Item);
    exit(Item.AsValue().AsInteger());
  end;

  local procedure BoolProperty(Obj: JsonObject; PropertyName: Text): Boolean
  var
    Item: JsonToken;
  begin
    Obj.Get(PropertyName, Item);
    exit(Item.AsValue().AsBoolean());
  end;

  local procedure FormatRunId(Id: Guid; EntireCompany: Boolean): Text
  begin
    if EntireCompany or IsNullGuid(Id) then
      exit('');
    exit(Format(Id, 0, 4));
  end;

  var
    SalesQuoteLbl: Label 'Sales quotes';
    SalesBlanketLbl: Label 'Blanket sales orders';
    SalesOrderLbl: Label 'Sales orders';
    SalesInvoiceLbl: Label 'Unposted sales invoices';
    SalesCreditLbl: Label 'Sales credit memos';
    SalesReturnLbl: Label 'Sales return orders';
    SalesShipmentLbl: Label 'Posted sales shipments';
    SalesPostedInvoiceLbl: Label 'Posted sales invoices';
    SalesPostedCreditLbl: Label 'Posted sales credit memos';
    SalesPostedReturnLbl: Label 'Posted sales return receipts';
    PurchaseQuoteLbl: Label 'Purchase quotes';
    PurchaseBlanketLbl: Label 'Blanket purchase orders';
    PurchaseOrderLbl: Label 'Purchase orders';
    PurchaseInvoiceLbl: Label 'Unposted purchase invoices';
    PurchaseCreditLbl: Label 'Purchase credit memos';
    PurchaseReturnLbl: Label 'Purchase return orders';
    PurchaseReceiptLbl: Label 'Posted purchase receipts';
    PurchasePostedInvoiceLbl: Label 'Posted purchase invoices';
    PurchasePostedCreditLbl: Label 'Posted purchase credit memos';
    PurchasePostedReturnLbl: Label 'Posted purchase return shipments';
    MasterGroupLbl: Label 'Master data';
    SalesGroupLbl: Label 'Sales';
    CustomerPaymentsLbl: Label 'Customer payments';
    VendorPaymentsLbl: Label 'Vendor payments';
    PlanningGroupLbl: Label 'Planning';
    ProjectUsageLbl: Label 'Project usage entries';
    ProjectSalesLbl: Label 'Project sales entries';
    PlanningProposalsLbl: Label 'Planning proposals';
    RegisteredPutAwayLbl: Label 'Registered put-aways';
    ProductionOrdersLbl: Label 'Production orders';
    ServiceOrdersLbl: Label 'Service orders';
    AssetEntriesLbl: Label 'Fixed asset entries';
    CampaignsLbl: Label 'Campaigns';
    ProductionItemsLbl: Label 'Manufactured items';
    ProductionConsumptionLbl: Label 'Production consumption';
    ProductionOutputLbl: Label 'Production output';
    ServiceInvoicesLbl: Label 'Posted service invoices';
    ServiceShipmentsLbl: Label 'Posted service shipments';
    MaintenanceEntriesLbl: Label 'Maintenance entries';
    SegmentsLbl: Label 'Segments';
    TasksLbl: Label 'Tasks';
    OpportunitiesLbl: Label 'Opportunities';
    InventoryGroupLbl: Label 'Stock movements';
    AssemblyGroupLbl: Label 'Assembly';
    PositiveAdjustmentsLbl: Label 'Positive adjustments';
    NegativeAdjustmentsLbl: Label 'Negative adjustments';
    TransferEntriesLbl: Label 'Transfer entries';
    AssemblyItemsLbl: Label 'Assembly items';
    AssemblyConsumptionLbl: Label 'Assembly consumption';
    AssemblyOutputLbl: Label 'Assembly output';
    AssemblyOrdersLbl: Label 'Open assembly orders';
    PostedAssemblyLbl: Label 'Posted assembly orders';
    TransferShipmentsLbl: Label 'Posted transfer shipments';
    TransferReceiptsLbl: Label 'Posted transfer receipts';
    CustomerCreditsLbl: Label 'Customer credit memo entries';
    VendorCreditsLbl: Label 'Vendor credit memo entries';
    PurchaseGroupLbl: Label 'Purchasing';
    EntriesGroupLbl: Label 'Ledger entries';
    FinanceGroupLbl: Label 'Finance and banking';
    WarehouseGroupLbl: Label 'Warehouse and logistics';
    ManufacturingGroupLbl: Label 'Manufacturing and assembly';
    ProjectsGroupLbl: Label 'Projects';
    ServiceGroupLbl: Label 'Service';
    AssetsGroupLbl: Label 'Fixed assets';
    ContactsGroupLbl: Label 'Relationship management';
    NoGeneratorLbl: Label 'No executable generator';
    NoAccessLbl: Label 'No access';
    NoListLbl: Label 'Standard list unavailable';
    UnverifiedLbl: Label 'This view cannot be matched reliably to the standard list.';
    ChangedLbl: Label 'The visible count changed or the list is unavailable. Refresh the dashboard.';
}
