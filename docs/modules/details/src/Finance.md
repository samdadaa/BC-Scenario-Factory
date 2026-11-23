# Finance – Modulspezifikation

**Status:** 7 AL-Objekte implementiert, zur Prüfung. **Pfad:** `src/Finance/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** MVP / P1.

## Fachlicher Auftrag

Finanz-Basiseinrichtungen und belastbare Finanz-Geschäftsvorfälle.

## Verantwortungen und gewünschte Ergebnisse

G/L, Buchungsgruppen, Dimensionen, Buchungsblätter, Bankkonten, Zahlungsbedingungen; später Zahlungen/Ausgleich.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Steuer-/Lokalisierungs-Setup aus BC prüfen statt feste Steuersätze erfinden. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Finance`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; dieser historische Planabschnitt wird durch den aktuellen Implementierungsstand unten ergänzt. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Implementierter Stand SF-009/SF-010 – 15.11.2026

90402 Finance Setup Check; Pflichtsubscriber am Setup-Inspektionsereignis. Keine Standarddatenmutation. Vertrag, Rechte, Transaktionsgrenzen und reale Prüfnachweise: [Setup und Seed](../../../SETUP_SEED.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/Finance/Codeunits/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-016/SF-017 – 18.11.2026

90400 Finance Package Mgt, 90402 Finance Setup Check, 90403 Finance Package, 90404 Finance Selection, 90405 Finance Preview, 90406 Finance Setup, 90407 Run Finance. Versionierte Testpakete, Standardberichte, Vorschau/Apply und Snapshotbindung. Kein Finanzbuchungs-/Zahlungsgenerator. [Vertrag und BC-Abnahmefälle](../../../VALIDATION_FINANCE.md), [lokale Nachweise](../../../TESTS.md#sf-016sf-017--lokaler-prüfnachweis-18112026). **Zur Prüfung**, keine nachgewiesene BC-Laufzeitabnahme.


## SF-018 – 18.11.2026

Partner-Capture-Subscriber liefert paketabhängige Gruppen und erfasste Standardnummernserien, Kontenzuordnungen, Zahlungsformeln und CRM-Bindungen. Keine neuen Konten oder Standardrechte, kein automatisches Apply. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-038

Gemeinsamer Finance-Einstieg, neue Teilpakete 2.0.0 mit bestätigter Foundation, kein Zwei-Konten-Fallback. Altversion 1.0.0 bleibt unverändert. [Rollen und Abnahme](../../../STABILIZATION_FINANCE_PARTNERS.md). **Zur Prüfung**.

## SF-045 – aktueller Bestand

Lokale SKR03-/SKR04-Neupakete 3.0.0 enthalten zusätzlich begrenzte BWA mit Erlösen, Warenkosten, Rohergebnis, Betriebskosten, Ergebnis und Abstimmungsdifferenz. Bilanz/GuV und Kontenbasis bleiben erhalten. 1.0.0/2.0.0 werden nicht umgeschrieben; Existing übernimmt nur gültige Einrichtung. Keine Voll-DATEV-/Voll-BWA-Behauptung.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## SF-022 / 1.0.7.0 – ausgewählte Zahlungen und Ausgleich

Neun AL-Objekte. Neue Codeunit 90401 Payment Processor: synthetische Bank BCSF-PAY, eingefrorenes paymentSetup v1 und Freigabe, wirklicher Batchclaim vor Standardzahlung und vollständigem Ausgleich der im selben Batch gebuchten Einkaufs-/Verkaufsrechnung. Temporäre General-Buchblattzeile, Gen. Jnl.-Post Line.RunWithCheck ohne impliziten Commit, Herkunft aller tatsächlichen Zahlungs-/Bank-/Sach-/Ausgleichsposten, Restbetragprüfung. Keine externen Bankdaten, Übermittlung, Teilzahlungen oder Gutschriften. Keine Abhängigkeit auf BackgroundProcessing; vorhandener EnsureExecution-Vertrag verifiziert den Claim. Package Mgt bereitet automatische Lagerwertbuchung nur ohne Sach-/Artikelposten vor, sonst Konflikt statt Änderung. [Vertrag und Grenzen](../../../INDUSTRY_INITIALIZATION.md), [Prüfung](../../../TESTS.md#sf-020sf-022--gebuchter-großhandel-und-zahlungsausgleich). **Zur Prüfung**, native Abnahme offen.


Herkunftsregistry: Bank Account Ledger Entry, Detailed Cust. Ledg. Entry und Detailed Vendor Ledg. Entry sind explizit als Standardergebnisse zugelassen. Die bestehende eindeutige physische Ergebnisidentität und Batchbesitzprüfung gelten unverändert.


## SF-022 – Datumszeitraum 1.0.7.3

Payment Processor verteilt neue Zahlungsbuchungen zwischen Rechnung und erfasstem Ende, setzt Zahlungs-Belegdatum und prüft tatsächliche Datumswerte. Historische Captures ohne Marker bleiben beim Rechnungsdatum; vollständiger Ausgleich und synthetische Bank erhalten. [Vertrag/offene native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.


## SF-047 – Zahlungsvalidierung 1.0.8.5

Payment Processor 90401 setzt `TempLine.SetSuppressCommit(true)` unmittelbar nach Init und vor sämtlichen Validierungen, unbedingt für Kunden-/Lieferantenzahlungen. Die Standard-Toleranzinstanz erhält dadurch die Unterdrückung ihrer eigenen Commits; fehlender Schutz führte nativ unter BC 29.1 zum Abbruch in DelVendPmtTolAcc. Strenger Batchguard, Berechtigungen, Standardbuchung/Ausgleich, Herkunft, Restbetrag-/Datumskontrolle und unsichere-Retry-Sperren bleiben erhalten. Kein Schemawechsel, keine neue UI/Setupvorgabe. Standard-API-Quellregression mit vier Negativkontrollen bestanden; Main/Test gegen lokale 28.5-Symbole kompiliert. [Native BC-29.1-Fälle und lokale Prüfgrenzen](../../../review/SF047_PRUEFBERICHT.md#zahlungskorrektur-1085--commit-bei-ausgleichsvalidierung). **Zur Prüfung**.


## SF-050 – aktuelle Umsetzung 1.0.11.0 / 23.11.2026

Isolierte neue Geschäftsvorfälle, lesende Prüfung der tatsächlich gewählten Quellen, atomare No-write-Skip-Checkpoints, fortgesetzte unabhängige Pending-Arbeit und unveränderte NeedsReview-Sperren. Bestehende Einrichtungen werden nur im bestätigten Foundationpfad ergänzt; neue interne Vorlagen verwenden konkrete kompatible Zuordnungen. Quellen, betroffene Moduldateien, Ergebnis-/Listenvertrag und Grenzen im [aktuellen Prüfbericht](../../../review/SF050_PRUEFBERICHT.md). Fünf neue Methoden im vorhandenen Testobjekt; lokale Nachweise dort, native Modulabnahme N01–N08 durch den Nutzer noch offen. **Zur Prüfung**, SF-051–SF-053 nicht umgesetzt.
