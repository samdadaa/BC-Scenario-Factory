# Manueller Testkatalog

Stand 26.11.2026 · App 1.0.12.0 · **Ergebnisspalte bewusst leer: keiner dieser Fälle wurde im Rahmen der Erstellung ausgeführt.** Referenzmengen stammen aus der bestehenden Dokumentation ([TESTANLEITUNG](review/TESTANLEITUNG.md), [COMPANY_INITIALIZATION](COMPANY_INITIALIZATION.md), [STARTER_TEMPLATES](STARTER_TEMPLATES.md), [CONFIG_EXPORT](CONFIG_EXPORT.md)) und sind in der Sandbox zu bestätigen. Nur eine frische, isolierte Sandbox-Firma ohne echte Daten verwenden.

Protokoll je Fall (ohne sensible Daten): BC-Version/Lokalisierung, Firma, Rolle, App-Version, Vorlage/Seed, Datum, Run-/Job-ID, beobachtetes Ergebnis. Zurück zu [TESTS](TESTS.md) · [README](../README.md).

## A. Installation, Einrichtung, Sicherheit

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-01 | Installation ohne Nebenwirkung | App in frischer Sandbox-Firma veröffentlichen. Vorlagen-, Job- und Kontenplan-Tabellen prüfen. | Keine Vorlagen, Jobs, Kontenplan- oder Standarddatenänderung durch die Installation. |  |
| MT-02 | Berechtigungssatz | Benutzer ohne und mit **BCSF ADMIN** die Einrichtung öffnen lassen. | Ohne Satz: Zugriff verweigert. Mit Satz: Einrichtung öffnet; Standardtabellenrechte werden dadurch nicht vergeben. |  |
| MT-03 | Mandant initialisieren (SKR03) | Einrichtung → Mandant initialisieren → SKR03 → bestätigen. | Kontenplan, Buchungsgruppen, Nummernserien, Startervorlagen angelegt; Generierung erlaubt; Buchungsfreigabe in neuer Firma aus. |  |
| MT-04 | Mandant initialisieren (SKR04) | Wie MT-03 in separater frischer Firma mit SKR04. | Wie MT-03 mit SKR04-Konten. |  |
| MT-05 | Vorhandene Einrichtung übernehmen | In bereits eingerichteter Firma „vorhandene Einrichtung“ wählen. | Keine Finanzänderung; Übernahme oder konkreter Konflikt-/Rechtehinweis. |  |
| MT-06 | Abbruch und Wiederholung | Dialog abbrechen, Initialisierung zweimal ausführen. | Abbruch ändert nichts; Wiederholung erzeugt keine Duplikate. |  |
| MT-07 | Produktionssperre | Generierung in einer Nicht-Sandbox-Umgebung bzw. nicht freigegebenen Firma starten (nur falls gefahrlos möglich). | Start wird serverseitig verweigert, auch im Hintergrundlauf. |  |
| MT-08 | Generierung abschalten | Generierung in der Einrichtung ausschalten, Vorlage starten. | Kein neuer Job; Vorlagenstart schaltet nichts heimlich wieder ein. |  |

## B. Vorlagen und Assistent

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-10 | Startvorlagen laden | Szenarien → Startvorlagen laden, wiederholen. | Vorlagen vorhanden (docs nennen 56 in frischer Firma, zu bestätigen); Wiederholung ohne Duplikate, Namen/Mengen unverändert. |  |
| MT-11 | Funktionstest Partner 5/5 | Vorlage „Allgemeines Unternehmen – Funktionstest: Debitoren und Kreditoren“ → Vorlage ausführen. | Laufkarte öffnet; 2 von 2 Paketen bestätigt, 5 Debitoren, 5 Kreditoren, Qualität „Bestanden“, kein Sachposten. |  |
| MT-12 | Assistent Großhandel Klein, Stammdaten | Assistent: Kontenplan → Großhandel → Klein → Stammdaten → Zusammenfassung → Start. | Zusammenfassung nennt Mengen (docs: 20 Debitoren, 5 Kreditoren, 40 Artikel); ein Hintergrundjob; keine Belege. |  |
| MT-13 | Größen Mittel/Groß | Größe Mittel bzw. Groß wählen, nur Zusammenfassung prüfen (nicht starten). | Mengen skalieren mit dem hinterlegten Faktor (docs: 10 bzw. 100). |  |
| MT-14 | Gesperrte Branchen/Stufen | Nicht unterstützte Branche und Buchungsstufe ohne Voraussetzung wählen. | Auswahl gesperrt bzw. Start verweigert, keine stille Freigabe. |  |
| MT-15 | Doppelstart | Start zweimal kurz nacheinander auslösen. | Nur ein Lauf; kein Duplikat. |  |
| MT-16 | Vorlage kopieren, ändern, archivieren, wiederherstellen, löschen | Eigene Vorlage anlegen/kopieren, archivieren, wiederherstellen, unbenutzte löschen. | Verwendete Vorlagen bleiben geschützt; archivierte Vorlagen erzeugen keine neuen Snapshots. |  |
| MT-17 | Vorlagen-Export/-Import | Zwei eigene Vorlagen exportieren, in anderer Firma importieren. | Zwei Kopien mit neuen GUIDs; keine Jobs/Läufe importiert; fehlerhafte Datei → kein Teilimport. |  |

## C. Datenerzeugung und Prozessstufen

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-20 | Ungebuchte Belege | Großhandel Klein, Stufe „ungebuchte Belege“ starten. | Docs-Referenz: 15 Einkaufsbestellungen, 5 Verkaufsangebote, 12 Verkaufsaufträge, 3 Verkaufsrechnungen; keine Posten; Partner/Artikel stammen aus demselben Lauf. |  |
| MT-21 | Gebuchte Belege (mit Zustimmung) | Stufe „gebuchte Belege“, Buchungszustimmung erteilen, starten. | Ohne Zustimmung Start gesperrt. Mit Zustimmung: Einkaufsrechnungen/Wareneingänge, Verkaufsrechnungen, Teilquoten nur bei Aufträgen; Angebote bleiben ungebucht. |  |
| MT-22 | Zahlungen und Ausgleich | Stufe Zahlungen/Ausgleich. | Zahlungen auf Bankkonto; Mix aus voll, Raten, Teilzahlung und offen; Rechnungsdatum ≤ Zahlungsdatum; Restbeträge nachvollziehbar. |  |
| MT-23 | Gutschriften und Retouren | Folgeprozess Gutschriften/Retouren aktivieren. | Ungebuchte sowie teil-/vollgebuchte Gutschriften zu gebuchten Rechnungen; Rücksendebelege. |  |
| MT-24 | Lagerbewegungen ohne WMS | Folgeprozess Lagerbewegungen aktivieren. | Zu-/Abgang, Inventurdifferenz, Umlagerung über Transitlager; Bestand je Lagerort/Datum nicht negativ. |  |
| MT-25 | Lagereingang/Einlagerung | Optionales Modul Lager wählen. | Lagereingang und Einlagerung über Standard; kontrollierter Skip mit Hinweis, falls Voraussetzung fehlt. |  |
| MT-26 | Fertigung | Optionales Modul Fertigung wählen. | Fertigungsstückliste und Fertigungsauftrag über Standard. |  |
| MT-27 | Montage | Optionales Modul Montage wählen. | Montageartikel mit Stückliste, ungebuchter sowie voll/teilweise gebuchter Montageauftrag. |  |
| MT-28 | Projekte | Optionales Modul Projekte wählen. | Projekte, Aufgaben, Planungszeilen, Verbrauch, ungebuchte/teil-/vollgebuchte Abrechnung. |  |
| MT-29 | Service | Optionales Modul Service wählen. | Serviceartikel und Serviceauftrag. |  |
| MT-30 | Anlagen | Optionales Modul Anlagen wählen. | Anlage, Anschaffung, erste Abschreibung. |  |
| MT-31 | CRM | Optionales Modul CRM wählen. | Kampagne und Verkaufschance. |  |
| MT-32 | Planungsvorschläge | Optionales Modul Planung wählen. | Planungsvorschläge über Standard-Dispositionsengine. |  |
| MT-33 | Zeitraum und Seed | Zwei Läufe mit gleichem Seed, einmal anderer Seed; Feld „Daten erzeugen ab“ setzen. | Gleiche Eingabewerte bei gleichem Seed (keine gleichen BC-Nummern); Daten im Zeitraum bis gestern; Wareneingang ≤ Verkauf. |  |
| MT-34 | Buchhaltung abstimmen | Sach-, MwSt.-, Artikel-, Wertposten, Lagerwert, Bilanz/GuV gegen Belegzeilen prüfen. | Summen stimmen mit Belegzeilen überein. |  |

## D. Queue, Fehler, Wiederaufnahme

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-40 | Hintergrundbetrieb | Lauf starten, Browser/Client schließen, später öffnen. | Lauf läuft in der Job Queue weiter, Fortschritt sichtbar. |  |
| MT-41 | Pause, Fortsetzen, Abbruch | Laufenden Lauf pausieren, fortsetzen, anderen abbrechen. | Wirkt an Paketgrenzen; erzeugte Ergebnisse bleiben; keine blinde Wiederholung. |  |
| MT-42 | Fehler pro Geschäftsvorfall | Gezielt einen Beleg fehlschlagen lassen (z. B. fehlende Einrichtung). | Nur dieser Vorfall betroffen; unklare Buchungsergebnisse als NeedsReview; unabhängige Vorgänge laufen weiter. |  |
| MT-43 | Kein Doppelbuchen beim Retry | Fehler nach Buchung/vor Checkpoint provozieren, fortsetzen. | Entweder vollständiger Rollback oder gesperrte unklare Arbeit; keine Doppelrechnung/-zahlung. |  |
| MT-44 | Fehlende Rechte | Hintergrundnutzer ohne Standardrechte starten. | Konkreter Befund statt stiller Fehler. |  |
| MT-45 | Modulare Läufe | Nur Stammdaten, danach nur Einkauf/Verkauf auf bestätigten Stammdaten desselben Mandanten. | Quelle wird wiederverwendet; Laufart wird in Zusammenfassung/Dashboard gezeigt. |  |

## E. Dashboard, Monitoring, Ergebnisse

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-50 | Dashboard öffnen | Rolle/Profil „BC Scenario Factory“ bzw. Dashboard öffnen. | Drei Ansichten (Generierung, Mandantendaten, Läufe), aktualisiert sich im Hintergrund ohne Flackern. |  |
| MT-51 | Kacheln und Drilldowns | Kachel anklicken (Debitoren, Rechnungen, Zahlungen …). | Öffnet die gefilterte BC-Liste mit der angezeigten Menge, sofern berechtigt. |  |
| MT-52 | Detail-Overlay | Modulkarte öffnen; Esc, Klick außerhalb, Schließen. | Overlay schließt jeweils; Fokus und Scroll bleiben erhalten. |  |
| MT-53 | Laufmonitor | Laufmonitor öffnen: Status, Schrittfortschritt, Batches, Statushistorie. | Werte entsprechen dem Lauf; Aktionen nur im passenden Zustand. |  |
| MT-54 | Qualitätsabschluss | Abgeschlossenen Lauf: Validierungsergebnisse öffnen. | Pflichtprüfungen Bestanden; Warnungen separat; Herkunft je Ergebnis nachvollziehbar. |  |
| MT-55 | Sprache | Sitzung Deutsch, dann Englisch: Einrichtung, Assistent, Dashboard, Fehlermeldungen. | Alle Texte in der Sprache; keine unübersetzten Texte. |  |
| MT-56 | Tastaturbedienung | Dashboard nur per Tastatur bedienen. | Fokus sichtbar, Aktionen erreichbar. |  |

## F. Konfigurationspaket und Test-App

| ID | Funktion | Schritte | Erwartetes Ergebnis | Ergebnis |
| --- | --- | --- | --- | --- |
| MT-60 | Datenexportpaket | Dashboard → Datenexportpaket vorbereiten (aktuelle Firma) → Nach Excel exportieren. | Paket BCSF-ALL-DATA mit Tabellen der aktuellen Firma (docs: 128 Tabellen); Blatt je Tabelle. |  |
| MT-61 | Test-App ausführen | Test-App `tests/SF019` veröffentlichen, alle Tests im AL Test Tool ausführen. | Im Code gezählt: 79 Testmethoden; Ergebnis hier eintragen. Referenzmethoden brauchen einen abgeschlossenen kleinen Lauf. |  |
| MT-62 | Upgrade eines Altstands | Kopie eines Altstands mit normalem Schema-Sync aktualisieren. | Historische Läufe, eigene Vorlagen, archivierte Starter erhalten; kein ForceSync. |  |

