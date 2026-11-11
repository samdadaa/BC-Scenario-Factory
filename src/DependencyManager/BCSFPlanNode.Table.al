namespace BCScenarioFactory.DependencyManager;

using BCScenarioFactory.Core;

table 90203 "BCSF Plan Node"
{
  Access = Internal;
  Caption = 'Plan Node';
  DataClassification = SystemMetadata;
  TableType = Temporary;

  fields
  {
    field(1; "Node Code"; Code[30])
    {
      Caption = 'Node Code';
      ToolTip = 'Specifies the stable planning node.';
    }
    field(2; "Module Code"; Code[30])
    {
      Caption = 'Module Code';
      ToolTip = 'Specifies the required business module.';
    }
    field(3; "Entity Code"; Code[30])
    {
      Caption = 'Entity Code';
      ToolTip = 'Specifies the entity or external prerequisite.';
    }
    field(4; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Process Mode';
      ToolTip = 'Specifies the frozen process mode.';
    }
    field(5; "Work Units"; Integer)
    {
      Caption = 'Planned Work Units';
      ToolTip = 'Specifies work units for this node, not a global generated record count.';
    }
    field(6; "Generator Code"; Code[30])
    {
      Caption = 'Generator Code';
      ToolTip = 'Specifies the stable generator identity.';
    }
    field(7; "Generator Version"; Code[20])
    {
      Caption = 'Generator Version';
      ToolTip = 'Specifies the selected implementation version.';
    }
    field(8; "Contract Version"; Integer)
    {
      Caption = 'Contract Version';
      ToolTip = 'Specifies the supported generator contract version.';
    }
    field(9; "External Check"; Boolean)
    {
      Caption = 'External Check';
      ToolTip = 'Specifies a prerequisite requiring independent preflight evidence.';
    }
    field(10; "Issue"; Enum "BCSF Plan Issue")
    {
      Caption = 'Blocker';
      ToolTip = 'Specifies the blocking condition for this step.';
    }
    field(11; "Reference Code"; Code[30])
    {
      Caption = 'Reference Code';
      ToolTip = 'Specifies the prerequisite or module related to the blocker.';
    }
    field(12; "Sequence No."; Integer)
    {
      Caption = 'Sequence';
      ToolTip = 'Specifies the deterministic topological position. Zero denotes an unsorted node.';
    }
    field(13; "Processed"; Boolean)
    {
      Caption = 'Processed';
      ToolTip = 'Specifies internal graph traversal state.';
    }
    field(14; "In Degree"; Integer)
    {
      Caption = 'Predecessor Count';
      ToolTip = 'Specifies the remaining incoming edges during sorting.';
    }
  }
  keys
  {
    key(PK; "Node Code") { Clustered = true; }
    key(Ready; Processed, "In Degree", "Node Code") { }
  }
}
