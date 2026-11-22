# BCSF-Q01 – Großhandel: Implementierungsbericht

**Status:** Zur Prüfung – Quellcode geändert, statisch geprüft, noch nicht nativ kompiliert oder in BC ausgeführt.

## Grundlage

Ausgangspunkt ist das hochgeladene Projekt `BC Scenario Factory(2).zip` und der Datenexport `Standard22_11_2026_9_25_47.xlsx` (mittleres Großhandelspaket). Der Export enthielt unter anderem 400 Artikel mit nur 40 Artikelbeschreibungen, einen einzigen Hauptlieferanten bei allen Artikeln und ausschließlich Einpositionsbelege.

## Implementierte Änderungen

1. **Versionierung:** Neue Großhandelsvorlagen werden mit `TRADE`/`5` erzeugt. `TRADE`/`4` und ältere Profile nutzen weiterhin ihre alte Produkt-, Lieferanten- und Beleglogik. Die App-Version in `app.json` wurde von `1.0.8.1` auf `1.0.8.2` erhöht. Alte gespeicherte Vorlagen werden nicht automatisch umgeschrieben.
2. **Artikelkatalog:** Version 5 unterstützt 6912 eindeutig unterscheidbare Kombinationen aus Produktfamilie, Durchmesser, Material, Baulänge/Dicke und Druckstufe. 400 Artikel ergeben 400 unterschiedliche Beschreibungen. Merkmale werden als Artikelattribute übernommen und Preise/Meldebestände anhand der Artikelmerkmale berechnet; bei mehr als 6912 Artikeln wird die Generierung abgewiesen.
3. **Lieferanten:** Für v5 werden Hauptlieferanten über die erzeugten Kreditoren verteilt. Artikelreferenzen und `Item Vendor` verwenden denselben Hauptlieferanten. Der zusätzliche Lieferant beim ersten Artikel bleibt erhalten.
4. **Belege:** Verkaufsbelege erhalten in v5 zwei bis fünf Zeilen, Einkaufsbelege zwei bis vier Zeilen. Artikelpositionen werden deterministisch und lieferantenkompatibel ausgewählt. Mengen, Teilmengen, Standardbuchung sowie gebuchte Belege und die zugehörigen Validierungsroutinen wurden auf mehrere Zeilen erweitert.
5. **Bestandsplanung:** Die vorgelagerten Wareneingänge decken die geplanten gebuchten Verkäufe pro Artikel einschließlich Teilbuchungen plus Reserve ab. Bei v5 erfolgt zusätzlich vor der Buchung jeder Verkaufszeile eine reale Bestandsprüfung. Die alte, nur für Einpositionsbelege gültige Bestandsvorprüfung ist für v5 deaktiviert.
6. **Partneradressen:** Für v5 werden 20 statt acht Stadtkombinationen für DE/GB verwendet; ältere Profile behalten die ursprüngliche Verteilung.
7. **Tests:** Zusätzliche Tests in `tests/SF019/BCSFInventoryTests.Codeunit.al` für 400 eindeutige Artikel, Kataloggrenze, v4-Kompatibilität und deterministische Mehrpositions-/Bedarfsplanung.

## Angepasste Dateien

- `app.json`
- `src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al`
- `src/Inventory/Codeunits/BCSFItemCatalog.Codeunit.al`
- `src/Inventory/Codeunits/BCSFItemSetup.Codeunit.al`
- `src/Inventory/Codeunits/BCSFInventoryGenerator.Codeunit.al`
- `src/Inventory/Codeunits/BCSFItemRelations.Codeunit.al`
- `src/DataGeneration/Codeunits/BCSFPartnerCatalog.Codeunit.al`
- `src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al`
- `src/Sales/Codeunits/BCSFSalesSetup.Codeunit.al`
- `src/Sales/Codeunits/BCSFSalesDocuments.Codeunit.al`
- `src/Sales/Codeunits/BCSFSalesGenerator.Codeunit.al`
- `src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al`
- `tests/SF019/BCSFInventoryTests.Codeunit.al`

## Ausgeführte Prüfungen

- Alle 144 AL-Quelldateien wurden für ausgeglichene `{}`-Blöcke geprüft.
- Ein offline nachgebildeter deterministischer v5-Produktkatalog wurde mit 4000 verschiedenen Produktidentitäten geprüft; keine Duplikate.
- Planungsarithmetik für 40/400/4000 Artikel sowie 5/50/500 Kreditoren auf Lieferantenzuordnung und gleiche Produkte innerhalb eines Verkaufsbelegs geprüft; keine Abweichungen in diesen Offline-Prüfungen.
- Verweise auf die neuen Koordinator-Methoden statisch abgeglichen.

**Nicht ausgeführt:** `alc`-Compiler, AL-Codeanalyse, BC-Standardtests, SF019-Testcodeunits, echte Einrichtung eines Sandboxmandanten und Buchungstest. In dieser Ausführungsumgebung steht weder der AL-Compiler noch ein Business-Central-Tenant zur Verfügung. Die bisherigen `.app`-Dateien im Ordner sind historische Binärdateien, **kein** neuer Build.

## Verbindliche Abnahme in BC

1. AL-Projekt neu kompilieren und SF019-Tests ausführen; Compilerfehler/BC-spezifische Validierungen zuerst beheben.
2. Frischen Sandboxmandanten für Version 5 verwenden; vorhandene v4-Läufe nicht verändern.
3. *Klein*: 40 Artikel, 5 Kreditoren; gebuchte und teilweise gebuchte Einkaufs-/Verkaufsprozesse ohne Fehler durchführen.
4. *Mittel*: 400 Artikel, 50 Kreditoren; Belegzeilen und Artikelstammdaten exportieren und mit dem alten Qualitätsbericht vergleichen.
5. Kontrollieren: 400 eindeutige fachliche Artikel, mindestens 20 unterschiedliche Hauptlieferanten, unterschiedliche Kunden-/Lieferantenbeziehungen, mehrere Zeilen je Beleg, alle Bestände plausibel, keine Fehlbuchung.
6. Seed-/Batchgrößen-Reproduzierbarkeit sowie Unterbrechung und Recovery in Sandbox prüfen.
7. Die Laufzeit des großen Profils gesondert messen: die v5-Bedarfsplanung überprüft Artikelbedarfe pro Einkaufsposition und ist aktuell noch nicht auf Großmengen profiliert/optimiert.

**Freigabe:** Erst nach erfolgreichem AL-Compile sowie End-to-End-Tests für klein und mittel. Bis dahin keine produktive Freigabe und keine Aussage, dass die gesamte Implementierung nativ getestet ist.
