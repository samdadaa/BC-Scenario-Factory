# TODO – BC Scenario Factory: aktueller Backlog

**Abgleich: 21.11.2026 · Quellstand 1.0.7.3 · Dokumentationsänderung zur Prüfung.** Aktuelle Quellen, Manifest, Testhost und lokale Nachweise sind maßgeblich. Der [bisherige vollständige Wortlaut](docs/review/BACKLOG_VOR_ABGLEICH_2026-11-21.md) bleibt als Historie erhalten; dortige Zwischenstände sind keine zusätzliche Arbeitsliste.

## Stand und nächste Arbeit

Vorhanden: **140 Main-AL-Objekte in 16 Modulen**, separate Test-App **1.3.0.3 mit 48 Testmethoden**, sieben ausführbare führende Entitäten (Debitor, Kreditor, Artikel, Einkaufsbestellung, Verkaufsangebot/-auftrag/-rechnung). Zahlung/Ausgleich ist ein vorhandener Folgedienst, kein eigener zusätzlicher Entitätsgenerator. Acht weitere Fachmodule enthalten keinen AL-Code. Ihre Auswahl im Assistenten bedeutet nur Planung.

Normalweg: **Einrichtung → Kontenplan einmalig → Großhandel → Module → Größe → Prozessstufe und Zeitraum → Zusammenfassung → Hintergrundstart → Dashboard/Ergebnisse**. Unterstützt sind Stammdaten, ungebuchte Belege, Standardbuchungen sowie vollständige Zahlung/Ausgleich. Der Zeitraum neuer Firmenrequests endet gestern; technische Erstellzeitstempel bleiben aktuell.

| Nächster offener Arbeitsbereich | Führendes Ticket | Abgrenzung |
| --- | --- | --- |
| Reale P0-Sandbox-/Fehler-/Rechteabnahme | [SF-042](#sf-042) | Vorhandene Implementierungen SF-003–SF-021 und SF-037–SF-045 prüfen; keine Neuimplementierung ihrer Grundlagen |
| Durchgängige gebuchte Großhandelsabnahme | [SF-024](#sf-024) | Bestehende Firmeninitialisierung aus SF-045 und Nachweise aus SF-042 wiederverwenden |
| AL-Runner und fehlende Regressionen | [SF-025](#sf-025) | Vorhandene Test-App ausführen/gezielt ergänzen; 48 kompilierte Methoden sind kein bestandener Testlauf |
| Fachlicher Folgeprozess-Rest | [SF-022](#sf-022) | Teilzahlungen, Gutschriften und Retouren; vorhandene Vollzahlung nicht erneut bauen |
| Sichere Partnerbankstämme | [SF-039](#sf-039) | Firmenverrechnungsbank BCSF-PAY erfüllt diesen offenen Teil nicht |
| Last, Retention, weitere Fachmodule/Branchen | [SF-026](#sf-026)–[SF-036](#sf-036) | Eigenständige künftige Aufträge; keine Ausführung durch diese Bereinigung |
| Externe Konfiguration/Releaseentscheidungen | [SF-001](#sf-001), [SF-036](#sf-036) | Publisher, installierte Zielversion/Lizenz/Rollen und externe ID-Belegung bestätigen |

## Bedeutung der Häkchen und gemeinsame Regeln

**Aktiver Implementierungsauftrag 22.11.2026:** SF-047-Zahlungsfehler zuerst korrigieren, danach ausdrücklich ausgewähltes SF-048 aus Nutzeranhang umsetzen. Bestätigte Stammdaten aus fehlgeschlagenen Läufen sind nach erneuter Prüfung ausdrücklich zugelassen. Frühere Ticketstände bleiben Historie.

- `[x]` bedeutet **im aktuellen Code vorhanden oder lokal belegt**. Es bedeutet keine bestandene native Prüfung oder menschliche Abnahme.
- `[ ]` benennt einen tatsächlichen Rest: fehlende Funktion, ausstehende native Prüfung oder Freigabe. `Zur Prüfung` kann einen benannten offenen Teilumfang enthalten; es gibt keine pauschale Fertigmeldung.
- `Erledigt` nur nach ausdrücklicher menschlicher Abnahme des jeweiligen Umfangs. Widersprüchliche alte Abnahmehäkchen sind keine neue Freigabe; SF-004 behält seinen vorhandenen expliziten Vermerk mit Klärungshinweis.
- Diese Anfrage autorisiert ausschließlich den Backlogabgleich. Für Implementierung weiterhin genau ein ausdrücklich gewähltes Ticket, Plan vor Änderung und Sicherheitsgrenzen aus [AGENTS.md](AGENTS.md).
- Neue Generatoren verwenden bestehenden Workflow, Foundation, Registry, Snapshots, Queue/Checkpoints und Qualitätsabschluss. Keine parallelen Assistenten/Finanzinitialisierungen; kein Direktinsert in Standardposten und kein Replay unsicherer Buchungen.
- Für jedes Fachmodul Voraussetzungen/Stammdaten vor abhängigen Prozessen, synthetischen Datenrealismus, Herkunft, Dashboardzähler/Drilldowns, DE/EN und passende geschützte Start-/Testvorlagen berücksichtigen. [Generatorcheckliste](docs/ARCHITECTURE.md#generator-qualitätscheckliste-sf-042), [Testvertrag](docs/TESTS.md#sf-042--prüfumfang-je-generator), [Stammdatenmatrix](docs/MASTER_DATA_READINESS.md).
- Gemeinsame native Mindestprüfung: frische SKR03-/SKR04- und vorhandene Firma, normale Rollen/fehlende Rechte, DE/EN/Tastatur, Browserende, Fehler-/Wiederanlauf-/Doppelstart, reale Standardlisten/Posten und additives Upgrade. Prüffälle einmal ausführen und in allen betroffenen Tickets verlinken; keine mehrfachen identischen Neuaufträge.

## Zusammengeführte oder ersetzte Aufgaben

- **AL-001 → SF-001/SF-002:** Doppelte Bestandsprüfung, keine separate Implementierung mehr. Historische ID bleibt unten erreichbar.
- **SF-015/SF-043 → SF-045:** Normaler Start über bestehende Setupkarte; entfernten separaten Wizard/Finanzdialog nicht wieder bauen. Technische Vorlagen bleiben Expertenzugang.
- **SF-017/SF-038:** Eine gemeinsame Finanzbasis; Paketintegration durch vorhandene Fachgeneratoren ist umgesetzt. Kein zweites Paketframework oder Voll-DATEV-Versprechen.
- **SF-014/SF-041/SF-044:** Ein gemeinsames Dashboard; Datenbestand, Bedienung und Native-Abnahme bleiben getrennte Prüfaspekte. Alte 150er-Herkunftsgrenze und frühere Analyzerblocker sind durch spätere Stände überholt.
- **SF-020/SF-021/SF-022:** Einkauf und Verkauf bis Rechnung vorhanden, Gutschriften/Retouren einmal unter SF-022 führen. Die frühere fehlende SF-020-Abhängigkeit ist umgesetzt.
- **SF-023/SF-045 und SF-025:** Großhandelspaket und separates Testprojekt existieren; verbleibende Profilbreite/Abdeckung und native Nachweise stehen unten.
- **SF-027/SF-037:** Vorlagenarchivierung ist vorhanden; fehlende Lauf-/Fachdaten-Retention bleibt offen.

Wiederholte allgemeine Vorgehensblöcke sowie doppelte Sicherheits-/Abnahmesätze sind durch diese gemeinsamen Regeln ersetzt. Ursprüngliche Ziele/Abhängigkeiten und historische Begründungen bleiben im verlinkten Archiv nachvollziehbar. Keine offene Fachanforderung wird allein wegen ihres Alters gestrichen.

## Ticketübersicht

| Ticket | Prio | Status | Umsetzungsstand / verbleibende Arbeit |
| --- | --- | --- | --- |
| [SF-001](#sf-001) | P0 | Blockiert | Lokale Basis vorhanden; externe Freigaben offen |
| [SF-002](#sf-002) | P0 | Zur Prüfung | Umgesetzt |
| [SF-003](#sf-003) | P0 | Zur Prüfung | Umgesetzt |
| [SF-004](#sf-004) | P0 | Zur Prüfung | Umgesetzt; Abnahmevermerk aus Altbestand |
| [SF-005](#sf-005) | P0 | Zur Prüfung | Umgesetzt |
| [SF-006](#sf-006) | P0 | Zur Prüfung | Umgesetzt |
| [SF-007](#sf-007) | P0 | Zur Prüfung | Umgesetzt; öffentliche API bleibt SF-034 |
| [SF-008](#sf-008) | P0 | Zur Prüfung | Umgesetzt |
| [SF-009](#sf-009) | P0 | Zur Prüfung | Umgesetzt |
| [SF-010](#sf-010) | P0 | Zur Prüfung | Umgesetzt |
| [SF-011](#sf-011) | P0 | Zur Prüfung | Umgesetzt |
| [SF-012](#sf-012) | P0 | Zur Prüfung | Umgesetzt |
| [SF-013](#sf-013) | P0 | Zur Prüfung | Umgesetzt; Wiederholung bewusst begrenzt |
| [SF-014](#sf-014) | P0 | Zur Prüfung | Umgesetzt; UI-Ausbau SF-041/SF-044/SF-045 |
| [SF-015](#sf-015) | P0 | Zur Prüfung | Früherer Wizard ersetzt durch bestehenden Unternehmensassistenten |
| [SF-016](#sf-016) | P0 | Zur Prüfung | Umgesetzt |
| [SF-017](#sf-017) | P1 | Zur Prüfung | Umgesetzt; gemeinsamer Finanzpfad |
| [SF-018](#sf-018) | P1 | Zur Prüfung | Umgesetzt |
| [SF-019](#sf-019) | P1 | Zur Prüfung | Umgesetzt im bestätigten Stammdatenumfang |
| [SF-020](#sf-020) | P1 | Zur Prüfung | Bestellung/Eingang/Rechnung umgesetzt; Gutschriften SF-022 |
| [SF-021](#sf-021) | P1 | Zur Prüfung | Umgesetzt; Übersicht korrigiert |
| [SF-022](#sf-022) | P1 | Zur Prüfung | Teilumfang umgesetzt; fachlicher Ausbau offen |
| [SF-023](#sf-023) | P1 | Zur Prüfung | Großhandel umgesetzt; ursprüngliche Profilbreite teilweise offen |
| [SF-024](#sf-024) | P1 | Zur Prüfung | Technischer Pfad vorhanden; E2E-Abnahme offen |
| [SF-025](#sf-025) | P1 | Zur Prüfung | Test-App vorhanden; Ausführung und Abdeckung offen |
| [SF-026](#sf-026) | P1 | Offen | Benchmarks fehlen |
| [SF-027](#sf-027) | P1 | Offen | Vorlagenschutz vorhanden; Lauf-Retention/Reset fehlen |
| [SF-028](#sf-028) | P2 | Offen | Kein Warehouse-Generator |
| [SF-029](#sf-029) | P2 | Offen | Keine Fertigungs-/Montagegeneratoren |
| [SF-030](#sf-030) | P2 | Offen | Keine Projekt-/Servicegeneratoren |
| [SF-031](#sf-031) | P2 | Offen | Kein Anlagengenerator |
| [SF-032](#sf-032) | P2 | Offen | Weitere Unternehmensbranchen fehlen |
| [SF-033](#sf-033) | P3 | Offen | Keine CRM-/Planungsgeneratoren |
| [SF-034](#sf-034) | P3 | Offen | Internes Interface vorhanden; öffentliches SDK fehlt |
| [SF-035](#sf-035) | P3 | Offen | Trainingsvorlagen vorhanden; Aufgaben-/Erfolgskontrollen fehlen |
| [SF-036](#sf-036) | P3 | Offen | Lokale Pakete vorhanden; Releasefreigabe fehlt |
| [SF-037](#sf-037) | P0 | Zur Prüfung | Umgesetzt; Normalnavigation durch SF-045 ersetzt |
| [SF-038](#sf-038) | P0 | Zur Prüfung | Umgesetzt; Finanzbasis gemeinsam mit SF-017 |
| [SF-039](#sf-039) | P0 | Zur Prüfung | Partnerqualität umgesetzt; Partnerbankstämme offen |
| [SF-040](#sf-040) | P0 | Zur Prüfung | Prüfstruktur für vorhandene Generatoren umgesetzt |
| [SF-041](#sf-041) | P0 | Zur Prüfung | Umgesetzt; native Filter-/Rechteabnahme offen |
| [SF-042](#sf-042) | P0 | Zur Prüfung | Regeln/Bedienung vorhanden; P0-Abnahme offen |
| [SF-043](#sf-043) | P0 | Zur Prüfung | Umgesetzt; Normalweg durch SF-045 erweitert |
| [SF-044](#sf-044) | P1 | Zur Prüfung | Umgesetzt; strenger Build inzwischen erfolgreich |
| [SF-045](#sf-045) | P0 | Zur Prüfung | Umgesetzt im Großhandelsumfang |
| [SF-046](#sf-046) | P1 | Zur Prüfung | Konfigurationspaket mit 128 Tabellen; native Exportabnahme offen |
| [SF-048](#sf-048) | P1 | Zur Prüfung | Drei Laufarten, bestätigte Stammdatenquelle und unabhängige Einkaufs-/Verkaufsläufe; native A–G offen |
| [SF-047](#sf-047) | P1 | Zur Prüfung | Großhandel v6: Artikelpool, zeitliche Beschaffung, geografische Streuung; native Abnahme offen |

## Ticketdetails

<a name="sf-001"></a>

### SF-001 — Projektkonfiguration, Objekt-ID-Strategie und Ziel-Sandbox abstimmen

**Status:** Blockiert · **Priorität:** P0
**Einordnung:** Lokale Basis vorhanden; externe Freigaben offen
**Abhängigkeiten:** Keine

- [x] App-Identität, Runtime 17, Application 28.0, IDs 90100–90999 und leere Dependencies aus app.json verifiziert; lokale BC-28.5-Symbole und Buildnachweise vorhanden.
- [x] Objektbereich und Struktur in SF-002 dokumentiert; alte 50-ID-Grenze und früherer Symbolmangel sind überholt.
- [ ] Publisher (weiter Default Publisher), tatsächlich installierte BC-Version/Lokalisierung, isolierte Testfirmen, externe ID-Belegung und effektive Zielrechte bestätigen. Releaseziel mit SF-036 klären.

**Belege:** [app.json](app.json), [PROJECT.md](docs/PROJECT.md), [DECISIONS.md](docs/DECISIONS.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-002"></a>

### SF-002 — AL-Struktur, Namenskonventionen und Objektplan finalisieren

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-001

- [x] Präfix BCSF, Namespaces, Objektplan und Typordner je Modul vorhanden; 140 AL-Objekte in 16 Modulen inventarisiert.
- [ ] Projektkonventionen/Objektbelegung menschlich prüfen; externe Kollisionen verbleiben in SF-001.

**Belege:** [CONVENTIONS.md](docs/CONVENTIONS.md), [OBJECT_PLAN.md](docs/OBJECT_PLAN.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-003"></a>

### SF-003 — Sicherheitsguard: Sandbox, Mandant, Berechtigung

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-001

- [x] Umgebungs-/Firmen-/Rechte-/Mengen-/Buchungsfreigaben im Environment Guard und verpflichtenden Datenbankevents implementiert; Hintergrund-/Postingpfade verwenden die Guards.
- [ ] Native Negativfälle für Produktion, falsche Firma, fehlende Rechte und direkte Schreibpfade einschließlich Modify(false) ausführen.

**Belege:** [BCSFEnvironmentGuard.Codeunit.al](src/Lifecycle/Codeunits/BCSFEnvironmentGuard.Codeunit.al), [BCSFScenarioGuard.Codeunit.al](src/Lifecycle/Codeunits/BCSFScenarioGuard.Codeunit.al), [SECURITY.md](docs/SECURITY.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-004"></a>

### SF-004 — Globale Factory-Einstellungen und Statusgrundlagen

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; Abnahmevermerk aus Altbestand
**Abhängigkeiten:** SF-002,SF-003

- [x] Firmenbezogene Factory-Einrichtung, validierte Defaults/Limits, stabile Enumwerte und Statusregeln vorhanden.
- [ ] Native ungültige Werte/Statusübergänge prüfen. Altbestand enthält bereits eine explizite Abnahmecheckbox, aber gleichzeitig offene Akzeptanz und Status Zur Prüfung; Datum/Umfang des Nachweises zu prüfen.

**Belege:** [BCSFFactorySetup.Table.al](src/Core/Tables/BCSFFactorySetup.Table.al), [BCSFRunStateMgt.Codeunit.al](src/Core/Codeunits/BCSFRunStateMgt.Codeunit.al).
**Abnahme:** [x] Expliziter Vermerk aus dem Altbestand übernommen; widersprüchlichen Umfang vor einem Statuswechsel klären.

<a name="sf-005"></a>

### SF-005 — Szenariovorlagen und versionierte Run-Snapshots

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-004

- [x] Vorlagen, Revision, Kopieren und atomare unveränderliche Laufköpfe/JSON-Snapshots implementiert; eingefrorene Ziele/Module unabhängig von späteren Vorlagenänderungen lesbar.
- [ ] Kopie, parallele Änderungen, historische Rekonstruktion und Änderungs-/Löschschutz in BC prüfen.

**Belege:** [BCSFSnapshotWriter.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFSnapshotWriter.Codeunit.al), [BCSFScenarioManager.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-006"></a>

### SF-006 — Entitätsmengen, Quoten und Prozessmodi konfigurieren

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-005

- [x] Entitätsziele, vier Prozessstufen, Mengenpresets und Dezimalquoten validiert; Angebote bleiben ungebucht, Teilquoten nur Aufträge/Bestellungen.
- [x] Normalweg verwendet Branchenpaket/Größe; technische Einzelmengen bleiben Expertenkonfiguration.
- [ ] Native Mengen-/Quoten-/Scopewechsel und Grenzen gegen gespeicherte Ziele sowie tatsächliche Belege abgleichen.

**Belege:** [BCSFScenarioPolicy.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFScenarioPolicy.Codeunit.al), [BCSFProcessCoordinator.Codeunit.al](src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-007"></a>

### SF-007 — Generator-Vertrag und Registry definieren

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; öffentliche API bleibt SF-034
**Abhängigkeiten:** SF-002,SF-004

- [x] Internes Generatorinterface, Enum-Bindungen, Capabilityprüfung und zwei lesende Vertragsproben vorhanden; echte Planung schließt Proben aus.
- [x] Echte Customer-, Vendor-, Item-, Verkaufs- und Einkaufsbeleggeneratoren sind registriert.
- [ ] Native Registry-/Versions-/Mehrdeutigkeitsfehler prüfen; keine öffentliche Drittanbieter-API behaupten.

**Belege:** [BCSFGenerator.Interface.al](src/ModuleRegistry/Interfaces/BCSFGenerator.Interface.al), [BCSFGeneratorRegistryMgt.Codeunit.al](src/ModuleRegistry/Codeunits/BCSFGeneratorRegistryMgt.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-008"></a>

### SF-008 — Abhängigkeitsgraph und Ausführungsplan

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-006,SF-007

- [x] Snapshotbasierter Abhängigkeitsgraph, topologische Sortierung, Konflikt-/Zyklenerkennung und feste Steps vorhanden; Einkauf vor gebuchten Verkäufen eingeordnet.
- [ ] Native fehlende Vorgänger, Zyklen, nicht unterstützte Modi und blockierenden Start nachweisen.

**Belege:** [BCSFDependencyPlanner.Codeunit.al](src/DependencyManager/Codeunits/BCSFDependencyPlanner.Codeunit.al), [BCSFGraphSorter.Codeunit.al](src/DependencyManager/Codeunits/BCSFGraphSorter.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-009"></a>

### SF-009 — BC-Setup-Prüfung und nicht-destruktiver Setup-Diff

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-003,SF-008

- [x] Lesender Setup-Diff mit konkreten Befunden und erneutem Start-/Hintergrundcheck vorhanden; Änderungen laufen gesondert über bestätigte Unternehmensinitialisierung.
- [ ] Native unvollständige/mehrdeutige Einrichtung und Rechtekonflikte ohne abhängige Datenanlage prüfen.

**Belege:** [BCSFSetupManager.Codeunit.al](src/SetupManager/Codeunits/BCSFSetupManager.Codeunit.al), [SETUP_SEED.md](docs/SETUP_SEED.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-010"></a>

### SF-010 — Synthetischer Realismus und Seed-Engine

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-004,SF-006

- [x] Versionierte Seed-Engine, getrennte Feldstreams, DE/EN-Kataloge und eingefrorene Syntheseregeln vorhanden; Datumszeitraum ergänzt über SF-022/1.0.7.3.
- [ ] Fachliche Verteilung/Reproduzierbarkeit mit unterschiedlichen Seeds und größeren tatsächlichen Datenmengen abnehmen.

**Belege:** [BCSFSeedEngine.Codeunit.al](src/DataGeneration/Codeunits/BCSFSeedEngine.Codeunit.al), [BCSFSyntheticRules.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFSyntheticRules.Codeunit.al), [SETUP_SEED.md](docs/SETUP_SEED.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-011"></a>

### SF-011 — Erzeugte Datensätze und Belegketten nachverfolgen

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-005,SF-010

- [x] Unveränderliche logische/physische Herkunft mit SystemId, Batch, Elternbezug und Konfliktschutz implementiert; reale Standardbelege und Buchungsposten registriert.
- [ ] Native Duplikat-/Fremdzuordnungsfälle, umbenannte/gelöschte Identitäten und Buchungsketten abgleichen.

**Belege:** [BCSFRecordRegistry.Codeunit.al](src/DataGeneration/Codeunits/BCSFRecordRegistry.Codeunit.al), [BCSFProvenanceGuard.Codeunit.al](src/Lifecycle/Codeunits/BCSFProvenanceGuard.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-012"></a>

### SF-012 — Job-Queue Dispatcher, Run-/Batch-Tabellen

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-003,SF-005,SF-008,SF-011

- [x] Dispatcher, Worker, atomarer Fachteil, feste Batchbereiche, Job-/Sitzungsbindung und persistente Fortschrittswerte vorhanden; Standardjob-Autoretry 0.
- [ ] Mehrpaketlauf nach Schließen des Browsers, Scheduling, Rechte und konkurrierende Worker in BC prüfen.

**Belege:** [BCSFQueueDispatcher.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFQueueDispatcher.Codeunit.al), [BCSFBatchWorker.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFBatchWorker.Codeunit.al), [EXECUTION_REGISTRY.md](docs/EXECUTION_REGISTRY.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-013"></a>

### SF-013 — Batch-Checkpoint, Retry, Pause/Resume, Cancellation

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; Wiederholung bewusst begrenzt
**Abhängigkeiten:** SF-012

- [x] Immutable Checkpoints, Stop/Pause/Abbruch an Paketgrenzen, begrenzter Retry nie übernommener Fehler und rein nachweisender Abgleich vorhanden; unsichere Arbeit bleibt NeedsReview.
- [ ] Echte Unterbrechungs-/Parallelitäts-/Retry-/Postingfehler testen; kein allgemeines Replay unklarer Buchungen freigeben.

**Belege:** [BCSFBatchRecovery.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFBatchRecovery.Codeunit.al), [RECOVERY.md](docs/RECOVERY.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-014"></a>

### SF-014 — Monitoring-Datenmodell und Dashboard

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; UI-Ausbau SF-041/SF-044/SF-045
**Abhängigkeiten:** SF-012,SF-013

- [x] Gemeinsames Dashboard-Control-Add-in/CardPart, eigenes Role-Center/Profil, Lauf-/Step-/Batchfortschritt, Qualitätsstatus, Fehlernavigation und Drilldowns vorhanden.
- [ ] Native Rolle/Navigation und Einbettung derselben CardPart in ein weiteres freigegebenes Role-Center prüfen. Reale Filter-/Rechteabnahme gemeinsam mit SF-041.

**Belege:** [BCSFDashboardPart.Page.al](src/Monitoring/Pages/BCSFDashboardPart.Page.al), [BCSFFactoryRoleCenter.Page.al](src/Monitoring/Pages/BCSFFactoryRoleCenter.Page.al), [DASHBOARD_EMBEDDING.md](docs/DASHBOARD_EMBEDDING.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-015"></a>

### SF-015 — Wizard für Branche, Module, Umfang und Planung

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Früherer Wizard ersetzt durch bestehenden Unternehmensassistenten
**Abhängigkeiten:** SF-006,SF-008,SF-009,SF-014

- [x] Geführte Auswahl in bestehender Setupkarte: Kontenplan → Großhandel → Module → Größe → Prozess/Datum → Zusammenfassung/Start; Freigaben und Preflight wiederverwendet.
- [ ] Native Tastatur/Tooltips, Abbrechen, Rücknavigation, Datumseingabe und blockierenden Start prüfen.

**Belege:** [BCSFFactorySetupCard.Page.al](src/Core/Pages/BCSFFactorySetupCard.Page.al), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-016"></a>

### SF-016 — Validierungsframework und Abschlussstatus

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-007,SF-011,SF-012

- [x] Pflicht-/Warnungsbefunde, Mengen-/Herkunfts-/Beziehungs-/Postenprüfung und Gesamtqualität implementiert; Completed erst nach FinalizeRun.
- [ ] Fehlende Ergebnisse/Posten und Mengenabweichungen gezielt in BC prüfen; Pflichtfehler darf keinen erfolgreichen Laufabschluss liefern.

**Belege:** [BCSFRunQuality.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFRunQuality.Codeunit.al), [BCSFValidationManager.Codeunit.al](src/Validation/Codeunits/BCSFValidationManager.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-017"></a>

### SF-017 — Finanzsetup und auswertbare Testkontenpläne für SKR03 und SKR04

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Umgesetzt; gemeinsamer Finanzpfad
**Abhängigkeiten:** SF-009, SF-010

- [x] Vorhandene Einrichtung oder lokale versionierte SKR03-/SKR04-Testpakete, Kontenrollen/Buchungsmatrizen, Bilanz/GuV und begrenzte BWA vorhanden.
- [x] Fachgeneratoren verwenden Paketgruppen und tatsächliche BC-Zuordnungen; frühere offene Integration SF-018–SF-022 ist im unterstützten Umfang vorhanden.
- [x] Finance-Auswahl einmalig in der Einrichtung; frühere separate Vorschauseite ist durch SF-043/SF-045 ersetzt.
- [ ] Je frische SKR03-/SKR04-Firma, Wiederholbarkeit, bestehende Einrichtung, Konflikt/Rollback sowie Einkaufs-/Verkaufs-/manuelle Sachkontenbuchung und Berichtssummen nativ abnehmen.

**Belege:** [BCSFFinancePackageMgt.Codeunit.al](src/Finance/Codeunits/BCSFFinancePackageMgt.Codeunit.al), [VALIDATION_FINANCE.md](docs/VALIDATION_FINANCE.md), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-018"></a>

### SF-018 — Debitoren und Kreditoren als kohärente Stammdaten

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Umgesetzt
**Abhängigkeiten:** SF-010,SF-011,SF-017

- [x] Ausführbare Debitoren-/Kreditorengeneratoren mit Standardvalidierung/Nummernserien, Klassen-/Adresswerten, Kindadressen, Herkunft und Prüfungen vorhanden.
- [ ] Tatsächliche B2B/B2C-, Adress-, Mengen-/Beziehungs-, Rechte- und Wiederanlauffälle abnehmen; Plausibilitätsprüfung gemeinsam mit SF-039.

**Belege:** [BCSFCustomerGenerator.Codeunit.al](src/Sales/Codeunits/BCSFCustomerGenerator.Codeunit.al), [BCSFVendorGenerator.Codeunit.al](src/Purchasing/Codeunits/BCSFVendorGenerator.Codeunit.al), [PARTNER_GENERATION.md](docs/PARTNER_GENERATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-019"></a>

### SF-019 — Artikel, Kategorien, Varianten und Lagerbasics

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Umgesetzt im bestätigten Stammdatenumfang
**Abhängigkeiten:** SF-009,SF-010,SF-017, SF-042

- [x] Artikel/Kategorien/Merkmale, Einheiten, ausgewählte Varianten/Referenzen/Bezugsquellen, Ersatzpaar, SKU und optionale fixe Lagerplätze vorhanden; Item-Vendor-Schlüssel korrigiert.
- [x] Reiner Artikelstammdatenlauf erzeugt keinen Anfangsbestand; Beschaffung/Bestand durch Standardbuchung gehört SF-020.
- [ ] Korrigierte TECH-TRADE-/TECH-BINS-Referenzen, Standardbelegnutzung, Rechte und Wiederanlauf nativ prüfen; keine pauschale Unterstützung aller Artikeltypen behaupten.

**Belege:** [BCSFInventoryGenerator.Codeunit.al](src/Inventory/Codeunits/BCSFInventoryGenerator.Codeunit.al), [BCSFItemRelations.Codeunit.al](src/Inventory/Codeunits/BCSFItemRelations.Codeunit.al), [INVENTORY_GENERATION.md](docs/INVENTORY_GENERATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-020"></a>

### SF-020 — Einkaufsprozess: Bestellung bis gebuchte Rechnung

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Bestellung/Eingang/Rechnung umgesetzt; Gutschriften SF-022
**Abhängigkeiten:** SF-018,SF-019,SF-013

- [x] Ungebuchte Bestellungen, volle/halbe Eingänge mit Rechnung und offenem Rest via Purch.-Post, Same-run-Lieferant/Artikel, Bestandsdeckung und Standardpostenherkunft vorhanden.
- [x] Direkte/indirekte effektive Buchungsrechte geprüft; Datumsregel berücksichtigt erste abhängige Verkäufe.
- [ ] Native Lieferanten-/Artikel-/Beleg-/Postenketten, Mischquoten, Rechte, Fehler/Rollback und Wiederanlauf abnehmen. Einkaufs-Gutschriften/Retouren verbleiben als einziger Ausbaupunkt in SF-022.

**Belege:** [BCSFPurchaseGenerator.Codeunit.al](src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al), [BCSFPurchaseEvidence.Codeunit.al](src/Purchasing/Codeunits/BCSFPurchaseEvidence.Codeunit.al), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-021"></a>

### SF-021 — Verkaufsprozess: Angebot bis gebuchte Rechnung

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Umgesetzt; Übersicht korrigiert
**Abhängigkeiten:** SF-018, SF-019, SF-020 (im aktuellen Quellstand vorhanden; native Abnahme offen)

- [x] Angebote, Standard-Angebotsumwandlung, Aufträge/direkte Rechnungen, ganze/halbe Lieferung/Faktura und Postenherkunft implementiert.
- [x] Same-run-Stämme und vorgelagerte gebuchte Beschaffung sind im Unternehmenspaket vorhanden; alte Quelllaufauswahl/fehlender Einkauf sind keine neuen Aufgaben.
- [x] Starter-/Scope-/Dezimalquoten-/Entfernen-/Archivschutz und datierter Bestandscheck vorhanden.
- [ ] Native Preise/Dimensionen/Bestände, ungebuchte und gemischt gebuchte Belege, konkurrierender Verbrauch, Rechte und Fehler-/Wiederanlauf prüfen.

**Belege:** [BCSFSalesDocuments.Codeunit.al](src/Sales/Codeunits/BCSFSalesDocuments.Codeunit.al), [BCSFSalesGenerator.Codeunit.al](src/Sales/Codeunits/BCSFSalesGenerator.Codeunit.al), [SALES_PROCESS.md](docs/SALES_PROCESS.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-022"></a>

### SF-022 — Zahlungen, Ausgleich, Gutschriften und Folgeprozesse

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Teilumfang umgesetzt; fachlicher Ausbau offen
**Abhängigkeiten:** SF-020,SF-021

- [x] Vollständige Debitoren-/Kreditorenzahlung und Ausgleich tatsächlich gebuchter Rechnungen via Standardjournal mit synthetischer Bank ohne Übermittlung implementiert.
- [x] Nachauftrag 1.0.7.2: erforderliche Branchenmodule plus optionale Planungsmarkierungen in Workflow/Request/Snapshot/Dashboard; keine Ziele für unfertige Module.
- [x] Nachauftrag 1.0.7.3: validiertes Startdatum bis gestern, eingefrorener Zeitraum, reproduzierbare Beleg-/Buchungs-/Zahlungsdaten und geschützte Altrequests/Captures implementiert.
- [ ] Teilzahlungen sowie Einkaufs-/Verkaufsgutschriften und Retouren fachlich spezifizieren und nach eigener Auswahl implementieren; keine vollständige SF-022-Erfüllung behaupten.
- [ ] Native Restbeträge, Ausgleich, Zahlungsrabatte, DE/EN-Modulauswahl, Datumsgrenzen/Arbeitsdatum/Tageswechsel, Buchungs-/Lagerperioden, Rechte und Altstand-Upgrade prüfen.

**Belege:** [BCSFPaymentProcessor.Codeunit.al](src/Finance/Codeunits/BCSFPaymentProcessor.Codeunit.al), [BCSFProcessCoordinator.Codeunit.al](src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-023"></a>

### SF-023 — Großhandel als erstes Branchenprofil

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Großhandel umgesetzt; ursprüngliche Profilbreite teilweise offen
**Abhängigkeiten:** SF-007,SF-010,SF-017,SF-021

- [x] Versioniertes Großhandelspaket mit Größen/Mengen, verbundenen Stämmen/Belegen, vier Prozessstufen, Pflicht-/Planungsmodulen und vier Referenzstartern vorhanden; gemeinsame Generatoren wiederverwendet.
- [ ] Native kleine Demo und mittleren Funktionstest mit plausiblen Beziehungen/Belegmix abnehmen.
- [ ] Ursprünglich gewünschte frei konfigurierbare B2B/B2C-, Preis-/Mengensegmente und Demo/Training/Functional/Performance im Branchenpaket gegen den festen B2B-Referenzumfang konkretisieren; nicht pauschal als vollständig umgesetzt abhaken. Kein neuer Profil-Editor allein wegen alter Planobjekte.

**Belege:** [BCSFWholesaleProfile.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al), [BCSFStarterCatalog.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-024"></a>

### SF-024 — End-to-End-MVP und fachliche Qualitätsgate

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Technischer Pfad vorhanden; E2E-Abnahme offen
**Abhängigkeiten:** SF-014,SF-015,SF-016,SF-022,SF-023, SF-042

- [x] Gemeinsame Foundation → Partner → Artikel → Beschaffung → Verkauf → optional Zahlung → Qualitätsabschluss ist im Code zusammengeführt.
- [ ] Kleine Demo und mittleren Funktionstest nativ protokollieren: tatsächliche Belege/Posten/Mengen, Berichte, Dashboard und Datenrealismus. SF-042-Nachweise wiederverwenden und um vorhandene Fachprozesse erweitern.

**Belege:** [BCSFCompanyInitialization.Codeunit.al](src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al), [BCSFRunQuality.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFRunQuality.Codeunit.al), [TESTANLEITUNG.md](docs/review/TESTANLEITUNG.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-025"></a>

### SF-025 — AL-Test-App und fachliche Regressionssuite

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Test-App vorhanden; Ausführung und Abdeckung offen
**Abhängigkeiten:** SF-001,SF-016,SF-024

- [x] Separate Test-App 1.3.0.3 mit 48 Methoden vorhanden, referenziert Main-App 1.0.7.3; Main-App enthält keine Test-Dependency.
- [x] Buildskript, deterministische Fixtures, bestehende negative/native Referenzmethoden und dokumentierte Laufvoraussetzungen vorhanden; Tests sind kompiliert.
- [ ] AL-Tests tatsächlich im BC-Runner ausführen, Fixtures/Ergebnisse festhalten und Lücken zu Kernfehlern, Finance, Berechtigungen, Recovery, Datenrealismus und Dashboard-Standardlisten konkret schließen. Kein zweites Testprojekt anlegen.

**Belege:** [app.json](tests/SF019/app.json), [BCSFInventoryTests.Codeunit.al](tests/SF019/BCSFInventoryTests.Codeunit.al), [build_sf019.py](scripts/build_sf019.py), [TESTS.md](docs/TESTS.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-026"></a>

### SF-026 — Lasttests, Durchsatzmessung, große Datenmengen

**Status:** Offen · **Priorität:** P1
**Einordnung:** Benchmarks fehlen
**Abhängigkeiten:** SF-024,SF-025

- [x] Mengenlimits, drei Unternehmensgrößen und Batching sind als Grundlage vorhanden; dies belegt keinen Durchsatz.
- [ ] Reale 1k-/10k-/50k-/100k-Fälle je geeigneter Entität mit Erstellungs-/Buchungsraten, Queuewartezeit, Fehlern und Batchgrößen messen; dokumentierte Engpässe statt Laufzeitversprechen.

**Belege:** [BCSFQueueDispatcher.Codeunit.al](src/BackgroundProcessing/Codeunits/BCSFQueueDispatcher.Codeunit.al), [BCSFWholesaleProfile.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-027"></a>

### SF-027 — Sicheres Lauf-Lifecycle, Retention und Reset

**Status:** Offen · **Priorität:** P1
**Einordnung:** Vorlagenschutz vorhanden; Lauf-Retention/Reset fehlen
**Abhängigkeiten:** SF-003,SF-011,SF-024

- [x] Sichere Vorlagenlöschung/Archivierung samt Entfernt-Vermerk ist über SF-037 vorhanden; kein Ersatz für Lauf-/Fachdaten-Retention.
- [ ] Laufaufbewahrung/-archivierung, Neufirmen-/Resetpfad und ggf. ausdrücklich bestätigte Bereinigung ungebuchter eigener Daten implementieren; Nachweis ohne Fremddatenlöschung. Keine pauschalen Deletes gebuchter Posten.

**Belege:** [BCSFScenarioManager.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al), [Lifecycle.md](docs/modules/details/src/Lifecycle.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-028"></a>

### SF-028 — Warehouse-Prozessgenerator

**Status:** Offen · **Priorität:** P2
**Einordnung:** Kein Warehouse-Generator
**Abhängigkeiten:** SF-024

- [x] Einfache Lagerorte/optionale feste Lagerplätze im Artikelumfang vorhanden; kein logistischer Prozessgenerator.
- [ ] Warehouse-Setup/Referenzstämme und aktivierte Standortfunktionen prüfen; Ein-/Auslagerung, Kommissionierung, Umlagerungen über Standardprozesse mit Bestandsabgleich und Dashboard integrieren.

**Belege:** [Warehouse.md](docs/modules/details/src/Warehouse.md), [BCSFItemSetup.Codeunit.al](src/Inventory/Codeunits/BCSFItemSetup.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-029"></a>

### SF-029 — Manufacturing- und Assembly-Generator

**Status:** Offen · **Priorität:** P2
**Einordnung:** Keine Fertigungs-/Montagegeneratoren
**Abhängigkeiten:** SF-024

- [ ] Stücklisten, Arbeitspläne, Arbeitsplätze/Kapazitäten und Komponentenstämme sowie Lizenz/Features konkretisieren; Fertigung/Montage getrennt über Standardverbrauch/Output und Dashboard abnehmen.

**Belege:** [Manufacturing.md](docs/modules/details/src/Manufacturing.md), [Assembly.md](docs/modules/details/src/Assembly.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-030"></a>

### SF-030 — Projects- und ServiceManagement-Generator

**Status:** Offen · **Priorität:** P2
**Einordnung:** Keine Projekt-/Servicegeneratoren
**Abhängigkeiten:** SF-024

- [ ] Projektaufgaben/Ressourcen/Zeiten/Abrechnung sowie Serviceartikel/Wartung/Ersatzteile konkretisieren; zwei Ende-zu-Ende-Fälle mit Standardposten und jeweiligen Drilldowns umsetzen/abnehmen.

**Belege:** [Projects.md](docs/modules/details/src/Projects.md), [ServiceManagement.md](docs/modules/details/src/ServiceManagement.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-031"></a>

### SF-031 — Anlagen und Abschreibungsfälle

**Status:** Offen · **Priorität:** P2
**Einordnung:** Kein Anlagengenerator
**Abhängigkeiten:** SF-024

- [ ] Anlagenklassen/-buchungsgruppen/-bücher vor Anschaffung, Abschreibung und Abgang prüfen; konsistente Standard-Anlagenposten und Dashboardanbindung umsetzen/abnehmen.

**Belege:** [FixedAssets.md](docs/modules/details/src/FixedAssets.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-032"></a>

### SF-032 — Weitere Profile: E-Commerce, Fertigung, Dienstleistung, Bau, Logistik, Wartung

**Status:** Offen · **Priorität:** P2
**Einordnung:** Weitere Unternehmensbranchen fehlen
**Abhängigkeiten:** SF-028,SF-029,SF-030

- [x] Weitere Branchenbezeichnungen/Planungsvorlagen und generische Syntheseregeln existieren; im normalen Unternehmensassistenten ist nur Großhandel unterstützt.
- [ ] E-Commerce, Fertigung, Dienstleistung, Bau, Logistik und Wartung einzeln fachlich spezifizieren, vorhandene Generatoren konfigurieren und je Profil ein validiertes Szenario nachweisen; gleiche Initialisierung verwenden.

**Belege:** [BCSFStarterCatalog.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al), [IndustryProfiles.md](docs/modules/details/src/IndustryProfiles.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-033"></a>

### SF-033 — CRM/Relationship- und Planning-Generatoren

**Status:** Offen · **Priorität:** P3
**Einordnung:** Keine CRM-/Planungsgeneratoren
**Abhängigkeiten:** SF-024

- [x] Abgeleitete Standardkontakte aus Partneranlage und optionale Planungsmarkierungen sind vorhanden; keine eigenständige CRM-/Dispositionserzeugung.
- [ ] Kampagnen/Opportunities/Beziehungen sowie Nachfrage-/Beschaffungsplanung mit verfügbaren Standardmodulen, Referenzen, Rechten und nachvollziehbaren Fällen umsetzen/abnehmen.

**Belege:** [CRM.md](docs/modules/details/src/CRM.md), [Planning.md](docs/modules/details/src/Planning.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-034"></a>

### SF-034 — Öffentliche Generator-Erweiterungs-API

**Status:** Offen · **Priorität:** P3
**Einordnung:** Internes Interface vorhanden; öffentliches SDK fehlt
**Abhängigkeiten:** SF-007,SF-025, SF-042

- [x] Internes Interface und eigene Fachmodulbindungen aus SF-007 werden bereits verwendet.
- [ ] Öffentliche versionierte Erweiterungsverträge, Profile/Validierung, Rechte und Beispiel-Extension entwerfen und über dieselbe Orchestrierung nativ nachweisen. Access = Internal erfüllt kein öffentliches SDK.

**Belege:** [BCSFGenerator.Interface.al](src/ModuleRegistry/Interfaces/BCSFGenerator.Interface.al), [ModuleRegistry.md](docs/modules/details/src/ModuleRegistry.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-035"></a>

### SF-035 — Schulungsfälle, Aufgaben und Erfolgskontrollen

**Status:** Offen · **Priorität:** P3
**Einordnung:** Trainingsvorlagen vorhanden; Aufgaben-/Erfolgskontrollen fehlen
**Abhängigkeiten:** SF-024

- [x] Nutzungsmodus Training und Startervorlagen sind vorhanden; keine vollständigen Lernziele/Rollen/Aufgabenprüfungen.
- [ ] Reproduzierbare Schulungsfälle mit Rollen, Lernzielen, Aufgaben und Ist-/Soll-Erfolgskontrollen umsetzen/abnehmen; keine echten Mitarbeiterkonten ohne Auftrag.

**Belege:** [BCSFUsageMode.Enum.al](src/Core/Enums/BCSFUsageMode.Enum.al), [BCSFStarterCatalog.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-036"></a>

### SF-036 — Release, AppSource-/PTE-Eignung und Dokumentation

**Status:** Offen · **Priorität:** P3
**Einordnung:** Lokale Pakete vorhanden; Releasefreigabe fehlt
**Abhängigkeiten:** SF-025,SF-027,SF-034

- [x] Lokale Build-/Paket-/Sprachprüfungen und Reviewartefakte vorhanden; keine Release-/AppSource-/PTE-Abnahme daraus ableiten.
- [ ] Publisher/Lizenz/Releaseziel, Produktgrenzen, Berechtigungen, datensparsame Telemetrie, Hilfelinks und Zielversions-/Upgrade-/Testmatrix vor freigegebener Bereitstellung prüfen; Restkonfiguration mit SF-001.

**Belege:** [app.json](app.json), [check_package.py](scripts/check_package.py), [SECURITY.md](docs/SECURITY.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-037"></a>

### SF-037 — Reparatur Vorlage → Start → Ergebnis (Nutzerauftrag 18.11.2026)

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; Normalnavigation durch SF-045 ersetzt
**Abhängigkeiten:** Bestehende Foundation; ursprünglicher Detailumfang im Archiv

- [x] Starterladen, Sammelimport/-export, Namenlokalisierung, sicheres Entfernen/Archivieren und Fehler-/Ergebnisnavigation implementiert; ursprünglicher Partnerlauf laut Nutzer wieder funktionsfähig.
- [ ] Quellbefund: `RestoreStarters()` behandelt bisherige Branchen-/Artikel-/Verkaufsstarter, aber nicht die vier Großhandels-IDs `{B55C4500-AB51-4045-9C00-000000000001}` bis `...0004`. Explizites Wiederherstellen nach Entfernen/Archivieren für diese Familie ergänzen und prüfen; normales Laden muss sie weiter schützen.
- [ ] 5/5-/12/7-Partnerfall, negativer Setupfall, firmenübergreifender Transfer, DE/EN, erneutes Laden nach Entfernen/Archivierung und Queue-/Parallelitätsfehler nativ abnehmen. Ursprüngliche konkrete Fehlerursache ohne Erstprotokoll bleibt Zu prüfen.

**Belege:** [BCSFScenarioTransfer.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFScenarioTransfer.Codeunit.al), [BCSFScenarioManager.Codeunit.al](src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al), [STARTER_TEMPLATES.md](docs/STARTER_TEMPLATES.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-038"></a>

### SF-038 — Realistische Kontenpläne und vollständige Buchungseinrichtung im Starterpfad

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; Finanzbasis gemeinsam mit SF-017
**Abhängigkeiten:** SF-009, SF-017, SF-037

- [x] Gemeinsamer Paketpfad ohne Zwei-Konten-Fallback, echte Kontenrollen/Matrizen, Konfliktprüfung und operationsbezogene Rechte vorhanden; aktuelle lokale Pakete 3.0.0 mit begrenzter BWA.
- [ ] Frische SKR03-/SKR04-/vorhandene Firma, Wiederholung, Konflikte, Standardrechte und Buchungs-/Berichtssummen abnehmen; dieselben Finanzfälle für SF-017 wiederverwenden.

**Belege:** [BCSFFinancePackageMgt.Codeunit.al](src/Finance/Codeunits/BCSFFinancePackageMgt.Codeunit.al), [STABILIZATION_FINANCE_PARTNERS.md](docs/STABILIZATION_FINANCE_PARTNERS.md), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-039"></a>

### SF-039 — Realistische Geschäftspartner und nutzbare Partnerstammdaten

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Partnerqualität umgesetzt; Partnerbankstämme offen
**Abhängigkeiten:** SF-010, SF-011, SF-018, SF-038

- [x] Natürliche DE/EN-Partnerkataloge, konsistente synthetische Adressen/reservierte E-Mails, Ansprechpartner, Liefer-/Bestelladressen und konfigurierbare Fachzuordnungen implementiert.
- [x] Parent-/Child-Herkunft und deterministische Werte vorhanden; BCSF-PAY aus SF-022 ist eine synthetische Firmenbank, keine Debitoren-/Kreditorenbankverbindung.
- [ ] Sichere synthetische Partnerbankstämme/Präferenzen und deren fachlichen Bedarf konkretisieren; bisherigen offenen Umfang nicht mit Firmenverrechnungsbank abhaken.
- [ ] Gemischte DE-Läufe mindestens 50/50 sowie EN, Plausibilität/Variation/Seed, Adress-/Banknutzung in Standardbelegen und Kinddaten-/Fehler-/Wiederanlauf nativ prüfen.

**Belege:** [BCSFPartnerCatalog.Codeunit.al](src/DataGeneration/Codeunits/BCSFPartnerCatalog.Codeunit.al), [BCSFPartnerChildren.Codeunit.al](src/DataGeneration/Codeunits/BCSFPartnerChildren.Codeunit.al), [STABILIZATION_FINANCE_PARTNERS.md](docs/STABILIZATION_FINANCE_PARTNERS.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-040"></a>

### SF-040 — Vollständige Stammdatenbasis vor Belegen und Bewegungsdaten

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Prüfstruktur für vorhandene Generatoren umgesetzt
**Abhängigkeiten:** SF-007, SF-008, SF-009, SF-016, SF-038, SF-039, SF-043

- [x] Modul-/Entitätsmatrix, lesende Startbereitschaft, konkrete Generatorvoraussetzungen und Prüfung im Hintergrund vor abhängigen Daten vorhanden; heutiger Umfang umfasst auch Artikel und Belege.
- [ ] Erfolgs-/Blockerfälle für tatsächliche Partner-/Artikel-/Belegkombinationen nativ prüfen; optionale fehlende Stämme dürfen unbetroffene Stammdatenläufe nicht blockieren. Voraussetzungen späterer Module bleiben Teil ihres Tickets.

**Belege:** [BCSFSetupManager.Codeunit.al](src/SetupManager/Codeunits/BCSFSetupManager.Codeunit.al), [MASTER_DATA_READINESS.md](docs/MASTER_DATA_READINESS.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-041"></a>

### SF-041 — Dashboard mit Datenbestand, Modulbereichen und prüfbaren Drilldowns

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; native Filter-/Rechteabnahme offen
**Abhängigkeiten:** SF-011, SF-014, SF-037

- [x] Mandanten-/Erzeugt-/Laufumfang, Gruppen für Stämme/Verkauf/Einkauf/Posten und weitere Module, SystemId-basierte Livewerte und berechtigte passende Standardlistenrouten vorhanden.
- [x] Frühere 150er-Grenze für Herkunftskennzahlen in 1.0.7.1 entfernt; Mappingliste und eindeutige Einkaufs-/Verkaufsrouten vorhanden.
- [ ] Manuelle Daten plus zwei Läufe, native Count/Drilldown-Übereinstimmung, Rollen/Securityfilter, gelöschte Ergebnisse und leere Ziele abnehmen; echte Ladezeiten/Speicher in SF-026 messen.

**Belege:** [BCSFDashboardStock.Codeunit.al](src/Monitoring/Codeunits/BCSFDashboardStock.Codeunit.al), [BCSFAttributeAssignments.Page.al](src/Monitoring/Pages/BCSFAttributeAssignments.Page.al), [DASHBOARD_DATA_STOCK.md](docs/DASHBOARD_DATA_STOCK.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-042"></a>

### SF-042 — Partnerpfad stabilisieren, Bedienung polieren und Ausbau freigeben

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Regeln/Bedienung vorhanden; P0-Abnahme offen
**Abhängigkeiten:** SF-037, SF-038, SF-039, SF-040, SF-041, SF-043

- [x] Qualitätscheckliste und Nachweisvertrag in AGENTS, Architektur, Tests und Moduldokumentation verankert; Einsteiger-Testanleitung vorhanden.
- [x] Statusabhängige Aktionen, eingeklappte Diagnose, Standardfehlernavigation und bestehender Kernpfad im Code vorhanden; Normalstart heute über SF-045.
- [ ] Zwei unterschiedlich dimensionierte native Partnerläufe ohne manuelle Konten-/Gruppenanlage und nach Browserende nachweisen; SF-038–SF-041, fehlendes Setup/Rechte, kontrollierten Batchfehler und sichere Wiederaufnahme abnehmen.
- [ ] Starter-/Sammeltransfer-/Archiv-/Sprachregression praktisch ausführen; menschliche P0-Freigabe ausdrücklich festhalten. Spätere direkte Nutzeraufträge sind keine rückwirkende P0-Abnahme.

**Belege:** [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](docs/ARCHITECTURE.md), [TESTS.md](docs/TESTS.md#sf-042--soll-ist-prüfung-des-partnerpfads), [TESTANLEITUNG.md](docs/review/TESTANLEITUNG.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-043"></a>

### SF-043 — Mandant einmalig initialisieren und Vorlagenstart vereinfachen

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt; Normalweg durch SF-045 erweitert
**Abhängigkeiten:** SF-038, SF-039

- [x] Einmalige Kontenplan-/Foundationwahl in Einrichtung und direkter technischer Vorlagenstart ohne neue Finanzwahl vorhanden; frühere doppelte Seiten werden nicht neu benötigt.
- [ ] Native frische SKR03-/SKR04-/bestehende Firma und additives Altstand-Upgrade abnehmen; gemeinsame Nachweise aus SF-045 verwenden.

**Belege:** [BCSFCompanyInitialization.Codeunit.al](src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al), [BCSFQuickScenarioRun.Codeunit.al](src/Monitoring/Codeunits/BCSFQuickScenarioRun.Codeunit.al), [COMPANY_INITIALIZATION.md](docs/COMPANY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-044"></a>

### SF-044 — Dashboard kompakt gestalten und Kennzahlen direkt nutzbar machen

**Status:** Zur Prüfung · **Priorität:** P1
**Einordnung:** Umgesetzt; strenger Build inzwischen erfolgreich
**Abhängigkeiten:** SF-041

- [x] Daten-/Laufreiter, responsive klickbare Kacheln, getrennte Filter, Fortschritt an Entitäten, kompakte Aktionen und eingeklappte Diagnose vorhanden; Clientregression dokumentiert.
- [ ] Breite/schmale native BC-Ansicht, Fokus, Scrollen und reale Ziellisten prüfen. Beispiel 25 Mandant/20 Lauf ist ein Clientfixture, kein nativer Datenbeleg.

**Belege:** [dashboard.js](src/Monitoring/Dashboard/dashboard.js), [dashboard.css](src/Monitoring/Dashboard/dashboard.css), [check_dashboard.mjs](scripts/check_dashboard.mjs), [DASHBOARD_DATA_STOCK.md](docs/DASHBOARD_DATA_STOCK.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-045"></a>

### SF-045 — Branchengesteuerte Unternehmensinitialisierung und Architekturvereinfachung

**Status:** Zur Prüfung · **Priorität:** P0
**Einordnung:** Umgesetzt im Großhandelsumfang
**Abhängigkeiten:** Bestehende Foundation, SF-019/SF-021, Queue/Checkpoint/Qualität

- [x] Bestehende Setupkarte, ein atomarer Foundation-/Planstart, Größen Klein/Mittel/Groß, vier Prozessstufen, vorhandene Queue/Monitoring und versionierte Finanzpakete implementiert.
- [x] Standardbeschaffung und Zahlungsausgleich sind inzwischen eingebunden; frühere Buchungsstufensperre ist überholt. Modulauswahl und Datumszeitraum siehe SF-022.
- [ ] Frische SKR03-/SKR04-/vorhandene Firma, reale Mengen/Beziehungen/Standardbelege/Posten/Berichte, Rechte, DE/EN, Browserende, Doppelstart, Batchfehler und Upgrade fachlich abnehmen. Weitere Branchen bleiben SF-032.

**Belege:** [BCSFFactorySetupCard.Page.al](src/Core/Pages/BCSFFactorySetupCard.Page.al), [BCSFCompanyInitialization.Codeunit.al](src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al), [INDUSTRY_INITIALIZATION.md](docs/INDUSTRY_INITIALIZATION.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="al-001"></a>

### AL-001 — Ursprüngliche AL-Agentura-Projektbasis prüfen (historische Ticket-ID)

**Status:** Zur Prüfung · **Einordnung:** Mit SF-001/SF-002 zusammengeführt; kein separater Arbeitsauftrag.

- [x] Manifest, Dateien, Objektzahl und Modulstruktur geprüft; aktuelle Basis steht oben und in [PROJECT.md](docs/PROJECT.md).
- [x] Offene Konfigurations-/Freigabefragen unter [SF-001](#sf-001) gebündelt.

**Historie:** [Ursprünglicher Wortlaut](docs/review/BACKLOG_VOR_ABGLEICH_2026-11-21.md). Keine zusätzliche menschliche Abnahme behauptet.

<a name="sf-046"></a>

### SF-046 — Vollständiges Konfigurationspaket für Generatorergebnisse

**Status:** Zur Prüfung · **Priorität:** P1
**Abhängigkeiten:** SF-011, SF-019, SF-020, SF-021, SF-022, SF-041, SF-045 · **Betroffene Module:** Monitoring, Core (deklarative Ausführungsrechte)

**Ausgangslage/Ziel (korrigiert 1.0.8.1):** Nach ausdrücklicher Aktion in der aktuellen Sandboxfirma ein Standard-Konfigurationspaket mit allen vom aktuellen Generator-/Foundationumfang betroffenen Stamm-, Einrichtungs-, Beleg- und Postentabellen bereitstellen. Nutzer bestätigt vollständige Tabelleninhalte einschließlich vorhandener Fremddaten; keine Lauf-/Herkunftsfilter.

**Scope/Grenzen:** Standard-RapidStart-Anlage und Standarddownload über Konfigurationspakete; Dashboardzugang. Keine Änderung von Geschäftsdaten, Läufen, Generatoren oder Buchungsfreigaben. Postenexport dient der Auswertung, kein unterstützter Wiederimport gebuchter Daten. Nicht implementierte Module sind keine ausführbaren Generatoren.

**Plan/Risiken:** Monitoring-Paketdienst 90371; Install-/Upgrade-Codeunits 90372/90373 seit 1.0.8.1 mit leeren Triggern. Korrektur nach gemeldeter hängender Installation bei über 40 Firmen: umfangreiche Paketfeldanlage aus dem mandantenübergreifenden Installationspfad nehmen; nur explizit in aktueller Firma. Betroffen sind außerdem bestehende Dashboardbefehle/-texte/-JS und Rollencenter, ADMIN-Execute, XLIFF, Objektplan/Modulnachweise. Symbolgeprüfter Tabellenkatalog einschließlich Standardnebenwirkungen. Paketkollisionen abbrechen; vorhandene Filter/Feldauswahl erhalten, nur fehlende Tabellen ergänzen. Standard-Exportgrenzen, effektive Leserechte, Securityfilter, Datenvolumen und gleichzeitige Generierung beachten.

- [x] Paketdienst 90371 und Dashboardzugang implementiert; 1.0.8.1 entfernt automatische Bereitstellung aus Install/Upgrade 90372/90373, Objektidentitäten bleiben erhalten; 128 Tabellen-IDs in docs/CONFIG_EXPORT.md dokumentiert.
- [x] Bestehende Starter gegen den Generatorstand geprüft; Export-Prüffälle für die vorhandenen Prozessstufen in docs/STARTER_TEMPLATES.md ergänzt. Keine neue Generatoroption, eigene Vorlagen unverändert.
- [x] Cloud-Build von Main/Test, CodeCop/UICop, Standard-API-/Katalogverträge, Übersetzungen, Dashboardregression und Paketprüfung bestanden, für 1.0.8.1 erneut ausgeführt; neue Negativkontrollen verhindern Paketarbeit in Install/Upgrade. Vier neue Methoden im vorhandenen Testhost weiterhin nur kompiliert.
- [ ] Native Installation/Upgrade in Umgebung mit über 40 Firmen ohne Paketmutation sowie ausdrückliche Anlage in nur einer Firma, DE/EN, Export, Rechte/Securityfilter, Wiederholung, Fremdpaketkollision und große Mengen prüfen.
- [ ] Menschliche Abnahme; erst danach Erledigt.

**Testprotokoll:** [Tatsächliche lokale Ergebnisse und offene native Fälle](docs/TESTS.md#sf-046--konfigurationspaket-für-vollständige-generator-daten), [Bedienung/Tabellen-IDs](docs/CONFIG_EXPORT.md). App 1.0.8.1, Test-App 1.4.0.1; lokale Korrekturprüfung dokumentiert, keine Veröffentlichung oder BC-Testausführung durch den Agenten.


<a name="Payment Tolerance Management"(CodeUnit 426).DelVendPmtTolAcc line 15 - Base Application by Microsoft version 29.1.57326.58215
"Payment Tolerance Management"(CodeUnit 426).PurchPmtTolGenJnl line 18 - Base Application by Microsoft version 29.1.57326.58215
"Payment Tolerance Management"(CodeUnit 426).PmtTolGenJnl line 26 - Base Application by Microsoft version 29.1.57326.58215
"Gen. Journal Line"(Table 81)."Applies-to Doc. No. - OnValidate"(Trigger) line 97 - Base Application by Microsoft version 29.1.57326.58215
"BCSF Payment Processor"(CodeUnit 90401).Pay line 99 - BC Scenario Factory by Default Publisher version 1.0.8.4
"BCSF Purchase Generator"(CodeUnit 90451).CreateOrder line 129 - BC Scenario Factory by Default Publisher version 1.0.8.4
"BCSF Purchase Generator"(CodeUnit 90451).ExecuteBatch line 20 - BC Scenario Factory by Default Publisher version 1.0.8.4
"BCSF Batch Runner"(CodeUnit 90307).Execute line 51 - BC Scenario Factory by Default Publisher version 1.0.8.4
"BCSF Batch Worker"(CodeUnit 90303).OnRun(Trigger) line 76 - BC Scenario Factory by Default Publisher version 1.0.8.4
"Job Queue Start Codeunit"(CodeUnit 449).OnRun(Trigger) line 18 - Base Application by Microsoft version 29.1.57326.58215
"Job Queue Dispatcher"(CodeUnit 448).HandleRequest line 26 - Base Application by Microsoft version 29.1.57326.58215
"Job Queue Dispatcher"(CodeUnit 448).OnRun(Trigger) line 35 - Base Application by Microsoft version 29.1.57326.58215


"></a>

### SF-047 — Großhandel v6: Artikelverwendung, unterjährige Beschaffung und Standortvielfalt (P1–P3)

**Status:** Zur Prüfung · **Priorität:** P1
**Ausdrücklich beauftragt:** 22.11.2026 · **Abhängigkeiten:** SF-023, SF-024, SF-042, SF-045, Qualitätskorrekturen TRADE/5
**Module:** ProcessEngine, Purchasing, Sales, DataGeneration, Inventory, IndustryProfiles, vorhandene Test-App

**Ausgangslage:** Mittelpaket aus TRADE/5: 400 unterschiedliche Artikel und funktionierende Mehrpositionsbelege, aber nur die ersten 200 Artikel in untersuchten Belegen, gebuchte Einkaufsbelege auf einem Startdatum, 164/200 Debitoren und 41/50 Kreditoren in Berlin/Dortmund. Die gemessene Verteilung bezieht sich auf den Export und ist keine allgemeine Aussage über jeden Seed.

**Ziel:** Künftige, über den gemeinsamen Unternehmensassistenten erzeugte Großhandelsläufe nutzen den ganzen Artikelkatalog als Auswahlraum, verteilen geplante Wareneingänge im Szenariozeitraum und streuen Kunden-/Lieferantenorte nachvollziehbar. Keine zusätzlichen Branchen, BC-Module, Dashboards oder Setupdialoge.

**Umfang und technische Entscheidung:**
- TRADE/6 für *neue* Läufe; TRADE/5-Snapshots bleiben semantisch unverändert. Vorhandenen Katalog, Seed Engine, Item Registry, Einkauf, Verkauf und BC-Standardbuchung weiterverwenden.
- **P1:** `BCSF Sales Setup` lädt TRADE/6-Artikel ohne alte `vendorCount * 4`-Begrenzung. `BCSF Process Coordinator` wählt Artikel auch aus späteren Einkaufsbestellungen; dieselbe Lieferantengruppe pro Einkaufsbeleg bleibt erhalten. Ungebuchte Verkäufe dürfen den gesamten Artikelstamm verwenden; gebuchte Verkäufe bleiben an bestätigte Wareneingänge gebunden. Eine nicht verwendete Artikelnummer ist nicht automatisch ein Fehler.
- **P2:** Deterministische Eingangsdatumsverteilung über Start-/Enddatum. Bei gebuchten Verkaufsbelegen liegt das Belegdatum nicht vor dem geplanten Wareneingang der zugehörigen Artikel. Mengen-/Teileingangslogik bleibt unverändert. Kein Direktinsert in Standard-Postentabellen.
- **P3:** Deterministische 20er-Ortspermutation mit zusammengehörigen Stadt-/PLZ-Paaren für DE/GB; gleichmäßige Zyklen statt pro Datensatz wiederholter Zufallsauswahl. Bestehende synthetische `.invalid`-Kontakte und Namensregeln bleiben.
- **Querschnitt:** Keine neuen UI-Texte, Seiten, Dashboardkennzahlen oder Workflowstufen. Die bestehende Fortschrittsanzeige, Registry und Hintergrundverarbeitung werden weiterverwendet; kein zusätzliches Finanzsetup. Vorhandene DE-/EN-Kataloge bleiben bestehen.

**Bearbeitungs- und Teststand:**
- [x] AL-Änderungen in den bestehenden Objekten umgesetzt (TRADE/6 versioniert, TRADE/5 geschützt).
- [x] Vorhandene Test-Codeunit um drei SF-047-Tests für Sortiment/Bestandsdeckung, zeitliche Reihenfolge und Ortsvielfalt ergänzt; keine neue Test-Codeunit.
- [x] Statische Quelltextkontrolle und unabhängige numerische Simulationsprüfung für kleine/mittlere/große Mengenkonfiguration durchgeführt; Details: [SF047_PRUEFBERICHT.md](docs/review/SF047_PRUEFBERICHT.md).
- [x] Main/Test-App lokal gegen BC-28.5-Symbole kompiliert; strenger Analyzer mit acht vorhandenen AA0018 nicht bestanden. Zahlungskorrekturen 1.0.8.5/1.0.8.6 im Prüfbericht. Native BC-29.1-Ausführung offen.
- [ ] Native Sandboxläufe klein/mittel/groß: SKR03/SKR04, ungebucht/gebucht/teilgebucht, Zeitraum > 1 Tag und 1 Tag, Bestände nach Datum, Mehrpositionsbelege, Queue-Wiederaufnahme/Retry, Idempotenz, Rechte, DE/EN, Dashboard/Export validieren.
- [ ] Menschliche fachliche Abnahme; erst danach **Erledigt**.

**Risiken:** Datumsverschiebung gebuchter Verkäufe kann die Verteilung stärker ans Periodenende verschieben; zusätzliche Artikel-IDs erhöhen JSON-/Vorprüfaufwand. Bei großen Datenmengen Performance in BC messen. Individuelle Artikel ohne Bewegung sind legitim. Bestandsdeckung und Lieferantenzuordnung nativ prüfen.

**Dateien:** `src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al`, `src/Sales/Codeunits/BCSFSalesSetup.Codeunit.al`, `src/DataGeneration/Codeunits/BCSFPartnerCatalog.Codeunit.al`, `src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al`, bestehende v6-fähig gemachte Inventory-Codeunits, `tests/SF019/BCSFInventoryTests.Codeunit.al`, `app.json`.

**Abnahme:** [ ] Menschliche Abnahme offen; Status **Zur Prüfung**.

<a name="sf-048"></a>

### SF-048 — Modulare Szenariogenerierung und unabhängige Geschäftsläufe

**Status:** Zur Prüfung · **Priorität:** P1
**Auftrag:** Nutzeranhang vom 22.11.2026 vollständig gelesen; zuerst SF-047-Zahlungsfehler beheben, danach SF-048 umsetzen. Keine neue Batchengine, kein fremder Datenbestand und keine unsichere Wiederholung.

**Ziel/Scope:** Im bestehenden Unternehmensworkflow Komplett/Stammdaten/Bewegungsdaten wählen. Bewegungsläufe referenzieren eine bestätigte Basis derselben Firma, wählen Einkauf/Verkauf und Belegmengen, erzeugen neue Run-IDs/Belege ohne zusätzliche Stammdaten. Eigenständige Lagerbewegungen bleiben mangels Generator gesperrt. Neue optionale Snapshotbindung mit festen SystemIds statt doppelter Registryeinträge.

**Architektur-/Dateiplan:** Bestehende Setupkarte/Company Initialization und Wholesale Profile erweitern. Additive Generation-Kind-/Source-/Requestfelder, bestehende Szenario-/Snapshot-/Planner-/Generator-/Recoveryverträge nutzen. Gemeinsamer lesender Stammdatenquellendienst, BackgroundProcessing bestätigt abgeschlossene Stammdatenpakete. Sales nutzt vorhandene Identitäts-/Bestandsprüfung; Purchase erhält dieselbe Quellenbindung. Dashboard zeigt gewählten Umfang/Quelle; Texte DE/EN und bestehende Test-App ergänzen.

**Risiken/Prüfweg:** Bestand muss bei Start und Buchung aktuell geprüft werden; nur explizit gewählter Einkauf liefert neue Deckung. Historische Snapshots/Registry und eigene Vorlagen erhalten, keine Source-Parent-Verknüpfung über Rungrenzen. Transaktions-/Claim-/Checkpointschutz erhalten. Lokale Symbole 28.5, gemeldete Sandbox 29.1; Compiler, Quellenregression, Übersetzungen, Pakete lokal prüfen, native Fälle A–G und echte Laufzeiten bleiben zu prüfen.

- [x] Drei Laufarten und bestehende UI erweitern.
- [x] Sichere Quellenbindung, getrennte Module/Mengen und aktuelle Bestandsprüfung implementieren.
- [x] Kompatibilität, Vorlagen, Dashboard, DE/EN und echte lokale Prüfungen dokumentieren.
- [ ] Native Fälle A–G einschließlich unabhängiger zweiter Läufe und negativer Quellen-/Recoveryfälle prüfen.
- [ ] Menschliche Abnahme; höchstens Zur Prüfung bis dahin.

**Ergänzung 22.11.2026 – Wiederverwendung ohne Quelllauf (ausdrücklicher neuer Nutzerauftrag):**
- [x] Null-GUID in Einrichtung und Szenariokonfiguration als Auswahl „geeignete vorhandene Mandantenstammdaten“ behandeln, nicht als fehlenden Pflichtquelllauf.
- [x] Lesenden, deterministisch eingefrorenen Pool mit SystemIds aus geeigneten Debitoren, Kreditoren und Lagerartikeln bilden. Mindestens zwei geeignete Hauptlieferanten mit je vier Artikeln sind für die bisherige Großhandels-Beleglogik notwendig.
- [x] Einkaufs- und Verkaufsauflösung für den Pool ohne neue Stammdatenregistrierung erweitern; frühere explizite Factory-Quellen unverändert lassen.
- [x] Setup-, Dashboard- und Tooltip-Texte sowie SF-048-Übersetzungsmapping anpassen.
- [ ] **Offen:** Allgemeine Fortsetzung nach *einzelnen Buchungsfehlern* benötigt einen ausdrücklich konzipierten isolierten Buchungsversuch mit nachgewiesenem Rollback und Recovery; keine Fehler verschlucken und keine bestehende Commit-Sperre entfernen.
- [ ] **Offen:** AL-Compiler, Standard-Sandbox, alle Buchungs-/Bestandsszenarien und deutsche XLF-Regenerierung nach Build nativ prüfen. Der Patch ist nicht als vollständige Abnahme freigegeben.

**Nachweise/Dateien:** [SF-048-Prüfbericht](docs/review/SF048_PRUEFBERICHT.md), [Vertrag](docs/MODULAR_GENERATION.md). Zwei neue Objekte 90114/90259; additive Felder in Setup/Szenario, vorhandene Planner-, Generator-, Snapshot-, UI- und Queueobjekte erweitert. 64 AL-Testmethoden kompiliert, davon fünf neue für SF-048; keine neue Test-Codeunit.

## Ticketvorlage

### SF-XXX — Titel

**Status:** Offen · **Priorität:** P0/P1/P2/P3
**Abhängigkeiten:** konkrete Tickets · **Betroffene Module:** aus Code prüfen

**Ausgangslage/Ziel:** tatsächliches Problem und messbares Soll.
**Scope/Grenzen:** gewählter Umfang, bestehender gemeinsamer Workflow, betroffene Querschnittsbereiche.
**Plan/Risiken:** Dateien, Referenzen/Setup, Schnittstellen, Transaktion/Checkpoint, Altstandschutz.

- [ ] Gewählte Funktion anhand vorhandener Architektur implementieren und dokumentieren.
- [ ] Lokale Prüfungen mit tatsächlichem Ergebnis protokollieren; bestehende Start-/Testvorlagen abgleichen.
- [ ] Native Positiv-/Negativ-/Rechte-/Wiederanlauf- und Dashboardfälle gemäß Testvertrag nachweisen.
- [ ] Menschliche Abnahme; erst danach Erledigt.

**Testprotokoll:** Zielversion/Umgebung/Rolle, Inputs/Seed/Zeitraum, Soll/Ist, echte Ergebnisse und offene Grenzen.


### SF-048 – Nachbesserung Verkaufsbestand und Dashboard (22.11.2026)

**Status: Zur Prüfung.** Ausdrücklich beauftragter Fix für reine Bewegungsläufe
mit vorhandenen Stammdaten und für nicht anklickbare Ergebnis-Kacheln.

- [x] Keine pauschale Bestandsblockade mehr während der Verkaufsvorprüfung
  bei einem vorhandenen Stammdatenpool.
- [x] Pro Verkaufsbeleg vor der Buchung Bestand am gewählten Lagerort und
  Belegdatum prüfen, einschließlich kumulierter Mengen mehrfacher Artikel.
- [x] Nicht buchbare Belege als ungebuchte Dokumente erhalten; nicht als
  erfolgreich gebuchte Rechnung ausgeben. Vorhandene Rechnungen/Posten
  bleiben unverändert; BC-Standardbuchung und Commit-Sperre bleiben aktiv.
- [x] Validierung berücksichtigt bei der geprüften Stammdaten-Wiederverwendung
  sowohl gebuchte als auch mangels Bestand ungebuchte Ergebnisse.
- [x] Dashboard-Drilldown nicht mehr an numerische Gleichheit mit dem
  bestätigten Lauf-Fortschritt koppeln; echte Listenanzahl separat anzeigen.
- [ ] AL-Kompilierung und Sandbox-Test für kein/teilweise/vollständig
  vorhandenen Bestand sowie teil-/vollständig gebuchte Verkaufsbelege.
- [ ] Test: ohne Bestand werden keine gebuchten Verkaufsrechnungen und
  Artikelposten fälschlich als erfolgreich angezeigt.
- [ ] Echte alternative Artikel und übersprungene Belege mit separater
  Fehlerstatistik sind noch nicht implementiert; hierfür ist ein eigener
  sicherer Persistenz-/Validierungsvertrag nötig.

**Statische Prüfung:** JavaScript-Syntaxprüfung und einfache AL-Strukturprüfung
(Balancierung) durchgeführt. Keine lokale AL-Compiler- oder BC-Sandbox-Abnahme.
**Querschnitt:** Dashboard und Verkauf betroffen; keine neuen UI-Texte,
Stammdatentabellen oder Einrichtungen eingeführt.
