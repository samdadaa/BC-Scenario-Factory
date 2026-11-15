namespace BCScenarioFactory.BackgroundProcessing;

using BCScenarioFactory.Core;

table 90305 "BCSF Run Execution"
{
  Access = Internal;
  DataPerCompany = true;
  DataClassification = CustomerContent;
  Caption = 'Run Execution';
  fields
  {
    field(1; "Run Id"; Guid)
    {
      Caption = 'Run Id';
      ToolTip = 'Specifies the owning captured run.';
    }
    field(2; "Status"; Enum "BCSF Run Status")
    {
      Caption = 'Status';
      ToolTip = 'Specifies the current execution state, separate from the captured initial status.';
    }
    field(3; "Earliest Start"; DateTime)
    {
      Caption = 'Earliest Start';
      ToolTip = 'Specifies the requested earliest start; actual scheduler availability may delay it.';
    }
    field(4; "Job Queue Entry Id"; Guid)
    {
      Caption = 'Job Queue Entry Id';
      ToolTip = 'Specifies the standard job queue entry assigned to this work.';
    }
    field(5; "Created At"; DateTime)
    {
      Caption = 'Created At';
      ToolTip = 'Specifies when this entry was created.';
    }
    field(6; "Started At"; DateTime)
    {
      Caption = 'Started At';
      ToolTip = 'Specifies when processing was claimed.';
    }
    field(7; "Finished At"; DateTime)
    {
      Caption = 'Finished At';
      ToolTip = 'Specifies when processing was confirmed complete.';
    }
    field(8; "Total Batches"; Integer)
    {
      Caption = 'Total Batches';
      ToolTip = 'Specifies the exact persisted batch count.';
    }
    field(9; "Completed Batches"; Integer)
    {
      Caption = 'Completed Batches';
      ToolTip = 'Specifies the number of confirmed complete batches.';
    }
  }
  keys
  {
    key(PK; "Run Id") { Clustered = true; }
  }
}
