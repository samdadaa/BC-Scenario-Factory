namespace BCScenarioFactory.Monitoring;

controladdin "BCSF Dashboard"
{
  RequestedHeight = 850;
  MinimumHeight = 500;
  MaximumHeight = 1200;
  RequestedWidth = 1200;
  MinimumWidth = 280;
  HorizontalStretch = true;
  HorizontalShrink = true;
  VerticalStretch = true;
  VerticalShrink = true;
  Scripts = 'src/Monitoring/Dashboard/translations.js',
    'src/Monitoring/Dashboard/dashboard.js';
  StyleSheets = 'src/Monitoring/Dashboard/dashboard.css';
  StartupScript = 'src/Monitoring/Dashboard/startup.js';
  RecreateScript = 'src/Monitoring/Dashboard/startup.js';

  event Ready();
  event Command(ActionCode: Text; RunId: Text);
  procedure SetDashboard(Payload: Text);
}
