# SF-038 / SF-039 – Finanzeinrichtung und Partnerdaten

Stand: 18.11.2026. Beide Tickets ausdrücklich gemeinsam beauftragt, Reihenfolge Finance → Partner. Status **Zur Prüfung**, keine fachliche Abnahme. Maßgeblich ist der aktuelle Workspace einschließlich der zuvor vorhandenen JSON-/Queue-/Übersetzungsfixes. Keine Änderungen an SF-040 bis SF-042.

## Ziel, Eingriffe und Grenzen

Ein gemeinsamer, ausdrücklich bestätigter Finance-Pfad ersetzt den Zwei-Konten-Schnellstart. Neue Partnerläufe erhalten natürliche synthetische Werte und überprüfbare Kinddatensätze. Betroffen: bestehende Finance-Dienste und Vorschauseiten, Quick Run, Starterkatalog, Szenariokarte/Assistent/Transfer/Snapshot, Partnergeneratoren/Regeln, Herkunftsliste, Berechtigungssatz und Übersetzungen. Neue interne Codeunits: 90257 Partner Catalog und 90258 Partner Children, im freien DataGeneration-Bereich 90250–90274. Keine Bestandsobjekte verschoben oder umbenannt, keine neuen AL-Testobjekte.

Risiken: wirkliche Standardtrigger, Marketingintegration, Dimensionen, Nummernserien, Rechte und implizite Commits benötigen BC-Abnahme. Keine Produktionsänderung, keine automatische Altbestandsbereinigung und kein Deployment. Standardtabellenrechte werden nicht erhöht. Keine neuen Beleg-, Artikel- oder Buchungsgeneratoren.

## SF-038 – Ursache und neuer Ablauf

`BCSF Quick Scenario Run` rief zuvor `BCSF Demo Partner Setup` auf. Dieser Sonderpfad legte BCSF-AR/BCSF-AP und BCSF-DEMO-Gruppen an und umging den gemeinsamen Finanzpaketvertrag. Der Aufruf ist entfernt; die vorhandene Codeunit 90408 bereitet jetzt ausschließlich die geprüfte Grundlage eines ausdrücklich angewendeten Finanzpakets vor. Im gesamten aktuellen `src/` gibt es keinen Schreibpfad mehr für BCSF-AR/AP. Die reservierte alte Gruppenkennung wird im Schnellstart nur noch zur Erkennung des alten Einrichtungsfalls gelesen.

Neue Starter verwenden SKR03 und NET00/14/30/60. Bestehende Starter werden beim Laden weder umgestellt noch überschrieben. Für sie führt **Finanzeinrichtung prüfen** zur gemeinsamen Auswahl/Vorschau. Ein bestehender eigener Modus verwendet seine Einstellungen weiter; die Partnerprüfung bindet weiterhin genau die ausgewählten Gruppen und Konten. Die Vorschau für vorhandene Einrichtung prüft zusätzlich nutzbare Sachkonten-Kandidaten in allgemeinen, MwSt.-, Lager- und Bankbuchungsgruppen. Neue Captures mit eigener vorhandener Einrichtung führen diese lesende Gesamtprüfung auch beim Start aus; historische Setupversion 1 behält ihre bisherigen Voraussetzungen. Das ist keine Zusicherung für jede fremde Beleg-/Steuerkombination: Vor Standardbuchungen die konkret verwendeten Kombinationen prüfen.

In einer neuen unbebuchten Sandbox: SKR03 oder SKR04 wählen → Vorschau prüfen → **Testpaket anwenden** ausdrücklich bestätigen → ggf. Zuordnung zur Vorlage bestätigen. Leere Nummernserienzuordnungen dürfen in diesem bestätigten Paket ergänzt werden. Gefüllte vorhandene Werte bleiben erhalten und müssen nutzbar sein. Konflikte und fehlende effektive Rechte blockieren; kein Überschreiben inkompatibler Konten. Nur der UI-Einstieg speichert die bearbeitete Vorlage vor dem modalen Dialog explizit. `Apply`, Generierung, Herkunft, Checkpoint und Paketabschluss behalten ihre bisherigen atomaren Grenzen und Commit-Sperren.

### Paketumfang 2.0.0 / Bezugsjahr 2026

Lokal erstellte, SKR03-/SKR04-basierte Teilpläne, keine vollständigen offiziellen DATEV-Kontenrahmen. Keine offiziellen Kontenbeschreibungen importiert, kein Scraping und keine Laufzeitdownloads. Die Nummern orientieren sich am jeweiligen Rahmen; Zwischen-, Abgrenzungs- und Summenkonten sind projektspezifische Ergänzungen. Kontenbeschreibungen werden bei Neuanlage lokalisiert gespeichert, bestehende Namen nicht umgeschrieben.

| Rolle | SKR03 | SKR04 | Direkte Buchung |
| --- | --- | --- | --- |
| Bank | 1200 | 1800 | Ja |
| Kasse | 1000 | 1600 | Ja |
| Forderungen | 1400 | 1200 | Nein |
| Verbindlichkeiten | 1600 | 3300 | Nein |
| Warenbestand | 3980 | 1140 | Nein |
| Vorsteuer 19 % | 1576 | 1406 | Nein |
| Umsatzsteuer 19 % | 1776 | 3806 | Nein |
| Eigenkapital | 0800 | 2900 | Ja |
| Inlandserlöse 19 % | 8400 | 4400 | Ja |
| Wareneinkauf 19 % | 3400 | 5400 | Ja |
| Wareneinsatz/Bestandsänderung | 3960 | 5880 | Nein |
| Sonstige Betriebskosten | 4900 | 6300 | Ja |
| Bürobedarf | 4930 | 6815 | Ja |
| Lagerzwischenkonto | 3970 | 1190 | Nein |
| Lagerabgrenzung | 1790 | 3390 | Nein |

Je 15 Buchungskonten plus 3 nicht direkt bebuchbare Summenkonten 1998/3998/9998. Summen verwenden explizite Kontenlisten. Klassifikation und Bilanz/GuV-Zuordnung werden geprüft. Erlös-/Einkaufskonten tragen passende Produkt-/MwSt.-Produktgruppen und Buchungsart für Standard-Sachkontenzeilen. Neue Gruppen INLAND03/INLAND04 verbinden Debitor, Kreditor, Bank, Lager, allgemeine und Inland-19%-MwSt.-Einrichtung; keine generischen Testnamen in diesen Gruppen. Die vorhandenen Standard-Finanzberichte SF03-BS/SF03-PL bzw. SF04-BS/SF04-PL bleiben mit expliziten Rollenlisten und nachvollziehbaren Formeln verbunden; die Bilanz berücksichtigt das laufende Ergebnis.

Paketgrundlage: EUR bei fehlender Hauptbuchgrundzeile, DE bei fehlendem Land, fehlende Verkaufs-/Einkaufs-/Lager-/Marketinggrundzeilen, vorhandene nichtleere Serien unverändert oder fehlende Bindungen mit CUSTOMER/VENDOR, Rechnungs-/Buchungs-/Lieferungs-/Wareneingangsserien und ITEM; NET00/14/30/60; fehlende Herkunftscodes und Zuordnungen für Verkauf/Einkauf/Fibu, ggf. allgemeine Buchblattvorlage. Kein künstlicher Lagerort und keine CRM-Integration. Obligatorischer Lagerort ohne nutzbaren vorhandenen Ort, Rechnungsrundung ohne unterstützten Kontenvertrag und inkompatible vorhandene Grundlagen blockieren. Anwendung prüft nach den Änderungen nochmals die tatsächliche Grundlage; Fehler verwerfen die Pakettransaktion.

**Altbestand:** Bereits angewendete Pakete 1.0.0 behalten Identität, 14 Konten, alte Gruppen, direkte Buchbarkeit und alte Berichtsdefinitionen. Version 2 ist ausschließlich der Neuinstallationsvertrag, keine stille Migration. Snapshots speichern die tatsächlich angewendete Version. Bestehende Ersatzkonten BCSF-AR/AP bleiben ebenfalls erhalten. Für ein vollständiges neues Paket eine frische Testfirma verwenden oder vorhandene Einrichtung nach separater fachlicher Prüfung auswählen; keine bebuchten Konten umhängen oder historische Läufe verändern.

## SF-039 – versionierte Partnerwerte

Neue Captures frieren `syntheticRules.version=2` und `partnerSetup.version=2` ein. Seed-Engine/Name-Katalogbasis und Generatorbindung bleiben Version 1; die neue Regelversion wählt den neuen Partnerkatalog. Alte Regel-/Setupversion 1 wird weiterhin unverändert gelesen und erzeugt bei Prüfung dieselben bisherigen Werte. Keine Migration historischer Snapshots oder Partner. Die read-only Namensvorschau auf Vorlagen- und neuer Laufkarte verwendet denselben Katalog und die gleiche Seed-/B2C-Auswahl; historische Laufkarten behalten ihre bisherige Vorschau. Die Szenarioebene veröffentlicht dafür einen Vorschauvertrag, den DataGeneration bedient, ohne umgekehrte Fachmodulabhängigkeit oder gespeicherten Lauf anzulegen.

Lokal erstellte Namensbausteine: DE/EN je 32 Vornamen × 64 Nachnamen; je 32 Firmenstämme × 32 allgemeine Tätigkeiten × 4 Rechtsformen. Sechs Branchen verwenden stattdessen je 8 passende Tätigkeiten (Beratung, Bau, Service, Fertigung, Distribution, E-Commerce). Je nach Profil 1.024 oder 4.096 Firmenkombinationen, 2.048 Personen; danach sind Namenswiederholungen möglich. Seed/Profil/Entität legen einen festen Versatz fest, eine teilerfremde Permutation verteilt logische Schlüssel ohne Wiederholung innerhalb des jeweiligen Zyklus. Namen sind keine technischen Identitäten; Herkunft und BC-Nummer bleiben unabhängig. Keine Personendaten importiert und keine Garantie, dass eine Kombination nicht zufällig einem wirklichen Namen entspricht.

Adressen verwenden für DE und GB jeweils acht konsistente PLZ-/Ortspaare, 16 Straßenbausteine und Hausnummern. Datensprache und Land sind getrennt: Sprache steuert Namen/Tätigkeiten, Land steuert Adresse und Rechtsform. Andere Länder blockieren vor der ersten Partneranlage; das Inland-Finanzpaket unterstützt weiterhin nur DE. Liefer-/Bestelladressen besitzen eigene deterministische Streams. E-Mails verwenden ausschließlich `contact.invalid`; keine Zustellung vorgesehen. Keine künstlichen Test-/Demo-Präfixe oder eckigen Zählersuffixe in neuen Partnerwerten. Der alte Katalog bleibt nur für alte Snapshots erhalten.

B2B-Debitoren erhalten eine Standard-Lieferadresse DELIVERY und den entsprechenden Standard-Lieferadresscode. B2C-Debitoren benötigen keine künstliche zweite Adresse. Kreditoren erhalten eine Standard-Bestelladresse ORDER. Felder laufen über Standardvalidierung, Datensätze über Standardinsert. Jede Adresse wird mit stabiler SystemId, gleichem Lauf/Paket/logischem Schlüssel und Parent Entry Id zum primären Partner registriert. Abschluss/Recovery prüfen Adresse, Elternzuordnung, Identität und Mengen erneut. `processedUnits` zählt Partner; `createdRecords` zählt Partner plus registrierte Kindartefakte. Ein Wiederanlauf führt unsichere Arbeit weiterhin nicht erneut aus.

Ansprechpartner werden in den Partner-/Adressfeldern natürlich erzeugt. Eine bereits konfigurierte BC-Marketingintegration bleibt unter ihren bisherigen Standardtriggern aktiv und wird vorab auf eingefrorene Relation/Serie und Rechte geprüft. Eine fehlende CRM-Integration wird nicht automatisch eingeschaltet; dieser Auftrag behauptet keine zusätzlichen autonomen Kontaktgeneratoren.

Optionale vorhandene Währung, Zahlungsform und Werte der beiden globalen Dimensionen sind in Karte/Assistent auswählbar und werden eingefroren, vorab geprüft und standardvalidiert übernommen. Leer bedeutet Mandantenwährung bzw. keine zusätzliche Zahlungsform/Dimension. Für Fremdwährungen ist ein nutzbarer Kurs am Startdatum erforderlich. Import/Export überträgt die vier optionalen Einstellungen additiv in Schema 1; alte Dateien bleiben lesbar. Fehlende Zielcodes werden beim Import konkret gemeldet; es startet kein Lauf.

**Zahlungsbereitschaft:** Kein freigegebener synthetischer Bankdatensatz liegt vor. Deshalb werden keine Partnerbankverbindungen oder bevorzugten Bankkonten erzeugt und keine Zahlungsprozesse als bereit ausgewiesen. Karte und Assistent nennen diese Grenze ausdrücklich. Zahlungsform alleine bedeutet keine sichere Zahlungsbereitschaft. Bankformate/Zahlungszeilen benötigen einen eigenen freigegebenen Prüfdatensatz und BC-Abnahme; keine erfundenen IBANs oder Zahlungsexporte.

## Reale Prüfung und offene Abnahme

Lokale Prüfungen und Paketnachweis stehen in [TESTS.md](TESTS.md); ausführbare Schritte und Sollbeträge in der [Testanleitung](review/TESTANLEITUNG.md). Ein Build oder Katalogcheck ersetzt keine BC-Standardvalidierung, keine Buchung und keinen Scheduler-Test. Nicht ausgeführt: zwei frische Firmen SKR03/SKR04, idempotente Anwendung, vorhandene Einrichtung, Standardbuchungen/Bilanz/GuV, DE 50/50 und EN, Belegübernahme, Kinddatensatz-/Rechte-/Rollback-/Recoveryfälle und firmengrenzender Sammeltransfer. Keine angebundene BC-Sandboxsteuerung verfügbar; installierter Paketstand bleibt zu prüfen.
