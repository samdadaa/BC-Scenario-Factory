# Projects – Modulspezifikation

**Status:** Geplant, keine AL-Objekte implementiert. **Pfad:** `src/Projects/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** P2.

## Fachlicher Auftrag

Projekt- und Ressourcenprozesse für Dienstleistungen/Bau.

## Verantwortungen und gewünschte Ergebnisse

Projektaufgaben, Ressourcen, Stunden, Beschaffung, Budget, Abrechnung und Projekteinträge.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Finance, Sales, Purchasing. Verpflichtende und optionale Beziehungen erst beim konkreten Generator im Dependency Manager fixieren; Zyklen verhindern.

## Grenzen und Risiken

Projektlogik versionsabhängig (Job/Project Naming) prüfen. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.
