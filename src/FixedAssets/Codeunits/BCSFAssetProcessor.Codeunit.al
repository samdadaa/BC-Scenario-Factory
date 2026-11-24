namespace BCScenarioFactory.FixedAssets;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Purchases.History;

/// <summary>
/// Fixed assets for standard-posted purchase invoices of the same run, in the approved follow-up stage (module Fixed Assets).
/// Per purchase invoice (about 15 %) a fixed asset with its depreciation book is created, its acquisition cost is posted
/// against the synthetic bank account and the first monthly straight-line depreciation is posted, both through the standard
/// general journal posting with the standard fixed asset ledger. Depreciation book, fixed asset posting group and G/L integration
/// of the tenant are only read: nothing is created or changed there. A tenant without usable fixed asset setup, or a
/// posting date outside the allowed fixed asset posting period, is skipped before any write (SOURCE).
/// Captures with the extension marker add a plan mode per asset: 1 acquisition and first depreciation, 2 plus two further monthly
/// depreciation postings, 3 plus appreciation and maintenance, 4 plus disposal with proceeds. Class and subclass come from
/// the synthetic class BCSF. A mode whose posting group accounts, G/L integration or dates are not usable is skipped as a whole (SOURCE).
/// </summary>
codeunit 90488 "BCSF Asset Processor"
{
  Access = Internal;

  /// <summary>Additive marker: assets are offered only when fixed asset setup, depreciation book and posting group are usable.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    BookCode: Code[10];
    GroupCode: Code[20];
  begin
    if not SetupUsable(BookCode, GroupCode) then
      exit;
    Settings.Add('assetVersion', 1);
    // Additive: new captures also plan depreciation runs, appreciation, maintenance and disposal, class and subclass.
    Settings.Add('assetExtVersion', 1);
    Settings.Add('assetBook', BookCode);
    Settings.Add('assetGroup', GroupCode);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'assetVersion'));
  end;

  /// <summary>Read-only: default depreciation book with G/L integration for cost and depreciation, and a posting group with usable accounts.</summary>
  local procedure SetupUsable(var BookCode: Code[10]; var GroupCode: Code[20]): Boolean
  var
    FASetup: Record "FA Setup";
    Book: Record "Depreciation Book";
    Group: Record "FA Posting Group";
  begin
    if not FASetup.Get() or (FASetup."Default Depr. Book" = '') or (FASetup."Fixed Asset Nos." = '') then
      exit(false);
    if not Book.Get(FASetup."Default Depr. Book") then
      exit(false);
    if not Book."G/L Integration - Acq. Cost" or not Book."G/L Integration - Depreciation" then
      exit(false);
    Group.SetCurrentKey(Code);
    if Group.FindSet() then
      repeat
        if UsableAccount(Group."Acquisition Cost Account") and UsableAccount(Group."Accum. Depreciation Account") and
          UsableAccount(Group."Depreciation Expense Acc.")
        then begin
          BookCode := Book.Code;
          GroupCode := Group.Code;
          exit(true);
        end;
      until Group.Next() = 0;
    exit(false);
  end;

  local procedure UsableAccount(AccountNo: Code[20]): Boolean
  var
    Account: Record "G/L Account";
  begin
    if AccountNo = '' then
      exit(false);
    if not Account.Get(AccountNo) then
      exit(false);
    exit((Account."Account Type" = Account."Account Type"::Posting) and not Account.Blocked);
  end;

  /// <summary>Deterministic: 0 no asset for this invoice, 1 asset with acquisition and first depreciation (15 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'ASSET-PLAN', 1, 100) <= 15 then
      exit(1);
    exit(0);
  end;

  /// <summary>Acquisition cost: 500 to 5000 in steps of 50, reproducible by the validator.</summary>
  procedure AcquisitionCost(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Decimal
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'ASSET-COST', 10, 100) * 50);
  end;

  /// <summary>First month of a five-year straight-line depreciation.</summary>
  procedure FirstDepreciation(Cost: Decimal): Decimal
  begin
    exit(Round(Cost / 60, 0.01));
  end;

  procedure DocumentNo(Prefix: Code[1]; Invoice: Record "Purch. Inv. Header"): Code[20]
  begin
    // Code[20]: keep the distinguishing tail of a full-length number instead of truncating it.
    if StrLen(Invoice."No.") < 20 then
      exit(CopyStr(Prefix + Invoice."No.", 1, 20));
    exit(CopyStr(Prefix + CopyStr(Invoice."No.", 2), 1, 20));
  end;

  /// <summary>Plan mode 1 to 4; captures without the extension marker keep mode 1.</summary>
  procedure PlanMode(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Selection: Codeunit "BCSF Module Selection";
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if not Selection.MarkerEnabled(Context, 'assetExtVersion') then
      exit(1);
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'ASSET-MODE', 1, 4));
  end;

  /// <summary>Posting date of the n-th follow-up posting: 30 days apart.</summary>
  procedure StepDate(Date: Date; Step: Integer): Date
  begin
    exit(Date + 30 * Step);
  end;

  procedure ClassCode(): Code[10]
  begin
    exit('BCSF');
  end;

  procedure MaintenanceCode(): Code[10]
  begin
    exit('BCSF');
  end;

  /// <summary>Read-only prerequisites of the mode: G/L integration, posting group accounts and the latest posting date.</summary>
  local procedure ModeUsable(Context: JsonObject; Mode: Integer; BookCode: Code[10]; GroupCode: Code[20]; Date: Date): Boolean
  var
    Book: Record "Depreciation Book";
    Group: Record "FA Posting Group";
    Contract: Codeunit "BCSF Contract JSON";
    EndingDate: Date;
    LastStep: Integer;
  begin
    if Mode = 1 then
      exit(true);
    Book.Get(BookCode);
    Group.Get(GroupCode);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    LastStep := 2;
    if Mode = 3 then
      LastStep := 2;
    if Mode = 4 then
      LastStep := 1;
    if (StepDate(Date, LastStep) > EndingDate) or not PeriodAllowed(StepDate(Date, LastStep)) then
      exit(false);
    case Mode of
      3:
        exit(Book."G/L Integration - Appreciation" and Book."G/L Integration - Maintenance" and
          UsableAccount(Group."Appreciation Account") and UsableAccount(Group."Appreciation Bal. Account") and
          UsableAccount(Group."Maintenance Expense Account") and UsableAccount(Group."Maintenance Bal. Acc."));
      4:
        exit(Book."G/L Integration - Disposal" and UsableAccount(Group."Acq. Cost Acc. on Disposal") and
          UsableAccount(Group."Accum. Depr. Acc. on Disposal") and UsableAccount(Group."Gains Acc. on Disposal") and
          UsableAccount(Group."Losses Acc. on Disposal") and UsableAccount(Group."Book Val. Acc. on Disp. (Gain)") and
          UsableAccount(Group."Book Val. Acc. on Disp. (Loss)") and UsableAccount(Group."Sales Acc. on Disp. (Gain)") and
          UsableAccount(Group."Sales Acc. on Disp. (Loss)"));
    end;
    exit(true);
  end;

  /// <summary>Additive class, subclass and maintenance code of the Scenario Factory. Existing ones are never changed.</summary>
  local procedure EnsureReferences(GroupCode: Code[20])
  var
    FAClass: Record "FA Class";
    FASubclass: Record "FA Subclass";
    Maintenance: Record Maintenance;
  begin
    if not FAClass.Get(ClassCode()) then begin
      FAClass.Init();
      FAClass.Code := ClassCode();
      FAClass.Name := CopyStr(ClassLbl, 1, MaxStrLen(FAClass.Name));
      FAClass.Insert(true);
    end;
    if not FASubclass.Get(ClassCode()) then begin
      FASubclass.Init();
      FASubclass.Code := ClassCode();
      FASubclass.Name := CopyStr(ClassLbl, 1, MaxStrLen(FASubclass.Name));
      FASubclass."FA Class Code" := ClassCode();
      FASubclass."Default FA Posting Group" := GroupCode;
      FASubclass.Insert(true);
    end;
    if not Maintenance.Get(MaintenanceCode()) then begin
      Maintenance.Init();
      Maintenance.Code := MaintenanceCode();
      Maintenance.Description := CopyStr(MaintenanceLbl, 1, MaxStrLen(Maintenance.Description));
      Maintenance.Insert(true);
    end;
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Asset: Record "Fixed Asset";
    AssetBook: Record "FA Depreciation Book";
    Ledger: Record "FA Ledger Entry";
    MaintenanceEntry: Record "Maintenance Ledger Entry";
    FAClass: Record "FA Class";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    Token: JsonToken;
    BookCode: Code[10];
    GroupCode: Code[20];
    Cost: Decimal;
    Mode: Integer;
    Step: Integer;
    SkipReason: Code[30];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    Mode := PlanMode(Context, NodeCode, LogicalKey);
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    BookCode := CopyStr(Contract.GetText(Settings, 'assetBook'), 1, MaxStrLen(BookCode));
    GroupCode := CopyStr(Contract.GetText(Settings, 'assetGroup'), 1, MaxStrLen(GroupCode));
    // Read-only preflight: setup unchanged since capture, permissions, the allowed fixed asset posting period and the mode prerequisites.
    if not SetupUsable(BookCode, GroupCode) or not Asset.WritePermission() or not AssetBook.WritePermission() or
      not PeriodAllowed(Date) or not ModeUsable(Context, Mode, BookCode, GroupCode, Date) or
      ((Mode > 1) and (not FAClass.WritePermission() or not MaintenanceEntry.ReadPermission()))
    then
      SkipReason := 'SOURCE';
    if SkipReason <> '' then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
      exit;
    end;
    Cost := AcquisitionCost(Context, NodeCode, LogicalKey);
    if Mode > 1 then
      EnsureReferences(GroupCode);
    Asset.Init();
    Asset.Description := AssetDescription(Invoice);
    Asset.Insert(true);
    if Mode > 1 then begin
      Asset.Validate("FA Class Code", ClassCode());
      Asset.Validate("FA Subclass Code", ClassCode());
    end;
    Asset.Validate("FA Posting Group", GroupCode);
    Asset.Modify(true);
    AssetBook.Init();
    AssetBook."FA No." := Asset."No.";
    AssetBook."Depreciation Book Code" := BookCode;
    AssetBook.Insert(true);
    AssetBook.Validate("FA Posting Group", GroupCode);
    AssetBook.Validate("Depreciation Method", AssetBook."Depreciation Method"::"Straight-Line");
    AssetBook.Validate("No. of Depreciation Years", 5);
    AssetBook.Validate("Depreciation Starting Date", Date);
    AssetBook.Modify(true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET', BatchId, Asset.RecordId(), ParentId);
    PostJournal(Settings, Asset."No.", BookCode, DocumentNo('F', Invoice), LogicalKey, Date, Cost, 1);
    FindEntry(Ledger, Asset."No.", BookCode, DocumentNo('F', Invoice), Ledger."FA Posting Type"::"Acquisition Cost");
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-ACQUISITION', BatchId, Ledger.RecordId(), ParentId);
    PostJournal(Settings, Asset."No.", BookCode, DocumentNo('A', Invoice), LogicalKey, Date, -FirstDepreciation(Cost), 2);
    FindEntry(Ledger, Asset."No.", BookCode, DocumentNo('A', Invoice), Ledger."FA Posting Type"::Depreciation);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-DEPRECIATION', BatchId, Ledger.RecordId(), ParentId);
    if Mode = 2 then
      // Depreciation run: two further monthly postings.
      for Step := 1 to 2 do begin
        PostJournal(Settings, Asset."No.", BookCode, DocumentNo(CopyStr('BC', Step, 1), Invoice), LogicalKey, StepDate(Date, Step), -FirstDepreciation(Cost), 2);
        FindEntry(Ledger, Asset."No.", BookCode, DocumentNo(CopyStr('BC', Step, 1), Invoice), Ledger."FA Posting Type"::Depreciation);
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-DEPRECIATION-' + Format(Step + 1, 0, 9), BatchId, Ledger.RecordId(), ParentId);
      end;
    if Mode = 3 then begin
      PostJournal(Settings, Asset."No.", BookCode, DocumentNo('Z', Invoice), LogicalKey, StepDate(Date, 1), AppreciationAmount(Cost), 3);
      FindEntry(Ledger, Asset."No.", BookCode, DocumentNo('Z', Invoice), Ledger."FA Posting Type"::Appreciation);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-APPRECIATION', BatchId, Ledger.RecordId(), ParentId);
      PostJournal(Settings, Asset."No.", BookCode, DocumentNo('W', Invoice), LogicalKey, StepDate(Date, 2), MaintenanceAmount(Cost), 4);
      MaintenanceEntry.SetRange("FA No.", Asset."No.");
      MaintenanceEntry.SetRange("Document No.", DocumentNo('W', Invoice));
      if not MaintenanceEntry.FindFirst() then
        Error(ResultErr);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-MAINTENANCE', BatchId, MaintenanceEntry.RecordId(), ParentId);
    end;
    if Mode = 4 then begin
      PostJournal(Settings, Asset."No.", BookCode, DocumentNo('V', Invoice), LogicalKey, StepDate(Date, 1), -DisposalProceeds(Cost), 5);
      FindEntry(Ledger, Asset."No.", BookCode, DocumentNo('V', Invoice), Ledger."FA Posting Type"::"Proceeds on Disposal");
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-DISPOSAL', BatchId, Ledger.RecordId(), ParentId);
    end;
  end;

  procedure AppreciationAmount(Cost: Decimal): Decimal
  begin
    exit(Round(Cost / 10, 0.01));
  end;

  procedure MaintenanceAmount(Cost: Decimal): Decimal
  begin
    exit(Round(Cost / 20, 0.01));
  end;

  /// <summary>Disposal proceeds are 60 % of the cost, so the result is a loss against the remaining book value.</summary>
  procedure DisposalProceeds(Cost: Decimal): Decimal
  begin
    exit(Round(Cost * 0.6, 0.01));
  end;

  local procedure PeriodAllowed(Date: Date): Boolean
  var
    FASetup: Record "FA Setup";
  begin
    if not FASetup.Get() then
      exit(false);
    if (FASetup."Allow FA Posting From" <> 0D) and (Date < FASetup."Allow FA Posting From") then
      exit(false);
    if (FASetup."Allow FA Posting To" <> 0D) and (Date > FASetup."Allow FA Posting To") then
      exit(false);
    exit(true);
  end;

  local procedure AssetDescription(Invoice: Record "Purch. Inv. Header"): Text[100]
  var
    InvoiceLine: Record "Purch. Inv. Line";
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if InvoiceLine.FindFirst() then
      exit(CopyStr(StrSubstNo(AssetLbl, InvoiceLine.Description), 1, 100));
    exit(CopyStr(StrSubstNo(AssetLbl, Invoice."No."), 1, 100));
  end;

  /// <summary>Posting types: 1 acquisition cost, 2 depreciation, 3 appreciation, 4 maintenance, 5 disposal. The line is temporary; persistent writes belong to the standard posting codeunit.</summary>
  local procedure PostJournal(Settings: JsonObject; AssetNo: Code[20]; BookCode: Code[10]; DocumentNo: Code[20]; LogicalKey: Integer; Date: Date; Amount: Decimal; PostingType: Integer)
  var
    TempLine: Record "Gen. Journal Line" temporary;
    PostLine: Codeunit "Gen. Jnl.-Post Line";
    Contract: Codeunit "BCSF Contract JSON";
  begin
    TempLine.Init();
    TempLine.SetSuppressCommit(true);
    TempLine."Journal Template Name" := CopyStr(Contract.GetText(Settings, 'template'), 1, 10);
    TempLine."Journal Batch Name" := CopyStr(Contract.GetText(Settings, 'batch'), 1, 10);
    TempLine."Line No." := LogicalKey;
    TempLine.Validate("Posting Date", Date);
    TempLine.Validate("Document Date", Date);
    TempLine.Validate("Document No.", DocumentNo);
    TempLine.Validate("Account Type", TempLine."Account Type"::"Fixed Asset");
    TempLine.Validate("Account No.", AssetNo);
    case PostingType of
      1: TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::"Acquisition Cost");
      2: TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::Depreciation);
      3: TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::Appreciation);
      4: TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::Maintenance);
      5: TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::Disposal);
    end;
    TempLine.Validate("Depreciation Book Code", BookCode);
    if PostingType = 4 then
      TempLine.Validate("Maintenance Code", MaintenanceCode());
    TempLine.Validate(Amount, Amount);
    if PostingType in [1, 5] then begin
      TempLine.Validate("Bal. Account Type", TempLine."Bal. Account Type"::"Bank Account");
      TempLine.Validate("Bal. Account No.", CopyStr(Contract.GetText(Settings, 'bankNo'), 1, 20));
    end;
    TempLine."Source Code" := CopyStr(Contract.GetText(Settings, 'sourceCode'), 1, 10);
    TempLine.Insert(true);
    PostLine.RunWithCheck(TempLine);
  end;

  local procedure FindEntry(var Ledger: Record "FA Ledger Entry"; AssetNo: Code[20]; BookCode: Code[10]; DocumentNo: Code[20]; PostingType: Enum "FA Ledger Entry FA Posting Type")
  begin
    Ledger.Reset();
    Ledger.SetRange("FA No.", AssetNo);
    Ledger.SetRange("Depreciation Book Code", BookCode);
    Ledger.SetRange("Document No.", DocumentNo);
    Ledger.SetRange("FA Posting Type", PostingType);
    if not Ledger.FindFirst() then
      Error(ResultErr);
  end;

  /// <summary>Read-only validation: asset, depreciation book and every standard ledger entry of the mode match the deterministic plan.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Date: Date)
  var
    Entry: Record "BCSF Generated Record";
    Asset: Record "Fixed Asset";
    AssetBook: Record "FA Depreciation Book";
    Ledger: Record "FA Ledger Entry";
    MaintenanceEntry: Record "Maintenance Ledger Entry";
    Cost: Decimal;
    Mode: Integer;
    Step: Integer;
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'ASSET*');
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'ASSET-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Purch. Inv. Header");
      if Entry."Skip Reason Code" <> 'SOURCE' then
        Error(ResultErr);
      exit;
    end;
    Mode := PlanMode(Context, NodeCode, LogicalKey);
    Cost := AcquisitionCost(Context, NodeCode, LogicalKey);
    Entry.SetRange("Artifact Code", 'ASSET');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Fixed Asset");
    Asset.GetBySystemId(Entry."Record SystemId");
    if Mode > 1 then begin
      Asset.TestField("FA Class Code", ClassCode());
      Asset.TestField("FA Subclass Code", ClassCode());
    end;
    AssetBook.SetRange("FA No.", Asset."No.");
    if not AssetBook.FindFirst() then
      Error(ResultErr);
    CheckLedger(RunId, NodeCode, LogicalKey, 'ASSET-ACQUISITION', Asset."No.", Date, Cost);
    CheckLedger(RunId, NodeCode, LogicalKey, 'ASSET-DEPRECIATION', Asset."No.", Date, -FirstDepreciation(Cost));
    if Mode = 2 then
      for Step := 1 to 2 do
        CheckLedger(RunId, NodeCode, LogicalKey, 'ASSET-DEPRECIATION-' + Format(Step + 1, 0, 9), Asset."No.", StepDate(Date, Step), -FirstDepreciation(Cost));
    if Mode = 3 then begin
      CheckLedger(RunId, NodeCode, LogicalKey, 'ASSET-APPRECIATION', Asset."No.", StepDate(Date, 1), AppreciationAmount(Cost));
      Entry.SetRange("Artifact Code", 'ASSET-MAINTENANCE');
      Entry.FindFirst();
      Entry.TestField("Table Id", Database::"Maintenance Ledger Entry");
      MaintenanceEntry.GetBySystemId(Entry."Record SystemId");
      MaintenanceEntry.TestField("FA No.", Asset."No.");
      MaintenanceEntry.TestField("FA Posting Date", StepDate(Date, 2));
      MaintenanceEntry.TestField(Amount, MaintenanceAmount(Cost));
    end;
    if Mode = 4 then
      CheckLedger(RunId, NodeCode, LogicalKey, 'ASSET-DISPOSAL', Asset."No.", StepDate(Date, 1), -DisposalProceeds(Cost));
  end;

  local procedure CheckLedger(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Artifact: Code[30]; AssetNo: Code[20]; Date: Date; Amount: Decimal)
  var
    Entry: Record "BCSF Generated Record";
    Ledger: Record "FA Ledger Entry";
  begin
    Entry.Get(RunId, NodeCode, LogicalKey, Artifact);
    Entry.TestField("Table Id", Database::"FA Ledger Entry");
    Ledger.GetBySystemId(Entry."Record SystemId");
    Ledger.TestField("FA No.", AssetNo);
    Ledger.TestField("FA Posting Date", Date);
    Ledger.TestField(Amount, Amount);
  end;

  var
    AssetLbl: Label 'Asset: %1', Comment = '%1 = item description of the purchase';
    ClassLbl: Label 'Scenario Factory assets';
    MaintenanceLbl: Label 'Scenario Factory maintenance';
    ResultErr: Label 'Fixed asset results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
