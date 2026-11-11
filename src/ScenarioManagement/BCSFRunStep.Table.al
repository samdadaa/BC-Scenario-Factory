namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90129 "BCSF Run Step"
{
  Access = Internal;
  Caption = 'Saved Run Step';
  DataClassification = SystemMetadata;

  fields
  {
    field(1; "Run Id"; Guid)
    {
      Caption = 'Run ID';
      ToolTip = 'Specifies the owning captured run.';
    }
    field(2; "Node Code"; Code[30])
    {
      Caption = 'Node Code';
      ToolTip = 'Specifies the stable planning node.';
    }
    field(3; "Module Code"; Code[30])
    {
      Caption = 'Module Code';
      ToolTip = 'Specifies the required business module.';
    }
    field(4; "Entity Code"; Code[30])
    {
      Caption = 'Entity Code';
      ToolTip = 'Specifies the entity or external prerequisite.';
    }
    field(5; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Process Mode';
      ToolTip = 'Specifies the frozen process mode.';
    }
    field(6; "Work Units"; Integer)
    {
      Caption = 'Planned Work Units';
      ToolTip = 'Specifies work units for this node, not a global generated record count.';
    }
    field(7; "Generator Code"; Code[30])
    {
      Caption = 'Generator Code';
      ToolTip = 'Specifies the stable generator identity.';
    }
    field(8; "Generator Version"; Code[20])
    {
      Caption = 'Generator Version';
      ToolTip = 'Specifies the selected implementation version.';
    }
    field(9; "Contract Version"; Integer)
    {
      Caption = 'Contract Version';
      ToolTip = 'Specifies the supported generator contract version.';
    }
    field(10; "External Check"; Boolean)
    {
      Caption = 'External Check';
      ToolTip = 'Specifies a prerequisite requiring independent preflight evidence.';
    }
    field(11; "Issue"; Enum "BCSF Plan Issue")
    {
      Caption = 'Blocker';
      ToolTip = 'Specifies the blocking condition for this step.';
    }
    field(12; "Reference Code"; Code[30])
    {
      Caption = 'Reference Code';
      ToolTip = 'Specifies the prerequisite or module related to the blocker.';
    }
    field(13; "Sequence No."; Integer)
    {
      Caption = 'Sequence';
      ToolTip = 'Specifies the deterministic topological position. Zero denotes an unsorted node.';
    }
    field(14; "Plan Version"; Integer)
    {
      Caption = 'Plan Version';
      ToolTip = 'Specifies the planning schema version.';
    }
  }
  keys
  {
    key(PK; "Run Id", "Node Code") { Clustered = true; }
    key(Ordered; "Run Id", "Sequence No.", "Node Code") { }
  }
}
