namespace BCScenarioFactory.SetupManager;

using BCScenarioFactory.Core;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.ModuleRegistry;
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
    TempModules: Record "BCSF Scenario Module" temporary;
    LedgerSetup: Record "General Ledger Setup";
    InventorySetup: Record "Inventory Setup";
    Location: Record Location;
    Manager: Codeunit "BCSF Scenario Manager";
    Policy: Codeunit "BCSF Scenario Policy";
    Context: JsonObject;
    NeedSales: Boolean;
    NeedPurchases: Boolean;
    NeedItems: Boolean;
    Posting: Boolean;
    PartnersOnly: Boolean;
    NeedDocuments: Boolean;
    WarehouseRequired: Boolean;
    UnpostedCount: Integer;
    PostedCount: Integer;
    PartialCount: Integer;
  begin
    TempDiff.Reset();
    TempDiff.DeleteAll();
    Manager.ReadSnapshot(RunId, Context);
    Header.Get(RunId);
    if Header."Company Name" <> CompanyName() then
      Error(CompanyErr);
    Manager.LoadFrozenTargets(RunId, TempTargets);
    Manager.LoadFrozenModules(RunId, TempModules);
    PartnersOnly := true;
    TempTargets.SetFilter(Quantity, '>0');
    if TempTargets.FindSet() then
      repeat
        PartnersOnly := PartnersOnly and (TempTargets.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item, "BCSF Entity Type"::SalesQuote, "BCSF Entity Type"::SalesOrder, "BCSF Entity Type"::SalesInvoice]);
        NeedSales := NeedSales or (TempTargets.Module = "BCSF Module Type"::Sales);
        NeedPurchases := NeedPurchases or (TempTargets.Module = "BCSF Module Type"::Purchasing);
        NeedDocuments := NeedDocuments or Policy.IsDocument(TempTargets.Entity);
        NeedItems := NeedItems or (TempTargets.Entity = "BCSF Entity Type"::Item) or Policy.IsDocument(TempTargets.Entity);
        Policy.GetDistribution(TempTargets, UnpostedCount, PostedCount, PartialCount);
        Posting := Posting or (PostedCount > 0) or (PartialCount > 0);
        // The executable partner generators validate their exact frozen series, not an unrelated default.
        if not (TempTargets.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]) then
          CheckTargetSeries(TempTargets, Header."Starting Date", (PostedCount > 0) or (PartialCount > 0), TempDiff);
      until TempTargets.Next() = 0;
    if CheckTable(Database::"General Ledger Setup", false, TempDiff) then begin
      LedgerSetup.FindFirst();
      CheckCondition(LedgerSetup.TableCaption() + ' / ' + LedgerSetup.FieldCaption("Amount Rounding Precision"),
        LedgerSetup."Amount Rounding Precision" > 0, TempDiff);
      if not PartnersOnly then begin
        CheckDimension(LedgerSetup."Global Dimension 1 Code", LedgerSetup.FieldCaption("Global Dimension 1 Code"), TempDiff);
        CheckDimension(LedgerSetup."Global Dimension 2 Code", LedgerSetup.FieldCaption("Global Dimension 2 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 3 Code", LedgerSetup.FieldCaption("Shortcut Dimension 3 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 4 Code", LedgerSetup.FieldCaption("Shortcut Dimension 4 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 5 Code", LedgerSetup.FieldCaption("Shortcut Dimension 5 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 6 Code", LedgerSetup.FieldCaption("Shortcut Dimension 6 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 7 Code", LedgerSetup.FieldCaption("Shortcut Dimension 7 Code"), TempDiff);
        CheckDimension(LedgerSetup."Shortcut Dimension 8 Code", LedgerSetup.FieldCaption("Shortcut Dimension 8 Code"), TempDiff);
      end;
      if Posting then
        CheckCondition(LedgerSetup.TableCaption() + ' / ' + LedgerSetup.FieldCaption("Allow Posting From"),
          ((LedgerSetup."Allow Posting From" = 0D) or (Header."Starting Date" >= LedgerSetup."Allow Posting From")) and
          ((LedgerSetup."Allow Posting To" = 0D) or (Header."Ending Date" <= LedgerSetup."Allow Posting To")), TempDiff);
    end;
    if NeedItems then begin
      CheckTable(Database::"Inventory Setup", false, TempDiff);
      CheckTable(Database::"Inventory Posting Group", false, TempDiff);
      WarehouseRequired := HasWarehouseScope(TempModules);
      if WarehouseRequired then
        CheckTable(Database::"Warehouse Setup", false, TempDiff);
      InventorySetup.SecurityFiltering(SecurityFilter::Filtered);
      if InventorySetup.ReadPermission() then
        if InventorySetup.FindFirst() then
          WarehouseRequired := WarehouseRequired or InventorySetup."Location Mandatory";
      if WarehouseRequired then begin
        Location.SecurityFiltering(SecurityFilter::Filtered);
        Location.SetRange("Use As In-Transit", false);
        if Location.ReadPermission() then
          CheckCondition(Location.TableCaption(), not Location.IsEmpty(), TempDiff)
        else
          AddFinding(TempDiff, Location.TableCaption(), true, ReadPermissionLbl, PermissionActionLbl);
      end;
    end;
    if NeedDocuments then begin
      CheckPostingCandidates(Context, TempDiff);
      OnInspectFinance(NeedSales, NeedPurchases, TempDiff);
    end;
    OnInspectFinancePackage(Context, Header."Starting Date", TempDiff);
    CheckGeneratorBindings(Context, TempTargets, TempModules, TempDiff);
    // Planning-only profiles do not get a green setup report merely because broad candidates exist.
    if not PartnersOnly then
      AddFinding(TempDiff, BindingLbl, true, BindingFindingLbl, BindingActionLbl);
    exit(not HasBlockers(TempDiff));
  end;

  local procedure CheckPostingCandidates(Context: JsonObject; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    GeneralMatrix: Record "General Posting Setup";
    VATMatrix: Record "VAT Posting Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
    GroupCode: Code[20];
  begin
    GeneralMatrix.SecurityFiltering(SecurityFilter::Filtered);
    VATMatrix.SecurityFiltering(SecurityFilter::Filtered);
    GeneralMatrix.SetRange(Blocked, false);
    VATMatrix.SetRange(Blocked, false);
    if Context.Get('partnerSetup', Token) then begin
      Settings := Token.AsObject();
      GroupCode := CopyStr(Contract.GetText(Settings, 'genBusPostingGroup'), 1, MaxStrLen(GroupCode));
      if GroupCode <> '' then
        GeneralMatrix.SetRange("Gen. Bus. Posting Group", GroupCode);
      GroupCode := CopyStr(Contract.GetText(Settings, 'vatBusPostingGroup'), 1, MaxStrLen(GroupCode));
      if GroupCode <> '' then
        VATMatrix.SetRange("VAT Bus. Posting Group", GroupCode);
    end;
    if GeneralMatrix.ReadPermission() then
      CheckCondition(GeneralMatrix.TableCaption(), not GeneralMatrix.IsEmpty(), TempDiff)
    else
      AddFinding(TempDiff, GeneralMatrix.TableCaption(), true, ReadPermissionLbl, PermissionActionLbl);
    if VATMatrix.ReadPermission() then
      CheckCondition(VATMatrix.TableCaption(), not VATMatrix.IsEmpty(), TempDiff)
    else
      AddFinding(TempDiff, VATMatrix.TableCaption(), true, ReadPermissionLbl, PermissionActionLbl);
  end;

  local procedure CheckGeneratorBindings(Context: JsonObject; var TempTargets: Record "BCSF Data Target" temporary; var TempModules: Record "BCSF Scenario Module" temporary; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Planner: Codeunit "BCSF Dependency Planner";
    Policy: Codeunit "BCSF Scenario Policy";
    Contract: Codeunit "BCSF Contract JSON";
    Generator: Interface "BCSF Generator";
    Target: JsonObject;
    Findings: JsonArray;
    Token: JsonToken;
    EntityCode: Code[30];
    ModuleCode: Code[30];
  begin
    TempTargets.Reset();
    TempTargets.SetFilter(Quantity, '>0');
    if not TempTargets.FindSet() then begin
      AddFinding(TempDiff, BindingLbl, true, TargetErr, BindingActionLbl);
      exit;
    end;
    repeat
      EntityCode := Policy.GetEntityCode(TempTargets.Entity);
      ModuleCode := Policy.GetModuleCode(TempTargets.Module);
      if not Planner.IsModuleEnabled(TempModules, ModuleCode) then
        AddFinding(TempDiff, Format(TempTargets.Entity), true, TargetErr, BindingActionLbl)
      else
        if Registry.SelectForTarget(EntityCode, TempTargets."Process Mode", false, TempCapability) then
          if (TempCapability."Module Code" <> ModuleCode) or
            (Contract.GetInteger(Context, 'batchSize') > TempCapability."Maximum Batch Size")
          then
            AddFinding(TempDiff, Format(TempTargets.Entity), true, TargetErr, BindingActionLbl)
          else begin
            Clear(Target);
            Target.Add('entityCode', EntityCode);
            Target.Add('moduleCode', ModuleCode);
            Target.Add('quantity', TempTargets.Quantity);
            Target.Add('processMode', TempTargets."Process Mode".AsInteger());
            Generator := Registry.Resolve(TempCapability."Generator Code", EntityCode, TempCapability);
            Clear(Findings);
            Generator.CheckPrerequisites(Contract.Clone(Context), Contract.Clone(Target), Findings);
            if Findings.Count() = 0 then
              AddFinding(TempDiff, TempCapability.Name, false, GeneratorReadyLbl, GeneratorActionLbl)
            else
              foreach Token in Findings do
                AddFinding(TempDiff, TempCapability.Name, true, Contract.GetText(Token.AsObject(), 'message'), BindingActionLbl);
          end
        else
          AddFinding(TempDiff, Format(TempTargets.Entity), true, MissingGeneratorLbl, BindingActionLbl);
    until TempTargets.Next() = 0;
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Plan Writer", 'OnBeforeRunStart', '', false, false)]
  local procedure CheckStart(RunId: Guid)
  var
    TempDiff: Record "BCSF Setup Diff" temporary;
  begin
    if not BuildFromRun(RunId, TempDiff) then begin
      TempDiff.Reset();
      TempDiff.SetRange(Blocked, true);
      if TempDiff.FindFirst() then
        Error(BlockedErr, TempDiff.Requirement, TempDiff.Finding, TempDiff.Action);
      Error(TargetErr);
    end;
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

  local procedure HasWarehouseScope(var TempModules: Record "BCSF Scenario Module" temporary): Boolean
  begin
    TempModules.Reset();
    TempModules.SetRange(Module, "BCSF Module Type"::Warehouse);
    TempModules.SetRange(Enabled, true);
    exit(not TempModules.IsEmpty());
  end;

  local procedure CheckTargetSeries(Target: Record "BCSF Data Target" temporary; StartingDate: Date; Posting: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
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
    if Posting then begin
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

  [IntegrationEvent(false, false)]
  local procedure OnInspectFinancePackage(Context: JsonObject; EffectiveDate: Date; var TempDiff: Record "BCSF Setup Diff" temporary)
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
    BlockedErr: Label 'Cannot start: %1. %2 %3', Comment = '%1 = requirement, %2 = reason, %3 = next action';
    CompanyErr: Label 'Review this run in its captured company.';
    TargetErr: Label 'No eligible work or the captured module, entity or batch size is incompatible.';
    MissingGeneratorLbl: Label 'No executable generator for the selected process mode. This target remains planning-only.';
    GeneratorReadyLbl: Label 'Will be generated. Current generator prerequisites passed.';
    GeneratorActionLbl: Label 'The background job checks these prerequisites again before writing records.';
    ReadPermissionLbl: Label 'Read permission is missing.';
    WritePermissionLbl: Label 'Effective write permission checked; no write was attempted.';
    PermissionActionLbl: Label 'Have an administrator review the required permissions, license and security filters. No rights are elevated.';
    AvailableLbl: Label 'Already present. Exact generator prerequisites are checked separately.';
    NoChangeLbl: Label 'Retain existing setup.';
    MissingLbl: Label 'Required setup is missing, blocked, outside the date range or not visible.';
    ReviewActionLbl: Label 'Review this requirement in standard BC setup. Obtain explicit approval before any manual change, then rerun preflight.';
    BindingLbl: Label 'Generator-specific setup bindings';
    BindingFindingLbl: Label 'Posting group combinations, accounts, tax context, dimension values, stock and posting permissions are not yet validated for a real generator.';
    BindingActionLbl: Label 'Review the named prerequisite and capture a new run after correction. Use partner master data only if the selected process has no executable generator.';
}
