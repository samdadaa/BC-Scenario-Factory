namespace BCScenarioFactory.BackgroundProcessing;

enum 90301 "BCSF Batch Status"
{
  Access = Internal;
  Extensible = false;
  value(0; Pending) { Caption = 'Pending'; }
  value(1; Running) { Caption = 'Running'; }
  value(2; Completed) { Caption = 'Completed'; }
  value(3; NeedsReview) { Caption = 'Needs Review'; }
  value(4; Failed) { Caption = 'Failed'; }
  value(5; Cancelled) { Caption = 'Cancelled'; }
}
