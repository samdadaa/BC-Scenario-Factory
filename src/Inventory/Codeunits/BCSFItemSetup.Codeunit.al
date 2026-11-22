namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Structure;

codeunit 90478 "BCSF Item Setup"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCaptureInventorySetup', '', false, false)]
  local procedure Capture(Scenario: Record "BCSF Scenario"; PartnerSettings: JsonObject; var Settings: JsonObject)
  var
    Target: Record "BCSF Data Target";
    Inventory: Record "Inventory Setup";
    PostingGroup: Record "Inventory Posting Group";
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Supplier: Record Vendor;
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
    CodeValue: Code[20];
  begin
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetRange(Entity, Target.Entity::Item);
    Target.SetFilter(Quantity, '>0');
    if Target.IsEmpty() or not Catalog.SupportsProfile(Scenario."Profile Code", Scenario."Profile Version") then
      exit;
    Inventory.SecurityFiltering(SecurityFilter::Disallowed);
    Inventory.Get();
    Settings.Add('version', 1);
    Settings.Add('series', Inventory."Item Nos.");
    Settings.Add('baseUnit', DefaultCode(Scenario."Item Base Unit", 'STK'));
    Settings.Add('packUnit', DefaultCode(Scenario."Item Pack Unit", 'KRT'));
    Settings.Add('location', ResolveLocation(Scenario."Item Location Code", Catalog.UsesBins(Scenario."Profile Code")));
    Settings.Add('bins', Catalog.UsesBins(Scenario."Profile Code"));
    Settings.Add('vendor', Scenario."Item Vendor No.");
    Settings.Add('secondVendor', Scenario."Item Second Vendor No.");
    Settings.Add('generatedVendors', Scenario."Item Vendor No." = '');
    Settings.Add('genBus', Contract.GetText(PartnerSettings, 'genBusPostingGroup'));
    Settings.Add('vatBus', Contract.GetText(PartnerSettings, 'vatBusPostingGroup'));
    CodeValue := Scenario."Item Inventory Group";
    if CodeValue = '' then begin
      PostingGroup.SecurityFiltering(SecurityFilter::Disallowed);
      if PostingGroup.Count() <> 1 then
        Error(AmbiguousErr, PostingGroup.TableCaption());
      PostingGroup.FindFirst();
      CodeValue := PostingGroup.Code;
    end;
    Settings.Add('inventoryGroup', CodeValue);
    General.SecurityFiltering(SecurityFilter::Disallowed);
    General.SetRange("Gen. Bus. Posting Group", Contract.GetCode(Settings, 'genBus'));
    CodeValue := Scenario."Item Product Group";
    if CodeValue = '' then begin
      if General.Count() <> 1 then
        Error(AmbiguousErr, General.TableCaption());
      General.FindFirst();
      CodeValue := General."Gen. Prod. Posting Group";
    end;
    Settings.Add('genProduct', CodeValue);
    VAT.SecurityFiltering(SecurityFilter::Disallowed);
    VAT.SetRange("VAT Bus. Posting Group", Contract.GetCode(Settings, 'vatBus'));
    CodeValue := Scenario."Item VAT Product Group";
    if CodeValue = '' then begin
      if VAT.Count() <> 1 then
        Error(AmbiguousErr, VAT.TableCaption());
      VAT.FindFirst();
      CodeValue := VAT."VAT Prod. Posting Group";
    end;
    Settings.Add('vatProduct', CodeValue);
    if Scenario."Item Vendor No." <> '' then begin
      Supplier.SecurityFiltering(SecurityFilter::Disallowed);
      Supplier.Get(Scenario."Item Vendor No.");
      Settings.Add('vendorSystemId', Format(Supplier.SystemId, 0, 4));
      Supplier.Get(Scenario."Item Second Vendor No.");
      Settings.Add('secondVendorSystemId', Format(Supplier.SystemId, 0, 4));
    end;
    Settings.Add('postingFingerprint', PostingFingerprint(Settings));
  end;

  local procedure ResolveLocation(SelectedCode: Code[10]; WithBins: Boolean): Code[10]
  var
    Location: Record Location;
    Preferred: Code[10];
  begin
    if SelectedCode <> '' then
      exit(SelectedCode);
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Preferred := 'MAIN';
    if WithBins then
      Preferred := 'RACK';
    if Location.Get(Preferred) then
      exit(Preferred);
    Location.SetRange("Use As In-Transit", false);
    Location.SetRange("Bin Mandatory", WithBins);
    Location.SetRange("Directed Put-away and Pick", false);
    Location.SetRange("Require Pick", false);
    Location.SetRange("Require Put-away", false);
    Location.SetRange("Require Receive", false);
    Location.SetRange("Require Shipment", false);
    if Location.Count() <> 1 then
      Error(AmbiguousErr, Location.TableCaption());
    Location.FindFirst();
    exit(Location.Code);
  end;

  local procedure DefaultCode(Value: Code[20]; Fallback: Code[20]): Code[20]
  begin
    if Value = '' then
      exit(Fallback);
    exit(Value);
  end;

  procedure ReadSettings(Context: JsonObject): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
  begin
    Contract.CheckContext(Context);
    if not Context.Get('itemSetup', Token) then
      Error(ProfileErr);
    Settings := Token.AsObject();
    if Contract.GetInteger(Settings, 'version') <> 1 then
      Error(ProfileErr);
    exit(Settings);
  end;

  procedure Quantity(Context: JsonObject; Entity: Enum "BCSF Entity Type"): Integer
  var
    Source: Codeunit "BCSF Master Data Source";
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Value: JsonToken;
  begin
    if Context.Contains('masterDataSource') then
      exit(Source.Quantity(Context, Entity));
    Context.Get('targets', Token);
    foreach Value in Token.AsArray() do
      if Contract.GetInteger(Value.AsObject(), 'entity') = Entity.AsInteger() then
        exit(Contract.GetInteger(Value.AsObject(), 'quantity'));
    exit(0);
  end;

  procedure CheckSetup(Context: JsonObject; Target: JsonObject)
  var
    Inventory: Record "Inventory Setup";
    Location: Record Location;
    Measure: Record "Unit of Measure";
    Series: Record "No. Series";
    Supplier: Record Vendor;
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
    Numbers: Codeunit "No. Series";
    Settings: JsonObject;
    BaseDate: Date;
  begin
    Contract.CheckTarget(Context, Target);
    if (Contract.GetText(Target, 'entityCode') <> 'ITEM') or (Contract.GetText(Target, 'moduleCode') <> 'INVENTORY') or
      (Contract.GetInteger(Target, 'processMode') <> 0) or not Catalog.SupportsProfile(Contract.GetText(Context, 'profileCode'), Contract.GetText(Context, 'profileVersion')) then
      Error(ProfileErr);
    Catalog.BuildValues(Context, 1);
    Settings := ReadSettings(Context);
    if not Evaluate(BaseDate, Contract.GetText(Context, 'startingDate'), 9) then
      Error(ProfileErr);
    Inventory.SecurityFiltering(SecurityFilter::Disallowed);
    Inventory.Get();
    Inventory.TestField("Item Nos.", Contract.GetCode(Settings, 'series'));
    Series.SecurityFiltering(SecurityFilter::Disallowed);
    Series.Get(Inventory."Item Nos.");
    Series.TestField("Default Nos.", true);
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Location.Get(Contract.GetCode(Settings, 'location'));
    Location.TestField("Bin Mandatory", Catalog.UsesBins(Contract.GetText(Context, 'profileCode')));
    Location.TestField("Use As In-Transit", false);
    Location.TestField("Directed Put-away and Pick", false);
    Location.TestField("Require Pick", false);
    Location.TestField("Require Put-away", false);
    Location.TestField("Require Receive", false);
    Location.TestField("Require Shipment", false);
    if Numbers.PeekNextNo(Series.Code, BaseDate) = '' then
      Error(ProfileErr);
    Measure.SecurityFiltering(SecurityFilter::Disallowed);
    Measure.Get(Contract.GetCode(Settings, 'baseUnit'));
    Measure.Get(Contract.GetCode(Settings, 'packUnit'));
    if Contract.GetText(Settings, 'baseUnit') = Contract.GetText(Settings, 'packUnit') then
      Error(UnitErr);
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Location.Get(Contract.GetCode(Settings, 'location'));
    Location.TestField("Use As In-Transit", false);
    Location.TestField("Bin Mandatory", Contract.GetBoolean(Settings, 'bins'));
    Location.TestField("Directed Put-away and Pick", false);
    Location.TestField("Require Receive", false);
    Location.TestField("Require Shipment", false);
    Location.TestField("Require Put-away", false);
    Location.TestField("Require Pick", false);
    if PostingFingerprint(Settings) <> Contract.GetText(Settings, 'postingFingerprint') then
      Error(DriftErr);
    if Contract.GetBoolean(Settings, 'generatedVendors') then begin
      if Quantity(Context, "BCSF Entity Type"::Vendor) < 2 then
        Error(VendorErr);
    end else begin
      Supplier.SecurityFiltering(SecurityFilter::Disallowed);
      Supplier.Get(Contract.GetCode(Settings, 'vendor'));
      Supplier.TestField(Blocked, Supplier.Blocked::" ");
      Supplier.Get(Contract.GetCode(Settings, 'secondVendor'));
      Supplier.TestField(Blocked, Supplier.Blocked::" ");
      if Contract.GetText(Settings, 'vendor') = Contract.GetText(Settings, 'secondVendor') then
        Error(VendorErr);
    end;
    CheckPermissions(Database::Item);
    CheckPermissions(Database::"Item Unit of Measure");
    CheckPermissions(Database::"Item Category");
    CheckPermissions(Database::"Item Attribute");
    CheckPermissions(Database::"Item Attribute Value");
    CheckPermissions(Database::"Item Attribute Value Mapping");
    CheckPermissions(Database::"Item Variant");
    CheckPermissions(Database::"Item Reference");
    CheckPermissions(Database::"Item Vendor");
    CheckPermissions(Database::"Item Substitution");
    CheckPermissions(Database::"Stockkeeping Unit");
    if Contract.GetBoolean(Settings, 'bins') then begin
      CheckPermissions(Database::Bin);
      CheckPermissions(Database::"Bin Content");
    end;
  end;

  local procedure PostingFingerprint(Settings: JsonObject): Text
  var
    Inventory: Record "Inventory Posting Setup";
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Group: Record "Inventory Posting Group";
    Product: Record "Gen. Product Posting Group";
    VATProduct: Record "VAT Product Posting Group";
    Contract: Codeunit "BCSF Contract JSON";
    Result: Text;
  begin
    Inventory.SecurityFiltering(SecurityFilter::Disallowed);
    General.SecurityFiltering(SecurityFilter::Disallowed);
    VAT.SecurityFiltering(SecurityFilter::Disallowed);
    Group.SecurityFiltering(SecurityFilter::Disallowed);
    Product.SecurityFiltering(SecurityFilter::Disallowed);
    VATProduct.SecurityFiltering(SecurityFilter::Disallowed);
    Group.Get(Contract.GetCode(Settings, 'inventoryGroup'));
    Product.Get(Contract.GetCode(Settings, 'genProduct'));
    VATProduct.Get(Contract.GetCode(Settings, 'vatProduct'));
    if not Inventory.Get(Contract.GetCode(Settings, 'location'), Group.Code) then
      Error(MatrixErr, Contract.GetCode(Settings, 'location'), Group.Code);
    General.Get(Contract.GetCode(Settings, 'genBus'), Product.Code);
    VAT.Get(Contract.GetCode(Settings, 'vatBus'), VATProduct.Code);
    Result := CheckAccount(Inventory."Inventory Account") + '|' + CheckAccount(General."Sales Account") + '|' +
      CheckAccount(General."Purch. Account") + '|' + CheckAccount(General."COGS Account") + '|';
    VAT.TestField("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
    Result += CheckAccount(VAT."Purchase VAT Account") + '|' + CheckAccount(VAT."Sales VAT Account") + '|' + Format(VAT."VAT %", 0, 9);
    if not Contract.GetBoolean(Settings, 'generatedVendors') then begin
      Result += '|' + ExistingVendorFingerprint(Settings, false);
      Result += '|' + ExistingVendorFingerprint(Settings, true);
    end;
    exit(Result);
  end;

  local procedure ExistingVendorFingerprint(Settings: JsonObject; Second: Boolean): Text
  var
    Supplier: Record Vendor;
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Contract: Codeunit "BCSF Contract JSON";
    ExpectedId: Guid;
  begin
    Supplier.SecurityFiltering(SecurityFilter::Disallowed);
    if Second then begin
      Supplier.Get(Contract.GetCode(Settings, 'secondVendor'));
      Evaluate(ExpectedId, Contract.GetText(Settings, 'secondVendorSystemId'));
    end else begin
      Supplier.Get(Contract.GetCode(Settings, 'vendor'));
      Evaluate(ExpectedId, Contract.GetText(Settings, 'vendorSystemId'));
    end;
    Supplier.TestField(SystemId, ExpectedId);
    Supplier.TestField(Blocked, Supplier.Blocked::" ");
    General.SecurityFiltering(SecurityFilter::Disallowed);
    VAT.SecurityFiltering(SecurityFilter::Disallowed);
    General.Get(Supplier."Gen. Bus. Posting Group", Contract.GetCode(Settings, 'genProduct'));
    VAT.Get(Supplier."VAT Bus. Posting Group", Contract.GetCode(Settings, 'vatProduct'));
    VAT.TestField("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
    exit(Format(Supplier.SystemId, 0, 4) + '|' + Supplier."Gen. Bus. Posting Group" + '|' + Supplier."VAT Bus. Posting Group" + '|' +
      CheckAccount(General."Purch. Account") + '|' + CheckAccount(General."COGS Account") + '|' +
      CheckAccount(VAT."Purchase VAT Account") + '|' + Format(VAT."VAT %", 0, 9));
  end;

  local procedure CheckAccount(AccountNo: Code[20]): Text
  var
    Account: Record "G/L Account";
  begin
    Account.SecurityFiltering(SecurityFilter::Disallowed);
    Account.Get(AccountNo);
    Account.TestField(Blocked, false);
    Account.TestField("Account Type", Account."Account Type"::Posting);
    exit(AccountNo);
  end;

  local procedure CheckPermissions(TableId: Integer)
  var
    Rows: RecordRef;
  begin
    Rows.Open(TableId);
    Rows.SecurityFiltering(SecurityFilter::Disallowed);
    if not Rows.ReadPermission() or not Rows.WritePermission() then
      Error(PermissionErr, Rows.Caption());
    Rows.Close();
  end;

  procedure PrimaryVendor(Context: JsonObject; LogicalKey: Integer): Code[20]
  var
    Contract: Codeunit "BCSF Contract JSON";
    VendorCount: Integer;
  begin
    if (Contract.GetText(Context, 'profileCode') <> 'TRADE') or
      not (Contract.GetText(Context, 'profileVersion') in ['5', '6']) then
      exit(ResolveVendor(Context, 1));
    if not Contract.GetBoolean(ReadSettings(Context), 'generatedVendors') then
      exit(ResolveVendor(Context, 1));
    VendorCount := Quantity(Context, "BCSF Entity Type"::Vendor);
    if VendorCount < 2 then
      Error(VendorErr);
    // Stable modulo assignment; all suppliers participate in medium scenarios.
    exit(ResolveVendor(Context, 1 + ((LogicalKey - 1) mod VendorCount)));
  end;

  procedure ResolveVendor(Context: JsonObject; Index: Integer): Code[20]
  var
    Entry: Record "BCSF Generated Record";
    Supplier: Record Vendor;
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    RunId: Guid;
  begin
    Settings := ReadSettings(Context);
    Supplier.SecurityFiltering(SecurityFilter::Disallowed);
    if Contract.GetBoolean(Settings, 'generatedVendors') then begin
      Evaluate(RunId, Contract.GetText(Context, 'runId'));
      Entry.Get(RunId, 'VENDOR', Index, 'VENDOR');
      Entry.TestField("Table Id", Database::Vendor);
      Supplier.GetBySystemId(Entry."Record SystemId");
    end else
      if Index = 1 then
        Supplier.Get(Contract.GetCode(Settings, 'vendor'))
      else
        Supplier.Get(Contract.GetCode(Settings, 'secondVendor'));
    Supplier.TestField(Blocked, Supplier.Blocked::" ");
    if not Contract.GetBoolean(Settings, 'generatedVendors') then
      ExistingVendorFingerprint(Settings, Index = 2);
    exit(Supplier."No.");
  end;

  var
    ProfileErr: Label 'Capture a new technical wholesale master-data run with item setup version 1.';
    AmbiguousErr: Label 'Select an explicit existing value for %1 under Item Assortment. The company setup does not have one unambiguous choice.', Comment = '%1 = setup table';
    MatrixErr: Label 'Inventory posting setup is missing for location %1 and inventory posting group %2. Complete this exact combination through company setup using the existing accounts.', Comment = '%1 = location, %2 = inventory posting group';
    DriftErr: Label 'The captured item posting setup has changed. Review the exact posting combinations and capture a new run.';
    VendorErr: Label 'Select two different existing suppliers or include at least two generated vendors as a predecessor in this scenario.';
    UnitErr: Label 'Choose different existing base and carton units for the item assortment.';
    PermissionErr: Label 'Item generation requires effective standard read and write permissions for %1.', Comment = '%1 = standard table';
}
