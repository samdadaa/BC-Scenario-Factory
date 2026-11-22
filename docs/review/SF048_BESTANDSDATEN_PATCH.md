# SF-048 – Stammdaten aus aktuellem Mandanten (Patch 22.11.2026)

## Umfang

- Bei `Nur Bewegungsdaten` ist die frühere Run-ID optional. Bei leerer ID werden bestehende geeignete Stammdatensätze des aktuellen Mandanten lesend ausgewählt.
- Debitoren, Kreditoren und Artikel erhalten keine neue Factory-Registry-Identität. Neue Belege gehören weiterhin zur eigenen neuen Run-ID.
- Der Pool wird im Run-Snapshot als `masterDataSource.version=2` mit SystemIds eingefroren; Änderungen der geeigneten Pool-Auswahl zwischen Snapshot und Lauf verhindern die Ausführung.
- Kunden müssen grundsätzlich ungesperrt mit Buchungsgruppen sein; Lieferanten müssen kaufgeeignet sein. Artikel müssen bestandsgeführt, nicht gesperrt, mit Einheit, Einkaufslieferant, Artikel-Lieferanten-Beziehung und grundlegenden Einkaufs-/Lagerbuchungskombinationen versehen sein.
- Die Großhandels-Belegplanung verlangt zyklische Lieferantenzuordnung. Daher werden mindestens zwei Lieferanten mit mindestens vier geeigneten Artikeln je Lieferant verwendet; die Artikelliste wird lieferantenweise rundlaufend erzeugt.

## Technische Grenzen und Risiken

- Diese Vorprüfung garantiert **keine** erfolgreiche Standardbuchung: Weitere Kombinationen und geschäftsfallabhängige Regeln werden durch BC beim Generator-/Buchungsaufruf geprüft.
- Der Nutzerwunsch „Bei Buchungsfehlern einfach zum nächsten Beleg“ ist **noch nicht sicher umgesetzt**. Die vorhandene Batch-/Commit-/Recovery-Architektur stoppt bei nicht isolierten Fehlern mit Absicht; ein pauschales TryFunction-Abfangen könnte Teilbuchungen und Doppelbuchungen verursachen. Dafür wird ein separater transaktional isolierter Fehlervertrag benötigt.
- Ohne AL-Compiler und BC-Sandbox wurden **keine** erfolgreichen Buchungen behauptet. Test der Datenpool-Stabilität, Vorprüfung, der Einkaufs-/Verkaufsbuchungen und der deutschen XLF nach erneuter Generierung erforderlich.
- Bestehende Quellläufe mit `masterDataSource.version=1` bleiben auf der bisherigen Logik.
- Die Variante mit bereits vorhandenen echten Mandantenstammdaten ist **nur für Sandbox-Testmandanten** vorgesehen. Sie verändert die Stammdatensätze nicht, aber gebuchte Belege verändern den Testmandanten dauerhaft.

## Manueller Abnahmetest

1. Testmandant mit 20 geeigneten Debitoren, fünf Kreditoren und 40 Artikeln bereitstellen.
2. `Nur Bewegungsdaten`, Stammdatenquelle **leer**, Einkauf aktivieren, 15 Bestellungen.
3. Prüfen, dass kein neuer Debitor, Kreditor oder Artikel angelegt wurde.
4. Beleg-/Postenreferenzen, Bestände und gebuchte/ungebuchte Quoten prüfen.
5. Verkauf separat starten. Ausgangsdaten und bereits gebuchte Belege unverändert erhalten; neue Verkaufsbelege erzeugen.
6. Einzelne ungeeignete Stammdaten testen: Auswahl soll sie aus dem Pool ausschließen. Bei unzulänglichem Pool erfolgt ein verständlicher Vorab-Abbruch.
7. Einen Standardbuchungsfehler auslösen: Der bestehende Lauf muss ihn sicher melden und darf ihn **nicht** als erfolgreich deklarieren. Automatische Fortsetzung ist nicht abgenommen.

**Status:** Zur Prüfung.
