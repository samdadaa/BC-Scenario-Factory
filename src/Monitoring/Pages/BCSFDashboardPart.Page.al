namespace BCScenarioFactory.Monitoring;

page 90362 "BCSF Dashboard Part"
{
  ApplicationArea = All;
  Caption = 'Scenario Factory Workspace';
  PageType = CardPart;
  layout
  {
    area(Content)
    {
      usercontrol(Dashboard; "BCSF Dashboard")
      {
        ApplicationArea = All;
        trigger Ready()
        begin
          IsReady := true;
          RenderDashboard();
        end;

        trigger Command(ActionCode: Text; RunId: Text)
        var
          Commands: Codeunit "BCSF Dashboard Commands";
        begin
          if ActionCode = 'select' then
            SelectedRunId := Commands.ParseRunId(RunId)
          else
            if ActionCode <> 'refresh' then
              Commands.Execute(ActionCode, RunId);
          RenderDashboard();
        end;
      }
    }
  }

  /// <summary>Sets optional run context for an embedding host; the server rechecks identity and visibility.</summary>
  procedure SetRunId(Value: Guid)
  begin
    if SelectedRunId = Value then
      exit;
    SelectedRunId := Value;
    if IsReady then
      RenderDashboard();
  end;

  local procedure RenderDashboard()
  var
    DashboardData: Codeunit "BCSF Dashboard Data";
  begin
    CurrPage.Dashboard.SetDashboard(DashboardData.Build(SelectedRunId));
  end;

  var
    SelectedRunId: Guid;
    IsReady: Boolean;
}
