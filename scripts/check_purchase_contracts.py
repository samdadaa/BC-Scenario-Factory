#!/usr/bin/env python3
"""Check purchase/payment API and transaction boundaries against installed Microsoft sources; no BC execution."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    package = sorted((ROOT / '.alpackages').glob('Microsoft_Base Application_*.app'))[-1]
    wanted = {'PurchPost.Codeunit.al', 'GenJnlPostLine.Codeunit.al', 'PurchaseHeader.Table.al',
              'PurchaseLine.Table.al', 'PurchInvLine.Table.al', 'PurchRcptLine.Table.al'}
    with zipfile.ZipFile(package) as archive:
        native = {Path(name).name: archive.read(name).decode('utf-8-sig')
                  for name in archive.namelist() if Path(name).name in wanted}
    assert native.keys() == wanted
    assert 'procedure SetSuppressCommit(NewSuppressCommit: Boolean)' in native['PurchPost.Codeunit.al']
    assert 'internal procedure RunWithCheck(' in native['PurchPost.Codeunit.al']
    assert 'procedure RunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer' in native['GenJnlPostLine.Codeunit.al']
    assert not re.search(r'\bCommit\s*\(', native['GenJnlPostLine.Codeunit.al'], re.I)
    expected_keys = {'PurchaseHeader.Table.al': ['Document Type', 'No.'],
                     'PurchaseLine.Table.al': ['Document Type', 'Document No.', 'Line No.'],
                     'PurchInvLine.Table.al': ['Document No.', 'Line No.'],
                     'PurchRcptLine.Table.al': ['Document No.', 'Line No.']}
    for name, fields in expected_keys.items():
        key = re.search(r'\bkeys\s*\{\s*key\([^;]+;([^)]*)\)', native[name])
        assert key and [part.strip().strip('"') for part in key[1].split(',')] == fields, name
    purchase = (ROOT / 'src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al').read_text()
    payment = (ROOT / 'src/Finance/Codeunits/BCSFPaymentProcessor.Codeunit.al').read_text()
    guard = (ROOT / 'src/Lifecycle/Codeunits/BCSFEnvironmentGuard.Codeunit.al').read_text()
    sales = (ROOT / 'src/Sales/Codeunits/BCSFSalesSetup.Codeunit.al').read_text()
    assert 'UserPermissions.GetEffectivePermission(' in guard
    assert 'TempPermission."Insert Permission"::Indirect' in guard
    assert 'TempPermission."Modify Permission"::Indirect' in guard
    assert 'Row.ReadPermission()' in guard
    posting_guard = guard.split('procedure EnsurePostingTableAccess', 1)[1].split('local procedure EnsureSandbox', 1)[0]
    assert 'WritePermission()' not in posting_guard
    for source in (purchase, sales, payment):
        assert 'Guard.EnsurePostingTableAccess(' in source
        assert 'Guard.EnsureCodeunitAccess(' in source
    assert 'RequirePermission(Database::"Gen. Journal Line")' not in payment
    registry = (ROOT / 'src/DataGeneration/Codeunits/BCSFRecordRegistry.Codeunit.al').read_text()
    allowed = registry.split('local procedure IsAllowedTable', 1)[1].split('[IntegrationEvent', 1)[0]
    for table in ('Bank Account Ledger Entry', 'Detailed Cust. Ledg. Entry', 'Detailed Vendor Ledg. Entry'):
        assert 'Database::"' + table + '"' in allowed, table
    assert 'PurchasePost.SetSuppressCommit(true);' in purchase
    assert 'PurchasePost.Run(Header);' in purchase
    assert not re.search(r'(?:if|:=)\s*PurchasePost\.Run\(', purchase)
    assert 'PostLine.RunWithCheck(TempLine)' in payment
    for source in (purchase, payment):
        assert '[CommitBehavior(CommitBehavior::Error)]' in source
        assert not re.search(r'\bCommit\s*\(', source, re.I)
        for variable in ('GL', 'VAT', 'ItemEntry', 'VendorEntry', 'CustomerEntry', 'BankEntry', 'CustomerDetail', 'VendorDetail'):
            assert not re.search(r'\b' + variable + r'\.(Insert|Modify|Delete|Rename)\s*\(', source), variable
    assert 'Rules.EnsureExecution(' in payment and 'Guard.EnsureCanGenerate(' in payment
    assert '"Industry Posting Approved"' in (ROOT / 'src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al').read_text()
    assert 'Copy."Purchase Posting Approved" := false;' in (ROOT / 'src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al').read_text()
    assert 'Copy."Payment Posting Approved" := false;' in (ROOT / 'src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al').read_text()
    print('PASS: four purchase keys, suppressed purchase posting, atomic journal posting, direct/indirect posting rights, standard execute checks, captured/live approval, no direct ledger mutations and copy approval reset. Source contracts only; no BC posting executed.')


if __name__ == '__main__':
    main()
