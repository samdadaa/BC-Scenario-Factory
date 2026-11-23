# Purchasing – Modulspezifikation

**Status:** 2 AL-Objekte für Partnerstammdaten implementiert, zur Prüfung; Beleggeneratoren weiterhin geplant. **Pfad:** `src/Purchasing/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** MVP / P1.

## Fachlicher Auftrag

Kreditoren und Beschaffungsbelegketten.

## Verantwortungen und gewünschte Ergebnisse

Lieferantenklassen, Bestellungen, Wareneingänge, Rechnungen, Gutschriften, Zahlungszielvarianten.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine unabhängigen Artikelposten ohne Einkaufs-/Lagerprozess. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Purchasing`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; der aktuelle Stand wird unten ergänzt. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Ablage – SF-002, 16.11.2026

Vorhandene Objekte liegen in Codeunits/ und EnumExtensions/; der Modulmarker bleibt erhalten. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-018 – 18.11.2026

90450 Vendor Generator und 90452 Vendor Binding: synthetische Firmenkreditoren, Klassenbedingungen/-prioritäten, explizite Gruppen, Standard-Validate/Insert und Herkunft/Outputvalidierung. Keine Einkaufsbelege. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-039

Vendor Generator unterstützt neue Regel-/Setupversion 2, optional validierte Einstellungen und registrierte Bestelladressen. [Vertrag](../../../STABILIZATION_FINANCE_PARTNERS.md). **Zur Prüfung**.

## SF-045 – aktueller Bestand

Purchase Generator 90451 plus EnumExtension 90453 implementieren ausschließlich PURCHASE.ORDER im ungebuchten Modus. purchaseSetup Version 1 friert Bestellserie/Lagerort ein. Zwei Kreditoren und Artikel aus demselben Lauf sind Pflicht; Bestellungen folgen dem tatsächlichen Item Vendor. Standard-Validate/Insert, keine Buchung. DOCUMENT-Herkunft am Kopf; Output prüft Lieferant, Artikel, Datum, Einheit, Menge und ungebuchten Zustand. Dashboard purchase/order öffnet die passende gefilterte Standardliste. Gebuchte Wareneingänge/Rechnungen und Folgeprozesse bleiben SF-020/SF-022.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-020 / 1.0.7.0 – aktueller Umfang

Fünf AL-Objekte. Purchase Generator 90451 unterstützt PURCHASE.ORDER bis PostedMovements, neue Evidence 90454 registriert echte gebuchte Rechnung/Eingang, Kreditoren-, Sach-, MwSt.-, Artikel- und Wertposten. purchaseSetup v2, Same-run-Lieferant und Artikel, Standard-Purch.-Post mit Commitunterdrückung, Mengen-/Datumsdeckung vor Verkauf und Outputprüfung. Optional inline Zahlungsdienst aus Finance; kein neuer Benutzerablauf. Ungebuchte v1-Snapshots bleiben gültig. Einkaufsbestellungen/-eingänge/-rechnungen und Kreditorenposten werden im Dashboard gezählt und gefiltert geöffnet. Gutschriften/Retouren nicht implementiert. [Aktueller Vertrag](../../../INDUSTRY_INITIALIZATION.md), [Prüfung](../../../TESTS.md#sf-020sf-022--gebuchter-großhandel-und-zahlungsausgleich). **Zur Prüfung**, native Abnahme offen.


## SF-022 – Datumszeitraum 1.0.7.3

Gebuchte Eingangs-/Rechnungsdaten über Process Coordinator verteilt, spätestens zum artikelbezogenen ersten Verkauf. Ausgabe validiert tatsächliche Datumsfelder, Standardposting/Claim/Commitgrenzen erhalten. [Vertrag/offene native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Generator liest Artikel-/Lieferanten-IDs aus ursprünglichem Quellrun, registriert ausschließlich neue Belege im eigenen Run. Standardbuchungen und Zahlungen nur nach bestehendem Freigabevertrag; Quellenprüfung vor jeder Generatorausführung. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.


## SF-049/SF-050 – lokaler Teilstand 1.0.10.0

Bestehenden Quellen-/Snapshot-/Mengen-/Registry-/Qualitäts-/Dashboardpfad für den modulabhängigen Pool Version 3 und ausdrückliche STOCK-Auslassungsnachweise ergänzt. Keine neue Batchengine und keine automatische Wiederholung unerwarteter Buchungsfehler. Unterstützter Umfang, konkrete Dateien/Datenflüsse, Kompatibilität und noch offene native Modulprüfung im [gemeinsamen Prüfbericht](../../../review/SF049_SF050_PRUEFBERICHT.md). Status In Arbeit, keine native Abnahme.


## SF-050 – aktuelle Umsetzung 1.0.11.0 / 23.11.2026

Isolierte neue Geschäftsvorfälle, lesende Prüfung der tatsächlich gewählten Quellen, atomare No-write-Skip-Checkpoints, fortgesetzte unabhängige Pending-Arbeit und unveränderte NeedsReview-Sperren. Bestehende Einrichtungen werden nur im bestätigten Foundationpfad ergänzt; neue interne Vorlagen verwenden konkrete kompatible Zuordnungen. Quellen, betroffene Moduldateien, Ergebnis-/Listenvertrag und Grenzen im [aktuellen Prüfbericht](../../../review/SF050_PRUEFBERICHT.md). Fünf neue Methoden im vorhandenen Testobjekt; lokale Nachweise dort, native Modulabnahme N01–N08 durch den Nutzer noch offen. **Zur Prüfung**, SF-051–SF-053 nicht umgesetzt.
