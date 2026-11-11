# Core – Modulspezifikation

**Status:** Teilweise implementiert, 13 AL-Objekte, Zur Prüfung. **Pfad:** `src/Core/`. Historische Planungsangaben unten gelten nur für noch nicht implementierte Teile.

## Fachlicher Auftrag

Gemeinsame Basistypen, globale Einstellungen, Laufkontext und stabile Fehler-/Statuskonventionen.

## Verantwortungen und gewünschte Ergebnisse

Globale Setupwerte; Lauf-ID; nachvollziehbare Statusübergänge; Datums-/Seed-Hilfsfunktionen; Schutz vor ungewollten Schreibzugriffen.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Die weitergehenden Schnittstellen bleiben Planung; vorhandene Foundation-Signaturen stehen in [FOUNDATION.md](../../../FOUNDATION.md).

## Abhängigkeiten

Keine ausführbaren Projekt-Codeabhängigkeiten; das Permission Set referenziert Lifecycle nur deklarativ. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Kein branchenfachlicher Generator; keine direkten Buchungen. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Core`; Präfix: `BCSF`. Die Foundation-Objekte sind seit SF-003/SF-004 vorhanden; die übrigen Planzeilen sind weiterhin unimplementiert. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.

## Implementierter Stand SF-003/SF-004

Setup-Tabelle/Card, drei Enums, Permission Set, Setup Management und Run State Mgt. Datenfluss, Felder, Rechte und Grenzen siehe [FOUNDATION.md](../../../FOUNDATION.md). Tatsächlicher Build mit CodeCop/UICop gegen lokale BC-28.5-/Runtime-17-Symbole erfolgreich; Laufzeit-/Rechte-/Sandboxfälle noch offen, siehe [TESTS.md](../../../TESTS.md). Keine Fachgeneratoren oder Queue-Worker.

## Aktueller Stand SF-005/SF-006 und Sprachen

Zusätzlich Datensprachen-Enum 90108 und Language Mgt 90109; neues Factory-Sprachfeld, BC-Sprachwechselaktion und erweiterte deklarative Rechte. Sprachkatalog verwendet explizite eingefrorene Sprache, keine Änderung der persönlichen BC-Präferenzen.

Vertrag, konkrete Objekte, Datenfluss und offene Laufzeitprüfungen: [SCENARIO_CONFIGURATION.md](../../../SCENARIO_CONFIGURATION.md), [OBJECT_PLAN.md](../../../OBJECT_PLAN.md), [TESTS.md](../../../TESTS.md).


## Aktueller Nachweis SF-007/SF-008

Reale Dateien:

- `BCSFADMIN.PermissionSet.al`
- `BCSFContractJSON.Codeunit.al`
- `BCSFDataLanguage.Enum.al`
- `BCSFDependencyKind.Enum.al`
- `BCSFFactorySetup.Table.al`
- `BCSFFactorySetupCard.Page.al`
- `BCSFLanguageMgt.Codeunit.al`
- `BCSFPlanIssue.Enum.al`
- `BCSFProcessMode.Enum.al`
- `BCSFRunStateMgt.Codeunit.al`
- `BCSFRunStatus.Enum.al`
- `BCSFSetupManagement.Codeunit.al`
- `BCSFUsageMode.Enum.al`

Verantwortung, Datenfluss, temporäre/persistente Tabellen, Versionierung und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](../../../GENERATOR_PLANNING.md). Build/Übersetzung lokal geprüft; Selbstprüfungen nur kompiliert, kein BC-Laufzeittest. Fachgeneratoren und Queue weiterhin geplant.
