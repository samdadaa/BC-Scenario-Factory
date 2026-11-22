#!/usr/bin/env python3
"""Check the export catalog against local BC symbols and generator sources. No BC execution."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MODULES = {'Finance', 'Sales', 'Purchasing', 'Inventory', 'DataGeneration', 'SetupManager'}


def validate_coverage(catalog, required):
    missing = required - catalog
    assert not missing, f'Missing business tables: {sorted(missing)}'


def validate_empty_lifecycle(source, trigger):
    # Installation must stay independent of company count; no indirect work either.
    source = re.sub(r'//[^\n]*|/\*.*?\*/', '', source, flags=re.S)
    body = re.search(r'trigger ' + trigger + r'\(\)\s*begin(.*?)end;', source, re.S)
    assert body and not body[1].strip(), 'Install/upgrade must contain no executable work'
    assert not re.search(r'\b(?:procedure|EventSubscriber|Permissions)\b', source)


def main():
    symbols = {}
    for package in (ROOT / '.alpackages').glob('*.app'):
        with zipfile.ZipFile(package) as archive:
            for name in archive.namelist():
                if not name.endswith('.al'):
                    continue
                source = archive.read(name).decode('utf-8-sig')
                match = re.search(r'(?m)^table (\d+) "?([^"\n{]+)"?', source)
                if match:
                    symbols[match[2].strip()] = (int(match[1]), source)
    assert symbols, 'Existing Microsoft AL symbols are required; nothing is installed by this script.'
    source = (ROOT / 'src/Monitoring/Codeunits/BCSFConfigExport.Codeunit.al').read_text()
    names = re.findall(r'TableIds.Add\(Database::"([^"]+)"\)', source)
    assert len(names) == len(set(names)), 'Duplicate catalog table'
    catalog = set(names)
    required = set()
    for path in (ROOT / 'src').rglob('*.al'):
        if path.relative_to(ROOT).parts[1] not in MODULES:
            continue
        for match in re.finditer(r'(?:\bRecord\s+|Database::)(?:"([^"]+)"|(\w+))', path.read_text()):
            name = match[1] or match[2]
            if name in symbols:
                table_id, definition = symbols[name]
                if table_id < 100000 and 'DataPerCompany = false' not in definition and 'TableType = Temporary' not in definition:
                    required.add(name)
    # Record registry does not track lines, registers, dimension sets or all posting relations.
    required |= {'Sales Line', 'Purchase Line', 'Sales Shipment Line', 'Sales Invoice Line',
                 'Purch. Rcpt. Line', 'Purch. Inv. Line', 'G/L Register', 'Item Register',
                 'G/L Entry - VAT Entry Link', 'Item Application Entry', 'Item Application Entry History',
                 'Dimension Set Entry', 'Dimension Set Tree Node', 'Item Entry Relation',
                 'Value Entry Relation', 'Post Value Entry to G/L', 'Contact Business Relation',
                 'Contact Duplicate', 'Cont. Duplicate Search String', 'Duplicate Search String Setup'}
    validate_coverage(catalog, required)
    try:
        validate_coverage(catalog - {'Sales Invoice Line'}, required)
    except AssertionError:
        pass
    else:
        raise AssertionError('Missing posted-line negative control was not detected')
    documentation = (ROOT / 'docs/CONFIG_EXPORT.md').read_text()
    ids = []
    for name in names:
        table_id, definition = symbols[name]
        ids.append(table_id)
        assert 'TableType = Temporary' not in definition
        assert 'DataPerCompany = false' not in definition
        assert f'| {table_id} | {name} |' in documentation, f'Undocumented ID/name: {name}'
    assert len(ids) == len(set(ids)) and ids == sorted(ids)
    assert 'Package.LockTable();' in source and 'PackageCollisionErr' in source
    assert 'Package."Product Version" <> GetCatalogMarker()' in source
    assert 'PackageManagement.InsertPackageTable(' in source
    assert 'PackageManagement.SetFieldFilter(' in source
    assert 'if PackageTable.Get(GetPackageCode(), TableId) then\n      exit;' in source
    assert '[CommitBehavior(CommitBehavior::Error)]' in source
    assert not re.search(r'\b(?:Commit|DeleteAll|Delete|ChangeCompany)\(', source, re.I)
    assert not re.search(r'\[TryFunction\]|\bPermissions\s*=', source)
    assert 'IsSaaS()' in source and 'IsSandbox()' in source and 'not EnvironmentInformation.IsProduction()' in source
    for kind, trigger in [('Install', 'OnInstallAppPerCompany'), ('Upgrade', 'OnUpgradePerCompany')]:
        wrapper = (ROOT / f'src/Monitoring/Codeunits/BCSFConfigExport{kind}.Codeunit.al').read_text()
        validate_empty_lifecycle(wrapper, trigger)
        try:
            validate_empty_lifecycle(wrapper.replace('  begin\n', '  begin\n    ExportPackage.EnsurePackage();\n', 1), trigger)
        except AssertionError:
            pass
        else:
            raise AssertionError('Per-company install/upgrade work negative control was not detected')
    opener = source.split('  procedure OpenPackage()', 1)[1].split('  end;', 1)[0]
    assert 'EnsurePackage();' in opener
    print(f'PASS: {len(names)} unique symbol-verified tables, {len(required)} source/side-effect requirements, documented IDs, empty install/upgrade and missing-line negative controls, explicit current-company provision. Source checks only; no BC export executed.')


if __name__ == '__main__':
    main()
