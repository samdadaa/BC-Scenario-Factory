namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.CRM.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 90408 "BCSF Demo Partner Setup"
{
  Access = Internal;

  procedure UsesDemoSetup(Scenario: Record "BCSF Scenario"): Boolean
  begin
    exit((Scenario."Finance Mode" = "BCSF Finance Mode"::Existing) and
      (Scenario."Partner Country Code" = 'DE') and
      (Scenario."Customer Posting Group" = 'BCSF-DEMO') and
      (Scenario."Vendor Posting Group" = 'BCSF-DEMO') and
      (Scenario."Gen. Bus. Posting Group" = 'BCSF-DEMO') and
      (Scenario."VAT Bus. Posting Group" = 'BCSF-DEMO') and
      (Scenario."Cash Terms Code" = 'BCSF-0D') and (Scenario."Small Terms Code" = 'BCSF-14D') and
      (Scenario."Medium Terms Code" = 'BCSF-30D') and (Scenario."Large Terms Code" = 'BCSF-60D'));
  end;

  /// <summary>Fills minimal partner-only prerequisites after an explicit UI confirmation.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure EnsureSetup(Scenario: Record "BCSF Scenario")
  var
    Setup: Record "BCSF Factory Setup";
    Ledger: Record "G/L Entry";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    if not UsesDemoSetup(Scenario) then
      Error(ConflictErr);
    Guard.EnsureCanConfigure(Scenario.CurrentCompany());
    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    Ledger.SecurityFiltering(SecurityFilter::Disallowed);
    Ledger.LockTable();
    if not Ledger.IsEmpty() then
      Error(PostedErr);
    EnsureFoundation();
    EnsureTerms('BCSF-0D', '<0D>');
    EnsureTerms('BCSF-14D', '<14D>');
    EnsureTerms('BCSF-30D', '<30D>');
    EnsureTerms('BCSF-60D', '<60D>');
    EnsureAccount('BCSF-AR', ReceivablesLbl, "G/L Account Category"::Assets);
    EnsureAccount('BCSF-AP', PayablesLbl, "G/L Account Category"::Liabilities);
    EnsureGroups();
    EnsureSeriesAndBindings();
  end;

  local procedure EnsureFoundation()
  var
    Country: Record "Country/Region";
    GeneralLedger: Record "General Ledger Setup";
    Marketing: Record "Marketing Setup";
  begin
    Country.SecurityFiltering(SecurityFilter::Disallowed);
    Country.LockTable();
    if not Country.Get('DE') then begin
      Country.Init();
      Country.Code := 'DE';
      Country.Name := GermanyLbl;
      Country.Insert(true);
    end;
    GeneralLedger.SecurityFiltering(SecurityFilter::Disallowed);
    GeneralLedger.LockTable();
    if not GeneralLedger.Get() then begin
      GeneralLedger.Init();
      GeneralLedger."Amount Rounding Precision" := 0.01;
      GeneralLedger.Insert(true);
    end;
    Marketing.SecurityFiltering(SecurityFilter::Disallowed);
    Marketing.LockTable();
    if not Marketing.Get() then begin
      Marketing.Init();
      Marketing.Insert(true);
    end;
  end;

  local procedure EnsureTerms(CodeValue: Code[10]; Formula: Text)
  var
    Terms: Record "Payment Terms";
    Due: DateFormula;
  begin
    Evaluate(Due, Formula);
    Terms.SecurityFiltering(SecurityFilter::Disallowed);
    Terms.LockTable();
    if Terms.Get(CodeValue) then begin
      Terms.TestField("Due Date Calculation", Due);
      Terms.TestField("Discount %", 0);
      exit;
    end;
    Terms.Init();
    Terms.Code := CodeValue;
    Terms.Description := CopyStr(StrSubstNo(TermsLbl, Formula), 1, MaxStrLen(Terms.Description));
    Terms."Due Date Calculation" := Due;
    Terms.Insert(true);
  end;

  local procedure EnsureAccount(No: Code[20]; AccountName: Text[100]; Category: Enum "G/L Account Category")
  var
    Account: Record "G/L Account";
  begin
    Account.SecurityFiltering(SecurityFilter::Disallowed);
    Account.LockTable();
    if Account.Get(No) then begin
      Account.TestField("Account Type", Account."Account Type"::Posting);
      Account.TestField("Account Category", Category);
      Account.TestField("Income/Balance", Account."Income/Balance"::"Balance Sheet");
      Account.TestField(Blocked, false);
      Account.TestField("Direct Posting", false);
      exit;
    end;
    Account.Init();
    Account."No." := No;
    Account.Validate(Name, AccountName);
    Account."Account Type" := Account."Account Type"::Posting;
    Account."Account Category" := Category;
    Account."Income/Balance" := Account."Income/Balance"::"Balance Sheet";
    Account."Direct Posting" := false;
    Account.Insert(true);
  end;

  local procedure EnsureGroups()
  var
    GeneralGroup: Record "Gen. Business Posting Group";
    VATGroup: Record "VAT Business Posting Group";
    CustomerGroup: Record "Customer Posting Group";
    VendorGroup: Record "Vendor Posting Group";
  begin
    GeneralGroup.SecurityFiltering(SecurityFilter::Disallowed);
    GeneralGroup.LockTable();
    if not GeneralGroup.Get('BCSF-DEMO') then begin
      GeneralGroup.Init();
      GeneralGroup.Code := 'BCSF-DEMO';
      GeneralGroup.Description := GroupLbl;
      GeneralGroup.Insert(true);
    end;
    VATGroup.SecurityFiltering(SecurityFilter::Disallowed);
    VATGroup.LockTable();
    if not VATGroup.Get('BCSF-DEMO') then begin
      VATGroup.Init();
      VATGroup.Code := 'BCSF-DEMO';
      VATGroup.Description := GroupLbl;
      VATGroup.Insert(true);
    end;
    CustomerGroup.SecurityFiltering(SecurityFilter::Disallowed);
    CustomerGroup.LockTable();
    if CustomerGroup.Get('BCSF-DEMO') then
      CustomerGroup.TestField("Receivables Account", 'BCSF-AR')
    else begin
      CustomerGroup.Init();
      CustomerGroup.Code := 'BCSF-DEMO';
      CustomerGroup.Description := GroupLbl;
      CustomerGroup."View All Accounts on Lookup" := true;
      CustomerGroup.Validate("Receivables Account", 'BCSF-AR');
      CustomerGroup.Insert(true);
    end;
    VendorGroup.SecurityFiltering(SecurityFilter::Disallowed);
    VendorGroup.LockTable();
    if VendorGroup.Get('BCSF-DEMO') then
      VendorGroup.TestField("Payables Account", 'BCSF-AP')
    else begin
      VendorGroup.Init();
      VendorGroup.Code := 'BCSF-DEMO';
      VendorGroup.Description := GroupLbl;
      VendorGroup."View All Accounts on Lookup" := true;
      VendorGroup.Validate("Payables Account", 'BCSF-AP');
      VendorGroup.Insert(true);
    end;
  end;

  local procedure EnsureSeriesAndBindings()
  var
    Sales: Record "Sales & Receivables Setup";
    Purchases: Record "Purchases & Payables Setup";
  begin
    Sales.SecurityFiltering(SecurityFilter::Disallowed);
    Sales.LockTable();
    if not Sales.Get() then begin
      Sales.Init();
      EnsureSeries('BCSF-CUST', 'SF-C-000001', 'SF-C-999999');
      Sales.Validate("Customer Nos.", 'BCSF-CUST');
      Sales.Insert(true);
    end else
      if Sales."Customer Nos." = '' then begin
        EnsureSeries('BCSF-CUST', 'SF-C-000001', 'SF-C-999999');
        Sales.Validate("Customer Nos.", 'BCSF-CUST');
        Sales.Modify(true);
      end;
    Purchases.SecurityFiltering(SecurityFilter::Disallowed);
    Purchases.LockTable();
    if not Purchases.Get() then begin
      Purchases.Init();
      EnsureSeries('BCSF-VEND', 'SF-V-000001', 'SF-V-999999');
      Purchases.Validate("Vendor Nos.", 'BCSF-VEND');
      Purchases.Insert(true);
    end else
      if Purchases."Vendor Nos." = '' then begin
        EnsureSeries('BCSF-VEND', 'SF-V-000001', 'SF-V-999999');
        Purchases.Validate("Vendor Nos.", 'BCSF-VEND');
        Purchases.Modify(true);
      end;
  end;

  local procedure EnsureSeries(CodeValue: Code[20]; FirstNo: Code[20]; LastNo: Code[20])
  var
    Series: Record "No. Series";
    SeriesLine: Record "No. Series Line";
    ExistingLine: Record "No. Series Line";
  begin
    Series.SecurityFiltering(SecurityFilter::Disallowed);
    SeriesLine.SecurityFiltering(SecurityFilter::Disallowed);
    ExistingLine.SecurityFiltering(SecurityFilter::Disallowed);
    Series.LockTable();
    SeriesLine.LockTable();
    if Series.Get(CodeValue) then begin
      Series.TestField("Default Nos.", true);
      ExistingLine.SetRange("Series Code", CodeValue);
      if (ExistingLine.Count() <> 1) or not SeriesLine.Get(CodeValue, 10000) then
        Error(ConflictErr);
      SeriesLine.TestField("Starting No.", FirstNo);
      SeriesLine.TestField("Ending No.", LastNo);
      SeriesLine.TestField("Increment-by No.", 1);
      SeriesLine.TestField(Open, true);
      exit;
    end;
    Series.Init();
    Series.Code := CodeValue;
    Series.Description := GroupLbl;
    Series."Default Nos." := true;
    Series.Insert(true);
    SeriesLine.Init();
    SeriesLine."Series Code" := CodeValue;
    SeriesLine."Line No." := 10000;
    SeriesLine.Validate("Starting No.", FirstNo);
    SeriesLine.Validate("Ending No.", LastNo);
    SeriesLine.Validate("Increment-by No.", 1);
    SeriesLine.Open := true;
    SeriesLine.Insert(true);
  end;

  var
    ConflictErr: Label 'The existing setup conflicts with the reserved partner demo setup. Select compatible existing settings instead.';
    PostedErr: Label 'Partner demo setup can only be prepared in a sandbox test company without G/L entries.';
    GermanyLbl: Label 'Germany';
    TermsLbl: Label 'Scenario Factory test terms %1', Comment = '%1 = due date formula';
    ReceivablesLbl: Label 'Scenario Factory Test Receivables';
    PayablesLbl: Label 'Scenario Factory Test Payables';
    GroupLbl: Label 'Scenario Factory Partner Test';
}
