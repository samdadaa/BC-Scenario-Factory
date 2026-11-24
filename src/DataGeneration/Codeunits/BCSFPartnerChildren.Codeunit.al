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
  /// <summary>New partner captures (marker bankAccountVersion = 1) create one synthetic bank account with the partner.</summary>
  procedure HasBankAccount(Settings: JsonObject): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
  begin
    if Contract.GetInteger(Settings, 'version') <> 2 then
      exit(false);
    if not Settings.Get('bankAccountVersion', Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(PermissionErr, 'bankAccountVersion');
    exit(true);
  end;

  procedure CheckBankPermissions(Customers: Boolean)
  var
    CustomerBank: Record "Customer Bank Account";
    VendorBank: Record "Vendor Bank Account";
  begin
    if Customers then begin
      CustomerBank.SecurityFiltering(SecurityFilter::Disallowed);
      if not CustomerBank.ReadPermission() or not CustomerBank.WritePermission() then
        Error(PermissionErr, CustomerBank.TableCaption());
    end else begin
      VendorBank.SecurityFiltering(SecurityFilter::Disallowed);
      if not VendorBank.ReadPermission() or not VendorBank.WritePermission() then
        Error(PermissionErr, VendorBank.TableCaption());
    end;
  end;

  /// <summary>Synthetic, checksum-valid German IBAN from the seed. The branch number is a fictitious test value; no real bank is referenced.</summary>
  /// <summary>Fictitious bank names (no real institution); chosen by seed so partners share a handful of houses.</summary>
  local procedure BankName(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Text[100]
  var
      Seed: Codeunit "BCSF Seed Engine";
  begin
      exit(CopyStr(SelectStr(Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'BANK-NAME', 1, 6),
        'Nordstadt Handelsbank,Rheinland Volksbank,Süddeutsche Kreditbank,Hanse Genossenschaftsbank,Alpenland Bank,Ostsee Kreditinstitut'), 1, 100));
  end;

  procedure SyntheticBank(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer; var BranchNo: Text[20]; var AccountNo: Text[30]; var Iban: Code[50])
  var
    Seed: Codeunit "BCSF Seed Engine";
    Bban: Text;
    Digits: Text;
    Check: Text;
    Remainder: Integer;
    Index: Integer;
  begin
    BranchNo := '99999999';
    AccountNo := CopyStr(Format(Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'BANK-ACCOUNT-A', 10000, 99999), 0, 9) +
      Format(Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'BANK-ACCOUNT-B', 10000, 99999), 0, 9), 1, 30);
    Bban := BranchNo + AccountNo;
    // ISO 13616: move "DE00" to the end (D=13, E=14) and use 98 - (value mod 97).
    Digits := Bban + '131400';
    for Index := 1 to StrLen(Digits) do
      Remainder := (Remainder * 10 + Digits[Index] - 48) mod 97;
    Check := Format(98 - Remainder, 0, 9);
    if StrLen(Check) = 1 then
      Check := '0' + Check;
    Iban := CopyStr('DE' + Check + Bban, 1, 50);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateCustomerBank(Context: JsonObject; var Partner: Record Customer; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Customer Bank Account";
    Registry: Codeunit "BCSF Record Registry";
    BranchNo: Text[20];
    AccountNo: Text[30];
    Iban: Code[50];
  begin
    CheckBankPermissions(true);
    SyntheticBank(Context, 'CUSTOMER', LogicalKey, BranchNo, AccountNo, Iban);
    Child.Init();
    Child.Validate("Customer No.", Partner."No.");
    Child.Validate(Code, 'GIRO');
    Child.Validate(Name, BankName(Context, 'CUSTOMER', LogicalKey));
    Child.Validate("Bank Branch No.", BranchNo);
    Child.Validate("Bank Account No.", AccountNo);
    Child.Validate(IBAN, Iban);
    Child.Insert(true);
    Registry.RegisterResult(RunId, 'CUSTOMER', LogicalKey, 'BANK', BatchId, Child.RecordId(), ParentId);
    // Same transaction and same call as the partner: no second database pass.
    Partner.Validate("Preferred Bank Account Code", 'GIRO');
    Partner.Modify(true);
  end;

  procedure CheckCustomerBank(Context: JsonObject; Partner: Record Customer; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Customer Bank Account";
    Entry: Record "BCSF Generated Record";
    BranchNo: Text[20];
    AccountNo: Text[30];
    Iban: Code[50];
  begin
    SyntheticBank(Context, 'CUSTOMER', LogicalKey, BranchNo, AccountNo, Iban);
    Entry.Get(RunId, 'CUSTOMER', LogicalKey, 'BANK');
    Entry.TestField("Batch Id", BatchId);
    Entry.TestField("Parent Entry Id", ParentId);
    Entry.TestField("Table Id", Database::"Customer Bank Account");
    Child.SecurityFiltering(SecurityFilter::Disallowed);
    Child.GetBySystemId(Entry."Record SystemId");
    Child.TestField("Customer No.", Partner."No.");
    Child.TestField(Code, 'GIRO');
    Child.TestField("Bank Branch No.", BranchNo);
    Child.TestField("Bank Account No.", AccountNo);
    Child.TestField(IBAN, Iban);
    Partner.TestField("Preferred Bank Account Code", 'GIRO');
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateVendorBank(Context: JsonObject; var Partner: Record Vendor; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Vendor Bank Account";
    Registry: Codeunit "BCSF Record Registry";
    BranchNo: Text[20];
    AccountNo: Text[30];
    Iban: Code[50];
  begin
    CheckBankPermissions(false);
    SyntheticBank(Context, 'VENDOR', LogicalKey, BranchNo, AccountNo, Iban);
    Child.Init();
    Child.Validate("Vendor No.", Partner."No.");
    Child.Validate(Code, 'GIRO');
    Child.Validate(Name, BankName(Context, 'VENDOR', LogicalKey));
    Child.Validate("Bank Branch No.", BranchNo);
    Child.Validate("Bank Account No.", AccountNo);
    Child.Validate(IBAN, Iban);
    Child.Insert(true);
    Registry.RegisterResult(RunId, 'VENDOR', LogicalKey, 'BANK', BatchId, Child.RecordId(), ParentId);
    Partner.Validate("Preferred Bank Account Code", 'GIRO');
    Partner.Modify(true);
  end;

  procedure CheckVendorBank(Context: JsonObject; Partner: Record Vendor; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Child: Record "Vendor Bank Account";
    Entry: Record "BCSF Generated Record";
    BranchNo: Text[20];
    AccountNo: Text[30];
    Iban: Code[50];
  begin
    SyntheticBank(Context, 'VENDOR', LogicalKey, BranchNo, AccountNo, Iban);
    Entry.Get(RunId, 'VENDOR', LogicalKey, 'BANK');
    Entry.TestField("Batch Id", BatchId);
    Entry.TestField("Parent Entry Id", ParentId);
    Entry.TestField("Table Id", Database::"Vendor Bank Account");
    Child.SecurityFiltering(SecurityFilter::Disallowed);
    Child.GetBySystemId(Entry."Record SystemId");
    Child.TestField("Vendor No.", Partner."No.");
    Child.TestField(Code, 'GIRO');
    Child.TestField("Bank Branch No.", BranchNo);
    Child.TestField("Bank Account No.", AccountNo);
    Child.TestField(IBAN, Iban);
    Partner.TestField("Preferred Bank Account Code", 'GIRO');
  end;

  var
    PermissionErr: Label 'Partner generation requires effective read and write permissions for %1 before the batch starts.', Comment = '%1 = child table caption';
}
