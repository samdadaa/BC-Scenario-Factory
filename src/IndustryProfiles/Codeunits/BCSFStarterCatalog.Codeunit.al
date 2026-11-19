namespace BCScenarioFactory.IndustryProfiles;

using BCScenarioFactory.Core;
using BCScenarioFactory.Finance;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Environment;

codeunit 90155 "BCSF Starter Catalog"
{
    Access = Internal;
    Permissions = tabledata "BCSF Removed Template" = D;

    procedure IsStarterSandbox(): Boolean
    var
        Environment: Codeunit "Environment Information";
    begin
        exit(Environment.IsSaaS() and Environment.IsSandbox() and not Environment.IsProduction());
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure InitializeCompany(Mode: Enum "BCSF Finance Mode")
    var
        Setup: Record "BCSF Factory Setup";
        Scenario: Record "BCSF Scenario";
        SetupMgt: Codeunit "BCSF Setup Management";
        Packages: Codeunit "BCSF Finance Package Mgt";
        Guard: Codeunit "BCSF Environment Guard";
    begin
        if not IsStarterSandbox() then
            Error(SandboxErr);
        // Coordinate with snapshot and template writers: scenario locks precede setup locks.
        Scenario.LockTable();
        SetupMgt.InitializeSetup();
        Guard.EnsureCanConfigure(CompanyName());
        Setup.Get(Setup.GetSetupKey());
        if Setup."Company Initialized" then
            exit;
        Packages.InitializeCompany(Mode);
        Setup."Company Initialized" := true;
        Setup.Validate("Generation Enabled", true);
        Setup.Modify(true);
        Seed();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Seed()
    var
        Setup: Record "BCSF Factory Setup";
        Scenario: Record "BCSF Scenario";
        SetupMgt: Codeunit "BCSF Setup Management";
        Industry: Integer;
    begin
        if not IsStarterSandbox() then
            Error(SandboxErr);
        Scenario.LockTable();
        SetupMgt.EnsureInitialized();
        SetupMgt.GetSetup(Setup);
        for Industry := 1 to 8 do
            SeedIndustry(Industry, Setup);
    end;

    local procedure SeedIndustry(Industry: Integer; Setup: Record "BCSF Factory Setup")
    var
        Profile: Code[20];
        Name: Text;
        Consumer: Integer;
    begin
        Consumer := 0;
        case Industry of
            1:
                begin
                    Profile := 'GENERAL';
                    Name := GeneralLbl;
                end;
            2:
                begin
                    Profile := 'TRADE';
                    Name := TradeLbl;
                    Consumer := 15;
                end;
            3:
                begin
                    Profile := 'ECOMMERCE';
                    Name := EcommerceLbl;
                    Consumer := 75;
                end;
            4:
                begin
                    Profile := 'DISTRIBUTION';
                    Name := DistributionLbl;
                end;
            5:
                begin
                    Profile := 'MANUFACTURING';
                    Name := ManufacturingLbl;
                end;
            6:
                begin
                    Profile := 'CONSULTING';
                    Name := ConsultingLbl;
                end;
            7:
                begin
                    Profile := 'CONSTRUCTION';
                    Name := ConstructionLbl;
                end;
            8:
                begin
                    Profile := 'SERVICE';
                    Name := ServiceLbl;
                    Consumer := 35;
                end;
        end;
        SeedOne(Industry, 1, Profile, Name, DemoLbl, "BCSF Usage Mode"::Demo, "BCSF Process Mode"::SetupAndMasterData, Consumer, 12, 7, Setup);
        SeedOne(Industry, 2, Profile, Name, TrainingLbl, "BCSF Usage Mode"::Training, "BCSF Process Mode"::SetupAndMasterData, Consumer, 20, 10, Setup);
        SeedOne(Industry, 3, Profile, Name, FunctionalLbl, "BCSF Usage Mode"::Functional, "BCSF Process Mode"::SetupAndMasterData, Consumer, 5, 5, Setup);
        SeedOne(Industry, 4, Profile, Name, PerformanceLbl, "BCSF Usage Mode"::Performance, "BCSF Process Mode"::SetupAndMasterData, Consumer, 1000, 500, Setup);
        SeedOne(Industry, 5, Profile, Name, DocumentsLbl, "BCSF Usage Mode"::Demo, "BCSF Process Mode"::UnpostedDocuments, Consumer, 12, 7, Setup);
        SeedOne(Industry, 6, Profile, Name, PostedLbl, "BCSF Usage Mode"::Demo, "BCSF Process Mode"::PostedMovements, Consumer, 12, 7, Setup);
        SeedOne(Industry, 7, Profile, Name, FollowUpLbl, "BCSF Usage Mode"::Demo, "BCSF Process Mode"::FollowUpProcesses, Consumer, 12, 7, Setup);
    end;

    local procedure SeedOne(Industry: Integer; VariantNo: Integer; Profile: Code[20]; Name: Text; Purpose: Text; Usage: Enum "BCSF Usage Mode"; Scope: Enum "BCSF Process Mode"; Consumer: Integer; Customers: Integer; Vendors: Integer; Setup: Record "BCSF Factory Setup")
    var
        Scenario: Record "BCSF Scenario";
        Removed: Record "BCSF Removed Template";
        ScenarioId: Guid;
        Qty: Integer;
        Share: Decimal;
    begin
        ScenarioId := GetStarterId(Industry, VariantNo);
        Scenario.LockTable();
        if Removed.Get(ScenarioId) then
            exit;
        if Scenario.Get(ScenarioId) then
            exit;
        Customers := MinValue(Customers, Setup."Maximum Records per Entity");
        Vendors := MinValue(Vendors, Setup."Maximum Records per Entity");
        Scenario.Init();
        Scenario."Scenario Id" := ScenarioId;
        Scenario.Description := CopyStr(StrSubstNo(TitleLbl, Name, Purpose), 1, MaxStrLen(Scenario.Description));
        Scenario."Profile Code" := Profile;
        Scenario."Profile Version" := '1';
        Scenario."Usage Mode" := Usage;
        Scenario."Process Mode" := Scope;
        Scenario.Seed := Industry * 100 + VariantNo;
        Scenario."Starting Date" := WorkDate();
        Scenario."Ending Date" := WorkDate();
        Scenario."Batch Size" := MinValue(Setup."Default Batch Size", MinValue(Customers, Vendors));
        Scenario."Data Language" := Setup."Default Data Language";
        Scenario."B2C Percent" := Consumer;
        Scenario.Insert(true);
        AddModule(ScenarioId, "BCSF Module Type"::Sales);
        AddModule(ScenarioId, "BCSF Module Type"::Purchasing);
        AddTarget(ScenarioId, "BCSF Entity Type"::Customer, Customers, "BCSF Process Mode"::SetupAndMasterData, 0);
        AddTarget(ScenarioId, "BCSF Entity Type"::Vendor, Vendors, "BCSF Process Mode"::SetupAndMasterData, 0);
        if Scope = "BCSF Process Mode"::SetupAndMasterData then
            exit;
        Qty := MinValue(5, Setup."Maximum Records per Entity");
        if Industry in [2, 3, 4, 5, 8] then begin
            AddModule(ScenarioId, "BCSF Module Type"::Inventory);
            AddTarget(ScenarioId, "BCSF Entity Type"::Item, Qty, "BCSF Process Mode"::SetupAndMasterData, 0);
        end;
        case Industry of
            4:
                AddModule(ScenarioId, "BCSF Module Type"::Warehouse);
            5:
                begin
                    AddModule(ScenarioId, "BCSF Module Type"::Manufacturing);
                    AddModule(ScenarioId, "BCSF Module Type"::Assembly);
                end;
            6, 7:
                AddModule(ScenarioId, "BCSF Module Type"::Projects);
            8:
                AddModule(ScenarioId, "BCSF Module Type"::ServiceManagement);
        end;
        if Scope <> "BCSF Process Mode"::UnpostedDocuments then
            Share := 100;
        AddTarget(ScenarioId, "BCSF Entity Type"::SalesOrder, Qty, Scope, Share);
        AddTarget(ScenarioId, "BCSF Entity Type"::PurchaseOrder, Qty, Scope, Share);
    end;

    local procedure AddModule(ScenarioId: Guid; ModuleType: Enum "BCSF Module Type")
    var
        Selection: Record "BCSF Scenario Module";
    begin
        Selection.Init();
        Selection."Scenario Id" := ScenarioId;
        Selection.Module := ModuleType;
        Selection.Enabled := true;
        Selection.Insert(true);
    end;

    local procedure AddTarget(ScenarioId: Guid; Entity: Enum "BCSF Entity Type"; Quantity: Integer; Scope: Enum "BCSF Process Mode"; PostedShare: Decimal)
    var
        Target: Record "BCSF Data Target";
    begin
        Target.Init();
        Target."Scenario Id" := ScenarioId;
        Target.Validate(Entity, Entity);
        Target.Quantity := Quantity;
        Target."Process Mode" := Scope;
        Target."Unposted Percent" := 100 - PostedShare;
        Target."Posted Percent" := PostedShare;
        Target.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Scenario Manager", 'OnGetDisplayName', '', false, false)]
    local procedure LocalizeStarter(Scenario: Record "BCSF Scenario"; var Name: Text)
    var
        Industry: Integer;
        VariantNo: Integer;
        Id: Guid;
    begin
        for Industry := 1 to 8 do
            for VariantNo := 1 to 7 do begin
                Id := GetStarterId(Industry, VariantNo);
                if Id = Scenario."Scenario Id" then
                    if (Scenario.Description = DefaultName(Industry, VariantNo, 1)) or
                       (Scenario.Description = DefaultName(Industry, VariantNo, 2)) then begin
                        Name := DefaultName(Industry, VariantNo, 0);
                        exit;
                    end;
            end;
    end;

    procedure RestoreStarters()
    var
        Removed: Record "BCSF Removed Template";
        Scenario: Record "BCSF Scenario";
        Industry: Integer;
        VariantNo: Integer;
        Id: Guid;
    begin
        if not Confirm(RestoreQst, false) then
            exit;
        Scenario.LockTable();
        for Industry := 1 to 8 do
            for VariantNo := 1 to 7 do begin
                Id := GetStarterId(Industry, VariantNo);
                if Removed.Get(Id) then
                    Removed.Delete(true);
                if Scenario.Get(Id) then
                    if Scenario.Archived then begin
                        Scenario.Archived := false;
                        Scenario.Modify(true);
                    end;
            end;
        Seed();
    end;

    local procedure DefaultName(Industry: Integer; VariantNo: Integer; LanguageVersion: Integer): Text
    var
        Name: Text;
        Purpose: Text;
    begin
        case Industry of
            1: Name := GeneralLbl;
            2: Name := TradeLbl;
            3: Name := EcommerceLbl;
            4: Name := DistributionLbl;
            5: Name := ManufacturingLbl;
            6: Name := ConsultingLbl;
            7: Name := ConstructionLbl;
            8: Name := ServiceLbl;
        end;
        case VariantNo of
            1: Purpose := DemoLbl;
            2: Purpose := TrainingLbl;
            3: Purpose := FunctionalLbl;
            4: Purpose := PerformanceLbl;
            5: Purpose := DocumentsLbl;
            6: Purpose := PostedLbl;
            7: Purpose := FollowUpLbl;
        end;
        case LanguageVersion of
            1: exit(SelectStr(Industry, EnglishIndustriesTok) + ' - ' + SelectStr(VariantNo, EnglishPurposesTok));
            2: exit(SelectStr(Industry, GermanIndustriesTok) + ' – ' + SelectStr(VariantNo, GermanPurposesTok));
        end;
        exit(StrSubstNo(TitleLbl, Name, Purpose));
    end;

    local procedure GetStarterId(Industry: Integer; VariantNo: Integer): Guid
    var
        Id: Guid;
    begin
        Evaluate(Id, '{bc5f2026-0001-4a01-8101-' + PadStr('', 10, '0') + Format(Industry, 0, 9) + Format(VariantNo, 0, 9) + '}');
        exit(Id);
    end;

    local procedure MinValue(Left: Integer; Right: Integer): Integer
    begin
        if Left < Right then
            exit(Left);
        exit(Right);
    end;

    var
        RestoreQst: Label 'Restore all removed or archived built-in starter templates? Custom names are retained.';
        EnglishIndustriesTok: Label 'General Business,Wholesale and Retail,E-Commerce,Distribution and Logistics,Manufacturing,Services and Consulting,Construction and Projects,Service and Maintenance', Locked = true;
        EnglishPurposesTok: Label 'Demo Partners,Training Partners,Functional Partner Test,Partner Volume Test,Planning Only: Open Documents,Planning Only: Posted Movements,Planning Only: Follow-Up Processes', Locked = true;
        GermanIndustriesTok: Label 'Allgemeines Unternehmen,Groß- und Einzelhandel,E-Commerce,Distribution und Logistik,Fertigung,Dienstleistung und Beratung,Bau- und Projektgeschäft,Service und Wartung', Locked = true;
        GermanPurposesTok: Label 'Demo: Debitoren und Kreditoren,Schulung: Debitoren und Kreditoren,Funktionstest: Debitoren und Kreditoren,Lasttest-Vorlage: Debitoren und Kreditoren,Nur Planung: Offene Belege,Nur Planung: Gebuchte Bewegungen,Nur Planung: Folgeprozesse', Locked = true;
        SandboxErr: Label 'Load starter scenarios only in an approved sandbox.';
        TitleLbl: Label '%1 - %2', Comment = '%1 = industry, %2 = scenario type';
        GeneralLbl: Label 'General Business';
        TradeLbl: Label 'Wholesale and Retail';
        EcommerceLbl: Label 'E-Commerce';
        DistributionLbl: Label 'Distribution and Logistics';
        ManufacturingLbl: Label 'Manufacturing';
        ConsultingLbl: Label 'Services and Consulting';
        ConstructionLbl: Label 'Construction and Projects';
        ServiceLbl: Label 'Service and Maintenance';
        DemoLbl: Label 'Demo Partners';
        TrainingLbl: Label 'Training Partners';
        FunctionalLbl: Label 'Functional Partner Test';
        PerformanceLbl: Label 'Partner Volume Test';
        DocumentsLbl: Label 'Planning Only: Open Documents';
        PostedLbl: Label 'Planning Only: Posted Movements';
        FollowUpLbl: Label 'Planning Only: Follow-Up Processes';
}
