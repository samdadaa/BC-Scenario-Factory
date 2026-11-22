namespace BCScenarioFactory.Monitoring;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.IO;
using System.Reflection;

codeunit 90371 "BCSF Config Export"
{
  Access = Internal;

  trigger OnRun()
  begin
    OpenPackage();
  end;

  procedure OpenPackage()
  var
    Package: Record "Config. Package";
  begin
    EnsurePackage();
    Package.Get(GetPackageCode());
    Page.Run(Page::"Config. Package Card", Package);
  end;

  /// <summary>Explicitly creates export metadata in the current company only. Never called by install or upgrade.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure EnsurePackage()
  var
    Package: Record "Config. Package";
    TableIds: List of [Integer];
    TableId: Integer;
  begin
    if not IsExportSandbox() then
      Error(SandboxErr);
    Package.LockTable();
    if Package.Get(GetPackageCode()) then begin
      if Package."Product Version" <> GetCatalogMarker() then
        Error(PackageCollisionErr, GetPackageCode());
    end else begin
      Package.Init();
      Package.Code := GetPackageCode();
      Package."Package Name" := PackageNameLbl;
      Package."Product Version" := GetCatalogMarker();
      Package."Exclude Config. Tables" := true;
      Package.Insert(true);
    end;
    GetTableIds(TableIds);
    foreach TableId in TableIds do
      AddTable(TableId);
  end;

  procedure IsExportSandbox(): Boolean
  var
    EnvironmentInformation: Codeunit "Environment Information";
  begin
    exit(EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsSandbox() and not EnvironmentInformation.IsProduction());
  end;

  procedure GetPackageCode(): Code[20]
  begin
    exit('BCSF-ALL-DATA');
  end;

  local procedure GetCatalogMarker(): Text[248]
  begin
    exit('BCSF-EXPORT/1');
  end;

  local procedure AddTable(TableId: Integer)
  var
    PackageTable: Record "Config. Package Table";
    PackageField: Record "Config. Package Field";
    TableField: Record Field;
    PackageManagement: Codeunit "Config. Package Management";
    ProcessingOrder: Integer;
  begin
    if PackageTable.Get(GetPackageCode(), TableId) then
      exit;
    // Standard API validates the table, creates fields and includes all eligible normal fields.
    PackageManagement.InsertPackageTable(PackageTable, GetPackageCode(), TableId);
    PackageTable.Comments := ExportOnlyLbl;
    PackageTable.Modify(true);
    // RapidStart omits Dimension Value ID. Preserve its link to dimension-set entries for inspection.
    PackageManagement.SetFieldFilter(TableField, TableId, 0);
    PackageField.SetRange("Package Code", GetPackageCode());
    PackageField.SetRange("Table ID", TableId);
    PackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
    if PackageField.FindLast() then
      ProcessingOrder := PackageField."Processing Order";
    if TableField.FindSet() then
      repeat
        if not PackageField.Get(GetPackageCode(), TableId, TableField."No.") then begin
          PackageManagement.InsertPackageField(PackageField, GetPackageCode(), TableId, TableField."No.",
            TableField.FieldName, TableField."Field Caption", true, false, false, false);
          ProcessingOrder += 1;
          PackageField."Processing Order" := ProcessingOrder;
          PackageField.Modify(true);
        end;
      until TableField.Next() = 0;
  end;

  /// <summary>Current generator/foundation tables plus standard posting, dimension, CRM and archive side effects.</summary>
  procedure GetTableIds(var TableIds: List of [Integer])
  begin
    Clear(TableIds);
    TableIds.Add(Database::"Payment Terms");
    TableIds.Add(Database::"Currency");
    TableIds.Add(Database::"Country/Region");
    TableIds.Add(Database::"Shipment Method");
    TableIds.Add(Database::"Location");
    TableIds.Add(Database::"G/L Account");
    TableIds.Add(Database::"G/L Entry");
    TableIds.Add(Database::"Customer");
    TableIds.Add(Database::"Cust. Ledger Entry");
    TableIds.Add(Database::"Vendor");
    TableIds.Add(Database::"Vendor Ledger Entry");
    TableIds.Add(Database::"Item");
    TableIds.Add(Database::"Item Ledger Entry");
    TableIds.Add(Database::"Sales Header");
    TableIds.Add(Database::"Sales Line");
    TableIds.Add(Database::"Purchase Header");
    TableIds.Add(Database::"Purchase Line");
    TableIds.Add(Database::"Purch. Comment Line");
    TableIds.Add(Database::"Sales Comment Line");
    TableIds.Add(Database::"G/L Register");
    TableIds.Add(Database::"Item Register");
    TableIds.Add(Database::"Gen. Journal Template");
    TableIds.Add(Database::"Gen. Journal Line");
    TableIds.Add(Database::"Item Journal Template");
    TableIds.Add(Database::"Item Journal Line");
    TableIds.Add(Database::"Acc. Schedule Name");
    TableIds.Add(Database::"Acc. Schedule Line");
    TableIds.Add(Database::"Financial Report");
    TableIds.Add(Database::"Customer Posting Group");
    TableIds.Add(Database::"Vendor Posting Group");
    TableIds.Add(Database::"Inventory Posting Group");
    TableIds.Add(Database::"Comment Line");
    TableIds.Add(Database::"General Ledger Setup");
    TableIds.Add(Database::"Item Vendor");
    TableIds.Add(Database::"Sales Shipment Header");
    TableIds.Add(Database::"Sales Shipment Line");
    TableIds.Add(Database::"Sales Invoice Header");
    TableIds.Add(Database::"Sales Invoice Line");
    TableIds.Add(Database::"Sales Cr.Memo Header");
    TableIds.Add(Database::"Sales Cr.Memo Line");
    TableIds.Add(Database::"Purch. Rcpt. Header");
    TableIds.Add(Database::"Purch. Rcpt. Line");
    TableIds.Add(Database::"Purch. Inv. Header");
    TableIds.Add(Database::"Purch. Inv. Line");
    TableIds.Add(Database::"Purch. Cr. Memo Hdr.");
    TableIds.Add(Database::"Purch. Cr. Memo Line");
    TableIds.Add(Database::"Unit of Measure");
    TableIds.Add(Database::"Ship-to Address");
    TableIds.Add(Database::"Order Address");
    TableIds.Add(Database::"Post Code");
    TableIds.Add(Database::"Source Code");
    TableIds.Add(Database::"Gen. Journal Batch");
    TableIds.Add(Database::"Item Journal Batch");
    TableIds.Add(Database::"Source Code Setup");
    TableIds.Add(Database::"Gen. Business Posting Group");
    TableIds.Add(Database::"Gen. Product Posting Group");
    TableIds.Add(Database::"General Posting Setup");
    TableIds.Add(Database::"G/L Entry - VAT Entry Link");
    TableIds.Add(Database::"VAT Entry");
    TableIds.Add(Database::"Bank Account");
    TableIds.Add(Database::"Bank Account Ledger Entry");
    TableIds.Add(Database::"Bank Account Posting Group");
    TableIds.Add(Database::"Payment Method");
    TableIds.Add(Database::"Shipping Agent");
    TableIds.Add(Database::"No. Series");
    TableIds.Add(Database::"No. Series Line");
    TableIds.Add(Database::"No. Series Relationship");
    TableIds.Add(Database::"Sales & Receivables Setup");
    TableIds.Add(Database::"Purchases & Payables Setup");
    TableIds.Add(Database::"Inventory Setup");
    TableIds.Add(Database::"VAT Business Posting Group");
    TableIds.Add(Database::"VAT Product Posting Group");
    TableIds.Add(Database::"VAT Posting Setup");
    TableIds.Add(Database::"Currency Exchange Rate");
    TableIds.Add(Database::"Column Layout Name");
    TableIds.Add(Database::"Column Layout");
    TableIds.Add(Database::"Tracking Specification");
    TableIds.Add(Database::"Reservation Entry");
    TableIds.Add(Database::"Item Application Entry");
    TableIds.Add(Database::"Item Application Entry History");
    TableIds.Add(Database::"Dimension");
    TableIds.Add(Database::"Dimension Value");
    TableIds.Add(Database::"Default Dimension");
    TableIds.Add(Database::"Detailed Cust. Ledg. Entry");
    TableIds.Add(Database::"Detailed Vendor Ledg. Entry");
    TableIds.Add(Database::"Dimension Set Entry");
    TableIds.Add(Database::"Dimension Set Tree Node");
    TableIds.Add(Database::"G/L Account Source Currency");
    TableIds.Add(Database::"Contact");
    TableIds.Add(Database::"Business Relation");
    TableIds.Add(Database::"Contact Business Relation");
    TableIds.Add(Database::"Marketing Setup");
    TableIds.Add(Database::"Contact Duplicate");
    TableIds.Add(Database::"Cont. Duplicate Search String");
    TableIds.Add(Database::"Duplicate Search String Setup");
    TableIds.Add(Database::"Sales Header Archive");
    TableIds.Add(Database::"Sales Line Archive");
    TableIds.Add(Database::"Purchase Header Archive");
    TableIds.Add(Database::"Purchase Line Archive");
    TableIds.Add(Database::"Unit Group");
    TableIds.Add(Database::"Item Variant");
    TableIds.Add(Database::"Item Unit of Measure");
    TableIds.Add(Database::"Stockkeeping Unit");
    TableIds.Add(Database::"Item Substitution");
    TableIds.Add(Database::"Item Category");
    TableIds.Add(Database::"Warehouse Setup");
    TableIds.Add(Database::"Item Reference");
    TableIds.Add(Database::"Shipping Agent Services");
    TableIds.Add(Database::"Value Entry");
    TableIds.Add(Database::"Post Value Entry to G/L");
    TableIds.Add(Database::"Inventory Posting Setup");
    TableIds.Add(Database::"G/L - Item Ledger Relation");
    TableIds.Add(Database::"Inventory Adjmt. Entry (Order)");
    TableIds.Add(Database::"Item Entry Relation");
    TableIds.Add(Database::"Value Entry Relation");
    TableIds.Add(Database::"Whse. Item Entry Relation");
    TableIds.Add(Database::"Return Shipment Header");
    TableIds.Add(Database::"Return Shipment Line");
    TableIds.Add(Database::"Return Receipt Header");
    TableIds.Add(Database::"Return Receipt Line");
    TableIds.Add(Database::"Bin Content");
    TableIds.Add(Database::"Warehouse Journal Line");
    TableIds.Add(Database::"Warehouse Entry");
    TableIds.Add(Database::"Warehouse Register");
    TableIds.Add(Database::"Bin");
    TableIds.Add(Database::"Item Attribute");
    TableIds.Add(Database::"Item Attribute Value");
    TableIds.Add(Database::"Item Attribute Value Mapping");
  end;

  var
    PackageNameLbl: Label 'Scenario Factory - all business data';
    ExportOnlyLbl: Label 'Full company table for inspection/export, including existing data. Posted entries cannot be reimported through RapidStart.';
    SandboxErr: Label 'Create the Scenario Factory export package in a Business Central online sandbox.';
    PackageCollisionErr: Label 'Configuration package %1 already exists without the Factory export marker. Rename that package before creating the Factory export package.', Comment = '%1 = package code';
}
