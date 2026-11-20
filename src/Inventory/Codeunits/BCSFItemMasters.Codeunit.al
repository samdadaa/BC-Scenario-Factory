namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

codeunit 90480 "BCSF Item Masters"
{
  Access = Internal;

  procedure CreateCategories(Context: JsonObject; RunId: Guid; BatchId: Guid)
  var
    Catalog: Codeunit "BCSF Item Catalog";
    Contract: Codeunit "BCSF Contract JSON";
    German: Boolean;
    RootId: Guid;
    CategoryId: Guid;
  begin
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    RootId := NewCategory(RunId, BatchId, 'TECH', '', Catalog.Choose(German, 'Installationstechnik', 'Installation supplies'), RootId);
    CategoryId := NewCategory(RunId, BatchId, 'FITTINGS', 'TECH', Catalog.Choose(German, 'Verbindungstechnik', 'Fittings'), RootId);
    AssignMaterial(Context, RunId, BatchId, 'FITTINGS', Catalog.Choose(German, 'Messing', 'Brass'), CategoryId);
    CategoryId := NewCategory(RunId, BatchId, 'VALVES', 'TECH', Catalog.Choose(German, 'Armaturen', 'Valves'), RootId);
    AssignMaterial(Context, RunId, BatchId, 'VALVES', Catalog.Choose(German, 'Messing', 'Brass'), CategoryId);
    CategoryId := NewCategory(RunId, BatchId, 'FILTERS', 'TECH', Catalog.Choose(German, 'Filtertechnik', 'Filters'), RootId);
    AssignMaterial(Context, RunId, BatchId, 'FILTERS', Catalog.Choose(German, 'Edelstahl', 'Stainless steel'), CategoryId);
    CategoryId := NewCategory(RunId, BatchId, 'SEALS', 'TECH', Catalog.Choose(German, 'Dichtungstechnik', 'Seals'), RootId);
    AssignMaterial(Context, RunId, BatchId, 'SEALS', 'EPDM', CategoryId);
  end;

  local procedure NewCategory(RunId: Guid; BatchId: Guid; Suffix: Code[10]; ParentSuffix: Code[10]; Description: Text; ParentId: Guid): Guid
  var
    Category: Record "Item Category";
    Catalog: Codeunit "BCSF Item Catalog";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Category.Init();
    Category.Validate(Code, Catalog.CategoryCode(RunId, Suffix));
    if ParentSuffix <> '' then
      Category.Validate("Parent Category", Catalog.CategoryCode(RunId, ParentSuffix));
    Category.Validate(Description, CopyStr(Description, 1, MaxStrLen(Category.Description)));
    // Insert, rather than upsert: a colliding foreign category is never adopted.
    Category.Insert(true);
    exit(Registry.RegisterResult(RunId, 'ITEM', 1, 'CAT-' + Suffix, BatchId, Category.RecordId(), ParentId));
  end;

  local procedure AssignMaterial(Context: JsonObject; RunId: Guid; BatchId: Guid; Suffix: Code[10]; Material: Text; ParentId: Guid)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
  begin
    Assign(Context, RunId, BatchId, 1, Database::"Item Category", Catalog.CategoryCode(RunId, Suffix),
      Catalog.Choose(Contract.GetInteger(Context, 'dataLanguage') = 1, 'Material', 'Material'), Material, 'MAP-' + Suffix, ParentId);
  end;

  procedure Assign(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer; TableId: Integer; No: Code[20]; AttributeName: Text; Value: Text; Role: Code[30]; ParentId: Guid)
  var
    Attribute: Record "Item Attribute";
    AttributeValue: Record "Item Attribute Value";
    Mapping: Record "Item Attribute Value Mapping";
    Registry: Codeunit "BCSF Record Registry";
    AttributeId: Guid;
  begin
    Attribute.LockTable();
    Attribute.SetRange(Name, AttributeName);
    if not Attribute.FindFirst() then begin
      Attribute.Init();
      Attribute.Validate(Name, CopyStr(AttributeName, 1, MaxStrLen(Attribute.Name)));
      Attribute.Type := Attribute.Type::Text;
      Attribute.Insert(true);
      AttributeId := Registry.RegisterResult(RunId, 'ITEM', LogicalKey, CopyStr(Role + '-ATTR', 1, 30), BatchId, Attribute.RecordId(), ParentId);
    end;
    Attribute.TestField(Blocked, false);
    if Attribute.Type <> Attribute.Type::Option then
      Attribute.TestField(Type, Attribute.Type::Text);
    AttributeValue.LockTable();
    AttributeValue.SetRange("Attribute ID", Attribute.ID);
    AttributeValue.SetRange(Value, Value);
    if not AttributeValue.FindFirst() then begin
      AttributeValue.Init();
      AttributeValue.Validate("Attribute ID", Attribute.ID);
      AttributeValue.Validate(Value, CopyStr(Value, 1, MaxStrLen(AttributeValue.Value)));
      AttributeValue.Insert(true);
      Registry.RegisterResult(RunId, 'ITEM', LogicalKey, CopyStr(Role + '-VALUE', 1, 30), BatchId, AttributeValue.RecordId(), AttributeId);
    end;
    AttributeValue.TestField(Blocked, false);
    Mapping.Init();
    Mapping.Validate("Table ID", TableId);
    Mapping.Validate("No.", No);
    Mapping.Validate("Item Attribute ID", Attribute.ID);
    Mapping.Validate("Item Attribute Value ID", AttributeValue.ID);
    Mapping.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, Role, BatchId, Mapping.RecordId(), ParentId);
  end;

  procedure RegisterInherited(RunId: Guid; BatchId: Guid; LogicalKey: Integer; Item: Record Item; ParentId: Guid)
  var
    Mapping: Record "Item Attribute Value Mapping";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Mapping.SetRange("Table ID", Database::Item);
    Mapping.SetRange("No.", Item."No.");
    if Mapping.FindSet() then
      repeat
        Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'INHERIT-' + Format(Mapping."Item Attribute ID", 0, 9), BatchId, Mapping.RecordId(), ParentId);
      until Mapping.Next() = 0;
  end;

  procedure ValidateCategories(Context: JsonObject; RunId: Guid)
  var
    Category: Record "Item Category";
    Entry: Record "BCSF Generated Record";
    Catalog: Codeunit "BCSF Item Catalog";
    Suffix: Code[10];
    Index: Integer;
  begin
    for Index := 1 to 5 do begin
      Suffix := CopyStr(SelectStr(Index, 'TECH,FITTINGS,VALVES,FILTERS,SEALS'), 1, 10);
      Entry.Get(RunId, 'ITEM', 1, 'CAT-' + Suffix);
      Category.GetBySystemId(Entry."Record SystemId");
      Category.TestField(Code, Catalog.CategoryCode(RunId, Suffix));
      if Index = 1 then
        Category.TestField("Parent Category", '')
      else
        Category.TestField("Parent Category", Catalog.CategoryCode(RunId, 'TECH'));
    end;
  end;

  procedure CheckAttribute(Item: Record Item; AttributeName: Text; ExpectedValue: Text)
  var
    Attribute: Record "Item Attribute";
    AttributeValue: Record "Item Attribute Value";
    Mapping: Record "Item Attribute Value Mapping";
  begin
    Attribute.SetRange(Name, AttributeName);
    Attribute.FindFirst();
    Attribute.TestField(Blocked, false);
    Mapping.Get(Database::Item, Item."No.", Attribute.ID);
    AttributeValue.Get(Attribute.ID, Mapping."Item Attribute Value ID");
    AttributeValue.TestField(Value, ExpectedValue);
    AttributeValue.TestField(Blocked, false);
  end;
}
