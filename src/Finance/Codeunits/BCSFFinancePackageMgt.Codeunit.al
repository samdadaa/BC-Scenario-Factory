namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.SetupManager;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 90400 "BCSF Finance Package Mgt"
{
    Access = Internal;
    Permissions = tabledata "BCSF Finance Package" = I;

    procedure Preview(Mode: Enum "BCSF Finance Mode"; var TempDiff: Record "BCSF Setup Diff" temporary): Boolean
    var
        SetupManager: Codeunit "BCSF Setup Manager";
    begin
        if not (Mode in [Mode::Existing, Mode::SKR03, Mode::SKR04]) then
            Error(ApplyBlockedErr);
        TempDiff.Reset();
        TempDiff.DeleteAll();
        Inspect(Mode, WorkDate(), false, TempDiff);
        TempDiff.Reset();
        exit(not SetupManager.HasBlockers(TempDiff));
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Apply(Mode: Enum "BCSF Finance Mode")
    var
        Package: Record "BCSF Finance Package";
        TempDiff: Record "BCSF Setup Diff" temporary;
        Guard: Codeunit "BCSF Environment Guard";
    begin
        if Mode = Mode::Existing then
            exit;
        Guard.EnsureCanConfigure(CompanyName());
        Package.LockTable();
        if not Preview(Mode, TempDiff) then
            Error(ApplyBlockedErr);
        Inspect(Mode, WorkDate(), true, TempDiff);
        if not Package.Get(PackageKeyTok) then begin
            Package.Init();
            Package."Primary Key" := PackageKeyTok;
            Package.Mode := Mode;
            Package."Reference Year" := 2026;
            Package.Version := VersionTok;
            Package.Insert(true);
        end;
    end;

    /// <summary>The test package uses one common code for the posting groups in its supported trade example.</summary>
    procedure GetTestPostingGroup(Mode: Enum "BCSF Finance Mode"): Code[20]
    begin
        case Mode of
            Mode::SKR03:
                exit('BCSF03');
            Mode::SKR04:
                exit('BCSF04');
            else
                exit('');
        end;
    end;

    local procedure Inspect(Mode: Enum "BCSF Finance Mode"; EffectiveDate: Date; Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Package: Record "BCSF Finance Package";
        Ledger: Record "G/L Entry";
        Location: Record Location;
        Inventory: Record "Inventory Setup";
        SetupManager: Codeunit "BCSF Setup Manager";
        AccountNos: Dictionary of [Code[20], Code[20]];
        GroupCode: Code[20];
        ReportPrefix: Code[6];
        AllowCreate: Boolean;
    begin
        if not Write then
            CheckFoundation(EffectiveDate, Mode <> Mode::Existing, TempDiff);
        if Mode = Mode::Existing then begin
            CheckExisting(TempDiff);
            exit;
        end;
        if not Write then
            SetupManager.AddFinding(TempDiff, StrSubstNo(PackageLbl, Format(Mode), 2026, VersionTok), false, SourceLbl, TestOnlyLbl);
        Package.SecurityFiltering(SecurityFilter::Disallowed);
        Inventory.SecurityFiltering(SecurityFilter::Disallowed);
        Location.SecurityFiltering(SecurityFilter::Disallowed);
        Ledger.SecurityFiltering(SecurityFilter::Disallowed);
        if not Ledger.ReadPermission() or not Package.ReadPermission() then begin
            if Write then
                Error(ApplyBlockedErr);
            SetupManager.AddFinding(TempDiff, Format(Mode), true, PermissionLbl, ResolveLbl);
            exit;
        end;
        if Write then
            Ledger.LockTable();
        AllowCreate := Ledger.IsEmpty();
        if Package.Get(PackageKeyTok) then begin
            if (Package.Mode <> Mode) or (Package."Reference Year" <> 2026) or (Package.Version <> VersionTok) then begin
                if Write then
                    Error(ApplyBlockedErr);
                SetupManager.AddFinding(TempDiff, Format(Mode), true, DifferentPackageLbl, ResolveLbl);
                exit;
            end;
        end else
            if not AllowCreate then begin
                if Write then
                    Error(ApplyBlockedErr);
                SetupManager.AddFinding(TempDiff, Format(Mode), true, PostedCompanyLbl, ResolveLbl);
                exit;
            end;
        GroupCode := GetTestPostingGroup(Mode);
        case Mode of
            Mode::SKR03:
                ReportPrefix := 'SF03';
            Mode::SKR04:
                ReportPrefix := 'SF04';
            else
                Error(ApplyBlockedErr);
        end;
        BuildAccounts(Mode, AccountNos, Write, AllowCreate, TempDiff);
        VATBusiness(GroupCode, Write, AllowCreate, TempDiff);
        VATProduct(GroupCode, Write, AllowCreate, TempDiff);
        GenBusiness(GroupCode, Write, AllowCreate, TempDiff);
        GenProduct(GroupCode, Write, AllowCreate, TempDiff);
        InventoryGroup(GroupCode, Write, AllowCreate, TempDiff);
        CustomerGroup(GroupCode, AccountNos.Get('AR'), Write, AllowCreate, TempDiff);
        VendorGroup(GroupCode, AccountNos.Get('AP'), Write, AllowCreate, TempDiff);
        VATMatrix(GroupCode, AccountNos.Get('INPUTVAT'), AccountNos.Get('OUTPUTVAT'), Write, AllowCreate, TempDiff);
        GenMatrix(GroupCode, GroupCode, AccountNos.Get('SALES'), AccountNos.Get('PURCHASES'),
          AccountNos.Get('COST'), AccountNos.Get('ACCRUAL'), Write, AllowCreate, TempDiff);
        // BC also uses the blank business group for inventory-only adjustments.
        GenMatrix('', GroupCode, AccountNos.Get('SALES'), AccountNos.Get('PURCHASES'),
          AccountNos.Get('COST'), AccountNos.Get('ACCRUAL'), Write, AllowCreate, TempDiff);
        InventoryMatrix('', GroupCode, AccountNos.Get('STOCK'), AccountNos.Get('INTERIMSTOCK'), Write, AllowCreate, TempDiff);
        if Inventory.ReadPermission() then
            if Inventory.Get() and Inventory."Location Mandatory" and Location.ReadPermission() then begin
                Location.SetRange("Use As In-Transit", false);
                if Location.FindSet() then
                    repeat
                        InventoryMatrix(Location.Code, GroupCode, AccountNos.Get('STOCK'), AccountNos.Get('INTERIMSTOCK'), Write, AllowCreate, TempDiff);
                    until Location.Next() = 0;
            end;
        BuildReports(ReportPrefix, AccountNos, Write, AllowCreate, TempDiff);
    end;

    local procedure BuildAccounts(Mode: Enum "BCSF Finance Mode"; var Nos: Dictionary of [Code[20], Code[20]]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    begin
        AddAccount(Mode, Nos, 'BANK', '1200', '1800', BankLbl, "G/L Account Category"::Assets,
          true, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'AR', '1400', '1200', ReceivableLbl, "G/L Account Category"::Assets,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'AP', '1600', '3300', PayableLbl, "G/L Account Category"::Liabilities,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'STOCK', '3980', '1140', StockLbl, "G/L Account Category"::Assets,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'INPUTVAT', '1576', '1406', InputVATLbl, "G/L Account Category"::Assets,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'OUTPUTVAT', '1776', '3806', OutputVATLbl, "G/L Account Category"::Liabilities,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'EQUITY', '0800', '2900', EquityLbl, "G/L Account Category"::Equity,
          true, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'SALES', '8400', '4400', SalesLbl, "G/L Account Category"::Income,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'PURCHASES', '3400', '5400', PurchasesLbl, "G/L Account Category"::"Cost of Goods Sold",
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'COST', '3960', '5880', CostLbl, "G/L Account Category"::"Cost of Goods Sold",
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'EXPENSE', '4900', '6300', ExpenseLbl, "G/L Account Category"::Expense,
          true, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'OFFICE', '4930', '6815', OfficeLbl, "G/L Account Category"::Expense,
          true, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'INTERIMSTOCK', 'BCSF-INT', 'BCSF-INT', InterimStockLbl, "G/L Account Category"::Assets,
          false, Write, AllowCreate, TempDiff);
        AddAccount(Mode, Nos, 'ACCRUAL', 'BCSF-ACCR', 'BCSF-ACCR', AccrualLbl, "G/L Account Category"::Liabilities,
          false, Write, AllowCreate, TempDiff);

    end;

    local procedure AddAccount(Mode: Enum "BCSF Finance Mode"; var Nos: Dictionary of [Code[20], Code[20]]; RoleCode: Code[20]; SKR03No: Code[20]; SKR04No: Code[20]; AccountName: Text[100]; Category: Enum "G/L Account Category"; Direct: Boolean; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "G/L Account";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        if Mode = Mode::SKR03 then
            Expected."No." := SKR03No
        else
            Expected."No." := SKR04No;
        Nos.Add(RoleCode, Expected."No.");
        Expected.Name := AccountName;
        Expected."Account Type" := Expected."Account Type"::Posting;
        Expected."Account Category" := Category;
        Expected."Direct Posting" := Direct;
        if Category in [Category::Income, Category::"Cost of Goods Sold", Category::Expense] then
            Expected."Income/Balance" := Expected."Income/Balance"::"Income Statement"
        else
            Expected."Income/Balance" := Expected."Income/Balance"::"Balance Sheet";
        MatchFields.Add(Expected.FieldNo("Account Type"));
        MatchFields.Add(Expected.FieldNo("Account Category"));
        MatchFields.Add(Expected.FieldNo("Income/Balance"));
        MatchFields.Add(Expected.FieldNo("Direct Posting"));
        MatchFields.Add(Expected.FieldNo(Blocked));
        MatchFields.Add(Expected.FieldNo("Gen. Posting Type"));
        MatchFields.Add(Expected.FieldNo("Gen. Bus. Posting Group"));
        MatchFields.Add(Expected.FieldNo("Gen. Prod. Posting Group"));
        MatchFields.Add(Expected.FieldNo("VAT Bus. Posting Group"));
        MatchFields.Add(Expected.FieldNo("VAT Prod. Posting Group"));
        MatchFields.Add(Expected.FieldNo("Debit/Credit"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff)
        then begin
            Expected.Validate(Name, AccountName);
            Expected.Insert(true);
        end;
    end;

    local procedure VATBusiness(GroupCode: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "VAT Business Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure VATProduct(GroupCode: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "VAT Product Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure GenBusiness(GroupCode: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Gen. Business Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        Expected."Def. VAT Bus. Posting Group" := GroupCode;
        Expected."Auto Insert Default" := true;
        MatchFields.Add(Expected.FieldNo("Def. VAT Bus. Posting Group"));
        MatchFields.Add(Expected.FieldNo("Auto Insert Default"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure GenProduct(GroupCode: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Gen. Product Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        Expected."Def. VAT Prod. Posting Group" := GroupCode;
        Expected."Auto Insert Default" := true;
        MatchFields.Add(Expected.FieldNo("Def. VAT Prod. Posting Group"));
        MatchFields.Add(Expected.FieldNo("Auto Insert Default"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure InventoryGroup(GroupCode: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Inventory Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure CustomerGroup(GroupCode: Code[20]; AccountNo: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Customer Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        Expected."Receivables Account" := AccountNo;
        Expected."View All Accounts on Lookup" := true;
        MatchFields.Add(Expected.FieldNo("Receivables Account"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then begin
            Expected.Validate("Receivables Account", Expected."Receivables Account");
            Expected.Insert(true);
        end;
    end;

    local procedure VendorGroup(GroupCode: Code[20]; AccountNo: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Vendor Posting Group";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Code" := GroupCode;
        Expected.Description := TestGroupLbl;
        Expected."Payables Account" := AccountNo;
        Expected."View All Accounts on Lookup" := true;
        MatchFields.Add(Expected.FieldNo("Payables Account"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then begin
            Expected.Validate("Payables Account", Expected."Payables Account");
            Expected.Insert(true);
        end;
    end;

    local procedure VATMatrix(GroupCode: Code[20]; PurchaseVATNo: Code[20]; SalesVATNo: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "VAT Posting Setup";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."VAT Bus. Posting Group" := GroupCode;
        Expected."VAT Prod. Posting Group" := GroupCode;
        Expected."VAT Identifier" := 'BCSF19';
        Expected."VAT %" := 19;
        Expected."VAT Calculation Type" := Expected."VAT Calculation Type"::"Normal VAT";
        Expected."Sales VAT Account" := SalesVATNo;
        Expected."Purchase VAT Account" := PurchaseVATNo;
        Expected.Blocked := false;
        MatchFields.Add(Expected.FieldNo("VAT Identifier"));
        MatchFields.Add(Expected.FieldNo("VAT %"));
        MatchFields.Add(Expected.FieldNo("VAT Calculation Type"));
        MatchFields.Add(Expected.FieldNo("Sales VAT Account"));
        MatchFields.Add(Expected.FieldNo("Purchase VAT Account"));
        MatchFields.Add(Expected.FieldNo(Blocked));
        MatchFields.Add(Expected.FieldNo("EU Service"));
        MatchFields.Add(Expected.FieldNo("Unrealized VAT Type"));
        MatchFields.Add(Expected.FieldNo("Adjust for Payment Discount"));
        MatchFields.Add(Expected.FieldNo("Allow Non-Deductible VAT"));
        MatchFields.Add(Expected.FieldNo("Non-Deductible VAT %"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then begin
            Expected.Validate("VAT %", Expected."VAT %");
            Expected.Validate("Sales VAT Account", Expected."Sales VAT Account");
            Expected.Validate("Purchase VAT Account", Expected."Purchase VAT Account");
            Expected.Insert(true);
        end;
    end;

    local procedure GenMatrix(BusinessCode: Code[20]; ProductCode: Code[20]; SalesNo: Code[20]; PurchasesNo: Code[20]; CostNo: Code[20]; AccrualNo: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "General Posting Setup";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Gen. Bus. Posting Group" := BusinessCode;
        Expected."Gen. Prod. Posting Group" := ProductCode;
        Expected."Sales Account" := SalesNo;
        Expected."Purch. Account" := PurchasesNo;
        Expected."COGS Account" := CostNo;
        Expected."Inventory Adjmt. Account" := CostNo;
        Expected."Sales Credit Memo Account" := SalesNo;
        Expected."Purch. Credit Memo Account" := PurchasesNo;
        Expected."Direct Cost Applied Account" := PurchasesNo;
        Expected."COGS Account (Interim)" := CostNo;
        Expected."Invt. Accrual Acc. (Interim)" := AccrualNo;
        Expected."Sales Line Disc. Account" := SalesNo;
        Expected."Sales Inv. Disc. Account" := SalesNo;
        Expected."Purch. Line Disc. Account" := PurchasesNo;
        Expected."Purch. Inv. Disc. Account" := PurchasesNo;
        Expected.Blocked := false;
        MatchFields.Add(Expected.FieldNo("Sales Account"));
        MatchFields.Add(Expected.FieldNo("Purch. Account"));
        MatchFields.Add(Expected.FieldNo("COGS Account"));
        MatchFields.Add(Expected.FieldNo("Inventory Adjmt. Account"));
        MatchFields.Add(Expected.FieldNo("Sales Credit Memo Account"));
        MatchFields.Add(Expected.FieldNo("Purch. Credit Memo Account"));
        MatchFields.Add(Expected.FieldNo("Direct Cost Applied Account"));
        MatchFields.Add(Expected.FieldNo("COGS Account (Interim)"));
        MatchFields.Add(Expected.FieldNo("Invt. Accrual Acc. (Interim)"));
        MatchFields.Add(Expected.FieldNo("Sales Line Disc. Account"));
        MatchFields.Add(Expected.FieldNo("Sales Inv. Disc. Account"));
        MatchFields.Add(Expected.FieldNo("Purch. Line Disc. Account"));
        MatchFields.Add(Expected.FieldNo("Purch. Inv. Disc. Account"));
        MatchFields.Add(Expected.FieldNo(Blocked));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then begin
            Expected.Validate("Sales Account", Expected."Sales Account");
            Expected.Validate("Purch. Account", Expected."Purch. Account");
            Expected.Validate("COGS Account", Expected."COGS Account");
            Expected.Validate("Inventory Adjmt. Account", Expected."Inventory Adjmt. Account");
            Expected.Validate("Direct Cost Applied Account", Expected."Direct Cost Applied Account");
            Expected.Insert(true);
        end;
    end;

    local procedure InventoryMatrix(LocationCode: Code[10]; GroupCode: Code[20]; StockNo: Code[20]; InterimNo: Code[20]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Inventory Posting Setup";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Location Code" := LocationCode;
        Expected."Invt. Posting Group Code" := GroupCode;
        Expected."Inventory Account" := StockNo;
        Expected."Inventory Account (Interim)" := InterimNo;
        Expected."View All Accounts on Lookup" := true;
        MatchFields.Add(Expected.FieldNo("Inventory Account"));
        MatchFields.Add(Expected.FieldNo("Inventory Account (Interim)"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then begin
            Expected.Validate("Inventory Account", Expected."Inventory Account");
            Expected.Validate("Inventory Account (Interim)", Expected."Inventory Account (Interim)");
            Expected.Insert(true);
        end;
    end;

    local procedure RowHeader(ReportCode: Code[10]; Title: Text[80]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Acc. Schedule Name";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected.Name := ReportCode;
        Expected.Description := Title;
        MatchFields.Add(Expected.FieldNo("Analysis View Name"));
        MatchFields.Add(Expected.FieldNo(Status));

        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure ColumnHeader(ColumnCode: Code[10]; Title: Text[80]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Column Layout Name";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected.Name := ColumnCode;
        Expected.Description := Title;
        MatchFields.Add(Expected.FieldNo("Analysis View Name"));
        MatchFields.Add(Expected.FieldNo(Status));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure ColumnLine(ColumnCode: Code[10]; BalanceSheet: Boolean; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Column Layout";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Column Layout Name" := ColumnCode;
        Expected."Line No." := 10000;
        Expected."Column No." := 'AMOUNT';
        Expected."Column Header" := AmountLbl;
        Expected."Column Type" := Expected."Column Type"::"Net Change";
        Expected.Show := Expected.Show::Always;
        if BalanceSheet then
            Expected."Column Type" := Expected."Column Type"::"Balance at Date";
        MatchFields.Add(Expected.FieldNo("Column No."));
        MatchFields.Add(Expected.FieldNo("Column Type"));
        MatchFields.Add(Expected.FieldNo(Show));
        MatchFields.Add(Expected.FieldNo("Ledger Entry Type"));
        MatchFields.Add(Expected.FieldNo("Amount Type"));
        MatchFields.Add(Expected.FieldNo(Formula));
        MatchFields.Add(Expected.FieldNo("Comparison Date Formula"));
        MatchFields.Add(Expected.FieldNo("Comparison Period Formula"));
        MatchFields.Add(Expected.FieldNo("G/L Account Totaling"));
        MatchFields.Add(Expected.FieldNo("Budget Name"));
        MatchFields.Add(Expected.FieldNo("Show Opposite Sign"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure Report(ReportCode: Code[10]; ColumnCode: Code[10]; Title: Text[80]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Financial Report";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected.Name := ReportCode;
        Expected.Description := Title;
        Expected."Financial Report Row Group" := ReportCode;
        Expected."Financial Report Column Group" := ColumnCode;
        MatchFields.Add(Expected.FieldNo("Financial Report Row Group"));
        MatchFields.Add(Expected.FieldNo("Financial Report Column Group"));
        MatchFields.Add(Expected.FieldNo(UseAmountsInAddCurrency));
        MatchFields.Add(Expected.FieldNo(Dim1Filter));
        MatchFields.Add(Expected.FieldNo(Dim2Filter));
        MatchFields.Add(Expected.FieldNo(Dim3Filter));
        MatchFields.Add(Expected.FieldNo(Dim4Filter));
        MatchFields.Add(Expected.FieldNo(DateFilter));
        MatchFields.Add(Expected.FieldNo(GLBudgetFilter));
        MatchFields.Add(Expected.FieldNo(Status));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;

    local procedure ReportLine(ReportCode: Code[10]; LineNo: Integer; RowNo: Code[10]; Title: Text[100]; Totaling: Text[250]; FormulaLine: Boolean; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Expected: Record "Acc. Schedule Line";
        MatchFields: List of [Integer];
    begin
        Expected.Init();
        Expected."Schedule Name" := ReportCode;
        Expected."Line No." := LineNo;
        Expected."Row No." := RowNo;
        Expected.Description := Title;
        Expected.Totaling := Totaling;
        Expected."Totaling Type" := Expected."Totaling Type"::"Posting Accounts";
        Expected.Show := Expected.Show::Yes;
        if FormulaLine then
            Expected."Totaling Type" := Expected."Totaling Type"::Formula;
        MatchFields.Add(Expected.FieldNo("Row No."));
        MatchFields.Add(Expected.FieldNo(Totaling));
        MatchFields.Add(Expected.FieldNo("Totaling Type"));
        MatchFields.Add(Expected.FieldNo(Show));
        MatchFields.Add(Expected.FieldNo("Show Opposite Sign"));
        MatchFields.Add(Expected.FieldNo("Row Type"));
        MatchFields.Add(Expected.FieldNo("Amount Type"));
        MatchFields.Add(Expected.FieldNo("Dimension 1 Totaling"));
        MatchFields.Add(Expected.FieldNo("Dimension 2 Totaling"));
        MatchFields.Add(Expected.FieldNo("Dimension 3 Totaling"));
        MatchFields.Add(Expected.FieldNo("Dimension 4 Totaling"));
        if NeedsInsert(Expected, MatchFields, Write, AllowCreate, TempDiff) then
            Expected.Insert(true);
    end;


    local procedure BuildReports(Prefix: Code[6]; Nos: Dictionary of [Code[20], Code[20]]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        BS: Code[10];
        PL: Code[10];
        BSCol: Code[10];
        PLCol: Code[10];
    begin
        BS := Prefix + '-BS';
        PL := Prefix + '-PL';
        BSCol := Prefix + '-BAL';
        PLCol := Prefix + '-NET';
        CheckReportKeys(BS, BSCol, 100000, Write, TempDiff);
        CheckReportKeys(PL, PLCol, 40000, Write, TempDiff);
        ColumnHeader(BSCol, BalanceLbl, Write, AllowCreate, TempDiff);
        ColumnHeader(PLCol, IncomeLbl, Write, AllowCreate, TempDiff);
        ColumnLine(BSCol, true, Write, AllowCreate, TempDiff);
        ColumnLine(PLCol, false, Write, AllowCreate, TempDiff);
        RowHeader(BS, BalanceLbl, Write, AllowCreate, TempDiff);
        RowHeader(PL, IncomeLbl, Write, AllowCreate, TempDiff);
        ReportLine(BS, 10000, 'BANK', BankLbl, Nos.Get('BANK'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 20000, 'AR', ReceivableLbl, Nos.Get('AR'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 30000, 'STOCK', StockLbl, Nos.Get('STOCK') + '|' + Nos.Get('INTERIMSTOCK'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 40000, 'INVAT', InputVATLbl, Nos.Get('INPUTVAT'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 50000, 'ASSETS', AssetsLbl, 'BANK+AR+STOCK+INVAT', true, Write, AllowCreate, TempDiff);
        ReportLine(BS, 60000, 'AP', PayableLbl, Nos.Get('AP') + '|' + Nos.Get('ACCRUAL'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 70000, 'OUTVAT', OutputVATLbl, Nos.Get('OUTPUTVAT'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 80000, 'EQUITY', EquityLbl, Nos.Get('EQUITY'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 90000, 'RESULT', ProfitLbl, Nos.Get('SALES') + '|' + Nos.Get('PURCHASES') + '|' + Nos.Get('COST') + '|' + Nos.Get('EXPENSE') + '|' + Nos.Get('OFFICE'), false, Write, AllowCreate, TempDiff);
        ReportLine(BS, 100000, 'TOTAL', LiabEquityLbl, 'AP+OUTVAT+EQUITY+RESULT', true, Write, AllowCreate, TempDiff);
        ReportLine(PL, 10000, 'SALES', SalesLbl, Nos.Get('SALES'), false, Write, AllowCreate, TempDiff);
        ReportLine(PL, 20000, 'COGS', CostLbl, Nos.Get('PURCHASES') + '|' + Nos.Get('COST'), false, Write, AllowCreate, TempDiff);
        ReportLine(PL, 30000, 'OPEX', ExpenseLbl, Nos.Get('EXPENSE') + '|' + Nos.Get('OFFICE'), false, Write, AllowCreate, TempDiff);
        ReportLine(PL, 40000, 'RESULT', ProfitLbl, 'SALES+COGS+OPEX', true, Write, AllowCreate, TempDiff);
        Report(BS, BSCol, BalanceLbl, Write, AllowCreate, TempDiff);
        Report(PL, PLCol, IncomeLbl, Write, AllowCreate, TempDiff);
    end;

    local procedure CheckReportKeys(ReportCode: Code[10]; ColumnCode: Code[10]; LastRow: Integer; Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Row: Record "Acc. Schedule Line";
        Column: Record "Column Layout";
        SetupManager: Codeunit "BCSF Setup Manager";
        Extra: Boolean;
    begin
        Row.SecurityFiltering(SecurityFilter::Disallowed);
        Column.SecurityFiltering(SecurityFilter::Disallowed);
        Row.SetRange("Schedule Name", ReportCode);
        Column.SetRange("Column Layout Name", ColumnCode);
        Column.SetFilter("Line No.", '<>%1', 10000);
        if Write then begin
            Row.LockTable();
            Column.LockTable();
        end;
        if Row.ReadPermission() then
            if Row.FindSet() then
                repeat
                    Extra := Extra or (Row."Line No." < 10000) or (Row."Line No." > LastRow) or ((Row."Line No." mod 10000) <> 0);
                until Row.Next() = 0;
        if Column.ReadPermission() then
            Extra := Extra or not Column.IsEmpty();
        if Extra then begin
            if Write then
                Error(ApplyBlockedErr);
            SetupManager.AddFinding(TempDiff, ReportCode, true, ExtraLinesLbl, ResolveLbl);
        end;
    end;

    local procedure NeedsInsert(ExpectedRow: Variant; MatchFields: List of [Integer]; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary): Boolean
    var
        SetupManager: Codeunit "BCSF Setup Manager";
        Expected: RecordRef;
        Actual: RecordRef;
        ExpectedField: FieldRef;
        ActualField: FieldRef;
        FieldNo: Integer;
        Requirement: Text;
        KeyHint: Text;
        Difference: Text;
        Found: Boolean;
    begin
        Expected.GetTable(ExpectedRow);
        Actual.Open(Expected.Number());
        Actual.SecurityFiltering(SecurityFilter::Disallowed);
        KeyHint := Format(Expected.RecordId());
        Requirement := Expected.Caption() + ' / ' + KeyHint;
        if not Actual.ReadPermission() then begin
            if Write then
                Error(ApplyBlockedErr);
            SetupManager.AddFinding(TempDiff, Requirement, true, PermissionLbl, ResolveLbl);
            exit(false);
        end;
        if Write then
            Actual.LockTable();
        Found := Actual.Get(Expected.RecordId());
        if Found then
            foreach FieldNo in MatchFields do begin
                ActualField := Actual.Field(FieldNo);
                ExpectedField := Expected.Field(FieldNo);
                if (ActualField.Value <> ExpectedField.Value) and (Difference = '') then
                    Difference := ExpectedField.Caption();
            end;
        if Difference <> '' then begin
            if Write then
                Error(ChangedErr, Requirement, Difference);
            SetupManager.AddFinding(TempDiff, Requirement, true, StrSubstNo(ConflictLbl, Difference), ResolveLbl);
            exit(false);
        end;
        if Found then begin
            if not Write then
                SetupManager.AddFinding(TempDiff, Requirement, false, ReuseLbl, NoChangeLbl);
            exit(false);
        end;
        if not AllowCreate or not Actual.WritePermission() then begin
            if Write then
                Error(ApplyBlockedErr);
            if not AllowCreate then
                SetupManager.AddFinding(TempDiff, Requirement, true, PostedCompanyLbl, ResolveLbl)
            else
                SetupManager.AddFinding(TempDiff, Requirement, true, PermissionLbl, ResolveLbl);
            exit(false);
        end;
        if not Write then
            SetupManager.AddFinding(TempDiff, Requirement, false, CreateLbl, ApplyActionLbl);
        exit(Write);
    end;

    local procedure CheckFoundation(EffectiveDate: Date; TestPackage: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        GL: Record "General Ledger Setup";
        Sales: Record "Sales & Receivables Setup";
        Purchases: Record "Purchases & Payables Setup";
        Inventory: Record "Inventory Setup";
        PaymentTerms: Record "Payment Terms";
        Journal: Record "Gen. Journal Template";
        Location: Record Location;
    begin
        GL.SecurityFiltering(SecurityFilter::Disallowed);
        Sales.SecurityFiltering(SecurityFilter::Disallowed);
        Purchases.SecurityFiltering(SecurityFilter::Disallowed);
        Inventory.SecurityFiltering(SecurityFilter::Disallowed);
        PaymentTerms.SecurityFiltering(SecurityFilter::Disallowed);
        Journal.SecurityFiltering(SecurityFilter::Disallowed);
        Location.SecurityFiltering(SecurityFilter::Disallowed);
        if GL.ReadPermission() and GL.Get() then
            CheckPresence(GL.TableCaption() + ' / ' + GL.FieldCaption("Amount Rounding Precision"),
              (GL."Amount Rounding Precision" > 0) and
              ((GL."Allow Posting From" = 0D) or (EffectiveDate >= GL."Allow Posting From")) and
              ((GL."Allow Posting To" = 0D) or (EffectiveDate <= GL."Allow Posting To")), TempDiff)
        else
            CheckPresence(GL.TableCaption(), false, TempDiff);
        if Sales.ReadPermission() and Sales.Get() then begin
            if TestPackage then
                CheckPresence(Sales.TableCaption() + ' / ' + Sales.FieldCaption("Invoice Rounding"), not Sales."Invoice Rounding", TempDiff);
            CheckSeries(Sales.FieldCaption("Customer Nos."), Sales."Customer Nos.", EffectiveDate, true, TempDiff);
            CheckSeries(Sales.FieldCaption("Invoice Nos."), Sales."Invoice Nos.", EffectiveDate, false, TempDiff);
            CheckSeries(Sales.FieldCaption("Posted Invoice Nos."), Sales."Posted Invoice Nos.", EffectiveDate, false, TempDiff);
            if Sales."Shipment on Invoice" then
                CheckSeries(Sales.FieldCaption("Posted Shipment Nos."), Sales."Posted Shipment Nos.", EffectiveDate, false, TempDiff);
        end else
            CheckPresence(Sales.TableCaption(), false, TempDiff);
        if Purchases.ReadPermission() and Purchases.Get() then begin
            if TestPackage then
                CheckPresence(Purchases.TableCaption() + ' / ' + Purchases.FieldCaption("Invoice Rounding"), not Purchases."Invoice Rounding", TempDiff);
            CheckSeries(Purchases.FieldCaption("Vendor Nos."), Purchases."Vendor Nos.", EffectiveDate, true, TempDiff);
            CheckSeries(Purchases.FieldCaption("Invoice Nos."), Purchases."Invoice Nos.", EffectiveDate, false, TempDiff);
            CheckSeries(Purchases.FieldCaption("Posted Invoice Nos."), Purchases."Posted Invoice Nos.", EffectiveDate, false, TempDiff);
            if Purchases."Receipt on Invoice" then
                CheckSeries(Purchases.FieldCaption("Posted Receipt Nos."), Purchases."Posted Receipt Nos.", EffectiveDate, false, TempDiff);
        end else
            CheckPresence(Purchases.TableCaption(), false, TempDiff);
        if Inventory.ReadPermission() and Inventory.Get() then begin
            CheckSeries(Inventory.FieldCaption("Item Nos."), Inventory."Item Nos.", EffectiveDate, true, TempDiff);
            if Inventory."Location Mandatory" then begin
                Location.SetRange("Use As In-Transit", false);
                CheckPresence(Location.TableCaption(), Location.ReadPermission() and not Location.IsEmpty(), TempDiff);
            end;
        end else
            CheckPresence(Inventory.TableCaption(), false, TempDiff);
        CheckPresence(PaymentTerms.TableCaption(), PaymentTerms.ReadPermission() and not PaymentTerms.IsEmpty(), TempDiff);
        Journal.SetRange(Type, Journal.Type::General);
        CheckPresence(Journal.TableCaption(), Journal.ReadPermission() and not Journal.IsEmpty(), TempDiff);
    end;

    local procedure CheckSeries(Requirement: Text; SeriesCode: Code[20]; EffectiveDate: Date; ManualAllowed: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Series: Record "No. Series";
        Line: Record "No. Series Line";
        Valid: Boolean;
        LatestDate: Date;
    begin
        Series.SecurityFiltering(SecurityFilter::Disallowed);
        Line.SecurityFiltering(SecurityFilter::Disallowed);
        LatestDate := 0D;
        if Series.ReadPermission() and Line.ReadPermission() then
            if Series.Get(SeriesCode) then begin
                if Series."Default Nos." then begin
                    Line.SetRange("Series Code", SeriesCode);
                    Line.SetFilter("Starting Date", '..%1', EffectiveDate);
                    if Line.FindSet() then
                        repeat
                            if Line."Starting Date" >= LatestDate then begin
                                LatestDate := Line."Starting Date";
                                Valid := Line.Open and (Line."Starting No." <> '') and (Line."Increment-by No." > 0);
                            end;
                        until Line.Next() = 0;
                end;
                Valid := Valid or (ManualAllowed and Series."Manual Nos.");
            end;
        CheckPresence(Requirement, Valid, TempDiff);
    end;

    local procedure CheckExisting(var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Account: Record "G/L Account";
        GeneralMatrix: Record "General Posting Setup";
        VATSetup: Record "VAT Posting Setup";
        InventorySetup: Record "Inventory Posting Setup";
        FinanceCheck: Codeunit "BCSF Finance Setup Check";
    begin
        Account.SetRange(Blocked, false);
        Account.SetRange("Account Type", Account."Account Type"::Posting);
        GeneralMatrix.SetRange(Blocked, false);
        VATSetup.SetRange(Blocked, false);
        CheckPresence(Account.TableCaption(), Account.ReadPermission() and not Account.IsEmpty(), TempDiff);
        CheckPresence(GeneralMatrix.TableCaption(), GeneralMatrix.ReadPermission() and not GeneralMatrix.IsEmpty(), TempDiff);
        CheckPresence(VATSetup.TableCaption(), VATSetup.ReadPermission() and not VATSetup.IsEmpty(), TempDiff);
        CheckPresence(InventorySetup.TableCaption(), InventorySetup.ReadPermission() and not InventorySetup.IsEmpty(), TempDiff);
        FinanceCheck.Inspect(true, true, TempDiff);
    end;

    local procedure CheckPresence(Requirement: Text; Ready: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        SetupManager: Codeunit "BCSF Setup Manager";
    begin
        if Ready then
            SetupManager.AddFinding(TempDiff, Requirement, false, ReuseLbl, NoChangeLbl)
        else
            SetupManager.AddFinding(TempDiff, Requirement, true, MissingFoundationLbl, ResolveLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCaptureFinancePackage', '', false, false)]
    local procedure CaptureFinance(Mode: Enum "BCSF Finance Mode"; var Year: Integer; var PackageVersion: Code[20])
    var
        Package: Record "BCSF Finance Package";
    begin
        if Mode = Mode::Existing then
            exit;
        if not Package.Get(PackageKeyTok) then
            Error(NotAppliedErr);
        Package.TestField(Mode, Mode);
        Year := Package."Reference Year";
        PackageVersion := Package.Version;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Setup Manager", 'OnInspectFinancePackage', '', false, false)]
    local procedure CheckSnapshotFinance(Context: JsonObject; EffectiveDate: Date; var TempDiff: Record "BCSF Setup Diff" temporary)
    var
        Package: Record "BCSF Finance Package";
        TempPackageDiff: Record "BCSF Setup Diff" temporary;
        SetupManager: Codeunit "BCSF Setup Manager";
        Contract: Codeunit "BCSF Contract JSON";
        Mode: Enum "BCSF Finance Mode";
        Token: JsonToken;
    begin
        if not Context.Get('financeMode', Token) then
            exit;
        Mode := "BCSF Finance Mode".FromInteger(Token.AsValue().AsInteger());
        if Mode = Mode::Existing then
            exit;
        if not Package.Get(PackageKeyTok) then begin
            SetupManager.AddFinding(TempDiff, Format(Mode), true, NotAppliedErr, ResolveLbl);
            exit;
        end;
        if (Package.Mode <> Mode) or (Package."Reference Year" <> Contract.GetInteger(Context, 'financeYear')) or
          (Package.Version <> Contract.GetCode(Context, 'financeVersion'))
        then begin
            SetupManager.AddFinding(TempDiff, Format(Mode), true, DifferentPackageLbl, ResolveLbl);
            exit;
        end;
        Inspect(Mode, EffectiveDate, false, TempPackageDiff);
        if TempPackageDiff.FindSet() then
            repeat
                if TempPackageDiff.Blocked or (TempPackageDiff.Finding = CreateLbl) then
                    SetupManager.AddFinding(TempDiff, TempPackageDiff.Requirement, true, TempPackageDiff.Finding, TempPackageDiff.Action);
            until TempPackageDiff.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCSF Finance Package", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckPackageInsert(var Rec: Record "BCSF Finance Package"; RunTrigger: Boolean)
    var
        TempDiff: Record "BCSF Setup Diff" temporary;
        Guard: Codeunit "BCSF Environment Guard";
    begin
        if Rec.IsTemporary() then
            exit;
        Guard.EnsureCanConfigure(Rec.CurrentCompany());
        Rec.TestField("Primary Key", PackageKeyTok);
        Rec.TestField("Reference Year", 2026);
        Rec.TestField(Version, VersionTok);
        if not (Rec.Mode in [Rec.Mode::SKR03, Rec.Mode::SKR04]) then
            Error(ApplyBlockedErr);
        if not Preview(Rec.Mode, TempDiff) then
            Error(ApplyBlockedErr);
        TempDiff.SetRange(Finding, CreateLbl);
        if not TempDiff.IsEmpty() then
            Error(ApplyBlockedErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCSF Finance Package", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckPackageModify(var Rec: Record "BCSF Finance Package"; var xRec: Record "BCSF Finance Package"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            Error(ApplyBlockedErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCSF Finance Package", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckPackageDelete(var Rec: Record "BCSF Finance Package"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            Error(ApplyBlockedErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCSF Finance Package", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckPackageRename(var Rec: Record "BCSF Finance Package"; var xRec: Record "BCSF Finance Package"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            Error(ApplyBlockedErr);
    end;

    var
        PackageKeyTok: Label 'APPLIED', Locked = true;
        VersionTok: Label '1.0.0', Locked = true;
        PackageLbl: Label '%1 / reference year %2 / package version %3', Comment = '%1 = package name, %2 = reference year, %3 = package version';
        SourceLbl: Label 'Based on DATEV standard charts 2026 (SKR03 article 11174, SKR04 article 11175).';
        TestOnlyLbl: Label 'For sandbox trade tests only. This is not a complete DATEV chart or statutory report.';
        PermissionLbl: Label 'Required standard read or write permission is missing.';
        ResolveLbl: Label 'Review the standard BC setup or permissions before applying. No existing setup will be overwritten.';
        DifferentPackageLbl: Label 'A different chart or package version is already recorded in this company.';
        PostedCompanyLbl: Label 'The company already has G/L entries. Initial installation or creation of missing package records is blocked.';
        ReuseLbl: Label 'Reuse existing record';
        NoChangeLbl: Label 'No change';
        ConflictLbl: Label 'Existing record conflicts in field %1.', Comment = '%1 = field caption';
        ChangedErr: Label 'Setup changed since review. %1 has a conflict in field %2. No package changes were kept.', Comment = '%1 = record, %2 = field caption';
        ApplyBlockedErr: Label 'The finance package cannot be applied. Reopen the preview and resolve the blocking findings.';
        CreateLbl: Label 'Create missing record';
        ApplyActionLbl: Label 'Create only when you explicitly apply the reviewed package.';
        ExtraLinesLbl: Label 'The report definition contains additional rows or columns outside the package.';
        MissingFoundationLbl: Label 'Required standard setup is missing, not visible or not usable on the selected date.';
        NotAppliedErr: Label 'Apply the selected finance test package in this company before capturing the run.';
        TestGroupLbl: Label 'Scenario Factory domestic 19% test setup';
        AssetsLbl: Label 'Total Assets';
        LiabEquityLbl: Label 'Total Liabilities and Equity';
        ProfitLbl: Label 'Result (credit balance is negative)';
        BalanceLbl: Label 'Scenario Factory Test Balance Sheet';
        IncomeLbl: Label 'Scenario Factory Test Income Statement';
        AmountLbl: Label 'Actual Amount';
        BankLbl: Label 'Bank';
        ReceivableLbl: Label 'Trade Receivables';
        PayableLbl: Label 'Trade Payables';
        StockLbl: Label 'Merchandise Inventory';
        InputVATLbl: Label 'Input VAT 19%';
        OutputVATLbl: Label 'Output VAT 19%';
        EquityLbl: Label 'Share Capital';
        SalesLbl: Label 'Domestic Sales 19%';
        PurchasesLbl: Label 'Merchandise Purchases 19%';
        CostLbl: Label 'Merchandise Cost and Stock Change';
        ExpenseLbl: Label 'Other Operating Expense';
        OfficeLbl: Label 'Office Supplies';
        InterimStockLbl: Label 'Test Inventory Interim';
        AccrualLbl: Label 'Test Inventory Accrual';
}
