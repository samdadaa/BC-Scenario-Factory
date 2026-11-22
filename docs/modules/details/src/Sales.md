# Sales – Modulspezifikation

**Status:** 7 AL-Objekte für Partnerstammdaten und SF-021-Verkaufsbelege implementiert, zur Prüfung; native BC-Abnahme offen. **Pfad:** `src/Sales/`. **Kategorie:** Fachlicher BC-Generator. **Phase:** MVP / P1.

## Fachlicher Auftrag

Debitoren und realistische Verkaufsbelegketten.

## Verantwortungen und gewünschte Ergebnisse

Kundentypen, Kreditlimits, Angebote, Aufträge, Teil-/Komplettlieferungen, Rechnungen, Gutschriften, offene Posten.

## Schnittstellen / Daten

Eingang: freigegebener Run-Snapshot (Branche, Nutzungsziel, Entitäten und Zielmengen, Seed, Zeitraum, Prozessmodus) und bereits validierte Vorgänger. Ausgang: datensparsame Ergebnisse pro Batch, Herkunftsnachweis und fachliche Validierungsbefunde. Konkrete AL-Objektnamen/Signaturen sind noch **zu prüfen**.

## Abhängigkeiten

Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle. Dies sind erlaubte direkte Codeabhängigkeiten gemäß [SF-002-Objektplan](../../../OBJECT_PLAN.md), keine zusätzlichen App-Abhängigkeiten. Fachliche Prozessvoraussetzungen werden separat im Dependency Manager geplant.

## Grenzen und Risiken

Synthetische Kommunikation; keine automatischen E-Mails. Bestehende Daten und Mandanten müssen geschützt werden; Standard-Buchungen dürfen nicht umgangen werden. Keine erfundenen APIs/Objektnummern.

## Mögliche Tests (noch nicht ausgeführt)

- Happy Path mit kleiner Menge und eindeutigen logischen Schlüsseln.
- Leeres/falsches Setup, fehlende Berechtigung oder nicht kompatibler Prozessmodus.
- Unterbrechung + Wiederanlauf und Prüfen auf Doppelanlage, soweit dieses Modul Daten verändert.
- Fachliche Beziehungen, Datums-/Wertgrenzen, Datenvariation und Soll/Ist-Kontrolle.
- Wechsel von Demo-/Training- auf Performance-Konfiguration ohne fachlichen Qualitätsverlust.

## Vor Implementierung klären

Konkrete Standardtabellen, Events und Codeunits in der Zielversion nachprüfen; danach Objektplan und Testfälle im passenden **einzeln freigegebenen TODO-Ticket** konkretisieren. Nach Implementierung hier reale Objekte, Datenflüsse und tatsächliche Testnachweise ergänzen.

## Objektplanung SF-002

Geplante IDs, Namen und Dateipfade stehen im [zentralen Objektplan](../../../OBJECT_PLAN.md). Namespace: `BCScenarioFactory.Sales`; Präfix: `BCSF`. Der Plan erzeugt keine AL-Objekte; der aktuelle Stand wird unten ergänzt. Signaturen und Standard-APIs erst im jeweiligen Umsetzungsticket prüfen.


## Ablage – SF-002, 16.11.2026

Vorhandene Objekte liegen in Codeunits/ und EnumExtensions/; der Modulmarker bleibt erhalten. Zuordnung gemäß [Konventionen](../../../CONVENTIONS.md). Objektidentitäten und Modulverantwortung bleiben erhalten.


## SF-018 – 18.11.2026

90425 Customer Generator und 90427 Customer Binding: synthetische B2B-/B2C-Debitoren, explizite Gruppen, Klassenbedingungen/-kreditlimits, Standard-Validate/Insert und Herkunft/Outputvalidierung. Keine Verkaufsbelege. [Vertrag](../../../PARTNER_GENERATION.md), [lokale Nachweise](../../../TESTS.md#sf-018--lokaler-prüfnachweis-18112026). **Zur Prüfung**, tatsächliche BC-Abnahme offen.


## SF-039

Customer Generator unterstützt neue Regel-/Setupversion 2, optional validierte Einstellungen und registrierte Lieferadressen für B2B. [Vertrag](../../../STABILIZATION_FINANCE_PARTNERS.md). **Zur Prüfung**.

## SF-018 – Nachprüfung 19.11.2026

In 90425 Customer Generator wird die zusätzliche Lieferadress-Rechteprüfung bei Partner-Setupversion 2 auf `B2C Percent < 100` begrenzt. Reine Privatkundenläufe erzeugen keine Lieferadresse und benötigen diese zusätzliche App-Vorprüfung deshalb nicht. B2B-/Mischläufe prüfen weiter vor Start, der Adresswriter erneut vor Anlage. Snapshot-/Generatorversion, Standardvalidierung, Herkunft und Schema unverändert. [Prüfnachweis und ausstehende BC-Rechtefälle](../../../TESTS.md#sf-018--nachprüfung-und-privatkunden-vorprüfung-19112026). **Zur Prüfung**.

## SF-021 – aktueller Stand, 20.11.2026

Jetzt sieben AL-Objekte: vorhandene 90425/90427 und neue 90426 Sales Generator, 90428 Sales Binding, 90429 Sales Setup, 90430 Sales Documents, 90431 Sales Evidence. Quote/Order/Invoice in Modus 1/2 (Quote nur 1), normale MwSt./LCY/einfacher Lagerort, ausdrückliche synthetische Quelle und Freigabe. Quoten, Halbmenge, Standardumwandlung/-preis/-buchung, Ausgabe-/Postenbezug und bestehende Queue/Checkpoints. Keine Bestandsbeschaffung, Zahlungen/Gutschriften oder unsicherer Replay. [Umfang/Bedienung/Abnahme](../../../SALES_PROCESS.md), [echte Prüfungen](../../../TESTS.md#sf-021--verkaufsprozess-20112026). **Zur Prüfung**. Frühere Abschnitte ohne Beleggenerator sind historische Stände.

## SF-045 – aktueller Bestand

Bestehende Verkaufsgeneratoren unverändert wiederverwendet; bei positivem Einkaufsbestellziel besteht eine explizite PURCHASE.ORDER-Abhängigkeit. Same-run-Stämme und Bestands-/Buchungssperren bleiben wirksam.

[Vertrag und offene BC-Referenzprüfung](../../../INDUSTRY_INITIALIZATION.md), [vollständiges Objekt-/Eventinventar](../../../ARCHITECTURE_AUDIT_SF045.md). Lokale Kompilierung ist kein fachlicher Sandboxnachweis. Status **Zur Prüfung**.


## 1.0.7.0 – aktueller Folgeumfang

salesSetup Version 3 bindet Standardbeschaffung desselben Laufs vor gebuchten Verkäufen; alte Version 2 bleibt für Buchung gesperrt. Optionale Zahlungen für gebuchte Auftrags-/Direktrechnungen über gemeinsamen Finance-Dienst. Keine neue Seite/Objekte. [Gemeinsamer Vertrag](../../../INDUSTRY_INITIALIZATION.md). **Zur Prüfung**, native Abnahme offen.


## SF-022 – Datumszeitraum 1.0.7.3

Gesamtbestandsprüfung neuer Datumsregel am Periodenende; einzelne Buchung weiterhin zum tatsächlichen Verkaufsdatum prüfen. Ausgabe validiert fachliche Beleg-/Buchungsdaten neuer Captures. [Vertrag/offene native Abnahme](../../../INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073). **Zur Prüfung**.


## SF-048 – Modulare Geschäftsläufe

Setup-v4 friert explizite Quellidentitäten/Fingerprint ein. Keine neuen Partner/Artikel; Einkauf nur bei explizitem positivem Ziel. Aktueller/stichtagsbezogener Bestand nach Reservierungen und verbleibender Eigenbedarf werden geprüft. Legacy-v1/2/3 geschützt. [Vertrag](../../../MODULAR_GENERATION.md), [lokale Nachweise und offene native A–G](../../../review/SF048_PRUEFBERICHT.md). Status **Zur Prüfung**; keine native Buchungsabnahme.
