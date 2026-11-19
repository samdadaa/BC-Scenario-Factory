# TODO – BC Scenario Factory: vollständiger geplanter Backlog

**Stand:** 19.11.2026 – SF-040 nach Nutzerangabe eingespielt. SF-041 umgesetzt und zur gemeinsamen Sandbox-Prüfung bereit. SF-044 umgesetzt, zur Prüfung; reale BC-Abnahme offen.

## Verbindliche Arbeitsregeln (aus dem vorhandenen TODO/AGENTS.md übernommen)

- Pro Auftrag **genau ein ausdrücklich vom Nutzer genanntes Ticket** bearbeiten; keine automatischen Folge-Tickets.
- Zulässige Stati: `Offen` → `In Arbeit` → `Zur Prüfung` → `Erledigt`; `Blockiert` bei konkreter offener Frage.
- Nur menschliche Abnahme erlaubt `Erledigt`; Build, Codegenerierung oder Häkchen reichen nicht.
- Vor jeder Umsetzung realen Code, BC-Version, Objekt-ID-Range, Zielumgebung und Standard-APIs prüfen.
- Vor Änderung Umfang, betroffene Dateien, Risiken, Voraussetzungen und echte Testschritte beschreiben.
- Keine Deployments, Git-Aktionen, stillen Dateiverschiebungen, Produktionsänderungen oder Testdateneinspielung ohne Freigabe.
- Tests niemals als ausgeführt/erfolgreich ausgeben, wenn sie nicht wirklich liefen.
- Allgemeine Prinzipien: Sandbox-only, synthetische Daten, freigegebene BC-Standardbuchungen, kontrollierte Queue-Batches, sicheres Retry, kein XERJ in BC.

## Aktuelle Priorität – Stabilisierung vor Ausbau

P0-Reihenfolge: [SF-038](#sf-038) Finanzsetup → [SF-039](#sf-039) Partnerdaten → [SF-040](#sf-040) Stammdatenbasis. [SF-041](#sf-041) Dashboard kann nach Prüfung seiner eigenen Voraussetzungen unabhängig bearbeitet werden. [SF-042](#sf-042) schließt die Stabilisierung mit realer Sandbox-Abnahme ab. Erst danach [SF-019](#sf-019) und weitere neue Fachgeneratoren beginnen. Jedes Ticket bleibt ein eigener Auftrag.

**Verbindliche Qualitätsregeln für neue und geänderte Generatoren**

- Fachwerte natürlich, vielfältig und synthetisch erzeugen. Keine generischen Test-/Demo-/Muster-Präfixe und keine Zählersuffixe in Fachfeldern. Herkunft intern zuordnen, statt die BC-Fachwerte zu verfälschen. Keine echten Empfänger oder Zahlungsdaten verwenden.
- Pro Modul Setup, benötigte Stammdaten und Abhängigkeiten dokumentieren und vor dem ersten abhängigen Schritt prüfen. Passendes BC-Setup wiederverwenden. Keine spontanen Dummy-Konten, keine stillen Überschreibungen und keine Belege oder Buchungen bei blockierenden Voraussetzungen.
- BC-Standardvalidierung und freigegebene Standardprozesse verwenden. Daten und Beziehungen bleiben vollständig, Lauf und Wiederanlauf nachvollziehbar und frei von unbeabsichtigten Duplikaten.
- Neue Entitäten mit verständlicher Beschriftung, Zählquelle und korrektem, berechtigungsgeprüftem Drilldown in der Modulstatistik berücksichtigen. BC-Sitzungssprache und gewählte Datensprache trennen.
- Jedes Generator-Ticket enthält mindestens einen fachlichen Sandbox-Nachweis, einen Negativ-/Wiederanlauffall passend zum Umfang und einen Nachweis des Drilldowns. Regeln werden mit SF-042 in `AGENTS.md` und der Modul-/Testdokumentation verankert.

## Ticketübersicht

| Ticket | Phase | Prio | Titel | Status |
| --- | --- | --- | --- | --- |
| [SF-037](#sf-037) | Stabilisierung | P0 | Reparatur Vorlage → Start → Ergebnis | Zur Prüfung |
| [SF-038](#sf-038) | Stabilisierung | P0 | Realistische Kontenpläne und vollständige Buchungseinrichtung im Starterpfad | Zur Prüfung |
| [SF-039](#sf-039) | Stabilisierung | P0 | Realistische Geschäftspartner und nutzbare Partnerstammdaten | Zur Prüfung |
| [SF-040](#sf-040) | Stabilisierung | P0 | Vollständige Stammdatenbasis vor Belegen und Bewegungsdaten | Zur Prüfung |
| [SF-041](#sf-041) | Stabilisierung | P0 | Dashboard mit Datenbestand, Modulbereichen und prüfbaren Drilldowns | Zur Prüfung |
| [SF-042](#sf-042) | Stabilisierung | P0 | Partnerpfad stabilisieren, Bedienung polieren und Ausbau freigeben | Offen |
| [SF-044](#sf-044) | Bedienung | P1 | Dashboard kompakt gestalten und Kennzahlen direkt nutzbar machen | Zur Prüfung |
| [SF-043](#sf-043) | Stabilisierung | P0 | Mandant einmalig initialisieren und Vorlagenstart vereinfachen | Zur Prüfung |
| [SF-001](#sf-001) | 0 / Fundierung | P0 | Projektkonfiguration, Objekt-ID-Strategie und Ziel-Sandbox abstimmen | Blockiert |
| [SF-002](#sf-002) | 0 / Fundierung | P0 | AL-Struktur, Namenskonventionen und Objektplan finalisieren | Zur Prüfung |
| [SF-003](#sf-003) | 0 / Fundierung | P0 | Sicherheitsguard: Sandbox, Mandant, Berechtigung | Zur Prüfung |
| [SF-004](#sf-004) | 0 / Fundierung | P0 | Globale Factory-Einstellungen und Statusgrundlagen | Zur Prüfung |
| [SF-005](#sf-005) | 0 / Fundierung | P0 | Szenariovorlagen und versionierte Run-Snapshots | Zur Prüfung |
| [SF-006](#sf-006) | 0 / Fundierung | P0 | Entitätsmengen, Quoten und Prozessmodi konfigurieren | Zur Prüfung |
| [SF-007](#sf-007) | 0 / Fundierung | P0 | Generator-Vertrag und Registry definieren | Zur Prüfung |
| [SF-008](#sf-008) | 0 / Fundierung | P0 | Abhängigkeitsgraph und Ausführungsplan | Zur Prüfung |
| [SF-009](#sf-009) | 0 / Fundierung | P0 | BC-Setup-Prüfung und nicht-destruktiver Setup-Diff | Zur Prüfung |
| [SF-010](#sf-010) | 0 / Fundierung | P0 | Synthetischer Realismus und Seed-Engine | Zur Prüfung |
| [SF-011](#sf-011) | 0 / Fundierung | P0 | Erzeugte Datensätze und Belegketten nachverfolgen | Zur Prüfung |
| [SF-012](#sf-012) | 0 / Fundierung | P0 | Job-Queue Dispatcher, Run-/Batch-Tabellen | Zur Prüfung |
| [SF-013](#sf-013) | 0 / Fundierung | P0 | Batch-Checkpoint, Retry, Pause/Resume, Cancellation | Zur Prüfung |
| [SF-014](#sf-014) | 0 / Fundierung | P0 | Monitoring-Datenmodell und Dashboard | Zur Prüfung |
| [SF-015](#sf-015) | 0 / Fundierung | P0 | Wizard für Branche, Module, Umfang und Planung | Zur Prüfung |
| [SF-016](#sf-016) | 0 / Fundierung | P0 | Validierungsframework und Abschlussstatus | Zur Prüfung |
| [SF-017](#sf-017) | 1 / MVP | P1 | Finanzsetup und auswertbare Testkontenpläne für SKR03 und SKR04 | Zur Prüfung |
| [SF-018](#sf-018) | 1 / MVP | P1 | Debitoren und Kreditoren als kohärente Stammdaten | Zur Prüfung |
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

<a name="sf-001"></a>

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

<a name="sf-002"></a>

### SF-002 — AL-Struktur, Namenskonventionen und Objektplan finalisieren

**Status:** Zur Prüfung
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


**Struktur-Nachtrag, Nutzerauftrag vom 16.11.2026 — Zur Prüfung:** Bestehende AL-Dateien je Modul nach Objekttyp unter `src/<Modul>/<Objekttyp>/` einordnen. Betroffen: alle 104 vorhandenen AL-Dateien in elf Modulen, ein Dateiverweis im Dashboard-Prüfskript sowie Strukturkonvention, Objektplan, Modulnachweise und Einstieg-/Projektdokumentation. Vorhandene Nutzeränderungen und Dateiinhalt erhalten; keine Objekt-/ID-/Namespace-/Fachlogikänderung. 13 Module ohne AL-Code behalten ihre Modulmarker, Typordner entstehen bei Bedarf.

**Vorgehen / Testweg:** Vorherige Pfade und SHA-256-Prüfsummen erfassen; Ziele auf Kollision prüfen; Dateien verschieben; Dokumentations-/Skriptverweise nachführen; danach Vollständigkeit, Bytegleichheit, Objektzuordnung, Ressourcenpfade und unveränderte Manifest-/Übersetzungsdateien prüfen. Lokalen Cloud-Build mit CodeCop/UICop sowie bestehende Übersetzungs- und Dashboardprüfungen ausführen, sofern lokal verfügbar. Risiko: veraltete externe Dateiverweise und XERJ-Index. Keine neuen fachlichen Anforderungen; BC-Laufzeitabnahme bleibt separat offen. Tatsächliche Ergebnisse: [TESTS.md](docs/TESTS.md#sf-002--strukturumstellung-16112026).

**Prüfergebnis 16.11.2026:** 104 verschobene AL-Dateien per SHA-256 bytegleich; Manifest/Übersetzungen/Ressourcen und andere Ticketdetails erhalten. Cloud-Build mit CodeCop/UICop Exit 0 (sechs bekannte Informationshinweise, keine Fehler/Warnungen), Übersetzungsprüfung 978 Einheiten PASS, bestehender Dashboard-Browsertest PASS, Diffprüfung ohne Befund. Keine BC-Laufzeitabnahme oder Veröffentlichung. Struktur-Nachtrag **Zur Prüfung**.


---

<a name="sf-003"></a>

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

<a name="sf-004"></a>

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

<a name="sf-005"></a>

### SF-005 — Szenariovorlagen und versionierte Run-Snapshots

**Status:** Zur Prüfung\
**Priorität:** P0  
**Abhängigkeiten:** SF-004  
**Verantwortung / betroffene Module:** ScenarioManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Vorlagen mit Branche, Nutzungsziel, Seed, Zeitfenster und gespeicherter Revision; Lauf darf von späterer Vorlagenänderung nicht abhängen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Tabellen/Pages nach freigegebenem Schema; Snapshots bei Start atomar speichern; Änderungsschutz.

**Umsetzung 11.11.2026:** Vorlagen-GUID/Revision, fachliche Modulauswahl, Copy und unveränderliche Draft-Laufköpfe/Schema-1-Snapshots implementiert. Capture sperrt Vorlage/Setup, schreibt Kopf und vollständigen JSON-Payload ohne Commit atomar im normalen Aufrufpfad. Laufansicht rekonstruiert eingefrorene Ziele/Module und Sprache unabhängig von der Vorlage. Kein Queue-Start, keine Fachgeneratoren.

**Zusätzlich ausdrücklich beauftragte Sprache:** UI vollständig in englischer Quellsprache und deutschem XLIFF-Master mit fünf Regionalableitungen; Englischdatei ebenfalls vorhanden. Datensprache Automatisch/Deutsch/Englisch in Setup/Vorlage; jede deutsche ISO-Sprachvariante wird automatisch Deutsch, sonst Englisch. Auflösung/Katalogversion im Snapshot eingefroren, bilinguale synthetische Namensvorschau ohne Änderung der Worker-Sprache. Keine automatische Übersetzung vorhandener Benutzerdaten oder behauptete Implementierung zukünftiger Generatoren.

**Nachweise / Grenzen:** [SCENARIO_CONFIGURATION.md](docs/SCENARIO_CONFIGURATION.md), [TESTS.md](docs/TESTS.md) und aktualisierter Objektplan. 32 AL-Objekte gegen vorhandene BC-28.5-/Runtime-17-Symbole mit CodeCop/UICop und Warnungen als Fehlern gebaut; zwei AW0006-Informationen für absichtlich über Listen geöffnete Detailkarten. 285 UI-Einheiten in sechs Zielkulturen geprüft; sechs beschädigte Übersetzungsvarianten erkannt. Keine ausgeführten BC-Laufzeit-, Rechte-, Konkurrenz- oder UI-Sprachtests; konkrete Fälle bleiben offen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Gleiche Vorlage kopierbar, aktiver Run unveränderlich und vollständig rekonstruierbar.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [x] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-006"></a>

### SF-006 — Entitätsmengen, Quoten und Prozessmodi konfigurieren

**Status:** Zur Prüfung\
**Priorität:** P0  
**Abhängigkeiten:** SF-005  
**Verantwortung / betroffene Module:** ScenarioManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Ziele pro Debitor/Kreditor/Artikel/Belegtyp; Quoten, Presets und vier Prozessmodi; Abhängigkeitsmengen schätzen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Validation bei widersprüchlichen Mengen/Modi, kein irreführender Globalzähler.

**Umsetzung 11.11.2026:** Getrennte Mengen, Quoten und Modi für zehn Entitäten, Validierung, pro Entität anwendbare Presets und nachvollziehbare Dokument-Mengenprojektionen implementiert. Aktive Ziele erfordern passende aktivierte Module, Angebote bleiben ungebucht, Teilverarbeitung nur für Aufträge/Bestellungen. Mindest-Partnerreferenzen sind gekennzeichnete Planungsuntergrenzen, kein globaler Datensatz-/Ledgerzähler.

**Zusätzlich ausdrücklich beauftragte Sprache:** UI vollständig in englischer Quellsprache und deutschem XLIFF-Master mit fünf Regionalableitungen; Englischdatei ebenfalls vorhanden. Datensprache Automatisch/Deutsch/Englisch in Setup/Vorlage; jede deutsche ISO-Sprachvariante wird automatisch Deutsch, sonst Englisch. Auflösung/Katalogversion im Snapshot eingefroren, bilinguale synthetische Namensvorschau ohne Änderung der Worker-Sprache. Keine automatische Übersetzung vorhandener Benutzerdaten oder behauptete Implementierung zukünftiger Generatoren.

**Nachweise / Grenzen:** [SCENARIO_CONFIGURATION.md](docs/SCENARIO_CONFIGURATION.md), [TESTS.md](docs/TESTS.md) und aktualisierter Objektplan. 32 AL-Objekte gegen vorhandene BC-28.5-/Runtime-17-Symbole mit CodeCop/UICop und Warnungen als Fehlern gebaut; zwei AW0006-Informationen für absichtlich über Listen geöffnete Detailkarten. 285 UI-Einheiten in sechs Zielkulturen geprüft; sechs beschädigte Übersetzungsvarianten erkannt. Keine ausgeführten BC-Laufzeit-, Rechte-, Konkurrenz- oder UI-Sprachtests; konkrete Fälle bleiben offen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Anwender definiert getrennte Ziele und sieht plausibel nötige Folgedaten.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-007"></a>

### SF-007 — Generator-Vertrag und Registry definieren

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-002,SF-004  
**Verantwortung / betroffene Module:** ModuleRegistry, Core  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Capabilities, unterstützte Modi/Entitäten, Parameter, Preflight, Batch und Validierung über AL-kompatibles Interface/Registrierung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Technische Alternativen und spätere Drittanbieter-Erweiterung prüfen, deterministische Registry.

**Umsetzung 11.11.2026:** Internes Interface mit sieben Methoden, deterministischer Enum-Registry, geprüften Capabilities und zwei getrennten lesenden Vertragsproben implementiert. Probe-Ausführung ist sandboxgeschützt; echte Pläne schließen Proben aus. Versionierter JSON-/Sprachvertrag und begrenzte Batchplanung; kein öffentlicher SDK oder echter Fachgenerator.

**Nachweise / Grenzen:** [GENERATOR_PLANNING.md](docs/GENERATOR_PLANNING.md), Objektplan, Moduldateien und [TESTS.md](docs/TESTS.md). 56 Dateien mit CodeCop/UICop lokal gebaut; 443 XLIFF-Einheiten vollständig geprüft. AL-Selbstprüfungen kompiliert, nicht in BC ausgeführt. Sandbox-/Rechte-/UI-/Parallelitätsprüfung und menschliche Abnahme offen. Manifest/Launch unverändert.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Zwei Testgeneratoren lassen sich ohne Änderung der zentralen Steuerung unterscheiden und ansprechen.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-008"></a>

### SF-008 — Abhängigkeitsgraph und Ausführungsplan

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-006,SF-007  
**Verantwortung / betroffene Module:** DependencyManager  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Gerichtete fachliche Abhängigkeiten, Zyklenerkennung, Pflicht-/Optionalpfade, module-/modusabhängige Reihenfolge.

**Soll-Verhalten / technischer Arbeitsauftrag:** Topologische Planung, verständliche Konfliktmeldungen, Startverbot bei Blockern.

**Umsetzung 11.11.2026:** Snapshot-basierter Graph mit Pflicht-/Optional-/Extern-Regeln, deterministischer topologischer Sortierung, Zyklus-/Fehlermeldungen und versionierten unveränderlichen Run Steps implementiert. Laufkarte um Vorschau/Speichern/Startprüfung erweitert. Fehlende echte Generatoren und ungeprüfte externe Voraussetzungen blockieren; keine Queue oder Ready-Transition.

**Nachweise / Grenzen:** [GENERATOR_PLANNING.md](docs/GENERATOR_PLANNING.md), Objektplan, Moduldateien und [TESTS.md](docs/TESTS.md). 56 Dateien mit CodeCop/UICop lokal gebaut; 443 XLIFF-Einheiten vollständig geprüft. AL-Selbstprüfungen kompiliert, nicht in BC ausgeführt. Sandbox-/Rechte-/UI-/Parallelitätsprüfung und menschliche Abnahme offen. Manifest/Launch unverändert.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Finance→Stamm→Einkauf→Bestand→Verkauf in korrekter Reihenfolge; absichtlich zyklische Regel wird erkannt.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-009"></a>

### SF-009 — BC-Setup-Prüfung und nicht-destruktiver Setup-Diff

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-003,SF-008  
**Verantwortung / betroffene Module:** SetupManager, Finance  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Vorhandene Buchungsgruppen, No. Series, MwSt., Dimensionen, Zahlungsbedingungen, Lager-Setup und Rechte lesen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Preflight als Read-only, Maßnahmenplan und Freigabe; vollen Leerfirmen-Setup gesondert entscheiden.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Bestehende Einrichtung unverändert; fehlende Pflichtwerte präzise sichtbar und blockierend.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Umsetzung 15.11.2026:** `src/SetupManager/BCSFSetupDiff.Table.al`, `BCSFSetupManager.Codeunit.al`, `BCSFSetupDiffPreview.Page.al`, `BCSFRunPreflight.PageExt.al` und `src/Finance/BCSFFinanceSetupCheck.Codeunit.al`. Lesende Prüfung aktueller Einrichtung und grundlegender effektiver Rechte zu eingefrorenen Zielen; temporäre Befunde mit manuellen Maßnahmen. Keine Apply-/Einrichtungsänderung. Kandidatencheck für ungesperrte Forderungs-/Verbindlichkeits-Buchungskonten. Konkrete Generator-/Steuer-/Dimensions-/Postingbindungen bleiben blockierend; Start-Gate zusätzlich angebunden. Maßnahmen vor manueller Änderung ausdrücklich freigeben, dann neu prüfen.

**Tests / Grenzen:** Vollständiger lokaler Cloud-Build mit CodeCop/UICop gegen vorhandene BC-28.5-/DE-Symbole und Runtime 17 bestanden; Übersetzungsprüfung 481 Einheiten, Inventar-/ID-/Schreibpfadprüfung und Diffkontrolle ausgeführt. Keine AL-Funktions-/Sandbox-/Rechte-/Lasttests; deren Schritt bleibt offen. Keine neuen Testobjekte, kein Deployment. Engine-/Regel-/Schema- und Rechtekompatibilität sowie unbekannte Fachanforderungen: [SETUP_SEED.md](docs/SETUP_SEED.md). Tatsächliche Nachweise und ausstehende Fälle: [TESTS.md](docs/TESTS.md#sf-009sf-010--lokaler-prüfnachweis-15112026). Menschliche Abnahme steht aus.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-010"></a>

### SF-010 — Synthetischer Realismus und Seed-Engine

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-004,SF-006  
**Verantwortung / betroffene Module:** DataGeneration, IndustryProfiles  
**Verantwortliche Person:** Zu prüfen

**Korrektur / neuer Prüfumfang:** [SF-039](#sf-039) konkretisiert naturnahe Stammdaten und prüft alle sichtbaren Platzhalter. Der Realismusvertrag gilt auch für Artikel, Regionen und nachgelagerte Generatoren.

**Ausgangslage / Problem:** Deterministische synthetische Firmen-/Personen-/Artikel-/Preiswerte mit realistischen Streuungen, Datums-/Klassenregeln.

**Soll-Verhalten / technischer Arbeitsauftrag:** Pseudodaten ohne echte Empfänger/Konten; logische Schlüssel unabhängig von Reihenfolge; Profileinstellungen versionieren.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Gleiche Konfiguration erzeugt gleiche Eingangsdaten, verschiedene Seeds plausible Varianten ohne reale PII.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Umsetzung 15.11.2026:** `src/DataGeneration/BCSFSeedEngine.Codeunit.al`, `BCSFRunSyntheticPreview.PageExt.al`, `src/IndustryProfiles/BCSFSyntheticRules.Codeunit.al` und Erweiterung des bestehenden Snapshot Writers. Zustandslose, versionierte Werteableitung mit Seed, Profil, logischem Schlüssel und getrennten Feldstreams; Firmen-/Personen-/Artikelkataloge in DE/EN, Preis-/Datums-/Klassenregeln. Neue Snapshots frieren sämtliche generischen Regelwerte ein; keine Standarddatenanlage oder nachträgliche Änderung alter Snapshots. Vollständige Branchenprofile bleiben SF-023.

**Tests / Grenzen:** Vollständiger lokaler Cloud-Build mit CodeCop/UICop gegen vorhandene BC-28.5-/DE-Symbole und Runtime 17 bestanden; Übersetzungsprüfung 481 Einheiten, Inventar-/ID-/Schreibpfadprüfung und Diffkontrolle ausgeführt. Keine AL-Funktions-/Sandbox-/Rechte-/Lasttests; deren Schritt bleibt offen. Keine neuen Testobjekte, kein Deployment. Engine-/Regel-/Schema- und Rechtekompatibilität sowie unbekannte Fachanforderungen: [SETUP_SEED.md](docs/SETUP_SEED.md). Tatsächliche Nachweise und ausstehende Fälle: [TESTS.md](docs/TESTS.md#sf-009sf-010--lokaler-prüfnachweis-15112026). Menschliche Abnahme steht aus.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-011"></a>

### SF-011 — Erzeugte Datensätze und Belegketten nachverfolgen

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-005,SF-010  
**Verantwortung / betroffene Module:** Lifecycle, DataGeneration  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Run→Generator→LogicalKey→Record/Beleg/Posting dokumentieren, Wiederanlauf und Validierung ermöglichen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Registry mit eindeutigen Schlüsseln und datensparsamem Audit; Standard-Posting-Ergebnisbezug prüfen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Jede erzeugte Einheit eindeutig einem Run zuordenbar; erneute Erstellung wird erkannt.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Umsetzung 15.11.2026:** `src/DataGeneration/BCSFGeneratedRecord.Table.al`, `BCSFRecordRegistry.Codeunit.al`, `BCSFGeneratedRecords.Page.al`, `BCSFRunProvenance.PageExt.al` und `src/Lifecycle/BCSFProvenanceGuard.Codeunit.al`. Unveränderliche logische und physische Herkunft, Batch-/Generatorversion, SystemId plus ursprünglicher RecordId und vorhandene Eltern desselben Runs. Identische Registrierung idempotent, widersprüchliche/mehrfache physische Zuordnung blockiert. Kein Standarddatensatzinsert. Referenzmodell für konkrete Posting-Ergebnisse vorhanden; tatsächliche Postingbeziehungen und Freigaben müssen spätere Fachgeneratoren nachweisen.

**Tests / Grenzen:** Vollständiger Cloud-Build aller 81 AL-Dateien gegen lokale BC-28.5-/DE-/Runtime-17-Symbole mit CodeCop/UICop bestanden; 606 Übersetzungseinheiten, Objekt-/ID-/Symbol-/Schreibpfad-/Scopeprüfungen und Diffkontrolle ausgeführt. Keine AL-Funktions-/Queue-/Sandbox-/Rechte-/Parallelitäts-/Postingtests; keine neuen Testobjekte und kein Deployment. Grenzen und technische Entscheidungen: [EXECUTION_REGISTRY.md](docs/EXECUTION_REGISTRY.md). Tatsächliche Ergebnisse und offene Laufzeitfälle: [TESTS.md](docs/TESTS.md#sf-011sf-012--lokaler-prüfnachweis-15112026). Menschliche Abnahme steht aus.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-012"></a>

### SF-012 — Job-Queue Dispatcher, Run-/Batch-Tabellen

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-003,SF-005,SF-008,SF-011  
**Verantwortung / betroffene Module:** BackgroundProcessing  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Persistente Steps/Batches, Statusmaschine und Queue-Steuerung für nichtinteraktive Ausführung.

**Soll-Verhalten / technischer Arbeitsauftrag:** Rechte, Scheduling und Abhängigkeiten berücksichtigen; keine unbegrenzten parallelen Worker.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Start, Laufstatus und Einzelbatches sichtbar; Browser kann geschlossen werden.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Umsetzung 15.11.2026:** Zwölf Objekte in `src/BackgroundProcessing/`: Batch/Status, separate Run Execution, Dispatcher/Worker/Runner, verpflichtende Validierungen/Fehlerklassifizierung und persistente UI mit frühestem Start/Bestätigung. Plan Writer um wiederverwendbare CheckExecution-Prüfung ergänzt; Header/Snapshot bleiben immutable. Je Job ein Batch, Standard-Kategorie BCSF.SER serialisiert regulär pro Firma, kein automatisches Retry. Dauerhafter Claim vor atomarem Ergebnis-/Herkunfts-/Abschluss-/Nachfolgerteil. Aktuelle echte Generator-/Setupblocker bleiben erhalten. Recovery, Pause/Resume/Cancel und ID 90304 bleiben SF-013.

**Tests / Grenzen:** Vollständiger Cloud-Build aller 81 AL-Dateien gegen lokale BC-28.5-/DE-/Runtime-17-Symbole mit CodeCop/UICop bestanden; 606 Übersetzungseinheiten, Objekt-/ID-/Symbol-/Schreibpfad-/Scopeprüfungen und Diffkontrolle ausgeführt. Keine AL-Funktions-/Queue-/Sandbox-/Rechte-/Parallelitäts-/Postingtests; keine neuen Testobjekte und kein Deployment. Grenzen und technische Entscheidungen: [EXECUTION_REGISTRY.md](docs/EXECUTION_REGISTRY.md). Tatsächliche Ergebnisse und offene Laufzeitfälle: [TESTS.md](docs/TESTS.md#sf-011sf-012--lokaler-prüfnachweis-15112026). Menschliche Abnahme steht aus.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-013"></a>

### SF-013 — Batch-Checkpoint, Retry, Pause/Resume, Cancellation

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-012  
**Verantwortung / betroffene Module:** BackgroundProcessing  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Fehlerisolierung, Retry-Limits, nachweisbar sichere Checkpoints, doppelte Claims vermeiden; manueller NeedsReview-Modus.

**Soll-Verhalten / technischer Arbeitsauftrag:** Unterbrechungen während Datenerstellung/Posting simulieren, keinen blinden Wiederholungsversuch nach unklarem Commit.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Fehlgeschlagene Arbeit kann nach Sicherungsprüfung fortgesetzt werden ohne doppelte Datensätze/Postings.
- [ ] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [ ] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Umsetzung 16.11.2026:** Neue Objekte in `src/BackgroundProcessing/`: `BCSFBatchRecovery.Codeunit.al` (90304), `BCSFRunControl.Table.al` (90313), `BCSFBatchCheckpoint.Table.al` (90314), `BCSFRecoveryRules.Codeunit.al` (90315). Bestehende Batch-/Zustands-/Worker-/Runner-/Dispatcher-/UI-Verträge, Core-Statusgraph und deklarative Rechte angepasst. Technische immutable Checkpoints, getrennte dauerhafte Stopanforderung, sichere Paketgrenzen, drei Einplanungen insgesamt, Retry nur für nie übernommene Fehler ohne Ergebnisse. Reconciliation führt keine Erzeugung/Buchung aus; ohne passenden Checkpoint oder nachweislich beendete eindeutige Worker-Sitzung bleibt NeedsReview bestehen. Cancel ist nicht resumierbar; bestätigte Ergebnisse bleiben erhalten.

**Tests / Grenzen:** Vollständiger Cloud-Build aller 85 AL-Dateien mit CodeCop/UICop gegen lokale BC-28.5-/DE-/Runtime-17-Symbole bestanden, 665 Übersetzungseinheiten vollständig, Inventar-/Symbol-/Scope-/Guard-/Paketprüfungen ausgeführt. XERJ bcsf-docs für Ticket-/Vertragssuche genutzt, AL-Definition dort nicht verfügbar und lokal geprüft. Keine echte Unterbrechungs-/Posting-/Queue-/Parallelitätssimulation, keine neuen Testobjekte, kein Deployment; entsprechende Schritte/Abnahme bleiben offen. Bestehende fremde TODO-Whitespace-Zeilen nicht geändert. [RECOVERY.md](docs/RECOVERY.md), [Testnachweise und offene Fault-Matrix](docs/TESTS.md#sf-013--lokaler-prüfnachweis-16112026).

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-014"></a>

### SF-014 — Monitoring-Datenmodell und Dashboard

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-012,SF-013  
**Verantwortung / betroffene Module:** Monitoring, UI  
**Verantwortliche Person:** Zu prüfen

**Korrektur / neuer Funktionsumfang:** [SF-041](#sf-041) ergänzt fachliche Modulstatistiken und Standardlisten-Drilldowns. [SF-042](#sf-042) vereinfacht den Hauptpfad und prüft Sprache und Navigation in BC.

**Ausgangslage / Problem:** Kacheln, Modul-/Entitäts-Soll/Ist, Queue-Status, Zeiten, Drilldowns, Fehlermeldungen und Validierung.

**Soll-Verhalten / technischer Arbeitsauftrag (Nutzerpräzisierung):** JavaScript-ControlAddIn als zentrales Dashboard mit Szenarioanlage, vollständiger relevanter Appnavigation und direkten Runaktionen. Eigenes Role-Center/Profil sowie wiederverwendbare CardPart für zusätzliche erweiterbare Role-Center per PageExtension. Anzeigen lesen persistierte Zustände; vorhandene Guards/Freigaben bleiben maßgeblich.

**Umsetzungsnachweis 16.11.2026:** Native Dashboardliste/FactBox, temporäre Schritt-Soll/Ist-Sicht, unveränderliche technische Statushistorie und gefilterte Standard-Queueprotokolle. Bestätigte Einheiten/Artefakte/ausstehende Gesamtqualität getrennt; kein Start beim Lesen. [Vertrag/Dateien](docs/MONITORING_WIZARD.md), [Objektplan](docs/OBJECT_PLAN.md), [echte lokale Prüfungen und offene BC-Fälle](docs/TESTS.md#sf-014sf-015--lokaler-prüfnachweis-16112026). Vollständiger Cloud-Build mit CodeCop/UICop erfolgreich (97 Objekte, BC-28.5-/DE-Symbole, Runtime 17); 865 Texte DE/EN geprüft. Keine BC-Laufzeit-/UI-/Rechteabnahme und kein Deployment. Nutzerabnahme weiterhin offen.

**Präzisierungsnachweis:** Sieben zusätzliche AL-Objekte mit gebündeltem JS/CSS, eigenes Profil und zentrale Navigation umgesetzt. Nativer Monitor erhalten. Lokaler Chromiumcheck mit synthetischer BC-Brücke erfolgreich; keine echte BC-Iframe-/Role-Center-/Dialog-/Profilprüfung. [Aktueller Vertrag und Einbau](docs/DASHBOARD_EMBEDDING.md), [Prüfnachweise](docs/TESTS.md).

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] JS-Arbeitsplatz, Szenarioanlage und relevante Appseiten/-aktionen ohne wiederholte Suche in BC nutzbar; eigenes Profil/Role-Center praktisch geprüft.
- [ ] Dieselbe CardPart in einem weiteren freigegebenen erweiterbaren Role-Center praktisch geprüft; Einbauweg dokumentiert.
- [ ] Anwender erkennt Lauf, Step, Batch, Fortschritt, Fehler und noch offene Daten ohne erneuten Start.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

**Korrekturauftrag 17.11.2026 — Ziel und Testweg:** Abgeschnittenes ControlAddIn durch einen auf die Iframehöhe begrenzten, per Tastatur erreichbaren Scrollbereich beheben. Deutsche Sitzung soll Dashboardtexte einschließlich technischem Schrittstatus aus dem bestehenden XLIFF-Master erhalten, auch wenn der AL-Payload noch englische Quellen liefert. Betroffen: Dashboard CSS/JS, generierte eigene Übersetzungsressource samt lokalem Generator, ControlAddIn-Ressourcenliste, bestehender Browsertest und Vertrags-/Prüfdokumentation. Keine Änderung von Datensprache, Laufdaten, Objektidentitäten oder Berechtigungen. Testweg: 500px Höhe mit äußerem Overflow hidden, Erreichbarkeit letzter Aktionen/Footer, Scrollposition nach Refresh, alle deutschen Regionen und englische UI mit deutscher Zahlenregion, vollständiger AL-Build mit CodeCop/UICop, Ressourcen-/XLIFF-Prüfung. Ursache der auf dem Screenshot sichtbaren englischen Laufzeitlabels bleibt ohne BC-Sitzungszugriff **Zu prüfen**; keine Installation/Veröffentlichung im Umfang.

**Prüfergebnis 17.11.2026:** Scrollen/Tastatur/Footer/Refresh bei 500px und echter lokaler Iframe sowie deutsche Fallbacklabels für fünf Regionen im bestehenden Browsertest PASS; XLIFF-Prüfung 977 Einheiten PASS; reine AL-Kompilierung 116 Dateien Exit 0 und vier Ressourcen im Paket geprüft. Strenger CodeCop/UICop-Gesamtbuild scheitert an 23 unveränderten Ausgangsbefunden außerhalb des geänderten ControlAddIn. Keine BC-Installation/Veröffentlichung oder echte Sitzungsabnahme. [Nachweise und Grenzen](docs/TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). Status **Zur Prüfung**.

---

<a name="sf-015"></a>

### SF-015 — Wizard für Branche, Module, Umfang und Planung

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-006,SF-008,SF-009,SF-014  
**Verantwortung / betroffene Module:** ScenarioManagement, IndustryProfiles, UI  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Fünf Schritte: Branche/Nutzungsziel, Module, Entity-Ziele, Prozessmodus, Preflight/Freigabe/Startzeit.

**Soll-Verhalten / technischer Arbeitsauftrag:** Abhängigkeiten und Buchungsrisiken eindeutig anzeigen; Tooltips/Barrierefreiheit.

**Umsetzungsnachweis 16.11.2026:** Native fünfstufige geführte Vorlagenplanung mit explizitem Snapshot, Plan-/Setupprüfung, Startzeit und ausdrücklicher Freigabe über vorhandene Queue-Gates. Keine Branchenpresets oder Postingfreigabe erfunden; aktuelle Startblocker bleiben bestehen. [Vertrag/Dateien](docs/MONITORING_WIZARD.md), [Objektplan](docs/OBJECT_PLAN.md), [echte lokale Prüfungen und offene BC-Fälle](docs/TESTS.md#sf-014sf-015--lokaler-prüfnachweis-16112026). Vollständiger Cloud-Build mit CodeCop/UICop erfolgreich (97 Objekte, BC-28.5-/DE-Symbole, Runtime 17); 865 Texte DE/EN geprüft. Keine BC-Laufzeit-/UI-/Rechteabnahme und kein Deployment. Nutzerabnahme weiterhin offen.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [ ] Ein vollständiges Szenario durch Wizard planbar; keine Job-Ausführung vor gültiger Freigabe.
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-016"></a>

### SF-016 — Validierungsframework und Abschlussstatus

**Status:** Zur Prüfung
**Priorität:** P0  
**Abhängigkeiten:** SF-007,SF-011,SF-012  
**Verantwortung / betroffene Module:** Validation  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Regeln je Generator, Mengen-/Beziehungs-/Posting-Validierung, Severity, Ergebnisse, Abweichungen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Pflichtprüfungen von optionalen unterscheiden; Completed nur bei validierter Arbeit.

**Checklistenstand:** `[x]` kennzeichnet umgesetzte bzw. lokal nachgewiesene Arbeit. Offene BC-Laufzeittests und menschliche Abnahme bleiben `[ ]`; Status weiterhin `Zur Prüfung`.

**Vorgehen (einzeln abzuarbeiten):**
- [x] Relevante Originaldateien, Modulregeln, Standard-BC-APIs, vorhandene Tests und `app.json` prüfen; offenen Sachverhalt vor Coding abstimmen.
- [x] Fachliche Vor-/Nachbedingungen, Prozessmodus, Berechtigungen und Fehlerpfade schriftlich beschreiben.
- [x] Betroffene AL-Objekte, Schnittstellen, ID-Belegung, Datenfluss und Transaktions-/Batch-Grenzen planen.
- [x] Nur diesen freigegebenen Ticketumfang implementieren; vorhandene Einstellungen, Modulgrenzen und Standardbuchungsprozesse respektieren.
- [ ] Positive, negative, Teilfehler-, Wiederholungs- und Berechtigungsfälle passend zum Ticket prüfen; tatsächliche Ergebnisse protokollieren.
- [x] Modul-Dokumentation, Architektur-/Testnachweise und Ticketstatus aktualisieren, ohne ungefragt Folge-Tickets zu öffnen.

**Akzeptanzkriterien:**
- [x] Fehlende Posten und Mismatches verhindern falsche Erfolgsmeldung. **Implementiert; BC-Laufzeitnachweis noch offen.**
- [x] Keine ungeplanten Änderungen an anderer Logik, keine echten Daten, keine neuen Abhängigkeiten auf XERJ.
- [x] Tatsächlich ausgeführte Tests samt BC-Version/Umgebung/Nachweisen dokumentiert; Unausgeführtes ausdrücklich als offen.
- [ ] Menschliche Prüfung erfolgt; erst dann Status `Erledigt`.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Änderung oder Veröffentlichung in Produktivmandanten; kein blindes Direktinsert in gebuchte Standardposten; keine erfundene Standard-API; keine automatische Umsetzung abhängiger Tickets.

**Risiken / Entscheidungen:** Zielversions- und Lokalisierungsabhängigkeit, Rechte, Datenvolumen und eventuell unklarer Commit-/Retry-Zustand nachprüfen. Bei Blocker konkrete Frage stellen und `Blockiert` statt mutmaßlich erfolgreich setzen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.


**Umsetzung 18.11.2026:** Vorhandene Ansätze vervollständigt und abgesichert; [Umsetzung und konkrete BC-Abnahmefälle](docs/VALIDATION_FINANCE.md), [tatsächliche lokale Prüfungen](docs/TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). Sandbox-/Buchungs-/Berechtigungsnachweise und menschliche Abnahme stehen aus. Keine Folgetickets umgesetzt.

---

<a name="sf-017"></a>

### SF-017 — Finanzsetup und auswertbare Testkontenpläne für SKR03 und SKR04

**Status:** Zur Prüfung
**Priorität:** P1  
**Phase:** 1 / MVP  
**Abhängigkeiten:** SF-009, SF-010  
**Betroffene Module:** Finance, SetupManager, ScenarioManagement

**Korrektur / neuer Prüfumfang:** [SF-038](#sf-038) prüft die Anwendung der vorhandenen Pakete im Starter-/Schnellstartpfad und ersetzt dort etwaige Zwei-Konten-Fallbacks. Keine zusätzlichen Finanzpakete neben dem gemeinsamen Paketvertrag.

**Ziel**  
Die BC Scenario Factory soll eine über den BC-Standard angelegte Sandbox-Testfirma mit einem schlanken **SKR03- oder SKR04-basierten Kontenplan** und der dazu passenden Buchungseinrichtung ausstatten. Der Kontenplan soll nicht nur Einkauf und Verkauf ermöglichen, sondern auch für Sachkontenbuchungen, Funktionstests, Schulungen und Finanzberichte in BC nutzbar sein. Der Nutzer soll dafür weder Sachkonten noch Buchungsgruppen einzeln anlegen müssen.

**Checklistenstand:** Umfangspunkte sind im Code umgesetzt; ihre Kennzeichnung ist keine Bestätigung ausgeführter BC-Tests. Sandbox-Anwendung, Wiederholung, Buchungen und Berichtssummen müssen noch nachgewiesen werden. Status weiterhin `Zur Prüfung`.

**Umfang**

- [x] Drei Optionen anbieten: **vorhandene BC-Einrichtung verwenden**, **SKR03-Testkontenplan einrichten** oder **SKR04-Testkontenplan einrichten**. Im ersten Modus wird die vorhandene Einrichtung nur geprüft und verwendet.
- [x] Je Kontenrahmen ein eigenes, versioniertes Einrichtungspaket bereitstellen. Bezugsjahr, Paketversion, fachliche Quelle und unterstützten Umfang dokumentieren. Die Pakete als schlanke **Testkontenpläne** kennzeichnen, nicht als vollständige DATEV-Kontenrahmen. Führende Nullen in Kontonummern erhalten.
- [x] Die Kontenpläne fachlich gliedern. Für den MVP mindestens Bank, Forderungen, Verbindlichkeiten, Bestand, Vorsteuer, Umsatzsteuer, Eigenkapital, Erlöse, Wareneinsatz und ausgewählte Betriebskosten abdecken. Auch Konten für manuelle Buchblatttests vorsehen, die nicht über Einkaufs- oder Verkaufsbelege bebucht werden.
- [x] Sachkonten den passenden Bilanz- und GuV-Kategorien zuordnen. Je Paket eine Bilanz- und eine GuV-Auswertung mit den Standard-Finanzberichten in BC bereitstellen. Die Berichte sollen dieselbe fachliche Auswertung ermöglichen, auch wenn sich die Kontonummern je Rahmen unterscheiden.
- [x] Die für das erste Branchenprofil nötigen Debitoren-, Kreditoren-, Lager-, allgemeinen und MwSt.-Buchungsgruppen samt benötigter Buchungsmatrizen und Lagerbuchungseinrichtung passend zum Kontenplan einrichten. Vorhandene Nummernserien, Zahlungsbedingungen und sonstige BC-Grundeinrichtung verwenden, sofern sie passen. Fehlende Voraussetzungen konkret melden.
- [x] Kontenrollen sind im jeweiligen Finanzpaket konkreten Sachkonten zugeordnet; `GetTestPostingGroup` stellt den passenden Buchungsgruppencode bereit. Debitoren, Kreditoren, Artikel und Belege bleiben BC-Standarddatensätze.
- [ ] Die späteren Fachgeneratoren verwenden diese Buchungsgruppen ohne fest codierte SKR-Kontonummern. **Integration erst mit SF-018 bis SF-022; diese Tickets bleiben außerhalb des aktuellen Auftrags.**
- [x] Vor dem Anwenden in einer Vorschau zeigen, was angelegt oder wiederverwendet wird und welche Konflikte die Einrichtung blockieren. **SF-009 bleibt rein lesend.** Das Anwenden ist eine separate, ausdrückliche Aktion in der freigegebenen Sandbox-Testfirma. Bestehende Konten und Buchungszuordnungen nicht still überschreiben.
- [x] Auswahl, Bezugsjahr und Version des angewendeten Finanzpakets im Lauf-Snapshot festhalten. Beim erneuten Anwenden desselben Pakets dürfen keine doppelten Konten, Buchungsgruppen oder Berichtsdefinitionen entstehen.

**Akzeptanzkriterien**

- [ ] SKR03 und SKR04 lassen sich jeweils in einer separaten, frisch angelegten Sandbox-Testfirma anwenden. Der zweite Aufruf desselben Pakets erzeugt keine Duplikate. Der Modus „Vorhandene BC-Einrichtung verwenden“ ändert keine vorhandenen Einträge.
- [ ] Je Kontenrahmen sind ein Einkaufsfall, ein Verkaufsfall und eine davon unabhängige Sachkontenbuchung über ein BC-Standardbuchblatt nachgewiesen, etwa eine Betriebsausgabe. Die resultierenden Sachposten landen auf den für das jeweilige Paket erwarteten Konten.
- [ ] Die gebuchten Beispielwerte erscheinen in Bilanz und GuV in den erwarteten Gruppen. Erwartete Konten, Beträge und Summen sind dokumentiert und mit den Sachposten abgeglichen. Ein Bericht ohne gebuchte Werte gilt nicht als Nachweis.
- [x] Inkompatible Konten oder Buchungszuordnungen werden vor dem Anwenden angezeigt. Ein blockierender Konflikt führt nicht zu einem teilweise angewendeten Paket. **Konfliktprüfung und commitfreier Apply implementiert; BC-Konflikt-/Rollbacktest noch offen.**
- [x] Der dokumentierte Abnahmeplan verwendet manuelle BC-Standardbelege und Standardbuchblätter. **SF-018 bis SF-022 wurden nicht vorgezogen.** Die Wiederverwendung durch spätere Generatoren ist als Schnittstellenvertrag beschrieben; deren Integration bleibt offen.
- [ ] Tatsächlich ausgeführte BC-Tests je Paket dokumentieren. Nicht ausgeführte Prüfungen offen ausweisen. Status erst nach menschlicher Abnahme auf `Erledigt` setzen.

**Nicht-Ziele**  
Keine automatische Firmenanlage, kein vollständiger DATEV-Kontenrahmen oder DATEV-Export, keine Umstellung einer bereits bebuchten Firma auf einen anderen Kontenrahmen und keine direkten Inserts in gebuchte BC-Posten. Keine Umsetzung von Folgetickets im Rahmen von SF-017.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.


**Umsetzung 18.11.2026:** Vorhandene Ansätze vervollständigt und abgesichert; [Umsetzung und konkrete BC-Abnahmefälle](docs/VALIDATION_FINANCE.md), [tatsächliche lokale Prüfungen](docs/TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). Sandbox-/Buchungs-/Berechtigungsnachweise und menschliche Abnahme stehen aus. Keine Folgetickets umgesetzt.

---

<a name="sf-018"></a>

### SF-018 — Debitoren und Kreditoren als kohärente Stammdaten

**Status:** Zur Prüfung  
**Priorität:** P1  
**Abhängigkeiten:** SF-010,SF-011,SF-017  
**Verantwortung / betroffene Module:** Sales, Purchasing  
**Verantwortliche Person:** Zu prüfen

**Nutzerstand / Korrektur:** Partnergeneratoren wurden laut Nutzer umgesetzt und haben Geschäftspartner angelegt. Der Backlog hält deshalb „Zur Prüfung“ fest. Die sichtbaren Platzhalter und noch nicht nachgewiesenen Partnerbeziehungen werden in [SF-039](#sf-039) korrigiert und nachgetestet. Keine Abnahme abgeleitet.

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

<a name="sf-019"></a>

### SF-019 — Artikel, Kategorien, Varianten und Lagerbasics

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-009,SF-010,SF-017, SF-042  
**Verantwortung / betroffene Module:** Inventory  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Artikel, Kategorien, Einheiten, Varianten, Preise, Lagerorte und Buchungszuordnungen nach SF-040 planen. Namen und Varianten fachlich plausibel erzeugen. Neue Entitäten in die Statistiken mit passendem Standardlisten-Drilldown aufnehmen.

**Ausgangslage / Problem:** Lager-/Nichtlager-/Serviceartikel, Preise, Einheiten, Kategorien, Lagerorte und Bestandsvoraussetzungen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Artikelposten nur über Standardprozesse, keine direkten Ledger-Inserts.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-020"></a>

### SF-020 — Einkaufsprozess: Bestellung bis gebuchte Rechnung

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-018,SF-019,SF-013  
**Verantwortung / betroffene Module:** Purchasing, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Vor dem ersten Bestell-/Buchungsschritt Lieferant, Bestelladresse, Zahlungsbedingungen, Artikel und Buchungskombination prüfen. Belegköpfe und resultierende Posten als getrennte Kennzahlen registrieren.

**Ausgangslage / Problem:** Ungebuchte Bestellungen, vollständige/teilweise Eingänge, gebuchte Eingangsrechnungen, ausgewählte Gutschriften.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Posting und resultierende Ledger/Inventory prüfen; Unsicherheiten bei Retry behandeln.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-021"></a>

### SF-021 — Verkaufsprozess: Angebot bis gebuchte Rechnung

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-018,SF-019,SF-020  
**Verantwortung / betroffene Module:** Sales, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Vor dem ersten Beleg-/Buchungsschritt Debitor, Lieferadresse, Zahlungsbedingungen, Artikel und Buchungskombination prüfen. Ungebuchte und gebuchte Belegarten und zugehörige Posten getrennt registrieren.

**Ausgangslage / Problem:** Angebote, Aufträge, Lieferungen, Teilmengen, Faktura, offene Debitorenposten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Sales-Posting, Bestand-/Preis-/Dimensionenprüfung; Standardprozess nicht umgehen.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-022"></a>

### SF-022 — Zahlungen, Ausgleich, Gutschriften und Folgeprozesse

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-020,SF-021  
**Verantwortung / betroffene Module:** Finance, Sales, Purchasing, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Zahlung, Ausgleich und Gutschrift nur mit passenden Stammdaten und Konto-/Zahlungszuordnungen ausführen. Keine externe Übermittlung und synthetische Bankverbindungen nicht als produktiv nutzbar behandeln. Postenzähler und Drilldowns nachführen.

**Ausgangslage / Problem:** Offene, teilweise und vollständig ausgeglichene Posten; unterschiedliche Zahlungszeitpunkte, Gutschriften/Retouren im freigegebenen Umfang.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Buchungs-/Ausgleichsprozesse und Referenzen, keine willkürlichen Ledger-Manipulationen.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-023"></a>

### SF-023 — Großhandel als erstes Branchenprofil

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-007,SF-010,SF-017,SF-021  
**Verantwortung / betroffene Module:** IndustryProfiles, Finance, Sales, Purchasing, Inventory  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Pro Branchenprofil unterstützte Prozesse, Datenrealismus, erwartete Finanzrollen und Referenzstämme anhand SF-038 bis SF-040 dokumentieren. Geplante Funktionen klar kennzeichnen.

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

<a name="sf-024"></a>

### SF-024 — End-to-End-MVP und fachliche Qualitätsgate

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-014,SF-015,SF-016,SF-022,SF-023, SF-042  
**Verantwortung / betroffene Module:** Validation, Monitoring, UI  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** P0-Stabilisierung als Vorgänger nutzen. Die MVP-Abnahme erweitert deren Belege, Posten, Berichte und Dashboard-Prüfungen um die tatsächlich umgesetzten Prozessgeneratoren.

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

<a name="sf-025"></a>

### SF-025 — AL-Test-App und fachliche Regressionssuite

**Status:** Offen  
**Priorität:** P1  
**Abhängigkeiten:** SF-001,SF-016,SF-024  
**Verantwortung / betroffene Module:** Tests, alle P1-Module  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Regressionssuite um Datenrealismus, Finance-Pakete, Stammdatenreihenfolge, Wiederanlauf und Abgleich Dashboard → Standardliste erweitern. P0-Smoke-Tests aus SF-042 nicht durch reine Mock-Tests ersetzen.

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

<a name="sf-026"></a>

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

<a name="sf-027"></a>

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

<a name="sf-028"></a>

### SF-028 — Warehouse-Prozessgenerator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Warehouse  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Lagerorte, Lagerplätze, Artikel und weitere pro Standort benötigte Referenzen vor Belegen/Bewegungen prüfen. Modulstatistik und Standardlisten-Drilldown aufnehmen.

**Ausgangslage / Problem:** Lagerplätze, Ein-/Auslagerung, Kommissionierung, Umlagerungen und Varianten von Lager-Konfiguration.

**Soll-Verhalten / technischer Arbeitsauftrag:** Abhängigkeiten zu Warehouse-Setup/Inventar prüfen; Nur-dort-wo-aktiv-Modus.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-029"></a>

### SF-029 — Manufacturing- und Assembly-Generator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Manufacturing, Assembly  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Stücklisten, Arbeitspläne, Kapazitäts-/Produktionsstammdaten und Artikel je Prozess vor Bewegungen prüfen. Fertigung/Montage im Dashboard separat ausweisbar machen.

**Ausgangslage / Problem:** Fertigungsstücklisten, Arbeitsplätze, Arbeitspläne, Produktionsauftrag/Verbrauch/Output sowie Montagestücklisten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Feature-/Lizenzprüfung und trennscharfe fachliche Workflows.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-030"></a>

### SF-030 — Projects- und ServiceManagement-Generator

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** Projects, ServiceManagement  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Projekt-, Ressourcen-, Service- und Partnerbeziehungen pro Prozess dokumentieren, vor Bewegungen prüfen und je Modul Drilldowns aufnehmen.

**Ausgangslage / Problem:** Projekte, Projektaufgaben, Ressourcen, Zeiterfassung und Abrechnung; Servicefälle, Wartung, Ersatzteile, Faktura.

**Soll-Verhalten / technischer Arbeitsauftrag:** Verfügbare Standardobjekte/Versionen und ggf. getrennte Sprints prüfen.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-031"></a>

### SF-031 — Anlagen und Abschreibungsfälle

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** FixedAssets, Finance  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Anlagenstämme, Buchungsgruppen und Abschreibungsbücher vor Buchung prüfen. Anlagen und Anlagenposten getrennt ausweisen.

**Ausgangslage / Problem:** Anlagenklassen, Anschaffung, Abschreibung, Abgang/Sonderfälle als synthetische Belegketten.

**Soll-Verhalten / technischer Arbeitsauftrag:** Standard-Buchungsmethoden, Rechte und Finanzabhängigkeiten prüfen.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-032"></a>

### SF-032 — Weitere Profile: E-Commerce, Fertigung, Dienstleistung, Bau, Logistik, Wartung

**Status:** Offen  
**Priorität:** P2  
**Abhängigkeiten:** SF-028,SF-029,SF-030  
**Verantwortung / betroffene Module:** IndustryProfiles  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Für jedes Branchenprofil die Modul-/Entitätsmatrix, plausible Datenkataloge, benutzbare Stammdaten und nachgewiesene Pfade aktuell halten.

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

<a name="sf-033"></a>

### SF-033 — CRM/Relationship- und Planning-Generatoren

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-024  
**Verantwortung / betroffene Module:** CRM, Planning  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Kontakte, Rollen, Beziehungen und erforderliche Planungsstämme vor Prozessen prüfen und in der Modulstatistik registrieren.

**Ausgangslage / Problem:** Kontakte/Kampagnen/Opportunities und Nachfrage-/Beschaffungsplanung mit plausiblen Daten.

**Soll-Verhalten / technischer Arbeitsauftrag:** BC-Modulverfügbarkeit nach Version prüfen; kein Dynamics CRM On-Prem vermischen.

**Master-Data-Gate:** Die [SF-040-Matrix](docs/MASTER_DATA_READINESS.md#modul--und-entitätsmatrix) für die eigenen Entitäten konkretisieren. Abhängige Stämme und Einrichtung vor der ersten Verwendung prüfen. Im Hintergrund vor Beleganlage/Buchung die tatsächlich verwendeten Kombinationen und effektiven Rechte prüfen.

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

<a name="sf-034"></a>

### SF-034 — Öffentliche Generator-Erweiterungs-API

**Status:** Offen  
**Priorität:** P3  
**Abhängigkeiten:** SF-007,SF-025, SF-042  
**Verantwortung / betroffene Module:** ModuleRegistry, Core  
**Verantwortliche Person:** Zu prüfen

**Verbindliche Ergänzung gemäß [SF-042](#sf-042):** Erweiterungen an die gemeinsamen Verträge für Datenqualität, Abhängigkeiten, Herkunft, Sprachtrennung und Statistiken anbinden.

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

<a name="sf-035"></a>

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

<a name="sf-036"></a>

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

<a name="sf-037"></a>

### SF-037 — Reparatur Vorlage → Start → Ergebnis (Nutzerauftrag 18.11.2026)

**Status:** Zur Prüfung  
**Priorität:** P0  

**Nutzerstand:** Vorlage und Lauf funktionieren nach Nutzerbericht wieder. Die Abnahme und die Stabilisierungskorrekturen [SF-038](#sf-038) bis [SF-042](#sf-042) bleiben davon getrennt.

**Ausgangslage:** Playground-Partnerlauf 5/5 mit zwei Paketen fehlgeschlagen; frühester vollständiger Queuefehler fehlt. Aktueller Workspace einschließlich lokaler Starter-/Transfer-/Ready-/Identitätsfixes ist die Arbeitsgrundlage.

**Ziel / Scope:** Bestehenden Partnerpfad und Zustandsverträge prüfen; Vorlagen laden, übertragen, lokalisieren, löschen/archivieren; Bedienung und Fehler-/Ergebnisnavigation vereinfachen. Keine neuen Fachgeneratoren, keine Laufdatenlöschung, kein Replay unsicherer Pakete, kein Deployment/ForceSync/Commit/Push.

**Vorgehen / Abhängigkeiten:** SF-005–SF-018 und vorhandene Starterimplementierung prüfen; Standard-Queuequellen aus lokalen Symbolen mit Worker/Runner/Fehlerhandler abgleichen. Gespeicherte Vorzustände, technische Historie, parent-lock bei Snapshot/Entfernung, feste Starter-IDs und vollständige Übersetzungskette prüfen. Neue ID 90148 für firmenbezogene Entfernt-Vermerke im freien ScenarioManagement-Block; additive Tabelle/Feldänderung, keine Migration historischer Snapshots.

**Akzeptanz:** Nutzervorgaben dieses Auftrags einschließlich 5/5, 12/7, negativer Setupfall, Sammeltransfer zwischen zwei Testfirmen, DE/EN und wiederholtes Laden nach Löschen/Archivieren. Lokale Builds sind keine BC-Abnahme.

**Tests / Risiken / offene Anforderungen:** [Aktueller Prüfnachweis](docs/TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026) und [vereinfachte Testanleitung](docs/review/TESTANLEITUNG.md). Ursprüngliche CUSTOMER-Ursache ohne frühesten vollständigen Standardfehler oder freigegebene Reproduktion weiterhin **Zu prüfen**. Sandbox-/Queue-/Rechte-/Parallelitäts-/Installations-/Transferabnahme offen. Keine menschliche Abnahme behauptet.

---

<a name="sf-038"></a>

### SF-038 — Realistische Kontenpläne und vollständige Buchungseinrichtung im Starterpfad

**Status:** Zur Prüfung  
**Priorität:** P0  
**Abhängigkeiten:** SF-009, SF-017, SF-037  
**Verantwortung / betroffene Module:** Finance, SetupManager, IndustryProfiles, ScenarioManagement  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** In der gezeigten Testfirma stehen nur `BCSF-AP` und `BCSF-AR` im Kontenplan. Die beiden Konten mit Test-Bezeichnung ersetzen keinen für Buchungen und Auswertungen brauchbaren Kontenplan. SF-017 beschreibt bereits SKR03-/SKR04-Pakete. Zu prüfen ist, welcher Starter-, Einrichtungs- oder Schnellstartpfad solche Ersatzkonten anlegt und ob er den Paketvertrag umgeht.

**Soll-Verhalten / technischer Arbeitsauftrag:** Einen gemeinsamen Finance-Einrichtungspfad nutzen. Passende vorhandene BC-Einrichtung vollständig prüfen und unverändert wiederverwenden oder in der freigegebenen Sandbox bei der einmaligen Mandanteninitialisierung nach einer Auswahl eines der versionierten lokalen SKR03-/SKR04-basierten Pakete anwenden. Fehlt die Einrichtung, soll die Vorlage eine klare Aktion zur passenden Einrichtung anbieten. Keine manuelle Einzelanlage von Sachkonten oder Gruppen als reguläre Startvoraussetzung.

**Vorgehen (einzeln abzuarbeiten):**

- [x] Alle Schreibpfade für Konten und Gruppen vom Starter, Schnellstart, Assistenten und regulären Lauf bis Finance prüfen. Zwei-Konten-Fallbacks und Buchungsgruppen mit generischen Test-/Demo-Namen aus dem regulären Pfad entfernen.
- [x] Je Rahmen einen schlanken, belastbaren Kontenplan mit fachlichen Nummernbereichen, führenden Nullen, lesbaren Bezeichnungen, Gliederung und Klassifikation vorsehen. Mindestens Bank/Kasse, Forderungen, Verbindlichkeiten, Bestand, Vor-/Umsatzsteuer, Eigenkapital, Erlöse, Wareneinsatz und repräsentative Betriebskosten abdecken. Buchungs- und Summenkonten unterscheiden, Standard-Bilanz/GuV und freie Sachkontenbuchungen unterstützen.
- [x] Konsistente Zuordnung der Kontenrollen zu Debitoren-/Kreditoren-/Bank-/Lagerbuchungsgruppen sowie allgemeinen und MwSt.-Buchungskombinationen treffen, soweit für das Profil benötigt. Sachkontonummern nicht in einzelnen Generatoren hardcodieren. Validierung und Zuordnung im Paket bündeln.
- [x] Bezugsjahr, Version, Herkunft, tatsächlichen Kontenumfang und Änderungen je Paket dokumentieren. Vorhandene SF-017-Pakete weiterverwenden bzw. korrigieren. Wenn offizielle DATEV-Daten erwogen werden, verfügbare Bezugsquelle und Wiederverwendungsrechte vor Übernahme prüfen. Kein Scraping oder Live-Abruf als Laufzeitvoraussetzung. Selbst erstellte Teilpläne eindeutig als SKR03-/SKR04-basiert beschreiben, nicht als vollständigen offiziellen Kontenrahmen ausgeben.
- [x] Konfliktprüfung intern, erste konkrete Meldung bei einem Blocker, Paketversion im Lauf-Snapshot und Umgang mit bestehenden Ersatzkonten dokumentieren. Die frühere Vorschauseite entfällt nach SF-043. Keine bestehenden oder bebuchten Konten umbenennen, löschen oder umhängen. Bei Konflikten konkrete nächste Aktion anzeigen.

**Akzeptanzkriterien:**

- [ ] Je eine frische Sandbox-Firma für SKR03 und SKR04. Nach Auswahl und Anwendung zeigt der BC-Standardkontenplan eine nachvollziehbare Gliederung und alle vorgesehenen Kontenrollen. Zweite Anwendung erzeugt keine Duplikate. Weitere Sandbox mit passender vorhandener BC-Einrichtung bleibt unverändert.
- [ ] Pro Paket einen manuellen Standard-Verkaufs-, Einkaufs- und Sachkontenbuchblattfall mit dokumentierten Soll-/Ist-Konten und Beträgen buchen. Bilanz und GuV mit gebuchten Beträgen und Summen abgleichen. Zulässige Standard-Sachkontenzeilen oder bereitgestellte Testartikel genügen, solange SF-019 noch nicht umgesetzt ist.
- [ ] Fehlende Kontenrollen, Konflikte sowie Rollen ohne Schreibfreigabe werden vor unvollständiger Paket- oder Datenanlage abgefangen. Der reguläre Pfad legt keine Ersatzkonten `BCSF-AR`/`BCSF-AP` an.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Produktivänderung, keine automatische Umstellung bestehender Buchungsdaten und keine Direktinserts in gebuchte Posten.

**Risiken / Entscheidungen:** Lokalisierung und BC-Zielversion prüfen. Nicht jede Standardfirma benötigt dieselbe Konfiguration. Anwendbare und nicht unterstützte Fälle mit nächsten Schritten ausweisen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

**Umsetzungsstand 18.11.2026:** Implementierung im aktuellen Workspace; [gemeinsamer Vertrag und Grenzen](docs/STABILIZATION_FINANCE_PARTNERS.md), [tatsächliche Prüfungen](docs/TESTS.md#sf-038--sf-039--lokaler-prüfnachweis-18112026). Keine Sandbox-Abnahme. Insbesondere Standardbuchungen, DE/EN-Partnerlauf und Kinddaten-/Recoveryfälle bleiben offen. Neue Paketversion 2.0.0; kein Zwei-Konten-Fallback, keine stille Migration alter Pakete.

**Nachprüfung 19.11.2026:** Nutzer bestätigt deaktivierte SKR-Anwendung mit Standardrechte-Befund. Zu pauschale Vollschreibprüfung (einschließlich Delete) durch operationsbezogene Prüfung bestehender Benutzer-/Lizenzrechte ergänzt; keine Rechteerhöhung. Vorschau zeigt Blocker zuerst, Ursache und nächste Schritte sowie hervorgehobene Aktionen. [Nachweis und offene BC-Rechteprüfung](docs/TESTS.md#sf-038--gesperrte-finanzpaketanwendung-19112026). Status bleibt **Zur Prüfung**, konkrete Sandboxlösung nicht behauptet.

---

<a name="sf-039"></a>

### SF-039 — Realistische Geschäftspartner und nutzbare Partnerstammdaten

**Status:** Zur Prüfung  
**Priorität:** P0  
**Abhängigkeiten:** SF-010, SF-011, SF-018, SF-038  
**Verantwortung / betroffene Module:** DataGeneration, IndustryProfiles, Sales, Purchasing, Finance  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Der gezeigte Debitorenbestand wiederholt wenige Namen und Kontakte und enthält Bezeichnungen wie „Testbetrieb Nordlicht [1]“ und „Testperson Jona Kupferwald“. Auch Adressen, E-Mail-Adressen und Gruppen wirken nach Nutzerbericht wie Platzhalter. Damit lassen sich Schulungen, Demos und echte BC-Prozessprüfungen schlechter durchführen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Die vorhandenen Partnergeneratoren liefern natürlich wirkende, vollständig synthetische B2B-/B2C-Stammdaten. Fachliche Daten sind aufeinander abgestimmt und für die vorgesehenen Standardprozesse nutzbar. Die Kennzeichnung als generierter Datensatz bleibt technisch über Herkunft und Lauf-ID möglich, nicht über Präfixe in Fachfeldern.

**Vorgehen (einzeln abzuarbeiten):**

- [x] Seed-Kataloge und Generatoren auf alle Platzhalterpfade prüfen. Plausible Personen wie „Jonas Schneider“ oder „Lea Müller“, fiktive Firmen mit passenden Rechtsformen und passende Ansprechpartner kombinieren. Variabilität nach Branche, Datensprache, Region und Zielmenge steuern. Keine eckigen Zählersuffixe oder künstlichen Test-/Demo-/Muster-Präfixe in Namen, Adressen, Kontakten, E-Mails und neu angelegten Buchungsgruppen. Fachlich legitime Kennzeichnung in App/Setup-Vorschau bleibt möglich.
- [ ] Straße, Hausnummer, PLZ, Ort und Land konsistent kombinieren. Für E-Mails reservierte nicht zustellbare Domains benutzen. Bankverbindungen als zugeordnete BC-Standarddatensätze mit plausiblen Feldwerten, und für Bankformate mit der BC-Validierung kompatible synthetische Testwerte verwenden. Keine realen Empfänger, importierten Personendaten, Mailzustellungen, Bankübermittlungen oder produktiven Zahlungsexporte. Wenn keine sichere Bankkonfiguration verfügbar ist, klar melden und den betroffenen Zahlungsprozess nicht als bereit ausweisen.
- [ ] Nach Profil und Partnerklasse passende Debitoren-Lieferadressen, Kreditoren-Bestelladressen, Kontakte, bevorzugte Bankverbindung soweit sinnvoll, Währung, Zahlungsbedingungen/-form, Buchungsgruppen, Steuerlogik und Dimensionen zuordnen. Relevante Felder über BC-Standardvalidierung und Nummernserien setzen. Keine fachfremden Einträge nur zur Erhöhung der Feldabdeckung.
- [x] Parent-/Child-Zuordnung, Herkunft, Wiederanlauf und Eindeutigkeit über stabile Schlüssel sicherstellen. Gleicher Seed und gleiche Regelversion ergeben gleiche fachliche Werte, ohne interne BC-Nummern mit Namen zu verwechseln. Alte Laufdaten und manuell gepflegte Stammwerte unverändert lassen.

**Teilumfang umgesetzt:** Plausible Adressen/E-Mail, natürliche Ansprechpartner, Liefer-/Bestelladressen sowie fachliche Zuordnungen für vorhandene Einstellungen. Bankverbindungen und Zahlungsabnahme sind nicht erledigt.

**Akzeptanzkriterien:**

- [ ] Sichtprüfung eines gemischten DE-Laufs mit mindestens 50 Debitoren und 50 Kreditoren sowie eines EN-Profils. Keine generischen Platzhalter oder Zählersuffixe, keine kleine sich zyklisch wiederholende Namensauswahl, sinnvolle B2B-/B2C-Verteilung und Adresskonsistenz. Gleicher Seed reproduzierbar, anderer Seed mit plausibel verteilten Varianten.
- [ ] Im BC-Standard lassen sich zu ausgewählten Partnern die vorgesehenen Liefer-/Bestelladressen und Bankverbindungen öffnen und in passenden Belegen bzw. Zahlungszeilen auswählen. Ein Standardeinkaufs- und ein Standardverkaufsbeleg übernehmen die korrekten Stammdatenwerte.
- [ ] Fehlende Buchungsgruppen oder nicht valide Partner-/Kinddaten werden mit konkreter Ursache sichtbar. Wiederanlauf erzeugt keine doppelten Kinddatensätze oder verwaisten Referenzen.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine Nutzung realer Geschäftspartnerdaten, keine Massenbereinigung früherer Läufe, keine Einführung neuer Fachgeneratoren.

**Risiken / Entscheidungen:** Synthetische Daten müssen unabhängig von der UI-Sprache steuerbar bleiben. Keine Zustellbarkeit für realistisch aussehende Adressen, Kontakt- oder Zahlungsdaten annehmen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

**Umsetzungsstand 18.11.2026:** Implementierung im aktuellen Workspace; [gemeinsamer Vertrag und Grenzen](docs/STABILIZATION_FINANCE_PARTNERS.md), [tatsächliche Prüfungen](docs/TESTS.md#sf-038--sf-039--lokaler-prüfnachweis-18112026). Keine Sandbox-Abnahme. Insbesondere Standardbuchungen, DE/EN-Partnerlauf und Kinddaten-/Recoveryfälle bleiben offen. Neue Partnerregel-/Setupversion 2; alte Captures unverändert. Ohne freigegebenen synthetischen Bankdatensatz ausdrücklich keine Zahlungsbereitschaft.

---

<a name="sf-040"></a>

### SF-040 — Vollständige Stammdatenbasis vor Belegen und Bewegungsdaten

**Status:** Zur Prüfung  
**Priorität:** P0  
**Abhängigkeiten:** SF-007, SF-008, SF-009, SF-016, SF-038, SF-039, SF-043  
**Verantwortung / betroffene Module:** Core, ModuleRegistry, Planning, SetupManager, DataGeneration, ProcessEngine  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Das bloße Anlegen von Datensätzen belegt nicht, dass ein Mandant oder Szenario fachlich startbereit ist. Fehlende Referenzstämme und Buchungseinstellungen können erst beim Buchen auffallen.

**Soll-Verhalten / technischer Arbeitsauftrag:** Für jedes BC-Fachmodul die im Szenario benötigten Stammdaten und Einrichtungen inventarisieren und nach Profil, Land, Modulen und Prozessumfang planen. Ausführung in fachlicher Reihenfolge: BC-Einrichtung prüfen/bereitstellen → Referenzstamm → Haupt- und abhängige Stammdaten → Buchungsbereitschaft prüfen → Belege → gebuchte Bewegungen. Ein Stammdatenlauf endet vor Belegen und Buchung.

**Vorgehen (einzeln abzuarbeiten):**

- [x] Eine Modul- und Entitätsmatrix für BC pflegen. Pro Entität angeben: erforderlich/optional, BC-Quelle, Standardvalidierung, Eltern/Referenzen, nachgelagerte Verwendung, Status `Vorhanden` / `Generierbar` / `Geplant` / `Nicht unterstützt` und zugehöriges Ticket. Mindestens FI/Bank, Verkauf, Einkauf, Artikel/Lager, Logistik, Fertigung/Montage, Projekte, Service, Anlagen und Kontakte berücksichtigen. Fachlich nötige Stämme inventarisieren, keine pauschale Befüllung aller BC-Tabellen.
- [x] Für den aktuellen Stand die notwendigen Referenzen für Partner und Finance (Nummernserien, Länder/Regionen, Zahlungsbedingungen/-formen, Buchungsgruppen/-matrizen, erforderliche Währungen und Dimensionen) automatisiert prüfen und nur bei vorgesehener Sandbox-Einrichtung anlegen. Für spätere Entitäten z. B. Artikel, Einheiten, Preise, Lagerorte, Ressourcen, Stücklisten oder Serviceartikel Anforderungen in den zugehörigen Tickets nachziehen.
- [x] Preflight trennt „wird erzeugt und vorher validiert“, „bereits vorhanden“ sowie „fehlt/blockiert“ und nennt eine nächste Aktion. Relevante Voraussetzungen nach Anlage und vor der ersten abhängigen Beleg-/Buchungsaktion im Hintergrund erneut prüfen. Vorlage, Schnellstart, reguläre Queue und Fortsetzen verwenden dieselben fachlichen Regeln.
- [x] Validierungsvertrag und Ablauf im bestehenden Architektur-/Testbereich dokumentieren. Zum Beispiel Pflichtfeld-/Referenzmatrix, Abhängigkeitsreihenfolge und Soll-/Ist-Nachweise versionieren. Regeln nutzen die Registry und keine verteilten Einzelprüfungen ohne Begründung.

**Akzeptanzkriterien:**

- [ ] Startfähiger Partner-Stammdatenlauf erstellt alle für das Profil zugesagten Stämme und Beziehungen. Es entstehen keine Belege oder gebuchten Bewegungen.
- [ ] Fehlt bei einem Bewegungsprofil z. B. die MwSt.-Kombination, der Lagerort oder ein erforderlicher Generator, nennt die Vorprüfung das konkrete Problem. Keine abhängige Beleganlage oder Buchung läuft darüber hinweg. Ein Stammdatenprofil ohne Lagerbedarf bleibt bei fehlendem optionalem Lagerort startfähig.
- [ ] Fachliche Reihenfolge und Prüfung sind für vorhandene Generatoren in Sandbox nachgewiesen. Spätere Module haben dokumentierte Voraussetzungen und sind bis zu ihrer Umsetzung eindeutig als geplant oder nicht unterstützt ausgewiesen.

**Nicht-Ziele / Sicherheitsgrenzen:** Keine neuen Branchen- oder Prozessgeneratoren zur Erfüllung dieses Tickets. Keine automatischen Buchungen ohne bestehende Freigabe und keine direkten Writes in gebuchte BC-Posten.

**Risiken / Entscheidungen:** Die Matrix ist erweiterbar, aber für bereits unterstützte Entitäten verbindlich. Fehlen Setup oder Rechte, darf die App keine Startfähigkeit vortäuschen.

**Umsetzung:** [Modulmatrix, Prüfvertrag und Sandbox-Testfälle](docs/MASTER_DATA_READINESS.md). Keine neuen Generatoren, Tabellen, Seiten oder Buchungsfreigaben. Teilweise bzw. nicht konfigurierte zukünftige Beleg-/Bewegungsprofile bleiben Planung. Der Nachweis in BC ist noch offen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-041"></a>

### SF-041 — Dashboard mit Datenbestand, Modulbereichen und prüfbaren Drilldowns

**Status:** Zur Prüfung  
**Priorität:** P0  
**Abhängigkeiten:** SF-011, SF-014, SF-037  
**Verantwortung / betroffene Module:** Monitoring, UI, ModuleRegistry, Sales, Purchasing, Finance, Inventory  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Der Laufmonitor zeigt heute vor allem technische Schritte. Auf einen Blick ist nicht erkennbar, was bereits erzeugt wurde, wo die Daten zu finden sind und welche Anzeige auch wirklich zur Zielseite führt.

**Soll-Verhalten / technischer Arbeitsauftrag:** Einen Bereich **Daten im Mandanten** mit klaren fachlichen Gruppen neben **Vorlagen** und **Läufe** ergänzen. Jede sichtbare Kennzahl mit verfügbarer und autorisierter Zielseite öffnet genau die angezeigte Menge in der passenden BC-Standardliste. Technische Diagnose bleibt über den Lauf erreichbar, ohne die fachliche Übersicht zu dominieren.

**Vorgehen (einzeln abzuarbeiten):**

- [x] Gruppen **Stammdaten**, **Verkauf**, **Einkauf** und **Bewegungsdaten** umsetzen. **Stammdaten** pro Entität zählen, z. B. Debitoren, Kreditoren, Kontakte, Liefer-/Bestelladressen, Partnerbankverbindungen, Sachkonten, Bankkonten, Artikel und Lagerorte. Fehlende Generatoren nicht als Nullausgabe tarnen.
- [x] **Verkauf** und **Einkauf** je relevante Standardbelegart abbilden, u. a. Angebote, Rahmenaufträge/-bestellungen, Aufträge/Bestellungen, Rechnungen, Gutschriften, Reklamationen und gebuchte Lieferungen/Eingänge, Rechnungen, Gutschriften und Rücksendungen. Ungebuchte Dokumente und gebuchte Dokumente separat zählen. Zählbasis sind Belegköpfe, keine Belegzeilen.
- [x] **Bewegungsdaten** für Sach-, Debitoren-, Kreditoren-, Bank-, MwSt.-, Artikel- und Wertposten nach Art ausweisen, soweit verfügbar. Beleg und Posten sind getrennte Kennzahlen und werden nicht zu einer vermeintlichen Gesamtzahl zusammenaddiert.
- [x] Skalierbare Gruppen für weitere BC-Module wie Finanzen/Bank, Lager/Logistik, Fertigung/Montage, Projekte, Service, Anlagen und CRM/Beziehungen vorsehen. Registrierung pro Entität mit Modul, Caption, Zählquelle, fachlichem Filter, Drilldown-Ziel, Berechtigungs- und Verfügbarkeitsregeln. Kerngruppen sichtbar, weitere Gruppen aufklappbar. Neue Module ergänzen ihre Registrierung statt das Dashboard zu duplizieren.
- [x] Standardansicht **Von Scenario Factory erzeugt** in der aktuellen Firma mit optionalem Lauf-Filter. **Gesamter Mandant** als separat auswählbaren, klar beschrifteten Umfang ohne Laufbindung anbieten. Vorhandene Live-Datensätze zählen, keine geplanten, doppelt protokollierten oder gelöschten Ergebnisse. Können Herkunft oder Filter nicht zuverlässig abgebildet werden, als nicht verfügbar kennzeichnen. Keine Drilldowns in ungefilterte Listen als Ersatz für einen gefilterten Wert.
- [x] BC-Sitzungssprache einheitlich für Dashboard, Aktionen, Tooltips, Fehler und Zielseitenbeschriftungen verwenden. Status klar unterscheiden: „0 Datensätze“, „Kein Generator verfügbar“ oder „Kein Zugriff“. Keine wirkungslosen Buttons. Zählung bedarfsgerecht laden, nicht bei jeder Aktualisierung alle Postentabellen vollständig lesen. Lade- und Aktualisierungszustand zeigen.

**Akzeptanzkriterien:**

- [ ] Nach einem Partnerlauf stimmen Dashboardzahlen für Partner und Kinder mit den gefilterten Standardlisten überein. Prüffall mit vorhandenen manuellen Daten und zwei Läufen zeigt korrekte Trennung der Ansichten und des Lauf-Filters.
- [ ] Je eine Verkaufs-, Einkaufs- und Postenkennzahl ist mit vorhandenen Standarddaten in der Mandantenansicht nachgewiesen, unabhängig davon, ob der zugehörige Generator bereits existiert. In der generierten Ansicht erscheinen nur tatsächlich zugeordnete Datensätze.
- [ ] Jeder verfügbare und berechtigte Zähler ist per Maus und Tastatur verständlich erreichbar. Bei fehlendem Standardlistenziel ist der Ausfall ausdrücklich sichtbar und für die nötige Alternative dokumentiert. Benutzer ohne Leserecht sehen keine Daten oder vertrauliche Zähler der Entität. Deutsche Sitzung zeigt keine unübersetzten englischen App-Texte.
- [ ] Dashboard bleibt mit leerem Mandanten, reichlich vorhandenen Daten und mehreren sichtbaren Modulgruppen benutzbar. Aktualisierung nach Laufabschluss und nach zwischenzeitlicher Datenänderung geprüft; Laufzeiten und Umfang dokumentiert.

**Nicht-Ziele / Sicherheitsgrenzen:** Statistik startet keine Generierung oder Buchung. Geplante Module erhalten keine erfundenen Datenquellen. Keine Berechtigungen über den Dashboardpfad umgehen.

**Risiken / Entscheidungen:** Drilldowns für abhängige Entitäten und nicht zusammenhängende Datensätze mit Standardseiten, den realen BC-Symbolen und repräsentativer Filtergröße prüfen. Für große Datenmengen Strategie und Messung festhalten.

**Umsetzung und gemeinsamer Sandbox-Test:** [SF-041 Daten im Mandanten](docs/DASHBOARD_DATA_STOCK.md). Statische und Client-/Bridge-Prüfungen durchgeführt. AL-Build, reale Zielseitenfilter, Berechtigungen und Laufzeiten noch nicht per Sandbox abgenommen.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-042"></a>

### SF-042 — Partnerpfad stabilisieren, Bedienung polieren und Ausbau freigeben

**Status:** Offen  
**Priorität:** P0  
**Abhängigkeiten:** SF-037, SF-038, SF-039, SF-040, SF-041, SF-043  
**Verantwortung / betroffene Module:** ScenarioManagement, Monitoring, BackgroundProcessing, Validation, Finance, Querschnitt  
**Verantwortliche Person:** Zu prüfen

**Ausgangslage / Problem:** Vorlage und Lauf funktionieren nach Nutzerbericht wieder. Das ist noch kein Nachweis dafür, dass ein neuer Nutzer von der Vorlage ohne Umwege zu brauchbaren Daten gelangt oder Fehler selbst einordnen kann. Der verbliebene Aufwand entsteht vor allem durch unklare Begriffe, viele technische Optionen und schwankende Datenqualität.

**Soll-Verhalten / technischer Arbeitsauftrag:** Den vorhandenen Kernpfad stabilisieren und in einer frischen Sandbox abnehmen. Klarer Bedienweg: Vorlage auswählen → Voraussetzungen prüfen und bei Bedarf passende Einrichtung anbieten → Lauf im Hintergrund starten → Status ansehen → Daten öffnen. Erweiterte Einrichtung, Pakete, Checkpoints und technische Fehlerdetails bleiben erreichbar, stehen aber nicht im Standardpfad.

**Vorgehen (einzeln abzuarbeiten):**

- [ ] Standardweg mit wenigen eindeutigen Hauptaktionen prüfen und vereinfachen. Je Status die sinnvolle nächste Aktion prominent anbieten. Fehlertext nennt betroffene Entität, Ursache und mögliche nächste Aktion. Keine automatische Wiederholung eines ungeklärten Pakets. Vorlage und Daten bleiben nachvollziehbar verknüpft.
- [ ] Ende-zu-Ende-Prüfung mit BC-Version, Lokalisierung, Umgebung, Rolle, Seed, Vorlage, erwartetem und tatsächlich erreichtem Ergebnis dokumentieren. Den realen Hintergrundlauf einschließlich mehrerer Pakete und Schließen der Sitzung nach Start prüfen. Die tatsächlich erzeugten Daten über den Dashboard-Drilldown im BC-Standard öffnen.
- [ ] Regression von Startervorlagen, Sammeltransfer, Lösch-/Archivregeln und DE/EN anhand SF-037 prüfen. Beispieldaten dürfen bei korrekter deutscher UI weiterhin der bewusst gewählten Datensprache folgen.
- [ ] Verbindliche Generatorregeln in `AGENTS.md` verlinken und an bestehender Stelle in Architektur-/Test-/Moduldokumentation festhalten. Mindestens Datenrealismus, Setup-/Stammreihenfolge, BC-Standardvalidierung und -buchung, Herkunft/Idempotenz, Modulstatistik und Drilldown, Sprachtrennung sowie die Nachweise je Modul dokumentieren. Kurze Einsteiger-Testanleitung unter dem bestehenden Testpfad nachführen.
- [ ] Bei künftigen Tickets die Qualitätscheckliste als Vorbedingung und Abnahme übernehmen. Bei fehlender Generator- oder Setupabdeckung ein Folgeticket verlinken oder den Umfang konkret eingrenzen, nicht stillschweigend umgehen.

**Akzeptanzkriterien:**

- [ ] In frischer Sandbox schafft ein Anwender den Kernpfad anhand der Kurzanleitung ohne manuelles Anlegen einzelner benötigter Sachkonten und Buchungsgruppen. Zwei unterschiedlich dimensionierte Partnerläufe liefern die erwarteten Mengen und Beziehungen auch bei geschlossener Sitzung. Abschlussstatus und Dashboard stimmen mit BC-Daten überein.
- [ ] Fehlendes Setup, fehlende Rechte und ein kontrollierter Batchfehler sind praktisch geprüft. Ein fehlgeschlagener Lauf zeigt einen verständlichen nächsten Schritt. Bei Wiederanlauf entstehen keine unbemerkten Duplikate. Nicht eindeutig fortsetzbare Arbeit bleibt sichtbar blockiert.
- [ ] Die Abnahme enthält die fachlichen Nachweise aus SF-038 bis SF-041. Ungetestete Varianten stehen ausdrücklich als offen. Build, lokale Tests und Nutzerbericht sind getrennt von der realen Sandbox-Abnahme dokumentiert.
- [ ] Menschliche Freigabe des P0-Stands liegt vor. Erst danach weitere Fachgeneratoren beginnen. Manuelle BC-Abnahmefälle sind ausreichend für den Kernpfad, ohne geplante Generatoren vorziehen zu müssen.

**Nicht-Ziele / Sicherheitsgrenzen:** Kein Vorziehen von SF-019 oder weiteren Generatoren, keine pauschale Freigabe aller Branchenprofile, keine Änderung außerhalb des genehmigten Ticketumfangs.

**Risiken / Entscheidungen:** Ein einzelner erfolgreicher Lauf genügt nicht für Wiederanlauf oder Datenqualität. Bei Wiederauftreten des Fehlers den ersten vollständigen Queue-Fehler mit Lauf-/Paketbezug dokumentieren.

**Abnahme:** [ ] Nutzer hat dieses Ticket ausdrücklich abgenommen.

---

<a name="sf-043"></a>

### SF-043 — Mandant einmalig initialisieren und Vorlagenstart vereinfachen

**Status:** Zur Prüfung  
**Priorität:** P0  
**Abhängigkeiten:** SF-038, SF-039  
**Betroffene Module:** Core, Finance, IndustryProfiles, ScenarioManagement, Monitoring

**Ziel und Umsetzung:** Kontenrahmenwahl beim einmaligen Initialisieren der Sandbox-Firma. Gemeinsame Stammdaten und Einrichtung dort vorhalten. Ein Vorlagenstart nutzt bereits vorhandene Einrichtung und legt keine globale Finanzkonfiguration an. Die Navigation konzentriert sich auf Einrichtung, Vorlagen und Laufmonitor. Sieben doppelte Seiten entfallen. Keine neuen Tabellen/Seiten, keine Datenlöschung.

- [x] Auswahl und Bootstrap in den vorhandenen Setupbereich verlegen, vorhandene SKR-Pakete verwenden und bei Blockern einen konkreten Befund anzeigen.
- [x] Direkten Queue-Start ohne Vorlagen-Finanzdialog umsetzen, bestehende Snapshots nicht verändern und Starterdaten erst beim Initialisieren laden.
- [x] Objektverweise, Übersetzungen und Bedien-/Abnahmeweg aktualisieren.
- [ ] AL-Build auf Zielversion und reale BC-Prüfung in leeren SKR03-/SKR04-Sandbox-Firmen, bestehender Firma und Altstand-Upgrade.
- [ ] Nutzerabnahme.

**Nachweise und Grenzen:** [Umsetzung und Testweg](docs/COMPANY_INITIALIZATION.md), [Prüfprotokoll](docs/TESTS.md#sf-043--mandanteneinrichtung-und-direkter-vorlagenstart).

---

<a name="sf-044"></a>

## SF-044 — Dashboard kompakt gestalten und Kennzahlen direkt nutzbar machen
**Status**: Zur Prüfung
**Priorität**: P1
**Abhängigkeit**: SF-041
**Betroffen**: Bestehender Scenario-Factory-Arbeitsplatz und sein Dashboard-Control-Add-in
**Ziel**
Entwickler und Fachberater sollen auf einen Blick sehen, welche Daten vorhanden sind und was der ausgewählte Lauf erzeugt hat. Das Dashboard soll flach, kompakt und direkt bedienbar sein. Fachliche Zahlen stehen im Vordergrund. Erklärtexte und technische Details erscheinen nur dort, wo sie bei einer Entscheidung oder Fehlersuche helfen.
Anforderungen
1. Daten und Läufe klar trennen. Im bestehenden Arbeitsplatz zwei Reiter Daten und Läufe anbieten. Szenariovorlagen bleibt ein direkter Einstieg, erscheint aber nicht mehrfach. Die Laufauswahl unter Läufe ändert den Datenfilter im Reiter Daten nicht unbemerkt. Keine neue BC-Seite anlegen.
2. Bestandszahlen als kleine Kacheln anzeigen. Stammdaten jeder Art sowie die Kennzahlen für Verkauf, Einkauf, Bewegungsdaten und weitere Module erscheinen in einem einheitlichen, responsiven Raster. Jede Kachel zeigt einen verständlichen Namen und eine Zahl, zum Beispiel Debitoren · 25 oder Lieferadressen · 25. Auf breiten Bildschirmen stehen mehrere Kacheln nebeneinander, auf schmalen Ansichten brechen sie um. Keine langen Tabellenzeilen mit einer kleinen Zahl am anderen Bildschirmrand.
3. Kennzahlen direkt anklickbar machen. Wo eine passende Standardliste oder Laufansicht verfügbar und zulässig ist, ist die gesamte Kachel klickbar. Das gilt auch für die Kennzahlen zu Vorlagen und Läufen, sofern die Zielansicht zur angezeigten Zahl passt. Eine klickbare Zahl öffnet genau die gefilterte Menge, die sie anzeigt. Eine 0 ist nur klickbar, wenn die Zielansicht zuverlässig leer geöffnet werden kann. Ohne Zugriff oder passende Zielansicht gibt es keine Scheinaktion.
4. Datenumfang sichtbar machen und leere Hinweise bündeln. Direkt am Kachelraster zeigen, ob die Zahlen den gesamten Mandanten, alle erzeugten Daten oder einen ausgewählten Lauf betreffen. In der erzeugten Ansicht nicht für jede Entität „Kein Generator verfügbar“ wiederholen. Diese Einträge standardmäßig in einem aufklappbaren Bereich bündeln. Ein echter Nullbestand, ein fehlender Generator und fehlender Zugriff bleiben unterscheidbar. In der Mandantenansicht bleiben vorhandene Daten auch ohne Generator sichtbar.
5. Lauffortschritt direkt an der Entität zeigen. Die weit entfernten Fortschrittsbalken durch kompakte Fortschrittskacheln ersetzen. Eine Kachel zeigt zum Beispiel Debitoren · 20/20 · abgeschlossen. Ein kleiner Ring oder kurzer Balken kann direkt daneben stehen, darf aber keinen zusätzlichen Platz beanspruchen, wenn die Zahl schon alles sagt. Geplant, erzeugt und offen müssen verständlich bleiben. Zusätzliche Ergebnisse wie Adressen fachlich benennen, sofern sie getrennt vorliegen. Technische Begriffe wie Artefakte bleiben in der Diagnose.
6. Laufansicht auf das Wesentliche kürzen. Im Normalfall reichen Laufname, Status, Ergebnis und die nächste sinnvolle Aktion. Ergebnisse öffnen bleibt bei einem abgeschlossenen Lauf gut sichtbar, aber nicht als Schaltfläche über die gesamte Breite. Den frühesten Start nur bei geplanten Läufen hervorheben. Bestanden darf nicht wie eine Warnung aussehen. Diagnose standardmäßig einklappen und leere Aktionsgruppen ausblenden.
7. Kopf, Texte und Typografie vereinheitlichen. Die zusätzliche obere Linie des eigenen Dashboards, den doppelten Titel, wiederholte Navigation und allgemeine Einführungstexte entfernen. Den nativen BC-Rahmen unverändert lassen. Eine Schriftfamilie und wenige konsistente Größen für Überschriften, Fachbezeichnungen und Kennzahlen verwenden. Weniger Rahmen, keine verschachtelten Kacheln und einheitliche Abstände. Beim Scrollen dürfen Filter und Überschriften nicht unter dem BC-Kopf abgeschnitten werden.
Akzeptanzkriterien
- [ ] Datenbestand und Laufdetails sind über getrennte Reiter erreichbar. Niemand muss durch die Stammdaten scrollen, um zum aktuellen Lauf zu gelangen.
- [ ] Alle Bestandsbereiche verwenden dasselbe Kachelraster. Die Kacheln sind mit Maus und Tastatur bedienbar, wo ein gültiges Ziel existiert.
- [ ] Das Beispiel aus dem aktuellen Test ist eindeutig lesbar: 25 Debitoren im Mandanten und 20 Debitoren im ausgewählten Lauf sind unterschiedliche, klar beschriftete Zahlen. Beide öffnen bei vorhandener Berechtigung die jeweils passende gefilterte Liste.
- [ ] Fortschritt steht direkt bei der Entität. Ein abgeschlossener Lauf lässt sich ohne technische Begriffe verstehen, die Diagnose bleibt erreichbar.
- [ ] Ein leerer Bestand, ein fehlender Generator, fehlender Zugriff und ein fehlgeschlagener Lauf sind visuell und sprachlich unterscheidbar. Keine unnötigen Wiederholungen oder leeren Aktionsgruppen.
- [ ] Die Ansicht ist in Business Central bei breiter und schmaler Fenstergröße geprüft. Es gibt keine abgeschnittenen Filter, keine unnötigen horizontalen Scrollbalken und einen sichtbaren Tastaturfokus.


**Umsetzungsumfang / Risiken / Testweg (19.11.2026):** Bestehende Dashboardressourcen, drei AL-Objekte (Part/Data/Stock), Übersetzungskette, vorhandene Clientprüfungen und zugehörige Dokumentation angepasst. Ziel: Daten/Läufe ohne implizite Filterkopplung, gemeinsame Kacheln und passende direkte Listenrouten. Risiko sind unterschiedliche Sicherheits-/Standardseitenfilter sowie bestätigte Arbeit gegenüber später verändertem Live-Bestand. Rechte-/Countprüfung erneut beim Klick; keine Standardliste als unbeschränkter Ersatz. Kein Schemawechsel, keine neue Seite, keine Änderung an Generatoren, Queue oder Manifest. Keine unbekannte Fachanforderung angenommen.

**Umsetzung / Nachweis:** [Bedienvertrag und konkrete Sandbox-Fälle](docs/DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026), [wirklich ausgeführte Prüfungen](docs/TESTS.md#sf-044--kompaktes-dashboard-und-direkte-kennzahlen). Lokale Client-/Layoutprüfung und Kompilierung sind erfolgreich; strenger Analyzerlauf bleibt durch zwölf nachweislich vorhandene Ausgangsbefunde blockiert. Akzeptanzhäkchen oben bleiben bis zur realen BC-Abnahme offen. Kein Deployment, keine menschliche Abnahme.

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
**Akzeptanz:** Nachweisbarer fachlicher Sollzustand, keine Regression. Bei Generatoren zusätzlich Qualitätsregeln und SF-042 berücksichtigen.  
**Testprotokoll:** BC-Version, Umgebung, Inputs, Erwartung, tatsächliches Ergebnis, bekannte Grenzen  
**Freigabe:** [ ] Menschlich bestätigt.
