namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Assembly;
using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.Projects;
using BCScenarioFactory.ProcessEngine;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;

/// <summary>
/// Inventory movements without warehouse management for standard-posted purchase receipts of the same run
/// (follow-up stage). Kinds: 0 none, 1 positive adjustment, 2 negative adjustment, 3 physical inventory
/// difference (shortage or surplus of one unit), 4 transfer order shipment and receipt via an in-transit location.
/// Every item line of the invoice is moved by 1 to 3 units, never more than half of the planned stock reserve of that
/// line, so the stock needed by later sales stays intact. Unsuitable cases are skipped before any posting (STOCK, DIMENSION).
/// </summary>
codeunit 90482 "BCSFInventoryMovementProcessor"
{
    Access = Internal;

    /// <summary>Movements belong to the approved follow-up stage and need the additive marker of new captures.</summary>
    procedure Enabled(Context: JsonObject): Boolean
    var
        Payments: Codeunit "BCSF Payment Processor";
        Token: JsonToken;
        Settings: JsonObject;
    begin
        if not Payments.Enabled(Context) then
            exit(false);
        Context.Get('paymentSetup', Token);
        Settings := Token.AsObject();
        if not Settings.Get('inventoryVersion', Token) then
            exit(false);
        if Token.AsValue().AsInteger() <> 1 then
            Error(SetupErr);
        exit(true);
    end;

    /// <summary>
    /// Adds the movement marker when the standard setup supports journal postings with automatic cost posting;
    /// otherwise movements stay off for this capture. Transfer locations are added only when fully usable.
    /// </summary>
    procedure AddSettings(var Settings: JsonObject)
    var
        SourceCode: Record "Source Code Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        if not SourceCode.Get() or not InventorySetup.Get() then
            exit;
        if (SourceCode."Item Journal" = '') or (SourceCode."Phys. Inventory Journal" = '') or
          not InventorySetup."Automatic Cost Posting"
        then
            exit;
        Settings.Add('inventoryVersion', 1);
        if TransferSetupAvailable(InventorySetup) then begin
            Settings.Add('transferTo', AuxiliaryLocation());
            Settings.Add('transit', TransitLocation());
        end;
    end;

    /// <summary>Additive foundation: two synthetic locations for transfers. Existing records are verified, never changed.</summary>
    [CommitBehavior(CommitBehavior::Error)]
    procedure PrepareFoundation()
    var
        Location: Record Location;
        PostingSetup: Record "Inventory Posting Setup";
        Guard: Codeunit "BCSF Environment Guard";
    begin
        Guard.EnsureCanConfigure(CompanyName());
        // Optional stage: without write permission the synthetic locations are simply not offered (no transfers).
        if not Location.WritePermission() or not PostingSetup.WritePermission() then
            exit;
        EnsureLocation(AuxiliaryLocation(), false);
        EnsureLocation(TransitLocation(), true);
        // Item postings at a location need the inventory posting setup of that location (copied from usable rows only).
        EnsureInventoryPostingSetup(AuxiliaryLocation());
        EnsureInventoryPostingSetup(TransitLocation());
    end;

    local procedure EnsureLocation(LocationCode: Code[10]; InTransit: Boolean)
    var
        Location: Record Location;
    begin
        Location.SecurityFiltering(SecurityFilter::Disallowed);
        Location.LockTable();
        if not Location.Get(LocationCode) then begin
            Location.Init();
            Location.Code := LocationCode;
            Location.Validate(Name, LocationName(InTransit));
            if InTransit then
                Location.Validate("Use As In-Transit", true);
            Location.Insert(true);
        end;
        Location.TestField("Use As In-Transit", InTransit);
        Location.TestField("Bin Mandatory", false);
        Location.TestField("Require Receive", false);
        Location.TestField("Require Shipment", false);
        Location.TestField("Require Put-away", false);
        Location.TestField("Require Pick", false);
    end;

    local procedure EnsureInventoryPostingSetup(LocationCode: Code[10])
    var
        InventoryGroup: Record "Inventory Posting Group";
        Setup: Record "Inventory Posting Setup";
        Source: Record "Inventory Posting Setup";
    begin
        // For every inventory posting group of the company, not only those already used by items: a company
        // without items must still be able to post at the synthetic locations.
        InventoryGroup.SecurityFiltering(SecurityFilter::Disallowed);
        if InventoryGroup.FindSet() then
            repeat
                if not Setup.Get(LocationCode, InventoryGroup.Code) then begin
                    Source.Reset();
                    Source.SetRange("Invt. Posting Group Code", InventoryGroup.Code);
                    Source.SetFilter("Inventory Account", '<>%1', '');
                    if Source.FindFirst() then begin
                        Setup.Init();
                        Setup.TransferFields(Source, false);
                        Setup."Location Code" := LocationCode;
                        Setup."Invt. Posting Group Code" := InventoryGroup.Code;
                        Setup.Insert(true);
                    end;
                end;
            until InventoryGroup.Next() = 0;
    end;

    local procedure HasInventoryPosting(LocationCode: Code[10]): Boolean
    var
        Setup: Record "Inventory Posting Setup";
    begin
        Setup.SetRange("Location Code", LocationCode);
        exit(not Setup.IsEmpty());
    end;

    local procedure TransferSetupAvailable(InventorySetup: Record "Inventory Setup"): Boolean
    var
        Location: Record Location;
        SourceCode: Record "Source Code Setup";
    begin
        if (InventorySetup."Transfer Order Nos." = '') or (InventorySetup."Posted Transfer Shpt. Nos." = '') or
          (InventorySetup."Posted Transfer Rcpt. Nos." = '') then
            exit(false);
        SourceCode.Get();
        if SourceCode.Transfer = '' then
            exit(false);
        if not Location.Get(AuxiliaryLocation()) or Location."Use As In-Transit" then
            exit(false);
        if not Location.Get(TransitLocation()) or not Location."Use As In-Transit" then
            exit(false);
        exit(HasInventoryPosting(AuxiliaryLocation()) and HasInventoryPosting(TransitLocation()));
    end;

    local procedure LocationName(InTransit: Boolean): Text[100]

    begin

        if InTransit then

            exit(InTransitLbl);

        exit(OutsideStorageLbl);

    end;


    local procedure AuxiliaryLocation(): Code[10]
    begin
        exit('BCSF-AUX');
    end;

    local procedure TransitLocation(): Code[10]
    begin
        exit('BCSF-TRN');
    end;

    local procedure TransferTarget(Context: JsonObject; var ToLocation: Code[10]; var Transit: Code[10]): Boolean
    var
        Token: JsonToken;
        Settings: JsonObject;
    begin
        Context.Get('paymentSetup', Token);
        Settings := Token.AsObject();
        if not Settings.Contains('transferTo') or not Settings.Contains('transit') then
            exit(false);
        Settings.Get('transferTo', Token);
        ToLocation := CopyStr(Token.AsValue().AsText(), 1, 10);
        Settings.Get('transit', Token);
        Transit := CopyStr(Token.AsValue().AsText(), 1, 10);
        exit((ToLocation <> '') and (Transit <> ''));
    end;

    /// <summary>Deterministic plan from the seed and the captured transfer setup; independent of run id and batch order.</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Location: Code[10]): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    ProjectProcessor: Codeunit "BCSF Project Processor";
    ToLocation: Code[10];
    Transit: Code[10];
    Roll: Integer;
  begin
    Roll := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'MOVEMENT-PLAN', 1, 100);
    case true of
      Roll <= 40:
        exit(0);
      Roll <= 48:
        exit(1);
      Roll <= 56:
        exit(2);
      Roll <= 64:
        exit(3);
      Roll <= 74:
        if TransferTarget(Context, ToLocation, Transit) and (ToLocation <> Location) then
          exit(4);
      Roll <= 87:
        if AssemblyProcessor.Enabled(Context) then
          exit(5);
      else
        if ProjectProcessor.Enabled(Context) then
          exit(6);
    end;
    exit(0);
  end;

  /// <summary>True when the physical inventory difference is a surplus; otherwise a shortage.</summary>
  procedure IsSurplus(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Boolean
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    exit(Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'MOVEMENT-COUNT', 0, 1) = 1);
  end;

  /// <summary>
  /// Units for one invoice line: 1 to 3 by seed, capped at half of the planned stock reserve of the purchase
  /// (12 in the wholesale profile, otherwise the base quantity) and at the posted quantity. Reproducible by the validator.
  /// </summary>
  procedure LineUnits(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; LineIndex: Integer; PostedQuantity: Decimal): Decimal
  var
    Coordinator: Codeunit "BCSF Process Coordinator";
    Seed: Codeunit "BCSF Seed Engine";
    Reserve: Decimal;
    Units: Decimal;
    Cap: Decimal;
  begin
    if Coordinator.IsWholesaleQualityProfile(Context) then
      Reserve := 12
    else
      Reserve := Coordinator.Quantity(Context, NodeCode, LogicalKey);
    Cap := Round(Reserve / 2, 1, '<');
    Units := Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'MOVEMENT-UNITS-' + Format(LineIndex, 0, 9), 1, 3);
    if Units > Cap then
      Units := Cap;
    if Units > PostedQuantity then
      Units := PostedQuantity;
    exit(Units);
  end;

  procedure MovementDate(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; InvoiceDate: Date): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    EndingDate: Date;
  begin
    if Contract.GetDatePolicyVersion(Context) = 0 then
      exit(InvoiceDate);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(Seed.SampleDate(Context, NodeCode, Format(LogicalKey, 0, 9), 'MOVEMENT-DATE', InvoiceDate, EndingDate, false));
  end;

  procedure DocumentNo(Invoice: Record "Purch. Inv. Header"): Code[20]
  begin
    // Code[20]: keep the distinguishing tail of a full-length number instead of truncating it.
    if StrLen(Invoice."No.") < 20 then
        exit(CopyStr('M' + Invoice."No.", 1, 20));
    exit(CopyStr('M' + CopyStr(Invoice."No.", 2), 1, 20));
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure CreateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; ParentId: Guid)
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Registry: Codeunit "BCSF Record Registry";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    ProjectProcessor: Codeunit "BCSF Project Processor";
    Kind: Integer;
    Date: Date;
    SkipReason: Code[30];
    Completed: Boolean;
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    if not InvoiceLine.FindFirst() then
      Error(ResultErr);
    Kind := PlanKind(Context, NodeCode, LogicalKey, InvoiceLine."Location Code");
    if Kind = 0 then
      exit;
    Date := MovementDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    if Kind = 5 then begin
      // Assembly performs its own read-only preflight and registers its own skip.
      AssemblyProcessor.CreateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId);
      exit;
    end;
    if Kind = 6 then begin
      // Project: own read-only preflight and own documented skip.
      ProjectProcessor.CreateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId);
      exit;
    end;
    SkipReason := StockPreflight(Context, NodeCode, LogicalKey, Invoice, Kind, Date);
    if SkipReason = '' then begin
      if Kind = 4 then
        Completed := PostTransfer(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Date, ParentId, SkipReason)
      else
        Completed := PostJournal(Context, RunId, NodeCode, LogicalKey, BatchId, Invoice, Kind, Date, ParentId, SkipReason);
    end;
    if not Completed then begin
      if SkipReason = '' then
        Error(ResultErr);
      // Controlled skip before any posting: the invoice itself carries the documented reason.
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'MOVEMENT-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
    end;
  end;

  /// <summary>Read-only check of free stock (not reserved, including earlier lines of the same movement). Returns a skip reason or blank.</summary>
  local procedure StockPreflight(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header"; Kind: Integer; Date: Date): Code[30]
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Item: Record Item;
    Planned: Dictionary of [Code[20], Decimal];
    LineIndex: Integer;
    Units: Decimal;
    Used: Decimal;
  begin
    if (Kind = 1) or ((Kind = 3) and IsSurplus(Context, NodeCode, LogicalKey)) then
      exit('');
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    repeat
      LineIndex += 1;
      Units := LineUnits(Context, NodeCode, LogicalKey, LineIndex, InvoiceLine.Quantity);
      Item.Get(InvoiceLine."No.");
      Item.SetRange("Location Filter", InvoiceLine."Location Code");
      Item.SetRange("Date Filter", 0D, Date);
      Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
      Used := 0;
      if Planned.ContainsKey(InvoiceLine."No.") then
        Used := Planned.Get(InvoiceLine."No.");
      if Item.Inventory - Item."Reserved Qty. on Inventory" - Used < Units then
        exit('STOCK');
      Planned.Set(InvoiceLine."No.", Used + Units);
    until InvoiceLine.Next() = 0;
    exit('');
  end;

  local procedure CheckDimensions(DimensionSetId: Integer; ItemNo: Code[20]): Boolean
  var
    Dimensions: Codeunit DimensionManagement;
    TableIds: array[10] of Integer;
    Nos: array[10] of Code[20];
  begin
    TableIds[1] := Database::Item;
    Nos[1] := ItemNo;
    exit(Dimensions.CheckDimIDComb(DimensionSetId) and Dimensions.CheckDimValuePosting(TableIds, Nos, DimensionSetId));
  end;

  /// <summary>Posts all lines as item journal lines (adjustment or physical inventory). False plus a reason when a pre-posting check fails.</summary>
  local procedure PostJournal(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Kind: Integer; Date: Date; ParentId: Guid; var SkipReason: Code[30]): Boolean
  var
    TempLine: Record "Item Journal Line" temporary;
    InvoiceLine: Record "Purch. Inv. Line";
    SourceCode: Record "Source Code Setup";
    Item: Record Item;
    Registry: Codeunit "BCSF Record Registry";
    PostLine: Codeunit "Item Jnl.-Post Line";
    EntryType: Enum "Item Ledger Entry Type";
    Delta: Dictionary of [Code[20], Decimal];
    Units: Decimal;
    Calculated: Decimal;
    Changed: Decimal;
    Previous: Decimal;
    LineIndex: Integer;
    Surplus: Boolean;
  begin
    SourceCode.Get();
    Surplus := IsSurplus(Context, NodeCode, LogicalKey);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    repeat
      LineIndex += 1;
      Units := LineUnits(Context, NodeCode, LogicalKey, LineIndex, InvoiceLine.Quantity);
      Item.Get(InvoiceLine."No.");
      TempLine.Init();
      TempLine."Line No." := LineIndex * 10000;
      TempLine."Document Line No." := LineIndex * 10000;
      TempLine."Document No." := DocumentNo(Invoice);
      TempLine.Validate("Posting Date", Date);
      TempLine.Validate("Document Date", Date);
      if Kind = 3 then begin
        TempLine."Source Code" := SourceCode."Phys. Inventory Journal";
        TempLine.Validate("Entry Type", TempLine."Entry Type"::"Positive Adjmt.");
        TempLine.Validate("Item No.", InvoiceLine."No.");
        TempLine.Validate("Location Code", InvoiceLine."Location Code");
        TempLine."Phys. Inventory" := true;
        // Earlier lines of the same item change the calculated stock; they are posted before this one.
        Calculated := CalculatedInventory(Item, InvoiceLine."Location Code", Date);
        if Delta.ContainsKey(InvoiceLine."No.") then
          Calculated += Delta.Get(InvoiceLine."No.");
        TempLine."Qty. (Calculated)" := Calculated;
        if Surplus then
          Changed := Units
        else
          Changed := -Units;
        TempLine.Validate("Qty. (Phys. Inventory)", Calculated + Changed);
      end else begin
        TempLine."Source Code" := SourceCode."Item Journal";
        if Kind = 1 then begin
          EntryType := EntryType::"Positive Adjmt.";
          Changed := Units;
        end else begin
          EntryType := EntryType::"Negative Adjmt.";
          Changed := -Units;
        end;
        TempLine.Validate("Entry Type", EntryType);
        TempLine.Validate("Item No.", InvoiceLine."No.");
        TempLine.Validate("Location Code", InvoiceLine."Location Code");
        TempLine.Validate("Unit of Measure Code", InvoiceLine."Unit of Measure Code");
        TempLine.Validate(Quantity, Units);
        if Kind = 1 then
          TempLine.Validate("Unit Amount", Item."Unit Cost");
      end;
      Previous := 0;
      if Delta.ContainsKey(InvoiceLine."No.") then
        Previous := Delta.Get(InvoiceLine."No.");
      Delta.Set(InvoiceLine."No.", Previous + Changed);
      // Temporary line without journal template/batch: Insert(true) would require both; the standard OnInsert is not needed here.
      TempLine.Insert();
      if not CheckDimensions(TempLine."Dimension Set ID", InvoiceLine."No.") then begin
        SkipReason := 'DIMENSION';
        exit(false);
      end;
    until InvoiceLine.Next() = 0;
    // From here on only the standard posting codeunit writes; no skip is possible any more.
    TempLine.FindSet();
    repeat
      // Standard item posting; no Boolean-driven commit and no direct ledger insert.
      PostLine.RunWithCheck(TempLine);
      RegisterLine(RunId, NodeCode, LogicalKey, BatchId, ParentId, TempLine);
      CheckNonNegative(TempLine."Item No.", TempLine."Location Code", Date);
    until TempLine.Next() = 0;
    exit(true);
  end;

  local procedure CalculatedInventory(var Item: Record Item; LocationCode: Code[10]; Date: Date): Decimal
  begin
    Item.SetRange("Location Filter", LocationCode);
    Item.SetRange("Date Filter", 0D, Date);
    Item.CalcFields(Inventory);
    exit(Item.Inventory);
  end;

  /// <summary>The location stock of the item up to the movement date and in total must never be negative.</summary>
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

  local procedure RegisterLine(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; Line: Record "Item Journal Line")
  var
    ItemEntry: Record "Item Ledger Entry";
    Found: Boolean;
    ItemArtifact: Code[30];
  begin
    ItemEntry.SetRange("Document No.", Line."Document No.");
    ItemEntry.SetRange("Document Line No.", Line."Document Line No.");
    ItemEntry.SetRange("Item No.", Line."Item No.");
    ItemEntry.SetFilter("Entry Type", '%1|%2', ItemEntry."Entry Type"::"Positive Adjmt.", ItemEntry."Entry Type"::"Negative Adjmt.");
    if not ItemEntry.FindSet() then
      Error(ResultErr);
    repeat
      // One record can be registered only once per run (unique table and SystemId): the first entry of the line
      // is the per-line primary artifact, further entries keep the generic item entry artifact.
      if Found then
        ItemArtifact := Artifact('MOVE-ITEM', ItemEntry."Entry No.")
      else
        ItemArtifact := Artifact('MOVEMENT', Line."Line No." div 10000);
      Found := true;
      RegisterEntry(RunId, NodeCode, LogicalKey, BatchId, ParentId, ItemEntry, true, ItemArtifact);
    until ItemEntry.Next() = 0;
  end;

  local procedure PostTransfer(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Purch. Inv. Header"; Date: Date; ParentId: Guid; var SkipReason: Code[30]): Boolean
  var
    Header: Record "Transfer Header";
    Line: Record "Transfer Line";
    InvoiceLine: Record "Purch. Inv. Line";
    ShipmentHeader: Record "Transfer Shipment Header";
    ReceiptHeader: Record "Transfer Receipt Header";
    Registry: Codeunit "BCSF Record Registry";
    Release: Codeunit "Release Transfer Document";
    PostShipment: Codeunit "TransferOrder-Post Shipment";
    PostReceipt: Codeunit "TransferOrder-Post Receipt";
    ToLocation: Code[10];
    Transit: Code[10];
    TransferNo: Code[20];
    FromLocation: Code[10];
    LineIndex: Integer;
  begin
    if not TransferTarget(Context, ToLocation, Transit) then
      Error(ResultErr);
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    FromLocation := InvoiceLine."Location Code";
    Header.Init();
    Header.Insert(true);
    Header.Validate("Transfer-from Code", FromLocation);
    Header.Validate("Transfer-to Code", ToLocation);
    Header.Validate("In-Transit Code", Transit);
    Header.Validate("Posting Date", Date);
    Header.Validate("Shipment Date", Date);
    Header.Validate("Receipt Date", Date);
    Header.Modify(true);
    TransferNo := Header."No.";
    repeat
      LineIndex += 1;
      Line.Init();
      Line.Validate("Document No.", TransferNo);
      Line.Validate("Line No.", LineIndex * 10000);
      Line.Insert(true);
      Line.Validate("Item No.", InvoiceLine."No.");
      Line.Validate("Unit of Measure Code", InvoiceLine."Unit of Measure Code");
      Line.Validate(Quantity, LineUnits(Context, NodeCode, LogicalKey, LineIndex, InvoiceLine.Quantity));
      Line.Modify(true);
      if not CheckDimensions(Line."Dimension Set ID", InvoiceLine."No.") then begin
        // Nothing is posted yet: remove the unposted transfer order again and document the skip.
        Header.Delete(true);
        SkipReason := 'DIMENSION';
        exit(false);
      end;
    until InvoiceLine.Next() = 0;
    Release.Run(Header);
    PostShipment.SetHideValidationDialog(true);
    PostShipment.SetSuppressCommit(true);
    PostShipment.Run(Header);
    Header.Get(TransferNo);
    PostReceipt.SetHideValidationDialog(true);
    PostReceipt.SetSuppressCommit(true);
    PostReceipt.Run(Header);
    ShipmentHeader.SetRange("Transfer Order No.", TransferNo);
    ReceiptHeader.SetRange("Transfer Order No.", TransferNo);
    if (ShipmentHeader.Count() <> 1) or (ReceiptHeader.Count() <> 1) then
      Error(ResultErr);
    ShipmentHeader.FindFirst();
    ReceiptHeader.FindFirst();
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'TRANSFER-SHIPMENT', BatchId, ShipmentHeader.RecordId(), ParentId);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'TRANSFER-RECEIPT', BatchId, ReceiptHeader.RecordId(), ParentId);
    InvoiceLine.FindSet();
    repeat
      RegisterTransferEntries(RunId, NodeCode, LogicalKey, BatchId, ParentId, ShipmentHeader."No.", ReceiptHeader."No.", InvoiceLine."No.");
      CheckNonNegative(InvoiceLine."No.", FromLocation, Date);
      CheckNonNegative(InvoiceLine."No.", ToLocation, Date);
    until InvoiceLine.Next() = 0;
    exit(true);
  end;

  local procedure RegisterTransferEntries(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; ShipmentNo: Code[20]; ReceiptNo: Code[20]; ItemNo: Code[20])
  var
    ItemEntry: Record "Item Ledger Entry";
    Found: Boolean;
  begin
    ItemEntry.SetRange("Item No.", ItemNo);
    ItemEntry.SetRange("Entry Type", ItemEntry."Entry Type"::Transfer);
    ItemEntry.SetFilter("Document No.", '%1|%2', ShipmentNo, ReceiptNo);
    if ItemEntry.FindSet() then
      repeat
        Found := true;
        RegisterEntry(RunId, NodeCode, LogicalKey, BatchId, ParentId, ItemEntry, false, Artifact('MOVE-ITEM', ItemEntry."Entry No."));
      until ItemEntry.Next() = 0;
    if not Found then
      Error(ResultErr);
  end;

  /// <summary>Registers the item entry with its value entries and G/L links. Adjustments must carry a value entry.</summary>
  local procedure RegisterEntry(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; ItemEntry: Record "Item Ledger Entry"; RequireValue: Boolean; ItemArtifact: Code[30])
  var
    Value: Record "Value Entry";
    Relation: Record "G/L - Item Ledger Relation";
    GL: Record "G/L Entry";
    Registry: Codeunit "BCSF Record Registry";
  begin
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, ItemArtifact, BatchId, ItemEntry.RecordId(), ParentId);
    Value.SetRange("Item Ledger Entry No.", ItemEntry."Entry No.");
    if RequireValue and Value.IsEmpty() then
      Error(ResultErr);
    if Value.FindSet() then
      repeat
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('MOVE-VALUE', Value."Entry No."), BatchId, Value.RecordId(), ParentId);
        Relation.SetRange("Value Entry No.", Value."Entry No.");
        if Relation.FindSet() then
          repeat
            GL.Get(Relation."G/L Entry No.");
            Registry.RegisterResult(RunId, NodeCode, LogicalKey, Artifact('MOVE-GL', GL."Entry No."), BatchId, GL.RecordId(), ParentId);
          until Relation.Next() = 0;
      until Value.Next() = 0;
  end;

  /// <summary>Read-only output validation against the invoice, the deterministic plan and the actual stock per location and date.</summary>
  procedure ValidateForPurchaseInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Purch. Inv. Header")
  var
    InvoiceLine: Record "Purch. Inv. Line";
    Entry: Record "BCSF Generated Record";
    ItemEntry: Record "Item Ledger Entry";
    ShipmentHeader: Record "Transfer Shipment Header";
    ReceiptHeader: Record "Transfer Receipt Header";
    ShipmentLine: Record "Transfer Shipment Line";
    AssemblyProcessor: Codeunit "BCSF Assembly Processor";
    ProjectProcessor: Codeunit "BCSF Project Processor";
    Kind: Integer;
    ExpectedDate: Date;
    ToLocation: Code[10];
    Transit: Code[10];
    LineIndex: Integer;
    Units: Decimal;
    Expected: Decimal;
    Surplus: Boolean;
  begin
    InvoiceLine.SetRange("Document No.", Invoice."No.");
    InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
    InvoiceLine.FindSet();
    Kind := PlanKind(Context, NodeCode, LogicalKey, InvoiceLine."Location Code");
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'MOVEMENT*|TRANSFER-*|ASSEMBLY-*|PROJECT*');
    if Kind = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    Entry.SetRange("Artifact Code", 'MOVEMENT-SKIP');
    if Entry.FindFirst() then begin
      // A documented skip carries a stable reason and no posted movement.
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Purch. Inv. Header");
      if not (Entry."Skip Reason Code" in ['STOCK', 'DIMENSION']) then
        Error(ResultErr);
      Entry.SetFilter("Artifact Code", 'MOVEMENT-1|TRANSFER-*|ASSEMBLY-*|PROJECT*');
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    ExpectedDate := MovementDate(Context, NodeCode, LogicalKey, Invoice."Posting Date");
    if Kind = 5 then begin
      AssemblyProcessor.ValidateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, Invoice, ExpectedDate);
      exit;
    end;
    if Kind = 6 then begin
      ProjectProcessor.ValidateForPurchaseInvoice(Context, RunId, NodeCode, LogicalKey, Invoice, ExpectedDate);
      exit;
    end;
    Surplus := IsSurplus(Context, NodeCode, LogicalKey);
    if Kind = 4 then begin
      TransferTarget(Context, ToLocation, Transit);
      Entry.Get(RunId, NodeCode, LogicalKey, 'TRANSFER-SHIPMENT');
      Entry.TestField("Table Id", Database::"Transfer Shipment Header");
      ShipmentHeader.GetBySystemId(Entry."Record SystemId");
      ShipmentHeader.TestField("Transfer-from Code", InvoiceLine."Location Code");
      ShipmentHeader.TestField("Transfer-to Code", ToLocation);
      ShipmentHeader.TestField("Posting Date", ExpectedDate);
      Entry.Get(RunId, NodeCode, LogicalKey, 'TRANSFER-RECEIPT');
      Entry.TestField("Table Id", Database::"Transfer Receipt Header");
      ReceiptHeader.GetBySystemId(Entry."Record SystemId");
      ReceiptHeader.TestField("Transfer-to Code", ToLocation);
      ReceiptHeader.TestField("Posting Date", ExpectedDate);
    end;
    repeat
      LineIndex += 1;
      Units := LineUnits(Context, NodeCode, LogicalKey, LineIndex, InvoiceLine.Quantity);
      if Kind = 4 then begin
        ShipmentLine.Get(ShipmentHeader."No.", LineIndex * 10000);
        ShipmentLine.TestField("Item No.", InvoiceLine."No.");
        ShipmentLine.TestField(Quantity, Units);
        CheckNonNegative(InvoiceLine."No.", InvoiceLine."Location Code", ExpectedDate);
        CheckNonNegative(InvoiceLine."No.", ToLocation, ExpectedDate);
      end else begin
        Entry.Get(RunId, NodeCode, LogicalKey, Artifact('MOVEMENT', LineIndex));
        Entry.TestField("Table Id", Database::"Item Ledger Entry");
        ItemEntry.Reset();
        ItemEntry.SetRange("Document No.", DocumentNo(Invoice));
        ItemEntry.SetRange("Document Line No.", LineIndex * 10000);
        ItemEntry.SetRange("Item No.", InvoiceLine."No.");
        ItemEntry.SetRange("Location Code", InvoiceLine."Location Code");
        ItemEntry.SetRange("Posting Date", ExpectedDate);
        ItemEntry.CalcSums(Quantity);
        case Kind of
          1:
            Expected := Units;
          2:
            Expected := -Units;
          else
            if Surplus then
              Expected := Units
            else
              Expected := -Units;
        end;
        if ItemEntry.Quantity <> Expected then
          Error(ResultErr);
        CheckNonNegative(InvoiceLine."No.", InvoiceLine."Location Code", ExpectedDate);
      end;
    until InvoiceLine.Next() = 0;
  end;

  local procedure Artifact(Prefix: Code[10]; EntryNo: Integer): Code[30]
  begin
    exit(CopyStr(Prefix + '-' + Format(EntryNo, 0, 9), 1, 30));
  end;

  var
    OutsideStorageLbl: Label 'Outside storage';
        InTransitLbl: Label 'Goods in transit';
    SetupErr: Label 'The inventory movement setup is not supported or changed. Review the item journal source codes, the transfer number series and the synthetic transfer locations.';
    ResultErr: Label 'Inventory movement results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain posting.';
}
