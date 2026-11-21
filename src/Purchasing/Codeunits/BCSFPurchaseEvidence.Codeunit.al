namespace BCScenarioFactory.Purchasing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 90454 "BCSF Purchase Evidence"
{
  Access = Internal;

  procedure RegisterPosting(RunId: Guid; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Receipt: Record "Purch. Rcpt. Header"; ParentId: Guid)
  var
    VendorEntry: Record "Vendor Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    ItemEntry: Record "Item Ledger Entry";
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    Registry: Codeunit "BCSF Record Registry";
  begin
    VendorEntry.Get(Invoice."Vendor Ledger Entry No.");
    VendorEntry.TestField("Document No.", Invoice."No.");
    VendorEntry.TestField("Vendor No.", Invoice."Pay-to Vendor No.");
    VendorEntry.TestField(Open, true);
    Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, 'VENDOR-ENTRY', BatchId, VendorEntry.RecordId(), ParentId);
    GL.SetRange("Transaction No.", VendorEntry."Transaction No.");
    GL.SetRange("Document No.", Invoice."No.");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", VendorEntry."Transaction No.");
    VAT.SetRange("Document No.", Invoice."No.");
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, Artifact('VAT', VAT."Entry No."), BatchId, VAT.RecordId(), ParentId);
      until VAT.Next() = 0;
    if Receipt."No." <> '' then begin
      ItemEntry.SetRange("Document No.", Receipt."No.");
      ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Purchase Receipt");
    end else begin
      ItemEntry.SetRange("Document No.", Invoice."No.");
      ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Purchase Invoice");
    end;
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Vendor);
    ItemEntry.SetRange("Source No.", Invoice."Buy-from Vendor No.");
    if not ItemEntry.FindSet() then
      Error(EvidenceErr);
    repeat
      Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, Artifact('ITEM', ItemEntry."Entry No."), BatchId, ItemEntry.RecordId(), ParentId);
      Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
      if Value.FindSet() then
        repeat
          Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, Artifact('VALUE', Value."Entry No."), BatchId, Value.RecordId(), ParentId);
          Relation.SetRange("Value Entry No.", Value."Entry No.");
          if Relation.FindSet() then
            repeat
              GL.Get(Relation."G/L Entry No.");
              Registry.RegisterResult(RunId, 'PURCHASE.ORDER', LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
            until Relation.Next() = 0;
        until Value.Next() = 0;
    until ItemEntry.Next() = 0;
  end;

  local procedure Artifact(Prefix: Code[10]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    EvidenceErr: Label 'Purchase posting did not produce the expected vendor, inventory and accounting evidence. Keep the batch blocked for review.';
}
