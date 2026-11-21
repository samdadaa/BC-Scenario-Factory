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
    begin
        InitializeFoundation(Mode);
        Seed();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure InitializeFoundation(Mode: Enum "BCSF Finance Mode")
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
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure RefreshCompanyFoundation()
    var
        SetupMgt: Codeunit "BCSF Setup Management";
        Packages: Codeunit "BCSF Finance Package Mgt";
        Guard: Codeunit "BCSF Environment Guard";
    begin
        Guard.EnsureCanConfigure(CompanyName());
        SetupMgt.EnsureInitialized();
        if Packages.GetAppliedMode() = "BCSF Finance Mode"::Existing then
            Error(ExistingFoundationErr);
        // Same applied package, same accounts; existing conflict/posted-company guards remain active.
        Packages.InitializeCompany(Packages.GetAppliedMode());
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
        SeedItemTemplates(Setup);
        SeedSalesTemplate(Setup);
        SeedWholesaleReference();
    end;

    local procedure SeedWholesaleReference()
    var
        Scenario: Record "BCSF Scenario";
        Removed: Record "BCSF Removed Template";
        Profile: Codeunit "BCSF Wholesale Profile";
        Id: Guid;
    begin
        Evaluate(Id, '{B55C4500-AB51-4045-9C00-000000000001}');
        // Explicit starter loading only. Never replace a custom, archived or intentionally removed template.
        if Scenario.Get(Id) or Removed.Get(Id) then
            exit;
        Profile.CreateTemplateForId(Id, 0, "BCSF Process Mode"::UnpostedDocuments, WorkDate());
    end;

    local procedure SeedSalesTemplate(Setup: Record "BCSF Factory Setup")
    var
        Scenario: Record "BCSF Scenario";
        Removed: Record "BCSF Removed Template";
        Id: Guid;
        VariantNo: Integer;
    begin
        for VariantNo := 1 to 2 do begin
            Evaluate(Id, '{B55C2100-AB51-4021-9C00-00000000000' + Format(VariantNo, 0, 9) + '}');
            if not Scenario.Get(Id) and not Removed.Get(Id) then begin
                Scenario.Init();
                Scenario."Scenario Id" := Id;
                Scenario.Description := SalesDocumentsLbl;
                Scenario."Profile Code" := 'TECH-SALES';
                Scenario."Profile Version" := '3';
                Scenario."Usage Mode" := "BCSF Usage Mode"::Functional;
                Scenario."Process Mode" := "BCSF Process Mode"::UnpostedDocuments;
                if VariantNo = 2 then begin
                    Scenario.Description := MixedSalesLbl;
                    Scenario."Process Mode" := "BCSF Process Mode"::PostedMovements;
                end;
                Scenario.Seed := 2100 + VariantNo;
                Scenario."Starting Date" := WorkDate();
                Scenario."Ending Date" := WorkDate();
                Scenario."Batch Size" := MinValue(3, Setup."Default Batch Size");
                Scenario."Data Language" := Setup."Default Data Language";
                Scenario.Insert(true);
                ConfigureSalesTargets(Scenario, 0, Setup);
            end else
                if not Removed.Get(Id) and (Scenario."Profile Code" = 'TECH-SALES') and (Scenario.Seed = 2100 + VariantNo) then
                    UpgradeSalesMasters(Scenario, Setup);
        end;
    end;

    local procedure ConfigureSalesTargets(Scenario: Record "BCSF Scenario"; Industry: Integer; Setup: Record "BCSF Factory Setup")
    var
        OrderQuantity: Integer;
        InvoiceQuantity: Integer;
    begin
        AddModule(Scenario."Scenario Id", "BCSF Module Type"::Sales);
        AddSalesMasters(Scenario."Scenario Id", Setup);
        OrderQuantity := 4;
        InvoiceQuantity := 2;
        if Scenario."Process Mode" = "BCSF Process Mode"::PostedMovements then begin
            OrderQuantity := 10;
            InvoiceQuantity := 4;
        end;
        AddTarget(Scenario."Scenario Id", "BCSF Entity Type"::SalesQuote, MinValue(2, Setup."Maximum Records per Entity"), "BCSF Process Mode"::UnpostedDocuments, 0);
        AddTarget(Scenario."Scenario Id", "BCSF Entity Type"::SalesOrder, MinValue(OrderQuantity, Setup."Maximum Records per Entity"), Scenario."Process Mode", 0);
        AddTarget(Scenario."Scenario Id", "BCSF Entity Type"::SalesInvoice, MinValue(InvoiceQuantity, Setup."Maximum Records per Entity"), Scenario."Process Mode", 0);
        if Scenario."Process Mode" = "BCSF Process Mode"::PostedMovements then
            ApplySalesMix(Scenario."Scenario Id", Industry);
    end;

    local procedure AddSalesMasters(ScenarioId: Guid; Setup: Record "BCSF Factory Setup")
    begin
        AddModule(ScenarioId, "BCSF Module Type"::Purchasing);
        AddModule(ScenarioId, "BCSF Module Type"::Inventory);
        AddTarget(ScenarioId, "BCSF Entity Type"::Customer, 1, "BCSF Process Mode"::SetupAndMasterData, 0);
        AddTarget(ScenarioId, "BCSF Entity Type"::Vendor, MinValue(2, Setup."Maximum Records per Entity"), "BCSF Process Mode"::SetupAndMasterData, 0);
        AddTarget(ScenarioId, "BCSF Entity Type"::Item, MinValue(8, Setup."Maximum Records per Entity"), "BCSF Process Mode"::SetupAndMasterData, 0);
    end;

    local procedure UpgradeSalesMasters(var Scenario: Record "BCSF Scenario"; Setup: Record "BCSF Factory Setup")
    var
        Target: Record "BCSF Data Target";
        Selection: Record "BCSF Scenario Module";
    begin
        if Scenario.Archived or not (Scenario."Profile Version" in ['1', '2']) or
          (Scenario."Item Vendor No." <> '') or (Scenario."Item Second Vendor No." <> '') then
            exit;
        Target.SetRange("Scenario Id", Scenario."Scenario Id");
        Selection.SetRange("Scenario Id", Scenario."Scenario Id");
        if (Target.Count() <> 3) or (Selection.Count() <> 1) then
            exit;
        if not Selection.Get(Scenario."Scenario Id", Selection.Module::Sales) then
            exit;
        if not Selection.Enabled then
            exit;
        if not Target.Get(Scenario."Scenario Id", Target.Entity::SalesQuote) or
          not Target.Get(Scenario."Scenario Id", Target.Entity::SalesOrder) or
          not Target.Get(Scenario."Scenario Id", Target.Entity::SalesInvoice) then
            exit;
        Scenario."Profile Version" := '3';
        Scenario."Sales Posting Approved" := false;
        Scenario.Modify(true);
        AddSalesMasters(Scenario."Scenario Id", Setup);
    end;

    local procedure ApplySalesMix(ScenarioId: Guid; Industry: Integer)
    var
        Target: Record "BCSF Data Target";
        Policy: Codeunit "BCSF Scenario Policy";
    begin
        Target.SetRange("Scenario Id", ScenarioId);
        Target.SetFilter(Entity, '%1|%2|%3', Target.Entity::SalesQuote, Target.Entity::SalesOrder, Target.Entity::SalesInvoice);
        if Target.FindSet(true) then
            repeat
                Policy.ApplyDocumentModeDefaults(Target);
                if Target.Entity = "BCSF Entity Type"::SalesOrder then begin
                    case Industry of
                        2:
                            begin
                                Target."Posted Percent" := 60;
                                Target."Partial Percent" := 20;
                            end;
                        3:
                            begin
                                Target."Posted Percent" := 75;
                                Target."Partial Percent" := 10;
                            end;
                        4:
                            begin
                                Target."Posted Percent" := 50;
                                Target."Partial Percent" := 30;
                            end;
                        5:
                            begin
                                Target."Posted Percent" := 45;
                                Target."Partial Percent" := 20;
                            end;
                        6:
                            begin
                                Target."Posted Percent" := 40;
                                Target."Partial Percent" := 10;
                            end;
                        7:
                            begin
                                Target."Posted Percent" := 40;
                                Target."Partial Percent" := 20;
                            end;
                        8:
                            begin
                                Target."Posted Percent" := 40;
                                Target."Partial Percent" := 15;
                            end;
                    end;
                    Target."Unposted Percent" := 100 - Target."Posted Percent" - Target."Partial Percent";
                end;
                Target.Modify(true);
            until Target.Next() = 0;
    end;

    local procedure IsLegacySalesStarter(Scenario: Record "BCSF Scenario"; Industry: Integer; VariantNo: Integer; Profile: Code[20]; Setup: Record "BCSF Factory Setup"): Boolean
    var
        Target: Record "BCSF Data Target";
        Selection: Record "BCSF Scenario Module";
        ExpectedCount: Integer;
        ExpectedQuantity: Integer;
        PostedShare: Decimal;
        HasItems: Boolean;
    begin
        if Scenario.Archived or (Scenario."Profile Version" <> '1') or
          (Scenario.Seed <> Industry * 100 + VariantNo) or (Scenario."Profile Code" <> Profile) then
            exit(false);
        if (VariantNo = 5) and (Scenario."Process Mode" <> "BCSF Process Mode"::UnpostedDocuments) then
            exit(false);
        if (VariantNo = 6) and (Scenario."Process Mode" <> "BCSF Process Mode"::PostedMovements) then
            exit(false);
        HasItems := Industry in [2, 3, 4, 5, 8];
        ExpectedCount := 4;
        if HasItems then
            ExpectedCount += 1;
        Target.SetRange("Scenario Id", Scenario."Scenario Id");
        if Target.Count() <> ExpectedCount then
            exit(false);
        if not Target.Get(Scenario."Scenario Id", Target.Entity::Customer) or
          not Target.Get(Scenario."Scenario Id", Target.Entity::Vendor) or
          not Target.Get(Scenario."Scenario Id", Target.Entity::SalesOrder) or
          not Target.Get(Scenario."Scenario Id", Target.Entity::PurchaseOrder) then
            exit(false);
        if Target.Get(Scenario."Scenario Id", Target.Entity::Item) <> HasItems then
            exit(false);
        if VariantNo = 6 then
            PostedShare := 100;
        if not Target.FindSet() then
            exit(false);
        repeat
            case Target.Entity of
                Target.Entity::Customer: ExpectedQuantity := MinValue(12, Setup."Maximum Records per Entity");
                Target.Entity::Vendor: ExpectedQuantity := MinValue(7, Setup."Maximum Records per Entity");
                Target.Entity::Item, Target.Entity::SalesOrder, Target.Entity::PurchaseOrder:
                    ExpectedQuantity := MinValue(5, Setup."Maximum Records per Entity");
                else exit(false);
            end;
            if (Target.Quantity <> ExpectedQuantity) or (Target."Partial Percent" <> 0) then
                exit(false);
            if Target.Entity in [Target.Entity::SalesOrder, Target.Entity::PurchaseOrder] then begin
                if (Target."Process Mode" <> Scenario."Process Mode") or (Target."Posted Percent" <> PostedShare) then
                    exit(false);
            end else
                if (Target."Process Mode" <> "BCSF Process Mode"::SetupAndMasterData) or (Target."Posted Percent" <> 0) then
                    exit(false);
        until Target.Next() = 0;
        Selection.SetRange("Scenario Id", Scenario."Scenario Id");
        ExpectedCount := 2;
        if HasItems then
            ExpectedCount += 1;
        case Industry of
            4, 6, 7, 8: ExpectedCount += 1;
            5: ExpectedCount += 2;
        end;
        if Selection.Count() <> ExpectedCount then
            exit(false);
        if Selection.FindSet() then
            repeat
                if not Selection.Enabled then
                    exit(false);
                case Selection.Module of
                    Selection.Module::Sales, Selection.Module::Purchasing: ;
                    Selection.Module::Inventory:
                        if not HasItems then
                            exit(false);
                    Selection.Module::Warehouse:
                        if Industry <> 4 then
                            exit(false);
                    Selection.Module::Manufacturing, Selection.Module::Assembly:
                        if Industry <> 5 then
                            exit(false);
                    Selection.Module::Projects:
                        if not (Industry in [6, 7]) then
                            exit(false);
                    Selection.Module::ServiceManagement:
                        if Industry <> 8 then
                            exit(false);
                    else exit(false);
                end;
            until Selection.Next() = 0;
        exit(true);
    end;

    local procedure UpgradeSalesStarter(var Scenario: Record "BCSF Scenario"; Industry: Integer; VariantNo: Integer; Profile: Code[20]; Setup: Record "BCSF Factory Setup")
    var
        Target: Record "BCSF Data Target";
        Selection: Record "BCSF Scenario Module";
        DefaultNameUsed: Boolean;
    begin
        if not (VariantNo in [5, 6]) then
            exit;
        if not IsLegacySalesStarter(Scenario, Industry, VariantNo, Profile, Setup) then
            exit;
        DefaultNameUsed := IsDefaultName(Scenario.Description, Industry, VariantNo);
        Target.SetRange("Scenario Id", Scenario."Scenario Id");
        Target.DeleteAll(true);
        Selection.SetRange("Scenario Id", Scenario."Scenario Id");
        Selection.DeleteAll(true);
        Scenario.Get(Scenario."Scenario Id");
        Scenario."Profile Version" := '3';
        Scenario."Sales Posting Approved" := false;
        if DefaultNameUsed then
            Scenario.Description := CopyStr(DefaultName(Industry, VariantNo, 0), 1, MaxStrLen(Scenario.Description));
        Scenario.Modify(true);
        ConfigureSalesTargets(Scenario, Industry, Setup);
    end;

    local procedure IsDefaultName(Name: Text; Industry: Integer; VariantNo: Integer): Boolean
    begin
        exit((Name = DefaultName(Industry, VariantNo, 1)) or
          (Name = DefaultName(Industry, VariantNo, 2)) or
          (Name = SelectStr(Industry, EnglishIndustriesTok) + ' - ' + SelectStr(VariantNo, LegacyEnglishPurposesTok)) or
          (Name = SelectStr(Industry, GermanIndustriesTok) + ' – ' + SelectStr(VariantNo, LegacyGermanPurposesTok)));
    end;

    local procedure SeedItemTemplates(Setup: Record "BCSF Factory Setup")
    var
        Scenario: Record "BCSF Scenario";
        Removed: Record "BCSF Removed Template";
        ScenarioId: Guid;
        VariantNo: Integer;
    begin
        for VariantNo := 1 to 2 do begin
            if VariantNo = 1 then
                Evaluate(ScenarioId, '{B55C1900-AB51-4019-9C00-000000000001}')
            else
                Evaluate(ScenarioId, '{B55C1900-AB51-4019-9C00-000000000002}');
            if not Scenario.Get(ScenarioId) and not Removed.Get(ScenarioId) then begin
                Scenario.Init();
                Scenario."Scenario Id" := ScenarioId;
                Scenario.Description := TechnicalItemsLbl;
                Scenario."Profile Code" := 'TECH-TRADE';
                if VariantNo = 2 then begin
                    Scenario.Description := TechnicalBinsLbl;
                    Scenario."Profile Code" := 'TECH-BINS';
                end;
                Scenario."Profile Version" := '1';
                Scenario."Usage Mode" := "BCSF Usage Mode"::Functional;
                Scenario."Process Mode" := "BCSF Process Mode"::SetupAndMasterData;
                Scenario.Seed := 1901;
                Scenario."Starting Date" := WorkDate();
                Scenario."Ending Date" := WorkDate();
                Scenario."Batch Size" := MinValue(3, Setup."Default Batch Size");
                Scenario."Data Language" := Setup."Default Data Language";
                Scenario."B2C Percent" := 0;
                Scenario.Insert(true);
                AddModule(ScenarioId, "BCSF Module Type"::Inventory);
                AddModule(ScenarioId, "BCSF Module Type"::Sales);
                AddTarget(ScenarioId, "BCSF Entity Type"::Customer, 1, "BCSF Process Mode"::SetupAndMasterData, 0);
                AddModule(ScenarioId, "BCSF Module Type"::Purchasing);
                AddTarget(ScenarioId, "BCSF Entity Type"::Vendor, MinValue(2, Setup."Maximum Records per Entity"), "BCSF Process Mode"::SetupAndMasterData, 0);
                AddTarget(ScenarioId, "BCSF Entity Type"::Item, MinValue(8, Setup."Maximum Records per Entity"), "BCSF Process Mode"::SetupAndMasterData, 0);
            end;
        end;
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
        if Scenario.Get(ScenarioId) then begin
            if (VariantNo in [5, 6]) and (Scenario."Profile Code" = Profile) and
              (Scenario.Seed = Industry * 100 + VariantNo) and (Scenario."Profile Version" = '2') then
                UpgradeSalesMasters(Scenario, Setup)
            else
                UpgradeSalesStarter(Scenario, Industry, VariantNo, Profile, Setup);
            exit;
        end;
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
        if VariantNo in [5, 6] then
            Scenario."Profile Version" := '3';
        Scenario.Insert(true);
        if VariantNo in [5, 6] then begin
            ConfigureSalesTargets(Scenario, Industry, Setup);
            exit;
        end;
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
        Target."Partial Percent" := 0;
        Target.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Scenario Manager", 'OnGetDisplayName', '', false, false)]
    local procedure LocalizeStarter(Scenario: Record "BCSF Scenario"; var Name: Text)
    var
        Industry: Integer;
        VariantNo: Integer;
        Id: Guid;
    begin
        Evaluate(Id, '{B55C2100-AB51-4021-9C00-000000000001}');
        if (Scenario."Scenario Id" = Id) and (Scenario.Description in ['Sales – Quotes, Orders and Invoices', 'Verkauf – Angebote, Aufträge und Rechnungen']) then begin
            Name := SalesDocumentsLbl;
            exit;
        end;
        Evaluate(Id, '{B55C2100-AB51-4021-9C00-000000000002}');
        if (Scenario."Scenario Id" = Id) and (Scenario.Description in ['Sales – Mixed Posted Documents', 'Verkauf – Gemischte gebuchte Belege']) then begin
            Name := MixedSalesLbl;
            exit;
        end;
        Evaluate(Id, '{B55C1900-AB51-4019-9C00-000000000001}');
        if (Scenario."Scenario Id" = Id) and (Scenario.Description in ['Technical Wholesale – Item Assortment', 'Technischer Großhandel – Artikelsortiment']) then begin
            Name := TechnicalItemsLbl;
            exit;
        end;
        Evaluate(Id, '{B55C1900-AB51-4019-9C00-000000000002}');
        if (Scenario."Scenario Id" = Id) and (Scenario.Description in ['Technical Wholesale – Item Assortment with Bins', 'Technischer Großhandel – Sortiment mit Lagerplätzen']) then begin
            Name := TechnicalBinsLbl;
            exit;
        end;
        for Industry := 1 to 8 do
            for VariantNo := 1 to 7 do begin
                Id := GetStarterId(Industry, VariantNo);
                if Id = Scenario."Scenario Id" then
                    if IsDefaultName(Scenario.Description, Industry, VariantNo) then begin
                        Name := DefaultName(Industry, VariantNo, 0);
                        if Scenario."Profile Version" = '1' then
                            case VariantNo of
                                5: Name := Name.Replace(DocumentsLbl, LegacyDocumentsLbl);
                                6: Name := Name.Replace(PostedLbl, LegacyPostedLbl);
                            end;
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
        for VariantNo := 1 to 2 do begin
            if VariantNo = 1 then
                Evaluate(Id, '{B55C1900-AB51-4019-9C00-000000000001}')
            else
                Evaluate(Id, '{B55C1900-AB51-4019-9C00-000000000002}');
            if Removed.Get(Id) then
                Removed.Delete(true);
            if Scenario.Get(Id) then
                if Scenario.Archived then begin
                    Scenario.Archived := false;
                    Scenario.Modify(true);
                end;
        end;
        Evaluate(Id, '{B55C2100-AB51-4021-9C00-000000000001}');
        if Removed.Get(Id) then
            Removed.Delete(true);
        if Scenario.Get(Id) then
            if Scenario.Archived then begin
                Scenario.Archived := false;
                Scenario.Modify(true);
            end;
        Evaluate(Id, '{B55C2100-AB51-4021-9C00-000000000002}');
        if Removed.Get(Id) then
            Removed.Delete(true);
        if Scenario.Get(Id) then
            if Scenario.Archived then begin
                Scenario.Archived := false;
                Scenario.Modify(true);
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
        ExistingFoundationErr: Label 'For existing company setup, select the existing item units, posting groups and compatible location under Item Assortment. No test package will be applied.';
        MixedSalesLbl: Label 'Sales – Mixed Posted Documents';
        SalesDocumentsLbl: Label 'Sales – Quotes, Orders and Invoices';
        TechnicalItemsLbl: Label 'Technical Wholesale – Item Assortment';
        TechnicalBinsLbl: Label 'Technical Wholesale – Item Assortment with Bins';
        RestoreQst: Label 'Restore all removed or archived built-in starter templates? Custom names are retained.';
        EnglishIndustriesTok: Label 'General Business,Wholesale and Retail,E-Commerce,Distribution and Logistics,Manufacturing,Services and Consulting,Construction and Projects,Service and Maintenance', Locked = true;
        LegacyEnglishPurposesTok: Label 'Demo Partners,Training Partners,Functional Partner Test,Partner Volume Test,Planning Only: Open Documents,Planning Only: Posted Movements,Planning Only: Follow-Up Processes', Locked = true;
        EnglishPurposesTok: Label 'Demo Partners,Training Partners,Functional Partner Test,Partner Volume Test,Sales: Unposted Documents,Sales: Mixed Posted Documents,Planning Only: Follow-Up Processes', Locked = true;
        GermanIndustriesTok: Label 'Allgemeines Unternehmen,Groß- und Einzelhandel,E-Commerce,Distribution und Logistik,Fertigung,Dienstleistung und Beratung,Bau- und Projektgeschäft,Service und Wartung', Locked = true;
        LegacyGermanPurposesTok: Label 'Demo: Debitoren und Kreditoren,Schulung: Debitoren und Kreditoren,Funktionstest: Debitoren und Kreditoren,Lasttest-Vorlage: Debitoren und Kreditoren,Nur Planung: Offene Belege,Nur Planung: Gebuchte Bewegungen,Nur Planung: Folgeprozesse', Locked = true;
        GermanPurposesTok: Label 'Demo: Debitoren und Kreditoren,Schulung: Debitoren und Kreditoren,Funktionstest: Debitoren und Kreditoren,Lasttest-Vorlage: Debitoren und Kreditoren,Verkauf: Ungebuchte Belege,Verkauf: Gemischte gebuchte Belege,Nur Planung: Folgeprozesse', Locked = true;
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
        LegacyDocumentsLbl: Label 'Planning Only: Open Documents';
        LegacyPostedLbl: Label 'Planning Only: Posted Movements';
        DocumentsLbl: Label 'Sales: Unposted Documents';
        PostedLbl: Label 'Sales: Mixed Posted Documents';
        FollowUpLbl: Label 'Planning Only: Follow-Up Processes';
}
