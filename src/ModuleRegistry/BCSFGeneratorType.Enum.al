namespace BCScenarioFactory.ModuleRegistry;

enum 90176 "BCSF Generator Type" implements "BCSF Generator"
{
  Access = Internal;
  Extensible = true;
  DefaultImplementation = "BCSF Generator" = "BCSF Missing Generator";
  UnknownValueImplementation = "BCSF Generator" = "BCSF Missing Generator";

  value(0; Unspecified) { Caption = 'Unspecified'; }
  value(1; CustomerProbe)
  {
    Caption = 'Customer Contract Probe';
    Implementation = "BCSF Generator" = "BCSF Customer Probe";
  }
  value(2; VendorProbe)
  {
    Caption = 'Vendor Contract Probe';
    Implementation = "BCSF Generator" = "BCSF Vendor Probe";
  }
}
