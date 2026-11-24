**SF-028–SF-033 · Zur Prüfung, Teilumfang (24.11.2026):** Optionale Module Lager, Fertigung, Service, Anlagen und CRM im Folgeprozess (zusammen mit Montage, Projekten und Planung) in der Einrichtung wählbar, ohne Planungsmarkierung; Auswahl steuert die Ausführung über Snapshot-Marker. SF-032 (weitere Branchen) bleibt offen. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](../review/SF028_SF033_PRUEFBERICHT.md).

**SF-055 / SF-056 · Zur Prüfung (24.11.2026):** Projekte (Stammdaten, Aufgaben, Planungszeilen, Verbrauch über Projektbuchblatt, ungebuchte/teil-/vollgebuchte Abrechnung) und Planungsvorschläge über die Standard-Dispositionsengine im Folgeprozess, mit Vorprüfung, dokumentiertem Skip, additiver Foundation und Dashboardmodulen. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [SF-055](../review/SF055_PRUEFBERICHT.md), [SF-056](../review/SF056_PRUEFBERICHT.md).

**SF-054 · Zur Prüfung (23.11.2026):** Montage im Folgeprozess für gebuchte Einkäufe: synthetischer Montageartikel mit Stückliste (und Ressource), ungebuchter sowie voll/teilweise gebuchter Montageauftrag über Standard-Posting, Vorprüfung mit kontrolliertem Skip, additive Foundation (Montageeinrichtung, Herkunftscodes, Matrix ohne Geschäftsbuchungsgruppe). App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](../review/SF054_PRUEFBERICHT.md).

**SF-053 · Zur Prüfung (23.11.2026):** Lagerbewegungen ohne WMS im Folgeprozess für alle Artikelzeilen gebuchter Einkäufe: Zugang/Abgang per Artikelbuchblatt, Inventurdifferenz und Umlagerung über Transitlager, mit Vorprüfung (freier, nicht reservierter Bestand, Dimensionen), kontrolliertem Skip und Bestandsprüfung je Lagerort/Datum. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](../review/SF053_PRUEFBERICHT.md).

**SF-052 / SF-039-Teil · Erledigt, Teilumfang (nativ abgenommen 24.11.2026):** Gutschriften (ungebucht, gebucht teil/voll) zu gebuchten Rechnungen im Folgeprozess sowie ein synthetisches Bankkonto pro neu angelegtem Debitor/Kreditor. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](../review/SF052_PRUEFBERICHT.md).

**SF-051 · App 1.0.12.0 · Erledigt, Teilumfang (nativ abgenommen 24.11.2026):** Neue Zahlungsstufe-Captures planen je gebuchter Rechnung deterministisch: vollständig (≈55 %), zwei Raten mit Ausgleich (≈20 %), Teilzahlung mit offenem Rest (≈15 %) oder bewusst offen (≈10 %). Zahlungsrabatt/-toleranz, Gutschriften und Sammelausgleich sind **nicht** umgesetzt. Nativ vom Nutzer getestet und abgenommen (24.11.2026). [Bericht und native Prüffälle](../review/SF051_PRUEFBERICHT.md).

**SF-050 · App 1.0.11.0 · Zur Prüfung (23.11.2026):** Neue Belegläufe isolieren je Geschäftsvorfall; unbekannte Buchungsergebnisse bleiben NeedsReview, unabhängige Pending-Vorgänge können weiterlaufen. No-write-Skips, Qualitäts-/Dashboardbilanz und fehlende technische Existing-Einrichtung sind integriert. Native BC-Abnahme durch den Nutzer offen. SF-051–SF-053 nicht umgesetzt. [Vertrag, Paket und native Prüffälle](../review/SF050_PRUEFBERICHT.md).

**SF-049/SF-050, lokaler Teilstand 1.0.10.0:** Neuer modulabhängiger Mandantenpool Version 3, eingefrorene Auswahl und explizite STOCK-Auslassungsnachweise mit Dashboard-/Qualitätswarnung. Zwei additive Registryfelder, weiterhin 145 Main-Objekte. SF-049/SF-050 In Arbeit; SF-051–SF-053 nicht implementiert. [Umfang, echte Prüfungen und offene native Abnahme](../review/SF049_SF050_PRUEFBERICHT.md).

# Modulindex – Zielarchitektur

**SF-048 / 1.0.9.0:** 145 Main-AL-Objekte. Core ergänzt Enum 90114, DataGeneration den lesenden Master Data Source 90259; vorhandene ScenarioManagement-, IndustryProfiles-, DependencyManager-, BackgroundProcessing-, ProcessEngine-, Monitoring-, Sales-, Purchasing- und Inventoryobjekte verwenden explizit bestätigte Fremdlaufstammdaten. Keine neue Tabelle/Seite/Engine. [Vertrag](../MODULAR_GENERATION.md), [Prüfbericht](../review/SF048_PRUEFBERICHT.md). **Zur Prüfung**. Nachfolgende Zählstände sind historisch.

**SF-022 / 1.0.7.3:** Weiterhin 140 Main-Objekte. Bestehende Core-/IndustryProfiles-/Monitoring-/ScenarioManagement-/ProcessEngine-/Sales-/Purchasing-/Finance-Objekte erweitern den eingefrorenen Datumszeitraum; keine neuen Generatoren/Seiten. [Umfang und Abnahme](../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.

**SF-022 / 1.0.7.2:** Weiterhin 140 Main-AL-Objekte. Bestehende Core-Setupkarte/-tabelle, IndustryProfiles-Paket/Starter, ScenarioManagement-Modulunterseite und Monitoring-Request/Dashboard ergänzt. Keine neuen Generatoren. [Modulauswahl und offene native Abnahme](../INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072). **Zur Prüfung**.

**Aktuell 1.0.7.1:** 140 AL-Objekte. Monitoring ergänzt die begründet benötigte lesende Mappingseite 90370; bestehende Stock/Data/JS korrigiert. Keine Generator-/Stamm-/Einrichtungsänderung. [Details](../DASHBOARD_DATA_STOCK.md#implementierter-stand-1071).


**Aktuell 1.0.7.0:** 139 AL-Objekte. Purchasing jetzt fünf Objekte einschließlich Purchase Evidence 90454, Finance neun einschließlich Payment Processor 90401. Großhandel mit vier Prozessstufen und Zwei-Sekunden-Dashboard; native Abnahme offen. [Aktueller Vertrag](../INDUSTRY_INITIALIZATION.md#aktueller-folgeumfang-1070--einkauf-buchung-und-ausgleich). Die nachfolgenden Objektzahlen sind historische Ticketstände.


**SF-045, 21.11.2026:** Aktuell 137 AL-Objekte; [vollständiger geprüfter Quellbestand und Einstufung je Objekt](../ARCHITECTURE_AUDIT_SF045.md). Neu: Wholesale Profile 90153, Company Initialization 90361, Purchase Generator 90451 und Binding 90453. Keine neue Tabelle/Seite. Großhandel mit Stammdaten oder ungebuchten Einkaufs-/Verkaufsbelegen; native Abnahme offen. Nachfolgende Modulzahlen sind historische Stände.

Für neue oder geänderte Generatoren gelten die [SF-042-Qualitätsregeln](../ARCHITECTURE.md#generator-qualitätscheckliste-sf-042) und der [Prüfumfang je Modul](../TESTS.md#sf-042--prüfumfang-je-generator). In der jeweiligen Moduldatei unterstützte Entitäten/Modi, konkrete Setup-/Stammvorgänger, Herkunft, Statistikroute und echte Soll-/Ist-Nachweise festhalten. Nicht unterstützte Fälle mit bestehendem Ticket und Grenze benennen. [Aktueller Partnerpfad und offene Abnahme](../TESTS.md#sf-042--soll-ist-prüfung-des-partnerpfads).

**Aktueller Bestand SF-018, 18.11.2026:** 121 AL-Dateien in 14 Modulen; zehn Module ohne AL-Code. Zwei echte Partnerstammdatengeneratoren, Qualitätsabschluss und Finanztestpakete zur Prüfung; BC-Laufzeitabnahme weiterhin offen. [Partnervertrag](../PARTNER_GENERATION.md).

| Modul | Kategorie | Ziel | Status |
| --- | --- | --- | --- |
| [Core](details/src/Core.md) | Kern | `src/Core/` | Grundlagen/Sprache/Vertrag/Finanzmodus: 14 AL-Objekte, zur Prüfung |
| [ScenarioManagement](details/src/ScenarioManagement.md) | Kern | `src/ScenarioManagement/` | Vorlagen/Ziele/Snapshots/Steps/Wizard: 22 AL-Objekte, zur Prüfung |
| [IndustryProfiles](details/src/IndustryProfiles.md) | Kern | `src/IndustryProfiles/` | 1 AL-Objekt: generische versionierte Syntheseregeln; zur Prüfung. Vollständige Branchenprofile weiterhin geplant. |
| [ModuleRegistry](details/src/ModuleRegistry.md) | Kern | `src/ModuleRegistry/` | Vertrag/Katalog/Proben: 10 AL-Objekte, zur Prüfung |
| [DependencyManager](details/src/DependencyManager.md) | Kern | `src/DependencyManager/` | Graph/Plan/Vorschau: 9 AL-Objekte, zur Prüfung |
| [SetupManager](details/src/SetupManager.md) | Kern | `src/SetupManager/` | 4 AL-Objekte: temporärer Setup-Diff, Manager, Vorschau und Laufkarten-Erweiterung; zur Prüfung. |
| [DataGeneration](details/src/DataGeneration.md) | Kern | `src/DataGeneration/` | 9 AL-Objekte: Partnerregeln/-katalog/-kinddaten, Seed, Vorschau und immutable Herkunftsregistry; zur Prüfung. |
| [ProcessEngine](details/src/ProcessEngine.md) | Kern | `src/ProcessEngine/` | 1 Objekt für SF-021-Prozessquoten, Mengen und Datum, zur Prüfung |
| [BackgroundProcessing](details/src/BackgroundProcessing.md) | Kern | `src/BackgroundProcessing/` | 17 AL-Objekte: Qualitätsabschluss, Ausführung, Queue und begrenzte Recovery mit Checkpoints/Steuerung; zur Prüfung. |
| [Validation](details/src/Validation.md) | Kern | `src/Validation/` | 4 AL-Objekte: immutable Qualitätsbefunde, Manager, Severity und Ergebnisliste; zur Prüfung |
| [Monitoring](details/src/Monitoring.md) | Kern | `src/Monitoring/` | 18 AL-Objekte: JS-Dashboard, Role-Center/Profil, Kennzahlen, Historie und Wizard-Ausführungsintegration, zur Prüfung |
| [Lifecycle](details/src/Lifecycle.md) | Kern | `src/Lifecycle/` | Teilweise implementiert, 4 AL-Objekte, Zur Prüfung. |
| [Finance](details/src/Finance.md) | Fach | `src/Finance/` | 7 AL-Objekte: lesender Finanzcheck, versionierter Paketmanager/Paketvermerk, Auswahl/Vorschau und zwei PageExtensions; zur Prüfung. Keine Fachbuchungsgeneratoren. |
| [Sales](details/src/Sales.md) | Fach | `src/Sales/` | 7 AL-Objekte: Customer-Generator und SF-021-Angebote/Aufträge/Rechnungen; zur Prüfung, native BC-Abnahme offen. |
| [Purchasing](details/src/Purchasing.md) | Fach | `src/Purchasing/` | 2 AL-Objekte: echter Vendor-Generator und EnumExtension-Bindung; zur Prüfung. Beleggeneratoren geplant. |
| [Inventory](details/src/Inventory.md) | Fach | `src/Inventory/` | Sechs SF-019-Objekte, Artikel-/Beziehungsstämme ohne Bestände, zur Prüfung |
| [Warehouse](details/src/Warehouse.md) | Fach | `src/Warehouse/` | Optional wählbar: Lagereingang und Einlagerung (1 AL-Objekt, SF-028); nativ abgenommen |
| [Manufacturing](details/src/Manufacturing.md) | Fach | `src/Manufacturing/` | Optional wählbar: Fertigungsstückliste und Fertigungsauftrag (1 AL-Objekt, SF-029); nativ abgenommen |
| [Assembly](details/src/Assembly.md) | Fach | `src/Assembly/` | Optional wählbar: Montageartikel und -aufträge (1 AL-Objekt, SF-054); nativ abgenommen |
| [Projects](details/src/Projects.md) | Fach | `src/Projects/` | Optional wählbar: Projekte, Verbrauch, Abrechnung (1 AL-Objekt, SF-055); nativ abgenommen |
| [ServiceManagement](details/src/ServiceManagement.md) | Fach | `src/ServiceManagement/` | Optional wählbar: Serviceartikel und Serviceauftrag (1 AL-Objekt, SF-030); nativ abgenommen |
| [FixedAssets](details/src/FixedAssets.md) | Fach | `src/FixedAssets/` | Optional wählbar: Anlage, Anschaffung, Abschreibung (1 AL-Objekt, SF-031); nativ abgenommen |
| [CRM](details/src/CRM.md) | Fach | `src/CRM/` | Optional wählbar: Kampagne und Verkaufschance (1 AL-Objekt, SF-033); nativ abgenommen |
| [Planning](details/src/Planning.md) | Fach | `src/Planning/` | Optional wählbar: Planungsvorschläge (1 AL-Objekt, SF-056); nativ abgenommen |

**MVP:** Alle Kernverantwortungen konzeptionell notwendig, zunächst Finance, Sales, Purchasing, Inventory umsetzen. Warehouse usw. dürfen als leere Verzeichnisse bleiben. Jedes Modul besitzt eine eigene Spezifikation; bei Implementierung tatsächliche AL-Objekte nachtragen.

**SF-002, 11.11.2026:** Für alle 24 Module sind ID-Blöcke, Namespaces, geplante Objekte und erlaubte Codeabhängigkeiten in [OBJECT_PLAN.md](../OBJECT_PLAN.md) dokumentiert. Modulspezifikationen darauf abgestimmt. Historischer Stand von SF-002: 0 AL-Objekte, 59 numerische Planobjekte und ein Interface. Der aktuelle Implementierungsstand steht oben; der Objektplan enthält inzwischen zusätzlich die Management-Codeunits 90106/90107.

**SF-005/SF-006:** Gegenüber der Foundation 23 neue Objekte. Keine Implementierung weiterer Modulverantwortungen; Quelle und Grenzen: [SCENARIO_CONFIGURATION.md](../SCENARIO_CONFIGURATION.md).

SF-007/SF-008: [Generator- und Planungsvertrag](../GENERATOR_PLANNING.md); alle implementierten Objekte im aktuellen [Objektplan](../OBJECT_PLAN.md).

SF-009/SF-010: [Setup-/Seed-Vertrag](../SETUP_SEED.md); vollständige Objektzuordnung im [Objektplan](../OBJECT_PLAN.md).

SF-011/SF-012: [Herkunft-/Queue-Vertrag](../EXECUTION_REGISTRY.md), [Objektplan](../OBJECT_PLAN.md).

SF-013: [Recovery-Vertrag](../RECOVERY.md), [Prüfnachweise](../TESTS.md).


## Ablage – SF-002, 16.11.2026

Alle 104 vorhandenen AL-Dateien liegen je Modul in Typordnern gemäß [CONVENTIONS.md](../CONVENTIONS.md). Die Modulpfade der Tabelle bleiben Einstiegspunkte; die konkreten Typordner stehen in den jeweiligen Modulspezifikationen. Keine neuen Objekte oder fachlichen Implementierungen; 13 Module weiterhin ohne AL-Code. Status **Zur Prüfung**.


## SF-014 – Dashboardkorrektur 17.11.2026

Eigener Scrollbereich und generierte deutsche UI-Fallback-Ressource im bestehenden Monitoring-Dashboard ergänzt; keine neuen AL-Objekte. [Vertrag](../DASHBOARD_EMBEDDING.md), [Prüfnachweis](../TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). **Zur Prüfung**.


## SF-037 – Partner-Normalpfad, 18.11.2026

Aktueller Bestand: 129 AL-Dateien in 14 Modulen, zehn Module ohne AL-Code. ScenarioManagement jetzt 24 Objekte einschließlich Transfer und neuem Entfernt-Vermerk 90148, IndustryProfiles 4 einschließlich Starterkatalog/Install/Upgrade, Monitoring 20 einschließlich Quick Run und Szenarioaktionen, Finance 8 einschließlich Demo Partner Setup. Andere Modulbestände unverändert. Starterobjekte waren vor diesem Auftrag bereits im Workspace; nur 90148 ist in diesem Auftrag neu. [Vertrag](../STARTER_TEMPLATES.md), [tatsächliche Prüfungen](../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**, keine BC-Laufzeitabnahme.


## SF-038 / SF-039 – Bestandserweiterung

131 AL-Dateien in weiterhin 14 Modulen. Neu DataGeneration 90257 Partner Catalog und 90258 Partner Children. Finance-Bestand unverändert, 90408 dient jetzt dem gemeinsamen Paketfoundation-Vertrag. [Details](../STABILIZATION_FINANCE_PARTNERS.md). **Zur Prüfung**.


## SF-044 – Monitoringdarstellung

Bestand unverändert 121 AL-Dateien, davon 19 Monitoringobjekte. Bestehende Dashboard Part, Dashboard Data und Dashboard Stock sowie gebündelte Ressourcen angepasst. Daten und Läufe getrennt, einheitliches Kachelraster und geprüfte Zählernavigation; keine neuen Seiten oder Persistenz. [Vertrag und Abnahme](../DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026). **Zur Prüfung**.

## SF-019 – Artikelstammdaten (20.11.2026)

127 AL-Dateien in 15 Modulen; Inventory jetzt sechs Objekte. Drei ausführbare führende Entitäten: Customer, Vendor und ITEM für die ausdrücklich unterstützten technischen Großhandelsprofile. Keine neue Custom-Tabelle/Seite; acht optionale Vorlagenfelder. Test-App getrennt unter `tests/SF019/`. [Umfang/Bedienung](../INVENTORY_GENERATION.md), [Prüfungen und offene BC-Abnahme](../TESTS.md#sf-019--artikelsortiment-und-lagerbasics-20112026). **Zur Prüfung**.

## SF-021 – Verkaufsprozess, 20.11.2026

133 Main-AL-Dateien in 16 Modulen, acht Module weiterhin ohne AL-Code. Sales sieben Objekte, ProcessEngine ein Objekt, übrige Objektzahlen unverändert. Keine neue Custom-Tabelle/Seite; separate bestehende Test-Codeunit jetzt 19 Tests. [Vertrag](../SALES_PROCESS.md), [Prüfstand](../TESTS.md#sf-021--verkaufsprozess-20112026). **Zur Prüfung**.

SF-021-Vorlagenkorrektur 1.0.5.1: Objektbestand unverändert (133/16 Module); vorhandene ScenarioManagement-/IndustryProfiles-/Monitoring-/Finance-/Core-/ProcessEngine-Objekte korrigiert. Bestehender isolierter Testhost 26 Methoden. [Vorlagenmatrix und native Abnahme](../SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051), Zur Prüfung.


## SF-046 – vollständiges Konfigurationspaket

143 Main-AL-Objekte in weiterhin 16 Modulen. Monitoring: Paketdienst 90371, Install 90372 und Upgrade 90373. Ab 1.0.8.1 sind die Install-/Upgrade-Trigger leer; Paketaufbau nur nach ausdrücklicher Aktion in der aktuellen Firma. Core-Permission-Set ergänzt nur Execute. Keine neue Tabelle/Seite, keine Generatoränderung. [128 Tabellen-IDs und Bedienung](../CONFIG_EXPORT.md), [Prüfungen](../TESTS.md#sf-046--konfigurationspaket-für-vollständige-generator-daten), **Zur Prüfung**.


## SF-047 – Zahlungskorrektur 1.0.8.5

Objektbestand unverändert 143 Main-Objekte. Finance Payment Processor 90401 setzt die Standard-Commitunterdrückung vor allen Journalvalidierungen; keine neue Modulabhängigkeit, kein neues Objekt/Schema. Der vorhandene TRADE/6-Diff bleibt erhalten. Main/Test-App lokal gegen 28.5 kompiliert; native Zielversion 29.1 und acht bestehende Analyzer-Formatbefunde offen. [Ursache, Querschnitt und Nachweise](../review/SF047_PRUEFBERICHT.md#zahlungskorrektur-1085--commit-bei-ausgleichsvalidierung). **Zur Prüfung**.
