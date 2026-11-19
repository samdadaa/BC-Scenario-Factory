namespace BCScenarioFactory.Core;

using System.Environment;

codeunit 90106 "BCSF Setup Management"
{
    Access = Internal;

    /// <summary>Explicitly creates disabled settings once. Lifecycle database events enforce the environment guard.</summary>
    procedure InitializeSetup()
    var
        FactorySetup: Record "BCSF Factory Setup";
        Environment: Codeunit "Environment Information";
    begin
        FactorySetup.LockTable();
        if FactorySetup.Get(FactorySetup.GetSetupKey()) then
            exit;
        FactorySetup.Init();
        FactorySetup."Primary Key" := FactorySetup.GetSetupKey();
        FactorySetup."Generation Enabled" := false;
        FactorySetup."Posting Enabled" := false;
        FactorySetup."Allowed Environment Name" := CopyStr(Environment.GetEnvironmentName(), 1, MaxStrLen(FactorySetup."Allowed Environment Name"));
        FactorySetup."Allowed Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FactorySetup."Allowed Company Name"));
        FactorySetup.Insert(true);
    end;

    /// <summary>Reads validated settings without initializing or committing data.</summary>
    procedure GetSetup(var FactorySetup: Record "BCSF Factory Setup")
    begin
        FactorySetup.Reset();
        FactorySetup.ChangeCompany(CompanyName());
        if not FactorySetup.Get(FactorySetup.GetSetupKey()) then
            Error(MissingSetupErr);
        FactorySetup.ValidateSettings();
    end;

    procedure EnsureInitialized()
    var
        FactorySetup: Record "BCSF Factory Setup";
    begin
        GetSetup(FactorySetup);
        if not FactorySetup."Company Initialized" then
            Error(MissingSetupErr);
    end;

    var
        MissingSetupErr: Label 'Open Scenario Factory Setup and choose Initialize Company in the approved sandbox and test company.';
}
