# Purchasing – Modulspezifikation

**Status:** Geplant, keine AL-Objekte implementiert. **Pfad:** `src/Purchasing/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** MVP / P1.

## Fachlicher Auftrag

Kreditoren und Beschaffungsbelegketten.

## Verantwortungen und gewünschte Ergebnisse

Lieferantenklassen, Bestellungen, Wareneingänge, Rechnungen, Gutschriften, Zahlungszielvarianten.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Finance, Inventory, DataGeneration, ProcessEngine. Verpflichtende und optionale Beziehungen erst beim konkreten Generator im Dependency Manager fixieren; Zyklen verhindern.

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
