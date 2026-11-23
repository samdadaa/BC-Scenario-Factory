# DataGeneration – Modulspezifikation

**Status:** 6 AL-Objekte: Seed, Vorschau und immutable Herkunftsregistry; zur Prüfung. **Pfad:** `src/DataGeneration/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

## Fachlicher Auftrag

Deterministische synthetische Werte und konsistente Stammdaten-/Beziehungsgenerierung.

## Verantwortungen und gewünschte Ergebnisse

Seed + LogicalKey; synthetische Lokalisierung; Verteilungen; eindeutige Identitäten; Herkunftsregistry.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Keine echten Kundendaten; keine generischen unvalidierten Inserts. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.DataGeneration`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Implementierter Stand SF-009/SF-010 – 15.11.2026

90250 Seed Engine; 90253 Run Synthetic Preview. Keine Standarddatenmutation. Vertrag, Rechte, Transaktionsgrenzen und reale Prüfnachweise: [Setup und Seed](../../../SETUP_SEED.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Implementierter Stand SF-011/SF-012 – 15.11.2026

90251 Generated Record, 90252 Record Registry, 90254 Generated Records und 90255 Run Provenance zusätzlich zur Seed-Basis. Keine behauptete BC-Laufzeitabnahme; Vertrag, Rechte, Zustände und Testgrenzen: [Herkunft und Queue](../../../EXECUTION_REGISTRY.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/DataGeneration/Codeunits/`, `src/DataGeneration/PageExtensions/`, `src/DataGeneration/Pages/`, `src/DataGeneration/Tables/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-018 – 18.11.2026

Neue Codeunit 90256 Partner Rules: gemeinsame versionierte Partnerwerte, lesende Setup-/Seedprüfung, Batchplanung und Snapshot-/Ergebnisvertrag. Keine direkte Lifecycle-/BackgroundProcessing-Rückreferenz; Pflichtsubscriber prüft Ausführungsbesitz. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-039

Neu 90257 Partner Catalog und 90258 Partner Children: versionierte natürliche Werte und Standard-Liefer-/Bestelladressen mit Parent-Herkunft. [Vertrag](../../../STABILIZATION_FINANCE_PARTNERS.md). Kein neuer Fachgenerator, alte Regelversion erhalten. **Zur Prüfung**.

## SF-045 – aktueller Bestand

Bestehende Seed-/Partnerkatalog-/Herkunftsdienste bleiben gemeinsam. Einkaufsbelege registrieren DOCUMENT-Köpfe mit Run/Batch/logischem Schlüssel und tatsächlicher Standard-SystemId.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Neuer ausschließlich lesender Dienst 90259 prüft Firma/Profil, alle Master-Checkpoints über Background-Event, Registry-SystemIds und lebende Basisdaten/Beziehungen. Snapshotbindung statt doppelter Registryanlage; keine Quellenketten. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.


## SF-049/SF-050 – lokaler Teilstand 1.0.10.0

Bestehenden Quellen-/Snapshot-/Mengen-/Registry-/Qualitäts-/Dashboardpfad für den modulabhängigen Pool Version 3 und ausdrückliche STOCK-Auslassungsnachweise ergänzt. Keine neue Batchengine und keine automatische Wiederholung unerwarteter Buchungsfehler. Unterstützter Umfang, konkrete Dateien/Datenflüsse, Kompatibilität und noch offene native Modulprüfung im [gemeinsamen Prüfbericht](../../../review/SF049_SF050_PRUEFBERICHT.md). Status In Arbeit, keine native Abnahme.


## SF-050 – aktuelle Umsetzung 1.0.11.0 / 23.11.2026

Isolierte neue Geschäftsvorfälle, lesende Prüfung der tatsächlich gewählten Quellen, atomare No-write-Skip-Checkpoints, fortgesetzte unabhängige Pending-Arbeit und unveränderte NeedsReview-Sperren. Bestehende Einrichtungen werden nur im bestätigten Foundationpfad ergänzt; neue interne Vorlagen verwenden konkrete kompatible Zuordnungen. Quellen, betroffene Moduldateien, Ergebnis-/Listenvertrag und Grenzen im [aktuellen Prüfbericht](../../../review/SF050_PRUEFBERICHT.md). Fünf neue Methoden im vorhandenen Testobjekt; lokale Nachweise dort, native Modulabnahme N01–N08 durch den Nutzer noch offen. **Zur Prüfung**, SF-051–SF-053 nicht umgesetzt.
