# Modulindex – Zielarchitektur

**Aktueller Bestand nach SF-007/SF-008:** 56 AL-Objekte: Core 13, ScenarioManagement 21, ModuleRegistry 10 (mit Interface), DependencyManager 9, Lifecycle 3; übrige 19 Module ohne AL-Code. Registry mit zwei lesenden Vertragsproben und blockierender Laufplan implementiert, zur Prüfung. Fachgeneratoren, Queue und Dashboard bleiben geplant. Build/Übersetzungen lokal geprüft, BC-Laufzeitabnahme offen.

| Modul | Kategorie | Ziel | Status |
| --- | --- | --- | --- |
| [Core](details/src/Core.md) | Kern | `src/Core/` | Grundlagen/Sprache/Vertrag: 13 AL-Objekte, zur Prüfung |
| [ScenarioManagement](details/src/ScenarioManagement.md) | Kern | `src/ScenarioManagement/` | Vorlagen/Ziele/Snapshots/Steps: 21 AL-Objekte, zur Prüfung |
| [IndustryProfiles](details/src/IndustryProfiles.md) | Kern | `src/IndustryProfiles/` | Geplant, ohne Code |
| [ModuleRegistry](details/src/ModuleRegistry.md) | Kern | `src/ModuleRegistry/` | Vertrag/Katalog/Proben: 10 AL-Objekte, zur Prüfung |
| [DependencyManager](details/src/DependencyManager.md) | Kern | `src/DependencyManager/` | Graph/Plan/Vorschau: 9 AL-Objekte, zur Prüfung |
| [SetupManager](details/src/SetupManager.md) | Kern | `src/SetupManager/` | Geplant, ohne Code |
| [DataGeneration](details/src/DataGeneration.md) | Kern | `src/DataGeneration/` | Geplant, ohne Code |
| [ProcessEngine](details/src/ProcessEngine.md) | Kern | `src/ProcessEngine/` | Geplant, ohne Code |
| [BackgroundProcessing](details/src/BackgroundProcessing.md) | Kern | `src/BackgroundProcessing/` | Geplant, ohne Code |
| [Validation](details/src/Validation.md) | Kern | `src/Validation/` | Geplant, ohne Code |
| [Monitoring](details/src/Monitoring.md) | Kern | `src/Monitoring/` | Geplant, ohne Code |
| [Lifecycle](details/src/Lifecycle.md) | Kern | `src/Lifecycle/` | Setup-/Szenario-/Planguards: 3 AL-Objekte, zur Prüfung |
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

**SF-002, 11.11.2026:** Für alle 24 Module sind ID-Blöcke, Namespaces, geplante Objekte und erlaubte Codeabhängigkeiten in [OBJECT_PLAN.md](../OBJECT_PLAN.md) dokumentiert. Modulspezifikationen darauf abgestimmt. Historischer Stand von SF-002: 0 AL-Objekte, 59 numerische Planobjekte und ein Interface. Der aktuelle Implementierungsstand steht oben; der Objektplan enthält inzwischen zusätzlich die Management-Codeunits 90106/90107.

**SF-005/SF-006:** Gegenüber der Foundation 23 neue Objekte. Keine Implementierung weiterer Modulverantwortungen; Quelle und Grenzen: [SCENARIO_CONFIGURATION.md](../SCENARIO_CONFIGURATION.md).

SF-007/SF-008: [Generator- und Planungsvertrag](../GENERATOR_PLANNING.md); alle implementierten Objekte im aktuellen [Objektplan](../OBJECT_PLAN.md).
