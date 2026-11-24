namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.CRM;
using BCScenarioFactory.Finance;
using BCScenarioFactory.FixedAssets;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Manufacturing;
using BCScenarioFactory.ServiceManagement;
using BCScenarioFactory.Warehouse;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

/// <summary>
/// Module selection of the company package. Optional follow-up modules (assembly, projects, planning, CRM, fixed assets,
/// warehouse, manufacturing, service) run only when they are selected in the setup. The selection is frozen with the scenario
/// modules and copied into the immutable run snapshot as a marker per module, so a captured run never changes its plan.
/// </summary>
codeunit 90486 "BCSF Module Selection"
{
  Access = Internal;

  /// <summary>Modules that add an executable follow-up process on top of the four required wholesale modules.</summary>
  procedure IsFollowUpModule(ModuleType: Enum "BCSF Module Type"): Boolean
  begin
    exit(ModuleType in [ModuleType::Warehouse, ModuleType::Manufacturing, ModuleType::Assembly, ModuleType::Projects,
      ModuleType::ServiceManagement, ModuleType::FixedAssets, ModuleType::CRM, ModuleType::Planning]);
  end;

  /// <summary>True when the scenario has this module enabled.</summary>
  procedure IsSelected(ScenarioId: Guid; ModuleType: Enum "BCSF Module Type"): Boolean
  var
    Selection: Record "BCSF Scenario Module";
  begin
    if not Selection.Get(ScenarioId, ModuleType) then
      exit(false);
    exit(Selection.Enabled);
  end;

  /// <summary>True when the pipe-separated additional module codes of the company request contain the module.</summary>
  procedure IsCodeSelected(AdditionalModules: Text; ModuleType: Enum "BCSF Module Type"): Boolean
  var
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    exit(StrPos('|' + AdditionalModules + '|', '|' + Policy.GetModuleCode(ModuleType) + '|') > 0);
  end;

  /// <summary>
  /// Snapshot marker check shared by all follow-up modules: the payment stage must be captured, the marker must be present
  /// and an unknown marker version stops the run instead of guessing.
  /// </summary>
  procedure MarkerEnabled(Context: JsonObject; Marker: Text): Boolean
  var
    Payments: Codeunit "BCSF Payment Processor";
    Token: JsonToken;
    Settings: JsonObject;
  begin
    if not Payments.Enabled(Context) then
      exit(false);
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    if not Settings.Get(Marker, Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(MarkerErr);
    exit(true);
  end;

  /// <summary>Optional modules of the purchase side: fixed assets, warehouse receipt and put-away, manufacturing.</summary>
  procedure RunForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; ParentId: Guid)
  var
    Movements: Codeunit "BCSFInventoryMovementProcessor";
    Assets: Codeunit "BCSF Asset Processor";
    Warehouse: Codeunit "BCSF Warehouse Processor";
    Production: Codeunit "BCSF Production Processor";
    Date: Date;
  begin
    Date := Movements.MovementDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    if Assets.Enabled(Context) then
      Assets.CreateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId);
    if Warehouse.Enabled(Context) then
      Warehouse.CreateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId);
    if Production.Enabled(Context) then
      Production.CreateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId);
  end;

  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header")
  var
    Movements: Codeunit "BCSFInventoryMovementProcessor";
    Assets: Codeunit "BCSF Asset Processor";
    Warehouse: Codeunit "BCSF Warehouse Processor";
    Production: Codeunit "BCSF Production Processor";
    Date: Date;
  begin
    Date := Movements.MovementDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    if Assets.Enabled(Context) then
      Assets.ValidateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, Invoice, Date);
    if Warehouse.Enabled(Context) then
      Warehouse.ValidateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, Invoice);
    if Production.Enabled(Context) then
      Production.ValidateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, Invoice, Date);
  end;

  /// <summary>Optional modules of the sales side: CRM opportunities and service items with service orders.</summary>
  procedure RunForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; ParentId: Guid)
  var
    Crm: Codeunit "BCSF CRM Processor";
    Service: Codeunit "BCSF Service Processor";
  begin
    if Crm.Enabled(Context) then
      Crm.RunForSalesInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, ParentId);
    if Service.Enabled(Context) then
      Service.RunForSalesInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, ParentId);
  end;

  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Crm: Codeunit "BCSF CRM Processor";
    Service: Codeunit "BCSF Service Processor";
  begin
    if Crm.Enabled(Context) then
      Crm.ValidateForSalesInvoice(Context, RunId, NodeCode, LogicalKey, Invoice);
    if Service.Enabled(Context) then
      Service.ValidateForSalesInvoice(Context, RunId, NodeCode, LogicalKey, Invoice);
  end;

  var
    MarkerErr: Label 'A module setup marker of this run is not supported or was changed. Review the captured module setup; do not repeat an uncertain step.';
}
