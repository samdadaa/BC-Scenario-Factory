# BackgroundProcessing – Modulspezifikation

**Status:** 16 AL-Objekte: Ausführung, Batches, Queue und begrenzte Recovery mit Checkpoints/Steuerung; zur Prüfung. **Pfad:** `src/BackgroundProcessing/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

## Fachlicher Auftrag

Job-Queue-Orchestrierung, Batchzustände, Checkpoints und Wiederaufnahme.

## Verantwortungen und gewünschte Ergebnisse

Planer/Dispatcher/Worker; adaptive Batches; Claims; Versuchsgrenzen; Status; Abbruch/Pause; fehlersichere Wiederaufnahme.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, DependencyManager, SetupManager, DataGeneration, ProcessEngine, Lifecycle, Validation. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine unbegrenzte Parallelität, keine Durchsatzgarantie. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.BackgroundProcessing`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Implementierter Stand SF-011/SF-012 – 15.11.2026

90300 Batch, 90301 Batch Status, 90302 Queue Dispatcher, 90303 Batch Worker, 90305 Run Execution, 90306 Execution Rules, 90307 Batch Runner, 90308 Queue Failure, 90309 Execution List, 90310 Schedule Request, 90311 Batch List und 90312 Run Queue. 90304 bleibt SF-013 vorbehalten. Keine behauptete BC-Laufzeitabnahme; Vertrag, Rechte, Zustände und Testgrenzen: [Herkunft und Queue](../../../EXECUTION_REGISTRY.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## SF-013 – 16.11.2026

90304 Batch Recovery, 90313 Run Control, 90314 Batch Checkpoint, 90315 Recovery Rules implementiert. Vorhandene Worker-/Runner-/Zustands-/UI-Verträge erweitert; Standardbuchungen und generischer unsicherer Replay bleiben gesperrt. [Recovery-Vertrag](../../../RECOVERY.md), [Testnachweise](../../../TESTS.md).


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/BackgroundProcessing/Codeunits/`, `src/BackgroundProcessing/Enums/`, `src/BackgroundProcessing/PageExtensions/`, `src/BackgroundProcessing/Pages/`, `src/BackgroundProcessing/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-016/SF-017 – 18.11.2026

Vorhandene Codeunit 90317 Run Quality: aktuelle Pflichtprüfungen, optionale Warnungen und abgeschlossene Summary im vorhandenen Dispatcher-/Recovery-Abschluss. Endstatus nur gemäß Summary. Keine neue Queue-/Retryfreigabe. [Vertrag und BC-Abnahmefälle](../../../VALIDATION_FINANCE.md), [lokale Nachweise](../../../TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). **Zur Prüfung**, keine nachgewiesene BC-Laufzeitabnahme.


## SF-018 – 18.11.2026

Zusätzlicher Pflichtsubscriber am Partner-Batchereignis prüft tatsächliche Sandbox/Firma, Generationserlaubnis, gespeicherte Batchbereiche, Standardjob, Worker-/Server-ID und Session-GUID. Kein neuer Commit oder Replayvertrag. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-037 – Reparaturauftrag 18.11.2026

Vorhandene gespeicherte Vorzustands-/Ready-/Identitätsfixes erhalten. Standardjob-Sitzungsprüfung und Runner-Claim-Sitzungsprüfung ergänzt; Originalprotokoll aus Paket zugänglich. Kein neuer Retry-/Commitpfad. [Aktueller Vertrag](../../../STARTER_TEMPLATES.md), [echte lokale Prüfungen und offene BC-Abnahme](../../../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**.

## SF-045 – aktueller Bestand

Vorhandene Batch-/Checkpoint-/Quality-/Recoverylogik bleibt erhalten; nur vorgeschaltete Vorbereitung im festen Standardjob 90361. Keine neue Wiederholungsfreigabe.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

ExecutionRules bestätigt nur vollständige Customer/Vendor/Item-Batches mit bestätigten Ergebnissen/Checkpoints. Terminal fehlgeschlagene Quellen gemäß Nutzerfreigabe zulässig. Claims/Recovery/NeedsReview unverändert. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.
