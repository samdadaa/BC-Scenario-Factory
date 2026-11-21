namespace BCScenarioFactory.Core;

using BCScenarioFactory.Finance;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.Monitoring;

page 90101 "BCSF Factory Setup Card"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Setup';
  PageType = Card;
  SourceTable = "BCSF Factory Setup";
  SourceTableTemporary = true;
  SourceTableView = where("Primary Key" = const('SETUP'));
  UsageCategory = Administration;
  InsertAllowed = false;
  DeleteAllowed = false;

  layout
  {
    area(Content)
    {
      group(ChartStep)
      {
        Caption = '1 - Chart of accounts';
        Visible = WizardStep = 1;
        field(ChartChoice; ChartChoice)
        {
          Caption = 'Chart of accounts';
          OptionCaption = 'SKR03,SKR04,Use existing valid BC setup';
          Editable = not Initialized;
          ToolTip = 'Choose the local test chart once. Existing company accounts and settings are preserved.';
        }
      }
      group(IndustryStep)
      {
        Caption = '2 - Industry';
        Visible = WizardStep = 2;
        field(Industry; IndustryName)
        {
          Caption = 'Industry';
          Editable = false;
          ToolTip = 'Wholesale is the first supported company package. Other industries are not yet executable.';
        }
      }
      group(SizeStep)
      {
        Caption = '3 - Data size';
        Visible = WizardStep = 3;
        field(SizeChoice; SizeChoice)
        {
          Caption = 'Data size';
          OptionCaption = 'Small,Medium,Large';
          ToolTip = 'Select the versioned wholesale quantities. Exact planned quantities appear before starting.';
        }
      }
      group(ProcessStep)
      {
        Caption = '4 - Data and processes';
        Visible = WizardStep = 4;
        field(ProcessChoice; ProcessChoice)
        {
          Caption = 'Data and processes';
          OptionCaption = 'Master data only,With unposted documents';
          ToolTip = 'Posting is unavailable until purchase receipts and complete posting prerequisites are supported. No documents are posted.';
        }
      }
      group(ReviewStep)
      {
        Caption = '5 - Summary and start';
        Visible = WizardStep = 5;
        field(Review; ReviewText)
        {
          Caption = 'Planned company';
          MultiLine = true;
          Editable = false;
          ToolTip = 'Review the chart, industry, quantities and unposted process types before authorizing the background job.';
        }
      }

      group(Safety)
      {
        Caption = 'Company Setup';
        Visible = Initialized and (WizardStep = 0);
        field(InstalledChart; InstalledChart)
        {
          CaptionClass = '3,' + ChartCaption;
          ToolTip = 'Shows the chart of accounts already selected for this company.';
          Editable = false;
        }
        field("Generation Enabled"; Rec."Generation Enabled") { }
        field("Allowed Environment Name"; Rec."Allowed Environment Name") { }
        field("Allowed Company Name"; Rec."Allowed Company Name") { }
        field("Posting Enabled"; Rec."Posting Enabled") { }
      }
      group(Defaults)
      {
        Caption = 'Scenario Defaults';
        Editable = Initialized;
        Visible = Initialized and (WizardStep = 0);
        field("Default Process Mode"; Rec."Default Process Mode") { }
        field("Default Usage Mode"; Rec."Default Usage Mode") { }
        field("Default Seed"; Rec."Default Seed") { }
        field("Default Data Language"; Rec."Default Data Language") { }
      }
      group(Limits)
      {
        Caption = 'Limits';
        Editable = Initialized;
        Visible = Initialized and (WizardStep = 0);
        field("Default Batch Size"; Rec."Default Batch Size") { }
        field("Maximum Batch Size"; Rec."Maximum Batch Size") { }
        field("Maximum Records per Entity"; Rec."Maximum Records per Entity") { }
      }
    }
  }

  actions
  {
    area(Promoted)
    {
      actionref(PreviousPromoted; PreviousStep) { }
      actionref(NextPromoted; NextStep) { }
      actionref(StartPromoted; StartCompany) { }
      actionref(InitializeCompanyPromoted; InitializeSetup) { }
    }
    area(Processing)
    {
      action(PreviousStep)
      {
        ApplicationArea = All;
        Caption = 'Back';
        Image = PreviousRecord;
        Visible = WizardStep > 1;
        ToolTip = 'Return to the previous choice without starting any work.';
        trigger OnAction()
        begin
          WizardStep -= 1;
        end;
      }
      action(NextStep)
      {
        ApplicationArea = All;
        Caption = 'Next';
        Image = NextRecord;
        Visible = (WizardStep > 0) and (WizardStep < 5);
        ToolTip = 'Review the next choice. No data is generated before Start.';
        trigger OnAction()
        begin
          WizardStep += 1;
          UpdateReview();
        end;
      }
      action(StartCompany)
      {
        ApplicationArea = All;
        Caption = 'Set up company and generate data';
        Image = Start;
        Visible = WizardStep = 5;
        ToolTip = 'Authorize one background process for company setup and the displayed data. The browser can be closed afterwards.';
        trigger OnAction()
        var
          Initialization: Codeunit "BCSF Company Initialization";
        begin
          Initialization.Start(SelectedChart(), SizeChoice, SelectedProcess());
          CurrPage.Close();
        end;
      }
      action(RefreshCompanyFoundation)
      {
        ApplicationArea = All;
        Caption = 'Complete Master Data Foundation';
        ToolTip = 'Adds missing foundation from the already applied test package, including carton unit and simple bin location. Does not change the chart of accounts or start a run.';
        Image = Setup;
        Enabled = Initialized;
        trigger OnAction()
        var
          Catalog: Codeunit "BCSF Starter Catalog";
        begin
          Catalog.RefreshCompanyFoundation();
          RefreshSetup();
          CurrPage.Update(false);
          Message(FoundationCompletedLbl);
        end;
      }
      action(InitializeSetup)
      {
        ApplicationArea = All;
        Caption = 'Initialize Company';
        Image = Setup;
        Visible = WizardStep = 0;
        ToolTip = 'Choose the chart of accounts and prepare this sandbox company once. Does not post documents.';

        trigger OnAction()
        begin
          WizardStep := 1;
          UpdateReview();
        end;
      }
    }
  }

  trigger OnOpenPage()
  begin
    RefreshSetup();
    if not Initialized then
      WizardStep := 1;
    ChartChoice := ChartChoice::SKR04;
    if Initialized then
      case PackagesMode() of
        "BCSF Finance Mode"::SKR03: ChartChoice := ChartChoice::SKR03;
        "BCSF Finance Mode"::Existing: ChartChoice := ChartChoice::Existing;
      end;
    IndustryName := WholesaleLbl;
    ProcessChoice := ProcessChoice::Documents;
    UpdateReview();
  end;

  trigger OnModifyRecord(): Boolean
  var
    Setup: Record "BCSF Factory Setup";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Company Initialized", true);
    if Rec."Generation Enabled" <> xRec."Generation Enabled" then
      Setup."Generation Enabled" := Rec."Generation Enabled";
    if Rec."Posting Enabled" <> xRec."Posting Enabled" then
      Setup."Posting Enabled" := Rec."Posting Enabled";
    if Rec."Allowed Environment Name" <> xRec."Allowed Environment Name" then
      Setup."Allowed Environment Name" := Rec."Allowed Environment Name";
    if Rec."Allowed Company Name" <> xRec."Allowed Company Name" then
      Setup."Allowed Company Name" := Rec."Allowed Company Name";
    if Rec."Default Process Mode" <> xRec."Default Process Mode" then
      Setup."Default Process Mode" := Rec."Default Process Mode";
    if Rec."Default Usage Mode" <> xRec."Default Usage Mode" then
      Setup."Default Usage Mode" := Rec."Default Usage Mode";
    if Rec."Default Seed" <> xRec."Default Seed" then
      Setup."Default Seed" := Rec."Default Seed";
    if Rec."Default Data Language" <> xRec."Default Data Language" then
      Setup."Default Data Language" := Rec."Default Data Language";
    if Rec."Default Batch Size" <> xRec."Default Batch Size" then
      Setup."Default Batch Size" := Rec."Default Batch Size";
    if Rec."Maximum Batch Size" <> xRec."Maximum Batch Size" then
      Setup."Maximum Batch Size" := Rec."Maximum Batch Size";
    if Rec."Maximum Records per Entity" <> xRec."Maximum Records per Entity" then
      Setup."Maximum Records per Entity" := Rec."Maximum Records per Entity";
    Setup.Modify(true);
    exit(true);
  end;

  local procedure PackagesMode(): Enum "BCSF Finance Mode"
  var
    Packages: Codeunit "BCSF Finance Package Mgt";
  begin
    exit(Packages.GetAppliedMode());
  end;

  local procedure SelectedChart(): Enum "BCSF Finance Mode"
  begin
    case ChartChoice of
      ChartChoice::SKR03: exit("BCSF Finance Mode"::SKR03);
      ChartChoice::SKR04: exit("BCSF Finance Mode"::SKR04);
    end;
    exit("BCSF Finance Mode"::Existing);
  end;

  local procedure SelectedProcess(): Enum "BCSF Process Mode"
  begin
    if ProcessChoice = ProcessChoice::Documents then
      exit("BCSF Process Mode"::UnpostedDocuments);
    exit("BCSF Process Mode"::SetupAndMasterData);
  end;

  local procedure UpdateReview()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    ReviewText := StrSubstNo(ReviewLbl, Format(SelectedChart()), IndustryName, SelectStr(SizeChoice + 1, SizesLbl), SelectStr(ProcessChoice + 1, ProcessesLbl),
      Profile.Quantity(SizeChoice, "BCSF Entity Type"::Customer), Profile.Quantity(SizeChoice, "BCSF Entity Type"::Vendor),
      Profile.Quantity(SizeChoice, "BCSF Entity Type"::Item));
    if ProcessChoice = ProcessChoice::Documents then
      ReviewText += StrSubstNo(DocumentsLbl, Profile.Quantity(SizeChoice, "BCSF Entity Type"::PurchaseOrder),
        Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesQuote), Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesOrder),
        Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesInvoice));
  end;

  local procedure RefreshSetup()
  var
    Setup: Record "BCSF Factory Setup";
    Scenario: Record "BCSF Scenario";
    Packages: Codeunit "BCSF Finance Package Mgt";
    AlreadyDisplayed: Boolean;
  begin
    AlreadyDisplayed := Rec.Get(Rec.GetSetupKey());
    Rec.Init();
    Rec."Primary Key" := Rec.GetSetupKey();
    if Setup.ReadPermission() then
      if Setup.Get(Setup.GetSetupKey()) then
        Rec := Setup;
    if AlreadyDisplayed then
      Rec.Modify(false)
    else
      Rec.Insert(false);
    Initialized := Rec."Company Initialized";
    Clear(InstalledChart);
    ChartCaption := Scenario.FieldCaption("Finance Mode");
    if Initialized then
      InstalledChart := Format(Packages.GetAppliedMode());
  end;

  var
    WizardStep: Integer;
    ChartChoice: Option SKR03,SKR04,Existing;
    SizeChoice: Option Small,Medium,Large;
    ProcessChoice: Option Master,Documents;
    IndustryName: Text;
    ReviewText: Text;
    SizesLbl: Label 'Small,Medium,Large';
    ProcessesLbl: Label 'Master data only,With unposted documents';
    WholesaleLbl: Label 'Wholesale';
    ReviewLbl: Label '%1 · %2 · %3 · %4. Customers: %5; vendors: %6; items: %7.', Comment = '%1 = chart, %2 = industry, %3 = size, %4 = process, %5 = customers, %6 = vendors, %7 = items';
    DocumentsLbl: Label ' Unposted purchase orders: %1; sales quotes: %2; sales orders: %3; sales invoices: %4. No posting.', Comment = '%1 = purchases, %2 = quotes, %3 = orders, %4 = invoices';
    Initialized: Boolean;
    InstalledChart: Text;
    ChartCaption: Text;
    FoundationCompletedLbl: Label 'The master data foundation has been checked and completed successfully.';
}
