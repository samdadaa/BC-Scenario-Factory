namespace BCScenarioFactory.Purchasing;

using BCScenarioFactory.ModuleRegistry;

enumextension 90452 "BCSF Vendor Binding" extends "BCSF Generator Type"
{
  value(90450; Vendor)
  {
    Caption = 'Synthetic Vendor Master Data';
    Implementation = "BCSF Generator" = "BCSF Vendor Generator";
  }
}
