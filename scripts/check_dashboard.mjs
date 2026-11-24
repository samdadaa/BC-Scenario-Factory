#!/usr/bin/env node
/** Local Chromium UI checks of the packaged JS/CSS with a synthetic BC message bridge.
 * No Business Central login, AL runtime or third-party packages. Requires Node 22+ and Chrome.
 * Optional CHROME_BIN selects an existing Chromium executable. All profiles/artifacts stay in /tmp.
 */
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { existsSync, readFileSync } from 'node:fs';
import { spawn, execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const chromeBin = process.env.CHROME_BIN || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
assert.ok(existsSync(chromeBin), 'Set CHROME_BIN to an installed Chromium executable. No installation is performed.');
execFileSync('python3', ['scripts/build_dashboard_translations.py', '--check'], { cwd: root });
const work = await mkdtemp(join(tmpdir(), 'bcsf-dashboard-'));
const source = await readFile(join(root, 'src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al'), 'utf8');
const labels = Object.fromEntries([...source.matchAll(/(\w+Lbl): Label '((?:[^']|'')*)';/gu)].map(match => [match[1], match[2].replaceAll("''", "'")]));
const textKeys = [...source.matchAll(/Texts\.Add\('([^']+)'/gu)].map(match => match[1]);
assert.equal(new Set(textKeys).size, textKeys.length, 'Dashboard AL payload keys must be unique; duplicate JsonObject.Add would fail in BC.');
const texts = Object.fromEntries([...source.matchAll(/Texts\.Add\('([^']+)', (\w+Lbl)\)/gu)].map(match => [match[1], labels[match[2]]]));
assert.ok(Object.values(texts).every(Boolean), 'Every dashboard text must be an AL label.');
const firstId = '{10000000-0000-0000-0000-000000000001}';
const secondId = '{20000000-0000-0000-0000-000000000002}';
const selected = { id: firstId, description: 'Wholesale · Demo 2026', profile: 'TRADE / 1', createdAt: '16.11.2026 10:00', processMode: 'Unposted Documents', status: 'Running', hasExecution: true, statusCode: 6, qualityCode: 0, quality: 'Passed', totalBatches: 5, completedBatches: 1, earliest: '16.11.2026 10:00', started: '16.11.2026 10:02', finished: '', pauseRequested: false, cancelRequested: false };
const fixture = { schemaVersion: 1, locale: 'en-US', language: 'en-US', initialized: true, texts, readAt: '16.11.2026 10:05', summary: { templates: 3, runs: 2, active: 1, review: 0 }, runs: [selected, { ...selected, id: secondId, description: 'Training · Returns' }], hasSelection: true, selected, steps: [
  { node: 'CUSTOMER', entityCode: 'CUSTOMER', module: 'Sales', entity: 'Customers', target: 100, confirmed: 20, remaining: 80, artifacts: 60, percent: 20, state: 'Running; unconfirmed work remains', external: false },
  { node: 'ITEM', entityCode: 'ITEM', module: 'Inventory', entity: 'Items', target: 120, confirmed: 0, remaining: 120, artifacts: 0, percent: 0, state: 'No saved plan', external: false },
  { node: 'FINANCE.SETUP', module: 'FINANCE', entity: 'FINANCE.SETUP', target: 1, confirmed: 0, remaining: 1, artifacts: 0, percent: 0, state: 'Plan blocked', external: true }
] };
fixture.summaryViews = Object.fromEntries(['templates', 'runs', 'active', 'review'].map(key => [key, { canOpen: fixture.summary[key] > 0 }]));
fixture.stock = { group: 'master', entireCompany: true, runId: '', groups: [
  { key: 'master', caption: 'Master data' }, { key: 'sales', caption: 'Sales' },
  { key: 'purchase', caption: 'Purchasing' }, { key: 'entries', caption: 'Ledger entries' },
  { key: 'finance', caption: 'Finance and banking' }
], metrics: [
  { key: 'customer', caption: 'Customers', count: 25, canOpen: true },
  { key: 'vendor', caption: 'Vendors', count: 0, canOpen: false },
  { key: 'item', caption: 'Items', count: 7, canOpen: true },
  { key: 'bank', caption: 'Bankkonten', status: 'No access', canOpen: false }
] };
fixture.runStock = { metrics: [
  { key: 'customer', caption: 'Customers', count: 20, canOpen: true },
  { key: 'shipTo', caption: 'Lieferadressen', count: 8, canOpen: true }
] };
const fixtureText = JSON.stringify(fixture).replaceAll('<', '\\u003c');
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="stylesheet" href="/dashboard.css"></head><body><div id="controlAddIn"></div><script>
window.fixture=${fixtureText}; window.calls=[]; window.hold=false; window.failNext=false;
window.Microsoft={Dynamics:{NAV:{InvokeExtensibilityMethod:function(name,args,skip,success,failure){
  window.calls.push({name,args,skip});
  function finish(){if(window.failNext){window.failNext=false;failure();return;}
    if(name==='Command' && args[0]==='select'){window.fixture.selected=window.fixture.runs.find(r=>r.id===args[1]);}
    if(name==='Command' && args[0]==='stockScope'){window.fixture.stock.entireCompany=args[1]==='company';}
    if(name==='Command' && args[0]==='stockRun'){window.fixture.stock.runId=args[1];}
    if(name==='Command' && args[0]==='stockGroup'){window.fixture.stock.group=args[1];}
    window.SetDashboard(JSON.stringify(window.fixture)); success();}
  if(window.hold)window.pending=finish;else setTimeout(finish,0);
}}}};
</script><script src="/translations.js"></script><script src="/dashboard.js"></script><script src="/startup.js"></script></body></html>`;
const server = createServer(async (request, response) => {
  try {
    if (request.url === '/') { response.setHeader('Content-Type', 'text/html; charset=utf-8'); response.end(html); return; }
    const name = request.url.slice(1);
    if (!['translations.js', 'dashboard.js', 'startup.js', 'dashboard.css'].includes(name)) { response.writeHead(404); response.end(); return; }
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
  await until('document.querySelector(".sf-stock-list") && document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  const idle = () => until('document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  const click = async selector => { await evaluate(`document.querySelector(${JSON.stringify(selector)}).click()`); await idle(); };
  const redraw = async code => evaluate(code + ';window.SetDashboard(JSON.stringify(window.fixture))');
  assert.equal(await evaluate('window.calls.length'), 1, 'Opening never triggers a command.');
  assert.equal(await evaluate('document.querySelectorAll("h1,.sf-hero,.sf-nav,table,progress").length'), 0);
  assert.equal(await evaluate('document.querySelector(".sf-run")'), null, 'Data and run details are separate.');
  assert.equal(await evaluate('document.querySelector(".sf-scope").textContent'), texts.stockCompany);
  assert.equal(await evaluate(`document.querySelector('[data-stock-focus="metric:customer"] .sf-stock-number').textContent`), '25');
  await click('[data-stock-focus="metric:customer"]');
  assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['stockOpen', 'customer']);
  assert.equal(await evaluate('document.querySelectorAll("[data-action=scenarios]").length'), 1);
  await click('#sf-tab-runs');
  assert.equal(await evaluate('document.querySelector(".sf-stock")'), null);
  assert.equal(await evaluate('document.querySelector(".sf-diagnostics").open'), false);
  assert.equal(await evaluate('document.querySelectorAll("[data-action=scenarios]").length'), 0, 'Template tile is the single template entry.');
  assert.equal(await evaluate('document.querySelectorAll(".sf-stat button").length'), 0, 'Tiles never contain nested buttons.');
  assert.equal(await evaluate('document.querySelector(".sf-step-value").textContent'), '20 / 100');
  assert.equal(await evaluate('document.querySelector(".sf-quality").classList.contains("sf-success")'), true);
  await redraw('window.fixture.selected.masterPool="Eligible 1/2 customers, 0/0 vendors, 40/45 items";window.fixture.selected.postingSkips="2 documents unposted: STOCK"');
  assert.ok((await evaluate('document.querySelector(".sf-run").textContent')).includes('40/45 items'));
  assert.ok((await evaluate('document.querySelector(".sf-run").textContent')).includes('2 documents unposted: STOCK'));
  await redraw('window.fixture.selected.masterPool="<img src=x onerror=window.poolInjected=true>"');
  assert.equal(await evaluate('document.querySelectorAll(".sf-run img").length'), 0);
  assert.equal(await evaluate('Boolean(window.poolInjected)'), false);
  await redraw('delete window.fixture.selected.masterPool;delete window.fixture.selected.postingSkips');
  await redraw('window.fixture.steps[0].skipped=1;window.fixture.steps[0].reviewUnits=2;window.fixture.steps[0].remaining=79');
  assert.ok((await evaluate('document.querySelector(".sf-step").textContent')).includes(texts.skippedUnits));
  assert.ok((await evaluate('document.querySelector(".sf-step").textContent')).includes(texts.reviewUnits));
  assert.equal(await evaluate('document.querySelector(".sf-step-value").textContent'), '20 / 100', 'Skipped and uncertain units must not increase created work.');
  await redraw('delete window.fixture.steps[0].skipped;delete window.fixture.steps[0].reviewUnits;window.fixture.steps[0].remaining=80');

  assert.ok(!(await evaluate('document.querySelector(".sf-run").textContent')).includes('2 documents unposted: STOCK'));

  assert.equal(await evaluate('document.querySelectorAll(".sf-step").length'), 2, 'External checks stay in diagnostics.');
  await click('[data-stock-focus="result:customer"]');
  assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['runOpen', 'customer']);
  await click('[data-stock-focus="result:shipTo"]');
  assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['runOpen', 'shipTo']);
  for (const key of ['templates', 'runs', 'active']) {
    await click('[data-action="summary:' + key + '"]');
    assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['summary', key]);
  }
  assert.equal(await evaluate('document.querySelector(".sf-stat-review").tagName'), 'DIV', 'Zero has no unsupported action.');
  await redraw('window.fixture.summaryViews.review.canOpen=true');
  assert.equal(await evaluate('document.querySelector(".sf-stat-review").tagName'), 'DIV');
  await evaluate(`document.querySelector('#sf-run-select').value=${JSON.stringify(secondId)};document.querySelector('#sf-run-select').dispatchEvent(new Event('change'))`);
  await idle();
  assert.equal(await evaluate('window.fixture.stock.entireCompany'), true, 'Run selection never changes data scope.');
  assert.equal(await evaluate('window.fixture.stock.runId'), '');
  await click('#sf-tab-data');
  assert.equal(await evaluate('document.querySelector(".sf-scope").textContent'), texts.stockCompany);
  await redraw(`window.fixture.stock.entireCompany=false;window.fixture.stock.runId=${JSON.stringify(firstId)};window.fixture.stock.metrics.push({key:'planned',caption:'Planned entity',noGenerator:true,status:'No executable generator'})`);
  assert.ok((await evaluate('document.querySelector(".sf-scope").textContent')).includes(texts.selectedRunScope));
  assert.equal(await evaluate('document.querySelector(".sf-stock-unavailable").open'), false);
  assert.equal(await evaluate('document.querySelector(".sf-stock-unavailable .sf-stock-status").textContent'), 'No executable generator');
  assert.equal(await evaluate('document.querySelector(".sf-stock-list .sf-stock-status").textContent'), 'No access');
  await evaluate('document.querySelector(".sf-stock-unavailable").open=true');
  await click('[data-action=refresh]');
  assert.equal(await evaluate('document.querySelector(".sf-stock-unavailable").open'), true);
  // Native tab semantics and arrow navigation; tab switching makes no server call.
  const callsBefore = await evaluate('window.calls.length');
  await evaluate('document.querySelector("#sf-tab-data").focus()');
  await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowRight', code: 'ArrowRight', windowsVirtualKeyCode: 39 });
  await cdp('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowRight', code: 'ArrowRight', windowsVirtualKeyCode: 39 });
  assert.equal(await evaluate('document.activeElement.id'), 'sf-tab-runs');
  assert.equal(await evaluate('document.querySelector("#sf-tab-runs").getAttribute("aria-selected")'), 'true');
  assert.equal(await evaluate('window.calls.length'), callsBefore);
  // Stale/deleted business results must not turn confirmed work into a false list count.
  await redraw('window.fixture.runStock.metrics[0].count=19');
  assert.equal(await evaluate('document.querySelector(".sf-step").tagName'), 'BUTTON');
  assert.ok((await evaluate('document.querySelector(".sf-step").textContent')).includes('19'));
  await click('.sf-step');
  assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['runOpen', 'customer']);
  await redraw('window.fixture.runStock.metrics[0].count=0');
  assert.equal(await evaluate('document.querySelector(".sf-step").tagName'), 'DIV');
  assert.equal(await evaluate('document.querySelectorAll(".sf-step[data-stock-focus]").length'), 0);
  await redraw('window.fixture.runStock.metrics[0].count=20;window.fixture.selected.description="<img src=x onerror=window.injected=true>"');
  assert.equal(await evaluate('document.querySelectorAll("img").length'), 0);
  assert.equal(await evaluate('Boolean(window.injected)'), false);
  assert.equal(await evaluate('document.querySelector("h2").textContent'), '<img src=x onerror=window.injected=true>');
  await redraw('window.fixture.selected.description="Training · Returns"');
  await evaluate('window.hold=true;document.querySelector("[data-action=refresh]").click();document.querySelector("[data-action=refresh]").click()');
  assert.equal(await evaluate('Array.from(document.querySelectorAll("button,select")).every(e=>e.disabled)'), true);
  const held = await evaluate('window.calls.length');
  await evaluate('document.querySelector("#sf-tab-data").click()');
  assert.equal(await evaluate('window.calls.length'), held);
  await evaluate('window.hold=false;window.pending()');
  await idle();
  await evaluate('window.failNext=true;document.querySelector("[data-action=refresh]").click()');
  await until('document.querySelector(".sf-feedback").textContent===window.fixture.texts.error');
  await click('[data-action=refresh]');
  assert.equal(await evaluate('document.querySelector(".sf-feedback").textContent'), '');
  await evaluate('window.SetDashboard(JSON.stringify({schemaVersion:99}))');
  assert.equal(await evaluate('document.querySelector(".sf-feedback").textContent'), texts.error);
  for (const [status, expectedText] of [[3, texts.primaryStart], [6, texts.primaryProgress], [9, texts.primaryResults], [11, texts.primaryErrors], [13, texts.primaryErrors]]) {
    await redraw(`window.fixture.selected.statusCode=${status};window.fixture.selected.canStart=true`);
    assert.equal(await evaluate('document.querySelector("[data-action=primary]").textContent'), expectedText);
    assert.equal(await evaluate('document.querySelector(".sf-status").classList.contains("sf-error")'), [11, 13].includes(status));
    assert.equal(await evaluate('document.querySelector(".sf-run > .sf-scope")!==null'), false, 'Earliest start is not shown outside queued/scheduled runs.');
    await click('[data-action=primary]');
    assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['primary', secondId]);
  }
  await redraw('window.fixture.selected.statusCode=5');
  assert.equal(await evaluate('document.querySelector(".sf-run > .sf-scope")!==null'), true);
  // Run / data tab state, real German XLIFF and five fallback cultures.
  for (const language of ['de-DE', 'de-AT', 'de-CH', 'de-LI', 'de-LU']) {
    await redraw(`window.fixture.language=${JSON.stringify(language)};window.fixture.locale='de-DE'`);
    assert.equal(await evaluate('document.querySelector("#sf-tab-data").textContent'), 'Daten');
    assert.equal(await evaluate('document.querySelector("#sf-tab-runs").textContent'), 'Läufe');
    assert.equal(await evaluate('document.querySelector(".sf-stat-label").textContent'), 'Vorlagen');
    assert.equal(await evaluate('document.querySelector(".sf-step .sf-stock-label").textContent'), 'Debitoren');
    assert.equal(await evaluate('document.querySelector(".sf-quality").textContent'), 'Bestanden');
  }
  await redraw('window.fixture.language="en-US";window.fixture.locale="de-DE";window.fixture.summary.templates=1000');
  assert.equal(await evaluate('document.querySelector(".sf-stat-label").textContent'), 'Templates');
  assert.equal(await evaluate('document.querySelector(".sf-stat-value").textContent'), '1.000');
  const germanBySource = JSON.parse(execFileSync('python3', ['-c', 'import json,xml.etree.ElementTree as E; n={"x":"urn:oasis:names:tc:xliff:document:1.2"};t=E.parse("Translations/BC Scenario Factory.de-DE.xlf"); print(json.dumps({u.find("x:source",n).text:u.find("x:target",n).text for u in t.findall(".//x:trans-unit",n)}))'], { cwd: root, encoding: 'utf8' }));
  // New labels have no compiler-generated XLIFF id before the first build; the reviewed language maps cover them.
  for (const name of ['sf041', 'sf044', 'sf052', 'sf053', 'sf054', 'sf055']) {
    const reviewed = JSON.parse(readFileSync(join(root, 'Translations', name + '.de.json'), 'utf8'));
    for (const [source, target] of Object.entries(reviewed)) germanBySource[source] ??= target;
  }
  const germanTexts = Object.fromEntries(Object.entries(texts).map(([key, value]) => [key, germanBySource[value]]));
  assert.ok(Object.values(germanTexts).every(Boolean), 'All labels have German XLIFF targets.');
  await redraw(`window.fixture.texts=${JSON.stringify(germanTexts)};window.fixture.language='de-DE'`);
  for (const tab of ['data', 'runs']) {
    await click('#sf-tab-' + tab);
    for (const width of [1440, 768, 320]) {
      await cdp('Emulation.setDeviceMetricsOverride', { width, height: 500, deviceScaleFactor: 1, mobile: false });
      assert.equal(await evaluate('document.querySelector("#controlAddIn").scrollWidth<=document.querySelector("#controlAddIn").clientWidth'), true, `No horizontal overflow: ${tab} at ${width}px.`);
      assert.equal(await evaluate('document.querySelector("#controlAddIn").clientHeight<=500'), true);
      if (width === 1440 && tab === 'data') assert.ok(await evaluate('getComputedStyle(document.querySelector(".sf-tile-grid")).gridTemplateColumns.split(" ").length') > 1);
      if (tab === 'runs') await evaluate('document.querySelector(".sf-diagnostics").open=true');
      await evaluate('document.querySelector("#controlAddIn").scrollTop=100000');
      assert.equal(await evaluate('document.querySelector(".sf-footer").getBoundingClientRect().bottom<=501'), true);
      const scroll = await evaluate('document.querySelector("#controlAddIn").scrollTop');
      await redraw('');
      assert.equal(await evaluate('document.querySelector("#controlAddIn").scrollTop'), scroll);
    }
  }
  await cdp('Emulation.setDeviceMetricsOverride', { width: 1440, height: 800, deviceScaleFactor: 1, mobile: false });
  await evaluate('document.querySelector(".sf-diagnostics").open=false;document.querySelector("#controlAddIn").scrollTop=0');
  const primaryWidth = await evaluate('document.querySelector("[data-action=primary]").getBoundingClientRect().width');
  assert.ok(primaryWidth < 400, 'Primary result action is compact.');
  await redraw('window.fixture.selected.statusCode=9;window.fixture.selected.status="Completed";window.fixture.steps[0].target=20;window.fixture.steps[0].remaining=0;window.fixture.steps[0].complete=true;window.fixture.steps=window.fixture.steps.slice(0,1)');
  assert.equal(await evaluate('document.querySelector(".sf-step-state").textContent'), germanTexts.completed);
  const shot = await cdp('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  await writeFile(join(tmpdir(), 'BCSF-dashboard-SF044-runs.png'), Buffer.from(shot.data, 'base64'));
  await click('#sf-tab-data');
  await evaluate('document.querySelector("#controlAddIn").scrollTop=0');
  await redraw('window.fixture.stock.entireCompany=true;window.fixture.stock.runId="";window.fixture.stock.metrics=window.fixture.stock.metrics.filter(metric=>!metric.noGenerator)');
  const dataShot = await cdp('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  await writeFile(join(tmpdir(), 'BCSF-dashboard-SF044-data.png'), Buffer.from(dataShot.data, 'base64'));
  await click('#sf-tab-runs');
  await redraw('window.fixture.steps=[{node:"ITEM",entityCode:"ITEM",entity:"Items",target:8,confirmed:8,remaining:0,complete:true,external:false,state:"Completed"}];window.fixture.runStock={metrics:[{key:"item",caption:"Items",count:8,canOpen:true}]}');
  await click('[data-stock-focus="result:item"]');
  assert.equal(await evaluate('window.calls.at(-1).args[0]'), 'runOpen');
  assert.equal(await evaluate('window.calls.at(-1).args[1]'), 'item');
  for (const [entity, metricKey] of [['SALES.QUOTE', 'sales/quote'], ['SALES.ORDER', 'sales/order'], ['SALES.INVOICE', 'sales/invoice']]) {
    await redraw(`window.fixture.steps=[{node:${JSON.stringify(entity)},entityCode:${JSON.stringify(entity)},entity:"Sales",target:2,confirmed:2,remaining:0,complete:true,external:false,state:"Completed"}];window.fixture.runStock={metrics:[{key:${JSON.stringify(metricKey)},caption:"Sales",count:2,canOpen:true}]}`);
    await click(`[data-stock-focus="result:${metricKey}"]`);
    assert.equal(await evaluate('window.calls.at(-1).args[0]'), 'runOpen');
    assert.equal(await evaluate('window.calls.at(-1).args[1]'), metricKey);
  }
  await redraw('window.fixture.runStock={metrics:[{key:"sales/postedInvoice",caption:"Posted invoices",count:5,canOpen:true},{key:"entries/customerEntry",caption:"Customer entries",count:5,canOpen:true}]}');
  for (const metricKey of ['sales/postedInvoice', 'entries/customerEntry']) {
    await click(`[data-stock-focus="result:${metricKey}"]`);
    assert.equal(await evaluate('window.calls.at(-1).args[1]'), metricKey);
  }
  // Medium dataset regression: counts above the old 150-ID limit stay usable.
  await redraw('window.fixture.steps=[{entityCode:"CUSTOMER",entity:"Customers",target:200,confirmed:200,remaining:0,complete:true,external:false},{entityCode:"ITEM",entity:"Items",target:400,confirmed:400,remaining:0,complete:true,external:false}];window.fixture.runStock={metrics:[{key:"customer",caption:"Customers",count:200,canOpen:true},{key:"item",caption:"Items",count:400,canOpen:true},{key:"itemUnit",caption:"Item units",count:800,canOpen:true},{key:"attributeMapping",caption:"Assignments",count:1154,canOpen:true},{key:"purchase/order",caption:"Purchase orders",count:60,canOpen:true},{key:"purchase/postedInvoice",caption:"Posted purchase invoices",count:120,canOpen:true},{key:"entries/vendorPayment",caption:"Vendor payments",count:0,canOpen:false}]}');
  assert.equal(await evaluate('document.querySelectorAll(".sf-step").length'), 2);
  for (const key of ['customer','item','itemUnit','attributeMapping','purchase/order','purchase/postedInvoice']) {
    await click(`[data-stock-focus="result:${key}"]`);
    assert.deepEqual(await evaluate('window.calls.at(-1).args'), ['runOpen',key]);
  }
  assert.equal(await evaluate(`document.querySelector('[data-render-key="runOpen:entries/vendorPayment"] .sf-stock-number').textContent`), '0', 'Expected zero payments must remain visible.');
  await redraw('window.fixture.hasSelection=false;window.fixture.runs=[]');
  assert.equal(await evaluate('document.querySelectorAll(".sf-action-groups").length'), 0);
  assert.equal(await evaluate('document.querySelector(".sf-empty").textContent'), germanTexts.empty);
  // SF-045: the company path has one summary, hides technical templates and uses real confirmed steps.
  await click('#sf-tab-data');
  await redraw(`window.fixture.hasSelection=true;window.fixture.selected.id=${JSON.stringify(secondId)};window.fixture.company={name:"Wholesale Sandbox",industry:"Wholesale",chart:"SKR04",status:"Company initialized",processMode:"Posted documents without payments",phase:"Company foundation",error:"",runId:${JSON.stringify(secondId)}}`);
  assert.equal(await evaluate('document.querySelector(".sf-experts").open'), false);
  assert.equal(await evaluate('document.querySelector(".sf-toolbar [data-action=scenarios]")'), null);
  assert.equal(await evaluate('document.querySelectorAll(".sf-company").length'), 1);
  assert.equal(await evaluate('document.querySelector(".sf-company").textContent.includes("Großhandel")'), true);
  await redraw('window.fixture.company.period="Fachlicher Zeitraum: 01.01.2026 bis 20.11.2026 (einschließlich)."');
  assert.ok(await evaluate('document.querySelector(".sf-company").textContent.includes("01.01.2026 bis 20.11.2026")'));
  await redraw('window.fixture.company.period="<img src=x onerror=alert(1)>"');
  assert.equal(await evaluate('document.querySelector(".sf-company img")'), null);
  await redraw('window.fixture.company.period=""');

  assert.ok(await evaluate('document.querySelectorAll(".sf-step").length') > 0);
  assert.ok(await evaluate('document.querySelector(".sf-company").textContent.includes("Gebuchte Belege ohne Zahlungen")'));
  await redraw('window.fixture.company.modules="Branchenmodule: Verkauf, Einkauf, Artikel, Finanzen. Zusätzliche Module (nur Planung, keine Datenerzeugung): Lager, CRM."');
  assert.ok(await evaluate('document.querySelector(".sf-company").textContent.includes("nur Planung, keine Datenerzeugung")'));
  assert.ok(await evaluate('document.querySelector(".sf-company").textContent.includes("Lager, CRM")'));
  await redraw('window.fixture.company.modules="<img src=x onerror=alert(1)>"');
  assert.equal(await evaluate('document.querySelector(".sf-company img")'), null);
  await redraw('window.fixture.company.modules=""');
  assert.ok(!await evaluate('document.querySelector(".sf-company").textContent.includes("Lager, CRM")'));
  await redraw('window.fixture.company.processMode="Posted documents with payments and application"');
  assert.ok(await evaluate('document.querySelector(".sf-company").textContent.includes("Gebuchte Belege mit Zahlungen und Ausgleich")'));
  await redraw('window.fixture.company.hasJob=true;window.fixture.company.steps=[{entityCode:"PURCHASE.ORDER",entity:"Purchase Orders",target:15,confirmed:15,remaining:0,complete:true,external:false}];window.fixture.selected.id="different-historical-run"');
  assert.equal(await evaluate('document.querySelector(".sf-step-value").textContent'), '15 / 15', 'Company progress is independent of historical run selection.');
  await evaluate('document.querySelector(".sf-experts").open=true');
  await click('[data-action=companyQueue]');
  assert.equal(await evaluate('window.calls.at(-1).args[0]'), 'companyQueue');
  await evaluate('document.querySelector(".sf-experts").open=false');
  await redraw('window.fixture.company.error="<img src=x onerror=alert(1)>"');
  assert.equal(await evaluate('document.querySelector(".sf-company img")'), null);
  assert.equal(await evaluate('document.querySelector(".sf-company [role=alert]").textContent.includes("<img")'), true);
  await redraw('window.fixture.company.error=""');
  for (const width of [1440, 768, 320]) {
    await cdp('Emulation.setDeviceMetricsOverride', { width, height: 500, deviceScaleFactor: 1, mobile: false });
    assert.equal(await evaluate('document.querySelector("#controlAddIn").scrollWidth<=document.querySelector("#controlAddIn").clientWidth'), true);
  }
  const companyShot = await cdp('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  await writeFile(join(tmpdir(), 'BCSF-dashboard-SF045-company.png'), Buffer.from(companyShot.data, 'base64'));
  // SF-045 follow-up: real one-second polling preserves nodes and never disables controls.
  await redraw('window.fixture.company.hasJob=false;window.fixture.stock.metrics=[{key:"customer",caption:"Customers",count:25,canOpen:true}];window.fixture.readAt="before"');
  await evaluate(`window.stableTile=document.querySelector('[data-stock-focus="metric:customer"]');window.stableNumber=window.stableTile.querySelector("strong");window.stableFilter=document.querySelector("select");window.stableExpert=document.querySelector(".sf-experts");window.stableExpert.open=true;window.fixture.stock.metrics[0].count=26;window.fixture.readAt="after";window.hold=true;window.calls=[]`);
  await until('window.calls.some(call=>call.args[0]==="autoRefresh")');
  const autoCalls = await evaluate('window.calls.length');
  assert.equal(await evaluate('document.querySelector("#controlAddIn").getAttribute("aria-busy")'), 'false');
  assert.equal(await evaluate('document.querySelector("[data-action=workflow]").disabled'), false);
  await pause(2200);
  assert.equal(await evaluate('window.calls.length'), autoCalls, 'Slow polls never overlap.');
  await evaluate('window.hold=false;window.pending()');
  await until('document.querySelector(".sf-footer").textContent.includes("after")');
  assert.equal(await evaluate(`window.stableTile===document.querySelector('[data-stock-focus="metric:customer"]')`), true, 'Tile node survives background refresh.');
  assert.equal(await evaluate('window.stableNumber===window.stableTile.querySelector("strong")'), true, 'Changed count updates the existing text node.');
  assert.equal(await evaluate('window.stableNumber.textContent'), '26');
  assert.equal(await evaluate('window.stableExpert===document.querySelector(".sf-experts") && window.stableExpert.open'), true);
  assert.equal(await evaluate('window.stableFilter===document.querySelector("select")'), true);
  await evaluate('window.failNext=true');
  await until('document.querySelector(".sf-feedback").textContent===window.fixture.texts.error');
  assert.equal(await evaluate('document.querySelector("[data-action=workflow]").disabled'), false);
  await click('[data-action=refresh]');
  assert.equal(await evaluate('document.querySelector(".sf-feedback").textContent'), '');
  console.log('PASS: one-second silent refresh, stable tile/text/filter/details nodes, changed live count, single-flight slow polling and recoverable polling errors.');
  console.log('PASS: SF-045 company summary, collapsed expert templates, same-run confirmed progress, German labels, error/XSS and responsive widths. Client bridge only, no native BC execution.');
  console.log('PASS: SF-044 Chromium client regression: separate accessible tabs, scope isolation (25 company / 20 run), entire tile routing, child results, zero/ACL/generator states, stale result separation, summary routes, compact actions, diagnosis, status/quality, DE/EN, duplicate suppression, error/XSS, responsive grids and scrolling at 1440/768/320px.');
  console.log(`Synthetic previews: ${join(tmpdir(), 'BCSF-dashboard-SF044-runs.png')}, ${join(tmpdir(), 'BCSF-dashboard-SF044-data.png')}. No Business Central runtime, permissions or native target filters were executed.`);
} finally {
  if (ws) ws.close();
  chrome.kill('SIGTERM');
  await new Promise(resolve => server.close(resolve));
  await pause(300);
  await rm(work, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
