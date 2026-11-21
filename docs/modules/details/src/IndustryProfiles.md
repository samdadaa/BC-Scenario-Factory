# IndustryProfiles – Modulspezifikation

**Status:** 1 AL-Objekt: generische versionierte Syntheseregeln; zur Prüfung. Vollständige Branchenprofile weiterhin geplant. **Pfad:** `src/IndustryProfiles/`. **Kategorie:** Technischer Kern. **Phase:** MVP / P1.

## Fachlicher Auftrag

Konfigurierbare Branchenprofile mit realistischen Datenmischungen, Geschäftsmodellen und Profilversion.

## Verantwortungen und gewünschte Ergebnisse

Handel zunächst; B2B/B2C, Artikelmix, Belegstatusquoten; Profil-Parameter; Eignungsprüfung pro Modul.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ModuleRegistry, ScenarioManagement. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Kein paralleler Fork von Finance-/Sales-Generatoren. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.IndustryProfiles`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; das Modul bleibt geplant und leer. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Implementierter Stand SF-009/SF-010 – 15.11.2026

90154 Synthetic Rules; Pflichtsubscriber am Snapshot-Regelereignis. Keine Standarddatenmutation. Vertrag, Rechte, Transaktionsgrenzen und reale Prüfnachweise: [Setup und Seed](../../../SETUP_SEED.md), [Tests](../../../TESTS.md). Frühere Planabschnitte bleiben Zielbild.

## Abgrenzung SF-015

Der Wizard erfasst beabsichtigten Profilcode und Version, wendet aber kein vollständiges Branchenpreset an. Dieses Modul bleibt unverändert bei einer Codeunit für generische Syntheseregeln; Branchenprofile weiterhin geplant. [Wizardvertrag](../../../MONITORING_WIZARD.md).


## Ablage – SF-002, 16.11.2026

Vorhandene AL-Objekte liegen unter `src/IndustryProfiles/Codeunits/`. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-037 – Reparaturauftrag 18.11.2026

Optionale Startvorlagen nur über die UI, fixe IDs und bekannte Standardnamen zur sprachabhängigen Anzeige, Entfernt-Vermerke/Archive beim Seed respektiert, Wiederherstellung ausdrücklich bestätigt. Install-/Upgradetrigger schreibfrei. [Aktueller Vertrag](../../../STARTER_TEMPLATES.md), [echte lokale Prüfungen und offene BC-Abnahme](../../../TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). **Zur Prüfung**.

SF-021-Vorlagenkorrektur 1.0.5.1: neue gemischte Verkaufsvorlage und explizites Upgrade genau erkannter unveränderter 16 Branchen-Belegstarter auf Verkaufsziele v2. Unterschiedliche Mischquoten, alte Namen/Quellen und Captures geschützt, angepasste/entfernte/archivierte Starter behalten. Ohne entfernte/eigene Vorlagen 60 Starter; 8 Folgeprozessvorlagen bleiben Planung. Keine neuen AL-Objekte. [Vertrag](../../../SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051), Zur Prüfung.

## SF-045 – aktueller Bestand

Wholesale Profile 90153 definiert versionierte TRADE-3-Mengen 20/5/40 und 15/5/12/3 im kleinen Belegpaket; Faktoren 10/100 für Mittel/Groß. Nur Master/Unposted. Seed lädt einen zusätzlichen festen Großhandelsreferenzstarter ausschließlich explizit und schützt vorhandene/entfernte/archivierte Vorlagen. Bestehende Branchenstarter werden nicht zu vollständigen Unternehmenspaketen erklärt.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.
