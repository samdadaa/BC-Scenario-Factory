#!/usr/bin/env python3
"""After an AL build, merge starter/export texts using real generated XLIFF IDs."""
import json
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

# Repair workflow texts; IDs always come from a fresh compiler catalogue.
DE.update({
 'The checkpoint result for batch %1 is empty or invalid JSON. Review the original queue error and saved results; do not repeat claimed work automatically.': 'Das Checkpoint-Ergebnis für Paket %1 ist leer oder enthält ungültiges JSON. Prüfen Sie den ursprünglichen Warteschlangenfehler und die gespeicherten Ergebnisse. Übernommene Arbeit nicht automatisch wiederholen.',

 'Affected Batch': 'Betroffenes Paket',
 'Opens the batch associated with the original queue error or the first unconfirmed failure.': 'Öffnet das Paket zum ursprünglichen Warteschlangenfehler oder zum ersten unbestätigten Fehler.',
 'The batch failed before claim. Read the original error, correct setup or permissions, then use Diagnostics, Batches, Retry Unclaimed Failure. The server checks that no work was claimed or recorded.': 'Das Paket ist vor der Übernahme fehlgeschlagen. Lesen Sie den ursprünglichen Fehler und korrigieren Sie Einrichtung oder Rechte. Verwenden Sie danach Diagnose, Pakete, Nicht übernommenes Fehlerpaket wiederholen. Der Server prüft, dass keine Arbeit übernommen oder registriert wurde.',
 'Open Show Errors to inspect the failed final validation. Existing results are retained; do not repeat generation to repair an unverified result.': 'Öffnen Sie „Fehler anzeigen“, um die fehlgeschlagene Abschlussprüfung zu prüfen. Vorhandene Ergebnisse bleiben erhalten. Wiederholen Sie die Erzeugung nicht zur Korrektur eines ungeprüften Ergebnisses.',

 'Entity': 'Entität',
 'Module': 'Modul',
 'Shows the entity name in the session language.': 'Zeigt den Entitätsnamen in der Sitzungssprache.',
 'Shows the module name in the session language.': 'Zeigt den Modulnamen in der Sitzungssprache.',
'%1 [%2]; ': '%1 [%2]; ',
 '%1 of %2': '%1 von %2',
 'Archived': 'Archiviert',
 'Availability': 'Verfügbarkeit',
 'Checks, prepares and starts this captured partner run with one confirmation.': 'Prüft und startet diesen erfassten Partnerlauf nach '
                                                                                 'einer Bestätigung einschließlich Paketvorbereitung.',
 'Confirmed Batches': 'Bestätigte Pakete',
 'Current Execution Status': 'Aktueller Ausführungsstatus',
 'Delete %1 unused templates and archive %2 templates with captured runs? Used templates cannot be deleted because their run history must remain. Active jobs and results are retained. The classification is checked again before changing data.': '%1 '
                                                                                                                                                                                                                                                    'unbenutzte '
                                                                                                                                                                                                                                                    'Vorlagen '
                                                                                                                                                                                                                                                    'löschen '
                                                                                                                                                                                                                                                    'und '
                                                                                                                                                                                                                                                    '%2 '
                                                                                                                                                                                                                                                    'Vorlagen '
                                                                                                                                                                                                                                                    'mit '
                                                                                                                                                                                                                                                    'erfassten '
                                                                                                                                                                                                                                                    'Läufen '
                                                                                                                                                                                                                                                    'archivieren? '
                                                                                                                                                                                                                                                    'Verwendete '
                                                                                                                                                                                                                                                    'Vorlagen '
                                                                                                                                                                                                                                                    'sind '
                                                                                                                                                                                                                                                    'wegen '
                                                                                                                                                                                                                                                    'ihrer '
                                                                                                                                                                                                                                                    'Laufhistorie '
                                                                                                                                                                                                                                                    'nicht '
                                                                                                                                                                                                                                                    'löschbar. '
                                                                                                                                                                                                                                                    'Laufende '
                                                                                                                                                                                                                                                    'Jobs '
                                                                                                                                                                                                                                                    'und '
                                                                                                                                                                                                                                                    'Ergebnisse '
                                                                                                                                                                                                                                                    'bleiben '
                                                                                                                                                                                                                                                    'erhalten. '
                                                                                                                                                                                                                                                    'Die '
                                                                                                                                                                                                                                                    'Zuordnung '
                                                                                                                                                                                                                                                    'wird '
                                                                                                                                                                                                                                                    'vor '
                                                                                                                                                                                                                                                    'der '
                                                                                                                                                                                                                                                    'Änderung '
                                                                                                                                                                                                                                                    'erneut '
                                                                                                                                                                                                                                                    'geprüft.',
 'Delete Selected Templates': 'Ausgewählte Vorlagen löschen',
 'Deletes unused selected templates and archives templates with captured runs after showing the counts and confirming.': 'Zeigt die '
                                                                                                                         'Anzahlen und '
                                                                                                                         'löscht nach '
                                                                                                                         'Bestätigung '
                                                                                                                         'unbenutzte '
                                                                                                                         'ausgewählte '
                                                                                                                         'Vorlagen. '
                                                                                                                         'Vorlagen mit '
                                                                                                                         'erfassten Läufen '
                                                                                                                         'werden '
                                                                                                                         'archiviert.',
 'Description': 'Beschreibung',
 'Diagnostics': 'Diagnose',
 'Execution Diagnostics': 'Ausführungsdiagnose',
 'Explains the safe next action without authorizing an automatic retry.': 'Erläutert den sicheren nächsten Schritt, ohne eine automatische '
                                                                          'Wiederholung freizugeben.',
 'Explicitly restores removed and archived built-in starters without resetting custom names.': 'Stellt entfernte und archivierte '
                                                                                               'Startvorlagen ausdrücklich wieder her. '
                                                                                               'Eigene Namen bleiben erhalten.',
 'Final Validation': 'Abschlussprüfung',
 'Generated Customers': 'Erzeugte Debitoren',
 'Generated Vendors': 'Erzeugte Kreditoren',
 'Historical Initial Status': 'Historischer Anfangsstatus',
 'Includes or hides archived templates. This does not resume jobs or restore removed starters.': 'Blendet archivierte Vorlagen ein oder '
                                                                                                 'aus. Setzt keine Jobs fort und stellt '
                                                                                                 'keine entfernten Startvorlagen wieder '
                                                                                                 'her.',
 'Makes selected archived templates available for new runs after confirmation.': 'Gibt die ausgewählten archivierten Vorlagen nach '
                                                                                 'Bestätigung wieder für neue Läufe frei.',
 'Missing reference codes in this company: %1. Review these template settings before starting. Imported templates have not started any runs.': 'Fehlende '
                                                                                                                                               'Referenzcodes '
                                                                                                                                               'in '
                                                                                                                                               'diesem '
                                                                                                                                               'Mandanten: '
                                                                                                                                               '%1. '
                                                                                                                                               'Prüfen '
                                                                                                                                               'Sie '
                                                                                                                                               'diese '
                                                                                                                                               'Vorlageneinstellungen '
                                                                                                                                               'vor '
                                                                                                                                               'dem '
                                                                                                                                               'Start. '
                                                                                                                                               'Durch '
                                                                                                                                               'den '
                                                                                                                                               'Import '
                                                                                                                                               'wurden '
                                                                                                                                               'keine '
                                                                                                                                               'Läufe '
                                                                                                                                               'gestartet.',
 'Next Step': 'Nächster Schritt',
 'Not started': 'Noch nicht gestartet',
 'Only partner master data has executable generators. Other templates support planning only.': 'Ausführbare Generatoren gibt es nur für '
                                                                                               'Debitoren- und Kreditorenstammdaten. '
                                                                                               'Andere Vorlagen dienen nur der Planung.',
 'Open Generated Partner': 'Erzeugten Partner öffnen',
 'Open Results': 'Ergebnisse öffnen',
 'Open Show Errors and review the affected batch. Claimed work must not be repeated without a verified checkpoint. Recovery actions are under Diagnostics.': 'Öffnen '
                                                                                                                                                             'Sie '
                                                                                                                                                             '„Fehler '
                                                                                                                                                             'anzeigen“ '
                                                                                                                                                             'und '
                                                                                                                                                             'prüfen '
                                                                                                                                                             'Sie '
                                                                                                                                                             'das '
                                                                                                                                                             'betroffene '
                                                                                                                                                             'Paket. '
                                                                                                                                                             'Übernommene '
                                                                                                                                                             'Arbeit '
                                                                                                                                                             'darf '
                                                                                                                                                             'ohne '
                                                                                                                                                             'geprüften '
                                                                                                                                                             'Checkpoint '
                                                                                                                                                             'nicht '
                                                                                                                                                             'wiederholt '
                                                                                                                                                             'werden. '
                                                                                                                                                             'Aktionen '
                                                                                                                                                             'zur '
                                                                                                                                                             'Wiederaufnahme '
                                                                                                                                                             'finden '
                                                                                                                                                             'Sie '
                                                                                                                                                             'unter '
                                                                                                                                                             '„Diagnose“.',
 'Opens only customers whose stable identities were recorded for this run.': 'Öffnet nur die Debitoren, deren stabile Identitäten diesem '
                                                                             'Lauf zugeordnet sind.',
 'Opens only vendors whose stable identities were recorded for this run.': 'Öffnet nur die Kreditoren, deren stabile Identitäten diesem '
                                                                           'Lauf zugeordnet sind.',
 'Opens the earliest failed standard log for this batch job, including registered error details and the call stack.': 'Öffnet das früheste '
                                                                                                                      'fehlerhafte '
                                                                                                                      'Standardprotokoll '
                                                                                                                      'dieses Paketjobs '
                                                                                                                      'einschließlich '
                                                                                                                      'registrierter '
                                                                                                                      'Fehlerdetails und '
                                                                                                                      'Aufrufliste.',
 'Opens the exact customer or vendor by its recorded stable identity.': 'Öffnet den genauen Debitor oder Kreditor anhand seiner '
                                                                        'gespeicherten stabilen Identität.',
 'Opens the provenance of records created by this run. Each partner result opens its exact standard record.': 'Öffnet die '
                                                                                                              'Ergebniszuordnungen dieses '
                                                                                                              'Laufs. Jeder Partnereintrag '
                                                                                                              'öffnet den genauen '
                                                                                                              'Standarddatensatz.',
 "Opens this run's original queue error or failed validation, with the affected batch retained for safe review.": 'Öffnet den '
                                                                                                                  'ursprünglichen '
                                                                                                                  'Warteschlangenfehler '
                                                                                                                  'oder die '
                                                                                                                  'fehlgeschlagene Prüfung '
                                                                                                                  'dieses Laufs. Das '
                                                                                                                  'betroffene Paket bleibt '
                                                                                                                  'zur sicheren Prüfung '
                                                                                                                  'erhalten.',
 'Original Queue Error': 'Ursprünglicher Warteschlangenfehler',
 'Partner Master Data': 'Debitoren- und Kreditorenstammdaten',
 'Planning Only': 'Nur Planung',
 'Progress and Results': 'Fortschritt und Ergebnisse',
 'Refreshes the run and opens its confirmed step progress.': 'Aktualisiert den Lauf und öffnet den bestätigten Schrittfortschritt.',
 'Removed Scenario Template': 'Entfernte Szenariovorlage',
 'Removed template identities cannot be changed. Restore starter templates explicitly.': 'Identitäten entfernter Vorlagen können nicht '
                                                                                         'geändert werden. Stellen Sie Startvorlagen '
                                                                                         'ausdrücklich wieder her.',
 'Restore Removed Starter Templates': 'Entfernte Startvorlagen wiederherstellen',
 'Restore Selected Templates': 'Ausgewählte Vorlagen wiederherstellen',
 'Restore all removed or archived built-in starter templates? Custom names are retained.': 'Alle entfernten oder archivierten '
                                                                                           'Startvorlagen wiederherstellen? Eigene Namen '
                                                                                           'bleiben erhalten.',
 'Restore the selected archived templates for new runs?': 'Die ausgewählten archivierten Vorlagen wieder für neue Läufe freigeben?',
 'Scenario ID': 'Szenario-ID',
 'Show Errors': 'Fehler anzeigen',
 'Show Original Queue Error': 'Ursprünglichen Warteschlangenfehler anzeigen',
 'Show or Hide Archived Templates': 'Archivierte Vorlagen ein-/ausblenden',
 'Shows confirmed completed batches compared with all prepared batches.': 'Zeigt die bestätigten abgeschlossenen Pakete im Vergleich zu '
                                                                          'allen vorbereiteten Paketen.',
 'Shows the current background execution state. Refresh this page to read the latest persisted progress.': 'Zeigt den aktuellen Status der '
                                                                                                           'Hintergrundausführung. '
                                                                                                           'Aktualisieren Sie die Seite '
                                                                                                           'für den neuesten gespeicherten '
                                                                                                           'Fortschritt.',
 'Shows the earliest available failed queue message. Use Show Errors for its full registered details and call stack.': 'Zeigt die früheste '
                                                                                                                       'verfügbare '
                                                                                                                       'Warteschlangenfehlermeldung. '
                                                                                                                       '„Fehler anzeigen“ '
                                                                                                                       'öffnet die '
                                                                                                                       'vollständigen '
                                                                                                                       'registrierten '
                                                                                                                       'Details und die '
                                                                                                                       'Aufrufliste.',
 'Shows the localized default name. Editing saves a custom name for this template.': 'Zeigt den übersetzten Standardnamen. Eine '
                                                                                     'Bearbeitung speichert einen eigenen Namen für diese '
                                                                                     'Vorlage.',
 'Shows the saved final validation result for this run.': 'Zeigt das gespeicherte Ergebnis der Abschlussprüfung dieses Laufs.',
 'Shows the template name in the session language when it is an unchanged built-in name.': 'Zeigt unveränderte mitgelieferte Vorlagennamen '
                                                                                           'in der Sitzungssprache.',
 'Specifies that this template is hidden for new runs. Historical runs and active jobs are retained.': 'Gibt an, dass diese Vorlage für '
                                                                                                       'neue Läufe ausgeblendet ist. '
                                                                                                       'Historische Läufe und laufende '
                                                                                                       'Jobs bleiben erhalten.',
 'Start': 'Starten',
 'Start this captured partner run after rechecking its setup and permissions? Test generation will be enabled. Existing or uncertain batches are not repeated.': 'Diesen '
                                                                                                                                                                 'erfassten '
                                                                                                                                                                 'Partnerlauf '
                                                                                                                                                                 'nach '
                                                                                                                                                                 'erneuter '
                                                                                                                                                                 'Prüfung '
                                                                                                                                                                 'von '
                                                                                                                                                                 'Einrichtung '
                                                                                                                                                                 'und '
                                                                                                                                                                 'Rechten '
                                                                                                                                                                 'starten? '
                                                                                                                                                                 'Die '
                                                                                                                                                                 'Testdatenerzeugung '
                                                                                                                                                                 'wird '
                                                                                                                                                                 'aktiviert. '
                                                                                                                                                                 'Vorhandene '
                                                                                                                                                                 'oder '
                                                                                                                                                                 'unsichere '
                                                                                                                                                                 'Pakete '
                                                                                                                                                                 'werden '
                                                                                                                                                                 'nicht '
                                                                                                                                                                 'wiederholt.',
 'Technical Details': 'Technische Details',
 'The original queue error is not available. Review the affected batch and obtain the earliest failed standard job queue log, including its full error and call stack. Do not repeat claimed work without a verified checkpoint.': 'Der '
                                                                                                                                                                                                                                   'ursprüngliche '
                                                                                                                                                                                                                                   'Warteschlangenfehler '
                                                                                                                                                                                                                                   'ist '
                                                                                                                                                                                                                                   'nicht '
                                                                                                                                                                                                                                   'verfügbar. '
                                                                                                                                                                                                                                   'Prüfen '
                                                                                                                                                                                                                                   'Sie '
                                                                                                                                                                                                                                   'das '
                                                                                                                                                                                                                                   'betroffene '
                                                                                                                                                                                                                                   'Paket '
                                                                                                                                                                                                                                   'und '
                                                                                                                                                                                                                                   'beschaffen '
                                                                                                                                                                                                                                   'Sie '
                                                                                                                                                                                                                                   'das '
                                                                                                                                                                                                                                   'früheste '
                                                                                                                                                                                                                                   'fehlerhafte '
                                                                                                                                                                                                                                   'Standardprotokoll '
                                                                                                                                                                                                                                   'einschließlich '
                                                                                                                                                                                                                                   'vollständigem '
                                                                                                                                                                                                                                   'Fehlertext '
                                                                                                                                                                                                                                   'und '
                                                                                                                                                                                                                                   'Aufrufliste. '
                                                                                                                                                                                                                                   'Übernommene '
                                                                                                                                                                                                                                   'Arbeit '
                                                                                                                                                                                                                                   'ohne '
                                                                                                                                                                                                                                   'geprüften '
                                                                                                                                                                                                                                   'Checkpoint '
                                                                                                                                                                                                                                   'nicht '
                                                                                                                                                                                                                                   'wiederholen.',
 'This run has no visible generated partners of the selected type. Review its result provenance.': 'Für diesen Lauf sind keine erzeugten '
                                                                                                   'Partner des gewählten Typs sichtbar. '
                                                                                                   'Prüfen Sie die Ergebniszuordnungen.',
 'This template has captured runs. Archive it instead of deleting its history.': 'Diese Vorlage hat erfasste Läufe. Archivieren Sie die '
                                                                                 'Vorlage, damit die Historie erhalten bleibt.',
 'View Progress': 'Fortschritt ansehen'})

# SF-038/SF-039: maintained German master mappings; compiler IDs come from the build.
DE.update({'Cash': 'Kasse',
 'Create missing setup or fill empty number series bindings': 'Fehlende Einrichtung anlegen oder leere Nummernserienzuordnungen '
                                                              'ergänzen',
 'Domestic trade 19%': 'Inlandshandel 19 %',
 'Domestic trade requires at least one unblocked posting combination with usable G/L accounts in this table. Exact document and tax combinations must also be reviewed before posting.': 'Für '
                                                                                                                                                                                         'den '
                                                                                                                                                                                         'Inlandshandel '
                                                                                                                                                                                         'muss '
                                                                                                                                                                                         'diese '
                                                                                                                                                                                         'Tabelle '
                                                                                                                                                                                         'mindestens '
                                                                                                                                                                                         'eine '
                                                                                                                                                                                         'ungesperrte '
                                                                                                                                                                                         'Buchungskombination '
                                                                                                                                                                                         'mit '
                                                                                                                                                                                         'nutzbaren '
                                                                                                                                                                                         'Sachkonten '
                                                                                                                                                                                         'enthalten. '
                                                                                                                                                                                         'Prüfen '
                                                                                                                                                                                         'Sie '
                                                                                                                                                                                         'vor '
                                                                                                                                                                                         'einer '
                                                                                                                                                                                         'Buchung '
                                                                                                                                                                                         'zusätzlich '
                                                                                                                                                                                         'die '
                                                                                                                                                                                         'konkreten '
                                                                                                                                                                                         'Beleg- '
                                                                                                                                                                                         'und '
                                                                                                                                                                                         'Steuerkombinationen.',
 'Explains why payment processes remain blocked without approved synthetic bank details.': 'Erläutert, warum Zahlungsprozesse '
                                                                                           'ohne freigegebene synthetische '
                                                                                           'Bankdaten gesperrt bleiben.',
 'Finance foundation %1 is missing, incompatible or not writable. Review setup and permissions before applying.': 'Die '
                                                                                                                  'Finanzgrundlage '
                                                                                                                  '%1 fehlt, ist '
                                                                                                                  'inkompatibel '
                                                                                                                  'oder nicht '
                                                                                                                  'beschreibbar. '
                                                                                                                  'Prüfen Sie '
                                                                                                                  'vor dem '
                                                                                                                  'Anwenden die '
                                                                                                                  'Einrichtung '
                                                                                                                  'und '
                                                                                                                  'Berechtigungen.',
 'General Journal': 'Allgemeines Buchblatt',
 'Inventory accrual account': 'Lagerabgrenzungskonto',
 'Inventory interim account': 'Lagerzwischenkonto',
 'Locally authored SKR03/SKR04-based subset, reference year 2026. No official chart data is imported.': 'Lokal erstellter '
                                                                                                        'Teilkontenplan auf '
                                                                                                        'Basis von SKR03/SKR04, '
                                                                                                        'Bezugsjahr 2026. Es '
                                                                                                        'werden keine '
                                                                                                        'offiziellen '
                                                                                                        'Kontenrahmendaten '
                                                                                                        'importiert.',
 'No approved synthetic bank dataset is configured. Payment-ready bank accounts and payment exports are not generated. Configure and verify bank data separately before any payment process.': 'Es '
                                                                                                                                                                                               'ist '
                                                                                                                                                                                               'kein '
                                                                                                                                                                                               'freigegebener '
                                                                                                                                                                                               'synthetischer '
                                                                                                                                                                                               'Bankdatensatz '
                                                                                                                                                                                               'eingerichtet. '
                                                                                                                                                                                               'Es '
                                                                                                                                                                                               'werden '
                                                                                                                                                                                               'keine '
                                                                                                                                                                                               'zahlungsfähigen '
                                                                                                                                                                                               'Bankkonten '
                                                                                                                                                                                               'oder '
                                                                                                                                                                                               'Zahlungsexporte '
                                                                                                                                                                                               'erzeugt. '
                                                                                                                                                                                               'Richten '
                                                                                                                                                                                               'Sie '
                                                                                                                                                                                               'Bankdaten '
                                                                                                                                                                                               'vor '
                                                                                                                                                                                               'einem '
                                                                                                                                                                                               'Zahlungsprozess '
                                                                                                                                                                                               'gesondert '
                                                                                                                                                                                               'ein '
                                                                                                                                                                                               'und '
                                                                                                                                                                                               'prüfen '
                                                                                                                                                                                               'Sie '
                                                                                                                                                                                               'diese.',
 'Open Generated Record': 'Erzeugten Datensatz öffnen',
 'Opens the exact partner, ship-to address or order address by its recorded stable identity.': 'Öffnet genau den zugeordneten '
                                                                                               'Partner, die Lieferadresse oder '
                                                                                               'die Bestelladresse anhand der '
                                                                                               'gespeicherten stabilen '
                                                                                               'Identität.',
 'Opens the shared finance preview. Apply a reviewed package explicitly, then select it for this template.': 'Öffnet die '
                                                                                                             'gemeinsame '
                                                                                                             'Finanzvorschau. '
                                                                                                             'Wenden Sie ein '
                                                                                                             'geprüftes Paket '
                                                                                                             'ausdrücklich an '
                                                                                                             'und wählen Sie es '
                                                                                                             'für diese Vorlage '
                                                                                                             'aus.',
 'Partner Currency': 'Partnerwährung',
 'Partner Global Dimension 1': 'Partner: Globale Dimension 1',
 'Partner Global Dimension 2': 'Partner: Globale Dimension 2',
 'Partner Payment Method': 'Partnerzahlungsform',
 'Partner catalog logical keys must be positive.': 'Logische Schlüssel im Partnerkatalog müssen positiv sein.',
 'Partner catalog version 2 supports address countries DE and GB. Configure a supported country instead of generating inconsistent addresses for %1.': 'Der '
                                                                                                                                                       'Partnerkatalog '
                                                                                                                                                       'Version '
                                                                                                                                                       '2 '
                                                                                                                                                       'unterstützt '
                                                                                                                                                       'Adressen '
                                                                                                                                                       'in '
                                                                                                                                                       'DE '
                                                                                                                                                       'und '
                                                                                                                                                       'GB. '
                                                                                                                                                       'Wählen '
                                                                                                                                                       'Sie '
                                                                                                                                                       'ein '
                                                                                                                                                       'unterstütztes '
                                                                                                                                                       'Land; '
                                                                                                                                                       'für '
                                                                                                                                                       '%1 '
                                                                                                                                                       'werden '
                                                                                                                                                       'keine '
                                                                                                                                                       'inkonsistenten '
                                                                                                                                                       'Adressen '
                                                                                                                                                       'erzeugt.',
 'Partner generation requires effective read and write permissions for %1 before the batch starts.': 'Die Partnererzeugung '
                                                                                                     'erfordert vor dem '
                                                                                                     'Paketstart wirksame Lese- '
                                                                                                     'und Schreibberechtigungen '
                                                                                                     'für %1.',
 'Payment Readiness': 'Zahlungsbereitschaft',
 'Reuse existing setup': 'Vorhandene Einrichtung wiederverwenden',
 'Review Finance Setup': 'Finanzeinrichtung prüfen',
 'Review the finance package and confirm. Existing nonempty settings are retained.': 'Prüfen und bestätigen Sie das Finanzpaket. '
                                                                                     'Vorhandene gefüllte Einstellungen bleiben '
                                                                                     'erhalten.',
 'Specifies an existing currency. Blank uses local currency; a valid exchange rate is required.': 'Gibt eine vorhandene Währung '
                                                                                                  'an. Leer verwendet die '
                                                                                                  'Mandantenwährung; für '
                                                                                                  'Fremdwährungen ist ein '
                                                                                                  'gültiger Wechselkurs '
                                                                                                  'erforderlich.',
 'Specifies an existing payment method. This does not make bank data ready for payments.': 'Gibt eine vorhandene Zahlungsform '
                                                                                           'an. Bankdaten werden dadurch nicht '
                                                                                           'für Zahlungen freigegeben.',
 'Specifies an existing value of the first global dimension. Blank leaves the dimension unset.': 'Gibt einen vorhandenen Wert '
                                                                                                 'der ersten globalen Dimension '
                                                                                                 'an. Leer lässt die Dimension '
                                                                                                 'ungesetzt.',
 'Specifies an existing value of the second global dimension. Blank leaves the dimension unset.': 'Gibt einen vorhandenen Wert '
                                                                                                  'der zweiten globalen '
                                                                                                  'Dimension an. Leer lässt die '
                                                                                                  'Dimension ungesetzt.',
 'Use %1 for this template? Version 2 packages also select their payment terms. Existing accounts, old runs and generated partners are retained.': '%1 '
                                                                                                                                                   'für '
                                                                                                                                                   'diese '
                                                                                                                                                   'Vorlage '
                                                                                                                                                   'verwenden? '
                                                                                                                                                   'Pakete '
                                                                                                                                                   'der '
                                                                                                                                                   'Version '
                                                                                                                                                   '2 '
                                                                                                                                                   'wählen '
                                                                                                                                                   'zusätzlich '
                                                                                                                                                   'ihre '
                                                                                                                                                   'Zahlungsbedingungen '
                                                                                                                                                   'aus. '
                                                                                                                                                   'Vorhandene '
                                                                                                                                                   'Konten, '
                                                                                                                                                   'alte '
                                                                                                                                                   'Läufe '
                                                                                                                                                   'und '
                                                                                                                                                   'erzeugte '
                                                                                                                                                   'Partner '
                                                                                                                                                   'bleiben '
                                                                                                                                                   'erhalten.'})

DE['Configured partner dimensions require effective read and write permissions for default dimensions before generation.'] = 'Eingerichtete Partnerdimensionen erfordern vor der Erzeugung wirksame Lese- und Schreibberechtigungen für Vorgabedimensionen.'

# SF-038: finance preview and operation-specific permission findings.
DE.update({'Setup': 'Einrichtung','%1 blocking findings prevent applying this setup. Choose Show Blocking Findings and resolve their stated causes. This preview changes no setup.': '%1 '
                                                                                                                                                    'blockierende '
                                                                                                                                                    'Befunde '
                                                                                                                                                    'verhindern '
                                                                                                                                                    'das '
                                                                                                                                                    'Anwenden. '
                                                                                                                                                    'Wählen '
                                                                                                                                                    'Sie '
                                                                                                                                                    '„Blockierende '
                                                                                                                                                    'Befunde '
                                                                                                                                                    'anzeigen“ '
                                                                                                                                                    'und '
                                                                                                                                                    'beheben '
                                                                                                                                                    'Sie '
                                                                                                                                                    'die '
                                                                                                                                                    'dort '
                                                                                                                                                    'genannten '
                                                                                                                                                    'Ursachen. '
                                                                                                                                                    'Die '
                                                                                                                                                    'Vorschau '
                                                                                                                                                    'ändert '
                                                                                                                                                    'keine '
                                                                                                                                                    'Einrichtung.',
 'Blocking Findings': 'Blockierende Befunde',
 'Creating this missing setup record requires effective read and insert permissions. Full delete permission is not required.': 'Zum '
                                                                                                                               'Anlegen '
                                                                                                                               'dieses '
                                                                                                                               'fehlenden '
                                                                                                                               'Einrichtungsdatensatzes '
                                                                                                                               'sind '
                                                                                                                               'wirksame '
                                                                                                                               'Lese- und '
                                                                                                                               'Einfügeberechtigungen '
                                                                                                                               'erforderlich. '
                                                                                                                               'Eine '
                                                                                                                               'vollständige '
                                                                                                                               'Löschberechtigung '
                                                                                                                               'wird nicht '
                                                                                                                               'benötigt.',
 'Explains whether to apply the reviewed setup or resolve blocking prerequisites first. Closing the preview does not apply a package.': 'Erläutert, '
                                                                                                                                        'ob '
                                                                                                                                        'Sie '
                                                                                                                                        'die '
                                                                                                                                        'geprüfte '
                                                                                                                                        'Einrichtung '
                                                                                                                                        'anwenden '
                                                                                                                                        'können '
                                                                                                                                        'oder '
                                                                                                                                        'zuerst '
                                                                                                                                        'blockierende '
                                                                                                                                        'Voraussetzungen '
                                                                                                                                        'beheben '
                                                                                                                                        'müssen. '
                                                                                                                                        'Das '
                                                                                                                                        'Schließen '
                                                                                                                                        'der '
                                                                                                                                        'Vorschau '
                                                                                                                                        'wendet '
                                                                                                                                        'kein '
                                                                                                                                        'Paket '
                                                                                                                                        'an.',
 'Filters the preview to the prerequisites that prevent applying this package.': 'Filtert die Vorschau auf die Voraussetzungen, die das '
                                                                                 'Anwenden dieses Pakets verhindern.',
 'First Blocking Finding': 'Erster blockierender Befund',
 'Have an administrator review effective table permissions and license rights in this test company. Scenario Factory does not grant standard setup permissions. Reopen the preview after correction.': 'Lassen '
                                                                                                                                                                                                       'Sie '
                                                                                                                                                                                                       'die '
                                                                                                                                                                                                       'wirksamen '
                                                                                                                                                                                                       'Tabellen- '
                                                                                                                                                                                                       'und '
                                                                                                                                                                                                       'Lizenzrechte '
                                                                                                                                                                                                       'in '
                                                                                                                                                                                                       'diesem '
                                                                                                                                                                                                       'Testmandanten '
                                                                                                                                                                                                       'administrativ '
                                                                                                                                                                                                       'prüfen. '
                                                                                                                                                                                                       'Scenario '
                                                                                                                                                                                                       'Factory '
                                                                                                                                                                                                       'vergibt '
                                                                                                                                                                                                       'keine '
                                                                                                                                                                                                       'Standard-Einrichtungsrechte. '
                                                                                                                                                                                                       'Öffnen '
                                                                                                                                                                                                       'Sie '
                                                                                                                                                                                                       'die '
                                                                                                                                                                                                       'Vorschau '
                                                                                                                                                                                                       'nach '
                                                                                                                                                                                                       'der '
                                                                                                                                                                                                       'Korrektur '
                                                                                                                                                                                                       'erneut.',
 'Next Step': 'Nächster Schritt',
 'Selected Finance Setup': 'Gewählte Finanzeinrichtung',
 'Setup Review': 'Einrichtung prüfen',
 'Show All Findings': 'Alle Befunde anzeigen',
 'Show Blocking Findings': 'Blockierende Befunde anzeigen',
 'Shows blocking findings, planned additions and existing setup together. Blockers appear first.': 'Zeigt blockierende Befunde, geplante '
                                                                                                   'Ergänzungen und vorhandene Einrichtung '
                                                                                                   'gemeinsam. Blocker stehen zuerst.',
 'Shows the first blocking prerequisite and its actual finding. Use Show Blocking Findings to see every blocker.': 'Zeigt die erste '
                                                                                                                   'blockierende '
                                                                                                                   'Voraussetzung mit '
                                                                                                                   'ihrem tatsächlichen '
                                                                                                                   'Befund. Mit '
                                                                                                                   '„Blockierende Befunde '
                                                                                                                   'anzeigen“ sehen Sie '
                                                                                                                   'alle Blocker.',
 'Shows the setup being reviewed. Existing setup is only checked; an SKR package creates the reviewed missing setup after confirmation.': 'Zeigt '
                                                                                                                                          'die '
                                                                                                                                          'geprüfte '
                                                                                                                                          'Einrichtung. '
                                                                                                                                          'Vorhandene '
                                                                                                                                          'Einrichtung '
                                                                                                                                          'wird '
                                                                                                                                          'nur '
                                                                                                                                          'geprüft; '
                                                                                                                                          'ein '
                                                                                                                                          'SKR-Paket '
                                                                                                                                          'legt '
                                                                                                                                          'die '
                                                                                                                                          'geprüfte '
                                                                                                                                          'fehlende '
                                                                                                                                          'Einrichtung '
                                                                                                                                          'nach '
                                                                                                                                          'Bestätigung '
                                                                                                                                          'an.',
 'Shows why the apply action is unavailable. Resolve every blocking finding and reopen the preview.': 'Zeigt, warum die Aktion zum '
                                                                                                      'Anwenden nicht verfügbar ist. '
                                                                                                      'Beheben Sie alle blockierenden '
                                                                                                      'Befunde und öffnen Sie die Vorschau '
                                                                                                      'erneut.',
 'The existing setup check passed. Close the preview to continue. This option does not create a chart or any missing setup.': 'Die Prüfung '
                                                                                                                              'der '
                                                                                                                              'vorhandenen '
                                                                                                                              'Einrichtung '
                                                                                                                              'ist '
                                                                                                                              'bestanden. '
                                                                                                                              'Schließen '
                                                                                                                              'Sie die '
                                                                                                                              'Vorschau, '
                                                                                                                              'um '
                                                                                                                              'fortzufahren. '
                                                                                                                              'Diese '
                                                                                                                              'Option legt '
                                                                                                                              'keinen '
                                                                                                                              'Kontenplan '
                                                                                                                              'und keine '
                                                                                                                              'fehlende '
                                                                                                                              'Einrichtung '
                                                                                                                              'an.',
 'The reviewed missing setup can be created. Choose Apply Test Package and confirm. Closing this preview creates no accounts or setup.': 'Die '
                                                                                                                                         'geprüfte '
                                                                                                                                         'fehlende '
                                                                                                                                         'Einrichtung '
                                                                                                                                         'kann '
                                                                                                                                         'angelegt '
                                                                                                                                         'werden. '
                                                                                                                                         'Wählen '
                                                                                                                                         'Sie '
                                                                                                                                         '„Testpaket '
                                                                                                                                         'anwenden“ '
                                                                                                                                         'und '
                                                                                                                                         'bestätigen '
                                                                                                                                         'Sie. '
                                                                                                                                         'Das '
                                                                                                                                         'Schließen '
                                                                                                                                         'dieser '
                                                                                                                                         'Vorschau '
                                                                                                                                         'legt '
                                                                                                                                         'keine '
                                                                                                                                         'Konten '
                                                                                                                                         'oder '
                                                                                                                                         'Einrichtung '
                                                                                                                                         'an.'})

SF040_DE = {'No eligible work or the captured module, entity or batch size is incompatible.': 'Keine ausführbare Arbeit oder '
                                                                                   'unpassendes Modul, unpassende '
                                                                                   'Entität oder Paketgröße im '
                                                                                   'erfassten Lauf.',
 'No executable generator for the selected process mode. This target remains planning-only.': 'Kein ausführbarer '
                                                                                              'Generator für '
                                                                                              'diesen '
                                                                                              'Prozessmodus. Das '
                                                                                              'Ziel bleibt auf '
                                                                                              'die Planung '
                                                                                              'beschränkt.',
 'Will be generated. Current generator prerequisites passed.': 'Wird erzeugt. Die aktuellen '
                                                               'Generatorvoraussetzungen sind erfüllt.',
 'The background job checks these prerequisites again before writing records.': 'Der Hintergrundjob prüft die '
                                                                                'Voraussetzungen vor dem '
                                                                                'Schreiben erneut.',
 'Already present. Exact generator prerequisites are checked separately.': 'Bereits vorhanden. Die konkreten '
                                                                           'Generatorvoraussetzungen werden '
                                                                           'separat geprüft.',
 'Review the named prerequisite and capture a new run after correction. Use partner master data only if the selected process has no executable generator.': 'Prüfe '
                                                                                                                                                            'die '
                                                                                                                                                            'genannte '
                                                                                                                                                            'Voraussetzung '
                                                                                                                                                            'und '
                                                                                                                                                            'erfasse '
                                                                                                                                                            'nach '
                                                                                                                                                            'der '
                                                                                                                                                            'Korrektur '
                                                                                                                                                            'einen '
                                                                                                                                                            'neuen '
                                                                                                                                                            'Lauf. '
                                                                                                                                                            'Ohne '
                                                                                                                                                            'passenden '
                                                                                                                                                            'Generator '
                                                                                                                                                            'ist '
                                                                                                                                                            'nur '
                                                                                                                                                            'die '
                                                                                                                                                            'Partnerstammdatenanlage '
                                                                                                                                                            'möglich.',
 'The saved plan for generator %1 contains a prerequisite blocker. Review setup and capture a new run after correction.': 'Der '
                                                                                                                          'gespeicherte '
                                                                                                                          'Plan '
                                                                                                                          'für '
                                                                                                                          'Generator '
                                                                                                                          '%1 '
                                                                                                                          'enthält '
                                                                                                                          'einen '
                                                                                                                          'Blocker. '
                                                                                                                          'Prüfe '
                                                                                                                          'die '
                                                                                                                          'Einrichtung '
                                                                                                                          'und '
                                                                                                                          'erfasse '
                                                                                                                          'nach '
                                                                                                                          'der '
                                                                                                                          'Korrektur '
                                                                                                                          'einen '
                                                                                                                          'neuen '
                                                                                                                          'Lauf.',
 'Start blocked for %1: %2': 'Start für %1 blockiert: %2'}

if __name__ == '__main__':
    generated = ET.parse(base.ROOT / f'{base.NAME}.g.xlf')
    sources = {base.source(u) for u in generated.iter(base.Q('trans-unit'))}
    if 'Run Template' not in sources or 'Initialize Company' not in sources:
        raise SystemExit('Build the current AL sources first. Starter-template compiler IDs are missing. No files were changed.')
    DE.update({'Company Setup': 'Mandanteneinrichtung', 'Initialize Company': 'Mandant initialisieren', 'Choose the chart of accounts and prepare this sandbox company once. Does not post documents.': 'Wählt den Kontenplan und richtet diesen Sandbox-Mandanten einmalig ein. Bucht keine Belege.', 'Which chart of accounts should %1 use? This prepares the sandbox company and enables test data generation. Posting remains disabled for a new company.': 'Welchen Kontenplan soll %1 verwenden? Damit wird der Sandbox-Mandant eingerichtet und die Datengenerierung aktiviert. In einem neuen Mandanten bleibt das Buchen deaktiviert.', 'Company setup could not be completed. Review setup and permissions for the current sandbox company.': 'Die Mandanteneinrichtung konnte nicht abgeschlossen werden. Prüfen Sie Einrichtung und Berechtigungen im aktuellen Sandbox-Mandanten.', 'Company setup stopped at %1. %2 %3': 'Die Mandanteneinrichtung wurde bei %1 gestoppt. %2 %3', 'The chart of accounts captured for this run is not initialized in the current company.': 'Der für diesen Lauf erfasste Kontenplan ist im aktuellen Mandanten nicht eingerichtet.', 'Open Scenario Factory Setup and choose Initialize Company in the approved sandbox and test company.': 'Öffnen Sie die Scenario-Factory-Einrichtung und wählen Sie „Mandant initialisieren“ in der freigegebenen Sandbox und Testfirma.', 'Start this captured partner run after rechecking its setup and permissions? Existing or uncertain batches are not repeated.': 'Diesen erfassten Partnerlauf nach Prüfung von Einrichtung und Berechtigungen starten? Bestehende oder unklare Pakete werden nicht wiederholt.', 'Quick run supports only customer and vendor master data. This template depends on generators that are not available yet.': 'Der Vorlagenstart unterstützt derzeit nur Debitoren und Kreditoren. Für diese Vorlage fehlen noch Generatoren.', 'Run Template': 'Vorlage ausführen', "Starts the selected template in the background using this company's initialized setup.": 'Startet die ausgewählte Vorlage mit der Einrichtung dieses Mandanten im Hintergrund.', 'Starts the selected template in the background using the initialized company setup.': 'Startet die ausgewählte Vorlage mit der Mandanteneinrichtung im Hintergrund.', 'Shows current persisted execution status, independently of the captured initial status.': 'Zeigt den aktuellen gespeicherten Laufstatus unabhängig vom erfassten Anfangsstatus.', 'Opens the available scenario templates.': 'Öffnet die verfügbaren Szenariovorlagen.', 'Cannot start: %1. %2 %3': 'Start nicht möglich bei %1. %2 %3', 'Have an administrator review effective table permissions and license rights in this test company. Scenario Factory does not grant standard setup permissions. Run Initialize Company again after correction.': 'Lassen Sie die effektiven Tabellen- und Lizenzrechte in dieser Testfirma prüfen. Scenario Factory vergibt keine Standardrechte. Wählen Sie nach der Korrektur erneut „Mandant initialisieren“.', 'Company Initialized': 'Mandant initialisiert'})
    DE['Up to 25 recent runs. Open the run monitor for full history.'] = 'Bis zu 25 aktuelle Läufe. Die vollständige Historie findest du im Laufmonitor.'
    DE.update(SF040_DE)
    DE.update(json.loads((base.ROOT / 'sf041.de.json').read_text(encoding='utf-8')))
    DE.update(json.loads((base.ROOT / 'sf044.de.json').read_text(encoding='utf-8')))
    base.DE.update(DE)
    base.sync()
