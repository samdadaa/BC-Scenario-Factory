namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using BCScenarioFactory.Monitoring;

page 90131 "BCSF Scenario Card"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Scenario';
  PageType = Card;
  SourceTable = "BCSF Scenario";
  InsertAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      group(General)
      {
        Caption = 'General';
        field(Description; DisplayName)
        {
          Caption = 'Description';
          ToolTip = 'Shows the localized default name. Editing saves a custom name for this template.';
          trigger OnValidate()
          begin
            Rec.Validate(Description, CopyStr(DisplayName, 1, MaxStrLen(Rec.Description)));
          end;
        }
        field(Revision; Rec.Revision) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Profile Version"; Rec."Profile Version") { }
      }
      group(Scope)
      {
        Caption = 'Scenario Period and Scope';
        field("Usage Mode"; Rec."Usage Mode") { }
        field("Process Mode"; MaximumProcessScope)
        {
          Caption = 'Maximum Process Scope';
          ToolTip = 'Changes the document target modes and initializes matching document shares when their mode changes. Master data stays unposted; a higher maximum alone does not request follow-up processes.';
          trigger OnValidate()
          var
            Manager: Codeunit "BCSF Scenario Manager";
            RequestedScope: Enum "BCSF Process Mode";
          begin
            RequestedScope := MaximumProcessScope;
            CurrPage.SaveRecord();
            Manager.ChangeProcessScope(Rec."Scenario Id", RequestedScope);
            Rec.Get(Rec."Scenario Id");
            CurrPage.Targets.Page.RefreshTargets();
            CurrPage.Update(false);
          end;
        }
        field(Seed; Rec.Seed) { }
        field("Starting Date"; Rec."Starting Date") { }
        field("Ending Date"; Rec."Ending Date") { }
        field("Data Language"; Rec."Data Language")
        {
          trigger OnValidate()
          begin
            CurrPage.Update(true);
          end;
        }
        field("Batch Size"; Rec."Batch Size") { }
      }
      group(SalesProcess)
      {
        Caption = 'Sales Process';
        Visible = HasSalesTarget;
        field(SalesLocation; Rec."Item Location Code")
        {
          Caption = 'Sales Location';
          ToolTip = 'Specifies the shared simple location for items and sales. Leave blank to use the assortment location.';
        }
        field("Sales Posting Approved"; Rec."Sales Posting Approved") { }
      }
      group(PartnerGeneration)
      {
        Caption = 'Synthetic Partners';
        ShowCaption = true;
        field("Partner Country Code"; Rec."Partner Country Code") { }
        field("Partner Currency Code"; Rec."Partner Currency Code") { }
        field("Partner Payment Method"; Rec."Partner Payment Method") { }
        field("Partner Dimension 1"; Rec."Partner Dimension 1") { }
        field("Partner Dimension 2"; Rec."Partner Dimension 2") { }
        field(PaymentReadiness; BankNoticeLbl)
        {
          Caption = 'Payment Readiness';
          ToolTip = 'Explains why payment processes remain blocked without approved synthetic bank details.';
          Editable = false;
          MultiLine = true;
        }

        field("Customer Posting Group"; Rec."Customer Posting Group") { }
        field("Vendor Posting Group"; Rec."Vendor Posting Group") { }
        field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group") { }
        field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group") { }
        field("Cash Terms Code"; Rec."Cash Terms Code") { }
        field("Small Terms Code"; Rec."Small Terms Code") { }
        field("Medium Terms Code"; Rec."Medium Terms Code") { }
        field("Large Terms Code"; Rec."Large Terms Code") { }
        field("B2C Percent"; Rec."B2C Percent") { }
        field("Small Credit Limit"; Rec."Small Credit Limit") { }
        field("Medium Credit Limit"; Rec."Medium Credit Limit") { }
        field("Large Credit Limit"; Rec."Large Credit Limit") { }
        field("B2C Credit Limit"; Rec."B2C Credit Limit") { }
      }
      group(LanguagePreview)
      {
        Caption = 'Data Language Preview';
        field(CustomerPreview; CustomerPreview)
        {
          Caption = 'Customer Name Preview';
          ToolTip = 'Shows a synthetic example in the selected data language.';
          Editable = false;
        }
        field(VendorPreview; VendorPreview)
        {
          Caption = 'Vendor Name Preview';
          ToolTip = 'Shows a synthetic example in the selected data language.';
          Editable = false;
        }
        field(ItemPreview; ItemPreview)
        {
          Caption = 'Item Name Preview';
          ToolTip = 'Shows a synthetic example in the selected data language.';
          Editable = false;
        }
      }
      part(Modules; "BCSF Scenario Modules")
      {
        Caption = 'Module Selection';
        SubPageLink = "Scenario Id" = field("Scenario Id");
        UpdatePropagation = Both;
      }
      part(Targets; "BCSF Data Targets")
      {
        Caption = 'Entity Targets';
        SubPageLink = "Scenario Id" = field("Scenario Id");
        UpdatePropagation = Both;
      }
      group(PlanningMinimums)
      {
        Caption = 'Planning Minimums';
        field(MinimumCustomers; MinimumCustomers)
        {
          Caption = 'Minimum Customer References';
          ToolTip = 'Shows the minimum reusable customer references required by the selected sales documents. This is not a customer generation target.';
          Editable = false;
        }
        field(MinimumVendors; MinimumVendors)
        {
          Caption = 'Minimum Vendor References';
          ToolTip = 'Shows the minimum reusable vendor references required by the selected purchase documents. This is not a vendor generation target.';
          Editable = false;
        }
      }
      group(ItemSettings)
      {
        Caption = 'Item Assortment';
        Visible = HasItemTarget;
        field("Item Base Unit"; Rec."Item Base Unit") { }
        field("Item Pack Unit"; Rec."Item Pack Unit") { }
        field("Item Inventory Group"; Rec."Item Inventory Group") { }
        field("Item Product Group"; Rec."Item Product Group") { }
        field("Item VAT Product Group"; Rec."Item VAT Product Group") { }
        field("Item Location Code"; Rec."Item Location Code") { }
        field("Item Vendor No."; Rec."Item Vendor No.") { }
        field("Item Second Vendor No."; Rec."Item Second Vendor No.") { }
      }
    }
  }
  actions
  {
    area(Promoted)
    {
      actionref(RunTemplatePromoted; CaptureRun) { }
      actionref(RemoveTemplatePromoted; RemoveTemplate) { }
    }
    area(Processing)
    {
      action(RemoveTemplate)
      {
        ApplicationArea = All;
        Caption = 'Delete Template';
        ToolTip = 'Deletes an unused template after confirmation. A template with captured runs is archived and its history retained.';
        Image = Delete;
        trigger OnAction()
        var
          Selection: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SaveRecord();
          Selection.SetRange("Scenario Id", Rec."Scenario Id");
          if Manager.RemoveSelection(Selection) then
            CurrPage.Close();
        end;
      }
      action(CopyScenario)
      {
        ApplicationArea = All;
        Caption = 'Copy Scenario';
        ToolTip = 'Creates an independent copy of this template, including modules and targets.';
        Image = Copy;
        trigger OnAction()
        var
          Scenario: Record "BCSF Scenario";
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SaveRecord();
          Scenario.Get(Manager.CopyScenario(Rec."Scenario Id"));
          Page.Run(Page::"BCSF Scenario Card", Scenario);
        end;
      }
      action(CaptureRun)
      {
        ApplicationArea = All;
        Enabled = CanRunTemplate;
        Caption = 'Run Template';
        ToolTip = 'Starts the selected template in the background using the initialized company setup.';
        Image = Archive;
        trigger OnAction()
        var
          Header: Record "BCSF Run Header";
          QuickRun: Codeunit "BCSF Quick Scenario Run";
        begin
          CurrPage.SaveRecord();
          Header.Get(QuickRun.RunScenario(Rec));
          Page.Run(Page::"BCSF Run Card", Header);
        end;
      }
      action(CapturedRuns)
      {
        ApplicationArea = All;
        Caption = 'Captured Runs';
        ToolTip = 'Opens the captured configuration history.';
        Image = History;
        RunObject = page "BCSF Factory Dashboard";
        RunPageLink = "Scenario Id" = field("Scenario Id");
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    ItemTarget: Record "BCSF Data Target";
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    ItemTarget.SetRange("Scenario Id", Rec."Scenario Id");
    ItemTarget.SetRange(Entity, ItemTarget.Entity::Item);
    ItemTarget.SetFilter(Quantity, '>0');
    HasItemTarget := not ItemTarget.IsEmpty();
    ItemTarget.SetFilter(Entity, '%1|%2|%3', ItemTarget.Entity::SalesQuote, ItemTarget.Entity::SalesOrder, ItemTarget.Entity::SalesInvoice);
    HasSalesTarget := not ItemTarget.IsEmpty();
    MaximumProcessScope := Rec."Process Mode";
    CanRunTemplate := not IsNullGuid(Rec."Scenario Id") and not Rec.Archived;
    Manager.GetMinimumReferences(Rec."Scenario Id", MinimumCustomers, MinimumVendors);
    Manager.GetScenarioLanguagePreview(Rec, CustomerPreview, VendorPreview, ItemPreview);
  end;

  var
    MaximumProcessScope: Enum "BCSF Process Mode";
    CanRunTemplate: Boolean;
    HasItemTarget: Boolean;
    HasSalesTarget: Boolean;
    CustomerPreview: Text[100];
    VendorPreview: Text[100];
    ItemPreview: Text[100];
    MinimumCustomers: Integer;
    MinimumVendors: Integer;
  trigger OnAfterGetRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    DisplayName := Manager.GetDisplayName(Rec);
  end;
  var
    DisplayName: Text;
    BankNoticeLbl: Label 'No approved synthetic bank dataset is configured. Payment-ready bank accounts and payment exports are not generated. Configure and verify bank data separately before any payment process.';
}
