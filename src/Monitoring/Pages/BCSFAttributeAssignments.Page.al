namespace BCScenarioFactory.Monitoring;

using Microsoft.Inventory.Item.Attribute;

page 90370 "BCSF Attribute Assignments"
{
  PageType = List;
  SourceTable = "Item Attribute Value Mapping";
  Caption = 'Item Attribute Assignments';
  ApplicationArea = All;
  UsageCategory = None;
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Assignments)
      {
        field(SourceCaption; SourceCaption)
        {
          ApplicationArea = All;
          Caption = 'Source';
          ToolTip = 'Specifies the source table of this attribute assignment.';
        }
        field("No."; Rec."No.") { ApplicationArea = All; ToolTip = 'Specifies the item or category that owns this attribute assignment.'; }
        field(AttributeName; AttributeName)
        {
          ApplicationArea = All;
          Caption = 'Attribute';
          ToolTip = 'Specifies the assigned attribute name.';
        }
        field(AttributeValue; AttributeValue)
        {
          ApplicationArea = All;
          Caption = 'Attribute Value';
          ToolTip = 'Specifies the assigned attribute value.';
        }
      }
    }
  }
  trigger OnAfterGetRecord()
  var
    Attribute: Record "Item Attribute";
    Value: Record "Item Attribute Value";
    Source: RecordRef;
  begin
    Clear(SourceCaption);
    Clear(AttributeName);
    Clear(AttributeValue);
    Source.Open(Rec."Table ID");
    SourceCaption := Source.Caption();
    Source.Close();
    Attribute.SecurityFiltering(SecurityFilter::Filtered);
    Value.SecurityFiltering(SecurityFilter::Filtered);
    if Attribute.ReadPermission() then
      if Attribute.Get(Rec."Item Attribute ID") then
        AttributeName := Attribute.Name;
    if Value.ReadPermission() then
      if Value.Get(Rec."Item Attribute ID", Rec."Item Attribute Value ID") then
        AttributeValue := Value.Value;
  end;
  var
    SourceCaption: Text;
    AttributeName: Text[250];
    AttributeValue: Text[250];
}
