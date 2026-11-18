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


## SF-005/SF-006 und Deutsch/Englisch – Prüfungen vom 11.11.2026

**Beauftragt:** Beide Tickets plus zweisprachige UI-/Datengrundlage. Vor Änderungen Manifest, Launch, TODO und vorhandene neun AL-Dateien lokal gesichert. Aktuell 32 AL-Objekte; App/Test nicht vermischt, keine neue AL-Test-App und keine Standard-BC-Datengenerierung. Keine Installation, Veröffentlichung, Anmeldung oder Remote-Übersetzung.

### Tatsächlich ausgeführt

| Prüfung | Ergebnis |
| --- | --- |
| Pflichtdokumentation/Bestand/XERJ | Regeln, Tickets, zentrale Dokumente und betroffene Module geprüft; XERJ-Suche/Definition ausschließlich bcsf-docs und gegen aktuelle Dateien abgeglichen. Verfügbare Symbole/Runtime wie in der Foundation |
| Compiler/CodeCop/UICop | Vollständiger Cloud-Build, Runtime 17, vorhandene fünf Microsoft-28.5-Pakete, AL Compiler 18.1.43.24897 über vorhandenen .NET-10.0.15-Host, generatecode+ und warnaserror+: Exit 0. Keine Fehler/Warnungen. Zwei AW0006-Informationen für nicht separat durchsuchbare Detailkarten; Listen sind durchsuchbar |
| Korrigierte Erstbefunde | Enumcaption-Kommas AL0649, Variablenreihenfolge AA0021, ungenutzte Variable AA0137 und unklarer Revision-only-Update AA0214 beim ersten Build gefunden und behoben; keine Warnungen unterdrückt |
| Übersetzungen | 285 generierte UI-Einheiten vollständig in de-DE/de-AT/de-CH/de-LI/de-LU und en-US; IDs, Quelltexte, Platzhalter, Maximalbreiten, Status und regionale Gleichheit mit `python3 scripts/check_translations.py --sync` sowie Prüfmodus validiert. Alle bestehenden Foundation-UI-Texte eingeschlossen; sieben XLIFF-Dateien insgesamt |
| Übersetzungs-Negativfälle | Sechs nur im Arbeitsspeicher beschädigte Varianten (fehlendes Target, veralteter Source, verlorener Platzhalter, falsche Kultur, unbestätigter Status, überschrittene Textlänge) korrekt abgewiesen. Projektdateien nicht beschädigt |
| IDs/Kollisionen | 32 eindeutige IDs/Namen innerhalb 90100–90999; Namen höchstens 30 Zeichen. Keine Kollision mit 8.361 Objektdeklarationen der fünf lokalen Microsoft-Pakete. Keine Aussage zu nicht vorliegenden Fremd-Apps |
| Sicherheitsverdrahtung | Je 20 neue verpflichtende Content- und Lifecycle-Subscriber auf fünf Tabellen, Skip-Flags false, kein RunTrigger-/GuiAllowed-Bypass. Nur temporäre Anzeige-DTOs ohne DB-Wirkung ausgenommen; bestehende Setup-Subscriber unverändert zwingend |
| Snapshot/Rechte – statisch | Gemeinsamer Parent-Lock vor Kindänderungen, Parent-/Setup-Lock beim Capture, CommitBehavior::Error, kein Commit/TryFunction; Header+Payload-Insert im festen Schreiber. Rollen nur Ri auf beide Tabellen, eng begrenztes Insert im Writer; Modify/Delete/Rename unveränderlicher Records blockiert. Alle zwölf fachlichen Vorlagenfelder in Payload-Mapping, rekonstruierende Lesewege ohne aktuelle Vorlage |
| Datensprache – statisch | ISO-de-Prüfung statt einzelner Region; Resolver bei Capture, Requested/Resolved Language und Katalogversion gespeichert. Datenkatalog wählt explizite gesperrte deutsche/englische Datenwerte, ohne GlobalLanguage zu ändern. Laufvorschau liest die erfasste Sprache/Katalogversion |
| Mengenformel | 70 Decimal-Rechenbeispiele zur im Quellcode abgeglichenen Abrundungs-/Restformel, Mengen 0 bis Integer-Maximum und Randquoten: Teilmengen nicht negativ, Summe exakt Ziel. Dies sind Rechen-/Quellprüfungen, keine ausgeführten AL-Laufzeittests |
| Scope | Manifest nur TranslationFile ergänzt, App-ID/Version/Range/Dependencies erhalten; Launch und andere Ticketdetails unverändert. Objektplan, Modulbestand und Verweise gegen vorhandene Dateien abgeglichen; kein Folge-Ticket implementiert |

Build-Aufruf wie Foundation mit `/target:Cloud /generatecode+ /warnaserror+ /analyzer:<CodeCop>,<UICop>`, Ausgabe nur als temporäres lokales Paket. Nach vollständigem Build muss der aktuelle deutsche Master zu `.g.xlf` passen; der Prüfer übersetzt unbekannte Texte nicht automatisch. Englisch ist Quellsprache, deutsche Regionaldateien werden bewusst vom Master abgeleitet.

### BC-Laufzeitprüfplan – nicht ausgeführt

| Bereich | Konkreter Prüffall / erwartetes Ergebnis |
| --- | --- |
| UI Deutsch | BC-Sprachen de-DE, de-AT, de-CH, de-LI, de-LU: Captions, Tooltips, Enums und Fehler auf Deutsch. Weitere deutsche Kulturen: primärer deutscher Fallback. Alle verwendeten Pages/Unterseiten einschließlich Foundation prüfen |
| UI Englisch/Fallback | en-US/en-GB sowie z. B. fr-FR bei deutscher Landes-/Standardsprache: App-Texte sollen Englisch verwenden. Native BC-Fallbackreihenfolge ist noch nicht praktisch verifiziert; keine automatische Änderung von Benutzer-/Serverpräferenzen |
| Datensprachen | Automatisch unter den fünf deutschen LCIDs → German; unter en/fr/nl → English. Explizite Auswahl überschreibt Auto. Vorlagenvorschau entsprechend; gespeicherter Lauf bleibt nach Wechsel der UI-/Worker-Sprache unverändert |
| Katalog | Katalogversion 1: CUSTOMER/VENDOR/ITEM mit positiver Nummer in Deutsch/Englisch; Auto/ungültige Version/unbekannter Typ/Nummer <=0 abgewiesen. Historische Version 1 bei späterer Katalogerweiterung erhalten |
| Vorlage/Kopie | Neue GUID, Defaults aus Setup, ein vollständiges unabhängiges Copy; Original/Kopie unabhängig editierbar. Revision steigt bei Kopf-/Modul-/Zieländerung; parallele Änderung verlangt konsistente Versionskontrolle |
| Ziele/Quoten | Getrennte Entity-Ziele, null deaktiviert, negative/über Limit abgewiesen, Preset nur auf aktueller Entität. Quoten außerhalb 0–100, mehr als fünf Dezimalstellen oder inkonsistente direkte Zuweisung abgewiesen; UI-Restquote plausibel aktualisiert |
| Modi | Stammdaten ohne Dokumentquoten, Quotes ungebucht, teilweise nur Aufträge/Bestellungen; aktiver Zielmodus nicht über Szenariomaximum. Modul nicht deaktivier-/löschbar bei positiven Zielen |
| Snapshot | Profilkennung/-version und positives Ziel erforderlich. Capture erzeugt genau einen Draft plus Payload, keine Queue/Standarddaten. Kopf/Arrays/Seed/Zeitraum/Limits/Sprache/Katalog vollständig und nach Änderungen an Vorlage/Setup identisch lesbar |
| Transaktion/Konkurrenz | Fehler nach Kopf- vor Payload-Insert unter normalem Aufruf hinterlässt keine Teilkonfiguration. Zwei Capture-/Kind-/Setup-Schreibsitzungen erzeugen konsistente Revisionen/Settings; Deadlock/Fehler bleibt sichtbar. Keine TryFunction-Rollback-Annahme |
| Unveränderlichkeit/Rechte | Direkte und RecordRef-/Insert(false)/Modify(false)/DeleteAll-/Rename-Pfade unter Sandbox/Produktion, falscher Firma, fehlenden Execute-/Read-/Write-Rechten und Security-Filtern prüfen. Nutzer kann nicht direkt in Run/Snapshot einfügen; fester Writer darf gültig indirekt inserten |
| Temporäre Ansicht | Eingefrorene Module/Ziele und Sprachvorschauen aus Snapshot, niemals aus aktueller Vorlage; keine DB-Schreibwirkung. Aktuelles Setup/Generierungsfreigabe kann danach geändert werden, Leseansicht bleibt erhalten |
| Eingaben/Datum | Leere Pflichtangaben, unbekannte Enums, Enddatum vor Startdatum, Paketgröße <=0/über Max werden abgewiesen. Fehlender Profilkatalog/Generator wird durch Snapshot-Erfassung nicht als bestanden ausgegeben |

**Grenzen:** Keine ausgeführten AL-Unit-/Integrationstests oder UI-/Sandbox-/Rechte-/Lasttests, kein Deployment. Die lokalen Prüfungen bestätigen Code/Übersetzungsabdeckung und Paketierbarkeit, nicht die komplette BC-Laufzeitakzeptanz. Objekt-/Sprach-/Schema-Vertrag: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md). Status beider Tickets: **Zur Prüfung**.

## SF-007/SF-008 – lokaler Prüfnachweis 11.11.2026

**Ausgeführt:**

- Vollständiger Cloud-Build von 56 AL-Dateien mit AL Compiler 18.1.43.24897, vorhandener .NET-10.0.15-Laufzeit, fünf lokalen Microsoft-Symbolpaketen (BC 28.5/DE, System 28.0), Runtime 17. CodeCop und UICop eingeschaltet, Warnungen als Fehler. Letzter Lauf 16:27:32–16:27:38 laut Compiler, Exit 0; keine Fehler/Warnungen. Drei AW0006-Informationen für Scenario Card, Run Card und Plan Preview: bewusst über Listen/Laufkarte geöffnet, nicht separat suchbar. Keine Analyzer-Regel unterdrückt.
- Paket-Symbolreferenz ausgewertet: 10 Tabellen, 21 Codeunits, 12 Pages, eine PageExtension, zehn Enums, ein Permission Set und ein Interface = 56 Objekte. Sieben XLIFF-Dateien (Quellkatalog und sechs Zielkulturen) im erzeugten Paket nachgewiesen. Build-Artefakt/Protokoll außerhalb des Repositories, kein Deployment.
- `python3 scripts/check_translations.py --sync` und anschließend `python3 scripts/check_translations.py`: PASS, 443 Texteinheiten mit identischen Quellen/IDs, Platzhaltern, Breiten und vollständigen Zieltexten für de-DE/de-AT/de-CH/de-LI/de-LU sowie en-US.
- Lokale Inventarprüfung: 55 eindeutige numerische IDs innerhalb 90100..90999 und ein Interface ohne numerische ID; Namen eindeutig und höchstens 30 Zeichen. Alle implementierten Dateien im Objektplan, insgesamt 93 numerische Planzeilen. Bestand nach Modul: Core 13, ScenarioManagement 21, ModuleRegistry 10, DependencyManager 9, Lifecycle 3. Keine neuen AL-Testobjekte.
- Typ-/ID- und Namenskollisionen gegen 9.589 Objekte der fünf verfügbaren Microsoft-Symbolpakete geprüft: keine. Dies ist keine Prüfung sämtlicher im Zieltenant installierter Fremd-Apps.
- Baselinevergleich: app.json und launch.json unverändert; detaillierte TODO-Abschnitte außerhalb SF-007/SF-008 unverändert. Bestehende Nutzeränderungen bleiben erhalten.
- Quellprüfung: sieben verpflichtende Interface-Methoden, explizite Fehlerbindung für unbekannte Enumwerte, Ausschluss der Proben aus echten Plänen, tiefe Kontextkopien, sechs verpflichtende neue Guard-Subscriber, enges Insert-Recht des Plan Writers und unveränderliche gespeicherte Steps. Keine SQL-/Fachdatenänderung durch die beiden Proben; keine Standardposten-Inserts, Queue-Starts oder Ready-Übergänge ergänzt.

**Nicht ausgeführt / offene Abnahme:**

Die beiden normalen Selbstprüfungs-Codeunits sind kompiliert, aber nicht in Business Central ausgeführt. Keine separate Test-App vorhanden oder neu erstellt. Kein Playground-/Produktions-Negativtest, keine UI-/Berechtigungs-/Parallelitäts-/Postingprüfung. Reale Fachgeneratoren und externe Vorbedingungsprüfungen sind weiterhin nicht implementiert. Ausführliche manuelle Fälle und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md). Vor Freigabe beide Selbstprüfungen sowie Plan-Persistenz, erneutes Speichern, fehlende Module/Generatoren, optionale/Pflichtabhängigkeiten, Zyklus, versionsgeänderte Bindungen, Trigger-false-Schreibversuche und DE/EN in freigegebener Sandbox tatsächlich prüfen. Tickets bleiben **Zur Prüfung**.

## SF-009/SF-010 – lokaler Prüfnachweis 15.11.2026

**Ausgeführt durch Codex im lokalen Workspace:**

- Vollständiger Cloud-Build aller 64 AL-Dateien, Compiler 18.1.43.24897 über vorhandenen .NET-10.0.15-Host, Runtime 17, fünf lokale Microsoft-Symbolpakete (BC 28.5/DE und System 28.0), CodeCop/UICop, generatecode+ und warnaserror+: Exit 0, keine Fehler/Warnungen im abschließenden Lauf. Vier AW0006-Informationen für nur über andere Pages erreichbare Detail-/Vorschauseiten. Keine Analyzer-Regel unterdrückt. Erstbefunde AA0018 (Formatierung) und AA0205 (explizite Datumsinitialisierung) behoben. Aufruf wie Foundation; temporäres Paket `/tmp/BCSF-SF009-SF010.app`, kein Deployment.
- `python3 scripts/check_translations.py --sync` und `python3 scripts/check_translations.py`: PASS, 481 vollständige Texteinheiten in fünf deutschen Kulturen und en-US; IDs, Quellen, Platzhalter und Textbreiten gültig. Paket enthält sieben XLIFF-Dateien.
- Lokales Objektinventar: 64 Dateien, davon 63 eindeutige numerische IDs plus Interface; IDs in 90100–90999, Namen eindeutig und maximal 30 Zeichen, alle implementierten Objekte im Objektplan. Keine Typ-/ID- oder Namenskollision mit 8.524 für den Vergleich ausgelesenen lokalen Microsoft-Symboleinträgen (einschließlich Paketduplikaten). Keine Aussage über unbekannte Fremd-Apps.
- Quellprüfung: neue Standarddatenzugriffe ausschließlich lesend; Insert/DeleteAll nur auf TableType-Temporary-Diff. Keine neuen Commit-/TryFunction-/HTTP-/Nummernverbrauchsaufrufe. ADMIN nur zusätzliche Objektausführung, keine Standardtabellenrechte. Drei neue Pflichtsubscriber ohne Skip-Flags für Finanzcheck, Start-Gate und Snapshot-Regeln; Regelerweiterung bekommt nur das Regelobjekt. Bestehende Snapshot-Guards bleiben erhalten.
- Seed-Quellprüfung: kein Random/Randomize, RunId, CurrentDateTime oder GlobalLanguage in der Werteableitung; längencodierte Schlüsseltupel, getrennte Feldstreams, Decimal-Zwischenwerte, explizite Regel-/Versions-/Bereichsprüfungen, Ausgabe nur DTO mit markierten Katalogwerten und reservierter E-Mail. Diese Prüfung ersetzt keinen ausgeführten AL-Funktionstest oder statistischen Verteilungsnachweis.
- `app.json` und `.vscode/launch.json` gegen HEAD unverändert; keine weiteren Tickets implementiert. Diff-/Whitespace- und Ticketumfangskontrolle ohne Befund. XERJ nur `bcsf-docs`: Dokumenttreffer gegen lokale Dateien geprüft; Definition des aktuellen Planners nicht im Index gefunden, Memory-Recall ohne Treffer. Lokale Quellen maßgeblich.

**Nicht ausgeführt:** AL-Selbstprüfungs-Codeunits, AL-Unit-/Integrationstests, Sandbox-Anmeldung/UI, Produktions-Negativtest, Rechte-/Security-Filter-/Parallelitäts-/Lasttests. Keine neue Test-App oder Testobjekte erstellt. Kompatibilität gegen ursprüngliche BC-28.0-Symbole, reale Playground-Version, Lokalisierung, Publisher und Fremd-App-Konflikte weiterhin **Zu prüfen**.

### BC-Laufzeitprüfplan – noch nicht ausgeführt

| Bereich | Eingabe / Erwartung |
| --- | --- |
| Vorhandene Einrichtung | Gültigen Draft mit Kunden-/Lieferanten-/Artikel-/Belegzielen öffnen; Vorschau zeigt passende konkrete Voraussetzungen. Standardtabellen und Nummernserienzähler vor/nach wiederholtem Öffnen unverändert. Generatorspezifischer Blocker bleibt sichtbar |
| Fehlende Einrichtung | Je eine Setupzeile, Nummernserie, gültige Serienzeile, Zahlungsbedingung oder Buchungsmatrix fehlt: zugehöriger Blocker und manuelle Maßnahme; keine automatische Anlage |
| Nummernserien | Serien nur manuell, geschlossen, fehlendes Startkennzeichen, Inkrement 0, mehrere Datums-/Zeilennummern: gültige jüngste Zeile am Startdatum prüfen; keine Nummer verbrauchen. Erschöpfung/spätere Serienwechsel bleiben unbestätigt und benötigen Generatorprüfung |
| Dimension/Lager | Konfigurierte gesperrte/fehlende Dimension → Blocker; optionale leere Dimension → keine erfundene Pflicht. Lagerortpflicht ohne sichtbaren Lagerort → Blocker; deaktiviertes Warehouse → kein Warehouse-Setupzwang |
| Finance | Fehlendes/gesperrtes/nicht bebuchbares Forderungs-/Verbindlichkeitskonto: Kandidat als unbrauchbar sichtbar; mindestens ein anderer gültiger Kandidat bleibt unverändert. Ohne gültigen Kandidaten eigener Blocker. Keine Auswahl eines Kontos durch die App |
| Rechte | Fehlende ReadPermission/WritePermission, nur ADMIN ohne Standardrechte, indirekte Rechte, Security-Filter und fehlende Objekt-/Lizenzrechte prüfen. Kein stilles Überspringen/Erhöhen; entweder Befund oder klarer BC-Berechtigungsfehler, niemals Freigabe |
| Aktuelle Prüfung | Nach Vorschau Einrichtung manuell mit Freigabe ändern; erneut öffnen muss den aktuellen Stand lesen. Frühere Vorschau ist keine Startgenehmigung. Start-Gate bleibt bei bisherigen Plan-/Generatorblockern geschlossen |
| Snapshot/Transaktion | Neuer Snapshot enthält Engine 1 und sämtliche Regelwerte Version 1. Vorlage/Default später ändern: Payload und bestehende Werte unverändert. Fehlender Subscriber-/Execute-Zugriff darf keinen teilweise persistierten Snapshot hinterlassen; direkte Trigger-false-Schreibversuche weiterhin abgewiesen |
| Altsnapshot/Version | Historischen Schema-1-Lauf weiter lesen; neue Seed-Vorschau verlangt neue versionierte Regeln statt Defaults nachzuladen. Unbekannte Engine-/Regel-/Katalogversion, ungültige Quoten/Preisgrenzen und leere logische Schlüssel → Fehler |
| Determinismus | In AL gleiche Konfiguration/Schlüssel wiederholt, rückwärts und in unterschiedlichen Batchzuschnitten abfragen; JSON-Eingangswerte identisch. Gleiche Konfiguration in neuer RunId identisch; mehrere andere Seeds ändern Muster. Worker-/UI-Sprache beeinflusst nicht den erfassten DE/EN-Katalog |
| Grenzen | Integer-Minimum/-Maximum und Einzelwertintervalle, Seed 0/negativ/Integergrenzen; Preis immer innerhalb gewählter Klassenbounds und in Cents. Ungültige/umgekehrte Datumsbereiche → Fehler; Schaltjahr, Einzeltag, Wochenende-only mit WeekdaysOnly, Bereichsende/Rücksprung prüfen |
| Realismus/PII | Große Menge je Entity zur Plausibilität/ungefähren Klassenverteilung prüfen, ohne exakte Quoten zu verlangen. Namen markiert synthetisch, unterschiedliche Seed-/Feldstreams wirksam, keine Telefon-/Bankdaten und keine echten Empfänger; keinerlei Versand |
| Oberfläche | Beide neuen Laufkartenaktionen in Deutsch/Englisch, Befunde, Maßnahmen, Fehlermeldungen, Tabellenfeld-Tooltips, Preis-/Datumsanzeige und Accessibility praktisch prüfen |

Beide Tickets **Zur Prüfung**. Der lokale Build bestätigt Paketierbarkeit, keine fachliche Laufzeitabnahme. Konkrete Setup-/Branchenbindungen und vollständiger Leerfirmenaufbau bleiben offen; siehe [SETUP_SEED.md](SETUP_SEED.md).

## SF-011/SF-012 – lokaler Prüfnachweis 15.11.2026

**Ausgeführt durch Codex im lokalen Workspace:**

- Vollständiger Cloud-Build aller 81 AL-Dateien mit Compiler 18.1.43.24897 und vorhandenem .NET-10.0.15-Host; fünf lokale Microsoft-Symbolpakete BC 28.5/DE und System 28.0, Runtime 17. CodeCop/UICop, generatecode+ und warnaserror+: abschließend Exit 0, keine Fehler/Warnungen. Vier AW0006-Informationen für vorhandene Detail-/Vorschauseiten. Keine Regelunterdrückung. Erstbefunde zu Variablenreihenfolge/-namen, expliziter Initialisierung und Kategorienlänge behoben. Buildaufruf wie Foundation, temporäres Paket `/tmp/BCSF-SF011-SF012.app`, kein Deployment.
- `python3 scripts/check_translations.py --sync` und `python3 scripts/check_translations.py`: PASS, 606 Texteinheiten in fünf deutschen Kulturen und en-US; Quellen/IDs/Platzhalter/Breiten geprüft. Paket mit sieben XLIFF-Dateien lesbar.
- Objekt-/ID-Inventar: 81 AL-Dateien, 80 eindeutige numerische IDs in 90100–90999 plus Interface; eindeutige Namen maximal 30 Zeichen, alle Implementierungsdateien im Objektplan, Recovery-ID 90304 unbenutzt. Keine neue Test-Codeunit. Kein Typ-/ID- oder Namenskonflikt gegen 9.430 ausgelesene lokale Microsoft-Symboleinträge einschließlich Paketduplikaten. Keine Tenant-/Fremd-App-Kollisionsbehauptung.
- Lokale Standardquellen aus dem vorhandenen Base-Application-Symbolpaket gelesen: Job Queue Entry/Enqueue/Dispatcher/Error Handler. Tatsächliche APIs und Error-Callback OnAfterFinalizeRun, eintragsspezifische Retries, Kategorie-Semaphore und Scheduler-Anbindung nachvollzogen. Nur der Standard-Enqueue verändert Queue-Metadaten; die App erhöht keine Standardtabellenrechte und schreibt keine Standard-Fachdatensätze.
- Quell-/Invariantenprüfung: ein expliziter Commit ausschließlich nach erfolgreichem Worker-Claim; atomarer Runner und Registry Writer mit CommitBehavior::Error, keine TryFunction-Schreibwege oder Resume-Aufrufe. Kein direkter Standard-Ledger-/Fachdateninsert. Exakte Run-/Batch-/Job-/Version-/Sprachbindung, tiefe JSON-Kopien, lückenlose Plan-/Herkunftsabdeckung und Zählwertabgleich. Kategorie BCSF.SER, Recurring=false und Maximum No. of Attempts to Run=0; keine neue aktive Queue in BC erzeugt.
- Vier verpflichtende Registry-DB-Subscriber, acht eigene Execution-/Batch-DB-Subscriber, ein Batchbesitz- und ein Standard-Fehler-Subscriber, alle ohne Skip-Flags. Immutable logische und physische Ergebnisidentität, vorhandene Eltern desselben Runs, SystemId-Auflösung statt Primärschlüssel-Fallback, bestehende Header-/Snapshot-/Stepguards erhalten. Diese statische Prüfung ist kein ausgeführter Parallelitäts-/Rechte-/Postingnachweis.
- `app.json` und `.vscode/launch.json` gegen HEAD unverändert; Ausgangsänderungen SF-009/SF-010 erhalten. Detaillierte Ticketabschnitte gegen den zu Beginn von SF-011/SF-012 erfassten Stand verglichen: ausschließlich SF-011/SF-012 verändert. Diff-/Whitespaceprüfung und lokale Links des neuen Vertrags/Objektplans/Indexes ohne Befund.
- XERJ ausschließlich bcsf-docs: relevante Ticket-/Dokumenttreffer gegen aktuelle Dateien geprüft; Memory-Recall ohne Treffer, CheckStart-Definition nicht im Index verfügbar. Aktuelle lokale Quellen und Symbole maßgeblich.

**Nicht ausgeführt:** bestehende AL-Selbstprüfungen, AL-Unit-/Integrationstests, echte Scheduler-/Queue-Ausführung, Sandbox-Anmeldung/Deployment, UI-, Standardrechte-/Security-Filter-/Produktions-Negativ-, Parallelitäts-, Abbruch-/Last- oder Postingtests. Keine neue Test-App/Testobjekte. Tatsächliche Playground-/Testfirmen-/Versions-/Publisherfragen bleiben offen. Aktuell verhindern fehlende echte Generatoren und konkrete Setupbindungen reguläre Vorbereitung und Start; es wurde kein Probe-Generator in einen echten Plan eingeschleust.

### BC-Laufzeitprüfplan – noch nicht ausgeführt

| Bereich | Konkreter Fall / Erwartung |
| --- | --- |
| Blockierte Vorbereitung | Fehlender Plan, echter Generator, externer Nachweis oder Setupbindung: Prepare scheitert ohne Execution-/Batch-/Queue-Teilbestand; ursprünglicher Header/Snapshot/Steps unverändert |
| Planpersistenz | Mit künftig gültigem echten Generator kleine Ziele sowie mehrere Planseiten prüfen. Exakte disjunkte Bereiche 1..Ziel, Reihenfolge nach Steps, eindeutige Identitäten. Wiederholte/gleichzeitige Vorbereitung wird abgewiesen |
| Negative Generatorpläne | Leeres/nicht fortschreitendes/überlappendes/gap-behaftetes Ergebnis, falsche Grenzen, zu langer Key, mehr als 100 Pakete je Seite, zusätzliche nicht persistierte JSON-Parameter oder mehr als 10000 Gesamtpakete → kompletter Planrollback |
| Scheduling/Rechte | Fehlende Standardrolle, Task-Scheduler-/Enqueue-/Objekt-/Tabellen-/Lizenzrechte: sichtbarer Fehler, keine Rechteerhöhung. Jetzt-/Zukunfts-/Vergangenheitsdatum, UI-Bestätigung und wiederholtes/gleichzeitiges Schedule prüfen; nur ein nächster Job pro Run |
| Hintergrundkontext | Browser schließen; eingeplanter Job verarbeitet genau einen Batch ohne GUI. Manipulierte Job-ID, Objektart/Codeunit, RecordId, Kategorie, Wiederholungsparameter, falsche Firma/Umgebung oder zurückgezogene Freigabe werden vor Generierung blockiert |
| Parallelität | Zwei Sessions für denselben Job/Run und mehrere Runs derselben Firma: kein doppelter Claim oder paralleler regulärer BCSF-Worker; Kategorie-Semaphore BCSF.SER in tatsächlicher Umgebung prüfen. Unterschiedliche Firmen isoliert |
| Herkunft/Idempotenz | Neu erzeugten tatsächlichen Standardrecord im laufenden Batch registrieren: eingefrorene Generatorbindung, eigener logischer Schlüssel/SystemId. Identischer Registeraufruf liefert dieselbe Entry-ID; anderer Datensatz/Batch/Elternbezug oder zweite logische Zuordnung desselben physikalischen Records wird abgewiesen |
| Guard-Schreibwege | Insert(false), Modify(false), DeleteAll, Rename, RecordRef und vollständige direkte Rechte unter Sandbox/falscher Firma/Produktion prüfen. Registryänderung/-löschung und Planidentitätsänderung verboten. Laufende Batchzuordnung und alle Zähl-/Statusinvarianten zwingend |
| Eltern/Postingbezug | Existierender Elternrecord desselben Runs zulässig; fremder Run, fehlender Elternrecord oder Selbstbezug → Fehler. Tatsächliche Posting-Quellen-/Ergebnisbeziehungen nach Implementierung eines genehmigten Postinggenerators anhand BC-Standardergebnissen prüfen; derzeit keine Postingfreigabe |
| SystemId | Standardrecord umbenennen: Existenz anhand gleicher SystemId. Löschen und unter gleichem Primärschlüssel neu erstellen: alte Herkunft bleibt unverändert, neue SystemId wird nicht still übernommen. Fehlende Sichtbarkeit/ReadPermission klar anzeigen |
| Ergebnisvalidierung | Falscher Run/Generator/Batch/Sprache, Probe-Ergebnis, unvollständige Verarbeitung, falsche createdRecords-Zahl, fehlendes Artefakt je Einheit oder ValidateOutput-Befund → kein bestätigter Abschluss/Nachfolgerjob |
| Claim-/Fehlergrenzen | Fehler/Sessionausfall vor Claim, direkt nach Claim, nach Fachanlage vor Registry, nach Registry vor Abschluss und nach Abschluss vor Standard-Queue-Finalisierung prüfen. Claim bleibt bei unbestätigter Arbeit erhalten; Error-Callback → NeedsReview/Failed soweit ausführbar, niemals automatisches Wiederholen |
| Commit-Vertrag | Expliziter Commit im Generator/Outputvalidator muss im atomaren Bereich scheitern. Implizite Fremd-/Posting-Commitgrenzen separat nachweisen, bevor ein solcher Generator freigegeben wird; keine pauschale TryFunction-Rollbackannahme |
| Abschluss | Batchresultate und Herkunft sowie Nachfolgerjob atomar; fertiger Run konservativ CompletedWithWarnings bis globalem SF-016-Qualitätsgate. Zähler nicht aus bloßen Versuchen erhöhen |
| UI/Standardjobs | DE/EN-Captions/Tooltips, erfasster Anfangsstatus vs. aktueller Execution-Status, gefilterte Listen, Startdialog und abgelehnte Bestätigung; vorhandenen Standardjob öffnen. Entfernten Erfolgsjob nur als fehlend melden, keine neue Standardaufgabe automatisch öffnen/anlegen |
| Nicht-Ziele | Keine Retry-/Resume-/Pause-/Cancel-Aktion, Recovery-Codeunit 90304 weiterhin nicht implementiert; keine echten Empfänger, Standard-Ledger-Inserts oder Änderungen an produktiven Einrichtungen |

Status beider Tickets **Zur Prüfung**. Lokale Prüfungen bestätigen Paketierbarkeit und statische Verdrahtung; tatsächliche Laufzeitakzeptanz, Standard-Queue-Rechte und Parallelität bleiben offen. Ausführlicher Vertrag und geänderte Objekte: [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md), [OBJECT_PLAN.md](OBJECT_PLAN.md).

## SF-013 – lokaler Prüfnachweis 16.11.2026

**Ausgeführt durch Codex im lokalen Workspace:**

- Vollständiger Cloud-Build aller 85 AL-Dateien gegen die fünf vorhandenen lokalen BC-28.5-/DE- und System-28.0-Symbolpakete, Runtime 17, Compiler 18.1.43.24897 über vorhandenes .NET 10.0.15. CodeCop/UICop, generatecode+ und warnaserror+: Exit 0, keine Fehler/Warnungen; vier bekannte AW0006-Informationen für bestehende Detailseiten. Anfangsbefunde AA0021 zur Variablenreihenfolge korrigiert, keine Analyzer-Unterdrückung. Temporäres Paket `/tmp/BCSF-SF013.app`, kein Deployment.
- `python3 scripts/check_translations.py --sync` und `python3 scripts/check_translations.py`: PASS, 665 vollständige Einheiten in de-DE/de-AT/de-CH/de-LI/de-LU und en-US. Abschließendes Paket enthält sieben XLIFF-Dateien mit jeweils 665 Einheiten.
- Inventar-/Objektplanprüfung: 85 AL-Dateien, 84 eindeutige numerische IDs plus Interface; Namen eindeutig und höchstens 30 Zeichen, alle IDs in 90100–90999 und Implementierungspfade im Objektplan. BackgroundProcessing 16, sonstige Modulbestände unverändert. Keine neue Test-App oder Test-Codeunit. Kein Typ-/ID- oder Namenskonflikt gegen 9.430 ausgelesene lokale Microsoft-Symboleinträge inklusive Paketduplikaten; keine Aussage über unbekannte Tenant-Apps.
- XERJ-Projektsuche ausschließlich bcsf-docs: Treffer zu SF-013 und zum SF-012-Vertrag gegen aktuelle Dateien abgeglichen. Memory-Recall ohne Treffer; AL-Definition des Runners im Index nicht verfügbar, aktuelle lokale Quellen maßgeblich. Kein XERJ-Laufzeitcode, kein Datenexport/Feedbackversand.
- Standard-API-/Symbolprüfung: Active Session mit Server Instance ID, Session ID und Session Unique ID nachgewiesen; CancelTask-Rückgabeverhalten und Jobstatus-/System-Task-Bezüge anhand vorhandener Standardquellen geprüft. Keine Standardtabellenrechte hinzugefügt, kein tatsächlicher Job oder Task angelegt/beendet.
- Statische Recovery-Invarianten: keine ExecuteBatch-/Generator.Resume-Aufrufe in Recovery; Retry nur vor Claim ohne Herkunft/Checkpoint und mit monotonem Limit drei; dauerhaft erfasste technische Workeridentität statt Lease-Zeitablauf; Checkpoint vor Batchabschluss; Anforderungen vor Claim/weiterer Einplanung; Checkpointidentität/Output/Ergebnis-SystemIds erneut geprüft. Acht neue verpflichtende Subscriber ohne Skip-Flags für Control/Checkpoint; Trigger-false-Pfade bleiben gebunden.
- Transaktionsprüfung am Quellcode: weiterhin ein expliziter Worker-Claim-Commit, zusätzlich genau ein expliziter Commit der isolierten UI-Steuerungsanforderung. Runner, Retry, Resume, Reconciliation und Checkpointschreiben ohne eigenen Commit bzw. unter CommitBehavior::Error; keine TryFunction-Schreibpfade, keine Standard-Ledger-Inserts, keine Sessionbeendigung. Fremde implizite Commitgrenzen werden damit nicht als getestet/sicher erklärt.
- Scope-/Hashvergleich gegen den zu Beginn von SF-013 erfassten Bestand: nur BackgroundProcessing und die vorgesehenen Core-Status-/Berechtigungsdateien geändert; keine Änderung an ScenarioManagement, Headern/Snapshots/Steps/Herkunftsdateien, Manifest, AGENTS oder Launch. Vorhandene Nutzeränderungen erhalten. Detaillierte TODO-Abschnitte außerhalb SF-013 gegen den Ausgangsstand unverändert. Neue Vertrags-/Objektplan-/Modulindex-Links geprüft.
- Whitespace: eigene Änderungen ohne Befund; `git diff --check -- . ':!TODO.md'` bestanden. Der vollständige HEAD-Diff meldet vier bereits zu Aufgabenbeginn vorhandene Markdown-Zeilenenden in einem fremden TODO-Abschnitt (ursprünglich Zeilen 685/686/689/712). Diese wurden wegen des Ticketumfangs nicht verändert. SF-013 fügt keine solchen Zeilen hinzu.

**Nicht ausgeführt:** tatsächliche Unterbrechungssimulationen bei Datenerstellung/Posting, AL-Selbstprüfungen/Unit-/Integrationstests, Queue-/Task-Scheduler-/Sandbox-/UI-/Rechte-/Security-Filter-/Produktions-Negativ-/Parallelitäts-/Lasttests. Keine freigegebene BC-Laufzeit benutzt oder bereitgestellt; echte Fachgeneratoren und konkrete Setupbindungen fehlen weiterhin. Es wurden keine Testdaten erzeugt und keine Test-/Force-/Rollback-Umgehung in die App eingebaut.

### Unterbrechungs- und Recovery-Matrix – in BC noch offen

| Fall / Unterbrechung | Erwartung und tatsächlich noch zu prüfender Nachweis |
| --- | --- |
| Vor Claim / Startprüfung schlägt fehl | Failed, Started At=0, keine Workerübernahme/Registry/Checkpoint; nach behobener Ursache manueller Retry mit gleicher Batch-ID/Bereichen, neuer Job-ID und erhöhtem Zähler. Fehler während Retry muss Metadaten konsistent erhalten |
| Direkt nach dauerhaftem Claim | Running bzw. nach Fehlerhandler NeedsReview; keine Wiederholung aufgrund leerer Registry. Ohne Checkpoint und ohne Inaktivitätsnachweis bleibt Ausführung blockiert |
| Fachinsert vor Herkunft | Fehler/Sessionabbruch/impliziter Fremdcommit simulieren; fehlender Herkunftseintrag darf niemals „nicht erzeugt/nicht gebucht“ beweisen. Keine generische Wiederholung freigeben |
| Nach Herkunft vor Checkpoint | Herkunft allein ist keine Abschlussfreigabe; fehlende Zusammenfassung oder Teilabdeckung → NeedsReview. Transaktionsrollback und mögliche Fremdcommitgrenzen mit konkretem Generator prüfen |
| Nach Checkpoint vor Batchabschluss | Normale commitfreie Transaktion rollt beides zurück. Ein tatsächlich persistierter Checkpoint bei abweichender Fremdtransaktion darf nur nach inaktiver eindeutiger Worker-Sitzung, gestopptem Job, Ergebnisidentität und erneuter Outputvalidierung bestätigt werden |
| Nach Abschluss vor Queue-Finalisierung | Bestätigten Batch/Checkpoint nie erneut erzeugen; bei noch ausstehender Arbeit sichere Fortsetzung mit nur Pending-Bereichen. Standardjob-/Error-Handler-Rennen prüfen |
| Aktiver oder wiederverwendeter Session-ID | Sitzung/Dienstinstanz/GUID gemeinsam abgleichen. Aktive alte GUID → blockiert; neue Sitzung mit gleicher Nummer darf nicht als alte gelten. Fehlendes Active-Session-Leserecht oder fehlende Legacy-GUID → keine Freigabe |
| Verwaister Claim | Nach tatsächlichem Sitzungsende „Unterbrochene Übernahme prüfen“ → NeedsReview/Failed ohne Fachänderung. Fehlender Checkpoint bleibt blockiert, auch wenn Schedulerstatus alt ist |
| Checkpointabweichung | Fehlende/gelöschte bzw. neu unter gleichem Schlüssel angelegte Ergebnis-SystemId, falsche Sprache/Version/Zähler/Schema, Probe, Extra-Nutzdaten oder ValidateOutput-Befund → keine Wiederaufnahme/Bestätigung |
| Pause während laufendem Batch | Request dauerhaft ohne langen Parent-Update-Lock; laufenden Batch vollständig bestätigen, keinen Nachfolger starten. Anforderungsflag und tatsächlicher Paused-Status getrennt anzeigen |
| Pause vor Claim / zukünftiger Job | Nur sicher stornierbare ungestartete Aufgabe stilllegen. Bei bereits startender Aufgabe Anforderung erhalten und vor Claim berücksichtigen. Selbstfreigabe nur für den eigenen unübernommenen Workerjob, niemals fremde In-Process-Arbeit |
| Pause-/Resume-Rennen | Zwei Bedienersitzungen gegen Worker/Nachfolgeplanung, keine doppelte neue Job-ID, keine verlorene Anforderung, keine Rücksetzung bestätigter Zähler/Bereiche. Erneute aktuellen Rechte/Setup-/Generatorprüfungen zwingend |
| Abbruch | Nur Pending/nie gestartete Failed-Arbeit Cancelled, bestehende Ergebnisse und NeedsReview erhalten. Cancelflag nicht löschbar, kein Resume. Bestätigte Ergebnisse dürfen später rein nachweisend abgeglichen werden, Run bleibt Cancelled |
| Limit / Legacy | Drei Einplanungen einschließlich Erstversuch und Pausezyklen; vierte abgewiesen und Zustand konsistent. Alter bereits gebundener Job wird einmal mitgezählt. Legacy-Completed ohne Checkpoint und alte übernommene Batches ohne Sitzungs-GUID bleiben blockiert |
| Rechte / falsche Umgebung | Produktion/falsche Firma, zurückgezogene Generierungsfreigabe, fehlende Queue-/CancelTask-/Active-Session-/eigene Tabellenrechte und Security-Filter prüfen; Stop darf keine Fachfreigabe erteilen, keine Rechteerhöhung |
| Trigger-false / Metadatenschutz | Direkte Insert(false)/Modify(false)/DeleteAll/Rename/RecordRef-Versuche auf Control/Checkpoint/Batch: immutable Identitäten/Checkpoint/Cancelflag, monotone Versuche und gültige Statuspfade zwingend. Nur vorgesehene Writer besitzen indirekte Mutation |
| Bestehende Workflows / DE/EN | Altsnapshots lesen, ursprüngliche Planblocker wirksam, neue Aktionen/Bestätigungen/Tooltips und gespeicherte Flags auf Deutsch/Englisch. Kein unerwarteter Standardjob beim Öffnen einer entfernten Aufgabe |
| Posting | Mit künftig konkret genehmigtem Postinggenerator Fehler vor/nach Standardbuchung und vor/nach Checkpoint prüfen, Standardbelege/Posten abgleichen. Derzeit PostingApproved=false; kein ausgeführter oder zugesicherter universeller Posting-Retry |

SF-013 bleibt **Zur Prüfung**; die lokale Paketierung und Quellprüfung ersetzen die verlangte echte Unterbrechungs-/Posting-/Parallelitätsabnahme nicht. Vertrag, Limits und offene fachliche Fragen: [RECOVERY.md](RECOVERY.md).

## SF-014/SF-015 – lokaler Prüfnachweis 16.11.2026

**Tatsächlich ausgeführt durch Codex im lokalen Workspace:**

- Vollständiger Cloud-Build aller 97 AL-Dateien, Compiler 18.1.43.24897 über vorhandenes .NET 10.0.15; lokale BC-28.5-/DE- und System-28.0-Symbole, Runtime 17, CodeCop/UICop, generatecode+ und warnaserror+: abschließend Exit 0, keine Fehler/Warnungen. Sechs AW0006-Informationen für vier vorhandene Detailseiten und die zwei neuen, ausschließlich runbezogen geöffneten Detailansichten. Keine Regelunterdrückung. Erstversuch mit falschem Analyzer-Unterpfad abgewiesen; anschließend Pfade korrigiert. Compilerbefunde zu fehlendem Enum-Import und PageExtension-Methodenaufruf behoben. Finales Paket `/tmp/BCSF-SF014-SF015.app`, Protokoll `/tmp/BCSF-SF014-SF015-build.log`, Aufruf wie Foundation. Keine Veröffentlichung.
- `python3 scripts/check_translations.py --sync` und Prüfmodus: PASS, 865 vollständige Texteinheiten in de-DE/de-AT/de-CH/de-LI/de-LU und en-US. Neue deutsche Texte im Master gepflegt, keine Übersetzungsdienste. Das abschließend gebaute Paket enthält sieben XLIFF-Dateien mit jeweils 865 Einheiten.
- Python-Inventar: 97 AL-Dateien, 96 eindeutige numerische IDs in 90100–90999 plus Interface; eindeutige Objektnamen maximal 30 Zeichen, alle Implementierungspfade im Objektplan. Keine Typ-/ID- oder Namenskollision mit 7.793 aus den tatsächlichen Objektkollektionen der fünf lokalen Microsoft-Pakete gelesenen Deklarationen. Andere historische Zählmethoden zählen Metadatenreferenzen mit; hier ausschließlich Objektkollektionen. Keine Aussage über unbekannte Tenant-Apps.
- Hash-/Scopevergleich mit dem zu Beginn erfassten Bestand: Manifest, Launch und AGENTS unverändert; vorhandene AL-Dateien ausschließlich Core-Permission-Set und zwei Scenario-Navigationsseiten geändert. Zwölf neue Objekte: elf Monitoring, ein Wizard. Keine Bestandsdatei entfernt, verschoben oder umbenannt, keine neue Test-App/Test-Codeunit.
- Lokale Microsoft-Symbole: `Job Queue Log Entry` mit ID, Object Type/ID to Run und `Job Queue Log Entries` nachgewiesen; die gefilterten Aufrufe gegen diese Symbole kompiliert. Standardrechte nicht erweitert. Fehlende/gelöschte Queue-Einträge werden nur angezeigt, keine neuen Jobs durch Monitoring erstellt.
- Quellprüfung: acht verpflichtende Monitoring-Subscriber mit false/false, Eventinsert gegen tatsächliche Batch-/Executionidentität und Sandbox-/Firmen-Guard, immutable Modify/Delete/Rename; ADMIN nur Ri, fester Writer I. Keine neuen Commit-/TryFunction-/ExecuteBatch-/Generator.Resume-Pfade. Historie teilt die Übergangstransaktion, kein Fehlertext-/PII-Export.
- Zähler-/Datenflussprüfung am Quellcode: Ist ausschließlich aus Completed; Ziele ohne gespeicherten Plan aus eingefrorenem Snapshot; Aggregation gefiltert je Run, keine aktuellen Vorlagen als historische Quelle. Artefakte getrennt von logischen Einheiten und globaler Qualität. Unklare/abgebrochene Arbeit nicht als bestätigt gezählt. Vollständiger Stepabschluss nur mit exakter bestätigter Zielmenge. Dies ist kein ausgeführter AL-Rechen-/Fach-/Massendatentest.
- Wizard-Startpfad geprüft: feste erfasste Run-ID, Capture nur einmal je Instanz; Konfiguration nach Capture gesperrt; Checkbox plus Bestätigung, SavePlan/Prepare/Schedule über vorhandene Gates. Kein Jobstart beim Öffnen, Navigieren oder Schließen. Posting-/Setupfreigaben nicht ergänzt; bestehende Generator-/Setupblocker weiterhin im Code wirksam.
- XERJ ausschließlich `bcsf-docs`: Map und Ticketsuche mit relevanten Dokumenttreffern; Definition CheckExecution ohne Treffer, Codekorpus nicht indiziert, Memory-Recall leer. Aktuelle lokale Quellen/Symbole als maßgebliche Nachweise verwendet. Keine Änderung des Index, kein externer Feedbackversand.

**Nicht ausgeführt:** BC-Sandbox-Anmeldung/Deployment, AL-Selbstprüfungen/Unit-/Integrationstests, tatsächliche Queueausführung, UI-/Screenreader-/Tastatur-/DE-/EN-Laufzeitprüfung, Rechte-/Security-Filter-/Produktions-Negativ-/Parallelitäts-/Abbruch-/Retry-/Posting-/Lasttests. Keine autorisierte BC-Laufzeit benutzt, keine Testdaten generiert. Fehlende Fachgeneratoren, konkrete Setupbindungen, vollständige Branchenpresets und globales SF-016-Qualitätsgate bleiben offen. Lokaler Build ist kein fachlicher End-to-End-Nachweis.

### Manuelle BC-Abnahmematrix – alle Fälle noch nicht ausgeführt

| Fall | Erwartung / erforderlicher Nachweis |
| --- | --- |
| Leere Liste / unvorbereiteter Run | Dashboard öffnet ohne Mutation; Zustand „Nicht vorbereitet“, keine Zeit-/Jobwerte erfunden. Schrittansicht zeigt eingefrorene positive Ziele ohne gespeicherten Plan. Erneutes Öffnen startet nichts |
| Plan mit Blockern | Externe Voraussetzungen, fehlende Module/Generatoren und deren konkrete Erklärung sichtbar; keine fiktiven Istwerte oder automatische Einrichtung. Gespeicherter Plan bleibt unverändert |
| Gemischter Fortschritt | Beispiel: Ziel 100, Completed 20 mit 60 Artefakten, Running 20, Failed 20, Cancelled 40 → bestätigt 20, Artefakte 60, offen 80, Fortschritt 20 %. Running/Failed/Cancelled niemals als Ist. Kein globales „validiert“ oder „gebucht“ daraus ableiten |
| Wiederöffnung / Filter / Drilldowns | Dashboard schließen, Queue-/Recoveryzustand verändern, erneut öffnen/aktualisieren → gespeicherte Zustände und Run-/Step-/Batchfilter korrekt. Statusfilter über Ausführungsliste; alte Runs ohne Statusereignisse weiter lesbar |
| Fehler / Standardprotokolle | Fehlender Job, fehlende Standardleserechte, Security-Filter und bereinigte Logs explizit unterscheiden soweit beobachtbar. Aktuelle/vorherige Job-ID aus Batch, frühere Job-ID aus Historie; keine fremden Workerlogs anzeigen, nichts automatisch anlegen |
| Atomare Historie / Unterbrechung | Erfolgreiche Übergänge erzeugen technische Ereignisse genau im selben Commit. Fehler in Historienprüfung rollt den betreffenden Übergang zurück. Abbruch zwischen Facharbeit und Checkpoint verändert bestehende SF-013-Sicherheitsgrenzen nicht |
| Historienrechte / Trigger-false | Direkte Insert(false)/Modify(false)/DeleteAll/Rename/RecordRef-Versuche, fehlende Subscriber-/Tabellenrechte und falsche Firma/Produktion prüfen: keine Mutation/Umgehung; ADMIN kann nicht beliebige Ereignisse schreiben oder löschen |
| Wizard neu / bestehend / Schließen | Neue Vorlage nur auf ausdrückliche Aktion. Alle fünf Schritte DE/EN erreichbar. Änderungen bleiben nach Schließen erhalten; kein Queuejob. Bereits vorhandene Vorlagen/Targets nicht zurückgesetzt |
| Wizard-Eingaben | Fehlende Profilkennung/-version, kein positives Ziel, ungültige Mengen/Quoten/Datum/Modi/Batchgröße, deaktiviertes Modul → vorhandene Policy/Capture-Prüfungen blockieren. Dokumentziel nach Anheben des Maximums eintragen, vor Senken Ziele korrigieren |
| Snapshot / Paralleländerung | Ein Capture je Instanz; Rücknavigation/Bearbeitung danach gesperrt. Vorlage nach Capture in anderer Sitzung ändern → Plan/Preflight/Start verwendet weiterhin den ursprünglichen Snapshot. Erneuter Capture benötigt neue Instanz, alte Run-ID unverändert |
| Freigabe / Startzeit | Ohne Checkbox oder bei abgelehnter Bestätigung kein Start. Aktuelle fehlende Generator-/Setupbindungen blockieren trotz Freigabe. Mit künftig gültigen Bindungen Jetzt/Zukunft/erneuter Aufruf und vorhandenes Ready prüfen: ein erster Job, kein Duplicate. Postingmode erteilt keine Buchungsfreigabe |
| Berechtigungen / Regression | Konfigurations-/Queue-/Guardrechte zwischen Review und Start zurückziehen → Vorbereitung/Start blockiert, keine Rechteerhöhung. Vorhandene Vorlagen-/Snapshot-/Plan-/Pause-/Cancel-/Retryseiten unverändert nutzbar. Qualitätsanzeige bleibt bis SF-016 offen |
| Volumen / Accessibility | 10.000 Pakete und lange Historie mit realen Rollen messen; keine Durchsatz-/ETAbehauptung. Native Tastatur, Fokus, sichtbare Schrittgruppen, Footeraktionen, FactBox und Tooltips praktisch prüfen |

Beide Tickets **Zur Prüfung**. Vertrag und genaue Grenzen: [MONITORING_WIZARD.md](MONITORING_WIZARD.md).

Abschließende Scope-/Dokumentprüfung: detaillierte TODO-Abschnitte gegen Aufgabenbeginn verglichen, ausschließlich SF-014/SF-015 verändert; beide Übersicht-/Detailstati konsistent Zur Prüfung. 183 lokale Markdown-Dateiverweise in geänderten Dokumenten vorhanden. `git diff --check` ohne Befund; neue, noch unversionierte AL-/Vertragsdateien zusätzlich auf abschließenden Zeilenumbruch, Tabs und nachgestellte Leerzeichen geprüft. Diese Prüfungen ändern die offenen BC-Laufzeitfälle nicht.

## SF-014 – JavaScript-/Role-Center-Präzisierung, 16.11.2026

**Beauftragt:** Nutzer präzisiert das Dashboard ausdrücklich als JavaScript-ControlAddIn mit eigenem App-Role-Center und zentraler Navigation; zusätzliche Role-Center sollen dieselbe Dashboard-Part verwenden können. SF-015 und sämtliche übrigen Ticketdetails bleiben gegenüber Beginn dieser Präzisierung unverändert.

**Tatsächlich ausgeführt:**

- Vollständiger Cloud-Build aller **104 AL-Dateien** mit lokalem Compiler 18.1.43.24897 und vorhandenem .NET 10.0.15, BC-28.5-/DE- und System-28.0-Symbolen, Runtime 17, CodeCop/UICop, generatecode+ und warnaserror+: abschließend **Exit 0, keine Fehler/Warnungen**. Sechs bekannte AW0006-Informationen für Detailseiten. Ein anfänglich fehlender ModuleRegistry-Import und eine nach Captionänderung veraltete XLIFF-Quelle wurden behoben; keine Regelunterdrückung. Paket/Buildlog wie zuvor außerhalb des Projekts `/tmp/BCSF-SF014-SF015.app` und `/tmp/BCSF-SF014-SF015-build.log`.
- `node --check` für Dashboard-/Startskript und Browserprüfskript; anschließend `node scripts/check_dashboard.mjs`: **PASS**. Vorhandener Chrome, isoliertes temporäres Profil und lokaler HTTP-Server, keine Installation/fremden Bibliotheken/BC-Anmeldung. Browser-Skill-Ausführungstool war nicht verfügbar; lokale Prüfung mit vorhandenem Chrome über isolierte Debuggingschnittstelle, ohne bestehende Browserprofile/Sitzungen.
- Echte Chromium-DOM-/Interaktionsprüfung mit **synthetischer nachgebildeter BC-Brücke**: Ready genau einmal; kein Command beim Öffnen; 29 Einstiege vollständig, Zahlen und 20 bestätigte/80 offene/60 Artefakte getrennt, externe Voraussetzung ohne Fortschrittsbalken. Plan-/Abbruchaktion mit korrekter gewählter Run-ID, gesperrte Doppelklicks, sichtbarer Fehlercallback und anschließende Wiederholung, Schemafehler mit erhaltener Voransicht, HTML-artige Beschreibung als bloßer Text ohne img/Scriptausführung, leere Datenansicht mit vollständiger Navigation. Dies prüft die Browserseite und den Nachrichtenvertrag, **nicht** die Ausführung der AL-Kommandos.
- Tatsächliche deutsche XLIFF-Zieltexte in die lokale Oberfläche geladen, deutsche Beschriftung und Zahlenformat `1.000` bei vom Server gelieferten `de-DE` nachgewiesen. Deutsche Layouts bei **1440, 768 und 320 Pixeln** ohne horizontalen Seitenüberlauf; Tabellen sind separat scrollbar. Englische Ansicht zuvor ebenfalls geprüft. Semantische Buttons, Status-live-region, Tabellen und Progress kontrolliert. Lokale synthetische Vorschau als PNG im vom Skript ausgegebenen temporären Pfad erzeugt und visuell geprüft; keine echte BC-Screenshot-/Accessibilityabnahme.
- `python3 scripts/check_translations.py --sync` und Prüfmodus: **PASS, 978 Einheiten** in fünf deutschen Kulturen und en-US. Finale Paketprüfung: sieben XLIFF-Dateien à 978 Einheiten; gebündelte dashboard.js/dashboard.css/startup.js byteidentisch zu den Projektquellen. Kompiliertes Profil BCSF Scenario Factory und ControlAddIn BCSF Dashboard im Paketsymbol nachgewiesen.
- Lokale Microsoft-Quellen für Language.GetCurrentCultureName/GetCultureName und bestehende App-Aktionen untersucht; APIs gegen die vorhandenen Symbole kompiliert. Formatregion für Zahlen und Oberflächensprache werden getrennt im AL-JSON-Vertrag geliefert. Microsoft-Dokumentation zu ControlAddIn/async/CardPart/Role-Center/Profile geprüft; Links im [Einbauvertrag](DASHBOARD_EMBEDDING.md).
- Inventar und Scope per Python: **104 eindeutige Namen**, maximal 30 Zeichen; **101 eindeutige numerische IDs** innerhalb 90100–90999 sowie ein Interface, ControlAddIn und Profil ohne numerische ID. Alle realen AL-Pfade im Objektplan. Keine Namens-/Typ-ID-Kollision gegen tatsächliche Objektkollektionen lokaler Microsoft-Symbole. Nur sieben neue AL-Objekte; bestehende AL-Dateien gegenüber Präzisierungsbeginn ausschließlich ADMIN, Run Header (ein Leseschlüssel), alter Dashboardmonitor und dessen zwei Navigationserweiterungen verändert. Manifest/Launch/AGENTS unverändert, keine Baseline-Datei gelöscht/verschoben. Kein AL-Testobjekt erzeugt.
- Sicherheits-/Transaktionsprüfung am Quellcode: feste serverseitige Kommandoliste, Run-GUID-Längenprüfung/Evaluate/Get; keine frei gewählten Seiten-/Tabellen-/Firmen-/Filter-/Freigabeparameter, keine zusätzlichen Codeunit-Permissions oder Standarddatenrechte. Mutierende Runaktionen nutzen serverseitige Confirm(Default Nein) und bestehende Backendprüfungen. Keine neuen expliziten Commits/Schreib-TryFunctions; vorhandener RequestStop-Commit bleibt ausschließlich im bestehenden Recovery-Backend. Ausdrückliche neue Vorlagenanlage nutzt den vorhandenen Scenario Manager. Keine Netzwerk-/Clientstorage-/eval-/innerHTML-Aufrufe in den gebündelten Ressourcen.

**Weiterhin nicht ausgeführt:** echte BC-Iframeinitialisierung, Profil-Auswahl/Anmeldung, Role-Center-/PageExtension-Einbettung, AL-Aktions-/Dialogausführung, Standardrechte/Sicherheitsfilter, Queue-/Recovery-/Posting-/Parallelitäts-/Massendatentests, Screenreader und Tastatur in BC. Das dokumentierte Beispiel für ein weiteres Role-Center enthält einen ID-Platzhalter und ist kein kompiliertes/installiertes Zusatzobjekt. Kein Deployment und keine Profilzuweisung durchgeführt. Bestehende fachliche Generator-/Setup-/Qualitätsblocker bleiben offen.

### Ergänzende BC-Abnahmematrix – noch offen

| Fall | Erforderlicher Nachweis |
| --- | --- |
| Eigene Rolle | Nach separat freigegebener Installation Profil BC Scenario Factory auswählen; Dashboardpart und native Navigation sichtbar, keine automatische Profil-/Rechtezuweisung |
| Weitere Rolle | Konkrete erweiterbare Role-Center-Seite und freie ID freigeben, Part per PageExtension einbauen; gleiche UI/Navigation ohne Kopie. Breite/Höhe, mehrere Parts, Ausblenden/Personalisieren und Neustart prüfen |
| Leere App / Setup fehlt | Dashboard lesend öffnen, alle zentralen Einstiege verfügbar. Neues Szenario ohne Setup zeigt bestehenden Guard-/Setupfehler; Einrichtung über Navigation erreichbar |
| Ready / Recreate / Sprache | BC-Iframe laden, zurückkehren/recreate, Sprache/Formatregion wechseln; keine doppelt gebundenen Ereignisse oder automatische Mutationen, korrekte AL/XLIFF-/Zahlen-/Zeittexte |
| Auswahl / historische Runs | Neueste 25 stabil nach Created At/Run Id; volle Historie direkt erreichbar. Älteren Run aus Wizard/Laufkarte als Kontext öffnen, danach anderen Run auswählen; alle Aktionen an richtige Run-ID gebunden |
| Aktion / Rechte | Jede der 29 Schaltflächen in BC mit berechtigtem und eingeschränktem Benutzer prüfen. Ungültige/unsichtbare/fremde GUID, unbekannter Aktionscode oder fehlende Execute-/Tabellenrechte führen zu Fehlern ohne Rechteerhöhung |
| Schreibdialoge | Plan speichern, Prepare, Schedule mit Startdialog, Pause/Cancel/Apply/Resume: Default Nein, Abbruch ohne Mutation. Nach Review Rechte/Freigabe zurückziehen: aktuelle Gates verhindern Start. JS-Buttonzustand ersetzt keine Backendvalidierung |
| Queue-/Ergebnisbezug | Runbezogene Pakete/Historie/Herkunft/Queue öffnen; entfernte Standardjobs nicht neu anlegen, aktuelle Job-ID nur beim BCSF-Worker zulässig. Paket-Recovery weiterhin über vorhandene Schutzmechanismen |
| Bedienbarkeit | Tastaturreihenfolge, Footer/Scrollbars, Screenreader-live-region, Progress, Zoom/hoher Kontrast und 320px in tatsächlichem BC-Host prüfen. Nach Fehlermeldung/abgelehntem Dialog bedienbar bleiben |

SF-014 bleibt **Zur Prüfung**. Aktueller Vertrag und Dateizuordnung: [DASHBOARD_EMBEDDING.md](DASHBOARD_EMBEDDING.md), [OBJECT_PLAN.md](OBJECT_PLAN.md).


## SF-002 – Strukturumstellung 16.11.2026

**Auftrag / Umfang:** Nutzer beauftragt Typordner innerhalb der bestehenden Module. 104 vorhandene AL-Dateien in elf Modulen verschoben; 13 weitere Module ohne AL-Code mit Modulmarker erhalten. Keine neuen Testobjekte oder fachlichen Änderungen. Ausgangsbestand einschließlich offener Nutzeränderungen vor dem Verschieben per SHA-256 erfasst. Status **Zur Prüfung**.

**Tatsächlich ausgeführt (lokaler Workspace, Codex):**

- XERJ-Map und Projektsuche ausschließlich `bcsf-docs`; historische Strukturentscheidung gegen aktuelle Dateien geprüft. Keine Indexänderung oder externer Feedbackversand; Index kann nach den Verschiebungen veraltete Pfade enthalten.
- Inventar-/Prüfsummenprüfung per Python: genau 104 AL-Dateien, jede am zugeordneten Ziel und bytegleich zum Ausgangsbestand; keine AL-Dateien direkt unter einem Modul und keine leeren neuen Typordner. 18 Tables, 25 Pages, acht PageExtensions, 38 Codeunits, elf Enums sowie je ein PermissionSet, Interface, ControlAddIn und Profile. Alle realen AL-Pfade im Objektplan vorhanden. Keine Änderung von Namen, IDs, Namespaces oder Geschäftslogik durch diese Umstellung.
- Bestehende Dashboarddatei- und Ressourcenverweise geprüft; der Dateipfad im bestehenden `scripts/check_dashboard.mjs` folgt jetzt `Monitoring/Codeunits`. Alle ControlAddIn-Ressourcen vorhanden. Dashboard-JavaScript/-CSS, Manifest, Modulmarker und sämtliche Übersetzungsdateien gegen Ausgangsprüfsummen unverändert; TODO-Ticketdetails außerhalb SF-002 bytegleich.
- Vollständiger Cloud-Build mit AL Compiler 18.1.43.24897, vorhandenem .NET 10.0.15, lokalen BC-28.5-/DE- und System-28.0-Symbolpaketen, Runtime 17, CodeCop/UICop, `/generatecode+ /warnaserror+`: **Exit 0, keine Fehler/Warnungen**; sechs bekannte AW0006-Informationen für Detail-/Vorschauseiten. Keine Regelunterdrückung. Build in isolierter lokaler Kopie von src/Translations/app.json, damit generierte Übersetzungskataloge im Workspace erhalten bleiben. Paket und Protokoll: `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-structure-p8ojstok/BCScenarioFactory.app`, `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-structure-p8ojstok/build.log`; keine Veröffentlichung.
- Paketprüfung: alle drei gebündelten Dashboardressourcen bytegleich zu den Projektquellen. Generierter Textkatalog der Buildkopie enthält dieselben 978 IDs und Quelltexte wie der unveränderte Workspacekatalog.
- `python3 scripts/check_translations.py`: **PASS, 978 Einheiten** in fünf deutschen Kulturen und en-US. `node --check scripts/check_dashboard.mjs`: Exit 0. `node scripts/check_dashboard.mjs`: **PASS** mit bestehendem lokalem Chrome und synthetischer BC-Brücke, einschließlich 29 Einstiegen, Run-Zuordnung, Doppelklickschutz, Fehlerbehandlung, DE-Texten/Zahlenformat, Textdarstellung und Layouts bei 1440/768/320 Pixeln.
- `git diff --check`: Exit 0. Konventionen, Einstieg, Architekturentscheidung, aktuelle/geplante Objektpfade und Modulablagen nachgeführt. Bereits vorhandene Nutzeränderungen erhalten.

**Nicht ausgeführt / verbleibende Grenzen:** Keine BC-Anmeldung, Veröffentlichung, AL-Laufzeit-/Sandbox-/Rechte-/Queue-/Postingtests. Build bestätigt Kompatibilität gegen die vorhandenen lokalen Symbole, keine vollständige Zielumgebungsabnahme. Externe Editor-Lesezeichen oder nicht im Projekt erfasste Skripte können alte Pfade enthalten; XERJ muss diese bei künftiger Nutzung gegen aktuelle Dateien abgleichen. Menschliche Prüfung der neuen Ablage steht aus.


## SF-014 – Scroll- und Sprachkorrektur 17.11.2026

**Umfang:** Nutzer meldet abgeschnittenen unteren Dashboardbereich und englische UI trotz deutscher BC-Oberfläche. Geändert: `src/Monitoring/Dashboard/dashboard.css`, `dashboard.js`, neue generierte `translations.js`, `src/Monitoring/ControlAddIns/BCSFDashboard.ControlAddIn.al`, neuer lokaler Generator `scripts/build_dashboard_translations.py`, bestehender `scripts/check_dashboard.mjs` sowie zugehörige Strukturdokumentation und ausschließlich SF-014 in TODO. Keine neuen AL-Testobjekte, Objektidentitäten oder fachlichen Backendänderungen. Vor Änderungen Ausgangsprüfsummen und TODO gesichert. **Zur Prüfung**.

**Tatsächlich ausgeführt:**

- XERJ-Projektsuche ausschließlich `bcsf-docs`, relevante Dashboard-/Sprachverträge mit lokalen Quellen abgeglichen. Vorhandener deutscher Master und lokales Ausgangspaket enthalten die Dashboardübersetzungen; daraus folgt kein Nachweis für die gemeldete installierte BC-Version oder Ursache des Laufzeitfehlers.
- `python3 scripts/build_dashboard_translations.py` und `--check`: PASS, gebündelter UI-Fallback identisch zu geprüften XLIFF-Quellen/Zielen. `python3 scripts/check_translations.py`: PASS, **977 Texteinheiten** in fünf deutschen Kulturen und en-US. Die Übersetzungsdateien wurden im Korrekturauftrag nicht verändert.
- `node --check src/Monitoring/Dashboard/dashboard.js`: Exit 0. Erweiterter `node scripts/check_dashboard.mjs`: **PASS** mit vorhandener lokaler Chromiuminstallation, ausschließlich synthetische Daten/BC-Brücke. Bestehende 29 Einstiege, Runrouting, Fehlerbehandlung, sichere Textdarstellung, DE/EN und responsive Breiten bestehen weiter. Neue Prüfungen: echte **500px-Iframe** mit nicht scrollbarem äußeren Dokument, interner Überlauf, PageDown, Erreichbarkeit von letzter Queueaktion und Footer sowie gleiche Scrollposition nach Render/Refresh. Deutsche Labels und Schrittstatus bei englischen AL-Ausgangstexten für **de-DE/de-AT/de-CH/de-LI/de-LU**; englische UI bei deutscher Zahlenregion bleibt Englisch mit Format `1.000`. Bereits deutsch gelieferte XLIFF-Labels weiterhin korrekt.
- Vollständige reine AL-Kompilierung von **116 Dateien**, Compiler 18.1.43.24897, vorhandenes .NET 10.0.15, lokale BC-28.5-/DE-/System-28.0-Symbole, Runtime 17, Cloud, generatecode+ und warnaserror+: **Exit 0**, keine Compilerwarnungen/-fehler. Build in isolierter lokaler Kopie, keine Änderung des Workspacekatalogs. Paket `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-dashboard-fix-s6e47e_g/BCScenarioFactory.app`, Log `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-dashboard-fix-s6e47e_g/compiler.log`.
- Strenger Gesamtbuild **mit CodeCop/UICop fehlgeschlagen (Exit 1)**: 23 Befunde AA0073/AA0021/AA0205/AA0207 in unveränderten `BCSFFinancePackageMgt.Codeunit.al`, `BCSFFinanceSetupCheck.Codeunit.al`, `BCSFRunQuality.Codeunit.al` und `BCSFRunOverview.Page.al`. Bytegleichheit aller vier Dateien zur Ausgangsbaseline bestätigt; keine Analyzerfehler im geänderten ControlAddIn. Keine Regeln unterdrückt, keine fremden Tickets korrigiert. Details: `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-dashboard-fix-s6e47e_g/build.log`. Die reine Kompilierung ist ausdrücklich kein bestandener Analyzerlauf.
- Paketprüfung: vier eigene Ressourcen translations.js/dashboard.js/dashboard.css/startup.js im kompilierten Paket vorhanden und bytegleich zu Projektquellen. Keine externen Ressourcen oder neuen Abhängigkeiten. Manifest und fachliche AL-Dateien durch den Korrekturauftrag unverändert.

**Nicht ausgeführt / offen:** Keine BC-Anmeldung, Veröffentlichung, Installation, echte Role-Center-/Sitzungssprach-/Screenreaderabnahme oder AL-/Queue-/Postingtests. Der lokale Iframe verwendet eine nachgebildete BC-Brücke und belegt keine Serverkommandoausführung. Konkreter Grund der englischen AL-Labels im Screenshot **Zu prüfen**. Spätere Installation benötigt vollständiges Paket und Neuöffnen der Oberfläche; keine RAD-Veröffentlichung als Übersetzungsnachweis. Menschliche Abnahme und bestehende Analyzerfehler bleiben offen.

## SF-016/SF-017 – lokaler Prüfnachweis 18.11.2026

**Auftrag:** Beide Tickets ausdrücklich gemeinsam. Ausgangsbestand bereits 116 AL-Dateien einschließlich undokumentierter Qualitäts-/Finanzpaketansätze; keine neuen Objekte/IDs/Testobjekte, keine Bestandsverschiebungen. Vor Änderungen Ziel, Dateien, Risiken und Testweg in [VALIDATION_FINANCE.md](VALIDATION_FINANCE.md) festgehalten. Status beider Tickets **Zur Prüfung**, keine menschliche Abnahme.

**Tatsächlich ausgeführt durch Codex im lokalen Workspace:**

- Pflichtdokumentation, Tickets, reale AL-Objekte und vorhandene Muster geprüft. XERJ ausschließlich `bcsf-docs`: Map, Ticket-/Architektursuche, Memory-Recall und Definitionssuche. Dokumenttreffer verwendbar; keine relevante gespeicherte Erinnerung. Aktuelle AL-Definitionen nicht zuverlässig im Index verfügbar, `xerj_code_search` meldet Corpus nicht indiziert. Lokale Dateien und Symbolquellen maßgeblich, keine Indexänderung oder externer Feedbackversand.
- Ausgangsbuild mit korrigiertem Analyzerpfad: Compiler Exit 0 mit 23 vorhandenen Analyzerwarnungen. Erstaufruf mit falschem Unterpfad `bin/Analyzers` scheiterte (AL1006), anschließend tatsächliche DLLs in `bin` verwendet. Im Ticketumfang wurden Variablenreihenfolge/Temp-Benennung/Datumsinitialisierung sowie der öffentliche Eventsubscriber im lesenden Finanzcheck korrigiert; dieser hat nun einen lokalen Subscriber-Wrapper und bleibt separat aufrufbar.
- Abschließender vollständiger **Cloud-Build aller 116 AL-Dateien**, Compiler **18.1.43.24897**, vorhandener VS-Code-.NET-Host **10.0.15**, lokale fünf Microsoft-Pakete BC **28.5/DE**, System **28.0**, Runtime **17**; `/target:Cloud /generatecode+ /warnaserror+ /analyzer:<bin>/Microsoft.Dynamics.Nav.CodeCop.dll,<bin>/Microsoft.Dynamics.Nav.UICop.dll`: **Exit 0, keine Fehler/Warnungen**. Acht AW0006-Informationen für ausschließlich über Kontextnavigation aufrufbare Detail-/Vorschauseiten. Keine Regelunterdrückung. Paket `/tmp/BCSF-SF016-SF017.app`, Log `/tmp/BCSF-SF016-SF017-build.log`, keine Veröffentlichung.
- Lokale Microsoft-Quellen: tatsächliche Rechnungs-/Gutschriftkopf-Verknüpfung zu Personenposten (Feld 1304), G/L-Transaktionsbezug und Standard-Insert-Trigger von G/L Account/Financial Report geprüft. Verwendete Felder, Enums, SystemId-/FlowField-/Filteraufrufe gegen vorhandene Symbole kompiliert. Die Standardkontenrahmen-2026-Quellen sind im [Paketvertrag](VALIDATION_FINANCE.md) verlinkt; keine vollständigen Kontenrahmen oder externen Skripte übernommen.
- `python3 scripts/check_translations.py --sync` und Prüfmodus: **PASS, 1.071 Texteinheiten** in fünf deutschen Kulturen und en-US. 94 im Ausgangsbestand fehlende bzw. neue UI-Texteinheiten im deutschen Master übersetzt, keine Übersetzungsdienste. `python3 scripts/build_dashboard_translations.py` und `--check`: PASS; bereits vorhandene Dashboard-Fallbackdatei bleibt inhaltlich unverändert.
- `node scripts/check_dashboard.mjs`: **PASS** im vorhandenen lokalen Chromium mit ausschließlich synthetischer BC-Brücke: 29 Einstiege, Runrouting, Zählertrennung, Doppelklickschutz, Fehler-/Schemaerholung, XSS-Textdarstellung, deutsche XLIFF-/Fallbacktexte in fünf Regionen, englische UI mit deutscher Zahlenregion, 500px-Iframe-Scroll/Tastatur/Footer/Refresh, Leerzustand und Breiten 1440/768/320. Dies ist kein AL-/BC-Aktionsnachweis.
- Finale Paketprüfung per Python/ZIP: **sieben XLIFF-Dateien mit jeweils 1.071 Einheiten**, vier Dashboardressourcen bytegleich zum Workspace.
- Objekt-/Scopeprüfung per Python: **116 eindeutige Namen**, 113 eindeutige numerische IDs innerhalb 90100–90999, Namen maximal 30 Zeichen, alle numerischen Objektpfade im Objektplan, Typordner konsistent. Keine Namens-/Typ-ID-Kollision gegen **8.661 tatsächliche Symboldeklarationen** einschließlich Namespaces aus den fünf lokalen Microsoft-Paketen. Keine Aussage über unbekannte installierte Apps. Manifest, Launch und AGENTS bytegleich zu HEAD; detaillierte Ticketabschnitte außerhalb SF-016/SF-017 unverändert.
- Statische Guard-/Datenflussprüfung: acht verpflichtende Insert/Modify/Delete/Rename-Subscriber (false/false) für Befunde/Paketvermerk, zusätzlicher Pflichtbefund-Subscriber aus BackgroundProcessing. Pflicht-/Warntrennung, vollständige Summary und erneute konkrete Postenprüfung; kein generisches Wiederholungs-/Erfolgsflag. Keine neuen Standardtabellenrechte oder Commits. Apply führt keine Modify/Delete/Rename-Operation auf Standarddaten aus; Existenz-/Konfliktprüfung unter Schreibsperre. Diese Quellprüfung ist kein Laufzeitnachweis für Rechte, Rollback oder Parallelität.
- Unabhängige Decimal-Nachrechnung des dokumentierten Standardbuchungsbeispiels: alle vorgesehenen Kontenwerte saldieren auf **0**, Aktiva **1.227,50 EUR**, GuV-Ergebnis **−80,00 EUR**. Ausschließlich Arithmetik; keine BC-Buchungen oder Finanzberichte ausgeführt.
- Lokale Links im neuen Vertrag, Objektplan und Modulindex auflösbar; `git diff --check` abschließend Exit 0. Zwei neu geänderte Statuszeilen mit Markdown-Leerzeichen zuvor bereinigt, keine sonstigen Ticketdetails verändert.

**Nicht ausgeführt:** AL-Selbstprüfungen/Unit-/Integrationstests, echte Sandbox-/Produktions-Negativ-/Berechtigungs-/Security-Filter-/Parallelitäts-/Rollback-/Queue-/Lasttests, tatsächliche Paket-Anwendung/Idempotenz und Standardbuchungen/-berichte je SKR03/SKR04. Keine neue Test-App/Test-Codeunit, kein Deployment und keine Testfirma angelegt. Reale Playground-Version/Firma, ursprüngliche BC-28.0-Kompatibilität, Publisher und externe ID-Konflikte weiterhin **Zu prüfen**. End-to-End-Ausführung bleibt durch fehlende echte Fachgeneratoren und deren konkrete Setupverträge begrenzt. Die zusätzliche Abschlussprüfung liest Ergebnisse erneut; keine Durchsatzgarantie oder Lastmessung.

**Konkrete nächste fachliche Abnahme:** [BC-Prüfplan einschließlich Einkauf, Verkauf, unabhängigem Standardbuchblatt und erwarteten Bilanz-/GuV-Summen je Paket](VALIDATION_FINANCE.md#bc-abnahme--noch-nicht-ausgeführt). Ein Bericht ohne gebuchte Beispielwerte erfüllt die Akzeptanz nicht. Vorhandene CommitBehavior-/lesende-Subscriber-Verträge gegen Drittanbietererweiterungen und implizite Fremdcommits in der tatsächlichen Umgebung prüfen.

## SF-037 – Reparatur Vorlage bis Ergebnis, 18.11.2026

**Status: Zur Prüfung.** Umfang ist der ausdrückliche Reparaturauftrag vom 18.11.2026. Arbeitsgrundlage waren 128 vorhandene AL-Dateien einschließlich lokaler, zunächst uncommitteter Starter-/Transfer-/Queuefixes; vor Änderungen außerhalb des Repositorys gesichert. Keine ältere ZIP eingespielt. Neu ist ausschließlich Tabelle 90148; keine neuen AL-Testobjekte oder Fachgeneratoren. Bestehende Ready-/gespeicherter-Vorzustand-/typisierte-Identitätsfixes in Execution Rules/Dispatcher und der tatsächliche CopyStream-Längenfix bleiben erhalten.

### Nachgewiesene Befunde und Änderungen

- **Übersetzungspaket:** Die vorher vorhandene lokale `Default Publisher_BC Scenario Factory_1.0.1.0.app` enthält 1.158 generierte Einheiten, aber nur je 1.116 in de-DE/en-US. Die 42 Startertexte fehlen dort tatsächlich, nicht nur in der Dokumentation. SHA256 des unverändert gelassenen alten Pakets: `7ad481ce25cc9bb468bb4a5af3664619a654209e37d768f04f92dde2398a9aff`. Dies belegt den lokalen Paketmangel, **nicht**, dass genau dieses Paket in Playground installiert war. Der installierte Stand bleibt zu prüfen.
- **Weitere xRec-Stellen:** `BCSF Recovery Rules.ControlModify` und `BCSF Scenario DB Events.ScenarioModify` lesen jetzt den gespeicherten Vorzustand unter Sperre. Unwiderrufliche Cancel-/Pause-/Revisionsprüfungen bleiben erhalten. `BCSF Run Event Writer` zeichnet jeden persistierten operativen Zustand einschließlich Job-/Zählerwechsel auf; er verwirft keine Historie mehr aufgrund eines unzuverlässigen xRec-Vergleichs. Keine Rohfehler im eigenen Audit und kein neuer Commit.
- **Queuevertrag gegen lokale Microsoft-Quellen:** Standard-Dispatcher 448 speichert In Process und aktuelle Session-/Service-ID vor dem Aufruf von 449; 449 ruft den Worker mit Job Queue Entry auf und rethrowt den Originalfehler; Error Handler 450 schreibt Standardprotokoll und ruft FinalizeRun auf. Worker prüft jetzt zusätzlich die gespeicherte Standardjob-Sitzung, Runner die Claim-Sitzung. Unveränderte Grenzen: einmaliger Job, Kategorie BCSF.SER, Autoretry 0, dauerhafter Claim vor commitfreiem Runner, Herkunft/Checkpoint/Abschluss/Nachfolgejob in einer Transaktion. Die vorhandenen Vorzustands-/Ready-/Integritätsprüfungen sind nicht abgeschwächt.
- **Ursprünglicher CUSTOMER-Fehler:** **Nicht nachgewiesen.** Kein frühester vollständiger Queuefehler und keine freigegebene Reproduktion verfügbar. `Worker.OnRun, Zeile 28` allein ist kein Ursachenbeweis. Neu: Laufkarte zeigt ursprüngliche Standardmeldung, betroffenes Paket und zustandsabhängigen sicheren nächsten Schritt; Standardfehlerdetails/Stack sind direkt erreichbar. Ermittlung berücksichtigt aktuelle/vorige Batchjobs und ältere Jobbindungen der Laufhistorie. NeedsReview wird nicht automatisch wiederholt. Ein Fehlstatus vor Claim erhält einen anderen Hinweis als übernommene unbestätigte Arbeit oder fehlgeschlagene Abschlussprüfung.
- **Normalpfad:** bestehender Quick Run bleibt Snapshot → Plan → Prepare → Schedule; StartCaptured verarbeitet denselben erfassten Run ohne Ersatzlauf. Laufkarte und Dashboard zeigen passende Hauptaktionen; GUID und historischer Anfangsstatus liegen in technischen Details, technische Aktionen unter Diagnose. Partnerzahlen öffnen per SystemId markierte, ausschließlich diesem Run zugeordnete Standardlisten; Ergebniszeilen öffnen die exakte Partnerkarte. Vorlagen-Historienlinks sind auf die ausgewählte Vorlage gefiltert.
- **Vorlagen:** feste Starter-ID plus bekannter unveränderter Standardname bestimmen die reine Sprachanzeige. Keine Umbenennung historischer Snapshots/eigener/importierter Namen. Unbenutzte Vorlagen werden mit Ziel-/Modulzeilen gelöscht, verwendete archiviert. Elternsperre und BeforeDelete prüfen aktuellen Laufbestand erneut; neue Snapshots aus archivierten Vorlagen sind doppelt serverseitig gesperrt. Entfernt-Vermerk 90148 und Archive werden bei normalem Seed respektiert, Wiederherstellung ausschließlich über bestätigte Aktionen. Install-/Upgrade-Trigger bleiben schreibfrei, auch die ungenutzten Installations-Schreibrechte sind entfernt.
- **Transfer/Setup:** feste Länge beim CopyStream bleibt entfernt; Upload.Length und 4-MiB-Grenze werden vor dem tatsächlichen Kopieren geprüft. Feldlängen werden vor begrenzter Zuweisung validiert. Import meldet fehlende Zielcodes für Land, Gruppen und Zahlungsbedingungen konkret. Neue IDs, getrennte Modul-/Zielarrays, transaktionaler Import und kein Startaufruf bleiben erhalten. Demo-Minimaleinrichtung bleibt eine bestätigte Ergänzung fehlender Werte ohne stilles Überschreiben; tatsächlicher Leerfirmentest offen.

### Tatsächlich ausgeführt

| Prüfung | Ergebnis / Grenze |
| --- | --- |
| XERJ | Map, Batchsuche, Definitionssuche und Memory Recall ausschließlich bcsf-docs; Dokument-/Codepassagen mit aktuellem Workspace abgeglichen. Kein Memorytreffer, code_search meldet den Corpus nicht indiziert. Lokale Quellen/Symbole maßgeblich, kein externer Feedbackversand. |
| Ausgangsbuild | Strenger Build scheiterte an 15 Analyzerbefunden im vorhandenen Starter-/Transfer-/Setup-/Szenarioaktionsstand. AA0217, AA0139 und AA0021 im Auftrag behoben, keine Regeln unterdrückt. |
| Vollständiger AL-Build | **PASS**, 129 Dateien, Cloud, Runtime 17, AL Compiler 18.1.43.24897 über vorhandenen .NET-10.0.15-Host, fünf lokale Microsoft-Symbolpakete: System 28.0.57066.0, System Application/Base Application 28.5.54976.57342, Application/Business Foundation 28.5.54976.56550. CodeCop/UICop, generatecode+ und warnaserror+. Keine Fehler/Warnungen; acht AW0006-Informationen für über Kontext erreichbare Detailseiten. Keine Installation fremder Werkzeuge. |
| Frische XLIFF-Kette | **PASS**, vollständiger Build generiert IDs → sync_starter_translations.py → check_translations.py → Dashboard-Fallback → vollständiger Paketbuild. **1.234 Einheiten** jeweils vollständig in de-DE/de-AT/de-CH/de-LI/de-LU/en-US; IDs, Quellen, Platzhalter, Längen und regionale Ableitung geprüft. Bestehende deutsche Übersetzungen und deren Reihenfolge/Format bei unverändertem Inhalt erhalten. |
| Dashboard | **PASS**, vorhandener lokaler Chromium und synthetische BC-Brücke. Hauptaktion bei Ready/Running/Completed/Failed/ValidationFailed; Diagnose zunächst eingeklappt, Zustandsaktionen gefiltert, Aufklapp-/Scrollzustand nach Refresh erhalten. Alle fünf deutschen Regionen einschließlich englisch gelieferter dynamischer Modul-/Entitäts-/Status-/Qualitätswerte; englische UI mit deutscher Zahlenregion. Bestehende Routing-/Doppelklick-/Fehler-/Schema-/XSS-/500px-Iframe-/Tastatur-/Footer-/Responsivefälle bei 1440/768/320 weiterhin bestanden. Kein Nachweis serverseitiger AL-Aktionsausführung. |
| Paketprüfung | **PASS**, scripts/check_package.py prüft App-ID/Version, alle 129 AL-Quellen bytegleich, sieben XLIFF-Kataloge mit passenden Compiler-IDs/Quellen/Zielen und vier bytegleiche gebündelte Dashboardressourcen. Paket enthält vollständigen Stand, keine bloße RAD-Änderung. |
| Statischer Transfervertrag | **PASS**, 27 Top-Level-Schlüssel einschließlich Modul-/Zielarrays in Schreib-/Lesepfad vorhanden, neue GUIDs, kein Snapshot-/Dispatcher-/Generatoraufruf, CopyStream ohne feste Länge. **Kein** ausgeführter AL-Sammeltransfer/Roundtrip. |
| Bestand/Scope | **PASS**, 129 AL-Dateien, 126 eindeutige numerische Typ-/ID-Zuordnungen in 90100–90999, Namen maximal 30 Zeichen, 56 gültige eindeutige feste Starter-GUIDs. Alle vorher vorhandenen Quelldateien erhalten, keine Bestandsverschiebung. Manifest/App-ID/Version unverändert. git diff --check bestanden. |

Der lokale vollständige Build wurde in einer isolierten Quellkopie gegen `.alpackages` ausgeführt, um alte Pakete nicht zu überschreiben. Reproduktionsparameter wie bei Foundation: vorhandener dotnet-Host, `alc.dll /project:<vollständige Quellkopie> /packagecachepath:<Repository>/.alpackages /out:<neues Paket> /target:Cloud /generatecode+ /warnaserror+ /analyzer:<CodeCop.dll>,<UICop.dll>`. Nach XLIFF-Synchronisierung nochmals mit sämtlichen Übersetzungen bauen. `python3 scripts/check_package.py <Paket.app>` gleicht das Lieferpaket mit dem aktuellen Workspace ab.

**Lieferung:** [Vollständiges Paket](../artifacts/BCScenarioFactory-1.0.1.0-SF037.app), [Buildprotokoll](../artifacts/BCScenarioFactory-SF037-build.log). Die alten Root-Pakete bleiben unverändert. Paketprüfsumme siehe abschließenden Nachtrag unten. Lokale `.app`-/`.log`-Dateien bleiben durch die bestehenden Ignore-Regeln außerhalb von Git.

### Nicht ausgeführt / offene Abnahme

Kein nutzbarer autorisierter Browser-/BC-Sandboxzugriff in dieser Sitzung; die erforderliche Browserausführungsfunktion war nicht verfügbar. Keine Zugangsdaten oder lokalen Sitzungsspeicher gelesen. **Nicht ausgeführt:** Installation/Upgrade/Publishing, Demo-Minimaleinrichtung in frischer unbebuchter Firma, UI-Start 5/5 mit 2/2, Mehrpaketfall 12/7 mit 5/5, negativer Setup-/Rollbackfall, zwei Vorlagen gemeinsam zwischen Firmen übertragen, native DE/EN-Seiten-/Dialogprüfung, alte englische Starter in BC, Lösch-/Archiv-/Restore-/Parallelitätsfälle, Standardrechte/Sicherheitsfilter und echte Queue-/Recovery-/AL-Integrationstests. Kein ForceSync, kein Löschen vorhandener Laufdaten, kein Commit/Push/Branchwechsel.

Die ursprüngliche CUSTOMER-Ursache, erfolgreiche Folgeplanung unter tatsächlichem Scheduler, Drittanbietertrigger-/Commitverhalten, tatsächliche Playground-Version/Firma und installierter Übersetzungsstand bleiben **Zu prüfen**. Benötigt wird der **vollständige früheste fehlerhafte CUSTOMER-Standardprotokolleintrag inklusive Fehlerdetails, Stack, Jobbindung/Startzeit und Claimstatus** oder eine ausdrücklich zugängliche freigegebene Sandbox-Reproduktion. Die neuen Fehlerlinks beschaffen diesen Nachweis lesend; sie reparieren alte unsichere Claims nicht automatisch.

Konkrete BC-Abnahmefälle und kürzester Klickpfad: [aktualisierte Testanleitung](review/TESTANLEITUNG.md). SF-037 bleibt **Zur Prüfung**, keine menschliche Abnahme.

**SF-037 – endgültiger Paketabgleich:** Vollständiger finaler Build `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-build-hhaahc3e`; Paket/Protokoll in `artifacts/` abgelegt. `scripts/check_package.py` PASS gegen aktuellen Workspace. SHA256: `85ac61a78c2ed083b3f7b37a87a83e694a52fff468f0c5779ec6a878f3127586`.

### SF-037 – Nachtrag zum JSON-Fehler im Partnerlauf

Nutzer meldet nach dem Paketstart „Die Daten stellen kein gültiges JSON-Token dar.“; Screenshot: fehlgeschlagener 12/7-Partnerlauf mit 0/3 bestätigten Paketen. Der Screenshot allein lokalisiert die auslösende AL-Anweisung nicht. Der inzwischen vom Nutzer erstellte Commit und seine zusätzlichen lokalen TODO-Änderungen werden erhalten; keine Bearbeitung der neuen Tickets SF-038–SF-042 im Rahmen dieses Nachtrags.

**Belegter fehlerhafter Lesepfad:** `BCSF Batch Checkpoint.ReadResult` versuchte den JSON-BLOB nach `Get()` anhand von `HasValue()` nur bedingt per `CalcFields` zu laden. Die Existenzprüfung ist kein Nachweis eines geladenen BLOB-Inhalts. Der erneute Lesezugriff erfolgt beim Paketabschluss (`CheckBatchChange → VerifyCheckpoint → CheckCheckpoint`) sowie bei Abschlussprüfung und Recovery. Microsoft zeigt für gespeicherte BLOBs ausdrücklich `Get → CalcFields → CreateInStream`: [Streams/BLOBs lesen](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-streams-overview).

**Korrektur:** Tabelle 90314 trennt `ReadStoredResult` (lädt den gespeicherten BLOB unbedingt) von `ReadResult` (prüft den aktuellen Speicherinhalt, insbesondere vor Insert). `VerifyCheckpoint` lädt vor der Prüfung explizit. Reconciliation und Run Quality verwenden den gespeicherten Leser. Der Insert-Subscriber behält den noch ungespeicherten gültigen BLOB; ihn aus der Datenbank nachzuladen wäre ebenfalls falsch. Der Writer schließt seinen OutStream ausdrücklich. Leere/ungültige Ergebnisse liefern eine lokalisierte paketbezogene Fehlermeldung und bleiben gesperrt. Alle vorhandenen Identitäts-, Ergebnis-, Herkunfts-, Sitzungs- und Checkpointprüfungen bleiben bestehen. Keine Änderung von Commit-/Retrygrenzen und keine Reparatur bestehender Laufdaten.

**Prüfweg:** vollständiger Build mit CodeCop/UICop, frisch generierte Compiler-IDs, Synchronisierung sämtlicher Ziel-XLF und neuer Paketabgleich. Die vier aktuellen Checkpoint-Lesekontexte gegen reale lokale Aufrufer geprüft. Kein neuer AL-Testgegenstand und keine behauptete BC-Reproduktion. Ergänzende BC-Fälle: frisch geschriebener BLOB vor Insert; erster erneuter Lesezugriff nach Get; Mehrpaketlauf 5/5 bzw. 12/7; Abschlussprüfung; kontrolliert leeres/ungültiges Ergebnis muss blockieren. Alten NeedsReview-Lauf nicht blind wiederholen.

Die konkrete Zuordnung des gemeldeten Screenshots zu diesem Fehlerpfad bleibt ohne vollständigen Stack oder Sandbox-Reproduktion **Zu prüfen**. Die neue lokale TODO nennt einen wieder funktionierenden Partnerlauf als Nutzerbericht; dies ist kein eigener ausgeführter Sandboxtest. Finaler Build-/Paketnachweis dieses Nachtrags folgt unten.

**JSON-Fix – tatsächlicher Abschlussnachweis:** Vollständiger Cloud-Build aller 129 AL-Dateien gegen die vorhandenen BC-28.5-/DE-/Runtime-17-Symbole mit Compiler 18.1.43.24897, CodeCop/UICop, generatecode+ und warnaserror+: **PASS**, keine Fehler/Warnungen, acht bekannte AW0006-Informationen. `check_translations.py`: **PASS**, 1.235 Einheiten in fünf deutschen Regionen und en-US. Dashboard-Fallbackprüfung: PASS. `check_package.py`: **PASS**, App-ID/Version, sämtliche AL-Quellen, sieben passende XLIFF-Dateien und vier Dashboardressourcen. Paket: [JSON-Fix](../artifacts/BCScenarioFactory-1.0.1.0-SF037-JSONFix.app), [Buildprotokoll](../artifacts/BCScenarioFactory-SF037-JSONFix-build.log). SHA256 `583938a25a1d5bdeb4853c95582bb3cb9d945b52ab6773c395349d0a68c6e6eb`. Kein Deployment, kein BC-Lauf, kein eigener Commit/Push.

**Diffprüfung dieses Nachtrags:** Änderungen an Übersetzungen und Dokumentation ohne Whitespace-Befund. Der Gesamtcheck meldet Markdown-Zeilenenden mit zwei Leerzeichen in den bereits vorhandenen lokalen Nutzeränderungen von TODO.md; diese wurden unverändert erhalten.


## SF-038 / SF-039 – lokaler Prüfnachweis 18.11.2026

Beide Tickets ausdrücklich ausgewählt, Finance vor Partnerdaten. Aktueller Workspace und lokale Nutzeränderungen erhalten. [Änderungsvertrag](STABILIZATION_FINANCE_PARTNERS.md), [ausführliche BC-Abnahme mit Sollbeträgen](review/TESTANLEITUNG.md#sf-038sf-039--noch-offene-bc-abnahme). Status beider Tickets **Zur Prüfung**; keine menschliche Abnahme.

**Tatsächlich ausgeführt:**

- Vollständiger Cloud-Build aller **131 AL-Dateien**, Compiler **18.1.43.24897**, CodeCop und UICop, generatecode+, warnaserror+: **PASS**, 0 Fehler, 0 Warnungen, 8 bekannte AW0006-Informationen für nicht suchbare Detail-/Vorschauseiten. App 1.0.1.0 / Runtime 17 / Application 28 unverändert. Symbole aus der vorhandenen `.alpackages`: Microsoft Base/System Application **28.5.54976.57342**, Application/Business Foundation **28.5.54976.56550**, System **28.0.57066.0**; keine Symbole neu geladen. Buildverzeichnis `/var/folders/qj/9rbr1wc575d4skwv8wnt21lw0000gn/T/bcsf-build-x16fut4k`.
- Frische `.g.xlf` aus isoliertem Build → `Translations/sync_starter_translations.py` → `scripts/check_translations.py`: **PASS**, **1.258 Compiler-IDs** vollständig in de-DE/AT/CH/LI/LU und en-US, passende Quellen, Platzhalter und Breiten. Dashboard-Fallback neu erzeugt und mit `--check` geprüft: **PASS**. Anschließend vollständiger Build mit allen Übersetzungen.
- `python3 scripts/check_partner_catalog.py`: **PASS**. 28 lokal gepflegte Katalogpools auf eindeutige/saubere Bausteine, DE/EN-Feldlängen, Branchenkombinationen, PLZ-Formate, reservierte Maildomain und vollständige Permutationszyklen geprüft. 1.024/2.048/4.096 Kombinationen pro entsprechender Poolgröße; kein Integerüberlauf beim maximalen logischen AL-Schlüssel. Dies sind Daten-/Mathematikprüfungen, kein ausgeführter AL- oder BC-Partnerlauf.
- `node scripts/check_dashboard.mjs`: **PASS** im lokalen echten Chromium mit synthetischer BC-Brücke: Handshake, Statushauptaktionen, Diagnosebereich, Navigation, Partner-/Artefaktzähler, doppelte Nachrichten, Fehler-/ungültige Payload-Erholung, XSS-Textdarstellung, fünf deutsche Regionen/englische Sitzung, Tastatur und 1440/768/320px. Keine native BC-Seite/AL-Ausführung.
- `python3 scripts/check_package.py artifacts/BCScenarioFactory-1.0.1.0-SF038-SF039.app`: **PASS**, App-ID/Version, alle **131 aktuellen AL-Quellen**, sieben XLIFF-Dateien mit je 1.258 Einheiten, vier Dashboardressourcen im vollständigen Paket.
- Inventarprüfung: **128 unterschiedliche numerische IDs** innerhalb 90100–90999; 90257/90258 im DataGeneration-Block. Keine neue Generatorbindung und keine neuen AL-Testobjekte. 30 Dateien in BackgroundProcessing/Validation/Lifecycle/Recovery bytegleich zur Sicherung bei Auftragsbeginn; Queue-, JSON-Checkpoint- und Recoveryfixes erhalten. SF-040/041/042-Tickettexte bytegleich zum Auftragsbeginn.
- `git diff --check -- . ':!TODO.md'`: **PASS**. TODO enthält bereits vorher vorhandene Markdown-Zeilenenden mit zwei Leerzeichen aus Nutzeränderungen; diese wurden erhalten, nur SF-038/SF-039-Status und deren Umsetzungsnachweise ergänzt.

**Geprüfter Standardvertrag:** Die lokalen Originalquellen in `Microsoft_Base Application_28.5.54976.57342.app` zeigen für Customer und Vendor `ValidateShortcutDimCode → SaveDefaultDim → Modify()`. Neue Dimensionsvalidierung erfolgt deshalb erst **nach** Standardpartnerinsert, vor Ergebnisregistrierung, in derselben Pakettransaktion. Nichtleere Dimensionen werden vorab auf gültigen Standardwert und Default-Dimension-Rechte geprüft. Kein Umgehen der Standardvalidierung.

**Nicht ausgeführt:** Installation/Upgrade oder Publishing, tatsächliche neue SKR03-/SKR04-Firmen, Wiederholung/konkurrierende Anwendung in BC, Standardverkaufs-/Einkaufs-/Buchblattbuchung und Bilanz-/GuV-Abgleich, DE-50/50-/EN-Läufe, Kinddatensatz-/Belegübernahme, Rechte-/Rollback-/Drittanbietertrigger-/Recoveryfälle und Sammeltransfer zwischen Firmen. Kein angebundener BC-Browser oder Sandbox-Connector verfügbar; keine Sitzung oder Geheimnisse ausgelesen. Der Nutzerbericht über einen bereits funktionierenden vorherigen Partnerlauf bleibt getrennt von diesen neuen Änderungen. Bankprozesse bleiben mangels freigegebenen synthetischen Bankdatensatzes ausdrücklich nicht bereit; CRM-Kontakte werden nur von vorhandener Standardintegration erzeugt. Alte Läufe/Snapshots/Partner und Paketversion 1.0.0 werden nicht migriert.

**Lieferung:** [vollständiges Paket](../artifacts/BCScenarioFactory-1.0.1.0-SF038-SF039.app), [Buildprotokoll](../artifacts/BCScenarioFactory-SF038-SF039-build.log). SHA256 `edf20b36cb02f9cf675a272504db4db8c62993259abcef193efee21002446b3d`. Kein Deployment, kein Commit/Push/Branchwechsel. Vor BC-Abnahme genau dieses Paket installieren; installierter Stand ist hier nicht nachgewiesen.
