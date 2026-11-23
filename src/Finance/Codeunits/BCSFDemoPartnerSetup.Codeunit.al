namespace BCScenarioFactory.Finance;

using BCScenarioFactory.SetupManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.CRM.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Bank.BankAccount;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;

codeunit 90408 "BCSF Demo Partner Setup"
{
  Access = Internal;

  /// <summary>Foundation of the explicitly reviewed finance package. Never creates substitute G/L accounts.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure Prepare(EffectiveDate: Date; Write: Boolean; AllowCreate: Boolean; Initializing: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  begin
    Prepare(EffectiveDate, Write, AllowCreate, Initializing, TempDiff, false);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure Prepare(EffectiveDate: Date; Write: Boolean; AllowCreate: Boolean; Initializing: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary; ReuseExistingTerms: Boolean)
  var
    Sales: Record "Sales & Receivables Setup";
    Purchases: Record "Purchases & Payables Setup";
    Inventory: Record "Inventory Setup";
    Location: Record Location;
    Marketing: Record "Marketing Setup";
    Country: Record "Country/Region";
    Journal: Record "Gen. Journal Template";
    JournalBatch: Record "Gen. Journal Batch";
    Measure: Record "Unit of Measure";
    Payment: Record "Payment Method";
    SourceSetup: Record "Source Code Setup";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Manager: Codeunit "BCSF Setup Manager";
    Fields: List of [Integer];
  begin
    PrepareLedger(EffectiveDate, Write, AllowCreate, TempDiff);
    Country.Init();
    Country.Code := 'DE';
    Country.Name := GermanyLbl;
    if Packages.NeedsInsert(Country, Fields, Write, AllowCreate, TempDiff) then
      Country.Insert(true);
    if Initializing then begin
      Country.Init();
      Country.Code := 'GB';
      Country.Name := 'Vereinigtes Königreich';
      if Packages.NeedsInsert(Country, Fields, Write, AllowCreate, TempDiff) then
        Country.Insert(true);
    end;
    Marketing.Init();
    if Packages.NeedsInsert(Marketing, Fields, Write, AllowCreate, TempDiff) then
      Marketing.Insert(true);
    Sales.Init();
    Sales."Customer Nos." := 'CUSTOMER';
    Sales."Invoice Nos." := 'SALES-INV';
    Sales."Posted Invoice Nos." := 'SALES-POST';
    Sales."Posted Shipment Nos." := 'SHIPMENT';
    Fields.Add(Sales.FieldNo("Customer Nos."));
    Fields.Add(Sales.FieldNo("Invoice Nos."));
    Fields.Add(Sales.FieldNo("Posted Invoice Nos."));
    Fields.Add(Sales.FieldNo("Posted Shipment Nos."));
    if Initializing then begin
      Sales."Quote Nos." := 'SALES-QUO';
      Sales."Order Nos." := 'SALES-ORD';
      Sales."Blanket Order Nos." := 'SALES-BLK';
      Sales."Credit Memo Nos." := 'SALES-CM';
      Sales."Posted Credit Memo Nos." := 'SALES-PCM';
      Sales."Return Order Nos." := 'SALES-RET';
      Sales."Posted Return Receipt Nos." := 'SALES-PRR';
      Fields.Add(Sales.FieldNo("Quote Nos."));
      Fields.Add(Sales.FieldNo("Order Nos."));
      Fields.Add(Sales.FieldNo("Blanket Order Nos."));
      Fields.Add(Sales.FieldNo("Credit Memo Nos."));
      Fields.Add(Sales.FieldNo("Posted Credit Memo Nos."));
      Fields.Add(Sales.FieldNo("Return Order Nos."));
      Fields.Add(Sales.FieldNo("Posted Return Receipt Nos."));
    end;
    SetupRow(Sales, Fields, true, EffectiveDate, Write, AllowCreate, TempDiff);
    Sales.SecurityFiltering(SecurityFilter::Disallowed);
    if Sales.Get() then
      if Sales."Invoice Rounding" then
        Block(Sales.TableCaption() + ' / ' + Sales.FieldCaption("Invoice Rounding"), Write, TempDiff);
    Clear(Fields);
    Purchases.Init();
    Purchases."Vendor Nos." := 'VENDOR';
    Purchases."Invoice Nos." := 'PURCH-INV';
    Purchases."Posted Invoice Nos." := 'PURCH-POST';
    Purchases."Posted Receipt Nos." := 'RECEIPT';
    Fields.Add(Purchases.FieldNo("Vendor Nos."));
    Fields.Add(Purchases.FieldNo("Invoice Nos."));
    Fields.Add(Purchases.FieldNo("Posted Invoice Nos."));
    Fields.Add(Purchases.FieldNo("Posted Receipt Nos."));
    if Initializing then begin
      Purchases."Quote Nos." := 'PURCH-QUO';
      Purchases."Order Nos." := 'PURCH-ORD';
      Purchases."Blanket Order Nos." := 'PURCH-BLK';
      Purchases."Credit Memo Nos." := 'PURCH-CM';
      Purchases."Posted Credit Memo Nos." := 'PURCH-PCM';
      Purchases."Return Order Nos." := 'PURCH-RET';
      Purchases."Posted Return Shpt. Nos." := 'PURCH-PRS';
      Fields.Add(Purchases.FieldNo("Quote Nos."));
      Fields.Add(Purchases.FieldNo("Order Nos."));
      Fields.Add(Purchases.FieldNo("Blanket Order Nos."));
      Fields.Add(Purchases.FieldNo("Credit Memo Nos."));
      Fields.Add(Purchases.FieldNo("Posted Credit Memo Nos."));
      Fields.Add(Purchases.FieldNo("Return Order Nos."));
      Fields.Add(Purchases.FieldNo("Posted Return Shpt. Nos."));
    end;
    SetupRow(Purchases, Fields, true, EffectiveDate, Write, AllowCreate, TempDiff);
    Purchases.SecurityFiltering(SecurityFilter::Disallowed);
    if Purchases.Get() then
      if Purchases."Invoice Rounding" then
        Block(Purchases.TableCaption() + ' / ' + Purchases.FieldCaption("Invoice Rounding"), Write, TempDiff);
    Clear(Fields);
    Inventory.Init();
    Inventory."Item Nos." := 'ITEM';
    Fields.Add(Inventory.FieldNo("Item Nos."));
    SetupRow(Inventory, Fields, true, EffectiveDate, Write, AllowCreate, TempDiff);
    Inventory.SecurityFiltering(SecurityFilter::Disallowed);
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Location.SetRange("Use As In-Transit", false);
    if Location.IsEmpty() then
      if Initializing then begin
        Location.Reset();
        Location.Init();
        Location.Code := 'MAIN';
        Location.Name := 'Hauptlager';
        Clear(Fields);
        Fields.Add(Location.FieldNo("Use As In-Transit"));
        if Packages.NeedsInsert(Location, Fields, Write, AllowCreate, TempDiff) then
          Location.Insert(true);
      end else
        if Inventory.Get() then
          if Inventory."Location Mandatory" then
            Block(Location.TableCaption(), Write, TempDiff);
    if Initializing then begin
      Clear(Fields);
      Measure.Init();
      Measure.Code := 'STK';
      Measure.Description := 'Stück';
      if Packages.NeedsInsert(Measure, Fields, Write, AllowCreate, TempDiff) then
        Measure.Insert(true);
      Clear(Measure);
      Measure.Init();
      Measure.Code := 'STD';
      Measure.Description := 'Stunde';
      if Packages.NeedsInsert(Measure, Fields, Write, AllowCreate, TempDiff) then
        Measure.Insert(true);
      Clear(Measure);
      Measure.Init();
      Measure.Code := 'KRT';
      Measure.Description := 'Karton';
      if Packages.NeedsInsert(Measure, Fields, Write, AllowCreate, TempDiff) then
        Measure.Insert(true);
      Location.Reset();
      if not Location.Get('RACK') then begin
        Location.Init();
        Location.Code := 'RACK';
        Location.Name := 'Regallager';
        Location."Bin Mandatory" := true;
        Clear(Fields);
        Fields.Add(Location.FieldNo("Bin Mandatory"));
        if Packages.NeedsInsert(Location, Fields, Write, AllowCreate, TempDiff) then
          Location.Insert(true);
      end;
      Clear(Fields);
      Payment.Init();
      Payment.Code := 'UBW';
      Payment.Description := 'Überweisung';
      if Packages.NeedsInsert(Payment, Fields, Write, AllowCreate, TempDiff) then
        Payment.Insert(true);
    end;
    Terms('NET00', '<0D>', Write, AllowCreate, TempDiff, ReuseExistingTerms);
    Terms('NET14', '<14D>', Write, AllowCreate, TempDiff, ReuseExistingTerms);
    Terms('NET30', '<30D>', Write, AllowCreate, TempDiff, ReuseExistingTerms);
    Terms('NET60', '<60D>', Write, AllowCreate, TempDiff, ReuseExistingTerms);
    Clear(Fields);
    SourceSetup.Init();
    SourceSetup.Sales := 'SALES';
    SourceSetup.Purchases := 'PURCHASES';
    SourceSetup."General Journal" := 'GENERAL';
    Clear(Fields);
    Fields.Add(SourceSetup.FieldNo(Sales));
    Fields.Add(SourceSetup.FieldNo(Purchases));
    Fields.Add(SourceSetup.FieldNo("General Journal"));
    SetupRow(SourceSetup, Fields, false, EffectiveDate, Write, AllowCreate, TempDiff);
    Clear(Fields);
    Journal.SetRange(Type, Journal.Type::General);
    if Journal.IsEmpty() then begin
      Journal.Reset();
      Journal.Init();
      Journal.Name := 'GENERAL';
      Journal.Description := JournalLbl;
      Journal.Type := Journal.Type::General;
      if SourceSetup.Get() then
        Journal."Source Code" := SourceSetup."General Journal";
      if not Write then
        if Journal."Source Code" = '' then
          Journal."Source Code" := 'GENERAL';
      Fields.Add(Journal.FieldNo(Type));
      if Packages.NeedsInsert(Journal, Fields, Write, AllowCreate, TempDiff) then
        Journal.Insert(true);
    end else begin
      Journal.FindFirst();
      Manager.AddFinding(TempDiff, Journal.TableCaption(), false, ReuseLbl, ReuseLbl);
    end;
    if Initializing then begin
      JournalBatch.SecurityFiltering(SecurityFilter::Disallowed);
      JournalBatch.SetRange("Journal Template Name", Journal.Name);
      if JournalBatch.IsEmpty() then begin
        JournalBatch.Init();
        JournalBatch."Journal Template Name" := Journal.Name;
        JournalBatch.Name := 'STANDARD';
        JournalBatch.Description := JournalLbl;
        Clear(Fields);
        if Packages.NeedsInsert(JournalBatch, Fields, Write, AllowCreate, TempDiff) then
          JournalBatch.Insert(true);
      end;
    end;
  end;

  // Existing financial roles are reused; no account is inferred from a name
  // or created as a substitute. Only absent technical setup is supplemented.
  procedure PrepareExisting(EffectiveDate: Date; Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Location: Record Location;
    InventoryPosting: Record "Inventory Posting Setup";
    SourcePosting: Record "Inventory Posting Setup";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Guard: Codeunit "BCSF Environment Guard";
    Fields: List of [Integer];
    LocationCode: Code[10];
  begin
    if Write then
      Guard.EnsureCanConfigure(CompanyName());
    Prepare(EffectiveDate, Write, true, true, TempDiff, true);
    EnsureReferencedGroups(Write, TempDiff);
    LocationCode := SimpleLocation();
    if LocationCode = '' then begin
      LocationCode := 'MAIN';
      if Location.Get(LocationCode) then
        LocationCode := 'BCSF-MAIN';
      Location.Init();
      Location.Code := LocationCode;
      Location.Name := SimpleLocationLbl;
      Fields.Add(Location.FieldNo("Bin Mandatory"));
      Fields.Add(Location.FieldNo("Use As In-Transit"));
      Fields.Add(Location.FieldNo("Require Receive"));
      Fields.Add(Location.FieldNo("Require Shipment"));
      Fields.Add(Location.FieldNo("Require Pick"));
      Fields.Add(Location.FieldNo("Require Put-away"));
      Fields.Add(Location.FieldNo("Directed Put-away and Pick"));
      if Packages.NeedsInsert(Location, Fields, Write, true, TempDiff) then
        Location.Insert(true);
    end;
    InventoryPosting.SecurityFiltering(SecurityFilter::Disallowed);
    InventoryPosting.SetRange("Location Code", LocationCode);
    if InventoryPosting.FindSet() then
      repeat
        if UsableAccount(InventoryPosting."Inventory Account", false) then
          exit;
      until InventoryPosting.Next() = 0;
    // Extend a known inventory-account role to the dedicated/simple location.
    // Existing location/group mappings are never changed.
    SourcePosting.SecurityFiltering(SecurityFilter::Disallowed);
    if SourcePosting.FindSet() then
      repeat
        if UsableAccount(SourcePosting."Inventory Account", false) then
          if not InventoryPosting.Get(LocationCode, SourcePosting."Invt. Posting Group Code") then begin
            InventoryPosting := SourcePosting;
            InventoryPosting."Location Code" := LocationCode;
            Clear(Fields);
            Fields.Add(InventoryPosting.FieldNo("Inventory Account"));
            Fields.Add(InventoryPosting.FieldNo("Inventory Account (Interim)"));
            if Packages.NeedsInsert(InventoryPosting, Fields, Write, true, TempDiff) then
              InventoryPosting.Insert(true);
            exit;
          end;
      until SourcePosting.Next() = 0;
    Block(InventoryPosting.TableCaption(), Write, TempDiff);
  end;

  local procedure EnsureReferencedGroups(Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    Inventory: Record "Inventory Posting Setup";
    Business: Record "Gen. Business Posting Group";
    Product: Record "Gen. Product Posting Group";
    VATBusiness: Record "VAT Business Posting Group";
    VATProduct: Record "VAT Product Posting Group";
    InventoryGroup: Record "Inventory Posting Group";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Fields: List of [Integer];
  begin
    General.SecurityFiltering(SecurityFilter::Disallowed);
    VAT.SecurityFiltering(SecurityFilter::Disallowed);
    Inventory.SecurityFiltering(SecurityFilter::Disallowed);
    General.SetRange(Blocked, false);
    if General.FindSet() then
      repeat
        if UsableAccount(General."Sales Account", false) and UsableAccount(General."Purch. Account", false) then begin
          if General."Gen. Bus. Posting Group" <> '' then begin
            Business.Init();
            Business.Code := General."Gen. Bus. Posting Group";
            Business.Description := Business.Code;
            if Packages.NeedsInsert(Business, Fields, Write, true, TempDiff) then
              Business.Insert(true);
          end;
          if General."Gen. Prod. Posting Group" <> '' then begin
            Product.Init();
            Product.Code := General."Gen. Prod. Posting Group";
            Product.Description := Product.Code;
            if Packages.NeedsInsert(Product, Fields, Write, true, TempDiff) then
              Product.Insert(true);
          end;
        end;
      until General.Next() = 0;
    VAT.SetRange(Blocked, false);
    VAT.SetRange("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
    if VAT.FindSet() then
      repeat
        if (VAT."VAT %" = 0) or (UsableAccount(VAT."Sales VAT Account", false) and UsableAccount(VAT."Purchase VAT Account", false)) then begin
          if VAT."VAT Bus. Posting Group" <> '' then begin
            VATBusiness.Init();
            VATBusiness.Code := VAT."VAT Bus. Posting Group";
            VATBusiness.Description := VATBusiness.Code;
            if Packages.NeedsInsert(VATBusiness, Fields, Write, true, TempDiff) then
              VATBusiness.Insert(true);
          end;
          if VAT."VAT Prod. Posting Group" <> '' then begin
            VATProduct.Init();
            VATProduct.Code := VAT."VAT Prod. Posting Group";
            VATProduct.Description := VATProduct.Code;
            if Packages.NeedsInsert(VATProduct, Fields, Write, true, TempDiff) then
              VATProduct.Insert(true);
          end;
        end;
      until VAT.Next() = 0;
    if Inventory.FindSet() then
      repeat
        if (Inventory."Invt. Posting Group Code" <> '') and UsableAccount(Inventory."Inventory Account", false) then begin
          InventoryGroup.Init();
          InventoryGroup.Code := Inventory."Invt. Posting Group Code";
          InventoryGroup.Description := InventoryGroup.Code;
          if Packages.NeedsInsert(InventoryGroup, Fields, Write, true, TempDiff) then
            InventoryGroup.Insert(true);
        end;
      until Inventory.Next() = 0;
  end;

  procedure BindExistingScenario(var Scenario: Record "BCSF Scenario")
  var
    General: Record "General Posting Setup";
    VAT: Record "VAT Posting Setup";
    InventoryPosting: Record "Inventory Posting Setup";
    CustomerGroup: Record "Customer Posting Group";
    VendorGroup: Record "Vendor Posting Group";
    Business: Record "Gen. Business Posting Group";
    Product: Record "Gen. Product Posting Group";
    Found: Boolean;
  begin
    General.SecurityFiltering(SecurityFilter::Disallowed);
    VAT.SecurityFiltering(SecurityFilter::Disallowed);
    InventoryPosting.SecurityFiltering(SecurityFilter::Disallowed);
    CustomerGroup.SecurityFiltering(SecurityFilter::Disallowed);
    VendorGroup.SecurityFiltering(SecurityFilter::Disallowed);
    Business.SecurityFiltering(SecurityFilter::Disallowed);
    Product.SecurityFiltering(SecurityFilter::Disallowed);
    // This method changes only the new template record supplied by its caller.
    // It never modifies a standard master or an existing financial mapping.
    if Scenario."Item Location Code" = '' then
      Scenario."Item Location Code" := SimpleLocation();
    if Scenario."Item Location Code" = '' then
      Error(ExistingBindingErr, 'Location');
    InventoryPosting.SetRange("Location Code", Scenario."Item Location Code");
    if Scenario."Item Inventory Group" <> '' then
      InventoryPosting.SetRange("Invt. Posting Group Code", Scenario."Item Inventory Group");
    Found := false;
    if InventoryPosting.FindSet() then
      repeat
        if UsableAccount(InventoryPosting."Inventory Account", false) then begin
          Scenario."Item Inventory Group" := InventoryPosting."Invt. Posting Group Code";
          Found := true;
          break;
        end;
      until InventoryPosting.Next() = 0;
    if not Found then
      Error(ExistingBindingErr, InventoryPosting.TableCaption());
    General.SetRange(Blocked, false);
    if Scenario."Gen. Bus. Posting Group" <> '' then
      General.SetRange("Gen. Bus. Posting Group", Scenario."Gen. Bus. Posting Group");
    if Scenario."Item Product Group" <> '' then
      General.SetRange("Gen. Prod. Posting Group", Scenario."Item Product Group");
    Found := false;
    if General.FindSet() then
      repeat
        if Business.Get(General."Gen. Bus. Posting Group") and Product.Get(General."Gen. Prod. Posting Group") and
          UsableAccount(General."Sales Account", false) and UsableAccount(General."Purch. Account", false) and
          UsableAccount(General."COGS Account", false) and UsableAccount(General."Inventory Adjmt. Account", false) and
          UsableAccount(General."Direct Cost Applied Account", false) then begin
          VAT.Reset();
          VAT.SetRange(Blocked, false);
          VAT.SetRange("VAT Calculation Type", VAT."VAT Calculation Type"::"Normal VAT");
          if Scenario."VAT Bus. Posting Group" <> '' then
            VAT.SetRange("VAT Bus. Posting Group", Scenario."VAT Bus. Posting Group")
          else
            if Business."Def. VAT Bus. Posting Group" <> '' then
              VAT.SetRange("VAT Bus. Posting Group", Business."Def. VAT Bus. Posting Group");
          if Scenario."Item VAT Product Group" <> '' then
            VAT.SetRange("VAT Prod. Posting Group", Scenario."Item VAT Product Group")
          else
            if Product."Def. VAT Prod. Posting Group" <> '' then
              VAT.SetRange("VAT Prod. Posting Group", Product."Def. VAT Prod. Posting Group");
          if VAT.FindSet() then
            repeat
              if (VAT."VAT %" = 0) or (UsableAccount(VAT."Sales VAT Account", false) and UsableAccount(VAT."Purchase VAT Account", false)) then begin
                Scenario."Gen. Bus. Posting Group" := General."Gen. Bus. Posting Group";
                Scenario."Item Product Group" := General."Gen. Prod. Posting Group";
                Scenario."VAT Bus. Posting Group" := VAT."VAT Bus. Posting Group";
                Scenario."Item VAT Product Group" := VAT."VAT Prod. Posting Group";
                Found := true;
                break;
              end;
            until VAT.Next() = 0;
        end;
        if Found then
          break;
      until General.Next() = 0;
    if not Found then
      Error(ExistingBindingErr, General.TableCaption() + ' / ' + VAT.TableCaption());
    if Scenario."Customer Posting Group" <> '' then
      CustomerGroup.SetRange(Code, Scenario."Customer Posting Group");
    Found := false;
    if CustomerGroup.FindSet() then
      repeat
        if UsableAccount(CustomerGroup."Receivables Account", true) then begin
          Scenario."Customer Posting Group" := CustomerGroup.Code;
          Found := true;
          break;
        end;
      until CustomerGroup.Next() = 0;
    if not Found then
      Error(ExistingBindingErr, CustomerGroup.TableCaption());
    if Scenario."Vendor Posting Group" <> '' then
      VendorGroup.SetRange(Code, Scenario."Vendor Posting Group");
    Found := false;
    if VendorGroup.FindSet() then
      repeat
        if UsableAccount(VendorGroup."Payables Account", true) then begin
          Scenario."Vendor Posting Group" := VendorGroup.Code;
          Found := true;
          break;
        end;
      until VendorGroup.Next() = 0;
    if not Found then
      Error(ExistingBindingErr, VendorGroup.TableCaption());
  end;

  local procedure SimpleLocation(): Code[10]
  var
    Location: Record Location;
  begin
    Location.SecurityFiltering(SecurityFilter::Disallowed);
    Location.SetRange("Use As In-Transit", false);
    Location.SetRange("Bin Mandatory", false);
    Location.SetRange("Require Receive", false);
    Location.SetRange("Require Shipment", false);
    Location.SetRange("Require Pick", false);
    Location.SetRange("Require Put-away", false);
    Location.SetRange("Directed Put-away and Pick", false);
    if Location.FindFirst() then
      exit(Location.Code);
    exit('');
  end;

  local procedure UsableAccount(No: Code[20]; ControlAccount: Boolean): Boolean
  var
    Account: Record "G/L Account";
  begin
    Account.SecurityFiltering(SecurityFilter::Disallowed);
    if not Account.Get(No) then
      exit(false);
    exit(not Account.Blocked and (Account."Account Type" = Account."Account Type"::Posting) and
      (not ControlAccount or not Account."Direct Posting"));
  end;

  local procedure PrepareLedger(EffectiveDate: Date; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    GL: Record "General Ledger Setup";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Manager: Codeunit "BCSF Setup Manager";
    Missing: Boolean;
  begin
    GL.SecurityFiltering(SecurityFilter::Disallowed);
    if not GL.ReadPermission() then begin
      Block(GL.TableCaption(), Write, TempDiff);
      exit;
    end;
    if Write then
      GL.LockTable();
    Missing := not GL.Get();
    if not Missing then
      if ((GL."LCY Code" <> '') and (GL."LCY Code" <> 'EUR')) or
         (GL."Amount Rounding Precision" < 0) or (GL."Unit-Amount Rounding Precision" < 0) or
         ((GL."Allow Posting From" <> 0D) and (EffectiveDate < GL."Allow Posting From")) or
         ((GL."Allow Posting To" <> 0D) and (EffectiveDate > GL."Allow Posting To")) then begin
        Block(GL.TableCaption(), Write, TempDiff);
        exit;
      end;
    if not (Missing or (GL."LCY Code" = '') or (GL."Amount Rounding Precision" = 0) or
       (GL."Unit-Amount Rounding Precision" = 0)) then
      exit;
    if not AllowCreate or not Packages.HasSetupWritePermission(Database::"General Ledger Setup", Missing) then begin
      Block(GL.TableCaption(), Write, TempDiff);
      exit;
    end;
    if not Write then begin
      Manager.AddFinding(TempDiff, GL.TableCaption(), false, FillLbl, ConfirmLbl);
      exit;
    end;
    if Missing then
      GL.Init();
    if GL."LCY Code" = '' then
      GL.Validate("LCY Code", 'EUR');
    // These are the standard field defaults. Assignment avoids the rounding fields' informational dialogs.
    if GL."Amount Rounding Precision" = 0 then
      GL."Amount Rounding Precision" := 0.01;
    if GL."Unit-Amount Rounding Precision" = 0 then
      GL."Unit-Amount Rounding Precision" := 0.00001;
    if Missing then
      GL.Insert(true)
    else
      GL.Modify(true);
  end;

  local procedure SetupRow(ExpectedRow: Variant; SeriesFields: List of [Integer]; NumberSeries: Boolean; EffectiveDate: Date; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Series: Record "No. Series";
    SeriesLine: Record "No. Series Line";
    Manager: Codeunit "BCSF Setup Manager";
    Packages: Codeunit "BCSF Finance Package Mgt";
    NoSeries: Codeunit "No. Series";
    Expected: RecordRef;
    Actual: RecordRef;
    ExpectedField: FieldRef;
    ActualField: FieldRef;
    FieldNo: Integer;
    Code: Code[20];
    Missing: Boolean;
    Changed: Boolean;
  begin
    Expected.GetTable(ExpectedRow);
    Actual.Open(Expected.Number());
    Actual.SecurityFiltering(SecurityFilter::Disallowed);
    if Write then
      Actual.LockTable();
    if not Actual.ReadPermission() then begin
      Block(Actual.Caption(), Write, TempDiff);
      exit;
    end;
    Missing := not Actual.Get(Expected.RecordId());
    if Missing then
      Actual := Expected.Duplicate();
    foreach FieldNo in SeriesFields do begin
      ExpectedField := Expected.Field(FieldNo);
      ActualField := Actual.Field(FieldNo);
      Code := CopyStr(Format(ActualField.Value), 1, MaxStrLen(Code));
      if Missing or (Code = '') then begin
        Code := CopyStr(Format(ExpectedField.Value), 1, MaxStrLen(Code));
        if NumberSeries then
          EnsureSeries(Code, Write, AllowCreate, TempDiff)
        else
          EnsureSourceCode(Code, Write, AllowCreate, TempDiff);
        if Write then
          ActualField.Validate(Code);
        Changed := true;
      end else
      if NumberSeries then begin
        Series.SecurityFiltering(SecurityFilter::Disallowed);
        if not Series.Get(Code) then
          EnsureSeries(Code, Write, AllowCreate, TempDiff)
        else begin
          if not Series."Default Nos." then
            Block(ActualField.Caption() + ' / ' + Code, Write, TempDiff);
          SeriesLine.SetRange("Series Code", Code);
          if SeriesLine.IsEmpty() then
            EnsureSeries(Code, Write, AllowCreate, TempDiff)
          else
            if NoSeries.PeekNextNo(Code, EffectiveDate) = '' then
              Block(ActualField.Caption() + ' / ' + Code, Write, TempDiff);
        end;
      end else
        EnsureSourceCode(Code, Write, AllowCreate, TempDiff);
    end;
    if Changed then begin
      if not AllowCreate or not Packages.HasSetupWritePermission(Actual.Number(), Missing) then begin
        Block(Actual.Caption(), Write, TempDiff);
        exit;
      end;
      if Write then begin
        if Missing then
          Actual.Insert(true)
        else
          Actual.Modify(true);
      end else
        Manager.AddFinding(TempDiff, Actual.Caption(), false, FillLbl, ConfirmLbl);
    end;
    Actual.Close();
    Expected.Close();
  end;

  local procedure EnsureSourceCode(Code: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Expected: Record "Source Code";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Fields: List of [Integer];
  begin
    Expected.Init();
    Expected.Code := CopyStr(Code, 1, MaxStrLen(Expected.Code));
    Expected.Description := CopyStr(Code, 1, MaxStrLen(Expected.Description));
    if Packages.NeedsInsert(Expected, Fields, Write, AllowCreate, TempDiff) then
      Expected.Insert(true);
  end;

  local procedure EnsureSeries(Code: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Expected: Record "No. Series";
    Line: Record "No. Series Line";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Fields: List of [Integer];
  begin
    Expected.Init();
    Expected.Code := Code;
    Expected.Description := Code;
    Expected."Default Nos." := true;
    Fields.Add(Expected.FieldNo("Default Nos."));
    if Packages.NeedsInsert(Expected, Fields, Write, AllowCreate, TempDiff) then
      Expected.Insert(true);
    Clear(Fields);
    Line.Init();
    Line."Series Code" := Code;
    Line."Line No." := 10000;
    Line."Starting No." := CopyStr(Code + '-000001', 1, MaxStrLen(Line."Starting No."));
    Line."Ending No." := CopyStr(Code + '-999999', 1, MaxStrLen(Line."Ending No."));
    Line."Increment-by No." := 1;
    Line.Open := true;
    Fields.Add(Line.FieldNo("Starting No."));
    Fields.Add(Line.FieldNo("Ending No."));
    Fields.Add(Line.FieldNo("Increment-by No."));
    Fields.Add(Line.FieldNo(Open));
    if Packages.NeedsInsert(Line, Fields, Write, AllowCreate, TempDiff) then
      Line.Insert(true);
  end;

  local procedure Terms(Code: Code[10]; Formula: Text; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary; ReuseExisting: Boolean)
  var
    Expected: Record "Payment Terms";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Fields: List of [Integer];
  begin
    if ReuseExisting and Expected.Get(Code) then
      exit;
    Expected.Init();
    Expected.Code := Code;
    Evaluate(Expected."Due Date Calculation", Formula);
    Expected.Description := Code;
    Fields.Add(Expected.FieldNo("Due Date Calculation"));
    Fields.Add(Expected.FieldNo("Discount %"));
    if Packages.NeedsInsert(Expected, Fields, Write, AllowCreate, TempDiff) then
      Expected.Insert(true);
  end;

  local procedure Block(Requirement: Text; Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Manager: Codeunit "BCSF Setup Manager";
  begin
    if Write then
      Error(BlockedErr, Requirement);
    Manager.AddFinding(TempDiff, Requirement, true, StrSubstNo(BlockedErr, Requirement), ConfirmLbl);
  end;

  var
    GermanyLbl: Label 'Germany';
    SimpleLocationLbl: Label 'Central warehouse';
    ExistingBindingErr: Label 'Existing company setup has no compatible account mapping for %1. Missing technical setup can be added, but financial account roles must be configured explicitly. Existing mappings were retained.', Comment = '%1 = setup table or role';
    JournalLbl: Label 'General Journal';
    FillLbl: Label 'Create missing setup or fill empty number series bindings';
    ConfirmLbl: Label 'Review the finance package and confirm. Existing nonempty settings are retained.';
    ReuseLbl: Label 'Reuse existing setup';
    BlockedErr: Label 'Finance foundation %1 is missing, incompatible or not writable. Review setup and permissions before applying.', Comment = '%1 = setup requirement';
}
