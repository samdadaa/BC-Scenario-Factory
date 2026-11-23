namespace BCScenarioFactory.Finance;

using BCScenarioFactory.SetupManager;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 90402 "BCSF Finance Setup Check"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Setup Manager", 'OnInspectFinance', '', false, false)]
  local procedure InspectFinance(NeedSales: Boolean; NeedPurchases: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  begin
    Inspect(NeedSales, NeedPurchases, TempDiff);
  end;

  procedure Inspect(NeedSales: Boolean; NeedPurchases: Boolean; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    CustomerGroup: Record "Customer Posting Group";
    VendorGroup: Record "Vendor Posting Group";
  begin
    if NeedSales then
      CheckAccounts(Database::"Customer Posting Group", CustomerGroup.FieldNo("Receivables Account"), TempDiff);
    if NeedPurchases then
      CheckAccounts(Database::"Vendor Posting Group", VendorGroup.FieldNo("Payables Account"), TempDiff);
  end;

  /// <summary>Read-only candidates for domestic trade; never repairs unrelated rows.</summary>
  procedure InspectTradeSetup(var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    GeneralMatrix: Record "General Posting Setup";
    VATMatrix: Record "VAT Posting Setup";
    InventoryMatrix: Record "Inventory Posting Setup";
    Fields: List of [Integer];
  begin
    Fields.Add(GeneralMatrix.FieldNo("Sales Account"));
    Fields.Add(GeneralMatrix.FieldNo("Purch. Account"));
    CheckMatrix(Database::"General Posting Setup", Fields, GeneralMatrix.FieldNo(Blocked), TempDiff);
    Clear(Fields);
    Fields.Add(VATMatrix.FieldNo("Sales VAT Account"));
    Fields.Add(VATMatrix.FieldNo("Purchase VAT Account"));
    CheckMatrix(Database::"VAT Posting Setup", Fields, VATMatrix.FieldNo(Blocked), TempDiff);
    Clear(Fields);
    Fields.Add(InventoryMatrix.FieldNo("Inventory Account"));
    CheckMatrix(Database::"Inventory Posting Setup", Fields, 0, TempDiff);
  end;

  local procedure CheckMatrix(TableId: Integer; AccountFields: List of [Integer]; BlockedField: Integer; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Account: Record "G/L Account";
    Manager: Codeunit "BCSF Setup Manager";
    Rows: RecordRef;
    Value: FieldRef;
    FieldNo: Integer;
    AccountNo: Code[20];
    Usable: Boolean;
    HasCandidate: Boolean;
    Blocked: Boolean;
  begin
    Rows.Open(TableId);
    Rows.SecurityFiltering(SecurityFilter::Disallowed);
    Account.SecurityFiltering(SecurityFilter::Disallowed);
    if not Rows.ReadPermission() or not Account.ReadPermission() then begin
      Manager.AddFinding(TempDiff, Rows.Caption(), true, PermissionLbl, ActionLbl);
      Rows.Close();
      exit;
    end;
    if Rows.FindSet() then
      repeat
        Usable := true;
        if BlockedField <> 0 then begin
          Value := Rows.Field(BlockedField);
          Blocked := Value.Value;
          Usable := not Blocked;
        end;
        foreach FieldNo in AccountFields do begin
          Value := Rows.Field(FieldNo);
          AccountNo := Value.Value;
          if not Account.Get(AccountNo) then
            Usable := false
          else
            Usable := Usable and not Account.Blocked and (Account."Account Type" = Account."Account Type"::Posting);
        end;
        HasCandidate := HasCandidate or Usable;
      until Rows.Next() = 0;
    Manager.AddFinding(TempDiff, Rows.Caption(), not HasCandidate, MatrixLbl, ActionLbl);
    Rows.Close();
  end;

  local procedure CheckAccounts(TableId: Integer; AccountFieldNo: Integer; var TempDiff: Record "BCSF Setup Diff" temporary)
  var
    Account: Record "G/L Account";
    Manager: Codeunit "BCSF Setup Manager";
    Groups: RecordRef;
    AccountField: FieldRef;
    GroupCodeField: FieldRef;
    AccountNo: Code[20];
    Requirement: Text;
    HasCandidate: Boolean;
    Valid: Boolean;
  begin
    Groups.Open(TableId);
    Groups.SecurityFiltering(SecurityFilter::Filtered);
    Requirement := Groups.Caption;
    if not Groups.ReadPermission() or not Account.ReadPermission() then begin
      Manager.AddFinding(TempDiff, Requirement, true, PermissionLbl, ActionLbl);
      Groups.Close();
      exit;
    end;
    if Groups.FindSet() then
      repeat
        AccountField := Groups.Field(AccountFieldNo);
        GroupCodeField := Groups.Field(1);
        AccountNo := AccountField.Value;
        Valid := false;
        if Account.Get(AccountNo) then
          Valid := not Account.Blocked and (Account."Account Type" = Account."Account Type"::Posting);
        HasCandidate := HasCandidate or Valid;
        if not Valid then
          // Unselected candidates are informational; never force a change to an unrelated posting group.
          Manager.AddFinding(TempDiff, Requirement + ' / ' + Format(GroupCodeField.Value) + ' / ' + AccountField.Caption,
            false, InvalidAccountLbl, ActionLbl);
      until Groups.Next() = 0;
    if HasCandidate then
      Manager.AddFinding(TempDiff, Requirement, false, CandidateLbl, ActionLbl)
    else
      Manager.AddFinding(TempDiff, Requirement, true, NoCandidateLbl, ActionLbl);
    Groups.Close();
  end;

  var
    MatrixLbl: Label 'Domestic trade requires at least one unblocked posting combination with usable G/L accounts in this table. Exact document and tax combinations must also be reviewed before posting.';
    PermissionLbl: Label 'Posting groups or G/L accounts cannot be read with the current effective permissions.';
    InvalidAccountLbl: Label 'This candidate references an empty, missing, blocked or non-posting G/L account. It must not be selected.';
    NoCandidateLbl: Label 'No visible posting group has a usable receivables or payables account. Execution is blocked.';
    CandidateLbl: Label 'Checked for at least one visible posting group with an unblocked posting account. Exact generator binding remains mandatory.';
    ActionLbl: Label 'Review the exact posting group and account in BC. Retain unrelated configuration; obtain approval before changes and rerun preflight.';
}
