namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90134 "BCSF Run Snapshot"
{
  Access = Internal;
  Caption = 'Run Snapshot';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Run Id"; Guid)
    {
      Caption = 'Run ID';
      ToolTip = 'Specifies the owning run.';
    }
    field(2; "Schema Version"; Integer)
    {
      Caption = 'Snapshot Schema Version';
      ToolTip = 'Specifies the payload schema version.';
    }
    field(3; "Payload"; Blob)
    {
      Caption = 'Frozen Configuration';
      ToolTip = 'Contains the immutable configuration used to reconstruct this run.';
    }
  }

  keys
  {
    key(PK; "Run Id") { Clustered = true; }
  }

  procedure ReadPayload(var SnapshotJson: JsonObject)
  var
    Input: InStream;
  begin
    Clear(SnapshotJson);
    Payload.CreateInStream(Input, TextEncoding::UTF8);
    if not SnapshotJson.ReadFrom(Input) then
      Error(InvalidPayloadErr);
  end;

  var
    InvalidPayloadErr: Label 'The captured configuration cannot be read. Do not retry generation until it has been reviewed.';
}
