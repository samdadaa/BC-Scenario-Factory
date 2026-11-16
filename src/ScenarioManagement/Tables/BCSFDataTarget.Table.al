namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

table 90127 "BCSF Data Target"
{
  Access = Internal;
  Caption = 'Entity Target';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Scenario Id"; Guid)
    {
      Caption = 'Scenario ID';
      ToolTip = 'Specifies the owning scenario.';
      TableRelation = "BCSF Scenario"."Scenario Id";
    }
    field(2; "Entity"; Enum "BCSF Entity Type")
    {
      Caption = 'Entity';
      ToolTip = 'Specifies the entity whose quantity and distribution are configured.';
      trigger OnValidate()
      var
        ScenarioPolicy: Codeunit "BCSF Scenario Policy";
      begin
        ScenarioPolicy.ApplyEntityDefaults(Rec);
      end;
    }
    field(3; "Module"; Enum "BCSF Module Type")
    {
      Caption = 'Module';
      ToolTip = 'Specifies the business module derived from the entity.';
      Editable = false;
    }
    field(4; "Quantity"; Integer)
    {
      Caption = 'Target Quantity';
      ToolTip = 'Specifies the separate target for this entity. Zero excludes it from generation.';
    }
    field(5; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Process Mode';
      ToolTip = 'Specifies this entity scope within the scenario maximum.';
    }
    field(6; "Unposted Percent"; Decimal)
    {
      Caption = 'Unposted %';
      ToolTip = 'Specifies the unposted document share. The posted share is adjusted so all shares total 100.';
      InitValue = 100;
      DecimalPlaces = 0 : 5;
      trigger OnValidate()
      var
        Policy: Codeunit "BCSF Scenario Policy";
      begin
        Policy.BalanceTargetShare(Rec, FieldNo("Unposted Percent"));
      end;
    }
    field(7; "Posted Percent"; Decimal)
    {
      Caption = 'Posted %';
      ToolTip = 'Specifies the fully posted document share. The remaining unposted share is calculated automatically.';
      DecimalPlaces = 0 : 5;
      trigger OnValidate()
      var
        Policy: Codeunit "BCSF Scenario Policy";
      begin
        Policy.BalanceTargetShare(Rec, FieldNo("Posted Percent"));
      end;
    }
    field(8; "Partial Percent"; Decimal)
    {
      Caption = 'Partially Processed %';
      ToolTip = 'Specifies the partial order share. The remaining unposted share is calculated automatically; only sales and purchase orders support partial processing.';
      DecimalPlaces = 0 : 5;
      trigger OnValidate()
      var
        Policy: Codeunit "BCSF Scenario Policy";
      begin
        Policy.BalanceTargetShare(Rec, FieldNo("Partial Percent"));
      end;
    }
  }

  keys
  {
    key(PK; "Scenario Id", Entity) { Clustered = true; }
    key(ModuleTargets; "Scenario Id", Module, Quantity) { }
  }
}
