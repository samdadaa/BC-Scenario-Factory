namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 90258 "BCSF Partner Children"
{
  Access = Internal;

  procedure CheckPermissions(Customers: Boolean)
  var
    ShipTo: Record "Ship-to Address";
    OrderAddress: Record "Order Address";
  begin
    if Customers then begin
      ShipTo.SecurityFiltering(SecurityFilter::Disallowed);
      if not ShipTo.ReadPermission() or not ShipTo.WritePermission() then
        Error(PermissionErr, ShipTo.TableCaption());
    end else begin
      OrderAddress.SecurityFiltering(SecurityFilter::Disallowed);
      if not OrderAddress.ReadPermission() or not OrderAddress.WritePermission() then
        Error(PermissionErr, OrderAddress.TableCaption());
    end;
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateCustomer(Context: JsonObject; var Partner: Record Customer; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Ship-to Address";
    Catalog: Codeunit "BCSF Partner Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Registry: Codeunit "BCSF Record Registry";
    Address: JsonObject;
  begin
    CheckPermissions(true);
    Address := Catalog.AddressValues(Context, 'CUSTOMER', LogicalKey, 'DELIVERY');
    Child.Init();
    Child.Validate("Customer No.", Partner."No.");
    Child.Validate(Code, 'DELIVERY');
    Child.Validate(Name, Partner.Name);
    Child.Validate(Contact, Partner.Contact);
    Child.Validate("Country/Region Code", CopyStr(Contract.GetText(Address, 'countryCode'), 1, MaxStrLen(Child."Country/Region Code")));
    Child.Validate("Post Code", CopyStr(Contract.GetText(Address, 'postCode'), 1, MaxStrLen(Child."Post Code")));
    Child.Validate(City, CopyStr(Contract.GetText(Address, 'city'), 1, MaxStrLen(Child.City)));
    Child.Validate(Address, CopyStr(Contract.GetText(Address, 'address'), 1, MaxStrLen(Child.Address)));
    Child.Validate("E-Mail", Partner."E-Mail");
    Child.Insert(true);
    Registry.RegisterResult(RunId, 'CUSTOMER', LogicalKey, 'DELIVERY', BatchId, Child.RecordId(), ParentId);
    Partner.Validate("Ship-to Code", 'DELIVERY');
    Partner.Modify(true);
  end;

  procedure CheckCustomer(Context: JsonObject; Partner: Record Customer; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Ship-to Address";
    Entry: Record "BCSF Generated Record";
    Catalog: Codeunit "BCSF Partner Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Address: JsonObject;
  begin
    Address := Catalog.AddressValues(Context, 'CUSTOMER', LogicalKey, 'DELIVERY');
    Entry.Get(RunId, 'CUSTOMER', LogicalKey, 'DELIVERY');
    Entry.TestField("Batch Id", BatchId);
    Entry.TestField("Parent Entry Id", ParentId);
    Entry.TestField("Table Id", Database::"Ship-to Address");
    Child.SecurityFiltering(SecurityFilter::Disallowed);
    Child.GetBySystemId(Entry."Record SystemId");
    Child.TestField("Customer No.", Partner."No.");
    Child.TestField(Code, 'DELIVERY');
    Child.TestField(Name, Partner.Name);
    Child.TestField(Contact, Partner.Contact);
    Child.TestField(Address, Contract.GetText(Address, 'address'));
    Child.TestField(City, Contract.GetText(Address, 'city'));
    Child.TestField("Post Code", Contract.GetText(Address, 'postCode'));
    Child.TestField("Country/Region Code", Contract.GetText(Address, 'countryCode'));
    Child.TestField("E-Mail", Partner."E-Mail");
    Partner.TestField("Ship-to Code", 'DELIVERY');
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateVendor(Context: JsonObject; var Partner: Record Vendor; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Order Address";
    Catalog: Codeunit "BCSF Partner Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Registry: Codeunit "BCSF Record Registry";
    Address: JsonObject;
  begin
    CheckPermissions(false);
    Address := Catalog.AddressValues(Context, 'VENDOR', LogicalKey, 'ORDER');
    Child.Init();
    Child.Validate("Vendor No.", Partner."No.");
    Child.Validate(Code, 'ORDER');
    Child.Validate(Name, Partner.Name);
    Child.Validate(Contact, Partner.Contact);
    Child.Validate("Country/Region Code", CopyStr(Contract.GetText(Address, 'countryCode'), 1, MaxStrLen(Child."Country/Region Code")));
    Child.Validate("Post Code", CopyStr(Contract.GetText(Address, 'postCode'), 1, MaxStrLen(Child."Post Code")));
    Child.Validate(City, CopyStr(Contract.GetText(Address, 'city'), 1, MaxStrLen(Child.City)));
    Child.Validate(Address, CopyStr(Contract.GetText(Address, 'address'), 1, MaxStrLen(Child.Address)));
    Child.Validate("E-Mail", Partner."E-Mail");
    Child.Insert(true);
    Registry.RegisterResult(RunId, 'VENDOR', LogicalKey, 'ORDER', BatchId, Child.RecordId(), ParentId);
  end;

  procedure CheckVendor(Context: JsonObject; Partner: Record Vendor; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Order Address";
    Entry: Record "BCSF Generated Record";
    Catalog: Codeunit "BCSF Partner Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    Address: JsonObject;
  begin
    Address := Catalog.AddressValues(Context, 'VENDOR', LogicalKey, 'ORDER');
    Entry.Get(RunId, 'VENDOR', LogicalKey, 'ORDER');
    Entry.TestField("Batch Id", BatchId);
    Entry.TestField("Parent Entry Id", ParentId);
    Entry.TestField("Table Id", Database::"Order Address");
    Child.SecurityFiltering(SecurityFilter::Disallowed);
    Child.GetBySystemId(Entry."Record SystemId");
    Child.TestField("Vendor No.", Partner."No.");
    Child.TestField(Code, 'ORDER');
    Child.TestField(Name, Partner.Name);
    Child.TestField(Contact, Partner.Contact);
    Child.TestField(Address, Contract.GetText(Address, 'address'));
    Child.TestField(City, Contract.GetText(Address, 'city'));
    Child.TestField("Post Code", Contract.GetText(Address, 'postCode'));
    Child.TestField("Country/Region Code", Contract.GetText(Address, 'countryCode'));
    Child.TestField("E-Mail", Partner."E-Mail");
  end;
  var
    PermissionErr: Label 'Partner generation requires effective read and write permissions for %1 before the batch starts.', Comment = '%1 = child table caption';
}
