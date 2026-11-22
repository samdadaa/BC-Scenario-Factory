#!/usr/bin/env python3
"""Check purchase/payment API and transaction boundaries against installed Microsoft sources; no BC execution."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def check_payment_validation_suppression(source):
    source = re.sub(r'//[^\n]*|/\*.*?\*/', '', source, flags=re.S)
    pay = source.split('  procedure Pay(', 1)[1].split('  local procedure RegisterPayment(', 1)[0]
    start = pay.index('TempLine.Init();')
    first_validation = pay.index('TempLine.Validate(')
    suppression = pay.index('TempLine.SetSuppressCommit(true);')
    assert start < suppression < first_validation, 'Suppress standard validation commits before any payment field validation'
    assert re.search(r'TempLine.Init\(\);\s*TempLine.SetSuppressCommit\(true\);', pay), 'Suppression must apply unconditionally to both customer and vendor payments'
    assert not re.search(r'TempLine\.SetSuppressCommit\(false\)|Clear\(TempLine\)', pay[suppression:])
    assert 'TempLine.Validate("Applies-to Doc. No.", DocumentNo);' in pay
    assert 'TempLine.Validate(Amount, -Remaining);' in pay


def main():
    package = sorted((ROOT / '.alpackages').glob('Microsoft_Base Application_*.app'))[-1]
    wanted = {'PurchPost.Codeunit.al', 'GenJnlPostLine.Codeunit.al', 'PurchaseHeader.Table.al',
              'PurchaseLine.Table.al', 'PurchInvLine.Table.al', 'PurchRcptLine.Table.al',
              'GenJournalLine.Table.al', 'PaymentToleranceManagement.Codeunit.al'}
    with zipfile.ZipFile(package) as archive:
        native = {Path(name).name: archive.read(name).decode('utf-8-sig')
                  for name in archive.namelist() if Path(name).name in wanted}
    assert native.keys() == wanted
    assert 'procedure SetSuppressCommit(NewSuppressCommit: Boolean)' in native['PurchPost.Codeunit.al']
    assert 'internal procedure RunWithCheck(' in native['PurchPost.Codeunit.al']
    assert 'procedure RunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer' in native['GenJnlPostLine.Codeunit.al']
    assert not re.search(r'\bCommit\s*\(', native['GenJnlPostLine.Codeunit.al'], re.I)
    assert 'procedure GetGLReg(var NewGLReg: Record "G/L Register")' in native['GenJnlPostLine.Codeunit.al']
    journal = native['GenJournalLine.Table.al']
    setter = journal.split('procedure SetSuppressCommit(NewSuppressCommit: Boolean)', 1)[1].split('    end;', 1)[0]
    assert 'PaymentToleranceMgt.SetSuppressCommit(SuppressCommit);' in setter
    application = journal.split('field(36; "Applies-to Doc. No.";', 1)[1].split('field(37;', 1)[0]
    assert 'PaymentToleranceMgt.SetSuppressCommit(true);' in application
    assert 'PaymentToleranceMgt.PmtTolGenJnl(Rec);' in application
    tolerance = native['PaymentToleranceManagement.Codeunit.al']
    for method, next_method in [('DelCustPmtTolAcc', 'DelVendPmtTolAcc'), ('DelVendPmtTolAcc', 'CalcGracePeriodCVLedgEntry')]:
        body = tolerance.split('procedure ' + method + '(', 1)[1].split('procedure ' + next_method + '(', 1)[0]
        assert re.search(r'if not SuppressCommit then\s+Commit\(\);', body), method
    expected_keys = {'PurchaseHeader.Table.al': ['Document Type', 'No.'],
                     'PurchaseLine.Table.al': ['Document Type', 'Document No.', 'Line No.'],
                     'PurchInvLine.Table.al': ['Document No.', 'Line No.'],
                     'PurchRcptLine.Table.al': ['Document No.', 'Line No.']}
    for name, fields in expected_keys.items():
        key = re.search(r'\bkeys\s*\{\s*key\([^;]+;([^)]*)\)', native[name])
        assert key and [part.strip().strip('"') for part in key[1].split(',')] == fields, name
    purchase = (ROOT / 'src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al').read_text()
    payment = (ROOT / 'src/Finance/Codeunits/BCSFPaymentProcessor.Codeunit.al').read_text()
    check_payment_validation_suppression(payment)
    for mutant in (
        payment.replace('    TempLine.SetSuppressCommit(true);\n', ''),
        payment.replace('    TempLine.SetSuppressCommit(true);\n', '').replace('    TempLine.Insert(true);', '    TempLine.SetSuppressCommit(true);\n    TempLine.Insert(true);'),
        payment.replace('    TempLine.Validate(Amount, -Remaining);', '    TempLine.SetSuppressCommit(false);\n    TempLine.Validate(Amount, -Remaining);'),
        payment.replace('    TempLine.SetSuppressCommit(true);', '    if CustomerPayment then\n      TempLine.SetSuppressCommit(true);'),
    ):
        try:
            check_payment_validation_suppression(mutant)
        except (AssertionError, ValueError):
            pass
        else:
            raise AssertionError('Missing, late, reset or customer-only payment validation suppression was not rejected')
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
    assert 'PostLine.GetGLReg(GLRegister);' in payment
    assert 'GL.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");' in payment
    assert not re.search(r'\w+\s*:=\s*PostLine.RunWithCheck\(TempLine\)', payment)
    assert 'GL.SetFilter("Transaction No.", \'<>%1\', PaymentTransactionNo);' in payment
    for source in (purchase, payment):
        assert '[CommitBehavior(CommitBehavior::Error)]' in source
        assert not re.search(r'\bCommit\s*\(', source, re.I)
        for variable in ('GL', 'VAT', 'ItemEntry', 'VendorEntry', 'CustomerEntry', 'BankEntry', 'CustomerDetail', 'VendorDetail'):
            assert not re.search(r'\b' + variable + r'\.(Insert|Modify|Delete|Rename)\s*\(', source), variable
    assert 'Rules.EnsureExecution(' in payment and 'Guard.EnsureCanGenerate(' in payment
    assert '"Industry Posting Approved"' in (ROOT / 'src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al').read_text()
    assert 'Copy."Purchase Posting Approved" := false;' in (ROOT / 'src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al').read_text()
    assert 'Copy."Payment Posting Approved" := false;' in (ROOT / 'src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al').read_text()
    print('PASS: four purchase keys, standard journal-to-tolerance commit suppression before validation, missing/late/reset/customer-only negative controls, atomic posting, direct/indirect rights, captured/live approval, no direct ledger mutations and copy approval reset. Source contracts only; no BC posting executed.')


if __name__ == '__main__':
    main()
