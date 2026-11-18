# Startvorlagen, Schnellstart und Sammeltransfer

## Benutzung

1. Den aktuellen Workspace verwenden, einschließlich lokaler Fixes. Vollständig gegen die Symbole der Ziel-Sandbox bauen; keine ältere Archivversion zurückkopieren.
2. Das vollständige neue `.app` in der freigegebenen Sandbox installieren/aktualisieren. **Install-/Upgrade-Trigger legen keine Vorlagen oder Standarddaten an.** Die optionale Vorlagenanlage gehört ausschließlich zum autorisierten UI-Einstieg und kann Publishing dadurch nicht wieder blockieren.
3. **Scenario-Factory-Szenarien → Startvorlagen laden** einmal ausführen. Wiederholtes Laden ergänzt nur fehlende, nicht absichtlich entfernte feste Vorlagen-IDs. Vorhandene Namen/Einstellungen und archivierte Vorlagen bleiben erhalten.
4. Z. B. **Groß- und Einzelhandel – Demo** wählen und **Partnerszenario ausführen** bestätigen. Der Schnellstart friert die gewählte Revision ein, prüft Plan und Einrichtung, bereitet Pakete vor und plant den Lauf. Die native Laufkarte zeigt das Ergebnis. Erwartet sind im Standard 12 Debitoren und 7 Kreditoren. Anzahl und Paketgröße sind bei der Erstellung auf vorhandene App-Limits begrenzt. Die Dauer hängt von der Standard-Queue ab.
5. Autokonfiguration ist **nur für Partnerstammdaten** mit den reservierten Demo-Referenzen vorgesehen. Sie ergänzt fehlende Daten in einem unbebuchten Sandbox-Testmandanten, legt nötigenfalls einfache Nummernserien, Zahlbedingungen, zwei Test-Sachkonten und Partnerbuchungsgruppen an. Fehlende BC-Grundzeilen werden minimal angelegt. Die beiden Nummernserienfelder im Verkaufs-/Einkaufssetup werden nur befüllt, wenn sie fehlen oder leer sind. Bestehende Werte, Marketing-Integration und ein bestehendes SKR-Paket werden nicht umgestellt. Konflikte, nicht nutzbare bestehende Standardserien, Rechte- oder Drittanbieterprobleme blockieren weiterhin den Start. Es werden keine Buchungen freigegeben. Der Bestätigungsdialog weist darauf hin, dass der App-Schalter für Testgenerierung aktiviert wird.
6. Eigene Vorlagen mit passenden Gruppen oder angewendeten SKR-Paketen verwenden weiterhin den vorhandenen BC-Setup-/Preflightpfad. Sie werden vom Schnellstart nicht auf Demo-Gruppen umgestellt.

Erstantest empfohlen in einer eigens erstellten Testfirma ohne Sachposten und ohne produktive Firmenkopie oder Integrationen. Die App legt keine Firma an.

## Gelieferte Vorlagen

Je dokumentierter Branche sieben Startvorlagen: **Demo, Schulung, Funktionstest, Volumentest** für Partnerstammdaten und je eine **Planungsvorlage für offene Belege, gebuchte Bewegungen und Folgeprozesse**. Das ergibt **56 Vorlagen** inklusive **32 ausführbar konfigurierter Partnerfälle**, vorbehaltlich normaler Sandbox-, Setup-, Rechte- und Queue-Prüfungen. Je Branche variieren Profilkennung und Seed, bei Handel, E-Commerce und Service auch der Privatkundenanteil. Branchen: allgemeines Unternehmen, Groß-/Einzelhandel, E-Commerce, Distribution/Logistik, Fertigung, Dienstleistung/Beratung, Bau/Projektgeschäft und Service/Wartung.

Die 24 Planungsfälle nutzen die schon im Modell ausdrückbaren Artikel-/Einkaufs-/Verkaufsziele und passende Modulkennzeichen. Das ist **kein** fertig implementierter Branchenprozess. Artikel-, Beleg-, Fertigungs-, Projekt-, Lager- und Folgeprozessgeneratoren fehlen. Schnellstart ist für diese Vorlagen deaktiviert. Der vorhandene Assistent und Planer zeigen den Plan beziehungsweise seine Blocker. Volumenvorlage bedeutet nicht geprüfte Leistung.

## Export und Import

- In **Scenario-Factory-Szenarien** eine oder mehrere Zeilen auswählen und **Ausgewählte Szenarien exportieren**. Es wird genau eine JSON-Datei heruntergeladen.
- Im Zielmandanten **Szenariopaket importieren** wählen, dieselbe Datei hochladen und die Anzahl bestätigen. Jede Vorlage erhält eine neue GUID und eigene Module/Ziele. Ein erneuter Import legt weitere Kopien an, kein Update. Falsche Schemaversion, Größenlimit, ungültige Felder, doppelte Modul-/Zielzeilen oder unzulässige Mengen führen zum Abbruch ohne Teilimport. 1–250 Vorlagen, höchstens 4 MiB je Datei.
- Übertragen werden Vorlageneinstellungen einschließlich Freitextname, Profile, Modi, Datum, Seed, Zielmengen/-anteile sowie **Codes** für Buchungsgruppen/Zahlbedingungen. Keine Partnerdatensätze, Sachposten, Jobs, Freigaben, Mandantenidentitäten, Nummernserien oder Finanzpaket-Installation. Eigene Standardcodes müssen im Ziel vorhanden sein oder angepasst werden. Ein SKR-Modus im Import wendet kein SKR-Paket an. Erfasste Lauf-Snapshots bleiben getrennt.
- Dateien sind UTF-8 und versioniert (`BCSF-SCENARIOS`, Schema 1). Keine Verarbeitung von frei adressierten Tabellen/Feldern. Typisierte App-Tabellen und ihre bestehenden Validierungen bleiben maßgeblich. Künftige Schemaänderungen versionieren und in beiden Richtungen testen.

## Build und Übersetzungen

Ein vollständiger AL-Build erzeugt die XLIFF-IDs. Danach im Projektstamm `python3 Translations/sync_starter_translations.py` ausführen (setzt das im Ausgangsprojekt vorhandene `sync_sf_translations.py` voraus), `python3 scripts/check_translations.py` prüfen und erneut vollständig bauen. Die deutsche Übersetzungszuordnung ist mitgeliefert. Keine geratenen XLIFF-IDs und keine Änderung bestehender Übersetzungseinheiten ohne Compiler. Unveränderte mitgelieferte Namen werden anhand fester Vorlagen-ID und bekanntem Standardnamen zur Anzeige lokalisiert, auch bei bereits gespeicherten englischen Vorlagen. Eigene/importierte/umbenannte Vorlagen und historische Snapshots werden nicht umgeschrieben.

## Prüfpunkte in BC

| ID | Test | Erwartung |
| --- | --- | --- |
| ST01 | Installation/Upgrade, danach Startvorlagen laden und wiederholen | Installation schreibt keine Vorlagen. UI-Laden erzeugt zunächst 56 Vorlagen, ohne Standarddaten/Läufe/Jobs; Wiederholung ohne Duplikate. |
| ST02 | Frische Playground-Testfirma, Demo starten | Bestätigung, ggf. fehlende Minimalwerte ergänzt, 12/7 Standardpartner nach Queue-Abschluss. Lauf, Herkunft und Prüfstatus sichtbar. Keine Sachposten. |
| ST03 | Einen reservierten Demo-Code inkompatibel belegen; bestehenden Mandanten mit Sachposten verwenden | Abbruch mit Ursache; keine stillen Teiländerungen, keine Freigabe, kein Job. Anderweitige Business-Central-Trigger gesondert verifizieren. |
| ST04 | Zwei eigene Vorlagen mit unterschiedlichen Modulen/Mengen und Profilen markieren und exportieren. In anderer Firma gemeinsam importieren. | Zwei vollständige Kopien mit neuen GUIDs. Keine importierten Jobs oder Standarddaten; Quell- und Zielvorlagen sind unabhängig. |
| ST05 | In Testdatei zweite Vorlage fachlich fehlerhaft, Formatversion abändern, Datei >4 MiB, Dialog abbrechen | Kein Teilimport. Bei fehlenden BC-Referenzcodes ist Vorlagenimport möglich; die Ausführung scheitert in der Vorprüfung. |
| ST06 | Planungsvorlage für Buchungen öffnen; außerhalb Playground die Installation und Bedienung prüfen | Kein Schnellstart, keine automatische Standarddatenänderung und keine produktive Generierung. |
| ST07 | EN/DE-Build und Publish, Rollen-/Berechtigungstest | Aktionen lokalisiert, Standardrechte nicht von BCSF ADMIN angehoben. Stört ein analysierter Standardtrigger, Fehler und BC-Version dokumentieren. |

**Prüfstatus:** Zur Prüfung. Aktuelle tatsächlich ausgeführte lokale Prüfungen und nicht ausgeführte BC-Fälle stehen in [TESTS.md](TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). Ein lokaler Build belegt keine erfolgreiche Sandboxausführung.

## Namen, Archiv und Entfernen

Unveränderte Startnamen erscheinen in der Sitzungssprache. Eine Bearbeitung auf Karte/Assistent speichert einen eigenen Namen; Öffnen und Sprachwechsel schreiben nichts. Die feste ID allein genügt nicht zum Umbenennen: Der gespeicherte Name muss zusätzlich einem bekannten Standardnamen entsprechen.

**Ausgewählte Vorlagen löschen** zeigt die Zahl unbenutzter und verwendeter Vorlagen vor der Bestätigung. Unbenutzte werden unter derselben Elternsperre wie die Snapshotanlage nochmals geprüft und mit Zielen/Modulen gelöscht. Verwendete werden archiviert. Die Backendregel gilt auch bei `Delete(false)`. Laufdaten, Checkpoints, Herkunft und BC-Standarddatensätze werden nicht gelöscht. Archivieren stoppt keine Jobs.

**Archivierte Vorlagen ein-/ausblenden** erhält den Zugang zur Vorlage und ihren Läufen. Neue Snapshots aus archivierten Vorlagen sind serverseitig gesperrt. **Ausgewählte Vorlagen wiederherstellen** macht archivierte wieder auswählbar. Entfernte IDs bleiben firmenbezogen in Tabelle 90148 vermerkt. Nur **Entfernte Startvorlagen wiederherstellen** stellt entfernte/archivierte Standardvorlagen nach ausdrücklicher Bestätigung wieder her; eigenes Umbenennen wird nicht zurückgesetzt.

## Fehler und Ergebnisse

Normalpfad: **Vorlage wählen → Partnerszenario ausführen → bestätigen → Laufkarte → Ergebnisse öffnen**. Die Laufkarte zeigt aktuellen Status, Paketzähler, Abschlussprüfung und erzeugte Debitoren/Kreditoren. Mengen öffnen ausschließlich die für diesen Lauf registrierten stabilen Partneridentitäten. Jede Herkunftszeile kann die genaue Partnerkarte öffnen.

**Fehler anzeigen** öffnet den frühesten verfügbaren fehlgeschlagenen Standard-Queueeintrag dieses Laufs, einschließlich früherer Jobbindungen aus der Historie. Registrierte Standardfehlerdetails und Aufrufliste bleiben im Standardprotokoll; keine Kopie in das eigene Audit. Ohne Protokoll wird der fehlende Nachweis konkret benannt und die betroffene Paketliste geöffnet. Unsichere übernommene Arbeit bleibt gesperrt; Diagnose ist keine Retryfreigabe.
