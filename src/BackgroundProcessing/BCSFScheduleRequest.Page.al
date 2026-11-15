namespace BCScenarioFactory.BackgroundProcessing;

page 90310 "BCSF Schedule Request"
{
  PageType = StandardDialog;
  Caption = 'Schedule Prepared Execution';
  layout
  {
    area(Content)
    {
      field(EarliestStart; EarliestStart)
      {
        ApplicationArea = All;
        Caption = 'Earliest Start';
        ToolTip = 'Specifies the earliest permitted start. The standard scheduler may start later. A past value means as soon as possible.';
      }
    }
  }
  trigger OnOpenPage()
  begin
    EarliestStart := CurrentDateTime();
  end;
  procedure GetEarliestStart(): DateTime
  begin
    exit(EarliestStart);
  end;
  var
    EarliestStart: DateTime;
}
