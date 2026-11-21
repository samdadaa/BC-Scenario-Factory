namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.DataGeneration;
using Microsoft.Assembly.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Item;
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
    AddGroup(Groups, 'entries', EntriesGroupLbl);
    AddGroup(Groups, 'finance', FinanceGroupLbl);
    AddGroup(Groups, 'warehouse', WarehouseGroupLbl);
    AddGroup(Groups, 'manufacturing', ManufacturingGroupLbl);
    AddGroup(Groups, 'projects', ProjectsGroupLbl);
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
      if TextProperty(Value.AsObject(), 'key') in ['customer', 'vendor', 'shipTo', 'orderAddress', 'item', 'category', 'itemUnit', 'attribute', 'attributeValue', 'attributeMapping', 'variant', 'itemReference', 'itemVendor', 'substitution', 'sku', 'bin', 'binContent'] then
        Metrics.Add(Value);
    AddRunMetrics('sales', RunId, Metrics);
    AddRunMetrics('entries', RunId, Metrics);
    Result.Add('metrics', Metrics);
    exit(Result);
  end;

  local procedure AddRunMetrics(GroupKey: Text; RunId: Guid; var Metrics: JsonArray)
  var
    Stock: JsonObject;
    Values: JsonToken;
    Value: JsonToken;
    Metric: JsonObject;
    MetricKey: Text;
  begin
    Stock := Build(GroupKey, false, RunId);
    Stock.Get('metrics', Values);
    foreach Value in Values.AsArray() do begin
      Metric := Value.AsObject();
      MetricKey := TextProperty(Metric, 'key');
      if (GroupKey = 'entries') or (MetricKey in ['quote', 'order', 'invoice', 'postedShipment', 'postedInvoice']) then
        if Metric.Contains('count') then
          if IntProperty(Metric, 'count') > 0 then begin
            Metric.Replace('key', GroupKey + '/' + MetricKey);
            Metrics.Add(Metric);
          end;
    end;
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
  begin
    if not GetDisplayedCount(LastStock, MetricKey, ExpectedCount) then
      Error(ChangedLbl);
    if GroupKey = 'master' then
      if CopyStr(MetricKey, 1, 6) = 'sales/' then begin
        GroupKey := 'sales';
        MetricKey := CopyStr(MetricKey, 7);
      end else
        if CopyStr(MetricKey, 1, 8) = 'entries/' then begin
          GroupKey := 'entries';
          MetricKey := CopyStr(MetricKey, 9);
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
          OpenAttributeMappings(Rows, StockRunId)
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
    PageId: Integer;
  begin
    Count := -1;
    CanOpen := false;
    PageId := IntProperty(Metric, 'page');
    // The mapping table has no standard list. Reuse the existing provenance page
    // only for generated data, where every displayed identity has one registry row.
    if EntireCompany and (TextProperty(Metric, 'key') = 'attributeMapping') then
      PageId := 0;
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
    if not ApplyBaseFilters(GroupKey, PageId, Rows) then begin
      Status := UnverifiedLbl;
      exit;
    end;
    if not EntireCompany then
      if not ApplyOriginFilter(Rows, Entry, StockRunId) then begin
        Status := LimitLbl;
        exit;
      end;
    Count := Rows.Count();
    if PageId = 0 then
      Status := NoListLbl
    else
      CanOpen := Count > 0;
  end;

  local procedure ApplyOriginFilter(var Rows: RecordRef; var Entry: Record "BCSF Generated Record"; StockRunId: Guid): Boolean
  var
    Id: FieldRef;
    EmptyId: Guid;
    Ids: Text;
    Scanned: Integer;
    Visible: Integer;
  begin
    if IsNullGuid(StockRunId) then
      Entry.SetCurrentKey("Table Id", "Record SystemId")
    else begin
      Entry.SetCurrentKey("Run Id");
      Entry.SetRange("Run Id", StockRunId);
    end;
    Entry.SetRange("Table Id", Rows.Number());
    Entry.SetLoadFields("Record SystemId");
    if Entry.Find('-') then
      repeat
        Scanned += 1;
        if Scanned > 1200 then
          exit(false);
        if not IsNullGuid(Entry."Record SystemId") then
          if Rows.GetBySystemId(Entry."Record SystemId") then begin
            // Provenance has a unique key on table and SystemId. Never classify a reused primary key as generated.
            Visible += 1;
            if Visible > 150 then
              exit(false);
            if Ids <> '' then
              Ids += '|';
            Ids += Format(Entry."Record SystemId", 0, 4);
          end;
      until Entry.Next() = 0;

    Rows.FilterGroup(10);
    Id := Rows.Field(Rows.SystemIdNo());
    if Ids = '' then
      Id.SetRange(EmptyId)
    else
      Id.SetFilter(Ids);
    Rows.FilterGroup(0);
    exit(true);
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
    Job: Record "Job";
    ServiceItem: Record "Service Item";
    FixedAsset: Record "Fixed Asset";
  begin
    if not Rows.FindFirst() then
      Error(ChangedLbl);
    case Rows.Number() of
      Database::"Customer":
        begin
          Rows.SetTable(Customer);
          Page.Run(PageId, Customer);
        end;
      Database::"Vendor":
        begin
          Rows.SetTable(Vendor);
          Page.Run(PageId, Vendor);
        end;
      Database::"Contact":
        begin
          Rows.SetTable(Contact);
          Page.Run(PageId, Contact);
        end;
      Database::"Ship-to Address":
        begin
          Rows.SetTable(ShiptoAddress);
          Page.Run(PageId, ShiptoAddress);
        end;
      Database::"Order Address":
        begin
          Rows.SetTable(OrderAddress);
          Page.Run(PageId, OrderAddress);
        end;
      Database::"Customer Bank Account":
        begin
          Rows.SetTable(CustomerBankAccount);
          Page.Run(PageId, CustomerBankAccount);
        end;
      Database::"Vendor Bank Account":
        begin
          Rows.SetTable(VendorBankAccount);
          Page.Run(PageId, VendorBankAccount);
        end;
      Database::"G/L Account":
        begin
          Rows.SetTable(GLAccount);
          Page.Run(PageId, GLAccount);
        end;
      Database::"Bank Account":
        begin
          Rows.SetTable(BankAccount);
          Page.Run(PageId, BankAccount);
        end;
      Database::"Item":
        begin
          Rows.SetTable(Item);
          Page.Run(PageId, Item);
        end;
      Database::"Item Category":
        begin
          Rows.SetTable(ItemCategory);
          Page.Run(PageId, ItemCategory);
        end;
      Database::"Item Unit of Measure":
        begin
          Rows.SetTable(ItemUnit);
          Page.Run(PageId, ItemUnit);
        end;
      Database::"Item Attribute":
        begin
          Rows.SetTable(ItemAttribute);
          Page.Run(PageId, ItemAttribute);
        end;
      Database::"Item Attribute Value":
        begin
          Rows.SetTable(ItemAttributeValue);
          Page.Run(PageId, ItemAttributeValue);
        end;
      Database::"Item Variant":
        begin
          Rows.SetTable(ItemVariant);
          Page.Run(PageId, ItemVariant);
        end;
      Database::"Item Reference":
        begin
          Rows.SetTable(ItemReference);
          Page.Run(PageId, ItemReference);
        end;
      Database::"Item Vendor":
        begin
          Rows.SetTable(ItemVendor);
          Page.Run(PageId, ItemVendor);
        end;
      Database::"Item Substitution":
        begin
          Rows.SetTable(ItemSubstitution);
          Page.Run(PageId, ItemSubstitution);
        end;
      Database::"Stockkeeping Unit":
        begin
          Rows.SetTable(StockkeepingUnit);
          Page.Run(PageId, StockkeepingUnit);
        end;
      Database::"Bin":
        begin
          Rows.SetTable(Bin);
          Page.Run(PageId, Bin);
        end;
      Database::"Bin Content":
        begin
          Rows.SetTable(BinContent);
          Page.Run(PageId, BinContent);
        end;
      Database::"Location":
        begin
          Rows.SetTable(Location);
          Page.Run(PageId, Location);
        end;
      Database::"Sales Header":
        begin
          Rows.SetTable(SalesHeader);
          Page.Run(PageId, SalesHeader);
        end;
      Database::"Sales Shipment Header":
        begin
          Rows.SetTable(SalesShipmentHeader);
          Page.Run(PageId, SalesShipmentHeader);
        end;
      Database::"Sales Invoice Header":
        begin
          Rows.SetTable(SalesInvoiceHeader);
          Page.Run(PageId, SalesInvoiceHeader);
        end;
      Database::"Sales Cr.Memo Header":
        begin
          Rows.SetTable(SalesCrMemoHeader);
          Page.Run(PageId, SalesCrMemoHeader);
        end;
      Database::"Return Receipt Header":
        begin
          Rows.SetTable(ReturnReceiptHeader);
          Page.Run(PageId, ReturnReceiptHeader);
        end;
      Database::"Purchase Header":
        begin
          Rows.SetTable(PurchaseHeader);
          Page.Run(PageId, PurchaseHeader);
        end;
      Database::"Purch. Rcpt. Header":
        begin
          Rows.SetTable(PurchRcptHeader);
          Page.Run(PageId, PurchRcptHeader);
        end;
      Database::"Purch. Inv. Header":
        begin
          Rows.SetTable(PurchInvHeader);
          Page.Run(PageId, PurchInvHeader);
        end;
      Database::"Purch. Cr. Memo Hdr.":
        begin
          Rows.SetTable(PurchCrMemoHdr);
          Page.Run(PageId, PurchCrMemoHdr);
        end;
      Database::"Return Shipment Header":
        begin
          Rows.SetTable(ReturnShipmentHeader);
          Page.Run(PageId, ReturnShipmentHeader);
        end;
      Database::"G/L Entry":
        begin
          Rows.SetTable(GLEntry);
          Page.Run(PageId, GLEntry);
        end;
      Database::"Cust. Ledger Entry":
        begin
          Rows.SetTable(CustLedgerEntry);
          Page.Run(PageId, CustLedgerEntry);
        end;
      Database::"Vendor Ledger Entry":
        begin
          Rows.SetTable(VendorLedgerEntry);
          Page.Run(PageId, VendorLedgerEntry);
        end;
      Database::"Bank Account Ledger Entry":
        begin
          Rows.SetTable(BankAccountLedgerEntry);
          Page.Run(PageId, BankAccountLedgerEntry);
        end;
      Database::"VAT Entry":
        begin
          Rows.SetTable(VATEntry);
          Page.Run(PageId, VATEntry);
        end;
      Database::"Item Ledger Entry":
        begin
          Rows.SetTable(ItemLedgerEntry);
          Page.Run(PageId, ItemLedgerEntry);
        end;
      Database::"Value Entry":
        begin
          Rows.SetTable(ValueEntry);
          Page.Run(PageId, ValueEntry);
        end;
      Database::"Payment Terms":
        begin
          Rows.SetTable(PaymentTerms);
          Page.Run(PageId, PaymentTerms);
        end;
      Database::"General Posting Setup":
        begin
          Rows.SetTable(GeneralPostingSetup);
          Page.Run(PageId, GeneralPostingSetup);
        end;
      Database::"Warehouse Entry":
        begin
          Rows.SetTable(WarehouseEntry);
          Page.Run(PageId, WarehouseEntry);
        end;
      Database::"Production BOM Header":
        begin
          Rows.SetTable(ProductionBOMHeader);
          Page.Run(PageId, ProductionBOMHeader);
        end;
      Database::"Assembly Header":
        begin
          Rows.SetTable(AssemblyHeader);
          Page.Run(PageId, AssemblyHeader);
        end;
      Database::"Job":
        begin
          Rows.SetTable(Job);
          Page.Run(PageId, Job);
        end;
      Database::"Service Item":
        begin
          Rows.SetTable(ServiceItem);
          Page.Run(PageId, ServiceItem);
        end;
      Database::"Fixed Asset":
        begin
          Rows.SetTable(FixedAsset);
          Page.Run(PageId, FixedAsset);
        end;
      else Error(ChangedLbl);
    end;
  end;

  local procedure OpenAttributeMappings(var Rows: RecordRef; StockRunId: Guid)
  var
    Entry: Record "BCSF Generated Record";
    Results: Page "BCSF Generated Records";
    Identity: FieldRef;
  begin
    Entry.SecurityFiltering(SecurityFilter::Filtered);
    Entry.SetRange("Table Id", Database::"Item Attribute Value Mapping");
    if not IsNullGuid(StockRunId) then
      Entry.SetRange("Run Id", StockRunId);
    Rows.FilterGroup(10);
    Identity := Rows.Field(Rows.SystemIdNo());
    Entry.FilterGroup(10);
    Entry.SetFilter("Record SystemId", Identity.GetFilter());
    Entry.FilterGroup(0);
    Rows.FilterGroup(0);
    // ResultIdentity is unique. Never substitute a broader provenance list.
    if Entry.Count() <> Rows.Count() then
      Error(ChangedLbl);
    Results.SetTableView(Entry);
    Results.ShowAttributeMappings();
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
          AddMetric(Catalog, 'customerBank', Database::"Customer Bank Account", Page::"Customer Bank Account List", false, '');
          AddMetric(Catalog, 'vendorBank', Database::"Vendor Bank Account", Page::"Vendor Bank Account List", false, '');
          AddMetric(Catalog, 'glAccount', Database::"G/L Account", Page::"Chart of Accounts", false, '');
          AddMetric(Catalog, 'bank', Database::"Bank Account", Page::"Bank Account List", false, '');
          AddMetric(Catalog, 'item', Database::"Item", Page::"Item List", true, '');
          AddMetric(Catalog, 'location', Database::"Location", Page::"Location List", false, '');
          AddMetric(Catalog, 'category', Database::"Item Category", Page::"Item Categories", true, '');
          AddMetric(Catalog, 'itemUnit', Database::"Item Unit of Measure", Page::"Item Units of Measure", true, '');
          AddMetric(Catalog, 'attribute', Database::"Item Attribute", Page::"Item Attributes", true, '');
          AddMetric(Catalog, 'attributeValue', Database::"Item Attribute Value", Page::"Item Attribute Values", true, '');
          AddMetric(Catalog, 'attributeMapping', Database::"Item Attribute Value Mapping", Page::"BCSF Generated Records", true, '');
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
          AddMetric(Catalog, 'quote', Database::"Sales Header", Page::"Sales Quotes", true, Doc0Lbl);
          AddMetric(Catalog, 'blanket', Database::"Sales Header", Page::"Blanket Sales Orders", false, Doc1Lbl);
          AddMetric(Catalog, 'order', Database::"Sales Header", Page::"Sales Order List", true, Doc2Lbl);
          AddMetric(Catalog, 'invoice', Database::"Sales Header", Page::"Sales Invoice List", true, Doc3Lbl);
          AddMetric(Catalog, 'credit', Database::"Sales Header", Page::"Sales Credit Memos", false, Doc4Lbl);
          AddMetric(Catalog, 'return', Database::"Sales Header", Page::"Sales Return Order List", false, Doc5Lbl);
          AddMetric(Catalog, 'postedShipment', Database::"Sales Shipment Header", Page::"Posted Sales Shipments", true, PostedShipmentLbl);
          AddMetric(Catalog, 'postedInvoice', Database::"Sales Invoice Header", Page::"Posted Sales Invoices", true, PostedInvoiceLbl);
          AddMetric(Catalog, 'postedCredit', Database::"Sales Cr.Memo Header", Page::"Posted Sales Credit Memos", false, PostedCreditLbl);
          AddMetric(Catalog, 'postedReturn', Database::"Return Receipt Header", Page::"Posted Return Receipts", false, PostedReturnLbl);
        end;
      'purchase':
        begin
          AddMetric(Catalog, 'quote', Database::"Purchase Header", Page::"Purchase Quotes", false, Doc0Lbl);
          AddMetric(Catalog, 'blanket', Database::"Purchase Header", Page::"Blanket Purchase Orders", false, Doc1Lbl);
          AddMetric(Catalog, 'order', Database::"Purchase Header", Page::"Purchase Order List", true, Doc2Lbl);
          AddMetric(Catalog, 'invoice', Database::"Purchase Header", Page::"Purchase Invoices", false, Doc3Lbl);
          AddMetric(Catalog, 'credit', Database::"Purchase Header", Page::"Purchase Credit Memos", false, Doc4Lbl);
          AddMetric(Catalog, 'return', Database::"Purchase Header", Page::"Purchase Return Order List", false, Doc5Lbl);
          AddMetric(Catalog, 'postedReceipt', Database::"Purch. Rcpt. Header", Page::"Posted Purchase Receipts", false, PostedReceiptLbl);
          AddMetric(Catalog, 'postedInvoice', Database::"Purch. Inv. Header", Page::"Posted Purchase Invoices", false, PostedInvoiceLbl);
          AddMetric(Catalog, 'postedCredit', Database::"Purch. Cr. Memo Hdr.", Page::"Posted Purchase Credit Memos", false, PostedCreditLbl);
          AddMetric(Catalog, 'postedReturn', Database::"Return Shipment Header", Page::"Posted Return Shipments", false, PostedReturnLbl);
        end;
      'entries':
        begin
          AddMetric(Catalog, 'glEntry', Database::"G/L Entry", Page::"General Ledger Entries", true, '');
          AddMetric(Catalog, 'customerEntry', Database::"Cust. Ledger Entry", Page::"Customer Ledger Entries", true, '');
          AddMetric(Catalog, 'vendorEntry', Database::"Vendor Ledger Entry", Page::"Vendor Ledger Entries", false, '');
          AddMetric(Catalog, 'bankEntry', Database::"Bank Account Ledger Entry", Page::"Bank Account Ledger Entries", false, '');
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
        AddMetric(Catalog, 'warehouseEntry', Database::"Warehouse Entry", Page::"Warehouse Entries", false, '');
      'manufacturing':
        begin
          AddMetric(Catalog, 'productionBom', Database::"Production BOM Header", Page::"Production BOM List", false, '');
          AddMetric(Catalog, 'assembly', Database::"Assembly Header", Page::"Assembly Orders", false, '');
        end;
      'projects':
        AddMetric(Catalog, 'job', Database::"Job", Page::"Job List", false, '');
      'service':
        AddMetric(Catalog, 'serviceItem', Database::"Service Item", Page::"Service Item List", false, '');
      'assets':
        AddMetric(Catalog, 'asset', Database::"Fixed Asset", Page::"Fixed Asset List", false, '');
      'contacts':
        AddMetric(Catalog, 'relation', Database::"Contact Business Relation", 0, false, '');
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
    MasterGroupLbl: Label 'Master data';
    SalesGroupLbl: Label 'Sales';
    PurchaseGroupLbl: Label 'Purchasing';
    EntriesGroupLbl: Label 'Ledger entries';
    FinanceGroupLbl: Label 'Finance and banking';
    WarehouseGroupLbl: Label 'Warehouse and logistics';
    ManufacturingGroupLbl: Label 'Manufacturing and assembly';
    ProjectsGroupLbl: Label 'Projects';
    ServiceGroupLbl: Label 'Service';
    AssetsGroupLbl: Label 'Fixed assets';
    ContactsGroupLbl: Label 'Relationship management';
    Doc0Lbl: Label 'Quotes';
    Doc1Lbl: Label 'Blanket orders';
    Doc2Lbl: Label 'Orders';
    Doc3Lbl: Label 'Invoices';
    Doc4Lbl: Label 'Credit memos';
    Doc5Lbl: Label 'Return orders';
    PostedShipmentLbl: Label 'Posted shipments';
    PostedReceiptLbl: Label 'Posted receipts';
    PostedInvoiceLbl: Label 'Posted invoices';
    PostedCreditLbl: Label 'Posted credit memos';
    PostedReturnLbl: Label 'Posted returns';
    NoGeneratorLbl: Label 'No executable generator';
    NoAccessLbl: Label 'No access';
    NoListLbl: Label 'Standard list unavailable';
    LimitLbl: Label 'Narrow to a single run or use provenance for larger sets.';
    UnverifiedLbl: Label 'This view cannot be matched reliably to the standard list.';
    ChangedLbl: Label 'The visible count changed or the list is unavailable. Refresh the dashboard.';
}
