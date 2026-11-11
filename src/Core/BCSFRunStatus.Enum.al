namespace BCScenarioFactory.Core;

enum 90102 "BCSF Run Status"
{
  Access = Internal;
  Extensible = false;

  value(0; Draft) { Caption = 'Draft'; }
  value(1; Preflight) { Caption = 'Preflight'; }
  value(2; PreflightFailed) { Caption = 'Preflight Failed'; }
  value(3; Ready) { Caption = 'Ready'; }
  value(4; Queued) { Caption = 'Queued'; }
  value(5; Scheduled) { Caption = 'Scheduled'; }
  value(6; Running) { Caption = 'Running'; }
  value(7; Paused) { Caption = 'Paused'; }
  value(8; ResumePending) { Caption = 'Resume Pending'; }
  value(9; Completed) { Caption = 'Completed'; }
  value(10; CompletedWithWarnings) { Caption = 'Completed with Warnings'; }
  value(11; Failed) { Caption = 'Failed'; }
  value(12; Cancelled) { Caption = 'Cancelled'; }
}
