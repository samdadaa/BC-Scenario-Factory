namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

page 90139 "BCSF Run Card"
{
  ApplicationArea = All;
  Caption = 'Captured Scenario Run';
  PageType = Card;
  SourceTable = "BCSF Run Header";
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      group(Configuration)
      {
        Caption = 'Captured Configuration';
        field(Description; Rec.Description) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Profile Version"; Rec."Profile Version") { }
        field(GenerationKind; GenerationKind)
        {
          Caption = 'Generation kind';
          ToolTip = 'Shows the generation kind frozen in this run. Historical captures keep their original interpretation.';
        }
        field(MasterSourceId; MasterSourceId)
        {
          Caption = 'Master data source';
          Visible = GenerationKind = GenerationKind::Transactions;
          ToolTip = 'Shows the frozen source run for reused master records. Only new documents and entries belong to this run.';
        }
        field("Usage Mode"; Rec."Usage Mode") { }
        field("Process Mode"; Rec."Process Mode") { }
        field(Seed; Rec.Seed) { }
        field("Starting Date"; Rec."Starting Date") { }
        field("Ending Date"; Rec."Ending Date") { }
        field("Data Language"; Rec."Data Language") { }
        field("Batch Size"; Rec."Batch Size") { }
      }
      group(TechnicalDetails)
      {
        Caption = 'Technical Details';
        field("Run Id"; Rec."Run Id") { Importance = Additional; }
        field("Scenario Id"; Rec."Scenario Id") { }
        field("Scenario Revision"; Rec."Scenario Revision") { }
        field(Status; Rec.Status) { Caption = 'Historical Initial Status'; Importance = Additional; }
        field("Created At"; Rec."Created At") { }
        field("Company Name"; Rec."Company Name") { }
        field("Environment Name"; Rec."Environment Name") { }
      }
      group(LanguagePreview)
      {
        Caption = 'Data Language Preview';
        field(CustomerPreview; CustomerPreview)
        {
          Caption = 'Customer Name Preview';
          ToolTip = 'Shows a synthetic example using the captured data language and catalog version.';
          Editable = false;
        }
        field(VendorPreview; VendorPreview)
        {
          Caption = 'Vendor Name Preview';
          ToolTip = 'Shows a synthetic example using the captured data language and catalog version.';
          Editable = false;
        }
        field(ItemPreview; ItemPreview)
        {
          Caption = 'Item Name Preview';
          ToolTip = 'Shows a synthetic example using the captured data language and catalog version.';
          Editable = false;
        }
      }
      part(Modules; "BCSF Frozen Modules") { Caption = 'Captured Modules'; }
      part(Targets; "BCSF Frozen Targets") { Caption = 'Captured Entity Targets'; }
    }
  }
  actions
  {
    area(Processing)
    {
      group(Diagnostics)
      {
        Caption = 'Diagnostics';
      }
    }
  }
  trigger OnAfterGetCurrRecord()
  var
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Token: JsonToken;
  begin
    Clear(MasterSourceId);
    GenerationKind := GenerationKind::Complete;
    if not IsNullGuid(Rec."Run Id") then begin
      Manager.ReadSnapshot(Rec."Run Id", Context);
      if Context.Get('generationKind', Token) then
        GenerationKind := "BCSF Generation Kind".FromInteger(Token.AsValue().AsInteger());
      if Context.Get('masterDataSource', Token) then
        Evaluate(MasterSourceId, Contract.GetText(Token.AsObject(), 'sourceRunId'));
      Manager.GetRunLanguagePreview(Rec."Run Id", CustomerPreview, VendorPreview, ItemPreview);
      CurrPage.Modules.Page.LoadRun(Rec."Run Id");
      CurrPage.Targets.Page.LoadRun(Rec."Run Id");
    end;
  end;
  var
    GenerationKind: Enum "BCSF Generation Kind";
    MasterSourceId: Guid;
    CustomerPreview: Text[100];
    VendorPreview: Text[100];
    ItemPreview: Text[100];
}
