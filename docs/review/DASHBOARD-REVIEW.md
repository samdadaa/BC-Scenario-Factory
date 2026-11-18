# Dashboard-Review – vom technischen Cockpit zum Arbeitsablauf

**Urteil:** Ein zentraler Einstieg ist sinnvoll, aber aktuell präsentiert er die interne Architektur. Auf einem ausgewählten Lauf stehen bis zu **19 Aktionen** (acht Planung, sechs Ausführung, fünf Ergebnisse), zusätzlich acht Seiteneinstiege, vier Kennzahlen, die Laufauswahl und die native Role-Center-Navigation. Die wichtigste Frage bleibt offen: „Was mache ich jetzt?“

Dieses Review basiert auf der AL-/JS-Implementierung. Optik, Farben und Bedienung in deiner BC-Sitzung sind nicht neu visuell abgenommen.

## Was heute klickbar ist

| Element | Ist im aktuellen Code | Verbesserung |
| --- | --- | --- |
| **Neues Szenario**, **Aktualisieren** | Echte Buttons. Neu speichert bereits die Vorlage und öffnet den Wizard. Aktualisieren lädt die aktuelle Auswahl. | Eine primäre Aktion. Aktualisieren sekundär; gespeicherte Entwürfe als solche zeigen. |
| Linke Navigation | Acht echte Buttons. Öffnen getrennte BC-Seiten wie Vorlagen, Läufe, Ausführungen, Pakete, Herkunft, Katalog, Setup und Laufmonitor. | Vorne **Vorlagen**, **Läufe**, **Einrichtung**. Technik unter **Diagnose** oder auf der Laufkarte. Die gleiche Info nicht dreifach verlinken. |
| Vier Kennzahlkacheln | Statische `div`-Elemente, kein Klick. Aktiv zählt Queued/Scheduled/Running/ResumePending. Review zählt Failed/ValidationFailed, nicht alle blockierten Entwürfe, Pausen oder Warnungen. | Nur dort einen Link anbieten, wo ein sinnvolles gefiltertes Ziel existiert. „Handlungsbedarf“ nicht als Label verwenden, solange das Filtermodell diese Fälle nicht abdeckt. Passive Werte ohne Klickoptik. |
| Letzte Läufe | Dropdown wechselt Auswahl, öffnet keine Laufkarte. 25 jüngste Läufe plus ggf. ausgewählter älterer Lauf. | Kompakte Liste mit Status und sichtbarem **Öffnen**. Link **Alle Läufe** behalten. |
| Laufkopf, Status, Qualität | Anzeige. Kein Validierungsdrilldown im JS, aber in der nativen Lauf-Faktbox. | **Prüfergebnisse** direkt verlinken. Vollständige GUID nur in Diagnose. |
| Schrittzeilen und Fortschritt | Nur Text und Fortschrittsbalken. Externe Checks zeigen statt konkreter Ursache einen allgemeinen Hinweis. | Bei Blocker **Grund anzeigen**, nach Abschluss **Debitoren (12)** und **Kreditoren (7)** als Links auf die für diesen Lauf gefilterten Ergebnisse. |
| Plan-, Ausführungs-, Ergebnisbuttons | Echte Buttons, in JS ohne fachliche Statussteuerung. Bei einem Aufruf werden alle vorübergehend deaktiviert. AL-Guards lehnen ungültige Aktionen ab. Queue-Link kann nach Abschluss erwartbar scheitern. | Eine passende Hauptaktion je Zustand. Ungültige Aktionen ausblenden oder den Grund direkt am Button zeigen. AL-Prüfungen bleiben. |
| Native Details | In der Lauf-Faktbox gibt es Drilldowns für Gesamtqualität und bestimmte Paketzähler. Herkunftsliste kann die Identität prüfen, nicht jede Partnerkarte direkt öffnen. | Den fachlich passenden Einstieg aus dem Dashboard anbieten, technische Detailseiten weiter behalten. |

Die Aktionsgruppen stehen **unterhalb der Schritttabelle**. Je mehr Daten sie anzeigt, desto weiter unten steht die Startaktion. Statt generischer Fehlerrückmeldung nur im Footer gehört der konkrete Blocker direkt in den Bedienbereich.

## Begriffe

| Heute | Vorschlag | Unterschied, der bleiben muss |
| --- | --- | --- |
| Szenario, erfasster Lauf, Ausführung | **Vorlage** und **Lauf** | Vorlage editierbar, Lauf fixiert. „Ausführung“ bleibt technisch getrennt, muss kein drittes Navigationsziel sein. |
| Snapshot / Erfassen | **Lauf prüfen** | Erstellt eine unveränderliche Aufnahme. Nach Änderung muss ein neuer Lauf geprüft werden. |
| Abhängigkeiten / Einrichtungsvorprüfung / Bereitschaft | **Vor dem Start prüfen** | Getrennte fachliche Prüfbereiche auf einer Seite. Pro Problem sagen, was fehlt und wie man es korrigiert. |
| Entität / Artefakt / bestätigt | **Datentyp** / **erstellte Ergebnisse** / **geprüfte Einheiten** | Ein logischer Fall kann mehrere Datensätze erzeugen. Beim Partner läuft heute 1 Einheit auf 1 führendes Ergebnis hinaus. |
| Queue / Batch / Herkunft | **Aufgabenwarteschlange** / **Verarbeitungspaket** / **Ergebnisnachweis** | Begriffe für Diagnose, nicht für den ersten Nutzerpfad. |
| Gesamtqualität | **Abschlussprüfung** | Klar getrennt vom Fortschritt. Kein „fertig“, bevor Pflichtprüfungen bestanden sind. |

## Zielbild für die nächste Iteration

1. **Testpartner anlegen.** Auf der Startseite prominent. Nur Anzahlen für Debitoren und Kreditoren sowie Datensprache abfragen. Seed, Paketgröße, B2C und Kreditlimits unter **Erweitert**. Kein Branchenpreset vortäuschen.
2. **Einrichtung prüfen.** Bewusst gewählte Gruppen und Zahlungsbedingungen je Mandant wiederverwenden. Keine willkürliche erste Gruppe. Fehlendes als konkrete Liste anzeigen. Den SKR-Pfad separat lassen.
3. **Prüfen & starten.** Zusammenfassung „12 Debitoren und 7 Kreditoren, keine Buchungen“, eine Bestätigung. Intern weiterhin Snapshot, Plan, Guards und Queue.
4. **Ergebnis öffnen.** Ansicht mit Status, zwei Ergebniszahlen und einer nächsten Aktion: Blocker erklären, Fortschritt ansehen oder die richtigen Datensätze öffnen. Pause/Abbruch nur im passenden Zustand, Diagnose aufklappbar.

## Priorität und Abnahme

| Prio | Arbeit | Woran du die Verbesserung erkennst |
| --- | --- | --- |
| P0 | SF-018-Smoke aus aktuellem Build | T00–T03 in einer Sandbox protokolliert. 12/7, 5/5 Pakete, Ergebnisse und Prüfung sichtbar. |
| P1 | Partnerpfad und Begrifflichkeiten | Erster Lauf ohne Kenntnisse von Queue, Snapshot und Registry. Primäre Aktion bleibt ohne Scrollen erkennbar. |
| P1 | Blocker und Ergebnisse mit Drilldowns | Ein konkreter Blocker zeigt Handlung oder passende Einrichtung. Zwei Ergebnislinks öffnen genau die Partner dieses Laufs. Tastaturbedienbar. |
| P2 | Visueller Feinschliff | Zwei Personen schaffen den ersten Lauf ohne Hilfe. Schmale Ansicht, DE/EN, Tastatur und Fokus explizit prüfen. |
| Danach | SF-019 und ein kleiner fachlicher End-to-End-Fall | Einen belastbaren Artikel-/Belegpfad nachweisen, bevor immer mehr Module im Standardpfad auftauchen. |

**Behalten:** Registry, unveränderliche Snapshots, Statusmaschine, Sandbox-/Rechteprüfung, Checkpoints und Abschlussvalidierung. Diese Logik löst echte Risiken und muss im normalen Nutzerpfad nicht dauerhaft sichtbar sein.

Belege: [Renderpfad](../../src/Monitoring/Dashboard/dashboard.js), [Styles](../../src/Monitoring/Dashboard/dashboard.css), [Datenprojektion](../../src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al), [Befehle](../../src/Monitoring/Codeunits/BCSFDashboardCommands.Codeunit.al), [native Faktbox](../../src/Monitoring/Pages/BCSFRunOverview.Page.al).
