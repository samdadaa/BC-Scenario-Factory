namespace BCScenarioFactory.BackgroundProcessing;

table 90300 "BCSF Batch"
{
  Access = Internal;
  DataPerCompany = true;
  DataClassification = CustomerContent;
  Caption = 'Batch';
  fields
  {
    field(1; "Batch Id"; Guid)
    {
      Caption = 'Batch Id';
      ToolTip = 'Specifies the stable batch identity.';
    }
    field(2; "Run Id"; Guid)
    {
      Caption = 'Run Id';
      ToolTip = 'Specifies the owning captured run.';
    }
    field(3; "Node Code"; Code[30])
    {
      Caption = 'Node Code';
      ToolTip = 'Specifies the immutable planned step.';
    }
    field(4; "Sequence No."; Integer)
    {
      Caption = 'Sequence No.';
      ToolTip = 'Specifies the serial order across all batches of the run.';
    }
    field(5; "Batch Key"; Text[100])
    {
      Caption = 'Batch Key';
      ToolTip = 'Specifies the exact immutable key returned by generator planning.';
    }
    field(6; "First Key"; Integer)
    {
      Caption = 'First Key';
      ToolTip = 'Specifies the inclusive first logical unit.';
    }
    field(7; "Last Key"; Integer)
    {
      Caption = 'Last Key';
      ToolTip = 'Specifies the inclusive last logical unit.';
    }
    field(8; "Status"; Enum "BCSF Batch Status")
    {
      Caption = 'Status';
      ToolTip = 'Specifies the persisted batch state; an interrupted running batch requires review.';
    }
    field(9; "Job Queue Entry Id"; Guid)
    {
      Caption = 'Job Queue Entry Id';
      ToolTip = 'Specifies the standard job queue entry assigned to this work.';
    }
    field(10; "Started At"; DateTime)
    {
      Caption = 'Started At';
      ToolTip = 'Specifies when processing was claimed.';
    }
    field(11; "Finished At"; DateTime)
    {
      Caption = 'Finished At';
      ToolTip = 'Specifies when processing was confirmed complete.';
    }
    field(12; "Processed Units"; Integer)
    {
      Caption = 'Processed Units';
      ToolTip = 'Specifies the number of confirmed logical units.';
    }
    field(13; "Created Records"; Integer)
    {
      Caption = 'Created Records';
      ToolTip = 'Specifies the confirmed number of provenance artifacts.';
    }
    field(14; "Schedule Attempts"; Integer)
    {
      Caption = 'Schedule Attempts';
      ToolTip = 'Specifies the number of job schedules, limited to three including retries.';
      DataClassification = SystemMetadata;
    }
    field(15; "Previous Job Id"; Guid)
    {
      Caption = 'Previous Job Id';
      ToolTip = 'Specifies the last retired job identity; standard job logs retain earlier attempts.';
      DataClassification = SystemMetadata;
    }
    field(16; "Worker Session Id"; Integer)
    {
      Caption = 'Worker Session Id';
      ToolTip = 'Specifies the technical session that durably claimed this batch.';
      DataClassification = SystemMetadata;
    }
    field(17; "Worker Server Id"; Integer)
    {
      Caption = 'Worker Server Id';
      ToolTip = 'Specifies the service instance of the claiming worker.';
      DataClassification = SystemMetadata;
    }
    field(18; "Worker Session Guid"; Guid)
    {
      Caption = 'Worker Session Guid';
      ToolTip = 'Specifies the unique worker session identity and prevents session number reuse from authorizing recovery.';
      DataClassification = SystemMetadata;
    }
  }
  keys
  {
    key(PK; "Batch Id") { Clustered = true; }
    key(RunOrder; "Run Id", "Sequence No.") { Unique = true; }
    key(Job; "Job Queue Entry Id") { }
    key(GeneratorBatch; "Run Id", "Node Code", "Batch Key") { Unique = true; }
    key(LogicalRange; "Run Id", "Node Code", "First Key") { Unique = true; }
  }
}
