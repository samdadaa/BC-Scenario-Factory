# TODO – BC Scenario Factory: vollständiger geplanter Backlog

**Stand:** 11.11.2026 – SF-003/SF-004 als erste neun AL-Grundlagenobjekte implementiert, zur Prüfung. Build mit CodeCop/UICop gegen lokale BC-28.5-Symbole erfolgreich; keine BC-Laufzeittests. SF-001 bleibt mit dokumentierten offenen Entscheidungen blockiert.

## Verbindliche Arbeitsregeln (aus dem vorhandenen TODO/AGENTS.md übernommen)

- Pro Auftrag **genau ein ausdrücklich vom Nutzer genanntes Ticket** bearbeiten; keine automatischen Folge-Tickets.
- Zulässige Stati: `Offen` → `In Arbeit` → `Zur Prüfung` → `Erledigt`; `Blockiert` bei konkreter offener Frage.
- Nur menschliche Abnahme erlaubt `Erledigt`; Build, Codegenerierung oder Häkchen reichen nicht.
- Vor jeder Umsetzung realen Code, BC-Version, Objekt-ID-Range, Zielumgebung und Standard-APIs prüfen.
- Vor Änderung Umfang, betroffene Dateien, Risiken, Voraussetzungen und echte Testschritte beschreiben.
- Keine Deployments, Git-Aktionen, stillen Dateiverschiebungen, Produktionsänderungen oder Testdateneinspielung ohne Freigabe.
- Tests niemals als ausgeführt/erfolgreich ausgeben, wenn sie nicht wirklich liefen.
- Allgemeine Prinzipien: Sandbox-only, synthetische Daten, freigegebene BC-Standardbuchungen, kontrollierte Queue-Batches, sicheres Retry, kein XERJ in BC.

## Ticketübersicht

| Ticket | Phase | Prio | Titel | Status |
| --- | --- | --- | --- | --- |
|x[SF-001](#sf-001) | 0 / Fundierung | P0 | Projektkonfiguration, Objekt-ID-Strategie und Ziel-Sandbox abstimmen | Blockiert |
|x[SF-002](#sf-002) | 0 / Fundierung | P0 | AL-Struktur, Namenskonventionen und Objektplan finalisieren | Zur Prüfung |
|x[SF-003](#sf-003) | 0 / Fundierung | P0 | Sicherheitsguard: Sandbox, Mandant, Berechtigung | Zur Prüfung |
|x[SF-004](#sf-004) | 0 / Fundierung | P0 | Globale Factory-Einstellungen und Statusgrundlagen | Zur Prüfung |
| [SF-005](#sf-005) | 0 / Fundierung | P0 | Szenariovorlagen und versionierte Run-Snapshots | Offen |
| [SF-006](#sf-006) | 0 / Fundierung | P0 | Entitätsmengen, Quoten und Prozessmodi konfigurieren | Offen |
| [SF-007](#sf-007) | 0 / Fundierung | P0 | Generator-Vertrag und Registry definieren | Offen |
| [SF-008](#sf-008) | 0 / Fundierung | P0 | Abhängigkeitsgraph und Ausführungsplan | Offen |
| [SF-009](#sf-009) | 0 / Fundierung | P0 | BC-Setup-Prüfung und nicht-destruktiver Setup-Diff | Offen |
| [SF-010](#sf-010) | 0 / Fundierung | P0 | Synthetischer Realismus und Seed-Engine | Offen |
| [SF-011](#sf-011) | 0 / Fundierung | P0 | Erzeugte Datensätze und Belegketten nachverfolgen | Offen |
| [SF-012](#sf-012) | 0 / Fundierung | P0 | Job-Queue Dispatcher, Run-/Batch-Tabellen | Offen |
| [SF-013](#sf-013) | 0 / Fundierung | P0 | Batch-Checkpoint, Retry, Pause/Resume, Cancellation | Offen |
| [SF-014](#sf-014) | 0 / Fundierung | P0 | Monitoring-Datenmodell und Dashboard | Offen |
| [SF-015](#sf-015) | 0 / Fundierung | P0 | Wizard für Branche, Module, Umfang und Planung | Offen |
| [SF-016](#sf-016) | 0 / Fundierung | P0 | Validierungsframework und Abschlussstatus | Offen |
| [SF-017](#sf-017) | 1 / MVP | P1 | Finanz-Grundsetup für Handelsprofil | Offen |
| [SF-018](#sf-018) | 1 / MVP | P1 | Debitoren und Kreditoren als kohärente Stammdaten | Offen |
| [SF-019](#sf-019) | 1 / MVP | P1 | Artikel, Kategorien, Varianten und Lagerbasics | Offen |
| [SF-020](#sf-020) | 1 / MVP | P1 | Einkaufsprozess: Bestellung bis gebuchte Rechnung | Offen |
| [SF-021](#sf-021) | 1 / MVP | P1 | Verkaufsprozess: Angebot bis gebuchte Rechnung | Offen |
| [SF-022](#sf-022) | 1 / MVP | P1 | Zahlungen, Ausgleich, Gutschriften und Folgeprozesse | Offen |
| [SF-023](#sf-023) | 1 / MVP | P1 | Großhandel als erstes Branchenprofil | Offen |
| [SF-024](#sf-024) | 1 / MVP | P1 | End-to-End-MVP und fachliche Qualitätsgate | Offen |
| [SF-025](#sf-025) | 1 / MVP | P1 | AL-Test-App und fachliche Regressionssuite | Offen |
| [SF-026](#sf-026) | 1 / MVP | P1 | Lasttests, Durchsatzmessung, große Datenmengen | Offen |
| [SF-027](#sf-027) | 1 / MVP | P1 | Sicheres Lauf-Lifecycle, Retention und Reset | Offen |
| [SF-028](#sf-028) | 2 / Ausbau | P2 | Warehouse-Prozessgenerator | Offen |
| [SF-029](#sf-029) | 2 / Ausbau | P2 | Manufacturing- und Assembly-Generator | Offen |
| [SF-030](#sf-030) | 2 / Ausbau | P2 | Projects- und ServiceManagement-Generator | Offen |
| [SF-031](#sf-031) | 2 / Ausbau | P2 | Anlagen und Abschreibungsfälle | Offen |
| [SF-032](#sf-032) | 2 / Ausbau | P2 | Weitere Profile: E-Commerce, Fertigung, Dienstleistung, Bau, Logistik, Wartung | Offen |
| [SF-033](#sf-033) | 3 / Produkt | P3 | CRM/Relationship- und Planning-Generatoren | Offen |
| [SF-034](#sf-034) | 3 / Produkt | P3 | Öffentliche Generator-Erweiterungs-API | Offen |
| [SF-035](#sf-035) | 3 / Produkt | P3 | Schulungsfälle, Aufgaben und Erfolgskontrollen | Offen |
| [SF-036](#sf-036) | 3 / Produkt | P3 | Release, AppSource-/PTE-Eignung und Dokumentation | Offen |

## Detaillierte Tickets

### AL-001 — Ursprüngliche AL-Agentura-Projektbasis prüfen (historische Ticket-ID)

**Status:** Offen  
**Priorität:** P0  
**Hinweis:** Inhalt aus der ursprünglichen `TODO.md` wird als bestehendes Ticket erhalten. Es ist ein **reines Prüf- und Dokumentationsticket**, kein Auftrag zum Implementieren. Überschneidungen mit `SF-001` vermeiden und nicht ungefragt beide bearbeiten.

**Ziel:** `app.json`, Objekt-ID-Bereich, echte AL-Dateien, Modulpfade und offene Konfigurationen prüfen und dokumentieren, ohne AL-Objekte oder Bestandskonfiguration zu ändern.

**Einzelaufgaben:**
- [ ] Projektdateien und Modulpfade lesend prüfen.
- [ ] Tatsächliche AL-Objekte zählen; nicht vorhandene Implementierung klar ausweisen.
- [ ] Versions-/ID-/Publisher-Fragen und offene Entscheidungen dokumentieren.
- [ ] Prüfbericht erstellen und nächstes Ticket nur **vorschlagen**.

**Akzeptanz:** Eine belegte Bestandsaufnahme, keine behaupteten Tests, keine unfreigegebenen AL-/Git-/Deployment-Änderungen.

---

### SF-001 — Projektkonfiguration, Objekt-ID-Strategie und Ziel-Sandbox abstimmen

**Status:** Blockiert
**Priorität:** P0  
**Abhängigkeiten:** Keine  
**Verantwortung / betroffene Module:** app.json, .vscode/launch.json, PROJECT/DECISIONS  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Publisher, freigegebene Objekt-IDs, AppSource/PTE-Ziel, Version/Lokalisierung, Sandbox- und Firmenstrategie dokumentieren; 50-ID-Grenze ausdrücklich klären.

**Soll-Verhalten / technischer Arbeitsauftrag:** Konfiguration mit freigegebenen Entscheidungen abgleichen, Symbol-/Build-Weg vorbereiten; keine unbestätigten Werte übernehmen.

**Bearbeitungsnachweis 11.11.2026:** Bestandsprüfung, Risiken, ID-Strategie ohne neue Reservierungen und Symbol-/Build-Weg in [docs/PROJECT.md](docs/PROJECT.md#sf-001--aktuelle-bestandsprüfung-vom-11112026) dokumentiert. Offene Entscheidungen und konkrete Rückfragen in [docs/DECISIONS.md](docs/DECISIONS.md#sf-001--ausstehende-festlegungen); tatsächlich ausgeführte Prüfungen und Einschränkungen in [docs/TESTS.md](docs/TESTS.md#sf-001--lokales-prüfprotokoll-vom-11112026).

**Erstprüfung vor Nutzerrückmeldung:** 0 AL-Dateien, 0 lokale Symbolpakete, 24 weiterhin leere Module. Manifest strukturell geprüft; `50100..50149` umfasst 50 numerische Werte, lokale Objektkollisionen mangels Objekten nicht vorhanden. Externe Belegung ungeprüft. Lokale AL-Erweiterung mit Compilerdateien vorhanden, Compiler nicht gestartet. Zwei Launch-Profile mit gleichem Namen, aber `Playgrund`/`Playground`; Ziel nicht bestätigt. Keine Änderungen an Manifest, Launch-Konfiguration, AL-Objekten oder anderen Tickets.

**Umsetzung nach Nutzerrückmeldung:** `Playground` und Entwicklungsmodus bestätigt; Auswahl der Range ausdrücklich delegiert. `app.json` auf `50100..50999` (900 ID-Werte) erweitert. Erstes Launch-Profil eindeutig als `BC Scenario Factory - Playground (Dev)` benannt und auf `Playground` korrigiert; zweites Profil erhalten. App-ID, Publisher, Versionswerte und Debug-Einstellungen erhalten. README und Projektnachweise aktualisiert.

**Verbleibende Blocker:** Exakten Publisher, tatsächliche BC-Version/Runtime, Lokalisierung und isolierte Testfirmenstrategie festlegen; Umgebungs-/Rechteprüfung und externe ID-Belegung nachweisen. Ein späteres PTE-/AppSource-Releaseziel ist weiterhin offen, für den aktuellen Entwicklungsmodus aber nicht erforderlich.

**Teststand:** Lokale JSON-, Datei-, Profil- und Werkzeugprüfung ausgeführt. AL-Build/Analyzer, Sandbox-Erreichbarkeit, externe ID-Kollisionen und Rechteprüfung nicht ausgeführt. Keine BC-Daten erzeugt. Nach Klärung Konfiguration abgleichen, Symbole laden und Build-/Umgebungsnachweis ergänzen; erst anschließend `Zur Prüfung`, `Erledigt` ausschließlich nach menschlicher Abnahme.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Freigegebener, kollisionsgeprüfter Objektbereich und bestätigte Sandbox; Testumgebung tatsächlich erreichbar oder Blocker dokumentiert.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-002 — AL-Struktur, Namenskonventionen und Objektplan finalisieren

**Status:** erledigt
**Priorität:** P0  
**Abhängigkeiten:** SF-001  
**Verantwortung / betroffene Module:** Core; docs/CONVENTIONS.md  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Objektnamen/-präfix, File Naming, Namenspaces, Interface-/Codeunit-Layer und Objekt-ID-Allokation pro Modul abstimmen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Objektplan mit Verantwortlichkeiten erstellen; keine leeren Dummy-Objekte generieren.

**Ergebnis 11.11.2026:** [Objektplan](docs/OBJECT_PLAN.md) mit Präfix/Namespace, Dateinamen, 24 disjunkten ID-Blöcken im ausdrücklich bestätigten Bereich `90100..90999`, 59 numerischen Planobjekten und einem Interface erstellt. 300 ID-Werte bleiben gemeinsame Reserve. Erlaubte Codeabhängigkeiten und Daten-/Transaktionsgrenzen beschrieben, alle 24 Modulspezifikationen und zentrale Dokumentation abgeglichen. Keine AL-Objekte angelegt; Manifest und Launch erhalten.

**Abhängigkeit SF-001:** Dokumentationsplanung auf Basis der bestätigten Range möglich. Publisher, reale Zielversion/Lokalisierung, Testfirma und externe Kollisions-/Rechteprüfung bleiben offen und werden durch diesen Plan nicht als erfüllt erklärt.

**Prüfnachweis:** Siehe [TESTS.md](docs/TESTS.md), Abschnitt SF-002. Nur lokale Dokument-/Strukturprüfungen, kein AL-Build, Analyzer oder Sandbox-Test. Keine fachlichen Laufzeiteffekte; spätere Kompatibilität anhand echter Ziel-Symbole prüfen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [x] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [x] Konfliktfreier Objektplan und feste Modulegrenzen dokumentiert.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [x] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-003 — Sicherheitsguard: Sandbox, Mandant, Berechtigung

**Status:** Zur Prüfung\
**Priorität:** P0  
**Abhängigkeiten:** SF-001  
**Verantwortung / betroffene Module:** Lifecycle, Core  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Mutierende Aktionen einschließlich Queue-Worker vor Produktion schützen; Rollen/Permission Sets, Zielmandant, Freigaben definieren.

**Soll-Verhalten / technischer Arbeitsauftrag:** Umgebungsprüfung versionsgerecht implementieren; Negativtests für Produktion/fehlende Rechte, keine Bypass-Pfade.

**Umsetzung 11.11.2026:** Guard 90375 und Permission Set 90105 implementiert. Tatsächliche Production/SaaS/Sandbox-Metadaten, Name/Firma, effektive Setup-Rechte, Generation-/Postingfreigabe und Mengenlimits werden geprüft. Vier verpflichtende Setup-Before-Events sichern direkte Insert/Modify-Pfade; Delete/Rename gesperrt. Keine GUI-/RunTrigger-Ausnahme, kein Test-Bypass und keine erhöhten Standarddatenrechte. Künftige Generatoren/Worker sind noch nicht implementiert und müssen den Guard später ausdrücklich aufrufen.

**Nachweise / Grenzen:** [FOUNDATION.md](docs/FOUNDATION.md), aktualisierter [Objektplan](docs/OBJECT_PLAN.md), Core-/Lifecycle-Moduldokumentation und [TESTS.md](docs/TESTS.md). Build von neun AL-Dateien mit AL Compiler 18.1.43.24897, CodeCop/UICop und Warnungen als Fehlern erfolgreich; fünf lokale Microsoft-28.5-/DE-Symbolpakete, Runtime 17. Keine ausgeführten BC-Laufzeit-/Negativ-/Berechtigungstests; diese Prüffälle sind konkret beschrieben und bleiben offen. app.json und launch.json unverändert. Publisher, Testfirma und tatsächliche Sandbox-/Rechteprüfung aus SF-001 bleiben offen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Alle schreibenden Einstiegspunkte blockieren unzulässige Umgebung und zeigen verständlichen Grund.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [x] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-004 — Globale Factory-Einstellungen und Statusgrundlagen

**Status:** Zur Prüfung\
**Priorität:** P0  
**Abhängigkeiten:** SF-002,SF-003  
**Verantwortung / betroffene Module:** Core  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Defaults, Grenzen, Konfiguration, stabile Run-/Batch-IDs, Status-Enums, Benutzerfeedback und Validation-Regeln festlegen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Kleine testbare Kernobjekte, AL Labels/Tooltips und dokumentierte Statusübergänge.

**Umsetzung 11.11.2026:** Setup-Tabelle/Card 90100/90101, Run-/Prozess-/Nutzungs-Enums 90102–90104 sowie Setup Management 90106 und Run State Mgt 90107 implementiert. Singleton je Firma, explizite deaktivierte Initialisierung, validierte Mengen-/Moduseinstellungen und Labels/Tooltips. GUID-Hilfen erhalten vorhandene IDs; dokumentierter Run-Zustandsgraph. Keine Run-/Batch-Persistenz oder Seed-Engine vorweg implementiert.

**Nachweise / Grenzen:** [FOUNDATION.md](docs/FOUNDATION.md), aktualisierter [Objektplan](docs/OBJECT_PLAN.md), Core-/Lifecycle-Moduldokumentation und [TESTS.md](docs/TESTS.md). Build von neun AL-Dateien mit AL Compiler 18.1.43.24897, CodeCop/UICop und Warnungen als Fehlern erfolgreich; fünf lokale Microsoft-28.5-/DE-Symbolpakete, Runtime 17. Keine ausgeführten BC-Laufzeit-/Negativ-/Berechtigungstests; diese Prüffälle sind konkret beschrieben und bleiben offen. app.json und launch.json unverändert. Publisher, Testfirma und tatsächliche Sandbox-/Rechteprüfung aus SF-001 bleiben offen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Einstellungen konsistent gespeichert, validiert und auslesbar; Tests für ungültige Werte.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [x] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [x] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-005 — Szenariovorlagen und versionierte Run-Snapshots

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-004  
**Verantwortung / betroffene Module:** ScenarioManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Vorlagen mit Branche, Nutzungsziel, Seed, Zeitfenster und gespeicherter Revision; Lauf darf von späterer Vorlagenänderung nicht abhängen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Tabellen/Pages nach freigegebenem Schema; Snapshots bei Start atomar speichern; Änderungsschutz.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Gleiche Vorlage kopierbar, aktiver Run unveränderlich und vollständig rekonstruierbar.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-006 — Entitätsmengen, Quoten und Prozessmodi konfigurieren

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-005  
**Verantwortung / betroffene Module:** ScenarioManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Ziele pro Debitor/Kreditor/Artikel/Belegtyp; Quoten, Presets und vier Prozessmodi; Abhängigkeitsmengen schätzen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Validation bei widersprüchlichen Mengen/Modi, kein irreführender Globalzähler.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Anwender definiert getrennte Ziele und sieht plausibel nötige Folgedaten.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-007 — Generator-Vertrag und Registry definieren

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-002,SF-004  
**Verantwortung / betroffene Module:** ModuleRegistry, Core  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Capabilities, unterstützte Modi/Entitäten, Parameter, Preflight, Batch und Validierung über AL-kompatibles Interface/Registrierung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Technische Alternativen und spätere Drittanbieter-Erweiterung prüfen, deterministische Registry.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Zwei Testgeneratoren lassen sich ohne Änderung der zentralen Steuerung unterscheiden und ansprechen.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-008 — Abhängigkeitsgraph und Ausführungsplan

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-006,SF-007  
**Verantwortung / betroffene Module:** DependencyManager  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Gerichtete fachliche Abhängigkeiten, Zyklenerkennung, Pflicht-/Optionalpfade, module-/modusabhängige Reihenfolge.

**Soll-Verhalten / technischer Arbeitsauftrag:** Topologische Planung, verständliche Konfliktmeldungen, Startverbot bei Blockern.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Finance→Stamm→Einkauf→Bestand→Verkauf in korrekter Reihenfolge; absichtlich zyklische Regel wird erkannt.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-009 — BC-Setup-Prüfung und nicht-destruktiver Setup-Diff

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-003,SF-008  
**Verantwortung / betroffene Module:** SetupManager, Finance  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Vorhandene Buchungsgruppen, No. Series, MwSt., Dimensionen, Zahlungsbedingungen, Lager-Setup und Rechte lesen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Preflight als Read-only, Maßnahmenplan und Freigabe; vollen Leerfirmen-Setup gesondert entscheiden.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Bestehende Einrichtung unverändert; fehlende Pflichtwerte präzise sichtbar und blockierend.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-010 — Synthetischer Realismus und Seed-Engine

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-004,SF-006  
**Verantwortung / betroffene Module:** DataGeneration, IndustryProfiles  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Deterministische synthetische Firmen-/Personen-/Artikel-/Preiswerte mit realistischen Streuungen, Datums-/Klassenregeln.

**Soll-Verhalten / technischer Arbeitsauftrag:** Pseudodaten ohne echte Empfänger/Konten; logische Schlüssel unabhängig von Reihenfolge; Profileinstellungen versionieren.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Gleiche Konfiguration erzeugt gleiche Eingangsdaten, verschiedene Seeds plausible Varianten ohne reale PII.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-011 — Erzeugte Datensätze und Belegketten nachverfolgen

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-005,SF-010  
**Verantwortung / betroffene Module:** Lifecycle, DataGeneration  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Run→Generator→LogicalKey→Record/Beleg/Posting dokumentieren, Wiederanlauf und Validierung ermöglichen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Registry mit eindeutigen Schlüsseln und datensparsamem Audit; Standard-Posting-Ergebnisbezug prüfen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Jede erzeugte Einheit eindeutig einem Run zuordenbar; erneute Erstellung wird erkannt.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-012 — Job-Queue Dispatcher, Run-/Batch-Tabellen

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-003,SF-005,SF-008,SF-011  
**Verantwortung / betroffene Module:** BackgroundProcessing  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Persistente Steps/Batches, Statusmaschine und Queue-Steuerung für nichtinteraktive Ausführung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Rechte, Scheduling und Abhängigkeiten berücksichtigen; keine unbegrenzten parallelen Worker.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Start, Laufstatus und Einzelbatches sichtbar; Browser kann geschlossen werden.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-013 — Batch-Checkpoint, Retry, Pause/Resume, Cancellation

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-012  
**Verantwortung / betroffene Module:** BackgroundProcessing  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Fehlerisolierung, Retry-Limits, nachweisbar sichere Checkpoints, doppelte Claims vermeiden; manueller NeedsReview-Modus.

**Soll-Verhalten / technischer Arbeitsauftrag:** Unterbrechungen während Datenerstellung/Posting simulieren, keinen blinden Wiederholungsversuch nach unklarem Commit.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Fehlgeschlagene Arbeit kann nach Sicherungsprüfung fortgesetzt werden ohne doppelte Datensätze/Postings.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-014 — Monitoring-Datenmodell und Dashboard

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-012,SF-013  
**Verantwortung / betroffene Module:** Monitoring, UI  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Kacheln, Modul-/Entitäts-Soll/Ist, Queue-Status, Zeiten, Drilldowns, Fehlermeldungen und Validierung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Native BC-Pages/FactBoxes/Role-Center-Option prüfen; Anzeigen lesen persistierte Zustände.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Anwender erkennt Lauf, Step, Batch, Fortschritt, Fehler und noch offene Daten ohne erneuten Start.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-015 — Wizard für Branche, Module, Umfang und Planung

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-006,SF-008,SF-009,SF-014  
**Verantwortung / betroffene Module:** ScenarioManagement, IndustryProfiles, UI  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Fünf Schritte: Branche/Nutzungsziel, Module, Entity-Ziele, Prozessmodus, Preflight/Freigabe/Startzeit.

**Soll-Verhalten / technischer Arbeitsauftrag:** Abhängigkeiten und Buchungsrisiken eindeutig anzeigen; Tooltips/Barrierefreiheit.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Ein vollständiges Szenario durch Wizard planbar; keine Job-Ausführung vor gültiger Freigabe.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-016 — Validierungsframework und Abschlussstatus

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-007,SF-011,SF-012  
**Verantwortung / betroffene Module:** Validation  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Regeln je Generator, Mengen-/Beziehungs-/Posting-Validierung, Severity, Ergebnisse, Abweichungen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Pflichtprüfungen von optionalen unterscheiden; Completed nur bei validierter Arbeit.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Fehlende Posten und Mismatches verhindern falsche Erfolgsmeldung.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-017 — Finanz-Grundsetup für Handelsprofil

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-009,SF-010  
**Verantwortung / betroffene Module:** Finance  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Zulässige Konten/Buchungsgruppen/MwSt./No.Series/Dimensionen/Zahlungsbedingungen in Ziel-Lokalisierung prüfen/ergänzen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Preflight-Regeln statt pauschaler Einrichtung; konkrete Standard-Objekte versionsgerecht identifizieren.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Finance-Voraussetzungen für Debitoren/Kreditoren/Artikel/Posting validiert; bestehende Werte nicht überschrieben.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-018 — Debitoren und Kreditoren als kohärente Stammdaten

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-010,SF-011,SF-017  
**Verantwortung / betroffene Module:** Sales, Purchasing  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** B2B/B2C, Regionen, Zahlungsziele, Kreditlimits, Lieferantenklassen und Beziehungen plausibel und synthetisch anlegen.

**Soll-Verhalten / technischer Arbeitsauftrag:** BC-Validate verwenden; gleiche Adresse/Kontakte nicht wahllos kopieren, deutliche Variabilität.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Beide Entitäten erfüllen Setupanforderungen, Seed-/Registry-, Mengen- und Fachprüfungen.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-019 — Artikel, Kategorien, Varianten und Lagerbasics

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-009,SF-010,SF-017  
**Verantwortung / betroffene Module:** Inventory  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Lager-/Nichtlager-/Serviceartikel, Preise, Einheiten, Kategorien, Lagerorte und Bestandsvoraussetzungen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Artikelposten nur über Standardprozesse, keine direkten Ledger-Inserts.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Artikelstamm für Verkauf und Beschaffung valide, gemischte Kategorien und Bestände plausibel.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-020 — Einkaufsprozess: Bestellung bis gebuchte Rechnung

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-018,SF-019,SF-013  
**Verantwortung / betroffene Module:** Purchasing, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Ungebuchte Bestellungen, vollständige/teilweise Eingänge, gebuchte Eingangsrechnungen, ausgewählte Gutschriften.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Posting und resultierende Ledger/Inventory prüfen; Unsicherheiten bei Retry behandeln.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Jede Belegkette hat korrekte Lieferanten/Artikel/Posten und Soll-/Ist-Verfolgung.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-021 — Verkaufsprozess: Angebot bis gebuchte Rechnung

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-018,SF-019,SF-020  
**Verantwortung / betroffene Module:** Sales, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Angebote, Aufträge, Lieferungen, Teilmengen, Faktura, offene Debitorenposten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Sales-Posting, Bestand-/Preis-/Dimensionenprüfung; Standardprozess nicht umgehen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Demo mit plausibler Belegkette und passenden Posten; ungebuchter Modus bleibt ohne Ledger.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-022 — Zahlungen, Ausgleich, Gutschriften und Folgeprozesse

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-020,SF-021  
**Verantwortung / betroffene Module:** Finance, Sales, Purchasing, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Offene, teilweise und vollständig ausgeglichene Posten; unterschiedliche Zahlungszeitpunkte, Gutschriften/Retouren im freigegebenen Umfang.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Buchungs-/Ausgleichsprozesse und Referenzen, keine willkürlichen Ledger-Manipulationen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Status und Restbeträge stimmen je Vorgang; Fehler-/Teilzahlung getestet.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-023 — Großhandel als erstes Branchenprofil

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-007,SF-010,SF-017,SF-021  
**Verantwortung / betroffene Module:** IndustryProfiles, Finance, Sales, Purchasing, Inventory  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Parameter/Quoten für B2B/B2C, Artikelmix, Belegstatus, Preis- und Mengensegmente; Demo/Training/Functional/Performance.

**Soll-Verhalten / technischer Arbeitsauftrag:** Profil lediglich konfigurierend; einheitliche Fachgeneratoren wiederverwenden.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Großhandels-Demo mit überzeugender Geschichte und konfigurierbarem Mix vollständig erzeugbar.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-024 — End-to-End-MVP und fachliche Qualitätsgate

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-014,SF-015,SF-016,SF-022,SF-023  
**Verantwortung / betroffene Module:** Validation, Monitoring, UI  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Handelsdemo aus leer genug vorbereiteter Testfirma von Wizard bis Postenkontrolle; keine falschen Erfolgsmeldungen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Kleine Demo und mittlerer Funktionstest; Basis-/Sonderfälle und Run-Protokoll.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Durchgängige Lieferanten-/Lager-/Debitorenbelegkette; Qualitätsbericht mit echten Ergebnissen.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-025 — AL-Test-App und fachliche Regressionssuite

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-001,SF-016,SF-024  
**Verantwortung / betroffene Module:** Tests, alle P1-Module  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Separate Test-App nach genehmigter Workspace-Strategie; Kern-, Fehler-, Sicherheits-, fachliche und Retry-Tests.

**Soll-Verhalten / technischer Arbeitsauftrag:** Deterministische Fixtures, keine Testobjekte in Produkt-App; Tests gegen echte Sandbox.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Testmatrix aus docs/TESTS.md mit wiederholbaren Ergebnissen und klaren offenen Lücken.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-026 — Lasttests, Durchsatzmessung, große Datenmengen

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-024,SF-025  
**Verantwortung / betroffene Module:** BackgroundProcessing, Monitoring, Validation  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** 1k/10k/50k/100k als parametrisierte Fälle je Entität, Erstellungs- und Postingraten, Queue-Wartezeiten, Fehler.

**Soll-Verhalten / technischer Arbeitsauftrag:** Batchgrößen nach Arbeitsart benchmarken; kein versprochener Durchsatz.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Echte Benchmarks und Logs zeigen skalierbaren Betrieb oder dokumentierte Engpässe.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-027 — Sicheres Lauf-Lifecycle, Retention und Reset

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-003,SF-011,SF-024  
**Verantwortung / betroffene Module:** Lifecycle  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Aufbewahrung/Archivierung, markierte Daten, Reset/Neufirma, bestätigungsbedürftige nicht gebuchte Bereinigung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Für gebuchte Ledgerposten keine pauschalen Deletes; Risiken gegenüber Benutzer sichtbar.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Läufe datensparsam archiviert; sicherer Resetpfad nachvollziehbar, keine Fremddaten gelöscht.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-028 — Warehouse-Prozessgenerator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Warehouse  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Lagerplätze, Ein-/Auslagerung, Kommissionierung, Umlagerungen und Varianten von Lager-Konfiguration.

**Soll-Verhalten / technischer Arbeitsauftrag:** Abhängigkeiten zu Warehouse-Setup/Inventar prüfen; Nur-dort-wo-aktiv-Modus.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Bewegungen korrekt über unterstützte BC-Prozesse; Bestände konsistent.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-029 — Manufacturing- und Assembly-Generator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Manufacturing, Assembly  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Fertigungsstücklisten, Arbeitsplätze, Arbeitspläne, Produktionsauftrag/Verbrauch/Output sowie Montagestücklisten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Feature-/Lizenzprüfung und trennscharfe fachliche Workflows.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Output und Komponentenverbrauch validiert; Branchenprofil Fertigung demonstrierbar.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-030 — Projects- und ServiceManagement-Generator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Projects, ServiceManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Projekte, Projektaufgaben, Ressourcen, Zeiterfassung und Abrechnung; Servicefälle, Wartung, Ersatzteile, Faktura.

**Soll-Verhalten / technischer Arbeitsauftrag:** Verfügbare Standardobjekte/Versionen und ggf. getrennte Sprints prüfen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Zwei echte Ende-zu-Ende-Szenarien mit Projekt-/Serviceposten.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-031 — Anlagen und Abschreibungsfälle

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** FixedAssets, Finance  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Anlagenklassen, Anschaffung, Abschreibung, Abgang/Sonderfälle als synthetische Belegketten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Buchungsmethoden, Rechte und Finanzabhängigkeiten prüfen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Anlagenposten fachlich konsistent und sichtbar im Dashboard.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-032 — Weitere Profile: E-Commerce, Fertigung, Dienstleistung, Bau, Logistik, Wartung

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-028,SF-029,SF-030  
**Verantwortung / betroffene Module:** IndustryProfiles  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Branchenmischungen realistisch definieren und Fachgeneratoren wiederverwenden, keine harte Datenkopie.

**Soll-Verhalten / technischer Arbeitsauftrag:** Branchen-Eignung und optional erforderliche BC-Features beschreiben.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Pro Profil mindestens ein demonstrierbares, validiertes Szenario.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-033 — CRM/Relationship- und Planning-Generatoren

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** CRM, Planning  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Kontakte/Kampagnen/Opportunities und Nachfrage-/Beschaffungsplanung mit plausiblen Daten.

**Soll-Verhalten / technischer Arbeitsauftrag:** BC-Modulverfügbarkeit nach Version prüfen; kein Dynamics CRM On-Prem vermischen.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Fachlich nachvollziehbare Fälle mit geprüften Abhängigkeiten.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-034 — Öffentliche Generator-Erweiterungs-API

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-007,SF-025  
**Verantwortung / betroffene Module:** ModuleRegistry, Core  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Drittanbieter-/Branchenextension registriert Generatoren, Profile und Validierung ohne zentralen Fork.

**Soll-Verhalten / technischer Arbeitsauftrag:** API-Verträge, Versionierung und Security/Permissions dokumentieren.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Beispiel-Extension wird geladen und über standardmäßige Orchestrierung ausgeführt.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-035 — Schulungsfälle, Aufgaben und Erfolgskontrollen

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** ScenarioManagement, Monitoring  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Trainingsvorlagen mit Rollen, Lernzielen, Aufgaben, Ist-/Soll-Daten und Prüfergebnis; Wiederholung in frischer Testfirma.

**Soll-Verhalten / technischer Arbeitsauftrag:** Keine realen Mitarbeiterkonten erzeugen, sofern nicht explizit freigegeben.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Trainer kann reproduzierbaren Schulungsfall erstellen und Zielzustand überprüfen.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

### SF-036 — Release, AppSource-/PTE-Eignung und Dokumentation

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-025,SF-027,SF-034  
**Verantwortung / betroffene Module:** Core, docs  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Berechtigungen, Telemetrie, Lokalisierung, Help, Packaging, Testmatrix, Publisher/Lizenz und Produktgrenzen prüfen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Kein Release/Publish ohne Auftrag und tatsächlich erfolgreiche Checks.

**Vorgehen (einzeln abzuarbeiten):**
- [ ] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [ ] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [ ] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [ ] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [ ] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Dokumentierte Bereitstellung, Sicherheitsprüfung, Artefakte und Abnahme.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

## Ticketvorlage für zukünftige Änderungen

### SF-XXX — Titel
**Status:** Offen  
**Priorität:** P0/P1/P2/P3  
**Abhängigkeiten:** Konkrete Tickets  
**Betroffene Module:** Nach realem Code prüfen  
**Ziel:** ...  
**Umfang / Nicht-Ziele:** ...  
**Schritte:** [ ] Analyse [ ] Design [ ] Implementierung [ ] echte Tests [ ] Dokumentation  
**Akzeptanz:** Nachweisbarer fachlicher Sollzustand, keine Regression  
**Testprotokoll:** BC-Version, Umgebung, Inputs, Erwartung, tatsächliches Ergebnis, bekannte Grenzen  
**Freigabe:** [ ] Menschlich bestätigt.
