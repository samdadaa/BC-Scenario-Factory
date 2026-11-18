namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 90256 "BCSF Partner Rules"
{
  Access = Internal;

  procedure ReadSettings(Context: JsonObject): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
  begin
    Contract.CheckContext(Context);
    if not Context.Get('partnerSetup', Token) then
      Error(SettingsErr);
    Settings := Token.AsObject();
    if Contract.GetInteger(Settings, 'version') <> 1 then
      Error(SettingsErr);
    exit(Settings);
  end;

  procedure CheckTarget(Context: JsonObject; Target: JsonObject; EntityCode: Code[30]; ModuleCode: Code[30])
  var
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Contract.CheckTarget(Context, Target);
    if (Contract.GetCode(Target, 'entityCode') <> EntityCode) or
      (Contract.GetCode(Target, 'moduleCode') <> ModuleCode) or
      (Contract.GetInteger(Target, 'processMode') <> 0) then
      Error(TargetErr);
  end;

  /// <summary>Read-only exact master-data prerequisites. Product posting matrices belong to future document/item generators.</summary>
  procedure CheckSetup(Context: JsonObject; EntityCode: Code[30])
  var
    Country: Record "Country/Region";
    CustomerGroup: Record "Customer Posting Group";
    VendorGroup: Record "Vendor Posting Group";
    GeneralGroup: Record "Gen. Business Posting Group";
    VATGroup: Record "VAT Business Posting Group";
    Account: Record "G/L Account";
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    Settings: JsonObject;
    BaseDate: Date;
    AccountNo: Code[20];
    ConsumerPercent: Integer;
  begin
    if not (EntityCode in ['CUSTOMER', 'VENDOR']) then
      Error(TargetErr);
    Settings := ReadSettings(Context);
    Country.SecurityFiltering(SecurityFilter::Disallowed);
    GeneralGroup.SecurityFiltering(SecurityFilter::Disallowed);
    VATGroup.SecurityFiltering(SecurityFilter::Disallowed);
    Country.Get(Contract.GetCode(Settings, 'countryCode'));
    if (Contract.GetInteger(Context, 'financeMode') <> 0) and (Country.Code <> 'DE') then
      Error(CountryErr);
    CheckContactSetup(Settings, EntityCode);
    GeneralGroup.Get(Contract.GetCode(Settings, 'genBusPostingGroup'));
    VATGroup.Get(Contract.GetCode(Settings, 'vatBusPostingGroup'));
    if not Evaluate(BaseDate, Contract.GetText(Context, 'startingDate'), 9) or (BaseDate = 0D) then
      Error(SettingsErr);
    ConsumerPercent := Contract.GetInteger(Settings, 'b2cPercent');
    if (ConsumerPercent < 0) or (ConsumerPercent > 100) or
      (GetDecimal(Settings, 'smallCreditLimit') < 0) or (GetDecimal(Settings, 'mediumCreditLimit') < 0) or
      (GetDecimal(Settings, 'largeCreditLimit') < 0) or (GetDecimal(Settings, 'b2cCreditLimit') < 0) then
      Error(SettingsErr);
    CheckTerms(Settings, 'smallTerms', BaseDate, false);
    CheckTerms(Settings, 'mediumTerms', BaseDate, false);
    CheckTerms(Settings, 'largeTerms', BaseDate, false);
    if EntityCode = 'CUSTOMER' then begin
      CustomerGroup.SecurityFiltering(SecurityFilter::Disallowed);
      CustomerGroup.Get(Contract.GetCode(Settings, 'customerPostingGroup'));
      AccountNo := CustomerGroup."Receivables Account";
      if AccountNo <> Contract.GetCode(Settings, 'customerAccountNo') then
        Error(SettingsErr);
      CheckSeries(Settings, 'customerNoSeries', BaseDate);
      if ConsumerPercent > 0 then
        CheckTerms(Settings, 'cashTerms', BaseDate, true);
    end else begin
      VendorGroup.SecurityFiltering(SecurityFilter::Disallowed);
      VendorGroup.Get(Contract.GetCode(Settings, 'vendorPostingGroup'));
      AccountNo := VendorGroup."Payables Account";
      if AccountNo <> Contract.GetCode(Settings, 'vendorAccountNo') then
        Error(SettingsErr);
      CheckSeries(Settings, 'vendorNoSeries', BaseDate);
    end;
    Account.SecurityFiltering(SecurityFilter::Disallowed);
    Account.Get(AccountNo);
    Account.TestField(Blocked, false);
    Account.TestField("Account Type", Account."Account Type"::Posting);
    Account.TestField("Direct Posting", false);
    // Also checks captured seed/rule/catalog versions before any standard number is consumed.
    Seed.BuildValues(Context, EntityCode, '1');
  end;

  local procedure CheckContactSetup(Settings: JsonObject; EntityCode: Code[30])
  var
    Marketing: Record "Marketing Setup";
    Contact: Record Contact;
    Relation: Record "Contact Business Relation";
    BusinessRelation: Record "Business Relation";
    Contract: Codeunit "BCSF Contract JSON";
    RelationCode: Code[10];
  begin
    // Customer/Vendor standard insert reads Marketing Setup even when automatic contacts are disabled.
    Marketing.SecurityFiltering(SecurityFilter::Disallowed);
    Marketing.Get();
    if EntityCode = 'CUSTOMER' then begin
      RelationCode := Marketing."Bus. Rel. Code for Customers";
      if RelationCode <> Contract.GetText(Settings, 'customerContactRelation') then
        Error(SettingsErr);
    end else begin
      RelationCode := Marketing."Bus. Rel. Code for Vendors";
      if RelationCode <> Contract.GetText(Settings, 'vendorContactRelation') then
        Error(SettingsErr);
    end;
    if RelationCode = '' then
      exit;
    Contact.SecurityFiltering(SecurityFilter::Disallowed);
    Relation.SecurityFiltering(SecurityFilter::Disallowed);
    BusinessRelation.SecurityFiltering(SecurityFilter::Disallowed);
    BusinessRelation.Get(RelationCode);
    if not Contact.ReadPermission() or not Contact.WritePermission() or
      not Relation.ReadPermission() or not Relation.WritePermission() then
      Error(ContactPermissionErr);
    if Marketing."Contact Nos." <> Contract.GetText(Settings, 'contactNoSeries') then
      Error(SettingsErr);
    CheckSeries(Settings, 'contactNoSeries', WorkDate());
  end;

  local procedure CheckTerms(Settings: JsonObject; FieldName: Text; BaseDate: Date; Immediate: Boolean)
  var
    Terms: Record "Payment Terms";
    Contract: Codeunit "BCSF Contract JSON";
    DueDate: Date;
  begin
    Terms.SecurityFiltering(SecurityFilter::Disallowed);
    Terms.Get(Contract.GetCode(Settings, FieldName));
    Terms.TestField("Discount %", 0);
    if Format(Terms."Due Date Calculation", 0, 9) <> Contract.GetText(Settings, FieldName + 'Formula') then
      Error(SettingsErr);
    DueDate := CalcDate(Terms."Due Date Calculation", BaseDate);
    if (DueDate < BaseDate) or (Immediate and (DueDate <> BaseDate)) then
      Error(TermsErr);
  end;

  local procedure CheckSeries(Settings: JsonObject; FieldName: Text; BaseDate: Date)
  var
    Series: Record "No. Series";
    NoSeries: Codeunit "No. Series";
    Contract: Codeunit "BCSF Contract JSON";
  begin
    Series.SecurityFiltering(SecurityFilter::Disallowed);
    Series.Get(Contract.GetCode(Settings, FieldName));
    Series.TestField("Default Nos.", true);
    // Peek never consumes a number. Execution uses this same captured series and date.
    if NoSeries.PeekNextNo(Series.Code, BaseDate) = '' then
      Error(SettingsErr);
  end;

  procedure GetDecimal(Value: JsonObject; FieldName: Text): Decimal
  var
    Token: JsonToken;
  begin
    if not Value.Get(FieldName, Token) then
      Error(SettingsErr);
    exit(Token.AsValue().AsDecimal());
  end;

  procedure BuildValues(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): JsonObject
  var
    Seed: Codeunit "BCSF Seed Engine";
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
    Values: JsonObject;
    Result: JsonObject;
    KeyText: Text;
    ClassCode: Text;
    City: Text;
    Street: Text;
    Terms: Text;
    Name: Text;
    CreditLimit: Decimal;
    Consumer: Boolean;
    German: Boolean;
    Region: Integer;
    Priority: Integer;
  begin
    if (LogicalKey <= 0) or not (EntityCode in ['CUSTOMER', 'VENDOR']) then
      Error(TargetErr);
    Settings := ReadSettings(Context);
    KeyText := Format(LogicalKey, 0, 9);
    Values := Seed.BuildValues(Context, EntityCode, KeyText);
    ClassCode := Contract.GetText(Values, 'classCode');
    Consumer := (EntityCode = 'CUSTOMER') and
      (Seed.SampleInteger(Context, EntityCode, KeyText, 'B2C', 1, 100) <= Contract.GetInteger(Settings, 'b2cPercent'));
    Region := Seed.SampleInteger(Context, EntityCode, KeyText, 'REGION', 1, 4);
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    if German then begin
      City := SelectStr(Region, GermanCitiesTok);
      Street := SelectStr(Seed.SampleInteger(Context, EntityCode, KeyText, 'STREET', 1, 6), GermanStreetsTok);
    end else begin
      City := SelectStr(Region, EnglishCitiesTok);
      Street := SelectStr(Seed.SampleInteger(Context, EntityCode, KeyText, 'STREET', 1, 6), EnglishStreetsTok);
    end;
    Name := Contract.GetText(Values, 'companyName');
    Terms := Contract.GetText(Settings, ClassCode + 'Terms');
    CreditLimit := GetDecimal(Settings, ClassCode + 'CreditLimit');
    case ClassCode of
      'small': Priority := 3;
      'medium': Priority := 2;
      'large': Priority := 1;
      else Error(SettingsErr);
    end;
    if Consumer then begin
      Name := Contract.GetText(Values, 'personName');
      Terms := Contract.GetText(Settings, 'cashTerms');
      CreditLimit := GetDecimal(Settings, 'b2cCreditLimit');
    end;
    Result.Add('name', Name);
    Result.Add('contact', Contract.GetText(Values, 'personName'));
    Result.Add('address', Street + ' ' + Format(Seed.SampleInteger(Context, EntityCode, KeyText, 'HOUSE', 1, 199), 0, 9));
    Result.Add('city', City);
    Result.Add('postCode', '0000' + Format(Region, 0, 9));
    Result.Add('countryCode', Contract.GetText(Settings, 'countryCode'));
    Result.Add('email', LowerCase(EntityCode) + '.' + KeyText + '@example.invalid');
    Result.Add('classCode', ClassCode);
    Result.Add('paymentTerms', Terms);
    Result.Add('creditLimit', CreditLimit);
    Result.Add('consumer', Consumer);
    Result.Add('priority', Priority);
    exit(Result);
  end;

  procedure Plan(Code: Code[30]; Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Batch: JsonObject;
    Quantity: Integer;
    BatchSize: Integer;
    LastKey: Integer;
  begin
    Contract.CheckTarget(Context, Target);
    Clear(Batches);
    if (FirstKey <= 0) or (MaximumBatches <= 0) or (MaximumBatches > 100) then
      Error(TargetErr);
    Quantity := Contract.GetInteger(Target, 'quantity');
    BatchSize := Contract.GetInteger(Context, 'batchSize');
    while (FirstKey <= Quantity) and (Batches.Count() < MaximumBatches) do begin
      LastKey := Quantity;
      if Quantity - FirstKey + 1 > BatchSize then
        LastKey := FirstKey + BatchSize - 1;
      Clear(Batch);
      Batch.Add('batchKey', Code + '/' + Format(FirstKey, 0, 9) + '-' + Format(LastKey, 0, 9));
      Batch.Add('firstKey', FirstKey);
      Batch.Add('lastKey', LastKey);
      Batches.Add(Batch);
      if LastKey = Quantity then
        exit;
      FirstKey := LastKey + 1;
    end;
  end;

  /// <summary>Real execution only: compare the immutable stored payload and require current worker ownership via BackgroundProcessing.</summary>
  procedure EnsureExecution(Context: JsonObject; Target: JsonObject; Batch: JsonObject; GeneratorCode: Code[30]; var RunId: Guid; var BatchId: Guid)
  var
    Header: Record "BCSF Run Header";
    Step: Record "BCSF Run Step";
    Manager: Codeunit "BCSF Scenario Manager";
    Contract: Codeunit "BCSF Contract JSON";
    Stored: JsonObject;
    Supplied: JsonObject;
    StoredText: Text;
    SuppliedText: Text;
  begin
    Contract.CheckBatch(Context, Target, Batch);
    if not Evaluate(RunId, Contract.GetText(Context, 'runId')) or
      not Evaluate(BatchId, Contract.GetText(Context, 'batchId')) then
      Error(ExecutionErr);
    Header.LockTable();
    Header.Get(RunId);
    Header.TestField("Company Name", CompanyName());
    Manager.ReadSnapshot(RunId, Stored);
    Supplied := Contract.Clone(Context);
    Supplied.Remove('batchId');
    Supplied.WriteTo(SuppliedText);
    Stored.WriteTo(StoredText);
    if SuppliedText <> StoredText then
      Error(ExecutionErr);
    Step.Get(RunId, Contract.GetCode(Target, 'entityCode'));
    Step.TestField("Generator Code", GeneratorCode);
    Step.TestField("Generator Version", '1');
    Step.TestField("Contract Version", 1);
    Step.TestField("Work Units", Contract.GetInteger(Target, 'quantity'));
    Step.TestField("Module Code", Contract.GetCode(Target, 'moduleCode'));
    Step.TestField("Process Mode", "BCSF Process Mode"::SetupAndMasterData);
    OnCheckExecutingBatch(RunId, BatchId, Step."Node Code", Batch);
  end;

  [IntegrationEvent(false, false)]
  local procedure OnCheckExecutingBatch(RunId: Guid; BatchId: Guid; NodeCode: Code[30]; Batch: JsonObject)
  begin
  end;

  procedure MakeResult(Context: JsonObject; Batch: JsonObject; GeneratorCode: Code[30]; var Result: JsonObject)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Units: Integer;
  begin
    Units := Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1;
    Clear(Result);
    Result.Add('generatorCode', GeneratorCode);
    Result.Add('runId', Contract.GetText(Context, 'runId'));
    Result.Add('batchKey', Contract.GetText(Batch, 'batchKey'));
    Result.Add('processedUnits', Units);
    Result.Add('createdRecords', Units);
    Result.Add('dataLanguage', Contract.GetInteger(Context, 'dataLanguage'));
    Result.Add('completed', true);
    Result.Add('contractProbe', false);
  end;

  procedure CheckResult(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; GeneratorCode: Code[30])
  var
    Contract: Codeunit "BCSF Contract JSON";
    Units: Integer;
  begin
    Contract.CheckBatch(Context, Target, Batch);
    Units := Contract.GetInteger(Batch, 'lastKey') - Contract.GetInteger(Batch, 'firstKey') + 1;
    if (Contract.GetText(Result, 'generatorCode') <> GeneratorCode) or
      (Contract.GetText(Result, 'runId') <> Contract.GetText(Context, 'runId')) or
      (Contract.GetText(Result, 'batchKey') <> Contract.GetText(Batch, 'batchKey')) or
      (Contract.GetInteger(Result, 'processedUnits') <> Units) or (Contract.GetInteger(Result, 'createdRecords') <> Units) or
      (Contract.GetInteger(Result, 'dataLanguage') <> Contract.GetInteger(Context, 'dataLanguage')) or
      not Contract.GetBoolean(Result, 'completed') or Contract.GetBoolean(Result, 'contractProbe') then
      Error(ExecutionErr);
  end;

  var
    ContactPermissionErr: Label 'The configured standard contact integration requires read and write permissions for contacts and contact business relations.';
    CountryErr: Label 'The current SKR test packages support domestic German partners only. Select country code DE or use explicitly configured existing setup.';
    SettingsErr: Label 'Capture a new run with partner settings version 1, existing country and posting groups, usable number series, payment terms and nonnegative credit limits.';
    TargetErr: Label 'Use a customer or vendor master-data target and valid logical batch ranges.';
    TermsErr: Label 'Use payment terms without payment discounts and with a nonnegative due date. Consumer terms must be due immediately.';
    ExecutionErr: Label 'Partner generation requires the unchanged captured configuration and its currently owned job-queue batch. Do not replay uncertain work.';
    GermanCitiesTok: Label 'Teststadt Nord,Teststadt Ost,Teststadt Sued,Teststadt West', Locked = true;
    EnglishCitiesTok: Label 'Sample Town North,Sample Town East,Sample Town South,Sample Town West', Locked = true;
    GermanStreetsTok: Label 'Testallee,Musterweg,Probestrasse,Demoring,Beispielgasse,Testbogen', Locked = true;
    EnglishStreetsTok: Label 'Sample Avenue,Example Lane,Demo Street,Test Road,Sample Crescent,Example Way', Locked = true;
}
