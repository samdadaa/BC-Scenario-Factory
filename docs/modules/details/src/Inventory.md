# Inventory – Modulspezifikation

**Status:** Sechs AL-Objekte für SF-019 implementiert, **Zur Prüfung**; reale BC-Nachprüfung offen. **Pfad:** `src/Inventory/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** MVP / P1.

## Fachlicher Auftrag

Artikel, Einheiten, Varianten, Kategorien/Merkmale, Referenzen/Bezugsquellen, Ersatzartikel, einfache Lagerstammdaten und gezielte SKUs. Bestands-/Postenprozesse bleiben Folgebausteine.

## Verantwortungen und gewünschte Ergebnisse

Artikeltyp, Einheiten, Wiederbeschaffungsparameter, Bestandsentwicklung über Standards.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine direkten Buchungen in Item Ledger Entry. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Inventory`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Ablage – SF-002, 16.11.2026

Weiterhin kein AL-Code; der Modulmarker bleibt erhalten. Typordner entstehen erst mit vorhandenen Objekten. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.

## SF-019 – aktueller Vertrag (20.11.2026)

- 90475 `BCSF Inventory Generator`, 90476 `BCSF Item Binding`, 90477 `BCSF Item Catalog`, 90478 `BCSF Item Setup`, 90479 `BCSF Item Relations`, 90480 `BCSF Item Masters`; Pfade `src/Inventory/Codeunits/` und `EnumExtensions/`.
- TECH-TRADE/TECH-BINS Version 1 im bestehenden Vorlagen-/Snapshot-/Queuepfad. ITEM benötigt bei nicht expliziten vorhandenen Lieferanten einen VENDOR-Vorgänger mit mindestens zwei Einheiten; optionale Kundenreferenz benötigt den positiven CUSTOMER-Vorgänger. Keine automatisch hinzugefügten Zielmengen.
- Vorab-/Hintergrundprüfung der konkreten Einrichtung, bestehende Ausführungsbesitz-/Guardprüfung, commitfreier Fachteil, Herkunft und Outputprüfung. Wiederverwendete Standardstämme zählen nicht als neue Ergebnisse.
- Kein Bestand und keine direkte oder indirekt angeforderte Standardbuchung. Main-App ohne Test-Codeunits; separate ausdrücklich beauftragte Test-App 90700.

[Sortiment, Quellen, Grenzen, Bedienung und Sandbox-Smoke](../../../INVENTORY_GENERATION.md), [tatsächlich ausgeführte Prüfungen und gemeldeter Item-Vendor-Schlüsselfehler](../../../TESTS.md#sf-019--artikelsortiment-und-lagerbasics-20112026). Historische Abschnitte „geplant/ohne Code“ oben gelten nur für den damaligen Stand.

SF-019-Bedienkorrektur: elf Standardlistenrouten für die ergänzten Entitäten; Attributzuordnungen im erzeugten Umfang lesbar in der bestehenden Herkunftsseite. Einrichtung meldet erfolgreichen Abschluss; Fehler propagieren unverändert. Keine neuen Objekte/Tabellenfelder. Native Prüfung offen; Details im oben verlinkten Vertrag.


## SF-048 – Modulare Geschäftsläufe

Keine neuen Artikel in Bewegungsläufen. Item Setup liest gebundene Mengen; vorhandene Quellartikel/Basiseinheiten/Lieferantenbeziehungen und Livebestand sind Grundlage. Kein eigenständiger Bewegungs-/Ledgergenerator. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.
