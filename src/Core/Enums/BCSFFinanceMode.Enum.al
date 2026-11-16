namespace BCScenarioFactory.Core;

enum 90113 "BCSF Finance Mode"
{
  Access = Internal;
  Extensible = false;

  value(0; Existing) { Caption = 'Use existing BC setup'; }
  value(1; SKR03) { Caption = 'SKR03 test chart'; }
  value(2; SKR04) { Caption = 'SKR04 test chart'; }
}
