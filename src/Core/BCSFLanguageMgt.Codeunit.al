namespace BCScenarioFactory.Core;

using System.Globalization;

codeunit 90109 "BCSF Language Mgt"
{
  Access = Internal;

  /// <summary>Resolves once at capture time. The result must be persisted and reused by background workers.</summary>
  procedure ResolveDataLanguage(Setting: Enum "BCSF Data Language"): Enum "BCSF Data Language"
  begin
    exit(ResolveForLanguageId(Setting, GlobalLanguage()));
  end;

  procedure ResolveForLanguageId(Setting: Enum "BCSF Data Language"; LanguageId: Integer): Enum "BCSF Data Language"
  var
    Language: Codeunit Language;
  begin
    case Setting of
      "BCSF Data Language"::German,
      "BCSF Data Language"::English:
        exit(Setting);
      "BCSF Data Language"::Automatic:
        begin
          if Language.GetTwoLetterISOLanguageName(LanguageId) = 'de' then
            exit("BCSF Data Language"::German);
          exit("BCSF Data Language"::English);
        end;
    end;
    Error(UnsupportedLanguageErr);
  end;

  procedure GetCatalogVersion(): Integer
  begin
    exit(1);
  end;

  /// <summary>Language-stable synthetic names; never depends on the worker's GlobalLanguage and never writes business records.</summary>
  procedure GetSyntheticName(EntityCode: Code[20]; SequenceNo: Integer; DataLanguage: Enum "BCSF Data Language"; CatalogVersion: Integer): Text[100]
  var
    NamePrefix: Text;
  begin
    // Dispatch by the captured version, not by the current default. Preserve version 1 when adding future catalogs.
    if (CatalogVersion <> 1) or (SequenceNo <= 0) then
      Error(CatalogErr);
    if not (DataLanguage in ["BCSF Data Language"::German, "BCSF Data Language"::English]) then
      Error(UnresolvedLanguageErr);
    case EntityCode of
      'CUSTOMER':
        if DataLanguage = "BCSF Data Language"::German then
          NamePrefix := GermanCustomerLbl
        else
          NamePrefix := EnglishCustomerLbl;
      'VENDOR':
        if DataLanguage = "BCSF Data Language"::German then
          NamePrefix := GermanVendorLbl
        else
          NamePrefix := EnglishVendorLbl;
      'ITEM':
        if DataLanguage = "BCSF Data Language"::German then
          NamePrefix := GermanItemLbl
        else
          NamePrefix := EnglishItemLbl;
      else
        Error(CatalogErr);
    end;
    exit(CopyStr(StrSubstNo(NameFormatLbl, NamePrefix, Format(SequenceNo, 0, 9)), 1, 100));
  end;

  var
    UnsupportedLanguageErr: Label 'Select Automatic, German or English as the data language.';
    UnresolvedLanguageErr: Label 'Use the resolved data language from the run snapshot.';
    CatalogErr: Label 'Select a supported synthetic name type, a positive sequence and a supported catalog version.';
    // Locked catalog entries are data, deliberately selected by the frozen language instead of UI translation.
    GermanCustomerLbl: Label 'Musterkunde', Locked = true;
    EnglishCustomerLbl: Label 'Sample Customer', Locked = true;
    GermanVendorLbl: Label 'Musterlieferant', Locked = true;
    EnglishVendorLbl: Label 'Sample Vendor', Locked = true;
    GermanItemLbl: Label 'Musterartikel', Locked = true;
    EnglishItemLbl: Label 'Sample Item', Locked = true;
    NameFormatLbl: Label '%1 %2', Locked = true;
}
