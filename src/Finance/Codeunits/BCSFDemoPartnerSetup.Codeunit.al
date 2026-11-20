namespace BCScenarioFactory.Finance;

using BCScenarioFactory.SetupManager;
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

codeunit 90408 "BCSF Demo Partner Setup"
{
  Access = Internal;

  /// <summary>Foundation of the explicitly reviewed finance package. Never creates substitute G/L accounts.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure Prepare(EffectiveDate: Date; Write: Boolean; AllowCreate: Boolean; Initializing: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
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
    Terms('NET00', '<0D>', Write, AllowCreate, TempDiff);
    Terms('NET14', '<14D>', Write, AllowCreate, TempDiff);
    Terms('NET30', '<30D>', Write, AllowCreate, TempDiff);
    Terms('NET60', '<60D>', Write, AllowCreate, TempDiff);
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
          Block(ActualField.Caption() + ' / ' + Code, Write, TempDiff)
        else begin
          if not Series."Default Nos." then
            Block(ActualField.Caption() + ' / ' + Code, Write, TempDiff);
          if NoSeries.PeekNextNo(Code, EffectiveDate) = '' then
            Block(ActualField.Caption() + ' / ' + Code, Write, TempDiff);
        end;
      end else
        CheckSourceCode(Code, Write, TempDiff);
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

  local procedure CheckSourceCode(Code: Code[20]; Write: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Source: Record "Source Code";
  begin
    Source.SecurityFiltering(SecurityFilter::Disallowed);
    if not Source.Get(Code) then
      Block(Source.TableCaption() + ' / ' + Code, Write, TempDiff);
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

  local procedure Terms(Code: Code[10]; Formula: Text; Write: Boolean; AllowCreate: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Expected: Record "Payment Terms";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Fields: List of [Integer];
  begin
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
    JournalLbl: Label 'General Journal';
    FillLbl: Label 'Create missing setup or fill empty number series bindings';
    ConfirmLbl: Label 'Review the finance package and confirm. Existing nonempty settings are retained.';
    ReuseLbl: Label 'Reuse existing setup';
    BlockedErr: Label 'Finance foundation %1 is missing, incompatible or not writable. Review setup and permissions before applying.', Comment = '%1 = setup requirement';
}
