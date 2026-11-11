namespace BCScenarioFactory.Core;

codeunit 90107 "BCSF Run State Mgt"
{
  Access = Internal;

  /// <summary>Assigns an ID only when empty. The caller must persist it once and reuse it on retry.</summary>
  procedure EnsureRunId(var RunId: Guid)
  begin
    if IsNullGuid(RunId) then
      RunId := CreateGuid();
  end;

  /// <summary>Assigns an ID only when empty. This does not create or claim a batch.</summary>
  procedure EnsureBatchId(var BatchId: Guid)
  begin
    if IsNullGuid(BatchId) then
      BatchId := CreateGuid();
  end;

  /// <summary>Checks only the state graph. Authorization, preflight and persisted transitions remain the caller's responsibility.</summary>
  procedure CheckTransition(CurrentStatus: Enum "BCSF Run Status"; NewStatus: Enum "BCSF Run Status")
  begin
    if not CanTransition(CurrentStatus, NewStatus) then
      Error(InvalidTransitionErr, CurrentStatus, NewStatus);
  end;

  procedure CanTransition(CurrentStatus: Enum "BCSF Run Status"; NewStatus: Enum "BCSF Run Status"): Boolean
  begin
    case CurrentStatus of
      "BCSF Run Status"::Draft:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Preflight, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Preflight:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Ready, "BCSF Run Status"::PreflightFailed, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::PreflightFailed:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Draft, "BCSF Run Status"::Preflight, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Ready:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Preflight, "BCSF Run Status"::Queued, "BCSF Run Status"::Scheduled, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Queued,
      "BCSF Run Status"::Scheduled:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Running, "BCSF Run Status"::Paused, "BCSF Run Status"::Failed, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Running:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Paused, "BCSF Run Status"::Completed, "BCSF Run Status"::CompletedWithWarnings, "BCSF Run Status"::Failed, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Paused,
      "BCSF Run Status"::Failed:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::ResumePending, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::ResumePending:
        exit(NewStatus in [CurrentStatus, "BCSF Run Status"::Preflight, "BCSF Run Status"::Failed, "BCSF Run Status"::Cancelled]);
      "BCSF Run Status"::Completed,
      "BCSF Run Status"::CompletedWithWarnings,
      "BCSF Run Status"::Cancelled:
        exit(NewStatus = CurrentStatus);
    end;
    exit(false);
  end;

  var
    InvalidTransitionErr: Label 'The run status cannot change from %1 to %2. Follow the documented run lifecycle.', Comment = '%1 = current status, %2 = requested status';
}
