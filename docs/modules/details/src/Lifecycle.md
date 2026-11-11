# Lifecycle – Modulspezifikation

**Status:** Teilweise implementiert (2 AL-Objekte), zur Prüfung; weitere Funktionen geplant. **Pfad:** `src/Lifecycle/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

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
