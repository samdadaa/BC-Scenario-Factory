namespace BCScenarioFactory.DataGeneration;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 90254 "BCSF Generated Records"
{
  PageType = List;
  SourceTable = "BCSF Generated Record";
  Caption = 'Generated Result Provenance';
  ApplicationArea = All;
  UsageCategory = Lists;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Results)
      {
        field(MappingSource; MappingSource)
        {
          ApplicationArea = All;
          Caption = 'Source';
          ToolTip = 'Specifies whether the attribute belongs to an item or item category.';
          Visible = AttributeMappingView;
        }
        field(MappingNo; MappingNo)
        {
          ApplicationArea = All;
          Caption = 'Item or Category No.';
          ToolTip = 'Specifies the item or category that owns this attribute value.';
          Visible = AttributeMappingView;
        }
        field(AttributeName; AttributeName)
        {
          ApplicationArea = All;
          Caption = 'Attribute';
          ToolTip = 'Specifies the attribute name.';
          Visible = AttributeMappingView;
        }
        field(AttributeValue; AttributeValue)
        {
          ApplicationArea = All;
          Caption = 'Attribute Value';
          ToolTip = 'Specifies the assigned attribute value.';
          Visible = AttributeMappingView;
        }
        field("Run Id"; Rec."Run Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Node Code"; Rec."Node Code") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Logical Key"; Rec."Logical Key") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Artifact Code"; Rec."Artifact Code") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Entry Id"; Rec."Entry Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Parent Entry Id"; Rec."Parent Entry Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Batch Id"; Rec."Batch Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Generator Code"; Rec."Generator Code") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Generator Version"; Rec."Generator Version") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Table Id"; Rec."Table Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Record SystemId"; Rec."Record SystemId") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Record Id"; Rec."Record Id") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Posting Skipped"; Rec."Posting Skipped") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Skip Reason Code"; Rec."Skip Reason Code") { ApplicationArea = All; Visible = not AttributeMappingView; }
        field("Created At"; Rec."Created At") { ApplicationArea = All; Visible = not AttributeMappingView; }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(OpenPartner)
      {
        ApplicationArea = All;
        Visible = not AttributeMappingView;
        Caption = 'Open Generated Record';
        ToolTip = 'Opens the exact partner, ship-to address or order address by its recorded stable identity.';
        Image = View;
        Enabled = CanOpenRecord;
        trigger OnAction()
        var
          Customer: Record Customer;
          Vendor: Record Vendor;
          ShipTo: Record "Ship-to Address";
          Item: Record Item;
          OrderAddress: Record "Order Address";
        begin
          case Rec."Table Id" of
            Database::Item:
              begin
                Item.GetBySystemId(Rec."Record SystemId");
                Page.Run(Page::"Item Card", Item);
              end;
            Database::Customer:
              begin
                Customer.GetBySystemId(Rec."Record SystemId");
                Page.Run(Page::"Customer Card", Customer);
              end;
            Database::Vendor:
              begin
                Vendor.GetBySystemId(Rec."Record SystemId");
                Page.Run(Page::"Vendor Card", Vendor);
              end;
            Database::"Ship-to Address":
              begin
                ShipTo.GetBySystemId(Rec."Record SystemId");
                Page.Run(Page::"Ship-to Address", ShipTo);
              end;
            Database::"Order Address":
              begin
                OrderAddress.GetBySystemId(Rec."Record SystemId");
                Page.Run(Page::"Order Address", OrderAddress);
              end;
            else Message(MissingLbl);
          end;
        end;
      }
      action(CheckIdentity)
      {
        ApplicationArea = All;
        Visible = not AttributeMappingView;
        Caption = 'Check Result Identity';
        ToolTip = 'Checks whether the recorded SystemId still exists. Does not accept a reused primary key or change any record.';
        Image = Check;
        trigger OnAction()
        var
          Registry: Codeunit "BCSF Record Registry";
        begin
          if Registry.ExistsByIdentity(Rec) then
            Message(FoundLbl)
          else
            Message(MissingLbl);
        end;
      }
    }
  }
  procedure ShowAttributeMappings()
  begin
    AttributeMappingView := true;
  end;

  trigger OnOpenPage()
  begin
    if AttributeMappingView then
      CurrPage.Caption(AttributeAssignmentsLbl);
  end;

  trigger OnAfterGetRecord()
  var
    Mapping: Record "Item Attribute Value Mapping";
    Attribute: Record "Item Attribute";
    Value: Record "Item Attribute Value";
    Source: RecordRef;
  begin
    Clear(MappingSource);
    Clear(MappingNo);
    Clear(AttributeName);
    Clear(AttributeValue);
    if AttributeMappingView then begin
      Mapping.SecurityFiltering(SecurityFilter::Filtered);
      Attribute.SecurityFiltering(SecurityFilter::Filtered);
      Value.SecurityFiltering(SecurityFilter::Filtered);
      if Mapping.GetBySystemId(Rec."Record SystemId") then begin
        Source.Open(Mapping."Table ID");
        MappingSource := Source.Caption();
        Source.Close();
        MappingNo := Mapping."No.";
        if Attribute.Get(Mapping."Item Attribute ID") then
          AttributeName := Attribute.Name;
        if Value.Get(Mapping."Item Attribute ID", Mapping."Item Attribute Value ID") then
          AttributeValue := Value.Value;
      end;
    end;
    CanOpenRecord := Rec."Table Id" in [Database::Customer, Database::Vendor, Database::Item, Database::"Ship-to Address", Database::"Order Address"];
  end;

  var
    AttributeMappingView: Boolean;
    MappingSource: Text;
    MappingNo: Code[20];
    AttributeName: Text[250];
    AttributeValue: Text[250];
    AttributeAssignmentsLbl: Label 'Item Attribute Assignments';
    CanOpenRecord: Boolean;
    FoundLbl: Label 'The recorded stable result identity still exists. This does not validate the full business process.';
    MissingLbl: Label 'The recorded result is missing or not visible. Review it before retrying any creation or posting.';
}
