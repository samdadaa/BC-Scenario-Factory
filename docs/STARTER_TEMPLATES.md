**Aktueller SF-050-Vertrag ab 1.0.11.0:** [Isolierte Dokumentjobs, lesende Skip-Nachweise, NeedsReview/Fortsetzung, Ergänzung vorhandener Mandanteneinrichtung und native Abnahme](review/SF050_PRUEFBERICHT.md). Additiv Batchfelder 19/20, temporäre Kennzahlen 20/21 und optionale Snapshot-Ausführungspolitik 1; keine Migration historischer Captures, kein ForceSync. Neue Captures vorhandener geschützter Starter nutzen die Politik automatisch. Native Prüfung durch den Nutzer offen, Status Zur Prüfung. Ältere datierte Ausführungs-/Existing-Beschreibungen unten bleiben historische Nachweise.

# Startvorlagen, Schnellstart und Sammeltransfer

**SF-048:** Drei zusätzliche geschützte Großhandelsstarter mit Endziffern 005/006/007: nur Stammdaten, 15 Einkaufsbestellungen, 20 Verkaufsaufträge. Bei den beiden ungebuchten Belegvorlagen vor Start eine echte bestätigte Stammdatenquelle auf der bestehenden Szenariokarte auswählen; ohne Quelle ist kein Lauf möglich. Vorhandene/archivierte/entfernte Starter werden nicht ersetzt. Normalweg bleibt gemeinsamer Unternehmensassistent. [Bedienung und native Abnahme](MODULAR_GENERATION.md).

## Benutzung

1. Den aktuellen Workspace verwenden, einschließlich lokaler Fixes. Vollständig gegen die Symbole der Ziel-Sandbox bauen; keine ältere Archivversion zurückkopieren.
2. Das vollständige neue `.app` in der freigegebenen Sandbox installieren/aktualisieren. **Install-/Upgrade-Trigger legen keine Vorlagen oder Standarddaten an.** Die optionale Vorlagenanlage gehört ausschließlich zum autorisierten UI-Einstieg und kann Publishing dadurch nicht wieder blockieren.
3. **Scenario-Factory-Szenarien → Startvorlagen laden** einmal ausführen. Wiederholtes Laden ergänzt nur fehlende, nicht absichtlich entfernte feste Vorlagen-IDs. Vorhandene Namen/Einstellungen und archivierte Vorlagen bleiben erhalten.
4. Z. B. **Groß- und Einzelhandel – Demo** wählen und **Partnerszenario ausführen** bestätigen. Der Schnellstart friert die gewählte Revision ein, prüft Plan und Einrichtung, bereitet Pakete vor und plant den Lauf. Die native Laufkarte zeigt das Ergebnis. Erwartet sind im Standard 12 Debitoren und 7 Kreditoren. Anzahl und Paketgröße sind bei der Erstellung auf vorhandene App-Limits begrenzt. Die Dauer hängt von der Standard-Queue ab.
5. Bei fehlender Finanzeinrichtung **Finanzeinrichtung prüfen** öffnen, SKR03 oder SKR04 auswählen, Vorschau prüfen und **Testpaket anwenden** bestätigen. Neue Starter schlagen SKR03 vor. Es gibt keinen Zwei-Konten-Fallback mehr. Bestehende Einrichtung bleibt erhalten; Konflikte blockieren. Der gemeinsame Paketvertrag und Altbestandsregeln stehen in [SF-038/SF-039](STABILIZATION_FINANCE_PARTNERS.md).
6. Danach **Partnerszenario ausführen** bestätigen. Der Schalter für Testgenerierung wird aktiviert; Buchungen werden nicht freigegeben. Eigene Vorlagen mit vorhandener Einrichtung und bereits angewendeten Paketen benötigen keine erneute Paketinstallation. Bestehende Starter werden beim Laden nicht geändert.

Erstantest empfohlen in einer eigens erstellten Testfirma ohne Sachposten und ohne produktive Firmenkopie oder Integrationen. Die App legt keine Firma an.

## Gelieferte Vorlagen

Je dokumentierter Branche sieben Startvorlagen: **Demo, Schulung, Funktionstest, Volumentest** für Partnerstammdaten und je eine **Planungsvorlage für offene Belege, gebuchte Bewegungen und Folgeprozesse**. Das ergibt **56 Vorlagen** inklusive **32 ausführbar konfigurierter Partnerfälle**, vorbehaltlich normaler Sandbox-, Setup-, Rechte- und Queue-Prüfungen. Je Branche variieren Profilkennung und Seed, bei Handel, E-Commerce und Service auch der Privatkundenanteil. Branchen: allgemeines Unternehmen, Groß-/Einzelhandel, E-Commerce, Distribution/Logistik, Fertigung, Dienstleistung/Beratung, Bau/Projektgeschäft und Service/Wartung.

Die 24 Planungsfälle nutzen die schon im Modell ausdrückbaren Artikel-/Einkaufs-/Verkaufsziele und passende Modulkennzeichen. Das ist **kein** fertig implementierter Branchenprozess. Artikel-, Beleg-, Fertigungs-, Projekt-, Lager- und Folgeprozessgeneratoren fehlen. Schnellstart ist für diese Vorlagen deaktiviert. Der vorhandene Assistent und Planer zeigen den Plan beziehungsweise seine Blocker. Volumenvorlage bedeutet nicht geprüfte Leistung.

## Export und Import

- In **Scenario-Factory-Szenarien** eine oder mehrere Zeilen auswählen und **Ausgewählte Szenarien exportieren**. Es wird genau eine JSON-Datei heruntergeladen.
- Im Zielmandanten **Szenariopaket importieren** wählen, dieselbe Datei hochladen und die Anzahl bestätigen. Jede Vorlage erhält eine neue GUID und eigene Module/Ziele. Ein erneuter Import legt weitere Kopien an, kein Update. Falsche Schemaversion, Größenlimit, ungültige Felder, doppelte Modul-/Zielzeilen oder unzulässige Mengen führen zum Abbruch ohne Teilimport. 1–250 Vorlagen, höchstens 4 MiB je Datei.
- Übertragen werden Vorlageneinstellungen einschließlich Freitextname, Profile, Modi, Datum, Seed, Zielmengen/-anteile sowie **Codes** für Buchungsgruppen/Zahlbedingungen und optional Währung, Zahlungsform sowie globale Dimensionswerte. Keine Partnerdatensätze, Sachposten, Jobs, Freigaben, Mandantenidentitäten, Nummernserien oder Finanzpaket-Installation. Eigene Standardcodes müssen im Ziel vorhanden sein oder angepasst werden. Ein SKR-Modus im Import wendet kein SKR-Paket an. Erfasste Lauf-Snapshots bleiben getrennt.
- Dateien sind UTF-8 und versioniert (`BCSF-SCENARIOS`, Schema 1). Keine Verarbeitung von frei adressierten Tabellen/Feldern. Typisierte App-Tabellen und ihre bestehenden Validierungen bleiben maßgeblich. Künftige Schemaänderungen versionieren und in beiden Richtungen testen.

## Build und Übersetzungen

Ein vollständiger AL-Build erzeugt die XLIFF-IDs. Danach im Projektstamm `python3 Translations/sync_starter_translations.py` ausführen (setzt das im Ausgangsprojekt vorhandene `sync_sf_translations.py` voraus), `python3 scripts/check_translations.py` prüfen und erneut vollständig bauen. Die deutsche Übersetzungszuordnung ist mitgeliefert. Keine geratenen XLIFF-IDs und keine Änderung bestehender Übersetzungseinheiten ohne Compiler. Unveränderte mitgelieferte Namen werden anhand fester Vorlagen-ID und bekanntem Standardnamen zur Anzeige lokalisiert, auch bei bereits gespeicherten englischen Vorlagen. Eigene/importierte/umbenannte Vorlagen und historische Snapshots werden nicht umgeschrieben.

## Prüfpunkte in BC

| ID | Test | Erwartung |
| --- | --- | --- |
| ST01 | Installation/Upgrade, danach Startvorlagen laden und wiederholen | Installation schreibt keine Vorlagen. UI-Laden erzeugt zunächst 56 Vorlagen, ohne Standarddaten/Läufe/Jobs; Wiederholung ohne Duplikate. |
| ST02 | Frische Playground-Testfirma, Demo starten | Gemeinsame Finanzvorschau und ausdrückliche Paketanwendung, danach 12/7 Standardpartner nach Queue-Abschluss. Lauf, Herkunft und Prüfstatus sichtbar. Keine Sachposten. |
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

Seit 1.0.5.2 enthalten die unterstützten Verkaufsvorlagen Stammdaten und Verkaufsziele gemeinsam. „Startvorlagen laden“ ergänzt die Vorgänger bei erkannten Verkaufsstartern. Der ungebuchte Testlauf benötigt keine Auswahl einer Lauf-GUID. Den aktuellen Ablauf und die Grenze für gebuchte Verkäufe beschreibt [Stammdaten und Verkauf in einem Lauf](SALES_PROCESS.md#stammdaten-und-verkauf-in-einem-lauf).


## 1.0.7.0 – drei Großhandelsreferenzen

Explizites Laden ergänzt geschützte feste Referenzen für ungebucht, gebucht und Zahlung/Ausgleich. Der vorhandene ungebuchte Starter wird nicht überschrieben. Gebuchte Referenzen verwenden TRADE v4 mit PO 60/20/Rest, SO 50/25/Rest und direkten Rechnungen 67/0/Rest; Angebote ungebucht. Neue Starter, Kopien und Importe übernehmen keine Buchungsfreigabe. Eigene Namen/Werte, Archivierung und Entfernungsvermerke bleiben erhalten. [Aktueller gemeinsamer Workflow](INDUSTRY_INITIALIZATION.md), [native Referenzprüfung](review/TESTANLEITUNG.md#1070--einkauf-buchung-zahlung-und-berechtigungsfehler).


## SF-046 – Exportprüfung mit vorhandenen Startvorlagen

Die vorhandenen geschützten Partner-, Artikel- und Großhandelsreferenzen gegen den realen Registry-/Generatorumfang geprüft. Für den Export ist keine neue Generatoroption und keine Änderung von Vorlagenmengen, IDs, Namen, Seeds, Quoten oder Freigaben erforderlich. Eigene/entfernte/archivierte Starter und gespeicherte Läufe bleiben unverändert.

Neue Abnahmefälle verwenden die bestehenden Referenzen und denselben Menüpunkt **Datenexportpaket vorbereiten** (BCSF-ALL-DATA). Seit 1.0.8.1 bereitet diese ausdrückliche Aktion das Paket ausschließlich in der aktuellen Firma vor; Installation/Upgrade tut dies nicht mehr. Die Starterwerte/Quoten bleiben unverändert:

| Referenz | Nach Laufabschluss im Excelexport prüfen |
| --- | --- |
| Partner/Artikel, reine Stammdaten | Customer, Vendor, Ship-to/Order Address, Item und sämtliche Artikelbeziehungen; ggf. Standardkontakte. Ohne Buchungen keine neuen Posten erwarten. |
| Großhandel ungebucht | Zusätzlich Sales/Purchase Header und Line mit identischen Schlüsseln/Mengen zur Standardliste. |
| Großhandel gebucht | Gebuchte Einkaufs-/Verkaufszeilen, Item/Value/G/L/VAT/CV-Posten, Detailposten, Register und Verknüpfungen. Gemischte PO 60/20/Rest, SO 50/25/Rest und Rechnungen 67/0/Rest erhalten; Angebote ungebucht. |
| Großhandel Zahlung/Ausgleich | Zusätzlich Bank Account Ledger Entry und Details zu Kunden-/Lieferantenausgleich. |
| Eine manuelle synthetische Zeile plus zwei Läufe | Alle Zeilen im Paketexport enthalten, unabhängig vom gewählten Dashboardlauf/-filter. Keine Duplikate durch wiederholtes Öffnen. |

Diese Fälle sind **vorbereitet, nicht nativ ausgeführt**. Vollständige Tabellen-IDs, Rechte und Standardgrenzen: [CONFIG_EXPORT.md](CONFIG_EXPORT.md).


## SF-047 – Zahlungs-Korrekturtest 1.0.8.5

Vorhandene Start-/Testvorlagen gegen den realen Generatorstand geprüft: `SeedWholesaleReference` verwendet `BCSF Wholesale Profile.CreateTemplateForId`; neu angelegte Großhandelsreferenzen erhalten damit TRADE/6. Eigene Werte/Namen, vorhandene Versionen, entfernte/archivierte Starter und historische Läufe werden nicht überschrieben. PO 60/20/Rest, SO 50/25/Rest und Rechnungen 67/0/Rest bleiben erhalten; Angebote ungebucht, Teilquoten nur Aufträge. Der Zahlungsfix ist keine neue konfigurierbare Generatorfunktion.

Für die native Korrekturabnahme einen **neuen** kleinen Großhandelslauf im gemeinsamen Workflow mit **Gebuchte Belege mit Zahlung und Ausgleich** und ausdrücklichen Freigaben verwenden. Kunden- und Lieferantenseite bis zu geschlossenen Rechnungs-/Zahlungsposten prüfen; Dashboard/Export gegen Standardposten abgleichen. Der vorhandene Evidence-Test prüft im kleinen Follow-up-Fall 23 Zahlungen/Bankposten; der Anti-Replay-Test sperrt abgeschlossene Zahlungen außerhalb eines Claims. Diese Tests sind nur kompiliert. Fehlgeschlagenen/übernommenen Altbatch nicht blind wiederholen. [Prüfbericht und genaue offene native Fälle](review/SF047_PRUEFBERICHT.md#zahlungskorrektur-1085--commit-bei-ausgleichsvalidierung).


## SF-049/SF-050 – vorhandene Vorlagen prüfen

Für den lokalen Teilstand 1.0.10.0 bleiben die geschützten SF-048-Starter für Stammdaten, 15 Bestellungen und 20 Verkaufsaufträge erhalten. Neu erfasste Bewegungsläufe mit leerer Quelle verwenden Pool Version 3. Rechnungs-only im bestehenden Unternehmensworkflow mit Einkauf/Angebot/Auftrag 0 und Rechnung 1 prüfen; bei Fehlbestand ungebuchten STOCK-Beleg und Qualitätswarnung erwarten. Danach Einkauf-only mit einem Lieferanten sowie gleiche 40 Artikel in wiederholten Läufen prüfen. Mischquoten und sämtliche eigenen/entfernten/archivierten Starter bleiben erhalten. Dies ist eine native Prüfanleitung, kein ausgeführter Lauf. [Nachweis und Grenzen](review/SF049_SF050_PRUEFBERICHT.md).


## SF-050 – Testen mit vorhandenen Startern

Vorhandene vier Großhandelsstufen sowie SF-048-Varianten (nur Stammdaten, Einkauf, Verkauf) verwenden. Neue Captures erhalten die Einzelvorgangspolitik; alte Läufe/Quoten/Freigaben unverändert. Für N03 Quelle mit gesperrtem ausgewähltem Stamm nach Capture, für N04 ausreichend Bestand und einen erst in Standardvalidierung wirksamen Kombinationsfehler vorbereiten. Der Existing-Stammdaten-/Komplettstarter prüft nun auch importierte Einrichtungsdaten mit fehlenden technischen Werten; die Meldung zu mehrdeutiger Artikel-Lagerortzuordnung darf im Normalweg nicht wiederkehren. Eigene, entfernte und archivierte Starter schützen. Keine neue Fachentität, daher keine zusätzliche als ausführbar ausgegebene SF-051/052/053-Vorlage. [Native Prüfschritte und genaue Grenzen](review/SF050_PRUEFBERICHT.md).
