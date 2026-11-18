namespace BCScenarioFactory.Sales;

using BCScenarioFactory.ModuleRegistry;

enumextension 90427 "BCSF Customer Binding" extends "BCSF Generator Type"
{
  value(90425; Customer)
  {
    Caption = 'Synthetic Customer Master Data';
    Implementation = "BCSF Generator" = "BCSF Customer Generator";
  }
}
