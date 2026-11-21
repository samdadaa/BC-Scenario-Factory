# SF-045 – Branchengesteuerte Unternehmensinitialisierung

## Aktueller Folgeumfang 1.0.7.0 – Einkauf, Buchung und Ausgleich

**Status: Zur Prüfung.** Diese Ergänzung ersetzt die unten dokumentierten Grenzen des Erststands 1.0.6.0. Großhandel `TRADE` Version **4** bietet vier Stufen: Stammdaten, ungebuchte Belege, gebuchte Bewegungen und Zahlungen/Ausgleich. Weitere Branchen bleiben gesperrt. Der bestehende Assistent enthält bei Buchungsstufen eine ausdrückliche Zustimmung; eine Vorlagenkopie oder ein Import übernimmt keine Buchungsfreigabe. Nach einem abgeschlossenen Lauf kann **Unternehmensdaten erzeugen** einen neuen Datensatz mit gleicher Mandanteneinrichtung starten. Laufhistorie, eigene Vorlagen und archivierte/entfernte Starter bleiben erhalten. Laufende, fehlgeschlagene oder unklare Arbeit wird dadurch nicht ersetzt.

Der maximale Umfang enthält absichtlich unterschiedliche Belegzustände. Angebote bleiben ungebucht; Teilquoten gelten nur für Aufträge. Prozentquoten werden je Zielmenge abgerundet.

| Ziel | Voll gebucht | Teil gebucht | Ungebucht | Ergebnis Klein |
| --- | ---: | ---: | ---: | --- |
| 15 Einkaufsbestellungen | 60 % | 20 % | Rest | 9 volle + 3 halbe Eingänge/Rechnungen, 6 verbleibende Bestellungen |
| 12 Verkaufsaufträge | 50 % | 25 % | Rest | 6 volle + 3 halbe Rechnungen, 6 verbleibende Aufträge |
| 3 Verkaufsrechnungen | 67 % | 0 % | Rest | 2 gebuchte, 1 ungebuchte Rechnung |
| 5 Verkaufsangebote | 0 % | 0 % | 100 % | 5 ungebuchte Angebote |

In der Zahlungsstufe werden die **23 tatsächlich gebuchten Rechnungen** im kleinen Lauf vollständig am Rechnungsbuchungsdatum bezahlt und ausgeglichen: 12 Kreditoren- und 11 Debitorenzahlungen sowie 23 Bankposten. Ungebuchte Restbelege werden nicht bezahlt. Keine Teilzahlungen, abweichenden Zahlungszeitpunkte, Gutschriften oder Retouren im ausgewählten SF-022-Teilumfang; diese bleiben offen. Nur lokale synthetische Verrechnung über `BCSF-PAY`, ohne IBAN/Kontonummer/SWIFT und ohne externe Übermittlung.

### Datenfluss, Einrichtung und Transaktion

Same-run-Partner → Artikel → Standard-Einkaufseingang/Rechnung → Verkauf → optional Standardzahlung/Ausgleich. Einkauf verwendet den wirklichen Artikellieferanten desselben Laufs. Die Beschaffungsmenge deckt die geplanten gebuchten Verkäufe ab; Eingang am Zeitraumstart liegt vor dem Verkauf. Bei teilgebuchten Bestellungen wird eine echte halbe Menge empfangen und fakturiert. Standard `Purch.-Post` läuft mit unterdrücktem Commit, Standard `Gen. Jnl.-Post Line.RunWithCheck` mit temporärer Buchblattzeile. Buchung, Herkunft, Zahlung und Batchbestätigung stehen unter den vorhandenen Transaktions-/Claimgrenzen. Kein direkter Standardposten-Insert und kein Boolean-Codeunit.Run mit implizitem Commit.

Die gemeinsame Foundation bleibt einmalig. Für neue Buchungsläufe wird automatische Lagerwertbuchung benötigt. Sie wird nur in einer Firma ohne Sach- und Artikelposten aktiviert; bei vorhandenen Posten und abweichender Kostenbuchungseinstellung stoppt der Start. Bestehende Kostenpolitik wird nicht still verändert. Bankbuchungsgruppe und direkt buchbares Sachkonto, General-Buchblattvorlage/-Batch sowie Quellcode werden eingefroren und erneut geprüft. Mehrdeutige Einrichtung stoppt. Unterstützt sind LCY, einfache Lagerorte ohne erforderliche Logistik und die bestehenden synthetischen Artikel-/Steuerkombinationen. Berichte/Bestandsbewertung benötigen native fachliche Abstimmung.

`purchaseSetup` Version 2 enthält Buchungsfreigabe sowie Bestell-/Eingangs-/Rechnungsserien. `salesSetup` Version 3 erlaubt den neuen beschafften Same-run-Pfad; historische Version 2 bleibt für Buchungen blockiert. Optionales `paymentSetup` Version 1 friert die ausdrückliche Freigabe und Verrechnungseinrichtung ein. Snapshot-Schema bleibt 1, alte ungebuchte Einkaufssnapshots Version 1 bleiben lesbar. Neue Felder: Scenario 43/44 und Factory Setup 26, ausschließlich additiv. Kein ForceSync, keine neue Tabelle/Seite, keine zusätzliche App-Abhängigkeit. Zwei neue Codeunits: **90454 Purchase Evidence** und **90401 Payment Processor**; insgesamt 139 Main-AL-Objekte. Main 1.0.7.0, separate Test-App 1.3.0.0, 36 Testmethoden.

### Gemeldeter Berechtigungsfehler und Korrektur

Der Nutzertest meldete vor dem Datenlauf bei `PURCHASE.ORDER` fehlendes Lese-/Schreibrecht für Einkaufsrechnungskopf. Die eigene Vorprüfung hatte direkte `WritePermission` auf gebuchten Standardtabellen verlangt. Das ist für reguläre indirekte Standardbuchungsrechte zu streng. Der gemeinsame Environment Guard prüft jetzt Leserecht und die effektiven zugewiesenen Insertrechte **Yes oder Indirect**, bei Rechnungsausgleich zusätzlich Modifyrechte. Ausführungsrechte für die jeweiligen Standardbuchungscodeunits werden geprüft. Einkauf, Verkauf und Zahlungsdienst nutzen denselben Vertrag. Direkte Rechte bleiben für die selbst angelegten ungebuchten Belege erforderlich. BCSF ADMIN erteilt keine neuen Standardpostenrechte; tatsächliche Standardbuchungen prüfen ihre Rechte weiterhin selbst.

Nach manueller Bereitstellung des korrigierten Pakets zuerst den fehlgeschlagenen **aktuellen Hintergrundauftrag** öffnen und dessen konkreten Zustand prüfen. Ist nur die atomare Vorbereitung gescheitert und noch kein Ergebnislauf gebunden, kann derselbe Vorbereitungsjob erneut bereitgestellt werden. Bei vorhandenem Ergebnislauf die bestehende Lauf-/Batchdiagnose nutzen; keine unklare Buchung wiederholen und keine Firma zurücksetzen. Der Screenshot belegt die Fehlermeldung, keine erfolgreiche native Buchung nach dieser Korrektur.

### Dashboard und Vorlagen

Lesende Aktualisierung alle **2 Sekunden**, sofern sichtbar und keine Anfrage läuft; langsame Aufrufe überlappen nicht. Eine Benutzerauswahl wird nach dem laufenden Poll verarbeitet. Inkrementelle DOM-Aktualisierung erhält Kacheln, Fokus, Scrollposition, Filter, Reiter und offene Detailbereiche; kein Ladeoverlay beim Poll. Bei offener Auswahl pausiert Polling, bei ausgeblendeter Seite ebenfalls. Die tatsächliche Aktualisierungsrate hängt von der Serverantwort ab. Abruffehler werden im bestehenden Rückmeldungsbereich angezeigt. Einkaufsrechnungen/-eingänge, Kreditoren-/Bankposten und Debitoren-/Kreditorenzahlungen haben Herkunft und berechtigungsgeprüfte Standardlistenrouten.

Drei explizit ladbare Großhandelsreferenzen: bisherige ungebuchte Vorlage bleibt erhalten, hinzu kommen gebuchte und Zahlungsreferenz. Neue Starter besitzen keine automatische Buchungsfreigabe. Eigene Namen/Werte und entfernte/archivierte Starter bleiben geschützt. Der Normalstart verwendet weiterhin das interne Paket, ohne technische Vorlagenwahl. Querschnittspflicht in AGENTS.md ergänzt.

XERJ läuft wieder lokal und wurde mit **bcsf-docs** genutzt; der ältere Index wird gegen aktuelle Quellen geprüft. Kein Code-Corpus verfügbar, keine BC-Laufzeitintegration.

[Ausgeführte lokale Prüfungen und offene native Abnahme](TESTS.md#sf-020sf-022--gebuchter-großhandel-und-zahlungsausgleich).


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

## Fortsetzung SF-045 / ausdrücklich beauftragter Einkauf und Folgeprozesse

Nutzerauftrag: Dashboard alle zwei Sekunden im Hintergrund ohne Flackern aktualisieren; den bestätigten Workflow um gebuchte Belege und Zahlungen/Ausgleich für Einkaufs- und Verkaufsrechnungen ergänzen; Einkaufsmodul ausbauen. Umsetzung als gemeinsamer Folgeumfang SF-045 mit ausdrücklich ausgewähltem SF-020-/SF-022-Fachumfang, keine anderen Tickets automatisch bearbeiten.

Vor Änderungen: betroffen sind Dashboardressourcen/Part, vorhandener Assistent/Request, Wholesale-Paket, Einkaufs-/Verkaufsverträge, Standardbuchung und Zahlungsdienst, Herkunft/Abnahme, Starter, vorhandener isolierter Testhost und DE/EN-Übersetzungen. Risiken sind UI-Fokus/Scrollzustand bei Polling, überlappende Serveraufrufe, Bestandsdeckung vor Verkauf, Buchungs-/Ausgleichs-Commits, doppelte Ausführung und historische Snapshots. Polling bleibt rein lesend und serialisiert; DOM wird inkrementell geändert. Keine automatische Buchungsfreigabe durch Aktualisierung. Gebuchte Mengen und Folgeprozesse benötigen ausdrückliche Zustimmung. Standard-Posting/-Ausgleich unter CommitBehavior::Error, keine direkten Ledger-Inserts, keine unsicheren Retries. Neue Request-/Vertragsversionen dürfen Altstand nicht umdeuten. Testweg: Compiler/Analyzer, reale vorhandene Microsoft-Quellen, Browserregression mit kontrollierten Timern/DOM-Identität, bestehende Verträge und zusätzliche Methoden im getrennten Testhost; native Sandbox-/Posting-/Rechteabnahme separat offen.

XERJ war zu Beginn nicht erreichbar und wurde auf Nutzerauftrag wieder lokal gestartet. Suche in bcsf-docs erfolgreich; Code-Corpus weiterhin nicht verfügbar. Aktuelle lokale Quellen sind maßgeblich.


Herkunftsregistry: Bank Account Ledger Entry, Detailed Cust. Ledg. Entry und Detailed Vendor Ledg. Entry sind explizit als Standardergebnisse zugelassen. Die bestehende eindeutige physische Ergebnisidentität und Batchbesitzprüfung gelten unverändert.


## 1.0.7.1 – Dashboardnachbesserung

[Darstellung, Navigation und neue lesende Mappingliste](DASHBOARD_DATA_STOCK.md#implementierter-stand-1071). Vorlagen, Generatoren, Mandanteneinrichtung und historische Läufe bleiben unverändert. Der Nutzer bestätigt einen erfolgreichen Datenlauf und liefert Bilder mittlerer gebuchter Mengen; vollständige native Zahlung-/Rechte-/Upgradeabnahme daraus nicht ableitbar. Prozessstufe jetzt im Kopf eindeutig mit/ohne Zahlungen. **Zur Prüfung**.

## SF-022 – Modulauswahl: Plan vor Änderung (21.11.2026)

Bestätigter Teilauftrag: zuerst Modulauswahl, vorhandene Zahlungen/vollständigen Ausgleich beibehalten. Keine Teilzahlungen, Gutschriften oder Retouren in diesem Schritt. Bestehender Unternehmensassistent: Kontenplan → Branche → Module → Größe → Prozessstufe → Zusammenfassung/Start. Großhandel bleibt einziges ausführbares Paket. Verkauf, Einkauf, Artikel und gemeinsame Finanzbasis sind erforderlich und vorgewählt. Zusätzliche vorhandene Modularten können ausdrücklich als **nur geplant, keine Generierung** vorgemerkt werden. Sie erhalten keine Ziele, Generatoren oder Erfolgsmengen.

Betroffene Dateien: vorhandene Setupkarte/-tabelle, Wholesale Profile, Company Initialization, Frozen Modules (temporäre Ansicht wiederverwenden), Dashboard Data/JS, bestehender isolierter Testhost und Übersetzungen. Ein additives optionales Requestfeld hält die kanonische Auswahl bis zur Hintergrundvorbereitung fest; bestehende Modulzeilen und Snapshot-Schema 1 transportieren sie anschließend. Kein neues AL-Objekt, keine neue Tabelle/Seite, keine Standardrechte oder Finanzinitialisierung. Historische Requests mit leerem Feld verwenden das unveränderte Basispaket.

Risiken: Auswahlverlust beim Zurückgehen, unzulässige Requests auch ohne Trigger, irreführende Planungsmodule, historische Captures. Validierung vor Einplanung und erneut im Hintergrund; Requestfeld nach Einplanung unveränderlich. Testweg: vorhandener Compiler/CodeCop/UICop, separate AL-Testmethoden für Basisauswahl/Erweiterung/ungültige Auswahl/Template-Snapshot, bestehende Quellverträge, Übersetzungen und Dashboardregression. Native DE/EN-Navigation, Tastatur, Queue nach Browserende und additives Upgrade bleiben separat zu prüfen.

Querschnitt: reale Dashboardbestände/Drilldowns unverändert; Planungsauswahl im Firmenstatus sichtbar. Bestehende Stämme/Einrichtung und Standardbuchung bleiben unverändert. Referenzstarter gegen Basispaket/Quoten prüfen; keine neue ausführbare Vorlage für unfertige Module vortäuschen.

## SF-022 – Modulauswahl 1.0.7.2

Umgesetzt im bestehenden Ablauf, keine neue Seite/Tabelle/Codeunit. Die vorhandene temporäre `BCSF Frozen Modules`-Unterseite erhält einen internen Auswahlmodus; beim Laden eines historischen Laufs bleiben ihre Felder nicht editierbar. Im Modulschritt zeigt sie alle zwölf vorhandenen Modularten. Verkauf, Einkauf, Artikel und Finanzbasis sind vorgewählt und gesperrt, weil das verbundene Großhandelspaket diese Basis verwendet. Lager, Fertigung, Montage, Projekte, Service, Anlagen, CRM und Planung sind optional und sichtbar **nur Planung; keine Datenerzeugung**. Die Branchenwahl bleibt beim einzigen unterstützten Großhandelspaket.

`Wholesale Profile` definiert die erforderlichen Module und prüft die kanonische optionale Auswahl gegen vorhandene Enumwerte/Modulcodes. Ungültige, doppelte oder als Zusatz übergebene Pflichtmodule werden abgewiesen. Der Request speichert sie im additiven Setupfeld 27 `Industry Additional Modules` (Text[250]); leere Altrequests bedeuten das Basispaket. Der Start prüft vor dem Queuejob, der bestehende Modify-Subscriber schützt das Feld auch ohne Tabellentrigger, der gebundene Hintergrundjob prüft vor Foundationänderungen erneut. Alte Start-/Template-Signaturen bleiben erhalten.

Die interne Vorlage enthält die gewählten vorhandenen Modulzeilen. Nur die bisherigen drei Stammdaten-/vier Belegentitäten erhalten Ziele. Zusätzliche Module erhalten keine Ziele, keinen Generator, keine Buchung oder künstliche Erfolgsmengen. Der bestehende Snapshot übernimmt die Auswahl ohne Schemawechsel; spätere Vorlagenänderungen verändern ihn nicht. Die Queue plant weiterhin ausschließlich reale Entitätsziele. Zusammenfassung und Firmenstatus im Dashboard nennen Basis und Planungszusätze; reale Bestandskacheln und Drilldowns bleiben quellengebunden.

**Start-/Testvorlagen geprüft und ergänzt:** Die bisherigen drei Großhandelsstarter nutzen bei Neuanlage dieselbe aktuelle Paketlogik. Ihre Mengen und Mischquoten bleiben erhalten (Angebote ungebucht, Teilquoten nur Aufträge); Buchungsfreigaben bleiben aus. Der vierte feste Referenzstarter `{B55C4500-AB51-4045-9C00-000000000004}`, **Großhandel - Lager und CRM geplant**, enthält 20 Debitoren, 5 Kreditoren, 40 Artikel, 15 Einkaufsbestellungen, 5 Angebote, 12 Aufträge und 3 Rechnungen, sämtlich ungebuchte Belege. Lager und CRM sind ausgewählt, aber ausdrücklich ohne Ziele. Er wird nur bei ausdrücklichem Laden der Starter und nur ohne bestehende Vorlage/Entfernt-Vermerk angelegt. Eigene Namen/Werte, Archive, entfernte Starter und historische Captures werden nicht umgeschrieben. Keine zusätzliche technische Vorlagenwahl im Normalweg.

Betroffene Querschnitte: **Workflow** um einen Schritt ergänzt; **Dashboard** zeigt die Auswahl ohne fiktive Ergebnisse; **Stammdaten/Einrichtung** verwenden unverändert die bestehenden Voraussetzungen und Foundation; **Übersetzungen** vollständig DE/EN samt deutschen Regionen. App 1.0.7.2, separate Test-App 1.3.0.2; weiterhin 140 Main-Objekte, Runtime 17, Application 28.0, unveränderte Identität/IDs/Dependencies. Nur ein additives Requestfeld; kein ForceSync, keine historischen Datenänderungen. Standardbuchungs-/Zahlungsumfang unverändert.

**Native Abnahme, noch nicht ausgeführt:**

1. In DE und EN Einrichtung öffnen: Schritte Kontenplan/Branche/Module/Größe/Prozess/Zusammenfassung. Alle zwölf Modularten sichtbar, vier Pflichtmodule vorgewählt/gesperrt, Zusätze abwählbar. Lager/CRM markieren, vor/zurück navigieren, Werte und Zusammenfassung prüfen. Abbrechen erzeugt keinen Firmenrequest oder Standarddaten.
2. Kleinen ungebuchten Lauf mit Lager/CRM starten, Browser schließen. Genau ein Hintergrundstart; bestehende sieben Entitätsziele und tatsächliche Mengen/Standardlisten wie oben, keine Lager-/CRM-Generierung. Firmenstatus und Capture enthalten dieselbe Modulauswahl. Erneut ohne Zusätze starten, sobald vorheriger Lauf abgeschlossen; keine alten Markierungen übernehmen.
3. Neue Referenzstarter ausdrücklich laden; neuen Modulstarter sowie Schutz eigener Namen/Werte/Archive/Entfernt-Vermerke und wiederholtes Laden prüfen. Gebuchte/Zahlungsstarter behalten vorhandene Mischquoten und gesonderte Zustimmung.
4. Historischen Lauf öffnen: temporäre Capture-Unterseite unveränderlich, keine nachträglichen Module/Targets. Additives Upgrade mit historischen Requests/Läufen ohne ForceSync prüfen. Fehlende Rechte/Queuefehler und unveränderlichen Request auch bei Modify(false) nachweisen.
5. Vorhandene Zahlungsreferenz weiter mit 23 vollständig ausgeglichenen Rechnungen und entsprechenden Bank-/Partnerposten abnehmen; keine neue Teilzahlungs-/Gutschrift-/Retourenfunktion erwarten.

[Ausgeführte lokale Prüfungen](TESTS.md#sf-022--modulauswahl-1072). Status **Zur Prüfung**, keine native oder menschliche Abnahme und kein Deployment.

## SF-022 – Datumszeitraum: Plan vor Änderung (21.11.2026)

Ausdrücklicher Nachauftrag: im bestehenden Initialisierungsworkflow ein Startdatum validieren und fachliche Daten/Belege sowie ausgewählte Standardbuchungen zufällig ab diesem Datum bis einschließlich gestern verteilen. Zugeordnet zum laufenden SF-022-Nachauftrag, keine weiteren Tickets. Technische SystemCreatedAt-/Audit-/Queuezeitpunkte bleiben tatsächliche Erstellzeitpunkte; Stammdaten ohne fachliches Anlagedatumsfeld erhalten kein erfundenes Rückdatierungsfeld.

Betroffen: bestehende Setupkarte/-request, Wholesale Profile/Starter, Snapshot Writer/Contract JSON, Process Coordinator, Verkaufs-Bestandsprüfung, Payment Processor, Dashboard und Übersetzungen sowie vorhandener Testhost. Start-/Enddatum beim Start einfrieren; Start nicht leer und spätestens gestern, Ende gestern. Hintergrund darf bei Tageswechsel die Grenze nicht neu berechnen. Additives optionales Enddatumsfeld, historische Requests/Snapshots behalten bisherige Semantik über fehlende Datumsregelversion. Neue Captures erhalten einen optionalen versionierten Datumsvertrag. Keine neue Seite/Tabelle/Generator, kein ForceSync.

Risiken/Testweg: Einkaufseingänge müssen artikelbezogen spätestens zu den davon abhängigen Verkaufsbuchungen vorhanden sein. Neue deterministische Einkaufsdaten deshalb bis zum frühesten geplanten Verkauf dieses Artikels streuen; Rechnungs-/Lieferdaten zusammenhalten. Zahlungen zwischen Rechnung und Periodenende streuen. Bestands-Gesamtprüfung nicht weiter am Periodenanfang verlangen, Einzelfallprüfung zum tatsächlichen Verkaufsdatum erhalten. BC-Buchungsperioden/Benutzerrechte nicht erweitern; Standardvalidierung darf begründet blockieren. Bestehende Seed-Engine, Quoten, Standardbuchung und Checkpoints wiederverwenden. Nachweise: Compiler/Analyzer, bestehende Vertrags-/Dashboardprüfungen, Datumsspanne/Grenzen/Reproduzierbarkeit/Einkauf-vor-Verkauf/Zahlung-nach-Rechnung im bestehenden isolierten Testhost; native Standardbuchung, Zahlungsrabatt, Nummernserien und DE/EN/Upgrade separat offen.

## SF-022 – Datumszeitraum 1.0.7.3

Der bestehende Schritt **Daten und Prozesse** enthält **Daten erzeugen ab** (editierbar) und **Daten erzeugen bis** (gestern, nicht editierbar). Vorschlag: ein Jahr vor dem tatsächlichen heutigen Datum bis gestern. Leeres Startdatum, heute, Zukunft und umgekehrte Grenzen werden abgewiesen, auch bei direktem Startaufruf. Nach einem Tageswechsel vor dem Start muss der Assistent zur Aktualisierung erneut geöffnet werden. Das BC-Arbeitsdatum bestimmt die Grenzen nicht mehr.

Setupfeld 25 `Industry Date` hält jetzt das gewählte Startdatum neuer Requests; additives optionales Feld 28 `Industry Ending Date` hält das angezeigte Ende. Beide sind nach Einplanung über den bestehenden Subscriber auch bei Modify(false) geschützt. Der Hintergrundjob übernimmt die gespeicherten Grenzen und berechnet sie nicht neu. Historische Requests ohne Ende bleiben beim bisherigen Einzeltermin. Die normale interne Vorlage erhält Anfang/Ende; der Snapshot schreibt sie in die bestehenden Felder und ergänzt optional `datePolicyVersion: 1` bei neuen Captures. Fehlender Marker bedeutet unveränderte Legacy-Regel (gebuchte Beschaffung am Anfang, Zahlung am Rechnungsdatum); unbekannte Versionen stoppen. Alte Captures/Läufe werden nicht geändert.

**Ausführung:** Verkaufsangebote, Aufträge und Rechnungen sowie ungebuchte Einkaufsbestellungen nutzen die bestehende deterministische Seed-Verteilung im Zeitraum. Für gebuchte Beschaffung wird je Artikel der früheste davon abhängige geplante gebuchte Verkauf ermittelt; das Eingangs-/Rechnungsdatum wird zwischen Start und diesem Datum gezogen, ohne Verkaufsverbrauch bis zum Eingang zu erlauben. Ohne abhängigen gebuchten Verkauf steht der gesamte Zeitraum zur Verfügung. Gleicher Tag für Eingang und Verkauf ist zulässig; die bestehende Queue führt den Eingang zuerst aus. Die Gesamtbestandsprüfung nutzt bei der neuen Regel das Periodenende, die einzelne Verkaufsbuchung prüft weiterhin Bestand zum tatsächlichen Verkaufsdatum. Mengen-/Mischquoten und Standardbuchung bleiben erhalten.

Debitoren-/Kreditorenzahlungen werden deterministisch zwischen dem jeweiligen Rechnungsbuchungsdatum und dem gespeicherten Periodenende gebucht/ausgeglichen. Zahlungs-Belegdatum folgt dem gezogenen Buchungsdatum. Ausgabevalidierung prüft tatsächliche Beleg-/Buchungsdaten bei neuen Captures zusätzlich an ungebuchten/teilgebuchten Einkaufs-/Verkaufsbelegen, gebuchten Rechnungen und Wareneingängen sowie Partnerzahlungen. Ausgleich bleibt vollständig; keine Teilzahlungen, Gutschriften oder Retouren hinzugefügt.

**Datumsgrenzen und Stammdaten:** Fachliche Beleg-/Auftrags-/Buchungsdaten werden verteilt. BC-SystemCreatedAt, Herkunftsregistrierung, Queue-/Laufzeiten und technische Anlagen von Stammdaten/Einrichtung bleiben tatsächliche Zeitpunkte. Debitor, Kreditor und Artikel besitzen in diesem Generatorpfad kein künstlich rückdatiertes fachliches Anlagedatumsfeld. Die bestehende synthetische Datumsableitung bleibt unverändert verfügbar. Fälligkeiten und sonstige Standardfolgedaten ergeben sich aus den BC-Bedingungen und können nach dem Periodenende liegen; es erfolgen keine Buchungen außerhalb des erfassten Fensters. Erlaubte BC-/Benutzerbuchungsperioden, Nummernserien und bestehende Einrichtung werden nicht erweitert oder überschrieben; erforderlichenfalls stoppt Standardvalidierung.

**Querschnitt/Vorlagen:** Zusammenfassung und Dashboard-Firmenstatus zeigen denselben eingefrorenen Zeitraum. Alle vier neu angelegten Großhandelsreferenzstarter verwenden jetzt den Jahreszeitraum bis gestern; ihre vorhandenen Quoten (Angebote ungebucht, Teilquoten nur Aufträge), fehlende automatische Buchungsfreigabe und optionalen Planungsmarkierungen bleiben erhalten. Vorhandene eigene/archivierte/entfernte Starter und gespeicherte Läufe werden nicht nachdatiert. Im Expertenzugang behalten bestehende Vorlagen ihren bewusst gespeicherten Zeitraum; für neue historische Prüfungen deren Kopie verwenden oder den Unternehmensassistenten starten. Einrichtung und Stammdatenvoraussetzungen werden weiter vor Belegen geprüft. Sämtliche neuen/geänderten UI-Texte sind DE/EN einschließlich deutscher Regionen gepflegt.

Geänderte AL-Dateien gegenüber 1.0.7.2: Core `BCSFFactorySetupCard`, `BCSFFactorySetup`, `BCSFContractJSON`; IndustryProfiles `BCSFWholesaleProfile`, `BCSFStarterCatalog`; Monitoring `BCSFCompanyInitialization`, `BCSFDashboardData`; ScenarioManagement `BCSFSnapshotWriter`; ProcessEngine `BCSFProcessCoordinator`; Sales `BCSFSalesSetup`, `BCSFSalesGenerator`; Purchasing `BCSFPurchaseGenerator`; Finance `BCSFPaymentProcessor`. Dazu Dashboard-JS/Clienttest, bestehender isolierter AL-Testhost, Manifestversionen, Übersetzungen und Dokumentation. Weiterhin 140 Main-AL-Objekte; keine neue Tabelle/Seite/Dependency, App-ID/Runtime/ID-Bereich unverändert. App **1.0.7.3**, Test-App **1.3.0.3**, ein additives optionales Enddatumsfeld, kein ForceSync.

**Native Abnahme offen:**

1. DE/EN: Startdatum leer/heute/zukünftig ablehnen, gestern als Einzeltag und einen langen Zeitraum akzeptieren; absichtlich abweichendes BC-Arbeitsdatum beeinflusst die Grenze nicht. Zusammenfassung zeigt das gewählte Datum. Rücknavigation erhält Datum/Module; bei Tageswechsel vor Start neu öffnen.
2. Neue Sandbox: klein/ungebucht, z. B. 01.01.2026–20.11.2026 beim Start am 21.11.2026. Angebote/Bestellungen/Aufträge/Rechnungen haben verteilte fachliche Daten im Fenster; keine Posten. Technische Anlagezeiten sind tatsächlich aktuell.
3. Gebuchter/Zahlungslauf: Wareneingänge spätestens vor artikelbezogenem Verbrauch, tatsächliche Rechnungs-/Sach-/MwSt.-/Artikel-/Wertposten und Zahlungen innerhalb der Grenzen. Zahlungen nicht vor Rechnung, Restbeträge 0. Alle Mischquoten und ungebuchten Reste erhalten. Zahlungsrabatte, Benutzerbuchungsperioden, geschlossene Lagerperioden und unzulässige Nummernserien gezielt prüfen; keine stillschweigende Erweiterung der Einrichtung.
4. Klein/Mittel/Groß, anderer Seed, Einzeltag, Monats-/Jahreswechsel und Schaltjahr prüfen. Capture/Batchgrenzen und Reihenfolge ändern die Datumswerte nicht. Hintergrundjob erst am nächsten Tag ausführen: gespeichertes Ende bleibt unverändert.
5. Additives Upgrade mit älterem Einzeltermin-Request und laufendem Capture ohne Marker prüfen; bisherige Datumswerte/Ergebnisse erhalten. Änderungen an beiden Requestgrenzen mit Modify(false) sperren. Eigene/entfernte/archivierte Starter unverändert; neue Starter nutzen den Zeitraum und vorhandene Mischquoten.

[Lokale Nachweise](TESTS.md#sf-022--datumszeitraum-1073). **Zur Prüfung**, keine native oder menschliche Abnahme, kein Deployment.
