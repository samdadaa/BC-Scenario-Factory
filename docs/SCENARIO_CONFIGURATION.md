# Szenariovorlagen, Entitätsziele und Sprachen – SF-005/SF-006

**Stand 11.11.2026: implementiert, zur Prüfung.** Beide Tickets und Deutsch/Englisch wurden ausdrücklich gemeinsam beauftragt. Keine Generatoren, Standardbelege, Job-Queue-Starts oder Deployment-Aktionen ausgeführt. Der neue Stand umfasst 32 AL-Objekte, davon 23 neu gegenüber SF-003/SF-004.

## Ziel, betroffene Dateien, Risiken und Prüfweg

Vorlagen sollen kopierbar sein; Änderungen an Vorlage, Modulen oder Zielen dürfen eine erfasste Laufkonfiguration nicht verändern. Ziele/Quoten bleiben je Entität getrennt. Oberfläche und synthetische Textgrundlage unterstützen Deutsch und Englisch. Geändert: neue Core-Sprachobjekte, ScenarioManagement-Tabellen/Pages/Management/Policy, Lifecycle-Subscriber, Setup-Sprachfeld/-Seite, Permission Set, TranslationFile-Feature, XLIFF-Dateien, Übersetzungsprüfung sowie zugehörige Dokumentation und ausschließlich SF-005/SF-006 in TODO. IDs ausschließlich aus 90100–90999 und dem nachgeführten Objektplan; keine Verschiebungen oder Löschungen.

Risiken: tatsächliche UI-Sprachauflösung, Rechte/Security-Filter, direkte DB-Pfade und konkurrierende Snapshots benötigen BC-Laufzeitprüfung. Snapshot-/Kopiermethoden dürfen nicht durch externe TryFunctions als vermeintlich rückabwickelbare Schreiboperationen behandelt werden. Kein universelles Rollback-Versprechen. Lokale Symbolversion weiterhin 28.5/DE, Runtime 17; andere Versionen/Länder nicht durch diesen Build bewiesen. Fachliche Profile/Generatoren/Planner fehlen und werden durch ausgewählte Module oder Profilkennungen nicht als existent ausgegeben.

Prüfweg: vollständiger Cloud-Build mit CodeCop/UICop und Warnungen als Fehlern; XLIFF-Abdeckung einschließlich bestehender Foundation-Texte, IDs/Platzhalter/Längen und Negativvarianten des Prüfers; Quellprüfung von Guard-Bindung, indirekten Rechten, Feldabdeckung, Sperren und unveränderten anderen Tickets. BC-Fälle ausdrücklich separat in TESTS.

## Oberfläche und Datenmodell

- „Scenario Factory Scenarios“ / „Scenario-Factory-Szenarien“ öffnet die Vorlagenliste. „New Scenario“ übernimmt Factory-Defaults einschließlich Datensprache und verwendet das Arbeitsdatum für beide Zeitraumgrenzen. Ohne ausdrücklich initialisiertes gültiges Setup wird nicht geschrieben.
- Vorlage: GUID, Beschreibung, monoton steigende Revision, beabsichtigte Profilkennung/-version, Nutzungsziel, maximaler Prozessumfang, Seed, Zeitraum, Datensprache und Paketgröße. Profilkennung/-version werden vor Snapshot verlangt, sind bis zum Profilkatalog jedoch Benutzerkonfiguration, keine bestätigten existierenden Generatorprofile.
- Module sind fachliche Auswahlwerte; ihre Auswahl beweist keine installierte Generatorfähigkeit. Die Registry-/Preflight-Prüfung bleibt SF-007/008/009. Positive Ziele erfordern das passende aktivierte Modul.
- Ziele separat für Debitoren, Kreditoren, Artikel, Verkaufsangebote/-aufträge/-rechnungen/-gutschriften und Einkaufsbestellungen/-rechnungen/-gutschriften. Pro Szenario/Entität genau ein Datensatz; Menge null deaktiviert das Ziel, negative und über dem Factory-Limit liegende Mengen sind unzulässig.
- „Copy Scenario“ kopiert Kopf, Modulauswahl und Ziele in einer Transaktion mit neuer GUID. Die Kopie hat eigene Revisionen und keine Bindung an spätere Quelländerungen. Revisionen steigen auch beim Anlegen der kopierten Kinddatensätze; es wird keine bestimmte abschließende Kopie-Revisionsnummer zugesagt.
- Profile, Seed-Engine und reale Fachgeneratoren bleiben eigene Tickets. Beschreibung/Profilcode sind Benutzereingaben und werden beim Sprachwechsel nicht automatisch umgeschrieben.

### Mengen und Verteilungen

Vier Modi bleiben erhalten. Jeder aktive Entitätsmodus muss innerhalb des Szenariomaximums liegen. Stammdaten verwenden nur Einrichtung/Stamm ohne gebuchte oder teilweise verarbeitete Anteile. Dokumente benötigen mindestens den ungebuchten Modus; Verkaufsangebote bleiben ungebucht. Teilverarbeitung ist nur für Verkaufsaufträge/Einkaufsbestellungen modelliert. Buchende Vorlagen dürfen geplant werden, während Posting global deaktiviert ist: ein Snapshot ist noch keine Buchungsfreigabe, tatsächliche Generierung muss erneut den SF-003-Guard aufrufen.

Anteile ungebucht/gebucht/teilweise liegen jeweils zwischen 0 und 100, maximal fünf Nachkommastellen, Summe 100. Bei Feld-Validate von „Gebucht %“ oder „Teilweise verarbeitet %“ wird der ungebuchte Rest angepasst; bei „Ungebucht %“ der gebuchte Rest. Eine negative Restquote wird abgewiesen. Direkte Zuweisung ohne Validate muss trotzdem beim Speichern eine gültige Gesamtsumme ergeben.

Geschätzte gebuchte/teilweise Mengen werden jeweils abgerundet; Rest geht auf ungebucht. Beispiel 7 Dokumente, 30 % gebucht/10 % teilweise: 2 gebucht, 0 teilweise, 5 ungebucht. Stammdaten erzeugen in dieser Anzeige keine Dokumentzähler. Das ist eine Mengenplanung, keine Behauptung vorhandener Belege oder Ledgerposten.

Presets 1000/10000/50000/100000 gelten ausschließlich für die aktuell gewählte Entität und respektieren das Factory-Limit. Kein globaler gleichförmiger Mengenzähler. Minimale Debitor-/Kreditorreferenzen auf der Karte sind jeweils 1, wenn entsprechende positive Dokumentziele vorhanden sind: Referenzen können wiederverwendet werden. Dies sind keine Generierungsziele oder geprüften Setup-Voraussetzungen. Artikel-/Positions-/Ledger-Folgemengen können vor dem fachlichen Planner nicht seriös quantifiziert werden und werden nicht erfunden.

## Revisionen, Datenbankpfade und Sicherheit

Vorlagen erhalten beim Insert Revision 1. Persistente Kopfänderungen und jede persistente Modul-/Zieländerung erhöhen die Revision; GUID-/Entitätsschlüssel können nicht umbenannt werden. Vorlagenlöschung ist momentan gesperrt; Modul-/Zielzeilen sind bearbeitbar bzw. löschbar. Ein Modul mit positiven Zielen darf weder deaktiviert noch entfernt werden.

Für alle fünf neuen Tabellen existieren jeweils vier verpflichtende Geschäftsregel- und vier Lifecycle-Subscriber (insgesamt 40 neue Subscriber), beide Skip-Flags false, keine GUI-/RunTrigger-Ausnahme. Konfigurationsschreiben benötigt tatsächliche genehmigte Sandbox/Firma und Setup-Rechte, aber keine aktivierte Datengenerierung. Alle Kindänderungen sperren zuerst den Elternkopf, wodurch Snapshot-Erfassung und Revisionen denselben Serialisierungspunkt verwenden. Datenbank-/Deadlockfehler sind nicht verschluckt; Konkurrenzverhalten bleibt in BC zu verifizieren.

Nur neue temporäre Anzeigedatensätze in den beiden eingefrorenen Unterseiten überspringen persistente Geschäftsregel-/Konfigurations-Subscriber. Sie können keine DB-Zeilen ändern; der explizite Generierungs-Guard benutzt weiterhin sein eigenes persistiertes Setup. Die bestehenden SF-003-Setup-Subscriber bleiben ohne Temporary-Ausnahme.

`BCSF ADMIN` erweitert sich um Konfiguration RIM, Modul-/Zielzeilen RIMD, notwendige Execute-/Page-Rechte und **Ri** für Laufkopf/Snapshot. Klein geschriebenes i bedeutet indirektes Insert. Ausschließlich Snapshot Writer besitzt eng begrenzte direkte Insert-Rechte auf diese beiden eigenen Tabellen. Kein Modify/Delete, keine Standard-BC-Datenrechte, keine pauschale Erhöhung. Sein einziger Schreibaufruf erhält eine Vorlagen-GUID, niemals einen fremden JSON-Inhalt; Guard, Schema-/Kopfkonsistenz und unveränderliche Before-Events bleiben verpflichtend.

## Atomare Lauf-Snapshots

„Capture Run Snapshot“ speichert einen neuen **Draft**, startet keine Queue und erzeugt keine Standarddaten. Der Schreiber sperrt Vorlage und Factory-Setup, validiert die momentane Konfiguration und erstellt Kopf und UTF-8-JSON-BLOB in derselben Transaktion. Mindestens ein positives Ziel sowie Profilkennung/-version sind erforderlich. Kein eigener Commit, keine TryFunction; CommitBehavior::Error verhindert explizite Commits in diesem Aufrufpfad. Fehler bei der normalen, nicht durch TryFunction umschlossenen Ausführung verwerfen die Operation. Externe Aufrufer müssen diesen Transaktionsvertrag respektieren.

Schema 1 erfasst alle zwölf fachlichen Vorlagenfelder, aufgelöste Datensprache, angefragte Sprachoption, Textkatalogversion, aktuelle Mengenlimits, Firma/Umgebung/Zeitpunkt und vollständige sortierte Modul-/Zielarrays einschließlich Quoten und Mengenprojektionen. Enumwerte werden numerisch, Daten/Zeitpunkte invariant im XML-Format und GUIDs ohne lokalisierte Darstellung serialisiert. Keine persönlichen Benutzerkennungen oder echten Geschäftsdaten.

Kopf und Snapshot sind derzeit nach Insert vollständig unveränderlich, auch bei Modify/Delete/Rename ohne Tabellen-Trigger und unabhängig von der noch veränderlichen Vorlage. Die vorhandene Statuslogik aus SF-004 ist damit noch kein persistenter Lauf-Worker: spätere Tickets müssen erlaubte Statusänderungen getrennt von unveränderlicher Konfiguration ergänzen. Kein weiterer Status wird hier simuliert.

Laufkarte und eingefrorene Unterseiten lesen ausschließlich Kopf und Payload. Die Unterseiten sind nur temporäre Darstellungskopien. Sie lesen keine aktuellen Vorlagenziele; auch die Textvorschau verwendet ausschließlich die erfasste Sprache/Katalogversion. Unbekannte Schemaversionen werden beim Lesen abgewiesen. Noch nicht implementierte Profilregeln müssen bei ihrer späteren Einführung durch eine neue Snapshot-Schemaversion ausdrücklich ergänzt werden.

## Deutsch/Englisch

**Oberfläche:** Englische Quelltexte, TranslationFile aktiviert, vollständige XLIFF-Dateien für en-US und de-DE/de-AT/de-CH/de-LI/de-LU. Auch alle bisherigen Foundation-Captions, Tooltips und Fehlermeldungen sind enthalten. Deutschvarianten verwenden denselben gepflegten deutschen Textbestand; weitere deutsche Kulturen nutzen die native primäre Sprachauflösung von BC. Die App ändert weder persönliche BC-Präferenzen noch GlobalLanguage. Der Anzeigesprachwechsel erfolgt über die neue Setup-Aktion „Change Display Language“ / „Anzeigesprache ändern“, die BC „Meine Einstellungen“ öffnet. Maßgeblich ist die in BC gewählte Sprache, nicht die steuerliche Landesversion oder Zahlen-/Datumsregion.

**Daten:** Factory-Default und Vorlage besitzen „Automatic / German / English“. Automatic prüft `Language.GetTwoLetterISOLanguageName(GlobalLanguage()) = de`; somit Deutsch unabhängig von der Region, sonst Englisch. Explizite Auswahl ist möglich. Der Snapshot speichert nur das aufgelöste Deutsch/Englisch und zusätzlich die ursprüngliche Wahl. Ein Worker darf Automatic nicht anhand seiner eigenen Sitzung neu auflösen. Bestehende Daten/Snapshots wechseln nicht nachträglich die Sprache.

XLIFF übersetzt UI-Texte, nicht automatisch gespeicherte Geschäftsdaten. Der versionierte Sprachhelfer stellt deshalb unabhängig von der Worker-Sprache synthetische Namen für CUSTOMER/VENDOR/ITEM bereit (Katalog 1, Vorschauen auf Vorlage und Laufkarte). Seine sprachlich ausgewählten Dateneinträge sind bewusst gesperrte Labels; UI-Übersetzungen verändern sie nicht. Das ist eine bilinguale Textgrundlage, kein bereits implementierter fachlicher Stammdatengenerator. Künftige Generatoren müssen die aufgelöste Snapshot-Sprache und unveränderte historische Katalogversionen verwenden; realistische Varianten/Adressen/Branchenwerte folgen ihren eigenen Tickets.

**Pflege:** Nach vollständigem Build `.g.xlf` als generierte Referenz nutzen, neue/änderte Einheiten im deutschen Master pflegen, `python3 scripts/check_translations.py --sync` leitet regionale Dateien und Englisch ab; anschließend `python3 scripts/check_translations.py` prüft Abdeckung, Quellen, IDs, Platzhalter, Status und Längen. Der Prüfer erfindet keine fehlenden Übersetzungen. Keine DTS-/Remote-Übersetzungsdienste. Keine inkrementellen/RAD-Veröffentlichungen als Übersetzungsnachweis verwenden.

Die native Sprach-Fallback-Reihenfolge, insbesondere nicht deutsche UI-Sprache bei deutschem Umgebungsstandard, ist als tatsächlicher BC-Prüffall offen. Die XLIFF-Paketierung und der Daten-Sprachresolver sind lokal geprüft, das Laufzeitverhalten der Oberfläche ist noch nicht verifiziert. Quellen: [Microsoft – Übersetzungsauflösung](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-translations-overview), [XLIFF](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files), [Sprach-/Regionseinstellungen](https://learn.microsoft.com/en-us/dynamics365/business-central/about-locale-language), geprüft am 11.11.2026. Konkrete Nachweise und ausstehende BC-Fälle: [TESTS.md](TESTS.md).


## Aktueller Stand SF-007/SF-008 – 11.11.2026

Zusätzlich zu den bisher 32 Objekten sind Registry/Planner/Guards ergänzt (gesamt 56). Run Steps 90129 können nun aus dem eingefrorenen Snapshot als Planversion 1 gespeichert werden. Bereits gespeicherte Steps werden nicht neu berechnet; Vorschau nutzt aktuelle Registry. Run Header und Snapshot bleiben vollständig unveränderlich; Status Draft bleibt bestehen. Die Datensprache und Katalogversion des Snapshots werden an den Generatorvertrag weitergereicht.

Vertrag und Grenzen: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md). Status: **Zur Prüfung**, kein Deployment oder BC-Laufzeittest.
