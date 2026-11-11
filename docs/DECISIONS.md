# Architekturentscheidungen und offene Fragen

> Status: **Bestätigt** = durch den Nutzer im Gespräch festgelegt; **Vorschlag** = Designidee ohne Implementierungsfreigabe; **Zu prüfen** = erfordert technische/fachliche Entscheidung. Keine Entscheidung hier autorisiert automatisch Codeänderungen.

| ID | Status | Thema | Vereinbarung / offene Frage |
| --- | --- | --- | --- |
| ADR-01 | Bestätigt | Produktziel | Branchenabhängige, fachlich echte, synthetische Demo-/Schulungs-/Test-/Performance-Daten statt gleichförmiger Massendatensätze |
| ADR-02 | Bestätigt | Auswahl | Branche, Module, Datenmengen, Buchungs-/Prozessmodus konfigurierbar |
| ADR-03 | Bestätigt | Background | Generierung über Aufgabenwarteschlange mit Dashboard, Fortschritt und Kontrolle auch ohne aktive Browser-Sitzung |
| ADR-04 | Bestätigt | Struktur | `src/<Modul>/` ohne leere Typ-Unterordner; Dokumentation & AGENTS-Regeln erhalten |
| ADR-05 | Bestätigt | XERJ | XERJ nur lokal mit Codex nutzen/testen, **keine BC-Integration** |
| ADR-06 | Vorschlag | Branchenstart | Großhandel als erstes Profil, Finance/Sales/Purchasing/Inventory als MVP-Fachmodule |
| ADR-07 | Vorschlag | SDK | Generator-Interface + Registry + Dependency Graph; tatsächliche AL-Signatur zu prüfen |
| ADR-08 | Teilweise bestätigt | Zielumgebung | Nutzer bestätigt `Playground`, Entwicklungsmodus. Tatsächlicher Sandbox-Typ, Version, Lokalisierung und Rechte technisch noch zu prüfen |
| ADR-09 | Zu prüfen | Setup | Bestehende Demo-Konfiguration zuerst nutzen oder leere Firma selbst aufbauen? Hybrid-Preflight vorgeschlagen |
| ADR-10 | Bestätigt | IDs | Nutzer hat das Manifest auf `90100..90999` geändert und diesen Bereich für SF-002 ausdrücklich bestätigt; ersetzt die frühere Auswahl `50100..50999`. Lokal 0 Objekte; externe Belegung zu prüfen |
| ADR-11 | Zu prüfen | Publisher | `Default Publisher` ersetzen, aber nur nach ausdrücklicher Festlegung |
| ADR-12 | Vorschlag | Sicherheit | Sandbox-only für alle mutierenden Abläufe; Blockade produktiver Umgebungen und keine direkten Ledger-Inserts |
| ADR-13 | Vorschlag | Test-Apps | Test-Codeunits in separater AL-Test-App vorsehen; Aufbau nach Ziel-Workspace klären |
| ADR-14 | Zu prüfen | Länder | DE-Fokus als mögliche erste Lokalisierung; Steuer-/Währungs-/Adressregeln nicht erfinden |
| ADR-15 | Zu prüfen | Bereinigung | Umgang mit bereits gebuchten Testdaten; neue Firma/Sandbox oder standardkonforme Gegenbuchung je Szenario |
| ADR-16 | Zu prüfen | Parallelität | Unterstützte Queue-Batching-/Lock-Strategie und zulässige Laufzeiten in Zielversion testen |

## SF-001 – ausstehende Festlegungen

**Erstprüfung 11.11.2026, vor Nutzerrückmeldung:** Lokaler Bestand geprüft; Konfigurationswerte zunächst unverändert gelassen. Die anschließend bestätigten Festlegungen und Änderungen stehen unten. SF-001 bleibt wegen der verbleibenden offenen Angaben **Blockiert**; Prüfbericht und vorbereiteter Symbol-/Build-Weg liegen in [PROJECT.md](PROJECT.md#sf-001--aktuelle-bestandsprüfung-vom-11112026).

| Entscheidung | Konkrete Klärungsfrage / benötigter Nachweis |
| --- | --- |
| Publisher (ADR-11) | Welcher exakte Publisher soll `Default Publisher` ersetzen? |
| Veröffentlichungsziel | Aktuell ausdrücklich Entwicklungsmodus. Ein späteres PTE-/AppSource-Releaseziel bleibt zu prüfen; für diesen Entwicklungsschritt nicht erforderlich |
| Objektbereich (ADR-10) | Auswahl delegiert und umgesetzt: `50100..50999`. Noch offen: Kollisionen gegen installierte Apps und externe Reservierungen prüfen |
| Ziel-Sandbox (ADR-08) | `Playground` vom Nutzer bestätigt. Tatsächlichen Umgebungstyp und Erreichbarkeit technisch prüfen; keine Tenant-Zugangsdaten dokumentieren |
| Version (ADR-08) | Welche BC-/Application-Version und Runtime gelten tatsächlich? `28.0.0.0`/`17.0` sind bisher nur Manifestwerte; passende Symbole und Compilerprüfung fehlen |
| Lokalisierung (ADR-14) | Welche Landesversion soll zuerst unterstützt und geprüft werden? DE bleibt ein Vorschlag |
| Testfirma / Ausgangsdaten (ADR-09) | Welche isolierte Testfirma wird verwendet: vorhandene Demokonfiguration oder separate leere Firma? Vollautomatischer Leeraufbau bleibt außerhalb des initialen MVP |
| Rechte / Verantwortung | Wer kann die Sandbox bestätigen und Symbolzugriff sowie nötige Entwicklungsrechte prüfen? Keine Passwörter oder Tokens übermitteln |

**Umgesetzte ID-Strategie:** `50100..50999` umfasst 900 ID-Werte und erhält den bisherigen Startwert. Als Planungsbudget wären beispielsweise 20 Werte je geplantem Modul (480) plus 420 Reserve möglich; dies ist keine Objektzählung, Reservierung oder Modulallokation. Die konkrete Belegung gehört zu SF-002. Der Nutzer hat die Auswahl ausdrücklich delegiert; die Range liegt im Microsoft-Bereich `50000..99999` für Anpassungen/Testzwecke. Quelle: [Microsoft Learn – Object ranges](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-object-ranges#50000-99999), geprüft am 11.11.2026. Keine Zusage externer Kollisionsfreiheit oder AppSource-Zuteilung.

Die Fragen wurden dem Nutzer am 11.11.2026 gestellt. Offene Antworten bleiben **Zu prüfen**; technische Erreichbarkeit, Kompatibilität und menschliche Abnahme sind noch nicht nachgewiesen.

### Bestätigte Nutzerrückmeldung und Umsetzung (11.11.2026)

- Nutzer: „Playground, Dev Modus und wähle einen Objekt id Range passend für unser Vorhaben“.
- `app.json`: Endwert von `50149` auf `50999` erweitert; App-ID, Publisher, Versionswerte und Dependencies erhalten.
- `.vscode/launch.json`: Erstes Profil als `BC Scenario Factory - Playground (Dev)` benannt, Schreibweise `Playgrund` auf `Playground` korrigiert. Zweites Profil erhalten; beide zeigen auf dieselbe bestätigte Sandbox und haben unterschiedliche Anzeigenamen. Vorhandene Debug-Einstellungen erhalten; kein eigenständiges erfundenes Manifestfeld für „Dev Modus“ ergänzt.
- Weiterhin offen: exakter Publisher, technische Versions-/Umgebungsprüfung, Lokalisierung und Testfirma. Keine Veröffentlichung oder Bereitstellung ausgeführt.

## SF-002 – Entwurfsentscheidungen zur Prüfung (11.11.2026)

Der Auftrag zur nächsten Todo wird als SF-002 bearbeitet; der Nutzer bestätigt ausdrücklich die neue Manifest-Range `90100..90999`. Die folgenden technischen Festlegungen entstehen im beauftragten Entwurf, sind keine behauptete menschliche Abnahme:

- Präfix `BCSF`, Namespace `BCScenarioFactory.<Modul>`, vollständige Typnamen in Dateinamen und 2 Leerzeichen für neue AL-Dateien.
- 24 disjunkte Modulblöcke à 25 Werte und 300 gemeinsame Reservewerte. Konkrete Zuordnung von 59 geplanten numerischen Objekten und einem Interface in [OBJECT_PLAN.md](OBJECT_PLAN.md).
- Core ohne Projekt-Codeabhängigkeiten; Generatorvertrag in ModuleRegistry, Snapshot/Run-Kontext in ScenarioManagement. Fachliche Prozessabhängigkeiten sind Planner-Daten, keine gegenseitigen Fachgenerator-Imports. Modulspezifikationen daran angeglichen.
- Die Dokumentationsplanung kann trotz SF-001-Restpunkten geprüft werden. Neue AL-Implementierung erfordert weiterhin die im jeweiligen Ticket nötigen Versions-/Umgebungsnachweise. SF-001 bleibt unverändert, keine Folgeimplementierung.


## SF-003/SF-004 – umgesetzte technische Entscheidungen zur Prüfung

Der Nutzer beauftragt ausdrücklich beide Tickets gemeinsam; die Ein-Ticket-Regel begrenzt hier nicht den ausdrücklich erweiterten Umfang. Es werden keine weiteren Tickets implementiert oder als abgenommen markiert.

- Firmentrennung per DataPerCompany-Singleton; explizite Initialisierung, Generation/Posting aus. Defaults: Seed 1, Batch 100, Maximum Batch 1.000, Maximum pro Entität 100.000; technische Startwerte, keine fachlichen Mengenvorgaben oder Leistungsgarantien.
- Nur bestätigbarer SaaS-Sandbox-Kontext; tatsächliche Metadaten plus erlaubter Name/Firma, auch ohne UI. On-Premises/Docker benötigt einen neuen abgestimmten Sicherheitsvertrag und ist momentan gesperrt.
- Guard über verpflichtende Before-Datenbankevents, damit Core nicht ausführbar von Lifecycle abhängt; deklarative Permission-Set-Referenz ausdrücklich ausgenommen. Keine nach Namen geprüfte Benutzerrolle, sondern effektive Rechte und BC-Datenbankprüfung. Keine pauschalen Standarddatenrechte.
- Neue, freie Core-IDs 90106/90107 für Setup Management und Run State Mgt, im Objektplan nachgeführt. Run-/Batch-Tabellen und Batch-Enum bleiben bei späteren Tickets. GUID-Hilfen erhalten bestehende IDs, persistieren aber nicht selbst.
- Lokale fünf Microsoft-Symbolpakete sind jetzt nachgewiesen; tatsächliche APIs und erfolgreicher Cloud-Build mit CodeCop/UICop geprüft. Keine Behauptung, dass die Sandbox erreichbar oder negativ auf Produktion getestet wurde.

Konkrete Felder, Guard-Aufruf und Zustandsübergänge: [FOUNDATION.md](FOUNDATION.md). Noch ausstehende Laufzeitfälle: [TESTS.md](TESTS.md). Beide Tickets maximal `Zur Prüfung`.


## SF-005/SF-006 – bestätigte Sprachvorgabe und Umsetzung

Nutzer beauftragt ausdrücklich beide Tickets und Deutsch/Englisch einschließlich generierter Inhalte. **Bestätigte Regel:** Automatisch Deutsch für jede deutsche Sprachregion, sonst Englisch. Oberfläche folgt der BC-Sprachauswahl; Datensprache zusätzlich explizit konfigurierbar, Auflösung bei Snapshot-Erstellung. UI-XLIFF und Datenkatalog sind getrennt, da BC gespeicherte Geschäftsdaten nicht automatisch übersetzt.

Umgesetzte technische Entscheidungen zur Prüfung: GUID-/revisionsbasierte Vorlagen, vollständige JSON-Snapshots Schema 1, Draft ohne Queue, nach Insert immutable Köpfe/Payloads, separate Mengen/Quoten pro Entität, abgerundete gebuchte/teilweise Mengen mit Rest auf ungebucht. Modul-/Profilbezeichner ersetzen keine spätere Capability-/Preflight-Prüfung. Nur Snapshot Writer erhält indirekte Insert-Rechte auf eigene immutable Tabellen. Der ursprüngliche Foundation-Vertrag wird für neue temporäre Anzeigezeilen und deklarative Rollenaggregation präzisiert, nicht für Standarddaten gelockert.

Details, neue IDs und tatsächliche Build-/Übersetzungsnachweise: [OBJECT_PLAN.md](OBJECT_PLAN.md), [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md), [TESTS.md](TESTS.md). Keine automatische Abnahme anderer Tickets.
