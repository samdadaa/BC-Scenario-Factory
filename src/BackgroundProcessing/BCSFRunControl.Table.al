namespace BCScenarioFactory.BackgroundProcessing;

table 90313 "BCSF Run Control"
{
  Access = Internal;
  DataPerCompany = true;
  DataClassification = SystemMetadata;
  Caption = 'Run Control Requests';
  fields
  {
    field(1; "Run Id"; Guid) { Caption = 'Run Id'; ToolTip = 'Specifies the owning captured run.'; }
    field(2; "Pause Requested"; Boolean) { Caption = 'Pause Requested'; ToolTip = 'Specifies a durable pause request to stop before the next unclaimed batch.'; }
    field(3; "Cancel Requested"; Boolean) { Caption = 'Cancel Requested'; ToolTip = 'Specifies an irreversible request to cancel unstarted work without undoing results.'; }
    field(4; "Requested At"; DateTime) { Caption = 'Requested At'; ToolTip = 'Specifies when the latest control request was saved.'; }
  }
  keys
  {
    key(PK; "Run Id") { Clustered = true; }
  }
}
