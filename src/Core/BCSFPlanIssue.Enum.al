namespace BCScenarioFactory.Core;

enum 90110 "BCSF Plan Issue"
{
  Access = Internal;
  Extensible = false;
  value(0; None) { Caption = 'No Blocker'; }
  value(1; MissingGenerator) { Caption = 'Generator Missing'; }
  value(2; MissingModule) { Caption = 'Module Disabled or Missing'; }
  value(3; MissingDependency) { Caption = 'Required Dependency Missing'; }
  value(4; UnsupportedMode) { Caption = 'Unsupported Process Mode'; }
  value(5; Cycle) { Caption = 'Cycle or Cyclic Prerequisite'; }
  value(6; ExternalPreflight) { Caption = 'External Check Pending'; }
  value(7; TestOnly) { Caption = 'Contract Probe Only'; }
  value(8; Prerequisite) { Caption = 'Generator Prerequisite Failed'; }
}
