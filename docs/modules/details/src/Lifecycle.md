# Lifecycle – Modulspezifikation

**Status:** Teilweise implementiert, 4 AL-Objekte, Zur Prüfung. **Pfad:** `src/Lifecycle/`. Historische Planungsangaben unten gelten nur für noch nicht implementierte Teile.

## Fachlicher Auftrag

Sicherheitsgrenzen, Berechtigungen, Datensatzherkunft, Archivierung und Reset-Strategien.

## Verantwortungen und gewünschte Ergebnisse

Sandbox Guard; Permission Sets; Laufaufbewahrung; nicht-destruktive Cleanup-Pläne; Löschfreigaben.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Die weitergehenden Schnittstellen bleiben Planung; vorhandene Foundation-Signaturen stehen in [FOUNDATION.md](../../../FOUNDATION.md).

## Abhängigkeiten

Core, ScenarioManagement. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine Löschung gebuchter Ledger-Einträge als Standard-Reset. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Lifecycle`; Präfix: `BCSF`. Die Foundation-Objekte sind seit SF-003/SF-004 vorhanden; die übrigen Planzeilen sind weiterhin unimplementiert. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.

## Implementierter Stand SF-003/SF-004

Environment Guard mit verpflichtenden Setup-Datenbank-Subscribern. Datenfluss, Felder, Rechte und Grenzen siehe [FOUNDATION.md](../../../FOUNDATION.md). Tatsächlicher Build mit CodeCop/UICop gegen lokale BC-28.5-/Runtime-17-Symbole erfolgreich; Laufzeit-/Rechte-/Sandboxfälle noch offen, siehe [TESTS.md](../../../TESTS.md). Keine Fachgeneratoren oder Queue-Worker.

## Aktueller Stand SF-005/SF-006 und Sprachen

Zusätzlich Scenario Guard 90377 mit 20 Before-Subscriber-Bindungen; der bestehende Environment Guard bietet EnsureCanConfigure. Planung braucht keine aktivierte Generierung, bleibt aber sandbox-/firmen-/rechtegebunden. Nur neue temporäre Anzeigezeilen haben keine persistente Schreibprüfung.

Vertrag, konkrete Objekte, Datenfluss und offene Laufzeitprüfungen: [SCENARIO_CONFIGURATION.md](../../../SCENARIO_CONFIGURATION.md), [OBJECT_PLAN.md](../../../OBJECT_PLAN.md), [TESTS.md](../../../TESTS.md).


## Aktueller Nachweis SF-007/SF-008

Reale Dateien:

- `BCSFEnvironmentGuard.Codeunit.al`
- `BCSFPlanningGuard.Codeunit.al`
- `BCSFScenarioGuard.Codeunit.al`

Verantwortung, Datenfluss, temporäre/persistente Tabellen, Versionierung und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](../../../GENERATOR_PLANNING.md). Build/Übersetzung lokal geprüft; Selbstprüfungen nur kompiliert, kein BC-Laufzeittest. Fachgeneratoren und Queue weiterhin geplant.

Neue tatsächliche Codeabhängigkeiten: ModuleRegistry und DependencyManager für verpflichtende Guard-Subscriber; kein ausführbarer Rückverweis aus dem Planer auf Lifecycle.


## Implementierter Stand SF-011/SF-012 – 15.11.2026

90379 Provenance Guard zusätzlich zu den drei bisherigen Guards; neue direkte Ereignisabhängigkeit auf DataGeneration. Keine behauptete BC-Laufzeitabnahme; Vertrag, Rechte, Zustände und Testgrenzen: [Herkunft und Queue](../../../EXECUTION_REGISTRY.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/Lifecycle/Codeunits/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-037 – Reparaturauftrag 18.11.2026

Vier verpflichtende Datenbanksubscriber schützen den neuen firmenbezogenen Remove-Vermerk auch ohne RunTrigger. Bestehende Sandbox-/Firmen-/Standarddatengrenzen erhalten. [Aktueller Vertrag](../../../STARTER_TEMPLATES.md), [echte lokale Prüfungen und offene BC-Abnahme](../../../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**.

## SF-045 – aktueller Bestand

Vorhandene Umgebungs-/Firmen-/Rechte-/Generierungs-/Buchungsprüfungen bleiben verpflichtend. Requestparameter nach Einplanung immutable; Ergebnislauf nur durch gebundene Jobsitzung.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.
