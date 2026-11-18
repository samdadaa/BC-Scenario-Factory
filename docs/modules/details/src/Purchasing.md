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
