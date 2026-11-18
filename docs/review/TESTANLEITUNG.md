# Testanleitung – Vorlage wählen, starten, Ergebnis öffnen

Stand: 18.11.2026, aktueller Repository-Workspace; Reparaturaufträge SF-037 sowie ausdrücklich ausgewählte SF-038/SF-039, **Zur Prüfung**. Keine ältere ZIP zurückkopieren. Die folgenden BC-Fälle sind noch nicht ausgeführt; lokale Nachweise stehen in [TESTS.md](../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026).

## Vorbereitung und Paketstand

1. Eine ausdrücklich freigegebene, isolierte **Playground-Testfirma** ohne Sachposten verwenden. Die App erstellt keine Firma. Keine produktiven Mandanten, kein ForceSync und keine vorhandenen Laufdaten löschen.
2. Symbole gegen die tatsächlich verwendete Sandbox prüfen. Vollständiger AL-Build → `python3 Translations/sync_starter_translations.py` → `python3 scripts/check_translations.py` → `python3 scripts/build_dashboard_translations.py` → nochmals vollständiger Build. Die Datei aus dem letzten Build verwenden, kein RAD-Publish als Übersetzungsnachweis.
3. Nur dieses vollständige Paket nach entsprechender Deploymentfreigabe installieren/aktualisieren. Version, App-ID und Paketprüfsumme mit dem installierten Stand abgleichen. Die aktuellen Install-/Upgradetrigger schreiben keine Vorlagen oder BC-Standardeinrichtung.
4. `BCSF ADMIN` und passende Standardrechte für Einrichtung, Debitoren/Kreditoren, Nummernserien und Aufgabenwarteschlange sind erforderlich. Bei aktivierter Standard-Kontaktintegration zusätzlich Kontakt-/Beziehungsrechte. Rechte des Hintergrundnutzers separat prüfen.

## T01 – Startvorlagen laden

**Scenario-Factory-Szenarien → Startvorlagen laden**. In einer frischen Firma zunächst 56 Vorlagen erwarten, davon 32 Partnerfälle und 24 ausdrücklich als **Nur Planung** gekennzeichnete Fälle. Erneut laden: keine Duplikate und keine zurückgesetzten Namen/Mengen. Kein Lauf oder Partner allein durch Laden.

## T02 – Funktionstest 5/5

1. In deutscher Sitzung **Allgemeines Unternehmen – Funktionstest: Debitoren und Kreditoren** auswählen. Auf der Karte Debitoren = 5, Kreditoren = 5, Paketgröße = 5 prüfen. Nur positive Partnerziele, Modus Einrichtung/Stammdaten.
2. **Partnerszenario ausführen** wählen und den Dialog lesen/bestätigen. Fehlende Finanzeinrichtung zuerst über **Finanzeinrichtung prüfen → SKR03/SKR04 → Vorschau → Testpaket anwenden** gesondert bestätigen. Es gibt keinen Zwei-Konten-Fallback mehr. Bestehende Standardeinrichtung wird nicht still ersetzt. Keine Buchungen freigeben.
3. Auf der automatisch geöffneten Laufkarte den aktuellen Ausführungsstatus und **Fortschritt ansehen** verwenden. Plan, Queue und Checkpoints nicht manuell bedienen. Der Browser muss für den Hintergrundlauf nicht offen bleiben. Die Seite bei Bedarf aktualisieren.
4. Erwartung nach tatsächlichem Queueabschluss: **2 von 2** Paketen bestätigt, **5 Debitoren**, **5 Kreditoren**, Abschlussprüfung **Bestanden**, Status **Abgeschlossen**. Kein Sachposten.
5. Mengenlinks öffnen nur diese 5/5 Partner. **Ergebnisse öffnen → Erzeugten Partner öffnen** öffnet exakt den registrierten Standarddatensatz. Keine ungefilterte Liste als Ergebnis akzeptieren.

## T03 – Mehrpaketfall 12/7

Die ausführbare Handels-Demovorlage auf 12/7 und Paketgröße 5 prüfen und ebenso starten. Erwartung: Debitorenpakete 5+5+2, Kreditorenpakete 5+2; **5 von 5**, genau 19 führende Herkunftseinträge, Abschlussprüfung bestanden. Damit wird die automatische Folgeplanung geprüft. Zusätzliche Standardkontakte zählen nicht zu den führenden Partnern.

## T04 – Negativer Setupfall und ursprünglicher Queuefehler

Eine eigene Kopie mit fehlender Zahlungsbedingung oder fehlender Buchungsgruppe verwenden. Erwartung: konkreter Referenzcode/Blocker, kein geplanter Job und keine unerwartete Teilanlage. Bei Schnellstartfehlern auch Demo-Ergänzungen/Freigabe/Laufanlage auf gemeinsame Rückabwicklung prüfen.

Den bereits fehlgeschlagenen Playground-Lauf öffnen und **Fehler anzeigen** wählen. Erwartung: frühester fehlerhafter Standardjob, vollständige registrierte Fehlermeldung, Aufrufliste und eindeutiger Paketbezug. **Diagnose → Pakete → Ursprünglichen Warteschlangenfehler anzeigen** ist der alternative Zugang. Für den ursprünglichen Fehler werden benötigt: vollständiger Fehlertext des frühesten CUSTOMER-Jobs, Startzeit/Jobbindung, Paketstatus vor/nach Claim und kompletter Stack. Worker.OnRun Zeile 28 allein belegt keine Ursache.

Keinen alten unsicheren Claim neu starten. **Paketprüfung erforderlich** bleibt ohne bestätigten Checkpoint/gesichert beendete Sitzung gesperrt. Fehlende Standardprotokolle oder Rechte sind offen auszuweisen. Ein neuer Lauf ist kein Nachweis, dass alte unsichere Ergebnisse nicht existieren.

## T05 – Sammeltransfer in eine andere Testfirma

Zwei eigene Vorlagen mit verschiedenen Modulen, Mengen, Anteilen, Seed, Zeitraum und Partnereinstellungen markieren → **Ausgewählte Szenarien exportieren**. Genau eine JSON-Datei. In einer zweiten freigegebenen Firma **Szenariopaket importieren** und die Anzahl bestätigen.

Erwartung: zwei neue GUIDs, vollständige unabhängige Module/Ziele/Einstellungen, konkrete Meldung fehlender Ziel-Referenzcodes, kein gestarteter Lauf und keine Standarddatenanlage. Auch eine Datei deutlich unter 4 MiB muss importieren; CopyStream verwendet die tatsächliche Streamlänge. Ungültige zweite Vorlage, Schemafehler, Datei >4 MiB und Abbruch prüfen: kein Teilimport. Erneuter Import erstellt bewusste Kopien, kein Update.

## T06 – DE/EN und alle Appseiten

DE-DE, DE-AT, DE-CH, DE-LI, DE-LU sowie en-US prüfen. Szenarienliste, Karte, Assistent, Laufkarte, Pakete, Setup, Vorprüfung, Generatoren, Ergebnis-/Validierungsansichten und JS-Dashboard einschließlich Aktionen, Bestätigungen und Fehlern durchgehen. Deutsche Sitzung: alle Apptexte Deutsch, englische Sitzung: Englisch. Zahlenregion getrennt von Oberflächensprache testen. Dashboard: Modul-/Entitätsnamen, Lauf-/Schrittstatus und Abschlussprüfung prüfen; gespeicherte historische Namen bleiben Daten.

Eine bereits vorhandene englische Startvorlage in DE und EN ansehen. Anzeige muss wechseln, gespeicherte Beschreibung und alte Snapshots nicht. Eigene, importierte und umbenannte Namen bleiben wörtlich erhalten. **Nur Planung** muss Artikel-/Beleg-/Buchungs-/Folgeprozessfälle klar vom ausführbaren Partnerpfad trennen.

## T07 – Löschen, Archiv und Wiederherstellen

Eine unbenutzte Vorlage und eine Vorlage mit erfasstem Lauf markieren → **Ausgewählte Vorlagen löschen**. Vor Bestätigung 1 löschbar/1 zu archivieren mit Begründung erwarten. Abbrechen: keine Änderung. Bestätigen: unbenutzte Vorlage samt Ziel-/Modulzeilen gelöscht; verwendete archiviert, Lauf/Job/Checkpoint/Herkunft/Standarddaten erhalten.

**Archivierte Vorlagen ein-/ausblenden** → archivierte Vorlage → alten Lauf öffnen. Neue Snapshots müssen auch bei direktem Backendaufruf gesperrt sein. **Startvorlagen laden** erneut: entfernte/archivierte Starter erscheinen nicht unaufgefordert; eigene Namen unverändert. Nur ausdrückliches **Entfernte Startvorlagen wiederherstellen** stellt Starter wieder her. Parallel zu einem Löschversuch einen Snapshot erfassen: die Elternsperre/erneute Prüfung verhindert eine Vorlage mit neuer Laufhistorie zu löschen.

## Tatsächliche Ergebnisse dieser Bearbeitung

Lokaler Build-/Übersetzungs-/Dashboard- und Paketnachweis: [TESTS.md](../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **T01–T07 in Business Central nicht ausgeführt:** kein nutzbarer autorisierter Browser-/Sandboxzugriff in dieser Sitzung. Installation, 5/5, 12/7, frische Demo-Minimaleinrichtung, negativer Setupfall, firmenübergreifender Transfer und native Sprach-/Archiv-/Parallelitätsprüfung bleiben offen. Kein erfolgreicher BC-Lauf aus Quellprüfung abgeleitet.

## Ergänzung – JSON-Fehler beim ersten Paket

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

Kürzester Normalpfad bei vorbereiteter Firma: **Vorlage wählen → Partnerszenario ausführen → Ergebnisse öffnen**. Einmalige neue Finance-Grundlage: **Finanzeinrichtung prüfen → Rahmen wählen → Vorschau → Testpaket anwenden**. Alte Vorlagen/Pakete werden dabei nicht automatisch migriert.
