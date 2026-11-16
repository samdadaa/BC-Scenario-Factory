namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.Core;

table 90354 "BCSF Step Metric"
{
  Access = Internal;
  Caption = 'Step Metric';
  DataClassification = SystemMetadata;
  TableType = Temporary;
  fields
  {
    field(1; "Run Id"; Guid)
    {
      Caption = 'Run Id';
      ToolTip = 'Specifies the owning captured run.';
    }
    field(2; "Node Code"; Code[30])
    {
      Caption = 'Node Code';
      ToolTip = 'Specifies the immutable planned step or frozen entity target.';
    }
    field(3; "Module Code"; Code[30])
    {
      Caption = 'Module Code';
      ToolTip = 'Specifies the frozen business module.';
    }
    field(4; "Entity Code"; Code[30])
    {
      Caption = 'Entity Code';
      ToolTip = 'Specifies the frozen entity or prerequisite.';
    }
    field(5; "Planned Units"; Integer)
    {
      Caption = 'Planned Units';
      ToolTip = 'Specifies the frozen logical target. External prerequisites are not generated entity targets.';
    }
    field(6; "Confirmed Units"; BigInteger)
    {
      Caption = 'Confirmed Units';
      ToolTip = 'Specifies logical units from completed batches only.';
    }
    field(7; "Remaining Units"; BigInteger)
    {
      Caption = 'Remaining Units';
      ToolTip = 'Specifies target units without confirmed completion; cancelled and uncertain work remains outstanding.';
    }
    field(8; "Created Artifacts"; BigInteger)
    {
      Caption = 'Created Artifacts';
      ToolTip = 'Specifies provenance artifact counts from completed batches; this is not an entity or posted count.';
    }
    field(9; "Total Batches"; Integer)
    {
      Caption = 'Total Batches';
      ToolTip = 'Specifies persisted batches for this step.';
    }
    field(10; "Completed Batches"; Integer)
    {
      Caption = 'Completed Batches';
      ToolTip = 'Specifies confirmed complete batches for this step.';
    }
    field(11; "Review Batches"; Integer)
    {
      Caption = 'Review Batches';
      ToolTip = 'Specifies failed or uncertain batches requiring investigation.';
    }
    field(12; "Progress Percent"; Decimal)
    {
      Caption = 'Progress Percent';
      ToolTip = 'Specifies confirmed logical units divided by the entity target; no global weighting is assumed.';
    }
    field(13; "State"; Text[100])
    {
      Caption = 'State';
      ToolTip = 'Specifies the observed step state, not a global quality approval.';
    }
    field(14; "Issue"; Enum "BCSF Plan Issue")
    {
      Caption = 'Issue';
      ToolTip = 'Specifies the immutable plan blocker.';
    }
    field(15; "Reference Code"; Code[30])
    {
      Caption = 'Reference Code';
      ToolTip = 'Specifies the related blocking prerequisite.';
    }
    field(16; "External Check"; Boolean)
    {
      Caption = 'External Check';
      ToolTip = 'Specifies an external prerequisite with no generated entity progress.';
    }
    field(17; "Plan Saved"; Boolean)
    {
      Caption = 'Plan Saved';
      ToolTip = 'Specifies whether this row comes from an immutable saved plan.';
    }
    field(18; "Running Batches"; Integer)
    {
      Caption = 'Running Batches';
      ToolTip = 'Specifies durably claimed batches, whose work is not yet confirmed.';
    }
    field(19; "Cancelled Batches"; Integer)
    {
      Caption = 'Cancelled Batches';
      ToolTip = 'Specifies cancelled batches whose targets remain outstanding.';
    }
  }
  keys
  {
    key(PK; "Run Id", "Node Code") { Clustered = true; }
  }
}
