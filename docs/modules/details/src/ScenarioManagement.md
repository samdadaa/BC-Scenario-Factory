# ScenarioManagement – Modulspezifikation

**Status:** 22 AL-Objekte implementiert, **Zur Prüfung**. Pfad: `src/ScenarioManagement/`. Historische Planabschnitte gelten für noch nicht umgesetzte Teile.

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

## SF-014/SF-015 – 16.11.2026

Zusätzlich Page 90132 BCSF Scenario Wizard: fünf geführte Konfigurationsschritte, expliziter Snapshot und danach gesperrte Konfiguration. Bestehende Vorlagenliste/-karte um Assistentennavigation ergänzt. Plan/Preflight/Start über Monitoring-PageExtension, keine direkte Modulrückreferenz.

Reale Objekte, gerichtete Abhängigkeiten, Persistenz-/Rechtevertrag, Bedienung und offene Prüfungen: [MONITORING_WIZARD.md](../../../MONITORING_WIZARD.md), [OBJECT_PLAN.md](../../../OBJECT_PLAN.md), [TESTS.md](../../../TESTS.md). Keine BC-Laufzeitabnahme.

SF-014-Nutzerpräzisierung: Run Header ausschließlich um den Leseschlüssel CreatedOrder (Created At, Run Id) für die begrenzte neueste Dashboardlaufwahl ergänzt. Keine neuen Headerfelder oder mutierenden Snapshot-/Laufpfade. [JS-Arbeitsplatz](../../../DASHBOARD_EMBEDDING.md).


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/ScenarioManagement/Codeunits/`, `src/ScenarioManagement/Enums/`, `src/ScenarioManagement/Pages/`, `src/ScenarioManagement/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-016/SF-017 – 18.11.2026

Finanzmodus in Vorlage/Wizard; unbekannte Enumwerte gesperrt. Snapshot übernimmt Modus/Jahr/Version über bestehendes Finance-Capture-Ereignis. Historische Snapshots unverändert. [Vertrag und BC-Abnahmefälle](../../../VALIDATION_FINANCE.md), [lokale Nachweise](../../../TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). **Zur Prüfung**, keine nachgewiesene BC-Laufzeitabnahme.


## SF-018 – 18.11.2026

Vierzehn zusätzliche optionale Partnerfelder auf bestehender Vorlage, sichtbar auf Karte/Wizard; DB-Policy prüft B2C-/Limitgrenzen, bestehende Sicherheits-/Revisionsevents gelten unverändert. Neues optionales partnerSetup-Objekt im Snapshot Schema 1. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-037 – Reparaturauftrag 18.11.2026

Archivflag, Remove-Vermerk 90148, neue Snapshot-Sperre für Archive, erneute Löschprüfung unter Elternsperre, Kindkaskade ohne Laufdatenlöschung, Namensanzeige-Ereignis und konkreter Import-Referenzbericht. [Aktueller Vertrag](../../../STARTER_TEMPLATES.md), [echte lokale Prüfungen und offene BC-Abnahme](../../../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**.

SF-021-Vorlagenkorrektur 1.0.5.1: gültige neue Minimalvorlage, Unterstützung tatsächlicher Ziele aus Registry, zentrale konsistente Scope-/Quotenwechsel, genaue Verfügbarkeit und sichtbares sicheres Löschen/Archivieren. Keine neuen AL-Objekte/Felder. [Vertrag/Abnahme](../../../SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051), Zur Prüfung.

## SF-045 – aktueller Bestand

Optionales OnCapturePurchaseSetup/purchaseSetup Version 1 im bestehenden Schema 1. Die interne Paketvorlage nutzt vorhandene Ziele, Module, Snapshots und historische Sperren. Keine parallele Paketpersistenz.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.
