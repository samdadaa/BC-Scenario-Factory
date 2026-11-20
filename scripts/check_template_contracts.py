#!/usr/bin/env python3
"""Check template integration boundaries. Static checks do not execute Business Central."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check_decimal_distribution(source):
    for name in ('postedPercent', 'partialPercent'):
        assert f"Contract.GetDecimal(Target, '{name}')" in source, 'Execution must retain decimal shares'
        assert f"Contract.GetInteger(Target, '{name}')" not in source


def main():
    source = (ROOT / 'src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al').read_text()
    check_decimal_distribution(source)
    try:
        check_decimal_distribution(source.replace('Contract.GetDecimal(Target,', 'Contract.GetInteger(Target,'))
    except AssertionError:
        pass
    else:
        raise AssertionError('Integer-share negative control was not rejected')
    catalog = (ROOT / 'src/IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al').read_text()
    assert 'UpgradeSalesStarter(Scenario, Industry, VariantNo, Profile, Setup);' in catalog
    upgrade = catalog.split('    local procedure UpgradeSalesStarter(', 1)[1].split('    local procedure IsDefaultName(', 1)[0]
    assert 'IsLegacySalesStarter(' in upgrade and 'DefaultNameUsed' in upgrade
    assert 'Scenario."Sales Posting Approved" := false;' in upgrade
    assert 'for VariantNo := 1 to 2 do begin' in catalog and 'MixedSalesLbl' in catalog
    assert "Scenario.\"Profile Version\" <> '1'" in catalog and 'Scenario.Archived or' in catalog
    assert 'Selection.Count() <> ExpectedCount' in catalog and 'Target.Count() <> ExpectedCount' in catalog
    assert '"Sales Posting Approved" := true' not in catalog
    assert 'BCSF Run Snapshot' not in catalog and 'BCSF Run Header' not in catalog
    for page, action in [('BCSFScenarioList', 'RemoveTemplatesPromoted'), ('BCSFScenarioCard', 'RemoveTemplatePromoted')]:
        text = (ROOT / f'src/ScenarioManagement/Pages/{page}.Page.al').read_text()
        assert f'actionref({action};' in text
        assert 'Manager.RemoveSelection(Selection)' in text
    assert 'Nach jedem Implementierungsticket' in (ROOT / 'AGENTS.md').read_text()
    print('PASS: decimal-share negative control, guarded legacy-template refresh, custom/archive/history protection, mixed sales starter and promoted safe removal. Static integration checks only; native UI/migration still required.')


if __name__ == '__main__':
    main()
