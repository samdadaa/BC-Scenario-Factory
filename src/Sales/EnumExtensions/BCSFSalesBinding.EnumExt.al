namespace BCScenarioFactory.Sales;

using BCScenarioFactory.ModuleRegistry;

enumextension 90428 "BCSF Sales Binding" extends "BCSF Generator Type"
{
  value(90426; SalesDocuments)
  {
    Caption = 'Sales Documents';
    Implementation = "BCSF Generator" = "BCSF Sales Generator";
  }
}
