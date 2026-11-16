namespace BCScenarioFactory.SetupManager;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Setup;

codeunit 90226 "BCSF Setup Manager"
{
  Access = Internal;

  /// <summary>Current, permission-filtered evidence only. Never changes setup or approves execution.</summary>
  procedure BuildFromRun(RunId: Guid; var TempDiff: Record "BCSF Setup Diff" temporary): Boolean
  var
    Header: Record "BCSF Run Header";
    TempTargets: Record "BCSF Data Target" temporary;
    LedgerSetup: Record "General Ledger Setup";
    InventorySetup: Record "Inventory Setup";
    Manager: Codeunit "BCSF Scenario Manager";
    Context: JsonObject;
    NeedSales: Boolean;
    NeedPurchases: Boolean;
    NeedItems: Boolean;
    Posting: Boolean;
  begin
    TempDiff.Reset();
    TempDiff.DeleteAll();
    Manager.ReadSnapshot(RunId, Context);
    Header.Get(RunId);
    if Header."Company Name" <> CompanyName() then
      Error(CompanyErr);
    Manager.LoadFrozenTargets(RunId, TempTargets);
    TempTargets.SetFilter(Quantity, '>0');
    if TempTargets.FindSet() then
      repeat
        NeedSales := NeedSales or (TempTargets.Module = "BCSF Module Type"::Sales);
        NeedPurchases := NeedPurchases or (TempTargets.Module = "BCSF Module Type"::Purchasing);
        NeedItems := NeedItems or (TempTargets.Entity = "BCSF Entity Type"::Item) or
          not (TempTargets.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor]);
        Posting := Posting or (TempTargets."Posted Percent" > 0) or (TempTargets."Partial Percent" > 0);
        CheckTargetSeries(TempTargets, Header."Starting Date", TempDiff);
      until TempTargets.Next() = 0;
    if CheckTable(Database::"General Ledger Setup", false, TempDiff) then begin
      LedgerSetup.FindFirst();
      CheckCondition(LedgerSetup.TableCaption() + ' / ' + LedgerSetup.FieldCaption("Amount Rounding Precision"),
        LedgerSetup."Amount Rounding Precision" > 0, TempDiff);
      CheckDimension(LedgerSetup."Global Dimension 1 Code", LedgerSetup.FieldCaption("Global Dimension 1 Code"), TempDiff);
      CheckDimension(LedgerSetup."Global Dimension 2 Code", LedgerSetup.FieldCaption("Global Dimension 2 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 3 Code", LedgerSetup.FieldCaption("Shortcut Dimension 3 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 4 Code", LedgerSetup.FieldCaption("Shortcut Dimension 4 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 5 Code", LedgerSetup.FieldCaption("Shortcut Dimension 5 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 6 Code", LedgerSetup.FieldCaption("Shortcut Dimension 6 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 7 Code", LedgerSetup.FieldCaption("Shortcut Dimension 7 Code"), TempDiff);
      CheckDimension(LedgerSetup."Shortcut Dimension 8 Code", LedgerSetup.FieldCaption("Shortcut Dimension 8 Code"), TempDiff);
      if Posting then
        CheckCondition(LedgerSetup.TableCaption() + ' / ' + LedgerSetup.FieldCaption("Allow Posting From"),
          ((LedgerSetup."Allow Posting From" = 0D) or (Header."Starting Date" >= LedgerSetup."Allow Posting From")) and
          ((LedgerSetup."Allow Posting To" = 0D) or (Header."Ending Date" <= LedgerSetup."Allow Posting To")), TempDiff);
    end;
    if NeedSales then begin
      CheckTable(Database::"Customer Posting Group", false, TempDiff);
      CheckTable(Database::Customer, true, TempDiff);
    end;
    if NeedPurchases then begin
      CheckTable(Database::"Vendor Posting Group", false, TempDiff);
      CheckTable(Database::Vendor, true, TempDiff);
    end;
    if NeedSales or NeedPurchases then
      CheckTable(Database::"Payment Terms", false, TempDiff);
    if NeedItems then begin
      CheckTable(Database::"Inventory Setup", false, TempDiff);
      CheckTable(Database::"Inventory Posting Group", false, TempDiff);
      CheckTable(Database::Item, true, TempDiff);
      if InventorySetup.ReadPermission() then
        if InventorySetup.FindFirst() then
          if InventorySetup."Location Mandatory" then
            CheckTable(Database::Location, false, TempDiff);
    end;
    if NeedSales or NeedPurchases or NeedItems then begin
      CheckTable(Database::"General Posting Setup", false, TempDiff);
      CheckTable(Database::"VAT Posting Setup", false, TempDiff);
    end;
    // Warehouse is only mandatory when explicitly enabled in the captured module selection.
    CheckWarehouse(RunId, TempDiff);
    OnInspectFinance(NeedSales, NeedPurchases, TempDiff);
    // Presence is never evidence that a particular generator's posting combination is valid.
    AddFinding(TempDiff, BindingLbl, true, BindingFindingLbl, BindingActionLbl);
    exit(not HasBlockers(TempDiff));
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Plan Writer", 'OnBeforeRunStart', '', false, false)]
  local procedure CheckStart(RunId: Guid)
  var
    TempDiff: Record "BCSF Setup Diff" temporary;
  begin
    if not BuildFromRun(RunId, TempDiff) then
      Error(BlockedErr);
  end;

  procedure HasBlockers(var TempDiff: Record "BCSF Setup Diff" temporary): Boolean
  var
    TempCheck: Record "BCSF Setup Diff" temporary;
  begin
    TempCheck.Copy(TempDiff, true);
    TempCheck.Reset();
    TempCheck.SetRange(Blocked, true);
    exit(not TempCheck.IsEmpty());
  end;

  local procedure CheckTable(TableId: Integer; NeedsWrite: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary): Boolean
  var
    Reference: RecordRef;
    Readable: Boolean;
    Present: Boolean;
  begin
    Reference.Open(TableId);
    Reference.SecurityFiltering(SecurityFilter::Filtered);
    Readable := Reference.ReadPermission();
    if Readable then
      Present := Reference.FindFirst();
    if not Readable then
      AddFinding(TempDiff, Reference.Caption, true, ReadPermissionLbl, PermissionActionLbl)
    else
      if NeedsWrite then
        AddFinding(TempDiff, Reference.Caption, not Reference.WritePermission(), WritePermissionLbl, PermissionActionLbl)
      else
        CheckCondition(Reference.Caption, Present, TempDiff);
    Reference.Close();
    exit(Readable and Present);
  end;

  local procedure CheckCondition(Requirement: Text; Valid: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  begin
    if Valid then
      AddFinding(TempDiff, Requirement, false, AvailableLbl, NoChangeLbl)
    else
      AddFinding(TempDiff, Requirement, true, MissingLbl, ReviewActionLbl);
  end;

  local procedure CheckDimension(DimensionCode: Code[20]; Requirement: Text; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Dimension: Record Dimension;
    Valid: Boolean;
  begin
    if DimensionCode = '' then
      exit;
    if not Dimension.ReadPermission() then begin
      AddFinding(TempDiff, Requirement, true, ReadPermissionLbl, PermissionActionLbl);
      exit;
    end;
    if Dimension.Get(DimensionCode) then
      Valid := not Dimension.Blocked;
    CheckCondition(Requirement, Valid, TempDiff);
  end;

  local procedure CheckWarehouse(RunId: Guid; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    TempModules: Record "BCSF Scenario Module" temporary;
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Manager.LoadFrozenModules(RunId, TempModules);
    TempModules.SetRange(Module, "BCSF Module Type"::Warehouse);
    TempModules.SetRange(Enabled, true);
    if not TempModules.IsEmpty() then
      CheckTable(Database::"Warehouse Setup", false, TempDiff);
  end;

  local procedure CheckTargetSeries(Target: Record "BCSF Data Target" temporary; StartingDate: Date; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    SalesSetup: Record "Sales & Receivables Setup";
    PurchaseSetup: Record "Purchases & Payables Setup";
    InventorySetup: Record "Inventory Setup";
    TableId: Integer;
    FieldNo: Integer;
    PostedFieldNo: Integer;
    ReceiptFieldNo: Integer;
  begin
    case Target.Entity of
      "BCSF Entity Type"::Customer:
        begin
          TableId := Database::"Sales & Receivables Setup";
          FieldNo := SalesSetup.FieldNo("Customer Nos.");
        end;
      "BCSF Entity Type"::Vendor:
        begin
          TableId := Database::"Purchases & Payables Setup";
          FieldNo := PurchaseSetup.FieldNo("Vendor Nos.");
        end;
      "BCSF Entity Type"::Item:
        begin
          TableId := Database::"Inventory Setup";
          FieldNo := InventorySetup.FieldNo("Item Nos.");
        end;
      "BCSF Entity Type"::SalesQuote:
        begin
          TableId := Database::"Sales & Receivables Setup";
          FieldNo := SalesSetup.FieldNo("Quote Nos.");
        end;
      "BCSF Entity Type"::SalesOrder:
        begin
          TableId := Database::"Sales & Receivables Setup";
          FieldNo := SalesSetup.FieldNo("Order Nos.");
          PostedFieldNo := SalesSetup.FieldNo("Posted Invoice Nos.");
          ReceiptFieldNo := SalesSetup.FieldNo("Posted Shipment Nos.");
        end;
      "BCSF Entity Type"::SalesInvoice:
        begin
          TableId := Database::"Sales & Receivables Setup";
          FieldNo := SalesSetup.FieldNo("Invoice Nos.");
          PostedFieldNo := SalesSetup.FieldNo("Posted Invoice Nos.");
        end;
      "BCSF Entity Type"::SalesCreditMemo:
        begin
          TableId := Database::"Sales & Receivables Setup";
          FieldNo := SalesSetup.FieldNo("Credit Memo Nos.");
          PostedFieldNo := SalesSetup.FieldNo("Posted Credit Memo Nos.");
        end;
      "BCSF Entity Type"::PurchaseOrder:
        begin
          TableId := Database::"Purchases & Payables Setup";
          FieldNo := PurchaseSetup.FieldNo("Order Nos.");
          PostedFieldNo := PurchaseSetup.FieldNo("Posted Invoice Nos.");
          ReceiptFieldNo := PurchaseSetup.FieldNo("Posted Receipt Nos.");
        end;
      "BCSF Entity Type"::PurchaseInvoice:
        begin
          TableId := Database::"Purchases & Payables Setup";
          FieldNo := PurchaseSetup.FieldNo("Invoice Nos.");
          PostedFieldNo := PurchaseSetup.FieldNo("Posted Invoice Nos.");
        end;
      "BCSF Entity Type"::PurchaseCreditMemo:
        begin
          TableId := Database::"Purchases & Payables Setup";
          FieldNo := PurchaseSetup.FieldNo("Credit Memo Nos.");
          PostedFieldNo := PurchaseSetup.FieldNo("Posted Credit Memo Nos.");
        end;
      else Error(TargetErr);
    end;
    CheckSeries(TableId, FieldNo, StartingDate, TempDiff);
    if (Target."Posted Percent" > 0) or (Target."Partial Percent" > 0) then begin
      if PostedFieldNo <> 0 then
        CheckSeries(TableId, PostedFieldNo, StartingDate, TempDiff);
      if ReceiptFieldNo <> 0 then
        CheckSeries(TableId, ReceiptFieldNo, StartingDate, TempDiff);
    end;
    if not (Target.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]) then
      if Target.Module = "BCSF Module Type"::Sales then
        CheckTable(Database::"Sales Header", true, TempDiff)
      else
        CheckTable(Database::"Purchase Header", true, TempDiff);
  end;

  local procedure CheckSeries(TableId: Integer; FieldNo: Integer; StartingDate: Date; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Series: Record "No. Series";
    Line: Record "No. Series Line";
    Reference: RecordRef;
    SeriesField: FieldRef;
    SeriesCode: Code[20];
    Requirement: Text;
    Valid: Boolean;
    Selected: Boolean;
    SelectedDate: Date;
  begin
    if not CheckTable(TableId, false, TempDiff) then
      exit;
    Reference.Open(TableId);
    Reference.FindFirst();
    SeriesField := Reference.Field(FieldNo);
    Requirement := Reference.Caption + ' / ' + SeriesField.Caption;
    SeriesCode := SeriesField.Value;
    Reference.Close();
    if not Series.ReadPermission() or not Line.ReadPermission() then begin
      AddFinding(TempDiff, Requirement, true, ReadPermissionLbl, PermissionActionLbl);
      exit;
    end;
    SelectedDate := 0D;
    if Series.Get(SeriesCode) then
      if Series."Default Nos." then begin
        Line.SetRange("Series Code", SeriesCode);
        Line.SetFilter("Starting Date", '..%1', StartingDate);
        if Line.FindSet() then
          repeat
            if not Selected or (Line."Starting Date" >= SelectedDate) then begin
              Selected := true;
              SelectedDate := Line."Starting Date";
              Valid := Line.Open and (Line."Starting No." <> '') and (Line."Increment-by No." > 0);
            end;
          until Line.Next() = 0;
      end;
    CheckCondition(Requirement, Valid, TempDiff);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnInspectFinance(NeedSales: Boolean; NeedPurchases: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  begin
  end;

  procedure AddFinding(var TempDiff: Record "BCSF Setup Diff" temporary; Requirement: Text; Blocked: Boolean; Finding: Text; ProposedAction: Text)
  var
    EntryNo: Integer;
  begin
    TempDiff.Reset();
    if TempDiff.FindLast() then
      EntryNo := TempDiff."Entry No.";
    TempDiff.Init();
    TempDiff."Entry No." := EntryNo + 1;
    TempDiff.Requirement := CopyStr(Requirement, 1, MaxStrLen(TempDiff.Requirement));
    TempDiff.Blocked := Blocked;
    TempDiff.Finding := CopyStr(Finding, 1, MaxStrLen(TempDiff.Finding));
    TempDiff.Action := CopyStr(ProposedAction, 1, MaxStrLen(TempDiff.Action));
    TempDiff.Insert();
  end;

  var
    BlockedErr: Label 'Setup preflight is blocked. Review the current setup diff and resolve every required action before execution.';
    CompanyErr: Label 'Review this run in its captured company.';
    TargetErr: Label 'The captured entity is not supported by setup preflight.';
    ReadPermissionLbl: Label 'Read permission is missing.';
    WritePermissionLbl: Label 'Effective write permission checked; no write was attempted.';
    PermissionActionLbl: Label 'Have an administrator review the required permissions, license and security filters. No rights are elevated.';
    AvailableLbl: Label 'Visible prerequisite found. Generator-specific validation is still required.';
    NoChangeLbl: Label 'Retain existing setup.';
    MissingLbl: Label 'Required setup is missing, blocked, outside the date range or not visible.';
    ReviewActionLbl: Label 'Review this requirement in standard BC setup. Obtain explicit approval before any manual change, then rerun preflight.';
    BindingLbl: Label 'Generator-specific setup bindings';
    BindingFindingLbl: Label 'Posting group combinations, accounts, tax context, dimension values, stock and posting permissions are not yet validated for a real generator.';
    BindingActionLbl: Label 'Keep execution blocked until the selected generator validates its exact setup and effective execution permissions. Acknowledge no automatic setup change.';
}
