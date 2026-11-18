# Testanleitung – vom ersten Start zu 19 Testpartnern

**Stand:** 18.11.2026, Quellarchiv `BC Scenario Factory(4).zip` bis SF-018.  
**Erstes Ziel:** In einer isolierten **Playground-Sandbox-Testfirma** genau 12 Debitoren und 7 Kreditoren erzeugen, ihren Lauf wiederfinden und das Ergebnis erklären können. Keine Artikel oder Belege konfigurieren. Kein Posting aktivieren.

## T00 · Aktuelle Version bauen und öffnen

1. In VS Code den Projektordner mit `app.json` öffnen. In `.vscode/launch.json` Tenant, SaaS-Sandbox und Ziel `Playground` prüfen. Die Erstinitialisierung legt den erlaubten Umgebungsnamen fest auf `Playground`; eine anders benannte Sandbox ist kein direkter Ersatz.
2. **AL: Download Symbols** gegen deine Ziel-Sandbox ausführen. Dann **AL: Package** bzw. den Compile-and-Package-Befehl ausführen. **Nicht** die alte `.app` aus dem ZIP installieren. Sie enthält SF-018 nicht. Nur das neue vollständige Paket in die freigegebene Sandbox veröffentlichen. Kein RAD-Publish für einen Sprach-/Ressourcen-Abnahmetest. [Microsoft: Einstieg in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started) · [Microsoft: AL-Tastenkürzel](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-keyboard-shortcuts).
3. In BC im richtigen Testmandanten **Generator Catalog** / **Generatorkatalog** öffnen. Erwartet: echte Bindungen `CUSTOMER` und `VENDOR` neben `PROBE.CUSTOMER` und `PROBE.VENDOR`. Die Probes sind keine Mastergeneratoren. Fehlen die echten Bindungen, nicht mit T01 weitermachen. Installation, gestarteten Mandanten und Paketstand abgleichen.
4. Das **Scenario-Factory-Dashboard** über BC-Suche öffnen. Optional unter **Meine Einstellungen** die Rolle **BC Scenario Factory** wählen und die Startseite neu öffnen. Die Rollenauswahl ersetzt keine Berechtigungen. Als Alternative steht der native **Scenario-Factory-Laufmonitor** bereit.

**Soll:** Aktuelle Generatoren sichtbar. Dashboard lädt ohne Generierung. Die Liste kann bei einer frischen Firma leer sein.

## T01 · Testfirma vorbereiten

Für den ersten Lauf ist **vorhandene BC-Einrichtung** die bessere Abkürzung, sofern die Testfirma bereits passende Standarddaten hat. Leere Firmen ohne BC-Grundeinrichtung und Finanzpakete separat testen.

| Was | Für 12 + 7 erforderlich |
| --- | --- |
| Rechte | `BCSF ADMIN` für App-Pages/Objekte, **zusätzlich** passende Standardrechte für Debitoren/Kreditoren, Einrichtung, Nummernserien sowie Aufgabenwarteschlange. Bei automatischer Kontakterzeugung auch Standard-Kontakt-/Beziehungsrechte. Dieselben effektiven Rechte beim Queue-Nutzer prüfen. |
| BC-Einrichtung | Sachkonteneinrichtung, Verkauf & Debitoren, Einkauf & Kreditoren sowie Marketing Setup müssen passend vorhanden bzw. lesbar sein. Zahl- und Nummernserien müssen nutzbar sein. |
| Buchungsgruppen bei Existing | Eine konkrete Debitorenbuchungsgruppe mit Forderungskonto und Kreditorenbuchungsgruppe mit Verbindlichkeitskonto, eine allgemeine Geschäftsbuchungsgruppe und eine MwSt.-Geschäftsbuchungsgruppe auswählen. Forderungs- und Verbindlichkeitskonto dürfen nicht gesperrt sein, müssen Buchungskonten sein und `Direkt buchen = Nein` haben. |
| Testland und Zahlbedingungen | Vorhandenes Land, z. B. `DE`; für SKR-Varianten zwingend `DE`. Je eine vorhandene Bedingung ohne Skonto für klein, mittel, groß. Für Privatkundenanteil > 0 zusätzlich eine sofort fällige Bedingung ohne Skonto. Die drei Klassenbedingungen dürfen nicht rückwirkend fällig sein. |
| Nummernserien | Automatische Debitoren- und Kreditorennummern mit freier nächster Nummer passend zum Startdatum. Manuelle Nummern allein reichen für den Generator nicht. Bei BC-Kontaktautomatik die im Marketing Setup eingetragene Kontaktnummernserie und Geschäftsbeziehung prüfen. |

1. **Scenario-Factory-Einrichtung** (`Scenario Factory Setup`) suchen und **Einrichtung initialisieren** wählen. Erwartet: Testfirma und `Playground` werden gespeichert, Generierung und Posting sind zunächst aus.
2. **Generierung aktiviert** (`Generation Enabled`) bewusst einschalten. **Posting Enabled** aus lassen. Für den Test reicht das Standard-Paketlimit, die konkrete Paketgröße kommt in T02.

**Soll:** Setup vorhanden, richtige Firma gebunden, Posting aus. Keine Standardpartner durch diese Schritte erzeugt.

## T02 · Szenario und Lauf anlegen

Im JS-Dashboard **Neues Szenario** wählen oder in der Szenarienliste **Neues Szenario mit Assistent**. Der Assistent speichert bereits eine Vorlage. Wenn du ihn schließt, kann der Entwurf erhalten bleiben.

| Assistent | Eingabe |
| --- | --- |
| 1 · Branche und Zweck | Beschreibung `SMOKE-SF018-12-7`, Profilcode `TRADE`, Profilversion `1`, Nutzungszweck Demo. `TRADE` ist hier nur ein eigenes Kennzeichen, kein geladenes Branchenpreset. |
| 2 · Module | Nur **Verkauf** und **Einkauf** für diesen Test aktivieren. Kein Warehouse oder zusätzliches Fachmodul. |
| 3 · Zielmengen und Regeln | Zielzeilen **Debitor** = 12 und **Kreditor** = 7. Beide auf **Einrichtung und Stammdaten** lassen. Keine weiteren positiven Ziele. Start- und Enddatum = ein gültiges Arbeitsdatum; Paketgröße **5**, Seed **42**, Datensprache Deutsch. |
| 3 · Synthetische Partner | Land `DE`, die vier vorhandenen Gruppen aus T01 und die drei Klassen-Zahlungsbedingungen eintragen. Für den ersten Smoke-Test **B2C = 0** und Standard-Kreditlimits belassen. So brauchst du für diesen ersten Test keine sofort fällige B2C-Bedingung. |
| 4 · Prozessumfang | **Einrichtung und Stammdaten**, **vorhandene BC-Einrichtung verwenden**. Für einen separat angewendeten Testkontenplan entsprechend SKR03/SKR04 wählen. |
| 5 · Prüfen | **Zur Prüfung erfassen** → **Abhängigkeiten prüfen** → **Einrichtungsvorprüfung anzeigen**. Erst bei passender Vorschau weitermachen. |

**Soll:** Ein neuer erfasster Lauf mit 12/7 und echten Generatoren `CUSTOMER`/`VENDOR`. Kein externer unaufgelöster `FINANCE.SETUP`-Knoten für diesen reinen Partnerlauf bei erfolgreichem Vorbedingungencheck. Es wurden noch keine Jobs oder Partner angelegt. Wenn du etwas an den Eingaben korrigieren musst, einen neuen Lauf erfassen. Ein einmal gespeicherter Plan desselben Laufs wird nicht umgeschrieben.

## T03 · Starten und Ergebnis nachweisen

1. Im letzten Assistentenschritt **Sandboxausführung freigeben** bestätigen und **Freigeben und einplanen** wählen. Frühester Start leer bedeutet: möglichst bald, nicht sofort garantiert. Bestätige den Dialog. Der Assistent speichert den Plan, bereitet die Pakete vor und plant den Lauf ein. Du musst nicht zusätzlich jede technische Dashboard-Aktion klicken.
2. **Erfassten Lauf öffnen** oder Dashboard öffnen, den **richtigen Lauf auswählen** und **Aktualisieren**. Das Dashboard zeigt beim Öffnen standardmäßig den jüngsten Lauf, behält aber eine dort bereits getroffene Auswahl beim Aktualisieren. Es aktualisiert sich nicht automatisch.
3. In **Verarbeitungspakete anzeigen**, im Laufmonitor oder auf der Laufkarte prüfen: 3 Debitorenpakete (5 + 5 + 2), 2 Kreditorenpakete (5 + 2). Nach erfolgreichem Abschluss sind 5 von 5 Paketen bestätigt. Die Schritte ergeben 12 bzw. 7, jeweils 0 offen.
4. Auf der Laufkarte **Erstellte Ergebnisse anzeigen** (`View Generated Results`) oder im Dashboard die Herkunft des ausgewählten Laufs öffnen. Auf **19 führende Einträge** prüfen und beispielhaft **Ergebnisidentität prüfen**. Die tatsächlichen Datensätze separat in den BC-Standardlisten **Debitoren** und **Kreditoren** prüfen (Nummer/Datensatzschlüssel aus der Herkunft, Testname und Werte). Nicht erwarten, dass jede Herkunftszeile die Standardkarte öffnet.
5. Auf der Laufkarte oder im nativen Laufmonitor in der Faktbox **Gesamtqualität** öffnen. Erwartet: insgesamt bestanden und ein Pflichtbefund je Paket (`REQUIRED-OUTPUT`), plus Laufzusammenfassung. Ausführungsstatus **Abgeschlossen**. Haben Standardtrigger zusätzliche Kontakte erstellt, zählen sie nicht zu den 19 führenden Ergebnissen.

| Hängt bei … | Das zuerst prüfen |
| --- | --- |
| Beim Erfassen | Profilcode/-version, positives Ziel bzw. korrekte Modul-/Zielbindung, bei SKR bereits angewendetes Paket. |
| Vorprüfung blockiert | Einzelne Zeile mit Blocker lesen. Häufig: falscher Modus, Land/Terms/Marketing Setup fehlt, Nummernserie nicht verwendbar, Konto direkt bebuchbar/gesperrt, Rechte oder keine Generierungsfreigabe. Nach Snapshot-Drift ggf. neu erfassen. |
| Vorbereitet, aber ohne Job | In der Laufkarte **Schedule Prepared Execution** bzw. im Wizard die ausdrückliche Freigabe verwenden. Nur Vorbereiten startet nicht. |
| Eingeplant oder Warteschlange | Startzeit, Standard-Aufgabenwarteschlange und Protokoll prüfen. Job-Kategorie `BCSF.SER` und Worker `BCSF Batch Worker`. Ein abgeschlossener Lauf muss keinen aktuellen Queue-Eintrag mehr haben. |
| Fehlgeschlagen / Prüfung nötig | Pakete → Statushistorie → Queue-Protokolle. Nicht vorsorglich denselben Job neu starten. Bei übernommener Arbeit erst Checkpoint und Sitzung prüfen. |
| Valider Lauf und trotzdem leere Anzeige | Lauf-ID, Mandant, aktuelle Auswahl und **Aktualisieren** prüfen. Native Laufkarte/Laufmonitor zur Gegenprobe. |

## Weitere Sandbox-Tests nach dem Smoke-Test

| ID | Startzustand und Aktion | Erwarteter Nachweis |
| --- | --- | --- |
| T04 · Einrichten ohne Mutation | Finanzmodus Existing in **Finanzeinrichtung prüfen** ansehen. Vorher/Nachher Gruppen, Konten und Serienstand vergleichen. Separat den Lauf ohne Start vorprüfen. | Vorschau und Vorprüfung verändern keine Standarddaten und verbrauchen keine Nummer. Der separate Finanz-Check kann breitere Voraussetzungen melden als ein reiner Partnerlauf. |
| T05 · Partnerdaten und Sprache | Neuen kleinen Lauf mit B2C 100 % und sofort fälliger Bedingung erfassen. Weitere Probe B2C 0 %. UI-Sprache und Datensprache getrennt testen. Gleiche Konfiguration/Seed mit anderer Paketgröße neu erfassen. | B2C 100 % → Debitoren Person, 0 % → Firma, Kreditoren Firma. E-Mail-Domain `example.invalid`. Gleiche logische Schlüssel und Regeln ergeben gleiche synthetische Eingabewerte, neue BC-Nummern sind normal. 15 % später nur mit größerer Stichprobe beurteilen. |
| T06 · Blocker sichtbar | Neue Kopie der Vorlage mit einem positiven Artikelziel (passendes Modul aktivieren), alternativ separate Kopie mit fehlender Zahlungsbedingung oder inkompatiblem Konto. Vorschau/Start prüfen. | Klarer Blocker, kein Job bzw. keine neue führende Einheit. Nicht mit einer produktiven Firma testen. |
| T07 · Pause und Abbruch | Separaten Testlauf mit Startzeit in Zukunft oder mehrere Pakete. Pause anfordern/anwenden, Zustand prüfen und aus bestätigten Paketen fortsetzen. Abbruch in **anderem** Lauf prüfen. | Sicherer Übergang an Paketgrenze, keine zusätzlichen Partner aus bestätigten Paketen. Abgebrochene Arbeit ist nicht wiederaufnehmbar und vorhandene Ergebnisse bleiben. |
| T08 · Review und Rechte | Nur als gezielte Abnahme in isoliertem Mandanten. Rechte vor Start entziehen bzw. dokumentierten Queue-Fehler untersuchen. Paketliste und Standardprotokoll vergleichen. | Guard greift, keine stillen Rechteerhöhungen. Nur nie übernommene Fehler nach Prüfkriterien wiederholen. Unsicheres Paket ohne passenden Checkpoint bleibt gesperrt. |
| T09 · SKR03/SKR04 | Zwei **getrennte** unbebuchte Sandbox-Testfirmen mit Standardgrundsetup. Im Setup **Finanzeinrichtung prüfen** → Paket → Vorschau → **Testpaket anwenden**. Je Paket erneut prüfen/anwenden, bevor Finanzfälle gebucht werden. | Paketcode `BCSF03` bzw. `BCSF04`, 14 Konten im Paket, keine Duplikate oder stilles Überschreiben. Konflikte sichtbar. Initialanwendung bei vorhandenen Sachposten/Paketwechsel blockiert. Für den Partnerlauf Paket im Wizard auswählen, DE und Zahlbedingungen bleiben explizit erforderlich. |
| T10 · Finanzberichte | Nur nach T09, in den getrennten Testfirmen. Standardbuchblatt und je eine Standard-Einkaufs-/Verkaufsrechnung gemäß [Beispiel](../VALIDATION_FINANCE.md#bc-abnahme--noch-nicht-ausgeführt) buchen. | Standardberichte `SF03-BS/PL` bzw. `SF04-BS/PL`. Dokumentiertes Beispiel nach Lagerkostenbuchung: Aktiva 1.227,50 EUR, GuV −80,00 EUR. Das ist ein manueller SF-017-Test, kein automatischer Dokumentgenerator. |
| T11 · Dashboard-UX | Leerer und befüllter Zustand, Lauf wechseln, Status/Aktionen mit Maus und Tab/Enter prüfen, Fenster schmal machen, bei Aktion ohne gültigen Kontext auf Rückmeldung achten. Zweitsprache EN testen. | Navigationstasten und Laufauswahl funktionieren. Heute sind Kacheln und Tabellenzeilen passiv. Unklare Labels, Sackgassen und Klickanzahl bis zum Ergebnis festhalten. [Klickmatrix](DASHBOARD-REVIEW.md#was-heute-klickbar-ist). |

## Was in diesem Review tatsächlich geprüft wurde

- Quell-/Paketabgleich, Objekt-/Modulinventar, Wege aus AL/JS verfolgt. SF-018 fehlt in der beigepackten `.app`.
- `python3 scripts/check_translations.py` → PASS für 1.116 Einheiten in sechs Zielsprachen. `python3 scripts/build_dashboard_translations.py --check` → PASS. `node --check` für `dashboard.js` und `startup.js` → PASS.
- `scripts/check_dashboard.mjs` versucht. Lokale Chromium-Debug-Schnittstelle startete nicht, deswegen in **diesem** Review kein browsergestützter UI-Test. Vorhandene Projektprotokolle früherer Builds sind keine neu ausgeführten Tests.
- Kein AL-Compiler im Review-Workspace, kein BC-Deployment, keine Sandbox-, Rollen-, Queue-, Posting-, Last- oder echte UI-Abnahme. T00–T11 sind Anleitungen, nicht bestandene Tests. XERJ in diesem Review nicht benutzt, maßgeblich ist das aktuelle Archiv.

## Vorlage für Tester und Agents

| Datum / BC-Version / App-Build | Testfall / Mandant / Lauf-ID | Soll | Ist und Nachweis | Status |
| --- | --- | --- | --- | --- |
| YYYY-MM-DD / … | T03 / … | 12 + 7, 5/5 und Validierung bestanden | … | Offen |

Bei neuen Tickets Fall-ID ergänzen, unveränderte IDs stehen lassen. Ergebnis und Befunde erst nach echter Durchführung eintragen. Keine Tenant-/Kundendaten, Zugangsdaten oder echten Beleginformationen ins Repo übernehmen.
