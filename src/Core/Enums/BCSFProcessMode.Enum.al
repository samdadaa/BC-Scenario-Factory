namespace BCScenarioFactory.Core;

enum 90103 "BCSF Process Mode"
{
  Access = Internal;
  Extensible = false;

  value(0; SetupAndMasterData) { Caption = 'Setup and Master Data'; }
  value(1; UnpostedDocuments) { Caption = 'Unposted Documents'; }
  value(2; PostedMovements) { Caption = 'Posted Movements'; }
  value(3; FollowUpProcesses) { Caption = 'Follow-up Processes'; }
}
