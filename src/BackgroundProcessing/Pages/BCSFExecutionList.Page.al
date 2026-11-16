namespace BCScenarioFactory.BackgroundProcessing;

page 90309 "BCSF Execution List"
{
  PageType = List;
  SourceTable = "BCSF Run Execution";
  Caption = 'Scenario Factory Executions';
  ApplicationArea = All;
  UsageCategory = Lists;
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Executions)
      {
        field("Run Id"; Rec."Run Id") { ApplicationArea = All; }
        field("Status"; Rec."Status") { ApplicationArea = All; }
        field("Earliest Start"; Rec."Earliest Start") { ApplicationArea = All; }
        field("Total Batches"; Rec."Total Batches") { ApplicationArea = All; }
        field("Completed Batches"; Rec."Completed Batches") { ApplicationArea = All; }
        field("Job Queue Entry Id"; Rec."Job Queue Entry Id") { ApplicationArea = All; }
        field("Created At"; Rec."Created At") { ApplicationArea = All; }
        field("Started At"; Rec."Started At") { ApplicationArea = All; }
        field("Finished At"; Rec."Finished At") { ApplicationArea = All; }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(ViewBatches)
      {
        ApplicationArea = All;
        Caption = 'View Batches';
        ToolTip = 'Shows the persisted batches and their confirmed progress for this execution.';
        Image = List;
        RunObject = page "BCSF Batch List";
        RunPageLink = "Run Id" = field("Run Id");
      }
    }
  }
}
