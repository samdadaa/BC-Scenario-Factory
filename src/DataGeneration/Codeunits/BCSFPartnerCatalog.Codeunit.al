namespace BCScenarioFactory.DataGeneration;

using BCScenarioFactory.Core;
using BCScenarioFactory.ScenarioManagement;

codeunit 90257 "BCSF Partner Catalog"
{
  Access = Internal;

  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Scenario Manager", 'OnPreviewPartnerNames', '', false, false)]
  local procedure PreviewNames(Context: JsonObject; var CustomerName: Text[100]; var VendorName: Text[100]; var ItemName: Text[100])
  var
    Contract: Codeunit "BCSF Contract JSON";
    Seed: Codeunit "BCSF Seed Engine";
    Values: JsonObject;
    Settings: JsonObject;
    Token: JsonToken;
  begin
    Values.Add('personName', '');
    Values.Add('companyName', '');
    Values.Add('itemDescription', '');
    ApplyNames(Context, 'CUSTOMER', 1, Values);
    Context.Get('partnerSetup', Token);
    Settings := Token.AsObject();
    if Seed.SampleInteger(Context, 'CUSTOMER', '1', 'B2C', 1, 100) <= Contract.GetInteger(Settings, 'b2cPercent') then
      CustomerName := CopyStr(Contract.GetText(Values, 'personName'), 1, MaxStrLen(CustomerName))
    else
      CustomerName := CopyStr(Contract.GetText(Values, 'companyName'), 1, MaxStrLen(CustomerName));
    ApplyNames(Context, 'VENDOR', 1, Values);
    VendorName := CopyStr(Contract.GetText(Values, 'companyName'), 1, MaxStrLen(VendorName));
    ItemName := CopyStr(Contract.GetText(Values, 'itemDescription'), 1, MaxStrLen(ItemName));
  end;

  procedure ApplyNames(Context: JsonObject; Entity: Code[30]; LogicalKey: Integer; var Values: JsonObject)
  var
    Contract: Codeunit "BCSF Contract JSON";
    Index: Integer;
    ActivityCount: Integer;
    Person: Text;
    Company: Text;
    German: Boolean;
  begin
    German := Contract.GetInteger(Context, 'dataLanguage') = 1;
    Index := Permutation(Context, Entity, LogicalKey, 'PERSON', 2048);
    if German then
      Person := SelectStr((Index mod 32) + 1, GermanFirstNamesTok) + ' ' + SelectStr((Index div 32) + 1, GermanLastNamesTok)
    else
      Person := SelectStr((Index mod 32) + 1, EnglishFirstNamesTok) + ' ' + SelectStr((Index div 32) + 1, EnglishLastNamesTok);
    ActivityCount := 32;
    if Contract.GetText(Context, 'profileCode') in ['CONSULTING', 'CONSTRUCTION', 'SERVICE', 'MANUFACTURING', 'DISTRIBUTION', 'ECOMMERCE'] then
      ActivityCount := 8;
    Index := Permutation(Context, Entity, LogicalKey, 'COMPANY', 32 * ActivityCount * 4);
    if German then
      Company := SelectStr((Index mod 32) + 1, GermanCompanyNamesTok) + ' ' +
        Activity(Context, (Index div 32) mod ActivityCount, true) + ' ' + LegalForm(Context, (Index div (32 * ActivityCount)) + 1, German)
    else
      Company := SelectStr((Index mod 32) + 1, EnglishCompanyNamesTok) + ' ' +
        Activity(Context, (Index div 32) mod ActivityCount, false) + ' ' + LegalForm(Context, (Index div (32 * ActivityCount)) + 1, German);
    Values.Replace('companyName', Company);
    Values.Replace('personName', Person);
    if German then
      Values.Replace('itemDescription', 'Präzisionsverbinder')
    else
      Values.Replace('itemDescription', 'Precision connector');
  end;

  procedure AddressValues(Context: JsonObject; Entity: Code[30]; LogicalKey: Integer; Role: Text): JsonObject
  var
    Seed: Codeunit "BCSF Seed Engine";
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
    Result: JsonObject;
    Region: Integer;
    Country: Text;
  begin
    Context.Get('partnerSetup', Token);
    Settings := Token.AsObject();
    Country := Contract.GetText(Settings, 'countryCode');
    if not (Country in ['DE', 'GB']) then
      Error(CountryErr, Country);
    if (Contract.GetText(Context, 'profileCode') = 'TRADE') and
      (Contract.GetText(Context, 'profileVersion') = '5') then
      Region := Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.CITY', 1, 20)
    else
      Region := Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.CITY', 1, 8);
    if Country = 'DE' then begin
      Result.Add('city', SelectStr(Region, GermanCitiesTok));
      Result.Add('postCode', SelectStr(Region, GermanPostCodesTok));
      Result.Add('address', SelectStr(Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.STREET', 1, 16), GermanStreetsTok) + ' ' +
        Format(Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.HOUSE', 1, 199), 0, 9));
    end else begin
      Result.Add('city', SelectStr(Region, EnglishCitiesTok));
      Result.Add('postCode', SelectStr(Region, EnglishPostCodesTok));
      Result.Add('address', Format(Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.HOUSE', 1, 199), 0, 9) + ' ' +
        SelectStr(Seed.SampleInteger(Context, Entity, Format(LogicalKey, 0, 9), Role + '.STREET', 1, 16), EnglishStreetsTok));
    end;
    Result.Add('countryCode', Country);
    exit(Result);
  end;

  procedure Email(Name: Text): Text
  var
    LocalPart: Text;
  begin
    LocalPart := LowerCase(ConvertStr(Name, 'äöüßé', 'aouse'));
    LocalPart := DelChr(LocalPart, '=', ' .,;''"/&()');
    exit(CopyStr(LocalPart, 1, 50) + '@contact.invalid');
  end;

  local procedure LegalForm(Context: JsonObject; Index: Integer; German: Boolean): Text
  var
    Contract: Codeunit "BCSF Contract JSON";
    Token: JsonToken;
    Settings: JsonObject;
  begin
    if Context.Get('partnerSetup', Token) then begin
      Settings := Token.AsObject();
      if Contract.GetText(Settings, 'countryCode') = 'DE' then
        exit(SelectStr(Index, GermanLegalFormsTok));
      if Contract.GetText(Settings, 'countryCode') = 'GB' then
        exit(SelectStr(Index, EnglishLegalFormsTok));
    end;
    if German then
      exit(SelectStr(Index, GermanLegalFormsTok));
    exit(SelectStr(Index, EnglishLegalFormsTok));
  end;

  local procedure Activity(Context: JsonObject; Index: Integer; German: Boolean): Text
  var
    Contract: Codeunit "BCSF Contract JSON";
    Profile: Text;
  begin
    Profile := Contract.GetText(Context, 'profileCode');
    if Profile in ['CONSULTING', 'CONSTRUCTION', 'SERVICE', 'MANUFACTURING', 'DISTRIBUTION', 'ECOMMERCE'] then
      if German then
        case Profile of
          'CONSULTING': exit(SelectStr((Index mod 8) + 1, ConsultingDETok));
          'CONSTRUCTION': exit(SelectStr((Index mod 8) + 1, ConstructionDETok));
          'SERVICE': exit(SelectStr((Index mod 8) + 1, ServiceDETok));
          'MANUFACTURING': exit(SelectStr((Index mod 8) + 1, ManufacturingDETok));
          'DISTRIBUTION': exit(SelectStr((Index mod 8) + 1, DistributionDETok));
          'ECOMMERCE': exit(SelectStr((Index mod 8) + 1, EcommerceDETok));
        end
      else
        case Profile of
          'CONSULTING': exit(SelectStr((Index mod 8) + 1, ConsultingENTok));
          'CONSTRUCTION': exit(SelectStr((Index mod 8) + 1, ConstructionENTok));
          'SERVICE': exit(SelectStr((Index mod 8) + 1, ServiceENTok));
          'MANUFACTURING': exit(SelectStr((Index mod 8) + 1, ManufacturingENTok));
          'DISTRIBUTION': exit(SelectStr((Index mod 8) + 1, DistributionENTok));
          'ECOMMERCE': exit(SelectStr((Index mod 8) + 1, EcommerceENTok));
        end;
    if German then
      exit(SelectStr(Index + 1, GermanActivitiesTok));
    exit(SelectStr(Index + 1, EnglishActivitiesTok));
  end;

  local procedure Permutation(Context: JsonObject; Entity: Code[30]; LogicalKey: Integer; Stream: Text; Size: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
    Offset: Integer;
  begin
    if LogicalKey <= 0 then
      Error(KeyErr);
    Offset := Seed.SampleInteger(Context, Entity, 'CATALOG.2', Stream, 0, Size - 1);
    // 73 is coprime with the power-of-two catalog sizes; no repeats within a catalog cycle.
    exit((((LogicalKey - 1) mod Size) * 73 + Offset) mod Size);
  end;

  var
    ConsultingDETok: Label 'Unternehmensberatung,Projektberatung,Organisationsberatung,Prozessberatung,IT-Beratung,Personalberatung,Finanzberatung,Strategieberatung', Locked = true;
    ConsultingENTok: Label 'Consulting,Project Advisory,Organisation Advisory,Process Consulting,IT Advisory,People Consulting,Finance Advisory,Strategy Consulting', Locked = true;
    ConstructionDETok: Label 'Bautechnik,Hochbau,Innenausbau,Bauplanung,Objektbau,Holzbau,Tiefbau,Gebäudetechnik', Locked = true;
    ConstructionENTok: Label 'Construction,Building Services,Interiors,Building Planning,Commercial Build,Timber Construction,Civil Engineering,Building Systems', Locked = true;
    ServiceDETok: Label 'Wartung,Instandhaltung,Anlagenservice,Gebäudeservice,Technikservice,Reparaturservice,Objektservice,Industrieservice', Locked = true;
    ServiceENTok: Label 'Maintenance,Facilities,Plant Services,Building Care,Technical Services,Repair Services,Property Services,Industrial Services', Locked = true;
    ManufacturingDETok: Label 'Metalltechnik,Feinmechanik,Komponentenbau,Werkzeugbau,Anlagentechnik,Fertigung,Maschinenbau,Montagetechnik', Locked = true;
    ManufacturingENTok: Label 'Metal Engineering,Precision Engineering,Components,Toolmaking,Plant Engineering,Manufacturing,Machinery,Assembly Systems', Locked = true;
    DistributionDETok: Label 'Logistik,Warenlogistik,Lagerlogistik,Distribution,Beschaffung,Fachdistribution,Handelslogistik,Materialversorgung', Locked = true;
    DistributionENTok: Label 'Logistics,Goods Distribution,Warehouse Services,Distribution,Procurement,Specialist Distribution,Trade Logistics,Material Supply', Locked = true;
    EcommerceDETok: Label 'Onlinehandel,Direktvertrieb,Versandhandel,Digitalvertrieb,Einzelhandel,Onlineshop,Warenvertrieb,Handel', Locked = true;
    EcommerceENTok: Label 'Online Retail,Direct Sales,Mail Order,Digital Sales,Retail,Online Store,Distribution,Trading', Locked = true;
    CountryErr: Label 'Partner catalog version 2 supports address countries DE and GB. Configure a supported country instead of generating inconsistent addresses for %1.', Comment = '%1 = country code';
    KeyErr: Label 'Partner catalog logical keys must be positive.';
    GermanFirstNamesTok: Label 'Jonas,Lea,Clara,Felix,Emma,Leon,Marie,Paul,Anna,Lukas,Lina,Max,Laura,Elias,Sophie,Noah,Hannah,David,Mia,Julian,Julia,Simon,Elena,Tim,Luisa,Jakob,Amelie,Niklas,Charlotte,Philipp,Johanna,Alexander', Locked = true;
    EnglishFirstNamesTok: Label 'Oliver,Amelia,George,Isla,Arthur,Ava,Harry,Freya,Leo,Ivy,Oscar,Lily,Charlie,Florence,Henry,Mia,Jack,Grace,Noah,Sophie,Thomas,Ella,William,Emily,James,Charlotte,Samuel,Alice,Daniel,Lucy,Edward,Matilda', Locked = true;
    GermanLastNamesTok: Label 'Schneider,Müller,Weber,Wagner,Becker,Schulz,Hoffmann,Schäfer,Koch,Bauer,Richter,Klein,Wolf,Schröder,Neumann,Schwarz,Braun,Zimmermann,Krüger,Hartmann,Lange,Schmitt,Werner,Schmitz,Krause,Meier,Lehmann,Schmid,Schulze,Maier,Köhler,Herrmann,König,Walter,Mayer,Huber,Kaiser,Fuchs,Peters,Lang,Scholz,Möller,Weiss,Jung,Hahn,Schubert,Vogel,Friedrich,Keller,Günther,Frank,Berger,Winkler,Roth,Beck,Lorenz,Baumann,Franke,Albrecht,Ludwig,Winter,Simon,Brandt,Seidel', Locked = true;
    EnglishLastNamesTok: Label 'Smith,Jones,Taylor,Brown,Williams,Wilson,Johnson,Davies,Robinson,Wright,Thompson,Evans,Walker,White,Roberts,Green,Hall,Thomas,Clarke,Jackson,Wood,Harris,Edwards,Turner,Martin,Cooper,Hill,Ward,Hughes,Moore,Clark,King,Baker,Lee,Allen,Morris,Scott,Watson,Davis,Parker,Price,Bennett,Young,Phillips,Richardson,Mitchell,Bailey,Collins,Carter,Stewart,Shaw,Ellis,Morgan,Cook,Webb,Bell,Adams,Kelly,Murphy,Chapman,Marshall,Mason,Gray,James', Locked = true;
    GermanCompanyNamesTok: Label 'Rheingarten,Elbwinkel,Falkenried,Lindenfels,Altenhafen,Birkenhain,Westbogen,Sonnenfeld,Havelgrund,Bergtal,Kornwinkel,Waldbrück,Eichenborn,Steinbach,Heidehof,Rosenquell,Feldhain,Wiesenberg,Bachgarten,Schwanenfels,Ahornblick,Seebogen,Weidenau,Tannengrund,Hohenried,Nordhafen,Kastanienhof,Südsteg,Erlenblick,Finkenau,Kirschberg,Wolfsgrund', Locked = true;
    EnglishCompanyNamesTok: Label 'Ashbourne,Brookhaven,Cedarwick,Daleford,Eastmere,Fernwick,Glenbrook,Hawthorne,Ivybridge,Kingswell,Lakeshore,Meadowgate,Northbridge,Oakfield,Pinehurst,Queensbrook,Rivergate,Stonebridge,Thornfield,Westhaven,Willowmere,Yewbrook,Alderford,Birchwell,Coppergate,Elmstead,Foxbridge,Greenhaven,Heatherwick,Mapleford,Rosehaven,Silverbrook', Locked = true;
    GermanActivitiesTok: Label 'Handel,Technik,Logistik,Warenvertrieb,Bürobedarf,Industriebedarf,Haustechnik,Elektrohandel,Bautechnik,Fachhandel,Einrichtung,Verpackungen,Feinmechanik,Werkzeughandel,Textilhandel,Metallwaren,Holzhandel,Handelskontor,Beschaffung,Ausrüstung,Objektservice,Vertrieb,Materialtechnik,Handelshaus,Systemtechnik,Fachbedarf,Komponenten,Betriebsausstattung,Montagetechnik,Warenkontor,Industrieservice,Versorgung', Locked = true;
    EnglishActivitiesTok: Label 'Trading,Engineering,Logistics,Supplies,Office Products,Industrial Supply,Building Services,Electrical Supply,Construction Supply,Distribution,Interiors,Packaging,Precision Tools,Tool Supply,Textiles,Metal Products,Timber,Commerce,Procurement,Equipment,Property Services,Sales,Materials,Merchants,Systems,Professional Supply,Components,Workplace Products,Assembly Systems,Wholesale,Industrial Services,Resources', Locked = true;
    GermanLegalFormsTok: Label 'GmbH,AG,KG,GmbH & Co. KG', Locked = true;
    EnglishLegalFormsTok: Label 'Ltd,Limited,PLC,LLP', Locked = true;
    GermanCitiesTok: Label 'Berlin,Hamburg,München,Köln,Frankfurt am Main,Stuttgart,Leipzig,Dresden,Bonn,Düsseldorf,Dortmund,Essen,Bremen,Hannover,Nürnberg,Mannheim,Karlsruhe,Münster,Aachen,Wuppertal', Locked = true;
    GermanPostCodesTok: Label '10115,20095,80331,50667,60311,70173,04109,01067,53111,40213,44135,45127,28195,30159,90402,68159,76133,48143,52062,42103', Locked = true;
    EnglishCitiesTok: Label 'London,Manchester,Birmingham,Leeds,Bristol,Liverpool,Sheffield,Nottingham,Leicester,Coventry,Bradford,Cardiff,Newcastle,Southampton,Portsmouth,Derby,Reading,Oxford,Cambridge,York', Locked = true;
    EnglishPostCodesTok: Label 'SW1A 1AA,M1 1AE,B1 1BB,LS1 1UR,BS1 1AD,L1 8JQ,S1 2HH,NG1 1AA,LE1 1AA,CV1 1AA,BD1 1AA,CF10 1AA,NE1 1AA,SO14 1AA,PO1 1AA,DE1 1AA,RG1 1AA,OX1 1AA,CB1 1AA,YO1 1AA', Locked = true;
    GermanStreetsTok: Label 'Kastanienweg,Lindenallee,Birkenstraße,Ahornweg,Eichenstraße,Erlenweg,Rosenstraße,Gartenweg,Bachstraße,Parkallee,Heideweg,Buchenstraße,Weidenweg,Feldstraße,Ulmenweg,Seestraße', Locked = true;
    EnglishStreetsTok: Label 'Oak Lane,Willow Road,Maple Avenue,Cedar Close,Birch Street,Elm Road,Rose Lane,Garden Way,Brook Street,Park Avenue,Heather Road,Beech Street,Alder Lane,Meadow Road,Pine Close,Lake Road', Locked = true;
}
