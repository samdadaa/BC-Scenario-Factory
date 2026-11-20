namespace BCScenarioFactory.ProcessEngine;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;

codeunit 90275 "BCSF Process Coordinator"
{
  Access = Internal;

  // 0 = unposted, 1 = fully invoiced, 2 = partially shipped and invoiced.
  procedure Disposition(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Integer
  var
    Policy: Codeunit "BCSF Scenario Policy";
    Contract: Codeunit "BCSF Contract JSON";
    Targets: JsonToken;
    Token: JsonToken;
    Target: JsonObject;
    Posted: Integer;
    Partial: Integer;
    TargetQuantity: Integer;
  begin
    Context.Get('targets', Targets);
    foreach Token in Targets.AsArray() do begin
      Target := Token.AsObject();
      if Policy.GetEntityCode("BCSF Entity Type".FromInteger(Contract.GetInteger(Target, 'entity'))) = EntityCode then begin
        TargetQuantity := Contract.GetInteger(Target, 'quantity');
        if (LogicalKey < 1) or (LogicalKey > TargetQuantity) then
          Error(ContractErr);
        Posted := Round(TargetQuantity * Contract.GetDecimal(Target, 'postedPercent') / 100, 1, '<');
        Partial := Round(TargetQuantity * Contract.GetDecimal(Target, 'partialPercent') / 100, 1, '<');
        if LogicalKey <= Posted then
          exit(1);
        if LogicalKey <= Posted + Partial then
          exit(2);
        exit(0);
      end;
    end;
    Error(ContractErr);
  end;

  procedure Quantity(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Decimal
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    // Even base quantities allow a true, non-zero half shipment.
    exit(2 * Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'SALES-QUANTITY', 1, 4));
  end;

  procedure DocumentDate(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Integer): Date
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    StartingDate: Date;
    EndingDate: Date;
  begin
    Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9);
    Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9);
    exit(StartingDate + Seed.SampleInteger(Context, EntityCode, Format(LogicalKey, 0, 9), 'SALES-DATE', 0, EndingDate - StartingDate));
  end;

  var
    ContractErr: Label 'The captured sales quantity or distribution is inconsistent. Capture a new run.';
}
