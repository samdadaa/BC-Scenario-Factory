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


## SF-044 – kompakte Daten- und Laufansicht

Bestehende Objekte 90362, 90365 und 90369 um getrennte Ansichten und direkte Zählernavigation ergänzt. Einheitliches responsives Kachelraster; Live-Herkunftsergebnisse getrennt von bestätigter Arbeit; Summary-Drilldowns mit aktuellem Rechte-/Countvergleich und begrenztem Status-ID-Filter. Kein neuer Generator, keine Tabelle/Seite oder Rechteerhöhung. [Bedienung und Grenzen](../../../DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026), [tatsächliche Prüfungen](../../../TESTS.md#sf-044--kompaktes-dashboard-und-direkte-kennzahlen). **Zur Prüfung**, BC-Abnahme offen.

SF-019-Bedienkorrektur 20.11.2026: Dashboard Stock ergänzt elf bestehende BC-Listenrouten für Artikelstämme/-beziehungen; erzeugte Attributzuordnungen werden in der vorhandenen Herkunftsseite lesbar geöffnet. Rechte, SystemId-Herkunftsfilter, Begrenzung und Neuzählung bleiben wirksam. Keine zusätzlichen AL-Objekte. [Vertrag und Grenzen](../../../INVENTORY_GENERATION.md#sf-019--bedienkorrektur-20112026), [Prüfungen](../../../TESTS.md#sf-019--rückmeldung-und-datenkacheln-20112026). Zur Prüfung.

## SF-045 – aktueller Bestand

Company Initialization 90361 orchestriert genau einen gespeicherten Request in der vorhandenen Setupkarte. Dashboard liest Firmen-/Branchen-/Kontenplan-/Jobzustand, zeigt bestätigte Schritte und Fehlerphase, verbirgt technische Vorlagen im Normalweg. Bestehende Diagnosen bleiben im eingeklappten Expertenbereich.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## 1.0.7.0 – aktueller Folgeumfang

Lesender Zwei-Sekunden-Poll mit serialisierten Aufrufen und inkrementellem DOM. Workflowstart auch nach abgeschlossenem Lauf, zusätzliche Herkunftskennzahlen für Eingang/Rechnung/Zahlung; Filter/Drilldown erneut geprüft. [Gemeinsamer Vertrag](../../../INDUSTRY_INITIALIZATION.md). **Zur Prüfung**, native Abnahme offen.


## 1.0.7.1 – vollständige Bestandsinformationen

Stock verwendet MarkedOnly statt begrenzter SystemId-OR-Filter, behält Standard-/Sicherheitsfilter und übergibt Marks an Listenrecords. Kauf-/Verkaufsbeschriftungen getrennt, purchase/-Runroute repariert, Prozessstufe sichtbar und erwartete Nullzahlungen behalten. Neue rein lesende Page 90370 auf Item Attribute Value Mapping wegen fehlender passender Standardliste. Keine Tabelle/Generator-/Einrichtungsmutation. [Vertrag](../../../DASHBOARD_DATA_STOCK.md#implementierter-stand-1071), [echte Prüfungen und native Grenzen](../../../TESTS.md#sf-045--dashboardnachbesserung-1071). **Zur Prüfung**.


## SF-022 – Modulauswahl 1.0.7.2

Company Initialization prüft/friert zusätzliche Modulauswahl vor Einplanung ein und validiert erneut im Hintergrund; unveränderliches optionales Setupfeld auch bei Modify(false). Dashboard nennt Basis/Planungszusätze im Firmenstatus, reale Ergebnis-/Drilldownquellen unverändert. [Vertrag und native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072), [lokale Prüfnachweise](../../../TESTS.md#sf-022--modulauswahl-1072). **Zur Prüfung**, keine BC-Laufzeitabnahme.


## SF-022 – Datumszeitraum 1.0.7.3

Request friert Anfang/Ende ein, schützt beide gegen Modify(false) und prüft erneut vor Hintergrundvorbereitung. Dashboard zeigt gespeicherten Zeitraum; tatsächliche Bestands-/Drilldownquellen unverändert. [Vertrag/offene native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.


## SF-046 – Standard-Konfigurationspaket

Neue Codeunits 90371 Config Export, 90372 Config Export Install und 90373 Config Export Upgrade. Seit 1.0.8.1 wird Paket BCSF-ALL-DATA erst durch die ausdrückliche Aktion im bestehenden Dashboard/Role-Center angelegt bzw. ergänzt, ausschließlich in der aktuellen SaaS-Sandboxfirma. Install-/Upgrade-Trigger 90372/90373 bleiben leer; vorhandene Pakete und Objektidentitäten erhalten. 128 typsichere Tabellenreferenzen einschließlich indirekter Standardbuchungsdaten; keine Herkunftsfilter. Standard-System.IO-APIs, keine erhöhten TableData-Rechte, keine Generator-/Queue-/Checkpointänderung. Bestehende Paketfilter/Feldauswahl geschützt, Fremdcodekollision blockiert. [Vertrag/Tabellen-IDs](../../../CONFIG_EXPORT.md), [lokale Prüfungen/native Abnahme](../../../TESTS.md#sf-046--konfigurationspaket-für-vollständige-generator-daten). **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Company Initialization schützt alle acht neuen Requestfelder und neue Starts gegen aktive Vorgänger. Bestehender Monitor als Quellenlookup; Dashboard zeigt Laufart, Module und Quelle. Zähler/Drilldowns bleiben echte neue Resultate. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.


## SF-049/SF-050 – lokaler Teilstand 1.0.10.0

Bestehenden Quellen-/Snapshot-/Mengen-/Registry-/Qualitäts-/Dashboardpfad für den modulabhängigen Pool Version 3 und ausdrückliche STOCK-Auslassungsnachweise ergänzt. Keine neue Batchengine und keine automatische Wiederholung unerwarteter Buchungsfehler. Unterstützter Umfang, konkrete Dateien/Datenflüsse, Kompatibilität und noch offene native Modulprüfung im [gemeinsamen Prüfbericht](../../../review/SF049_SF050_PRUEFBERICHT.md). Status In Arbeit, keine native Abnahme.


## SF-050 – aktuelle Umsetzung 1.0.11.0 / 23.11.2026

Isolierte neue Geschäftsvorfälle, lesende Prüfung der tatsächlich gewählten Quellen, atomare No-write-Skip-Checkpoints, fortgesetzte unabhängige Pending-Arbeit und unveränderte NeedsReview-Sperren. Bestehende Einrichtungen werden nur im bestätigten Foundationpfad ergänzt; neue interne Vorlagen verwenden konkrete kompatible Zuordnungen. Quellen, betroffene Moduldateien, Ergebnis-/Listenvertrag und Grenzen im [aktuellen Prüfbericht](../../../review/SF050_PRUEFBERICHT.md). Fünf neue Methoden im vorhandenen Testobjekt; lokale Nachweise dort, native Modulabnahme N01–N08 durch den Nutzer noch offen. **Zur Prüfung**, SF-051–SF-053 nicht umgesetzt.
