namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ModuleRegistry;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;

codeunit 90475 "BCSF Inventory Generator" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  begin
    Capabilities.Init();
    Capabilities."Generator Code" := 'ITEM';
    Capabilities."Entity Code" := 'ITEM';
    Capabilities."Module Code" := 'INVENTORY';
    Capabilities.Name := NameLbl;
    Capabilities.Version := '1';
    Capabilities."Contract Version" := 1;
    Capabilities."Minimum Mode" := "BCSF Process Mode"::SetupAndMasterData;
    Capabilities."Maximum Mode" := "BCSF Process Mode"::SetupAndMasterData;
    Capabilities."Maximum Batch Size" := 1000;
    Capabilities."Contract Probe" := false;
    Capabilities.Insert();
  end;

  procedure CheckPrerequisites(Context: JsonObject; Target: JsonObject; var Findings: JsonArray)
  var
    Finding: JsonObject;
  begin
    Clear(Findings);
    if not CheckSetup(Context, Target) then begin
      Finding.Add('code', 'ITEM.SETUP');
      Finding.Add('message', GetLastErrorText());
      ClearLastError();
      Findings.Add(Finding);
    end;
  end;

  [TryFunction]
  local procedure CheckSetup(Context: JsonObject; Target: JsonObject)
  var
    Setup: Codeunit "BCSF Item Setup";
  begin
    Setup.CheckSetup(Context, Target);
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  var
    Setup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Requirement: JsonObject;
  begin
    Clear(Dependencies);
    if not Context.Contains('itemSetup') then
      exit;
    if Contract.GetBoolean(Setup.ReadSettings(Context), 'generatedVendors') then begin
      Requirement.Add('entityCode', 'VENDOR');
      Requirement.Add('moduleCode', 'PURCHASING');
      Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
      Requirement.Add('minimumMode', 0);
      Requirement.Add('maximumMode', 0);
      Dependencies.Add(Requirement);
    end;
    if Setup.Quantity(Context, "BCSF Entity Type"::Customer) > 0 then begin
      Clear(Requirement);
      Requirement.Add('entityCode', 'CUSTOMER');
      Requirement.Add('moduleCode', 'SALES');
      Requirement.Add('kind', "BCSF Dependency Kind"::Required.AsInteger());
      Requirement.Add('minimumMode', 0);
      Requirement.Add('maximumMode', 0);
      Dependencies.Add(Requirement);
    end;
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Rules: Codeunit "BCSF Partner Rules";
  begin
    Rules.Plan('ITEM', Context, Target, FirstKey, MaximumBatches, Batches);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Entry: Record "BCSF Generated Record";
    Rules: Codeunit "BCSF Partner Rules";
    Setup: Codeunit "BCSF Item Setup";
    Masters: Codeunit "BCSF Item Masters";
    Relations: Codeunit "BCSF Item Relations";
    Contract: Codeunit "BCSF Contract JSON";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    FirstKey: Integer;
    LastKey: Integer;
  begin
    // Reuse the unchanged snapshot and actual job/session/batch ownership contract.
    Rules.EnsureExecution(Context, Target, Batch, 'ITEM', RunId, BatchId);
    Setup.CheckSetup(Context, Target);
    Setup.ResolveVendor(Context, 1);
    Setup.ResolveVendor(Context, 2);
    FirstKey := Contract.GetInteger(Batch, 'firstKey');
    LastKey := Contract.GetInteger(Batch, 'lastKey');
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'ITEM');
    Entry.SetRange("Logical Key", FirstKey, LastKey);
    if not Entry.IsEmpty() then
      Error(ReplayErr);
    if FirstKey = 1 then
      Masters.CreateCategories(Context, RunId, BatchId);
    for LogicalKey := FirstKey to LastKey do begin
      CreateItem(Context, RunId, BatchId, LogicalKey);
      Relations.Create(Context, RunId, BatchId, LogicalKey);
    end;
    Clear(Result);
    Result.Add('generatorCode', 'ITEM');
    Result.Add('runId', Contract.GetText(Context, 'runId'));
    Result.Add('batchKey', Contract.GetText(Batch, 'batchKey'));
    Result.Add('processedUnits', LastKey - FirstKey + 1);
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    Result.Add('createdRecords', Entry.Count());
    Result.Add('dataLanguage', Contract.GetInteger(Context, 'dataLanguage'));
    Result.Add('completed', true);
    Result.Add('contractProbe', false);
  end;

  local procedure CreateItem(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer)
  var
    Item: Record Item;
    Measure: Record "Item Unit of Measure";
    Catalog: Codeunit "BCSF Item Catalog";
    Setup: Codeunit "BCSF Item Setup";
    Masters: Codeunit "BCSF Item Masters";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Numbers: Codeunit "No. Series";
    Rules: Codeunit "BCSF Partner Rules";
    Settings: JsonObject;
    Values: JsonObject;
    BaseDate: Date;
    ParentId: Guid;
    NoParent: Guid;
    German: Boolean;
  begin
    Settings := Setup.ReadSettings(Context);
    Values := Catalog.BuildValues(Context, LogicalKey);
    Evaluate(BaseDate, Contract.GetText(Context, 'startingDate'), 9);
    Item.Init();
    Item."No. Series" := CopyStr(Contract.GetCode(Settings, 'series'), 1, MaxStrLen(Item."No. Series"));
    Item."No." := Numbers.GetNextNo(Item."No. Series", BaseDate);
    Item.Validate(Type, Item.Type::Inventory);
    Item.Validate(Description, CopyStr(Contract.GetText(Values, 'description'), 1, MaxStrLen(Item.Description)));
    Item.Validate("Costing Method", Item."Costing Method"::FIFO);
    Item.Validate("Gen. Prod. Posting Group", CopyStr(Contract.GetCode(Settings, 'genProduct'), 1, MaxStrLen(Item."Gen. Prod. Posting Group")));
    Item.Validate("VAT Prod. Posting Group", CopyStr(Contract.GetCode(Settings, 'vatProduct'), 1, MaxStrLen(Item."VAT Prod. Posting Group")));
    Item.Validate("Inventory Posting Group", CopyStr(Contract.GetCode(Settings, 'inventoryGroup'), 1, MaxStrLen(Item."Inventory Posting Group")));
    Item.Insert(true);
    ParentId := Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'ITEM', BatchId, Item.RecordId(), NoParent);
    Item.Validate("Base Unit of Measure", CopyStr(Contract.GetCode(Settings, 'baseUnit'), 1, MaxStrLen(Item."Base Unit of Measure")));
    Measure.Get(Item."No.", Item."Base Unit of Measure");
    Measure.TestField("Qty. per Unit of Measure", 1);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'BASE-UOM', BatchId, Measure.RecordId(), ParentId);
    Measure.Init();
    Measure.Validate("Item No.", Item."No.");
    Measure.Validate(Code, CopyStr(Contract.GetCode(Settings, 'packUnit'), 1, MaxStrLen(Measure.Code)));
    Measure.Validate("Qty. per Unit of Measure", Contract.GetInteger(Values, 'packQuantity'));
    Measure.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'PACK-UOM', BatchId, Measure.RecordId(), ParentId);
    Item.Validate("Purch. Unit of Measure", Measure.Code);
    Item.Validate("Sales Unit of Measure", Item."Base Unit of Measure");
    Item.Validate("Unit Cost", Rules.GetDecimal(Values, 'cost'));
    Item.Validate("Unit Price", Rules.GetDecimal(Values, 'price'));
    Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
    if Values.Contains('reorderPoint') then
      Item.Validate("Reorder Point", Contract.GetInteger(Values, 'reorderPoint'))
    else
      Item.Validate("Reorder Point", 12);
    Item.Validate("Reorder Quantity", Contract.GetInteger(Values, 'packQuantity'));
    Item.Validate("Vendor No.", Setup.PrimaryVendor(Context, LogicalKey));
    Item.Validate("Item Category Code", Catalog.CategoryCode(RunId, CopyStr(Contract.GetCode(Values, 'category'), 1, 10)));
    Item.Modify(true);
    Masters.RegisterInherited(RunId, BatchId, LogicalKey, Item, ParentId);
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    // In TRADE v5 the material is an article-specific attribute instead of a
    // category default, because multiple materials share the same category.
    if (Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') in ['5', '6']) then
      Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
        'Material', Contract.GetText(Values, 'material'), 'MATERIAL', ParentId);
    Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
      Catalog.Choose(German, 'Durchmesser', 'Diameter'), Contract.GetText(Values, 'diameter'), 'DIAMETER', ParentId);
    if Contract.GetInteger(Values, 'family') <> 5 then
      Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
        Catalog.Choose(German, 'Gewinde', 'Thread'), Contract.GetText(Values, 'thread'), 'THREAD', ParentId);
    if Values.Contains('dimension') then begin
      if Contract.GetInteger(Values, 'family') = 5 then
        Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
          Catalog.Choose(German, 'Dicke', 'Thickness'), Contract.GetText(Values, 'dimension'), 'DIMENSION', ParentId)
      else
        Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
          Catalog.Choose(German, 'Baulänge', 'Length'), Contract.GetText(Values, 'dimension'), 'DIMENSION', ParentId);
      Masters.Assign(Context, RunId, BatchId, LogicalKey, Database::Item, Item."No.",
        Catalog.Choose(German, 'Druckstufe', 'Pressure rating'), Contract.GetText(Values, 'rating'), 'RATING', ParentId);
    end;
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Entry: Record "BCSF Generated Record";
    Item: Record Item;
    Measure: Record "Item Unit of Measure";
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
    Setup: Codeunit "BCSF Item Setup";
    Masters: Codeunit "BCSF Item Masters";
    Relations: Codeunit "BCSF Item Relations";
    Rules: Codeunit "BCSF Partner Rules";
    Values: JsonObject;
    Settings: JsonObject;
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    German: Boolean;
  begin
    Clear(Findings);
    Contract.CheckBatch(Context, Target, Batch);
    Settings := Setup.ReadSettings(Context);
    Evaluate(RunId, Contract.GetText(Context, 'runId'));
    Evaluate(BatchId, Contract.GetText(Context, 'batchId'));
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    Masters.ValidateCategories(Context, RunId);
    if (Contract.GetInteger(Result, 'processedUnits') <> Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1) or
      (Contract.GetText(Result, 'generatorCode') <> 'ITEM') or not Contract.GetBoolean(Result, 'completed') or Contract.GetBoolean(Result, 'contractProbe') then
      Error(ReplayErr);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      Entry.Get(RunId, 'ITEM', LogicalKey, 'ITEM');
      Entry.TestField("Batch Id", BatchId);
      Entry.TestField("Table Id", Database::Item);
      Item.GetBySystemId(Entry."Record SystemId");
      Values := Catalog.BuildValues(Context, LogicalKey);
      Item.TestField(Type, Item.Type::Inventory);
      Item.TestField(Description, Contract.GetText(Values, 'description'));
      Item.TestField("Base Unit of Measure", Contract.GetText(Settings, 'baseUnit'));
      Item.TestField("Purch. Unit of Measure", Contract.GetText(Settings, 'packUnit'));
      Item.TestField("Sales Unit of Measure", Item."Base Unit of Measure");
      Item.TestField("Inventory Posting Group", Contract.GetText(Settings, 'inventoryGroup'));
      Item.TestField("Gen. Prod. Posting Group", Contract.GetText(Settings, 'genProduct'));
      Item.TestField("VAT Prod. Posting Group", Contract.GetText(Settings, 'vatProduct'));
      Item.TestField("Item Category Code", Catalog.CategoryCode(RunId, CopyStr(Contract.GetCode(Values, 'category'), 1, 10)));
      Item.TestField(Blocked, false);
      Item.TestField(Type, Item.Type::Inventory);
      Item.TestField("Costing Method", Item."Costing Method"::FIFO);
      Item.TestField("Unit Cost", Rules.GetDecimal(Values, 'cost'));
      Item.TestField("Unit Price", Rules.GetDecimal(Values, 'price'));
      Item.TestField("Vendor No.", Setup.PrimaryVendor(Context, LogicalKey));
      Measure.Get(Item."No.", Item."Base Unit of Measure");
      Measure.TestField("Qty. per Unit of Measure", 1);
      Measure.Get(Item."No.", Item."Purch. Unit of Measure");
      Measure.TestField("Qty. per Unit of Measure", Contract.GetInteger(Values, 'packQuantity'));
      Masters.CheckAttribute(Item, 'Material', Contract.GetText(Values, 'material'));
      Masters.CheckAttribute(Item, Catalog.Choose(German, 'Durchmesser', 'Diameter'), Contract.GetText(Values, 'diameter'));
      if Contract.GetInteger(Values, 'family') <> 5 then
        Masters.CheckAttribute(Item, Catalog.Choose(German, 'Gewinde', 'Thread'), Contract.GetText(Values, 'thread'));
      if Values.Contains('dimension') then begin
        if Contract.GetInteger(Values, 'family') = 5 then
          Masters.CheckAttribute(Item, Catalog.Choose(German, 'Dicke', 'Thickness'), Contract.GetText(Values, 'dimension'))
        else
          Masters.CheckAttribute(Item, Catalog.Choose(German, 'Baulänge', 'Length'), Contract.GetText(Values, 'dimension'));
        Masters.CheckAttribute(Item, Catalog.Choose(German, 'Druckstufe', 'Pressure rating'), Contract.GetText(Values, 'rating'));
        Item.TestField("Reorder Point", Contract.GetInteger(Values, 'reorderPoint'));
      end;
      Relations.Validate(Context, RunId, LogicalKey, Item);
    end;
    // Every registered artifact must still exist, including shared masters and inherited mappings.
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    if Entry.Count() <> Contract.GetInteger(Result, 'createdRecords') then
      Error(ReplayErr);
    if Entry.FindSet() then
      repeat
        CheckIdentity(Entry);
      until Entry.Next() = 0;
  end;

  local procedure CheckIdentity(Entry: Record "BCSF Generated Record")
  var
    Registry: Codeunit "BCSF Record Registry";
  begin
    if not Registry.ExistsByIdentity(Entry) then
      Error(ReplayErr);
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    Error(ReplayErr);
  end;

  var
    NameLbl: Label 'Technical Wholesale Items';
    ReplayErr: Label 'Item results or relationships are missing, changed or already registered. Review the existing batch and checkpoint; do not repeat uncertain work.';
}
