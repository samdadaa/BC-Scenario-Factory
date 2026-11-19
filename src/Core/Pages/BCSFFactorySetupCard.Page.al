namespace BCScenarioFactory.Core;

using BCScenarioFactory.Finance;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.ScenarioManagement;
using BCScenarioFactory.Lifecycle;

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
      group(Safety)
      {
        Caption = 'Company Setup';
        Visible = Initialized;
        field(InstalledChart; InstalledChart)
        {
          CaptionClass = '3,' + ChartCaption;
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
        Visible = Initialized;
        field("Default Process Mode"; Rec."Default Process Mode") { }
        field("Default Usage Mode"; Rec."Default Usage Mode") { }
        field("Default Seed"; Rec."Default Seed") { }
        field("Default Data Language"; Rec."Default Data Language") { }
      }
      group(Limits)
      {
        Caption = 'Limits';
        Editable = Initialized;
        Visible = Initialized;
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
      actionref(InitializeCompanyPromoted; InitializeSetup) { }
    }
    area(Processing)
    {
      action(InitializeSetup)
      {
        ApplicationArea = All;
        Caption = 'Initialize Company';
        Image = Setup;
        Enabled = not Initialized;
        ToolTip = 'Choose the chart of accounts and prepare this sandbox company once. Does not post documents.';

        trigger OnAction()
        var
          Catalog: Codeunit "BCSF Starter Catalog";
          Packages: Codeunit "BCSF Finance Package Mgt";
          Mode: Enum "BCSF Finance Mode";
          Choice: Integer;
          DefaultChoice: Integer;
        begin
          DefaultChoice := 2;
          case Packages.GetAppliedMode() of
            Mode::SKR03: DefaultChoice := 1;
            Mode::SKR04: DefaultChoice := 2;
          end;
          Choice := StrMenu(StrSubstNo('%1,%2,%3', Format(Mode::SKR03), Format(Mode::SKR04), Format(Mode::Existing)),
            DefaultChoice, StrSubstNo(SetupAvailableMsg, CompanyName()));
          case Choice of
            0: exit;
            1: Mode := Mode::SKR03;
            2: Mode := Mode::SKR04;
            3: Mode := Mode::Existing;
          end;
          Catalog.InitializeCompany(Mode);
          RefreshSetup();
          CurrPage.Update(false);
        end;
      }
    }
  }

  trigger OnOpenPage()
  begin
    RefreshSetup();
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

  local procedure RefreshSetup()
  var
    Setup: Record "BCSF Factory Setup";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Scenario: Record "BCSF Scenario";
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
    Initialized: Boolean;
    InstalledChart: Text;
    ChartCaption: Text;
    SetupAvailableMsg: Label 'Which chart of accounts should %1 use? This prepares the sandbox company and enables test data generation. Posting remains disabled for a new company.', Comment = '%1 = company name';
}
