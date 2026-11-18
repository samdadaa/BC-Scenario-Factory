# Testanleitung – Vorlage wählen, starten, Ergebnis öffnen

Stand: 18.11.2026, aktueller Repository-Workspace; Reparaturauftrag SF-037, **Zur Prüfung**. Keine ältere ZIP zurückkopieren. Die folgenden BC-Fälle sind noch nicht ausgeführt; lokale Nachweise stehen in [TESTS.md](../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026).

## Vorbereitung und Paketstand

1. Eine ausdrücklich freigegebene, isolierte **Playground-Testfirma** ohne Sachposten verwenden. Die App erstellt keine Firma. Keine produktiven Mandanten, kein ForceSync und keine vorhandenen Laufdaten löschen.
2. Symbole gegen die tatsächlich verwendete Sandbox prüfen. Vollständiger AL-Build → `python3 Translations/sync_starter_translations.py` → `python3 scripts/check_translations.py` → `python3 scripts/build_dashboard_translations.py` → nochmals vollständiger Build. Die Datei aus dem letzten Build verwenden, kein RAD-Publish als Übersetzungsnachweis.
3. Nur dieses vollständige Paket nach entsprechender Deploymentfreigabe installieren/aktualisieren. Version, App-ID und Paketprüfsumme mit dem installierten Stand abgleichen. Die aktuellen Install-/Upgradetrigger schreiben keine Vorlagen oder BC-Standardeinrichtung.
4. `BCSF ADMIN` und passende Standardrechte für Einrichtung, Debitoren/Kreditoren, Nummernserien und Aufgabenwarteschlange sind erforderlich. Bei aktivierter Standard-Kontaktintegration zusätzlich Kontakt-/Beziehungsrechte. Rechte des Hintergrundnutzers separat prüfen.

## T01 – Startvorlagen laden

**Scenario-Factory-Szenarien → Startvorlagen laden**. In einer frischen Firma zunächst 56 Vorlagen erwarten, davon 32 Partnerfälle und 24 ausdrücklich als **Nur Planung** gekennzeichnete Fälle. Erneut laden: keine Duplikate und keine zurückgesetzten Namen/Mengen. Kein Lauf oder Partner allein durch Laden.

## T02 – Funktionstest 5/5

1. In deutscher Sitzung **Allgemeines Unternehmen – Funktionstest: Debitoren und Kreditoren** auswählen. Auf der Karte Debitoren = 5, Kreditoren = 5, Paketgröße = 5 prüfen. Nur positive Partnerziele, Modus Einrichtung/Stammdaten.
2. **Partnerszenario ausführen** wählen und den Dialog lesen/bestätigen. Für die reservierten Demo-Codes werden fehlende Minimalwerte ausschließlich nach dieser Bestätigung ergänzt. Bestehende Standardeinrichtung wird nicht still ersetzt. Keine Buchungen freigeben.
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
