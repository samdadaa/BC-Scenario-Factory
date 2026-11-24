# SF-056 – Disposition/Planung: Bedarf, Beschaffung und Vorschläge

**24.11.2026 · App-Version unverändert (1.0.12.0) · Zur Prüfung.** Ausdrücklich beauftragt: SF-056 vollständig. Kein Commit, kein Deployment. **Nicht kompiliert** (.NET 10 fehlt), keine AL-Testausführung, keine native Sandbox.

## Umsetzung
Kein neuer Generator: In der **Folgeprozess-Stufe** plant der Verkaufsgenerator (Codeunit `BCSF Planning Processor` 90485, Namespace `BCScenarioFactory.Planning`) zu 45 % der gebuchten Verkaufsrechnungen die verkauften Artikel mit der **Standard-Dispositionsengine** (`Inventory Profile Offsetting.CalculatePlanFromWorksheet`, ohne den Bericht, weil dieser pro Artikel committet). Die Engine verbindet Verkaufsbedarf, vorhandenen Bestand, Meldebestand/Wiederbeschaffungsverfahren und offene Einkaufsaufträge (Deckung) zu **Bedarfsvorschlagszeilen** im eigenen Blatt `BCSFPLAN`/`BCSF`.

- **Planungsparameter:** Es werden keine Stammdaten verändert. Die vom Artikelgenerator gesetzten Parameter (Wiederbeschaffungsverfahren, Meldebestand, Bestellmenge, Lieferant) werden gelesen und geprüft; Fremdstämme ohne Verfahren, ohne Lieferant, gesperrt, mit Chargenpflicht oder Varianten werden nicht geplant (Skip `SOURCE`).
- **Vorschlag ≠ Bestellung:** Es wird **nichts** in Bestellungen umgesetzt; die Umsetzung bleibt eine ausdrückliche spätere Entscheidung (Einstellung fehlt bewusst). Vorschläge stehen im Blatt und werden nur geprüft/angezeigt.
- **Doppelte Deckung vermeiden:** Hat ein Artikel schon Vorschläge im Blatt, wird er nicht erneut berechnet. Eine Zeile gehört der ersten registrierenden Rechnung des Laufs.
- **Ergebnis/Nachvollziehbarkeit:** Herkunft `PLAN-LINE-n` je Vorschlagszeile; ohne Vorschlag dokumentierter Skip `COVERED` (ausreichende Deckung) oder `SOURCE`. Die Ausgabevalidierung prüft Blatt, Artikelbezug zur Rechnung und Menge > 0 (positive Fälle = Unterdeckung) sowie den Skip-Nachweis (negative Fälle = Überdeckung); es wird keine Bestellung aus Vorschlägen erwartet.
- **Zeit/Lagerort:** Planungsfenster ab Rechnungsdatum 90 Tage; Lagerortfilter der Rechnungszeile.

## Foundation (additiv)
Bedarfsvorschlagsvorlage `BCSFPLAN` (Typ Bedarfsanforderung) und Blatt `BCSF` werden angelegt, falls fehlend; vorhandene Vorlagen/Blätter bleiben unverändert; ohne Berechtigung entfällt die Funktion ohne Abbruch (`paymentSetup.planningVersion = 1`).
**Advanced Planning/Fertigung:** nicht Teil von SF-056 (SF-029); Produktionsplanung wird nicht berechnet.

## Dashboard und Querschnitt
Datengruppe **Planung** (Dispositionsvorschläge) und Modulkarte **Planung**; Übersetzungen in `sf055.de.json`/`sf054.de.json`.

## Native Prüffälle (Soll)
D01 Verkauf mit Meldebestand-Unterschreitung: Vorschlagszeilen, Menge/Fälligkeit plausibel, keine Bestellung. D02 Genügender Bestand: Skip `COVERED`. D03 Zweiter Verkauf desselben Artikels: keine doppelte Deckung. D04 Fremdartikel ohne Wiederbeschaffungsverfahren: Skip `SOURCE`. D05 Frische SKR03/04- und Standardfirma. D06 Wiederanlauf. D07 Dashboard/DE-EN/Rechte.
