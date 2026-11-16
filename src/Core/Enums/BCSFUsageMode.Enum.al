namespace BCScenarioFactory.Core;

enum 90104 "BCSF Usage Mode"
{
  Access = Internal;
  Extensible = false;

  value(0; Demo) { Caption = 'Demo'; }
  value(1; Training) { Caption = 'Training'; }
  value(2; Functional) { Caption = 'Functional Test'; }
  value(3; Performance) { Caption = 'Performance Test'; }
}
