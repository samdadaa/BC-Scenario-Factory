# Testanleitung – Vorlage wählen, starten, Ergebnis öffnen

## 1.0.7.0 – Einkauf, Buchung, Zahlung und Berechtigungsfehler

**Vorbereitet, nicht nativ ausgeführt.** Paket zuerst manuell nach bestehender Freigabe bereitstellen. [Lokales Prüfprotokoll und Prüfsumme](../TESTS.md#sf-020sf-022--gebuchter-großhandel-und-zahlungsausgleich). Nicht versehentlich den während der Entwicklung erzeugten älteren 1.0.7.0-Build verwenden: aktuelles Paket `artifacts/BCScenarioFactory-1.0.7.0-Purchase-Payments-Permissions.app`.

1. Gemeldeten Fehler prüfen: **Aktueller Hintergrundauftrag** öffnen. Nach Update kann bei fehlender Ergebnislauf-ID die gescheiterte atomare Vorbereitung mit demselben Queuejob erneut bereitgestellt werden. Bei bereits gebundenem Ergebnislauf dessen Batchdiagnose verwenden. Kein Datenreset, keine neue Initialisierung als Fehlerbehelf, keine Wiederholung einer unklaren Buchung.
2. Frische isolierte SKR03- und SKR04-Firmen getrennt prüfen: Großhandel → Klein → gebuchte Bewegungen, Zustimmung zunächst aus. Start muss gesperrt sein. Mit Zustimmung einmal starten, Browser schließen, nach Wiederöffnung abgeschlossenen Lauf/Qualität prüfen. Referenzmengen 20 Debitoren, 5 Kreditoren, 40 Artikel, 15 Einkaufsziele, 5 Angebote, 12 Verkaufsauftragsziele, 3 direkte Rechnungsziele.
3. Gebuchtes Ergebnis: 12 Einkaufsrechnungen und 12 Eingänge, 6 verbleibende Bestellungen; 9 Auftragsrechnungen, 6 verbleibende Verkaufsaufträge; 2 direkte gebuchte Rechnungen, 1 ungebuchte Rechnung; 5 ungebuchte Angebote. Je 3 teilgebuchte Aufträge auf beiden Seiten mit echter halber Menge. Lieferant/Artikel/Herkunft desselben Laufs, Bestand vor Verkauf und Beträge/MwSt. kontrollieren. Debitoren-/Kreditorenrechnungen in dieser Stufe offen.
4. Separat denselben kleinen Referenzfall mit **Zahlungen und Ausgleich** ausführen. Erwartung: 12 Kreditorenzahlungen + 11 Debitorenzahlungen, 23 Bankposten auf BCSF-PAY, alle 23 gebuchten Rechnungen und deren Zahlungen geschlossen/Restbetrag 0. Ungebuchte Reste unverändert. Rechnungsdatum = Zahlungsbuchungsdatum. Keine Bankübermittlung/externen Kennungen.
5. Sach-/MwSt.-/Artikel-/Wertposten und Lagerwert, Bankbewegungen, Bilanz/GuV/BWA gegen die tatsächlichen Belegzeilen abstimmen. Automatische Lagerwertbuchung muss für neue Buchungsläufe aktiv sein. Bestehende Firma mit Posten und deaktivierter automatischer Lagerwertbuchung muss mit Konflikt stoppen, ohne die Kostenpolitik zu ändern.
6. Bestehende Test-App 1.3.0.0 bereitstellen und die fünf neuen Methoden ausführen; reine Methoden benötigen keinen neuen Datensatz, Referenz-/Replaymethoden den dokumentierten abgeschlossenen Lauf. Zusätzlich fehlende Zahlungseinrichtung, manipulierte Bankzuordnung und fehlende Approval prüfen. Fehlende Standardbuchungsrechte bleiben blockiert; reguläre indirekte Rechte dürfen nicht schon wegen fehlender direkter WritePermission abgewiesen werden. Mit tatsächlichem Hintergrundnutzer prüfen.
7. Fehler nach Buchung/vor Checkpoint und nach bestätigtem Batch gezielt prüfen: entweder vollständiger Rollback oder gesperrte unklare Arbeit; keine Doppelrechnung/-zahlung beim Replay. Tatsächliche Job-/Batch-/Run-IDs und Ergebnisse ohne sensible Daten protokollieren.
8. Dashboard mindestens mehrere Pollzyklen beobachten: Änderungen erscheinen ohne Flackern, Fokus/Scroll/Filter/Reiter/Details bleiben erhalten; langsame Serverantwort, ausgeblendeter Tab und Abruffehler prüfen. Zahlungs-/Eingangs-/Rechnungskacheln öffnen genau die angezeigte berechtigte Menge. Große Provenienzmengen bleiben gesonderte Grenze.
9. Nach abgeschlossenem Lauf neuen Datensatz über **Unternehmensdaten erzeugen** anlegen: gleiche Einrichtung, keine erneute Kontenplanwahl, alte Läufe/Starter/eigene Namen/Entfernungsvermerke erhalten. Upgrade ohne ForceSync; alte Snapshotverträge nicht umschreiben. Drei Referenzstarter nur explizit laden, keine automatische Buchungsfreigabe beim Laden/Kopieren/Import.

Die folgenden Abschnitte dokumentieren ältere Abnahmestände.


## SF-045 – zuerst den frischen Großhandelsfall prüfen

**Alle folgenden BC-Prüfungen sind vorbereitet, nicht ausgeführt.** Nur eine neue isolierte SaaS-Sandbox-Firma verwenden. Eine Installation/Veröffentlichung ist separat freizugeben.

1. Factory-Dashboard öffnen. Ohne Initialisierung/Anforderung erscheint die bestehende Einrichtung als Assistent. Abbrechen darf keine Standarddaten und keinen Job anlegen.
2. SKR04 → Großhandel → Klein → Mit ungebuchten Belegen wählen. Zusammenfassung: 20 Debitoren, 5 Kreditoren, 40 Artikel, 15 Einkaufsbestellungen, 5 Verkaufsangebote, 12 Verkaufsaufträge, 3 Verkaufsrechnungen. Keine Buchungen. Vorhandene Katalog-Kinddaten kommen zusätzlich hinzu und sind keine führenden Ziele.
3. **Unternehmen einrichten und Daten erzeugen** genau einmal wählen, Browser schließen. Im Standard-Queuejob müssen zuerst Foundation/Snapshot/Plan und anschließend die vorhandenen Batches laufen. Nach Wiederöffnen aktualisieren; tatsächlichen Fortschritt und ursprünglichen Fehler bei Abbruch ansehen.
4. Nach Qualitätsabschluss dieselben Mengen über die Kacheln und gefilterten BC-Listen prüfen. An jeder Einkaufszeile Lieferant/Artikelbezugsquelle und Herkunft aus demselben Lauf, Einheiten, Preise und ungebuchte Mengen kontrollieren. Keine erzeugten Posten. Bilanz/GuV/BWA existieren; ungebucht sind daraus keine Salden zu erwarten.
5. In der separaten Test-App die fünf neuen SF-045-Testmethoden ausführen; die beiden Referenzprüfungen brauchen den soeben abgeschlossenen kleinen Lauf. BC-Version, Firma, Rolle, App-/Paketstand, Seed, Datum, Job-/Run-ID sowie beobachtetes Ergebnis ohne sensible Daten protokollieren.
6. In neuer Firma mit SKR03 wiederholen. Stammdatenstufe erzeugt ausschließlich 20/5/40. Mittel/Groß vor Start anhand Faktor 10/100 kontrollieren; bestehende Dashboard-Herkunftsfiltergrenzen für große Mengen sind offen.
7. Doppelstart, erneute Initialisierung, fehlende Rechte, widersprüchliche vorhandene Einrichtung, Standardjobfehler vor Datenlauf und Fehler nach abgeschlossenem Batch prüfen. Keine Duplikate und keine automatische Wiederholung ungeklärter Arbeit. Fehlerbehebung erfolgt über die bestehenden Queue-/Batchdiagnosen.
8. Vorhandene gültige Firma und Kopie eines Altstands separat prüfen: kein Überschreiben, eigene/archivierte/entfernte Starter und historische Snapshots/Jobs erhalten, normale Schemasynchronisierung ohne ForceSync. Keine Umstellung des gewählten Kontenplans.

[Umsetzung und offene Abnahme](../INDUSTRY_INITIALIZATION.md), [lokale Nachweise](../TESTS.md#sf-045--branchengesteuerte-unternehmensinitialisierung). Frühere Anleitungen unten sind historische Wege bzw. Expertenprüfungen.

Stand: 19.11.2026, Quellversion **1.0.4.0**, SF-042 **Zur Prüfung**. Die folgenden BC-Fälle sind noch nicht ausgeführt. [Aktueller Soll-Ist-Abgleich und lokale Prüfungen](../TESTS.md#sf-042--soll-ist-prüfung-des-partnerpfads). Keine ältere ZIP zurückkopieren.

## Kurzeinstieg

**Einmal:** Einrichtung → Mandant initialisieren → SKR03/SKR04 oder vorhandene passende Einrichtung übernehmen. **Danach:** Vorlagen → ausführbare Partnervorlage → Vorlage ausführen → Status ansehen → Daten öffnen. Der Vorlagenstart verlangt keine erneute Kontenplanwahl. Nur Debitoren/Kreditoren sind derzeit ausführbar. Diagnose wird für den normalen Start nicht benötigt.

## Vorbereitung und Paketstand

1. Eine ausdrücklich freigegebene, isolierte **Playground-Testfirma** ohne Sachposten verwenden. Die App erstellt keine Firma. Keine produktiven Mandanten, kein ForceSync und keine vorhandenen Laufdaten löschen.
2. Symbole gegen die tatsächlich verwendete Sandbox prüfen. Vollständiger AL-Build → `python3 Translations/sync_starter_translations.py` → `python3 scripts/check_translations.py` → `python3 scripts/build_dashboard_translations.py` → nochmals vollständiger Build. Die Datei aus dem letzten Build verwenden, kein RAD-Publish als Übersetzungsnachweis.
3. Nur dieses vollständige Paket nach entsprechender Deploymentfreigabe installieren/aktualisieren. Version, App-ID und Paketprüfsumme mit dem installierten Stand abgleichen. Installation/Upgrade allein schreibt keine Vorlagen oder BC-Standardeinrichtung.
4. `BCSF ADMIN` und passende Standardrechte für Einrichtung, Debitoren/Kreditoren, Nummernserien und Aufgabenwarteschlange sind erforderlich. Bei aktivierter Standard-Kontaktintegration zusätzlich Kontakt-/Beziehungsrechte. Rechte des Hintergrundnutzers separat prüfen.
5. **Scenario-Factory-Einrichtung → Mandant initialisieren**: SKR03 oder SKR04 für eine frische Firma wählen; alternativ passende vorhandene Einrichtung übernehmen. Initialisierung ausdrücklich bestätigen. Sie bereitet die gemeinsame Basis vor, lädt Startervorlagen und erlaubt Generierung; neue Firmen erhalten keine Buchungsfreigabe. Keine Sachkonten oder Buchungsgruppen einzeln als Behelf anlegen. Bei einem Blocker den konkreten Befund klären. Abbruch, Wiederholung, vorhandene Firma und Altstand gemäß [SF-043-Abnahme](../COMPANY_INITIALIZATION.md#sandbox-abnahme) prüfen.

**Pro BC-Fall protokollieren:** tatsächliche BC-Version/Lokalisierung, freigegebene Umgebung/Testfirma, wirksame Rolle, installierte App-Version/Paket, Vorlage/Revision, Seed, Zeitraum, Datensprache, Zielmengen/Paketgröße, Lauf-/Paketbezug, erwartetes und beobachtetes Ergebnis, Laufzeit und Abweichungen. Nur synthetische Nachweise, keine Geheimnisse oder realen personenbezogenen Daten. Bis zur Ausführung bleibt das Ergebnis **Zu prüfen**.

## T01 – Startvorlagen laden

Nach Initialisierung **Scenario-Factory-Szenarien → Startvorlagen laden** erneut ausführen. In einer frischen, unveränderten Firma 56 Vorlagen erwarten, davon 32 Partnerfälle und 24 ausdrücklich als **Nur Planung** gekennzeichnete Fälle. Keine Duplikate und keine zurückgesetzten Namen/Mengen. Kein Lauf oder Partner allein durch Laden.

## T02 – Funktionstest 5/5

1. In deutscher Sitzung **Allgemeines Unternehmen – Funktionstest: Debitoren und Kreditoren** auswählen. Auf der Karte Debitoren = 5, Kreditoren = 5, Paketgröße = 5 prüfen. Nur positive Partnerziele, Modus Einrichtung/Stammdaten.
2. **Vorlage ausführen** wählen. Bei bereits initialisierter Firma kein Finanz-/Vorschau- oder zusätzlicher Startdialog. Fehlende Basis über die einmalige Mandanteneinrichtung klären. Bestehende Standardeinrichtung wird nicht still ersetzt. Keine Buchungen freigeben.
3. Auf der automatisch geöffneten Laufkarte den aktuellen Ausführungsstatus und **Fortschritt ansehen** verwenden. Plan, Queue und Checkpoints nicht manuell bedienen. Der Browser muss für den Hintergrundlauf nicht offen bleiben. Die Seite bei Bedarf aktualisieren.
4. Erwartung nach tatsächlichem Queueabschluss: **2 von 2** Paketen bestätigt, **5 Debitoren**, **5 Kreditoren**, Abschlussprüfung **Bestanden**, Status **Abgeschlossen**. Kein Sachposten.
5. Im Dashboard **Läufe** diesen Lauf wählen. Die Debitoren-/Kreditorenkacheln öffnen genau diese 5/5 Partner in den BC-Standardlisten. Liefer-/Bestelladressen separat öffnen und Elternbezug prüfen. **Ergebnisse öffnen** führt zusätzlich zur Herkunftsliste und zum registrierten Standarddatensatz. Unter **Daten** unterscheiden sich **Gesamter Mandant** und der auf diesen Lauf gefilterte erzeugte Bestand. Keine ungefilterte Liste als Laufergebnis akzeptieren.

## T03 – Mehrpaketfall 12/7

Die ausführbare Handels-Demovorlage auf 12/7 und Paketgröße 5 einstellen und ebenso starten. Nach erfolgreichem Start Lauf-ID notieren und die interaktive Sitzung schließen. Später den Laufmonitor erneut öffnen. Erwartung: Debitorenpakete 5+5+2, Kreditorenpakete 5+2; **5 von 5**, genau 19 führende Herkunftseinträge, Abschlussprüfung bestanden. Damit wird die automatische Folgeplanung ohne offene Sitzung geprüft. Zusätzliche Adressen und Standardkontakte zählen nicht zu den führenden Partnern. T02 und T03 je in frischen SKR03-/SKR04-Firmen nachweisen; bereits vorhandene Daten separat zählen.

## T04 – Negativer Setupfall und ursprünglicher Queuefehler

Eine eigene Kopie mit ungültiger ausgewählter Zahlungsbedingung oder Buchungsgruppe verwenden. Zusätzlich einen Testnutzer mit fehlenden erforderlichen Standardrechten prüfen. Erwartung: konkreter Referenz-/Berechtigungsblocker, kein neuer Job und keine unerwartete Teilanlage. Vorlagenstart darf weder globale Einrichtung ergänzen noch eine ausgeschaltete Generierung wieder aktivieren.

Für einen kontrollierten Fehler zwischen zwei Paketen in einer separaten Testfirma den Lauf an sicherer Paketgrenze pausieren und erst dann einen tatsächlich referenzierten Dimensionswert sperren oder erforderliche Rechte entziehen. Erwartung beim Fortsetzen: konkrete Blockierung vor weiterer Fachanlage; bestätigte Partner bleiben erhalten. Ursache korrigieren und nur die nachweislich sichere Restarbeit über die vorhandene Recovery prüfen. Zusätzlich den Fall eines nach Claim fehlgeschlagenen Pakets ohne bestätigten Checkpoint prüfen: keine automatische Wiederholung. [Recovery-Fälle](../RECOVERY.md) und [SF-040-Abnahme](../MASTER_DATA_READINESS.md#abnahme-in-zwei-kleinen-sandbox-läufen). Wie ein Fehler nach Claim in der konkreten Sandbox reproduziert wird, vor Durchführung festlegen; keinen Test-Bypass in die App einbauen. Alle zusätzlichen Fehlertest-Partner getrennt von T02/T03 zählen.

Den bereits fehlgeschlagenen Playground-Lauf öffnen und **Fehler anzeigen** wählen. Erwartung: frühester fehlerhafter Standardjob, vollständige registrierte Fehlermeldung, Aufrufliste und eindeutiger Paketbezug. **Diagnose → Pakete → Ursprünglichen Warteschlangenfehler anzeigen** ist der alternative Zugang. Für den ursprünglichen Fehler werden benötigt: vollständiger Fehlertext des frühesten CUSTOMER-Jobs, Startzeit/Jobbindung, Paketstatus vor/nach Claim und kompletter Stack. Worker.OnRun Zeile 28 allein belegt keine Ursache.

Keinen alten unsicheren Claim neu starten. **Paketprüfung erforderlich** bleibt ohne bestätigten Checkpoint/gesichert beendete Sitzung gesperrt. Fehlende Standardprotokolle oder Rechte sind offen auszuweisen. Ein neuer Lauf ist kein Nachweis, dass alte unsichere Ergebnisse nicht existieren.

## T05 – Sammeltransfer in eine andere Testfirma

Zwei eigene Vorlagen mit verschiedenen Modulen, Mengen, Anteilen, Seed, Zeitraum und Partnereinstellungen markieren → **Ausgewählte Szenarien exportieren**. Genau eine JSON-Datei. In einer zweiten freigegebenen Firma **Szenariopaket importieren** und die Anzahl bestätigen.

Erwartung: zwei neue GUIDs, vollständige unabhängige Module/Ziele/Einstellungen, konkrete Meldung fehlender Ziel-Referenzcodes, kein gestarteter Lauf und keine Standarddatenanlage. Auch eine Datei deutlich unter 4 MiB muss importieren; CopyStream verwendet die tatsächliche Streamlänge. Ungültige zweite Vorlage, Schemafehler, Datei >4 MiB und Abbruch prüfen: kein Teilimport. Erneuter Import erstellt bewusste Kopien, kein Update.

## T06 – DE/EN und alle Appseiten

DE-DE, DE-AT, DE-CH, DE-LI, DE-LU sowie en-US prüfen. Szenarienliste/-karte, Laufkarte, Pakete, Setup, vorhandene Vorprüfung, Ergebnis-/Validierungsansichten und JS-Dashboard einschließlich Aktionen, Bestätigungen und Fehlern durchgehen. Deutsche Sitzung: alle Apptexte Deutsch, englische Sitzung: Englisch. Zahlenregion getrennt von Oberflächensprache testen. Zusätzlich EN-Datensprache in deutscher Sitzung wählen: Fachwerte bleiben bewusst englisch. Dashboard: Modul-/Entitätsnamen, Lauf-/Schrittstatus und Abschlussprüfung prüfen; gespeicherte historische Namen bleiben Daten. Beide Reiter bei breiter/schmaler Ansicht und per Tastatur bedienen; [SF-044-Abnahme](../DASHBOARD_DATA_STOCK.md#noch-ausstehende-sandbox-abnahme-sf-044).

Eine bereits vorhandene englische Startvorlage in DE und EN ansehen. Anzeige muss wechseln, gespeicherte Beschreibung und alte Snapshots nicht. Eigene, importierte und umbenannte Namen bleiben wörtlich erhalten. **Nur Planung** muss Artikel-/Beleg-/Buchungs-/Folgeprozessfälle klar vom ausführbaren Partnerpfad trennen.

## T07 – Löschen, Archiv und Wiederherstellen

Eine unbenutzte Vorlage und eine Vorlage mit erfasstem Lauf markieren → **Ausgewählte Vorlagen löschen**. Vor Bestätigung 1 löschbar/1 zu archivieren mit Begründung erwarten. Abbrechen: keine Änderung. Bestätigen: unbenutzte Vorlage samt Ziel-/Modulzeilen gelöscht; verwendete archiviert, Lauf/Job/Checkpoint/Herkunft/Standarddaten erhalten.

**Archivierte Vorlagen ein-/ausblenden** → archivierte Vorlage → alten Lauf öffnen. Neue Snapshots müssen auch bei direktem Backendaufruf gesperrt sein. **Startvorlagen laden** erneut: entfernte/archivierte Starter erscheinen nicht unaufgefordert; eigene Namen unverändert. Nur ausdrückliches **Entfernte Startvorlagen wiederherstellen** stellt Starter wieder her. Parallel zu einem Löschversuch einen Snapshot erfassen: die Elternsperre/erneute Prüfung verhindert eine Vorlage mit neuer Laufhistorie zu löschen.

## Tatsächliche Ergebnisse dieser Bearbeitung

Aktueller lokaler Nachweis: [SF-042](../TESTS.md#sf-042--soll-ist-prüfung-des-partnerpfads). **T01–T07 in Business Central nicht ausgeführt:** Installation, Initialisierung, 5/5, 12/7 ohne offene Sitzung, Setup-/Rechte-/Paketfehler, Wiederanlauf, firmenübergreifender Transfer und native Sprach-/Archiv-/Drilldownprüfung bleiben offen. Fachliche SF-038-/SF-039-Nachweise aus den folgenden Abschnitten ebenfalls protokollieren. Ihre älteren Finanzdialog-/Assistentenschritte durch den heutigen [Mandanteneinrichtungsweg](../COMPANY_INITIALIZATION.md) ersetzen. Ohne diese Nachweise und ausdrückliche menschliche P0-Abnahme keine Ausbau-Freigabe.

## Historischer Nachweis – JSON-Fehler beim ersten Paket

Für die Meldung „Die Daten stellen kein gültiges JSON-Token dar.“ enthält das neue JSON-Fix-Paket eine Korrektur am Checkpoint-BLOB-Lesepfad. Nach Installation des vollständigen Pakets einen **neuen**, ausdrücklich freigegebenen kleinen Partnerlauf prüfen. Erwartet: erster Paketabschluss, automatischer Nachfolger und Abschlussprüfung können gespeicherte Checkpoints erneut lesen. Einen alten Lauf mit unsicherem Claim nicht neu starten. Der genaue Screenshot-Stack und die BC-Abnahme bleiben getrennte Nachweise; siehe [Prüfprotokoll](../TESTS.md#sf-037--nachtrag-zum-json-fehler-im-partnerlauf).


## SF-038/SF-039 – noch offene BC-Abnahme

Aktueller [Vertrag mit Rollen und Versionsgrenzen](../STABILIZATION_FINANCE_PARTNERS.md). Alle folgenden Fälle sind **nicht ausgeführt**. Drei getrennte Testfirmen nutzen: unbebucht für SKR03, unbebucht für SKR04, passende vorhandene eigene Einrichtung. Vorher installierte App-ID/Version und konkretes Paket dokumentieren. Keine Produktionsfirma und keine vorhandenen Laufdaten bereinigen.

| Fall | Schritte | Soll / Nachweis |
| --- | --- | --- |
| F38-01 | Neue Starter laden, Karte → Finanzeinrichtung prüfen, SKR03 bzw. SKR04 wählen. Vorschau abbrechen. Erneut öffnen und Paket ausdrücklich anwenden. | Abbruch schreibt keine Standarddaten. Nach Apply 15 Postingkonten + 3 Summenkonten, korrekte Rollen/Kategorien/Bilanz-GuV; 0800 mit führender Null. INLAND03/04 in allen vorgesehenen Gruppen. Kein neues BCSF-AR/AP. |
| F38-02 | Dieselbe Anwendung wiederholen; anschließend vorhandene Einrichtung prüfen, alten Paketbestand 1.0.0 separat öffnen. | Keine Duplikate, keine Umbenennung/Umhängung. Vorhandene nichtleere Nummernserien unverändert. Version 1 bleibt 1 und erhält keine stille Version-2-Migration. Ein Wechsel des bereits angewendeten Rahmens blockiert. |
| F38-03 | In jeder neuen Firma Standard-Verkaufsrechnung: Sachkonto 8400/4400, netto 100 EUR, 19 %; Einkaufsrechnung: 3400/5400, netto 50 EUR, 19 %. Danach Fibu-Buchblatt: Bank 1200/1800 gegen Eigenkapital 0800/2900, 1.000 EUR. Beleg-/Buchungsnummern und Soll/Ist sichern. | Verkauf: Forderung +119, Erlös −100, USt −19. Einkauf: Einkauf +50, VSt +9,50, Verbindlichkeit −59,50. Journal: Bank +1.000, Eigenkapital −1.000. Keine direkten Ledger-Inserts. |
| F38-04 | SF03-BS/PL bzw. SF04-BS/PL mit dem passenden Datumsfilter öffnen. | Ohne sonstige Buchungen: Aktiva 1.128,50; Verbindlichkeiten −59,50, USt −19, Kapital −1.000, laufendes Ergebnis −50; Passiva inkl. Ergebnis −1.128,50. GuV Erlöse −100, Wareneinkauf +50, Ergebnis −50. Vorzeichen und Berichtssummen gegen Standardposten abgleichen. |
| F38-05 | Vor Apply Konto/Gruppe inkompatibel vorbelegen, Rechte entziehen, ungültige vorhandene Serie und fehlende Pflichtgrundlage prüfen. | Konkreter Blocker vor Teilanlage; bestehende Daten bleiben erhalten. In bebuchter Firma keine fehlenden Paketdaten ergänzen. Fremde Standardtrigger und Commit-Sperre gesondert prüfen. |
| F39-01 | Neue Vorlage 50 Debitoren/50 Kreditoren, Paketgröße 5, DE, gemischter B2B/B2C-Anteil. UI starten und Queue arbeiten lassen. Zweiter neuer Lauf gleicher Seed, dann anderer Seed. | 50/50 primäre Partner, 20 bestätigte Pakete, abgeschlossene Pflichtprüfung. Natürliche Namen/Ansprechpartner, keine Präfixe/Zählersuffixe. Fachwerte je logischem Schlüssel reproduzierbar; BC-Nummern dürfen abweichen. Vorlagen-/Laufkarten-Vorschau zeigt dieselben neuen Namenswerte, historische Vorschau bleibt erhalten. Andere Seeds variieren. |
| F39-02 | EN-Datensprache bei unveränderter DE-Sitzung; anschließend EN-Sitzung. GB nur mit geeigneter eigener Einrichtung, keine SKR-Auslandssteuerzusage. | Namen/Tätigkeiten folgen Datensprache, Oberfläche Sitzungssprache; PLZ/Ort/Land/Rechtsform bleiben konsistent. Unbekanntes Land blockiert vor Partneranlage. |
| F39-03 | Ergebniszuordnungen und Standardpartner öffnen. B2B-Debitor: DELIVERY; B2C: keine unnötige zweite Adresse; Kreditor: ORDER. Standardverkaufs-/Einkaufsbeleg anlegen und Adresse auswählen. | Kinddatensätze haben eigene SystemId, korrekte Parent Entry Id, denselben Lauf/Batch und logischen Schlüssel. Artikel-/Beleggeneratoren bleiben nicht verfügbar. Standardbelege übernehmen die ausgewählten Adressen und Partnerwerte. |
| F39-04 | Vorhandene Währung mit Kurs, Zahlungsform und zwei globale Dimensionen setzen; Belegübernahme prüfen. Je fehlenden Kurs/gesperrten Dimensionswert/fehlende Default-Dimension-Schreibrechte negativ testen. | Lesende Vorprüfung blockiert ungültige Werte. Standard-Dimensionsvalidierung erfolgt nach Partnerinsert und speichert Vorgabedimensionen. Ein Paketfehler verwirft alle Partner-/Kinddaten dieses Pakets; keine Wiederholung eines unsicheren Claims. |
| F39-05 | Firma mit vorhandener Marketingintegration, dann Firma ohne Integration prüfen. | Vorhandene Kontaktintegration und Nummernserien bleiben erhalten; Rechte-/Konfigurationsabweichungen blockieren vorab. Ohne CRM-Integration werden Ansprechpartnerfelder befüllt, keine selbständige CRM-Integration eingeschaltet. Standardkontakte separat prüfen. |
| F39-06 | Karte/Assistent → Zahlungsbereitschaft lesen; Bank-/Zahlungsfall bewerten. | Ohne freigegebenen synthetischen Bankdatensatz keine Partnerbankdaten, keine bevorzugte Bank, keine behauptete Zahlungsbereitschaft und kein Zahlungsexport. Bankprozessabnahme bleibt offen. |
| F39-07 | Zwei Vorlagen mit verschiedenen optionalen Währungs-/Zahlungs-/Dimensionscodes gemeinsam exportieren und in andere Firma importieren; zusätzlich alte Schema-1-Datei ohne diese Felder. | Neue GUIDs, Module/Mengen/Einstellungen erhalten, alte Dateien lesbar, konkrete fehlende Referenzcodes. Kein Lauf und keine Standarddaten werden durch den Import erzeugt. |
| F39-08 | Neuer Mehrpaketlauf 12/7, Paketgröße 5; kontrollierter Fehler nach einem erfolgreich bestätigten Paket; Recovery/Abschluss prüfen. Alten Version-1-Lauf öffnen. | 5 Pakete; bestätigte Einheiten und Kindartefakte getrennt. Keine doppelten Partner/Kinder, kein blinder Retry und kein Überschreiben alter Fachwerte. Ursprüngliche Paketfehler direkt erreichbar. |

Aktueller Normalpfad bei vorbereiteter Firma: **Vorlage wählen → Vorlage ausführen → Status ansehen → Daten öffnen**. Einmalige Finance-Grundlage über **Einrichtung → Mandant initialisieren**. Alte Vorlagen/Pakete werden dabei nicht automatisch migriert.


## Historischer Prüfweg SF-038 – Rechte und deaktiviertes Anwenden

Die folgenden Vorschau-/Filteraktionen gehören zum damaligen Stand 1.0.1.0. Die separate Finanzvorschau ist seit SF-043 entfernt. Die fachlichen Rechte-, Konflikt- und Rückabwicklungsfälle gelten weiter und sind heute über **Mandant initialisieren** zu prüfen; die alten UI-Schritte sind keine aktuelle Einsteigeranleitung.

Nutzer bestätigt den Befund „Erforderliche Standard-Lese- oder Schreibberechtigung fehlt.“. Neuer lokaler Paketstand und echte Checks siehe [TESTS.md](../TESTS.md#sf-038--gesperrte-finanzpaketanwendung-19112026). Keine Prüfung der individuellen Sandboxrechte ausgeführt.

1. In einer neuen **unbebuchten Sandbox-Testfirma** SKR03 bzw. SKR04 wählen. Die Vorschau zeigt Blockerzahl und ersten Befund oben, blockierende Zeilen zuerst. **Blockierende Befunde anzeigen** und **Alle Befunde anzeigen** prüfen. Die Paketaktion muss als hervorgehobene Aktion auffindbar sein. Vorschau öffnen/filtern/schließen darf keine Standarddaten schreiben.
2. Benutzer mit erforderlichen direkten Lese-/Einfüge- und Lizenzrechten auf fehlende Paketdatensätze, aber ohne Delete: Neuanlagen dürfen nicht allein wegen fehlendem Delete blockieren. Bei Ergänzung leerer Felder in vorhandenen Setupzeilen sind zusätzlich die dortigen Modify-Rechte erforderlich. Alle Standardtrigger-Nebenrechte bleiben maßgeblich.
3. Fehlendes Insert, fehlendes Modify bei nötiger Ergänzung, ausschließlich indirekte Berechtigung ohne passenden Standardwriter, fehlendes Lizenzrecht oder unzulässiger Sicherheitsfilter: konkrete Blockierung/Standardfehler; keine teilweise gespeicherte Paketanwendung und kein Job. Keine automatische Rollenzuweisung oder Empfehlung, pauschal SUPER zu vergeben.
4. Vollständig passende bestehende Datensätze werden lesend wiederverwendet; unnötige Schreib-/Löschrechte dürfen nicht verlangt werden. Rechte im **richtigen Testmandanten** unter den effektiven Berechtigungen prüfen lassen, wenn der Befund bestehen bleibt. `BCSF ADMIN` allein enthält weiterhin keine Standard-Einrichtungsrechte.
5. Nach fehlerfreier Vorschau **Testpaket anwenden → Bestätigung**; erst danach den Partnerlauf fortsetzen. Datenbank-/Lizenz-/Sicherheitsfilteränderung zwischen Vorschau und Anwendung muss durch die frische Prüfung weiterhin blockiert werden. Buchungsschutz, Paketwechselverbot und vorhandene Laufdaten bleiben erhalten.

Diese fünf nativen BC-Prüfungen sind **noch nicht ausgeführt**. Fehlende Standardrechte lassen sich nicht durch ein Codepaket ohne administrative Freigabe des Mandanten beheben. Der konkrete ursprüngliche Benutzerfall ist deshalb noch nicht als gelöst abgenommen.

## SF-019 – Artikelsortiment, aktueller Smoke-Test

In einer frischen Firma sind jetzt 58 Starter vorgesehen: 32 Partnerfälle, zwei technische Artikelsortimente und 24 Planungsfälle. **Einrichtung → Mandant initialisieren**, bei älterer SKR-Testfirma ggf. **Stammdatenbasis ergänzen**, dann **Vorlagen → Technischer Großhandel – Artikelsortiment → Vorlage ausführen**. Standard 1 Debitor / 2 Kreditoren / 8 Artikel bei Paketgröße 3. Anschließend die Variante **mit Lagerplätzen** prüfen.

[Erwartete Mengen, Standardseiten, ungebuchte Einkaufs-/Verkaufszeilen, negative Fälle und ausführliche Anleitung](../INVENTORY_GENERATION.md#manueller-sandbox-smoke-test). Der gemeldete Fehler mit vertauschter Kreditoren-/Artikelnummer ist im Code korrigiert; alten nach Claim fehlgeschlagenen Lauf nicht blind neu starten. Nach Paketupdate bewusst neuen Lauf verwenden und bestätigte alte Partner erhalten. Keine fachliche Korrekturabnahme aus dem Build ableiten.
