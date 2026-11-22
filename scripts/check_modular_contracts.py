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
    print('PASS: read-only same-company source, confirmed master checkpoints including terminal failed runs, four unsafe-source negative controls, immutable request, no new master targets, legacy sales contracts, current stock and protected starters. Source checks only; native A-G open.')


if __name__ == '__main__':
    main()
