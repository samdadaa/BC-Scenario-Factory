# SF-047 – Implementierungs- und Prüfbericht (22.11.2026)

## Umfang

TRADE-Profil 6 als Neuversionierung der bisherigen Großhandelsregeln. Die alte Version 5 wird durch bedingte Verzweigungen beibehalten. Ausgangs-Manifestversion 1.0.8.4 (Zahlungskorrektur 1.0.8.5 unten), Identität, IDs, Abhängigkeiten, Runtime und vorhandene Tabellen unverändert.

- **P1:** Entfernte Artikelpoolgrenze aus `BCSF Sales Setup` für v6; die Positionen der Einkaufsbelege greifen über Lieferantenzuordnung auf mehr Artikel aus dem Sortiment zu. Gebuchte Verkäufe bleiben an die in derselben Laufkonfiguration vorgesehenen gebuchten Einkaufsbelege gekoppelt; ungebuchte Verkäufe dürfen jeden Artikel nutzen. Das bedeutet **nicht**, dass 400 von 400 Artikeln in gebuchten Transaktionen auftauchen müssen: Die Beleganzahl und Buchungsquote begrenzen dies fachlich.
- **P2:** Bei Profil 6 wird jedes Einkaufsbestellungsdatum aus der Positionsnummer und dem vollständigen Szenariozeitraum berechnet. Für gebuchte Verkaufsbelege hebt die Datumslogik den geplanten Verkaufstag bei Bedarf auf den spätestens benötigten Empfangstag der zugeordneten Beschaffung an. Belegkopf und Buchungsprüfungen nutzen die gemeinsame Koordinatorfunktion. Ein-Tages-Läufe bleiben möglich.
- **P3:** Städte/PLZ stammen weiterhin aus 20 hinterlegten korrespondierenden Paaren; v6 besucht sie in einer vollständig gleichmäßig permutierten Reihenfolge, zufälliger seedabhängiger Startpunkt, ohne Wiederholungen vor 20 Datensätzen.

## Ursprüngliche Prüfungen des Entwurfs 1.0.8.4

- Lesen des hochgeladenen Projektstands inklusive AGENTS.md, TODO.md, app.json, Modulstruktur sowie fachlich relevanter Architektur-/Testdokumentation.
- Statische Pfad-/Versions-/Konfigurationskontrolle der geänderten Dateien.
- Numerische Simulation der deterministischen v6-Artikelzuordnung für Klein/Mittel/Groß: mittel 400 Artikel, 50 Lieferanten, 150 Einkaufsbestellungen, 120 Verkaufsaufträge und 30 Verkaufsrechnungen. Bei 150 Bestellungen werden 366 unterschiedliche Artikel referenziert, gegenüber der alten Auswahlbegrenzung der ersten 200 Artikel; 400 von 400 liegen technisch im möglichen Auswahlraum.
- Native AL-Komplilierung und tatsächlicher Sandboxlauf: **NICHT ausgeführt**, weil kein BC-AL-Compiler und keine BC-Sandbox zur Verfügung stehen. AL-Testmethoden ergänzt, aber **nicht ausgeführt**.

## Offene fachliche Abnahme (lokaler Build inzwischen unten nachgewiesen)

1. Beide AL-Projekte sind inzwischen lokal kompiliert; die Tests der vorhandenen Test-App noch nativ ausführen.
2. Neuer leerer Sandboxmandant, SKR03 mit denselben Mengen/Seed/Zeitraum wie Vorlauf (TRADE/6).
3. Insbesondere alle Artikelnummern-/Lieferantenzuordnungen, gebuchte Einkaufs- und Verkaufsdatumsfolgen, Lagerposten/negativen Bestand zum Stichtag, Teillieferungen und Mehrpositionsbelege prüfen.
4. Konfigurationspaket exportieren und nach dem Vorgängerpaket vergleichen; Stadtverteilung DE/GB und reale Laufzeiten/Queue-Wiederaufnahme beurteilen.
5. Status erst nach menschlicher Abnahme auf Erledigt setzen.

## Risiken

Die neue Datumsvorgabe kann gebuchte Verkäufe nach hinten verlagern. Mögliche AL-Compilerfehler, unerwartete BC-Standardvalidierungen sowie Leistung großer Läufe sind mangels Sandbox nicht ausgeschlossen. Weder Dashboard, Übersetzungs-UI noch Finanzpakete wurden funktional geändert; Regressionsprüfung bleibt erforderlich.

## Zahlungskorrektur 1.0.8.5 – Commit bei Ausgleichsvalidierung

**Auftrag und Ausgangslage:** Nutzer wählt ausdrücklich SF-047 und meldet in 1.0.8.4 den Fehler „Der Commit ist im aktuellen Bereich nicht zulässig“ bei gebuchten Belegen mit Zahlung/Ausgleich. Der Stack führt über `BCSF Payment Processor.Pay` → Table 81, `Applies-to Doc. No.` OnValidate → `Payment Tolerance Management.PmtTolGenJnl` → `PurchPmtTolGenJnl` → `DelVendPmtTolAcc`. Gemeldete native Base Application **29.1.57326.58215**. Einkauf scheitert, Partner/Artikel sind laut Screenshot bereits angelegt. Das ist eine fehlgeschlagene native Ausführung des Vorstands und keine Abnahme der Korrektur.

**Vor Änderung geprüft:** Aktueller Git-Diff einschließlich TRADE/6-Artikelpool, Datumsverteilung, Ortspermutation, Snapshotkompatibilität und Zahlungsänderung. XERJ ausschließlich `bcsf-docs`; dessen Treffer sind teilweise älter als der lokale Quellstand, der maßgeblich bleibt. Ziel: ausschließlich den Standardcommit vor der eigentlichen Zahlungsbuchung unterdrücken, ohne Batchatomarität/Claim/Checkpoints/Freigaben zu lockern. Betroffen: Payment Processor, Purchase-Quellvertrag, vorhandener Testhost (Kompilierbarkeit), Versionsmanifeste, fehlende Katalogübersetzung und Prüfdokumentation. Risiko: lokal nur BC-28.5-Symbole; konkrete BC-29.1-Laufzeit und Fremdsubscriber bleiben offen.

**Ursache:** Der Diff setzt `Amount` bereits vor `Applies-to Doc. No.`. Das verschiebt die Toleranzprüfung, verhindert sie aber nicht: Auch die Ausgleichsbelegvalidierung ruft die Toleranzverwaltung auf. Diese modifiziert zulässigerweise Standardposten und committet ohne gesetztes SuppressCommit; der bestehende `CommitBehavior::Error` bricht folgerichtig ab. Ein temporärer Gen.-Journal-Line-Datensatz macht die standardmäßigen Nebenwirkungen auf echte Posten nicht temporär.

**Korrektur:** Direkt nach `TempLine.Init()` wird **unbedingt für Kunden und Lieferanten** `TempLine.SetSuppressCommit(true)` aufgerufen, vor jeder Feldvalidierung. Die Standardmethode setzt sowohl das Table-Flag als auch die zugehörige Instanz von Payment Tolerance Management. Keine bloße separate Codeunitinstanz und kein Abschalten des Batchguards. Vorhandene `Validate`-Aufrufe, `Gen. Jnl.-Post Line.RunWithCheck`, echte Standardbuchung/Ausgleich, Herkunft, Restbetrags-/Datumsnachweise und unsichere-Retry-Sperren bleiben erhalten. Keine zusätzliche Berechtigung, kein Commit, keine direkte App-Schreiboperation auf Standardposten, kein Schema-/Snapshotwechsel.

**API-Nachweis:** Lokale Microsoft-Originalquellen Table 81 (`SetSuppressCommit` und Applies-to-OnValidate), Codeunit 426 (`DelCustPmtTolAcc`/`DelVendPmtTolAcc`: Commit nur bei `not SuppressCommit`) und Codeunit 12. Die öffentliche Microsoft-Referenz bestätigt [Gen. Journal Line.SetSuppressCommit](https://microsoft.github.io/BCApps/reference/base-application/Table/Microsoft.Finance.GeneralLedger.Journal.Gen.-Journal-Line.html#setsuppresscommit) und die [Commit-Unterdrückung der Zahlungstoleranzverwaltung](https://microsoft.github.io/BCApps/reference/base-application/Codeunit/Microsoft.Finance.ReceivablesPayables.Payment-Tolerance-Management.html#setsuppresscommit). Lokale Quellversion 28.5; dies ist kein nativer BC-29.1-Test.

### Tatsächlich ausgeführte lokale Prüfungen

- **PASS:** `python3 scripts/build_sf019.py --output /tmp/bcsf-sf047-paymentfix-final`: Main **1.0.8.5** und separate Test-App **1.4.0.5** gegen vorhandene BC-28.5-/Runtime-17-Symbole kompiliert, keine Compilerfehler/-warnungen. **59 AL-Testmethoden nur kompiliert**, einschließlich der drei vorhandenen SF-047-Tests; keine native Testausführung. Ein bereits im Testhost verwendeter reservierter Variablenname `Key` wurde lokal auf `ItemKey` geändert, ohne Testsemantikänderung.
- **PASS:** Erweiterter `check_purchase_contracts.py`: Standardvertrag Journal → Toleranzinstanz, Suppression vor sämtlichen Validierungen und weiterhin strenger Commitguard. Vier Negativkontrollen erkennen fehlenden, zu spät gesetzten, zurückgesetzten und auf Kundenzahlungen beschränkten Aufruf. Bestehende öffentliche Posting-API-, Schlüssel-, Rechte-, Freigabe-/Claim- und Ledger-Schreibgrenzen geprüft.
- **PASS:** Bestehende Inventory-/Sales-/Template-/ConfigExport-Quellprüfungen. Großhandelsstarter werden durch den unveränderten Starterkatalog mit `Profile.CreateTemplateForId` erstellt; dieser verwendet jetzt TRADE/6. Neues gebuchtes/Follow-up-Referenzpaar verwendet weiterhin PO 60/20/Rest, SO 50/25/Rest, Rechnungen 67/0/Rest; Angebote ungebucht. Eigene/entfernte/archivierte Starter und historische v5-Läufe nicht überschrieben. Bestehender native Evidence-Test erwartet für den kleinen Follow-up-Lauf 23 Standardzahlungen/Bankposten; weiterhin nicht ausgeführt.
- **PASS:** `check_partner_catalog.py` für den tatsächlichen 20er-Ortspool aktualisiert; unabhängige Zyklenprüfung für alle 20 Offsets, 200 logische Partner mit je zehn Besuchen pro Ort. Legacy-Auswahlraum 8 und TRADE/5-Auswahlraum 20 bleiben sourcegeprüft. Diese Daten-/Quellprüfung ersetzt keine AL-Ausführung.
- **PASS:** 1.407 Compilertexte vollständig DE/EN und fünf deutsche Regionen, `check_translations.py`; die bereits vorhandene Sortimentsgrenzenmeldung wurde in `sf047.de.json` übersetzt. `build_dashboard_translations.py --check` bestanden. Keine neue Zahlungs-UI und keine Änderung an Dashboard-JS/Seiten.
- **NICHT BESTANDEN:** Strenger CodeCop/UICop-Lauf mit Warnungen als Fehler: acht **AA0018** in unveränderten Inlineblöcken von `BCSFItemCatalog.Codeunit.al`, Zeilen 173–180. Alle acht Zeilen gegen `git show HEAD:…` als bereits vorhanden geprüft. Keine neue Payment-Analyzerdiagnose. Diese fachfremde Formatierung nicht geändert; Analyzerlog separat im Reviewpaketbestand erhalten.
- **PASS:** Paketprüfung von `artifacts/BCScenarioFactory-1.0.8.5-SF047-PaymentCommitFix.app`: Manifest, alle 143 AL-Quellen, sieben XLIFF-Dateien und vier Dashboardressourcen stimmen mit aktuellem Workspace überein. SHA256 **03a6b0c9d92fced34f39012f198ab907fb52dd0b96dec1175581d895e892fbd3**. Separate Test-App `artifacts/BCScenarioFactory-Tests-1.4.0.5-SF047-PaymentCommitFix.app`; Build-/Analyzerlogs daneben. Frühere Pakete erhalten, nicht überschrieben.

### Noch native Prüfung erforderlich

1. Korrektur in einer isolierten BC-29.1-Sandbox installieren; keine ForceSync-Anforderung. Vorhandenen fehlgeschlagenen/übernommenen Lauf weiterhin als prüfpflichtig behandeln. Die Korrektur genehmigt keinen blinden Retry und ändert keine Recoverydaten.
2. Neuen kleinen Großhandelslauf mit **gebuchten Belegen, Zahlung und Ausgleich**, expliziten Freigaben und gleichem Seed/Zeitraum starten. Einkaufs- und Verkaufsrechnung jeweils bis zur Standardzahlung prüfen. Standard-Toleranzvalidierungen müssen ohne Zwischencommit durchlaufen; der strenge Batchguard muss aktiv bleiben.
3. `CompletedSmallPostedCompanyHasStandardEvidence` nach erfolgreichem kleinen Referenzlauf sowie `CompletedPaymentCannotBeReplayedOutsideClaim` im vorhandenen Testhost ausführen. Geschlossene Rechnungs- und Zahlungsposten, Restbetrag 0, richtige Bank-/Sach-/Detailposten und Datumsgrenzen nachweisen. Erfolg derzeit **nicht beobachtet**.
4. SKR03/SKR04, vorhandene/keine Toleranzeinstellungen, Kunden-/Lieferantenseite, fehlende Rechte und Fehler während des Batches prüfen; keine halben Zahlungen/Herkunfts-/Checkpointabschlüsse. Unklare Arbeit bleibt gesperrt.
5. Dashboardzählungen/-Drilldowns und Volltabellenexport nach Abschluss mit Standardlisten abgleichen; Starter-/Unternehmensworkflow DE/EN prüfen. Stammdaten und Einrichtungen unverändert, keine neue toleranzabschaltende Setupvorgabe. Übrige fachliche SF-047-Abnahmen bleiben offen.

**Querschnitt:** Workflow/Zahlungsmodus bleiben gleich, Dashboard erhält nach erfolgreichem Standardlauf seine vorhandenen echten Ergebnisse; keine neuen Zähler oder Texte. Stammdaten/Einrichtung/Freigaben bleiben erhalten. Übersetzungen für die vorhandene Sortimentsfehlermeldung ergänzt. Keine Veröffentlichung, Sandboxaktion, Task-Scheduler-/Test-Runner-Ausführung oder Git-Commit durch den Agenten. **SF-047 bleibt Zur Prüfung.**

## Folgefehler 1.0.8.6 – Sachposten mit Lfd. Nr. 0

Der native Nutzertrace aus 1.0.8.5 zeigt einen zweiten Fehler nach der behobenen Toleranzvalidierung. `RunWithCheck` liefert bei Kunden-/Lieferantenzahlungen nicht zuverlässig die zu ladende Sachpostennummer. Die Annahme `GL.Get(RunWithCheck(...))` wurde entfernt. Nach der Standardbuchung wird das Register derselben Posting-Codeunit über `GetGLReg` gelesen; tatsächlicher Sachpostenbereich, Belegnummer, Datum und eine eindeutige positive Transaktionsnummer werden geprüft. Die Herkunftsregistrierung nutzt diese echte Transaktion. Kein `GL.Get(0)`, kein Direktinsert, kein Commit, keine Lockerung von CommitBehavior; SuppressCommit bleibt vor Feldvalidierung aktiv.

Main 1.0.8.6 und separate Test-App 1.4.0.6 wurden lokal gegen 28.5 kompiliert, nicht nativ ausgeführt. Archiv: `artifacts/BCScenarioFactory-1.0.8.6-SF047-PaymentRegisterFix.app`, SHA256 `2c2b68dde01f3041765832ad3a11a8164fd8c65c32548790445e6538cc9e21b3`. Diese Korrektur ist auch in der folgenden SF-048-Version 1.0.9.0 enthalten. [Aktueller Prüfbericht mit Grenzen](SF048_PRUEFBERICHT.md). Reale BC-29.1-Kunden-/Lieferantenzahlung und Ausgleich bleiben offen; der lokale Build beweist keine erfolgreiche Buchung.
