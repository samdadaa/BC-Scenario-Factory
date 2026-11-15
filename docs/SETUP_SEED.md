# Setup-Preflight und synthetische Eingangswerte – SF-009/SF-010

Stand 15.11.2026: implementiert, **Zur Prüfung**. Keine Standarddatenanlage, Einrichtungsergänzung, Buchung oder Queue-Ausführung. BC-Laufzeitabnahme steht aus.

## Ziel, Umfang und Prüfansatz

SF-009 liest aktuelle BC-Einrichtung zu eingefrorenen Laufzielen und liefert einen temporären Maßnahmenplan. SF-010 liefert wiederholbare synthetische Werte aus eingefrorener Konfiguration. Betroffen: SetupManager (Tabelle, Codeunit, Vorschau, Laufkarten-Erweiterung), Finance (lesender Kontencheck), DataGeneration (Engine und Laufkarten-Erweiterung), IndustryProfiles (Regelkatalog), Snapshot Writer, deklarative ADMIN-Rechte, Übersetzungen und Nachweisdokumentation. Bestehende Objekte werden weder verschoben noch ersetzt; Manifest und Launch bleiben unverändert.

Risiken vor Umsetzung: fehlende konkrete Generator-/Setupbindungen, ungeprüfte effektive Rechte und Sicherheitsfilter, versionsabhängige Nummernserien und Lokalisierung. Fachliche Branchenverteilungen und Leerfirmenaufbau sind weiterhin **Zu prüfen**: Welche konkreten Buchungsgruppen, Steuerkombinationen und Branchenverteilungen soll das erste Fachprofil verwenden? Die Umsetzung erfindet hierfür keine erfolgreiche Zuordnung. Testweg: vollständiger Compiler-/CodeCop-/UICop-Lauf gegen lokale Symbole, Übersetzungsprüfung, Objekt-/ID-/Abhängigkeits- und Schreibpfadprüfung; BC-Fälle separat in TESTS.

## SF-009: Bedienung und Evidenz

Auf der Laufkarte **Einrichtungsvorprüfung anzeigen** wählen. Die Vorschau liest den gespeicherten Snapshot, nicht die aktuelle Vorlage. Pro Befund: Voraussetzung, Blocker, Ergebnis und vorgeschlagene manuelle Maßnahme. Wiederholtes Öffnen prüft aktuelle Einrichtungen erneut. Kein persistierter Diff und keine veraltete Freigabe. Schließen der Vorschau ist keine Ausführungsfreigabe.

Geprüft werden:

- Erforderliche Verkaufs-/Einkaufs-/Artikeleinrichtung und konkrete Nummernserienfelder je positiver Entität; bei gebuchten/teilweisen Quoten zusätzlich relevante gebuchte Rechnungs-/Gutschrifts- und Liefer-/Wareneingangsserien. Sichtbare Serie, automatische Nummern, jüngste für das Startdatum geltende Zeile, offene Zeile, Startnummer und positives Inkrement. Keine Nummer wird verbraucht. Bei gleichem Gültigkeitsdatum entscheidet die höchste Zeilennummer.
- Finanzbuchhaltungseinrichtung, positive Betragsrundung und bei Buchungsquoten Abdeckung des gesamten Laufzeitraums durch die allgemeinen zulässigen Buchungsdaten. Konfigurierte globale und zusätzliche Shortcut-Dimensionen müssen sichtbar und ungesperrt sein. Nicht konfigurierte optionale Dimensionen werden nicht erfunden.
- Sichtbare Debitoren-/Kreditoren-/Lagerbuchungsgruppen, allgemeine und MwSt.-Buchungsmatrix, Zahlungsbedingungen. Lagerorte nur bei aktivierter Lagerortpflicht; Lagergrundlagen bei Artikel-/Belegzielen; Warehouse-Einrichtung bei ausdrücklich aktiviertem Warehouse-Modul.
- Effektive grundsätzliche Schreibberechtigung für benötigte Debitoren/Kreditoren/Artikel bzw. Verkaufs-/Einkaufsköpfe mittels RecordRef.WritePermission. Kein Schreibversuch und keine Rechteerhöhung. Ein negatives Ergebnis blockiert; ein positives beweist weder jede einzelne Operation noch Posting-Codeunit-, Lizenz-, Zeilen- oder Security-Filter-Rechte.
- Finance prüft mindestens einen sichtbaren Debitoren-/Kreditorenbuchungsgruppenkandidaten mit vorhandenem, ungesperrtem Sachkonto vom Typ Buchung. Ungültige andere Kandidaten erscheinen als Hinweis mit Gruppe und Kontenfeld; sie erzwingen keine Änderung fremder Konfiguration. Fehlt jeder verwendbare Kandidat, entsteht ein Blocker.

**Verbindlicher verbleibender Blocker:** Die konkrete Auswahl zusammenpassender Buchungsgruppen/Konten/Steuerregeln, Dimensionswerte, Bestand und vollständige Ausführungsrechte muss ein echter Generator prüfen. Tabellenexistenz bedeutet keine fachliche Eignung. Nummernserienkapazität, spätere datumsabhängige Serienwechsel, benutzerspezifische Buchungszeiträume und Sonderimplementierungen werden hier nicht als gültig bestätigt. Ein Pflichtsubscriber am vorhandenen Start-Gate führt den Preflight zusätzlich aus, sobald die bisherigen Plan-/Statusprüfungen dieses Gate erreichen. Bestehende Graph-/Startblocker bleiben erhalten.

**Maßnahmen/Freigabe:** Bestehende Einrichtung beibehalten. Fehlendes in der BC-Standardeinrichtung fachlich prüfen, vor jeder manuellen Änderung eine ausdrückliche Freigabe einholen, anschließend Preflight erneut öffnen. Keine generische Apply-Aktion, kein freigebbarer automatischer Schreibplan ohne bekannte fachliche Sollwerte. Voller Leerfirmenaufbau bleibt außerhalb dieses Tickets.

Nur aktuelle Sichtbarkeit unter effektiven Benutzerrechten wird beurteilt. Fehlen Objekt-Ausführungsrechte, kann BC bereits den lesenden Aufruf mit Berechtigungsfehler abbrechen; das ist kein erfolgreiches Preflight-Ergebnis. Kein TryFunction/Catch verbirgt solche Fehler. Setupwerte oder Geschäftsdatensätze werden weder exportiert noch in Befunden kopiert; Finance zeigt ausschließlich Einrichtungscodes und Feldbezeichnungen.

## SF-010: Vertrag und Vorschau

Auf der Laufkarte **Synthetische Eingangswerte anzeigen** wählen. Gezeigt wird ein lesendes Beispiel für den logischen Artikelschlüssel `1`: Unternehmen, synthetische Person, Artikel, Beispielpreis und Datum. Die Vorschau legt keine Standarddatensätze an. Der alte Core-Namenskatalog bleibt für bestehende Vorschauen kompatibel; die neue Seed-Vorschau ist separat.

`BCSF Seed Engine` bietet intern:

- `SampleInteger(Context, GeneratorCode, LogicalKey, Stream, Minimum, Maximum)` für deterministische Ganzzahlen einschließlich negativer und voller Integer-Grenzen. Tupel sind längencodiert; Decimal-Zwischenwerte vermeiden Integer-Überläufe.
- `SampleDate(..., StartingDate, EndingDate, WeekdaysOnly)` für inklusive Bereiche. Optional werden Wochenenden innerhalb desselben Bereichs auf den nächsten verfügbaren Werktag abgebildet, am Bereichsende mit Rücksprung. Ein Bereich ohne zulässigen Tag wird abgewiesen. Diese Werktagsabbildung ist keine gleichmäßige Verteilung über Werktage und kein Feiertagskalender.
- `BuildValues(Context, EntityCode, LogicalKey)` für CUSTOMER/VENDOR/ITEM als JSON-Eingabewerte. Der vollständige logische Schlüssel bleibt separat erhalten; Anzeigenamen werden auf 100 Zeichen gekürzt und sind keine Datenbankschlüssel.

Algorithmusversion 1: polynomieller Zeichenhash mit Faktor 131 und Modul 2147483647, feste modulare Mischung mit 48271 und zweigliedrige Decimal-Abbildung auf den inklusiven Zielbereich. Nicht kryptografisch; Hashwerte sind keine eindeutigen Identitäten. Generatorcode, logischer Schlüssel und getrennte Feldstreams verhindern Abhängigkeit von Aufruf-/Batchreihenfolge. Input enthält Seed sowie Profilcode/-version. RunId, Session, Uhrzeit und Batchgröße beeinflussen die Werte nicht. Gleiche fachliche Konfiguration erzeugt damit auch in einem neuen Run dieselben Eingangswerte. BC-Nummern und Buchungsergebnisse sind davon ausdrücklich ausgenommen.

Der Snapshot Writer veröffentlicht ein internes Ereignis nur für das Regelobjekt. `BCSF Synthetic Rules` ergänzt versionierte generische technische Defaults: Regelversion 1, Klassen 70 % klein / 25 % mittel / 5 % groß; Preisbereiche 1,00–99,00 / 100,00–999,00 / 1.000,00–9.999,00 in 0,01-Schritten. Das sind synthetische Ausgangswerte, keine Marktwerte oder garantierten Quoten je endlicher Stichprobe. Profilcode/-version sind wie bisher erfasste Benutzerkonfiguration; hier entsteht kein vollständiger Branchenprofilkatalog (SF-023). Die Engine liest ausschließlich das eingefrorene Regelobjekt; angepasste gültige Quoten/Preisbereiche können über denselben internen Vertrag verarbeitet werden. Eine UI zur Bearbeitung von Profilregeln bleibt SF-023.

Neue Schema-1-Snapshots ergänzen `seedEngineVersion: 1` und `syntheticRules` mit Version und allen obigen Werten. Altsnapshots bleiben lesbar und unverändert; die neue Seed-Vorschau verlangt diese Angaben und fordert bei fehlenden Feldern einen neuen Lauf über den Vertragsfehler an. Kein stilles Ergänzen aus aktuellen Defaults. Version 1 von Engine, Regeln und Textkatalog muss bei späteren Erweiterungen erhalten bleiben.

Namen verwenden ausschließlich markierte, konstruierte Testkataloge auf Deutsch/Englisch, ausgewählt nach erfasster Datensprache. E-Mail ist fest `synthetic@example.invalid`; Telefon, Bank-/Zahlungskonten und Zustelladressen werden nicht erzeugt. Keine echten Empfänger, Kontakte oder Konten werden eingelesen; keinerlei Versand. Erreichbare Integrationen müssen spätere Fachgeneratoren weiterhin unabhängig absichern.

## Rechte, Transaktionen und Grenzen

Neue Objekte sind intern; die Pages sind über die Laufkarte erreichbar. ADMIN erhält ausschließlich zusätzliche Objekt-Ausführungsrechte, keine Standardtabellenrechte. Die ausführbare Core-Logik bleibt unabhängig; die deklarative Rollenaggregation bleibt die bestehende dokumentierte Ausnahme.

Setup-Diff ist TableType Temporary. Alle neuen Datenbankzugriffe auf Standardtabellen sind lesend. Kein Commit, TryFunction, Queue-/Postingaufruf oder Ledger-Insert. Snapshot-Erfassung behält den bestehenden gemeinsamen Transaktions-/Guardvertrag; nur das bereits geschützte App-Payload wird um versionierte Regeln ergänzt. Read-only-Vorschauen benötigen keine Generierungsfreigabe. Schreibende Folgeprozesse bleiben sandboxgebunden.

Die Setupprüfung liest mehrere Tabellen ohne Langzeitsperre. Das Ergebnis ist eine aktuelle Vorschau, keine atomare Ausführungszusage; spätere Worker müssen unmittelbar vor Mutation erneut prüfen. Kosten: kleine Einrichtungslesezugriffe pro Ziel plus Scan sichtbarer Debitoren-/Kreditorenbuchungsgruppen und zugehöriger Konten; keine behauptete Lastmessung. Seed-Werte hängen von Schlüssellänge ab und benötigen keine Standarddatenbankzugriffe.

Prüfnachweise und ausstehende Laufzeitfälle: [TESTS.md](TESTS.md). Beide Tickets bleiben **Zur Prüfung**.
