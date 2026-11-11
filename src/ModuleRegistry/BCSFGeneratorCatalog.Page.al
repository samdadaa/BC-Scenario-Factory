namespace BCScenarioFactory.ModuleRegistry;

page 90182 "BCSF Generator Catalog"
{
  ApplicationArea = All;
  Caption = 'Generator Catalog';
  PageType = List;
  SourceTable = "BCSF Generator Registry";
  UsageCategory = Lists;
  Editable = false;
  InsertAllowed = false;
  ModifyAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      repeater(Capabilities)
      {
        field("Generator Code"; Rec."Generator Code") { }
        field(Name; Rec.Name) { }
        field("Entity Code"; Rec."Entity Code") { }
        field("Module Code"; Rec."Module Code") { }
        field(Version; Rec.Version) { }
        field("Contract Version"; Rec."Contract Version") { }
        field("Minimum Mode"; Rec."Minimum Mode") { }
        field("Maximum Mode"; Rec."Maximum Mode") { }
        field("Maximum Batch Size"; Rec."Maximum Batch Size") { }
        field("Contract Probe"; Rec."Contract Probe") { }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(CheckContract)
      {
        ApplicationArea = All;
        Caption = 'Run Contract Self-Check';
        ToolTip = 'Checks two read-only probes, bounded batches, resume results and input isolation. No business data is generated.';
        Image = Check;
        trigger OnAction()
        var
          SelfCheck: Codeunit "BCSF Contract Self Check";
        begin
          SelfCheck.Check();
          Message(CheckedLbl);
        end;
      }
    }
  }
  trigger OnOpenPage()
  var
    Registry: Codeunit "BCSF Generator Registry Mgt";
  begin
    Registry.LoadCatalog(Rec);
  end;
  var
    CheckedLbl: Label 'The read-only generator contract self-check passed. No business records were generated.';
}
