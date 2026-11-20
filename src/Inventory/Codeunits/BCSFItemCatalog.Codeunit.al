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
}
