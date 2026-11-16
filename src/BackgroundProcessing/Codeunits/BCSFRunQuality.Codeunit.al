namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Validation;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 90317 "BCSF Run Quality"
{
  Access = Internal;

  [CommitBehavior(CommitBehavior::Error)]
  procedure FinalizeRun(var Execution: Record "BCSF Run Execution")
  var
    Batch: Record "BCSF Batch";
    Validation: Codeunit "BCSF Validation Manager";
    Severity: Enum "BCSF Validation Severity";
    BatchSeverity: Enum "BCSF Validation Severity";
    WarningCodes: List of [Code[30]];
    WarningCode: Code[30];
    NoBatch: Guid;
  begin
    Batch.SetRange("Run Id", Execution."Run Id");
    if (Execution."Total Batches" <= 0) or (Batch.Count() <> Execution."Total Batches") or
      (Execution."Completed Batches" <> Execution."Total Batches")
    then
      Error(BatchCountErr);
    Severity := Severity::Passed;
    if Batch.FindSet() then
      repeat
        BatchSeverity := BatchSeverity::Passed;
        if not CheckRequiredOutput(Batch) then begin
          ClearLastError();
          BatchSeverity := BatchSeverity::Error;
          Severity := Severity::Error;
        end;
        Validation.RecordCheck(Batch."Run Id", Batch."Batch Id", Batch."Node Code", 'REQUIRED-OUTPUT',
          BatchSeverity, Batch."Last Key" - Batch."First Key" + 1, Batch."Processed Units");
        if BatchSeverity = BatchSeverity::Passed then begin
          Clear(WarningCodes);
          if not CheckOptionalOutput(Batch."Batch Id", WarningCodes) then begin
            ClearLastError();
            Clear(WarningCodes);
            WarningCodes.Add('OPTIONAL-CHECK-FAILED');
          end;
          foreach WarningCode in WarningCodes do
            Validation.RecordCheck(Batch."Run Id", Batch."Batch Id", Batch."Node Code", WarningCode, BatchSeverity::Warning, 0, 0);
          if (WarningCodes.Count() > 0) and (Severity <> Severity::Error) then
            Severity := Severity::Warning;
        end;
      until Batch.Next() = 0;
    Validation.RecordCheck(Execution."Run Id", NoBatch, '', 'RUN', Severity, 0, 0);
    case Severity of
      Severity::Passed: Execution.Status := Execution.Status::Completed;
      Severity::Warning: Execution.Status := Execution.Status::CompletedWithWarnings;
      Severity::Error: Execution.Status := Execution.Status::ValidationFailed;
    end;
    Execution."Finished At" := CurrentDateTime();
    Clear(Execution."Job Queue Entry Id");
  end;

  [TryFunction]
  local procedure CheckRequiredOutput(Batch: Record "BCSF Batch")
  var
    Checkpoint: Record "BCSF Batch Checkpoint";
    Entry: Record "BCSF Generated Record";
    Parent: Record "BCSF Generated Record";
    Recovery: Codeunit "BCSF Batch Recovery";
    Provenance: Codeunit "BCSF Record Registry";
    Rules: Codeunit "BCSF Execution Rules";
    Contract: Codeunit "BCSF Contract JSON";
    Result: JsonObject;
    LogicalKey: Integer;
    SalesPosted: Boolean;
    PurchasePosted: Boolean;
    HasGL: Boolean;
    HasCustomerLedger: Boolean;
    HasVendorLedger: Boolean;
  begin
    Batch.TestField(Status, Batch.Status::Completed);
    Rules.CheckCoverage(Batch);
    Checkpoint.Get(Batch."Batch Id");
    Result := Checkpoint.ReadResult();
    Batch.TestField("Processed Units", Contract.GetInteger(Result, 'processedUnits'));
    Batch.TestField("Created Records", Contract.GetInteger(Result, 'createdRecords'));
    Recovery.CheckCheckpoint(Checkpoint);
    Entry.SetCurrentKey("Batch Id", "Logical Key");
    Entry.SetRange("Batch Id", Batch."Batch Id");
    if Entry.FindSet() then
      repeat
        if Entry."Logical Key" <> LogicalKey then begin
          CheckPostingEvidence(SalesPosted, PurchasePosted, HasGL, HasCustomerLedger, HasVendorLedger);
          LogicalKey := Entry."Logical Key";
          SalesPosted := false;
          PurchasePosted := false;
          HasGL := false;
          HasCustomerLedger := false;
          HasVendorLedger := false;
        end;
        case Entry."Table Id" of
          Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header": SalesPosted := true;
          Database::"Purch. Inv. Header", Database::"Purch. Cr. Memo Hdr.": PurchasePosted := true;
          Database::"G/L Entry": HasGL := true;
          Database::"Cust. Ledger Entry": HasCustomerLedger := true;
          Database::"Vendor Ledger Entry": HasVendorLedger := true;
        end;
        if not IsNullGuid(Entry."Parent Entry Id") then begin
          Parent.SetRange("Entry Id", Entry."Parent Entry Id");
          if not Parent.FindFirst() then
            Error(RelationshipErr);
          Parent.TestField("Run Id", Entry."Run Id");
          if (Parent."Entry Id" = Entry."Entry Id") or not Provenance.ExistsByIdentity(Parent) then
            Error(RelationshipErr);
        end;
      until Entry.Next() = 0;
    CheckPostingEvidence(SalesPosted, PurchasePosted, HasGL, HasCustomerLedger, HasVendorLedger);
  end;

  local procedure CheckPostingEvidence(SalesPosted: Boolean; PurchasePosted: Boolean; HasGL: Boolean; HasCustomerLedger: Boolean; HasVendorLedger: Boolean)
  begin
    if (SalesPosted and not (HasGL and HasCustomerLedger)) or (PurchasePosted and not (HasGL and HasVendorLedger)) then
      Error(PostingEvidenceErr);
  end;

  [TryFunction]
  local procedure CheckOptionalOutput(BatchId: Guid; var WarningCodes: List of [Code[30]])
  var
    UniqueCodes: List of [Code[30]];
    WarningCode: Code[30];
  begin
    OnCheckOptionalOutput(BatchId, WarningCodes);
    if WarningCodes.Count() > 20 then
      Error(OptionalContractErr);
    foreach WarningCode in WarningCodes do begin
      if (CopyStr(WarningCode, 1, 5) <> 'WARN-') or UniqueCodes.Contains(WarningCode) then
        Error(OptionalContractErr);
      UniqueCodes.Add(WarningCode);
    end;
  end;

  // Subscribers must be read-only. Return stable WARN-* rule codes, not business data.
  [IntegrationEvent(false, false)]
  local procedure OnCheckOptionalOutput(BatchId: Guid; var WarningCodes: List of [Code[30]])
  begin
  end;

  var
    BatchCountErr: Label 'The saved batch counts do not match the prepared run.';
    PostingEvidenceErr: Label 'A posted invoice or credit memo is missing its registered general ledger or partner ledger evidence.';
    RelationshipErr: Label 'A generated result references a missing or invalid parent.';
    OptionalContractErr: Label 'An optional check returned an invalid or repeated warning code.';
}
