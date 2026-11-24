# TODO – BC Scenario Factory: aktueller Backlog

**Abgleich: 21.11.2026 · Quellstand 1.0.7.3 · Dokumentationsänderung zur Prüfung.** Aktuelle Quellen, Manifest, Testhost und lokale Nachweise sind maßgeblich. Der [bisherige vollständige Wortlaut](docs/review/BACKLOG_VOR_ABGLEICH_2026-11-21.md) bleibt als Historie erhalten; dortige Zwischenstände sind keine zusätzliche Arbeitsliste.

## Stand und nächste Arbeit

Vorhanden: **156 AL-Dateien in 22 Modulen (Stand 24.11.2026, nicht kompiliert)**, separate Test-App **1.3.0.3 mit 48 Testmethoden**, sieben ausführbare führende Entitäten (Debitor, Kreditor, Artikel, Einkaufsbestellung, Verkaufsangebot/-auftrag/-rechnung). Zahlung/Ausgleich ist ein vorhandener Folgedienst, kein eigener zusätzlicher Entitätsgenerator. Die acht optionalen Fachmodule Lager, Fertigung, Montage, Projekte, Service, Anlagen, CRM und Planung sind in der Einrichtung wählbar und erzeugen im Folgeprozess eigene Daten (SF-028–SF-033, SF-054–SF-056; nativ abgenommen am 24.11.2026, ebenso Rahmenaufträge, Retouren, Anlagen-/Service-/CRM-/Projekt-Erweiterungen, Lizenzprüfung und Dashboard). Es gibt keine reine Planungsauswahl mehr.

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

**Standhinweis:** Grundlage dieser Aktualisierung ist der zuletzt hochgeladene vollständige Projektstand `BC Scenario Factory(5).zip` und der Gesprächsverlauf der heutigen Sandbox-Tests. Später separat gelieferte AL-Patches sind nicht automatisch Teil dieses ZIPs; vor Implementierung stets aktuellen Workspace gegen einzelne Patchstände und aktuelle App-Version abgleichen.

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

Wiederholte allgemeine Vorgehensblöcke sowie doppelte Sicherheits-/Abnahmesätze sind durch diese gemeinsamen Regeln ersetzt. Ursprüngliche Ziele/Abhängigkeiten und historische Begründungen bleiben im verlinkten Archiv nachvollziehbar. Keine offene Fachanforderung wird allein wegen ihres Alters gestrichen.

**Aktuelle Entwicklungsreihenfolge:** [Generator- und Modulfahrplan ab 22.11.2026](#entwicklungsfahrplan-ab-22112026--vollständig-definierte-generatoren-vor-neuen-branchen). Neue Tickets SF-049–SF-056 erst einzeln nach Freigabe implementieren.

**Aktueller Auftrag 22.11.2026:** SF-049 bis SF-053 ausdrücklich gemeinsam zur sequenziellen Umsetzung ausgewählt. Lokaler Teilstand SF-049/SF-050 siehe [Prüfbericht](docs/review/SF049_SF050_PRUEFBERICHT.md); native Abnahme und sichere Buchungsisolation offen, SF-051–SF-053 noch nicht implementiert. Dieser Auftrag ersetzt die älteren rein dokumentarischen Freigabevermerke für diese Auswahl.

**Aktuelle Begrenzung 23.11.2026:** Ausschließlich SF-050 fertigstellen, einschließlich ausdrücklich nachbeauftragter Ergänzung fehlender technischer Einrichtung bei Existing, danach Stop. Native Tests übernimmt der Nutzer. SF-051 bis SF-053 bleiben offen. [Aktueller Prüfbericht](docs/review/SF050_PRUEFBERICHT.md).

## Ticketübersicht

| Ticket | Prio | Status | Umsetzungsstand / verbleibende Arbeit |
| --- | --- | --- | --- |
| [SF-001](#sf-001) | P0 | Blockiert | Lokale Basis vorhanden; externe Freigaben offen |
| [SF-002](#sf-002) | P0 | Zur Prüfung | Umgesetzt |
| [SF-003](#sf-003) | P0 | Zur Prüfung | Umgesetzt |
| [SF-004](#sf-004) | P0 | Zur Prüfung | Umgesetzt; Abnahmevermerk aus Altbestand |
| [SF-005](#sf-005) | P0 | Zur Prüfung | Umgesetzt |
| [SF-006](#sf-006) | P0 | Zur Prüfung | Umgesetzt |
| [SF-007](#sf-007) | P0 | Zur Prüfung | Umgesetzt |
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
| [SF-028](#sf-028) | P2 | Erledigt | Lager: Lagereingang und Einlagerung; Pick/Versand/gelenktes WMS nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-029](#sf-029) | P2 | Erledigt | Fertigung und Montage; Arbeitsplan/Kapazität nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-030](#sf-030) | P2 | Erledigt | Projekte und Service; Servicebuchung/Verträge nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-031](#sf-031) | P2 | Erledigt | Anlagen: Anschaffung und erste Abschreibung; Abgang nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-032](#sf-032) | P2 | Offen | Weitere Branchen bleiben gesperrt: je Branche fachliche Spezifikation und native Abnahme der Module fehlen |
| [SF-033](#sf-033) | P3 | Erledigt | CRM und Planung; Interaktionen/Segmente nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
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
| [SF-049](#sf-049) | P0 | Erledigt | Gemeinsamer Stammdatenpool, Preflight und Mengenvertrag; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-050](#sf-050) | P0 | Erledigt | Einzelvorgänge, sichere Fortsetzung, Skip-/Prüfzustände und Existing-Foundation; nativ vom Nutzer getestet (23.11.2026) |
| [SF-051](#sf-051) | P1 | Erledigt | Teilzahlung/Raten/offene Posten; Rabatt, Toleranz, Sammelausgleich nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-052](#sf-052) | P1 | Erledigt | Gutschriften im Folgeprozess; Retouren nicht im Umfang; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-053](#sf-053) | P1 | Erledigt | Lagerbewegungen ohne WMS; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-054](#sf-054) | P2 | Erledigt | Montage; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-055](#sf-055) | P2 | Erledigt | Projekte; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-056](#sf-056) | P2 | Erledigt | Planungsvorschläge; nativ vom Nutzer abgenommen (24.11.2026) |
| [SF-057](#sf-057) | P2 | Zur Prüfung | Dashboard als Live Control Center (Laufstatus, Modulkarten, Aktivitätsfeed); native Abnahme offen |
| [SF-058](#sf-058) | P2 | Zur Prüfung | Dashboard in drei Ansichten (Generierung, Mandantendaten, Läufe), Detail-Overlay, kompakter Kopf; native Abnahme offen |


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
**Einordnung:** Umgesetzt
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

<a name="sf-028"></a>

### SF-028 — Warehouse-Prozessgenerator

**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P2
**Einordnung:** Optionales Modul *Lager* im gemeinsamen Ablauf; nativ vom Nutzer getestet und abgenommen (24.11.2026)
**Abhängigkeiten:** SF-024

- [x] Einfache Lagerorte/optionale feste Lagerplätze im Artikelumfang vorhanden.
- [x] Lagerprozess zu ca. 20 % der gebuchten Einkaufsrechnungen: Einkaufsbestellung am synthetischen Lagerort `BCSF-WMS` (Lagereingang und Einlagerung erforderlich, Lagerplatzpflicht), Standard-Lagereingang buchen, Einlagerung in Lagerplatz `A-01` registrieren; Vorprüfung (Nummernserien, Lagermitarbeiter, Kreditor/Buchungseinrichtung) mit dokumentiertem Skip `SOURCE`; Dashboard-Gruppe *Lager* mit registrierten Einlagerungen; Auswahl über das Modul *Warehouse* in der Einrichtung.
- [ ] Offen: Kommissionierung, Lieferung/Versand, Umlagerungsbeleg mit Lagerplätzen, gelenkte Einlagerung und Kommissionierung (Zonen), Bestandsabgleich je Lagerplatz über die Eingangsmenge hinaus; native Abnahme.

**Belege:** [BCSFWarehouseProcessor.Codeunit.al](src/Warehouse/Codeunits/BCSFWarehouseProcessor.Codeunit.al), [Prüfbericht](docs/review/SF028_SF033_PRUEFBERICHT.md), [Warehouse.md](docs/modules/details/src/Warehouse.md).
**Abnahme:** [x] Menschliche Abnahme des beschriebenen Umfangs (Teilumfang, offene Punkte oben bleiben außerhalb) am 24.11.2026.

<a name="sf-029"></a>

### SF-029 — Manufacturing- und Assembly-Generator

**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P2
**Einordnung:** Montage aus SF-054; optionales Modul *Fertigung* im gemeinsamen Ablauf; nativ vom Nutzer getestet und abgenommen (24.11.2026)
**Abhängigkeiten:** SF-024

- [x] Montage (Stückliste, Montageaufträge ungebucht/teil/voll) vorhanden, siehe SF-054.
- [x] Fertigung zu ca. 12 % der gebuchten Einkaufsrechnungen: synthetischer Fertigungsartikel, zertifizierte Fertigungsstückliste (ein bis zwei Artikel des Einkaufs), freigegebener Fertigungsauftrag; Modus 1 bleibt freigegeben und ungebucht, Modus 2 bucht Verbrauch und Ausgabe über die Standard-Artikelbuchung und beendet über die Standard-Statusverwaltung. Gebuchter Verbrauch nur, wenn die Lagerbewegungen derselben Rechnung die Bestandsreserve nicht nutzen; Vorprüfung mit Skip `SOURCE`/`STOCK`.
- [ ] Offen: Arbeitsplan, Arbeits-/Maschinenplätze, Kapazität, Rückmeldung nach Vorgang, Fremdvergabe; Lizenz-/Featureprüfung der Zielumgebung; native Abnahme.

**Belege:** [BCSFProductionProcessor.Codeunit.al](src/Manufacturing/Codeunits/BCSFProductionProcessor.Codeunit.al), [BCSFAssemblyProcessor.Codeunit.al](src/Assembly/Codeunits/BCSFAssemblyProcessor.Codeunit.al), [Prüfbericht](docs/review/SF028_SF033_PRUEFBERICHT.md), [Manufacturing.md](docs/modules/details/src/Manufacturing.md), [Assembly.md](docs/modules/details/src/Assembly.md).
**Abnahme:** [x] Menschliche Abnahme des beschriebenen Umfangs (Teilumfang, offene Punkte oben bleiben außerhalb) am 24.11.2026.

<a name="sf-030"></a>

### SF-030 — Projects- und ServiceManagement-Generator

**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P2
**Einordnung:** Projekte aus SF-055; optionales Modul *Service* im gemeinsamen Ablauf; nativ vom Nutzer getestet und abgenommen (24.11.2026)
**Abhängigkeiten:** SF-024

- [x] Projekte (Aufgaben, Planung, Verbrauch, Abrechnung) vorhanden, siehe SF-055.
- [x] Service zu ca. 20 % der gebuchten Verkaufsrechnungen: Serviceartikel für Debitor und fakturierten Artikel (Seriennummer, Installationsdatum aus der Rechnung) und ungebuchter Serviceauftrag mit Serviceartikelzeile und Ersatzteilzeile; Vorprüfung (Nummernserien, Debitor, geeigneter Artikel) mit Skip `SOURCE`; Dashboard-Gruppe *Service*.
- [ ] Offen: Buchen von Serviceaufträgen (Lieferung, Verbrauch, Rechnung), Serviceverträge, Wartungsfälle, Ressourcen-/Zeitbuchung; native Abnahme.

**Belege:** [BCSFServiceProcessor.Codeunit.al](src/ServiceManagement/Codeunits/BCSFServiceProcessor.Codeunit.al), [BCSFProjectProcessor.Codeunit.al](src/Projects/Codeunits/BCSFProjectProcessor.Codeunit.al), [Prüfbericht](docs/review/SF028_SF033_PRUEFBERICHT.md), [Projects.md](docs/modules/details/src/Projects.md), [ServiceManagement.md](docs/modules/details/src/ServiceManagement.md).
**Abnahme:** [x] Menschliche Abnahme des beschriebenen Umfangs (Teilumfang, offene Punkte oben bleiben außerhalb) am 24.11.2026.

<a name="sf-031"></a>

### SF-031 — Anlagen und Abschreibungsfälle

**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P2
**Einordnung:** Optionales Modul *Anlagen* im gemeinsamen Ablauf; nativ vom Nutzer getestet und abgenommen (24.11.2026)
**Abhängigkeiten:** SF-024

- [x] Anlagen zu ca. 15 % der gebuchten Einkaufsrechnungen: Anlage mit Abschreibungsbuch (Standardbuch, lineare Abschreibung über fünf Jahre), Anschaffungskosten (500 bis 5000) gegen das synthetische Bankkonto und erste Monatsabschreibung über die Standard-Sachbuchung mit Standard-Anlagenposten. Nur auf vorhandener Anlageneinrichtung (Standard-Abschreibungsbuch mit G/L-Integration, Buchungsgruppe mit nutzbaren Konten, Buchungszeitraum); es werden weder Kontenpläne noch Buchungsgruppen erfunden, sonst dokumentierter Skip `SOURCE`; Dashboard-Gruppe *Anlagen*.
- [ ] Offen: Anlagenklassen/-unterklassen, Abgang, Wartung, Zuschreibung, Sonderabschreibung, Abschreibungsbuchblatt-Lauf; automatische Anlageneinrichtung für Mandanten ohne Anlagenbuchungsgruppe; native Abnahme.

**Belege:** [BCSFAssetProcessor.Codeunit.al](src/FixedAssets/Codeunits/BCSFAssetProcessor.Codeunit.al), [Prüfbericht](docs/review/SF028_SF033_PRUEFBERICHT.md), [FixedAssets.md](docs/modules/details/src/FixedAssets.md).
**Abnahme:** [x] Menschliche Abnahme des beschriebenen Umfangs (Teilumfang, offene Punkte oben bleiben außerhalb) am 24.11.2026.

<a name="sf-032"></a>

### SF-032 — Weitere Profile: E-Commerce, Fertigung, Dienstleistung, Bau, Logistik, Wartung

**Status:** Offen · **Priorität:** P2
**Einordnung:** Weitere Unternehmensbranchen bleiben gesperrt; im normalen Unternehmensassistenten ist nur Großhandel unterstützt (24.11.2026 geprüft)
**Abhängigkeiten:** SF-028,SF-029,SF-030

- [x] Weitere Branchenbezeichnungen/Planungsvorlagen und generische Syntheseregeln existieren.
- [x] Technische Voraussetzungen aus SF-028–SF-031/SF-033 sind als wählbare optionale Module vorhanden (Lager, Fertigung, Montage, Projekte, Service, Anlagen, CRM, Planung).
- [ ] **Nicht umgesetzt (bewusst):** Eine Branche darf erst freigegeben werden, wenn ihre Module nativ abgenommen sind (Ticketvertrag) und je Branche eine fachliche Spezifikation vorliegt (Artikel-/Partnerprofile, Pflichtmodule, Prozessmix, Plausibilitätsregeln). Beides fehlt; E-Commerce, Fertigung, Dienstleistung, Bau, Logistik und Wartung bleiben gesperrt. **Zu prüfen / Rückfrage:** Reihenfolge der Branchen und Pflichtmodule je Branche.

**Belege:** [BCSFStarterCatalog.Codeunit.al](src/IndustryProfiles/Codeunits/BCSFStarterCatalog.Codeunit.al), [IndustryProfiles.md](docs/modules/details/src/IndustryProfiles.md).
**Abnahme:** [ ] Menschliche Abnahme des beschriebenen Umfangs offen.

<a name="sf-033"></a>

### SF-033 — CRM/Relationship- und Planning-Generatoren

**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P3
**Einordnung:** Planung aus SF-056; optionales Modul *CRM* im gemeinsamen Ablauf; nativ vom Nutzer getestet und abgenommen (24.11.2026)
**Abhängigkeiten:** SF-024

- [x] Abgeleitete Standardkontakte aus der Partneranlage; Planungsvorschläge über die Standard-Dispositionsengine (SF-056).
- [x] CRM zu ca. 35 % der gebuchten Verkaufsrechnungen: Verkaufschance für den Kontakt des Debitors (Standard-Geschäftsbeziehung), eine Kampagne je Lauf, eigener Verkaufszyklus `BCSF` (additiv); Vorprüfung (Nummernserien, Kontakt, Zyklus) mit Skip `SOURCE`; Dashboard-Gruppe *Kontakte* mit Kampagnen und Verkaufschancen.
- [ ] Offen: Interaktionsprotokoll, Segmente/Teams, Verkaufschancen-Phasen und -Abschluss, Aufgaben, Beziehungsstufen; native Abnahme.

**Belege:** [BCSFCrmProcessor.Codeunit.al](src/CRM/Codeunits/BCSFCrmProcessor.Codeunit.al), [BCSFPlanningProcessor.Codeunit.al](src/Planning/Codeunits/BCSFPlanningProcessor.Codeunit.al), [Prüfbericht](docs/review/SF028_SF033_PRUEFBERICHT.md), [CRM.md](docs/modules/details/src/CRM.md), [Planning.md](docs/modules/details/src/Planning.md).
**Abnahme:** [x] Menschliche Abnahme des beschriebenen Umfangs (Teilumfang, offene Punkte oben bleiben außerhalb) am 24.11.2026.

<a name="sf-036"></a>

### SF-036 — Release, AppSource-/PTE-Eignung und Dokumentation

**Status:** Offen · **Priorität:** P3
**Einordnung:** Lokale Pakete vorhanden; Releasefreigabe fehlt
**Abhängigkeiten:** SF-025

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


## Entwicklungsfahrplan ab 22.11.2026 – vollständig definierte Generatoren vor neuen Branchen

**Nutzerentscheidung:** Zuerst alle relevanten fachlichen Module auf einer stabilen, wiederverwendbaren Generatorplattform implementieren und **nativ abnehmen**; erst danach weitere Branchenprofile aktivieren. Großhandel ist Referenzszenario, nicht Sonderimplementierung. Die hier aufgeführten neuen Tickets sind **Planungs-/Implementierungsaufträge, keine bereits fertiggestellten Funktionen**. Nur das ausdrücklich gewählte Ticket bearbeiten (`AGENTS.md`). Die bisherigen Tickets SF-022, SF-025–SF-033, SF-039, SF-042 und SF-047/048 bleiben erhalten; neue Tickets konkretisieren Querschnittsverträge oder abgrenzbare Teilmodule, ohne vorhandene Grundlagen neu zu entwickeln.

### Priorisierung und Modulmatrix

| Reihenfolge | Modul / Generator | Nachweisbarer Bestand aus Projekt | Restumfang / führendes Ticket | Freigabe |
| --- | --- | --- | --- | --- |
| 0 | Gemeinsamer Generatorvertrag / Wiederanlauf / Preflight | Registry, Snapshot, Batch, Run, teilweise Master-Pool | **SF-049**, danach **SF-050** | Vor weiteren Fachgeneratoren |
| 1 | Kunden, Lieferanten, Artikel, Lager-Grundstämme | Generatoren vorhanden | Datenqualität, Fremdstamm-Eignung und Mengenunabhängigkeit **SF-049/050**, SF-039/040/047/048 | Pflicht für Belegmodule |
| 2 | Verkauf (Angebot/Auftrag/Rechnung/Lieferung) | Generatoren vorhanden | Bestandsabhängige Buchung, isolierte Fehler, Einzelbelegarten, Drilldowns **SF-050**, SF-021/024 | Regression vor Ausbau |
| 3 | Einkauf (Bestellung/Wareneingang/Rechnung) | Generator vorhanden | Teilbuchungen, Wiederverwendung, Mandantenvoraussetzungen, isolierte Fehler **SF-050**, SF-020/024 | Regression vor Ausbau |
| 4 | Finanzen, Zahlung, Ausgleich | Finanzbasis und vollständige Zahlung vorhanden | **SF-051**: Teilzahlung, Zahlungsrabatt/-toleranz, Ausgleich, Zahlungsmodi, Bankstämme SF-039 | Nach 0–3 |
| 5 | Retouren, Verkaufs-/Einkaufsgutschriften | Im TODO offen | **SF-052** als konkrete Teilumsetzung von SF-022 | Nach 0–4 |
| 6 | Lagerbewegungen ohne erweitertes Warehouse | Artikel/Lagerorte vorhanden | **SF-053**: Umlagerung, Inventur, Artikelbuchblatt, Bestand/Kosten | Nach 0–3 |
| 7 | Warehouse / WMS | Kein Prozessgenerator | **SF-028** konkretisiert; Empfang, Pick, Put-away, Shipment nur bei passender Lagerort-Konfiguration | Nach SF-053 |
| 8 | Assembly | Kein Generator | **SF-054** als abgrenzbarer Teil von SF-029 | Nach SF-053 |
| 9 | Manufacturing | Kein Generator | **SF-029**: Produktionsaufträge, Komponenten, Kapazität, Output | Nach SF-054 / Lizenzklärung |
| 10 | Projekte / Jobs | Kein Generator | **SF-055** als abgrenzbarer Teil von SF-030 | Nach SF-051 |
| 11 | Service Management | Kein Generator | **SF-030**: Serviceartikel, Serviceaufträge und -buchungen | Nach SF-055 / Lizenzklärung |
| 12 | Fixed Assets | Kein Generator | **SF-031**: Anlagen, Abschreibung, Abgang | Nach SF-051 |
| 13 | CRM / Kontakte / Verkaufschancen | Nur abgeleitete Kontakte | **SF-033** als eigenständiger Fachumfang | Nach 0–4 |
| 14 | Planning / Disposition | Kein ausführbarer Generator | **SF-056** als abgrenzbarer Teil von SF-033 | Nach Einkauf/Lager/Warehouse |
| 15 | Neue Branchenprofile | Nur Großhandel im Normalweg | **SF-032** erst nach modulfähiger, getesteter Grundlage | Abschließende Freigabe |

**Nicht als bereits unterstützt ausgeben:** WMS, Fertigung, Montage, Projekte, Service, Anlagen, CRM-Kampagnen/Chancen, Disposition, Retouren und Gutschriften, solange zugehöriger ausführbarer Generator, Voraussetzungen, Testfälle und reale BC-Standardbelege/Posten fehlen. Markierte/angezeigte Module ohne ausführbare Registry-Bindung sind nicht nutzbar. Für nicht lizenzierte oder in der Zielversion fehlende Features: *Nicht verfügbar*, statt Scheindaten oder pauschaler Erfolgsanzeige.

### Verbindlicher modulübergreifender Qualitätsvertrag (gilt für SF-049–SF-056 und bestehende SF-022/SF-028–SF-033)

1. **Unabhängige Mengen und Laufarten.** `Komplett`, `Nur Stammdaten`, `Nur Bewegungsdaten` mit wählbaren ausführbaren Modulen und Einzelbelegarten (auch ausschließlich `SALES.INVOICE`, Einkauf 0, andere Verkaufsmengen 0). Menge 0 = bewusst nicht ausgewählt, nicht pauschal Eingabefehler. Für jede vom Produktlimit gedeckte positive Anforderung die Verteilung exakt/überlappungsfrei planen (Summe der Quotentypen = angeforderte Menge); Mengen dürfen nicht an Anzahl der Kunden/Artikel gekoppelt sein. Nicht erfüllbare fachliche Bedingungen **konkret** melden statt generischer Mengenfehlermeldungen. Grenzen müssen dokumentiert und getestet sein; *keine Garantie für beliebig große Mengen ohne Ressourcenlimit*.
2. **Mandantenstammdaten unabhängig von früheren Läufen.** Null-GUID bezeichnet *vorhandene geeignete Daten im aktuellen Unternehmen*, nicht einen zu ladenden Run. Factory-Stämme aus anderen Läufen und manuell/importierte BC-Stämme nach derselben fachlichen Eignungsprüfung verwenden; existierende Stämme nie stillschweigend duplizieren, um Bewegungsbelege auszuführen. Auswahl über stabile SystemIds im eigenen unveränderlichen Lauf-Snapshot einfrieren; Registry-Provenienz/Quelllaufbezüge der Originale nicht umschreiben. Ungeeignete Datensätze überspringen und nächsten **geeigneten** versuchen; bei unzureichendem Pool mit nachvollziehbarer Diagnose beenden. Kein fremdes Unternehmen/Company übergreifend lesen.
3. **Vorprüfung pro angeforderter Belegart.** BC-Basis- und Finanz-Setup, Buchungsgruppen/Kombinationen, MwSt.-Einrichtung, Nummernserien, Einheiten, gesperrte Stammdaten, Haupt-/Alternativlieferanten, Lagerort/-platz, verfügbare und nicht reservierte Menge, Dimensionen, erlaubte Buchungsdaten und Perioden, Berechtigungen, Features/Lizenz und gewünschte Folgeschritte prüfen. Für Bestandsbuchung aktuellen verfügbaren Bestand **zum Buchungszeitpunkt** prüfen; geeigneten Ersatzartikel/anderen Belegplan deterministisch wählen, sonst einen nachvollziehbaren **nicht gebuchten/übersprungenen** Einzelfall erzeugen. Kein erfundener Bestand, keine stillen Änderungen an vorhandenen Stammdaten und Buchungsgruppen.
4. **Sichere Fehlerisolierung.** Ein fachlich nicht geeigneter Datensatz oder *eindeutig vor jeder Buchung erkannter* Belegfehler darf den übrigen Lauf nicht blockieren. Bei wirklichen Postingfehlern nur nach sicherer Transaktionsabgrenzung und geklärtem Commit-Verhalten fortsetzen; `TryFunction` ist kein garantierter Rollback. Unklare, teilweise bestätigte oder möglicherweise gebuchte Vorgänge = `NeedsReview`, niemals automatischer Replay und niemals als erfolgreich zählen. Kein `COMMIT` im gesperrten Bereich; BC-Standardcodeunits mit internem Commit (u. a. Zahlungstoleranz in Zahlungsjournal-Validierungen) separat auf sichere Architektur prüfen. Keine direkten Writes in Standardposten.
5. **Korrekte Buchungs- und Zeitlogik.** Einkauf/Wareneingang → verfügbare Menge → Verkauf/Lieferung/Rechnung → optional Zahlung/Ausgleich; jede Belegart hat zulässige voneinander unabhängige Mengen und Datumsgrenzen; Vorbedingungen und tatsächliche Bestandsmengen aus bereits gebuchten anderen Läufen berücksichtigen. Reproduzierbare Seed-Werte, fachlich sinnvolle Mehrpositionsbelege und realistische Preis-/Mengen-/Partnerverteilung. Historische Profile/Snapshots unverändert behandeln.
6. **Kein festhängender Start.** Doppelte Unternehmensinitialisierung verhindern, solange tatsächlich aktiver Queue-Job/Request existiert. Fehlgeschlagene/abgeschlossene Job-Queue-Entries ohne aktiven Run dürfen neue Ausführung nicht dauerhaft sperren; konkurrierende Starts synchron und im Job-Kontext absichern. Wiederaufnahme unterscheidet neuen Run von Retry derselben Run-ID; Checkpoints/Confirmed Work dürfen nicht erneut buchen.
7. **Dashboard ist Ergebnisansicht, kein Fortschrittsfilter.** Kachel/Drilldown bei existierendem Datensatz öffnen, auch wenn Anzahl *erzeugt* von aktuell *vorhanden* abweicht (z. B. Auftrag nach Buchung gelöscht/umgewandelt). Lauf- und Unternehmenszähler getrennt; klare Kategorien Erzeugt / ungebucht / teilweise gebucht / gebucht / übersprungen / fehlgeschlagen / NeedsReview. Zählung aus realen Belegen/Posten und Herkunft, nicht bloß Sollwert oder Status. Standardlistenfilter müssen konkrete gültige Datensätze zeigen, einschließlich nachfolgender Belegarten; leere Kacheln nicht anklickbar ausgeben.
8. **Branchenunabhängige Engine.** Branche liefert Datenprofile, Pflichtmodule, zulässige Prozesse, Plausibilitätsregeln und interne Ausgangsverteilungen. Keine branchenabhängigen hart codierten Artikel-/Kundenlimits, keine ad-hoc Sonderlogik im Batch Runner, keine neuen parallelen Pipeline/Setup/UI-Systeme. Profile nur für tatsächlich ausführbare Module aktivieren. Einheitliche Kernel-Tests für jedes Modul und jede Branche.
9. **Testfallmatrix je Ticket.** Kleines/Mittleres/Großes Paket; SKR03, SKR04 und vorhandene BC-Einrichtung; neuer/leerer und vorbefüllter Mandant; komplett, nur Stamm, nur Bewegung mit/ohne Quell-Run; ausschließlich eine Belegart; 0/1/2/viele Mengen; unterschiedliche Quotensätze/Seed/Batchgrößen; fehlende/gesperrte/unvollständige Stammdaten; Artikel ohne/mit knappem/reserviertem Bestand; gebuchte und ungebuchte Modi; Zahlungsmodus ohne/mit Zahlung; fehlgeschlagener Batch, Recovery, erneuter Start, Job Queue; DE/EN und Rollen; Datenkonsistenz, Standardposten, Dashboard/Drilldowns; Altprofil/Upgrade. Für >Kapazität/Limit erwartetes kontrolliertes Verhalten nachweisen. Abweichungen mit tatsächlichem Run/Seed/Objekt und erwarteter Behandlung dokumentieren; kein pauschales „alles funktioniert“.
10. **Abschluss jedes Generatortickets.** Bestehende Starter und Templates nur bei tatsächlich neu ausführbarem Modul aktualisieren; technische Referenzen/Module/Registrierung/Test-App/DE-EN-Labels/Dashboard und Docs synchron. Vorhandene Testobjekte ergänzen, neue Testobjekte nur mit ausdrücklichem Ticketauftrag. Erst nach echter AL-Kompilierung, Test-App-Ausführung, Sandbox-Lauf und fachlichem Soll-/Ist-Vergleich `Zur Prüfung` – `Erledigt` ausschließlich durch Menschen. Wenn Lauf nicht ausführbar: offen lassen und technische Ursache präzise nennen. `AGENTS.md` hat Vorrang.

### Konkrete Regressionen aus der Testserie vom 22.11.2026

| Fall | Früherer Fehler | Verbindlicher Regressionstest |
| --- | --- | --- |
| R01 | Artikelattribute Material „Messing“/„Edelstahl“ aus Kategorie geerbt | 400 unterschiedliche Artikel, Kategorieattribute vs. Artikelattribute konfliktfrei, keine Duplikatbeschreibung ohne echte Variante |
| R02 | Ein einziger Hauptlieferant/Ein-Positionsbelege | Unterschiedliche passende Haupt-/Alternativlieferanten, 2–5 Verkaufs-/2–4 Einkaufspositionen, keine fremden Lieferantenzeilen |
| R03 | Nur erste Hälfte des Artikelstamms benutzt | Voller geeigneter Artikelpool ohne feste 50/200-Grenze, keine fest verdrahteten Indexbereiche; Backtests 40/400 Artikel |
| R04 | Alle Einkäufe am ersten Tag und zwei Städte dominieren | Geplante zeitliche Verteilung und 20 Stadt-/PLZ-Kombinationen, reproduzierbar und keine unplausiblen Klumpen |
| R05 | `Master Source Run Id = 0000...` und gescheiterte Fremdstammquelle | Nur Bewegungsdaten aus vorhandenen Mandantenstämmen ohne vorherige Run-ID läuft; keine neuen Kunden/Lieferanten/Artikel |
| R06 | `PurchaseQuantity()` erwartet Stammdatenziel im aktuellen Bewegungslauf | Menge aus eingefrorenem geeigneten Stammdatenpool; für kleine/belegartbezogene Läufe keine generische widersprüchliche-Verteilungs-Meldung |
| R07 | Nur `SALES.INVOICE` wurde durch Requestvalidierung abgelehnt | Alle anderen Belegmengen 0: ausschließlich angeforderte Verkaufsrechnungen zulässig; keine automatischen Nebenbelege außerhalb Pflichtfolgeprozessen |
| R08 | Artikel benötigt 6 Einheiten, verfügbar 0 | Kein gesamter Abbruch wegen nicht verfügbarer Artikel; deterministische geeignete Ersatzwahl oder expliziter Skip vor Buchung; keine künstlichen Lagerposten |
| R09 | Commit verboten: `BCSF Payment Processor.Pay` → Codeunit 426 Zahlungstoleranz | Zahlungsjournalvalidierung mit/ohne Toleranz/Applies-to, sichere Transaktionsgrenzen, kein stilles Commit/kein Doppelposting; „ohne Zahlungen“ ruft Zahlung nie auf |
| R10 | Abgeschlossener/gefallener Initialisierungsrequest blockiert Folge-Run | Aktiven Job schützen, terminale Job Queue nicht dauerhaft sperren, Retry/Re-Start sicher, keine parallele Doppelinitialisierung |
| R11 | Kacheln mit existierenden Belegen nicht klickbar nach Statuswechsel | Jede belegte Karte zeigt reale Standardliste nach Buchung/Umwandlung; keine Abhängigkeit vom Sollzähler |
| R12 | Neuer kompletter Lauf erzeugt gleichartige Stammduplikate | **Erwartung unterscheiden**: Komplettlauf darf gemäß Modus neue synthetische Stämme generieren; Bewegungslauf darf das nicht. Reuse/Neuanlage transparent anzeigen und testen |
| R13 | Fachlicher Buchungsfehler stoppt komplette Queue oder wird verschluckt | Safe preflight skip und sichere pro-Beleg Isolation; unklare Transaktion => NeedsReview + keine automatische Wiederbuchung |

**Abnahmemetriken und belegbare Grenzen:** Jede Generatorcharge besitzt `Requested`, `Created`, `Posted`, `Skipped`, `Failed`, `NeedsReview` (falls zugehörige Datenstruktur diese Werte unterstützt; andernfalls die Zuordnung vor Implementierung entwerfen). Bilanz: `Requested = erfolgreich erledigte + dokumentiert nicht erledigte` ohne doppelte Zählung teilgebuchter Belege; Ergebnisse in Standardbelegen/Posten nachprüfbar. **Keine Aussage „für jede Branche und jede Datenmenge garantiert erfolgreich“**: fachlich ungeeignete Kundenstämme, Rechte, Lizenz, Buchungsperioden, Zeit- und Mengenlimits dürfen kontrolliert zu Skips/Fehlern führen, aber niemals zu fälschlich als erfolgreich gemeldeten Belegen.

<a name="sf-049"></a>
### SF-049 — Einheitlicher Preflight, Stammdatenpool und Mengenvertrag für alle Generatoren
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P0 · **Abhängigkeiten:** SF-048, SF-040, SF-042 · **Gilt für:** alle Module

**Ziel:** Einen gemeinsamen *lesenden* Eignungs- und Auswahlvertrag über existierende Partner/Artikel/Einrichtungen herstellen; Null-Run-ID, 0-Mengen, einzelne Dokumentarten und beliebige positive Belegmengen im zulässigen Limit richtig planen, ohne vorhandene Stammdaten zu ändern.

- [x] `BCSF Master Data Source`, `BCSF Company Initialization`, Scenario/Run Snapshot, Dependency Planner, `BCSF Process Coordinator` und Sales/Purchase-Resolver in den aktuellen Quellen nach festen Run-IDs, harten Mengen-/Artikelgrenzen und divergierenden Selektoren untersuchen; keine vorhandene korrekte Implementierung duplizieren.
- [ ] Eignungsprüfungen modular pro Belegart: Stammdatensatz, Posting-Gruppen, Nummernserien, USt, Einheiten, Lagerort, Lieferanten, Sperren, Dimensionen und BC-Rechte; ungeeignete Alternativen in begrenzter deterministischer Suche ersetzen; keine manuellen Setup-Pflichten beim Nutzer erfinden.
- [ ] Snapshot enthält nur explizit ausgewählte geeignete SystemIds/Setupinformationen und Prozessmengen; kein Rückschreiben fremder Masterdatensätze und keine falschen generierten Registry-Identitäten.
- [ ] Verkauf nur: `SALES.INVOICE=1` bei Angebot/Auftrag/Einkauf=0; Einkauf nur; mehrfache Läufe mit denselben 40 Artikeln; alter/fehlender Source-Run; 0/1/Grenzwert Mengen, Quote 0/100 und Rundung testen.
- [ ] Dashboard meldet Anzahl geeigneter/geprüfter/übersprungener Stämme und konkreten Grund bei zu kleinem Pool; vorhandene Filter/Run-Kontrakte erhalten.
- [ ] Bestehende `tests/SF019` ergänzen; kleines/mittleres und negatives Sandbox-Szenario, SKR03/SKR04/Bestandsmandant, DE/EN; keine globale Erfolgsmeldung ohne echte Buchung.
**Nicht im Scope:** Neue Fachmodule, neue Datenbank/Batch-Engine, pauschales Autofix fremder Finanzstämme. **Abnahme:** Zulässiger reiner Bewegungslauf mit/ohne Factory-Run-ID vollständig planbar, keine zusätzlichen Stammobjekte, keine falschen Mengenfehler; Testprotokoll und menschliche Freigabe.

**Lokaler Teilstand 1.0.10.0:** Modulabhängiger bestehender Pool Version 3, geeignete SystemIds ohne neue 500-/Gleichmengenbegrenzung, lieferantentreue Auswahl, einmaliger Capture und eingefrorene Identitätsprüfung, Dashboarddiagnose und vorhandener Testhost ergänzt. Konservative Kontenprüfung/Dimensionskombinationen und native Abnahme bleiben offen. Kein vollständiger Abschluss; [Dateien, Grenzen und Prüfungen](docs/review/SF049_SF050_PRUEFBERICHT.md).

<a name="sf-050"></a>
### SF-050 — Buchungsfehler pro Geschäftsvorfall sicher isolieren, Recovery und Drilldowns
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 23.11.2026) · **Priorität:** P0 · **Abhängigkeiten:** SF-049, SF-013, SF-020, SF-021, SF-025

- [x] `BCSF Batch Runner/Worker`, Payment Processor, Sales/Purchase Generators, Posting Calls, Job-Queue-Status und Dashboard auf tatsächliche Commit/Transactional Boundaries prüfen und eine sichere **isolierte** Buchungseinheit pro Vorgang definieren. Nicht pauschal `TryFunction` oder `CommitBehavior::Error` entfernen.
- [x] Vorher erkennbare Fehler (Lagerbestand 0, ungültige Artikelkombination, gesperrte Partner etc.) als nachvollziehbare `Skipped` dokumentieren; nächsten geeigneten Datensatz/Beleg versuchen. Buchungsfehler nur weitersetzen, wenn Standardposting und Rollback sicher nachweisbar; sonst `NeedsReview` sperrt automatische Wiederholung des betroffenen Vorgangs, nicht zwingend unabhängige Vorgänge.
- [x] Pro Run eindeutige Fach-/Belegidentität, Checkpoint/Confirmed Work und Reconciliation nach echten Standardbelegen/Posten. Keine Doppellieferung, -rechnung, -zahlung; bei Transaktionsunsicherheit keine Scheinerfolge.
- [x] Korrekte Trennung terminaler vs. aktiver Initialisierungsjobs; Simultanstart, Queue-Fehler, erneute Eingabe, manuelle Wiederaufnahme prüfen.
- [x] Dashboards/Drilldowns zu offen, teilweise, vollständig, gebucht, übersprungen, NeedsReview und Fehlgrund; keine Gleichheitsprüfung Sollzähler vs. realer Datenbestand.
- [x] Regression R08–R11/R13 mit AL-Test-App und echten Sandboxläufen; Buchen/Lager-/Sach-/Debitoren-/Kreditoren-/Wertposten abgleichen; alle neuen Fehltexte DE/EN.
**Nicht im Scope:** ungesicherte automatische Wiederholungen, Löschen gebuchter Posten, künstliche Bestandsbuchung bei Verkauf-only. **Abnahme:** Ein ungeeigneter Artikel/Beleg stoppt nicht alle unabhängigen Vorhaben; kein unklar gebuchter Vorgang wird automatisch neu gebucht. Menschliche Freigabe erforderlich.

**Umsetzung 1.0.11.0 / 23.11.2026:** Neue Snapshotpolitik mit isoliertem Geschäftsvorfall je Belegpaket, Pending-only-Fortsetzung unabhängiger Vorgänge nach Standardfehlern, unveränderte NeedsReview-/Replay-Sperre, lesende Preflight-Skips mit echten Checkpoints ohne Geschäftsdatenherkunft, getrennte Dashboardzähler. Zusatzauftrag: fehlende technische Existing-Mandanteneinrichtung vor Generatoren ergänzen und neue Vorlage an vorhandene verwendbare Finanz-/Artikelzuordnungen binden; keine Ersatzkonten oder fremden Überschreibungen. [Umsetzung, Prüfungen und native Fälle N01–N08](docs/review/SF050_PRUEFBERICHT.md). Nutzer übernimmt native BC-Abnahme. Danach Stop; keine Umsetzung SF-051–SF-053.

<a name="sf-051"></a>
### SF-051 — Finanzen: Teilzahlungen, Ausgleich und Zahlungsmodus robust abschließen
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · **Priorität:** P1 · **Abhängigkeiten:** SF-050, SF-022, SF-039

- [x] Vorhandenen `BCSF Payment Processor`, Finanzsetup, gültige Partner-/Bankkonten und Journal-Standardroutinen wiederverwenden; keine neuen direkten Postentabellen-Inserts. (Lokal im Code; nicht kompiliert.)
- [x] Zahlungsplan je Rechnung (Seed-deterministisch, additives Marker `planVersion` 1 im `paymentSetup`; alte Snapshots bleiben Vollzahlung): voll, zwei Raten mit unterschiedlichen Zahlungsterminen, Teilzahlung mit offenem Rest, bewusst offen. Exakte Restbetragsprüfung nach jeder Rate und im Validator. [ ] „Sammelausgleich“ und separate Nutzerwahl der Modi bleiben offen.
- [ ] Zahlungsrabatt, Zahlungstoleranz und Gutschriften (SF-052) **nicht umgesetzt**: Der Validator erwartet exakte Restbeträge; eine stille Toleranz-/Rabattanpassung führt zu einem gesperrten Vorgang statt Scheinerfolg. Mehrfache Teilzahlungen >2 Raten offen.
- [x] Fehlende Partnerbankdaten: sichere Fallbacks nur nach geprüfter Fach-/Rechtsregel, niemals reale Zahlung auslösen; Kunden-/Lieferantenstämme nicht ungefragt mutieren (SF-039).
- [x] R09 mit Codeunit 426 und `Applies-to Doc. Type/No.` in echter BC 29.x Sandbox testen, sichere Journalvaliderungsreihenfolge und Commit-Grenzen; Zahlungen bei deaktiviertem Modul nicht auslösen.
- [x] Journalzeilen/-belege, Debitoren-/Kreditorenposten, detaillierte Posten, Bank-/Sachposten, Ausgleichsreste verproben; Dashboard und Starter aktualisieren.
**Abnahme:** gebuchte Rechnungen haben je Prozessmodus nachweisbar korrekte offene/ausgeglichene Restbeträge, kein COMMIT-Verbot/kein Doppelposting.

**Umsetzung 1.0.12.0 / 23.11.2026:** Nur `BCSFPaymentProcessor` (Plan, Ratenbuchung, Restprüfung, Validator), zwei Testmethoden im vorhandenen Testobjekt 90700, Versionen. Keine neue Tabelle/Seite/UI-Text. **Nicht kompiliert (.NET 10 fehlt), nicht nativ getestet.** [Bericht](docs/review/SF051_PRUEFBERICHT.md).

<a name="sf-052"></a>
### SF-052 — Verkauf/Einkauf: Retouren und Gutschriften vollständig als Folgeschritte
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · [Bericht](docs/review/SF052_PRUEFBERICHT.md) · **Priorität:** P1 · **Abhängigkeiten:** SF-050, SF-022, SF-051

- [ ] Einkauf: Rücksendung/Warenausgang und Einkaufsgutschrift, Teil- und Vollretoure mit Referenz auf ursprünglichen Wareneingang/Rechnung, angemessene Bestandsdeckung.
- [ ] Verkauf: Rücknahme/Wareneingang und Verkaufsgutschrift auf gebuchte Lieferung/Rechnung, inklusive Teilmengen und kaufmännischer Begründung; passende MWSt./Wertposten.
- [x] Nicht gebuchte Gutschriften separat von gebuchten Kreditbelegen behandeln; keine negativen Rechnungen als Ersatz für echte Standardgutschriften.
- [x] Bezug zu ursprünglicher Rechnung/Belegzeile, Preis/Rabatt/Steuer/Einheit, Lager-/Wert-/Sach-/Partnerposten und ggf. Zahlungsausgleich konsistent; zeitliche Reihenfolge erhalten.
- [ ] Einzelmodul, Komplettszenario und vorbefüllter Fremdstammdatensatz testen; Ausgangsbelege mit fehlender/teilweise bereits retournierter Menge kontrolliert skippen.
- [x] Starter/Run Snapshot/Registry/Drilldowns und DE/EN ergänzen; bei fehlenden BC-Funktionen Grenzen kennzeichnen.
**Abnahme:** gebuchte Teil-/Vollretouren und Gutschriften als echte BC-Standardbelege in Einkauf und Verkauf nachweisbar.

**Umsetzung 23.11.2026 (Teilumfang):** Ungebuchte, gebuchte Teil- und (Verkauf) Vollgutschriften zu gebuchten Rechnungen im Folgeprozess über die vorhandenen Generatoren (`BCSF Credit Memo Processor`, 90481); Partnerbankkonten (SF-039-Teil) beim Anlegen der Partner. Offen: Rücksendung/Rückgabebelege, Ausgleich mit der Rechnung, Quoten-/Optionsfelder, Dashboard-Sonderkachel, native Abnahme.

<a name="sf-053"></a>
### SF-053 — Inventory: Lagerbewegungen, Inventur und Umlagerung ohne WMS
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · [Bericht](docs/review/SF053_PRUEFBERICHT.md) · **Priorität:** P1 · **Abhängigkeiten:** SF-049, SF-050, SF-020

- [x] Artikel-/Lagerort-/ggf. Lagerplatzstämme sowie Bestands-/Einheits-/Chargenpflichten prüfen; bestehende Artikelgeneratoren wiederverwenden.
- [x] Standard-Artikelbuchblätter für positive/negative Korrekturen, Inventurzählung/-differenz und Umlagerungsaufträge/-buchblätter mit Versand/Empfang (je nach vorhandenem BC-Standard) erzeugen; physische und rechnerische Bestände abstimmen.
- [x] Ohne Advanced Warehouse kein künstlicher Pick/Put-away; für WMS siehe SF-028. Bei vorhandenen Lagerorten nur erlaubte Bewegungsarten verwenden.
- [x] Mengen und Datum unabhängig von Artikelerzeugungsmenge; keine negativen oder reservierten Bestandsabzüge ohne fachliche Zulässigkeit; Dimensionen, Kostenberechnung/Wertposten prüfen.
- [x] Bewegungen gegen tatsächliche Artikel-/Wert-/Sachposten und Stand je Lagerort/Datum, inkl. wiederholtem Run und verschiedenen Losgrößen, validieren.
**Abnahme:** mindestens Warenein-/ausgang per Buchblatt, Inventurabweichung und Umlagerung über Standardabläufe inkl. Dashboard/Drilldowns nativ erfolgreich.

**Umsetzung 23.11.2026:** `BCSF Inventory Movement Processor` (90482) im Folgeprozess des Einkaufsgenerators für alle Artikelzeilen, mit Vorprüfung (freier/reservierter Bestand, Dimensionen), dokumentiertem Skip, Wertposten- und Bestandsprüfung je Lagerort/Datum; Lagerorte `BCSF-AUX`/`BCSF-TRN`. Lagerplätze/WMS gehören zu SF-028. [Bericht](docs/review/SF053_PRUEFBERICHT.md)

<a name="sf-054"></a>
### SF-054 — Assembly: Montage-Stammdaten und Montageaufträge
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · [Bericht](docs/review/SF054_PRUEFBERICHT.md) · **Priorität:** P2 · **Abhängigkeiten:** SF-053, SF-049, SF-050, SF-029 (gemeinsamer Epic)

- [x] Geeignete Montageartikel, Montage-Stücklisten und Komponenten-/Ressourcenbedarf im Standard einrichten, Maße/Einheiten und Bestände validieren.
- [x] Montageauftrag, Verbrauch und Output mit passenden Stücklisten / Fertigstellungsgraden/Datumsgrenzen über BC-Standardverfahren; ungebucht und gebucht getrennt.
- [x] Beschaffungsbedarf, Fehlbestand, reservierte Komponenten, alternative Komponenten und Varianten als reguläre Vorprüfung/Skip behandeln.
- [x] Mengen-/Kosten-/Artikel-/Wertposten, Komponentenverbrauch und Fertigartikelzugang abgleichen; keine Doppelbuchung nach Retry.
- [x] Featureverfügbarkeit/BC-Version und Standardtests inklusive Dashboard/DE-EN prüfen.
**Abnahme:** reproduzierbar gebuchter Montageauftrag mit nachvollziehbarem Komponentenverbrauch und Output.

**Umsetzung 23.11.2026:** `BCSF Assembly Processor` (90483) im Folgeprozess des Einkaufsgenerators, additive Foundation, Registry/Dashboard/DE-EN; Tests im vorhandenen Testobjekt. Manufacturing (SF-029) und WMS (SF-028) bleiben getrennt.

<a name="sf-055"></a>
### SF-055 — Projects/Jobs: Projekte, Ressourcen und Projektabrechnung
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · [Bericht](docs/review/SF055_PRUEFBERICHT.md) · **Priorität:** P2 · **Abhängigkeiten:** SF-049, SF-050, SF-051, SF-030 (gemeinsamer Epic)

- [x] Projekt-/Job-Stamm, Aufgaben, Planungszeilen, Ressourcen, Kosten und ggf. Artikelbezüge über vorhandene BC-Standards anlegen.
- [x] Ressourcenzeit-/Materialverbrauch über Projektbuchblatt, Fakturavorschlag/Verkaufsrechnung und gebuchte Projekt-/Sach-/Partnerposten als nachvollziehbare Kette realisieren.
- [ ] Teilabrechnung, unterschiedliche Projektlaufzeiten, Kosten-/Ertragszuordnung, Dimensionen und fehlende Ressourcenkapazität prüfen; Phasen und Buchungsrechte respektieren.
- [ ] Reine Projektstammdaten und zusätzliche unabhängige Abrechnungsläufe erlauben; keine Stammdatenvervielfachung.
- [x] Von Service Management trennen; eigene Modulverfügbarkeit und Tests, Drilldowns/DE-EN.
**Abnahme:** reales Projekt mit Zeit/Material, gebuchten Projektposten und Rechnung, belastbarer Soll-/Ist-Abgleich.

**Offen (ehrlich benannt):** Fehlende Ressourcenkapazität wird nur über „Ressource nicht nutzbar → keine Ressourcenzeile“ behandelt, Kapazitätseinträge werden nicht geprüft; zusätzliche, vom Einkaufslauf unabhängige Abrechnungsläufe für vorhandene Projekte gibt es nicht (nur Modus „Projekt und Planung“ als reine Stammdaten, neue Projekte je Lauf).

**Umsetzung 24.11.2026:** siehe [Bericht](docs/review/SF055_PRUEFBERICHT.md).

<a name="sf-056"></a>
### SF-056 — Disposition/Planning: Bedarf, Beschaffung und Vorschläge
**Status:** Erledigt (Nutzerabnahme nach nativem Test, 24.11.2026) · [Bericht](docs/review/SF056_PRUEFBERICHT.md) · **Priorität:** P2 · **Abhängigkeiten:** SF-053, SF-020, SF-029 (falls Produktionsplanung)

- [x] Planungsparameter (Wiederbeschaffungsverfahren, Lieferzeiten, Losgrößen, Wiederbeschaffungslagerorte) nur für eigens erzeugte Testsynthese setzen; bestehende Fremdstämme lesen und prüfen.
- [x] Verkaufsbedarf, Meldebestände, vorhandenen Bestand und offene Einkaufs-/Produktionsaufträge zu Planungszeilen oder Bestellvorschlägen über BC-Standardfunktionen zusammenführen.
- [x] Planungsvorschlag von tatsächlicher Bestellung/Buchung klar trennen; nur ausdrücklich gewünschte Umsetzung aktivieren; doppelte Deckung und Zeit-/Lagerortprobleme verhindern.
- [x] Ergebnisse anhand Bedarf/Deckung/Buchungszeitpunkt, Vorschlagsmenge und tatsächlichen Belegen nachvollziehbar prüfen; Advanced-Planning-Funktionen nur bei Verfügbarkeit.
**Abnahme:** reproduzierbare und fachlich passende Vorschläge für Unter-/Überdeckung inklusive negativer Varianten.

**Umsetzung 24.11.2026:** siehe [Bericht](docs/review/SF056_PRUEFBERICHT.md).

<a name="sf-057"></a>
### SF-057 — Dashboard als Live Control Center
**Status:** Zur Prüfung · **Priorität:** P2 · **Abhängigkeiten:** SF-041, SF-044 · Nutzerauftrag 24.11.2026

- [x] Im vorhandenen Control-Add-in: Laufstatus-Kopf (Branche, Status, Gesamtfortschrittskreis, Module fertig/in Verarbeitung/wartend, Fehler, Warnungen, Laufzeit, aktueller Schritt), kompakte aufklappbare Modulkarten mit Akzentfarbe, Icon, Ring, Balken, zwei bis vier klickbaren Kennzahlen und vollständiger Detailansicht, Live-Aktivitätsfeed, Zählanimationen nur bei echten Änderungen. Aufklappzustand, Scrollposition und Auswahl bleiben bei der 1-s-Aktualisierung erhalten (Knoten werden gepatcht, nicht neu gebaut).
- [x] AL-Payload minimal erweitert (`BCSF Dashboard Data`): `startedIso`, `finishedIso`, `failedBatches`, `failedNodes`, `reviewBatches`, `currentNode` und die letzten 12 Zustandswechsel aus der vorhandenen Tabelle *Run Event* (`events`). Keine neue Tabelle/Seite/Protokollarchitektur, keine Generator- oder Buchungsänderung.
- [x] 15 neue Labels DE/EN (`Translations/sf057.de.json`, in Dashboard-Fallback und Sync-Skript eingebunden). XLIFF-IDs entstehen erst beim nächsten AL-Build, danach `python3 Translations/sync_sf_translations.py`.
- [ ] Offen: AL-Build (Compiler hier nicht verfügbar, **nicht kompiliert**), XLIFF-Sync, native Prüfung in BC (Role Center, 20–30 Module, echter Lauf, Live-Feed mit tatsächlichen Run Events, Berechtigung ohne Leserecht auf *Run Event*).

**Belege:** [dashboard.js](src/Monitoring/Dashboard/dashboard.js), [dashboard.css](src/Monitoring/Dashboard/dashboard.css), [BCSFDashboardData.Codeunit.al](src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al), [check_dashboard.mjs](scripts/check_dashboard.mjs), [DASHBOARD_EMBEDDING.md](docs/DASHBOARD_EMBEDDING.md#live-control-center-sf-057).
**Abnahme:** [ ] Menschliche Abnahme offen.

<a name="sf-058"></a>
### SF-058 — Dashboard-Feinschliff: drei Ansichten und Detail-Overlay
**Status:** Zur Prüfung · **Priorität:** P2 · **Abhängigkeiten:** SF-057 · Nutzerauftrag 24.11.2026

- [x] Drei Tabs mit Icons im bestehenden Control-Add-in: **Generierung** (kompakter Kopf, Live-Zeile, Modulkarten, Laufauswahl, Aktionen), **Mandantendaten** (Datenumfang-/Lauffilter, dieselben Modulkarten mit Bestandszahlen, Entitäten ohne Generator im Overlay gekennzeichnet) und **Läufe** (Liste mit Branche, Modus, Kontenplan, Start, Laufzeit, Status, Fehler/Warnungen; Klick wählt den Lauf und öffnet die Generierungsansicht, Summenkacheln und Diagnose unverändert). Tab, Filter, Suche, Lauf und Overlay bleiben beim Wechsel erhalten.
- [x] Kopf um ca. 60 % niedriger (Zeilen: Titel/Status/Branche, Statuspillen `3/4 abgeschlossen`, aktueller Schritt + letzte Aktivität). Warnungen/Fehler als anklickbare Pillen; lange Texte (Buchungsübersprünge, Stammdatenpool, Qualität) im Overlay *Alle Details*.
- [x] Aufklappen ersetzt durch zentriertes Overlay innerhalb des Add-ins (Escape, Klick außerhalb, Schließen; Fokusrückgabe; intern scrollbar; wird gepatcht statt neu aufgebaut). Jede Entität einmal; Kennzahlen auf der Karte öffnen weiter direkt die BC-Liste. Karten mit einheitlicher Höhe (Spalten mind. 250 px, ≥ 4 pro Reihe bei 1440 px, > 6 bei 2200 px), Entitätsanzahl, grüner Haken, reservierter Balkenplatz, Modulstatus/-warnung an der Karte, Statusfilter und Modulsuche erst ab 5 bzw. 9 Modulen.
- [x] AL: Befehl `view` (Ansicht), `BuildView` baut alle Stockgruppen nur in der Mandantendatenansicht (Schlüssel `Gruppe/Schlüssel` wie Laufergebnisse, ein `OpenMetric`-Pfad), Laufergebnisse nur in der Generierungsansicht, Fehler-/Warnzähler je Lauf nur in der Läufeansicht. Älteres `stockGroup` entfällt. Neue Labels in `Translations/sf057.de.json`.
- [ ] Offen: AL-Build (nicht kompiliert), XLIFF-Sync, native Prüfung (Standardlistenfilter je Datenumfang/Lauf, Rechte, 20–30 Module, beide Scrollbars in BC). Eine Gesamtzahl erzeugter Datensätze wird bewusst nicht angezeigt (keine doppelfreie Quelle). Ohne Auswahl bleibt der Unternehmensfortschritt sichtbar; bei gewähltem Lauf zeigt die Generierungsansicht diesen Lauf.
- [ ] `scripts/check_dashboard_stock.mjs` testet die entfernte Gruppen-Oberfläche mit einer DOM-Attrappe und ist durch `check_dashboard.mjs` ersetzt; Löschung bedarf der Freigabe.

**Belege:** [dashboard.js](src/Monitoring/Dashboard/dashboard.js), [dashboard.css](src/Monitoring/Dashboard/dashboard.css), [BCSFDashboardStock.Codeunit.al](src/Monitoring/Codeunits/BCSFDashboardStock.Codeunit.al), [BCSFDashboardData.Codeunit.al](src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al), [BCSFDashboardPart.Page.al](src/Monitoring/Pages/BCSFDashboardPart.Page.al), [check_dashboard.mjs](scripts/check_dashboard.mjs), [DASHBOARD_EMBEDDING.md](docs/DASHBOARD_EMBEDDING.md#ansichten-und-detail-overlay-sf-058).
**Abnahme:** [ ] Menschliche Abnahme offen.

### Detaillierte Arbeitspakete für bereits bestehende offene Modultickets

**SF-028 – Warehouse (nach SF-053):** Setup-/Featurematrix nach Lagerort (`Bin Mandatory`, `Require Receive/Put-away/Pick/Shipment`, Directed Put-away and Pick), geeignete Lagerplätze/Zonen/Behälter und Standard-Warehouse-Stämme; getrennte Generatorpfade für Warehouse Receipt/Put-away, Pick/Shipment, Umlagerung und Inventur nach tatsächlich aktiver Standortkonfiguration. Menge, Reservierung, offene Belegmenge und Buchungsreihenfolge berücksichtigen; Warehouse Entries, Artikelposten, Lagerplatzinhalt/Wertposten nach Standardprozessen abstimmen. Ohne aktivierte Funktionen keine erfundenen WMS-Belege; Kompatibilität und Standardlisten/Drilldowns/DE-EN prüfen. Abnahme in zwei Lagerortkonfigurationen inkl. negativer Bestands-/Lagerplatzfälle und Wiederanlauf.

**SF-029 – Manufacturing (Assembly separat SF-054):** Artikel- und Produktionsstücklisten, Versionen, Arbeitsplätze/-gruppen, Arbeitspläne, Einheiten, Produktionskalender/Schichten, Komponentenverfügbarkeit und passende BC-Feature-/Lizenzprüfung. Freigegebene Produktionsaufträge, Komponentenverbrauch, Output, Teilmengen, Fertigmeldung und ggf. Kostenregulierung als Standardprozess, nicht direkte Posteninserts. Engpässe/fehlende Komponenten/gesperrte Perioden kontrolliert melden. Ist-Komponenten-/Output-/Kapazitäts-/Artikel-/Wert-/Sachposten abgleichen; unterschiedliche Losgrößen, Seeds, Batchgrößen und Wiederanlauf testen.

**SF-030 – Service Management (Projects separat SF-055):** Serviceartikel und Kundenbezug, Serviceverträge sofern verfügbar/gewählt, Wartungspläne/-intervalle, Serviceaufträge, Ersatzteile, Ressourcen-/Arbeitszeiten, Serviceverbrauch, Fakturierung und Standard-Serviceposten. Fehlende Serviceberechtigung/Erweiterung blockiert nur das gewählte Fachmodul, nicht den gesamten Mandanten. End-to-end zwei unterschiedliche Servicefälle inkl. Teilreparatur, Ressourcen-/Teileverfügbarkeit, berechneter Rechnung und Drilldown.

**SF-031 – Fixed Assets:** Anlagenbuchungsgruppen, Abschreibungsbücher, Anlagenklassen, Anschaffung über Standard-Anlagen-/Einkaufsbuchungsprozess, periodische Abschreibung und Verkauf/Abgang; Geschäftsperioden, Dimensionen, Rundung, Abschreibungsverfahren/Nutzungsdauer und Teilabgang nach Standard prüfen. Anlagen-/Sachposten und Restbuchwert abgleichen; ungebuchte Stammphase separat. Negative Fälle: fehlende Buchungsgruppe, geschlossene Periode, Doppelabschreibung/zweiter Lauf.

**SF-033 – CRM (Disposition separat SF-056):** Kontakte/Unternehmen/Personen, Beziehungen zum Debitor/Kreditor, Aktivitäten, Verkaufschancen, Aufgaben, Kampagnen/Segmente soweit in BC-Standard und Lizenz vorhanden; realistische B2B-Vertriebspipeline, nachvollziehbare Statusübergänge und optional Übergang zu Angebot/Auftrag (nur wenn Sales aktiviert). Ausgewählte Kontakte nicht duplizieren; Kontakte aus Fremdstämmen nur mit ausdrücklichem, datenschutzgeeignetem Testmodus. CRM-Aufgaben nicht als gebuchte Belege ausgeben; Zugriff, Testdaten, Drilldowns und DE/EN prüfen.

**SF-032 – Branchenfreigabe:** Pro zusätzlichem Profil getrennte Freigabe nur bei verfügbaren getesteten Modulbausteinen, profiltypischen internen Produkt-/Partner-/Preis-/Belegmustern und neutraler Modul-Pipeline. Erste Kandidaten aus bestehendem TODO: E-Commerce/Einzelhandel, Fertigung, Dienstleistungen, Bau, Logistik, Wartung. Weitere mögliche Unterprofile nur nach fachlicher Spezifikation; eine adesso-Wirtschaftsbranche impliziert kein vorhandenes BC-Standardmodul. Pro Profil kleiner/mittlerer nativer Durchlauf, Modulauswahl, Bestands-/Buchungs-/Drilldownqualität, Wiederverwendung in vorhandener Firma, DE/EN und Versionierung. Nicht freigegebene Branchen nicht anklickbar anbieten.

**Ressourcen-/Performancegate SF-026:** Erst nach stabilen klein/mittel Szenarien 1k/10k/50k/100k stufenweise benchmarken, Laufdauer, Laufzeitlimit, Speicher, Datenbankzugriffe, Queue, abgebrochene/übersprungene Postings und Wiederanlauf dokumentieren; bei Grenzwerten kontrolliert begrenzen statt instabil weiterzulaufen.

---

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
