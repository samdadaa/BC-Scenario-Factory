# BCSF-Q01 – Hotfix Großhandel v5.2 (Artikelmaterial)

## Beobachtung
Lauf bricht bei Artikelattributwert ab: erwarteter Wert `Messing`, gespeicherter Wert `Edelstahl` (Attribut-ID 1, Wert-ID 2); zu diesem Zeitpunkt waren 3 von 400 Artikeln abgeschlossen.

## Ursache und Korrektur
`BCSF Item Masters.CreateCategories()` wies bisher den Warengruppen feste Materialattribute zu. Der neue Katalog `TRADE/5` erlaubt dagegen mehrere Materialien pro Warengruppe. Artikel übernehmen bei Zuweisung der Kategorie die Attributbelegung; die spätere Validierung des Artikels kann dadurch einen anderen Materialwert vorfinden als in `BuildWholesaleValues()` vorgesehen.

Bei `TRADE/5` werden die Materialattribute nicht mehr auf Kategorien hinterlegt. Stattdessen weist `BCSF Inventory Generator.CreateItem()` jedem Artikel nach Anlage der Kategorie das für dieses konkrete Produkt ermittelte Material zu. Version 4 und ältere Profile behalten ihre bisherige Kategorienlogik. Die Artikelvalidierung prüft weiterhin Material gegen den Katalog. App-Version auf 1.0.8.3 angehoben.

## Hinweise zum erneuten Test
Der abgebrochene Lauf enthält bereits 200 Debitoren, 50 Kreditoren und 3 Artikel. **Nicht denselben fehlgeschlagenen Lauf einfach in dem teilbefüllten Mandanten wiederholen.** Einen neuen, leeren Testmandanten verwenden oder über eine nachweislich sichere Bereinigungsfunktion die vorhandenen Szenariodatensätze vollständig entfernen. Danach die neue App installieren und mit SKR03 sowie derselben mittleren Konfiguration starten.

## Validierung
Quellcode- und ZIP-Integrität geprüft. Es fand **kein AL-Compile, keine BC-Ausführung und kein Sandbox-Regressionstest** statt. Vor Produktivnutzung AL kompilieren und im neuen Testmandanten vollständigen 400-Artikel-Lauf durchführen; danach Einkaufs-/Verkaufsprozesse und Belegpostings prüfen.
