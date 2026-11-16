namespace BCScenarioFactory.IndustryProfiles;

using BCScenarioFactory.ScenarioManagement;

codeunit 90154 "BCSF Synthetic Rules"
{
  Access = Internal;

  // Generic synthetic defaults, not a claim that the selected industry profile exists.
  [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCSF Snapshot Writer", 'OnBuildSyntheticRules', '', false, false)]
  local procedure CaptureRules(var Rules: JsonObject)
  begin
    Rules.Add('version', 1);
    Rules.Add('smallPercent', 70);
    Rules.Add('mediumPercent', 25);
    Rules.Add('smallMinimumCents', 100);
    Rules.Add('smallMaximumCents', 9900);
    Rules.Add('mediumMinimumCents', 10000);
    Rules.Add('mediumMaximumCents', 99900);
    Rules.Add('largeMinimumCents', 100000);
    Rules.Add('largeMaximumCents', 999900);
  end;
}
