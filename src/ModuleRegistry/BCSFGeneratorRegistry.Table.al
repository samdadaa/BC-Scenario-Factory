namespace BCScenarioFactory.ModuleRegistry;

using BCScenarioFactory.Core;

table 90175 "BCSF Generator Registry"
{
  Access = Internal;
  Caption = 'Generator Catalog';
  DataClassification = SystemMetadata;
  TableType = Temporary;

  fields
  {
    field(1; "Generator Code"; Code[30])
    {
      Caption = 'Generator Code';
      ToolTip = 'Specifies the stable generator identity.';
    }
    field(2; "Entity Code"; Code[30])
    {
      Caption = 'Entity Code';
      ToolTip = 'Specifies the supported entity identity.';
    }
    field(3; "Module Code"; Code[30])
    {
      Caption = 'Module Code';
      ToolTip = 'Specifies the required business module.';
    }
    field(4; "Name"; Text[100])
    {
      Caption = 'Generator Name';
      ToolTip = 'Specifies the localized generator description.';
    }
    field(5; "Version"; Code[20])
    {
      Caption = 'Generator Version';
      ToolTip = 'Specifies the implementation version pinned in a saved plan.';
    }
    field(6; "Contract Version"; Integer)
    {
      Caption = 'Contract Version';
      ToolTip = 'Specifies the supported generator contract version.';
    }
    field(7; "Implementation"; Enum "BCSF Generator Type")
    {
      Caption = 'Implementation';
      ToolTip = 'Specifies the compiled interface binding.';
    }
    field(8; "Minimum Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Minimum Process Mode';
      ToolTip = 'Specifies the lowest supported process mode.';
    }
    field(9; "Maximum Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Maximum Process Mode';
      ToolTip = 'Specifies the highest supported process mode.';
    }
    field(10; "Maximum Batch Size"; Integer)
    {
      Caption = 'Maximum Batch Size';
      ToolTip = 'Specifies the generator batch limit in addition to the factory limit.';
    }
    field(11; "Contract Probe"; Boolean)
    {
      Caption = 'Contract Probe';
      ToolTip = 'Specifies a read-only probe that cannot satisfy a real generation target.';
    }
  }
  keys
  {
    key(PK; "Generator Code", "Entity Code") { Clustered = true; }
  }
}
