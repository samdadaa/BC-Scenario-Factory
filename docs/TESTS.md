# Teststrategie und Evidenz — BC Scenario Factory

## Regel für Coding-Agenten

Keine Tests, Compilerläufe oder Sandbox-Effekte als erfolgreich melden, wenn sie nicht wirklich ausgeführt wurden. **Neue Test-Codeunits nur bei ausdrücklichem Ticketauftrag erzeugen**; bestehende Tests und manuelle Prüfschritte nach Möglichkeit anwenden. Das Testniveau richtet sich nach Risiko und Änderung.

## Teststufen

| Stufe | Inhalt | Was als Nachweis zählt |
| --- | --- | --- |
| Codeprüfung | ID-Bereiche, Naming, Abhängigkeiten, Events, Rechte | Betroffene Dateien, konkrete Erkenntnisse |
| Compile / Analyzer | AL Language, richtige Symbols/BC-Version, projektkonfigurierte Analyzer | Tatsächliches Kommando/IDE-Aktion und Ergebnis |
| Unit-/Integrationstests | AL Test Codeunits, Setup, Fehlerpfade, Rechte | Test-ID, Umgebung, Resultat |
| Fachliche Prüfung | Ist-/Soll-Verhalten inkl. Sonderfälle | Eingaben, Schritte, erwartete und beobachtete Ergebnisse |
| Regression / Last | Vorheriges Verhalten, Massenverarbeitung, Locking | Realistische Datenmengen, Messzeit, Vergleich und Einschränkungen |

## Projektstruktur App/Test

Bei **AL-Go** und getrennten Projekten:
- `App/` für Anwendungscode, `Test/` für Testobjekte, je eigenes `app.json`.
- `Test` referenziert `App`, nicht umgekehrt.
- Testordner entlang fachlicher Features strukturieren, gemeinsam genutzte Testhelfer separat.
- Nicht ohne Auftrag ein Testprojekt erzeugen oder vorhandene Projektstruktur umbauen.

Im **einzelnen AL-Projekt** ist eine getrennte Test-App optional bzw. von vorhandener Architektur abhängig. Nicht automatisch AL-Go voraussetzen.

## Prüfprotokoll für ein Ticket

| Feld | Eintrag |
| --- | --- |
| Ticket / Änderung | Zu prüfen |
| Getestete AL-Objekte | Zu prüfen |
| BC-Version / Runtime | Zu prüfen |
| Umgebung, nur nicht-sensible Bezeichnung | Zu prüfen |
| Testdaten, anonymisiert | Zu prüfen |
| Ausgeführt am / durch | Zu prüfen |
| Build/Analyzer | Nicht ausgeführt |
| Automatisierte Tests | Nicht ausgeführt |
| Manuelle Szenarien | Nicht ausgeführt |
| Ergebnis und Fehler | Zu prüfen |
| Offene Risiken / Regressionen | Zu prüfen |

## Mindestfälle für fachliche Änderungen

- Erfolgsfall (Happy Path), leerer/ungültiger Input, fehlende Berechtigung, wiederholte Ausführung (Doppelverarbeitung), Teilfehler, Datums-/Rundungsgrenzen, bestehende Daten; Massendaten nur, wenn relevant.
- Bei Buchungen zusätzlich gebuchte/ungebuchte Belege, Ausgleich, Storno, Mehrwertsteuer, Dimensionswerte, Fehlerabbruch und Recovery prüfen, soweit fachlich zutreffend.
- Bei Events zusätzlich Subscriber-Kombinationen und Erweiterbarkeit; bei APIs Fehlantworten, idempotente Wiederholung und Authentifizierung.

Quelle: https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-testing/


## Projektbezogene Testmatrix (Plan; alles noch offen)

| Testfall | Erwartung |
| --- | --- |
| Sandbox vs. Produktion | Mutation nur in freigegebener Testumgebung; Produktion blockiert |
| Setup vorgefüllt vs. unvollständig | Preflight zeigt präzise Differenz; überschreibt nichts ungefragt |
| Nur Stammdaten | Keine Belege/Posten |
| Ungebucht | Vollständige Stammdaten und Dokumente, keine Buchungsposten aus diesen Dokumenten |
| Gebucht | Resultate ausschließlich via Standardbuchung; Ledger-/Belegbeziehungen stimmen |
| Voller Prozess | Lieferung/Rechnung/Zahlung/Ausgleich im freigegebenen Umfang korrekt |
| Branche/Seed | Plausible Variationen; reproduzierbare Eingangsdaten je gleicher Konfiguration |
| 1.000/10.000/50.000/100.000 | Pro Entität gemessene Verarbeitung, Soll-Ist, Fehler und Ressourcen beachten |
| Ausfall während des N-ten Batches | Fortsetzung ohne doppelte Stammdaten und vor allem ohne Doppelbuchung |
| Zwei parallele Jobs | Kein mehrfach geclaimter/gebuchter Batch |
| Falsche Dimension/MwSt./No.Series | Blocker oder gezielter Negativtest, kein stiller Datenfehler |
| Abgebrochener/pausierter Lauf | Status konsistent, abhängige Schritte warten, keine falsche Erfolgsmeldung |
| Dashboard-Summen | Soll/erstellt/validiert/gebucht differenziert, nachvollziehbare Drilldowns |
| Test- und Schulungsfälle | Erwartete Lernziele und Belegzustände fachlich überprüfbar |

**Evidenz:** Lauf-ID, Konfiguration/Snapshot, BC-Version, Testergebnis, reale Messwerte und Abweichungen dokumentieren. Keine Performancezahl oder Testbestehen ohne tatsächlichen Lauf behaupten.

## SF-001 – lokales Prüfprotokoll vom 11.11.2026

**Ausgeführt durch:** Codex, lokaler Projektworkspace. Keine BC-Testdaten oder AL-Testobjekte angelegt. BC-Version/Runtime: nur Manifestwerte `28.0.0.0`/`17.0`; tatsächliche Zielumgebung **Zu prüfen**.

Die folgende Tabelle dokumentiert die Erstprüfung vor der Nutzerrückmeldung. Aktuelle Konfigurationsänderungen und deren Prüfung stehen im Nachtrag unten; insbesondere gilt „bytegleich zu HEAD“ nur für die Erstprüfung.

| Prüfung / Methode | Tatsächliches Ergebnis |
| --- | --- |
| Pflichtdokumentation und Ticket lesen | README, AGENTS, Manifest, Projekt-/Moduldokumentation und SF-001 geprüft; keine bestätigten Publisher-/ID-/Umgebungswerte gefunden |
| XERJ-Projektsuche | `xerj_map` und `xerj_batch_search` ausschließlich für `bcsf-docs`; relevante Treffer zu SF-001 und offenen Konfigurationen gegen lokale Dateien geprüft |
| Manifest / Python-JSON-Parser | Gültiges JSON; bestehende App-ID, Versionen, Dependencies und ID-Range gelesen. Keine Kompatibilitätsprüfung durch AL-Compiler |
| Dateiinventar / `rg --files --hidden`, Python `Path.rglob` | 0 AL-Dateien, 24 Modulverzeichnisse mit `.gitkeep`; keine vorhandenen AL-Tests oder Objektdeklarationen |
| Symbole / Python `Path.glob` | 0 `.app`-Dateien in `.alpackages`; kein Symbolbezug ausgeführt |
| Launch-Konfiguration / Python-Parser nach Entfernen von JSONC-Zeilenkommentaren | Zwei Sandbox-Profile mit gleichem Anzeigenamen, abweichend `Playgrund`/`Playground`; keine Firma festgelegt. Konfigurationsinhalt ist kein Nachweis einer existierenden Sandbox |
| Werkzeuge / `shutil.which`, lokale Erweiterungsdateien | `dotnet` gefunden; `alc` und `code` nicht im PATH. AL-Erweiterung `18.1.2842859` mit `alc.dll`/`alc.exe` gefunden; Befehle `al.downloadSymbols` und `al.package` in `package.json` nachgewiesen |
| Abschlussprüfung / Python-Assertions, `git diff --check` | Manifest/App-ID/Range und 24 leere Module bestätigt; Manifest und Launch bytegleich zu HEAD; sämtliche übrigen Tickettexte unverändert, SF-001-Status in Übersicht und Detail konsistent, lokale Linkdateien vorhanden. Abschließende Whitespace-Prüfung ohne Befund |

**Nicht ausgeführt:** Compiler, Analyzer, AL-Unit-/Integrationstests, Sandbox-Anmeldung/Erreichbarkeit, Prüfung installierter Fremd-Apps, Rechte-/Firmenprüfung, Veröffentlichung, Deployment und fachliche Regression/Lasttests. Gründe: Zielkonfiguration nicht bestätigt, keine Symbole oder AL-Objekte vorhanden. Lokale Compilerdateien belegen noch keine ausführbare oder kompatible Build-Umgebung.

**Offene Risiken:** Externe ID-Kollisionen, ungeklärte Range-Kapazität, Platzhalter-Publisher, falsches Sandbox-Profil, unbekannte Firmen-/Lokalisierungsdaten und ungeprüfte Versionskompatibilität. Die entscheidungsabhängigen Akzeptanzkriterien von SF-001 sind noch nicht erfüllt. Nächste Prüfschritte stehen im vorbereiteten Symbol-/Build-Weg in [PROJECT.md](PROJECT.md#vorbereiteter-symbol-build-weg).

### Nachtrag nach Nutzerrückmeldung (11.11.2026)

**Umgesetzt:** `Playground`, Entwicklungsmodus, vom Nutzer delegierte Range-Auswahl `50100..50999`. Erstes Launch-Profil umbenannt und Schreibweise des Ziels korrigiert; beide Profile erhalten. README, PROJECT, DECISIONS und SF-001 aktualisiert.

**Tatsächlich ausgeführt:** Python-Assertions bestätigen gültige Konfiguration, 900 ID-Werte innerhalb `50000..99999`, unveränderte übrige Manifestwerte, ausschließlich Name/Ziel des ersten Launch-Profils geändert, zwei eindeutige Profilnamen und beide Ziele `Sandbox`/`Playground`. Weiterhin 0 AL-Dateien und 24 Modulmarker; alle anderen Tickettexte unverändert, lokale Linkdateien vorhanden. `git diff --check` ohne Befund. Bereichseignung anhand Microsoft Learn geprüft; Quellenlink in DECISIONS.

**Weiterhin nicht ausgeführt:** Build/Analyzer, Symbol-Download, Sandbox-Verbindung, externe Kollisions- und Rechteprüfung. Publisher, tatsächliche BC-Version, Lokalisierung und Testfirma bleiben offen. Die Zielschreibweise und Auswahl sind jetzt geklärt; technische Erreichbarkeit und externe Kollisionsfreiheit folgen daraus nicht.


## SF-002 – Planprüfung vom 11.11.2026

**Umgebung:** Lokaler Workspace, Codex. Manifest aktuell `90100..90999`, Application `28.0.0.0`, Runtime `17.0`; letztere sind keine nachgewiesenen Sandbox-Versionen. Nutzer bestätigt den neuen Bereich und `Playground` im Entwicklungsmodus. Vor Änderungen wurden TODO, app.json und launch.json lokal für einen Vergleich gesichert (außerhalb des Projekts, ohne Zugangsdaten).

**Ausgeführt:** XERJ-Suche ausschließlich in `bcsf-docs`, Ergebnisse gegen lokale Dateien geprüft; Pflichtdokumentation und Modulaufträge gelesen. [OBJECT_PLAN.md](OBJECT_PLAN.md) mit Python aus dem geschriebenen Markdown geprüft:

| Prüfung | Tatsächliches Ergebnis |
| --- | --- |
| Vollständigkeit / Range | Genau 24 Modulblöcke à 25 Werte, vollständig innerhalb des aktuellen Manifests; keine Überlappungen; 600 Werte zugeordnet und 300 gemeinsame Reserve |
| Objektplan / Naming | 59 numerische Planobjekte mit eindeutigen IDs, Namen und Dateipfaden; Namen einschließlich Präfix maximal 30 Zeichen; IDs im jeweiligen Modulblock; Ticketreferenzen vorhanden. Ein Interface separat ohne deklarierte numerische ID geplant |
| Codegraph | Alle referenzierten Module vorhanden; geplanter Graph zyklenfrei. Modulabhängigkeiten von fachlichen Ablaufvoraussetzungen getrennt |
| Negative Varianten | Bereich außerhalb des Manifests, überlappende Blöcke, doppelter Objektname, überlanger Name und Core/Registry-Zyklus jeweils als ungültig erkannt; nur im Arbeitsspeicher, keine fehlerhaften Projektdateien angelegt |
| Bestand / Scope | 0 AL-Dateien, 24 unverändert leere Module; app.json und launch.json bytegleich zur Sicherung vor SF-002. Alle anderen Ticketdetails einschließlich SF-001 unverändert; lokale Linkdateien vorhanden |
| Dokumentations-Diff | Whitespace-Prüfung auf die SF-002-Dokumentationsdateien ohne Befund. Globaler `git diff --check` meldet eine bereits vor SF-002 vorhandene Leerzeichenzeile in `.vscode/launch.json:4`; diese Datei wurde nicht geändert |

**Nicht ausgeführt:** AL-Compiler/Analyzer, AL-Tests, Sandbox-Verbindung, BC-Berechtigungs- und externe Kollisionsprüfung. Kein AL-Code und kein Testobjekt erstellt, keine Standard-BC-API oder Commit-Garantie als geprüft behauptet. Wiederholung/Teilfehler/Berechtigungsfälle von BC-Läufen sind bei dieser Dokumentationsänderung nicht anwendbar. Noch offene technische Voraussetzungen aus SF-001 bleiben vor der betreffenden Implementierung zu klären; menschliche Prüfung des Entwurfs steht aus. Status SF-002: **Zur Prüfung**.


## SF-003/SF-004 – tatsächliche Prüfungen vom 11.11.2026

**Scope:** Beide Tickets ausdrücklich gemeinsam beauftragt. Neun neue AL-Objekte unter Core/Lifecycle; keine neuen Test-Codeunits in der App und keine Umsetzung der separaten Test-App aus SF-025. Keine echten Daten oder BC-Schreiboperationen durchgeführt. Status beider Tickets: zur Prüfung, keine Laufzeitabnahme.

### Ausgeführt

| Prüfung | Tatsächliches Ergebnis |
| --- | --- |
| Projekt-/Symbolinventar | Vor Beginn 0 AL-Objekte; jetzt 9. Fünf vorhandene Microsoft-Pakete in `.alpackages`: System 28.0.57066.0; System Application und Base Application 28.5.54976.57342; Application und Business Foundation 28.5.54976.56550. Application-Metadaten DE, Runtime 17 |
| Versionsgerechte API | Lokale SymbolReference/Quellen von Environment Information (Codeunit 457) enthalten IsProduction, IsSaaS, IsSandbox, GetEnvironmentName; verwendete API gegen diese Pakete kompiliert. Datenbankevent-Signaturen und Read/WritePermission anhand Microsoft-Dokumentation geprüft |
| Compiler-Erstversuch | System-dotnet startete alc.dll nicht (Exit 150): .NET 10 benötigt, nur .NET 8.0.8 systemweit vorhanden. Daraufhin vorhandenen VS-Code-.NET-10.0.15-Cache gefunden; keine Installation |
| AL-Build/Analyzer | AL Compiler 18.1.43.24897, Runtime 17, Cloud-Ziel, CodeCop und UICop, `warnaserror+`, `generatecode+`: Exit 0, 9 Dateien, keine Fehler/Warnungen. Erzeugtes Paket im temporären Arbeitsverzeichnis außerhalb des Projekts (36.836 Bytes beim protokollierten Build); nicht veröffentlicht |
| IDs/Namen/Pfade | 9 eindeutige IDs/Namen, maximal 30 Zeichen, passende Namespaces/Dateinamen und Objektplan; neue Core-Codeunits 90106/90107 aus freien Werten. Keine Kollision mit 8.361 untersuchten Objektdeklarationen in den fünf lokalen Microsoft-Paketen. Kein Nachweis für sonstige installierte Apps |
| Statische Security-Prüfung | Vier Before-Datenbankevent-Subscriber mit beiden Skip-Flags false; keine RunTrigger-/GuiAllowed-Ausnahme. Production-/SaaS-/Sandbox-, Namens-/Firmen-/Rechteprüfungen vorhanden; Guard liest eigenes lokales Setup. Keine erhöhten Codeunit-Permissions, HTTP-Aufrufe, TryFunctions oder explizite Commits |
| Rechte/Defaults | Permission Set gibt nur Setup RIM und die benötigte Ausführung frei, keine Delete-/Standarddatenrechte. Initialisierung setzt Generation/Posting ausdrücklich false. OnOpenPage/GetSetup initialisieren nicht. Core hat keine ausführbare Lifecycle-Rückabhängigkeit; nur deklarative Permission-Set-Referenz |
| Statusgraph | Source-basierte Graphprüfung (kein AL-Laufzeittest): alle 13 Enumzustände vorhanden und von Draft erreichbar, Ziele gültig, Endzustände verlassen sich nicht, Failed/ResumePending führen nicht direkt nach Running. Einrückungsprüfung korrigierte eine einzelne Fortsetzungszeile; anschließend Zweierschritte ohne Tabs |
| Scope/Diff | Manifest und Launch-Konfiguration seit Ticketbeginn bytegleich; alle anderen Ticketdetails unverändert. Nur benötigte Foundation-/Dokumentationsdateien geändert, keine Verschiebungen/Löschungen. Neue AL-Dateien und lokale Dokumentationslinks geprüft. Dokumentations-/Source-Whitespace-Prüfung ohne Befund; globale bereits vorhandene Leerzeichenzeile in launch.json bleibt unberührt |

Reproduzierbarer Build-Aufruf (lokale Pfade über den tatsächlich vorhandenen VS-Code-Cache auflösen): `dotnet alc.dll /project:<Projekt> /packagecachepath:<Projekt>/.alpackages /out:<temporärer Pfad>/BCScenarioFactory.app /target:Cloud /generatecode+ /warnaserror+ /analyzer:<CodeCop.dll>,<UICop.dll>`. Beim ausgeführten Aufruf wurde der dotnet-Host aus `10.0.15~arm64~aspnetcore` und alc.dll samt Analyzer aus `ms-dynamics-smb.al-18.1.2842859/bin` verwendet, nicht das systemweite dotnet. Nachweise und Paket liegen nur im temporären lokalen Arbeitsverzeichnis; keine Deployment-/Login-/Download-Aktion.

### Noch auszuführende BC-Laufzeitfälle

**Alle folgenden Fälle sind beschrieben, aber nicht ausgeführt.** Kompilierung und Source-Analyse sind kein Nachweis ihres Laufzeitbestehens. Nur in einer freigegebenen Testumgebung bzw. über einen isolierten Test-Harness ausführen; keine unautorisierte Produktionserprobung.

| Ticket/Fall | Eingabe / Aktion | Erwartung |
| --- | --- | --- |
| SF-003 Produktion | Produktionsmetadaten, auch mit Namen Playground | Initialisierungs-Insert/Modify und Guard-Aufruf abgewiesen |
| SF-003 unbekannt/On-Prem | IsSandbox false oder IsSaaS false | Gesperrt; kein Test-Bypass |
| SF-003 falsches Ziel | Tatsächlicher Name weicht ab; Ziel-/Setup-Firma weicht von Sitzung ab | Abgewiesen; auch direkte ChangeCompany-Schreibversuche |
| SF-003 fehlende Rechte | Kein Read, kein Write, Security Filter auf anderen Schlüssel oder kein Execute auf Subscriber | Keine Mutation/Generierungsfreigabe; keine still übersprungenen Subscriber |
| SF-003 Initialisierung | Playground, berechtigter Benutzer, isolierte aktuelle Testfirma, noch kein Setup | Genau ein Setup mit Generation/Posting false; erneute Initialisierung verändert Werte nicht |
| SF-003 Disabled/fehlend | Guard ohne Setup oder mit Generation false | Abgewiesen, auch in Hintergrundsitzung |
| SF-003 nicht buchender Erfolg | Gültiges aktiviertes Setup, SetupAndMasterData bzw. UnpostedDocuments, Records 1 und Batch 1 | Guard kehrt erfolgreich zurück; erzeugt selbst keine Daten |
| SF-003 Posting | PostedMovements/FollowUpProcesses ohne Posting Enabled oder ohne aufrufspezifische Zustimmung | Abgewiesen; nur mit beiden Freigaben zulässig |
| SF-003 Mengen | Records oder Batch 0/negativ/über Maximum, Batch größer als Entitätsziel | Abgewiesen; exakt konfigurierte Grenzen zulässig |
| SF-003 direkte DB-Pfade | Insert(false), Modify(false), ModifyAll, RecordRef, Delete/DeleteAll, Rename | Sicherheits-/Datensatzprüfung auch ohne Tabellen-/Feldtrigger; Delete/Rename stets abgewiesen |
| SF-003 Background/Temporary | Identische Anfragen ohne GUI bzw. mit temporärem Setup-Record | Keine automatische Freigabe; Guard verwendet eigenes persistiertes Setup |
| SF-004 ungültige Settings | Falscher Singleton-Key, leere Freigabeangaben, Mengen 0/negativ, Default-Batch größer Maximum, Maximum-Batch größer Entitätsmaximum | Speichern abgewiesen, auch bei direkter Feldzuweisung ohne Validate |
| SF-004 Modi | Unbekannte Enumwerte über FromInteger; Default-Postingmodus bei Posting false | Abgewiesen; vier definierte Prozess-/Nutzungsmodi gültig |
| SF-004 Persistenz | Einstellungen ändern, schließen/neu öffnen, GetSetup aufrufen | Werte bleiben konsistent erhalten, keine automatische Initialisierung beim Lesen |
| SF-004 Seed | Integer-Minimum, 0, 1, Integer-Maximum | Als Seed-Konfiguration erlaubt; noch keine Seed-Engine-Verarbeitung |
| SF-004 GUIDs | Leere/nichtleere Run-/Batch-GUID zweimal an Ensure...Id übergeben | Leere IDs einmal neu, vorhandene unverändert. Persistenz durch späteren Aufrufer, keine Batch-Doppelbuchungszusage |
| SF-004 Übergänge | Draft→Preflight→Ready→Queued→Running→Completed, Wiederholung des Zustands, Failed→Running, Completed→Draft, unbekannter Status | Erlaubte Übergänge/No-ops akzeptiert, unzulässige abgewiesen; CheckTransition schreibt nicht |
| SF-004 Teilfehler/Konkurrenz | Ungültige Änderung beim Speichern; zwei parallele Initialisierungen | Fehlerhafte Operation nicht persistiert; ein Singleton, keine Rücksetzung vorhandener Freigaben |

**Verbleibende Grenzen:** Kein Login/Deployment, keine ausgeführten AL-Unit-/Integrations-/Lasttests, kein Nachweis tatsächlich vorhandener Testfirma/Rechte, keine Kollisionsprüfung gegen unbekannte Fremd-Apps. Build nur gegen vorhandene 28.5-Pakete, nicht gegen ursprüngliche 28.0-Pakete oder jede Lokalisierung. Spätere Worker/Generatoren müssen den Guard und konkrete Standardtabellenrechte einbinden; sie existieren hier noch nicht.
