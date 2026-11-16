# DataGeneration – Modulspezifikation

**Status:** 6 AL-Objekte: Seed, Vorschau und immutable Herkunftsregistry; zur Prüfung. **Pfad:** `src/DataGeneration/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

## Fachlicher Auftrag

Deterministische synthetische Werte und konsistente Stammdaten-/Beziehungsgenerierung.

## Verantwortungen und gewünschte Ergebnisse

Seed + LogicalKey; synthetische Lokalisierung; Verteilungen; eindeutige Identitäten; Herkunftsregistry.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine echten Kundendaten; keine generischen unvalidierten Inserts. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.DataGeneration`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Implementierter Stand SF-009/SF-010 – 15.11.2026

90250 Seed Engine; 90253 Run Synthetic Preview. Keine Standarddatenmutation. Vertrag, Rechte, Transaktionsgrenzen und reale Prüfnachweise: [Setup und Seed](../../../SETUP_SEED.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Implementierter Stand SF-011/SF-012 – 15.11.2026

90251 Generated Record, 90252 Record Registry, 90254 Generated Records und 90255 Run Provenance zusätzlich zur Seed-Basis. Keine behauptete BC-Laufzeitabnahme; Vertrag, Rechte, Zustände und Testgrenzen: [Herkunft und Queue](../../../EXECUTION_REGISTRY.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/DataGeneration/Codeunits/`, `src/DataGeneration/PageExtensions/`, `src/DataGeneration/Pages/`, `src/DataGeneration/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.
