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
using Microsoft.FixedAssets.Setup;
using Microsoft.Purchases.History;

/// <summary>
/// Fixed assets for standard-posted purchase invoices of the same run, in the approved follow-up stage (module Fixed Assets).
/// Per purchase invoice (about 15 %) a fixed asset with its depreciation book is created, its acquisition cost is posted
/// against the synthetic bank account and the first monthly straight-line depreciation is posted, both through the standard
/// general journal posting with the standard fixed asset ledger. Depreciation book, fixed asset posting group and G/L integration
/// of the tenant are only read: nothing is created or changed there. A tenant without usable fixed asset setup, or a
/// posting date outside the allowed fixed asset posting period, is skipped before any write (SOURCE).
/// Disposal is not part of this module.
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

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Asset: Record "Fixed Asset";
    AssetBook: Record "FA Depreciation Book";
    Ledger: Record "FA Ledger Entry";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    Token: JsonToken;
    BookCode: Code[10];
    GroupCode: Code[20];
    Cost: Decimal;
    SkipReason: Code[30];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    BookCode := CopyStr(Contract.GetText(Settings, 'assetBook'), 1, MaxStrLen(BookCode));
    GroupCode := CopyStr(Contract.GetText(Settings, 'assetGroup'), 1, MaxStrLen(GroupCode));
    // Read-only preflight: setup unchanged since capture, permissions and the allowed fixed asset posting period.
    if not SetupUsable(BookCode, GroupCode) or not Asset.WritePermission() or not AssetBook.WritePermission() or
      not PeriodAllowed(Date)
    then
      SkipReason := 'SOURCE';
    if SkipReason <> '' then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
      exit;
    end;
    Cost := AcquisitionCost(Context, NodeCode, LogicalKey);
    Asset.Init();
    Asset.Description := AssetDescription(Invoice);
    Asset.Insert(true);
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
    PostJournal(Settings, Asset."No.", BookCode, DocumentNo('F', Invoice), LogicalKey, Date, Cost, true);
    FindEntry(Ledger, Asset."No.", BookCode, true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-ACQUISITION', BatchId, Ledger.RecordId(), ParentId);
    PostJournal(Settings, Asset."No.", BookCode, DocumentNo('A', Invoice), LogicalKey, Date, -FirstDepreciation(Cost), false);
    FindEntry(Ledger, Asset."No.", BookCode, false);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSET-DEPRECIATION', BatchId, Ledger.RecordId(), ParentId);
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

  /// <summary>The line is temporary; persistent writes belong to the standard posting codeunit.</summary>
  local procedure PostJournal(Settings: JsonObject; AssetNo: Code[20]; BookCode: Code[10]; DocumentNo: Code[20]; LogicalKey: Integer; Date: Date; Amount: Decimal; Acquisition: Boolean)
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
    if Acquisition then
      TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::"Acquisition Cost")
    else
      TempLine.Validate("FA Posting Type", TempLine."FA Posting Type"::Depreciation);
    TempLine.Validate("Depreciation Book Code", BookCode);
    TempLine.Validate(Amount, Amount);
    if Acquisition then begin
      TempLine.Validate("Bal. Account Type", TempLine."Bal. Account Type"::"Bank Account");
      TempLine.Validate("Bal. Account No.", CopyStr(Contract.GetText(Settings, 'bankNo'), 1, 20));
    end;
    TempLine."Source Code" := CopyStr(Contract.GetText(Settings, 'sourceCode'), 1, 10);
    TempLine.Insert(true);
    PostLine.RunWithCheck(TempLine);
  end;

  local procedure FindEntry(var Ledger: Record "FA Ledger Entry"; AssetNo: Code[20]; BookCode: Code[10]; Acquisition: Boolean)
  begin
    Ledger.Reset();
    Ledger.SetRange("FA No.", AssetNo);
    Ledger.SetRange("Depreciation Book Code", BookCode);
    if Acquisition then
      Ledger.SetRange("FA Posting Type", Ledger."FA Posting Type"::"Acquisition Cost")
    else
      Ledger.SetRange("FA Posting Type", Ledger."FA Posting Type"::Depreciation);
    if not Ledger.FindFirst() then
      Error(ResultErr);
  end;

  /// <summary>Read-only validation: asset, depreciation book and both standard ledger entries match the deterministic plan.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Date: Date)
  var
    Entry: Record "BCSF Generated Record";
    Asset: Record "Fixed Asset";
    AssetBook: Record "FA Depreciation Book";
    Ledger: Record "FA Ledger Entry";
    Cost: Decimal;
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
    Cost := AcquisitionCost(Context, NodeCode, LogicalKey);
    Entry.SetRange("Artifact Code", 'ASSET');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"Fixed Asset");
    Asset.GetBySystemId(Entry."Record SystemId");
    AssetBook.SetRange("FA No.", Asset."No.");
    if not AssetBook.FindFirst() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'ASSET-ACQUISITION');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"FA Ledger Entry");
    Ledger.GetBySystemId(Entry."Record SystemId");
    Ledger.TestField("FA No.", Asset."No.");
    Ledger.TestField("FA Posting Date", Date);
    Ledger.TestField(Amount, Cost);
    Entry.SetRange("Artifact Code", 'ASSET-DEPRECIATION');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::"FA Ledger Entry");
    Ledger.GetBySystemId(Entry."Record SystemId");
    Ledger.TestField("FA No.", Asset."No.");
    Ledger.TestField("FA Posting Date", Date);
    Ledger.TestField(Amount, -FirstDepreciation(Cost));
  end;

  var
    AssetLbl: Label 'Asset: %1', Comment = '%1 = item description of the purchase';
    ResultErr: Label 'Fixed asset results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
