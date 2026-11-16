#!/usr/bin/env node
/** Local Chromium UI checks of the packaged JS/CSS with a synthetic BC message bridge.
 * No Business Central login, AL runtime or third-party packages. Requires Node 22+ and Chrome.
 * Optional CHROME_BIN selects an existing Chromium executable. All profiles/artifacts stay in /tmp.
 */
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { spawn, execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const chromeBin = process.env.CHROME_BIN || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
assert.ok(existsSync(chromeBin), 'Set CHROME_BIN to an installed Chromium executable. No installation is performed.');
const work = await mkdtemp(join(tmpdir(), 'bcsf-dashboard-'));
const source = await readFile(join(root, 'src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al'), 'utf8');
const labels = Object.fromEntries([...source.matchAll(/(\w+Lbl): Label '((?:[^']|'')*)';/gu)].map(match => [match[1], match[2].replaceAll("''", "'")]));
const texts = Object.fromEntries([...source.matchAll(/Texts\.Add\('([^']+)', (\w+Lbl)\)/gu)].map(match => [match[1], labels[match[2]]]));
assert.ok(Object.values(texts).every(Boolean), 'Every dashboard text must be an AL label.');
const firstId = '{10000000-0000-0000-0000-000000000001}';
const secondId = '{20000000-0000-0000-0000-000000000002}';
const selected = { id: firstId, description: 'Wholesale · Demo 2026', profile: 'TRADE / 1', createdAt: '16.11.2026 10:00', processMode: 'Unposted Documents', status: 'Running', hasExecution: true, statusCode: 6, totalBatches: 5, completedBatches: 1, earliest: '16.11.2026 10:00', started: '16.11.2026 10:02', finished: '', pauseRequested: false, cancelRequested: false };
const fixture = { schemaVersion: 1, locale: 'en-US', language: 'en-US', texts, readAt: '16.11.2026 10:05', summary: { templates: 3, runs: 2, active: 1, review: 0 }, runs: [selected, { ...selected, id: secondId, description: 'Training · Returns' }], hasSelection: true, selected, steps: [
  { node: 'CUSTOMER', module: 'SALES', entity: 'CUSTOMER', target: 100, confirmed: 20, remaining: 80, artifacts: 60, percent: 20, state: 'Running; unconfirmed work remains', external: false },
  { node: 'ITEM', module: 'INVENTORY', entity: 'ITEM', target: 120, confirmed: 0, remaining: 120, artifacts: 0, percent: 0, state: 'No saved plan', external: false },
  { node: 'FINANCE.SETUP', module: 'FINANCE', entity: 'FINANCE.SETUP', target: 1, confirmed: 0, remaining: 1, artifacts: 0, percent: 0, state: 'Plan blocked', external: true }
] };
const fixtureText = JSON.stringify(fixture).replaceAll('<', '\\u003c');
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="stylesheet" href="/dashboard.css"></head><body><div id="controlAddIn"></div><script>
window.fixture=${fixtureText}; window.calls=[]; window.hold=false; window.failNext=false;
window.Microsoft={Dynamics:{NAV:{InvokeExtensibilityMethod:function(name,args,skip,success,failure){
  window.calls.push({name,args,skip});
  function finish(){if(window.failNext){window.failNext=false;failure();return;}
    if(name==='Command' && args[0]==='select'){window.fixture.selected=window.fixture.runs.find(r=>r.id===args[1]);}
    window.SetDashboard(JSON.stringify(window.fixture)); success();}
  if(window.hold)window.pending=finish;else setTimeout(finish,0);
}}}};
</script><script src="/dashboard.js"></script><script src="/startup.js"></script></body></html>`;
const server = createServer(async (request, response) => {
  try {
    if (request.url === '/') { response.setHeader('Content-Type', 'text/html; charset=utf-8'); response.end(html); return; }
    const name = request.url.slice(1);
    if (!['dashboard.js', 'startup.js', 'dashboard.css'].includes(name)) { response.writeHead(404); response.end(); return; }
    response.setHeader('Content-Type', name.endsWith('.css') ? 'text/css' : 'text/javascript');
    response.end(await readFile(join(root, 'src/Monitoring/Dashboard', name)));
  } catch { response.writeHead(500); response.end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const chrome = spawn(chromeBin, ['--headless=new', '--remote-debugging-port=0', `--user-data-dir=${join(work, 'profile')}`, '--no-first-run', '--no-default-browser-check', '--disable-background-networking', '--disable-component-update', '--disable-sync', '--disable-extensions', 'about:blank'], { stdio: 'ignore' });
let ws;
const pause = (ms) => new Promise(resolve => setTimeout(resolve, ms));
try {
  let port;
  for (let attempt = 0; attempt < 100; attempt++) {
    try { port = (await readFile(join(work, 'profile/DevToolsActivePort'), 'utf8')).split('\n')[0]; break; } catch { await pause(100); }
  }
  assert.ok(port, 'Chrome debugging endpoint did not start.');
  const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  ws = new WebSocket(tabs.find(tab => tab.type === 'page').webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { ws.addEventListener('open', resolve, { once: true }); ws.addEventListener('error', reject, { once: true }); });
  let id = 0;
  const waiting = new Map();
  ws.addEventListener('message', message => {
    const result = JSON.parse(message.data);
    if (waiting.has(result.id)) { const entry = waiting.get(result.id); waiting.delete(result.id); clearTimeout(entry.timeout); result.error ? entry.reject(new Error(result.error.message)) : entry.resolve(result.result); }
  });
  const cdp = (method, params = {}) => new Promise((resolve, reject) => {
    const callId = ++id;
    const timeout = setTimeout(() => { waiting.delete(callId); reject(new Error(`CDP timeout: ${method}`)); }, 10000);
    waiting.set(callId, { resolve, reject, timeout }); ws.send(JSON.stringify({ id: callId, method, params }));
  });
  const evaluate = async (expression) => {
    const response = await cdp('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (response.exceptionDetails) throw new Error(JSON.stringify(response.exceptionDetails));
    return response.result.value;
  };
  const until = async (expression) => { for (let i = 0; i < 100; i++) { if (await evaluate(expression)) return; await pause(30); } throw new Error(`Condition not met: ${expression}`); };
  await cdp('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1100, deviceScaleFactor: 1, mobile: false });
  await cdp('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/` });
  await until('document.querySelector(".sf-table") && document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  assert.equal(await evaluate('window.calls.filter(c=>c.name==="Ready").length'), 1);
  assert.equal(await evaluate('window.calls.filter(c=>c.name==="Command").length'), 0, 'Opening must never trigger a command.');
  assert.deepEqual(await evaluate('Array.from(document.querySelectorAll(".sf-stat-value")).map(e=>e.textContent)'), ['3', '2', '1', '0']);
  assert.deepEqual(await evaluate('Array.from(document.querySelectorAll("tbody tr:first-child .sf-number")).map(e=>e.textContent)'), ['100', '20', '80', '60']);
  assert.equal(await evaluate('document.querySelector("progress").value'), 20);
  assert.equal(await evaluate('document.querySelectorAll("progress").length'), 2, 'External prerequisites must have no generated progress.');
  assert.equal(await evaluate('document.querySelector(".sf-quality").textContent'), texts.quality);
  const expected = ['new', 'refresh', 'scenarios', 'runs', 'executions', 'allBatches', 'allRecords', 'catalog', 'setup', 'monitor', 'run', 'scenario', 'wizard', 'plan', 'savePlan', 'readiness', 'preflight', 'synthetic', 'prepare', 'schedule', 'pause', 'cancel', 'apply', 'resume', 'progress', 'batches', 'history', 'records', 'queue'];
  const actual = await evaluate('Array.from(document.querySelectorAll("button[data-action]")).map(e=>e.dataset.action)');
  assert.deepEqual(actual.toSorted(), expected.toSorted(), 'Every central navigation and run action must be available.');
  await evaluate('window.hold=true;document.querySelector("[data-action=new]").click();document.querySelector("[data-action=new]").click()');
  assert.equal(await evaluate('window.calls.filter(c=>c.name==="Command"&&c.args[0]==="new").length'), 1, 'Busy controls must suppress duplicate creation.');
  assert.equal(await evaluate('Array.from(document.querySelectorAll("button,select")).every(e=>e.disabled)'), true);
  await evaluate('window.hold=false;window.pending()');
  await evaluate('document.querySelector("[data-action=plan]").click()');
  await until('document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  assert.deepEqual(await evaluate('window.calls.filter(c=>c.name==="Command").at(-1).args'), ['plan', firstId]);
  await evaluate(`document.querySelector('select').value=${JSON.stringify(secondId)};document.querySelector('select').dispatchEvent(new Event('change'))`);
  await until(`document.querySelector('select').value===${JSON.stringify(secondId)} && document.querySelector('#controlAddIn').getAttribute('aria-busy')==='false'`);
  await evaluate('document.querySelector("[data-action=cancel]").click()');
  await until('document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  assert.deepEqual(await evaluate('window.calls.filter(c=>c.name==="Command").at(-1).args'), ['cancel', secondId]);
  await evaluate('window.failNext=true;document.querySelector("[data-action=refresh]").click()');
  await until('document.querySelector(".sf-feedback").textContent===window.fixture.texts.error');
  assert.equal(await evaluate('document.querySelector("[data-action=refresh]").disabled'), false, 'Errors must allow recovery.');
  await evaluate('document.querySelector("[data-action=refresh]").click()');
  await until('document.querySelector(".sf-feedback").textContent===""');
  await evaluate('window.fixture.selected.description="<img src=x onerror=window.injected=true>";window.SetDashboard(JSON.stringify(window.fixture))');
  assert.equal(await evaluate('document.querySelectorAll("img").length'), 0, 'Untrusted descriptions must be rendered as text.');
  assert.equal(await evaluate('Boolean(window.injected)'), false);
  assert.equal(await evaluate('document.querySelector("h2").textContent'), '<img src=x onerror=window.injected=true>');
  await evaluate('window.fixture.selected.description="Training · Returns";window.SetDashboard(JSON.stringify(window.fixture))');
  assert.equal(await evaluate('Array.from(document.querySelectorAll("button")).every(e=>e.type==="button" && e.textContent.trim().length>0)'), true);
  assert.equal(await evaluate('document.querySelectorAll(".sf-feedback[aria-live=polite]").length'), 1);
  await evaluate('window.SetDashboard(JSON.stringify({schemaVersion:99}))');
  assert.equal(await evaluate('document.querySelector(".sf-feedback").textContent'), texts.error, 'Invalid payloads must retain the prior view and show an error.');
  const germanBySource = JSON.parse(execFileSync('python3', ['-c', 'import json,xml.etree.ElementTree as E; n={"x":"urn:oasis:names:tc:xliff:document:1.2"};t=E.parse("Translations/BC Scenario Factory.de-DE.xlf"); print(json.dumps({u.find("x:source",n).text:u.find("x:target",n).text for u in t.findall(".//x:trans-unit",n)}))'], { cwd: root, encoding: 'utf8' }));
  const germanTexts = Object.fromEntries(Object.entries(texts).map(([key, value]) => [key, germanBySource[value]]));
  assert.ok(Object.values(germanTexts).every(Boolean), 'Every UI text must have an actual German XLIFF target.');
  await evaluate(`window.fixture.texts=${JSON.stringify(germanTexts)};window.fixture.locale='de-DE';window.fixture.language='de-DE';window.fixture.summary.templates=1000;window.SetDashboard(JSON.stringify(window.fixture))`);
  assert.equal(await evaluate('document.querySelector(".sf-stat-value").textContent'), '1.000', 'Number formatting must follow the supplied BC locale.');
  assert.equal(await evaluate('document.documentElement.lang'), 'de-DE');
  assert.equal(await evaluate('document.querySelector("[data-action=scenarios]").textContent.includes("Szenariovorlagen")'), true);
  for (const width of [1440, 768, 320]) {
    await cdp('Emulation.setDeviceMetricsOverride', { width, height: 1100, deviceScaleFactor: 1, mobile: false });
    assert.equal(await evaluate('document.documentElement.scrollWidth<=window.innerWidth'), true, `No page overflow at ${width}px.`);
  }
  await cdp('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1200, deviceScaleFactor: 1, mobile: false });
  const shot = await cdp('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  await writeFile(join(tmpdir(), 'BCSF-dashboard-preview.png'), Buffer.from(shot.data, 'base64'));
  await evaluate('window.fixture.hasSelection=false;window.fixture.runs=[];window.SetDashboard(JSON.stringify(window.fixture))');
  assert.equal(await evaluate('document.querySelectorAll(".sf-action-groups").length'), 0);
  assert.equal(await evaluate('document.querySelector(".sf-empty").textContent.includes(window.fixture.texts.empty)'), true);
  assert.equal(await evaluate('document.querySelectorAll(".sf-nav-link").length'), 8, 'Empty state must retain complete navigation.');
  console.log('PASS: real Chromium rendering, ready handshake, 29 entry points, run routing, confirmed/remaining/artifact separation, duplicate suppression, error recovery, invalid payload recovery, XSS text rendering, real German XLIFF labels/number formatting, empty state and 1440/768/320px layouts.');
  console.log(`Synthetic local preview: ${join(tmpdir(), 'BCSF-dashboard-preview.png')}. AL/BC iframe, security, dialogs and profile selection were not executed.`);
} finally {
  if (ws) ws.close();
  chrome.kill('SIGTERM');
  await new Promise(resolve => server.close(resolve));
  await pause(300);
  await rm(work, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
