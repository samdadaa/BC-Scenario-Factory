# ProcessEngine – Modulspezifikation

**Status:** 1 AL-Objekt für SF-021-Prozessquoten, Mengen und Datum implementiert, zur Prüfung. **Pfad:** `src/ProcessEngine/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

## Fachlicher Auftrag

Standardkonforme Dokumentketten und konfigurierbare Buchungs-/Folgeprozesse.

## Verantwortungen und gewünschte Ergebnisse

Ungebuchte, gebuchte, teilweise erfüllte Vorgänge; passende Buchungscodeunits; Ergebnisabgleich.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, DataGeneration, Lifecycle. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine direkten Ledger-Inserts und kein automatischer Retry nach unklarer Buchung. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.ProcessEngine`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Ablage – SF-002, 16.11.2026

Weiterhin kein AL-Code; der Modulmarker bleibt erhalten. Typordner entstehen erst mit vorhandenen Objekten. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.

## SF-021 – aktueller Stand, 20.11.2026

Ein reales Objekt 90275 BCSF Process Coordinator unter Codeunits/: generische deterministische Prozessquoten, gerade Basismengen für Halbteilung und Periodendatum. BC-Sales-APIs bleiben im Sales-Modul, keine Rückabhängigkeit auf Fachgeneratoren und keine neuen Tabellen/Seiten. [Vertrag](../../../SALES_PROCESS.md), [Prüfungen](../../../TESTS.md#sf-021--verkaufsprozess-20112026). **Zur Prüfung**. Historische Abschnitte „ohne Code“ oben gelten nur für den damaligen Stand.

## SF-045 – aktueller Bestand

Gemeinsame deterministische Datums-/Mengenableitung wird für Einkaufsbestellungen wiederverwendet; keine duplizierte Branchenprozessengine.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## 1.0.7.0 – aktueller Folgeumfang

Beschaffungsdatum am Zeitraumstart, ausreichend beschaffte Menge vor geplanten Verkaufsbuchungen; echte halbe Bestelleingänge. Bestehende deterministische Quoten-/Datumsableitung bleibt gemeinsam. [Gemeinsamer Vertrag](../../../INDUSTRY_INITIALIZATION.md). **Zur Prüfung**, native Abnahme offen.
