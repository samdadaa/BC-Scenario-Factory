# Modulindex – Zielarchitektur

**Aktueller Bestand SF-018, 18.11.2026:** 121 AL-Dateien in 14 Modulen; zehn Module ohne AL-Code. Zwei echte Partnerstammdatengeneratoren, Qualitätsabschluss und Finanztestpakete zur Prüfung; BC-Laufzeitabnahme weiterhin offen. [Partnervertrag](../PARTNER_GENERATION.md).

| Modul | Kategorie | Ziel | Status |
| --- | --- | --- | --- |
| [Core](details/src/Core.md) | Kern | `src/Core/` | Grundlagen/Sprache/Vertrag/Finanzmodus: 14 AL-Objekte, zur Prüfung |
| [ScenarioManagement](details/src/ScenarioManagement.md) | Kern | `src/ScenarioManagement/` | Vorlagen/Ziele/Snapshots/Steps/Wizard: 22 AL-Objekte, zur Prüfung |
| [IndustryProfiles](details/src/IndustryProfiles.md) | Kern | `src/IndustryProfiles/` | 1 AL-Objekt: generische versionierte Syntheseregeln; zur Prüfung. Vollständige Branchenprofile weiterhin geplant. |
| [ModuleRegistry](details/src/ModuleRegistry.md) | Kern | `src/ModuleRegistry/` | Vertrag/Katalog/Proben: 10 AL-Objekte, zur Prüfung |
| [DependencyManager](details/src/DependencyManager.md) | Kern | `src/DependencyManager/` | Graph/Plan/Vorschau: 9 AL-Objekte, zur Prüfung |
| [SetupManager](details/src/SetupManager.md) | Kern | `src/SetupManager/` | 4 AL-Objekte: temporärer Setup-Diff, Manager, Vorschau und Laufkarten-Erweiterung; zur Prüfung. |
| [DataGeneration](details/src/DataGeneration.md) | Kern | `src/DataGeneration/` | 7 AL-Objekte: Partnerregeln, Seed, Vorschau und immutable Herkunftsregistry; zur Prüfung. |
| [ProcessEngine](details/src/ProcessEngine.md) | Kern | `src/ProcessEngine/` | Geplant, ohne Code |
| [BackgroundProcessing](details/src/BackgroundProcessing.md) | Kern | `src/BackgroundProcessing/` | 17 AL-Objekte: Qualitätsabschluss, Ausführung, Queue und begrenzte Recovery mit Checkpoints/Steuerung; zur Prüfung. |
| [Validation](details/src/Validation.md) | Kern | `src/Validation/` | 4 AL-Objekte: immutable Qualitätsbefunde, Manager, Severity und Ergebnisliste; zur Prüfung |
| [Monitoring](details/src/Monitoring.md) | Kern | `src/Monitoring/` | 18 AL-Objekte: JS-Dashboard, Role-Center/Profil, Kennzahlen, Historie und Wizard-Ausführungsintegration, zur Prüfung |
| [Lifecycle](details/src/Lifecycle.md) | Kern | `src/Lifecycle/` | Teilweise implementiert, 4 AL-Objekte, Zur Prüfung. |
| [Finance](details/src/Finance.md) | Fach | `src/Finance/` | 7 AL-Objekte: lesender Finanzcheck, versionierter Paketmanager/Paketvermerk, Auswahl/Vorschau und zwei PageExtensions; zur Prüfung. Keine Fachbuchungsgeneratoren. |
| [Sales](details/src/Sales.md) | Fach | `src/Sales/` | 2 AL-Objekte: echter Customer-Generator und EnumExtension-Bindung; zur Prüfung. Beleggeneratoren geplant. |
| [Purchasing](details/src/Purchasing.md) | Fach | `src/Purchasing/` | 2 AL-Objekte: echter Vendor-Generator und EnumExtension-Bindung; zur Prüfung. Beleggeneratoren geplant. |
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

SF-013: [Recovery-Vertrag](../RECOVERY.md), [Prüfnachweise](../TESTS.md).


## Ablage – SF-002, 16.11.2026

Alle 104 vorhandenen AL-Dateien liegen je Modul in Typordnern gemäß [CONVENTIONS.md](../CONVENTIONS.md). Die Modulpfade der Tabelle bleiben Einstiegspunkte; die konkreten Typordner stehen in den jeweiligen Modulspezifikationen. Keine neuen Objekte oder fachlichen Implementierungen; 13 Module weiterhin ohne AL-Code. Status **Zur Prüfung**.


## SF-014 – Dashboardkorrektur 17.11.2026

Eigener Scrollbereich und generierte deutsche UI-Fallback-Ressource im bestehenden Monitoring-Dashboard ergänzt; keine neuen AL-Objekte. [Vertrag](../DASHBOARD_EMBEDDING.md), [Prüfnachweis](../TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). **Zur Prüfung**.
