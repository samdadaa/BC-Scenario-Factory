namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Structure;

codeunit 90479 "BCSF Item Relations"
{
  Access = Internal;

  procedure Create(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer)
  var
    Item: Record Item;
    Entry: Record "BCSF Generated Record";
    Setup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
    ParentId: Guid;
    Settings: JsonObject;
    German: Boolean;
  begin
    Entry.Get(RunId, 'ITEM', LogicalKey, 'ITEM');
    Item.GetBySystemId(Entry."Record SystemId");
    ParentId := Entry."Entry Id";
    Settings := Setup.ReadSettings(Context);
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    AddReference(Item, '', CopyStr(Contract.GetCode(Settings, 'packUnit'), 1, 10), Setup.PrimaryVendor(Context, LogicalKey), LogicalKey, 'SUPPLIER1', RunId, BatchId, ParentId, '<3D>');
    if LogicalKey = 1 then begin
      AddReference(Item, '', CopyStr(Contract.GetCode(Settings, 'packUnit'), 1, 10), Setup.ResolveVendor(Context, 2), LogicalKey, 'SUPPLIER2', RunId, BatchId, ParentId, '<7D>');
      AddSKU(Item, CopyStr(Contract.GetCode(Settings, 'location'), 1, 10), RunId, BatchId, LogicalKey, ParentId);
      if Setup.Quantity(Context, "BCSF Entity Type"::Customer) > 0 then
        AddCustomerReference(Item, RunId, BatchId, ParentId);
    end;
    if ((LogicalKey - 1) mod 8) = 2 then begin
      AddVariant(Item, 'ROT', Catalog.Choose(German, 'Hebel rot', 'Red lever'), RunId, BatchId, LogicalKey, ParentId);
      AddVariant(Item, 'BLAU', Catalog.Choose(German, 'Hebel blau', 'Blue lever'), RunId, BatchId, LogicalKey, ParentId);
      AddBarcode(Item, 'ROT', 1, RunId, BatchId, LogicalKey, ParentId);
      AddBarcode(Item, 'BLAU', 2, RunId, BatchId, LogicalKey, ParentId);
      AddReference(Item, 'ROT', Item."Base Unit of Measure", Setup.PrimaryVendor(Context, LogicalKey), LogicalKey, 'VARIANT-REF', RunId, BatchId, ParentId, '<3D>');
    end;
    if LogicalKey = 2 then
      AddSubstitution(Item, RunId, BatchId, ParentId);
    if Catalog.UsesBins(Contract.GetText(Context, 'profileCode')) and (LogicalKey in [1, 3]) then
      AddBin(Item, CopyStr(Contract.GetCode(Settings, 'location'), 1, 10), RunId, BatchId, LogicalKey, ParentId);
  end;

  local procedure AddReference(Item: Record Item; VariantCode: Code[10]; UnitCode: Code[10]; VendorNo: Code[20]; LogicalKey: Integer; Role: Code[30]; RunId: Guid; BatchId: Guid; ParentId: Guid; LeadTime: Text)
  var
    Reference: Record "Item Reference";
    Supplier: Record "Item Vendor";
    Registry: Codeunit "BCSF Record Registry";
    LeadTimeFormula: DateFormula;
    ReferenceId: Guid;
  begin
    Reference.Init();
    Reference.Validate("Item No.", Item."No.");
    Reference.Validate("Variant Code", VariantCode);
    Reference.Validate("Unit of Measure", UnitCode);
    Reference.Validate("Reference Type", Reference."Reference Type"::Vendor);
    Reference.Validate("Reference Type No.", VendorNo);
    Reference.Validate("Reference No.", CopyStr('TG-' + Format(LogicalKey, 0, 9) + '-' + VariantCode, 1, 50));
    Reference.Insert(true);
    ReferenceId := Registry.RegisterResult(RunId, 'ITEM', LogicalKey, Role, BatchId, Reference.RecordId(), ParentId);
    // The standard Item Reference insert creates Item Vendor. Never insert it a second time.
    GetItemVendor(Supplier, VendorNo, Item."No.", VariantCode);
    Supplier.TestField("Vendor Item No.", Reference."Reference No.");
    Evaluate(LeadTimeFormula, LeadTime);
    Supplier.Validate("Lead Time Calculation", LeadTimeFormula);
    Supplier.Modify(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, CopyStr(Role + '-VENDOR', 1, 30), BatchId, Supplier.RecordId(), ReferenceId);
  end;

  /// <summary>The standard primary key is Vendor No., Item No., Variant Code.</summary>
  procedure GetItemVendor(var Supplier: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
  begin
    Supplier.Get(VendorNo, ItemNo, VariantCode);
    Supplier.TestField("Vendor No.", VendorNo);
    Supplier.TestField("Item No.", ItemNo);
    Supplier.TestField("Variant Code", VariantCode);
  end;

  local procedure AddCustomerReference(Item: Record Item; RunId: Guid; BatchId: Guid; ParentId: Guid)
  var
    Entry: Record "BCSF Generated Record";
    Customer: Record Customer;
    Reference: Record "Item Reference";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Entry.Get(RunId, 'CUSTOMER', 1, 'CUSTOMER');
    Customer.GetBySystemId(Entry."Record SystemId");
    Customer.TestField(Blocked, Customer.Blocked::" ");
    Reference.Init();
    Reference.Validate("Item No.", Item."No.");
    Reference.Validate("Unit of Measure", Item."Base Unit of Measure");
    Reference.Validate("Reference Type", Reference."Reference Type"::Customer);
    Reference.Validate("Reference Type No.", Customer."No.");
    Reference.Validate("Reference No.", 'GT-KUPPLUNG');
    Reference.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', 1, 'CUSTOMER-REF', BatchId, Reference.RecordId(), ParentId);
  end;

  local procedure AddBarcode(Item: Record Item; VariantCode: Code[10]; VariantIndex: Integer; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Reference: Record "Item Reference";
    Registry: Codeunit "BCSF Record Registry";
    Value: Text;
    Digit: Integer;
    Sum: Integer;
    Index: Integer;
  begin
    Value := '0000000' + Format(LogicalKey mod 1000000, 0, 9);
    Value := '20' + CopyStr(Value, StrLen(Value) - 6, 7) + Format(VariantIndex, 0, 9) + '00';
    for Index := 1 to 12 do begin
      Evaluate(Digit, CopyStr(Value, Index, 1));
      if Index mod 2 = 0 then
        Sum += Digit * 3
      else
        Sum += Digit;
    end;
    Value += Format((10 - (Sum mod 10)) mod 10, 0, 9);
    Reference.Init();
    Reference.Validate("Item No.", Item."No.");
    Reference.Validate("Variant Code", VariantCode);
    Reference.Validate("Unit of Measure", Item."Base Unit of Measure");
    Reference.Validate("Reference Type", Reference."Reference Type"::"Bar Code");
    Reference.Validate("Reference No.", CopyStr(Value, 1, MaxStrLen(Reference."Reference No.")));
    Reference.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'BARCODE-' + VariantCode, BatchId, Reference.RecordId(), ParentId);
  end;

  local procedure AddVariant(Item: Record Item; CodeValue: Code[10]; Description: Text; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Variant: Record "Item Variant";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Variant.Init();
    Variant.Validate("Item No.", Item."No.");
    Variant.Validate(Code, CodeValue);
    Variant.Validate(Description, CopyStr(Description, 1, MaxStrLen(Variant.Description)));
    Variant.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'VAR-' + CodeValue, BatchId, Variant.RecordId(), ParentId);
  end;

  local procedure AddSubstitution(Item: Record Item; RunId: Guid; BatchId: Guid; ParentId: Guid)
  var
    Entry: Record "BCSF Generated Record";
    Other: Record Item;
    Substitution: Record "Item Substitution";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Entry.Get(RunId, 'ITEM', 1, 'ITEM');
    Other.GetBySystemId(Entry."Record SystemId");
    if Other."No." = Item."No." then
      Error(RelationErr);
    Substitution.Init();
    Substitution.Validate(Type, Substitution.Type::Item);
    Substitution.Validate("No.", Item."No.");
    Substitution.Validate("Substitute Type", Substitution."Substitute Type"::Item);
    Substitution.Validate("Substitute No.", Other."No.");
    Substitution.Validate(Interchangeable, false);
    Substitution.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', 2, 'SUBSTITUTION', BatchId, Substitution.RecordId(), ParentId);
  end;

  local procedure AddSKU(Item: Record Item; LocationCode: Code[10]; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    SKU: Record "Stockkeeping Unit";
    Registry: Codeunit "BCSF Record Registry";
  begin
    SKU.Init();
    SKU.Validate("Item No.", Item."No.");
    SKU.Validate("Location Code", LocationCode);
    SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Fixed Reorder Qty.");
    SKU.Validate("Reorder Point", 48);
    SKU.Validate("Reorder Quantity", 96);
    SKU.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'SKU', BatchId, SKU.RecordId(), ParentId);
  end;

  local procedure AddBin(Item: Record Item; LocationCode: Code[10]; RunId: Guid; BatchId: Guid; LogicalKey: Integer; ParentId: Guid)
  var
    Bin: Record Bin;
    Content: Record "Bin Content";
    Catalog: Codeunit "BCSF Item Catalog";
    Registry: Codeunit "BCSF Record Registry";
    BinId: Guid;
  begin
    Bin.Init();
    Bin.Validate("Location Code", LocationCode);
    Bin.Validate(Code, Catalog.CategoryCode(RunId, 'A' + Format(LogicalKey, 0, 9)));
    Bin.Validate(Description, CopyStr(Item.Description, 1, MaxStrLen(Bin.Description)));
    Bin.Insert(true);
    BinId := Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'BIN', BatchId, Bin.RecordId(), ParentId);
    Content.Init();
    Content.Validate("Location Code", LocationCode);
    Content.Validate("Bin Code", Bin.Code);
    Content.Validate("Item No.", Item."No.");
    Content.Validate("Unit of Measure Code", Item."Base Unit of Measure");
    Content.Validate(Fixed, true);
    Content.Validate(Default, true);
    Content.Insert(true);
    Registry.RegisterResult(RunId, 'ITEM', LogicalKey, 'BIN-CONTENT', BatchId, Content.RecordId(), BinId);
  end;

  procedure Validate(Context: JsonObject; RunId: Guid; LogicalKey: Integer; Item: Record Item)
  var
    Entry: Record "BCSF Generated Record";
    Reference: Record "Item Reference";
    Supplier: Record "Item Vendor";
    Variant: Record "Item Variant";
    Substitution: Record "Item Substitution";
    Other: Record Item;
    SKU: Record "Stockkeeping Unit";
    Content: Record "Bin Content";
    Setup: Codeunit "BCSF Item Setup";
    Contract: Codeunit "BCSF Contract JSON";
    Catalog: Codeunit "BCSF Item Catalog";
    Settings: JsonObject;
    LocationCode: Code[10];
  begin
    Settings := Setup.ReadSettings(Context);
    LocationCode := CopyStr(Contract.GetCode(Settings, 'location'), 1, 10);
    Entry.Get(RunId, 'ITEM', LogicalKey, 'SUPPLIER1');
    Reference.GetBySystemId(Entry."Record SystemId");
    Reference.TestField("Item No.", Item."No.");
    Reference.TestField("Unit of Measure", CopyStr(Contract.GetCode(Settings, 'packUnit'), 1, 10));
    Reference.TestField("Reference Type No.", Setup.PrimaryVendor(Context, LogicalKey));
    GetItemVendor(Supplier, Reference."Reference Type No.", Item."No.", '');
    Supplier.TestField("Vendor Item No.", Reference."Reference No.");
    if LogicalKey = 1 then begin
      Entry.Get(RunId, 'ITEM', LogicalKey, 'SUPPLIER2');
      Reference.GetBySystemId(Entry."Record SystemId");
      Reference.TestField("Item No.", Item."No.");
      Reference.TestField("Reference Type No.", Setup.ResolveVendor(Context, 2));
      Entry.Get(RunId, 'ITEM', LogicalKey, 'SKU');
      SKU.GetBySystemId(Entry."Record SystemId");
      SKU.TestField("Item No.", Item."No.");
      SKU.TestField("Location Code", LocationCode);
      SKU.TestField("Reorder Point", 48);
      SKU.TestField("Reorder Quantity", 96);
    end;
    if ((LogicalKey - 1) mod 8) = 2 then begin
      Variant.Get(Item."No.", 'ROT');
      Variant.TestField(Blocked, false);
      Variant.Get(Item."No.", 'BLAU');
      Variant.TestField(Blocked, false);
      Entry.Get(RunId, 'ITEM', LogicalKey, 'VARIANT-REF');
      Reference.GetBySystemId(Entry."Record SystemId");
      Reference.TestField("Item No.", Item."No.");
      Reference.TestField("Variant Code", 'ROT');
      Reference.TestField("Unit of Measure", Item."Base Unit of Measure");
    end;
    if LogicalKey = 2 then begin
      Entry.Get(RunId, 'ITEM', LogicalKey, 'SUBSTITUTION');
      Substitution.GetBySystemId(Entry."Record SystemId");
      Entry.Get(RunId, 'ITEM', 1, 'ITEM');
      Other.GetBySystemId(Entry."Record SystemId");
      Substitution.TestField("No.", Item."No.");
      Substitution.TestField("Substitute No.", Other."No.");
      Substitution.TestField(Interchangeable, false);
    end;
    if Catalog.UsesBins(Contract.GetText(Context, 'profileCode')) and (LogicalKey in [1, 3]) then begin
      Entry.Get(RunId, 'ITEM', LogicalKey, 'BIN-CONTENT');
      Content.GetBySystemId(Entry."Record SystemId");
      Content.TestField("Item No.", Item."No.");
      Content.TestField("Location Code", LocationCode);
      Content.TestField(Fixed, true);
      Content.TestField(Default, true);
    end;
  end;

  var
    RelationErr: Label 'An item substitution must refer to a different existing item in this run.';
}
