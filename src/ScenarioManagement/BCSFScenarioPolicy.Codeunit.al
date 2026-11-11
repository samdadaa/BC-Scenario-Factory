namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

codeunit 90143 "BCSF Scenario Policy"
{
  Access = Internal;

  procedure GetEntityModule(Entity: Enum "BCSF Entity Type"): Enum "BCSF Module Type"
  begin
    case Entity of
      "BCSF Entity Type"::Customer,
      "BCSF Entity Type"::SalesQuote,
      "BCSF Entity Type"::SalesOrder,
      "BCSF Entity Type"::SalesInvoice,
      "BCSF Entity Type"::SalesCreditMemo:
        exit("BCSF Module Type"::Sales);
      "BCSF Entity Type"::Vendor,
      "BCSF Entity Type"::PurchaseOrder,
      "BCSF Entity Type"::PurchaseInvoice,
      "BCSF Entity Type"::PurchaseCreditMemo:
        exit("BCSF Module Type"::Purchasing);
      "BCSF Entity Type"::Item:
        exit("BCSF Module Type"::Inventory);
    end;
    Error(EntityErr);
  end;

  procedure IsDocument(Entity: Enum "BCSF Entity Type"): Boolean
  begin
    GetEntityModule(Entity);
    exit(not (Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]));
  end;

  procedure CheckProcessMode(ProcessMode: Enum "BCSF Process Mode")
  begin
    if not (ProcessMode in ["BCSF Process Mode"::SetupAndMasterData, "BCSF Process Mode"::UnpostedDocuments,
      "BCSF Process Mode"::PostedMovements, "BCSF Process Mode"::FollowUpProcesses])
    then
      Error(ModeErr);
  end;

  procedure ValidateScenario(var Scenario: Record "BCSF Scenario")
  var
    FactorySetup: Record "BCSF Factory Setup";
    Target: Record "BCSF Data Target";
    SetupManagement: Codeunit "BCSF Setup Management";
    LanguageManagement: Codeunit "BCSF Language Mgt";
  begin
    if IsNullGuid(Scenario."Scenario Id") then
      Error(IdentityErr);
    Scenario.TestField(Description);
    CheckProcessMode(Scenario."Process Mode");
    if not (Scenario."Usage Mode" in ["BCSF Usage Mode"::Demo, "BCSF Usage Mode"::Training,
      "BCSF Usage Mode"::Functional, "BCSF Usage Mode"::Performance])
    then
      Error(ModeErr);
    LanguageManagement.ResolveDataLanguage(Scenario."Data Language");
    if (Scenario."Starting Date" = 0D) or (Scenario."Ending Date" < Scenario."Starting Date") then
      Error(DateErr);
    SetupManagement.GetSetup(FactorySetup);
    if (Scenario."Batch Size" <= 0) or (Scenario."Batch Size" > FactorySetup."Maximum Batch Size") then
      Error(BatchErr);
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if Target.FindSet() then
      repeat
        if Target."Process Mode".AsInteger() > Scenario."Process Mode".AsInteger() then
          Error(ScopeErr);
      until Target.Next() = 0;
  end;

  procedure ApplyEntityDefaults(var Target: Record "BCSF Data Target")
  var
    Scenario: Record "BCSF Scenario";
  begin
    Target.Module := GetEntityModule(Target.Entity);
    Scenario.Get(Target."Scenario Id");
    if IsDocument(Target.Entity) then begin
      Target."Process Mode" := Scenario."Process Mode";
      if (Target."Process Mode" = "BCSF Process Mode"::SetupAndMasterData) or (Target.Entity = "BCSF Entity Type"::SalesQuote) then
        Target."Process Mode" := "BCSF Process Mode"::UnpostedDocuments;
    end else
      Target."Process Mode" := "BCSF Process Mode"::SetupAndMasterData;
    Target."Unposted Percent" := 100;
    Target."Posted Percent" := 0;
    Target."Partial Percent" := 0;
  end;

  procedure ValidateTarget(var Target: Record "BCSF Data Target")
  var
    Scenario: Record "BCSF Scenario";
    ScenarioModule: Record "BCSF Scenario Module";
    FactorySetup: Record "BCSF Factory Setup";
    SetupManagement: Codeunit "BCSF Setup Management";
  begin
    Scenario.Get(Target."Scenario Id");
    Target.Module := GetEntityModule(Target.Entity);
    CheckProcessMode(Target."Process Mode");
    SetupManagement.GetSetup(FactorySetup);
    if (Target.Quantity < 0) or (Target.Quantity > FactorySetup."Maximum Records per Entity") then
      Error(QuantityErr);
    CheckPercent(Target."Unposted Percent");
    CheckPercent(Target."Posted Percent");
    CheckPercent(Target."Partial Percent");
    if Target."Unposted Percent" + Target."Posted Percent" + Target."Partial Percent" <> 100 then
      Error(PercentTotalErr);
    if Target.Quantity > 0 then begin
      if not ScenarioModule.Get(Target."Scenario Id", Target.Module) then
        Error(ModuleRequiredErr);
      ScenarioModule.TestField(Enabled, true);
      if Target."Process Mode".AsInteger() > Scenario."Process Mode".AsInteger() then
        Error(ScopeErr);
    end;
    if not IsDocument(Target.Entity) then begin
      if (Target."Process Mode" <> "BCSF Process Mode"::SetupAndMasterData) or
        (Target."Posted Percent" <> 0) or (Target."Partial Percent" <> 0)
      then
        Error(MasterDataErr);
      exit;
    end;
    if Target."Process Mode" = "BCSF Process Mode"::SetupAndMasterData then
      Error(DocumentModeErr);
    if Target."Process Mode" = "BCSF Process Mode"::UnpostedDocuments then
      if (Target."Posted Percent" <> 0) or (Target."Partial Percent" <> 0) then
        Error(DocumentModeErr);
    if Target.Entity = "BCSF Entity Type"::SalesQuote then
      if Target."Process Mode" <> "BCSF Process Mode"::UnpostedDocuments then
        Error(QuoteErr);
    if Target."Partial Percent" <> 0 then
      if not (Target.Entity in ["BCSF Entity Type"::SalesOrder, "BCSF Entity Type"::PurchaseOrder]) then
        Error(PartialErr);
  end;

  procedure ValidateModule(var ScenarioModule: Record "BCSF Scenario Module")
  var
    Scenario: Record "BCSF Scenario";
  begin
    Scenario.Get(ScenarioModule."Scenario Id");
    if not (ScenarioModule.Module in ["BCSF Module Type"::Sales, "BCSF Module Type"::Purchasing,
      "BCSF Module Type"::Inventory, "BCSF Module Type"::Finance, "BCSF Module Type"::Warehouse,
      "BCSF Module Type"::Manufacturing, "BCSF Module Type"::Assembly, "BCSF Module Type"::Projects,
      "BCSF Module Type"::ServiceManagement, "BCSF Module Type"::FixedAssets, "BCSF Module Type"::CRM, "BCSF Module Type"::Planning])
    then
      Error(ModuleErr);
    if not ScenarioModule.Enabled then
      CheckModuleRemoval(ScenarioModule);
  end;

  procedure CheckModuleRemoval(var ScenarioModule: Record "BCSF Scenario Module")
  var
    Target: Record "BCSF Data Target";
  begin
    Target.SetCurrentKey("Scenario Id", Module, Quantity);
    Target.SetRange("Scenario Id", ScenarioModule."Scenario Id");
    Target.SetRange(Module, ScenarioModule.Module);
    Target.SetFilter(Quantity, '>0');
    if not Target.IsEmpty() then
      Error(ModuleInUseErr);
  end;

  procedure GetDistribution(Target: Record "BCSF Data Target"; var Unposted: Integer; var Posted: Integer; var Partial: Integer)
  begin
    if not IsDocument(Target.Entity) then begin
      Unposted := 0;
      Posted := 0;
      Partial := 0;
      exit;
    end;
    Posted := Round(Target.Quantity * Target."Posted Percent" / 100, 1, '<');
    Partial := Round(Target.Quantity * Target."Partial Percent" / 100, 1, '<');
    Unposted := Target.Quantity - Posted - Partial;
  end;

  procedure BalanceTargetShare(var Target: Record "BCSF Data Target"; ChangedFieldNo: Integer)
  begin
    case ChangedFieldNo of
      Target.FieldNo("Unposted Percent"):
        Target."Posted Percent" := 100 - Target."Unposted Percent" - Target."Partial Percent";
      Target.FieldNo("Posted Percent"), Target.FieldNo("Partial Percent"):
        Target."Unposted Percent" := 100 - Target."Posted Percent" - Target."Partial Percent";
    end;
    CheckPercent(Target."Unposted Percent");
    CheckPercent(Target."Posted Percent");
    CheckPercent(Target."Partial Percent");
  end;

  procedure GetPresetQuantity(Preset: Enum "BCSF Quantity Preset"): Integer
  begin
    case Preset of
      "BCSF Quantity Preset"::Small: exit(1000);
      "BCSF Quantity Preset"::Medium: exit(10000);
      "BCSF Quantity Preset"::Large: exit(50000);
      "BCSF Quantity Preset"::ExtraLarge: exit(100000);
    end;
    Error(QuantityErr);
  end;

  local procedure CheckPercent(Value: Decimal)
  begin
    if (Value < 0) or (Value > 100) or (Value <> Round(Value, 0.00001)) then
      Error(PercentErr);
  end;

  var
    EntityErr: Label 'Select a supported entity.';
    IdentityErr: Label 'Create the scenario with a new, nonempty identity.';
    ModeErr: Label 'Select a supported process and usage mode.';
    DateErr: Label 'Enter a starting date and an ending date on or after it.';
    BatchErr: Label 'Enter a positive batch size within the factory maximum.';
    ScopeErr: Label 'The entity process scope cannot exceed the scenario maximum. Adjust the targets first.';
    QuantityErr: Label 'Enter a nonnegative quantity within the factory limit for each entity.';
    PercentErr: Label 'Enter a percentage between 0 and 100 with at most five decimal places.';
    PercentTotalErr: Label 'The unposted, posted and partially processed shares must total 100.';
    ModuleRequiredErr: Label 'Select and enable the module before assigning a positive entity target.';
    MasterDataErr: Label 'Master data requires Setup and Master Data mode and no posted or partial document shares.';
    DocumentModeErr: Label 'Select a document mode consistent with the requested posted and partial shares.';
    QuoteErr: Label 'Sales quotes must remain unposted.';
    PartialErr: Label 'Partial processing shares are supported only for sales orders and purchase orders.';
    ModuleErr: Label 'Select a supported business module.';
    ModuleInUseErr: Label 'Set the module entity targets to zero before disabling or removing the module.';
}
