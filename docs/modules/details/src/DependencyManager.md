# DependencyManager – Modulspezifikation

**Status:** Teilweise implementiert, 9 AL-Objekte, Zur Prüfung. **Pfad:** `src/DependencyManager/`. Historische Planungsangaben unten gelten nur für noch nicht implementierte Teile.

## Fachlicher Auftrag

Abhängigkeitsgraph und fachliche Ausführungsreihenfolge.

## Verantwortungen und gewünschte Ergebnisse

Zyklenerkennung; Preflight; notwendige/optionale Abhängigkeiten; Deaktivierung mit verständlichen Konfliktmeldungen.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, SetupManager. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine automatische Änderung bestehender Einrichtung. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.DependencyManager`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; die noch nicht implementierten Teile bleiben geplant. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Aktueller Nachweis SF-007/SF-008

Reale Dateien:

- `BCSFDependency.Table.al`
- `BCSFDependencyPlanner.Codeunit.al`
- `BCSFGraphSelfCheck.Codeunit.al`
- `BCSFGraphSorter.Codeunit.al`
- `BCSFPlanNode.Table.al`
- `BCSFPlanPreview.Page.al`
- `BCSFPlanWriter.Codeunit.al`
- `BCSFRunPlanning.PageExt.al`
- `BCSFSavedRunSteps.Page.al`

Verantwortung, Datenfluss, temporäre/persistente Tabellen, Versionierung und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](../../../GENERATOR_PLANNING.md). Build/Übersetzung lokal geprüft; Selbstprüfungen nur kompiliert, kein BC-Laufzeittest. Fachgeneratoren und Queue weiterhin geplant.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/DependencyManager/Codeunits/`, `src/DependencyManager/PageExtensions/`, `src/DependencyManager/Pages/`, `src/DependencyManager/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-018 – 18.11.2026

Für reine Customer-/Vendor-Ziele kein künstlich ungelöster FINANCE.SETUP-Knoten; konkrete Generator-Prerequisites bleiben erforderlich. Gemischte/Artikel-/Dokument-/Stockpläne behalten externe Gates. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.

## SF-045 – aktueller Bestand

Unterstützte ungebuchte PURCHASE.ORDER-Ziele werden wie reale Partner-/Artikel-/Verkaufsziele durch konkrete Prüfungen statt einen fehlenden externen FINANCE.SETUP-Generator abgesichert. Einkaufsbestellungen folgen VENDOR/ITEM; Verkauf folgt zusätzlich vorhandenen Einkaufszielen.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Nur bei expliziter Snapshotquellenbindung entfallen neue Stammdatenabhängigkeiten im Bewegungslauf. Echte Voraussetzung wird im vorhandenen Generator-Prerequisitepfad erneut geprüft; kein Ersatzgenerator. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.
