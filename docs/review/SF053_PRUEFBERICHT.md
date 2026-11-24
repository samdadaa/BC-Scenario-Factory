# SF-053 – Lagerbewegungen, Inventur und Umlagerung ohne WMS 

**23.11.2026 · App-Version unverändert (1.0.12.0) · Zur Prüfung .** Ausdrücklich beauftragt: SF-053 (XERJ-Index `bcsf-docs` für Suche genutzt). Kein Commit, kein Deployment. **Nicht kompiliert** (AL-Compiler braucht .NET 10, vorhanden 8.0.8), keine AL-Testausführung, keine native Sandbox.

## Umsetzung
Kein neuer Entitätsgenerator: der vorhandene Einkaufsgenerator erzeugt in der **Folgeprozess-Stufe** (mit Zahlungsfreigabe, nach Zahlung und Gutschrift) zu gebuchten Einkaufsrechnungen deterministisch (Seed, `paymentSetup.inventoryVersion = 1`) **eine Bewegungsart für alle Artikelzeilen** der Rechnung (Codeunit `BCSF Inventory Movement Processor` 90482):

| Anteil | Bewegung | Standardweg |
| --- | --- | --- |
| 45 % | keine | – |
| 10 % | Zugang (Kosten = Artikelstückkosten) | Artikelbuchblattzeilen (temporär) über `Item Jnl.-Post Line` |
| 10 % | Abgang | wie oben |
| 10 % | Inventurdifferenz (Fehlmenge oder Überschuss je Seed; berechneter Bestand zum Buchungsdatum, Herkunftscode Inventurbuchblatt) | Artikelbuchblatt mit Inventurkennzeichen |
| 12 % | Umlagerung Hauptlager → `BCSF-AUX` über Transitlager `BCSF-TRN` | Umlagerungsauftrag, freigeben, `TransferOrder-Post Shipment`/`Receipt` |
| 13 % | Montage (siehe [SF-054](SF054_PRUEFBERICHT.md)); ohne Montage-Marker keine Bewegung | Montageauftrag |

**Mengen:** je Zeile 1–3 Einheiten (Seed), höchstens die Hälfte der geplanten Bestandsreserve der Zeile (Großhandel 12, sonst Basismenge) und höchstens die gebuchte Menge; damit bleibt der Bestand für spätere Verkäufe gedeckt und die Menge ist unabhängig von der Artikelerzeugungsmenge reproduzierbar. Datum zwischen Rechnungsdatum und Periodenende.

**Vorprüfung ohne Schreibzugriff, kontrollierter Skip:** Für Abgang, Fehlmenge und Umlagerung muss der freie Bestand (Bestand zum Datum minus Reservierung minus frühere Zeilen derselben Bewegung) je Lagerort reichen, sonst Skip `STOCK`. Dimensionskombination und Dimensionswertbuchung der Journal-/Umlagerungszeilen werden vor der Buchung geprüft, sonst Skip `DIMENSION` (eine bereits angelegte, noch ungebuchte Umlagerung wird dabei wieder gelöscht). Der Skip steht als `MOVEMENT-SKIP` an der Rechnung (Registry-Regel erweitert), erzeugt die vorhandene Warnung „Buchung übersprungen“ und blockiert keine weiteren Vorgänge.

**Kosten/Wertposten:** Zugänge und Abgänge müssen einen Wertposten haben; Sachposten werden über die Wertposten-Verknüpfung registriert. **Bestand:** nach jeder Buchung und in der Ausgabevalidierung darf der Bestand je Artikel/Lagerort bis zum Bewegungsdatum und insgesamt nicht negativ sein; Umlagerungsmengen werden gegen die Versandzeilen geprüft, Journalmengen und Vorzeichen gegen die Artikelposten je Belegzeile.

**Foundation (additiv):** `PrepareFoundation` legt in der Folgeprozess-Stufe die einfachen synthetischen Lagerorte `BCSF-AUX` und `BCSF-TRN` (Transit) an, falls sie fehlen; vorhandene werden nur geprüft. Die Umlagerung wird nur geplant, wenn bei der Erfassung beide Lagerorte, die Umlagerungs-Nummernserien und der Umlagerungs-Herkunftscode brauchbar waren; Bewegungen bleiben aus, wenn Artikel-/Inventurbuchblatt-Herkunftscode fehlen oder die automatische Kostenbuchung aus ist.

**Herkunft/Nachweis:** `MOVEMENT-n` (je Zeile) bzw. `TRANSFER-SHIPMENT`/`TRANSFER-RECEIPT` plus Artikel-, Wert- und Sachposten (`MOVE-ITEM/-VALUE/-GL`).

## Korrektur nach erstem Lauf (23.11.2026) und Prüfung auf unzulässige Daten
Der Fehler „Länge 12, erlaubt 10: BCSF-TRANSIT“ ist behoben: Lagerortcodes sind `Code[10]`, das Transitlager heißt jetzt `BCSF-TRN` (Hilfslager `BCSF-AUX`). Die Prüfung aller in SF-051 bis SF-054 gesetzten Feldwerte gegen die Feldlängen der Standardtabellen ergab sonst keine Überschreitung (Dokumentnummern `Code[20]`, Herkunftscodes `Code[10]`, Nummernserien `Code[20]`, Ressourcennummer `BCSF-MONT`, IBAN `Code[50]`, Namen `Text[100]`). Weitere Befunde und Korrekturen: (1) Die neuen Lagerorte brauchen für jede verwendete Lagerbuchungsgruppe eine **Lagerbuchungsmatrixzeile**; die Foundation kopiert sie aus einer vorhandenen nutzbaren Zeile derselben Gruppe, und eine Umlagerung wird nur geplant, wenn beide Lagerorte solche Zeilen haben. (2) Die Belegnummer der Bewegung (`M` + Rechnungsnummer) schneidet bei voller Länge nicht mehr das unterscheidende Ende ab.

## Korrektur „Vorhandene gültige BC-Einrichtung“ (23.11.2026)
Meldung: „fehlt eine passende Kontenzuordnung für Lagerbuchung Einrichtung“. Ursache: Die synthetischen Lagerorte `BCSF-AUX`/`BCSF-TRN` sortieren vor den Standardlagerorten und wurden von der Standard-Lagerortauswahl als „erster einfacher Lagerort“ gewählt, obwohl sie (in einer Firma ohne Artikel) keine Lagerbuchungsmatrix hatten. Korrekturen: (1) Alle drei Lagerortauswahlen (Mandanteneinrichtung, Stammdatenquelle, Artikeleinrichtung) schließen die synthetischen Lagerorte aus; die Mandanteneinrichtung bevorzugt einen einfachen Lagerort, dessen vorhandene Lagerbuchungsmatrix bereits ein nutzbares Lagerkonto hat. (2) Die Lagerbuchungsmatrix der synthetischen Lagerorte wird je vorhandener Lagerbuchungsgruppe angelegt, nicht nur für Gruppen mit Artikeln. (3) Alle optionalen Voraussetzungen der Folgeprozesse – Umlagerungs-/Montage-Nummernserien, Herkunftscodes, Lagerorte, Matrixzeilen, Ressource – füllen nur leere Einstellungen, prüfen vorhandene Werte nie streng und blockieren bei fehlender Berechtigung die Mandanteneinrichtung nicht. (4) Gutschriften werden nur noch aktiviert, wenn Nummernserien und Einstellungen sie unterstützen (statt den Start zu verhindern).

## Dashboard und Querschnitt
Neue Ergebniskacheln **Gebuchte Umlagerungslieferungen/-eingänge**; Artikel- und Wertposten sowie Sachposten erscheinen in den vorhandenen Kacheln. Einrichtung: Foundation/Capture wie oben. Übersetzungen: fünf neue Texte in `Translations/sf053.de.json`; nach erstem Build `python3 Translations/sync_sf_translations.py` und `python3 scripts/build_dashboard_translations.py`, neu bauen.

## Dashboard (Korrektur)
Die Kacheln stehen jetzt in den eigenen Datengruppen **Lagerbewegungen** bzw. **Montage** und im Laufergebnis als Modulkarte (siehe [DASHBOARD_DATA_STOCK.md](../DASHBOARD_DATA_STOCK.md#modulkacheln-im-laufergebnis-23112026)). Kacheln erscheinen nur bei vorhandenen Datensätzen aus dem Lauf.

## Abgrenzung (andere Tickets)
Lagerplätze/WMS (SF-028), Chargen-/Seriennummernartikel (Einkaufsgenerator lässt sie ohnehin nicht zu), Direktumlagerung und Fremdlagerorte als Umlagerungsziel.

## Native Prüffälle
L01 Folgeprozesslauf klein: alle fünf Bewegungsarten, Artikel-/Wert-/Sachposten, Bestand je Lagerort. L02 Existing-Firma. L03 Ohne Umlagerungs-Nummernserie: keine Umlagerungen, kein Fehler. L08 Reservierter/knapper Bestand und gesperrte Dimension: Skip `STOCK`/`DIMENSION` mit Warnung, Lauf läuft weiter. L09 Mehrzeilige Rechnungen mit gleichem Artikel auf zwei Zeilen, zwei Läufe hintereinander. L04 Wiederanlauf ohne Doppelbuchung. L05 Verkaufsbestand nach Bewegungen weiterhin gedeckt (keine neuen STOCK-Skips). L06 Dashboard-Kacheln, DE/EN. L07 Rechte (Item-/Transfer-Posting).
