# SF-028 bis SF-033 – Optionale Fachmodule: Lager, Fertigung, Service, Anlagen, CRM

**24.11.2026 · App-Version unverändert (1.0.12.0) · Erledigt (Teilumfang): vom Nutzer nativ getestet und abgenommen am 24.11.2026 (SF-028–SF-031, SF-033, SF-051–SF-056). SF-032 bleibt offen.** Ausdrücklich beauftragt: SF-028–SF-033. AGENTS.md, TODO.md und die Dokumentation wurden gelesen; Montage (SF-054), Projekte (SF-055) und Planung (SF-056) lagen bereits vor und sind Teil von SF-029/030/033. Kein Commit, kein Deployment. **Nicht kompiliert** (AL-Compiler braucht .NET 10, vorhanden 8.0.8), keine AL-Testausführung, keine native Sandbox. API-Namen wurden gegen die lokalen BC-28-Symbole (`.alpackages`) geprüft, nicht gegen das Laufzeitverhalten.

## Ergebnis je Ticket

| Ticket | Modul | Umfang | Offen |
| --- | --- | --- | --- |
| SF-028 | Lager | Einkaufsbestellung am synthetischen Lagerort `BCSF-WMS`, Standard-Lagereingang, Einlagerung in Lagerplatz `A-01` | Kommissionierung, Versand, gelenktes WMS |
| SF-029 | Fertigung (+ Montage SF-054) | Fertigungsstückliste, Fertigungsauftrag freigegeben oder gebucht und beendet | Arbeitsplan, Kapazität |
| SF-030 | Service (+ Projekte SF-055) | Serviceartikel und ungebuchter Serviceauftrag | Servicebuchung, Verträge |
| SF-031 | Anlagen | Anlage, Anschaffung, erste Abschreibung über Standardbuchung | Abgang, Klassen, Einrichtung ohne Buchungsgruppe |
| SF-032 | Branchen | **nicht umgesetzt** (bleibt gesperrt) | Fachliche Spezifikation je Branche, native Modulabnahme |
| SF-033 | CRM (+ Planung SF-056) | Kampagne je Lauf, Verkaufschance je Debitorenkontakt | Interaktionen, Segmente, Phasen |

## Gemeinsamer Ablauf (kein neuer Assistent, keine neue Seite/Tabelle)
- **Auswahl:** Die Module sind in der vorhandenen Modulauswahl der Einrichtung wählbar. Die Markierung „nur Planung“ ist entfernt (Seite, Hinweis, Zusammenfassung). Die Auswahl steuert nun die Ausführung: `BCSF Module Selection` (90486) schreibt pro gewähltem Modul eine Markierung in den unveränderlichen Lauf-Snapshot (`crmVersion`, `assetVersion`, `warehouseVersion`, `productionVersion`, `serviceVersion` sowie die vorhandenen Montage-/Projekt-/Planungsmarker). **Verhaltensänderung:** Montage, Projekte und Planung laufen nur noch, wenn sie gewählt sind (bisher immer im Folgeprozess). Gespeicherte Läufe behalten ihren Snapshot.
- **Anbindung:** Einkaufsseite (gebuchte Einkaufsrechnung): Anlagen, Lager, Fertigung. Verkaufsseite (gebuchte Verkaufsrechnung): CRM, Service. Je Geschäftsvorfall deterministisch per Seed (unabhängig von Lauf-ID): Anlagen 15 %, Lager 20 %, Fertigung 12 %, CRM 35 %, Service 20 %.
- **Vorprüfung ohne Schreibzugriff, kontrollierter Skip:** fehlende Nummernserien, Einrichtung, Berechtigung, Kreditor/Debitor oder geeigneter Artikel erzeugen `*-SKIP` mit Grund `SOURCE`/`STOCK` an der Rechnung; nichts wird erfunden. Fertigung bucht Verbrauch nur, wenn die Lagerbewegungen derselben Rechnung die Bestandsreserve nicht nutzen (sonst bleibt der Auftrag freigegeben).
- **Foundation (additiv):** Lagerort `BCSF-WMS` mit Lagerplätzen und Lagerbuchungseinrichtung, Verkaufszyklus `BCSF`, fehlende Nummernserien/Herkunftscodes (nur leere Felder) für Marketing, Anlagen, Lager, Fertigung, Service. Anlagen-Buchungsgruppen, Abschreibungsbuch und Sachkonten werden **nicht** angelegt.
- **Nachweis/Dashboard:** Herkunft `CRM-*`, `ASSET-*`, `WHSE-*`, `PRODUCTION-*`, `SERVICE-*` in der Registry; neue Modulkarten Lager, Fertigung, Service, Anlagen, CRM mit Drilldowns auf die Standardlisten; Ausgabevalidierung gleicht jeden Fall mit dem Plan und den Standardposten ab.
- **Konfigurationspaket (SF-046):** 28 bisher fehlende Tabellen (Montage, Projekte, Planung, Umlagerung, Bankkonten und die neuen Module) in Katalog und Dokumentation ergänzt, der Vertragstest ist wieder grün.
- **Übersetzungen:** `Translations/sf028.de.json` (Sync- und Dashboardskript angebunden); Dashboard-Fallback neu erzeugt. XLF-Synchronisation erst nach dem ersten Build möglich.

## Lokal ausgeführte Prüfungen
`build_dashboard_translations.py` (neu erzeugt), `check_config_export_contracts.py`, `check_partner_catalog.py`, `check_sales_contracts.py`, `check_template_contracts.py`, `check_dashboard.mjs`, `check_dashboard_stock.mjs`: bestanden. **Bereits vor dieser Änderung (letzter Commit) fehlgeschlagen und unverändert:** `check_inventory_contracts.py`, `check_modular_contracts.py`, `check_purchase_contracts.py`, `check_translations.py` (veraltete Vertragsprüfungen bzw. XLF vor dem Build). Test-App: eine Testmethode `OptionalModulePlansAreDeterministicAndNeedTheirMarker` ergänzt (nicht ausgeführt).

## Native Prüffälle (Soll)
W01 Lager: Einkauf klein mit Modul Lager: Lagereingang, Einlagerung, Warehouse-Einträge in `A-01`; W02 ohne Lagermitarbeiter/Nummernserie: Skip `SOURCE`. F01 Anlagen auf Mandant mit Anlagenbuchungsgruppe: Anlage, Anschaffungs- und Abschreibungsposten, Bankposten; F02 ohne Einrichtung: Skip. M01 Fertigung: freigegeben und gebucht/beendet, Verbrauch/Ausgabe, Bestand; M02 knapper Bestand. S01 Service: Serviceartikel, Serviceauftrag. C01 CRM: Kampagne, Verkaufschance zum Kontakt. A01 Modul abgewählt: keine Daten. A02 Wiederanlauf ohne Doppelanlage. A03 SKR03/SKR04/vorhandene Einrichtung, DE/EN, Rechte nur Factory-Rolle, Dashboard-Drilldowns.

## Risiken (vor der nativen Abnahme prüfen)
Nicht kompiliert; Feld-/Methodenverhalten von Fertigungs-Artikelbuchblatt (Verbrauch/Ausgabe), Lagereingang/Einlagerung (Lagermitarbeiter des ausführenden Benutzers, Platzzuweisung), Anlagenbuchung gegen Bank und Serviceauftragsanlage ist nur gegen die Symbole, nicht zur Laufzeit geprüft. Die Fertigungsstückliste/Fertigungsartikel setzen Felder aus Tabellenerweiterungen voraus, die nicht in den lokalen Basissymbolen stehen.

## Nachtrag 24.11.2026: Verkaufsrahmenaufträge (Nutzerauftrag, kein eigenes Ticket)
Neue Belegart `SALES.BLANKET` (Enum `SalesBlanketOrder`, Wert 10) im Verkaufsgenerator, quotengleich: immer ungebucht, mindestens drei (drei bis fünf) Zeilen, Menge klein 8, mittel 12, groß 18 (Faktor 1,5). Eigene Mengeneingabe im Assistenten bei „Nur Bewegungsdaten“, Setup-Feld 37 additiv, Snapshot-Schlüssel `blanketSeries` additiv (ältere Läufe planen keine Rahmenaufträge). Nummernserie `SALES-BLK` aus der Foundation. Dashboard: Kachel „Verkaufsrahmenaufträge“ mit Drilldown. Nicht kompiliert, nicht nativ getestet.

## Nachtrag 24.11.2026 (2): Ausbau der abgenommenen Module (nicht kompiliert, nicht nativ getestet)
- **Retouren (Verkauf und Einkauf):** `BCSF Return Processor` (90492, Finance): zu ca. 12 % der gebuchten Rechnungen ein Retourenauftrag, offen oder gebucht (Rücklieferung/Retourenlieferung plus Gutschrift, Teilmenge); Einkaufsretouren nur bei freiem Bestand (sonst `STOCK`); Marker `returnVersion`, Skip `RETURN-SKIP`; Dashboard-Kacheln Retourenaufträge und gebuchte Rückgaben nun mit Herkunft.
- **Anlagen:** Marker `assetExtVersion`: Modus 1 wie bisher, 2 zwei weitere Monatsabschreibungen (Abschreibungslauf), 3 Zuschreibung und Wartung, 4 Abgang mit Erlös; Klasse/Unterklasse/Wartungscode `BCSF` additiv; Modus wird als Ganzes übersprungen (`SOURCE`), wenn G/L-Integration, Buchungsgruppenkonten oder Datum nicht passen.
- **Service:** Marker `servicePostVersion`: ca. 50 % der Serviceaufträge werden über die Standard-Servicebuchung geliefert und fakturiert (`SERVICE-INVOICE`, `SERVICE-SHIPMENT`); Skip `STOCK`/`SOURCE`.
- **Bewusst nicht umgesetzt (kein sicherer Weg ohne Kompilierung/Architekturentscheidung):** Sammelrechnungen und Sammelausgleich, Zahlungsrabatt/-toleranz (Commit in der Standard-Toleranzprüfung, R09), eigene Bankstämme je Zahlung, Einkaufsangebote/-rahmenaufträge, Kommissionierung/Versand/gelenktes WMS/Umlagerung mit Lagerplätzen, Arbeitsplan/Kapazität/Rückmeldung, Serviceverträge/Wartungsfälle.

## Nachtrag 24.11.2026 (3): Lizenzprüfung und Ausbau CRM/Projekte (nicht kompiliert, nicht nativ getestet)
- **Lizenz/Premium:** `BCSF Module Selection.IsAvailable`: Fertigung und Service sind nur wählbar, wenn der Benutzer lizenzbewusst Lese- und Schreibrechte auf deren Kerntabellen hat (BC liefert keine direkte Lizenzabfrage; die Objektberechtigung ist der belastbare Ersatz). Nicht verfügbare Module sind in der Einrichtung nicht anwählbar („Nicht verfügbar: benötigt Premium-Lizenz oder Berechtigungen“), werden bei der Anforderung abgelehnt und nicht im Lauf erfasst. Alle anderen Module gelten als Essential. Ein Benutzer mit Essential-Lizenz, aber vollen Rechten auf diese Tabellen, ließe sich nicht unterscheiden; die Prüfung gilt je Benutzer, nicht je Mandant.
- **CRM:** Marker `crmExtVersion`: Segment je Lauf mit Segmentzeile je Verkaufschance-Kontakt, Nachfass-Aufgabe (Telefonat) je Chance, wenn der Debitor einen Verkäufer hat. Interaktionsprotokoll, Chancenphasen und -abschluss nicht umgesetzt (laufen über Assistenten/Chancenposten, ohne sichere Standard-API).
- **Projekte:** Marker `projectStructureVersion`: Begin-/End-Summenaufgabe um die Buchungsaufgaben (mehrstufige Struktur). WIP/Ertragsrealisierung, Projektpreise und Kapazitätsprüfung nicht umgesetzt.
- **Planung:** Umsetzung der Vorschläge in Bestellungen und Produktionsplanung nicht umgesetzt (Standard-Umsetzungscodeunit mit internem Commit; Produktionsplanung braucht Arbeitspläne).
