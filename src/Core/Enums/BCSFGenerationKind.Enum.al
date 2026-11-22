namespace BCScenarioFactory.Core;

enum 90114 "BCSF Generation Kind"
{
  Access = Internal;
  Extensible = false;
  value(0; Complete) { Caption = 'Complete scenario'; }
  value(1; MasterData) { Caption = 'Master data only'; }
  value(2; Transactions) { Caption = 'Transactions only'; }
}
