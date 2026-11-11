# ModuleRegistry – Modulspezifikation

**Status:** Teilweise implementiert, 10 AL-Objekte, Zur Prüfung. **Pfad:** `src/ModuleRegistry/`. Historische Planungsangaben unten gelten nur für noch nicht implementierte Teile.

## Fachlicher Auftrag

Registrierung und Auffindbarkeit der fachlichen Generatoren, Fähigkeiten und Modi.

## Verantwortungen und gewünschte Ergebnisse

Stabile Identifikatoren; Modul-Capabilities; Modus-/Versionsunterstützung; Registry-Prüfungen.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Signaturen sind im implementierten Interface festgelegt.

## Abhängigkeiten

Core. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine Annahme über dynamische AL-Typinstanziierung ohne geprüften Interface-Vertrag. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.ModuleRegistry`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; unimplementierte Modulanteile bleiben geplant. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Aktueller Nachweis SF-007/SF-008

Reale Dateien:

- `BCSFContractSelfCheck.Codeunit.al`
- `BCSFCustomerProbe.Codeunit.al`
- `BCSFGenerator.Interface.al`
- `BCSFGeneratorCatalog.Page.al`
- `BCSFGeneratorRegistry.Table.al`
- `BCSFGeneratorRegistryMgt.Codeunit.al`
- `BCSFGeneratorType.Enum.al`
- `BCSFMissingGenerator.Codeunit.al`
- `BCSFProbeSupport.Codeunit.al`
- `BCSFVendorProbe.Codeunit.al`

Verantwortung, Datenfluss, temporäre/persistente Tabellen, Versionierung und Sicherheitsgrenzen: [GENERATOR_PLANNING.md](../../../GENERATOR_PLANNING.md). Build/Übersetzung lokal geprüft; Selbstprüfungen nur kompiliert, kein BC-Laufzeittest. Fachgeneratoren und Queue weiterhin geplant.
