namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;

codeunit 90250 "BCSF Seed Engine"
{
  Access = Internal;

  /// <summary>Stateless version-1 sampling. Each field has its own stream; batches and RunId do not affect values.</summary>
  procedure SampleInteger(Context: JsonObject; GeneratorCode: Code[30]; LogicalKey: Text; Stream: Text; Minimum: Integer; Maximum: Integer): Integer
  var
    Contract: Codeunit "BCSF Contract JSON";
    Input: Text;
    Hash: Decimal;
    Span: Decimal;
    Index: Integer;
  begin
    Contract.CheckContext(Context);
    if (Contract.GetInteger(Context, 'seedEngineVersion') <> 1) or
      (GeneratorCode = '') or (LogicalKey = '') or (Stream = '') or (Maximum < Minimum)
    then
      Error(InputErr);
    // Length prefixes make tuples unambiguous. XML format 9 is independent of UI language.
    Input := Part('BCSF.SEED.1') + Part(Format(Contract.GetInteger(Context, 'seed'), 0, 9)) +
      Part(Contract.GetText(Context, 'profileCode')) + Part(Contract.GetText(Context, 'profileVersion')) +
      Part(GeneratorCode) + Part(LogicalKey) + Part(Stream);
    Hash := 1;
    for Index := 1 to StrLen(Input) do
      Hash := (Hash * 131 + Input[Index]) mod 2147483647;
    // Fixed modular mixing; this is a noncryptographic synthetic sampler.
    Hash := (Hash * 48271) mod 2147483647;
    Hash := Hash * 2147483647 + ((Hash * 48271) mod 2147483647);
    Span := Maximum;
    Span := Span - Minimum + 1;
    exit(Minimum + (Hash mod Span));
  end;

  procedure SampleDate(Context: JsonObject; GeneratorCode: Code[30]; LogicalKey: Text; Stream: Text; StartingDate: Date; EndingDate: Date; WeekdaysOnly: Boolean): Date
  var
    Candidate: Date;
    Offset: Integer;
    Days: Integer;
    Attempt: Integer;
  begin
    if (StartingDate = 0D) or (EndingDate < StartingDate) then
      Error(DateErr);
    Days := EndingDate - StartingDate;
    Offset := SampleInteger(Context, GeneratorCode, LogicalKey, Stream, 0, Days);
    Candidate := StartingDate + Offset;
    if WeekdaysOnly then
      while Date2DWY(Candidate, 1) > 5 do begin
        Attempt += 1;
        if (Attempt > Days) or (Attempt > 2) then
          Error(DateErr);
        if Candidate = EndingDate then
          Candidate := StartingDate
        else
          Candidate += 1;
      end;
    exit(Candidate);
  end;

  /// <summary>Pure synthetic input DTO. Does not insert customers, contacts, items, accounts or documents.</summary>
  procedure BuildValues(Context: JsonObject; EntityCode: Code[30]; LogicalKey: Text): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Rules: JsonObject;
    Result: JsonObject;
    DataLanguage: Enum "BCSF Data Language";
    ClassCode: Text;
    CompanyStem: Text;
    PersonStem: Text;
    ItemStem: Text;
    MinimumCents: Integer;
    MaximumCents: Integer;
    SmallPercent: Integer;
    MediumPercent: Integer;
    Draw: Integer;
    Variant: Integer;
    Price: Decimal;
    StartingDate: Date;
    EndingDate: Date;
    SampledDate: Date;
  begin
    Contract.CheckContext(Context);
    if not (EntityCode in ['CUSTOMER', 'VENDOR', 'ITEM']) then
      Error(InputErr);
    if not Context.Get('seedEngineVersion', Token) then
      Error(RulesErr);
    if Token.AsValue().AsInteger() <> 1 then
      Error(RulesErr);
    if not Context.Get('syntheticRules', Token) then
      Error(RulesErr);
    Rules := Token.AsObject();
    if (Contract.GetInteger(Rules, 'version') <> 1) or (Contract.GetInteger(Context, 'nameCatalogVersion') <> 1) then
      Error(RulesErr);
    SmallPercent := Contract.GetInteger(Rules, 'smallPercent');
    MediumPercent := Contract.GetInteger(Rules, 'mediumPercent');
    if (SmallPercent < 0) or (SmallPercent > 100) or (MediumPercent < 0) or (MediumPercent > 100) or
      (SmallPercent + MediumPercent > 100) then
      Error(RulesErr);
    CheckPriceRange(Rules, 'small');
    CheckPriceRange(Rules, 'medium');
    CheckPriceRange(Rules, 'large');
    Draw := SampleInteger(Context, EntityCode, LogicalKey, 'CLASS', 1, 100);
    ClassCode := 'large';
    if Draw <= SmallPercent then
      ClassCode := 'small'
    else
      if Draw <= SmallPercent + MediumPercent then
        ClassCode := 'medium';
    MinimumCents := Contract.GetInteger(Rules, ClassCode + 'MinimumCents');
    MaximumCents := Contract.GetInteger(Rules, ClassCode + 'MaximumCents');
    Price := SampleInteger(Context, EntityCode, LogicalKey, 'PRICE', MinimumCents, MaximumCents) / 100;
    if not Evaluate(StartingDate, Contract.GetText(Context, 'startingDate'), 9) or
      not Evaluate(EndingDate, Contract.GetText(Context, 'endingDate'), 9)
    then
      Error(DateErr);
    SampledDate := SampleDate(Context, EntityCode, LogicalKey, 'DATE', StartingDate, EndingDate, false);
    DataLanguage := "BCSF Data Language".FromInteger(Contract.GetInteger(Context, 'dataLanguage'));
    Variant := SampleInteger(Context, EntityCode, LogicalKey, 'NAME', 1, 6);
    if DataLanguage = "BCSF Data Language"::German then begin
      CompanyStem := SelectStr(Variant, GermanCompaniesLbl);
      PersonStem := SelectStr(SampleInteger(Context, EntityCode, LogicalKey, 'PERSON', 1, 6), GermanPeopleLbl);
      ItemStem := SelectStr(SampleInteger(Context, EntityCode, LogicalKey, 'ITEM', 1, 6), GermanItemsLbl);
    end else begin
      CompanyStem := SelectStr(Variant, EnglishCompaniesLbl);
      PersonStem := SelectStr(SampleInteger(Context, EntityCode, LogicalKey, 'PERSON', 1, 6), EnglishPeopleLbl);
      ItemStem := SelectStr(SampleInteger(Context, EntityCode, LogicalKey, 'ITEM', 1, 6), EnglishItemsLbl);
    end;
    Result.Add('logicalKey', LogicalKey);
    Result.Add('entityCode', EntityCode);
    Result.Add('companyName', CopyStr(CompanyStem + ' [' + LogicalKey + ']', 1, 100));
    Result.Add('personName', CopyStr(PersonStem + ' [' + LogicalKey + ']', 1, 100));
    Result.Add('itemDescription', CopyStr(ItemStem + ' [' + LogicalKey + ']', 1, 100));
    // Fixed reserved domain; logical keys never become recipients. Phone, bank and account identifiers stay absent.
    Result.Add('email', 'synthetic@example.invalid');
    Result.Add('classCode', ClassCode);
    Result.Add('unitPrice', Price);
    Result.Add('date', Format(SampledDate, 0, 9));
    Result.Add('seedEngineVersion', 1);
    Result.Add('rulesVersion', 1);
    exit(Result);
  end;

  local procedure CheckPriceRange(Rules: JsonObject; ClassCode: Text)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Minimum: Integer;
    Maximum: Integer;
  begin
    Minimum := Contract.GetInteger(Rules, ClassCode + 'MinimumCents');
    Maximum := Contract.GetInteger(Rules, ClassCode + 'MaximumCents');
    if (Minimum <= 0) or (Maximum < Minimum) then
      Error(RulesErr);
  end;

  local procedure Part(Value: Text): Text
  begin
    exit(Format(StrLen(Value), 0, 9) + ':' + Value);
  end;

  var
    InputErr: Label 'Use seed engine version 1, a supported entity, a nonempty generator, logical key and field stream, and an ordered value range.';
    DateErr: Label 'Use a nonempty ordered date range containing an eligible day.';
    RulesErr: Label 'Capture a new run with supported versioned synthetic rules, valid class percentages and positive price ranges.';
    GermanCompaniesLbl: Label 'Testbetrieb Nordlicht,Testbetrieb Kupferwald,Testbetrieb Wolkenhain,Testbetrieb Kieselstern,Testbetrieb Morgenfarn,Testbetrieb Silberwiese', Locked = true;
    EnglishCompaniesLbl: Label 'Sample Northlight Trading,Sample Copperwood Supply,Sample Cloudgrove Services,Sample Pebblestar Trade,Sample Morningfern Supply,Sample Silvermeadow Trade', Locked = true;
    GermanItemsLbl: Label 'Musterartikel Verbindung,Musterartikel Halterung,Musterartikel Gehäuse,Musterartikel Dichtung,Musterartikel Einsatz,Musterartikel Abdeckung', Locked = true;
    EnglishItemsLbl: Label 'Sample Connector,Sample Bracket,Sample Housing,Sample Seal,Sample Insert,Sample Cover', Locked = true;
    GermanPeopleLbl: Label 'Testperson Nela Wolkenhain,Testperson Taro Kieselstern,Testperson Mira Morgenfarn,Testperson Jona Kupferwald,Testperson Leni Silberwiese,Testperson Niko Nordlicht', Locked = true;
    EnglishPeopleLbl: Label 'Test Person Nela Cloudgrove,Test Person Taro Pebblestar,Test Person Mira Morningfern,Test Person Jona Copperwood,Test Person Leni Silvermeadow,Test Person Niko Northlight', Locked = true;
}
