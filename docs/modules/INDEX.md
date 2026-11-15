# Modulindex – Zielarchitektur

**Aktueller Bestand nach SF-011/SF-012:** 81 AL-Objekte in zehn Modulen, 14 Module ohne AL-Code. DataGeneration 6, BackgroundProcessing 12, Lifecycle 4; übrige Modulzahlen unverändert. Immutable Herkunftsregistry und serielle Queue-Grundlage zur Prüfung. Echte Fachgeneratoren, Recovery, globale Qualitätsprüfung und Laufzeitabnahme weiterhin ausstehend.

| Modul | Kategorie | Ziel | Status |
| --- | --- | --- | --- |
| [Core](details/src/Core.md) | Kern | `src/Core/` | Grundlagen/Sprache/Vertrag: 13 AL-Objekte, zur Prüfung |
| [ScenarioManagement](details/src/ScenarioManagement.md) | Kern | `src/ScenarioManagement/` | Vorlagen/Ziele/Snapshots/Steps: 21 AL-Objekte, zur Prüfung |
| [IndustryProfiles](details/src/IndustryProfiles.md) | Kern | `src/IndustryProfiles/` | 1 AL-Objekt: generische versionierte Syntheseregeln; zur Prüfung. Vollständige Branchenprofile weiterhin geplant. |
| [ModuleRegistry](details/src/ModuleRegistry.md) | Kern | `src/ModuleRegistry/` | Vertrag/Katalog/Proben: 10 AL-Objekte, zur Prüfung |
| [DependencyManager](details/src/DependencyManager.md) | Kern | `src/DependencyManager/` | Graph/Plan/Vorschau: 9 AL-Objekte, zur Prüfung |
| [SetupManager](details/src/SetupManager.md) | Kern | `src/SetupManager/` | 4 AL-Objekte: temporärer Setup-Diff, Manager, Vorschau und Laufkarten-Erweiterung; zur Prüfung. |
| [DataGeneration](details/src/DataGeneration.md) | Kern | `src/DataGeneration/` | 6 AL-Objekte: Seed, Vorschau und immutable Herkunftsregistry; zur Prüfung. |
| [ProcessEngine](details/src/ProcessEngine.md) | Kern | `src/ProcessEngine/` | Geplant, ohne Code |
| [BackgroundProcessing](details/src/BackgroundProcessing.md) | Kern | `src/BackgroundProcessing/` | 12 AL-Objekte: operative Ausführung, Batches, Dispatcher, Worker, Guards und UI; zur Prüfung. Recovery weiterhin geplant. |
| [Validation](details/src/Validation.md) | Kern | `src/Validation/` | Geplant, ohne Code |
| [Monitoring](details/src/Monitoring.md) | Kern | `src/Monitoring/` | Geplant, ohne Code |
| [Lifecycle](details/src/Lifecycle.md) | Kern | `src/Lifecycle/` | Teilweise implementiert, 4 AL-Objekte, Zur Prüfung. |
| [Finance](details/src/Finance.md) | Fach | `src/Finance/` | 1 AL-Objekt: lesender Finanz-Setupcheck; zur Prüfung. Finanzgenerator/Buchungen weiterhin geplant. |
| [Sales](details/src/Sales.md) | Fach | `src/Sales/` | Geplant, ohne Code |
| [Purchasing](details/src/Purchasing.md) | Fach | `src/Purchasing/` | Geplant, ohne Code |
| [Inventory](details/src/Inventory.md) | Fach | `src/Inventory/` | Geplant, ohne Code |
| [Warehouse](details/src/Warehouse.md) | Fach | `src/Warehouse/` | Geplant, ohne Code |
| [Manufacturing](details/src/Manufacturing.md) | Fach | `src/Manufacturing/` | Geplant, ohne Code |
| [Assembly](details/src/Assembly.md) | Fach | `src/Assembly/` | Geplant, ohne Code |
| [Projects](details/src/Projects.md) | Fach | `src/Projects/` | Geplant, ohne Code |
| [ServiceManagement](details/src/ServiceManagement.md) | Fach | `src/ServiceManagement/` | Geplant, ohne Code |
| [FixedAssets](details/src/FixedAssets.md) | Fach | `src/FixedAssets/` | Geplant, ohne Code |
| [CRM](details/src/CRM.md) | Fach | `src/CRM/` | Geplant, ohne Code |
| [Planning](details/src/Planning.md) | Fach | `src/Planning/` | Geplant, ohne Code |

**MVP:** Alle Kernverantwortungen konzeptionell notwendig, zunächst Finance, Sales, Purchasing, Inventory umsetzen. Warehouse usw. dürfen als leere Verzeichnisse bleiben. Jedes Modul besitzt eine eigene Spezifikation; bei Implementierung tatsächliche AL-Objekte nachtragen.

**SF-002, 11.11.2026:** Für alle 24 Module sind ID-Blöcke, Namespaces, geplante Objekte und erlaubte Codeabhängigkeiten in [OBJECT_PLAN.md](../OBJECT_PLAN.md) dokumentiert. Modulspezifikationen darauf abgestimmt. Historischer Stand von SF-002: 0 AL-Objekte, 59 numerische Planobjekte und ein Interface. Der aktuelle Implementierungsstand steht oben; der Objektplan enthält inzwischen zusätzlich die Management-Codeunits 90106/90107.

**SF-005/SF-006:** Gegenüber der Foundation 23 neue Objekte. Keine Implementierung weiterer Modulverantwortungen; Quelle und Grenzen: [SCENARIO_CONFIGURATION.md](../SCENARIO_CONFIGURATION.md).

SF-007/SF-008: [Generator- und Planungsvertrag](../GENERATOR_PLANNING.md); alle implementierten Objekte im aktuellen [Objektplan](../OBJECT_PLAN.md).

SF-009/SF-010: [Setup-/Seed-Vertrag](../SETUP_SEED.md); vollständige Objektzuordnung im [Objektplan](../OBJECT_PLAN.md).

SF-011/SF-012: [Herkunft-/Queue-Vertrag](../EXECUTION_REGISTRY.md), [Objektplan](../OBJECT_PLAN.md).
