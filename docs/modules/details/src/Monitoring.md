# Monitoring – Modulspezifikation

**Status:** 18 AL-Objekte implementiert, **Zur Prüfung**. Pfad: `src/Monitoring/`. Historische Planabschnitte gelten für noch nicht umgesetzte Teile.

## Fachlicher Auftrag

Übersicht, Kennzahlen, Job-/Fehlerdetails und Ergebnisnavigation.

## Verantwortungen und gewünschte Ergebnisse

Dashboard/FactBoxes; Modul-Soll/Ist; Queue-Status; Fortschritt; Warnungen; Filter/Drilldowns.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, BackgroundProcessing, Validation. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine mutierende Geschäftslogik in Pages. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Monitoring`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.

## SF-014/SF-015 – 16.11.2026

Dashboard, FactBox, temporäre Schrittkennzahlen, technische unveränderliche Statushistorie und Queueprotokoll-Drilldowns. Ausführungsintegration des Wizards als PageExtension; keine Fachgenerierung.

Reale Objekte, gerichtete Abhängigkeiten, Persistenz-/Rechtevertrag, Bedienung und offene Prüfungen: [MONITORING_WIZARD.md](../../../MONITORING_WIZARD.md), [OBJECT_PLAN.md](../../../OBJECT_PLAN.md), [TESTS.md](../../../TESTS.md). Keine BC-Laufzeitabnahme.

## SF-014 – präzisierter JavaScript-Arbeitsplatz

ControlAddIn, wiederverwendbare CardPart, große Hostseite, eigenes Role-Center/Profil und zwei Daten-/Aktionscodeunits ergänzt. Zusätzliche ModuleRegistry-/DataGeneration-Referenzen dienen vorhandener Navigation/Leselogik. Sieben neue AL-Objekte, davon fünf mit numerischer ID. [Aktuelle Bedienung, Ressourcen und Einbau](../../../DASHBOARD_EMBEDDING.md), [Prüfnachweise](../../../TESTS.md). Echte BC-Role-Center-/Iframe-/Dialogabnahme offen.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/Monitoring/Codeunits/`, `src/Monitoring/ControlAddIns/`, `src/Monitoring/PageExtensions/`, `src/Monitoring/Pages/`, `src/Monitoring/Profiles/`, `src/Monitoring/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-014 – Scrollen und deutsche Anzeige, 17.11.2026

Dashboardcontainer scrollt innerhalb begrenzter Iframehöhe; Scrollposition bleibt beim Refresh erhalten. Bekannte englische Dashboardlabels erhalten bei deutscher BC-Sitzung eine generierte XLIFF-Fallbackübersetzung. Keine neuen AL-Objekte, Datenmutationen oder Rechte. [Vertrag](../../../DASHBOARD_EMBEDDING.md), [Prüfungen](../../../TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). **Zur Prüfung**.


## SF-016/SF-017 – 18.11.2026

Gespeicherte Summary statt pauschaler Qualitätsauskunft; rungefilterte Ergebnisliste. Variablenreihenfolge im zugehörigen Overview-Trigger für CodeCop korrigiert. [Vertrag und BC-Abnahmefälle](../../../VALIDATION_FINANCE.md), [lokale Nachweise](../../../TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). **Zur Prüfung**, keine nachgewiesene BC-Laufzeitabnahme.


## SF-037 – Reparaturauftrag 18.11.2026

Zustandsabhängige Hauptaktionen, Diagnosebereich, ursprünglicher Standardfehler mit Paketbezug/sicherem Folgeschritt, exakte Partnernavigation und vollständige persistierte Zustandshistorie ohne xRec-Vergleich. JS-Dynamik lokalisiert. [Aktueller Vertrag](../../../STARTER_TEMPLATES.md), [echte lokale Prüfungen und offene BC-Abnahme](../../../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**.
