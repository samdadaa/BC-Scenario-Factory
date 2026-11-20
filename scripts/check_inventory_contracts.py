#!/usr/bin/env python3
"""Check Inventory composite-key contracts against installed BC source symbols, without BC execution."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STANDARD = ROOT / '.alpackages'


def table_source(archive, name):
    declaration = re.compile(r'\btable\s+\d+\s+"?' + re.escape(name) + r'"?\s*\{')
    for path in archive.namelist():
        if path.endswith('.Table.al'):
            source = archive.read(path).decode('utf-8-sig')
            if declaration.search(source):
                return source
    raise AssertionError(f'Standard source unavailable: {name}')


def primary_key(source):
    match = re.search(r'\bkeys\s*\{\s*key\([^;]+;([^)]*)\)', source)
    assert match, 'No primary key found'
    return [part.strip().strip('"') for part in match[1].split(',')]


def check_vendor_lookup(source, standard_fields):
    method = source.split('  procedure GetItemVendor(', 1)[1].split('\n  end;', 1)[0]
    calls = re.findall(r'Supplier\.Get\(([^;]+)\);', method)
    assert len(calls) == 1, 'Expected one canonical Item Vendor reader'
    names = {'VendorNo': 'Vendor No.', 'ItemNo': 'Item No.', 'VariantCode': 'Variant Code'}
    arguments = [part.strip() for part in calls[0].split(',')]
    assert [names.get(name, name) for name in arguments] == standard_fields, 'Item Vendor primary-key order mismatch'
    assert len(re.findall(r'Supplier\.Get\(', source)) == 1, 'An Item Vendor read bypasses the canonical key contract'
    assert 'GetItemVendor(Supplier, VendorNo, Item."No.", VariantCode);' in source
    assert 'GetItemVendor(Supplier, Reference."Reference Type No.", Item."No.", \'\');' in source


def main():
    packages = sorted(STANDARD.glob('Microsoft_Base Application_*.app'))
    assert packages, 'Use installed BC source symbols; no package is downloaded'
    expected = {
        'Item Vendor': ['Vendor No.', 'Item No.', 'Variant Code'],
        'Item Unit of Measure': ['Item No.', 'Code'],
        'Item Variant': ['Item No.', 'Code'],
        'Item Attribute Value': ['Attribute ID', 'ID'],
        'Item Attribute Value Mapping': ['Table ID', 'No.', 'Item Attribute ID'],
        'Inventory Posting Setup': ['Location Code', 'Invt. Posting Group Code'],
        'General Posting Setup': ['Gen. Bus. Posting Group', 'Gen. Prod. Posting Group'],
        'VAT Posting Setup': ['VAT Bus. Posting Group', 'VAT Prod. Posting Group'],
    }
    with zipfile.ZipFile(packages[-1]) as archive:
        for table, fields in expected.items():
            actual = primary_key(table_source(archive, table))
            assert actual == fields, (table, actual, fields)
    source = (ROOT / 'src/Inventory/Codeunits/BCSFItemRelations.Codeunit.al').read_text()
    check_vendor_lookup(source, expected['Item Vendor'])
    # Prove this check catches the reported regression, rather than accepting either order.
    wrong = source.replace('Supplier.Get(VendorNo, ItemNo, VariantCode);',
                           'Supplier.Get(ItemNo, VendorNo, VariantCode);')
    try:
        check_vendor_lookup(wrong, expected['Item Vendor'])
    except AssertionError:
        pass
    else:
        raise AssertionError('Reversed-key regression was not detected')
    for path in (ROOT / 'src/Inventory').rglob('*.al'):
        text = path.read_text()
        assert not re.search(r'\bCommit\s*\(', text, re.I), f'Unexpected commit: {path}'
        for table in ('Item Ledger Entry', 'Value Entry', 'Item Application Entry', 'Warehouse Entry'):
            assert not re.search(r':\s*Record\s+"' + re.escape(table) + '"', text), (path, table)
    print('PASS: eight standard composite keys, both Item Vendor call sites and reversed-key negative control; no Inventory commits/ledger writers. Source-contract checks only, no BC runtime.')


if __name__ == '__main__':
    main()
