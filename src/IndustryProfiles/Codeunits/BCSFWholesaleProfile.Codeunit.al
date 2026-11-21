namespace BCScenarioFactory.IndustryProfiles;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

codeunit 90153 "BCSF Wholesale Profile"
{
  Access = Internal;

  procedure Quantity(Size: Integer; Entity: Enum "BCSF Entity Type"): Integer
  var
    Factor: Integer;
  begin
    case Size of
      0: Factor := 1;
      1: Factor := 10;
      2: Factor := 100;
      else Error(SizeErr);
    end;
    case Entity of
      Entity::Customer: exit(20 * Factor);
      Entity::Vendor: exit(5 * Factor);
      Entity::Item: exit(40 * Factor);
      Entity::PurchaseOrder: exit(15 * Factor);
      Entity::SalesQuote: exit(5 * Factor);
      Entity::SalesOrder: exit(12 * Factor);
      Entity::SalesInvoice: exit(3 * Factor);
    end;
    Error(SizeErr);
  end;

  procedure CheckSelection(Size: Integer; Mode: Enum "BCSF Process Mode")
  var
    Setup: Record "BCSF Factory Setup";
    Entity: Enum "BCSF Entity Type";
    Ordinal: Integer;
  begin
    Quantity(Size, "BCSF Entity Type"::Item);
    if not (Mode in [Mode::SetupAndMasterData, Mode::UnpostedDocuments, Mode::PostedMovements, Mode::FollowUpProcesses]) then
      Error(PostingErr);
    if Setup.Get(Setup.GetSetupKey()) then
      foreach Ordinal in Entity.Ordinals() do begin
        Entity := "BCSF Entity Type".FromInteger(Ordinal);
        if Entity in [Entity::Customer, Entity::Vendor, Entity::Item, Entity::PurchaseOrder, Entity::SalesQuote, Entity::SalesOrder, Entity::SalesInvoice] then
          if Quantity(Size, Entity) > Setup."Maximum Records per Entity" then
            Error(LimitErr);
      end;
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateTemplate(Size: Integer; Mode: Enum "BCSF Process Mode"; Date: Date): Guid
  begin
    exit(CreateTemplateForId(CreateGuid(), Size, Mode, Date));
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateTemplateForId(ScenarioId: Guid; Size: Integer; Mode: Enum "BCSF Process Mode"; Date: Date): Guid
  var
    Setup: Record "BCSF Factory Setup";
    Scenario: Record "BCSF Scenario";
    Selection: Record "BCSF Scenario Module";
    Target: Record "BCSF Data Target";
    Policy: Codeunit "BCSF Scenario Policy";
    Entity: Enum "BCSF Entity Type";
    ModuleType: Enum "BCSF Module Type";
    Ordinal: Integer;
  begin
    CheckSelection(Size, Mode);
    Setup.Get(Setup.GetSetupKey());
    Setup.TestField("Company Initialized", true);
    Scenario.Init();
    if IsNullGuid(ScenarioId) then
      Error(SizeErr);
    Scenario."Scenario Id" := ScenarioId;
    Scenario.Description := WholesaleLbl;
    // Reuse the versioned trade assortment, partner catalog and immutable snapshot contract.
    Scenario."Profile Code" := 'TRADE';
    Scenario."Profile Version" := '4';
    Scenario."Usage Mode" := "BCSF Usage Mode"::Functional;
    Scenario."Process Mode" := Mode;
    Scenario.Seed := Setup."Default Seed";
    Scenario."Starting Date" := Date;
    Scenario."Ending Date" := Date;
    Scenario."Batch Size" := 3;
    if Setup."Default Batch Size" < 3 then
      Scenario."Batch Size" := Setup."Default Batch Size";
    Scenario."Data Language" := Setup."Default Data Language";
    Scenario."B2C Percent" := 0;
    Scenario.Insert(true);
    for Ordinal := 0 to 2 do begin
      case Ordinal of
        0: ModuleType := ModuleType::Sales;
        1: ModuleType := ModuleType::Purchasing;
        2: ModuleType := ModuleType::Inventory;
      end;
      Selection.Init();
      Selection."Scenario Id" := Scenario."Scenario Id";
      Selection.Module := ModuleType;
      Selection.Enabled := true;
      Selection.Insert(true);
    end;
    foreach Ordinal in Entity.Ordinals() do begin
      Entity := "BCSF Entity Type".FromInteger(Ordinal);
      if (Entity in [Entity::Customer, Entity::Vendor, Entity::Item]) or
        ((Mode <> Mode::SetupAndMasterData) and (Entity in [Entity::PurchaseOrder, Entity::SalesQuote, Entity::SalesOrder, Entity::SalesInvoice])) then begin
        Target.Init();
        Target."Scenario Id" := Scenario."Scenario Id";
        Target.Validate(Entity, Entity);
        Target.Quantity := Quantity(Size, Entity);
        Target."Process Mode" := "BCSF Process Mode"::SetupAndMasterData;
        if Policy.IsDocument(Entity) then begin
          Target."Process Mode" := Mode;
          if Mode = Mode::FollowUpProcesses then
            Target."Process Mode" := Mode::PostedMovements;
          if Entity = Entity::SalesQuote then
            Target."Process Mode" := Mode::UnpostedDocuments;
        end;
        Target."Unposted Percent" := 100;
        if (Mode.AsInteger() >= 2) and Policy.IsDocument(Entity) and (Entity <> Entity::SalesQuote) then begin
          case Entity of
            Entity::PurchaseOrder:
              begin
                Target."Posted Percent" := 60;
                Target."Partial Percent" := 20;
              end;
            Entity::SalesOrder:
              begin
                Target."Posted Percent" := 50;
                Target."Partial Percent" := 25;
              end;
            Entity::SalesInvoice: Target."Posted Percent" := 67;
          end;
          Target."Unposted Percent" := 100 - Target."Posted Percent" - Target."Partial Percent";
        end;
        Target.Insert(true);
      end;
    end;
    exit(Scenario."Scenario Id");
  end;

  var
    WholesaleLbl: Label 'Wholesale company';
    SizeErr: Label 'Select Small, Medium or Large for the supported wholesale package.';
    PostingErr: Label 'Select master data, unposted documents, posted documents or approved payments and application for wholesale.';
    LimitErr: Label 'This size exceeds the configured entity limit. Select a smaller size or review Factory Setup.';
}
