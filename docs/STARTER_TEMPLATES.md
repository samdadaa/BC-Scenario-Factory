# Startvorlagen, Schnellstart und Sammeltransfer

## Benutzung

1. Geänderte Dateien über den Projektstand aus `BC Scenario Factory(4).zip` legen. Die alte beigelegte `.app` nicht verwenden. Erst mit den Symbolen der eigenen Sandbox bauen; siehe unten für Übersetzungen.
2. Version **1.0.1.0** mit unveränderter App-ID veröffentlichen und in der freigegebenen SaaS-Sandbox **Playground** installieren/aktualisieren. Starter-Install-/Upgrade legt pro freigegebenem Mandanten nur App-Einrichtung und Vorlagen an. Dabei werden keine Standarddaten oder Läufe angelegt und die Generierung wird nicht automatisch freigeschaltet.
3. **Scenario-Factory-Szenarien** öffnen. Für einen nach der App-Installation angelegten Mandanten gegebenenfalls einmal **Startvorlagen laden** benutzen. Wiederholung und Upgrade füllen fehlende fixe Vorlagen-IDs nach, überschreiben aber weder eigene noch geänderte Vorlagen. Ein kopiertes Setup, das auf einen anderen Mandanten oder eine andere Umgebung zeigt, wird bei der automatischen Anlage übersprungen. Es wird nicht still umgebunden.
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

Ein vollständiger AL-Build erzeugt die XLIFF-IDs. Danach im Projektstamm `python3 Translations/sync_starter_translations.py` ausführen (setzt das im Ausgangsprojekt vorhandene `sync_sf_translations.py` voraus), `python3 scripts/check_translations.py` prüfen und erneut vollständig bauen. Die deutsche Übersetzungszuordnung ist mitgeliefert. Keine geratenen XLIFF-IDs und keine Änderung bestehender Übersetzungseinheiten ohne Compiler. Benennungen bereits angelegter Vorlagen werden bei Sprachwechsel nicht überschrieben.

## Prüfpunkte in BC

| ID | Test | Erwartung |
| --- | --- | --- |
| ST01 | Installation in einer frischen Playground-Testfirma; erneutes Laden/Upgrade | 56 Presets, App-Setup vorhanden. Keine Sachkonten, Partner, Gruppen oder Jobs allein durch Installieren. Wiederholung ohne Duplikate, bestehende Änderungen erhalten. |
| ST02 | Frische Playground-Testfirma, Demo starten | Bestätigung, ggf. fehlende Minimalwerte ergänzt, 12/7 Standardpartner nach Queue-Abschluss. Lauf, Herkunft und Prüfstatus sichtbar. Keine Sachposten. |
| ST03 | Einen reservierten Demo-Code inkompatibel belegen; bestehenden Mandanten mit Sachposten verwenden | Abbruch mit Ursache; keine stillen Teiländerungen, keine Freigabe, kein Job. Anderweitige Business-Central-Trigger gesondert verifizieren. |
| ST04 | Zwei eigene Vorlagen mit unterschiedlichen Modulen/Mengen und Profilen markieren und exportieren. In anderer Firma gemeinsam importieren. | Zwei vollständige Kopien mit neuen GUIDs. Keine importierten Jobs oder Standarddaten; Quell- und Zielvorlagen sind unabhängig. |
| ST05 | In Testdatei zweite Vorlage fachlich fehlerhaft, Formatversion abändern, Datei >4 MiB, Dialog abbrechen | Kein Teilimport. Bei fehlenden BC-Referenzcodes ist Vorlagenimport möglich; die Ausführung scheitert in der Vorprüfung. |
| ST06 | Planungsvorlage für Buchungen öffnen; außerhalb Playground die Installation und Bedienung prüfen | Kein Schnellstart, keine automatische Standarddatenänderung und keine produktive Generierung. |
| ST07 | EN/DE-Build und Publish, Rollen-/Berechtigungstest | Aktionen lokalisiert, Standardrechte nicht von BCSF ADMIN angehoben. Stört ein analysierter Standardtrigger, Fehler und BC-Version dokumentieren. |

**Prüfstatus:** Zur Prüfung. Kein AL-Compiler im Bearbeitungsworkspace, kein Deployment und keine BC-Laufzeitabnahme. Die neuen Roundtrip-/Installations-/Schnellstartfälle sind manuelle Abnahmefälle.

Lokale Quellprüfungen: 125 eindeutige numerische IDs, 56 gültige feste Vorlagen-GUIDs, JSON-Feldabgleich für alle 25 Portabilitätsfelder sowie getrennte Modul-/Zielarrays. Bestehender XLIFF-Bestand geprüft; 42 neue Quelltexte abgedeckt, Synchronisierung in einer isolierten Fixture mit simulierten IDs geprüft. IDs dieser Fixture sind nicht Teil der Lieferung. XERJ stand in diesem Workspace nicht zur Verfügung.
