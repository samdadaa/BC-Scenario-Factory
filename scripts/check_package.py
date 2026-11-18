#!/usr/bin/env python3
"""Verify a complete AL package against the current workspace, including translations and dashboard assets."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import unquote
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
NS = {'x': 'urn:oasis:names:tc:xliff:document:1.2'}
CULTURES = ('g', 'de-DE', 'de-AT', 'de-CH', 'de-LI', 'de-LU', 'en-US')


def units(data):
    tree = ET.fromstring(data)
    entries = tree.findall('.//x:trans-unit', NS)
    result = {u.attrib['id']: (u.findtext('x:source', namespaces=NS),
                              u.findtext('x:target', namespaces=NS)) for u in entries}
    if len(result) != len(entries):
        raise ValueError('Duplicate translation IDs in package')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path)
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'app.json').read_text())
    with zipfile.ZipFile(args.package) as archive:
        names = {unquote(name): name for name in archive.namelist()}
        for culture in CULTURES:
            name = f'Translations/{manifest["name"]}.{culture}.xlf'
            if name not in names:
                raise ValueError(f'Missing packaged language: {culture}')
            local = (ROOT / name).read_bytes()
            packaged = archive.read(names[name])
            if units(local) != units(packaged):
                raise ValueError(f'Stale packaged compiler IDs, source or target: {culture}')
        for name in ('translations.js', 'dashboard.js', 'dashboard.css', 'startup.js'):
            candidates = [path for path in names if path.startswith('addin/') and path.endswith('/' + name)]
            if len(candidates) != 1:
                raise ValueError(f'Missing or ambiguous dashboard asset: {name}')
            if archive.read(names[candidates[0]]) != (ROOT / 'src/Monitoring/Dashboard' / name).read_bytes():
                raise ValueError(f'Stale packaged dashboard asset: {name}')
        app_manifest = ET.fromstring(archive.read(names['NavxManifest.xml']))
        app = next(element for element in app_manifest.iter() if element.tag.split('}')[-1] == 'App')
        if app.get('Id', '').lower() != manifest['id'].lower() or app.get('Version') != manifest['version']:
            raise ValueError('Packaged app identity/version differs from app.json')
        # The package includes source: verify every actual AL file, not just symbols or translations.
        sources = list((ROOT / 'src').rglob('*.al'))
        for path in sources:
            candidates = [name for name in names if name.startswith('src/') and name.endswith('/' + path.as_posix().removeprefix(str(ROOT) + '/'))]
            if len(candidates) != 1 or archive.read(names[candidates[0]]) != path.read_bytes():
                raise ValueError(f'Missing or stale packaged AL source: {path.relative_to(ROOT)}')
    digest = hashlib.sha256(args.package.read_bytes()).hexdigest()
    count = len(units((ROOT / f'Translations/{manifest["name"]}.g.xlf').read_bytes()))
    print(f'PASS: app identity/version, {len(sources)} AL sources, seven XLIFF files ({count} units each), four current dashboard assets. SHA256 {digest}')


if __name__ == '__main__':
    main()
