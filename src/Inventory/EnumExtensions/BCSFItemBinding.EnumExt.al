namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.ModuleRegistry;

enumextension 90476 "BCSF Item Binding" extends "BCSF Generator Type"
{
  value(90475; Inventory)
  {
    Caption = 'Technical Wholesale Items';
    Implementation = "BCSF Generator" = "BCSF Inventory Generator";
  }
}
