namespace BCScenarioFactory.Core;

enum 90112 "BCSF Dependency Kind"
{
  Access = Internal;
  Extensible = false;
  value(0; Required) { Caption = 'Required'; }
  value(1; Optional) { Caption = 'Optional'; }
  value(2; External) { Caption = 'External Check'; }
}
