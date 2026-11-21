# SF-045 – Branchengesteuerte Unternehmensinitialisierung

## Auftrag und Plan vor Änderungen (21.11.2026)

Der ausdrücklich beauftragte Architekturwechsel ersetzt den normalen Weg Einrichtung → Vorlagenwahl → Queue durch Kontenplan → Branche → Größe → Prozessstufe → Zusammenfassung/Start. Zuerst Großhandel mit ungebuchten Einkaufs- und Verkaufsbelegen. Bestehende Partner-, Artikel-, Verkaufs-, Snapshot-, Plan-, Queue-, Checkpoint- und Qualitätslogik wiederverwenden. Keine zusätzliche Branchen-Datenbank und keine Löschung historischer Strukturen.

Betroffen: bestehende Setupkarte/-tabelle, IndustryProfiles, Finance, Purchasing, Monitoring, Berechtigungssatz, isolierter Testhost, Übersetzungen und Projektdokumentation. Neue Objekte nur für den nachweislich fehlenden Einkaufsbeleggenerator und die Hintergrundorchestrierung. Die vorhandene Setupkarte wird Assistent; kein zusätzlicher Dialogstapel. Gemeinsame Einrichtung und interne Paketvorlage werden in einem Standard-Queuejob atomar vorbereitet, anschließend übernimmt die vorhandene Batchengine.

Risiken: Standardtrigger in leerer Firma, effektive Rechte, konfliktbehaftete vorhandene Einrichtung, implizite Commits, konkurrierender Start und unsichere Wiederaufnahme. Keine stillen Überschreibungen, keine automatische Wiederholung unklarer Buchungen, kein ForceSync. Paketversionen und historische Snapshots erhalten. Branchenauswahl zunächst ausschließlich Großhandel; Buchungsstufe gesperrt, solange vorgelagerte Standardwareneingänge fehlen. Andere Branchen sind keine ausführbaren Pakete.

Testweg: AL-App und getrennten Testhost kompilieren; vorhandene Vertrags-, Übersetzungs- und Dashboardprüfungen; neue Referenz-/Negativfälle im bestehenden isolierten Testhost. Native Sandboxabnahme für SKR03/SKR04, vorhandene Einrichtung, Rechte, Browser schließen, Fehler nach Batch und Upgrade ausdrücklich getrennt protokollieren. Kein Deployment im Auftrag.

Zu prüfen: Tatsächlich installierte BC-Version/Lizenz, lokale Standardtrigger in frischer Sandbox und fachliche Berichtsabnahme. Lokale Pakete sind begrenzte Testkontenrahmen, keine offiziellen DATEV-Vollkontenrahmen.

## Implementierter Benutzerweg

1. Das Factory-Dashboard öffnet in einer noch nicht initialisierten Firma ohne laufende Anfrage die vorhandene Setupkarte als Assistent. Abbrechen führt keine Standarddatenanlage aus.
2. Kontenplan SKR03/SKR04 oder vorhandene gültige Einrichtung auswählen. Bei bereits initialisierter Firma bleibt der tatsächliche Kontenplan fest.
3. Großhandel auswählen; derzeit gibt es genau ein ausführbares Unternehmenspaket. Branche ist im Assistenten entsprechend fest vorgegeben. Weitere Zielbranchen bleiben außerhalb dieser Auswahl.
4. Klein, Mittel oder Groß und anschließend **Nur Stammdaten** oder **Mit ungebuchten Belegen** wählen. Die bisherige Setupkarte enthält fünf sichtbare Schritte einschließlich Zusammenfassung; keine zusätzliche Seite. Die Buchungsstufe ist nicht auswählbar.
5. Zusammenfassung prüfen und **Unternehmen einrichten und Daten erzeugen** wählen. Dieser Klick autorisiert die angezeigte Einrichtung und Generierung. Keine weiteren Finanz-/Planungs-/Queue-Dialoge. Danach kann der Browser geschlossen werden.
6. Dashboard aktualisieren. Firmenstatus und bestätigter Unternehmensfortschritt sind unabhängig von der historischen Laufwahl. Bestandskacheln verwenden die vorhandenen Filter und Standardlisten. Fehler zeigen die betroffene Einrichtung/Entität und den ursprünglichen Queuefehler; **Aktueller Hintergrundauftrag** liegt im eingeklappten Expertenbereich und öffnet die vorhandene Standardseite.

| Führendes Ziel | Klein | Mittel | Groß |
| --- | ---: | ---: | ---: |
| Debitoren | 20 | 200 | 2.000 |
| Kreditoren | 5 | 50 | 500 |
| Artikel | 40 | 400 | 4.000 |
| Einkaufsbestellungen | 15 | 150 | 1.500 |
| Verkaufsangebote | 5 | 50 | 500 |
| Verkaufsaufträge | 12 | 120 | 1.200 |
| Verkaufsrechnungen | 3 | 30 | 300 |

In der Stammdatenstufe entfallen sämtliche Belegziele. Beziehungen wie Kategorien, Einheiten, Varianten, Referenzen und Adressen kommen aus den bereits implementierten Katalogen hinzu; sie sind keine zusätzlichen führenden Zielmengen. Betriebliche Limits werden vor Einplanung geprüft. Ein vorhandenes Factory-Setup mit deaktivierter Generierung wird nicht heimlich wieder freigeschaltet. Die Anfrage friert auch das Datum ein; Mengen/Parameter können nach Einplanung nicht umgeschrieben werden.

## Wiederverwendete und ergänzte Komponenten

[Der Audit](ARCHITECTURE_AUDIT_SF045.md) enthält jedes der 137 aktuellen AL-Objekte mit Einstufung, Referenzzahl, Event-/Subscriberinventar, JSON und Ausführungsmodell.

- **Zusammengeführt:** Normaler Setup-/Startweg in der vorhandenen Setupkarte und einer festen Orchestrierung; Unternehmensmengen in Wholesale Profile. Kein neuer Brancheneditor, keine zweite Paketpersistenz, keine zusätzliche Prozessengine.
- **Intern beibehalten:** Szenarien, Ziele/Module, Snapshot/Header/Steps, Herkunft, Execution/Batches/Checkpoints, Validierung, Ereignisse und vorhandene Diagnose-/Transferseiten. Technische Vorlagenlisten/-zähler verschwinden aus dem normalen Dashboardpfad; Import/Export bleibt optional.
- **Ergänzt:** Codeunit 90153 Wholesale Profile, Codeunit 90361 Company Initialization, Codeunit 90451 Purchase Generator und EnumExtension 90453 Purchase Binding. Sechs technische Requestfelder im bestehenden Factory Setup. Keine neue Tabelle oder Seite.
- **Entfernt:** Keine Datei, kein Objekt und keine persistente Struktur. Historische und laufende Referenzen rechtfertigen den Erhalt; ein Quell-Audit kann keinen installierten Tabellenbestand freigeben.

Die lokale Variante des Unternehmenspakets verwendet `TRADE` Version `3`, vorhandene Partner-/Artikelkataloge und eine normale interne Vorlage. Die bestehenden Starter werden bei einer expliziten Ladeaktion erhalten; ein neuer fester Großhandelsreferenzstarter kommt hinzu. Eigene/archivierte/entfernte Vorlagen werden nicht ersetzt. Der normale Erststart lädt keine 60 technischen Starter und benötigt keine Vorlageauswahl.

## Technischer Ablauf und fachliche Grenzen

Der Assistent speichert nur den Firmenrequest und einen Standard-Queuejob. Dieser liest den gespeicherten Job, Objekt-/RecordId-/Sitzungs-/Serverbezug, Sandbox, Firma und Rechte erneut. **Foundation, interne Vorlage, Snapshot, Plan, erste Batchaufgabe und Ergebnislauf-ID bilden eine CommitBehavior::Error-Transaktion.** Ein Fehler vor deren Abschluss hinterlässt keine teilweise vorbereitete BC-Finanzbasis. Ein gespeicherter Ergebnislauf verhindert eine zweite Datenplanung. Unbekannte oder widersprüchliche Einrichtung stoppt konkret; Standardrechte werden nicht erhöht.

Danach übernimmt die bestehende Engine: Debitoren/Kreditoren → Artikel/Beziehungen → Einkaufsbestellungen → Verkaufsbelege → Output-/Gesamtqualität. Jeder bestätigte Batch behält seinen Checkpoint und seine Herkunft. Unklare Arbeit wird nicht automatisch wiederholt. Der neue Bootstrapjob hat Autoretry 0 und ist nicht wiederkehrend; er selbst kann keinen Lauf auf Completed setzen.

Einkaufsbestellungen verwenden Standard-Purchase-Header/-Line, Validate und Insert(true). Die Artikel und ihr tatsächlich hinterlegter Lieferant müssen aus demselben Lauf stammen; Bezugsquelle, Einheit, Preis/Kosten und Buchungsgruppen werden geprüft. Es gibt keine direkten Posten-Inserts, keinen Standardbuchungsaufruf in diesem Generator und keine stillschweigende Buchungsfreigabe. Unterstützt sind einfache Lagerorte ohne erforderliche Logistikprozesse. Beschaffungsbuchungen, Bestandszugänge, Zahlung/Ausgleich und weitere Unternehmensbranchen fehlen weiterhin. Die dritte Unternehmensstufe bleibt deshalb gesperrt; bestehende historische Verkaufsverträge werden nicht nachträglich geändert.

## Finanzpakete und Berichte

Neue SKR03-/SKR04-Pakete tragen Version **3.0.0**, Referenzjahr 2026. Es sind lokal enthaltene, begrenzte deutsche Testkontenrahmen für die unterstützten Fälle, keine offiziellen vollständigen DATEV-Kontenrahmen und keine DATEV-Liveabfrage. Die bestehende Kontenbasis enthält Bilanz-/Bank-/Bestands-/Forderungs-/Verbindlichkeitskonten, Eigenkapital, Vor-/Umsatzsteuer, Erlöse, Waren-/Betriebskosten und abgestimmte Matrizen. Es werden keine zwei beliebigen Ersatzkonten als vollständige Einrichtung ausgegeben.

Zusätzlich zu `SF03-BS`/`SF04-BS` und `SF03-PL`/`SF04-PL` entstehen `SF03-BWA`/`SF04-BWA`. BWA-Zeilen: Erlöse, Warenkosten, Rohergebnis, Betriebskosten, Ergebnis und Abstimmungsdifferenz. Rechenlogik: `GROSS=SALES+COGS`, `RESULT=GROSS+OPEX`, `CHECK=RESULT-(SALES+COGS+OPEX)`. Es gilt die bestehende Soll-/Haben-Saldenkonvention des Testberichts: Erlöse/Habenergebnis negativ, Kosten positiv. Beispiel -1.000 + 600 + 150 ergibt -250 Gewinnsaldo und Abstimmungsdifferenz 0. Keine Lohn-, Abschreibungs-, Finanzierungs- oder steuerliche Voll-BWA. Diese Vorgänge werden heute nicht generiert.

Im ungebuchten Referenzfall bleiben Berichte folgerichtig ohne durch diesen Lauf erzeugte Buchungssalden. Die Formelstruktur wurde lokal arithmetisch geprüft; die tatsächliche BC-Auswertung und eine fachliche Abstimmung nach separaten Standardbuchungsproben bleiben **Zu prüfen**. Installierte Paketversionen 1.0.0 und 2.0.0 werden nicht auf 3.0.0 umgeschrieben; sie erhalten keinen heimlichen neuen Bericht. Wer vorhandene gültige Einrichtung verwendet, bekommt keinen SKR-Kontenplan übergestülpt.

## Kompatibilität, Prüfstand und Restabnahme

App-Version 1.0.6.0; unveränderte App-ID, Publisher, Runtime 17, Application 28.0 und Dependencies []. Die sechs neuen optionalen Requestfelder sind additive Schemaergänzungen; keine ForceSync-/Upgrade-Abkürzung. `purchaseSetup` Version 1 ist optional im bestehenden Snapshot-Schema 1. Alte Vorlagen/Läufe/Snapshots bleiben unverändert, eigene Konfigurationen und Starter-Entfernungsvermerke erhalten. Vorhandene Queuejobs werden nicht umgestellt.

[Das Prüfprotokoll](TESTS.md#sf-045--branchengesteuerte-unternehmensinitialisierung) trennt Compiler/Analyzer, lokale Browser-/Vertragsprüfungen und noch nicht ausgeführte BC-Abnahme. Fünf neue Methoden liegen im bereits getrennten Testhost (jetzt 31 Tests), keine Test-Codeunit in der Main-App. [Native Anleitung für den kleinen Referenzfall](review/TESTANLEITUNG.md#sf-045--zuerst-den-frischen-großhandelsfall-prüfen).

**Die zentrale Nutzerabnahme ist noch offen:** Frische SKR04-/SKR03-Firma, tatsächliche Einrichtung und Standardtrigger, Rechte/Lizenz, Browser schließen, Fehler nach abgeschlossenem Batch, DE/EN und Altstand-Upgrade wurden nicht in BC ausgeführt. Die lokalen Befunde sind kein Nachweis eines zuverlässig abgeschlossenen Testunternehmens. Für Mittel/Groß bleibt außerdem die bestehende Herkunftsfiltergrenze im Dashboard offen (150 sichtbare Datensätze/1.200 gescannte Herkunftseinträge je Kennzahl); bestätigter Fortschritt ist davon getrennt, eine begrenzte Kennzahl wird nicht als falsche Zahl ausgegeben. Status **Zur Prüfung**, keine menschliche Abnahme.
