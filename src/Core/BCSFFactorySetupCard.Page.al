namespace BCScenarioFactory.Core;

page 90101 "BCSF Factory Setup Card"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Setup';
  PageType = Card;
  SourceTable = "BCSF Factory Setup";
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
        Caption = 'Safety';
        Editable = SetupExists;
        field("Generation Enabled"; Rec."Generation Enabled") { }
        field("Allowed Environment Name"; Rec."Allowed Environment Name") { }
        field("Allowed Company Name"; Rec."Allowed Company Name") { }
        field("Posting Enabled"; Rec."Posting Enabled") { }
      }
      group(Defaults)
      {
        Caption = 'Scenario Defaults';
        Editable = SetupExists;
        field("Default Process Mode"; Rec."Default Process Mode") { }
        field("Default Usage Mode"; Rec."Default Usage Mode") { }
        field("Default Seed"; Rec."Default Seed") { }
      }
      group(Limits)
      {
        Caption = 'Limits';
        Editable = SetupExists;
        field("Default Batch Size"; Rec."Default Batch Size") { }
        field("Maximum Batch Size"; Rec."Maximum Batch Size") { }
        field("Maximum Records per Entity"; Rec."Maximum Records per Entity") { }
      }
    }
  }

  actions
  {
    area(Processing)
    {
      action(InitializeSetup)
      {
        ApplicationArea = All;
        Caption = 'Initialize Setup';
        Image = Setup;
        ToolTip = 'Creates disabled default settings in the approved sandbox and current test company. Existing settings are retained.';

        trigger OnAction()
        var
          SetupManagement: Codeunit "BCSF Setup Management";
        begin
          SetupManagement.InitializeSetup();
          SetupExists := Rec.Get(Rec.GetSetupKey());
          CurrPage.Update(false);
          Message(SetupAvailableMsg);
        end;
      }
    }
  }

  trigger OnOpenPage()
  begin
    SetupExists := Rec.Get(Rec.GetSetupKey());
  end;

  var
    SetupExists: Boolean;
    SetupAvailableMsg: Label 'The settings are available. Review the safety settings before explicitly enabling generation.';
}
