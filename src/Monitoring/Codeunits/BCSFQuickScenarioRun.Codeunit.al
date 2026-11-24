namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Assembly;
using BCScenarioFactory.Planning;
using BCScenarioFactory.CRM;
using BCScenarioFactory.Warehouse;
using BCScenarioFactory.Core;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.DependencyManager;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;

codeunit 90367 "BCSF Quick Scenario Run"
{
    Access = Internal;

    procedure StartCaptured(RunId: Guid)
    var
        Header: Record "BCSF Run Header";
    begin
        Header.Get(RunId);
        if not Confirm(CapturedQst, false) then
            exit;
        StartCapturedConfirmed(RunId);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure StartCapturedConfirmed(RunId: Guid)
    var
        Header: Record "BCSF Run Header";
        Execution: Record "BCSF Run Execution";
        TempTarget: Record "BCSF Data Target" temporary;
        SetupMgt: Codeunit "BCSF Setup Management";
        Manager: Codeunit "BCSF Scenario Manager";
        Guard: Codeunit "BCSF Environment Guard";
        Plan: Codeunit "BCSF Plan Writer";
        Dispatcher: Codeunit "BCSF Queue Dispatcher";
    begin
        Header.LockTable();
        Header.Get(RunId);
        Guard.EnsureCanConfigure(CompanyName());
        SetupMgt.EnsureInitialized();
        Manager.LoadFrozenTargets(RunId, TempTarget);
        TempTarget.SetFilter(Quantity, '>0');
        if not TempTarget.FindSet() then
            Error(PartnerOnlyErr);
        repeat
            if not Manager.SupportsTarget(TempTarget) then
                Error(PartnerOnlyErr);
        until TempTarget.Next() = 0;
        Execution.LockTable();
        if not Execution.Get(RunId) then begin
            Plan.SavePlan(RunId);
            Dispatcher.Prepare(RunId);
        end else
            Execution.TestField(Status, Execution.Status::Ready);
        Dispatcher.Schedule(RunId, CurrentDateTime());
    end;

    procedure RunScenario(Scenario: Record "BCSF Scenario"): Guid
    begin
        exit(StartConfirmed(Scenario."Scenario Id", Scenario.Revision));
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure StartConfirmed(ScenarioId: Guid; ConfirmedRevision: Integer): Guid
    var
        Scenario: Record "BCSF Scenario";
        SetupMgt: Codeunit "BCSF Setup Management";
        Guard: Codeunit "BCSF Environment Guard";
        Snapshot: Codeunit "BCSF Snapshot Writer";
        Plan: Codeunit "BCSF Plan Writer";
        Dispatcher: Codeunit "BCSF Queue Dispatcher";
        Payments: Codeunit "BCSF Payment Processor";
        Movements: Codeunit "BCSFInventoryMovementProcessor";
        AssemblyProcessor: Codeunit "BCSF Assembly Processor";
        PlanningProcessor: Codeunit "BCSF Planning Processor";
        CrmProcessor: Codeunit "BCSF CRM Processor";
        WarehouseProcessor: Codeunit "BCSF Warehouse Processor";
        Selection: Codeunit "BCSF Module Selection";
        Packages: Codeunit "BCSF Finance Package Mgt";
        RunId: Guid;
    begin
        // Snapshot, configuration editors and module/target writes coordinate on the same scenario lock.
        Scenario.LockTable();
        Scenario.Get(ScenarioId);
        Scenario.TestField(Revision, ConfirmedRevision);
        SetupMgt.EnsureInitialized();
        Guard.EnsureCanConfigure(Scenario.CurrentCompany());
        CheckTargets(Scenario);

        if Scenario."Purchase Posting Approved" then
            Packages.PreparePostingFoundation();
        if Scenario."Payment Posting Approved" then begin
            Payments.PrepareFoundation();
            Movements.PrepareFoundation();
            // Additive foundation of the optional modules; only the modules selected in the scenario are prepared.
            if Selection.IsSelected(ScenarioId, "BCSF Module Type"::Assembly) then
                AssemblyProcessor.PrepareFoundation();
            if Selection.IsSelected(ScenarioId, "BCSF Module Type"::Planning) then
                PlanningProcessor.PrepareFoundation();
            if Selection.IsSelected(ScenarioId, "BCSF Module Type"::CRM) then
                CrmProcessor.PrepareFoundation();
            if Selection.IsSelected(ScenarioId, "BCSF Module Type"::Warehouse) then
                WarehouseProcessor.PrepareFoundation();
        end;
        RunId := Snapshot.CreateSnapshot(ScenarioId);
        Plan.SavePlan(RunId);
        Dispatcher.Prepare(RunId);
        Dispatcher.Schedule(RunId, CurrentDateTime());
        exit(RunId);
    end;

    local procedure CheckTargets(Scenario: Record "BCSF Scenario")
    var
        Manager: Codeunit "BCSF Scenario Manager";
    begin
        Manager.RequireExecutableTargets(Scenario);
    end;

    var
        CapturedQst: Label 'Start this captured run after rechecking its setup and permissions? Approved sales targets can post documents. Existing or uncertain batches are not repeated.';
        PartnerOnlyErr: Label 'Quick run supports customer, vendor, supported items and sales quotes, orders and invoices. This template requires an unavailable generator.';
}
