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
        field("Finance Mode"; Rec."Finance Mode") { }
      }
      group(PartnerGeneration)
      {
        Caption = 'Synthetic Partners';
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
    }
  }
  actions
  {
    area(Processing)
    {
      action(ConfigureFinance)
      {
        ApplicationArea = All;
        Caption = 'Review Finance Setup';
        ToolTip = 'Opens the shared finance preview. Apply a reviewed package explicitly, then select it for this template.';
        Image = Setup;
        trigger OnAction()
        var
          Manager: Codeunit "BCSF Scenario Manager";
        begin
          CurrPage.SaveRecord();
          // Finish template editing before opening the separate reviewed setup workflow.
          Commit();
          Manager.ConfigureFinance(Rec."Scenario Id");
          Rec.Get(Rec."Scenario Id");
          CurrPage.Update(false);
        end;
      }

      action(GuidedPlanning)
      {
        ApplicationArea = All;
        Caption = 'Plan with Wizard';
        ToolTip = 'Opens five guided steps on this saved template. Edits persist; closing does not schedule execution.';
        Image = Planning;
        trigger OnAction()
        begin
          CurrPage.SaveRecord();
          Page.Run(Page::"BCSF Scenario Wizard", Rec);
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
        RunPageLink = "Scenario Id" = field("Scenario Id");
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
  begin
    Manager.GetMinimumReferences(Rec."Scenario Id", MinimumCustomers, MinimumVendors);
    Manager.GetScenarioLanguagePreview(Rec, CustomerPreview, VendorPreview, ItemPreview);
  end;

  var
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
