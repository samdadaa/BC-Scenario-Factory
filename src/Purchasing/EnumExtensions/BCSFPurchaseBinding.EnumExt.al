namespace BCScenarioFactory.Purchasing;

using BCScenarioFactory.ModuleRegistry;

enumextension 90453 "BCSF Purchase Binding" extends "BCSF Generator Type"
{
  value(90451; PurchaseDocuments)
  {
    Caption = 'Purchase Documents';
    Implementation = "BCSF Generator" = "BCSF Purchase Generator";
  }
}
