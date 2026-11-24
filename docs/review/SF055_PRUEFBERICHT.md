# SF-055 – Projekte (Jobs): Stammdaten, Verbrauch und Abrechnung

**24.11.2026 · App-Version unverändert (1.0.12.0) · Zur Prüfung.** Ausdrücklich beauftragt: SF-055 vollständig (AGENTS.md und Dokumentation gelesen, XERJ-Index `bcsf-docs` genutzt). Kein Commit, kein Deployment. **Nicht kompiliert** (AL-Compiler braucht .NET 10, vorhanden 8.0.8), keine AL-Testausführung, keine native Sandbox.

## Umsetzung
Kein neuer Entitätsgenerator: In der **Folgeprozess-Stufe** erzeugt der Einkaufsgenerator zu 13 % der gebuchten Einkaufsrechnungen ein Projekt (Teil des Bewegungsplans aus SF-053, neue Codeunit `BCSF Project Processor` 90484, Namespace `BCScenarioFactory.Projects`):

1. **Stammdaten (Standard-Tabellen):** Projekt mit Nummernserie, Debitor aus demselben Lauf, natürlichem Namen je Datensprache (z. B. „Heizungsmodernisierung Köln“), Laufzeit 20–120 Tage (Seed), Status Offen, Verbrauchsverknüpfung; zwei Aufgaben (*Materiallieferung*, *Montage und Inbetriebnahme*); Planungszeilen *Budget und Fakturierbar*: Material = erste ein bis zwei Artikelzeilen der Rechnung, Ressourcenzeile mit der synthetischen Montageressource `BCSF-MONT`, wenn nutzbar.
2. **Modi per Seed** (je ¼): (1) nur Projekt und Planung; (2) Verbrauch über Projektbuchblatt gebucht, **Rechnung aus Planungszeilen ungebucht**; (3) Verbrauch gebucht und **Teilabrechnung** (halbe Menge, gebucht); (4) Verbrauch gebucht und **Vollabrechnung** gebucht. Verbrauch über `Job Jnl.-Post Line` (temporäre Zeile, Commit unterdrückt), Abrechnung über `Job Create-Invoice.CreateSalesInvoiceLines` (kein Bericht, kein Commit) und Standard `Sales-Post`.
3. **Nachweis/Soll-Ist:** Herkunft `PROJECT`, `PROJECT-TASK-n`, `PROJECT-PLAN-n`, Projektposten (Verbrauch und Verkauf), Artikel-/Wert-/Sachposten, Ressourcenposten, Rechnung samt Debitoren-/Sach-/MwSt.-Posten. Die Ausgabevalidierung gleicht Projekt, Termine, Planungsmengen, gebuchte Menge (`Qty. Posted`), Projektposten, abgerechnete Menge und Bestand je Lagerort/Datum mit dem Plan ab.

**Vorprüfung ohne Schreibzugriff, kontrollierter Skip:** `SOURCE` (Nummernserie fehlt, kein Debitor des Laufs, Fremdwährungsdebitor, Komponente gesperrt/Chargenpflicht/Varianten), `STOCK` (freier, nicht reservierter Bestand reicht nicht, nur bei Verbrauch), `DIMENSION` (Dimensionskombination der Buchblattzeilen). Verbrauch nutzt dieselbe Mengengrenze wie die Lagerbewegungen (höchstens die Hälfte der Bestandsreserve), damit spätere Verkäufe gedeckt bleiben. Phasen/Rechte: nur Status *Offen*, Posting-Codeunit- und Tabellenrechte werden vorab geprüft; fehlende Ressourcenkapazität erzeugt keine Scheinbuchung (die Ressourcenzeile entfällt, wenn die Ressource nicht nutzbar ist). Projekte sind vollständig von Service Management getrennt.

## Foundation (additiv, nur leere Einstellungen)
Projektnummernserie `JOB` und Herkunftscode `JOBJNL` (nur falls leer), VAT-Produktbuchungsgruppe der eigenen Ressource (aus einem Artikel derselben Produktgruppe). Das Projekt wird nur geplant, wenn bei der Erfassung Projekteinrichtung, Herkunftscode, Ressource und automatische Kostenbuchung brauchbar sind (`paymentSetup.projectVersion = 1`).

## Dashboard und Querschnitt
Neue Datengruppe **Projekte** (Projekte, Aufgaben, Planungszeilen, Verbrauchs- und Verkaufsposten) und Modulkarte **Projekte**; Rechnung und Buchungsposten erscheinen in den vorhandenen Verkaufs-/Finanzkacheln. Übersetzungen: `Translations/sf055.de.json` und `sf054.de.json` (Sync-Skripte nach dem ersten Build).

## Abgrenzung
Kapazitätsprüfung der Ressource (Kapazitätseinträge) und vom Einkaufslauf unabhängige Abrechnungsläufe für vorhandene Projekte sind nicht umgesetzt (im TODO offen). WIP/Ertragsrealisierung, Mehrstufige Aufgabenstrukturen, Projektpreise, Kontingente, Service Management (SF-030).

## Native Prüffälle (Soll)
P01 Folgeprozesslauf klein: alle vier Modi, Projektliste, Aufgaben, Planungszeilen, Projektposten, Rechnung ungebucht/gebucht, Debitoren-/Sach-/MwSt.-Posten. P02 Frische SKR03/SKR04-Firma und Standardfirma mit Einrichtungsdaten (Jobs Setup, Herkunftscodes). P03 Ohne Projektnummernserie/Berechtigung: keine Projekte, kein Abbruch. P04 Variantenartikel/knapper Bestand: Skip `SOURCE`/`STOCK` mit Warnung. P05 Wiederanlauf ohne Doppelbuchung. P06 Verkaufsbestand bleibt gedeckt. P07 Dashboard, DE/EN, Rechte nur Factory-Rolle.

## Mögliche Fehlerursachen (vorab geprüft)
Feldlängen (Nummern `Code[20]`, Namen `Text[100]`); Datumsregeln (Enddatum nicht vor Start); temporäre Buchblattzeile ohne Vorlage (`Insert()` statt `Insert(true)`); eindeutige Herkunft je Datensatz; fehlende Nummernserien, Herkunftscodes, Ressourcen-VAT-Gruppe; Buchungsmatrix des Debitors für die Ressourcen-Produktgruppe; Bestandsdeckung vor Verbrauch; gleiche Belegnummer für Verbrauch (Projektnummer) ist je Projekt eindeutig.
