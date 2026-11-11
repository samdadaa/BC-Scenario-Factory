# Objektplan und Modulgrenzen – SF-002

**Stand:** 11.11.2026, zur Prüfung. Dies ist ein Entwicklungsplan, keine implementierte Funktion und keine Implementierungsfreigabe für Folgetickets. Historischer SF-002-Stand: 0 AL-Objekte und 24 leere Modulordner. Aktuell sind die unten aufgeführten Grundlagen aus SF-003/SF-004 implementiert; weitere Zeilen bleiben Planung. Grundlage ist die vom Nutzer bestätigte aktuelle Manifest-Range `90100..90999` (900 ID-Werte), Ziel `Playground`, Entwicklungsmodus. Die frühere Auswahl `50100..50999` ist abgelöst.

## Umfang, Voraussetzungen und Prüfweg

Ziel: eindeutige Namen, Ablage, ID-Zuordnung und Verantwortungsgrenzen vor dem ersten AL-Objekt festlegen. Betroffen: dieser Plan, CONVENTIONS, ARCHITECTURE, PROJECT, DECISIONS, TESTS, Modulindex und die 24 Modulspezifikationen sowie README und ausschließlich SF-002 in TODO. Manifest, Launch-Konfiguration und Modulverzeichnisse bleiben unverändert.

SF-001 bleibt separat offen/blockiert: Publisher, reale BC-Version/Lokalisierung, Testfirma, Rechte und externe ID-Belegung sind nicht geklärt. Diese Punkte verhindern keine lokale Dokumentationsplanung, bleiben aber Voraussetzungen für die jeweilige Implementierung und Sandbox-Verifikation. Standard-BC-API-Namen, Feldschemas und Signaturen werden erst im betreffenden Ticket anhand echter Symbole festgelegt. Keine Kundendaten, BC-Schreiboperationen oder zusätzlichen Laufzeitabhängigkeiten.

Prüfweg: alle Modulblöcke und Plan-IDs gegen app.json, Eindeutigkeit/Länge der Namen und Pfade, Vollständigkeit der 24 Module, Zyklenfreiheit des geplanten Codegraphen, unveränderte Konfiguration/andere Tickets sowie Markdown-Links und Diff prüfen. Risiken: externe Kollisionen, spätere Erweiterung des Objektbedarfs, nicht kompilierte Signaturen. Positive Fälle: eindeutige Zuordnung; negative Fälle: überlappende/außerhalb liegende IDs, doppelte Namen, fehlende Module und Zyklen müssen bei der Planprüfung auffallen. BC-Berechtigungs-, Retry- und Teilfehlertests sind hier mangels Laufzeitänderung nicht anwendbar.

## ID-Zuordnung

25 numerische Werte je Modul, insgesamt 600; `90700..90999` (300) gemeinsame Reserve. Ein Wert wird im Plan nur einmal verwendet, auch über Objekttypen hinweg; das ist eine konservative Projektregel, keine Behauptung einer AL-Pflicht. Unbelegte Werte sind Modulreserve, keine erzeugten Objekte. Interfaces erhalten keine deklarierte numerische Objekt-ID. Test-App-IDs werden nicht vorweg reserviert (SF-025).

Vor jedem neuen Objekt ID und Name gegen diesen Plan, aktuellen Quellcode und verfügbare Fremd-App-Metadaten prüfen. Bei ausgeschöpftem Block den Plan ausdrücklich aktualisieren, keine stillen Doppelbelegungen oder IDs außerhalb des Manifests. Diese Planung belegt nur lokale Konfliktfreiheit.

| Modul | Von | Bis | Namespace | Erlaubte direkte Projekt-Codeabhängigkeiten |
| --- | --- | --- | --- | --- |
| Core | 90100 | 90124 | `BCScenarioFactory.Core` | Keine |
| ScenarioManagement | 90125 | 90149 | `BCScenarioFactory.ScenarioManagement` | Core, ModuleRegistry |
| IndustryProfiles | 90150 | 90174 | `BCScenarioFactory.IndustryProfiles` | Core, ModuleRegistry, ScenarioManagement |
| ModuleRegistry | 90175 | 90199 | `BCScenarioFactory.ModuleRegistry` | Core |
| DependencyManager | 90200 | 90224 | `BCScenarioFactory.DependencyManager` | Core, ScenarioManagement, ModuleRegistry, SetupManager |
| SetupManager | 90225 | 90249 | `BCScenarioFactory.SetupManager` | Core, ScenarioManagement, ModuleRegistry |
| DataGeneration | 90250 | 90274 | `BCScenarioFactory.DataGeneration` | Core, ScenarioManagement |
| ProcessEngine | 90275 | 90299 | `BCScenarioFactory.ProcessEngine` | Core, ScenarioManagement, DataGeneration, Lifecycle |
| BackgroundProcessing | 90300 | 90324 | `BCScenarioFactory.BackgroundProcessing` | Core, ScenarioManagement, ModuleRegistry, DependencyManager, SetupManager, DataGeneration, ProcessEngine, Lifecycle, Validation |
| Validation | 90325 | 90349 | `BCScenarioFactory.Validation` | Core, ScenarioManagement, DataGeneration |
| Monitoring | 90350 | 90374 | `BCScenarioFactory.Monitoring` | Core, ScenarioManagement, BackgroundProcessing, Validation |
| Lifecycle | 90375 | 90399 | `BCScenarioFactory.Lifecycle` | Core, ScenarioManagement |
| Finance | 90400 | 90424 | `BCScenarioFactory.Finance` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Sales | 90425 | 90449 | `BCScenarioFactory.Sales` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Purchasing | 90450 | 90474 | `BCScenarioFactory.Purchasing` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Inventory | 90475 | 90499 | `BCScenarioFactory.Inventory` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Warehouse | 90500 | 90524 | `BCScenarioFactory.Warehouse` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Manufacturing | 90525 | 90549 | `BCScenarioFactory.Manufacturing` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Assembly | 90550 | 90574 | `BCScenarioFactory.Assembly` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Projects | 90575 | 90599 | `BCScenarioFactory.Projects` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| ServiceManagement | 90600 | 90624 | `BCScenarioFactory.ServiceManagement` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| FixedAssets | 90625 | 90649 | `BCScenarioFactory.FixedAssets` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| CRM | 90650 | 90674 | `BCScenarioFactory.CRM` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |
| Planning | 90675 | 90699 | `BCScenarioFactory.Planning` | Core, ScenarioManagement, ModuleRegistry, SetupManager, DataGeneration, ProcessEngine, Lifecycle |

## Geplante Objekte

Die Tabelle ist der vollständige Plan. Vorhandene Dateien sind im Abschnitt „Implementierter Stand SF-003/SF-004“ aufgeführt; alle übrigen Zeilen sind ausschließlich Reservierungen. Die Verantwortung ergibt sich aus dem Modulauftrag und dem genannten Umsetzungsticket. Seiten delegieren fachliche Aktionen an die zugehörige Management-/Generator-Codeunit. Die in einem Modul vorgesehenen Tabellen werden nur über dessen Geschäftsregeln verändert. Enumwerte, Felder, Schlüssel, Permission-Umfang und Page-Typen sind im Umsetzungsticket festzulegen.

| Modul | Plan-ID | Typ | Objektname | Geplanter Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| Core | 90100 | Table | `BCSF Factory Setup` | `src/Core/BCSFFactorySetup.Table.al` | SF-004 |
| Core | 90101 | Page | `BCSF Factory Setup Card` | `src/Core/BCSFFactorySetupCard.Page.al` | SF-004 |
| Core | 90102 | Enum | `BCSF Run Status` | `src/Core/BCSFRunStatus.Enum.al` | SF-004 |
| Core | 90103 | Enum | `BCSF Process Mode` | `src/Core/BCSFProcessMode.Enum.al` | SF-004 |
| Core | 90104 | Enum | `BCSF Usage Mode` | `src/Core/BCSFUsageMode.Enum.al` | SF-004 |
| Core | 90105 | PermissionSet | `BCSF ADMIN` | `src/Core/BCSFADMIN.PermissionSet.al` | SF-003 |
| Core | 90106 | Codeunit | `BCSF Setup Management` | `src/Core/BCSFSetupManagement.Codeunit.al` | SF-004 |
| Core | 90107 | Codeunit | `BCSF Run State Mgt` | `src/Core/BCSFRunStateMgt.Codeunit.al` | SF-004 |
| ScenarioManagement | 90125 | Table | `BCSF Scenario` | `src/ScenarioManagement/BCSFScenario.Table.al` | SF-005 |
| ScenarioManagement | 90126 | Table | `BCSF Scenario Module` | `src/ScenarioManagement/BCSFScenarioModule.Table.al` | SF-005 |
| ScenarioManagement | 90127 | Table | `BCSF Data Target` | `src/ScenarioManagement/BCSFDataTarget.Table.al` | SF-006 |
| ScenarioManagement | 90128 | Table | `BCSF Run Header` | `src/ScenarioManagement/BCSFRunHeader.Table.al` | SF-005 |
| ScenarioManagement | 90129 | Table | `BCSF Run Step` | `src/ScenarioManagement/BCSFRunStep.Table.al` | SF-008 |
| ScenarioManagement | 90130 | Codeunit | `BCSF Scenario Manager` | `src/ScenarioManagement/BCSFScenarioManager.Codeunit.al` | SF-005 |
| ScenarioManagement | 90131 | Page | `BCSF Scenario Card` | `src/ScenarioManagement/BCSFScenarioCard.Page.al` | SF-005 |
| ScenarioManagement | 90132 | Page | `BCSF Scenario Wizard` | `src/ScenarioManagement/BCSFScenarioWizard.Page.al` | SF-015 |
| ScenarioManagement | 90133 | Page | `BCSF Scenario List` | `src/ScenarioManagement/BCSFScenarioList.Page.al` | SF-005 |
| ScenarioManagement | 90134 | Table | `BCSF Run Snapshot` | `src/ScenarioManagement/BCSFRunSnapshot.Table.al` | SF-005 |
| IndustryProfiles | 90150 | Table | `BCSF Industry Profile` | `src/IndustryProfiles/BCSFIndustryProfile.Table.al` | SF-023 |
| IndustryProfiles | 90151 | Table | `BCSF Profile Rule` | `src/IndustryProfiles/BCSFProfileRule.Table.al` | SF-023 |
| IndustryProfiles | 90152 | Codeunit | `BCSF Profile Resolver` | `src/IndustryProfiles/BCSFProfileResolver.Codeunit.al` | SF-023 |
| IndustryProfiles | 90153 | Codeunit | `BCSF Wholesale Profile` | `src/IndustryProfiles/BCSFWholesaleProfile.Codeunit.al` | SF-023 |
| ModuleRegistry | 90175 | Table | `BCSF Generator Registry` | `src/ModuleRegistry/BCSFGeneratorRegistry.Table.al` | SF-007 |
| ModuleRegistry | 90176 | Enum | `BCSF Generator Type` | `src/ModuleRegistry/BCSFGeneratorType.Enum.al` | SF-007 |
| ModuleRegistry | 90177 | Codeunit | `BCSF Generator Registry Mgt` | `src/ModuleRegistry/BCSFGeneratorRegistryMgt.Codeunit.al` | SF-007 |
| DependencyManager | 90200 | Table | `BCSF Dependency` | `src/DependencyManager/BCSFDependency.Table.al` | SF-008 |
| DependencyManager | 90201 | Codeunit | `BCSF Dependency Planner` | `src/DependencyManager/BCSFDependencyPlanner.Codeunit.al` | SF-008 |
| SetupManager | 90225 | Table | `BCSF Setup Diff` | `src/SetupManager/BCSFSetupDiff.Table.al` | SF-009 |
| SetupManager | 90226 | Codeunit | `BCSF Setup Manager` | `src/SetupManager/BCSFSetupManager.Codeunit.al` | SF-009 |
| DataGeneration | 90250 | Codeunit | `BCSF Seed Engine` | `src/DataGeneration/BCSFSeedEngine.Codeunit.al` | SF-010 |
| DataGeneration | 90251 | Table | `BCSF Generated Record` | `src/DataGeneration/BCSFGeneratedRecord.Table.al` | SF-011 |
| DataGeneration | 90252 | Codeunit | `BCSF Record Registry` | `src/DataGeneration/BCSFRecordRegistry.Codeunit.al` | SF-011 |
| ProcessEngine | 90275 | Codeunit | `BCSF Process Coordinator` | `src/ProcessEngine/BCSFProcessCoordinator.Codeunit.al` | SF-007 |
| BackgroundProcessing | 90300 | Table | `BCSF Batch` | `src/BackgroundProcessing/BCSFBatch.Table.al` | SF-012 |
| BackgroundProcessing | 90301 | Enum | `BCSF Batch Status` | `src/BackgroundProcessing/BCSFBatchStatus.Enum.al` | SF-012 |
| BackgroundProcessing | 90302 | Codeunit | `BCSF Queue Dispatcher` | `src/BackgroundProcessing/BCSFQueueDispatcher.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90303 | Codeunit | `BCSF Batch Worker` | `src/BackgroundProcessing/BCSFBatchWorker.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90304 | Codeunit | `BCSF Batch Recovery` | `src/BackgroundProcessing/BCSFBatchRecovery.Codeunit.al` | SF-013 |
| Validation | 90325 | Table | `BCSF Validation Result` | `src/Validation/BCSFValidationResult.Table.al` | SF-016 |
| Validation | 90326 | Codeunit | `BCSF Validation Manager` | `src/Validation/BCSFValidationManager.Codeunit.al` | SF-016 |
| Monitoring | 90350 | Table | `BCSF Run Event` | `src/Monitoring/BCSFRunEvent.Table.al` | SF-014 |
| Monitoring | 90351 | Page | `BCSF Factory Dashboard` | `src/Monitoring/BCSFFactoryDashboard.Page.al` | SF-014 |
| Monitoring | 90352 | Page | `BCSF Run List` | `src/Monitoring/BCSFRunList.Page.al` | SF-014 |
| Monitoring | 90353 | Page | `BCSF Batch List` | `src/Monitoring/BCSFBatchList.Page.al` | SF-014 |
| Lifecycle | 90375 | Codeunit | `BCSF Environment Guard` | `src/Lifecycle/BCSFEnvironmentGuard.Codeunit.al` | SF-003 |
| Lifecycle | 90376 | Codeunit | `BCSF Lifecycle Manager` | `src/Lifecycle/BCSFLifecycleManager.Codeunit.al` | SF-027 |
| Finance | 90400 | Codeunit | `BCSF Finance Generator` | `src/Finance/BCSFFinanceGenerator.Codeunit.al` | SF-017 |
| Finance | 90401 | Codeunit | `BCSF Payment Processor` | `src/Finance/BCSFPaymentProcessor.Codeunit.al` | SF-022 |
| Sales | 90425 | Codeunit | `BCSF Customer Generator` | `src/Sales/BCSFCustomerGenerator.Codeunit.al` | SF-018 |
| Sales | 90426 | Codeunit | `BCSF Sales Generator` | `src/Sales/BCSFSalesGenerator.Codeunit.al` | SF-021 |
| Purchasing | 90450 | Codeunit | `BCSF Vendor Generator` | `src/Purchasing/BCSFVendorGenerator.Codeunit.al` | SF-018 |
| Purchasing | 90451 | Codeunit | `BCSF Purchase Generator` | `src/Purchasing/BCSFPurchaseGenerator.Codeunit.al` | SF-020 |
| Inventory | 90475 | Codeunit | `BCSF Inventory Generator` | `src/Inventory/BCSFInventoryGenerator.Codeunit.al` | SF-019 |
| Warehouse | 90500 | Codeunit | `BCSF Warehouse Generator` | `src/Warehouse/BCSFWarehouseGenerator.Codeunit.al` | SF-028 |
| Manufacturing | 90525 | Codeunit | `BCSF Manufacturing Generator` | `src/Manufacturing/BCSFManufacturingGenerator.Codeunit.al` | SF-029 |
| Assembly | 90550 | Codeunit | `BCSF Assembly Generator` | `src/Assembly/BCSFAssemblyGenerator.Codeunit.al` | SF-029 |
| Projects | 90575 | Codeunit | `BCSF Project Generator` | `src/Projects/BCSFProjectGenerator.Codeunit.al` | SF-030 |
| ServiceManagement | 90600 | Codeunit | `BCSF Service Generator` | `src/ServiceManagement/BCSFServiceGenerator.Codeunit.al` | SF-030 |
| FixedAssets | 90625 | Codeunit | `BCSF Fixed Asset Generator` | `src/FixedAssets/BCSFFixedAssetGenerator.Codeunit.al` | SF-031 |
| CRM | 90650 | Codeunit | `BCSF CRM Generator` | `src/CRM/BCSFCRMGenerator.Codeunit.al` | SF-033 |
| Planning | 90675 | Codeunit | `BCSF Planning Generator` | `src/Planning/BCSFPlanningGenerator.Codeunit.al` | SF-033 |

## Verträge und Aufrufgrenzen

- `BCSF Generator` ist das geplante Interface in `BCScenarioFactory.ModuleRegistry`, Dateipfad `src/ModuleRegistry/BCSFGenerator.Interface.al`, ohne deklarierte numerische ID. Das Interface verwendet gemeinsame Core-Typen; Registry/Core referenzieren keine konkreten Fachgeneratoren. Fachmodule implementieren und registrieren ihre Fähigkeiten. Enum-basierte Auflösung und endgültige Methodensignaturen gehören zu SF-007, öffentliche Fremdanbieter-Verträge zu SF-034.
- Core enthält ausschließlich Basistypen und globale Einstellungen. Laufkonfiguration, Run Header, Run Step und Snapshot gehören ScenarioManagement; Core referenziert weder ScenarioManagement noch Lifecycle. Der Environment Guard gehört Lifecycle und wird an jedem mutierenden Einstieg einschließlich Worker aufgerufen.
- ScenarioManagement hält Vorlagen/Snapshots und Modul-/Entitätsauswahl. IndustryProfiles löst Regeln darauf auf; Profile enthalten keine kopierte Generatorlogik. ModuleRegistry verwaltet Fähigkeiten, DependencyManager plant fachliche Reihenfolgen, SetupManager erstellt lesende Diffs und setzt nur freigegebene Änderungen um.
- DataGeneration hält deterministische Werte und Datensatzherkunft. ProcessEngine koordiniert Dokument-/Postingmodi; konkrete geprüfte BC-Standardaufrufe verbleiben bei den Fachgeneratoren. Kein Direktinsert in Standardledger.
- BackgroundProcessing besitzt Batches, Claims und Wiederaufnahme, aber keine Fachbuchungslogik. Validation hält Prüfergebnisse; fachliche Prüfer können später über geprüfte Registrierung/Erweiterungspunkte beitragen. Monitoring liest Run-/Batch-/Prüfstände; BackgroundProcessing referenziert Monitoring nicht. Run-Events werden im Monitoring-Modul über Subscriber aufgezeichnet; Eventsignaturen folgen SF-014.
- Finance besitzt Finanz-Setup und Zahlungs-/Ausgleichsprozesse. Sales besitzt Debitoren/Verkaufsbelege; Purchasing Kreditoren/Einkaufsbelege; Inventory Artikel/Bestandsgrundlagen. Die übrigen Fachmodule behalten die in ihren Modulspezifikationen beschriebene Verantwortung. Sie referenzieren keine anderen konkreten Fachgeneratoren; der Planner bildet deren fachliche Voraussetzungen als Daten ab.

Die Tabelle beschreibt erlaubte direkte **Codeabhängigkeiten innerhalb einer App**, keine zusätzlichen app.json-Dependencies und keine zwingenden Imports. Fachliche Abhängigkeit „Einkauf vor Verkauf“ ist eine Laufplanregel, kein gegenseitiger Codeverweis. Die früheren allgemeinen Abhängigkeitslisten in den Modulskeletten werden entsprechend präzisiert.

## Datenfluss und Transaktionsgrenzen

UI → Scenario Manager → eingefrorener Snapshot → Profil/Registry/Setup/Planner → Queue-Dispatcher → Worker → Generator-Interface → Fachgenerator/Standardprozesse → Herkunft und Validierung → persistenter Fortschritt → Dashboard.

Pages starten keine Massengenerierung im UI-Trigger. Guard/Rechte/Freigabe werden auch im Worker erneut geprüft. Fachgeneratoren melden nachweisbare Ergebnisse zurück; Queue-Code setzt Checkpoints erst nach gesicherter Persistenz. SF-012/013 definieren konkrete Commit-/Claim-Verträge. Bis dahin ist kein Commit oder Retry-Verhalten zugesichert. Bei unsicherem Posting-Ausgang erst Resultate abgleichen, niemals blind neu buchen. Cleanup gebuchter Daten bleibt auf kontrollierte Standardprozesse bzw. neue Testfirma beschränkt.

## Kompatibilität und Quellen

Der Plan nutzt klassische Interface-Signaturen ohne Default-Methoden; keine Runtime-Erhöhung. Microsoft dokumentiert Default-Implementierungen erst ab Runtime 18, während app.json Runtime 17 vorgibt. Namespaces und Interfaces werden vor AL-Implementierung mit Zielcompiler/Symbolen geprüft. Die Wahl von Präfix/Namespace ist eine Projektkonvention und keine externe Registrierung oder Freigabe des noch offenen Publishers.

- [Microsoft Learn – Interfaces in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al)
- [Microsoft Learn – Namespaces](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-structure)

Quellen geprüft am 11.11.2026. Tatsächliche Prüfergebnisse: [TESTS.md](TESTS.md). Menschliche Abnahme steht aus.


## Implementierter Stand SF-003/SF-004 (11.11.2026)

9 AL-Objekte: Core 90100–90107 und Lifecycle 90375. Die beiden zusätzlichen Management-Codeunits nutzen zuvor unbelegte Werte des Core-Blocks; insgesamt jetzt 61 numerische Planobjekte plus ein weiterhin geplantes Interface. Keine Bestandsobjekte umbenannt oder verschoben.

Core enthält Tabelle, Setup-Card, drei Enums, Setup Management, Run State Management und das Permission Set. Lifecycle sichert die vier Datenbankereignisse der Setup-Tabelle ab. Ausführbarer Core-Code referenziert Lifecycle nicht; das Permission Set ist als deklarative Berechtigungszusammenstellung die ausdrückliche Ausnahme und referenziert den Guard. Daraus entsteht kein zyklischer Geschäftslogik-Aufruf.

Run-/Batch-Persistenz bleibt bei SF-005/012; insbesondere ist der Batch-Status 90301 noch nicht implementiert. Die GUID-Hilfen ändern nur einen übergebenen leeren Wert. Statusnummern 0–12 sind im neuen Run-Enum festgelegt; Übergänge im [Foundation-Vertrag](FOUNDATION.md). Kompiliert mit vorhandenen BC-28.5-Symbolen/Runtime 17; noch kein Sandbox- oder Berechtigungs-Laufzeittest.
