namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

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
        field(Description; Rec.Description) { }
        field(Revision; Rec.Revision) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Profile Version"; Rec."Profile Version") { }
      }
      group(Scope)
      {
        Caption = 'Scenario Period and Scope';
        field("Usage Mode"; Rec."Usage Mode") { }
        field("Process Mode"; Rec."Process Mode") { }
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
    }
  }
  actions
  {
    area(Processing)
    {
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
        Caption = 'Capture Run Snapshot';
        ToolTip = 'Freezes the current settings and resolved data language as a new draft run. No data generation or queue start occurs.';
        Image = Archive;
        trigger OnAction()
        var
          Header: Record "BCSF Run Header";
          Writer: Codeunit "BCSF Snapshot Writer";
        begin
          CurrPage.SaveRecord();
          Header.Get(Writer.CreateSnapshot(Rec."Scenario Id"));
          Page.Run(Page::"BCSF Run Card", Header);
        end;
      }
      action(CapturedRuns)
      {
        ApplicationArea = All;
        Caption = 'Captured Runs';
        ToolTip = 'Opens the captured configuration history.';
        Image = History;
        RunObject = page "BCSF Run List";
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Languages: Codeunit "BCSF Language Mgt";
    Resolved: Enum "BCSF Data Language";
  begin
    Manager.GetMinimumReferences(Rec."Scenario Id", MinimumCustomers, MinimumVendors);
    Resolved := Languages.ResolveDataLanguage(Rec."Data Language");
    CustomerPreview := Languages.GetSyntheticName('CUSTOMER', 1, Resolved, Languages.GetCatalogVersion());
    VendorPreview := Languages.GetSyntheticName('VENDOR', 1, Resolved, Languages.GetCatalogVersion());
    ItemPreview := Languages.GetSyntheticName('ITEM', 1, Resolved, Languages.GetCatalogVersion());
  end;

  var
    CustomerPreview: Text[100];
    VendorPreview: Text[100];
    ItemPreview: Text[100];
    MinimumCustomers: Integer;
    MinimumVendors: Integer;
}
