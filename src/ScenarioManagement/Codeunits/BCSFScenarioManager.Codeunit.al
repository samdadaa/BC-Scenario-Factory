namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using BCScenarioFactory.ModuleRegistry;

codeunit 90130 "BCSF Scenario Manager"
{
  Access = Internal;
  Permissions = tabledata "BCSF Scenario" = D;

  procedure GetDisplayName(Scenario: Record "BCSF Scenario"): Text
  var
    Name: Text;
  begin
    Name := Scenario.Description;
    OnGetDisplayName(Scenario, Name);
    exit(Name);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnGetDisplayName(Scenario: Record "BCSF Scenario"; var Name: Text)
  begin
  end;

  procedure HasSalesPostingApproval(RunId: Guid; NodeCode: Code[30]): Boolean
  var
    Step: Record "BCSF Run Step";
    Contract: Codeunit "BCSF Contract JSON";
    Context: JsonObject;
    Token: JsonToken;
  begin
    if not Step.Get(RunId, NodeCode) then
      exit(false);
    if (Step."Generator Version" <> '1') or (Step."Contract Version" <> 1) or
      (Step."Process Mode" <> "BCSF Process Mode"::PostedMovements) then
      exit(false);
    ReadSnapshot(RunId, Context);
    case NodeCode of
      'SALES.ORDER', 'SALES.INVOICE':
        begin
          if (Step."Generator Code" <> 'SALES.DOCUMENT') or not Context.Get('salesSetup', Token) then
            exit(false);
          exit(((Contract.GetInteger(Token.AsObject(), 'version') in [1, 3]) or
            ((Contract.GetInteger(Token.AsObject(), 'version') = 4) and Context.Contains('masterDataSource'))) and
            Contract.GetBoolean(Token.AsObject(), 'postingApproved'));
        end;
      'PURCHASE.ORDER':
        begin
          if (Step."Generator Code" <> 'PURCHASE.DOCUMENT') or not Context.Get('purchaseSetup', Token) then
            exit(false);
          exit((Contract.GetInteger(Token.AsObject(), 'version') = 2) and Contract.GetBoolean(Token.AsObject(), 'postingApproved'));
        end;
    end;
    exit(false);
  end;

  procedure SupportsTarget(Target: Record "BCSF Data Target"): Boolean
  var
    TempCapability: Record "BCSF Generator Registry" temporary;
    Registry: Codeunit "BCSF Generator Registry Mgt";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    if not Registry.SelectForTarget(Policy.GetEntityCode(Target.Entity), Target."Process Mode", false, TempCapability) then
      exit(false);
    exit(TempCapability."Module Code" = Policy.GetModuleCode(Target.Module));
  end;

  procedure IsPartnerTemplate(Scenario: Record "BCSF Scenario"): Boolean
  var
    Target: Record "BCSF Data Target";
    HasTarget: Boolean;
  begin
    if Scenario.Archived then
      exit(false);
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if Target.FindSet() then
      repeat
        HasTarget := true;
        if not SupportsTarget(Target) then
          exit(false);
      until Target.Next() = 0;
    exit(HasTarget);
  end;

  procedure RequireExecutableTargets(Scenario: Record "BCSF Scenario")
  var
    Target: Record "BCSF Data Target";
    Module: Record "BCSF Scenario Module";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    Scenario.TestField(Archived, false);
    Scenario.TestField("Profile Code");
    Scenario.TestField("Profile Version");
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if not Target.FindSet() then
      Error(NoTargetsErr);
    repeat
      if not SupportsTarget(Target) then
        Error(UnsupportedTargetErr, Format(Target.Entity), Format(Target."Process Mode"));
      Policy.ValidateTarget(Target);
      Module.Get(Scenario."Scenario Id", Target.Module);
      Module.TestField(Enabled, true);
    until Target.Next() = 0;
  end;

  procedure DescribeAvailability(Scenario: Record "BCSF Scenario"): Text
  var
    Target: Record "BCSF Data Target";
    HasSales: Boolean;
    HasItems: Boolean;
  begin
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if Target.IsEmpty() then
      exit(NoTargetsLbl);
    if not IsPartnerTemplate(Scenario) then
      exit(PlanningLbl);
    if Target.FindSet() then
      repeat
        HasSales := HasSales or (Target.Entity in ["BCSF Entity Type"::SalesQuote, "BCSF Entity Type"::SalesBlanketOrder, "BCSF Entity Type"::SalesOrder, "BCSF Entity Type"::SalesInvoice]);
        HasItems := HasItems or (Target.Entity = "BCSF Entity Type"::Item);
      until Target.Next() = 0;
    if HasSales then
      exit(SalesLbl);
    if HasItems then
      exit(ItemsLbl);
    exit(PartnersLbl);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ChangeProcessScope(ScenarioId: Guid; NewScope: Enum "BCSF Process Mode")
  var
    Scenario: Record "BCSF Scenario";
    Target: Record "BCSF Data Target";
    Policy: Codeunit "BCSF Scenario Policy";
    TargetScope: Enum "BCSF Process Mode";
    PreviousScope: Enum "BCSF Process Mode";
  begin
    Scenario.LockTable();
    Scenario.Get(ScenarioId);
    Policy.CheckProcessMode(NewScope);
    PreviousScope := Scenario."Process Mode";
    if PreviousScope = NewScope then
      exit;
    Target.SetRange("Scenario Id", ScenarioId);
    if NewScope = NewScope::SetupAndMasterData then
      if Target.FindSet() then
        repeat
          if Policy.IsDocument(Target.Entity) and (Target.Quantity > 0) then
            Error(MasterScopeErr);
        until Target.Next() = 0;
    // Raising the ceiling precedes child validation; lowering follows it.
    if NewScope.AsInteger() > PreviousScope.AsInteger() then begin
      Scenario."Process Mode" := NewScope;
      Scenario."Sales Posting Approved" := false;
      Scenario."Purchase Posting Approved" := false;
      Scenario."Payment Posting Approved" := false;
      Scenario.Modify(true);
    end;
    if NewScope.AsInteger() >= NewScope::PostedMovements.AsInteger() then
      TargetScope := TargetScope::PostedMovements
    else
      TargetScope := TargetScope::UnpostedDocuments;
    if Target.FindSet(true) then
      repeat
        if Policy.IsDocument(Target.Entity) and not (Target.Entity in ["BCSF Entity Type"::SalesQuote, "BCSF Entity Type"::SalesBlanketOrder]) then
          if Target."Process Mode" <> TargetScope then begin
            Target."Process Mode" := TargetScope;
            Policy.ApplyDocumentModeDefaults(Target);
            Target.Modify(true);
          end;
      until Target.Next() = 0;
    Scenario.Get(ScenarioId);
    Scenario."Process Mode" := NewScope;
    Scenario."Sales Posting Approved" := false;
    Scenario."Purchase Posting Approved" := false;
    Scenario."Payment Posting Approved" := false;
    Scenario.Modify(true);
  end;

  procedure RemoveSelection(var Selection: Record "BCSF Scenario"): Boolean
  var
    Header: Record "BCSF Run Header";
    RemoveCount: Integer;
    ArchiveCount: Integer;
  begin
    Header.SecurityFiltering(SecurityFilter::Disallowed);
    if Selection.FindSet() then
      repeat
        Header.SetRange("Scenario Id", Selection."Scenario Id");
        if Header.IsEmpty() then
          RemoveCount += 1
        else
          ArchiveCount += 1;
      until Selection.Next() = 0;
    if RemoveCount + ArchiveCount = 0 then
      exit;
    if not Confirm(RemoveQst, false, RemoveCount, ArchiveCount) then
      exit;
    RemoveConfirmed(Selection);
    exit(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure RemoveConfirmed(var Selection: Record "BCSF Scenario")
  var
    Scenario: Record "BCSF Scenario";
    Header: Record "BCSF Run Header";
  begin
    Scenario.LockTable();
    Header.SecurityFiltering(SecurityFilter::Disallowed);
    if Selection.FindSet() then
      repeat
        Scenario.Get(Selection."Scenario Id");
        Header.SetRange("Scenario Id", Scenario."Scenario Id");
        // Snapshot creation holds this same parent lock; never delete a concurrently used template.
        if Header.IsEmpty() then
          Scenario.Delete(true)
        else begin
          Scenario.Archived := true;
          Scenario.Modify(true);
        end;
      until Selection.Next() = 0;
  end;

  procedure RestoreSelection(var Selection: Record "BCSF Scenario")
  var
    Scenario: Record "BCSF Scenario";
  begin
    if not Confirm(RestoreQst, false) then
      exit;
    Scenario.LockTable();
    if Selection.FindSet() then
      repeat
        Scenario.Get(Selection."Scenario Id");
        Scenario.Archived := false;
        Scenario.Modify(true);
      until Selection.Next() = 0;
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateScenario(): Guid
  var
    Scenario: Record "BCSF Scenario";
    FactorySetup: Record "BCSF Factory Setup";
    Module: Record "BCSF Scenario Module";
    Target: Record "BCSF Data Target";
    SetupManagement: Codeunit "BCSF Setup Management";
  begin
    SetupManagement.GetSetup(FactorySetup);
    Scenario.Init();
    Scenario."Scenario Id" := CreateGuid();
    Scenario.Description := NewScenarioLbl;
    Scenario."Profile Code" := 'GENERAL';
    Scenario."Profile Version" := '1';
    Scenario."Usage Mode" := FactorySetup."Default Usage Mode";
    Scenario."Process Mode" := FactorySetup."Default Process Mode";
    Scenario.Seed := FactorySetup."Default Seed";
    Scenario."Batch Size" := FactorySetup."Default Batch Size";
    Scenario."Data Language" := FactorySetup."Default Data Language";
    Scenario."Starting Date" := WorkDate();
    Scenario."Ending Date" := WorkDate();
    Scenario.Insert(true);
    Module.Init();
    Module."Scenario Id" := Scenario."Scenario Id";
    Module.Module := "BCSF Module Type"::Sales;
    Module.Enabled := true;
    Module.Insert(true);
    Target.Init();
    Target."Scenario Id" := Scenario."Scenario Id";
    Target.Validate(Entity, "BCSF Entity Type"::Customer);
    Target.Quantity := 1;
    Target.Insert(true);
    exit(Scenario."Scenario Id");
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CopyScenario(SourceId: Guid): Guid
  var
    Source: Record "BCSF Scenario";
    Copy: Record "BCSF Scenario";
    SourceModule: Record "BCSF Scenario Module";
    CopyModule: Record "BCSF Scenario Module";
    SourceTarget: Record "BCSF Data Target";
    CopyTarget: Record "BCSF Data Target";
  begin
    Source.LockTable();
    Source.Get(SourceId);
    Copy.Init();
    Copy.TransferFields(Source, false);
    Copy."Sales Posting Approved" := false;
    Copy."Purchase Posting Approved" := false;
    Copy."Payment Posting Approved" := false;
    Copy."Scenario Id" := CreateGuid();
    Copy.Archived := false;
    Copy.Description := CopyStr(StrSubstNo(CopyScenarioLbl, Source.Description), 1, MaxStrLen(Copy.Description));
    Copy.Insert(true);
    SourceModule.SetRange("Scenario Id", SourceId);
    if SourceModule.FindSet() then
      repeat
        CopyModule.Init();
        CopyModule.TransferFields(SourceModule);
        CopyModule."Scenario Id" := Copy."Scenario Id";
        CopyModule.Insert(true);
      until SourceModule.Next() = 0;
    SourceTarget.SetRange("Scenario Id", SourceId);
    if SourceTarget.FindSet() then
      repeat
        CopyTarget.Init();
        CopyTarget.TransferFields(SourceTarget);
        CopyTarget."Scenario Id" := Copy."Scenario Id";
        CopyTarget.Insert(true);
      until SourceTarget.Next() = 0;
    exit(Copy."Scenario Id");
  end;

  procedure ApplyPreset(ScenarioId: Guid; Entity: Enum "BCSF Entity Type"; Preset: Enum "BCSF Quantity Preset")
  var
    Target: Record "BCSF Data Target";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    Target.Get(ScenarioId, Entity);
    Target.Quantity := Policy.GetPresetQuantity(Preset);
    Target.Modify(true);
  end;

  /// <summary>Minimum reusable partner references, not a claim about generated records, ledger entries or verified prerequisites.</summary>
  procedure GetMinimumReferences(ScenarioId: Guid; var MinimumCustomers: Integer; var MinimumVendors: Integer)
  var
    Target: Record "BCSF Data Target";
    Policy: Codeunit "BCSF Scenario Policy";
  begin
    MinimumCustomers := 0;
    MinimumVendors := 0;
    Target.SetRange("Scenario Id", ScenarioId);
    Target.SetFilter(Quantity, '>0');
    if Target.FindSet() then
      repeat
        if Policy.IsDocument(Target.Entity) then
          case Target.Module of
            "BCSF Module Type"::Sales: MinimumCustomers := 1;
            "BCSF Module Type"::Purchasing: MinimumVendors := 1;
          end;
      until Target.Next() = 0;
  end;

  procedure ReadSnapshot(RunId: Guid; var Payload: JsonObject)
  var
    Header: Record "BCSF Run Header";
    Snapshot: Record "BCSF Run Snapshot";
  begin
    Header.Get(RunId);
    Header.TestField("Schema Version", 1);
    Snapshot.Get(RunId);
    Snapshot.TestField("Schema Version", 1);
    Snapshot.CalcFields(Payload);
    Snapshot.ReadPayload(Payload);
  end;

  procedure LoadFrozenTargets(RunId: Guid; var TempTarget: Record "BCSF Data Target" temporary)
  var
    Payload: JsonObject;
    Targets: JsonArray;
    Token: JsonToken;
    Item: JsonObject;
    Value: JsonToken;
    Index: Integer;
  begin
    if not TempTarget.IsTemporary() then
      Error(TemporaryErr);
    TempTarget.Reset();
    TempTarget.DeleteAll();
    ReadSnapshot(RunId, Payload);
    Payload.Get('targets', Token);
    Targets := Token.AsArray();
    for Index := 0 to Targets.Count() - 1 do begin
      Targets.Get(Index, Token);
      Item := Token.AsObject();
      TempTarget.Init();
      TempTarget."Scenario Id" := RunId;
      Item.Get('entity', Value);
      TempTarget.Entity := "BCSF Entity Type".FromInteger(Value.AsValue().AsInteger());
      Item.Get('module', Value);
      TempTarget.Module := "BCSF Module Type".FromInteger(Value.AsValue().AsInteger());
      Item.Get('quantity', Value);
      TempTarget.Quantity := Value.AsValue().AsInteger();
      Item.Get('processMode', Value);
      TempTarget."Process Mode" := "BCSF Process Mode".FromInteger(Value.AsValue().AsInteger());
      Item.Get('unpostedPercent', Value);
      TempTarget."Unposted Percent" := Value.AsValue().AsDecimal();
      Item.Get('postedPercent', Value);
      TempTarget."Posted Percent" := Value.AsValue().AsDecimal();
      Item.Get('partialPercent', Value);
      TempTarget."Partial Percent" := Value.AsValue().AsDecimal();
      TempTarget.Insert(false);
    end;
  end;

  procedure LoadFrozenModules(RunId: Guid; var TempModule: Record "BCSF Scenario Module" temporary)
  var
    Payload: JsonObject;
    Modules: JsonArray;
    Token: JsonToken;
    Item: JsonObject;
    Value: JsonToken;
    Index: Integer;
  begin
    if not TempModule.IsTemporary() then
      Error(TemporaryErr);
    TempModule.Reset();
    TempModule.DeleteAll();
    ReadSnapshot(RunId, Payload);
    Payload.Get('modules', Token);
    Modules := Token.AsArray();
    for Index := 0 to Modules.Count() - 1 do begin
      Modules.Get(Index, Token);
      Item := Token.AsObject();
      TempModule.Init();
      TempModule."Scenario Id" := RunId;
      Item.Get('module', Value);
      TempModule.Module := "BCSF Module Type".FromInteger(Value.AsValue().AsInteger());
      Item.Get('enabled', Value);
      TempModule.Enabled := Value.AsValue().AsBoolean();
      TempModule.Insert(false);
    end;
  end;

  procedure GetScenarioLanguagePreview(Scenario: Record "BCSF Scenario"; var CustomerName: Text[100]; var VendorName: Text[100]; var ItemName: Text[100])
  var
    Languages: Codeunit "BCSF Language Mgt";
    Context: JsonObject;
    Settings: JsonObject;
  begin
    // Read-only name preview; no snapshot, standard record or execution identity is persisted.
    Context.Add('schemaVersion', 1);
    Context.Add('runId', Format(Scenario."Scenario Id"));
    Context.Add('companyName', CompanyName());
    Context.Add('dataLanguage', Languages.ResolveDataLanguage(Scenario."Data Language").AsInteger());
    Context.Add('seed', Scenario.Seed);
    Context.Add('processMode', Scenario."Process Mode".AsInteger());
    Context.Add('nameCatalogVersion', 1);
    Context.Add('seedEngineVersion', 1);
    Context.Add('batchSize', 1);
    Context.Add('maximumBatchSize', 1);
    Context.Add('maximumRecordsPerEntity', 1);
    Context.Add('profileCode', Scenario."Profile Code");
    Context.Add('profileVersion', Scenario."Profile Version");
    Settings.Add('countryCode', Scenario."Partner Country Code");
    Settings.Add('b2cPercent', Scenario."B2C Percent");
    Context.Add('partnerSetup', Settings);
    OnPreviewPartnerNames(Context, CustomerName, VendorName, ItemName);
    OnPreviewItemName(Context, ItemName);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnPreviewPartnerNames(Context: JsonObject; var CustomerName: Text[100]; var VendorName: Text[100]; var ItemName: Text[100])
  begin
  end;

  [IntegrationEvent(false, false)]
  local procedure OnPreviewItemName(Context: JsonObject; var ItemName: Text[100])
  begin
  end;

  procedure GetRunLanguagePreview(RunId: Guid; var CustomerName: Text[100]; var VendorName: Text[100]; var ItemName: Text[100])
  var
    Header: Record "BCSF Run Header";
    Languages: Codeunit "BCSF Language Mgt";
    Payload: JsonObject;
    Token: JsonToken;
    Rules: JsonObject;
    CatalogVersion: Integer;
  begin
    Header.Get(RunId);
    ReadSnapshot(RunId, Payload);
    if Payload.Get('syntheticRules', Token) then begin
      Rules := Token.AsObject();
      Rules.Get('version', Token);
      if Token.AsValue().AsInteger() = 2 then begin
        OnPreviewPartnerNames(Payload, CustomerName, VendorName, ItemName);
        OnPreviewItemName(Payload, ItemName);
        exit;
      end;
    end;
    Payload.Get('nameCatalogVersion', Token);
    CatalogVersion := Token.AsValue().AsInteger();
    CustomerName := Languages.GetSyntheticName('CUSTOMER', 1, Header."Data Language", CatalogVersion);
    VendorName := Languages.GetSyntheticName('VENDOR', 1, Header."Data Language", CatalogVersion);
    ItemName := Languages.GetSyntheticName('ITEM', 1, Header."Data Language", CatalogVersion);
  end;

  var
    NoTargetsErr: Label 'Enter at least one positive entity target before running this template.';
    UnsupportedTargetErr: Label 'No executable generator is available for %1 in mode %2. Choose a supported target or mode; the maximum process scope alone does not request additional processes.', Comment = '%1 = entity, %2 = target process mode';
    MasterScopeErr: Label 'Set document quantities to zero before reducing the maximum scope to setup and master data.';
    NoTargetsLbl: Label 'Enter entity targets';
    PlanningLbl: Label 'Planning Only';
    SalesLbl: Label 'Sales: setup check required';
    ItemsLbl: Label 'Items: setup check required';
    PartnersLbl: Label 'Partner Master Data';
    RemoveQst: Label 'Delete %1 unused templates and archive %2 templates with captured runs? Used templates cannot be deleted because their run history must remain. Active jobs and results are retained. The classification is checked again before changing data.', Comment = '%1 = unused count, %2 = used count';
    RestoreQst: Label 'Restore the selected archived templates for new runs?';
    NewScenarioLbl: Label 'New Scenario';
    CopyScenarioLbl: Label 'Copy of %1', Comment = '%1 = source scenario description';
    TemporaryErr: Label 'Frozen configuration can only be loaded into temporary display records.';
}
