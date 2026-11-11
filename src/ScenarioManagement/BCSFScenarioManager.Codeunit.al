namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;

codeunit 90130 "BCSF Scenario Manager"
{
  Access = Internal;

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

  procedure GetRunLanguagePreview(RunId: Guid; var CustomerName: Text[100]; var VendorName: Text[100]; var ItemName: Text[100])
  var
    Header: Record "BCSF Run Header";
    Languages: Codeunit "BCSF Language Mgt";
    Payload: JsonObject;
    Token: JsonToken;
    CatalogVersion: Integer;
  begin
    Header.Get(RunId);
    ReadSnapshot(RunId, Payload);
    Payload.Get('nameCatalogVersion', Token);
    CatalogVersion := Token.AsValue().AsInteger();
    CustomerName := Languages.GetSyntheticName('CUSTOMER', 1, Header."Data Language", CatalogVersion);
    VendorName := Languages.GetSyntheticName('VENDOR', 1, Header."Data Language", CatalogVersion);
    ItemName := Languages.GetSyntheticName('ITEM', 1, Header."Data Language", CatalogVersion);
  end;

  var
    NewScenarioLbl: Label 'New Scenario';
    CopyScenarioLbl: Label 'Copy of %1', Comment = '%1 = source scenario description';
    TemporaryErr: Label 'Frozen configuration can only be loaded into temporary display records.';
}
