namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

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

  procedure IsPartnerTemplate(Scenario: Record "BCSF Scenario"): Boolean
  var
    Target: Record "BCSF Data Target";
    HasTarget: Boolean;
  begin
    if Scenario.Archived or (Scenario."Process Mode" <> "BCSF Process Mode"::SetupAndMasterData) then
      exit(false);
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    Target.SetFilter(Quantity, '>0');
    if Target.FindSet() then
      repeat
        HasTarget := true;
        if not (Target.Entity in ["BCSF Entity Type"::Customer, "BCSF Entity Type"::Vendor, "BCSF Entity Type"::Item]) or
          (Target."Process Mode" <> "BCSF Process Mode"::SetupAndMasterData) then
          exit(false);
      until Target.Next() = 0;
    exit(HasTarget);
  end;

  procedure RemoveSelection(var Selection: Record "BCSF Scenario")
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

  procedure CreateScenario(): Guid
  var
    Scenario: Record "BCSF Scenario";
    FactorySetup: Record "BCSF Factory Setup";
    SetupManagement: Codeunit "BCSF Setup Management";
  begin
    SetupManagement.GetSetup(FactorySetup);
    Scenario.Init();
    Scenario."Scenario Id" := CreateGuid();
    Scenario.Description := NewScenarioLbl;
    Scenario."Usage Mode" := FactorySetup."Default Usage Mode";
    Scenario."Process Mode" := FactorySetup."Default Process Mode";
    Scenario.Seed := FactorySetup."Default Seed";
    Scenario."Batch Size" := FactorySetup."Default Batch Size";
    Scenario."Data Language" := FactorySetup."Default Data Language";
    Scenario."Starting Date" := WorkDate();
    Scenario."Ending Date" := WorkDate();
    Scenario.Insert(true);
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
    RemoveQst: Label 'Delete %1 unused templates and archive %2 templates with captured runs? Used templates cannot be deleted because their run history must remain. Active jobs and results are retained. The classification is checked again before changing data.', Comment = '%1 = unused count, %2 = used count';
    RestoreQst: Label 'Restore the selected archived templates for new runs?';
    NewScenarioLbl: Label 'New Scenario';
    CopyScenarioLbl: Label 'Copy of %1', Comment = '%1 = source scenario description';
    TemporaryErr: Label 'Frozen configuration can only be loaded into temporary display records.';
}
