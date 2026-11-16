namespace BCScenarioFactory.ScenarioManagement;

enum 90135 "BCSF Entity Type"
{
  Access = Internal;
  Extensible = false;

  value(0; Customer) { Caption = 'Customers'; }
  value(1; Vendor) { Caption = 'Vendors'; }
  value(2; Item) { Caption = 'Items'; }
  value(3; SalesQuote) { Caption = 'Sales Quotes'; }
  value(4; SalesOrder) { Caption = 'Sales Orders'; }
  value(5; SalesInvoice) { Caption = 'Sales Invoices'; }
  value(6; PurchaseOrder) { Caption = 'Purchase Orders'; }
  value(7; PurchaseInvoice) { Caption = 'Purchase Invoices'; }
  value(8; SalesCreditMemo) { Caption = 'Sales Credit Memos'; }
  value(9; PurchaseCreditMemo) { Caption = 'Purchase Credit Memos'; }
}
