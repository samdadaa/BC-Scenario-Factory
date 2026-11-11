namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;

table 90200 "BCSF Dependency"
{
  Access = Internal;
  Caption = 'Planning Dependency';
  DataClassification = SystemMetadata;
  TableType = Temporary;

  fields
  {
    field(1; "Node Code"; Code[30])
    {
      Caption = 'Dependent Node';
      ToolTip = 'Specifies the node that must wait.';
    }
    field(2; "Predecessor Code"; Code[30])
    {
      Caption = 'Predecessor';
      ToolTip = 'Specifies the preceding node or external check.';
    }
    field(3; "Kind"; Enum "BCSF Dependency Kind")
    {
      Caption = 'Dependency Kind';
      ToolTip = 'Specifies whether the dependency is required, optional or external.';
    }
  }
  keys
  {
    key(PK; "Node Code", "Predecessor Code") { Clustered = true; }
    key(Predecessor; "Predecessor Code", "Node Code") { }
  }
}
