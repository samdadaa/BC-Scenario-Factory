#!/usr/bin/env python3
"""After an AL build, merge starter/export texts using real generated XLIFF IDs."""
import sys

sys.dont_write_bytecode = True
import xml.etree.ElementTree as ET
import sync_sf_translations as base

DE = {
    'Load starter scenarios only in an approved sandbox.': 'Startvorlagen nur in einer freigegebenen Sandbox laden.',
    '%1 - %2': '%1 – %2',
    'General Business': 'Allgemeines Unternehmen',
    'Wholesale and Retail': 'Groß- und Einzelhandel',
    'E-Commerce': 'E-Commerce',
    'Distribution and Logistics': 'Distribution und Logistik',
    'Manufacturing': 'Fertigung',
    'Services and Consulting': 'Dienstleistung und Beratung',
    'Construction and Projects': 'Bau- und Projektgeschäft',
    'Service and Maintenance': 'Service und Wartung',
    'Demo Partners': 'Demo: Debitoren und Kreditoren',
    'Training Partners': 'Schulung: Debitoren und Kreditoren',
    'Functional Partner Test': 'Funktionstest: Debitoren und Kreditoren',
    'Partner Volume Test': 'Lasttest-Vorlage: Debitoren und Kreditoren',
    'Planning Only: Open Documents': 'Nur Planung: Offene Belege',
    'Planning Only: Posted Movements': 'Nur Planung: Gebuchte Bewegungen',
    'Planning Only: Follow-Up Processes': 'Nur Planung: Folgeprozesse',
    'Scenario bundles (*.json)|*.json': 'Szenariopakete (*.json)|*.json',
    'Select between 1 and 250 scenarios per bundle.': 'Wählen Sie pro Paket 1 bis 250 Szenarien aus.',
    'The file is not a Scenario Factory bundle in supported schema version 1.': 'Die Datei ist kein Scenario-Factory-Paket der unterstützten Schemaversion 1.',
    'The scenario bundle must not be empty or exceed 4 MiB.': 'Das Szenariopaket darf nicht leer oder größer als 4 MiB sein.',
    'The scenario bundle contains an invalid value for %1.': 'Das Szenariopaket enthält einen ungültigen Wert für %1.',
    'Import %1 scenarios as new copies in the current company? Existing scenarios are not replaced.': '%1 Szenarien im aktuellen Mandanten als neue Kopien importieren? Vorhandene Szenarien werden nicht ersetzt.',
    'Imported %1 scenarios. Check copied posting group and payment term codes in this company before running.': '%1 Szenarien importiert. Prüfen Sie vor dem Ausführen die übernommenen Buchungsgruppen und Zahlungsbedingungen im Zielmandanten.',
    'The existing setup conflicts with the reserved partner demo setup. Select compatible existing settings instead.': 'Die vorhandene Einrichtung steht im Konflikt mit der reservierten Partner-Testeinrichtung. Wählen Sie stattdessen kompatible vorhandene Einstellungen.',
    'Partner demo setup can only be prepared in a sandbox test company without G/L entries.': 'Die Partner-Testeinrichtung kann nur in einem Sandbox-Testmandanten ohne Sachposten vorbereitet werden.',
    'Germany': 'Deutschland',
    'Scenario Factory test terms %1': 'Scenario Factory Test-Zahlungsbedingung %1',
    'Scenario Factory Test Receivables': 'Scenario Factory Test-Forderungen',
    'Scenario Factory Test Payables': 'Scenario Factory Test-Verbindlichkeiten',
    'Scenario Factory Partner Test': 'Scenario Factory Partnertest',
    'Quick run supports only customer and vendor master data. Use guided planning to inspect other templates.': 'Der Schnellstart unterstützt nur Debitoren- und Kreditorenstammdaten. Andere Vorlagen prüfen Sie im Planungsassistenten.',
    'Start %1 in company %2? This prepares missing demo partner setup and enables test data generation in the company. No posting is approved.': '%1 in Mandant %2 starten? Fehlende Partner-Testeinrichtung wird ergänzt und die Testdatenerzeugung im Mandanten aktiviert. Es werden keine Buchungen freigegeben.',
    'Start %1 in company %2 using its existing BC setup? This enables test data generation in the company. No posting is approved.': '%1 in Mandant %2 mit der bestehenden BC-Einrichtung starten? Dies aktiviert die Testdatenerzeugung im Mandanten. Es werden keine Buchungen freigegeben.',
    'Run Partner Scenario': 'Partnerszenario ausführen',
    'Checks, captures and schedules the selected partner scenario in the approved sandbox after confirmation.': 'Prüft, erfasst und plant das gewählte Partnerszenario nach Bestätigung in der freigegebenen Sandbox ein.',
    'Load Starter Scenarios': 'Startvorlagen laden',
    'Adds missing built-in starter scenarios without replacing existing templates or starting a run.': 'Ergänzt fehlende Startvorlagen, ohne vorhandene Vorlagen zu ersetzen oder einen Lauf zu starten.',
    'Export Selected Scenarios': 'Ausgewählte Szenarien exportieren',
    'Downloads the selected scenarios and their settings together in one JSON file.': 'Lädt die ausgewählten Szenarien einschließlich Einstellungen gemeinsam als JSON-Datei herunter.',
    'Import Scenario Bundle': 'Szenariopaket importieren',
    'Imports multiple scenarios from a JSON file as new copies without starting any runs.': 'Importiert mehrere Szenarien aus einer JSON-Datei als neue Kopien, ohne Läufe zu starten.',
}

if __name__ == '__main__':
    generated = ET.parse(base.ROOT / f'{base.NAME}.g.xlf')
    sources = {base.source(u) for u in generated.iter(base.Q('trans-unit'))}
    if not DE.keys() <= sources:
        raise SystemExit('Build the current AL sources first. The generated XLIFF does not yet contain all starter-template strings. No files were changed.')
    base.DE.update(DE)
    base.sync()
