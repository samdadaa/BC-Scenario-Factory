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

`RunId + GeneratorId + LogicalKey + Seed` bestimmen synthetische Eingabewerte; ohne Abhängigkeit von zufälliger Session-/Batch-Reihenfolge. Nummernserien, Zeitstempel, Buchungsergebnisse und von BC vergebene IDs können trotzdem abweichen. Datengeneratoren müssen nachvollziehbare Herkunftsmarker/Registry-Einträge erstellen. Anonymität: keine Mischung mit realen Kontaktdaten, keine erreichbaren E-Mails/Telefonnummern, keine Bankverbindung mit Zahlungsgefahr.

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
