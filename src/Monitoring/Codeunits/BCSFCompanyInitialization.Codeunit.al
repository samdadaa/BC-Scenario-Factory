namespace BCScenarioFactory.Monitoring;

using BCScenarioFactory.BackgroundProcessing;
using BCScenarioFactory.Core;
using BCScenarioFactory.Finance;
using BCScenarioFactory.IndustryProfiles;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using System.Threading;

codeunit 90361 "BCSF Company Initialization"
{
  Access = Internal;
  TableNo = "Job Queue Entry";

  trigger OnRun()
  var
    Setup: Record "BCSF Factory Setup";
    Scenario: Record "BCSF Scenario";
    StoredJob: Record "Job Queue Entry";
    Profile: Codeunit "BCSF Wholesale Profile";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    // Standard scheduler owns this job. Validate persisted state, not just the supplied record.
    StoredJob.SecurityFiltering(SecurityFilter::Disallowed);
    StoredJob.Get(Rec.ID);
    StoredJob.TestField(Status, StoredJob.Status::"In Process");
    StoredJob.TestField("Object Type to Run", StoredJob."Object Type to Run"::Codeunit);
    StoredJob.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
    StoredJob.TestField("User Session ID", SessionId());
    StoredJob.TestField("User Service Instance ID", ServiceInstanceId());
    StoredJob.TestField("Maximum No. of Attempts to Run", 0);
    StoredJob.TestField("Recurring Job", false);
    if StoredJob."Record ID to Process" <> Rec."Record ID to Process" then
      Error(JobErr);
    Rec.TestField("Object Type to Run", Rec."Object Type to Run"::Codeunit);
    Rec.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
    Rec.TestField("System Task ID");
    Rec.TestField(Status, Rec.Status::"In Process");
    Rec.TestField("User Session ID", SessionId());
    Rec.TestField("User Service Instance ID", ServiceInstanceId());
    if GuiAllowed() then
      Error(JobErr);
    Scenario.LockTable();
    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    Guard.EnsureCanConfigure(CompanyName());
    Setup.TestField("Industry Job Id", Rec.ID);
    if Rec."Record ID to Process" <> Setup.RecordId() then
      Error(JobErr);
    if not IsNullGuid(Setup."Industry Run Id") then
      exit;
    Profile.CheckSelection(Setup."Industry Size", Setup."Industry Process Mode");
    // Setup, snapshot and first batch job form one atomic transaction. Failure leaves no half company.
    InitializeAndSchedule(Setup);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  local procedure InitializeAndSchedule(var Setup: Record "BCSF Factory Setup")
  var
    Scenario: Record "BCSF Scenario";
    Catalog: Codeunit "BCSF Starter Catalog";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Profile: Codeunit "BCSF Wholesale Profile";
    QuickRun: Codeunit "BCSF Quick Scenario Run";
    ScenarioId: Guid;
  begin
    if Setup."Company Initialized" then begin
      Setup.TestField("Generation Enabled", true);
      if Setup."Industry Finance Mode" <> Packages.GetAppliedMode() then
        Error(ChartErr);
    end else
      Catalog.InitializeFoundation(Setup."Industry Finance Mode");
    ScenarioId := Profile.CreateTemplate(Setup."Industry Size", Setup."Industry Process Mode", Setup."Industry Date");
    Scenario.Get(ScenarioId);
    Setup.Get(Setup.GetSetupKey());
    Setup."Industry Run Id" := QuickRun.RunScenario(Scenario);
    Setup.Modify(true);
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure Start(Mode: Enum "BCSF Finance Mode"; Size: Integer; ProcessMode: Enum "BCSF Process Mode")
  var
    Setup: Record "BCSF Factory Setup";
    Scenario: Record "BCSF Scenario";
    Job: Record "Job Queue Entry";
    SetupMgt: Codeunit "BCSF Setup Management";
    Packages: Codeunit "BCSF Finance Package Mgt";
    Profile: Codeunit "BCSF Wholesale Profile";
    Guard: Codeunit "BCSF Environment Guard";
    Enqueue: Codeunit "Job Queue - Enqueue";
  begin
    // Fixed lock order shared with snapshots, configuration editors and the bootstrap job.
    Scenario.LockTable();
    SetupMgt.InitializeSetup();
    Guard.EnsureCanConfigure(CompanyName());
    Setup.LockTable();
    Setup.Get(Setup.GetSetupKey());
    if not IsNullGuid(Setup."Industry Job Id") or not IsNullGuid(Setup."Industry Run Id") then
      Error(ExistingErr);
    Profile.CheckSelection(Size, ProcessMode);
    if Setup."Company Initialized" then begin
      Setup.TestField("Generation Enabled", true);
      if Mode <> Packages.GetAppliedMode() then
        Error(ChartErr);
    end;
    // Read-only finance preflight before accepting the background request.
    Packages.CheckInitialization(Mode);
    Job.CheckRequiredPermissions();
    if not Job.WritePermission() then
      Error(JobErr);
    Setup."Industry Finance Mode" := Mode;
    Setup."Industry Size" := Size;
    Setup."Industry Process Mode" := ProcessMode;
    Setup."Industry Date" := WorkDate();
    Job.Init();
    Job."Object Type to Run" := Job."Object Type to Run"::Codeunit;
    Job."Object ID to Run" := Codeunit::"BCSF Company Initialization";
    Job."Record ID to Process" := Setup.RecordId();
    Job.Description := JobLbl;
    Job."User Language ID" := GlobalLanguage();
    Job."Maximum No. of Attempts to Run" := 0;
    Job."Recurring Job" := false;
    Job."Earliest Start Date/Time" := CurrentDateTime();
    Enqueue.Run(Job);
    Job.TestField(ID);
    Job.TestField("System Task ID");
    Setup."Industry Job Id" := Job.ID;
    Setup.Modify(true);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeModifyEvent', '', false, false)]
  local procedure ProtectRequest(var Rec: Record "BCSF Factory Setup"; var xRec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
  var
    Previous: Record "BCSF Factory Setup";
    Job: Record "Job Queue Entry";
    Profile: Codeunit "BCSF Wholesale Profile";
  begin
    if Rec.IsTemporary() then
      exit;
    Previous.LockTable();
    Previous.Get(Rec.GetSetupKey());
    if not IsNullGuid(Previous."Industry Job Id") then begin
      Rec.TestField("Industry Job Id", Previous."Industry Job Id");
      Rec.TestField("Industry Finance Mode", Previous."Industry Finance Mode");
      Rec.TestField("Industry Size", Previous."Industry Size");
      Rec.TestField("Industry Process Mode", Previous."Industry Process Mode");
      Rec.TestField("Industry Date", Previous."Industry Date");
      if not IsNullGuid(Previous."Industry Run Id") then
        Rec.TestField("Industry Run Id", Previous."Industry Run Id")
      else
        if not IsNullGuid(Rec."Industry Run Id") then begin
          Job.Get(Previous."Industry Job Id");
          Job.TestField(Status, Job.Status::"In Process");
          Job.TestField("User Session ID", SessionId());
          Job.TestField("User Service Instance ID", ServiceInstanceId());
        end;
    end else
      if not IsNullGuid(Rec."Industry Job Id") then begin
        Rec.TestField("Industry Date");
        Profile.CheckSelection(Rec."Industry Size", Rec."Industry Process Mode");
        Job.Get(Rec."Industry Job Id");
        Job.TestField("Object Type to Run", Job."Object Type to Run"::Codeunit);
        Job.TestField("Object ID to Run", Codeunit::"BCSF Company Initialization");
        Job.TestField("Maximum No. of Attempts to Run", 0);
        Job.TestField("Recurring Job", false);
        if Job."Record ID to Process" <> Rec.RecordId() then
          Error(JobErr);
      end;
  end;

  var
    JobLbl: Label 'Scenario Factory company initialization';
    JobErr: Label 'Company initialization requires an authorized standard background job. Review job queue permissions and its current status.';
    ExistingErr: Label 'A company initialization request already exists. Review its progress or error in the dashboard; do not start a duplicate.';
    ChartErr: Label 'This company already has a chart of accounts. Reuse it; another chart requires a new sandbox company.';
}
