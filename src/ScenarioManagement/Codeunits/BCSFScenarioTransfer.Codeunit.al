namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 90147 "BCSF Scenario Transfer"
{
  Access = Internal;

  procedure ExportSelection(var Selection: Record "BCSF Scenario")
  var
    Scenario: Record "BCSF Scenario";
    Blob: Codeunit "Temp Blob";
    Root: JsonObject;
    Scenarios: JsonArray;
    Output: OutStream;
    Input: InStream;
    FileName: Text;
  begin
    if (Selection.Count() = 0) or (Selection.Count() > 250) then
      Error(CountErr);
    // All scenario and child edits take the parent lock, so the exported collections are consistent.
    Scenario.LockTable();
    if Selection.FindSet() then
      repeat
        Scenario.Get(Selection."Scenario Id");
        Scenarios.Add(WriteScenario(Scenario));
        if Scenarios.Count() > 250 then
          Error(CountErr);
      until Selection.Next() = 0;
    if Scenarios.Count() = 0 then
      Error(CountErr);
    Root.Add('format', FormatTok);
    Root.Add('schemaVersion', 1);
    Root.Add('scenarios', Scenarios);
    Blob.CreateOutStream(Output, TextEncoding::UTF8);
    Root.WriteTo(Output);
    Clear(Output);
    if Blob.Length() > MaxBytes() then
      Error(SizeErr);
    Blob.CreateInStream(Input, TextEncoding::UTF8);
    FileName := FileNameTok;
    DownloadFromStream(Input, '', '', '', FileName);
  end;

  procedure ImportSelection()
  var
    Contract: Codeunit "BCSF Contract JSON";
    Root: JsonObject;
    Scenarios: JsonArray;
    Input: InStream;
    MissingReferences: Text;
  begin
    if not UploadIntoStream(FilterLbl, Input) then
      exit;
    Root := ReadPackage(Input);
    if (Contract.GetText(Root, 'format') <> FormatTok) or (Contract.GetInteger(Root, 'schemaVersion') <> 1) then
      Error(FormatErr);
    Scenarios := ReadArray(Root, 'scenarios', 250);
    if Scenarios.Count() = 0 then
      Error(CountErr);
    if not Confirm(ImportQst, false, Scenarios.Count()) then
      exit;
    ImportConfirmed(Scenarios, MissingReferences);
    Message(ImportedLbl, Scenarios.Count());
    if MissingReferences <> '' then
      Message(MissingReferencesLbl, MissingReferences);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure ImportConfirmed(Scenarios: JsonArray; var MissingReferences: Text)
  var
    Scenario: Record "BCSF Scenario";
    SetupMgt: Codeunit "BCSF Setup Management";
    Item: JsonToken;
  begin
    Scenario.LockTable();
    SetupMgt.EnsureInitialized();
    foreach Item in Scenarios do
      MissingReferences += ReadScenario(Item.AsObject());
  end;

  local procedure ReadPackage(var Upload: InStream): JsonObject
  var
    Blob: Codeunit "Temp Blob";
    Input: InStream;
    Output: OutStream;
    Root: JsonObject;
    UploadLength: BigInteger;
  begin
    // File uploads have a known size. Reject unknown lengths before copying.
    UploadLength := Upload.Length();
    if (UploadLength <= 0) or (UploadLength > MaxBytes()) then
      Error(SizeErr);

    Blob.CreateOutStream(Output);
    CopyStream(Output, Upload);
    Clear(Output);
    if Blob.Length() <> UploadLength then
      Error(SizeErr);
    Blob.CreateInStream(Input, TextEncoding::UTF8);
    if not Root.ReadFrom(Input) then
      Error(FormatErr);
    exit(Root);
  end;

  local procedure WriteScenario(Scenario: Record "BCSF Scenario"): JsonObject
  var
    ScenarioModule: Record "BCSF Scenario Module";
    Target: Record "BCSF Data Target";
    Item: JsonObject;
    Child: JsonObject;
    Modules: JsonArray;
    Targets: JsonArray;
  begin
    Item.Add('description', Scenario.Description);
    Item.Add('profileCode', Scenario."Profile Code");
    Item.Add('profileVersion', Scenario."Profile Version");
    Item.Add('usageMode', Scenario."Usage Mode".AsInteger());
    Item.Add('processMode', Scenario."Process Mode".AsInteger());
    Item.Add('seed', Scenario.Seed);
    Item.Add('startingDate', Format(Scenario."Starting Date", 0, 9));
    Item.Add('endingDate', Format(Scenario."Ending Date", 0, 9));
    Item.Add('dataLanguage', Scenario."Data Language".AsInteger());
    Item.Add('batchSize', Scenario."Batch Size");
    Item.Add('financeMode', Scenario."Finance Mode".AsInteger());
    Item.Add('countryCode', Scenario."Partner Country Code");
    Item.Add('customerPostingGroup', Scenario."Customer Posting Group");
    Item.Add('vendorPostingGroup', Scenario."Vendor Posting Group");
    Item.Add('genBusPostingGroup', Scenario."Gen. Bus. Posting Group");
    Item.Add('vatBusPostingGroup', Scenario."VAT Bus. Posting Group");
    Item.Add('cashTerms', Scenario."Cash Terms Code");
    Item.Add('smallTerms', Scenario."Small Terms Code");
    Item.Add('mediumTerms', Scenario."Medium Terms Code");
    Item.Add('largeTerms', Scenario."Large Terms Code");
    Item.Add('b2cPercent', Scenario."B2C Percent");
    Item.Add('smallCreditLimit', Scenario."Small Credit Limit");
    Item.Add('mediumCreditLimit', Scenario."Medium Credit Limit");
    Item.Add('largeCreditLimit', Scenario."Large Credit Limit");
    Item.Add('b2cCreditLimit', Scenario."B2C Credit Limit");
    Item.Add('currencyCode', Scenario."Partner Currency Code");
    Item.Add('paymentMethod', Scenario."Partner Payment Method");
    Item.Add('dimension1', Scenario."Partner Dimension 1");
    Item.Add('dimension2', Scenario."Partner Dimension 2");
    Item.Add('salesSourceRunId', Format(Scenario."Sales Source Run Id", 0, 4));
    // Posting approval is deliberately not portable to another company.
    Item.Add('itemBaseUnit', Scenario."Item Base Unit");
    Item.Add('itemPackUnit', Scenario."Item Pack Unit");
    Item.Add('itemInventoryGroup', Scenario."Item Inventory Group");
    Item.Add('itemProductGroup', Scenario."Item Product Group");
    Item.Add('itemVATProductGroup', Scenario."Item VAT Product Group");
    Item.Add('itemLocation', Scenario."Item Location Code");
    Item.Add('itemVendor', Scenario."Item Vendor No.");
    Item.Add('itemSecondVendor', Scenario."Item Second Vendor No.");

    ScenarioModule.SetRange("Scenario Id", Scenario."Scenario Id");
    if ScenarioModule.FindSet() then
      repeat
        Clear(Child);
        Child.Add('module', ScenarioModule.Module.AsInteger());
        Child.Add('enabled', ScenarioModule.Enabled);
        Modules.Add(Child);
      until ScenarioModule.Next() = 0;
    Target.SetRange("Scenario Id", Scenario."Scenario Id");
    if Target.FindSet() then
      repeat
        Clear(Child);
        Child.Add('entity', Target.Entity.AsInteger());
        Child.Add('quantity', Target.Quantity);
        Child.Add('processMode', Target."Process Mode".AsInteger());
        Child.Add('unpostedPercent', Target."Unposted Percent");
        Child.Add('postedPercent', Target."Posted Percent");
        Child.Add('partialPercent', Target."Partial Percent");
        Targets.Add(Child);
      until Target.Next() = 0;
    Item.Add('modules', Modules);
    Item.Add('targets', Targets);
    exit(Item);
  end;

  local procedure ReadScenario(Item: JsonObject): Text
  var
    Scenario: Record "BCSF Scenario";
    ScenarioModule: Record "BCSF Scenario Module";
    Target: Record "BCSF Data Target";
    Contract: Codeunit "BCSF Contract JSON";
    Child: JsonObject;
    Token: JsonToken;
    Modules: JsonArray;
    Targets: JsonArray;
  begin
    Scenario.Init();
    Scenario."Scenario Id" := CreateGuid();
    Scenario.Description := CopyStr(ReadText(Item, 'description', MaxStrLen(Scenario.Description)), 1, MaxStrLen(Scenario.Description));
    Scenario."Profile Code" := CopyStr(ReadText(Item, 'profileCode', MaxStrLen(Scenario."Profile Code")), 1, MaxStrLen(Scenario."Profile Code"));
    Scenario."Profile Version" := CopyStr(ReadText(Item, 'profileVersion', MaxStrLen(Scenario."Profile Version")), 1, MaxStrLen(Scenario."Profile Version"));
    Scenario."Usage Mode" := "BCSF Usage Mode".FromInteger(Contract.GetInteger(Item, 'usageMode'));
    Scenario."Process Mode" := "BCSF Process Mode".FromInteger(Contract.GetInteger(Item, 'processMode'));
    Scenario.Seed := Contract.GetInteger(Item, 'seed');
    Scenario."Starting Date" := ReadDate(Item, 'startingDate');
    Scenario."Ending Date" := ReadDate(Item, 'endingDate');
    Scenario."Data Language" := "BCSF Data Language".FromInteger(Contract.GetInteger(Item, 'dataLanguage'));
    Scenario."Batch Size" := Contract.GetInteger(Item, 'batchSize');
    Scenario."Finance Mode" := "BCSF Finance Mode".FromInteger(Contract.GetInteger(Item, 'financeMode'));
    Scenario."Partner Country Code" := CopyStr(ReadText(Item, 'countryCode', MaxStrLen(Scenario."Partner Country Code")), 1, MaxStrLen(Scenario."Partner Country Code"));
    Scenario."Customer Posting Group" := CopyStr(ReadText(Item, 'customerPostingGroup', MaxStrLen(Scenario."Customer Posting Group")), 1, MaxStrLen(Scenario."Customer Posting Group"));
    Scenario."Vendor Posting Group" := CopyStr(ReadText(Item, 'vendorPostingGroup', MaxStrLen(Scenario."Vendor Posting Group")), 1, MaxStrLen(Scenario."Vendor Posting Group"));
    Scenario."Gen. Bus. Posting Group" := CopyStr(ReadText(Item, 'genBusPostingGroup', MaxStrLen(Scenario."Gen. Bus. Posting Group")), 1, MaxStrLen(Scenario."Gen. Bus. Posting Group"));
    Scenario."VAT Bus. Posting Group" := CopyStr(ReadText(Item, 'vatBusPostingGroup', MaxStrLen(Scenario."VAT Bus. Posting Group")), 1, MaxStrLen(Scenario."VAT Bus. Posting Group"));
    Scenario."Cash Terms Code" := CopyStr(ReadText(Item, 'cashTerms', MaxStrLen(Scenario."Cash Terms Code")), 1, MaxStrLen(Scenario."Cash Terms Code"));
    Scenario."Small Terms Code" := CopyStr(ReadText(Item, 'smallTerms', MaxStrLen(Scenario."Small Terms Code")), 1, MaxStrLen(Scenario."Small Terms Code"));
    Scenario."Medium Terms Code" := CopyStr(ReadText(Item, 'mediumTerms', MaxStrLen(Scenario."Medium Terms Code")), 1, MaxStrLen(Scenario."Medium Terms Code"));
    Scenario."Large Terms Code" := CopyStr(ReadText(Item, 'largeTerms', MaxStrLen(Scenario."Large Terms Code")), 1, MaxStrLen(Scenario."Large Terms Code"));
    Scenario."B2C Percent" := Contract.GetInteger(Item, 'b2cPercent');
    Scenario."Small Credit Limit" := ReadDecimal(Item, 'smallCreditLimit');
    Scenario."Medium Credit Limit" := ReadDecimal(Item, 'mediumCreditLimit');
    Scenario."Large Credit Limit" := ReadDecimal(Item, 'largeCreditLimit');
    Scenario."B2C Credit Limit" := ReadDecimal(Item, 'b2cCreditLimit');
    if Item.Contains('currencyCode') then
      Scenario."Partner Currency Code" := CopyStr(ReadText(Item, 'currencyCode', MaxStrLen(Scenario."Partner Currency Code")), 1, MaxStrLen(Scenario."Partner Currency Code"));
    if Item.Contains('paymentMethod') then
      Scenario."Partner Payment Method" := CopyStr(ReadText(Item, 'paymentMethod', MaxStrLen(Scenario."Partner Payment Method")), 1, MaxStrLen(Scenario."Partner Payment Method"));
    if Item.Contains('dimension1') then
      Scenario."Partner Dimension 1" := CopyStr(ReadText(Item, 'dimension1', MaxStrLen(Scenario."Partner Dimension 1")), 1, MaxStrLen(Scenario."Partner Dimension 1"));
    if Item.Contains('dimension2') then
      Scenario."Partner Dimension 2" := CopyStr(ReadText(Item, 'dimension2', MaxStrLen(Scenario."Partner Dimension 2")), 1, MaxStrLen(Scenario."Partner Dimension 2"));
    if Item.Contains('salesSourceRunId') then
      Evaluate(Scenario."Sales Source Run Id", ReadText(Item, 'salesSourceRunId', 50));
    Scenario."Sales Posting Approved" := false;
    if Item.Contains('itemBaseUnit') then
      Scenario."Item Base Unit" := CopyStr(ReadText(Item, 'itemBaseUnit', MaxStrLen(Scenario."Item Base Unit")), 1, MaxStrLen(Scenario."Item Base Unit"));
    if Item.Contains('itemPackUnit') then
      Scenario."Item Pack Unit" := CopyStr(ReadText(Item, 'itemPackUnit', MaxStrLen(Scenario."Item Pack Unit")), 1, MaxStrLen(Scenario."Item Pack Unit"));
    if Item.Contains('itemInventoryGroup') then
      Scenario."Item Inventory Group" := CopyStr(ReadText(Item, 'itemInventoryGroup', MaxStrLen(Scenario."Item Inventory Group")), 1, MaxStrLen(Scenario."Item Inventory Group"));
    if Item.Contains('itemProductGroup') then
      Scenario."Item Product Group" := CopyStr(ReadText(Item, 'itemProductGroup', MaxStrLen(Scenario."Item Product Group")), 1, MaxStrLen(Scenario."Item Product Group"));
    if Item.Contains('itemVATProductGroup') then
      Scenario."Item VAT Product Group" := CopyStr(ReadText(Item, 'itemVATProductGroup', MaxStrLen(Scenario."Item VAT Product Group")), 1, MaxStrLen(Scenario."Item VAT Product Group"));
    if Item.Contains('itemLocation') then
      Scenario."Item Location Code" := CopyStr(ReadText(Item, 'itemLocation', MaxStrLen(Scenario."Item Location Code")), 1, MaxStrLen(Scenario."Item Location Code"));
    if Item.Contains('itemVendor') then
      Scenario."Item Vendor No." := CopyStr(ReadText(Item, 'itemVendor', MaxStrLen(Scenario."Item Vendor No.")), 1, MaxStrLen(Scenario."Item Vendor No."));
    if Item.Contains('itemSecondVendor') then
      Scenario."Item Second Vendor No." := CopyStr(ReadText(Item, 'itemSecondVendor', MaxStrLen(Scenario."Item Second Vendor No.")), 1, MaxStrLen(Scenario."Item Second Vendor No."));
    Scenario.Insert(true);
    Modules := ReadArray(Item, 'modules', 12);
    foreach Token in Modules do begin
      Child := Token.AsObject();
      ScenarioModule.Init();
      ScenarioModule."Scenario Id" := Scenario."Scenario Id";
      ScenarioModule.Module := "BCSF Module Type".FromInteger(Contract.GetInteger(Child, 'module'));
      ScenarioModule.Enabled := Contract.GetBoolean(Child, 'enabled');
      ScenarioModule.Insert(true);
    end;
    Targets := ReadArray(Item, 'targets', 10);
    foreach Token in Targets do begin
      Child := Token.AsObject();
      Target.Init();
      Target."Scenario Id" := Scenario."Scenario Id";
      Target.Validate(Entity, "BCSF Entity Type".FromInteger(Contract.GetInteger(Child, 'entity')));
      Target.Quantity := Contract.GetInteger(Child, 'quantity');
      Target."Process Mode" := "BCSF Process Mode".FromInteger(Contract.GetInteger(Child, 'processMode'));
      Target."Unposted Percent" := ReadDecimal(Child, 'unpostedPercent');
      Target."Posted Percent" := ReadDecimal(Child, 'postedPercent');
      Target."Partial Percent" := ReadDecimal(Child, 'partialPercent');
      Target.Insert(true);
    end;
    exit(DescribeMissingReferences(Scenario));
  end;

  local procedure DescribeMissingReferences(Scenario: Record "BCSF Scenario"): Text
  var
    Country: Record "Country/Region";
    CustomerGroup: Record "Customer Posting Group";
    VendorGroup: Record "Vendor Posting Group";
    GeneralGroup: Record "Gen. Business Posting Group";
    VATGroup: Record "VAT Business Posting Group";
    Terms: Record "Payment Terms";
    Currency: Record Currency;
    PaymentMethod: Record "Payment Method";
    Dimension: Record "Dimension Value";
    GL: Record "General Ledger Setup";
    Missing: Text;
    TermCode: Code[10];
    TermCodes: List of [Code[10]];
  begin
    if (Scenario."Partner Country Code" <> '') and not Country.Get(Scenario."Partner Country Code") then
      Missing += StrSubstNo(ReferenceLbl, Country.TableCaption(), Scenario."Partner Country Code");
    if not (Scenario."Customer Posting Group" in ['', 'BCSF-DEMO', 'BCSF03', 'BCSF04', 'INLAND03', 'INLAND04']) and not CustomerGroup.Get(Scenario."Customer Posting Group") then
        Missing += StrSubstNo(ReferenceLbl, CustomerGroup.TableCaption(), Scenario."Customer Posting Group");
      if not (Scenario."Vendor Posting Group" in ['', 'BCSF-DEMO', 'BCSF03', 'BCSF04', 'INLAND03', 'INLAND04']) and not VendorGroup.Get(Scenario."Vendor Posting Group") then
        Missing += StrSubstNo(ReferenceLbl, VendorGroup.TableCaption(), Scenario."Vendor Posting Group");
      if not (Scenario."Gen. Bus. Posting Group" in ['', 'BCSF-DEMO', 'BCSF03', 'BCSF04', 'INLAND03', 'INLAND04']) and not GeneralGroup.Get(Scenario."Gen. Bus. Posting Group") then
        Missing += StrSubstNo(ReferenceLbl, GeneralGroup.TableCaption(), Scenario."Gen. Bus. Posting Group");
      if not (Scenario."VAT Bus. Posting Group" in ['', 'BCSF-DEMO', 'BCSF03', 'BCSF04', 'INLAND03', 'INLAND04']) and not VATGroup.Get(Scenario."VAT Bus. Posting Group") then
        Missing += StrSubstNo(ReferenceLbl, VATGroup.TableCaption(), Scenario."VAT Bus. Posting Group");
    TermCodes.Add(Scenario."Cash Terms Code");
    TermCodes.Add(Scenario."Small Terms Code");
    TermCodes.Add(Scenario."Medium Terms Code");
    TermCodes.Add(Scenario."Large Terms Code");
    foreach TermCode in TermCodes do
      if not (TermCode in ['', 'NET00', 'NET14', 'NET30', 'NET60']) and not Terms.Get(TermCode) then
        Missing += StrSubstNo(ReferenceLbl, Terms.TableCaption(), TermCode);
    if Scenario."Partner Currency Code" <> '' then
      if not Currency.Get(Scenario."Partner Currency Code") then
        Missing += StrSubstNo(ReferenceLbl, Currency.TableCaption(), Scenario."Partner Currency Code");
    if Scenario."Partner Payment Method" <> '' then
      if not PaymentMethod.Get(Scenario."Partner Payment Method") then
        Missing += StrSubstNo(ReferenceLbl, PaymentMethod.TableCaption(), Scenario."Partner Payment Method");
    if not GL.Get() then
      Clear(GL);
    if Scenario."Partner Dimension 1" <> '' then
      if not Dimension.Get(GL."Global Dimension 1 Code", Scenario."Partner Dimension 1") then
        Missing += StrSubstNo(ReferenceLbl, Dimension.TableCaption(), GL."Global Dimension 1 Code" + '/' + Scenario."Partner Dimension 1");
    if Scenario."Partner Dimension 2" <> '' then
      if not Dimension.Get(GL."Global Dimension 2 Code", Scenario."Partner Dimension 2") then
        Missing += StrSubstNo(ReferenceLbl, Dimension.TableCaption(), GL."Global Dimension 2 Code" + '/' + Scenario."Partner Dimension 2");
    if Missing <> '' then
      exit(Scenario.Description + ': ' + Missing + '\');
    exit('');
  end;

  local procedure ReadArray(Item: JsonObject; FieldName: Text; Maximum: Integer): JsonArray
  var
    Token: JsonToken;
    ListValue: JsonArray;
  begin
    if not Item.Get(FieldName, Token) then
      Error(FieldErr, FieldName);
    if not Token.IsArray() then
      Error(FieldErr, FieldName);
    ListValue := Token.AsArray();
    if ListValue.Count() > Maximum then
      Error(FieldErr, FieldName);
    exit(ListValue);
  end;

  local procedure ReadText(Item: JsonObject; FieldName: Text; Maximum: Integer): Text
  var
    Contract: Codeunit "BCSF Contract JSON";
    Value: Text;
  begin
    Value := Contract.GetText(Item, FieldName);
    if StrLen(Value) > Maximum then
      Error(FieldErr, FieldName);
    exit(Value);
  end;

  local procedure ReadDate(Item: JsonObject; FieldName: Text): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Value: Date;
  begin
    if not Evaluate(Value, Contract.GetText(Item, FieldName), 9) then
      Error(FieldErr, FieldName);
    exit(Value);
  end;

  local procedure ReadDecimal(Item: JsonObject; FieldName: Text): Decimal
  var
    Token: JsonToken;
  begin
    if not Item.Get(FieldName, Token) then
      Error(FieldErr, FieldName);
    exit(Token.AsValue().AsDecimal());
  end;

  local procedure MaxBytes(): Integer
  begin
    exit(4194304);
  end;

  var
    MissingReferencesLbl: Label 'Missing reference codes in this company: %1. Review these template settings before starting. Imported templates have not started any runs.', Comment = '%1 = templates and missing table/code references';
    ReferenceLbl: Label '%1 [%2]; ', Comment = '%1 = reference table, %2 = missing code';
    FormatTok: Label 'BCSF-SCENARIOS', Locked = true;
    FileNameTok: Label 'BCSF-Scenarios.json', Locked = true;
    FilterLbl: Label 'Scenario bundles (*.json)|*.json';
    CountErr: Label 'Select between 1 and 250 scenarios per bundle.';
    FormatErr: Label 'The file is not a Scenario Factory bundle in supported schema version 1.';
    SizeErr: Label 'The scenario bundle must not be empty or exceed 4 MiB.';
    FieldErr: Label 'The scenario bundle contains an invalid value for %1.', Comment = '%1 = JSON field name';
    ImportQst: Label 'Import %1 scenarios as new copies in the current company? Existing scenarios are not replaced.', Comment = '%1 = number of scenarios';
    ImportedLbl: Label 'Imported %1 scenarios. Check copied posting group and payment term codes in this company before running.', Comment = '%1 = number of scenarios';
}
