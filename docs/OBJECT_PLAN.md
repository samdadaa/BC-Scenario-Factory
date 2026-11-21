# Objektplan und Modulgrenzen – SF-002

**Aktueller Stand ab 1.0.2.0:** Der reale Bedienweg ist in [Mandanteneinrichtung und Vorlagenstart](COMPANY_INITIALIZATION.md) beschrieben. Ältere Angaben zu Finanzauswahl je Vorlage, Vorschaufenster, Wizard, parallelen Lauflisten und Dashboard-Host sind historische Nachweise. Entfernte Objekt-IDs bleiben unbenutzt.

**Stand:** 11.11.2026, zur Prüfung. Dies ist ein Entwicklungsplan, keine implementierte Funktion und keine Implementierungsfreigabe für Folgetickets. Historischer SF-002-Stand: 0 AL-Objekte und 24 leere Modulordner. Aktuell sind die unten aufgeführten Grundlagen aus SF-003/SF-004 implementiert; weitere Zeilen bleiben Planung. Grundlage ist die vom Nutzer bestätigte aktuelle Manifest-Range `90100..90999` (900 ID-Werte), Ziel `Playground`, Entwicklungsmodus. Die frühere Auswahl `50100..50999` ist abgelöst.

## Umfang, Voraussetzungen und Prüfweg

Ziel: eindeutige Namen, Ablage, ID-Zuordnung und Verantwortungsgrenzen vor dem ersten AL-Objekt festlegen. Betroffen: dieser Plan, CONVENTIONS, ARCHITECTURE, PROJECT, DECISIONS, TESTS, Modulindex und die 24 Modulspezifikationen sowie README und ausschließlich SF-002 in TODO. Historischer Umfang vom 11.11.2026: Manifest, Launch-Konfiguration und Modulverzeichnisse blieben unverändert. Seit Nutzerauftrag vom 16.11.2026 folgen alle aktuellen und geplanten Dateipfade der modularen Typablage gemäß [CONVENTIONS.md](CONVENTIONS.md); geplante Pfade erzeugen keine leeren Ordner.

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
| Validation | 90325 | 90349 | `BCScenarioFactory.Validation` | Core, ScenarioManagement, DataGeneration, Lifecycle |
| Monitoring | 90350 | 90374 | `BCScenarioFactory.Monitoring` | Core, ScenarioManagement, BackgroundProcessing, Validation, DependencyManager, SetupManager, Lifecycle, ModuleRegistry, DataGeneration |
| Lifecycle | 90375 | 90399 | `BCScenarioFactory.Lifecycle` | Core, ScenarioManagement, ModuleRegistry, DependencyManager |
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
| Core | 90100 | Table | `BCSF Factory Setup` | `src/Core/Tables/BCSFFactorySetup.Table.al` | SF-004 |
| Core | 90101 | Page | `BCSF Factory Setup Card` | `src/Core/Pages/BCSFFactorySetupCard.Page.al` | SF-004 |
| Core | 90102 | Enum | `BCSF Run Status` | `src/Core/Enums/BCSFRunStatus.Enum.al` | SF-004 |
| Core | 90103 | Enum | `BCSF Process Mode` | `src/Core/Enums/BCSFProcessMode.Enum.al` | SF-004 |
| Core | 90104 | Enum | `BCSF Usage Mode` | `src/Core/Enums/BCSFUsageMode.Enum.al` | SF-004 |
| Core | 90105 | PermissionSet | `BCSF ADMIN` | `src/Core/PermissionSets/BCSFADMIN.PermissionSet.al` | SF-003 |
| Core | 90106 | Codeunit | `BCSF Setup Management` | `src/Core/Codeunits/BCSFSetupManagement.Codeunit.al` | SF-004 |
| Core | 90107 | Codeunit | `BCSF Run State Mgt` | `src/Core/Codeunits/BCSFRunStateMgt.Codeunit.al` | SF-004 |
| ScenarioManagement | 90125 | Table | `BCSF Scenario` | `src/ScenarioManagement/Tables/BCSFScenario.Table.al` | SF-005 |
| ScenarioManagement | 90126 | Table | `BCSF Scenario Module` | `src/ScenarioManagement/Tables/BCSFScenarioModule.Table.al` | SF-005 |
| ScenarioManagement | 90127 | Table | `BCSF Data Target` | `src/ScenarioManagement/Tables/BCSFDataTarget.Table.al` | SF-006 |
| ScenarioManagement | 90128 | Table | `BCSF Run Header` | `src/ScenarioManagement/Tables/BCSFRunHeader.Table.al` | SF-005 |
| ScenarioManagement | 90129 | Table | `BCSF Run Step` | `src/ScenarioManagement/Tables/BCSFRunStep.Table.al` | SF-008 |
| ScenarioManagement | 90130 | Codeunit | `BCSF Scenario Manager` | `src/ScenarioManagement/Codeunits/BCSFScenarioManager.Codeunit.al` | SF-005 |
| ScenarioManagement | 90131 | Page | `BCSF Scenario Card` | `src/ScenarioManagement/Pages/BCSFScenarioCard.Page.al` | SF-005 |
| ScenarioManagement | 90132 | Page | `BCSF Scenario Wizard` | `src/ScenarioManagement/Pages/BCSFScenarioWizard.Page.al` | SF-015 |
| ScenarioManagement | 90133 | Page | `BCSF Scenario List` | `src/ScenarioManagement/Pages/BCSFScenarioList.Page.al` | SF-005 |
| ScenarioManagement | 90134 | Table | `BCSF Run Snapshot` | `src/ScenarioManagement/Tables/BCSFRunSnapshot.Table.al` | SF-005 |
| IndustryProfiles | 90150 | Table | `BCSF Industry Profile` | `src/IndustryProfiles/Tables/BCSFIndustryProfile.Table.al` | SF-023 |
| IndustryProfiles | 90151 | Table | `BCSF Profile Rule` | `src/IndustryProfiles/Tables/BCSFProfileRule.Table.al` | SF-023 |
| IndustryProfiles | 90152 | Codeunit | `BCSF Profile Resolver` | `src/IndustryProfiles/Codeunits/BCSFProfileResolver.Codeunit.al` | SF-023 |
| IndustryProfiles | 90153 | Codeunit | `BCSF Wholesale Profile` | `src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al` | SF-023 |
| ModuleRegistry | 90175 | Table | `BCSF Generator Registry` | `src/ModuleRegistry/Tables/BCSFGeneratorRegistry.Table.al` | SF-007 |
| ModuleRegistry | 90176 | Enum | `BCSF Generator Type` | `src/ModuleRegistry/Enums/BCSFGeneratorType.Enum.al` | SF-007 |
| ModuleRegistry | 90177 | Codeunit | `BCSF Generator Registry Mgt` | `src/ModuleRegistry/Codeunits/BCSFGeneratorRegistryMgt.Codeunit.al` | SF-007 |
| DependencyManager | 90200 | Table | `BCSF Dependency` | `src/DependencyManager/Tables/BCSFDependency.Table.al` | SF-008 |
| DependencyManager | 90201 | Codeunit | `BCSF Dependency Planner` | `src/DependencyManager/Codeunits/BCSFDependencyPlanner.Codeunit.al` | SF-008 |
| SetupManager | 90225 | Table | `BCSF Setup Diff` | `src/SetupManager/Tables/BCSFSetupDiff.Table.al` | SF-009 |
| SetupManager | 90226 | Codeunit | `BCSF Setup Manager` | `src/SetupManager/Codeunits/BCSFSetupManager.Codeunit.al` | SF-009 |
| DataGeneration | 90250 | Codeunit | `BCSF Seed Engine` | `src/DataGeneration/Codeunits/BCSFSeedEngine.Codeunit.al` | SF-010 |
| DataGeneration | 90251 | Table | `BCSF Generated Record` | `src/DataGeneration/Tables/BCSFGeneratedRecord.Table.al` | SF-011 |
| DataGeneration | 90252 | Codeunit | `BCSF Record Registry` | `src/DataGeneration/Codeunits/BCSFRecordRegistry.Codeunit.al` | SF-011 |
| ProcessEngine | 90275 | Codeunit | `BCSF Process Coordinator` | `src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al` | SF-007 |
| BackgroundProcessing | 90300 | Table | `BCSF Batch` | `src/BackgroundProcessing/Tables/BCSFBatch.Table.al` | SF-012 |
| BackgroundProcessing | 90301 | Enum | `BCSF Batch Status` | `src/BackgroundProcessing/Enums/BCSFBatchStatus.Enum.al` | SF-012 |
| BackgroundProcessing | 90302 | Codeunit | `BCSF Queue Dispatcher` | `src/BackgroundProcessing/Codeunits/BCSFQueueDispatcher.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90303 | Codeunit | `BCSF Batch Worker` | `src/BackgroundProcessing/Codeunits/BCSFBatchWorker.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90304 | Codeunit | `BCSF Batch Recovery` | `src/BackgroundProcessing/Codeunits/BCSFBatchRecovery.Codeunit.al` | SF-013 |
| Validation | 90325 | Table | `BCSF Validation Result` | `src/Validation/Tables/BCSFValidationResult.Table.al` | SF-016 |
| Validation | 90326 | Codeunit | `BCSF Validation Manager` | `src/Validation/Codeunits/BCSFValidationManager.Codeunit.al` | SF-016 |
| Monitoring | 90350 | Table | `BCSF Run Event` | `src/Monitoring/Tables/BCSFRunEvent.Table.al` | SF-014 |
| Monitoring | 90351 | Page | `BCSF Factory Dashboard` | `src/Monitoring/Pages/BCSFFactoryDashboard.Page.al` | SF-014 |
| Monitoring | 90352 | Page | `BCSF Step Progress` | `src/Monitoring/Pages/BCSFStepProgress.Page.al` | SF-014 |
| Monitoring | 90353 | Page | `BCSF Run Events` | `src/Monitoring/Pages/BCSFRunEvents.Page.al` | SF-014 |
| Lifecycle | 90375 | Codeunit | `BCSF Environment Guard` | `src/Lifecycle/Codeunits/BCSFEnvironmentGuard.Codeunit.al` | SF-003 |
| Lifecycle | 90376 | Codeunit | `BCSF Lifecycle Manager` | `src/Lifecycle/Codeunits/BCSFLifecycleManager.Codeunit.al` | SF-027 |
| Finance | 90400 | Codeunit | `BCSF Finance Package Mgt` | `src/Finance/Codeunits/BCSFFinancePackageMgt.Codeunit.al` | SF-017 |
| Finance | 90401 | Codeunit | `BCSF Payment Processor` | `src/Finance/Codeunits/BCSFPaymentProcessor.Codeunit.al` | SF-022 |
| Sales | 90425 | Codeunit | `BCSF Customer Generator` | `src/Sales/Codeunits/BCSFCustomerGenerator.Codeunit.al` | SF-018 |
| Sales | 90426 | Codeunit | `BCSF Sales Generator` | `src/Sales/Codeunits/BCSFSalesGenerator.Codeunit.al` | SF-021 |
| Purchasing | 90450 | Codeunit | `BCSF Vendor Generator` | `src/Purchasing/Codeunits/BCSFVendorGenerator.Codeunit.al` | SF-018 |
| Purchasing | 90451 | Codeunit | `BCSF Purchase Generator` | `src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al` | SF-020 |
| Inventory | 90475 | Codeunit | `BCSF Inventory Generator` | `src/Inventory/Codeunits/BCSFInventoryGenerator.Codeunit.al` | SF-019 |
| Warehouse | 90500 | Codeunit | `BCSF Warehouse Generator` | `src/Warehouse/Codeunits/BCSFWarehouseGenerator.Codeunit.al` | SF-028 |
| Manufacturing | 90525 | Codeunit | `BCSF Manufacturing Generator` | `src/Manufacturing/Codeunits/BCSFManufacturingGenerator.Codeunit.al` | SF-029 |
| Assembly | 90550 | Codeunit | `BCSF Assembly Generator` | `src/Assembly/Codeunits/BCSFAssemblyGenerator.Codeunit.al` | SF-029 |
| Projects | 90575 | Codeunit | `BCSF Project Generator` | `src/Projects/Codeunits/BCSFProjectGenerator.Codeunit.al` | SF-030 |
| ServiceManagement | 90600 | Codeunit | `BCSF Service Generator` | `src/ServiceManagement/Codeunits/BCSFServiceGenerator.Codeunit.al` | SF-030 |
| FixedAssets | 90625 | Codeunit | `BCSF Fixed Asset Generator` | `src/FixedAssets/Codeunits/BCSFFixedAssetGenerator.Codeunit.al` | SF-031 |
| CRM | 90650 | Codeunit | `BCSF CRM Generator` | `src/CRM/Codeunits/BCSFCRMGenerator.Codeunit.al` | SF-033 |
| Planning | 90675 | Codeunit | `BCSF Planning Generator` | `src/Planning/Codeunits/BCSFPlanningGenerator.Codeunit.al` | SF-033 |

| Core | 90108 | Enum | `BCSF Data Language` | `src/Core/Enums/BCSFDataLanguage.Enum.al` | SF-005 |
| Core | 90109 | Codeunit | `BCSF Language Mgt` | `src/Core/Codeunits/BCSFLanguageMgt.Codeunit.al` | SF-005 |
| Lifecycle | 90377 | Codeunit | `BCSF Scenario Guard` | `src/Lifecycle/Codeunits/BCSFScenarioGuard.Codeunit.al` | SF-005 |
| ScenarioManagement | 90137 | Page | `BCSF Data Targets` | `src/ScenarioManagement/Pages/BCSFDataTargets.Page.al` | SF-006 |
| ScenarioManagement | 90135 | Enum | `BCSF Entity Type` | `src/ScenarioManagement/Enums/BCSFEntityType.Enum.al` | SF-006 |
| ScenarioManagement | 90141 | Page | `BCSF Frozen Modules` | `src/ScenarioManagement/Pages/BCSFFrozenModules.Page.al` | SF-005 |
| ScenarioManagement | 90140 | Page | `BCSF Frozen Targets` | `src/ScenarioManagement/Pages/BCSFFrozenTargets.Page.al` | SF-005 |
| ScenarioManagement | 90146 | Enum | `BCSF Module Type` | `src/ScenarioManagement/Enums/BCSFModuleType.Enum.al` | SF-006 |
| ScenarioManagement | 90142 | Enum | `BCSF Quantity Preset` | `src/ScenarioManagement/Enums/BCSFQuantityPreset.Enum.al` | SF-006 |
| ScenarioManagement | 90139 | Page | `BCSF Run Card` | `src/ScenarioManagement/Pages/BCSFRunCard.Page.al` | SF-005 |
| ScenarioManagement | 90138 | Page | `BCSF Run List` | `src/ScenarioManagement/Pages/BCSFRunList.Page.al` | SF-005 |
| ScenarioManagement | 90145 | Codeunit | `BCSF Scenario DB Events` | `src/ScenarioManagement/Codeunits/BCSFScenarioDBEvents.Codeunit.al` | SF-005 |
| ScenarioManagement | 90136 | Page | `BCSF Scenario Modules` | `src/ScenarioManagement/Pages/BCSFScenarioModules.Page.al` | SF-005 |
| ScenarioManagement | 90143 | Codeunit | `BCSF Scenario Policy` | `src/ScenarioManagement/Codeunits/BCSFScenarioPolicy.Codeunit.al` | SF-006 |
| ScenarioManagement | 90144 | Codeunit | `BCSF Snapshot Writer` | `src/ScenarioManagement/Codeunits/BCSFSnapshotWriter.Codeunit.al` | SF-005 |

| Core | 90111 | Codeunit | `BCSF Contract JSON` | `src/Core/Codeunits/BCSFContractJSON.Codeunit.al` | SF-007 |
| Core | 90112 | Enum | `BCSF Dependency Kind` | `src/Core/Enums/BCSFDependencyKind.Enum.al` | SF-007 |
| Core | 90110 | Enum | `BCSF Plan Issue` | `src/Core/Enums/BCSFPlanIssue.Enum.al` | SF-007 |
| DependencyManager | 90207 | Codeunit | `BCSF Graph Self Check` | `src/DependencyManager/Codeunits/BCSFGraphSelfCheck.Codeunit.al` | SF-008 |
| DependencyManager | 90202 | Codeunit | `BCSF Graph Sorter` | `src/DependencyManager/Codeunits/BCSFGraphSorter.Codeunit.al` | SF-008 |
| DependencyManager | 90203 | Table | `BCSF Plan Node` | `src/DependencyManager/Tables/BCSFPlanNode.Table.al` | SF-008 |
| DependencyManager | 90205 | Page | `BCSF Plan Preview` | `src/DependencyManager/Pages/BCSFPlanPreview.Page.al` | SF-008 |
| DependencyManager | 90204 | Codeunit | `BCSF Plan Writer` | `src/DependencyManager/Codeunits/BCSFPlanWriter.Codeunit.al` | SF-008 |
| DependencyManager | 90208 | PageExtension | `BCSF Run Planning` | `src/DependencyManager/PageExtensions/BCSFRunPlanning.PageExt.al` | SF-008 |
| DependencyManager | 90206 | Page | `BCSF Saved Run Steps` | `src/DependencyManager/Pages/BCSFSavedRunSteps.Page.al` | SF-008 |
| Lifecycle | 90378 | Codeunit | `BCSF Planning Guard` | `src/Lifecycle/Codeunits/BCSFPlanningGuard.Codeunit.al` | SF-008 |
| ModuleRegistry | 90181 | Codeunit | `BCSF Contract Self Check` | `src/ModuleRegistry/Codeunits/BCSFContractSelfCheck.Codeunit.al` | SF-007 |
| ModuleRegistry | 90178 | Codeunit | `BCSF Customer Probe` | `src/ModuleRegistry/Codeunits/BCSFCustomerProbe.Codeunit.al` | SF-007 |
| ModuleRegistry | 90182 | Page | `BCSF Generator Catalog` | `src/ModuleRegistry/Pages/BCSFGeneratorCatalog.Page.al` | SF-007 |
| ModuleRegistry | 90180 | Codeunit | `BCSF Missing Generator` | `src/ModuleRegistry/Codeunits/BCSFMissingGenerator.Codeunit.al` | SF-007 |
| ModuleRegistry | 90183 | Codeunit | `BCSF Probe Support` | `src/ModuleRegistry/Codeunits/BCSFProbeSupport.Codeunit.al` | SF-007 |
| ModuleRegistry | 90179 | Codeunit | `BCSF Vendor Probe` | `src/ModuleRegistry/Codeunits/BCSFVendorProbe.Codeunit.al` | SF-007 |

## Verträge und Aufrufgrenzen

- `BCSF Generator` ist das implementierte interne Interface in `BCScenarioFactory.ModuleRegistry`, Dateipfad `src/ModuleRegistry/Interfaces/BCSFGenerator.Interface.al`, ohne deklarierte numerische ID. Das Interface verwendet gemeinsame Core-Typen; Registry/Core referenzieren keine konkreten Fachgeneratoren. Fachmodule implementieren und registrieren ihre Fähigkeiten. Enum-basierte Auflösung und Methodensignaturen sind in SF-007 umgesetzt, öffentliche Fremdanbieter-Verträge zu SF-034.
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


## Implementierter Stand SF-005/SF-006 und Sprachen (11.11.2026)

Aktuell 32 AL-Objekte: Core 10, ScenarioManagement 20, Lifecycle 2; übrige 21 Module leer. Neu gegenüber SF-003/SF-004: zwei Core-Sprachobjekte (90108/90109), 20 ScenarioManagement-Objekte und Lifecycle-Konfigurationsguard 90377. Die Tabelle enthält jetzt 76 numerische Planobjekte; alle neuen Werte stammen aus zuvor freien Modulwerten. Run Step 90129, Wizard 90132 und alle übrigen Folgetickets bleiben unimplementiert.

Sicherheitsbindung über Datenbank-Subscriber; keine ausführbare ScenarioManagement→Lifecycle-Rückreferenz. Nur das aggregierende Permission Set referenziert beide deklarativ. Der Snapshot Writer besitzt eng begrenzte Insert-Rechte auf eigene Lauf-/Snapshot-Tabellen, Anwender lediglich indirektes Insert. Erfasste Köpfe und Payloads sind aktuell vollständig unveränderlich. Vollständiger Feld-/Transaktions-/Sprachvertrag: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md). Sprachkatalog ist Teil der Core-Grundlage; er ersetzt keinen geplanten Generator.


## Implementierter Stand SF-007/SF-008 (11.11.2026)

56 AL-Objekte: Core 13, ScenarioManagement 21, ModuleRegistry 10 einschließlich Interface, DependencyManager 9, Lifecycle 3; 19 Module ohne AL-Code. 93 numerische Planobjekte plus Interface; alle 55 implementierten IDs innerhalb ihrer Modulblöcke. Implementierte Dateien sind direkt unter `src/` nachweisbar; übrige Zeilen bleiben Planung. Run Step 90129 ist jetzt implementiert. Process Coordinator 90275 bleibt ein Planobjekt für die spätere reale Prozessausführung; SF-007 liefert den Vertrag. PageExtension-Dateien verwenden beim ersten tatsächlichen Objekt das von CodeCop verlangte `.PageExt.al` (CONVENTIONS). Registry und Planner: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md).

## Ergänzungen und Umsetzung SF-009/SF-010 – 15.11.2026

Die geplanten IDs 90225/90226 und 90250 sind nun implementiert. Fünf zusätzliche freie Modulwerte sind nach lokaler Belegungsprüfung zugeordnet:

| Modul | Plan-ID | Typ | Objektname | Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| IndustryProfiles | 90154 | Codeunit | `BCSF Synthetic Rules` | `src/IndustryProfiles/Codeunits/BCSFSyntheticRules.Codeunit.al` | SF-010 |
| SetupManager | 90227 | Page | `BCSF Setup Diff Preview` | `src/SetupManager/Pages/BCSFSetupDiffPreview.Page.al` | SF-009 |
| SetupManager | 90228 | PageExtension | `BCSF Run Preflight` | `src/SetupManager/PageExtensions/BCSFRunPreflight.PageExt.al` | SF-009 |
| DataGeneration | 90253 | PageExtension | `BCSF Run Synthetic Preview` | `src/DataGeneration/PageExtensions/BCSFRunSyntheticPreview.PageExt.al` | SF-010 |
| Finance | 90402 | Codeunit | `BCSF Finance Setup Check` | `src/Finance/Codeunits/BCSFFinanceSetupCheck.Codeunit.al` | SF-009 |

Jetzt 64 implementierte Objekte einschließlich Interface ohne numerische ID. SetupManager darf zusätzlich DependencyManager ausschließlich für dessen Start-Ereignis referenzieren. Finance → SetupManager und IndustryProfiles → ScenarioManagement nutzen vorhandene erlaubte Richtungen; keine neue ausführbare Rückabhängigkeit des Snapshot Writers. Core-Permission-Set bleibt deklarative Ausnahme. Datenfluss, Felder, Defaults und Kompatibilität: [SETUP_SEED.md](SETUP_SEED.md).

## Ergänzungen und Umsetzung SF-011/SF-012 – 15.11.2026

Geplante Objekte 90251/90252 und 90300–90303 sind nun implementiert. 90304 bleibt für Recovery in SF-013 reserviert. Folgende zusätzlich lokal freie Modulwerte werden zugeordnet:

| Modul | Plan-ID | Typ | Objektname | Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| DataGeneration | 90254 | Page | `BCSF Generated Records` | `src/DataGeneration/Pages/BCSFGeneratedRecords.Page.al` | SF-011 |
| DataGeneration | 90255 | PageExtension | `BCSF Run Provenance` | `src/DataGeneration/PageExtensions/BCSFRunProvenance.PageExt.al` | SF-011 |
| Lifecycle | 90379 | Codeunit | `BCSF Provenance Guard` | `src/Lifecycle/Codeunits/BCSFProvenanceGuard.Codeunit.al` | SF-011 |
| BackgroundProcessing | 90305 | Table | `BCSF Run Execution` | `src/BackgroundProcessing/Tables/BCSFRunExecution.Table.al` | SF-012 |
| BackgroundProcessing | 90306 | Codeunit | `BCSF Execution Rules` | `src/BackgroundProcessing/Codeunits/BCSFExecutionRules.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90307 | Codeunit | `BCSF Batch Runner` | `src/BackgroundProcessing/Codeunits/BCSFBatchRunner.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90308 | Codeunit | `BCSF Queue Failure` | `src/BackgroundProcessing/Codeunits/BCSFQueueFailure.Codeunit.al` | SF-012 |
| BackgroundProcessing | 90309 | Page | `BCSF Execution List` | `src/BackgroundProcessing/Pages/BCSFExecutionList.Page.al` | SF-012 |
| BackgroundProcessing | 90310 | Page | `BCSF Schedule Request` | `src/BackgroundProcessing/Pages/BCSFScheduleRequest.Page.al` | SF-012 |
| BackgroundProcessing | 90311 | Page | `BCSF Batch List` | `src/BackgroundProcessing/Pages/BCSFBatchList.Page.al` | SF-012 |
| BackgroundProcessing | 90312 | PageExtension | `BCSF Run Queue` | `src/BackgroundProcessing/PageExtensions/BCSFRunQueue.PageExt.al` | SF-012 |

81 implementierte Objekte einschließlich Interface ohne numerische ID. Lifecycle darf für den Pflichtsubscriber zusätzlich DataGeneration referenzieren. BackgroundProcessing nutzt seine bereits vorgesehenen Abhängigkeiten auf Core, ScenarioManagement, ModuleRegistry, DependencyManager, DataGeneration und Lifecycle; keine Rückabhängigkeit des Snapshotmoduls. Deklaratives Core-Permission-Set weiterhin Ausnahme. Header/Steps/Snapshots unverändert immutable, Ausführungsstatus und Batches in BackgroundProcessing. [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md).

## Umsetzung SF-013 – 16.11.2026

Reservierte Codeunit 90304 `BCSF Batch Recovery` unter `src/BackgroundProcessing/Codeunits/BCSFBatchRecovery.Codeunit.al` implementiert. Drei weitere zuvor freie Werte im BackgroundProcessing-Block:

| Modul | Plan-ID | Typ | Objektname | Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| BackgroundProcessing | 90313 | Table | `BCSF Run Control` | `src/BackgroundProcessing/Tables/BCSFRunControl.Table.al` | SF-013 |
| BackgroundProcessing | 90314 | Table | `BCSF Batch Checkpoint` | `src/BackgroundProcessing/Tables/BCSFBatchCheckpoint.Table.al` | SF-013 |
| BackgroundProcessing | 90315 | Codeunit | `BCSF Recovery Rules` | `src/BackgroundProcessing/Codeunits/BCSFRecoveryRules.Codeunit.al` | SF-013 |

85 Objekte einschließlich Interface, 84 numerische IDs. Keine neue Modulrichtung oder App-Abhängigkeit; Core enthält nur die ergänzten erlaubten Statusübergänge und die deklarative Berechtigungserweiterung. Checkpoint-/Control-Felder und neue technische Batchfelder im [Recovery-Vertrag](RECOVERY.md). Keine neuen Testobjekte.

## Umsetzung SF-014/SF-015 – 16.11.2026

97 reale AL-Objekte (96 numerische IDs plus Interface), elf Module mit AL-Code.
Reserviert geplante 90350/90351 und Wizard 90132 jetzt implementiert. Die bislang **nicht implementierten** Monitoring-Planwerte 90352/90353 erhalten die Namen Step Progress/Run Events, weil Run List und Batch List bereits in ScenarioManagement/BackgroundProcessing existieren. Keine vorhandene Datei/Objekt umbenannt oder verschoben.

| Modul | Plan-ID | Typ | Objektname | Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| Monitoring | 90354 | Table (Temporary) | `BCSF Step Metric` | `src/Monitoring/Tables/BCSFStepMetric.Table.al` | SF-014 |
| Monitoring | 90355 | Page | `BCSF Run Overview` | `src/Monitoring/Pages/BCSFRunOverview.Page.al` | SF-014 |
| Monitoring | 90356 | Codeunit | `BCSF Monitoring Mgt` | `src/Monitoring/Codeunits/BCSFMonitoringMgt.Codeunit.al` | SF-014 |
| Monitoring | 90357 | Codeunit | `BCSF Run Event Writer` | `src/Monitoring/Codeunits/BCSFRunEventWriter.Codeunit.al` | SF-014 |
| Monitoring | 90358 | PageExtension | `BCSF Run Monitoring` | `src/Monitoring/PageExtensions/BCSFRunMonitoring.PageExt.al` | SF-014 |
| Monitoring | 90359 | PageExtension | `BCSF Wizard Execution` | `src/Monitoring/PageExtensions/BCSFWizardExecution.PageExt.al` | SF-015 |
| Monitoring | 90360 | PageExtension | `BCSF Batch Diagnostics` | `src/Monitoring/PageExtensions/BCSFBatchDiagnostics.PageExt.al` | SF-014 |

Zusätzliche Werte vor Nutzung lokal frei; bestehende Modulblöcke unverändert. Monitoring erhält gerichtete Lesereferenzen auf DependencyManager/SetupManager und den Lifecycle-Guard; keine ausführbare Rückrichtung. Core-Permission-Set weiterhin rein deklarative Ausnahme. Wizard bleibt von diesen Modulen unabhängig. Vertrag, Felder, Rechte, Messgrenzen und Transaktionen: [MONITORING_WIZARD.md](MONITORING_WIZARD.md). Beide Tickets zur Prüfung, keine BC-Laufzeitabnahme.

## SF-014 – JavaScript-Arbeitsplatz und Role-Center nach Nutzerpräzisierung

Zusätzlich sieben reale Objekte; jetzt 104 AL-Objekte, davon 101 mit numerischer ID sowie Interface, ControlAddIn und Profil ohne numerische ID. Monitoring jetzt 18 Dateien/Objekte. Neue Werte 90362–90366 vor Verwendung lokal unbesetzt; 90361 bleibt Modulreserve. Keine Verschiebung oder Umbenennung vorhandener Objekte. Die bisherige Dashboardseite 90351 erhält lediglich die präzisierte Caption Scenario Factory Run Monitor; das neue JS-Dashboard ist separat.

| Modul | Plan-ID | Typ | Objektname | Dateipfad | Ticket |
| --- | --- | --- | --- | --- | --- |
| Monitoring | — | ControlAddIn | `BCSF Dashboard` | `src/Monitoring/ControlAddIns/BCSFDashboard.ControlAddIn.al` | SF-014 |
| Monitoring | 90362 | Page (CardPart) | `BCSF Dashboard Part` | `src/Monitoring/Pages/BCSFDashboardPart.Page.al` | SF-014 |
| Monitoring | 90363 | Page (Card) | `BCSF Dashboard Host` | `src/Monitoring/Pages/BCSFDashboardHost.Page.al` | SF-014 |
| Monitoring | 90364 | Page (RoleCenter) | `BCSF Factory Role Center` | `src/Monitoring/Pages/BCSFFactoryRoleCenter.Page.al` | SF-014 |
| Monitoring | 90365 | Codeunit | `BCSF Dashboard Data` | `src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al` | SF-014 |
| Monitoring | 90366 | Codeunit | `BCSF Dashboard Commands` | `src/Monitoring/Codeunits/BCSFDashboardCommands.Codeunit.al` | SF-014 |
| Monitoring | — | Profile | `BCSF Scenario Factory` | `src/Monitoring/Profiles/BCSFScenarioFactory.Profile.al` | SF-014 |

Monitoring referenziert zusätzlich die vorhandenen UI-/Lesetypen aus ModuleRegistry/DataGeneration; keine Rückreferenz dieser Module. Run Header 90128 erhält ausschließlich den Leseschlüssel CreatedOrder (Created At, Run Id) für die begrenzte neueste Laufprojektion, keine neuen Felder/Schreibwege. JS/CSS/Startup sind gebündelte App-Ressourcen, keine weiteren AL-Objekte oder externen Abhängigkeiten. Profil wird nicht automatisch zugewiesen. Reproduzierbarer lokaler Browsercheck unter `scripts/check_dashboard.mjs`, keine neue AL-Test-Codeunit. [Aktueller Vertrag und Einbauweg](DASHBOARD_EMBEDDING.md).


## SF-016/SF-017 – nachgewiesener Bestand 18.11.2026

116 AL-Dateien in zwölf Modulen (113 numerische IDs sowie Interface, ControlAddIn und Profil). Die folgenden bereits im Ausgangscode vorhandenen Objekte sind nun im Plan erfasst; 90400 bezeichnet den vorhandenen Paketmanager, keine Objektumbenennung.

| Modul | ID | Typ | Objekt | Datei | Ticket |
| --- | --- | --- | --- | --- | --- |
| BackgroundProcessing | 90317 | codeunit | `BCSF Run Quality` | `src/BackgroundProcessing/Codeunits/BCSFRunQuality.Codeunit.al` | SF-016 |
| Core | 90113 | enum | `BCSF Finance Mode` | `src/Core/Enums/BCSFFinanceMode.Enum.al` | SF-017 |
| Finance | 90406 | pageextension | `BCSF Finance Setup` | `src/Finance/PageExtensions/BCSFFinanceSetup.PageExt.al` | SF-017 |
| Finance | 90407 | pageextension | `BCSF Run Finance` | `src/Finance/PageExtensions/BCSFRunFinance.PageExt.al` | SF-017 |
| Finance | 90405 | page | `BCSF Finance Preview` | `src/Finance/Pages/BCSFFinancePreview.Page.al` | SF-017 |
| Finance | 90404 | page | `BCSF Finance Selection` | `src/Finance/Pages/BCSFFinanceSelection.Page.al` | SF-017 |
| Finance | 90403 | table | `BCSF Finance Package` | `src/Finance/Tables/BCSFFinancePackage.Table.al` | SF-017 |
| Validation | 90327 | enum | `BCSF Validation Severity` | `src/Validation/Enums/BCSFValidationSeverity.Enum.al` | SF-016 |
| Validation | 90328 | page | `BCSF Validation Results` | `src/Validation/Pages/BCSFValidationResults.Page.al` | SF-016 |

Validation → Lifecycle für den bestehenden Sandbox-/Firmen-Guard. BackgroundProcessing → Validation einschließlich Pflichtsubscriber OnCheckResult; keine Rückreferenz im Validation-Modul. Finance → ScenarioManagement/SetupManager/Lifecycle wie vorgesehen; Core-Permission-Set bleibt deklarative Ausnahme. Keine neuen Runtime-/App-Dependencies. [Vertrag](VALIDATION_FINANCE.md).


## SF-018 – Partnergeneratoren, 18.11.2026

121 AL-Dateien in 14 Modulen, davon 118 numerische IDs sowie Interface/ControlAddIn/Profil. Vorhandene Planreservierungen 90425 und 90450 implementiert; drei zusätzliche freie Werte im eigenen Modulblock ergänzt:

| Modul | ID | Typ | Objekt | Datei | Ticket |
| --- | --- | --- | --- | --- | --- |
| DataGeneration | 90256 | Codeunit | `BCSF Partner Rules` | `src/DataGeneration/Codeunits/BCSFPartnerRules.Codeunit.al` | SF-018 |
| Sales | 90427 | EnumExtension | `BCSF Customer Binding` | `src/Sales/EnumExtensions/BCSFCustomerBinding.EnumExt.al` | SF-018 |
| Purchasing | 90452 | EnumExtension | `BCSF Vendor Binding` | `src/Purchasing/EnumExtensions/BCSFVendorBinding.EnumExt.al` | SF-018 |

EnumExtensions binden Werte 90425/90450 des bestehenden Generator-Type-Enums. Keine Änderung vorhandener Enumwerte oder zentralen Registry-Imports auf Fachmodule. DataGeneration bleibt ohne Lifecycle-/BackgroundProcessing-Import: verpflichtender BackgroundProcessing-Subscriber am Partner-Batchereignis führt die bestehenden Environment-/Besitzprüfungen aus. Finance erfasst Paketgruppen und Standard-Setupfingerprints über ein enges neues Snapshotereignis. SetupManager nutzt seine bereits erlaubte Registry-Abhängigkeit für konkrete Partner-Prerequisites. Keine neue gerichtete Geschäftsmodul-Abhängigkeit und keine app.json-Dependency. [Vertrag](PARTNER_GENERATION.md).

## Startvorlagen, Schnellstart und Sammeltransfer – 18.11.2026

| Modul | ID | Typ | Objekt |
| --- | ---: | --- | --- |
| ScenarioManagement | 90147 | Codeunit | BCSF Scenario Transfer |
| IndustryProfiles | 90155 | Codeunit | BCSF Starter Catalog |
| IndustryProfiles | 90156 | Install-Codeunit | BCSF Starter Install |
| IndustryProfiles | 90157 | Upgrade-Codeunit | BCSF Starter Upgrade |
| Monitoring | 90367 | Codeunit | BCSF Quick Scenario Run |
| Monitoring | 90368 | PageExtension | BCSF Scenario Actions |
| Finance | 90408 | Codeunit | BCSF Demo Partner Setup |

Monitoring referenziert IndustryProfiles und Finance für diese Bedienaktionen. Die zusätzlichen Referenzen gehen vom UI-Orchestrator zu den Diensten, nicht umgekehrt. Das Install-/Upgrade-Seeding schreibt ausschließlich eigene, mandantenbezogene App-Daten. Keine Änderungen bestehender IDs. Details und BC-Prüfplan: [STARTER_TEMPLATES.md](STARTER_TEMPLATES.md).


## SF-037 – zusätzliche belegte ID, 18.11.2026

| ID | Typ | Objekt | Datei | Zweck |
| --- | --- | --- | --- | --- |
| 90148 | Table | BCSF Removed Template | `src/ScenarioManagement/Tables/BCSFRemovedTemplate.Table.al` | Firmenbezogener Entfernt-Vermerk; normaler Starterseed darf absichtliche Entfernung nicht rückgängig machen |

90148 liegt im bestehenden ScenarioManagement-Block 90125–90149; vor Anlage keine lokale Objekt-/Planbelegung gefunden. Keine weiteren Objekt-IDs reserviert, keine Standarddaten oder historischen Laufdaten migriert. Lifecycle-Subscriber sichern Insert/Modify/Delete/Rename auch ohne Tabellentrigger.


## SF-039 – zusätzlich belegte IDs, 18.11.2026

| Modul | ID | Typ | Objekt | Datei |
| --- | --- | --- | --- | --- |
| DataGeneration | 90257 | Codeunit | BCSF Partner Catalog | `src/DataGeneration/Codeunits/BCSFPartnerCatalog.Codeunit.al` |
| DataGeneration | 90258 | Codeunit | BCSF Partner Children | `src/DataGeneration/Codeunits/BCSFPartnerChildren.Codeunit.al` |

Beide vor Anlage im aktuellen Code und Objektplan frei; innerhalb des bestehenden Modulblocks 90250–90274. 131 AL-Dateien insgesamt. Keine neuen Generatorbindungen oder Testobjekte. **Zur Prüfung**.


## SF-041 – Datenbestand

| Modul | ID | Typ | Objekt |
| --- | --- | --- | --- |
| Monitoring | 90369 | Codeunit | BCSF Dashboard Stock |

## SF-019 – belegte Ergänzungen 20.11.2026

| Modul | ID | Typ | Objekt | Pfad |
| --- | --- | --- | --- | --- |
| Inventory | 90475 | Codeunit | BCSF Inventory Generator | `src/Inventory/Codeunits/BCSFInventoryGenerator.Codeunit.al` |
| Inventory | 90476 | EnumExtension | BCSF Item Binding | `src/Inventory/EnumExtensions/BCSFItemBinding.EnumExt.al` |
| Inventory | 90477 | Codeunit | BCSF Item Catalog | `src/Inventory/Codeunits/BCSFItemCatalog.Codeunit.al` |
| Inventory | 90478 | Codeunit | BCSF Item Setup | `src/Inventory/Codeunits/BCSFItemSetup.Codeunit.al` |
| Inventory | 90479 | Codeunit | BCSF Item Relations | `src/Inventory/Codeunits/BCSFItemRelations.Codeunit.al` |
| Inventory | 90480 | Codeunit | BCSF Item Masters | `src/Inventory/Codeunits/BCSFItemMasters.Codeunit.al` |
| Separate SF-019-Test-App | 90700 | Test-Codeunit | BCSF Inventory Tests | `tests/SF019/BCSFInventoryTests.Codeunit.al` |

Main-Objekte im freigegebenen Inventory-Block 90475–90499; Testbereich 90700–90709 für die ausdrücklich verlangte separate SF-019-Test-App aus der gemeinsamen Reserve gewählt, davon nur 90700 belegt. Keine neue Main-Tabelle oder Seite. Externe Fremd-App-Kollisionen bleiben in der Ziel-Sandbox zu prüfen. Core referenziert Inventory ausschließlich deklarativ im ADMIN-Permission-Set; keine neue ausführbare Rückabhängigkeit.

## SF-021 – reale Ergänzungen, 20.11.2026

| Modul | ID | Typ | Objekt | Pfad |
| --- | --- | --- | --- | --- |
| ProcessEngine | 90275 | Codeunit | BCSF Process Coordinator | `src/ProcessEngine/Codeunits/BCSFProcessCoordinator.Codeunit.al` |
| Sales | 90426 | Codeunit | BCSF Sales Generator | `src/Sales/Codeunits/BCSFSalesGenerator.Codeunit.al` |
| Sales | 90428 | EnumExtension | BCSF Sales Binding | `src/Sales/EnumExtensions/BCSFSalesBinding.EnumExt.al` |
| Sales | 90429 | Codeunit | BCSF Sales Setup | `src/Sales/Codeunits/BCSFSalesSetup.Codeunit.al` |
| Sales | 90430 | Codeunit | BCSF Sales Documents | `src/Sales/Codeunits/BCSFSalesDocuments.Codeunit.al` |
| Sales | 90431 | Codeunit | BCSF Sales Evidence | `src/Sales/Codeunits/BCSFSalesEvidence.Codeunit.al` |

90275/90426 waren geplant und lokal unimplementiert; 90428–90431 vor Anlage frei, innerhalb des bestehenden Sales-Blocks. Main insgesamt 133 AL-Dateien, keine neue Tabelle/Seite; vorhandene Test-Codeunit 90700 um sechs Methoden ergänzt, keine neue Test-ID. Zwei additive Szenariofelder 41/42. Core referenziert ProcessEngine/Sales nur deklarativ im ADMIN-Execute-Permission-Set. Kein Standardtabledata-Recht hinzugefügt. Externe ID-Konflikte in der Ziel-Sandbox weiterhin zu prüfen.

## SF-045 – belegte Ergänzungen

Vor Erstellung gegen aktuelle app.json und Quellobjekte geprüft: 90153 war nur als Wholesale Profile geplant, 90361 unbesetzte Monitoringreserve, 90451 als Purchase Generator geplant, 90453 unbelegt. Alle liegen in 90100–90999. Keine bestehende ID/Enumzuordnung wiederverwendet oder umnummeriert.

| Modul | ID | Typ | Objekt / Pfad |
| --- | --- | --- | --- |
| IndustryProfiles | 90153 | Codeunit | `src/IndustryProfiles/Codeunits/BCSFWholesaleProfile.Codeunit.al` |
| Monitoring | 90361 | Codeunit | `src/Monitoring/Codeunits/BCSFCompanyInitialization.Codeunit.al` |
| Purchasing | 90451 | Codeunit | `src/Purchasing/Codeunits/BCSFPurchaseGenerator.Codeunit.al` |
| Purchasing | 90453 | EnumExtension | `src/Purchasing/EnumExtensions/BCSFPurchaseBinding.EnumExt.al` |

Orchestrierung bleibt in Monitoring, die bestehende Setupkarte delegiert dorthin. Purchasing nutzt Inventory für eingefrorene Artikelmengen/Einrichtung, keine duplizierte Artikelauflösung und keine App-Dependency. Snapshot publiziert OnCapturePurchaseSetup, Purchasing abonniert mit beiden Skipflags false. [Vollinventar und Ereignisse](ARCHITECTURE_AUDIT_SF045.md).


## 1.0.7.0 – tatsächlich ergänzte Objekte

Codeunit 90401 BCSF Payment Processor (bereits für SF-022 geplant) und Codeunit 90454 BCSF Purchase Evidence (vor Erstellung unbesetzte Purchasingreserve) innerhalb des freigegebenen app.json-Bereichs. Keine Kollision/Umnummerierung. Beide intern; BCSF ADMIN ergänzt nur Codeunit-Ausführung. Keine neue Standardtabellenberechtigung oder App-Abhängigkeit. Purchasing nutzt den gemeinsamen Finance-Dienst, dieser verifiziert Claims über DataGeneration ohne direkte BackgroundProcessing-Abhängigkeit.
