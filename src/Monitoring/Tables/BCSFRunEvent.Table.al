namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;

table 90350 "BCSF Run Event"
{
  Access = Internal;
  DataPerCompany = true;
  Caption = 'Run Event';
  DataClassification = SystemMetadata;
  fields
  {
    field(1; "Entry Id"; Guid)
    {
      Caption = 'Entry Id';
      ToolTip = 'Specifies the immutable event identity.';
    }
    field(2; "Run Id"; Guid)
    {
      Caption = 'Run Id';
      ToolTip = 'Specifies the owning captured run.';
    }
    field(3; "Batch Id"; Guid)
    {
      Caption = 'Batch Id';
      ToolTip = 'Specifies the batch, or is empty for an execution event.';
    }
    field(4; "Node Code"; Code[30])
    {
      Caption = 'Node Code';
      ToolTip = 'Specifies the related step.';
    }
    field(5; "Occurred At"; DateTime)
    {
      Caption = 'Occurred At';
      ToolTip = 'Specifies when the persisted transition was recorded.';
    }
    field(6; "Run Status"; Enum "BCSF Run Status")
    {
      Caption = 'Run Status';
      ToolTip = 'Specifies the execution state for an execution event.';
    }
    field(7; "Batch Status"; Enum "BCSF Batch Status")
    {
      Caption = 'Batch Status';
      ToolTip = 'Specifies the state for a batch event.';
    }
    field(8; "Job Queue Entry Id"; Guid)
    {
      Caption = 'Job Queue Entry Id';
      ToolTip = 'Specifies the job identity at the transition.';
    }
    field(9; "Processed Units"; Integer)
    {
      Caption = 'Processed Units';
      ToolTip = 'Specifies confirmed logical units at the transition.';
    }
    field(10; "Created Records"; Integer)
    {
      Caption = 'Created Records';
      ToolTip = 'Specifies confirmed provenance artifacts at the transition.';
    }
  }
  keys
  {
    key(PK; "Entry Id") { Clustered = true; }
    key(History; "Run Id", "Occurred At", "Entry Id") { }
  }
}
