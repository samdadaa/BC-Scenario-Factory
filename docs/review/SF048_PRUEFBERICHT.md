# SF-048 – Implementierung und tatsächliche Prüfung, 22.11.2026

**Status: Zur Prüfung.** Auftrag: zuerst den SF-047-Zahlungsfehler `Sachposten, Lfd. Nr. 0` beheben, danach SF-048 aus dem Nutzeranhang implementieren. Nutzer bestätigt ausdrücklich die Nutzung vollständiger, erneut geprüfter Stammdatenpakete aus fehlgeschlagenen Läufen. [Bedienung und Architekturvertrag](../MODULAR_GENERATION.md).

## Änderung und Kompatibilität

Main **1.0.9.0**, separate Test-App **1.5.0.0**. App-ID, Publisher, Runtime 17, Application-Mindestversion 28 und Dependencies unverändert. 145 Main-AL-Objekte (zuvor 143). Neu ausschließlich Enum 90114 und lesende Codeunit 90259. Setupfelder 29–36 und Szenariofelder 45/46 additiv. Keine neue Tabelle, Seite, Batchengine, Laufzeitbibliothek oder ForceSync. Alle vorhandenen Workspaceänderungen einschließlich TRADE/6 erhalten.

Bestehender Workflow um drei Laufarten, Quelle, Module und Belegmengen ergänzt. Der Planner überspringt die Neuanlage der gebundenen Stammdaten. Source-Dienst und ExecutionRules bestätigen Firma, Profil, alle drei Stammdatenpakete, Checkpoints und lebende Identitäten. Sales-v4 friert explizite Fremdlaufreferenzen ein; historische Sales-v1/2/3-Verträge bleiben gültig. Kein erneutes Registrieren als neue Stammdaten. Jede neue Ausführung erhält neue IDs und eigene Checkpoints. Aktiver oder pausierter Vorgänger sperrt einen neuen Unternehmensstart; terminale alte Läufe werden erhalten. Recovery-/NeedsReview-Verträge bleiben bestehen.

Bestand wird aktuell, stichtagsbezogen und nach Reservierungen geprüft. Bei Sales-only wird bestätigter Eigenbedarf nicht doppelt angesetzt. Der Artikellock und die vorhandene serielle BCSF-Verarbeitung bleiben wirksam. Standardbuchungen bleiben unverändert; Zahlungen sind nur im ausdrücklich gewählten Folgemodus möglich. Neue Tests sind Ergänzungen im bestehenden Testobjekt.

## Lokale Nachweise

| Tatsächlich ausgeführte Prüfung | Ergebnis und Grenze |
| --- | --- |
| `python3 scripts/build_sf019.py --output /tmp/bcsf-sf048-release` | **PASS** Main 145 Objekte und separate Test-App mit **64 Testmethoden** kompiliert; keine Compilerwarnung. Lokale BC-28.5-Symbole, AL-Compiler 18.1.43.24897. Keine AL-Testausführung. |
| `python3 scripts/build_sf019.py --analyzers --output /tmp/bcsf-sf048-analysis-release` | **Nicht bestanden:** genau acht bereits in HEAD vorhandene AA0018 in ItemCatalog:173–180. Neu eingeführte Analyzerfehler korrigiert; endgültig keine weiteren Fehler/Warnungen. Analyzerinformationen bleiben im Log. |
| Inventory-/Sales-/Purchase-/Template-/ConfigExport-Quellprüfungen über Buildskript | **PASS**, einschließlich Standard-API-/Schlüsselverträge, Zahlungstoleranzunterdrückung und Gegenproben, 128 Exporttabellen, leerer Install-/Upgrade-Trigger und Schutz eigener/entfernter Vorlagen. Keine Standardbuchung ausgeführt. |
| `python3 scripts/check_modular_contracts.py` | **PASS** lesende Quelle, Firmen-/Identitäts-/Checkpointschutz, terminal fehlgeschlagene Quellen, vier unsichere Mutationsgegenproben, unveränderlicher Request, keine neuen Stammdatentargets, alter Sales-Vertrag und drei neue geschützte Starter. Quellvertrag, kein native BC-Test. |
| `python3 scripts/check_partner_catalog.py` | **PASS** 28 Datenpools und numerische Katalog-/Ortsverteilung. Kein BC-Validate. |
| `python3 Translations/sync_sf_translations.py`, `python3 scripts/check_translations.py`, `python3 scripts/build_dashboard_translations.py` | **PASS** 1.448 Compilertexte, fünf deutsche Regionen und en-US; IDs, Platzhalter, Breiten, Dashboardfallback vollständig. |
| `node scripts/check_dashboard_stock.mjs`, `node scripts/check_dashboard.mjs` | **PASS** Client-/Commandbridge und Chromiumregression für Daten/Läufe, Filter, Zähler, Polling, DE/EN, XSS/ACL-Anzeigen, Responsivebreiten. Keine nativen BC-Filter/Berechtigungen ausgeführt. |
| `python3 scripts/check_package.py artifacts/BCScenarioFactory-1.0.9.0-SF048-Modular.app` | **PASS** Manifest, alle 145 aktuellen AL-Quellen, sieben XLIFF-Dateien, vier Dashboardressourcen identisch zum Workspace. |
| `git diff --check` | Nach bereinigten Ticketzeilen ohne Leerraumfehler geprüft. Kein Commit/Push/Branchwechsel/Deployment. |

Fünf neue AL-Tests **kompiliert, nicht ausgeführt**: `MovementSourceCountsRemainReferences`, `SourceBindingRejectsUnknownContracts`, `IndependentSalesOnlyAddsExplicitPurchases`, `IndependentSalesDateDoesNotInventReceipt`, `ConfirmedSourceCaptureDoesNotDuplicateRegistry`. Letzterer benötigt eine echte zulässige Quelllauf-Fixture. Insgesamt 64 Methoden einschließlich bestehender native Finanz-/Postingtests. Keine neue Test-Codeunit und kein npm-Testlauf.

## Auslieferung

- [App 1.0.9.0](../../artifacts/BCScenarioFactory-1.0.9.0-SF048-Modular.app), SHA256 `a511e2dab6197f9ea0bba52619e2b2bfd7548d45e3adcc205a7fbbe08293371e`.
- [Separate Test-App 1.5.0.0](../../artifacts/BCScenarioFactory-Tests-1.5.0.0-SF048-Modular.app).
- [Main-Buildlog](../../artifacts/BCScenarioFactory-1.0.9.0-SF048-build.log), [Test-Buildlog](../../artifacts/BCScenarioFactory-Tests-1.5.0.0-SF048-build.log), [Analyzerlog](../../artifacts/BCScenarioFactory-1.0.9.0-SF048-analyzers.log).

Paket enthält den SF-047-Zahlungsregisterfix aus 1.0.8.6 einschließlich vorheriger Toleranz-Commit-Unterdrückung. Alte Pakete bleiben erhalten. Die Version wurde weder veröffentlicht noch installiert.

## Native Fälle A–G: vollständig offen

Ziel laut Nutzertrace BC **29.1.57326.58215**; lokal ausschließlich 28.5-Symbole. Keine BC-29.1-Kompilierung, Sandboxverbindung, Datenmutation oder Testausführung erfolgt. Vor menschlicher Abnahme dort prüfen:

A. Neuer Stammdatenlauf klein: 20 Kunden, 5 Lieferanten, 40 Artikel samt Beziehungen; null Belege/Standardposten. Erneute Quellaufnahme ändert keine Registry-/Stammzahlen.

B. Nur Einkauf, Quelle A (zusätzlich Quelle aus fehlgeschlagenem Komplettlauf mit bestätigten Masterpaketen): 15 neue Bestellungen; nur ausgewählte Prozessstufe, eigene neue Run-ID, kein neuer Partner/Artikel.

C. Nur Verkauf mit 20 Aufträgen, Angebote/Rechnungen null: keine Einkaufsnodes. Ungebucht ohne Bestandsfiktion. Gebucht bei nachweislich hinreichendem aktuellen/stichtagsbezogenen Bestand; fehlender/reservierter/zwischenzeitlich verbrauchter Bestand stoppt verständlich. Nicht jede zufällige Artikelauswahl ist durch 15 Einkäufe gedeckt.

D. Weiterer Einkauf mit 10 Bestellungen, gleiche ursprüngliche Quelle; frühere 15 Bestellungen und Historie unverändert, eigene Run-/Belegidentitäten; nach terminalem Vorgänger erneut startbar.

E. Erzwungene sichere/unsichere Batchfehler: bestätigte Arbeit nicht wiederholen, `NeedsReview` nicht umgehen, aktiver/pausierter Lauf blockiert unabhängigen Unternehmensstart, neue Geschäftsläufe schreiben keine alten Claims/Checkpoints um. Bestand nach erstem Sales-Batch nur um verbleibenden Bedarf prüfen.

F. Komplettszenario als Standard, alte TRADE/5- und TRADE/6-Snapshots sowie Sales-v1/2/3 weiter prüfen. Eigene/archivierte/entfernte Starter und historische Läufe erhalten. Neue Starter wiederholt laden, Quellenpflicht und deutsch/englische UI testen. Konfigexport weiterhin manuell im aktuellen Mandanten.

G. Ungültige/fremde/aktive/unvollständige Quelle, fehlender Checkpoint, gelöschte oder gesperrte Identität, fehlende Basiseinheit/Lieferantenbeziehung, manipulierte Quelle/Request/Berechtigungen müssen stoppen. Quelländerung zwischen Erfassung und Ausführung prüfen. Zahlung nur im gewählten Folgemodus, reale Kunden-/Lieferantenzahlungen und Ausgleich ohne G/L-0-/Commitfehler nachweisen. Gleichzeitige externe Buchungen/Reservierungen, große Mengen/Laufzeiten/Locks und Dashboard-Drilldowns nativ abnehmen.

## Querschnitt und Risiken

Dashboard/Workflow zeigen Laufart, Module und Quelle; gezählt werden neue Resultate. Stammdaten werden geprüft und referenziert; Einrichtung wird über bestehende Finanz-/Buchungs-/Lagerprüfungen abgesichert; alle neuen Texte DE/EN. Keine zusätzliche Finanzinitialisierung in Fachgeneratoren und keine installbedingte Mandantenschleife. Quellaufnahme prüft viele Identitäten; Zeit-/Lockverhalten bei großen Mengen ist **zu prüfen**, kein Performanceversprechen. Echte Zahlungen und native UI bleiben der wesentliche offene Nachweis; Status höchstens **Zur Prüfung**.
