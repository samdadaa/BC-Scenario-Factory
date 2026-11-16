namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.ScenarioManagement;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 90252 "BCSF Record Registry"
{
  Access = Internal;
  Permissions = tabledata "BCSF Generated Record" = I;

  /// <summary>Register in the same transaction as creation. Never commits or creates the target record.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure RegisterResult(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; ArtifactCode: Code[30]; BatchId: Guid; TargetId: RecordId; ParentEntryId: Guid): Guid
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    Entry: Record "BCSF Generated Record";
    Target: RecordRef;
    SystemIdField: FieldRef;
    TargetSystemId: Guid;
  begin
    Header.LockTable();
    Header.Get(RunId);
    Step.Get(RunId, NodeCode);
    if not IsAllowedTable(TargetId.TableNo()) then
      Error(TargetErr);
    if not Target.Get(TargetId) then
      Error(TargetErr);
    if Target.IsTemporary() then
      Error(TargetErr);
    SystemIdField := Target.Field(Target.SystemIdNo());
    TargetSystemId := SystemIdField.Value;
    Target.Close();
    if Entry.Get(RunId, NodeCode, LogicalKey, ArtifactCode) then begin
      if (Entry."Table Id" <> TargetId.TableNo()) or (Entry."Record SystemId" <> TargetSystemId) or
        (Entry."Batch Id" <> BatchId) or (Entry."Parent Entry Id" <> ParentEntryId) or
        (Entry."Generator Code" <> Step."Generator Code") or (Entry."Generator Version" <> Step."Generator Version")
      then
        Error(DuplicateErr);
      exit(Entry."Entry Id");
    end;
    Entry.Init();
    Entry."Run Id" := RunId;
    Entry."Node Code" := NodeCode;
    Entry."Logical Key" := LogicalKey;
    Entry."Artifact Code" := ArtifactCode;
    Entry."Entry Id" := CreateGuid();
    Entry."Batch Id" := BatchId;
    Entry."Generator Code" := Step."Generator Code";
    Entry."Generator Version" := Step."Generator Version";
    Entry."Table Id" := TargetId.TableNo();
    Entry."Record SystemId" := TargetSystemId;
    Entry."Record Id" := TargetId;
    Entry."Parent Entry Id" := ParentEntryId;
    Entry."Created At" := CurrentDateTime();
    Entry.Insert(true);
    exit(Entry."Entry Id");
  end;

  procedure CheckEntry(Entry: Record "BCSF Generated Record")
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    Parent: Record "BCSF Generated Record";
    Target: RecordRef;
    SystemIdField: FieldRef;
    TargetSystemId: Guid;
  begin
    if Entry.CurrentCompany() <> CompanyName() then
      Error(TargetErr);
    Header.LockTable();
    Header.Get(Entry."Run Id");
    Header.TestField("Company Name", CompanyName());
    Step.Get(Entry."Run Id", Entry."Node Code");
    Step.TestField("Generator Code", Entry."Generator Code");
    Step.TestField("Generator Version", Entry."Generator Version");
    Entry.TestField("Entry Id");
    Entry.TestField("Batch Id");
    Entry.TestField("Artifact Code");
    Entry.TestField("Created At");
    if (Entry."Logical Key" <= 0) or (Entry."Logical Key" > Step."Work Units") or
      not IsAllowedTable(Entry."Table Id") or (Entry."Record Id".TableNo() <> Entry."Table Id")
    then
      Error(TargetErr);
    if not Target.Get(Entry."Record Id") then
      Error(TargetErr);
    SystemIdField := Target.Field(Target.SystemIdNo());
    TargetSystemId := SystemIdField.Value;
    Target.Close();
    if IsNullGuid(TargetSystemId) or (TargetSystemId <> Entry."Record SystemId") then
      Error(TargetErr);
    if not IsNullGuid(Entry."Parent Entry Id") then begin
      Parent.SetRange("Entry Id", Entry."Parent Entry Id");
      if not Parent.FindFirst() then
        Error(ParentErr);
      Parent.TestField("Run Id", Entry."Run Id");
      if Parent."Entry Id" = Entry."Entry Id" then
        Error(ParentErr);
    end;
    OnCheckBatch(Entry);
  end;

  /// <summary>Resolve by stable identity; never silently fall back to a reused record key.</summary>
  procedure ExistsByIdentity(Entry: Record "BCSF Generated Record"): Boolean
  var
    Target: RecordRef;
    Found: Boolean;
  begin
    if Entry.CurrentCompany() <> CompanyName() then
      Error(TargetErr);
    if not IsAllowedTable(Entry."Table Id") or IsNullGuid(Entry."Record SystemId") then
      exit(false);
    Target.Open(Entry."Table Id");
    Found := Target.GetBySystemId(Entry."Record SystemId");
    Target.Close();
    exit(Found);
  end;

  local procedure IsAllowedTable(TableId: Integer): Boolean
  begin
    exit(TableId in [Database::Customer, Database::Vendor, Database::Item,
      Database::"Sales Header", Database::"Purchase Header", Database::"Sales Invoice Header",
      Database::"Sales Cr.Memo Header", Database::"Sales Shipment Header", Database::"Purch. Inv. Header",
      Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Rcpt. Header", Database::"Cust. Ledger Entry",
      Database::"Vendor Ledger Entry", Database::"G/L Entry", Database::"VAT Entry",
      Database::"Item Ledger Entry", Database::"Value Entry"]);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnCheckBatch(Entry: Record "BCSF Generated Record")
  begin
  end;

  var
    TargetErr: Label 'Register an existing supported standard result in the current run company with a valid logical key and stable SystemId.';
    DuplicateErr: Label 'This logical result already refers to a different artifact, batch or parent. Do not create or post it again; review its provenance.';
    ParentErr: Label 'Select an existing parent result from the same run. Provenance cannot reference itself.';
}
