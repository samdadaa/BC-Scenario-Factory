namespace BCScenarioFactory.Sales;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ModuleRegistry;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;

codeunit 90425 "BCSF Customer Generator" implements "BCSF Generator"
{
  Access = Internal;

  procedure DescribeCapabilities(var Capabilities: Record "BCSF Generator Registry" temporary)
  begin
    Capabilities.Init();
    Capabilities."Generator Code" := 'CUSTOMER';
    Capabilities."Entity Code" := 'CUSTOMER';
    Capabilities."Module Code" := 'SALES';
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
      Finding.Add('code', 'PARTNER.SETUP');
      Finding.Add('message', GetLastErrorText());
      ClearLastError();
      Findings.Add(Finding);
    end;
  end;

  [TryFunction]
  local procedure CheckSetup(Context: JsonObject; Target: JsonObject)
  var
    Partner: Record Customer;
    Rules: Codeunit "BCSF Partner Rules";
    Children: Codeunit "BCSF Partner Children";
    Contract: Codeunit "BCSF Contract JSON";
    Settings: JsonObject;
  begin
    Rules.CheckTarget(Context, Target, 'CUSTOMER', 'SALES');
    Rules.CheckSetup(Context, 'CUSTOMER');
    Settings := Rules.ReadSettings(Context);
    // Only business customers receive an additional delivery address.
    if (Contract.GetInteger(Settings, 'version') = 2) and (Contract.GetInteger(Settings, 'b2cPercent') < 100) then
      Children.CheckPermissions(true);
    Partner.SecurityFiltering(SecurityFilter::Disallowed);
    if not Partner.ReadPermission() or not Partner.WritePermission() then
      Error(PermissionErr);
  end;

  procedure GetDependencies(Context: JsonObject; Target: JsonObject; var Dependencies: JsonArray)
  begin
    // Master setup is verified directly; no artificial customer/vendor dependency cycle.
    Clear(Dependencies);
  end;

  procedure PlanBatches(Context: JsonObject; Target: JsonObject; FirstKey: Integer; MaximumBatches: Integer; var Batches: JsonArray)
  var
    Rules: Codeunit "BCSF Partner Rules";
  begin
    Rules.CheckTarget(Context, Target, 'CUSTOMER', 'SALES');
    Rules.Plan('CUSTOMER', Context, Target, FirstKey, MaximumBatches, Batches);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure ExecuteBatch(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  var
    Entry: Record "BCSF Generated Record";
    Rules: Codeunit "BCSF Partner Rules";
    Contract: Codeunit "BCSF Contract JSON";
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
  begin
    Rules.CheckTarget(Context, Target, 'CUSTOMER', 'SALES');
    Rules.EnsureExecution(Context, Target, Batch, 'CUSTOMER', RunId, BatchId);
    CheckSetup(Context, Target);
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", 'CUSTOMER');
    Entry.SetRange("Logical Key", Contract.GetInteger(Batch, 'firstKey'), Contract.GetInteger(Batch, 'lastKey'));
    if not Entry.IsEmpty() then
      Error(ReplayErr);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do
      CreatePartner(Context, RunId, BatchId, LogicalKey);
    Rules.MakeResult(Context, Batch, 'CUSTOMER', Result);
  end;

  local procedure CreatePartner(Context: JsonObject; RunId: Guid; BatchId: Guid; LogicalKey: Integer)
  var
    Partner: Record Customer;
    Rules: Codeunit "BCSF Partner Rules";
    Registry: Codeunit "BCSF Record Registry";
    Children: Codeunit "BCSF Partner Children";
    Contract: Codeunit "BCSF Contract JSON";
    NoSeries: Codeunit "No. Series";
    Settings: JsonObject;
    Values: JsonObject;
    BaseDate: Date;
    NoParent: Guid;
    ParentId: Guid;
  begin
    Settings := Rules.ReadSettings(Context);
    Values := Rules.BuildValues(Context, 'CUSTOMER', LogicalKey);
    if not Evaluate(BaseDate, Contract.GetText(Context, 'startingDate'), 9) then
      Error(ReplayErr);
    Partner.Init();
    // Standard API assigns the number; validating an automatically allocated No. as manual would reject default-only series.
    Partner."No. Series" := CopyStr(Contract.GetCode(Settings, 'customerNoSeries'), 1, MaxStrLen(Partner."No. Series"));
    Partner."No." := NoSeries.GetNextNo(Partner."No. Series", BaseDate);
    if Partner."No." = '' then
      Error(ReplayErr);
    Partner.Validate(Name, CopyStr(Contract.GetText(Values, 'name'), 1, MaxStrLen(Partner.Name)));
    Partner.Validate("Country/Region Code", CopyStr(Contract.GetCode(Values, 'countryCode'), 1, MaxStrLen(Partner."Country/Region Code")));
    Partner.Validate("Post Code", CopyStr(Contract.GetCode(Values, 'postCode'), 1, MaxStrLen(Partner."Post Code")));
    Partner.Validate(City, CopyStr(Contract.GetText(Values, 'city'), 1, MaxStrLen(Partner.City)));
    Partner.Validate(Address, CopyStr(Contract.GetText(Values, 'address'), 1, MaxStrLen(Partner.Address)));
    Partner.Validate("E-Mail", CopyStr(Contract.GetText(Values, 'email'), 1, MaxStrLen(Partner."E-Mail")));
    Partner.Validate("Gen. Bus. Posting Group", CopyStr(Contract.GetCode(Settings, 'genBusPostingGroup'), 1, MaxStrLen(Partner."Gen. Bus. Posting Group")));
    Partner.Validate("VAT Bus. Posting Group", CopyStr(Contract.GetCode(Settings, 'vatBusPostingGroup'), 1, MaxStrLen(Partner."VAT Bus. Posting Group")));
    Partner.Validate("Customer Posting Group", CopyStr(Contract.GetCode(Settings, 'customerPostingGroup'), 1, MaxStrLen(Partner."Customer Posting Group")));
    Partner.Validate("Payment Terms Code", CopyStr(Contract.GetCode(Values, 'paymentTerms'), 1, MaxStrLen(Partner."Payment Terms Code")));
    Partner.Validate(Priority, Contract.GetInteger(Values, 'priority'));
    Partner.Validate("Credit Limit (LCY)", Rules.GetDecimal(Values, 'creditLimit'));
    if Contract.GetBoolean(Values, 'consumer') then begin
      Partner.Validate("Partner Type", Partner."Partner Type"::Person);
      Partner.Validate("Contact Type", Partner."Contact Type"::Person);
    end else begin
      Partner.Validate("Partner Type", Partner."Partner Type"::Company);
      Partner.Validate("Contact Type", Partner."Contact Type"::Company);
    end;
    // Contact.OnValidate can Modify an already stored record. Supply the synthetic contact to the standard insert instead.
    Partner.Contact := CopyStr(Contract.GetText(Values, 'contact'), 1, MaxStrLen(Partner.Contact));
    if Contract.GetInteger(Settings, 'version') = 2 then begin
      Partner.Validate("Currency Code", CopyStr(Contract.GetText(Settings, 'currencyCode'), 1, MaxStrLen(Partner."Currency Code")));
      Partner.Validate("Payment Method Code", CopyStr(Contract.GetText(Settings, 'paymentMethod'), 1, MaxStrLen(Partner."Payment Method Code")));
    end;
    Partner.Insert(true);
    // Standard dimension validation saves Default Dimension and calls Modify; the partner must already exist.
    if Contract.GetInteger(Settings, 'version') = 2 then begin
      if Contract.GetText(Settings, 'dimension1') <> '' then
        Partner.Validate("Global Dimension 1 Code", CopyStr(Contract.GetText(Settings, 'dimension1'), 1, MaxStrLen(Partner."Global Dimension 1 Code")));
      if Contract.GetText(Settings, 'dimension2') <> '' then
        Partner.Validate("Global Dimension 2 Code", CopyStr(Contract.GetText(Settings, 'dimension2'), 1, MaxStrLen(Partner."Global Dimension 2 Code")));
    end;
    ParentId := Registry.RegisterResult(RunId, 'CUSTOMER', LogicalKey, 'CUSTOMER', BatchId, Partner.RecordId(), NoParent);
    if Contract.GetInteger(Settings, 'version') = 2 then
      if not Contract.GetBoolean(Values, 'consumer') then
        Children.CreateCustomer(Context, Partner, RunId, BatchId, LogicalKey, ParentId);
  end;

  procedure ValidateOutput(Context: JsonObject; Target: JsonObject; Batch: JsonObject; Result: JsonObject; var Findings: JsonArray)
  var
    Partner: Record Customer;
    Entry: Record "BCSF Generated Record";
    Rules: Codeunit "BCSF Partner Rules";
    Contract: Codeunit "BCSF Contract JSON";
    Children: Codeunit "BCSF Partner Children";
    Settings: JsonObject;
    Values: JsonObject;
    RunId: Guid;
    BatchId: Guid;
    LogicalKey: Integer;
    ExpectedArtifacts: Integer;
  begin
    Clear(Findings);
    Rules.CheckTarget(Context, Target, 'CUSTOMER', 'SALES');
    Rules.CheckResult(Context, Target, Batch, Result, 'CUSTOMER');
    Settings := Rules.ReadSettings(Context);
    if not Evaluate(RunId, Contract.GetText(Context, 'runId')) or
      not Evaluate(BatchId, Contract.GetText(Context, 'batchId')) then
      Error(ReplayErr);
    Partner.SecurityFiltering(SecurityFilter::Disallowed);
    for LogicalKey := Contract.GetInteger(Batch, 'firstKey') to Contract.GetInteger(Batch, 'lastKey') do begin
      Entry.Get(RunId, 'CUSTOMER', LogicalKey, 'CUSTOMER');
      Entry.TestField("Batch Id", BatchId);
      Entry.TestField("Table Id", Database::Customer);
      Entry.TestField("Generator Code", 'CUSTOMER');
      Entry.TestField("Generator Version", '1');
      Partner.GetBySystemId(Entry."Record SystemId");
      Values := Rules.BuildValues(Context, 'CUSTOMER', LogicalKey);
      ExpectedArtifacts += 1;
      if Contract.GetInteger(Settings, 'version') = 2 then
        if not Contract.GetBoolean(Values, 'consumer') then begin
          Children.CheckCustomer(Context, Partner, RunId, BatchId, LogicalKey, Entry."Entry Id");
          ExpectedArtifacts += 1;
        end;
      Partner.TestField(Name, Contract.GetText(Values, 'name'));
      Partner.TestField(Contact, Contract.GetText(Values, 'contact'));
      Partner.TestField(Address, Contract.GetText(Values, 'address'));
      Partner.TestField(City, Contract.GetText(Values, 'city'));
      Partner.TestField("Post Code", Contract.GetCode(Values, 'postCode'));
      Partner.TestField("Country/Region Code", Contract.GetCode(Values, 'countryCode'));
      Partner.TestField("E-Mail", Contract.GetText(Values, 'email'));
      Partner.TestField("No. Series", Contract.GetCode(Settings, 'customerNoSeries'));
      Partner.TestField("Gen. Bus. Posting Group", Contract.GetCode(Settings, 'genBusPostingGroup'));
      Partner.TestField("VAT Bus. Posting Group", Contract.GetCode(Settings, 'vatBusPostingGroup'));
      Partner.TestField("Customer Posting Group", Contract.GetCode(Settings, 'customerPostingGroup'));
      Partner.TestField("Payment Terms Code", Contract.GetCode(Values, 'paymentTerms'));
      Partner.TestField(Priority, Contract.GetInteger(Values, 'priority'));
      Partner.TestField(Blocked, Partner.Blocked::" ");
      if Contract.GetInteger(Settings, 'version') = 2 then begin
        Partner.TestField("Currency Code", Contract.GetText(Settings, 'currencyCode'));
        Partner.TestField("Payment Method Code", Contract.GetText(Settings, 'paymentMethod'));
        Partner.TestField("Global Dimension 1 Code", Contract.GetText(Settings, 'dimension1'));
        Partner.TestField("Global Dimension 2 Code", Contract.GetText(Settings, 'dimension2'));
      end;
      Partner.TestField("Phone No.", '');
      Partner.TestField("VAT Registration No.", '');
      Partner.TestField("Credit Limit (LCY)", Rules.GetDecimal(Values, 'creditLimit'));
      if Contract.GetBoolean(Values, 'consumer') then begin
        Partner.TestField("Partner Type", Partner."Partner Type"::Person);
        Partner.TestField("Contact Type", Partner."Contact Type"::Person);
      end else begin
        Partner.TestField("Partner Type", Partner."Partner Type"::Company);
        Partner.TestField("Contact Type", Partner."Contact Type"::Company);
      end;
    end;
    Entry.Reset();
    Entry.SetRange("Batch Id", BatchId);
    if (Entry.Count() <> Contract.GetInteger(Result, 'createdRecords')) or (Entry.Count() <> ExpectedArtifacts) then
      Error(ReplayErr);
  end;

  procedure Resume(Context: JsonObject; Target: JsonObject; Batch: JsonObject; var Result: JsonObject)
  begin
    // Recovery verifies existing checkpoints; it never blindly executes this interface method.
    Error(ReplayErr);
  end;

  var
    NameLbl: Label 'Synthetic Customer Master Data';
    PermissionErr: Label 'Partner generation requires effective standard read and write permissions for the selected customer or vendor table.';
    ReplayErr: Label 'Partner results are missing, changed or already registered. Review the existing batch and checkpoint; do not recreate uncertain work.';
}
