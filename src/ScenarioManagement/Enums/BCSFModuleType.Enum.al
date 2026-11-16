namespace BCScenarioFactory.ScenarioManagement;

enum 90146 "BCSF Module Type"
{
  Access = Internal;
  Extensible = false;

  value(0; Sales) { Caption = 'Sales'; }
  value(1; Purchasing) { Caption = 'Purchasing'; }
  value(2; Inventory) { Caption = 'Inventory'; }
  value(3; Finance) { Caption = 'Finance'; }
  value(4; Warehouse) { Caption = 'Warehouse'; }
  value(5; Manufacturing) { Caption = 'Manufacturing'; }
  value(6; Assembly) { Caption = 'Assembly'; }
  value(7; Projects) { Caption = 'Projects'; }
  value(8; ServiceManagement) { Caption = 'Service Management'; }
  value(9; FixedAssets) { Caption = 'Fixed Assets'; }
  value(10; CRM) { Caption = 'CRM'; }
  value(11; Planning) { Caption = 'Planning'; }
}
