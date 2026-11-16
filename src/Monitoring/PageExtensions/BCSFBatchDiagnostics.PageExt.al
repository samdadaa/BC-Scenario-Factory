namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using System.Threading;

pageextension 90360 "BCSF Batch Diagnostics" extends "BCSF Batch List"
{
  actions
  {
    addlast(Processing)
    {
      action(ViewStandardLogs)
      {
        ApplicationArea = All;
        Caption = 'View Queue Logs';
        ToolTip = 'Opens standard queue logs for the current and previous job identities. Earlier attempts are accessible through status history. Standard read permissions are required.';
        Image = Log;
        trigger OnAction()
        var
          LogEntry: Record "Job Queue Log Entry";
        begin
          if IsNullGuid(Rec."Job Queue Entry Id") and IsNullGuid(Rec."Previous Job Id") then
            Error(NoJobErr);
          LogEntry.SetFilter(ID, '%1|%2', Rec."Job Queue Entry Id", Rec."Previous Job Id");
          LogEntry.SetRange("Object Type to Run", LogEntry."Object Type to Run"::Codeunit);
          LogEntry.SetRange("Object ID to Run", Codeunit::"BCSF Batch Worker");
          Page.Run(Page::"Job Queue Log Entries", LogEntry);
        end;
      }
      action(StatusHistory)
      {
        ApplicationArea = All;
        Caption = 'View Status History';
        ToolTip = 'Shows technical transitions for this batch, including earlier recorded job identities.';
        Image = History;
        RunObject = page "BCSF Run Events";
        RunPageLink = "Run Id" = field("Run Id"), "Batch Id" = field("Batch Id");
      }
    }
  }
  var
    NoJobErr: Label 'No job identity has been assigned to this batch. Review its plan and execution status.';
}
