namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.Core;

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
                var
                    Setup: Record "BCSF Factory Setup";
                begin
                    IsReady := true;
                    ReloadStock();
                    RenderDashboard();
                    if not WizardOpened then begin
                        WizardOpened := true;
                        if Setup.ReadPermission() then
                            if not Setup.Get(Setup.GetSetupKey()) then
                                Page.RunModal(Page::"BCSF Factory Setup Card")
                            else
                                if not Setup."Company Initialized" and IsNullGuid(Setup."Industry Job Id") then
                                    Page.RunModal(Page::"BCSF Factory Setup Card");
                        ReloadStock();
                        RenderDashboard();
                    end;
                end;

                trigger Command(ActionCode: Text; RunId: Text)
                var
                    Commands: Codeunit "BCSF Dashboard Commands";
                    Data: Codeunit "BCSF Dashboard Data";
                    Stock: Codeunit "BCSF Dashboard Stock";
                begin
                    if ActionCode = 'autoRefresh' then begin
                        if not TryAutoRefresh() then begin
                            ClearLastError();
                            CurrPage.Dashboard.AutoRefreshFailed();
                        end;
                        exit;
                    end;
                    case ActionCode of
                        'select':
                            begin
                                SelectedRunId := Commands.ParseRunId(RunId);
                                Clear(RunStock);
                            end;
                        'view':
                            begin
                                if not (RunId in ['generation', 'data', 'runs']) then
                                    Error(InvalidStockSelectionErr);
                                ActiveView := RunId;
                                ReloadStock();
                            end;
                        'stockScope', 'stockRun', 'stockOpen':
                            HandleStock(ActionCode, RunId);
                        'summary':
                            Data.OpenSummary(RunId, SummaryViews);
                        'runOpen':
                            Stock.OpenMetric('master', RunId, false, SelectedRunId, RunStock);
                        'refresh':
                            begin
                                Clear(RunStock);
                                ReloadStock();
                            end;
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
                    Stock.OpenMetric('master', Value, EntireCompany, StockRunId, StockView);
                    exit;
                end;
        end;
        ReloadStock();
    end;

    // Read-only polling: surface failures in the dashboard without repeating modal server errors.
    [TryFunction]
    local procedure TryAutoRefresh()
    begin
        // Polling must stay cheap: the company data counts are rebuilt only on explicit view, scope or refresh commands.
        if ActiveView <> 'data' then
            ReloadStock();
        RenderDashboard();
    end;

    local procedure ReloadStock()
    var
        Stock: Codeunit "BCSF Dashboard Stock";
    begin
        StockView := Stock.BuildView(ActiveView = 'data', EntireCompany, StockRunId);
    end;

    local procedure RenderDashboard()
    var
        DashboardData: Codeunit "BCSF Dashboard Data";
    begin
        CurrPage.Dashboard.SetDashboard(DashboardData.Build(SelectedRunId, StockView, RunStock, SummaryViews, ActiveView));
    end;

    var
        SelectedRunId: Guid;
        IsReady: Boolean;
        WizardOpened: Boolean;
        ActiveView: Text;
        EntireCompany: Boolean;
        StockRunId: Guid;
        StockView: JsonObject;
        RunStock: JsonObject;
        SummaryViews: JsonObject;
        InvalidStockSelectionErr: Label 'The requested data selection is unavailable.';
}
