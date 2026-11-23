#!/usr/bin/env python3
"""SF-048 source boundaries and mutation negative controls; no BC execution."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / 'src' / path).read_text()


def check_source(source, execution):
    assert not re.search(r'\.(Insert|Modify|Delete|RegisterResult|ChangeCompany)\s*\(', source, re.I)
    for guard in ('Header.TestField("Company Name", CompanyName())', 'Registry.ExistsByIdentity(Entry)',
                  'OnCheckSource(SourceId, Confirmed)', 'if not Confirmed then',
                  'if StoredText <> CurrentText then', "Context.Contains('masterDataSource')"):
        assert guard in source, guard
    for guard in ('Execution.Status::Failed', 'Execution.Status::ValidationFailed',
                  'Batch.Status::Running', 'Batch.TestField(Status, Batch.Status::Completed)',
                  'Checkpoint.TestField("Confirmed At")', 'Checkpoint.ReadStoredResult()',
                  'Units <> Step."Work Units"'):
        assert guard in execution, guard


def main():
    source = read('DataGeneration/Codeunits/BCSFMasterDataSource.Codeunit.al')
    execution = read('BackgroundProcessing/Codeunits/BCSFExecutionRules.Codeunit.al')
    check_source(source, execution)
    for broken_source, broken_execution in (
        (source + '\nEntry.Insert();', execution),
        (source.replace('Registry.ExistsByIdentity(Entry)', 'true'), execution),
        (source, execution.replace('Batch.TestField(Status, Batch.Status::Completed)', '')),
        (source, execution.replace('Checkpoint.TestField("Confirmed At")', '')),
    ):
        try:
            check_source(broken_source, broken_execution)
        except AssertionError:
            pass
        else:
            raise AssertionError('Unsafe source negative control was accepted')
    selected = source.split('procedure CaptureExisting(PurchaseSelected:', 1)[1].split('local procedure CompatibleItems', 1)[0]
    assert "Binding.Add('version', 3)" in selected
    assert 'MinItemsPerSupplier' not in selected and '500' not in selected
    assert 'PurchaseSelected' in selected and 'SalesSelected' in selected
    validation = source.split('local procedure ValidateSelected(', 1)[1].split('local procedure CountEligibleItems', 1)[0]
    assert 'CaptureExisting(' not in validation, 'Selected identities must not be replaced by a live company rescan.'
    assert 'GetBySystemId' in validation and "Binding.Get('itemVendors'" in validation
    assert 'EligibleSelectedCustomer(Customer)' in validation and 'EligibleSelectedVendor(Vendor)' in validation
    writer = read('ScenarioManagement/Codeunits/BCSFSnapshotWriter.Codeunit.al')
    assert 'OnCaptureSalesSetup(Scenario, InventorySettings, MasterBinding, SalesSettings)' in writer
    capture_sales = read('Sales/Codeunits/BCSFSalesSetup.Codeunit.al').split('procedure UsesRunMasters', 1)[0]
    assert 'Source.Capture' not in capture_sales, 'Sales must reuse the exact master binding.'
    documents = read('Sales/Codeunits/BCSFSalesDocuments.Codeunit.al')
    assert "SkipReason := 'STOCK'" in documents
    assert documents.index("if SkipReason <> '' then") > documents.index("SkipReason := 'STOCK'")
    registry = read('DataGeneration/Codeunits/BCSFRecordRegistry.Codeunit.al')
    assert 'Entry."Posting Skipped" := SkipReason <> ' in registry
    assert 'Entry."Skip Reason Code" <> SkipReason' in registry
    quality = read('BackgroundProcessing/Codeunits/BCSFRunQuality.Codeunit.al')
    assert "WarningCodes.Add('WARN-POSTING-SKIPPED')" in quality
    dispatcher = read('BackgroundProcessing/Codeunits/BCSFQueueDispatcher.Codeunit.al')
    recovery = read('BackgroundProcessing/Codeunits/BCSFBatchRecovery.Codeunit.al')
    runner = read('BackgroundProcessing/Codeunits/BCSFBatchRunner.Codeunit.al')
    failure = read('BackgroundProcessing/Codeunits/BCSFQueueFailure.Codeunit.al')
    partner = read('DataGeneration/Codeunits/BCSFPartnerRules.Codeunit.al')
    foundation = read('Finance/Codeunits/BCSFDemoPartnerSetup.Codeunit.al')
    def check_isolation(code):
        assert 'Candidate.Status <> Candidate.Status::Pending' in code
        assert 'Other.Status::Running' in code
        assert 'Generator.GetDependencies(Context, MakeTarget(Step), Dependencies)' in code
        assert 'Other.SetFilter("Skipped Units",' in code
        assert 'Candidate."First Key" = Candidate."Last Key"' in code
    check_isolation(dispatcher)
    for unsafe in (
        dispatcher.replace('Candidate.Status <> Candidate.Status::Pending', 'false'),
        dispatcher.replace('Other.Status::Running', 'Other.Status::Completed'),
        dispatcher.replace('Other.SetFilter("Skipped Units",', 'Other.SetRange("Skipped Units",'),
    ):
        try:
            check_isolation(unsafe)
        except AssertionError:
            pass
        else:
            raise AssertionError('Unsafe scheduling negative control was accepted')
    assert "Payload.Add('executionPolicyVersion', 1)" in writer
    assert 'BatchSize := 1' in partner
    assert 'Rules.CheckSkippingOwner(NewBatch)' in recovery
    assert 'if Batch."Skipped Units" > 0 then' in recovery
    assert 'PartnerRules.InspectDocument' in runner and 'Rules.CheckSkipped(Batch)' in runner
    assert failure.index('Batch.Status := Batch.Status::NeedsReview') < failure.index('Dispatcher.ScheduleNext(Execution)')
    assert not re.search(r'\b(Insert|Modify|Delete|Commit)\s*\(', failure.split('local procedure CanContinue(', 1)[1], re.I)
    assert not re.search(r'Account\.(Insert|Modify|Delete|Rename|Validate)\s*\(', foundation, re.I)
    assert 'Guard.EnsureCanConfigure(CompanyName())' in foundation
    assert 'ExistingFoundation.PrepareExisting(EffectiveDate, Write, TempDiff)' in read('Finance/Codeunits/BCSFFinancePackageMgt.Codeunit.al')
    for path in ('Sales/Codeunits/BCSFSalesGenerator.Codeunit.al', 'Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al'):
        inspection = read(path).split('local procedure TryInspectDocument(', 1)[1].split('procedure GetDependencies', 1)[0]
        assert not re.search(r'\.(Insert|Modify|Validate|Delete)\s*\(', inspection)
    profile = read('IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al')
    assert 'Target.Delete(true)' in profile and 'Quantity := 0' in profile
    for entity in ('Customer', 'Vendor', 'Item'):
        assert f'Target.Entity::{entity}:' not in profile.split('local procedure ConfigureTransactionTargets(', 1)[1]
    initialization = read('Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al')
    for field in ('Industry Generation Kind', 'Industry Master Source Id', 'Industry Purchase Selected',
                  'Industry Sales Selected', 'Industry Purchase Quantity', 'Industry Sales Order Quantity',
                  'Industry Sales Quote Quantity', 'Industry Sales Inv Quantity'):
        assert f'Rec.TestField("{field}", Previous."{field}")' in initialization
    sales = read('Sales/Codeunits/BCSFSalesSetup.Codeunit.al')
    assert 'in [1, 2, 3, 4]' in sales and 'in [2, 3]' in sales
    assert 'Source.Validate(Context)' in sales and 'WholesaleRemainingDemand(Context, ItemIndex)' in sales
    assert 'Item.LockTable()' in sales and 'Item.CalcFields(Inventory, "Reserved Qty. on Inventory")' in sales
    catalog = read('IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al')
    assert 'for VariantNo := 1 to 7 do begin' in catalog
    assert 'not Scenario.Get(Id) and not Removed.Get(Id)' in catalog
    assert 'ConfigureTransactionDraft(Id, true, false, 15, 0, 0, 0)' in catalog
    assert 'ConfigureTransactionDraft(Id, false, true, 0, 20, 0, 0)' in catalog
    print('PASS: SF-050 singleton policy, pending-only scheduling with confirmed dependencies, three unsafe-scheduling negative controls, claimed-owner skip guards, no-write inspection, and existing-foundation account protection. Source checks only.')
    print('PASS: read-only same-company source, confirmed master checkpoints including terminal failed runs, four unsafe-source negative controls, immutable request, no new master targets, legacy sales contracts, current stock and protected starters. Source checks only; native A-G open.')


if __name__ == '__main__':
    main()
