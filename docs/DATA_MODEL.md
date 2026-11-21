# Datenqualität, Generierung und Buchungsregeln

## Unterschied zu einer Zufallsdaten-App

Zuerst **Geschäftsvorfall** und Beziehungen modellieren, danach Werte synthetisch ziehen. Erst wenn Voraussetzungen und Geschäftsregeln erfüllt sind, Standardobjekte über Validierung / vorgesehene Codeunits anlegen. Realistische Daten müssen für Anwender verständliche *Geschichten* erzeugen, z. B. Kunde bestellt, Lieferant liefert, Lager wächst, Kunde erhält Ware, bezahlt Rechnung.

## Dimensionen der Datenvariation

- **Personas/Organisationen:** B2B/B2C, Größe/Kategorie, Sitzregion (synthetisch), Verkaufs-/Zahlungsverhalten.
- **Zeit:** Eröffnungsdatum, Saison, Arbeitstage, Fälligkeit, Vergangenheit/Zukunft; Datumsprüfungen im jeweiligen Modul.
- **Wert:** Preis/Mengenklassen, Steuersätze **nur aus gültiger Lokalisierungs-/Setup-Konfiguration**, Währung und Rundung, Zahlungsziele.
- **Status:** Offen, teilweise bearbeitet, vollständig, überfällig, storniert/retourniert, ausgeglichen (sofern über BC-Standard erzeugbar).
- **Beziehungen:** Debitor→Beleg→Posten, Kreditor→Bestellung→Eingang, Artikel→Lagerbewegung, Dimensionen/Kostenstellen.
- **Randfälle:** bewusst definierte Sonderfälle in Functional-Tests; keine unbeabsichtigten Fehlerzustände im Demo-Standard.

## Deterministische Erzeugung

`GeneratorId + LogicalKey + Seed + Profilcode/-version + Feldstream` bestimmen in Seed-Engine-Version 1 synthetische Eingangswerte; die RunId dient ausschließlich der Herkunft, damit gleiche Konfiguration auch in neuen Läufen reproduzierbar bleibt; ohne Abhängigkeit von zufälliger Session-/Batch-Reihenfolge. Nummernserien, Zeitstempel, Buchungsergebnisse und von BC vergebene IDs können trotzdem abweichen. Datengeneratoren müssen nachvollziehbare Herkunftsmarker/Registry-Einträge erstellen. Anonymität: keine Mischung mit realen Kontaktdaten, keine erreichbaren E-Mails/Telefonnummern, keine Bankverbindung mit Zahlungsgefahr.

## Abhängigkeits- und Fehlerregeln

1. Existenz/Lesbarkeit eines gültigen Einrichtungsdatensatzes ≠ Einrichtungsqualität; benötigte Konten, Gruppen, No. Series, Dimensionen, Lager-/MwSt.-Kontext prüfen.
2. Fehlende Setupwerte als Preflight-Befund und Setup-Diff mit Freigabe; keine ungefragte Änderung vorhandener Einstellungen.
3. Für Standardledger **immer fachliche Standardbuchung**. Direkte `Insert` auf Cust./Vendor/G/L/Item Ledger Entry als Abkürzung verboten.
4. Jede referenzierende Entität darf nur auf existierende/zugelassene Vorgänger zeigen; Mengen-/Beziehungstests nach Lauf.
5. Posting-spezifischer Wiederanlauf sucht zuerst vorhandene resultierende Posten/Belege; unklare Ergebnisse markieren und manuellen Check fordern.
6. Zielmengen je Entität, fachliche Quote und tatsächlich erzeugte/gebuchte Menge getrennt aufzeichnen. Ein einziges Gesamtzählerfeld ist irreführend.

## Grenzen der Konfiguration

Feste Vorgabemengen wie 1.000/10.000/50.000/100.000 nur Presets, **kein globales gleichförmiges Datenmodell**. Nutzer kann je Modul und Entität Ziele/Quoten individuell einstellen. Beispielsweise erzeugt 10.000 Verkaufsrechnungen nicht zwangsläufig 10.000 Debitoren; Wiederverwendung der Debitoren nach parametrisierten Verteilungen.

## Nachprüfung

Validierungsregeln: Soll/Ist je Entity, eindeutige logische Schlüssel, vorhandene Relationen, korrekte Beleg- und Buchungszustände, dimensions-/steuerliche Konsistenz und, bei Buchungen, verknüpfte resultierende Posten. Bei Performance zusätzlich Erstellungszeit, Batchgröße, Fehlerrate, Wiederanläufe – als Messwerte, nicht versprochene Kennzahlen.

## Umgesetzte Konfigurationsbasis SF-005/SF-006

Szenario-GUID/Revision, positive bzw. deaktivierte Entitätsziele, getrennte Mengen-/Modus-/Quotenparameter und Schema-1-JSON-Snapshots sind vorhanden. Momentan nur Planungsdaten, keine Standardstammdaten-/Ledgergenerierung. Der Snapshot bindet aufgelöste Deutsch-/Englisch-Datensprache und Textkatalogversion; spätere Worker müssen beide beibehalten. Technische Feldabdeckung und Grenzen: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md).

SF-010 implementiert stateless Integer-/Datumswerte und synthetische Firmen-/Personen-/Artikel-/Preis-DTOs mit erfassten Deutsch-/Englisch-Katalogen und versionierten Regeln. Keine Standarddatensatzanlage; Herkunftsregistry bleibt SF-011. Verteilung, Rundung, Schlüssel- und Versionsgrenzen: [SETUP_SEED.md](SETUP_SEED.md).

SF-011: Herkunft mit Run/Step/logischem Integer-Schlüssel/Artefaktcode, Batch, eingefrorenem Generator, Tabelle/SystemId, ursprünglichem RecordId und Eltern-Eintrags-GUID implementiert. Eindeutige SQL-Schlüssel verhindern widersprüchliche logische und physische Zuordnungen; Standarddaten werden nur referenziert, niemals generisch erstellt. SF-012 bestätigt Batchzählwerte erst nach vollständiger Herkunftsabdeckung und erfolgreicher Generator-Outputvalidierung. Fachliche Postenbeziehungen und globale Qualitätsprüfung bleiben generatorspezifisch bzw. SF-016. [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md).

SF-013: versionierte, immutable technische Checkpoints ergänzen die Herkunft. Sie binden Run/Batch/Generator, Sprache, Ergebnisflags und Zähler; keine Namen/Adressen/Beträge oder frei kopierte Ergebnis-JSON. Wiederaufnahme prüft alle Ergebnis-SystemIds und Generator-Output erneut. Ein alter Primärschlüssel, fehlende Registry oder abgelaufene Zeit ersetzt keinen Nachweis. [RECOVERY.md](RECOVERY.md).


## SF-018 – 18.11.2026

Optionaler Snapshotuntervertrag partnerSetup Version 1 hält Land, explizite bzw. paketgebundene Gruppen, erfasste Kontenzuordnungen, Nummernserien, Zahlungsbedingungen/-formeln, CRM-Beziehungs-/Kontaktseriencodes, Privatkundenanteil und Kreditlimits. Vorhandene Schema-1-Snapshots und syntheticRules unverändert lesbar; neue Generatoren verlangen diese zusätzlichen Angaben. Führende Ergebnisse sind Standard Customer/Vendor plus Herkunftsrolle CUSTOMER/VENDOR und SystemId; Standardkontaktnebenwirkungen sind keine zusätzlichen primären Mengeneinheiten. [Vertrag](PARTNER_GENERATION.md).

## SF-045 – additive Wiederverwendung

Keine neue Tabelle. Factory Setup erhält sechs technische Requestfelder (20–25): Standardjob-/Ergebnislauf-ID, Finanzmodus, Größe, Prozessmodus und Datum. Der tatsächliche Run/Snapshot/Plan/Checkpoint bleibt im vorhandenen Datenmodell. purchaseSetup Version 1 ergänzt optional Schema 1 (Bestellnummernserie, Lagerort). Ältere Snapshots erhalten keine neuen Einkaufsziele oder Buchungsfreigaben. Keine Laufdatenmigration/ForceSync. [Kompatibilitätsgrenzen](INDUSTRY_INITIALIZATION.md).
