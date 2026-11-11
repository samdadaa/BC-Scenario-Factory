# AL-Konventionen — BC Scenario Factory

> SF-002, 11.11.2026: Projektkonventionen zur Prüfung. SF-003/SF-004 implementieren inzwischen die ersten neun AL-Objekte. Die folgenden Regeln konkretisieren den beauftragten Objektplan; vorhandene Dateien werden nicht umstrukturiert.

## 1. Namen und Dateien

- Objektpräfix: `BCSF ` (mit Leerzeichen), kein zusätzliches Suffix. Für kurze Permission-Set-Namen ebenfalls `BCSF` verwenden. Keine externe Registrierung behaupten.
- Namespace: `BCScenarioFactory.<Modul>`; Modulname exakt wie das Verzeichnis unter `src/`. Kein Publisher-Platzhalter im Namespace. Explizite, alphabetisch sortierte `using`-Anweisungen; bei Mehrdeutigkeit qualifizierte Namen.
- Dateiname: Objektname ohne Leerzeichen plus vollständiger Objekttyp, z. B. `BCSFFactorySetup.Table.al`, `BCSFGenerator.Interface.al`. Auch `TableExtension`/`PageExtension` ausschreiben, keine gemischten Typkürzel. Eine Datei pro Objekt.
- AL-Objektnamen müssen die plattformspezifischen Längenrestriktionen erfüllen (in der Regel maximal 30 Zeichen inklusive Prefix/Suffix); eindeutige, verständliche Begriffe wählen.
- Objektplan und reservierte Namen/IDs: [OBJECT_PLAN.md](OBJECT_PLAN.md). Neue Namen maximal 30 Zeichen einschließlich Präfix als konservative Projektgrenze; auch ohne Unterscheidung der Groß-/Kleinschreibung auf Eindeutigkeit prüfen.
- PascalCase für benannte Elemente, wo AL-Syntax und Bestand es erlauben; bei AL-Objektbezeichnungen mit Leerzeichen lesbare Fachbegriffe beibehalten.
- Funktionsnamen nach Tätigkeit (`Calculate...`, `Validate...`, `Create...`); Mehrdeutigkeit vermeiden.
- Optionale XML-Dokumentation für erklärungsbedürftige / öffentliche Prozeduren; keine falschen Kommentare.
- Labels, Tooltips und Übersetzbarkeit beachten; keine hartkodierten UI-Fehlermeldungen, wo Labels passend sind.

## 2. Ordnerprofile

**Projektentscheidung vom 10.11.2026:** Für BC Scenario Factory gilt `src/<Modul>/` **ohne vorab angelegte Typ-Unterordner**. Neue AL-Dateien im jeweiligen Modul direkt ablegen; weitere fachliche Unterordner nur bei echter Komplexität und nach Ticketfreigabe. Kein `src/<Modul>/Tables|Pages|Codeunits`-Zwang. Bestehende AL-Dateien weiterhin nie ohne Auftrag verschieben.


| Profil | Aufbau | Entscheidung |
| --- | --- | --- |
| Standard | `src/Tables`, `src/Pages`, `src/Codeunits` usw. | AL-Agentura-MVP; behalten, wenn ausgewählt |
| Modular | `src/<Modul>/Tables`, `src/<Modul>/Codeunits` usw. | Modularisierung nach bestätigten Modulen |
| Feature-first | `src/<Fachbereich>/<Feature>` mit AL-Objekttypen nach Bedarf | AL-Guidelines-orientierte Alternative, **nicht automatisch von AL Agentura umsetzen** |

Nicht bei jedem Ticket neue Struktur erfinden. Keine Bestandsdatei ohne Nutzerfreigabe verschieben.

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
