# SF-041 – Daten im Mandanten

**Quellversion 1.0.4.0 · Zur Prüfung**

## Bedienung

Im bisherigen Scenario-Factory-Dashboard **Daten im Mandanten** verwenden. Erst die Auswahl eines Bereichs lädt Zahlen. Stammdaten, Verkauf, Einkauf und Bewegungsdaten liegen direkt zugänglich nebeneinander. Finanzen/Bank, Lager/Logistik, Fertigung/Montage, Projekte, Service, Anlagen und Kontakte stehen unter **Weitere Module**. Der Laufmonitor und die Einrichtungsvorprüfung aus SF-040 bleiben unverändert erreichbar.

| Auswahl | Inhalt |
| --- | --- |
| **Von Scenario Factory erzeugt** | Live-Datensätze mit bestätigter Herkunft im aktuellen Mandanten. Optional nach einem erfassten Lauf filtern. |
| **Gesamter Mandant** | Alle für den angemeldeten Benutzer in der jeweiligen Ansicht sichtbaren Daten inklusive manueller Anlagen und Standardbuchungen. Kein Lauf-Filter. |
| **Zahl als Schaltfläche** | Öffnet die zugehörige BC-Standardliste mit demselben serverseitigen Filter. Wenn der Bestand sich seit der Anzeige geändert hat, fordert das Dashboard zur Aktualisierung auf. |
| **0 / Status ohne Zahl** | 0 ist ein geprüfter leerer Bestand. Kein Generator, kein Zugriff und nicht zuverlässig abbildbare Filter sind eigene Zustände. Ein lesbarer Wert ohne unterstützte Standardliste erhält keine Schaltfläche. |

Die Herkunftsansicht deckt derzeit Debitoren, Kreditoren, Lieferadressen und Bestelladressen ab. Kontakte aus aktivierter Marketingintegration sind keine getrennt verbuchten Generatorergebnisse. Direkte Bankverbindungen, artikel- oder dokumentbezogene Generatoren sowie eine Herkunftszuordnung gebuchter Posten werden durch SF-041 nicht eingeführt. Die Auswahl „Gesamter Mandant“ zählt dafür auch vorhandene Standarddaten.

Verkauf und Einkauf trennen sechs offene Belegarten (Angebot, Rahmenauftrag/-bestellung, Auftrag/Bestellung, Rechnung, Gutschrift, Reklamation) und jeweils vier gebuchte Kopftabellen. Bewegungsdaten sind separat für Sach-, Debitoren-, Kreditoren-, Bank-, MwSt.-, Artikel- und Wertposten verfügbar. Es gibt keine addierte Beleg-/Posten-Gesamtsumme. Kontakt-Geschäftsbeziehungen sind eine reine Zählkachel ohne globale Standardliste. Zur Einzelansicht die Kontaktkarte nutzen.

## Technik und Grenzen

- Bestehendes Control Add-in und bestehende CardPart. Eine interne Codeunit 90369, keine neue Tabelle oder Seite. Ein expliziter Katalog ordnet jedem Schlüssel Quelle, Listenroute, Gruppe und Herkunftsunterstützung zu. Client-Kommandos wählen nur freigegebene Schlüssel. Tabellen, Seiten, Filterstrings, Mandant, Berechtigungen und angezeigte Anzahl werden **nicht** vom Client übernommen.
- Lesen unter Benutzer- und Unternehmenskontext, mit TableData-Leserecht und `SecurityFiltering::Filtered`. Eine Listenroute verlangt zusätzlich effektives Page-X. Verkaufs- und Einkaufsansichten berücksichtigen den aktuellen Standard-Zuständigkeitsfilter. Nicht übertragbare Filter und fehlerhafte Views fallen nicht auf unbeschränkte Listen zurück. Normale Standard-BC-Berechtigungsprüfungen bleiben aktiv. Die Codeunit trägt keine erhöhten Tabellendatenrechte.
- Herkunft basiert auf dem eindeutigen Paar aus Table-ID und System-ID. Gelöschte Datensätze und manuelle Wiederverwendung alter Primärschlüssel zählen nicht. Bei einer Umbenennung bleibt die System-ID maßgeblich. Für den Drilldown wird derselbe Filter aufgebaut wie für den sichtbaren Count und die Anzahl neu geprüft. Nachträgliche Änderungen außerhalb der Auswertung können auch native Live-Listen verändern.
- Es werden nur die Kennzahlen des angeforderten Bereichs geladen. Wechsel von Bereich, Umfang oder Lauf und **Aktualisieren** laden die aktive Gruppe neu. Bedienung der bestehenden Laufdiagnose startet keine Statistikabfrage. Es werden keine vollständigen Datensätze an das Control Add-in übertragen.
- Für zuverlässig übergebbare Herkunftsfilter gilt eine Grenze von 150 gefundenen IDs und 1.200 gesichteten Herkunftszeilen je Kennzahl. Oberhalb der Grenze wird keine scheinexakte Zahl oder unbeschränkte Liste angeboten. Einzelnen Lauf eingrenzen oder die bestehende Herkunftsliste für technische Nachverfolgung verwenden. Die Firmenansicht zählt über die gefilterte Standardtabelle ohne diese Herkunftsgrenze. Für eine spätere Skalierung den Filtervertrag in der Zielversion mit repräsentativem Datenbestand messen.
- Native Listen können in einer Kundenerweiterung zusätzliche Standardfilter oder Ansichten erhalten. Standard-Mappings und AL-APIs sind gegen öffentliche Microsoft-Referenzen geprüft. Verhalten in der real installierten Version, Anwendung von Filtergruppen und Laufzeiten müssen bei der Sandbox-Abnahme bestätigt werden.

## Sandbox-Abnahme zusammen mit SF-040

1. Quellprojekt gegen deine BC-Symbole bauen. Wenn die neuen XLIFF-IDs erzeugt wurden, `python3 Translations/sync_starter_translations.py` und danach `python3 scripts/build_dashboard_translations.py` ausführen, neu bauen und in der Sandbox installieren.
2. In einer initialisierten Sandbox ohne bestehende Erzeugnisse **Stammdaten** öffnen. Debitor und Kreditor sind bei vorhandenen Rechten echte 0. Artikel ist in der Herkunftsansicht als „Kein Generator verfügbar“ gekennzeichnet. In der Firmenansicht vorhandene manuelle Datensätze vergleichen.
3. Zwei kleine Partnerläufe ausführen, beispielsweise 2 und 3 Debitoren sowie 2 und 3 Kreditoren. Ein manueller Debitor bleibt außerhalb der Herkunftsansicht. Die Werte für Lieferadressen können je B2B/B2C-Ausprägung abweichen. **Aktualisieren** wählen. Je Lauf und für alle Läufe die Rechte, Zählung, geöffneten Listen und System-IDs vergleichen. Nach Umbenennung bleibt ein erzeugter Partner sichtbar. Ein gelöschter Partner zählt nach Aktualisierung nicht mehr.
4. Ein Verkaufsangebot, eine Einkaufsbestellung und mindestens einen standardmäßig gebuchten Posten manuell in der Sandbox anlegen. Im Umfang **Gesamter Mandant** die betreffenden Zähler und Listen prüfen. Andere Belegtypen dürfen nicht im gleichen Zähler stecken. In der Herkunftsansicht werden sie nicht als erzeugt ausgegeben.
5. Testbenutzer ohne TableData-R/ohne Page-X oder mit eingeschränktem Sicherheitsfilter bzw. Zuständigkeitsbereich prüfen. Erwartet sind kein vertraulicher Zähler bzw. nur der sichtbare Datenbestand. Nichts darf auf eine unbeschränkte Liste zurückfallen. Mit Tab/Enter die Bereiche und Zähler prüfen. Deutschen und englischen Sitzungsclient vergleichen.
6. In einer gesonderten Testfirma einen SF-040-Generatorblocker auslösen und nachweisen, dass kein fehlgeschlagener Lauf fälschlich geplante Ergebnisse erzeugt. Danach Ursache korrigieren, neuen kleinen Lauf ausführen und die Herkunftszahlen erneut abgleichen. Bei großem Herkunftsbestand die Meldung und Lauf-Eingrenzung sowie Laufzeiten dokumentieren.

## Microsoft-Referenzen

- [AL Page.Run und gefilterter Record](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-table-joker-method)
- [SetTable über einen typisierten Record](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-table-method)
- [Standard-Lieferadressen](https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/page/microsoft.sales.customer.ship-to-address-list) und [Standard-Bestelladressen](https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/page/microsoft.purchases.vendor.order-address-list)
- [Effektive Benutzerberechtigung](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.security.user.user-permissions)

## SF-044 – kompakter Arbeitsplatz (19.11.2026)

**Status: Zur Prüfung.** Im bestehenden Control Add-in sind **Daten** und **Läufe** getrennte Reiter. Daten öffnet zunächst Stammdaten; weitere Gruppen werden weiterhin erst bei Auswahl gezählt. Reiterwechsel ist lokal und löst keine neue BC-Abfrage aus. Die Auswahl unter Läufe ändert weder Umfang noch Lauf-Filter unter Daten. Scrollpositionen werden für die beiden Reiter während der geöffneten Ansicht getrennt bewahrt. Ein Neuladen des Arbeitsplatzes setzt die lokale Ansicht zurück.

Alle Bestandsgruppen verwenden dasselbe responsive Kachelraster. Die gesamte berechtigte Kachel öffnet die passende Standardliste; echte Nullbestände bleiben ohne Aktion, weil der bestehende Standardlistenvertrag kein zuverlässig leeres Ziel zusagt. Fehlender Zugriff bleibt ohne Zahl sichtbar. Entitäten ohne Generator werden ausschließlich in der Herkunftsansicht unter **Entitäten ohne Generator** gebündelt und standardmäßig eingeklappt. In der Mandantenansicht bleiben ihre tatsächlichen Bestände sichtbar. Der Umfang steht direkt am Raster.

Unter Läufe stehen Vorlagen-, Lauf- und Ausführungszähler, Laufwahl, Name, Status, Qualität, Entitätsfortschritt und nächste Aktion. Die Vorlagenkachel ist dort der direkte Vorlageneinstieg; im Datenreiter liegt dieser Einstieg in der Werkzeugleiste. Es gibt keinen zweiten eigenen Titel, keine Seitenleiste und keinen Einleitungstext. Der native BC-Rahmen bleibt unverändert. Filter und Überschriften verwenden keine Positionierung über dem Inhalt; das Add-in besitzt weiterhin seinen eigenen höhenbegrenzten Scrollbereich.

Fortschrittskacheln zeigen **Erzeugt / Ziel**, offen und den Schrittstatus direkt bei der Entität. Abgeschlossene Pakete bedeuten einen abgeschlossenen Entitätsschritt; die globale Laufqualität wird separat angezeigt. Liefer-/Bestelladressen erhalten fachlich bezeichnete eigene Live-Zähler. Bestätigte Arbeit und heute noch vorhandene Ergebnisse sind verschiedene Größen: Eine Fortschrittskachel öffnet eine Standardliste nur, wenn ihr aktueller Herkunftsbestand genau der bestätigten Menge entspricht. Nach Löschungen oder bei unsicheren Ergebnissen bleiben Fortschritt und aktueller Bestand getrennte Kacheln. Artefaktsummen und externe Prüfungen stehen nur unter Diagnose. **Bestanden** wird anhand der strukturierten Prüfseverity grün dargestellt. Der früheste Start erscheint nur für eingereihte/geplante Läufe. Die Hauptaktion bleibt kompakt, Diagnose ist zunächst eingeklappt.

### Filter- und Berechtigungsvertrag

- Daten- und Laufresultate nutzen denselben bestehenden Standardlisten-/Herkunftsdienst. Die Part hält `SelectedRunId`, `StockRunId`, `StockView` und `RunStock` getrennt. `runOpen` akzeptiert ausschließlich einen Kennzahlenschlüssel aus dem zuletzt serverseitig erzeugten Laufbestand; keine Clientfilter, Mengen oder Seiten-IDs.
- Der Vorlagenzähler berücksichtigt nur nicht archivierte Vorlagen, passend zur bestehenden Vorlagenliste. Der Laufzähler öffnet alle sichtbaren Laufköpfe. Aktive bzw. fehlgeschlagene Ausführungen öffnen bei bis zu 150 Einträgen genau die per Status ermittelten Lauf-IDs im bestehenden Laufmonitor. Über 150 Ausführungen bleibt die Zahl lesbar, der Drilldown wird mit einem Hinweis deaktiviert. Bei einer Abweichung zwischen sichtbaren Ausführungen und sichtbaren Laufköpfen gibt es ebenfalls keine Ersatzaktion.
- Jede Zählerroute prüft beim Klick Rechte, aktuellen Filter und Count erneut. Veränderte Mengen verlangen eine Aktualisierung. Kein erhöhter TableData-Zugriff, keine neuen Seiten, Tabellen, Feld-IDs, Commit-Grenzen oder Generatoren.
- Laufresultate lesen zusätzlich die vier bereits unterstützten Herkunftsentitäten für den gewählten Lauf. Grenzen von 150 Live-IDs und 1.200 Herkunftszeilen je Kennzahl gelten weiterhin. Laufzeiten in großen echten Mandanten sind **Zu prüfen**.

### Noch ausstehende Sandbox-Abnahme SF-044

1. In einer freigegebenen Testfirma 25 Debitoren insgesamt und einen bestätigten Lauf mit 20 davon bereitstellen. Unter Daten **Gesamter Mandant** muss die Kachel 25 öffnen; unter Läufe muss die 20/20-Kachel genau die 20 Laufdebitoren öffnen. System-IDs vergleichen. Daten zusätzlich auf einen anderen Lauf filtern, unter Läufe wechseln und nach Rückkehr den unveränderten Datenfilter nachweisen.
2. Liefer-/Bestelladressen des Laufs vergleichen. Einen erzeugten Debitor in einer isolierten Testfirma manuell löschen und aktualisieren: bestätigte Arbeit bleibt 20/20, der Live-Zähler ist 19 und öffnet 19 sichtbare Datensätze. Kein automatischer Wiederanlauf.
3. Leere Bestände, eine Entität ohne Generator, einen Benutzer ohne TableData-R/Page-X und einen fehlgeschlagenen Lauf vergleichen. Kein Zugriff zeigt keine vertrauliche Zahl; kein Generator liegt im eingeklappten Bereich; echte 0 ist keine Scheinaktion. In der Mandantenansicht bleiben vorhandene Daten unabhängig vom Generator sichtbar.
4. Vorlagen einschließlich archivierter Vorlage, alle Läufe sowie aktive/fehlgeschlagene Ausführungen mit ihren Ziellisten abgleichen. Mehr als 150 aktive oder fehlgeschlagene Ausführungen bzw. abweichende Sicherheitsfilter müssen eine deaktivierte Kennzahl mit Hinweis ergeben. Bestandsänderung vor Klick muss zur Aktualisierung auffordern.
5. In einer deutschen und englischen BC-Sitzung prüfen: geplant, laufend, abgeschlossen, Warnung, fehlgeschlagen. Ergebnisse öffnen ist kompakt; Bestanden ist grün; frühester Start erscheint nur bei geplant/eingereiht. Technische Aktionen sind unter Diagnose erreichbar; keine leere Aktionsgruppe.
6. Im echten Role-Center breit und schmal prüfen, insbesondere bei 320px und 500px Höhe. Mit Tab, Pfeiltasten, Enter und Leertaste bedienen; Fokus muss sichtbar bleiben, Filter dürfen nicht unter den BC-Kopf geraten. Native Zielseiten, deren Filter und Rechte sind durch lokale Browserprüfungen nicht abgenommen.

Lokale Nachweise und Grenzen: [SF-044 Prüfprotokoll](TESTS.md#sf-044--kompaktes-dashboard-und-direkte-kennzahlen).
