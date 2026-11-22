namespace BCScenarioFactory.Inventory;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.ScenarioManagement;

codeunit 90477 "BCSF Item Catalog"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Scenario Manager", 'OnPreviewItemName', '', false, false)]
  local procedure PreviewItem(Context: JsonObject; var ItemName: Text[100])
  var
    Contract: Codeunit "BCSF Contract JSON";
    Values: JsonObject;
  begin
    if not SupportsProfile(Contract.GetText(Context, 'profileCode'), Contract.GetText(Context, 'profileVersion')) then
      exit;
    Values := BuildValues(Context, 1);
    ItemName := CopyStr(Contract.GetText(Values, 'description'), 1, MaxStrLen(ItemName));
  end;

  procedure SupportsProfile(Profile: Text; Version: Text): Boolean
  begin
    if Version = '1' then
      exit(Profile in ['TECH-TRADE', 'TECH-BINS']);
    if (Version in ['4', '5', '6']) and (Profile = 'TRADE') then
      exit(true);
    exit((Version = '3') and (Profile in ['TECH-SALES', 'GENERAL', 'TRADE', 'ECOMMERCE', 'DISTRIBUTION', 'MANUFACTURING', 'CONSULTING', 'CONSTRUCTION', 'SERVICE']));
  end;

  procedure UsesBins(Profile: Text): Boolean
  begin
    exit(Profile = 'TECH-BINS');
  end;

  procedure BuildValues(Context: JsonObject; LogicalKey: Integer): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    Result: JsonObject;
    SampleContext: JsonObject;
    German: Boolean;
    Family: Integer;
    Size: Integer;
    Description: Text;
    Category: Code[10];
    Material: Text;
    Cost: Decimal;
    PackQuantity: Integer;
  begin
    if not SupportsProfile(Contract.GetText(Context, 'profileCode'), Contract.GetText(Context, 'profileVersion')) or (LogicalKey <= 0) then
      Error(ProfileErr);
    if (Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') in ['5', '6']) then
      exit(BuildWholesaleValues(Context, LogicalKey));
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    Family := ((LogicalKey - 1) mod 8) + 1;
    SampleContext := Contract.Clone(Context);
    SampleContext.Replace('profileCode', 'TECH-TRADE');
    // The two substitution candidates share the same functional diameter.
    Evaluate(Size, SelectStr(1 + Seed.SampleInteger(SampleContext, 'ITEM', Format((LogicalKey - 1) div 8, 0, 9), 'DIAMETER', 0, 5), '15,20,25,32,40,50'));
    case Family of
      1:
        begin
          Category := 'FITTINGS';
          Description := Choose(German, 'Gerade Gewindekupplung', 'Straight threaded coupling');
        end;
      2:
        begin
          Category := 'FITTINGS';
          Description := Choose(German, 'Gewindekupplung verstärkt', 'Reinforced threaded coupling');
        end;
      3:
        begin
          Category := 'VALVES';
          Description := Choose(German, 'Kugelhahn mit Hebel', 'Lever ball valve');
        end;
      4:
        begin
          Category := 'FILTERS';
          Description := Choose(German, 'Schmutzfilter', 'Strainer');
        end;
      5:
        begin
          Category := 'SEALS';
          Description := Choose(German, 'Flachdichtung', 'Flat gasket');
        end;
      6:
        begin
          Category := 'FITTINGS';
          Description := Choose(German, 'Winkelverschraubung', 'Elbow fitting');
        end;
      7:
        begin
          Category := 'VALVES';
          Description := Choose(German, 'Rückschlagventil', 'Check valve');
        end;
      8:
        begin
          Category := 'FITTINGS';
          Description := Choose(German, 'Schlauchtülle', 'Hose connector');
        end;
    end;
    Material := Choose(German, 'Messing', 'Brass');
    if Family = 4 then
      Material := Choose(German, 'Edelstahl', 'Stainless steel');
    if Family = 5 then
      Material := 'EPDM';
    Cost := Round((Family * 135 + Size * 22) / 100, 0.01);
    PackQuantity := 24;
    if Family in [3, 7] then
      PackQuantity := 6;
    if Family = 4 then begin
      PackQuantity := 4;
      Cost := Round(Cost * 2.5, 0.01);
    end;
    if Family = 5 then begin
      PackQuantity := 100;
      Cost := Round(Cost / 8, 0.01);
    end;
    Result.Add('description', Description + ' ' + Material + ' DN ' + Format(Size, 0, 9));
    Result.Add('family', Family);
    Result.Add('category', Category);
    Result.Add('material', Material);
    Result.Add('diameter', Format(Size, 0, 9) + ' mm');
    case Size of
      15: Result.Add('thread', 'G 1/2');
      20: Result.Add('thread', 'G 3/4');
      25: Result.Add('thread', 'G 1');
      32: Result.Add('thread', 'G 1 1/4');
      40: Result.Add('thread', 'G 1 1/2');
      50: Result.Add('thread', 'G 2');
    end;
    Result.Add('cost', Cost);
    Result.Add('price', Round(Cost * 1.65, 0.01));
    Result.Add('packQuantity', PackQuantity);
    exit(Result);
  end;

  // Profile TRADE/5: enumerate real combinations without random collisions. This
  // catalog has 8 families x 6 sizes x 12 lengths x 4 materials x 3 ratings
  // (6,912 distinct product identities). The layout is independent of batches.
  local procedure BuildWholesaleValues(Context: JsonObject; LogicalKey: Integer): JsonObject
  var
    Contract: Codeunit "BCSF Contract JSON";
    Result: JsonObject;
    German: Boolean;
    Family: Integer;
    SizeIndex: Integer;
    Size: Integer;
    LengthIndex: Integer;
    MaterialIndex: Integer;
    PressureIndex: Integer;
    Dimension: Integer;
    Category: Code[10];
    Description: Text;
    Material: Text;
    Specification: Text;
    Cost: Decimal;
    PackQuantity: Integer;
  begin
    if (LogicalKey < 1) or (LogicalKey > 6912) then
      Error(CatalogCapacityErr, LogicalKey);
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    Family := ((LogicalKey - 1) mod 8) + 1;
    SizeIndex := (((LogicalKey - 1) div 8) mod 6) + 1;
    Evaluate(Size, SelectStr(SizeIndex, '15,20,25,32,40,50'));
    LengthIndex := ((LogicalKey - 1) div 48) mod 12;
    MaterialIndex := (((LogicalKey - 1) div 576) mod 4) + 1;
    PressureIndex := (((LogicalKey - 1) div 2304) mod 3) + 1;
    case Family of
      1: begin Category := 'FITTINGS'; Description := Choose(German, 'Gerade Gewindekupplung', 'Straight threaded coupling'); end;
      2: begin Category := 'FITTINGS'; Description := Choose(German, 'Gewindekupplung verstärkt', 'Reinforced threaded coupling'); end;
      3: begin Category := 'VALVES'; Description := Choose(German, 'Kugelhahn mit Hebel', 'Lever ball valve'); end;
      4: begin Category := 'FILTERS'; Description := Choose(German, 'Schmutzfilter', 'Strainer'); end;
      5: begin Category := 'SEALS'; Description := Choose(German, 'Flachdichtung', 'Flat gasket'); end;
      6: begin Category := 'FITTINGS'; Description := Choose(German, 'Winkelverschraubung', 'Elbow fitting'); end;
      7: begin Category := 'VALVES'; Description := Choose(German, 'Rückschlagventil', 'Check valve'); end;
      8: begin Category := 'FITTINGS'; Description := Choose(German, 'Schlauchtülle', 'Hose connector'); end;
    end;
    if Family = 5 then
      Material := SelectStr(MaterialIndex, 'EPDM,NBR,FKM,Silikon')
    else
      Material := SelectStr(MaterialIndex, 'Messing,Edelstahl,Rotguss,PVC-U');
    if not German then
      case Material of
        'Messing': Material := 'Brass';
        'Edelstahl': Material := 'Stainless steel';
        'Rotguss': Material := 'Gunmetal';
        'Silikon': Material := 'Silicone';
      end;
    if Family = 5 then begin
      Dimension := 2 + LengthIndex;
      Specification := Choose(German, 'Dicke ', 'Thickness ') + Format(Dimension, 0, 9) + ' mm';
      PackQuantity := 100;
    end else begin
      Dimension := 40 + LengthIndex * 10;
      Specification := Choose(German, 'Baulänge ', 'Length ') + Format(Dimension, 0, 9) + ' mm';
      PackQuantity := 24;
      if Family in [3, 7] then
        PackQuantity := 6;
      if Family = 4 then
        PackQuantity := 4;
    end;
    Description += ' ' + Material + ' DN ' + Format(Size, 0, 9) + ' ' + Specification +
      ' PN ' + SelectStr(PressureIndex, '10,16,25');
    Cost := Round((Family * 135 + Size * 22 + Dimension * 4 + MaterialIndex * 85 + PressureIndex * 63) / 100, 0.01);
    if Family = 4 then
      Cost := Round(Cost * 2.5, 0.01);
    if Family = 5 then
      Cost := Round(Cost / 8, 0.01);
    Result.Add('description', Description);
    Result.Add('family', Family);
    Result.Add('category', Category);
    Result.Add('material', Material);
    Result.Add('diameter', Format(Size, 0, 9) + ' mm');
    case Size of
      15: Result.Add('thread', 'G 1/2');
      20: Result.Add('thread', 'G 3/4');
      25: Result.Add('thread', 'G 1');
      32: Result.Add('thread', 'G 1 1/4');
      40: Result.Add('thread', 'G 1 1/2');
      50: Result.Add('thread', 'G 2');
    end;
    Result.Add('cost', Cost);
    Result.Add('price', Round(Cost * (1.35 + (Family mod 4) * 0.1), 0.01));
    Result.Add('packQuantity', PackQuantity);
    Result.Add('reorderPoint', PackQuantity * (1 + (Family mod 3)));
    Result.Add('dimension', Format(Dimension, 0, 9) + ' mm');
    Result.Add('rating', 'PN ' + SelectStr(PressureIndex, '10,16,25'));
    exit(Result);
  end;

  procedure CategoryCode(RunId: Guid; Suffix: Code[10]): Code[20]
  begin
    exit(CopyStr(DelChr(Format(RunId, 0, 4), '=', '{}-'), 1, 16) + '-' + CopyStr(Suffix, 1, 3));
  end;

  procedure Choose(German: Boolean; GermanValue: Text; EnglishValue: Text): Text
  begin
    if German then
      exit(GermanValue);
    exit(EnglishValue);
  end;

  var
    ProfileErr: Label 'Select a supported item assortment or sales template profile with a positive item key.';
    CatalogCapacityErr: Label 'The wholesale assortment supports up to 6912 unique products. Requested item key %1 is out of range.', Comment = '%1 = logical item key';
}
