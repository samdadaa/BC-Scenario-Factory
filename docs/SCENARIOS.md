# Anwendungsfälle, Profile und Szenariomodi

## Benutzerablauf

Szenario-Vorlage wählen → Branchenkategorie → Module → Mengen je Entität → Datum/Region/Seed → Dokument-/Buchungsmodus → Preflight & Setup-Diff → Laufplan freigeben → Queue-Start oder Termin → Dashboard/Abweichungen → Ergebnis/Training/Demonstration.

## Betriebsmodi

| Modus | Erzeugt | Wichtige Einschränkung |
| --- | --- | --- |
| Setup + Stamm | Einrichtungsabhängigkeiten und Stammdaten | Keine Belege/gebuchten Posten |
| + Ungebuchte Belege | Angebote, Aufträge, Bestellungen, Rechnungsentwürfe | Keine Ledgerposten aus diesen Belegen |
| + Gebuchte Bewegungen | Belegketten inkl. resultierender Standardposten | Nur mit gültigen Buchungsbedingungen und expliziter Freigabe |
| + Folgeprozesse | Zahlung, Ausgleich, Retouren, Abschlussfälle je freigegebenem Umfang | Keine universelle Zusage für alle Branchen/Belege |

## Nutzungsprofile (orthogonal zur Branche)

- **Demo:** Wenige, aussagekräftige Unternehmen/Kunden; Namen nachvollziehbar; verschiedene Belegzustände und vollständige Geschichten; keine überflüssige Menge.
- **Training:** Aufgaben mit klarer Ausgangslage und Soll-Resultat, zeitlich nachvollziehbaren Vorgängen, Rollen; Reset bevorzugt über neue Testfirma/Sandbox.
- **Functional:** Randbedingungen, Kombinationen, ausgewählte gezielte Negativtests, stabile Seeds, referenzierbare Datensätze.
- **Performance:** Skalierbare Mengen und Zeitverteilung, kontrollierte Mischung aus Standardoperationen, technische und fachliche Messpunkte; zunächst Baseline erstellen.

## Ziel-Branchenprofile (alle *geplant*, MVP = Großhandel)

| Branche | Fachlicher Schwerpunkt | Typische Verteilung / Ketten |
| --- | --- | --- |
| Allgemeines Unternehmen | Finance, Sales, Purchasing | Gemeinkosten, B2B-Debitoren, Ausgangsrechnungen |
| Groß-/Einzelhandel (MVP) | Sales, Purchasing, Inventory, Finance | B2B/B2C, Artikelgruppen, Lagerfluss, Retouren |
| E-Commerce | Sales, Inventory, Finance | Viele kleine Orders, Varianten, Zahlungen, Rücksendungen |
| Distribution & Logistik | Inventory, Warehouse, Purchasing, Sales | Lagerorte, Umlagerungen, Versand-/Lieferstatus |
| Fertigung | Manufacturing, Assembly, Inventory, Finance | Stücklisten, Fertigungs- und Materialflüsse |
| Dienstleistung/Beratung | Projects, Sales, Finance | Ressourcen, Stunden, Projektabrechnungen |
| Bau-/Projektgeschäft | Projects, Purchasing, Finance | Meilensteine, Beschaffung, projektbezogene Kosten |
| Service/Wartung | ServiceManagement, Inventory, Finance | Servicefälle, Ersatzteile, Aufträge, Fakturierung |

## Beispiel: Handelsunternehmen

**Profilparameter (Beispielwerte, keine Marktdaten):** 85 % B2B / 15 % B2C; 90 % Lagerartikel / 10 % Dienstleistungsartikel; Aufträge in mehreren Größenklassen; offene/teilweise/komplett erledigte Fälle; unterschiedliche Zahlungsziele und zeitliche Verteilung.

**Verketteter Pfad:** Finanz-Basissetup → Debitoren/Kreditoren/Artikel/Lagerorte → Einkaufsbestellung → Wareneingang → Lagerbestand → Verkaufsauftrag → Lieferung → Rechnung → Zahlung → Ausgleich. Je nach Modus an vorgesehenem Punkt stoppen. Verfügbare Mengen nicht zufällig negativ werden lassen; optional definierte Ausnahmeszenarien separat.

**Testbeispiel:** 1.000 Debitoren, 200 Kreditoren, 600 Artikel, 1.500 Aufträge, davon 60 % ungebucht, 30 % fakturiert, 10 % teilweise geliefert. Zusätzliche Ziele wie 10.000 Rechnungen sind gesondert einzugeben. Zahlen sind ausschließlich Konfigurationsbeispiele.

## Reproduzierbarkeit und Schulung

Run-Konfiguration inklusive Profilversion und Seed als Snapshot speichern. Trainingsaufgaben brauchen vor dem Start prüfbare Lernziele, Rollen und erwartete Endzustände. Für sauberen Reset von gebuchten Belegen **neue Testfirma/Sandbox** statt unkontrolliertem Rücklöschen priorisieren. Keine echten Kontakte oder ausgehende Kommunikationsaktionen generieren.
