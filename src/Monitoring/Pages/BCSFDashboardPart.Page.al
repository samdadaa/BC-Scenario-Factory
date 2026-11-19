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
                    ReloadStock();
                    RenderDashboard();
                end;

                trigger Command(ActionCode: Text; RunId: Text)
                var
                    Commands: Codeunit "BCSF Dashboard Commands";
                begin
                    case ActionCode of
                        'select':
                            SelectedRunId := Commands.ParseRunId(RunId);
                        'stockGroup', 'stockScope', 'stockRun', 'stockOpen':
                            HandleStock(ActionCode, RunId);
                        'refresh':
                            ReloadStock();
                        else
                            Commands.Execute(ActionCode, RunId);
                    end;
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

    local procedure HandleStock(ActionCode: Text; Value: Text)
    var
        Stock: Codeunit "BCSF Dashboard Stock";
        Commands: Codeunit "BCSF Dashboard Commands";
    begin
        case ActionCode of
            'stockGroup':
                begin
                    if not Stock.IsGroup(Value) then
                        Error(InvalidStockSelectionErr);
                    StockGroup := Value;
                end;
            'stockScope':
                begin
                    if (Value <> 'generated') and (Value <> 'company') then
                        Error(InvalidStockSelectionErr);
                    EntireCompany := Value = 'company';
                    if EntireCompany then
                        Clear(StockRunId);
                end;
            'stockRun':
                begin
                    if EntireCompany then
                        Error(InvalidStockSelectionErr);
                    if Value = '' then
                        Clear(StockRunId)
                    else
                        StockRunId := Commands.ParseRunId(Value);
                end;
            'stockOpen':
                begin
                    Stock.OpenMetric(StockGroup, Value, EntireCompany, StockRunId, StockView);
                    exit;
                end;
        end;
        ReloadStock();
    end;

    local procedure ReloadStock()
    var
        Stock: Codeunit "BCSF Dashboard Stock";
    begin
        StockView := Stock.Build(StockGroup, EntireCompany, StockRunId);
    end;

    local procedure RenderDashboard()
    var
        DashboardData: Codeunit "BCSF Dashboard Data";
    begin
        CurrPage.Dashboard.SetDashboard(DashboardData.Build(SelectedRunId, StockView));
    end;

    var
        SelectedRunId: Guid;
        IsReady: Boolean;
        StockGroup: Text;
        EntireCompany: Boolean;
        StockRunId: Guid;
        StockView: JsonObject;
        InvalidStockSelectionErr: Label 'The requested data selection is unavailable.';
}
