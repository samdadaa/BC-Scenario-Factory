namespace BCScenarioFactory.Lifecycle;

using BCScenarioFactory.Core;
using System.Environment;
using System.Security.AccessControl;
using System.Security.User;

codeunit 90375 "BCSF Environment Guard"
{
  Access = Internal;

  /// <summary>Checks configuration writes without enabling generation or approving posting.</summary>
  procedure EnsureCanConfigure(TargetCompanyName: Text)
  var
    FactorySetup: Record "BCSF Factory Setup";
    SetupManagement: Codeunit "BCSF Setup Management";
  begin
    EnsureSandbox();
    EnsureCurrentCompany(TargetCompanyName);
    EnsureSetupPermissions(FactorySetup);
    SetupManagement.GetSetup(FactorySetup);
    EnsureConfiguredTarget(FactorySetup);
  end;

  /// <summary>Checks the real environment, company, current permissions, setup opt-in, limits and posting approval on every invocation.</summary>
  /// <param name="TargetCompanyName">Pass the actual target record's CurrentCompany, including for background calls.</param>
  procedure EnsureCanGenerate(TargetCompanyName: Text; ProcessMode: Enum "BCSF Process Mode"; RequestedRecords: Integer; RequestedBatchSize: Integer; PostingApproved: Boolean)
  var
    FactorySetup: Record "BCSF Factory Setup";
    SetupManagement: Codeunit "BCSF Setup Management";
  begin
    EnsureSandbox();
    EnsureCurrentCompany(TargetCompanyName);
    EnsureSetupPermissions(FactorySetup);
    SetupManagement.GetSetup(FactorySetup);
    EnsureConfiguredTarget(FactorySetup);
    FactorySetup.TestField("Generation Enabled", true);
    if (RequestedRecords <= 0) or (RequestedRecords > FactorySetup."Maximum Records per Entity") then
      Error(RecordLimitErr);
    if (RequestedBatchSize <= 0) or (RequestedBatchSize > FactorySetup."Maximum Batch Size") or (RequestedBatchSize > RequestedRecords) then
      Error(BatchLimitErr);
    case ProcessMode of
      "BCSF Process Mode"::SetupAndMasterData,
      "BCSF Process Mode"::UnpostedDocuments:
        ;
      "BCSF Process Mode"::PostedMovements,
      "BCSF Process Mode"::FollowUpProcesses:
        begin
          FactorySetup.TestField("Posting Enabled", true);
          if not PostingApproved then
            Error(PostingApprovalErr);
        end;
      else
        Error(UnknownModeErr);
    end;
  end;

  /// <summary>Posting owns its writes. Accept assigned indirect rights without granting direct ledger access.</summary>
  procedure EnsurePostingTableAccess(TableId: Integer; ModifyRequired: Boolean)
  var
    TempPermission: Record "Expanded Permission" temporary;
    UserPermissions: Codeunit "User Permissions";
    Row: RecordRef;
    Caption: Text;
  begin
    Row.Open(TableId);
    Row.SecurityFiltering(SecurityFilter::Disallowed);
    Caption := Row.Caption();
    if not Row.ReadPermission() then
      Error(PostingPermissionErr, Caption);
    TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", TableId);
    if not AllowsStandardPosting(TempPermission, ModifyRequired) then
      Error(PostingPermissionErr, Caption);
    Row.Close();
  end;

  procedure AllowsStandardPosting(TempPermission: Record "Expanded Permission" temporary; ModifyRequired: Boolean): Boolean
  begin
    exit((TempPermission."Insert Permission" in [TempPermission."Insert Permission"::Yes, TempPermission."Insert Permission"::Indirect]) and
      (not ModifyRequired or (TempPermission."Modify Permission" in [TempPermission."Modify Permission"::Yes, TempPermission."Modify Permission"::Indirect])));
  end;

  procedure EnsureCodeunitAccess(CodeunitId: Integer)
  var
    TempPermission: Record "Expanded Permission" temporary;
    UserPermissions: Codeunit "User Permissions";
  begin
    TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Codeunit, CodeunitId);
    if TempPermission."Execute Permission" <> TempPermission."Execute Permission"::Yes then
      Error(PostingExecuteErr, CodeunitId);
  end;

  local procedure EnsureSandbox()
  var
    EnvironmentInformation: Codeunit "Environment Information";
  begin
    if EnvironmentInformation.IsProduction() then
      Error(ProductionErr);
    if not EnvironmentInformation.IsSaaS() or not EnvironmentInformation.IsSandbox() then
      Error(SandboxErr);
  end;

  local procedure EnsureCurrentCompany(TargetCompanyName: Text)
  begin
    if (TargetCompanyName = '') or (TargetCompanyName <> CompanyName()) then
      Error(CompanyErr);
  end;

  local procedure EnsureSetupPermissions(var FactorySetup: Record "BCSF Factory Setup")
  begin
    if not FactorySetup.ReadPermission() then
      Error(PermissionErr);
    if not FactorySetup.WritePermission() then
      Error(PermissionErr);
  end;

  local procedure EnsureConfiguredTarget(var FactorySetup: Record "BCSF Factory Setup")
  var
    EnvironmentInformation: Codeunit "Environment Information";
  begin
    EnsureCurrentCompany(FactorySetup.CurrentCompany());
    if (FactorySetup."Allowed Environment Name" = '') or
        (FactorySetup."Allowed Environment Name" <> EnvironmentInformation.GetEnvironmentName())
    then
      Error(EnvironmentNameErr);
    EnsureCurrentCompany(FactorySetup."Allowed Company Name");
  end;

  local procedure CheckSetupWrite(var FactorySetup: Record "BCSF Factory Setup")
  begin
    if FactorySetup.IsTemporary() then
      exit;
    EnsureSandbox();
    EnsureSetupPermissions(FactorySetup);
    FactorySetup.ValidateSettings();
    EnsureConfiguredTarget(FactorySetup);
  end;

  // Do not condition these checks on RunTrigger or GuiAllowed: direct AL and background writes must also be checked.
  [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeInsertEvent', '', false, false)]
  local procedure CheckSetupInsert(var Rec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
  begin
    CheckSetupWrite(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeModifyEvent', '', false, false)]
  local procedure CheckSetupModify(var Rec: Record "BCSF Factory Setup"; var xRec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
  begin
    CheckSetupWrite(Rec);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeDeleteEvent', '', false, false)]
  local procedure BlockSetupDelete(var Rec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(DeleteErr);
  end;

  [EventSubscriber(ObjectType::Table, Database::"BCSF Factory Setup", 'OnBeforeRenameEvent', '', false, false)]
  local procedure BlockSetupRename(var Rec: Record "BCSF Factory Setup"; var xRec: Record "BCSF Factory Setup"; RunTrigger: Boolean)
  begin
    if not Rec.IsTemporary() then
      Error(RenameErr);
  end;

  var
    PostingPermissionErr: Label 'Standard posting requires read access and assigned direct or indirect insert permission for %1, and modify permission when applying entries. Review standard posting permissions; no direct ledger rights are granted.', Comment = '%1 = table caption';
    PostingExecuteErr: Label 'Execution permission is missing for standard codeunit %1. Review the purchase, sales or journal posting role.', Comment = '%1 = standard codeunit ID';
    ProductionErr: Label 'Scenario Factory cannot write data in a production environment. Use an approved sandbox.';
    SandboxErr: Label 'Scenario Factory requires a confirmed sandbox environment. Unknown and on-premises environments are blocked.';
    CompanyErr: Label 'Use the approved test company in the current session. Cross-company generation and setup writes are blocked.';
    EnvironmentNameErr: Label 'The actual sandbox name does not match the allowed environment. Review Scenario Factory Setup in the approved sandbox.';
    PermissionErr: Label 'Scenario Factory requires effective read and write access to its setup. Ask an administrator to review BCSF ADMIN and the current company permissions.';
    RecordLimitErr: Label 'Request a positive record count within Maximum Records per Entity.';
    BatchLimitErr: Label 'Request a positive batch size within Maximum Batch Size and the requested record count.';
    PostingApprovalErr: Label 'Explicitly approve posting for this invocation before requesting posted movements or follow-up processes.';
    UnknownModeErr: Label 'Select a supported Scenario Factory process mode.';
    DeleteErr: Label 'Scenario Factory Setup cannot be deleted. Disable generation instead.';
    RenameErr: Label 'Scenario Factory Setup cannot be renamed.';
}
