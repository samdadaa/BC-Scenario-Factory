# AL-Konventionen — BC Scenario Factory

> SF-002, 11.11.2026: Projektkonventionen zur Prüfung. SF-003/SF-004 implementieren inzwischen die ersten neun AL-Objekte. Die folgenden Regeln konkretisieren den beauftragten Objektplan; der ausdrücklich beauftragte Strukturwechsel vom 16.11.2026 ist in Abschnitt 2 festgehalten.

## 1. Namen und Dateien

- Objektpräfix: `BCSF ` (mit Leerzeichen), kein zusätzliches Suffix. Für kurze Permission-Set-Namen ebenfalls `BCSF` verwenden. Keine externe Registrierung behaupten.
- Namespace: `BCScenarioFactory.<Modul>`; Modulname exakt wie das Verzeichnis unter `src/`. Kein Publisher-Platzhalter im Namespace. Explizite, alphabetisch sortierte `using`-Anweisungen; bei Mehrdeutigkeit qualifizierte Namen.
- Dateiname: Objektname ohne Leerzeichen plus vollständiger Objekttyp, z. B. `BCSFFactorySetup.Table.al`, `BCSFGenerator.Interface.al`. Für die erste implementierte PageExtension (SF-008) gilt entsprechend CodeCop `.PageExt.al`; sonst vollständiger Objekttyp. Keine Bestandsdateien hierfür umbenennen. Eine Datei pro Objekt.
- AL-Objektnamen müssen die plattformspezifischen Längenrestriktionen erfüllen (in der Regel maximal 30 Zeichen inklusive Prefix/Suffix); eindeutige, verständliche Begriffe wählen.
- Objektplan und reservierte Namen/IDs: [OBJECT_PLAN.md](OBJECT_PLAN.md). Neue Namen maximal 30 Zeichen einschließlich Präfix als konservative Projektgrenze; auch ohne Unterscheidung der Groß-/Kleinschreibung auf Eindeutigkeit prüfen.
- PascalCase für benannte Elemente, wo AL-Syntax und Bestand es erlauben; bei AL-Objektbezeichnungen mit Leerzeichen lesbare Fachbegriffe beibehalten.
- Funktionsnamen nach Tätigkeit (`Calculate...`, `Validate...`, `Create...`); Mehrdeutigkeit vermeiden.
- Optionale XML-Dokumentation für erklärungsbedürftige / öffentliche Prozeduren; keine falschen Kommentare.
- Labels, Tooltips und Übersetzbarkeit beachten; keine hartkodierten UI-Fehlermeldungen, wo Labels passend sind.

## 2. Ordnerprofile

**Projektentscheidung vom 16.11.2026 (SF-002):** Der Nutzer beauftragt die Einordnung bestehender AL-Dateien nach Objekttyp innerhalb jedes Moduls. Dies ersetzt die flache Modulablage vom 10.11.2026. Verbindlich ist `src/<Modul>/<Objekttyp>/<ObjectName>.<ObjectType>.al`; Modulgrenzen und Namespaces bleiben erhalten.

| AL-Objekttyp / Dateisuffix | Ordner |
| --- | --- |
| Table / `.Table.al` | `Tables` |
| Page / `.Page.al` | `Pages` |
| PageExtension / `.PageExt.al` | `PageExtensions` |
| Codeunit / `.Codeunit.al` | `Codeunits` |
| Enum / `.Enum.al` | `Enums` |
| EnumExtension / `.EnumExt.al` | `EnumExtensions` |
| PermissionSet / `.PermissionSet.al` | `PermissionSets` |
| Interface / `.Interface.al` | `Interfaces` |
| ControlAddIn / `.ControlAddIn.al` | `ControlAddIns` |
| Profile / `.Profile.al` | `Profiles` |

Beispiel: `src/Core/Tables/BCSFFactorySetup.Table.al`. Typordner nur bei vorhandenen Objekten anlegen; geplante Dateipfade erzeugen keine leeren Verzeichnisse. Weitere Objekttypen bei ihrem ersten beauftragten Einsatz konsistent benennen. Eigene Dashboardressourcen bleiben gemeinsam unter `src/Monitoring/Dashboard/`; ControlAddIn-Pfade sind projektwurzelrelativ.

Die AL Guidelines empfehlen fachliche Gruppierung; die zusätzliche Typunterteilung innerhalb der bestehenden Module ist die ausdrückliche Projektentscheidung des Nutzers. Kein allgemeiner Zwang zu Typordnern wird daraus abgeleitet. Bestandsdateien außerhalb dieses Strukturauftrags weiterhin nur mit ausdrücklichem Auftrag verschieben.


## 3. Formatierung

- Neue AL-Dateien: **2 Leerzeichen**, keine Tabs; konsistente UTF-8-Dateien und abschließender Zeilenumbruch. Es gibt noch keinen bestehenden AL-Formatter-Stil zu migrieren.
- Einheitliches `begin`/`end`, lesbare `if`-/`case`-Blöcke; kurze klar benannte Prozeduren statt riesiger UI-Trigger.
- Eine klare Verantwortung pro AL-Objekt/Prozedur anstreben; keine ungenutzten Variablen/unklaren Abkürzungen.

## 4. Objekt-IDs und App-Konfiguration

Aktuelle, vom Nutzer bestätigte Range: `90100..90999`. 25 Werte je Modul (`90100..90699`); gemeinsame Reserve `90700..90999`. Konkrete Zuordnung ausschließlich aus [OBJECT_PLAN.md](OBJECT_PLAN.md). Ein Planwert wird projektweit nur einmal vergeben; Interfaces bekommen keine deklarierte numerische ID. Keine Feld-IDs oder Test-App-IDs aus dieser Modulplanung ableiten.

- ID-Ranges nur aus gültiger `app.json` und ggf. abgestimmten Reservierungsregeln beziehen. Kollisionsprüfung gegen reale Objekte ist Pflicht.
- `runtime`, `application`, `platform`, Abhängigkeiten und Feature-Verfügbarkeit **zielversionsspezifisch** prüfen.
- Keine fremden Objekte mit identischer ID, Namen oder unpassendem Namespace erzeugen.
- Kein frei erfundenes `app.json`, wenn keine belastbaren Zielversion-/Publisher-Angaben vorliegen.

## 5. Performance

- Filter vor `FindSet`/`Get`, möglichst selektiv und unter Beachtung von Schlüsseln.
- `SetLoadFields` für kompatible reine Lesezugriffe erwägen und benötigte Felder berücksichtigen; insbesondere Schreibpfade sorgfältig prüfen.
- SQL-/DB-Zugriffe in Schleifen, unnötige `Modify`/`CalcFields`, Sperren und lange Transaktionen vermeiden; Optimierungen anhand realer Daten prüfen.
- Temporäre Records einsetzen, wenn sie wirklich Kosten reduzieren, nicht als universelle Lösung.

## 6. Events, Fehler, Erweiterbarkeit

- Pages: Darstellung, Eingabe und Delegation; Geschäftsregeln in zugehörigen Codeunits, Invarianten zusätzlich an geeigneten Tabellenvalidierungen. Keine Massengenerierung in Page-Triggern.
- Modulinterne Prozeduren möglichst `local`; App-interne Objekte bei Eignung `Access = Internal`. Benötigte öffentliche Verträge ausdrücklich im Umsetzungsticket dokumentieren, kein pauschales Public-SDK vor SF-034.
- Generator-Vertrag in ModuleRegistry, Basistypen in Core. Aufrufgrenzen und erlaubte Codeabhängigkeiten gemäß Objektplan; keine Rückreferenzen aus Core auf konkrete Generatoren. Keine Default-Interface-Methoden unter der aktuellen Runtime 17 planen.

- Events/Subscribers bevorzugen, wenn unterstützte Erweiterungspunkte verfügbar sind. Publisher-/Subscriber-Verträge und Skip-Flags vor Verwendung prüfen.
- Klare, lokalisierbare Fehlermeldungen; `TryFunction`-Verhalten, Schreibzugriffe und Rückabwicklung nicht pauschal annehmen.
- Keine Catch-all-Unterdrückung, keine personenbezogenen Daten im Telemetry-Event.

## 7. Tests und Versionssicherheit

- AL-Go App/Test-Trennung nur im passenden Workspace, Test-Projekt referenziert App.
- Neue Testobjekte nur bei explizitem Auftrag; jede Codeänderung dennoch mit realistischen Prüffällen und ggf. vorhandenen Tests absichern.
- Analyzer und Compiler entsprechend Projekt-/BC-Version; nicht ausgeführte Prüfungen als offen kennzeichnen.

**Quellen:**
- https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-code-style/
- https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-naming-conventions/
- https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-performance/
- https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-error-handling/
- https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-events/

## Umsetzungshinweise SF-003/SF-004

Core-Geschäftslogik bleibt ohne Lifecycle-Referenz. Das Core-Permission-Set ist eine rein deklarative Ausnahme zur Modulreferenzregel: es vergibt Execute für den Lifecycle-Guard. Standard-Datenbank-Events binden diesen Guard an Setup-Schreibzugriffe. Keine Abkürzung über `RunTrigger = false` oder `GuiAllowed`; Subscriber überspringen fehlende Lizenz/Rechte nicht. Validierung muss vollständige Datensätze vor Persistenz prüfen; OnValidate allein genügt nicht. Pages besitzen keine `Access`-Property; Tabelle/Enums/Codeunits verwenden `Access = Internal`. Stabile Enumwerte nach Persistenz nicht umnummerieren.


## SF-005/SF-006 – Sprache und Snapshots

Englische Quell-Captions/Labels mit TranslationFile; alle UI-Texte einschließlich Fehlermeldungen in XLIFF vollständig pflegen. Deutscher Master de-DE, identische Regionalableitungen de-AT/de-CH/de-LI/de-LU und en-US-Spiegel. Nach Änderungen vollständigen Build und `scripts/check_translations.py` ausführen; keine automatischen Platzhalterübersetzungen. Gesperrte Katalogeinträge sind synthetische Datenwerte, keine UI-Texte.

Automatische Datensprache anhand ISO-Sprachkennung de bestimmen, nicht anhand einer einzelnen Region oder der Landesversion. Beim Snapshot auflösen und versionieren; Generatoren dürfen die Worker-Sprache nicht neu als Datensprache verwenden. Keine nachträgliche Übersetzung vorhandener Daten.

Snapshot-Schema-/Enum-/Katalogversionen stabil halten. Immutable Datensätze nie per Trigger-false verändern. Narrow-Insert-Permissions nur im festen Snapshot-Schreiber, normale Nutzer mit indirektem Insert; keine pauschalen TableData-Rechte oder Schreib-TryFunctions. Temporäre Snapshot-Unterseiten müssen ausschließlich lokale Darstellungskopien enthalten.

SF-007/SF-008: Temporäre Record-Variablen mit `Temp` benennen; gemeinsame JSON-Werte vor fremder Implementierung tief kopieren. Vertrag-/Katalogversionen prüfen, Probe-Bindungen aus echten Plänen ausschließen. Details: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md).

SF-009/SF-010: SetupManager darf das Start-Ereignis aus DependencyManager abonnieren (neue direkte Ereignisabhängigkeit im Objektplan). Finance abonniert SetupManager, IndustryProfiles den Snapshot Writer. Die Snapshot-Regelerweiterung erhält nur das Regelobjekt per var, keinen veränderbaren Gesamtkontext. Seed-/Regelversionen und Feldstreams sind Teil des reproduzierbaren Vertrags. Unveröffentlichte zukünftige Versionen dürfen historische Version 1 nicht still ersetzen. Siehe [SETUP_SEED.md](SETUP_SEED.md).

SF-011/SF-012: Run Header/Snapshot und gespeicherte Stepkonfiguration bleiben immutable; operativer Status wird separat in BackgroundProcessing gespeichert. App-Batchpläne sind nach Vorbereitung unveränderlich. Statusänderungen nur über feste Writer mit indirekten Anwenderrechten und verpflichtenden DB-Validierungen, auch ohne Tabellentrigger. Registry-Artefakte verwenden positive logische Integer-Schlüssel und stabile Rollen; niemals Hashwerte oder RecordId allein als Ergebnisidentität behandeln. Expliziter Claim-Commit gehört ausschließlich zum Worker; fachlicher Batchteil ist commitfrei und enthält Herkunft/Abschluss/Nachfolgeplanung. Details: [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md).

SF-013: bestätigte technische Checkpoints sind immutable und versioniert (Schema 1, exakt acht technische Ergebnisfelder). Claim-Sitzung wird mit Dienstinstanz und eindeutiger Session-GUID gebunden, nicht aus einem Timeout abgeleitet. Steuerungsanforderung hat einen expliziten eigenen Commit vor dem Elternlock; fachliche Batch-/Recoverytransaktionen bleiben commitfrei. Cancel ist dauerhaft, Retry nur vor bewiesener Nichtübernahme und maximal drei Einplanungen. Keine generischen Force-/Rollback-/Replay-Flags. [RECOVERY.md](RECOVERY.md).

## SF-014/SF-015 – 16.11.2026

Monitoring darf beim Öffnen oder Aktualisieren keine Ausführung starten. Ausdrückliche Bedienaktionen im JavaScript-Dashboard delegieren nach serverseitiger Bestätigung an bestehende geprüfte AL-Workflows. Fortschritt aus Completed-Batches je Step; Artefakte, logische Einheiten und globale Qualitätsfreigabe getrennt benennen. Statushistorie nur technische Metadaten aus derselben Übergangstransaktion, keine Fehlertexte kopieren. UI-Integration über PageExtension im abhängigen Monitoring-Modul erhält die gerichtete Modulstruktur. Geführte Vorlagenbearbeitung nutzt bestehende Policies/Unterseiten; Erfassung trennt editierbare Vorlage und festen Review-Run. [Vertrag und Grenzen](MONITORING_WIZARD.md), **Zur Prüfung**.

JavaScript-Dashboard: alle UI-Texte als AL/XLIFF-Vertrag liefern; DOM über textContent aufbauen, keine HTML-Fragmente aus Daten. Nur gebündelte eigene Ressourcen, asynchrone Aufrufe serialisieren und Fehler sichtbar rückmelden. Wiederverwendung über öffentliche CardPart, keine kopierten Dashboardimplementierungen je Role-Center. [Einbauvertrag](DASHBOARD_EMBEDDING.md).


## SF-014 – Dashboardressourcen 17.11.2026

Nach Änderungen deutscher Dashboard-/Monitoringlabels `python3 scripts/build_dashboard_translations.py` ausführen; die erzeugte `translations.js` gemeinsam mit dem ControlAddIn paketieren. `--check` prüft Frische. Bestehende XLIFF- und Browserprüfungen bleiben erforderlich. UI-Sprache ausschließlich aus dem BC-Payload, Formatregion getrennt; keine Übersetzung gespeicherter Benutzerdaten im Frontend.


## SF-016/SF-017 – 18.11.2026

Validation-Befunde und Finanzpaketidentität sind append-only; feste interne Writer, Ri für Anwender, keine Standardtabellenrechte erhöhen. Pflichtbefunde und optionale WARN-* strikt trennen. Abschluss nur mit vollständigem Summary. Finanz-Kontonummern einschließlich führender Null ausschließlich als Code[20] im Finance-Paket; spätere Generatoren verwenden Paketgruppen statt SKR-Konstanten. Bestehende Vierer-Einrückung im Finance-Paketmanager erhalten, kein Formatierungsrefactoring. [Vertrag](VALIDATION_FINANCE.md).


## SF-018 – 18.11.2026

Echte Generatorbindungen per EnumExtension im jeweiligen Fachmodul; gemeinsame Registry importiert keine konkrete Implementierung. Snapshot-Partnervertrag separat mit Version 1, vorhandenen Seed-/Katalogvertrag nicht umdefinieren. Standardnummern über No. Series API und Standard-Validate/Insert(true); Contact-Text vor Insert wie im [Partnervertrag](PARTNER_GENERATION.md) begründet zuweisen. Kein eigener Generatorcommit und kein fachlicher Resume bei unsicherer Arbeit. Standardkontakte sind abgeleitete Nebenwirkungen, primäre Ergebniszähler bleiben Customer/Vendor.


## SF-037 – Vorlagen und Zustand

Bei Modify-Prüfungen gespeicherten Vorzustand unter passender Sperre lesen; xRec nicht als Nachweis verwenden. Statushistorie enthält auch persistierte Job-/Zähleränderungen. Lokalisierte Standardvorlagennamen sind Anzeigewerte über feste ID plus bekannte Standardbeschreibung, keine Datenmigration. Neuer Remove-Vermerk 90148 ist firmenbezogen und Lifecycle-geschützt. Neue Partner-Snapshots aus archivierten Vorlagen sind gesperrt. Normaler Seed darf Entfernt-Vermerke nicht entfernen.


## SF-044 – Dashboardkacheln

Datenfilter und Laufwahl getrennt halten. Fachliche Kennzahlen verwenden dasselbe responsive Raster; vollständige Kachel nur bei passendem berechtigtem Ziel als Button. Keine verschachtelten Buttons, keine Aktion für unzuverlässig leere Standardlisten. Bestätigte Arbeit nicht mit noch vorhandenen Live-Ergebnissen gleichsetzen. Technische Summen in Diagnose belassen. Texte bleiben AL-/XLIFF-basiert; `Translations/sf044.de.json` pflegt die neuen deutschen Texte für die Synchronisierung mit echten Compiler-IDs.

## SF-019 – Testtrennung und Standardbeziehungen

Die separate Test-App unter `tests/SF019/` wird mit `BCSFTESTS` gebaut; ihre AL-Quelle bleibt im normalen Main-Build per Präprozessor ausgeschlossen. Main-App hat keine Test-Dependency, nur eine ausdrücklich benannte Internals-Freigabe für diese Test-App. [Reproduzierbarer isolierter Build und Runner-Voraussetzungen](INVENTORY_GENERATION.md#automatisierte-test-app).

Zusammengesetzte Standard-Primärschlüssel gegen die tatsächlichen Symbole prüfen; Felddeklarationsreihenfolge und Sekundärschlüssel sind kein Nachweis. Für Item Vendor ist die Reihenfolge Kreditor, Artikel, Variante; `GetItemVendor` bündelt die Lesestellen. Standard-Item-Reference-Insert erzeugt die Bezugsquelle, deshalb keine zweite Item-Vendor-Anlage. Core-Permission-Set darf deklarativ Inventory-Execute aufnehmen; Core-Geschäftslogik bleibt ohne Inventory-Aufruf.

## SF-021 – Buchungsaufruf und Tests

Sales-Post öffentlich nur ohne booleschen Run-Rückgabewert, mit SetSuppressCommit(true) unter CommitBehavior::Error. Internes RunWithCheck nicht direkt aus Fremd-App aufrufen. Standard-Angebotsumwandlung ebenfalls ohne booleschen Run. Keine zusätzlichen Main-Testobjekte; sechs neue Methoden im vorhandenen isolierten Testhost. Snapshot-Schema bleibt 1, neuer optionaler salesSetup-Vertrag Version 1; alte Snapshots erhalten keine Buchungsfreigabe. Keine ForceSync-Änderung. [Vertrag](SALES_PROCESS.md).

### Verbindliche Vorlagenpflege nach jedem Implementierungsticket

Vorhandene Starter gegen den aktuellen Generator-Katalog prüfen und zum Testen aktualisieren; Umfang/Quoten/Quellen und Native-Prüfschritte dokumentieren. Maximalumfang nicht mit tatsächlichem Stepmodus verwechseln. Geeignete Standard-Vorlagenmigration über feste IDs/erkannte ursprüngliche Konfiguration und explizite Ladeaktion; eigene/entfernte/archivierte Vorlagen und Captures schützen. Prozentwerte als Decimal transportieren. Keine automatische Buchungsfreigabe. [Aktueller SF-021-Vertrag](SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051).

## SF-045 – gemeinsame Unternehmensinitialisierung

Neue Generatoren nach dem [verbindlichen Unternehmenspaketvertrag](INDUSTRY_INITIALIZATION.md) integrieren: keine separaten Assistenten, Finanzbootstrap- oder Vorlagenframeworks. Snapshot-Schema 1 wird optional um versioniertes purchaseSetup ergänzt; Altstand nicht nachträglich verändern. Normalstart verwendet genau einen eingefrorenen Firmenrequest; dessen Identität/Parameter bleiben nach Einplanung unveränderlich, Ergebnislauf darf nur die gebundene Standardsitzung zuweisen. Keine zusätzlichen Standardtabellenrechte.
