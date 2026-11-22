# SF-048 – Modulare Großhandelsläufe ab 1.0.9.0

Status **Zur Prüfung**. Implementierter Vertrag; lokale Prüfung ist keine native BC-Abnahme. [Prüfbericht](review/SF048_PRUEFBERICHT.md).

## Bedienung und Testvorlagen

Der vorhandene Unternehmensassistent führt über Kontenplan → Branche → Generierungsart → Module → Größe/Mengen → Prozessstufe → Zusammenfassung/Start. Die einmalige Mandanteneinrichtung bleibt Grundlage. Ohne andere Auswahl gilt **Komplettes Szenario** mit dem bisherigen Gesamtprozess.

- **Nur Stammdaten:** Einrichtungen und 20 Debitoren, 5 Kreditoren, 40 Artikel im Kleinpaket samt Beziehungen; keine Belege oder Buchungen. Die Prozessstufe bleibt Stammdaten.
- **Nur Bewegungsdaten:** Eine bestätigte Datenbasis desselben Mandanten auswählen. Einkauf und Verkauf unabhängig auswählen und Mengen für Bestellungen, Aufträge, Angebote und Rechnungen eingeben. Null lässt eine Belegart aus. Kein neuer Partner/Artikel. Artikel/Lager liefert vorhandene Artikel und aktuelle Bestandsprüfungen; kein eigenständiger Bewegungsprozess.
- **Komplettes Szenario:** Bisheriger Abhängigkeitsplan einschließlich Stammdaten, explizit freigegebener Buchung und optionaler Zahlung/Ausgleich.

Beispiel nach einem im Einkauf fehlgeschlagenen Komplettlauf: **Unternehmensdaten erzeugen → Nur Bewegungsdaten → Stammdatenquelle**; dort den fehlgeschlagenen Lauf auswählen, sofern seine drei Stammdatenpakete vollständig bestätigt sind. Nur Einkauf wählen, Bestellmenge 15 und gewünschte Prozessstufe festlegen; Zusammenfassung prüfen und starten. Für den späteren Verkauf erneut einen unabhängigen Lauf mit derselben ursprünglichen Stammdatenquelle erstellen. Die Auswahl eines Bewegungslaufs als neue Stammdatenquelle ist gesperrt.

**Startvorlagen laden** ergänzt drei neue feste, bisher unbenutzte IDs `{B55C4500-AB51-4045-9C00-000000000005}` bis `...007`: nur Stammdaten, 15 Einkaufsbestellungen, 20 Verkaufsaufträge. Die beiden Belegvorlagen sind ungebucht; vor Ausführung muss auf der bestehenden Szenariokarte eine echte Stammdatenquelle gewählt werden. Ohne Quelle stoppt die Erfassung. Vorhandene vier Großhandelsvorlagen und eigene/archivierte/absichtlich entfernte Vorlagen werden nicht ersetzt. Wiederholter Unternehmensstart benutzt jeweils eine neue interne Vorlage und Run-ID.

## Quellenvertrag und Abhängigkeiten

`BCSF Master Data Source` (90259) arbeitet ausschließlich lesend. Er prüft aktuelle Firma, TRADE-Profil 5/6, unveränderten Quellsnapshot, vollständige Customer-/Vendor-/Item-Ziele und Registry-SystemIds sowie aktuell vorhandene, ungesperrte Datensätze, Artikelbasiseinheiten und Lieferantenbeziehungen. Lieferadressen werden anhand ihrer Registry-/Parent-Identität erfasst. Quellenketten sind nicht zulässig.

BackgroundProcessing bestätigt diese Quelle nur bei terminalem Status Completed, CompletedWithWarnings, Failed oder ValidationFailed. **Fehlgeschlagene Läufe sind auf ausdrückliche Nutzerbestätigung zugelassen.** Jeder Customer-/Vendor-/Item-Batch muss Completed sein, einen bestätigten Schema-1-Checkpoint mit vollständigem Ergebnis besitzen und die bestätigten Mengen müssen die jeweilige komplette Step-Arbeit abdecken. Kein Running-Batch darf mehr existieren. Unvollständige, aktive, pausierte oder unklare Stammdatenpakete liefern keine Freigabe.

Neue Snapshots behalten Wurzelschema 1 und ergänzen `generationKind` (0 komplett, 1 Stamm, 2 Bewegung). Bewegungsläufe erhalten eine optionale Bindung `masterDataSource` Version 1 mit Quelllauf, Profilversion und festen SystemId-Listen für Kunden, Kreditoren, Artikel und Lieferadressen. `itemSetup` wird aus der Quelle übernommen; `salesSetup` Version 4 enthält diese konkreten Identitäten und den vorhandenen Stammdatenfingerabdruck. Vor jeder Generatorprüfung wird die Quelle erneut geprüft und mit der erfassten Bindung verglichen. Alte Sales-Verträge 1/2/3 und historische Snapshots bleiben lesbar; sie werden nicht umgeschrieben.

Im Bewegungsplan existieren ausschließlich gewählte positive Belegziele. Customer/Vendor/Item sind Referenzen, keine neuen Nodes oder Registryergebnisse. Einkauf und Verkaufsauflösung lesen die Quellregistry; neue Belege, Belegposten, Zahlungen und Checkpoints gehören ausschließlich zum neuen Run. Der bestehende Registry-/Parent-Vertrag über Run-Grenzen bleibt unverändert.

Sales fügt Purchase.ORDER nur hinzu, wenn dieser im neuen Snapshot ausdrücklich als positives Ziel ausgewählt ist. Ohne ausgewählten Einkauf wird kein Wareneingang erfunden. Standardfinanz-, Nummernserien-, Lagerort-, Buchungsgruppen- und Berechtigungsprüfungen bleiben wirksam.

## Bestand, Buchung und Wiederholung

Gebuchte Verkäufe prüfen aktuellen und stichtagsbezogenen Bestand abzüglich Reservierungen am Quelllagerort. In Sales-only-Läufen wird auch der verbleibende Gesamtbedarf vorgeprüft; bereits registrierte Belege desselben Runs werden nicht erneut als offener Bedarf gezählt. Direkt vor jeder tatsächlichen Buchung bleibt die bestehende Mengenprüfung aktiv. Die Artikelprüfung übernimmt den Standard-Artikellock, die vorhandene BCSF-SER-Verarbeitung bleibt erhalten. Eine historische Quellmenge garantiert keinen heutigen Bestand. Zu wenig Bestand oder ein Verkaufstag vor dem realen Eingang führt zum bestehenden Bestandsfehler; ungebuchte Angebote/Aufträge brauchen keinen künstlichen Wareneingang. Gleichzeitige externe Buchungen und reale Locks sind nativ zu prüfen.

Bei explizitem Einkauf+Verkauf gilt weiterhin die vorhandene Einkaufsdeckung und Reihenfolge. Zahlungen erfolgen ausschließlich in FollowUpProcesses mit erfasster Zustimmung. Alle Beleg-/Postenbuchungen laufen durch Standardcodeunits; keine direkten Ledger-Inserts, kein Commit und keine Lockerung von CommitBehavior.

Ein neuer Unternehmenslauf ist erst nach einem terminalen alten Lauf und ohne Running-Batch zulässig. Er ersetzt nur den aktuellen Setup-Verweis, nicht alte Snapshots, Belege oder Historie. Ein neuer Geschäftslauf ist keine Recovery: alte unsichere Belege/NeedsReview bleiben getrennt zu prüfen und werden weder wiederholt noch als erfolgreich markiert. Derselbe neue Run behält die vorhandenen Claims, Checkpoints, Wiederaufnahmesperren und Idempotenzregeln.

## Datenmodell und Querschnitt

Neu: Enum 90114 `BCSF Generation Kind`, Codeunit 90259 `BCSF Master Data Source`; beide im freigegebenen Modulbereich. Keine neue Tabelle/Seite/Batchengine oder Runtime-Dependency. Setupfelder 29–36 halten die unveränderliche Startanforderung; Szenariofelder 45/46 halten Laufart und Quelle. Historische Werte erhalten Enumwert 0/Nullquelle. Keine ForceSync-Anweisung.

Das bestehende Dashboard zeigt Laufart, gewählte Module und Quelllauf in der Unternehmenszusammenfassung. Die Laufkarte liest Laufart/Quelle aus dem eingefrorenen Snapshot. Erzeugt-Zähler und Lauf-Drilldowns zählen neue Ergebnisse; vorhandene Stammdaten sind über den Quelllauf bzw. den Gesamtmandanten einsehbar. Keine doppelte Zählung wiederverwendeter Stammdaten als Neuanlage. Gemeinsame Finanzeinrichtung und Exportpaket bleiben bestehende Funktionen; keine automatische Paketanlage bei Installation. Neue Texte sind in Deutsch und Englisch einschließlich fünf deutscher Regionen gepflegt.
