namespace BCScenarioFactory.DataGeneration;

table 90251 "BCSF Generated Record"
{
  Access = Internal;
  DataPerCompany = true;
  DataClassification = CustomerContent;
  Caption = 'Generated Record';
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
      ToolTip = 'Specifies the immutable planned step.';
    }
    field(3; "Logical Key"; Integer)
    {
      Caption = 'Logical Key';
      ToolTip = 'Specifies the positive unit number within the planned entity.';
    }
    field(4; "Artifact Code"; Code[30])
    {
      Caption = 'Artifact Code';
      ToolTip = 'Specifies the stable result role within this unit.';
    }
    field(5; "Entry Id"; Guid)
    {
      Caption = 'Entry Id';
      ToolTip = 'Specifies the stable provenance identity used by child results.';
    }
    field(6; "Batch Id"; Guid)
    {
      Caption = 'Batch Id';
      ToolTip = 'Specifies the stable batch identity.';
    }
    field(7; "Generator Code"; Code[30])
    {
      Caption = 'Generator Code';
      ToolTip = 'Specifies the captured generator binding.';
    }
    field(8; "Generator Version"; Code[20])
    {
      Caption = 'Generator Version';
      ToolTip = 'Specifies the captured generator version.';
    }
    field(9; "Table Id"; Integer)
    {
      Caption = 'Table Id';
      ToolTip = 'Specifies the standard result table.';
    }
    field(10; "Record SystemId"; Guid)
    {
      Caption = 'Record SystemId';
      ToolTip = 'Specifies the stable SystemId of the existing result.';
    }
    field(11; "Record Id"; RecordId)
    {
      Caption = 'Record Id';
      ToolTip = 'Specifies the captured record key; SystemId remains the stable identity after a rename.';
    }
    field(12; "Parent Entry Id"; Guid)
    {
      Caption = 'Parent Entry Id';
      ToolTip = 'Specifies an optional earlier result from the same run.';
    }
    field(13; "Created At"; DateTime)
    {
      Caption = 'Created At';
      ToolTip = 'Specifies when this entry was created.';
    }
    field(14; "Posting Skipped"; Boolean)
    {
      Caption = 'Posting Skipped';
      ToolTip = 'Specifies that requested posting was skipped before calling standard posting; the document remains unposted.';
    }
    field(15; "Skip Reason Code"; Code[30])
    {
      Caption = 'Skip Reason Code';
      ToolTip = 'Specifies the stable reason for skipped posting. STOCK means insufficient unreserved stock on the document date.';
    }
  }
  keys
  {
    key(PK; "Run Id", "Node Code", "Logical Key", "Artifact Code") { Clustered = true; }
    key(Identity; "Entry Id") { Unique = true; }
    key(ResultIdentity; "Table Id", "Record SystemId") { Unique = true; }
    key(Batch; "Batch Id", "Logical Key") { }
  }
}
