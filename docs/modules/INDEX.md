# Modulindex – Zielarchitektur

**Bestand:** Alle 24 Verzeichnisse sind geplant und enthalten nur `.gitkeep`; **0 implementierte AL-Objekte**. Aus einem Ordnernamen folgt keine bereits existente Funktion. Kernmodule/Fachmodule und Verantwortungen sind **Entwurfsdefinitionen**.

| Modul | Kategorie | Ziel | Status |
| --- | --- | --- | --- |
| [Core](details/src/Core.md) | Kern | `src/Core/` | Geplant, ohne Code |
| [ScenarioManagement](details/src/ScenarioManagement.md) | Kern | `src/ScenarioManagement/` | Geplant, ohne Code |
| [IndustryProfiles](details/src/IndustryProfiles.md) | Kern | `src/IndustryProfiles/` | Geplant, ohne Code |
| [ModuleRegistry](details/src/ModuleRegistry.md) | Kern | `src/ModuleRegistry/` | Geplant, ohne Code |
| [DependencyManager](details/src/DependencyManager.md) | Kern | `src/DependencyManager/` | Geplant, ohne Code |
| [SetupManager](details/src/SetupManager.md) | Kern | `src/SetupManager/` | Geplant, ohne Code |
| [DataGeneration](details/src/DataGeneration.md) | Kern | `src/DataGeneration/` | Geplant, ohne Code |
| [ProcessEngine](details/src/ProcessEngine.md) | Kern | `src/ProcessEngine/` | Geplant, ohne Code |
| [BackgroundProcessing](details/src/BackgroundProcessing.md) | Kern | `src/BackgroundProcessing/` | Geplant, ohne Code |
| [Validation](details/src/Validation.md) | Kern | `src/Validation/` | Geplant, ohne Code |
| [Monitoring](details/src/Monitoring.md) | Kern | `src/Monitoring/` | Geplant, ohne Code |
| [Lifecycle](details/src/Lifecycle.md) | Kern | `src/Lifecycle/` | Geplant, ohne Code |
| [Finance](details/src/Finance.md) | Fach | `src/Finance/` | Geplant, ohne Code |
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
