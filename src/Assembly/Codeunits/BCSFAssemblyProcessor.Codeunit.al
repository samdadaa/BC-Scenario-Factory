namespace BCScenarioFactory.Assembly;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Inventory;
using BCScenarioFactory.Lifecycle;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Posting;
using Microsoft.Assembly.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;

/// <summary>
/// Assembly (not manufacturing) for standard-posted purchases of the same run, in the approved follow-up stage.
/// A synthetic assembly item with a bill of materials (the first one or two item lines of the purchase and,
/// when available, one assembly resource) is created, then an assembly order: 1 unposted, 2 posted in full,
/// 3 posted partially (open rest stays as an unposted order). Component use is capped by the movement unit rule,
/// so the stock reserve for later sales stays intact. Unsuitable cases are skipped before posting (STOCK, DIMENSION, SOURCE).
/// </summary>
codeunit 90483 "BCSF Assembly Processor"
{
  Access = Internal;

  procedure ResourceNo(): Code[20]
  begin
    exit('BCSF-MONT');
  end;

  /// <summary>Additive marker: assembly is offered only when the standard assembly setup and posting prerequisites are usable.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    AssemblySetup: Record "Assembly Setup";
    SourceCode: Record "Source Code Setup";
    InventorySetup: Record "Inventory Setup";
  begin
    if not AssemblySetup.Get() or not SourceCode.Get() or not InventorySetup.Get() then
      exit;
    if (AssemblySetup."Assembly Order Nos." = '') or (AssemblySetup."Posted Assembly Order Nos." = '') or
      (SourceCode.Assembly = '') or (InventorySetup."Item Nos." = '') or not InventorySetup."Automatic Cost Posting"
    then
      exit;
    Settings.Add('assemblyVersion', 1);
    Settings.Add('assemblyResource', ResourceUsable());
  end;

  /// <summary>True for new captures with the assembly marker; an unknown marker stops.</summary>
  procedure Enabled(Context: JsonObject): Boolean
  var
    Token: JsonToken;
    Settings: JsonObject;
  begin
    if not Context.Get('paymentSetup', Token) then
      exit(false);
    Settings := Token.AsObject();
    if not Settings.Get('assemblyVersion', Token) then
      exit(false);
    if Token.AsValue().AsInteger() <> 1 then
      Error(SetupErr);
    exit(true);
  end;

  local procedure UseResource(Context: JsonObject): Boolean
  var
    Token: JsonToken;
    Settings: JsonObject;
  begin
    Context.Get('paymentSetup', Token);
    Settings := Token.AsObject();
    if not Settings.Get('assemblyResource', Token) then
      exit(false);
    exit(Token.AsValue().AsBoolean());
  end;

  /// <summary>Additive foundation: blank-business-group posting rows for used product groups and one synthetic assembly resource.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure PrepareFoundation()
  var
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    EnsureBlankBusinessPosting();
    EnsureResource();
  end;

  local procedure EnsureBlankBusinessPosting()
  var
    Item: Record Item;
    Source: Record "General Posting Setup";
    Target: Record "General Posting Setup";
    Done: List of [Code[20]];
    ProductGroup: Code[20];
  begin
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    Item.SetRange(Type, Item.Type::Inventory);
    Item.SetLoadFields("Gen. Prod. Posting Group");
    if Item.FindSet() then
      repeat
        ProductGroup := Item."Gen. Prod. Posting Group";
        if (ProductGroup <> '') and not Done.Contains(ProductGroup) then begin
          Done.Add(ProductGroup);
          if not Target.Get('', ProductGroup) then begin
            // Copy only from an already usable matrix row of the same product group; never invent accounts.
            Source.Reset();
            Source.SetRange("Gen. Prod. Posting Group", ProductGroup);
            Source.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
            if Source.FindSet() then
              repeat
                if UsablePosting(Source) then begin
                  Target.Init();
                  Target.TransferFields(Source, false);
                  Target."Gen. Bus. Posting Group" := '';
                  Target."Gen. Prod. Posting Group" := ProductGroup;
                  Target.Insert(true);
                  break;
                end;
              until Source.Next() = 0;
          end;
        end;
      until Item.Next() = 0;
  end;

  local procedure EnsureResource()
  var
    Resource: Record Resource;
    Measure: Record "Unit of Measure";
    Source: Record "General Posting Setup";
    Item: Record Item;
    ProductGroup: Code[20];
  begin
    Resource.SecurityFiltering(SecurityFilter::Disallowed);
    if Resource.Get(ResourceNo()) then
      exit;
    if not Measure.Get('STD') then
      exit;
    Item.SecurityFiltering(SecurityFilter::Disallowed);
    Item.SetRange(Type, Item.Type::Inventory);
    Item.SetLoadFields("Gen. Prod. Posting Group");
    if Item.FindSet() then
      repeat
        if Source.Get('', Item."Gen. Prod. Posting Group") and UsablePosting(Source) then begin
          ProductGroup := Item."Gen. Prod. Posting Group";
          break;
        end;
      until Item.Next() = 0;
    if ProductGroup = '' then
      exit;
    Resource.Init();
    Resource."No." := ResourceNo();
    Resource.Validate(Name, ResourceNameLbl);
    Resource.Validate(Type, Resource.Type::Person);
    Resource.Insert(true);
    Resource.Validate("Base Unit of Measure", 'STD');
    Resource.Validate("Gen. Prod. Posting Group", ProductGroup);
    Resource.Validate("Direct Unit Cost", 40);
    Resource.Validate("Unit Price", 60);
    Resource.Modify(true);
  end;

  local procedure ResourceUsable(): Boolean
  var
    Resource: Record Resource;
    Posting: Record "General Posting Setup";
  begin
    if not Resource.Get(ResourceNo()) then
      exit(false);
    if Resource.Blocked or (Resource.Type <> Resource.Type::Person) or (Resource."Base Unit of Measure" <> 'STD') then
      exit(false);
    exit(Posting.Get('', Resource."Gen. Prod. Posting Group") and UsablePosting(Posting));
  end;

  /// <summary>All accounts the assembly posting uses must be existing, unblocked posting accounts.</summary>
  local procedure UsablePosting(Posting: Record "General Posting Setup"): Boolean
  begin
    exit(UsableAccount(Posting."Inventory Adjmt. Account") and UsableAccount(Posting."Direct Cost Applied Account") and
      UsableAccount(Posting."COGS Account"));
  end;

  local procedure UsableAccount(AccountNo: Code[20]): Boolean
  var
    Account: Record "G/L Account";
  begin
    if AccountNo = '' then
      exit(false);
    if not Account.Get(AccountNo) then
      exit(false);
    exit((Account."Account Type" = Account."Account Type"::Posting) and not Account.Blocked);
  end;

  /// <summary>Sub kind from the seed: 1 unposted order, 2 posted in full, 3 posted partially (needs at least two units).</summary>
  procedure SubKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Quantity: Decimal): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    Kind: Integer;
  begin
    Kind := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'ASSEMBLY-MODE', 1, 3);
    if (Kind = 3) and (Quantity < 2) then
      Kind := 2;
    exit(Kind);
  end;

  /// <summary>Assembled quantity: the smallest unit allowance of the used component lines (1 to 3, within the reserve cap).</summary>
  procedure AssembledQuantity(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"): Decimal
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Movements: Codeunit "BCSFInventoryMovementProcessor";
    Quantity: Decimal;
    Units: Decimal;
    LineIndex: Integer;
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    repeat
      LineIndex += 1;
      Units := Movements.LineUnits(Context, NodeCode, LogicalKey, LineIndex, InvoiceLine.Quantity);
      if (Quantity = 0) or (Units < Quantity) then
        Quantity := Units;
    until (InvoiceLine.Next() = 0) or (LineIndex >= 2);
    exit(Quantity);
  end;

  /// <summary>The first one or two lines with different items are the components. Result is the number of components (1 or 2).</summary>
  local procedure Components(Invoice: Record "Purch. Inv. Header"; var ItemNos: array[2] of Code[20]; var Locations: array[2] of Code[10]; var Units: array[2] of Code[10]): Integer
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Count: Integer;
    LineIndex: Integer;
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    repeat
      LineIndex += 1;
      if (Count = 0) or ((Count = 1) and (ItemNos[1] <> InvoiceLine."No.")) then begin
        Count += 1;
        ItemNos[Count] := InvoiceLine."No.";
        Locations[Count] := InvoiceLine."Location Code";
        Units[Count] := InvoiceLine."Unit of Measure Code";
      end;
    until (InvoiceLine.Next() = 0) or (LineIndex >= 2) or (Count = 2);
    exit(Count);
  end;

  /// <summary>Creates the assembly item, its bill of materials and the order. Returns a skip reason when nothing could be posted.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid)
  var
    Registry: Codeunit "BCSF Record Registry";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Count: Integer;
    Quantity: Decimal;
    Kind: Integer;
    SkipReason: Code[30];
  begin
    Count := Components(Invoice, ItemNos, Locations, Measures);
    Quantity := AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    Kind := SubKind(Context, NodeCode, LogicalKey, Quantity);
    SkipReason := Preflight(Context, Kind, Quantity, Count, ItemNos, Locations, Date);
    if SkipReason = '' then
      SkipReason := Build(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId, Kind, Quantity, Count, ItemNos, Locations, Measures);
    if SkipReason <> '' then
      // Controlled skip: nothing is posted and the invoice carries the documented reason.
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'MOVEMENT-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
  end;

  /// <summary>Read-only prerequisites: item number series, unblocked components, usable posting setup and free stock for posted orders.</summary>
  local procedure Preflight(Context: JsonObject; Kind: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Date: Date): Code[30]
  var
    Item: Record Item;
    Variant: Record "Item Variant";
    Posting: Record "General Posting Setup";
    InventorySetup: Record "Inventory Setup";
    Consume: Decimal;
    Index: Integer;
  begin
    InventorySetup.Get();
    if InventorySetup."Item Nos." = '' then
      exit('SOURCE');
    Consume := Quantity;
    if Kind = 3 then
      Consume := Round(Quantity / 2, 1, '>');
    for Index := 1 to Count do begin
      Item.Get(ItemNos[Index]);
      if Item.Blocked or (Item.Type <> Item.Type::Inventory) or (Item."Item Tracking Code" <> '') then
        exit('SOURCE');
      // Variants and automatic substitutes are not part of this contract: such components are skipped, never replaced.
      Variant.SetRange("Item No.", ItemNos[Index]);
      if not Variant.IsEmpty() then
        exit('SOURCE');
      if Kind > 1 then begin
        if not Posting.Get('', Item."Gen. Prod. Posting Group") or not UsablePosting(Posting) then
          exit('SOURCE');
        Item.SetRange("Location Filter", Locations[Index]);
        Item.SetRange("Date Filter", 0D, Date);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        if Item.Inventory - Item."Reserved Qty. on Inventory" < Consume then
          exit('STOCK');
      end;
    end;
    exit('');
  end;

  local procedure Build(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid; Kind: Integer; Quantity: Decimal; Count: Integer; ItemNos: array[2] of Code[20]; Locations: array[2] of Code[10]; Measures: array[2] of Code[10]): Code[30]
  var
    Kit: Record Item;
    Component: Record Item;
    Measure: Record "Item Unit of Measure";
    Bom: Record "BOM Component";
    Header: Record "Assembly Header";
    Line: Record "Assembly Line";
    InventorySetup: Record "Inventory Setup";
    Registry: Codeunit "BCSF Record Registry";
    Contract: Codeunit "BCSF Contract JSON";
    Numbers: Codeunit "No. Series";
    ReleaseDocument: Codeunit "Release Assembly Document";
    AssemblyPost: Codeunit "Assembly-Post";
    Dimensions: Codeunit DimensionManagement;
    KitId: Guid;
    KitNo: Code[20];
    BomLines: Integer;
    Index: Integer;
    Cost: Decimal;
    Part: Decimal;
    OrderNo: Code[20];
    StartDate: Date;
  begin
    InventorySetup.Get();
    Evaluate(StartDate, Contract.GetText(Context, 'startingDate'), 9);
    Component.Get(ItemNos[1]);
    KitNo := Numbers.GetNextNo(InventorySetup."Item Nos.", StartDate);
    Kit.Init();
    Kit."No. Series" := InventorySetup."Item Nos.";
    Kit."No." := KitNo;
    Kit.Validate(Type, Kit.Type::Inventory);
    if Contract.GetInteger(Context, 'dataLanguage') = 1 then
      Kit.Validate(Description, CopyStr('Montageset ' + Format(LogicalKey, 0, 9), 1, MaxStrLen(Kit.Description)))
    else
      Kit.Validate(Description, CopyStr('Assembly kit ' + Format(LogicalKey, 0, 9), 1, MaxStrLen(Kit.Description)));
    Kit.Validate("Costing Method", Kit."Costing Method"::FIFO);
    Kit.Validate("Gen. Prod. Posting Group", Component."Gen. Prod. Posting Group");
    Kit.Validate("VAT Prod. Posting Group", Component."VAT Prod. Posting Group");
    Kit.Validate("Inventory Posting Group", Component."Inventory Posting Group");
    Kit.Insert(true);
    Kit.Validate("Base Unit of Measure", Component."Base Unit of Measure");
    Measure.Get(Kit."No.", Kit."Base Unit of Measure");
    for Index := 1 to Count do begin
      Component.Get(ItemNos[Index]);
      BomLines += 1;
      Bom.Init();
      Bom.Validate("Parent Item No.", Kit."No.");
      Bom."Line No." := BomLines * 10000;
      Bom.Validate(Type, Bom.Type::Item);
      Bom.Validate("No.", Component."No.");
      Bom.Validate("Quantity per", 1);
      Bom.Validate("Unit of Measure Code", Measures[Index]);
      Bom.Insert(true);
      Cost += Component."Unit Cost";
    end;
    if UseResource(Context) then begin
      BomLines += 1;
      Bom.Init();
      Bom.Validate("Parent Item No.", Kit."No.");
      Bom."Line No." := BomLines * 10000;
      Bom.Validate(Type, Bom.Type::Resource);
      Bom.Validate("No.", ResourceNo());
      Bom.Validate("Quantity per", 1);
      Bom.Validate("Unit of Measure Code", 'STD');
      Bom.Insert(true);
      Cost += 40;
    end;
    Kit.Validate("Replenishment System", Kit."Replenishment System"::Assembly);
    Kit.Validate("Assembly Policy", Kit."Assembly Policy"::"Assemble-to-Stock");
    Kit.Validate("Unit Cost", Round(Cost, 0.01));
    Kit.Validate("Unit Price", Round(Cost * 1.35, 0.01));
    Kit.Modify(true);
    KitId := Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ITEM', BatchId, Kit.RecordId(), ParentId);
    Bom.SetRange("Parent Item No.", Kit."No.");
    Bom.FindSet();
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-BOM', Bom."Line No." div 10000), BatchId, Bom.RecordId(), KitId);
    until Bom.Next() = 0;
    Header.Init();
    Header."Document Type" := Header."Document Type"::Order;
    Header.Insert(true);
    Header.SetHideValidationDialog(true);
    Header.Validate("Item No.", Kit."No.");
    Header.Validate("Location Code", Locations[1]);
    Header.Validate(Quantity, Quantity);
    Header.Validate("Posting Date", Date);
    Header.Validate("Due Date", Date);
    Header.Validate("Starting Date", Date);
    Header.Validate("Ending Date", Date);
    Header.Modify(true);
    OrderNo := Header."No.";
    if not Dimensions.CheckDimIDComb(Header."Dimension Set ID") then begin
      Header.Delete(true);
      exit('DIMENSION');
    end;
    Line.SetRange("Document Type", Header."Document Type");
    Line.SetRange("Document No.", Header."No.");
    if Line.Count() <> BomLines then
      Error(ResultErr);
    if Line.FindSet() then
      repeat
        if not Dimensions.CheckDimIDComb(Line."Dimension Set ID") then begin
          Header.Delete(true);
          exit('DIMENSION');
        end;
      until Line.Next() = 0;
    if Kind = 1 then begin
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ORDER', BatchId, Header.RecordId(), ParentId);
      exit('');
    end;
    if Kind = 3 then begin
      Part := Round(Quantity / 2, 1, '>');
      Header.Validate("Quantity to Assemble", Part);
      Header.Modify(true);
    end;
    ReleaseDocument.Run(Header);
    AssemblyPost.SetSuppressCommit(true);
    AssemblyPost.Run(Header);
    RegisterPosted(RunId, NodeCode, LogicalKey, BatchId, ParentId, OrderNo, Kit."No.", Kind = 3);
    exit('');
  end;

  local procedure RegisterPosted(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; OrderNo: Code[20]; KitNo: Code[20]; Partial: Boolean)
  var
    Posted: Record "Posted Assembly Header";
    Header: Record "Assembly Header";
    ItemEntry: Record "Item Ledger Entry";
    ResourceEntry: Record "Res. Ledger Entry";
    GL: Record "G/L Entry";
    Registry: Codeunit "BCSF Record Registry";
    Found: Boolean;
  begin
    Posted.SetRange("Order No.", OrderNo);
    if Posted.Count() <> 1 then
      Error(ResultErr);
    Posted.FindFirst();
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSEMBLY-POSTED', BatchId, Posted.RecordId(), ParentId);
    if Partial then begin
      // The open rest stays as an unposted assembly order.
      Header.Get(Header."Document Type"::Order, OrderNo);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ORDER', BatchId, Header.RecordId(), ParentId);
    end;
    ItemEntry.SetRange("Document No.", Posted."No.");
    ItemEntry.SetFilter("Entry Type", '%1|%2', ItemEntry."Entry Type"::"Assembly Consumption", ItemEntry."Entry Type"::"Assembly Output");
    if ItemEntry.FindSet() then
      repeat
        Found := true;
        RegisterEntry(RunId, NodeCode, LogicalKey, BatchId, ParentId, ItemEntry);
      until ItemEntry.Next() = 0;
    if not Found then
      Error(ResultErr);
    ResourceEntry.SetRange("Document No.", Posted."No.");
    if ResourceEntry.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-RES', ResourceEntry."Entry No."), BatchId, ResourceEntry.RecordId(), ParentId);
      until ResourceEntry.Next() = 0;
    GL.SetRange("Document No.", Posted."No.");
    GL.SetRange("Posting Date", Posted."Posting Date");
    if GL.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
      until GL.Next() = 0;
  end;

  local procedure RegisterEntry(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; ItemEntry: Record "Item Ledger Entry")
  var
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    GL: Record "G/L Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-ILE', ItemEntry."Entry No."), BatchId, ItemEntry.RecordId(), ParentId);
    Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
    if Value.IsEmpty() then
      Error(ResultErr);
    Value.FindSet();
    repeat
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-VAL', Value."Entry No."), BatchId, Value.RecordId(), ParentId);
      Relation.SetRange("Value Entry No.", Value."Entry No.");
      if Relation.FindSet() then
        repeat
          GL.Get(Relation."G/L Entry No.");
          Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('ASSEMBLY-GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
        until Relation.Next() = 0;
    until Value.Next() = 0;
  end;

  /// <summary>Read-only validation of the item, bill of materials, order state, consumption, output and stock.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Date: Date)
  var
    Entry: Record "BCSF Generated Record";
    Kit: Record Item;
    Bom: Record "BOM Component";
    Header: Record "Assembly Header";
    Posted: Record "Posted Assembly Header";
    ItemEntry: Record "Item Ledger Entry";
    ItemNos: array[2] of Code[20];
    Locations: array[2] of Code[10];
    Measures: array[2] of Code[10];
    Count: Integer;
    Index: Integer;
    Quantity: Decimal;
    Part: Decimal;
    Kind: Integer;
  begin
    Count := Components(Invoice, ItemNos, Locations, Measures);
    Quantity := AssembledQuantity(Context, NodeCode, LogicalKey, Invoice);
    Kind := SubKind(Context, NodeCode, LogicalKey, Quantity);
    Entry.Get(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ITEM');
    Entry.TestField("Table Id", Database::Item);
    Kit.GetBySystemId(Entry."Record SystemId");
    Kit.TestField("Replenishment System", Kit."Replenishment System"::Assembly);
    Kit.TestField("Assembly Policy", Kit."Assembly Policy"::"Assemble-to-Stock");
    Bom.SetRange("Parent Item No.", Kit."No.");
    Bom.SetRange(Type, Bom.Type::Item);
    if Bom.Count() <> Count then
      Error(ResultErr);
    for Index := 1 to Count do begin
      Bom.Get(Kit."No.", Index * 10000);
      Bom.TestField("No.", ItemNos[Index]);
      Bom.TestField("Quantity per", 1);
    end;
    if Kind = 1 then begin
      Entry.Get(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ORDER');
      Entry.TestField("Table Id", Database::"Assembly Header");
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Item No.", Kit."No.");
      Header.TestField(Quantity, Quantity);
      Header.TestField("Assembled Quantity", 0);
      exit;
    end;
    Entry.Get(RunId, NodeCode, LogicalKey, 'ASSEMBLY-POSTED');
    Entry.TestField("Table Id", Database::"Posted Assembly Header");
    Posted.GetBySystemId(Entry."Record SystemId");
    Posted.TestField("Item No.", Kit."No.");
    Posted.TestField("Posting Date", Date);
    Posted.TestField("Location Code", Locations[1]);
    Part := Quantity;
    if Kind = 3 then begin
      Part := Round(Quantity / 2, 1, '>');
      Entry.Get(RunId, NodeCode, LogicalKey, 'ASSEMBLY-ORDER');
      Header.GetBySystemId(Entry."Record SystemId");
      Header.TestField("Assembled Quantity", Part);
      Header.TestField("Remaining Quantity", Quantity - Part);
    end;
    Posted.TestField(Quantity, Part);
    // Output of the assembly item and consumption of every item component, per location.
    ItemEntry.SetRange("Document No.", Posted."No.");
    ItemEntry.SetRange("Item No.", Kit."No.");
    ItemEntry.SetRange("Entry Type", ItemEntry."Entry Type"::"Assembly Output");
    ItemEntry.CalcSums(Quantity);
    if ItemEntry.Quantity <> Part then
      Error(ResultErr);
    for Index := 1 to Count do begin
      ItemEntry.Reset();
      ItemEntry.SetRange("Document No.", Posted."No.");
      ItemEntry.SetRange("Item No.", ItemNos[Index]);
      ItemEntry.SetRange("Entry Type", ItemEntry."Entry Type"::"Assembly Consumption");
      ItemEntry.CalcSums(Quantity);
      if ItemEntry.Quantity <> -Part then
        Error(ResultErr);
      CheckNonNegative(ItemNos[Index], Locations[Index], Date);
    end;
    CheckNonNegative(Kit."No.", Locations[1], Date);
  end;

  local procedure CheckNonNegative(ItemNo: Code[20]; LocationCode: Code[10]; Date: Date)
  var
    Item: Record Item;
  begin
    Item.Get(ItemNo);
    Item.SetRange("Location Filter", LocationCode);
    Item.SetRange("Date Filter", 0D, Date);
    Item.CalcFields(Inventory);
    if Item.Inventory < 0 then
      Error(ResultErr);
    Item.SetRange("Date Filter");
    Item.CalcFields(Inventory);
    if Item.Inventory < 0 then
      Error(ResultErr);
  end;

  local procedure Artifact(Prefix: Code[20]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    ResourceNameLbl: Label 'Scenario Factory assembly resource';
    SetupErr: Label 'The assembly setup is not supported or changed. Review the assembly number series, the assembly source code, the posting setup without business posting group and the synthetic assembly resource.';
    ResultErr: Label 'Assembly results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
