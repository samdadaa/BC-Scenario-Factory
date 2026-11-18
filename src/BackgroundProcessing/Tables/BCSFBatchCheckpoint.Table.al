namespace BCScenarioFactory.BackgroundProcessing;

table 90314 "BCSF Batch Checkpoint"
{
  Access = Internal;
  DataPerCompany = true;
  DataClassification = SystemMetadata;
  Caption = 'Confirmed Batch Checkpoint';
  fields
  {
    field(1; "Batch Id"; Guid) { Caption = 'Batch Id'; ToolTip = 'Specifies the stable batch identity.'; }
    field(2; "Run Id"; Guid) { Caption = 'Run Id'; ToolTip = 'Specifies the owning captured run.'; }
    field(3; "Schema Version"; Integer) { Caption = 'Schema Version'; ToolTip = 'Specifies the immutable result envelope version.'; }
    field(4; "Result Envelope"; Blob) { Caption = 'Result Envelope'; ToolTip = 'Contains only validated technical result identifiers, counters and language, without business payload.'; }
    field(5; "Confirmed At"; DateTime) { Caption = 'Confirmed At'; ToolTip = 'Specifies when output and provenance were validated in the batch transaction.'; }
  }
  keys
  {
    key(PK; "Batch Id") { Clustered = true; }
    key(Run; "Run Id") { }
  }
  procedure WriteResult(Result: JsonObject)
  var
    Output: OutStream;
    Serialized: Text;
  begin
    "Result Envelope".CreateOutStream(Output, TextEncoding::UTF8);
    Result.WriteTo(Serialized);
    Output.WriteText(Serialized);
    Clear(Output);
  end;
  /// <summary>Loads the persisted envelope after Get. HasValue does not replace loading a BLOB.</summary>
  procedure ReadStoredResult(): JsonObject
  begin
    CalcFields("Result Envelope");
    exit(ReadResult());
  end;

  /// <summary>Reads the current in-memory envelope, including the value checked before Insert.</summary>
  procedure ReadResult(): JsonObject
  var
    Input: InStream;
    Result: JsonObject;
  begin
    if not "Result Envelope".HasValue() then
      Error(InvalidEnvelopeErr, "Batch Id");
    "Result Envelope".CreateInStream(Input, TextEncoding::UTF8);
    if not Result.ReadFrom(Input) then
      Error(InvalidEnvelopeErr, "Batch Id");
    exit(Result);
  end;
  var
    InvalidEnvelopeErr: Label 'The checkpoint result for batch %1 is empty or invalid JSON. Review the original queue error and saved results; do not repeat claimed work automatically.', Comment = '%1 = batch identity';
}
