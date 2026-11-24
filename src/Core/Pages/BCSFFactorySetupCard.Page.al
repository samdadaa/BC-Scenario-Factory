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
          ToolTip = 'Choose the chart once. Existing financial mappings are retained; missing required technical setup is added before generation.';
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
      group(GenerationStep)
      {
        Caption = '3 - Generation kind';
        Visible = WizardStep = 3;
        field(GenerationKind; GenerationKind)
        {
          Caption = 'Generation kind';
          ToolTip = 'Choose a complete scenario, master data only, or transactions using eligible existing master records in this company.';
          trigger OnValidate()
          begin
            PostingApproved := false;
            if GenerationKind <> GenerationKind::Transactions then
              Clear(MasterSourceId);
            if GenerationKind = GenerationKind::MasterData then
              ProcessChoice := ProcessChoice::Master
            else
              if ProcessChoice = ProcessChoice::Master then
                ProcessChoice := ProcessChoice::Documents;
            UpdateReview();
          end;
        }
        field(MasterSource; MasterSourceId)
        {
          Caption = 'Master data source';
          Visible = GenerationKind = GenerationKind::Transactions;
          ToolTip = 'Optional: select a specific confirmed Factory run. Leave empty to use eligible customers, vendors and items from this company; selected SystemIds are captured for the run.';
          trigger OnLookup(var Text: Text): Boolean
          var
            Initialization: Codeunit "BCSF Company Initialization";
          begin
            exit(Initialization.SelectMasterSource(MasterSourceId));
          end;
        }
      }
      group(TransactionModules)
      {
        Caption = '4 - Process modules';
        Visible = (WizardStep = 4) and (GenerationKind = GenerationKind::Transactions);
        field(PurchaseSelected; PurchaseSelected)
        {
          Caption = 'Purchasing';
          ToolTip = 'Creates new purchase orders from the selected master data. Posting and payments follow the selected process mode.';
        }
        field(SalesSelected; SalesSelected)
        {
          Caption = 'Sales';
          ToolTip = 'Creates only the selected sales documents. Purchasing is added only when explicitly selected; posted sales require current stock.';
        }
        field(InventoryMovementInfo; InventoryMovementLbl)
        {
          Caption = 'Inventory';
          Editable = false;
          MultiLine = true;
          ToolTip = 'Inventory supplies existing items and live stock checks. An independent inventory movement generator is not implemented.';
        }
      }
      group(ModuleStep)
      {
        Caption = '4 - Modules';
        Visible = (WizardStep = 4) and (GenerationKind <> GenerationKind::Transactions);
        field(ModuleExplanation; ModulesHintLbl)
        {
          Caption = 'Module selection';
          Editable = false;
          MultiLine = true;
          ToolTip = 'Required modules remain selected to preserve the connected wholesale process. Optional modules add their own data and processes in the follow-up stage.';
        }
        part(CompanyModules; "BCSF Frozen Modules")
        {
          ApplicationArea = All;
          Caption = 'Industry modules and optional additions';
        }
      }
      group(SizeStep)
      {
        Caption = '5 - Data size';
        Visible = WizardStep = 5;
        field(SizeChoice; SizeChoice)
        {
          Caption = 'Data size';
          OptionCaption = 'Small,Medium,Large';
          ToolTip = 'Select the versioned wholesale quantities. Exact planned quantities appear before starting.';
          trigger OnValidate()
          begin
            SetDocumentQuantities();
          end;
        }
      }
      group(TransactionQuantities)
      {
        Caption = 'Document quantities';
        Visible = (WizardStep = 5) and (GenerationKind = GenerationKind::Transactions);
        field(PurchaseQuantity; PurchaseQuantity)
        {
          Caption = 'Purchase orders';
          Visible = PurchaseSelected;
          MinValue = 0;
          ToolTip = 'Specifies the number of new documents for this independent run. Zero omits this document type; master records are reused.';
        }
        field(SalesOrderQuantity; SalesOrderQuantity)
        {
          Caption = 'Sales orders';
          Visible = SalesSelected;
          MinValue = 0;
          ToolTip = 'Specifies the number of new documents for this independent run. Zero omits this document type; master records are reused.';
        }
        field(SalesQuoteQuantity; SalesQuoteQuantity)
        {
          Caption = 'Sales quotes';
          Visible = SalesSelected;
          MinValue = 0;
          ToolTip = 'Specifies the number of new documents for this independent run. Zero omits this document type; master records are reused.';
        }
        field(SalesBlanketQuantity; SalesBlanketQuantity)
        {
          Caption = 'Sales blanket orders';
          Visible = SalesSelected;
          MinValue = 0;
          ToolTip = 'Specifies the number of new blanket orders with at least three lines each. Blanket orders stay unposted. Zero omits this document type; master records are reused.';
        }
        field(SalesInvoiceQuantity; SalesInvoiceQuantity)
        {
          Caption = 'Sales invoices';
          Visible = SalesSelected;
          MinValue = 0;
          ToolTip = 'Specifies the number of new documents for this independent run. Zero omits this document type; master records are reused.';
        }
      }
      group(ProcessStep)
      {
        Caption = '6 - Data and processes';
        Visible = WizardStep = 6;
        field(StartingDate; StartingDate)
        {
          Caption = 'Generate data from';
          ToolTip = 'Specifies the first business date. Dates are distributed from this date through yesterday; technical creation timestamps show the actual creation time.';
          trigger OnValidate()
          var
            Profile: Codeunit "BCSF Wholesale Profile";
          begin
            Profile.CheckDateRange(StartingDate, EndingDate, Today() - 1);
            PostingApproved := false;
          end;
        }
        field(EndingDate; EndingDate)
        {
          Caption = 'Generate data through';
          Editable = false;
          ToolTip = 'Shows yesterday, fixed when the request is submitted. Background batches use this captured boundary even after midnight.';
        }
        field(ProcessChoice; ProcessChoice)
        {
          Caption = 'Data and processes';
          Editable = GenerationKind <> GenerationKind::MasterData;
          OptionCaption = 'Master data only,With unposted documents,With posted documents,With payments and application';
          ToolTip = 'Select unposted documents, standard purchase and sales posting, or additional payments and application. Posting requires explicit approval.';
          trigger OnValidate()
          begin
            PostingApproved := false;
          end;
        }
      }
      group(PostingConsent)
      {
        Caption = 'Posting approval';
        Visible = (WizardStep = 6) and (ProcessChoice >= 2);
        field(PostingApproved; PostingApproved)
        {
          Caption = 'Approve posting and selected follow-up processes';
          ToolTip = 'Explicitly authorizes standard receipts, shipments and invoices. Payment mode also posts and applies customer and vendor payments using a synthetic bank account without bank transmission.';
        }
      }
      group(ReviewStep)
      {
        Caption = '7 - Summary and start';
        Visible = WizardStep = 7;
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
          CaptureModules();
          WizardStep -= 1;
        end;
      }
      action(NextStep)
      {
        ApplicationArea = All;
        Caption = 'Next';
        Image = NextRecord;
        Visible = (WizardStep > 0) and (WizardStep < 7);
        ToolTip = 'Review the next choice. No data is generated before Start.';
        trigger OnAction()
        begin
          CaptureModules();
          WizardStep += 1;
          UpdateReview();
        end;
      }
      action(StartCompany)
      {
        ApplicationArea = All;
        Caption = 'Set up company and generate data';
        Image = Start;
        Visible = WizardStep = 7;
        ToolTip = 'Authorize one background process for company setup and the displayed data. The browser can be closed afterwards.';
        trigger OnAction()
        var
          Initialization: Codeunit "BCSF Company Initialization";
        begin
          CaptureModules();
          Initialization.StartConfigured(SelectedChart(), SizeChoice, SelectedProcess(), PostingApproved, AdditionalModules, StartingDate, EndingDate,
            GenerationKind, MasterSourceId, PurchaseSelected, SalesSelected, PurchaseQuantity, SalesOrderQuantity, SalesQuoteQuantity, SalesInvoiceQuantity, SalesBlanketQuantity);
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
        Caption = 'Set up company or start another run';
        Image = Setup;
        Visible = WizardStep = 0;
        ToolTip = 'Use the existing company foundation and choose the data size and process scope. A new run requires the previous company run to have completed.';

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
    if not Initialized or OpenAsWorkflow then
      WizardStep := 1;
    ChartChoice := ChartChoice::SKR04;
    if Initialized then
      case PackagesMode() of
        "BCSF Finance Mode"::SKR03: ChartChoice := ChartChoice::SKR03;
        "BCSF Finance Mode"::Existing: ChartChoice := ChartChoice::Existing;
      end;
    IndustryName := WholesaleLbl;
    StartingDate := CalcDate('<-1Y>', Today());
    EndingDate := Today() - 1;
    ProcessChoice := ProcessChoice::Documents;
    InitializeModules();
    PurchaseSelected := true;
    SalesSelected := true;
    SetDocumentQuantities();
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

  procedure OpenWorkflow()
  begin
    OpenAsWorkflow := true;
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
    case ProcessChoice of
      ProcessChoice::Documents: exit("BCSF Process Mode"::UnpostedDocuments);
      ProcessChoice::Posted: exit("BCSF Process Mode"::PostedMovements);
      ProcessChoice::Payments: exit("BCSF Process Mode"::FollowUpProcesses);
    end;
    exit("BCSF Process Mode"::SetupAndMasterData);
  end;

  local procedure InitializeModules()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    Profile.LoadModules('', TempBaseModules);
    Profile.LoadModules('', TempSelectedModules);
    CurrPage.CompanyModules.Page.LoadSelection(TempSelectedModules, TempBaseModules);
  end;

  local procedure CaptureModules()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    if GenerationKind = GenerationKind::Transactions then begin
      AdditionalModules := '';
      exit;
    end;
    CurrPage.CompanyModules.Page.GetSelection(TempSelectedModules);
    AdditionalModules := Profile.EncodeAdditionalModules(TempSelectedModules);
  end;

  local procedure SetDocumentQuantities()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    PurchaseQuantity := Profile.Quantity(SizeChoice, "BCSF Entity Type"::PurchaseOrder);
    SalesOrderQuantity := Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesOrder);
    SalesQuoteQuantity := Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesQuote);
    SalesInvoiceQuantity := Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesInvoice);
    SalesBlanketQuantity := Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesBlanketOrder);
  end;

  local procedure UpdateReview()
  var
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    ReviewText := NewDatasetLbl + StrSubstNo(ReviewLbl, Format(SelectedChart()), IndustryName, SelectStr(SizeChoice + 1, SizesLbl), SelectStr(ProcessChoice + 1, ProcessesLbl),
      Profile.Quantity(SizeChoice, "BCSF Entity Type"::Customer), Profile.Quantity(SizeChoice, "BCSF Entity Type"::Vendor),
      Profile.Quantity(SizeChoice, "BCSF Entity Type"::Item));
    ReviewText += ' ' + Profile.DescribeModules(AdditionalModules) + ' ' + StrSubstNo(PeriodLbl, StartingDate, EndingDate);
    if ProcessChoice >= ProcessChoice::Documents then
      ReviewText += StrSubstNo(DocumentsLbl, Profile.Quantity(SizeChoice, "BCSF Entity Type"::PurchaseOrder),
        Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesQuote), Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesOrder),
        Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesInvoice)) +
        StrSubstNo(BlanketReviewLbl, Profile.Quantity(SizeChoice, "BCSF Entity Type"::SalesBlanketOrder));
    if ProcessChoice >= ProcessChoice::Posted then
      ReviewText += PostingMixLbl + CostPostingLbl;
    if ProcessChoice = ProcessChoice::Payments then
      ReviewText += PaymentsReviewLbl;
    ReviewText := Format(GenerationKind) + ' · ' + ReviewText;
    if GenerationKind = GenerationKind::Transactions then begin
      ReviewText := StrSubstNo(SourceReviewLbl, MasterSourceId, PurchaseSelected, SalesSelected,
        SelectedQuantity(PurchaseSelected, PurchaseQuantity), SelectedQuantity(SalesSelected, SalesOrderQuantity),
        SelectedQuantity(SalesSelected, SalesQuoteQuantity), SelectedQuantity(SalesSelected, SalesInvoiceQuantity)) +
        StrSubstNo(BlanketReviewLbl, SelectedQuantity(SalesSelected, SalesBlanketQuantity)) + ' ' +
        StrSubstNo(PeriodLbl, StartingDate, EndingDate) + ' ' + SelectStr(ProcessChoice + 1, ProcessesLbl);
      if ProcessChoice >= ProcessChoice::Posted then
        ReviewText += PostingMixLbl + CostPostingLbl;
      if ProcessChoice = ProcessChoice::Payments then
        ReviewText += PaymentsReviewLbl;
    end;
    if SelectedChart() = "BCSF Finance Mode"::Existing then
      ReviewText += ExistingFoundationLbl;
  end;

  local procedure SelectedQuantity(Selected: Boolean; Quantity: Integer): Integer
  begin
    if Selected then
      exit(Quantity);
    exit(0);
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
    TempBaseModules: Record "BCSF Scenario Module" temporary;
    TempSelectedModules: Record "BCSF Scenario Module" temporary;
    GenerationKind: Enum "BCSF Generation Kind";
    MasterSourceId: Guid;
    PurchaseSelected: Boolean;
    SalesSelected: Boolean;
    PurchaseQuantity: Integer;
    SalesOrderQuantity: Integer;
    SalesQuoteQuantity: Integer;
    SalesBlanketQuantity: Integer;
    SalesInvoiceQuantity: Integer;
    SourceReviewLbl: Label 'Transactions only. Master data source: %1. Purchasing: %2; sales: %3. New orders: purchase %4, sales %5; quotes %6; invoices %7. No new master records.', Comment = '%1 = source run, %2 = purchasing selected, %3 = sales selected, %4 = purchase count, %5 = sales order count, %6 = quote count, %7 = invoice count';
    InventoryMovementLbl: Label 'Existing items and current stock are reused. Independent inventory movements are not available.';
    AdditionalModules: Text[250];
    StartingDate: Date;
    EndingDate: Date;
    PeriodLbl: Label 'Business dates: %1 to %2 (inclusive). Technical creation timestamps remain the actual creation time.', Comment = '%1 = starting date, %2 = ending date';
    ModulesHintLbl: Label 'Wholesale requires Sales, Purchasing, Inventory and the shared Finance foundation. Select optional modules; they generate data in the follow-up stage of the company package.';
    OpenAsWorkflow: Boolean;
    WizardStep: Integer;
    ChartChoice: Option SKR03,SKR04,Existing;
    SizeChoice: Option Small,Medium,Large;
    ProcessChoice: Option Master,Documents,Posted,Payments;
    PostingApproved: Boolean;
    IndustryName: Text;
    ReviewText: Text;
    ExistingFoundationLbl: Label ' Existing financial accounts and mappings are retained. Missing required technical setup is added before generation; financial roles without a usable mapping remain blocked.';
    NewDatasetLbl: Label 'A new run creates the displayed synthetic records in this company. ';
    CostPostingLbl: Label ' Automatic inventory cost posting is enabled only in a company without posted activity; an existing conflicting cost policy stops the run.';
    PostingMixLbl: Label ' Purchase orders: 20% unposted, 20% partial, 60% fully invoiced; sales orders: 25% unposted, 25% partial, 50% fully invoiced; sales invoices: 33% unposted, 67% posted. Rounded down per target; remaining units stay unposted.';
    PaymentsReviewLbl: Label ' All resulting posted purchase and sales invoices are fully paid and applied between their invoice date and the period end through standard journal posting; unposted documents remain open.';
    SizesLbl: Label 'Small,Medium,Large';
    ProcessesLbl: Label 'Master data only,With unposted documents,With posted documents,With payments and application';
    WholesaleLbl: Label 'Wholesale';
    ReviewLbl: Label '%1 · %2 · %3 · %4. Customers: %5; vendors: %6; items: %7.', Comment = '%1 = chart, %2 = industry, %3 = size, %4 = process, %5 = customers, %6 = vendors, %7 = items';
    DocumentsLbl: Label ' Planned purchase orders: %1; sales quotes: %2; sales orders: %3; sales invoices: %4. Quotes remain unposted; posting follows the selected process and approval.', Comment = '%1 = purchases, %2 = quotes, %3 = orders, %4 = invoices';
    BlanketReviewLbl: Label ' Sales blanket orders: %1 (at least three lines each, always unposted).', Comment = '%1 = blanket orders';
    Initialized: Boolean;
    InstalledChart: Text;
    ChartCaption: Text;
    FoundationCompletedLbl: Label 'The master data foundation has been checked and completed successfully.';
}
