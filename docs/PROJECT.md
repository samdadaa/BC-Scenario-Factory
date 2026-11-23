**SF-054 · Zur Prüfung (23.11.2026):** Montage im Folgeprozess für gebuchte Einkäufe: synthetischer Montageartikel mit Stückliste (und Ressource), ungebuchter sowie voll/teilweise gebuchter Montageauftrag über Standard-Posting, Vorprüfung mit kontrolliertem Skip, additive Foundation (Montageeinrichtung, Herkunftscodes, Matrix ohne Geschäftsbuchungsgruppe). App-Version unverändert. **Nicht kompiliert (.NET 10 fehlt), nicht nativ getestet.** [Bericht und Prüffälle](review/SF054_PRUEFBERICHT.md).

**SF-053 · Zur Prüfung (23.11.2026):** Lagerbewegungen ohne WMS im Folgeprozess für alle Artikelzeilen gebuchter Einkäufe: Zugang/Abgang per Artikelbuchblatt, Inventurdifferenz und Umlagerung über Transitlager, mit Vorprüfung (freier, nicht reservierter Bestand, Dimensionen), kontrolliertem Skip und Bestandsprüfung je Lagerort/Datum. App-Version unverändert. **Nicht kompiliert (.NET 10 fehlt), nicht nativ getestet.** [Bericht und Prüffälle](review/SF053_PRUEFBERICHT.md).

**SF-052 / SF-039-Teil · Zur Prüfung, Teilumfang (23.11.2026):** Gutschriften (ungebucht, gebucht teil/voll) zu gebuchten Rechnungen im Folgeprozess sowie ein synthetisches Bankkonto pro neu angelegtem Debitor/Kreditor. App-Version unverändert. **Nicht kompiliert (.NET 10 fehlt), nicht nativ getestet.** [Bericht und Prüffälle](review/SF052_PRUEFBERICHT.md).

**SF-051 · App 1.0.12.0 · Zur Prüfung, Teilumfang (23.11.2026):** Neue Zahlungsstufe-Captures planen je gebuchter Rechnung deterministisch: vollständig (≈55 %), zwei Raten mit Ausgleich (≈20 %), Teilzahlung mit offenem Rest (≈15 %) oder bewusst offen (≈10 %). Zahlungsrabatt/-toleranz, Gutschriften und Sammelausgleich sind **nicht** umgesetzt. App wurde mangels .NET-10-Compiler **nicht kompiliert**, keine native Abnahme. [Bericht und native Prüffälle](review/SF051_PRUEFBERICHT.md).

**SF-050 · App 1.0.11.0 · Zur Prüfung (23.11.2026):** Neue Belegläufe isolieren je Geschäftsvorfall; unbekannte Buchungsergebnisse bleiben NeedsReview, unabhängige Pending-Vorgänge können weiterlaufen. No-write-Skips, Qualitäts-/Dashboardbilanz und fehlende technische Existing-Einrichtung sind integriert. Native BC-Abnahme durch den Nutzer offen. SF-051–SF-053 nicht umgesetzt. [Vertrag, Paket und native Prüffälle](review/SF050_PRUEFBERICHT.md).

**SF-049/SF-050, lokaler Teilstand 1.0.10.0:** Neuer modulabhängiger Mandantenpool Version 3, eingefrorene Auswahl und explizite STOCK-Auslassungsnachweise mit Dashboard-/Qualitätswarnung. Zwei additive Registryfelder, weiterhin 145 Main-Objekte. SF-049/SF-050 In Arbeit; SF-051–SF-053 nicht implementiert. [Umfang, echte Prüfungen und offene native Abnahme](review/SF049_SF050_PRUEFBERICHT.md).

**Aktuell SF-048 (22.11.2026):** App `1.0.9.0`, separate Test-App `1.5.0.0`, 145 Main-Objekte und 64 kompilierte AL-Testmethoden. Neu Enum 90114 und lesende Source-Codeunit 90259; additive Setup-/Szenariofelder, keine neue Tabelle/Seite/Runtimeabhängigkeit. Drei Laufarten im vorhandenen Workflow, wiederverwendbare bestätigte Stammdaten auch aus terminal fehlgeschlagenen Läufen. Lokaler Build gegen BC 28.5 erfolgreich, native BC-29.1-Prüfung offen; acht bestehende Analyzerfehler. [Vertrag](MODULAR_GENERATION.md), [Prüfbericht](review/SF048_PRUEFBERICHT.md). **Zur Prüfung**. Nachfolgende Versionsstände sind historisch.


**SF-047 (22.11.2026):** Manifestversion `1.0.8.5`, keine neuen Objekt-IDs, Tabellen oder Dependencies; TRADE/6 und vorhandener SF-047-Diff erhalten. Zahlungsvalidierung unterdrückt Standard-Toleranzcommits ausdrücklich. Main/Test-App 1.4.0.5 gegen lokale BC-28.5-Symbole kompiliert; native Zielumgebung laut Nutzertrace BC 29.1.57326.58215, dafür keine lokalen Symbole/keine Laufzeitabnahme. Strenger Analyzer: acht vorhandene AA0018-Befunde. [Prüfbericht](review/SF047_PRUEFBERICHT.md). **Zur Prüfung**.

# Projektfakten und bestätigter Plan

**SF-022 / Datumszeitraum 1.0.7.3:** App 1.0.7.3, Test-App 1.3.0.3; unverändert 140 Main-Objekte. Ein additives optionales Setup-Enddatumsfeld 28. Unternehmensinitialisierung erfasst Start bis gestern; neue Snapshots erhalten optionale Datumsregelversion 1, ältere behalten ihre Semantik. [Vertrag und native Prüfgrenzen](INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.

**SF-022 / 1.0.7.2, aktueller Nachauftrag:** App 1.0.7.2, separate Test-App 1.3.0.2; unverändert 140 Main-AL-Objekte. Ein additives optionales Setup-Requestfeld 27 für Planungsmodule. Keine neue Seite/Tabelle, keine neue Dependency/ID oder Runtimeänderung. Unternehmensassistent um Modulauswahl ergänzt. [Umsetzung und Prüfgrenzen](INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072). **Zur Prüfung**.

**Aktuell 1.0.7.1:** 140 AL-Objekte, neue ausschließlich lesende Mappingseite 90370. Identität, Runtime 17, ID-Bereich, Dependencies und persistentes Schema unverändert. Test-App 1.3.0.1 mit 38 Methoden. [Dashboardkorrektur](DASHBOARD_DATA_STOCK.md#implementierter-stand-1071). Folgende Versionsabschnitte sind historische Ticketstände.


## Aktueller Quellstand SF-045 – 21.11.2026

Manifest: App-ID `618c08c6-601b-430a-90d2-55f96866bfa4`, Name `BC Scenario Factory`, Publisher `Default Publisher`, Version `1.0.7.0`, Application `28.0.0.0`, Runtime `17.0`, IDs `90100–90999`, Dependencies `[]`. Identität/Range/Runtime unverändert; additive Featureversion. 139 AL-Objekte, keine neue Tabelle/Seite. Gegenüber 1.0.6.0 zwei neue Codeunits 90401 Payment Processor und 90454 Purchase Evidence. Sieben optionale Requestfelder im bestehenden Setup, zwei zusätzliche Scenario-Freigabefelder; optionale purchaseSetup/paymentSetup-Verträge im Snapshot-Schema 1. Separate Test-App `1.3.0.0` mit 36 Testmethoden referenziert App `1.0.7.0`; Main-App hängt nicht von Tests ab.

[Architektur und Grenzen](INDUSTRY_INITIALIZATION.md), [vollständiges Quellinventar](ARCHITECTURE_AUDIT_SF045.md). Kein Deployment und keine native Sandbox-/Upgradeabnahme. Nachfolgende Bestandszahlen sind historische Stände.

## SF-042 – aktueller Prüfstand 19.11.2026

`app.json`: App-ID `618c08c6-601b-430a-90d2-55f96866bfa4`, Name `BC Scenario Factory`, Publisher `Default Publisher`, Version `1.0.4.0`, Application `28.0.0.0`, Runtime `17.0`, IDs `90100–90999`, Dependencies `[]`. Direkter Vorlagenstart, Queue und kompakte Dashboardansichten sind im aktuellen Code vorhanden. In SF-042 ausschließlich Anleitung und Qualitäts-/Prüfverweise nachgeführt; keine neue App-Funktion oder Kompatibilitätsänderung. [Soll-Ist-Abgleich und tatsächlich ausgeführte Prüfungen](TESTS.md#sf-042--soll-ist-prüfung-des-partnerpfads). Status **Zur Prüfung**; installierte Zielversion, fachliche Sandbox-Abnahme und menschliche P0-Freigabe bleiben **Zu prüfen**. Die folgenden Bestandszahlen sind historische Ticketstände.

## Historischer technischer Bestand (ZIP vom 10.11.2026; aktuelle Änderungen siehe SF-001 unten)

| Feld | Ist |
| --- | --- |
| Name | BC Scenario Factory |
| App-ID | `618c08c6-601b-430a-90d2-55f96866bfa4` |
| Publisher | `Default Publisher` (Platzhalter) |
| Version | `1.0.0.0` |
| Application | `28.0.0.0` (aus app.json; Laufzeit-Kompatibilität ungetestet) |
| Runtime | `17.0` (aus app.json; Kompatibilität ungetestet) |
| IDs | `50100..50149` (50 IDs; voraussichtlich zu wenig) |
| Abhängigkeiten | `[]` |
| AL-Objekte | **0**, noch nicht implementiert |
| Module | 24 geplante Verzeichnisse unter `src/`, noch ohne Code |

`app.json`, `.vscode/launch.json`, `.gitignore` und sonstige bestehende technische Konfiguration wurden im Dokumentationsschritt **nicht geändert**. `.vscode/launch.json` enthält zwei Sandbox-Profile (Playgrund/Playground), deren Richtigkeit vor Debugging zu überprüfen ist.

## Bestätigtes Produktziel

Wiederverwendbare **AL-Extension** zur Erstellung kontrollierter, konsistenter, realistischer und synthetischer BC-Umgebungen für Demo, Schulung, Prozess-/Regressionstest und Performance. Branchenprofile definieren Datenverteilungen und Prozessmuster; Fachgeneratoren implementieren die Logik. Umfang: Setup+Stammdaten / zusätzlich ungebuchte Belege / gebuchte Belege und Posten / optional Folgevorgänge einschließlich Zahlung und Ausgleich. Per Entität einstellbare Mengen; langfristig auch 100.000+ Datensätze, ohne Durchsatzgarantie. Längere Erzeugungen über Job Queue mit Dashboard, Checkpoints, Wiederanlauf und Validierung.

## Produktphasen

- **MVP / P1:** Core + Scenario Management, Profiles/Registry, Dependency/Setup, Data/Process, Queue/Monitoring, Validation/Lifecycle, Finanz-Grundlagen, Verkauf, Einkauf, Artikel/Lagerbestand; **Handelsprofil**.
- **P2:** Lagerprozesse, Fertigung, Montage, Projekte, Service, Anlagen; Zahlung/Retouren/komplexe Belegketten vertiefen.
- **P3:** CRM/Beziehungsmanagement, Planung, weitere Branchenprofile, Erweiterungs-API, Schulungsszenarien mit definierbaren Lernzielen.

## Was noch entschieden werden muss

ID-Bereich und Publisher, geeignete Sandbox/Versionen und verwendbare BC-Basisdaten; Länder-/Lokalisierungsumfang (DE zuerst als Vorschlag), Branchenwerte/Kataloge, Test-App-Struktur, rechtlich zulässige Namens-/Adressgeneratoren, Umgang mit Vorhanden-/Neuaufbau-Setups, Sicherheitsfreigabe bei Massenbuchungen, Aufbewahrungs-/Bereinigungsstrategie. Siehe `docs/DECISIONS.md` und die Tickets.

## SF-001 – aktuelle Bestandsprüfung vom 11.11.2026

**Historischer Stand nach der ersten Nutzerrückmeldung:** Entwicklungsmodus mit Ziel `Playground`; `app.json` enthält jetzt `50100..50999` (900 ID-Werte). Erstes Launch-Profil heißt `BC Scenario Factory - Playground (Dev)` und zeigt ebenfalls auf `Playground`; beide Profile erhalten. Die folgende Erstprüfung beschreibt den Zustand vor diesen Änderungen. Publisher, tatsächliche BC-Version, Lokalisierung, Testfirma und externe ID-Belegung bleiben **Zu prüfen**.

**Ziel und Umfang:** Projektkonfiguration mit bestätigten Entscheidungen abgleichen und Symbol-/Build-Weg vorbereiten. Betroffene Dateien: `docs/PROJECT.md`, `docs/DECISIONS.md`, `docs/TESTS.md`, `TODO.md`; `app.json` und `.vscode/launch.json` erst nach Festlegung der offenen Werte ändern. Keine AL-Objekte, Schnittstellen oder BC-Schreibzugriffe erforderlich; Transaktions-/Batch-Grenzen sind für diesen Dokumentationsschritt nicht anwendbar. Objektplan und Modulallokation gehören zu SF-002.

**Voraussetzungen und Risiken:** Publisher, Veröffentlichungsziel, ID-Freigabe, Zielversion, Lokalisierung und Testfirma fehlen. Ein vorhandenes Launch-Profil belegt weder Sandbox-Typ noch Erreichbarkeit oder Rechte. Falsche Werte könnten Symbolbezug, App-Identität oder spätere Installation beeinträchtigen. Es gibt noch keinen implementierten Environment Guard.

**Testweg:** Manifest strukturell prüfen, AL-Dateien/ID-Belegung und Symbolbestand zählen, Launch-Profile ohne Zugangsdaten vergleichen, lokale Werkzeugverfügbarkeit prüfen und abschließend Diff/Umfang kontrollieren. Build und Sandbox-Prüfung bleiben bis zur bestätigten Zielkonfiguration offen; tatsächliche Ergebnisse stehen in [TESTS.md](TESTS.md#sf-001--lokales-prüfprotokoll-vom-11112026).

| Prüfaspekt | Lokal nachgewiesener Stand |
| --- | --- |
| Manifest | JSON lesbar; App-ID, Name, Publisher, Version, Application, Runtime, ID-Bereich und Dependencies entsprechen der obigen Bestandsaufnahme; `platform: 1.0.0.0`, Feature `NoImplicitWith` |
| Objektbelegung | Projektweit 0 AL-Dateien; deshalb keine lokale Objekt-ID-Kollision nachweisbar. Keine Aussage über installierte Fremd-Apps oder reservierte Bereiche |
| ID-Kapazität | `50100..50149` = 50 numerische Werte; keine neue Range und keine IDs pro Modul reserviert. Ausreichende Kapazität erst anhand des Objektplans und der Nutzungsart bewerten |
| Launch-Profile | Zwei Profile mit identischem Namen `Microsoft cloud sandbox`, jeweils `environmentType: Sandbox`; `environmentName` einmal `Playgrund`, einmal `Playground`. Beide starten Page 22; keine Firma festgelegt |
| Symbole | 0 `.app`-Dateien im Projektordner `.alpackages`; Ziel-APIs und Versionskompatibilität nicht geprüft |
| Lokale AL-Werkzeuge | VS-Code-Erweiterung `ms-dynamics-smb.al-18.1.2842859` vorhanden; `bin/alc.dll` und `bin/alc.exe` vorhanden. `dotnet` im PATH, `alc` und `code` nicht im PATH. Compiler nicht gestartet |
| Laufzeit/Umgebung | Keine Sandbox-Verbindung, Rechteprüfung oder Firmenprüfung durchgeführt; tatsächliche BC-Version und Lokalisierung **Zu prüfen** |

### Vorbereiteter Symbol-/Build-Weg

1. Die offenen Werte in [DECISIONS.md](DECISIONS.md#sf-001--ausstehende-festlegungen) festlegen. Tatsächlichen Sandbox-Typ, BC-Version, Lokalisierung und isolierte Testfirma durch eine berechtigte Person prüfen; nur nicht sensible Prüfergebnisse dokumentieren.
2. Manifest mit diesen Festlegungen abgleichen, App-ID erhalten. ID-Kollisionen zusätzlich gegen installierte Apps und verbindliche Reservierungen der Zielumgebung prüfen. Erst danach freigegebene Konfigurationswerte eintragen.
3. Das bestätigte Launch-Profil eindeutig benennen und die Testfirma explizit festlegen. Das andere Profil bis zur Entscheidung erhalten; Zugangsdaten ausschließlich über den vorgesehenen Anmeldemechanismus verwalten.
4. In VS Code `AL: Download symbols` (`al.downloadSymbols`) für die bestätigte Sandbox ausführen. Die Befehlsregistrierung ist in der lokal installierten AL-Erweiterung nachgewiesen; der Download wurde nicht ausgeführt. Symbolversionen mit `application`, `platform`, `runtime` und Dependencies abgleichen.
5. Anschließend `AL: Package` (`al.package`) ausführen und Compiler-/Analyzer-Diagnosen dokumentieren. Auch dieser Befehl ist lokal registriert, aber nicht ausgeführt. Ein Paket des noch objektlosen Projekts wäre kein Funktionsnachweis für die geplanten Module.
6. BC-Berechtigungen und Sandbox-Erreichbarkeit separat mit einem autorisierten Zugriff prüfen. Veröffentlichung/Deployment benötigen weiterhin einen ausdrücklichen Auftrag; SF-001 erteilt diesen nicht.

**Prüfweg nach der Rückmeldung:** Range-Grenzen und Kapazität, unveränderte App-Identität/Versionen, beide Sandbox-Ziele und eindeutige Profilnamen prüfen. Risiken bleiben externe ID-Konflikte und ungeprüfte Zielkompatibilität. Kein AL-Code oder Modulplan im Umfang von SF-001 ergänzt.

## SF-002 – aktuelle Projektgrundlage (11.11.2026)

Der Nutzer hat `app.json` selbst auf `90100..90999` geändert und die Verwendung ausdrücklich bestätigt. Dies ersetzt die frühere Auswahl `50100..50999`; Kapazität weiterhin 900 ID-Werte. Manifest/Launch-Konfiguration werden in SF-002 nicht verändert. Entwicklungsziel bleibt `Playground`. [OBJECT_PLAN.md](OBJECT_PLAN.md) und [CONVENTIONS.md](CONVENTIONS.md) legen Präfix `BCSF`, Namespace `BCScenarioFactory.<Modul>`, 24 Modulblöcke und 300 Reservewerte fest. Es existieren weiterhin 0 AL-Objekte. SF-001 ist nicht als abgenommen erklärt; dessen technische und fachliche Restfragen bleiben vor Implementierung relevant.


## Aktueller Bestand nach SF-003/SF-004 (11.11.2026)

Neun AL-Objekte: acht Core-Objekte (90100–90107) und ein Lifecycle-Guard (90375), übrige 22 Module leer. app.json und launch.json im Rahmen dieser beiden Tickets unverändert. Setup-Vertrag, Felder, technische Defaults und Berechtigungen: [FOUNDATION.md](FOUNDATION.md). Keine Benutzer, Standard-BC-Daten, Generatoren oder Jobs angelegt.

Fünf lokale Microsoft-Symbolpakete vorhanden: System 28.0.57066.0, System Application/Base Application 28.5.54976.57342, Application/Business Foundation 28.5.54976.56550; DE in den Application-Metadaten, Runtime 17. Diese lokalen Fakten ersetzen die frühere Aussage „keine Symbole“ für den aktuellen Bestand, belegen jedoch keine reale Sandbox-Version oder Testfirmen-Einrichtung. Compiler 18.1.43.24897 über bereits vorhandenen VS-Code-.NET-10.0.15-Cache ausführbar; Build mit CodeCop/UICop erfolgreich. Keine Installation vorgenommen. Publisher bleibt unverändert ein Platzhalter; ursprüngliche BC-28.0-Kompatibilität und tatsächliche Sandbox-/Rechteprüfung weiterhin offen.


## Aktueller Bestand SF-005/SF-006 und Zweisprachigkeit (11.11.2026)

32 AL-Objekte: Core 10, ScenarioManagement 20, Lifecycle 2; 21 weitere Module noch ohne AL. Vorlagen, Module, Mengen-/Quotenparameter, Kopieren/Revision und unveränderliche Draft-Lauf-Snapshots vorhanden; keine implementierten Fachgeneratoren, Profile, Queue-Worker oder Standardbuchungen. Sieben XLIFF-Dateien (generierte Referenz, Englisch und fünf deutsche Regionen), Übersetzungsprüfer und sprachstabile synthetische Namensvorschauen. Einzelheiten: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md).

Manifest ausschließlich um TranslationFile ergänzt, Identität/Version/Range/Dependencies erhalten; Launch unverändert. Bisherige Sicherheitsgrenzen erweitert auf fünf Konfigurationstabellen und immutable Snapshot-Schreibwege. Narrow-Insert-Permissions im Snapshot-Schreiber nur auf eigene App-Tabellen. Publisher und echte Sandbox-/Testfirmen-/Rechteprüfung bleiben offen; Build weiterhin gegen vorhandene BC-28.5-/DE-Symbole, Runtime 17.


## Aktueller Stand SF-007/SF-008 – 11.11.2026

56 AL-Objekte in fünf Modulen implementiert; 19 Module ohne AL-Code. Manifest/Launch unverändert; lokale Symbole BC 28.5/DE, Runtime 17. Registry/Planung samt Übersetzung lokal gebaut. Publisher und reale Playground-/Testfirmen-/Rechteprüfung aus SF-001 weiterhin offen.

Vertrag und Grenzen: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md). Status: **Zur Prüfung**, kein Deployment oder BC-Laufzeittest.

## Aktueller Bestand SF-009/SF-010 – 15.11.2026

64 AL-Objekte: Core 13, ScenarioManagement 21, ModuleRegistry 10, DependencyManager 9, Lifecycle 3, SetupManager 4, DataGeneration 2, IndustryProfiles 1, Finance 1. 15 Module weiterhin ohne AL-Code. Finance enthält nur einen lesenden Setupcheck, IndustryProfiles nur generische versionierte Syntheseregeln; keine vollständigen Fachgeneratoren oder Branchenprofile. Manifest/Launch unverändert. Schnittstellen, Defaultwerte, Sicherheits- und Kompatibilitätsgrenzen: [SETUP_SEED.md](SETUP_SEED.md). Kein Deployment oder nachgewiesener BC-Laufzeittest. **Zur Prüfung**.

## Aktueller Bestand SF-011/SF-012 – 15.11.2026

81 AL-Objekte in zehn Modulen, davon 80 numerische IDs und ein Interface: BackgroundProcessing 12, DataGeneration jetzt 6, Lifecycle jetzt 4; alle anderen Modulzahlen wie bei SF-009/SF-010. 14 Module weiterhin ohne AL-Code. Herkunftsregistry, getrennte Ausführungs-/Batchpersistenz und serielle Standard-Job-Queue-Grundlage vorhanden. Keine echten Fachgeneratoren, kein Retry/Resume und kein bestätigter End-to-End-Lauf. Header und Snapshot bleiben immutable. Manifest/Launch unverändert, Build gegen lokale BC-28.5-/DE-/Runtime-17-Symbole. [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md), Status **Zur Prüfung**.

## Aktueller Bestand SF-013 – 16.11.2026

85 AL-Objekte (84 numerische IDs und ein Interface) in zehn Modulen; BackgroundProcessing nun 16, übrige Bestände unverändert, 14 Module ohne AL-Code. Neue Objekte 90304 und 90313–90315 für begrenzte Recovery, Steuerung und technische Checkpoints. Manifest/Launch/Runtime/Dependencies unverändert. Checkpoints enthalten keine fachlichen Nutzdaten; keine echte Generator-/Setupbindung oder BC-Laufzeitabnahme ergänzt. [RECOVERY.md](RECOVERY.md), **Zur Prüfung**.

## Aktueller Bestand SF-014/SF-015 – 16.11.2026

97 AL-Objekte (96 numerische IDs plus Interface) in elf Modulen. Monitoring 11, ScenarioManagement 22, übrige Modulzahlen wie SF-013; 13 Module ohne AL-Code. Native Dashboard-/Schritt-/Statushistorienansicht und geführte fünfstufige Planung mit bestehendem Start-Gate. Profilkennungen bleiben Planungsmetadaten; keine echten Generatoren/Branchenpresets/globalen Validierungsregeln ergänzt. Manifest/Launch unverändert. Lokale Paketierung ersetzt keine Sandboxabnahme. [Vertrag und Grenzen](MONITORING_WIZARD.md), **Zur Prüfung**.

## SF-014 – präzisierter JavaScript-Arbeitsplatz – 16.11.2026

Jetzt 104 AL-Objekte (101 numerisch sowie Interface, ControlAddIn und Profil ohne numerische ID). Monitoring 18, alle anderen Modulzahlen wie zuvor. Neues eigenes Role-Center/Profil, wiederverwendbare Dashboard-CardPart und Host, Daten-/Aktionsservice sowie gebündelte JS/CSS-Ressourcen. Run Header ausschließlich um Leseschlüssel ergänzt. Manifest, Runtime und App-Dependencies unverändert. [Vertrag, Einbau und Grenzen](DASHBOARD_EMBEDDING.md). Status **Zur Prüfung**, echte BC-Abnahme offen.


## SF-002 – Strukturumstellung (16.11.2026)

104 vorhandene AL-Dateien in elf Modulen nach Objekttyp unter `src/<Modul>/<Objekttyp>/` eingeordnet; 13 Module ohne AL-Code bleiben mit Modulmarker erhalten. Dateinamen, Dateiinhalt, Objektidentitäten, Namespaces und Manifest werden erhalten. Bestehende offene Nutzeränderungen sind Teil des Ausgangsbestands. Konventionen, Objektpfade und Dashboard-Prüfskript folgen der neuen Ablage. Prüfungen und Grenzen: [TESTS.md](TESTS.md#sf-002--strukturumstellung-16112026). Status **Zur Prüfung**.


## SF-014 – Dashboardkorrektur 17.11.2026

Eigener höhenbegrenzter Scrollbereich und aus dem vorhandenen deutschen XLIFF-Master erzeugte Fallback-Ressource für Dashboardlabels ergänzt. BC-Sitzungssprache und Zahlenregion bleiben getrennt. Browserregression einschließlich 500px/Iframe/DE bestanden; reine Kompilierung erfolgreich, strenger Gesamtbuild durch 23 bereits im Ausgangsbestand vorhandene Analyzerbefunde blockiert. Kein Deployment. [Vertrag](DASHBOARD_EMBEDDING.md), [Prüfungen](TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). **Zur Prüfung**.


## Aktueller Bestand SF-016/SF-017 – 18.11.2026

116 vorhandene AL-Dateien in zwölf Modulen, davon 113 numerische IDs und Interface/ControlAddIn/Profil. Core 14, ScenarioManagement 22, IndustryProfiles 1, ModuleRegistry 10, DependencyManager 9, SetupManager 4, DataGeneration 6, BackgroundProcessing 17, Validation 4, Monitoring 18, Lifecycle 4, Finance 7. Zwölf Module ohne AL-Code. Der Ausgangscode enthielt bereits die zwölf zusätzlichen Objekte; deren Sicherheits-/Qualitätslücken und Analyzerbefunde wurden im aktuellen Auftrag bearbeitet, ohne Objektverschiebung oder neue IDs.

Pflichtabschluss, append-only Befunde und versionierte SKR03-/SKR04-Testeinrichtung einschließlich Standard-Finanzberichten implementiert. Manifest/Launch/AGENTS unverändert; Runtime 17, Dependencies []. Lokaler strenger Build und Übersetzungs-/Dashboardprüfung ersetzen keine Sandbox-/Buchungsabnahme. [Vertrag und BC-Prüfplan](VALIDATION_FINANCE.md). **Zur Prüfung**.


## Aktueller Bestand SF-018 – 18.11.2026

121 AL-Dateien in 14 Modulen: neu zwei Sales-, zwei Purchasing-Objekte und eine gemeinsame DataGeneration-Codeunit (dort jetzt 7). 118 eindeutige numerische IDs; zehn Module ohne AL-Code. Echte Customer-/Vendor-Mastergeneratoren samt konkreter Partnerkonfiguration, Snapshotbindung und Queue-/Herkunfts-/Abschlussintegration. Keine Artikel-/Dokument-/Postinggeneratoren ergänzt. Manifest/Launch unverändert, lokale Symbole BC 28.5/DE, Runtime 17. [Vertrag und offene BC-Abnahme](PARTNER_GENERATION.md). **Zur Prüfung**.


## Aktueller Reparaturauftrag SF-037 – 18.11.2026

Grundlage ist der aktuelle Workspace einschließlich bereits vorhandener Starter-, Schnellstart-, Transfer- und Zustandsfixes. App-ID/Version 1.0.1.0, Application 28.0, Runtime 17 und Dependencies [] bleiben erhalten. Gegen die vorhandenen BC-28.5-/DE-Symbole gebaut; keine Aussage über den tatsächlich installierten Playground-Paketstand. Additive Scenario.Archived und Tabelle 90148 für entfernte Vorlagen. Aktueller Bestand und lokale Nachweise: [TESTS.md](TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). Native BC-/Installations-/Queue-/Transferabnahme offen; keine menschliche Abnahme.


## SF-038 / SF-039 – aktueller Bestand

Manifest unverändert 1.0.1.0, Application 28, Runtime 17. Aktuell 131 AL-Dateien; neue interne DataGeneration-Codeunits 90257/90258. Finance-Paketneuanlage 2.0.0, neue Partnerregel-/Setupversion 2; historische Versionen bleiben erhalten. [Vertrag und Grenzen](STABILIZATION_FINANCE_PARTNERS.md). Status **Zur Prüfung**, kein Deployment oder BC-Abnahmenachweis.


## SF-044 – kompakter Arbeitsplatz, 19.11.2026

Verifizierter Ausgangs-/Endbestand: 121 AL-Dateien, davon 19 unter Monitoring. Keine neuen AL-Objekte, Tabellen oder Felder. App-ID, Publisher, Version 1.0.4.0, Application 28.0.0.0, Runtime 17, ID-Bereich 90100–90999 und Dependencies [] unverändert. Daten-/Laufreiter, Kachelraster und sichere Zählernavigation im bestehenden Dashboard ergänzt. [Bedienung und offene BC-Abnahme](DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026), [lokale Prüfungen](TESTS.md#sf-044--kompaktes-dashboard-und-direkte-kennzahlen). **Zur Prüfung**.

## SF-019 – verifizierter Quellstand 20.11.2026

Main-App 1.0.4.0 / Runtime 17 / Application 28.0 unverändert; keine neuen Main-App-Dependencies. 127 AL-Dateien in 15 Modulen, sechs neue Inventory-Objekte und acht optionale Felder in der bestehenden Szenariotabelle. `internalsVisibleTo` bindet nur die eigene separate SF-019-Test-App, keine Laufzeit-/SDK-Abhängigkeit und keine Standardrechteerhöhung. Test-App hat eigene Identität/Dependencies und nur Test-Codeunit 90700.

[Implementierung, Testanleitung und Scope](INVENTORY_GENERATION.md), [echte lokale Prüfungen, Nutzer-Sandboxfehler und offene Korrekturabnahme](TESTS.md#sf-019--artikelsortiment-und-lagerbasics-20112026). Der Nutzer meldet einen fehlgeschlagenen Artikelstart durch vertauschte Item-Vendor-Schlüssel; die korrigierte Version ist deshalb nicht als fachlich abgenommen erklärt. **Zur Prüfung**.

## SF-021 – Verkaufsprozess, 20.11.2026

Aktuelle Main-Version **1.0.5.0**, App-ID/Publisher/Application 28.0/Runtime 17/IDs 90100–90999/Dependencies [] unverändert. 133 Main-AL-Dateien in 16 Modulen, Sales sieben/ProcessEngine ein Objekt; keine neue Tabelle/Seite, zwei additive Szenariofelder. Angebote, Standard-Angebotsumwandlung, offene/volle/halbe Verkäufe, Standardbuchung und Herkunft im vorhandenen Queuepfad. Quelle ausdrücklich aus abgeschlossenem synthetischem Lauf; keine Umsetzung SF-020. Separate bestehende Test-App jetzt 19 Tests, keine neue Test-Codeunit. [Vertrag und Grenzen](SALES_PROCESS.md), [Prüfstand](TESTS.md#sf-021--verkaufsprozess-20112026). **Zur Prüfung**, keine Sandboxabnahme oder Veröffentlichung.

## SF-021 – Vorlagenkorrektur 1.0.5.1

Bestand unverändert 133 Main-AL-Dateien/16 Module, keine neuen AL-Objekte/Tabellen/Seiten/Felder. Main 1.0.5.1, Testhost 1.1.1.0 mit 26 Methoden. Neue Vorlagen mit GENERAL/1-Debitor-Ziel; Ausführbarkeit anhand tatsächlicher registrierter Zielmodi. Sicheres Löschen/Archivieren sichtbar. Erkennbare unveränderte 16 Branchen-Belegstarter werden auf Verkauf v2 aktualisiert, zusätzliche gemischte Verkaufsvorlage; eigene/entfernte/archivierte Vorlagen und immutable Läufe bleiben geschützt. [Vertrag](SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051). **Zur Prüfung**, native Prüfung/Deployment offen.


## SF-046 – Geschäftsdatenexport, 22.11.2026

Main-Version 1.0.8.1; bestehende App-ID 618c08c6-601b-430a-90d2-55f96866bfa4, Default Publisher, Application 28.0.0.0, Runtime 17.0, IDs 90100–90999 und Dependencies [] erhalten. 143 Main-AL-Objekte; drei neue Monitoring-Codeunits 90371–90373, keine neue Tabelle/Seite oder Schemaänderung. Separate Test-App 1.4.0.1 referenziert Main 1.0.8.1; bestehender Testhost um vier Methoden erweitert (52 insgesamt).

BCSF-ALL-DATA wird seit 1.0.8.1 erst über die ausdrückliche Dashboard-/Role-Center-Aktion in der aktuellen SaaS-Sandboxfirma angelegt. Installation/Upgrade enthält keinen Paketaufbau; bestehende Pakete bleiben erhalten. Nutzer meldet über 40 Firmen und eine hängende Installation von 1.0.8.0; hoher Aufwand des früheren PerCompany-Aufbaus ist plausibel, aber ohne native Telemetrie nicht als alleinige Ursache bewiesen. 128 symbolgeprüfte Tabellen, vollständiger Firmenumfang ausdrücklich bestätigt. [Bedienung, IDs und Grenzen](CONFIG_EXPORT.md). Keine Veröffentlichung/native Abnahme durch den Agenten; Publisher, externe ID-Konflikte und Zielumgebung bleiben gemäß SF-001 zu prüfen.
