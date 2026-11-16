namespace BCScenarioFactory.Validation;

enum 90327 "BCSF Validation Severity"
{
  Access = Internal;
  Extensible = false;

  value(0; Passed) { Caption = 'Passed'; }
  value(1; Warning) { Caption = 'Warning'; }
  value(2; Error) { Caption = 'Error'; }
}
