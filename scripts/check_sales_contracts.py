#!/usr/bin/env python3
"""Verify SF-021 API/key/transaction contracts against installed BC source symbols, not BC execution."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def check_posting_call(source):
    assert 'SalesPost.SetSuppressCommit(true);' in source
    assert re.search(r'^\s*SalesPost\.Run\(Header\);', source, re.M), 'Use the public posting trigger without a Boolean return'
    assert not re.search(r'(?:if|:=)\s+SalesPost\.Run\(', source), 'Boolean Codeunit.Run can commit implicitly'
    assert '[CommitBehavior(CommitBehavior::Error)]' in source
    assert 'QuoteToOrder.Run(Header);' in source
    assert 'QuoteToOrder.GetSalesOrderHeader(Header);' in source


def main():
    packages = sorted((ROOT / '.alpackages').glob('Microsoft_Base Application_*.app'))
    assert packages, 'Installed source symbols are required; nothing is downloaded'
    names = ['SalesPost.Codeunit.al', 'SalesQuotetoOrder.Codeunit.al', 'SalesHeader.Table.al',
             'SalesLine.Table.al', 'SalesInvoiceLine.Table.al', 'GLItemLedgerRelation.Table.al']
    with zipfile.ZipFile(packages[-1]) as archive:
        sources = {Path(path).name: archive.read(path).decode('utf-8-sig')
                   for path in archive.namelist() if Path(path).name in names}
    assert set(sources) == set(names)
    posting = sources['SalesPost.Codeunit.al']
    assert re.search(r'trigger OnRun\(\)\s*begin\s*RunWithCheck\(Rec\);', posting)
    assert 'internal procedure RunWithCheck(' in posting, 'Recheck public posting API for this BC version'
    assert 'procedure SetSuppressCommit(NewSuppressCommit: Boolean)' in posting
    assert 'procedure GetGlobaDocumentsHeaders(' in posting
    assert 'procedure GetSalesOrderHeader(' in sources['SalesQuotetoOrder.Codeunit.al']
    expected = {'SalesHeader.Table.al': ['Document Type', 'No.'],
                'SalesLine.Table.al': ['Document Type', 'Document No.', 'Line No.'],
                'SalesInvoiceLine.Table.al': ['Document No.', 'Line No.'],
                'GLItemLedgerRelation.Table.al': ['G/L Entry No.', 'Value Entry No.']}
    for name, fields in expected.items():
        match = re.search(r'\bkeys\s*\{\s*key\([^;]+;([^)]*)\)', sources[name])
        assert match and [p.strip().strip('"') for p in match[1].split(',')] == fields, name
    documents = (ROOT / 'src/Sales/Codeunits/BCSFSalesDocuments.Codeunit.al').read_text()
    check_posting_call(documents)
    try:
        check_posting_call(documents.replace('SalesPost.Run(Header);', 'if SalesPost.Run(Header) then;'))
    except AssertionError:
        pass
    else:
        raise AssertionError('Boolean-run negative control was not detected')
    # The evidence reader can register existing ledger identities, never write ledger records.
    for path in (ROOT / 'src/Sales/Codeunits').glob('BCSFSales*.al'):
        source = path.read_text()
        assert not re.search(r'\bCommit\s*\(', source, re.I), path
        for variable in ('GL', 'VAT', 'ItemEntry', 'Entry', 'Value', 'CustomerEntry', 'Relation'):
            assert not re.search(r'\b' + variable + r'\.(?:Insert|Modify|Delete|Rename)\s*\(', source), (path, variable)
    for name in ('BCSFPlanningGuard', 'BCSFProvenanceGuard'):
        source = (ROOT / f'src/Lifecycle/Codeunits/{name}.Codeunit.al').read_text()
        assert 'Manager.HasSalesPostingApproval(' in source, name
    print('PASS: standard public posting/quote APIs, four composite keys, suppressed explicit commits, Boolean-run negative control, no custom ledger writers, captured approval in start/provenance guards. Source checks only; no BC runtime.')


if __name__ == '__main__':
    main()
