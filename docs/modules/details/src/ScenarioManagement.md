# ScenarioManagement – Modulspezifikation

**Status:** Teilweise implementiert, 21 AL-Objekte, Zur Prüfung. **Pfad:** `src/ScenarioManagement/`. Historische Planungsangaben unten gelten nur für noch nicht implementierte Teile.

## Fachlicher Auftrag

Szenariovorlagen, Versionierung, Konfiguration je Entity, Nutzungsziel und eingefrorene Run-Snapshots.

## Verantwortungen und gewünschte Ergebnisse

Vorlage/Revision; Branchenauswahl; Modul- und Entity-Ziele; Seed; Zeitraum; Validierung von widersprüchlichen Eingaben.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ModuleRegistry. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine Datenbankeinrichtung und keine Generierung im UI-Trigger. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.ScenarioManagement`; Präfix: `BCSF`. Die Vorlagen-/Ziel-/Snapshot-Objekte sind seit SF-005/SF-006 vorhanden; Run Step und Wizard bleiben Planung. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.

## Aktueller Stand SF-005/SF-006 und Sprachen

Fünf Tabellen, drei Enums, acht Pages und vier Codeunits für Vorlagen, Ziele, Kopien/Revisionen und atomare unveränderliche Draft-Snapshots. Kein Profil-/Generator-/Queue-/Run-Step- oder Wizard-Ersatz. Live- und eingefrorene Namensvorschauen verwenden den Sprachvertrag.

Vertrag, konkrete Objekte, Datenfluss und offene Laufzeitprüfungen: [SCENARIO_CONFIGURATION.md](../../../SCENARIO_CONFIGURATION.md), [OBJECT_PLAN.md](../../../OBJECT_PLAN.md), [TESTS.md](../../../TESTS.md).


## Aktueller Nachweis SF-007/SF-008

Reale Dateien:

- `BCSFDataTarget.Table.al`
- `BCSFDataTargets.Page.al`
- `BCSFEntityType.Enum.al`
- `BCSFFrozenModules.Page.al`
- `BCSFFrozenTargets.Page.al`
- `BCSFModuleType.Enum.al`
- `BCSFQuantityPreset.Enum.al`
- `BCSFRunCard.Page.al`
- `BCSFRunHeader.Table.al`
- `BCSFRunList.Page.al`
- `BCSFRunSnapshot.Table.al`
- `BCSFRunStep.Table.al`
- `BCSFScenario.Table.al`
- `BCSFScenarioCard.Page.al`
- `BCSFScenarioDBEvents.Codeunit.al`
- `BCSFScenarioList.Page.al`
- `BCSFScenarioManager.Codeunit.al`
- `BCSFScenarioModule.Table.al`
- `BCSFScenarioModules.Page.al`
- `BCSFScenarioPolicy.Codeunit.al`
- `BCSFSnapshotWriter.Codeunit.al`

Verantwortung, Datenfluss, temporäre/persistente Tabellen, Versionierung und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](../../../GENERATOR_PLANNING.md). Build/Übersetzung lokal geprüft; Selbstprüfungen nur kompiliert, kein BC-Laufzeittest. Fachgeneratoren und Queue weiterhin geplant.
