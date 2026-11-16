namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using System.Threading;

page 90353 "BCSF Run Events"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Status History';
  PageType = List;
  SourceTable = "BCSF Run Event";
  SourceTableView = sorting("Run Id", "Occurred At", "Entry Id") order(descending);
  Editable = false;
  layout
  {
    area(Content)
    {
      repeater(Events)
      {
        field("Occurred At"; Rec."Occurred At") { }
        field("Run Id"; Rec."Run Id") { }
        field("Batch Id"; Rec."Batch Id") { }
        field("Node Code"; Rec."Node Code") { }
        field(ObservedStatus; ObservedStatus)
        {
          Caption = 'Observed Status';
          ToolTip = 'Shows the run state for execution events and the batch state for batch events. History starts when monitoring is installed.';
        }
        field("Job Queue Entry Id"; Rec."Job Queue Entry Id") { }
        field("Processed Units"; Rec."Processed Units") { }
        field("Created Records"; Rec."Created Records") { }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(ViewStandardLogs)
      {
        Caption = 'View Queue Logs';
        ToolTip = 'Opens standard queue diagnostics for this recorded job identity without copying error text into monitoring.';
        Image = Log;
        trigger OnAction()
        var
          LogEntry: Record "Job Queue Log Entry";
        begin
          if IsNullGuid(Rec."Job Queue Entry Id") then
            Error(NoJobErr);
          LogEntry.SetRange(ID, Rec."Job Queue Entry Id");
          LogEntry.SetRange("Object Type to Run", LogEntry."Object Type to Run"::Codeunit);
          LogEntry.SetRange("Object ID to Run", Codeunit::"BCSF Batch Worker");
          Page.Run(Page::"Job Queue Log Entries", LogEntry);
        end;
      }
      action(Batches)
      {
        Caption = 'View Batches';
        ToolTip = 'Opens the persisted batch related to this transition.';
        Image = List;
        RunObject = page "BCSF Batch List";
        RunPageLink = "Run Id" = field("Run Id"), "Batch Id" = field("Batch Id");
      }
    }
  }
  trigger OnAfterGetRecord()
  begin
    if IsNullGuid(Rec."Batch Id") then
      ObservedStatus := Format(Rec."Run Status")
    else
      ObservedStatus := Format(Rec."Batch Status");
  end;
  var
    ObservedStatus: Text;
    NoJobErr: Label 'This transition has no job identity. Review the related execution or batch.';
}
