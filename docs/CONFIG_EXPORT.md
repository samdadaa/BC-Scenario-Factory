# Konfigurationspaket für vollständige Generator-Daten (SF-046)

**Version 1.0.8.1 · Zur Prüfung · Korrektur vom 22.11.2026 für Umgebungen mit vielen Firmen.** Der Nutzer bestätigt ausdrücklich den Export vollständiger Tabellen einschließlich bereits vorhandener Daten.

## Bedienung

1. App **1.0.8.1** in der vorgesehenen BC-Online-Sandbox installieren bzw. mit Upgrade aktualisieren. Installation und Upgrade erzeugen **keine Paketdefinitionen oder Felder** und rufen den Paketdienst nicht auf. Bestehende Pakete bleiben erhalten. Die alten Codeunit-IDs 90372/90373 bleiben mit leeren Triggern erhalten.
2. Den vorhandenen Unternehmensworkflow oder eine vorhandene Startvorlage ausführen und Abschluss/Fehler im Dashboard prüfen.
3. In die gewünschte Firma wechseln und im Dashboard oder Role-Center **Datenexportpaket vorbereiten** / **Prepare data export package** wählen. Erst diese ausdrückliche Aktion erstellt bzw. ergänzt **BCSF-ALL-DATA**, ausschließlich in der **aktuellen Firma**. Die erstmalige Vorbereitung von 128 Tabellen samt Feldern kann dauern; keine automatische Arbeit in anderen Firmen und kein Hintergrundjob. Danach ist das Paket auch über die BC-Suche **Konfigurationspakete** erreichbar.
4. Auf der Standard-Paketkarte **Nach Excel exportieren** wählen: BC erzeugt ein Blatt je exportierter Tabelle. Alternativ **Paket exportieren** für die Standarddatei `.rapidstart`. Über die Tabellenzeilen lassen sich aktuelle Datenbankdatensätze öffnen, soweit eine Standardseite hinterlegt ist. Für Tabellen ohne Standardseite den Excelexport verwenden.

Beim Export liest der Standard den **aktuellen Tabelleninhalt der aktuellen Firma**; es gibt keinen Lauf-, Präfix- oder SystemId-Filter. Auch vorhandene, nicht von der Factory erzeugte Datensätze sind enthalten. Der Exportumfang ist unabhängig von den Dashboardfiltern. Leere Tabellen bleiben enthalten. Das Paket muss nach einem Generatorlauf nicht neu befüllt werden.

Die Bereitstellung fügt nur fehlende Tabellen hinzu. Bestehende Namen, Kommentare, Feldauswahlen, Filter und zusätzliche Tabellen bleiben erhalten. Eigene Filter/Feldausschlüsse beeinflussen daher spätere Downloads; für einen vollständigen Export diese auf der Paketkarte prüfen. Ein bereits unter demselben Code angelegtes Fremdpaket ohne Kennung `BCSF-EXPORT/1` führt zum Fehler und wird nicht übernommen. Zur Auflösung das fremde Paket bewusst umbenennen; keine automatische Löschung oder Ersetzung.

## Umfang und Grenzen

Der Katalog enthält **128 symbolgeprüfte Standardtabellen** des derzeit implementierten Partner-/Artikel-/Einkaufs-/Verkaufs-/Zahlungspfads und der gemeinsamen Foundation. Er umfasst Stammbeziehungen, Einrichtungsreferenzen, offene und gebuchte Belegköpfe **und Zeilen**, Detailposten, Sach-/MwSt.-/Artikel-/Wert-/Bankposten, Register, Buchungsverknüpfungen, Dimensionen, CRM-Kontakte und Standardarchiv-/Lagernebenwirkungen. Einige Tabellen bleiben abhängig von Betriebsart und Standardsetup leer. Das Vorhandensein von Gutschrift-/Retouren- oder Archivtabellen im Export ist keine neue Generatorfähigkeit.

Alle vom Standard zugelassenen aktiven normalen Felder werden bei neuen Tabellen aufgenommen; zusätzlich die vom Standard sonst ausgelassene `Dimension Value ID`, damit Dimensionssatzeinträge zugeordnet werden können. FlowFields/FlowFilter, entfernte Felder und die fünf vom Standardfilter ausgeschlossenen System-/Auditfelder gehören nicht zum Feldumfang. Neue Felder in bereits vorhandenen Paketzeilen werden beim Upgrade absichtlich nicht automatisch zugeschaltet, damit eigene Feldauswahlen geschützt bleiben; bei Bedarf in der Standard-Feldauswahl ergänzen. Keine eigene Serialisierung oder Veränderung von BLOB-/Mediawerten. Standardgrenzen für Feldtypen, XML-Namen, Excelzeilen, Dateigröße und Laufzeit gelten weiterhin.

Dies ist ein **Auswertungs-/Exportpaket, kein Migration- oder Wiederherstellungspaket**. Gebuchte Posten dürfen nicht mit RapidStart reimportiert werden. Persistente interne Factory-Steuerungstabellen, System-/Sicherheitstabellen und nicht implementierte Fachmodule sind nicht Teil des Geschäftsdatenkatalogs. Beliebige Fremdextensions oder zukünftige Generatoren benötigen eine erneute Katalogprüfung; keine pauschale Vollständigkeitszusage für deren Nebenwirkungen.

Erforderlich sind Standardrechte für Paketverwaltung und direkte Leserechte auf jede exportierte Geschäftstabelle. `BCSF ADMIN` ergänzt nur Execute für den Paketdienst; keine Standard-TableData-Rechte oder erhöhten Codeunit-Permissions. Fehlende Rechte und Securityfilter können den Standardexport einschränken oder blockieren. Erst die ausdrückliche Paketaktion benötigt Rechte zum Anlegen der Standard-Paketdefinition; Installation/Upgrade führt diese Paketzugriffe nicht mehr aus. Das ist nativ mit der Zielrolle zu prüfen, kein Grund für automatische Rechteerhöhung.

Für einen in sich vergleichbaren Export zuerst die betreffenden Läufe abschließen und während des Downloads weitere Schreibvorgänge vermeiden. Der Standardexport ist kein atomarer Snapshot aller Tabellen. Große Datenmengen gegebenenfalls in ausgewählten Tabellen exportieren; Durchsatz und Downloadgrenzen sind nicht gemessen.

## Implementierung und Kompatibilität

`BCSF Config Export` (90371) enthält den statischen, typsicheren `Database::`-Katalog und wird ausschließlich durch die ausdrückliche Dashboard-/Role-Center-Aktion verwendet. `BCSF Config Export Install` (90372) und `BCSF Config Export Upgrade` (90373) besitzen seit 1.0.8.1 leere Trigger; keine indirekten Aufrufe, keine Paketanlage, keine Schleife über Firmen. Der Dienst prüft den echten SaaS-Sandboxkontext auch beim manuellen Aufruf, sperrt den Paketkopf und verwendet `Config. Package Management.InsertPackageTable` sowie den Standard-Tabellentrigger für die Felder. Keine eigenen Commits oder Schreib-TryFunctions. Die Paketkennung dient als Kollisionsschutz, nicht als Zugriffsberechtigung.

BC-28.5-Symbole aus den vorhandenen `.alpackages`, Application 28.0 / Runtime 17. App-ID, Publisher, Dependencies und ID-Bereich bleiben erhalten. Keine neuen eigenen Tabellen/Felder/Seiten und kein ForceSync. Historische Läufe, Snapshots, Vorlagen und Generatorkonfiguration bleiben erhalten.

**Querschnitt:** Dashboard/Role-Center sind der ausdrückliche Einstieg zur einmaligen Paketvorbereitung je gewünschter Firma; Workflow und Generatorläufe bleiben unverändert. Stammdaten und Einrichtungen werden nur durch den BC-Standardexport gelesen. Englische Quelltexte und deutsche XLIFF-Übersetzungen einschließlich regionaler Ableitungen sind gepflegt. Die bestehende Startermatrix ist für den Export ausreichend: Partner/Artikel, ungebucht, gebucht und Zahlung/Ausgleich einschließlich gemischter Belegquoten. Es gibt keine neue Generatoroption, deshalb keine Änderung eigener oder bestehender Starterwerte. [Export-Abnahme mit den vorhandenen Referenzen](STARTER_TEMPLATES.md#sf-046--exportprüfung-mit-vorhandenen-startvorlagen).

## Tabellen-IDs

Quelle: tatsächliche Tabellenobjekte und Namespaces in den lokalen Microsoft-Symbolpaketen, abgeglichen mit dem aktuellen AL-Katalog. „Direkt“ bedeutet im App-Quellcode als Record referenziert; „Standard/Referenz“ ergänzt Zeilen, Register, Verknüpfungen und bedingte Standardnebenwirkungen bzw. Einrichtungsreferenzen. Beide Gruppen werden gleichermaßen vollständig aufgenommen.

| ID | BC-Tabellenname | Nachweis |
| --- | --- | --- |
| 3 | Payment Terms | Direkt |
| 4 | Currency | Direkt |
| 9 | Country/Region | Direkt |
| 10 | Shipment Method | Standard/Referenz |
| 14 | Location | Direkt |
| 15 | G/L Account | Direkt |
| 17 | G/L Entry | Direkt |
| 18 | Customer | Direkt |
| 21 | Cust. Ledger Entry | Direkt |
| 23 | Vendor | Direkt |
| 25 | Vendor Ledger Entry | Direkt |
| 27 | Item | Direkt |
| 32 | Item Ledger Entry | Direkt |
| 36 | Sales Header | Direkt |
| 37 | Sales Line | Direkt |
| 38 | Purchase Header | Direkt |
| 39 | Purchase Line | Direkt |
| 43 | Purch. Comment Line | Standard/Referenz |
| 44 | Sales Comment Line | Standard/Referenz |
| 45 | G/L Register | Standard/Referenz |
| 46 | Item Register | Standard/Referenz |
| 80 | Gen. Journal Template | Direkt |
| 81 | Gen. Journal Line | Direkt |
| 82 | Item Journal Template | Standard/Referenz |
| 83 | Item Journal Line | Standard/Referenz |
| 84 | Acc. Schedule Name | Direkt |
| 85 | Acc. Schedule Line | Direkt |
| 88 | Financial Report | Direkt |
| 90 | BOM Component | Direkt |
| 92 | Customer Posting Group | Direkt |
| 93 | Vendor Posting Group | Direkt |
| 94 | Inventory Posting Group | Direkt |
| 97 | Comment Line | Standard/Referenz |
| 98 | General Ledger Setup | Direkt |
| 99 | Item Vendor | Direkt |
| 110 | Sales Shipment Header | Direkt |
| 111 | Sales Shipment Line | Standard/Referenz |
| 112 | Sales Invoice Header | Direkt |
| 113 | Sales Invoice Line | Direkt |
| 114 | Sales Cr.Memo Header | Direkt |
| 115 | Sales Cr.Memo Line | Standard/Referenz |
| 120 | Purch. Rcpt. Header | Direkt |
| 121 | Purch. Rcpt. Line | Direkt |
| 122 | Purch. Inv. Header | Direkt |
| 123 | Purch. Inv. Line | Direkt |
| 124 | Purch. Cr. Memo Hdr. | Standard/Referenz |
| 125 | Purch. Cr. Memo Line | Standard/Referenz |
| 167 | Job | Direkt |
| 169 | Job Ledger Entry | Direkt |
| 203 | Res. Ledger Entry | Direkt |
| 204 | Unit of Measure | Direkt |
| 222 | Ship-to Address | Direkt |
| 224 | Order Address | Direkt |
| 225 | Post Code | Standard/Referenz |
| 230 | Source Code | Direkt |
| 232 | Gen. Journal Batch | Direkt |
| 233 | Item Journal Batch | Standard/Referenz |
| 242 | Source Code Setup | Direkt |
| 246 | Requisition Line | Direkt |
| 250 | Gen. Business Posting Group | Direkt |
| 251 | Gen. Product Posting Group | Direkt |
| 252 | General Posting Setup | Direkt |
| 253 | G/L Entry - VAT Entry Link | Standard/Referenz |
| 254 | VAT Entry | Direkt |
| 270 | Bank Account | Direkt |
| 271 | Bank Account Ledger Entry | Direkt |
| 277 | Bank Account Posting Group | Direkt |
| 287 | Customer Bank Account | Direkt |
| 288 | Vendor Bank Account | Direkt |
| 289 | Payment Method | Direkt |
| 291 | Shipping Agent | Standard/Referenz |
| 308 | No. Series | Direkt |
| 309 | No. Series Line | Direkt |
| 310 | No. Series Relationship | Standard/Referenz |
| 311 | Sales & Receivables Setup | Direkt |
| 312 | Purchases & Payables Setup | Direkt |
| 313 | Inventory Setup | Direkt |
| 315 | Jobs Setup | Direkt |
| 323 | VAT Business Posting Group | Direkt |
| 324 | VAT Product Posting Group | Direkt |
| 325 | VAT Posting Setup | Direkt |
| 330 | Currency Exchange Rate | Direkt |
| 333 | Column Layout Name | Direkt |
| 334 | Column Layout | Direkt |
| 336 | Tracking Specification | Standard/Referenz |
| 337 | Reservation Entry | Standard/Referenz |
| 339 | Item Application Entry | Standard/Referenz |
| 343 | Item Application Entry History | Standard/Referenz |
| 348 | Dimension | Direkt |
| 349 | Dimension Value | Direkt |
| 352 | Default Dimension | Direkt |
| 379 | Detailed Cust. Ledg. Entry | Direkt |
| 380 | Detailed Vendor Ledg. Entry | Direkt |
| 480 | Dimension Set Entry | Standard/Referenz |
| 481 | Dimension Set Tree Node | Standard/Referenz |
| 589 | G/L Account Source Currency | Standard/Referenz |
| 900 | Assembly Header | Direkt |
| 905 | Assembly Setup | Direkt |
| 910 | Posted Assembly Header | Direkt |
| 1001 | Job Task | Direkt |
| 1003 | Job Planning Line | Direkt |
| 5050 | Contact | Direkt |
| 5053 | Business Relation | Direkt |
| 5054 | Contact Business Relation | Direkt |
| 5071 | Campaign | Direkt |
| 5079 | Marketing Setup | Direkt |
| 5085 | Contact Duplicate | Standard/Referenz |
| 5086 | Cont. Duplicate Search String | Standard/Referenz |
| 5092 | Opportunity | Direkt |
| 5095 | Duplicate Search String Setup | Standard/Referenz |
| 5107 | Sales Header Archive | Standard/Referenz |
| 5108 | Sales Line Archive | Standard/Referenz |
| 5109 | Purchase Header Archive | Standard/Referenz |
| 5110 | Purchase Line Archive | Standard/Referenz |
| 5400 | Unit Group | Standard/Referenz |
| 5401 | Item Variant | Direkt |
| 5404 | Item Unit of Measure | Direkt |
| 5405 | Production Order | Direkt |
| 5600 | Fixed Asset | Direkt |
| 5601 | FA Ledger Entry | Direkt |
| 5603 | FA Setup | Direkt |
| 5700 | Stockkeeping Unit | Direkt |
| 5715 | Item Substitution | Direkt |
| 5722 | Item Category | Direkt |
| 5740 | Transfer Header | Direkt |
| 5741 | Transfer Line | Direkt |
| 5744 | Transfer Shipment Header | Direkt |
| 5745 | Transfer Shipment Line | Direkt |
| 5746 | Transfer Receipt Header | Direkt |
| 5769 | Warehouse Setup | Standard/Referenz |
| 5772 | Registered Whse. Activity Hdr. | Direkt |
| 5777 | Item Reference | Direkt |
| 5790 | Shipping Agent Services | Standard/Referenz |
| 5802 | Value Entry | Direkt |
| 5811 | Post Value Entry to G/L | Standard/Referenz |
| 5813 | Inventory Posting Setup | Direkt |
| 5823 | G/L - Item Ledger Relation | Direkt |
| 5896 | Inventory Adjmt. Entry (Order) | Standard/Referenz |
| 5900 | Service Header | Direkt |
| 5911 | Service Mgt. Setup | Direkt |
| 5940 | Service Item | Direkt |
| 6507 | Item Entry Relation | Standard/Referenz |
| 6508 | Value Entry Relation | Standard/Referenz |
| 6509 | Whse. Item Entry Relation | Standard/Referenz |
| 6650 | Return Shipment Header | Standard/Referenz |
| 6651 | Return Shipment Line | Standard/Referenz |
| 6660 | Return Receipt Header | Direkt |
| 6661 | Return Receipt Line | Standard/Referenz |
| 7302 | Bin Content | Direkt |
| 7311 | Warehouse Journal Line | Standard/Referenz |
| 7312 | Warehouse Entry | Standard/Referenz |
| 7313 | Warehouse Register | Standard/Referenz |
| 7354 | Bin | Direkt |
| 7500 | Item Attribute | Direkt |
| 7501 | Item Attribute Value | Direkt |
| 7505 | Item Attribute Value Mapping | Direkt |

## Quellen und Prüfstatus

Die lokalen Originalquellen von `Config. Package Table`, `Config. Package Management`, `Config. XML Exchange` und `Config. Excel Exchange` sind für den konkreten API-/Feldvertrag maßgeblich. Microsoft beschreibt [Standardpakete, Rechte und Importgrenzen](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/set-up-standard-company-configuration-packages) sowie [den Excelexport je Tabelle](https://learn.microsoft.com/en-us/dynamics365/business-central/across-import-data-configuration-packages). Dokumentationsprüfung am 22.11.2026.

Lokale Prüfergebnisse und offene native Abnahme stehen in [TESTS.md](TESTS.md#sf-046--konfigurationspaket-für-vollständige-generator-daten). Kein Deployment und keine erfolgreiche BC-Exportausführung aus dem lokalen Build ableiten.
