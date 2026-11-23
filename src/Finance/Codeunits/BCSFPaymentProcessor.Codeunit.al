namespace BCScenarioFactory.Finance;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.History;

codeunit 90401 "BCSF Payment Processor"
{
  Access = Internal;

  [CommitBehavior(CommitBehavior::Error)]
  procedure PrepareFoundation()
  var
    Bank: Record "Bank Account";
    Group: Record "Bank Account Posting Group";
    Account: Record "G/L Account";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Guard: Codeunit "BCSF Environment Guard";
    GroupCode: Code[20];
  begin
    Guard.EnsureCanConfigure(CompanyName());
    GroupCode := Packages.GetTestPostingGroup(Packages.GetAppliedMode());
    Group.SecurityFiltering(SecurityFilter::Disallowed);
    if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then begin
      // Confirmed German BC standard: GIROKONTO is the domestic bank posting
      // group. Do not pick the first bank group (BAR/BETRIEB/SPARKONTO).
      GroupCode := 'GIROKONTO';
      Group.Get(GroupCode);
      Group.TestField("G/L Account No.", '1810');
    end;
    if GroupCode = '' then begin
      if Group.Count() <> 1 then
        Error(SetupErr);
      Group.FindFirst();
      GroupCode := Group.Code;
    end;
    Group.Get(GroupCode);
    Account.Get(Group."G/L Account No.");
    Account.TestField(Blocked, false);
    if Packages.GetAppliedMode() <> "BCSF Finance Mode"::Existing then
      Account.TestField("Direct Posting", true)
    else
      Account.TestField("Direct Posting", false);
    Account.TestField("Account Type", Account."Account Type"::Posting);
    Bank.SecurityFiltering(SecurityFilter::Disallowed);
    Bank.LockTable();
    if not Bank.Get('BCSF-PAY') then begin
      Bank.Init();
      Bank."No." := 'BCSF-PAY';
      Bank.Validate(Name, BankLbl);
      Bank.Validate("Bank Acc. Posting Group", GroupCode);
      Bank.Insert(true);
    end;
    CheckBank(Bank, GroupCode, Group."G/L Account No.");
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnCapturePaymentSetup', '', false, false)]
  local procedure Capture(Scenario: Record "BCSF Scenario"; var Settings: JsonObject)
  var
    Bank: Record "Bank Account";
    Group: Record "Bank Account Posting Group";
    JournalTemplate: Record "Gen. Journal Template";
    Batch: Record "Gen. Journal Batch";
    Packages: Codeunit "BCSF Finance Package Mgt";
  begin
    if not Scenario."Payment Posting Approved" then
      exit;
    Scenario.TestField("Sales Posting Approved", true);
    Scenario.TestField("Purchase Posting Approved", true);
    Scenario.TestField("Process Mode", "BCSF Process Mode"::FollowUpProcesses);
    Bank.Get('BCSF-PAY');
    Group.Get(Bank."Bank Acc. Posting Group");
    CheckBank(Bank, Group.Code, Group."G/L Account No.");
    if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then begin
      // German standard journal; its source code is FIBUBUCHBL, not GENERAL.
      JournalTemplate.Get('ALLGEMEIN');
    end else
    if not JournalTemplate.Get('GENERAL') then begin
      JournalTemplate.SetRange(Type, JournalTemplate.Type::General);
      JournalTemplate.SetRange(Recurring, false);
      if JournalTemplate.Count() <> 1 then
        Error(SetupErr);
      JournalTemplate.FindFirst();
    end;
    JournalTemplate.TestField(Type, JournalTemplate.Type::General);
    JournalTemplate.TestField(Recurring, false);
    JournalTemplate.TestField("Source Code");
    if not Batch.Get(JournalTemplate.Name, 'STANDARD') then begin
      Batch.SetRange("Journal Template Name", JournalTemplate.Name);
      if Batch.Count() <> 1 then
        Error(SetupErr);
      Batch.FindFirst();
    end;
    Settings.Add('version', 1);
    Settings.Add('approved', true);
    Settings.Add('bankId', Format(Bank.SystemId, 0, 4));
    Settings.Add('bankNo', Bank."No.");
    Settings.Add('bankGroup', Group.Code);
    Settings.Add('bankGL', Group."G/L Account No.");
    Settings.Add('template', JournalTemplate.Name);
    Settings.Add('batch', Batch.Name);
    Settings.Add('sourceCode', JournalTemplate."Source Code");
  end;

  procedure PaymentDate(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; InvoiceDate: Date): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    EndingDate: Date;
  begin
    if Contract.GetDatePolicyVersion(Context) = 0 then
      exit(InvoiceDate);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(Seed.SampleDate(Context, NodeCode, Format(LogicalKey, 0, 9), 'PAYMENT-DATE', InvoiceDate, EndingDate, false));
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
  begin
    if not Context.Get('paymentSetup', Token) then
      exit(false);
    exit((Contract.GetInteger(Token.AsObject(), 'version') = 1) and Contract.GetBoolean(Token.AsObject(), 'approved'));
  end;

  procedure Check(Context: JsonObject)
  var
    Bank: Record "Bank Account";
    JournalTemplate: Record "Gen. Journal Template";
    Batch: Record "Gen. Journal Batch";
    Source: Record "Source Code";
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
    BankId: Guid;
  begin
    if not Enabled(Context) then
      Error(ApprovalErr);
    if Contract.GetInteger(Context, 'processMode') <> 3 then
      Error(ApprovalErr);
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    Evaluate(BankId, Contract.GetText(Settings, 'bankId'));
    Bank.GetBySystemId(BankId);
    Bank.TestField("No.", Contract.GetText(Settings, 'bankNo'));
    CheckBank(Bank, CopyStr(Contract.GetText(Settings, 'bankGroup'), 1, 20), CopyStr(Contract.GetText(Settings, 'bankGL'), 1, 20));
    JournalTemplate.Get(Contract.GetText(Settings, 'template'));
    if Contract.GetText(Settings, 'bankGroup') = 'GIROKONTO' then
      JournalTemplate.TestField(Name, 'ALLGEMEIN');
    JournalTemplate.TestField(Type, JournalTemplate.Type::General);
    JournalTemplate.TestField(Recurring, false);
    JournalTemplate.TestField("Source Code", Contract.GetText(Settings, 'sourceCode'));
    Batch.Get(JournalTemplate.Name, Contract.GetText(Settings, 'batch'));
    Source.Get(JournalTemplate."Source Code");
    // The journal line is temporary; persistent writes belong to the standard posting codeunit.
    RequirePostingCodeunit();
    RequirePermission(Database::"Cust. Ledger Entry");
    RequirePermission(Database::"Detailed Cust. Ledg. Entry");
    RequirePermission(Database::"Vendor Ledger Entry");
    RequirePermission(Database::"Detailed Vendor Ledg. Entry");
    RequirePermission(Database::"Bank Account Ledger Entry");
    RequirePermission(Database::"G/L Entry");
  end;

  local procedure CheckBank(Bank: Record "Bank Account"; GroupCode: Code[20]; AccountNo: Code[20])
  var
    Group: Record "Bank Account Posting Group";
    Account: Record "G/L Account";
    Packages: Codeunit "BCSF Finance Package Mgt";
  begin
    Bank.TestField("No.", 'BCSF-PAY');
    Bank.TestField(Blocked, false);
    Bank.TestField("Currency Code", '');
    Bank.TestField("Bank Account No.", '');
    Bank.TestField(IBAN, '');
    Bank.TestField("SWIFT Code", '');
    Bank.TestField("Bank Acc. Posting Group", GroupCode);
    Group.Get(GroupCode);
    Group.TestField("G/L Account No.", AccountNo);
    if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then begin
      Bank.TestField("Bank Acc. Posting Group", 'GIROKONTO');
      Group.TestField("G/L Account No.", '1810');
    end;
    Account.Get(AccountNo);
    Account.TestField(Blocked, false);
    if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then begin
      // The confirmed German BC demo bank account 1810 is an indirect
      // posting account: never enable direct posting to make payments work.
      Group.TestField("G/L Account No.", '1810');
      Account.TestField("Direct Posting", false);
    end else
      Account.TestField("Direct Posting", true);
    Account.TestField("Account Type", Account."Account Type"::Posting);
  end;

  local procedure RequirePostingCodeunit()
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCodeunitAccess(Codeunit::"Gen. Jnl.-Post Line");
  end;

  local procedure RequirePermission(TableId: Integer)
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsurePostingTableAccess(TableId, TableId in [Database::"Cust. Ledger Entry", Database::"Vendor Ledger Entry"]);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Pay(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; InvoiceEntryNo: Integer; CustomerPayment: Boolean; ParentId: Guid)
  var
    TempLine: Record "Gen. Journal Line" temporary;
    CustomerEntry: Record "Cust. Ledger Entry";
    VendorEntry: Record "Vendor Ledger Entry";
    GL: Record "G/L Entry";
    GLRegister: Record "G/L Register";
    Parent: Record "BCSF Generated Record";
    PurchaseInvoice: Record "Purch. Inv. Header";
    SalesInvoice: Record "Sales Invoice Header";
    Step: Record "BCSF Run Step";
    Manager: Codeunit "BCSF Scenario Manager";
    Rules: Codeunit "BCSF Partner Rules";
    Guard: Codeunit "BCSF Environment Guard";
    PostLine: Codeunit "Gen. Jnl.-Post Line";
    Contract: Codeunit "BCSF Contract JSON";
    Stored: JsonObject;
    Target: JsonObject;
    BatchJson: JsonObject;
    Token: JsonToken;
    Settings: JsonObject;
    VerifiedRun: Guid;
    VerifiedBatch: Guid;
    AccountNo: Code[20];
    DocumentNo: Code[20];
    PostingDate: Date;
    Remaining: Decimal;
    PaymentTransactionNo: Integer;
  begin
    // Reconstruct and verify the immutable contract and actual claimed worker before any payment.
    Step.Get(RunId, NodeCode);
    Manager.ReadSnapshot(RunId, Stored);
    Stored.Add('batchId', Format(BatchId, 0, 4));
    Target.Add('entityCode', NodeCode);
    Target.Add('moduleCode', Step."Module Code");
    Target.Add('quantity', Step."Work Units");
    Target.Add('processMode', Step."Process Mode".AsInteger());
    if not Context.Get('executingBatch', Token) then
      Error(ResultErr);
    BatchJson := Token.AsObject();
    if (LogicalKey < Contract.GetInteger(BatchJson, 'firstKey')) or
      (LogicalKey > Contract.GetInteger(BatchJson, 'lastKey')) then
      Error(ResultErr);
    Rules.EnsureExecution(Stored, Target, BatchJson, Step."Generator Code", VerifiedRun, VerifiedBatch);
    Check(Stored);
    Guard.EnsureCanGenerate(CompanyName(), "BCSF Process Mode"::FollowUpProcesses, Step."Work Units", 1, true);
    Parent.Get(RunId, NodeCode, LogicalKey, 'INVOICE');
    Parent.TestField("Entry Id", ParentId);
    Stored.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    if CustomerPayment then begin
      Parent.TestField("Table Id", Database::"Sales Invoice Header");
      SalesInvoice.GetBySystemId(Parent."Record SystemId");
      SalesInvoice.TestField("Cust. Ledger Entry No.", InvoiceEntryNo);
      CustomerEntry.Get(InvoiceEntryNo);
      CustomerEntry.TestField(Open, true);
      CustomerEntry.TestField("Document Type", CustomerEntry."Document Type"::Invoice);
      CustomerEntry.TestField("Currency Code", '');
      CustomerEntry.CalcFields("Remaining Amount");
      AccountNo := CustomerEntry."Customer No.";
      DocumentNo := CustomerEntry."Document No.";
      PostingDate := CustomerEntry."Posting Date";
      Remaining := CustomerEntry."Remaining Amount";
    end else begin
      Parent.TestField("Table Id", Database::"Purch. Inv. Header");
      PurchaseInvoice.GetBySystemId(Parent."Record SystemId");
      PurchaseInvoice.TestField("Vendor Ledger Entry No.", InvoiceEntryNo);
      VendorEntry.Get(InvoiceEntryNo);
      VendorEntry.TestField(Open, true);
      VendorEntry.TestField("Document Type", VendorEntry."Document Type"::Invoice);
      VendorEntry.TestField("Currency Code", '');
      VendorEntry.CalcFields("Remaining Amount");
      AccountNo := VendorEntry."Vendor No.";
      DocumentNo := VendorEntry."Document No.";
      PostingDate := VendorEntry."Posting Date";
      Remaining := VendorEntry."Remaining Amount";
    end;
    if Remaining = 0 then
      Error(ResultErr);
    TempLine.Init();
    // Field validation invokes payment-tolerance management before posting.
    // Forward suppression to that instance while keeping the batch commit guard.
    TempLine.SetSuppressCommit(true);
    TempLine."Journal Template Name" := CopyStr(Contract.GetText(Settings, 'template'), 1, 10);
    TempLine."Journal Batch Name" := CopyStr(Contract.GetText(Settings, 'batch'), 1, 10);
    TempLine."Line No." := LogicalKey;
    PostingDate := PaymentDate(Stored, NodeCode, LogicalKey, PostingDate);
    TempLine.Validate("Posting Date", PostingDate);
    TempLine.Validate("Document Date", PostingDate);
    TempLine.Validate("Document Type", TempLine."Document Type"::Payment);
    TempLine.Validate("Document No.", DocumentNo);
    if CustomerPayment then
      TempLine.Validate("Account Type", TempLine."Account Type"::Customer)
    else
      TempLine.Validate("Account Type", TempLine."Account Type"::Vendor);
    TempLine.Validate("Account No.", AccountNo);
    TempLine.Validate("Bal. Account Type", TempLine."Bal. Account Type"::"Bank Account");
    TempLine.Validate("Bal. Account No.", CopyStr(Contract.GetText(Settings, 'bankNo'), 1, 20));
    // Assign the payment amount before application; both validations use the
    // standard commit suppression configured above.
    TempLine.Validate(Amount, -Remaining);
    TempLine.Validate("Applies-to Doc. Type", TempLine."Applies-to Doc. Type"::Invoice);
    TempLine.Validate("Applies-to Doc. No.", DocumentNo);
    TempLine."Source Code" := CopyStr(Contract.GetText(Settings, 'sourceCode'), 1, 10);
    TempLine.Insert(true);
    // The return value can be zero for customer/vendor payments despite real G/L entries.
    // Resolve the actual transaction from this posting instance's standard register.
    PostLine.RunWithCheck(TempLine);
    PostLine.GetGLReg(GLRegister);
    if (GLRegister."No." = 0) or (GLRegister."From Entry No." <= 0) or
      (GLRegister."To Entry No." < GLRegister."From Entry No.") then
      Error(ResultErr);
    GL.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
    if not GL.FindFirst() then
      Error(ResultErr);
    GL.TestField("Document No.", DocumentNo);
    GL.TestField("Posting Date", PostingDate);
    PaymentTransactionNo := GL."Transaction No.";
    if PaymentTransactionNo = 0 then
      Error(ResultErr);
    GL.SetFilter("Transaction No.", '<>%1', PaymentTransactionNo);
    if not GL.IsEmpty() then
      Error(ResultErr);
    RegisterPayment(RunId, NodeCode, LogicalKey, BatchId, InvoiceEntryNo, CustomerPayment, PaymentTransactionNo, ParentId);
    ValidatePayment(RunId, NodeCode, LogicalKey, InvoiceEntryNo, CustomerPayment);
  end;

  local procedure RegisterPayment(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; InvoiceEntryNo: Integer; CustomerPayment: Boolean; TransactionNo: Integer; ParentId: Guid)
  var
    CustomerEntry: Record "Cust. Ledger Entry";
    VendorEntry: Record "Vendor Ledger Entry";
    CustomerDetail: Record "Detailed Cust. Ledg. Entry";
    VendorDetail: Record "Detailed Vendor Ledg. Entry";
    GL: Record "G/L Entry";
    BankEntry: Record "Bank Account Ledger Entry";
    Registry: Codeunit "BCSF Record Registry";
    PaymentEntryNo: Integer;
  begin
    if CustomerPayment then begin
      CustomerEntry.SetRange("Transaction No.", TransactionNo);
      CustomerEntry.SetRange("Document Type", CustomerEntry."Document Type"::Payment);
      if CustomerEntry.Count() <> 1 then
        Error(ResultErr);
      CustomerEntry.FindFirst();
      PaymentEntryNo := CustomerEntry."Entry No.";
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PAYMENT', BatchId, CustomerEntry.RecordId(), ParentId);
      CustomerDetail.SetFilter("Cust. Ledger Entry No.", '%1|%2', InvoiceEntryNo, PaymentEntryNo);
      if CustomerDetail.FindSet() then
        repeat
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('CUST-DETAIL', CustomerDetail."Entry No."), BatchId, CustomerDetail.RecordId(), ParentId);
        until CustomerDetail.Next() = 0;
    end else begin
      VendorEntry.SetRange("Transaction No.", TransactionNo);
      VendorEntry.SetRange("Document Type", VendorEntry."Document Type"::Payment);
      if VendorEntry.Count() <> 1 then
        Error(ResultErr);
      VendorEntry.FindFirst();
      PaymentEntryNo := VendorEntry."Entry No.";
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'PAYMENT', BatchId, VendorEntry.RecordId(), ParentId);
      VendorDetail.SetFilter("Vendor Ledger Entry No.", '%1|%2', InvoiceEntryNo, PaymentEntryNo);
      if VendorDetail.FindSet() then
        repeat
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VEND-DETAIL', VendorDetail."Entry No."), BatchId, VendorDetail.RecordId(), ParentId);
        until VendorDetail.Next() = 0;
    end;
    GL.SetRange("Transaction No.", TransactionNo);
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PAY-GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    BankEntry.SetRange("Transaction No.", TransactionNo);
    BankEntry.SetRange("Bank Account No.", 'BCSF-PAY');
    if not BankEntry.FindSet() then
      Error(ResultErr);
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('PAY-BANK', BankEntry."Entry No."), BatchId, BankEntry.RecordId(), ParentId);
    until BankEntry.Next() = 0;
  end;

  procedure ValidatePayment(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; InvoiceEntryNo: Integer; CustomerPayment: Boolean)
  var
    Entry: Record "BCSF Generated Record";
    CustomerEntry: Record "Cust. Ledger Entry";
    VendorEntry: Record "Vendor Ledger Entry";
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    InvoiceDate: Date;
  begin
    Manager.ReadSnapshot(RunId, Context);
    Entry.Get(RunId, NodeCode, LogicalKey, 'PAYMENT');
    if CustomerPayment then begin
      CustomerEntry.Get(InvoiceEntryNo);
      InvoiceDate := CustomerEntry."Posting Date";
      CustomerEntry.CalcFields("Remaining Amount");
      CustomerEntry.TestField(Open, false);
      CustomerEntry.TestField("Remaining Amount", 0);
      CustomerEntry.GetBySystemId(Entry."Record SystemId");
      CustomerEntry.TestField("Posting Date", PaymentDate(Context, NodeCode, LogicalKey, InvoiceDate));
      if Contract.GetDatePolicyVersion(Context) = 1 then
        CustomerEntry.TestField("Document Date", CustomerEntry."Posting Date");
      CustomerEntry.TestField("Document Type", CustomerEntry."Document Type"::Payment);
      CustomerEntry.CalcFields("Remaining Amount");
      CustomerEntry.TestField("Remaining Amount", 0);
      CustomerEntry.TestField(Open, false);
    end else begin
      VendorEntry.Get(InvoiceEntryNo);
      InvoiceDate := VendorEntry."Posting Date";
      VendorEntry.CalcFields("Remaining Amount");
      VendorEntry.TestField(Open, false);
      VendorEntry.TestField("Remaining Amount", 0);
      VendorEntry.GetBySystemId(Entry."Record SystemId");
      VendorEntry.TestField("Posting Date", PaymentDate(Context, NodeCode, LogicalKey, InvoiceDate));
      if Contract.GetDatePolicyVersion(Context) = 1 then
        VendorEntry.TestField("Document Date", VendorEntry."Posting Date");
      VendorEntry.TestField("Document Type", VendorEntry."Document Type"::Payment);
      VendorEntry.CalcFields("Remaining Amount");
      VendorEntry.TestField("Remaining Amount", 0);
      VendorEntry.TestField(Open, false);
    end;
  end;

  local procedure Artifact(Prefix: Code[12]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    BankLbl: Label 'Synthetic payment clearing (no bank connection)';
    SetupErr: Label 'Payment setup, synthetic clearing bank or standard posting permissions are missing or changed. Review the company foundation; no bank data is sent.';
    ApprovalErr: Label 'Payments require the captured follow-up approval and enabled posting in this sandbox.';
    ResultErr: Label 'Payment or application could not be verified. Keep the batch blocked for review; do not repeat an uncertain payment.';
}
