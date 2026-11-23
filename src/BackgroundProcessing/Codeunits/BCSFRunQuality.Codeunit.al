namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Validation;
using Microsoft.Finance.GeneralLedger.Journal;
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
          BatchSeverity, Batch."Last Key" - Batch."First Key" + 1 - Batch."Skipped Units", Batch."Processed Units");
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
    Validation.RecordCheck(Execution."Run Id", NoBatch, '', 'RUN', Severity, Execution."Total Batches", Execution."Total Batches");
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
  begin
    Batch.TestField(Status, Batch.Status::Completed);
    Rules.CheckCoverage(Batch);
    Checkpoint.Get(Batch."Batch Id");
    Result := Checkpoint.ReadStoredResult();
    Batch.TestField("Processed Units", Contract.GetInteger(Result, 'processedUnits'));
    Batch.TestField("Created Records", Contract.GetInteger(Result, 'createdRecords'));
    Recovery.CheckCheckpoint(Checkpoint);
    Entry.SetCurrentKey("Batch Id", "Logical Key");
    Entry.SetRange("Batch Id", Batch."Batch Id");
    if Entry.FindSet() then
      repeat
        CheckPostedDocument(Entry);
        if not IsNullGuid(Entry."Parent Entry Id") then begin
          Parent.SetRange("Entry Id", Entry."Parent Entry Id");
          if not Parent.FindFirst() then
            Error(RelationshipErr);
          Parent.TestField("Run Id", Entry."Run Id");
          if (Parent."Entry Id" = Entry."Entry Id") or not Provenance.ExistsByIdentity(Parent) then
            Error(RelationshipErr);
        end;
      until Entry.Next() = 0;
  end;

  local procedure CheckPostedDocument(Entry: Record "BCSF Generated Record")
  var
    SalesInvoice: Record "Sales Invoice Header";
    SalesCredit: Record "Sales Cr.Memo Header";
    PurchaseInvoice: Record "Purch. Inv. Header";
    PurchaseCredit: Record "Purch. Cr. Memo Hdr.";
  begin
    case Entry."Table Id" of
      Database::"Sales Invoice Header":
        begin
          SalesInvoice.GetBySystemId(Entry."Record SystemId");
          SalesInvoice.CalcFields("Amount Including VAT");
          CheckCustomerPosting(Entry, SalesInvoice."Cust. Ledger Entry No.", SalesInvoice."No.",
            SalesInvoice."Bill-to Customer No.", SalesInvoice."Posting Date", SalesInvoice."Amount Including VAT", "Gen. Journal Document Type"::Invoice);
        end;
      Database::"Sales Cr.Memo Header":
        begin
          SalesCredit.GetBySystemId(Entry."Record SystemId");
          SalesCredit.CalcFields("Amount Including VAT");
          CheckCustomerPosting(Entry, SalesCredit."Cust. Ledger Entry No.", SalesCredit."No.",
            SalesCredit."Bill-to Customer No.", SalesCredit."Posting Date", -SalesCredit."Amount Including VAT", "Gen. Journal Document Type"::"Credit Memo");
        end;
      Database::"Purch. Inv. Header":
        begin
          PurchaseInvoice.GetBySystemId(Entry."Record SystemId");
          PurchaseInvoice.CalcFields("Amount Including VAT");
          CheckVendorPosting(Entry, PurchaseInvoice."Vendor Ledger Entry No.", PurchaseInvoice."No.",
            PurchaseInvoice."Pay-to Vendor No.", PurchaseInvoice."Posting Date", -PurchaseInvoice."Amount Including VAT", "Gen. Journal Document Type"::Invoice);
        end;
      Database::"Purch. Cr. Memo Hdr.":
        begin
          PurchaseCredit.GetBySystemId(Entry."Record SystemId");
          PurchaseCredit.CalcFields("Amount Including VAT");
          CheckVendorPosting(Entry, PurchaseCredit."Vendor Ledger Entry No.", PurchaseCredit."No.",
            PurchaseCredit."Pay-to Vendor No.", PurchaseCredit."Posting Date", PurchaseCredit."Amount Including VAT", "Gen. Journal Document Type"::"Credit Memo");
        end;
    end;
  end;

  local procedure CheckCustomerPosting(Entry: Record "BCSF Generated Record"; LedgerNo: Integer; DocumentNo: Code[20]; PartnerNo: Code[20]; PostingDate: Date; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
  var
    Ledger: Record "Cust. Ledger Entry";
  begin
    Ledger.SecurityFiltering(SecurityFilter::Disallowed);
    Ledger.Get(LedgerNo);
    Ledger.TestField("Document No.", DocumentNo);
    Ledger.TestField("Customer No.", PartnerNo);
    Ledger.TestField("Document Type", DocumentType);
    Ledger.TestField("Posting Date", PostingDate);
    Ledger.CalcFields("Original Amount");
    Ledger.TestField("Original Amount", Amount);
    CheckRegisteredIdentity(Entry, Database::"Cust. Ledger Entry", Ledger.SystemId);
    CheckGLPosting(Entry, Ledger."Transaction No.", DocumentNo, PostingDate, DocumentType);
  end;

  local procedure CheckVendorPosting(Entry: Record "BCSF Generated Record"; LedgerNo: Integer; DocumentNo: Code[20]; PartnerNo: Code[20]; PostingDate: Date; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
  var
    Ledger: Record "Vendor Ledger Entry";
  begin
    Ledger.SecurityFiltering(SecurityFilter::Disallowed);
    Ledger.Get(LedgerNo);
    Ledger.TestField("Document No.", DocumentNo);
    Ledger.TestField("Vendor No.", PartnerNo);
    Ledger.TestField("Document Type", DocumentType);
    Ledger.TestField("Posting Date", PostingDate);
    Ledger.CalcFields("Original Amount");
    Ledger.TestField("Original Amount", Amount);
    CheckRegisteredIdentity(Entry, Database::"Vendor Ledger Entry", Ledger.SystemId);
    CheckGLPosting(Entry, Ledger."Transaction No.", DocumentNo, PostingDate, DocumentType);
  end;

  local procedure CheckGLPosting(Entry: Record "BCSF Generated Record"; TransactionNo: Integer; DocumentNo: Code[20]; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type")
  var
    Ledger: Record "G/L Entry";
    Balance: Decimal;
  begin
    if TransactionNo <= 0 then
      Error(PostingEvidenceErr);
    Ledger.SecurityFiltering(SecurityFilter::Disallowed);
    Ledger.SetCurrentKey("Transaction No.");
    Ledger.SetRange("Transaction No.", TransactionNo);
    Ledger.SetRange("Document No.", DocumentNo);
    Ledger.SetRange("Document Type", DocumentType);
    Ledger.SetRange("Posting Date", PostingDate);
    Balance := 0;
    if not Ledger.FindSet() then
      Error(PostingEvidenceErr);
    repeat
      CheckRegisteredIdentity(Entry, Database::"G/L Entry", Ledger.SystemId);
      Balance += Ledger.Amount;
    until Ledger.Next() = 0;
    if Balance <> 0 then
      Error(PostingEvidenceErr);
  end;

  local procedure CheckRegisteredIdentity(Entry: Record "BCSF Generated Record"; TableId: Integer; RecordSystemId: Guid)
  var
    Evidence: Record "BCSF Generated Record";
  begin
    Evidence.SetCurrentKey("Table Id", "Record SystemId");
    Evidence.SetRange("Table Id", TableId);
    Evidence.SetRange("Record SystemId", RecordSystemId);
    if not Evidence.FindFirst() then
      Error(PostingEvidenceErr);
    Evidence.TestField("Run Id", Entry."Run Id");
    Evidence.TestField("Node Code", Entry."Node Code");
    Evidence.TestField("Logical Key", Entry."Logical Key");
    Evidence.TestField("Batch Id", Entry."Batch Id");
  end;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Validation Manager", 'OnCheckResult', '', false, false)]
  local procedure CheckResult(Result: Record "BCSF Validation Result")
  var
    Execution: Record "BCSF Run Execution";
    Batch: Record "BCSF Batch";
    Finding: Record "BCSF Validation Result";
    Severity: Enum "BCSF Validation Severity";
    RequiredCount: Integer;
  begin
    Execution.Get(Result."Run Id");
    if not (Execution.Status in [Execution.Status::Running, Execution.Status::ResumePending]) then
      Error(BatchCountErr);
    if not IsNullGuid(Result."Batch Id") then begin
      Batch.Get(Result."Batch Id");
      Batch.TestField("Run Id", Result."Run Id");
      Batch.TestField("Node Code", Result."Node Code");
      Batch.TestField(Status, Batch.Status::Completed);
      if Result."Rule Code" = 'REQUIRED-OUTPUT' then begin
        Result.TestField("Expected Units", Batch."Last Key" - Batch."First Key" + 1 - Batch."Skipped Units");
        Result.TestField("Reported Units", Batch."Processed Units");
        if Result.Severity = Result.Severity::Warning then
          Error(BatchCountErr);
        if Result.Severity = Result.Severity::Passed then
          CheckRequiredOutput(Batch);
      end else begin
        Result.TestField(Severity, Result.Severity::Warning);
        if (CopyStr(Result."Rule Code", 1, 5) <> 'WARN-') and (Result."Rule Code" <> 'OPTIONAL-CHECK-FAILED') then
          Error(OptionalContractErr);
        Finding.Get(Result."Run Id", Result."Batch Id", 'REQUIRED-OUTPUT');
        Finding.TestField(Severity, Finding.Severity::Passed);
      end;
      exit;
    end;
    Result.TestField("Rule Code", 'RUN');
    Result.TestField("Node Code", '');
    Severity := Severity::Passed;
    RequiredCount := 0;
    Batch.SetRange("Run Id", Result."Run Id");
    if (Batch.Count() <> Execution."Total Batches") or (Execution."Total Batches" <= 0) then
      Error(BatchCountErr);
    if Batch.FindSet() then
      repeat
        Batch.TestField(Status, Batch.Status::Completed);
        Finding.Get(Result."Run Id", Batch."Batch Id", 'REQUIRED-OUTPUT');
        RequiredCount += 1;
      until Batch.Next() = 0;
    Finding.SetRange("Run Id", Result."Run Id");
    if Finding.FindSet() then
      repeat
        if Finding.Severity = Finding.Severity::Error then
          Severity := Severity::Error
        else
          if (Finding.Severity = Finding.Severity::Warning) and (Severity <> Severity::Error) then
            Severity := Severity::Warning;
      until Finding.Next() = 0;
    Result.TestField(Severity, Severity);
    Result.TestField("Expected Units", RequiredCount);
    Result.TestField("Reported Units", RequiredCount);
  end;

  [TryFunction]
  local procedure CheckOptionalOutput(BatchId: Guid; var WarningCodes: List of [Code[30]])
  var
    Entry: Record "BCSF Generated Record";
    Batch: Record "BCSF Batch";
    UniqueCodes: List of [Code[30]];
    WarningCode: Code[30];
  begin
    Batch.Get(BatchId);
    if Batch."Skipped Units" > 0 then
      WarningCodes.Add('WARN-UNIT-SKIPPED');
    Entry.SetRange("Batch Id", BatchId);
    Entry.SetRange("Posting Skipped", true);
    if not Entry.IsEmpty() then
      WarningCodes.Add('WARN-POSTING-SKIPPED');
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
