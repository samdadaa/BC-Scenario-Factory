namespace BCScenarioFactory.Sales;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 90431 "BCSF Sales Evidence"
{
  Access = Internal;

  procedure RegisterPosting(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; Shipment: Record "Sales Shipment Header"; ParentId: Guid)
  var
    CustomerEntry: Record "Cust. Ledger Entry";
    GL: Record "G/L Entry";
    VAT: Record "VAT Entry";
    ItemEntry: Record "Item Ledger Entry";
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    Registry: Codeunit "BCSF Record Registry";
  begin
    CustomerEntry.Get(Invoice."Cust. Ledger Entry No.");
    CustomerEntry.TestField("Document No.", Invoice."No.");
    CustomerEntry.TestField("Customer No.", Invoice."Bill-to Customer No.");
    CustomerEntry.TestField(Open, true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CUSTOMER-ENTRY', BatchId, CustomerEntry.RecordId(), ParentId);
    GL.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    GL.SetRange("Document No.", Invoice."No.");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
    VAT.SetRange("Transaction No.", CustomerEntry."Transaction No.");
    VAT.SetRange("Document No.", Invoice."No.");
    if VAT.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VAT', VAT."Entry No."), BatchId, VAT.RecordId(), ParentId);
      until VAT.Next() = 0;
    if Shipment."No." <> '' then begin
      ItemEntry.SetRange("Document No.", Shipment."No.");
      ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Sales Shipment");
    end else begin
      ItemEntry.SetRange("Document No.", Invoice."No.");
      ItemEntry.SetRange("Document Type", ItemEntry."Document Type"::"Sales Invoice");
    end;
    ItemEntry.SetRange("Source Type", ItemEntry."Source Type"::Customer);
    ItemEntry.SetRange("Source No.", Invoice."Sell-to Customer No.");
    if not ItemEntry.FindSet() then
      Error(EvidenceErr);
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ITEM', ItemEntry."Entry No."), BatchId, ItemEntry.RecordId(), ParentId);
      Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
      if Value.FindSet() then
        repeat
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('VALUE', Value."Entry No."), BatchId, Value.RecordId(), ParentId);
          Relation.SetRange("Value Entry No.", Value."Entry No.");
          if Relation.FindSet() then
            repeat
              GL.Get(Relation."G/L Entry No.");
              Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
            until Relation.Next() = 0;
        until Value.Next() = 0;
    until ItemEntry.Next() = 0;
  end;

  local procedure Artifact(Prefix: Code[10]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    EvidenceErr: Label 'Sales posting did not produce the expected customer, inventory and accounting evidence. Keep the batch blocked for review.';
}
