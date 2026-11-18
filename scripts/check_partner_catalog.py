#!/usr/bin/env python3
"""Check authored catalog data and permutation coverage; no BC execution is simulated."""
from itertools import product
from math import gcd
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'src/DataGeneration/Codeunits/BCSFPartnerCatalog.Codeunit.al'


def main():
    source = SOURCE.read_text()
    pools = {name: value.replace("''", "'").split(',') for name, value in re.findall(
        r"(\w+Tok): Label '((?:[^']|'')*)', Locked = true;", source)}
    for name, values in pools.items():
        assert len(values) == len(set(values)), f'Duplicate catalog member: {name}'
        assert all(value.strip() == value and value for value in values), name
        assert all(not re.search(r'(?i)\b(test|demo|muster)\w*|\[\d+\]', value)
                   for value in values), f'Placeholder in {name}'
    for language in ('German', 'English'):
        first = pools[language + 'FirstNamesTok']
        last = pools[language + 'LastNamesTok']
        companies = pools[language + 'CompanyNamesTok']
        activities = pools[language + 'ActivitiesTok']
        forms = pools[language + 'LegalFormsTok']
        assert (len(first), len(last), len(companies), len(activities), len(forms)) == (32, 64, 32, 32, 4)
        people = [' '.join(row) for row in product(first, last)]
        assert len(set(people)) == 2048 and max(map(len, people)) <= 50
        for sector in ('', 'Consulting', 'Construction', 'Service', 'Manufacturing', 'Distribution', 'Ecommerce'):
            sector_activities = activities if not sector else pools[sector + ('DETok' if language == 'German' else 'ENTok')]
            assert len(sector_activities) == (32 if not sector else 8)
            names = [' '.join(row) for row in product(companies, sector_activities, forms)]
            assert len(names) == len(set(names))
            assert max(map(len, names)) <= 100
        assert len(pools[language + 'CitiesTok']) == len(pools[language + 'PostCodesTok']) == 8
        assert len(pools[language + 'StreetsTok']) == 16
    assert all(re.fullmatch(r'\d{5}', code) for code in pools['GermanPostCodesTok'])
    assert all(re.fullmatch(r'[A-Z]{1,2}\d[A-Z\d]? \d[A-Z]{2}', code) for code in pools['EnglishPostCodesTok'])
    # Coverage and arithmetic at both cycle boundaries and the largest AL Integer.
    for size in (1024, 2048, 4096):
        assert gcd(73, size) == 1
        for offset in (0, 1, size // 2, size - 1):
            indices = [(((key - 1) % size) * 73 + offset) % size for key in range(1, size + 1)]
            assert len(set(indices)) == size
            assert len(set(indices[:100])) == 100
            assert (((2147483647 - 1) % size) * 73 + offset) <= 2147483647
    assert "'@contact.invalid'" in source
    assert '((LogicalKey - 1) mod Size) * 73' in source, 'Reduce key before multiplication'
    assert "countryCode') = 'DE'" in source and "countryCode') = 'GB'" in source
    print(f'PASS: {len(pools)} locked pools; DE/EN names, sector combinations, field limits, postcode formats, reserved email and catalog-cycle coverage. Data/math checks only; BC validation remains required.')


if __name__ == '__main__':
    main()
