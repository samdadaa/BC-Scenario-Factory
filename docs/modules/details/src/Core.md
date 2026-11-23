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


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/Core/Codeunits/`, `src/Core/Enums/`, `src/Core/Pages/`, `src/Core/PermissionSets/`, `src/Core/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-016/SF-017 – 18.11.2026

Vorhandenes Enum 90113 Finance Mode mit Existing/SKR03/SKR04 im Inventar erfasst; ValidationFailed bleibt Endzustand 13. Keine neue App-Abhängigkeit. [Vertrag und BC-Abnahmefälle](../../../VALIDATION_FINANCE.md), [lokale Nachweise](../../../TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). **Zur Prüfung**, keine nachgewiesene BC-Laufzeitabnahme.

## SF-045 – aktueller Bestand

Sechs additive technische Requestfelder im vorhandenen Factory Setup; bestehende Setupkarte wird fünfstufiger Unternehmensassistent. Keine zusätzliche Benutzerseite.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-022 – Modulauswahl 1.0.7.2

Setupkarte jetzt mit sechs Schritten einschließlich Modulauswahl; optionales Requestfeld 27 `Industry Additional Modules`, keine neue Seite/Tabelle. [Vertrag und native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072), [lokale Prüfnachweise](../../../TESTS.md#sf-022--modulauswahl-1072). **Zur Prüfung**, keine BC-Laufzeitabnahme.


## SF-022 – Datumszeitraum 1.0.7.3

Bestehende Setupkarte erfasst Start bis gestern, Requestfeld 28 hält Ende. Contract JSON validiert optionale datePolicyVersion 1; fehlende Version erhält alte Datumssemantik. [Vertrag/offene native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Neues Enum 90114 und additive Setup-Requestfelder 29–36; bestehende Setupkarte zeigt drei Laufarten, Quelle, Module/Mengen. ADMIN enthält Execute 90259, keine neuen Standard-Schreibrechte. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.


## SF-050 – aktuelle Umsetzung 1.0.11.0 / 23.11.2026

Isolierte neue Geschäftsvorfälle, lesende Prüfung der tatsächlich gewählten Quellen, atomare No-write-Skip-Checkpoints, fortgesetzte unabhängige Pending-Arbeit und unveränderte NeedsReview-Sperren. Bestehende Einrichtungen werden nur im bestätigten Foundationpfad ergänzt; neue interne Vorlagen verwenden konkrete kompatible Zuordnungen. Quellen, betroffene Moduldateien, Ergebnis-/Listenvertrag und Grenzen im [aktuellen Prüfbericht](../../../review/SF050_PRUEFBERICHT.md). Fünf neue Methoden im vorhandenen Testobjekt; lokale Nachweise dort, native Modulabnahme N01–N08 durch den Nutzer noch offen. **Zur Prüfung**, SF-051–SF-053 nicht umgesetzt.
