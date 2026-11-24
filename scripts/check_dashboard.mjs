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
const labels = Object.fromEntries([...source.matchAll(/(\w+Lbl): Label '((?:[^']|'')*)'(?:, Comment = '(?:[^']|'')*')?;/gu)].map(match => [match[1], match[2].replaceAll("''", "'")]));
const textKeys = [...source.matchAll(/Texts\.Add\('([^']+)'/gu)].map(match => match[1]);
assert.equal(new Set(textKeys).size, textKeys.length, 'Dashboard AL payload keys must be unique; duplicate JsonObject.Add would fail in BC.');
const texts = Object.fromEntries([...source.matchAll(/Texts\.Add\('([^']+)', (\w+Lbl)\)/gu)].map(match => [match[1], labels[match[2]]]));
assert.ok(Object.values(texts).every(Boolean), 'Every dashboard text must be an AL label.');
const firstId = '{10000000-0000-0000-0000-000000000001}';
const secondId = '{20000000-0000-0000-0000-000000000002}';
const startedIso = new Date(Date.now() - 65000).toISOString();
const selected = { id: firstId, description: 'Wholesale · Demo 2026', profile: 'TRADE / 1', createdAt: '16.11.2026 10:00', processMode: 'Unposted Documents', status: 'Running', hasExecution: true, statusCode: 6, qualityCode: 0, quality: 'Passed', totalBatches: 5, completedBatches: 1, earliest: '16.11.2026 10:00', started: '16.11.2026 10:02', finished: '', startedIso, finishedIso: '', currentNode: 'ITEM', failedBatches: 0, reviewBatches: 0, failedNodes: [], pauseRequested: false, cancelRequested: false,
  events: [{ at: '2026-11-24T14:32:08.000Z', node: 'ITEM', status: 'Running', units: 10 }, { at: '2026-11-24T14:32:05.000Z', node: 'CUSTOMER', status: 'Completed', units: 20 }, { at: '2026-11-24T14:32:01.000Z', node: '', status: 'Running', units: 0 }] };
const fixture = { schemaVersion: 1, view: 'generation', locale: 'en-US', language: 'en-US', initialized: true, texts, readAt: '16.11.2026 10:05', summary: { templates: 3, runs: 2, active: 1, review: 0 },
  runs: [selected, { ...selected, id: secondId, description: 'Training · Returns', statusCode: 11, status: 'Failed', failedBatches: 2, reviewBatches: 1, finishedIso: new Date().toISOString() }],
  hasSelection: true, selected, steps: [
  { node: 'CUSTOMER', entityCode: 'CUSTOMER', module: 'Sales', entity: 'Customers', target: 20, confirmed: 20, remaining: 0, complete: true, external: false, state: 'Completed' },
  { node: 'VENDOR', entityCode: 'VENDOR', module: 'Sales', entity: 'Vendors', target: 5, confirmed: 2, remaining: 3, complete: false, external: false, state: 'Running' },
  { node: 'ITEM', entityCode: 'ITEM', module: 'Inventory', entity: 'Items', target: 40, confirmed: 10, remaining: 30, skipped: 2, complete: false, external: false, state: 'Running' },
  { node: 'SALES.ORDER', entityCode: 'SALES.ORDER', module: 'Sales', entity: 'Sales Orders', target: 10, confirmed: 0, remaining: 10, complete: false, external: false, state: 'Waiting' },
  { node: 'PURCHASE.ORDER', entityCode: 'PURCHASE.ORDER', module: 'Purchase', entity: 'Purchase Orders', target: 5, confirmed: 5, remaining: 0, complete: true, external: false, state: 'Completed' },
  { node: 'FINANCE.SETUP', module: 'FINANCE', entity: 'FINANCE.SETUP', target: 1, confirmed: 0, remaining: 1, artifacts: 0, percent: 0, state: 'Plan blocked', external: true }
] };
fixture.summaryViews = Object.fromEntries(['templates', 'runs', 'active', 'review'].map(key => [key, { canOpen: fixture.summary[key] > 0 }]));
fixture.runStock = { metrics: [{ key: 'customer', caption: 'Customers', count: 20, canOpen: true }, { key: 'vendor', caption: 'Vendors', count: 2, canOpen: true }, { key: 'item', caption: 'Items', count: 10, canOpen: true },
  { key: 'itemUnit', caption: 'Item units', count: 10, canOpen: true }, { key: 'purchase/order', caption: 'Purchase orders', count: 5, canOpen: true }, { key: 'purchase/postedInvoice', caption: 'Posted purchase invoices', count: 4, canOpen: true },
  { key: 'warehouse/putaway', caption: 'Registered put-aways with a very long caption', count: 3, canOpen: true }] };
fixture.stock = { entireCompany: true, runId: '', all: true, groups: [{ key: 'master', caption: 'Master data' }, { key: 'sales', caption: 'Sales' }, { key: 'purchase', caption: 'Purchasing' }, { key: 'inventory', caption: 'Stock movements' }],
  metrics: [
    { key: 'customer', group: 'master', caption: 'Customers', count: 25, canOpen: true }, { key: 'vendor', group: 'master', caption: 'Vendors', count: 0, canOpen: false },
    { key: 'item', group: 'master', caption: 'Items', count: 7, canOpen: true }, { key: 'bank', group: 'master', caption: 'Bankkonten', status: 'No access', canOpen: false },
    { key: 'sales/order', group: 'sales', caption: 'Sales orders', count: 12, canOpen: true }, { key: 'sales/postedInvoice', group: 'sales', caption: 'Posted sales invoices', count: 11, canOpen: true },
    { key: 'purchase/order', group: 'purchase', caption: 'Purchase orders', count: 15, canOpen: true }, { key: 'inventory/entry', group: 'inventory', caption: 'Item ledger entries', count: 33, canOpen: true }] };
const fixtureText = JSON.stringify(fixture).replaceAll('<', '\\u003c');
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="stylesheet" href="/dashboard.css"></head><body><div id="controlAddIn"></div><script>
window.fixture=${fixtureText}; window.calls=[]; window.hold=false; window.failNext=false;
window.Microsoft={Dynamics:{NAV:{InvokeExtensibilityMethod:function(name,args,skip,success,failure){
  window.calls.push({name,args,skip});
  function finish(){if(window.failNext){window.failNext=false;failure();return;}
    if(name==='Command' && args[0]==='select'){window.fixture.selected=window.fixture.runs.find(r=>r.id===args[1]);}
    if(name==='Command' && args[0]==='stockScope'){window.fixture.stock.entireCompany=args[1]==='company';}
    if(name==='Command' && args[0]==='stockRun'){window.fixture.stock.runId=args[1];}
    if(name==='Command' && args[0]==='view'){window.fixture.view=args[1];}
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
  await until('document.querySelector(".sf-hero") && document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  const idle = () => until('document.querySelector("#controlAddIn").getAttribute("aria-busy")==="false"');
  const click = async selector => { await evaluate(`document.querySelector(${JSON.stringify(selector)}).click()`); await idle(); };
  const redraw = async code => evaluate(code + ';window.SetDashboard(JSON.stringify(window.fixture))');
  const calls = () => evaluate('window.calls.length');
  const lastArgs = () => evaluate('window.calls.at(-1).args');
  const ev = expression => evaluate(expression);
  const width = async (w, h = 900) => cdp('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
  assert.equal(await calls(), 1, 'Opening only sends the Ready handshake.');
  await width(1440);

  // ---- Three views inside the one add-in -------------------------------------------------------------------
  assert.equal(await ev('[...document.querySelectorAll("[role=tab]")].map(e=>e.textContent).join("|")'), 'Generation|Company data|Runs');
  assert.equal(await ev('document.querySelectorAll("[role=tab] svg").length'), 3, 'Every tab has an icon.');
  assert.equal(await ev('document.querySelector("#sf-tab-generation").getAttribute("aria-selected")'), 'true');
  assert.equal(await ev('document.querySelectorAll(".sf-hero").length'), 1);
  assert.equal(await ev('document.querySelectorAll(".sf-stock, .sf-run-list").length'), 0, 'Only the active view is rendered.');
  assert.equal(await ev('document.querySelectorAll(".sf-module-detail, .sf-chevron-down").length'), 0, 'The inline expand mechanism is gone.');
  await click('[data-action=exportPackage]');
  assert.deepEqual(await lastArgs(), ['exportPackage', '']);
  await click('[data-action=refresh]');

  // ---- Generation: compact hero, pills, live row -------------------------------------------------------------
  await until('document.querySelector(".sf-hero .sf-ring-hero .sf-ring-label").textContent==="46%"');
  assert.ok(await ev('document.querySelector(".sf-hero").getBoundingClientRect().height') < 150, 'Overall status is compact.');
  assert.equal(await ev('document.querySelector(".sf-pill-ok").textContent.startsWith("1/4")'), true, 'Completed modules read 1/4.');
  assert.equal(await ev('document.querySelector(".sf-pill-run strong").textContent'), '2');
  assert.equal(await ev('document.querySelector(".sf-pill-wait strong").textContent'), '1');
  assert.equal(await ev('document.querySelector(".sf-pill-warn strong").textContent'), '1', 'Entities with skipped units count as warnings.');
  assert.equal(await ev('document.querySelector(".sf-pill-err")'), null, 'No error pill without errors.');
  assert.ok(/^0:01:\d\d$/.test(await ev('document.querySelector(".sf-hero .sf-elapsed").textContent')));
  assert.equal(await ev('document.querySelector(".sf-feed-step strong").textContent'), 'Items', 'Current step is visible while running.');
  assert.ok((await ev('document.querySelector(".sf-feed-last").textContent')).includes('Items · Running'), 'Latest activity is visible without opening.');
  assert.equal(await ev('document.querySelector(".sf-feed").open'), false);
  assert.equal(await ev('document.querySelectorAll(".sf-feed-item").length'), 3);
  assert.equal(await ev('document.querySelector(".sf-warning, .sf-hero .sf-scope")'), null, 'Long warning texts are not shown across the page.');

  // ---- Module cards ---------------------------------------------------------------------------------------------
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 4);
  assert.equal(await ev('document.querySelectorAll(".sf-module.sf-running").length'), 1);
  assert.equal(await ev('document.querySelectorAll(".sf-module-done .sf-check").length'), 1, 'Completed modules carry a green check.');
  assert.equal(await ev('new Set([...document.querySelectorAll(".sf-module")].map(e=>Math.round(e.getBoundingClientRect().height))).size'), 1, 'Equal card height.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-more").textContent.includes("Entities: 4")'), true, 'Entity count is shown quietly.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-more-warn").textContent'), '⚠ 1', 'Module warning shown on its module.');
  assert.equal(await ev('document.querySelector(".sf-mod-purchase .sf-module-meter").classList.contains("sf-meter-off")'), true, 'Finished module hides its bar without removing it.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-meter").classList.contains("sf-meter-off")'), false);
  assert.equal(await ev('[...document.querySelectorAll(".sf-chips")].every(e=>e.children.length>=1&&e.children.length<=4)'), true);
  const handlerBase = await calls();
  await click('.sf-mod-master .sf-chip[data-render-key="chip:step:ITEM"]');
  assert.deepEqual(await lastArgs(), ['runOpen', 'item'], 'Headline figure opens the list and not the overlay.');
  assert.equal(await ev('document.querySelector(".sf-overlay")'), null);
  assert.equal(await calls(), handlerBase + 1);

  // ---- Detail overlay ---------------------------------------------------------------------------------------------
  const rects = '[...document.querySelectorAll(".sf-module")].map(e=>JSON.stringify(e.getBoundingClientRect())).join()';
  await pause(400);
  const before = await ev(rects);
  await click('[data-action="module:master"]');
  assert.equal(await ev('Boolean(document.querySelector(".sf-overlay [role=dialog]"))'), true);
  assert.equal(await ev(rects), before, 'Opening the overlay moves no card.');
  assert.equal(await ev('document.activeElement.className'), 'sf-overlay-close', 'Focus moves into the dialog.');
  assert.equal(await ev('document.querySelector(".sf-overlay-title").textContent'), 'Master data');
  assert.equal(await ev('document.querySelectorAll(".sf-overlay-grid > *").length'), 4, 'Every entity of the module is listed.');
  const labels = await ev('[...document.querySelectorAll(".sf-overlay .sf-stock-label")].map(e=>e.textContent)');
  assert.equal(new Set(labels).size, labels.length, 'No entity appears twice in the overlay.');
  assert.equal(await ev('document.querySelector(".sf-overlay .sf-step-value").textContent'), '20 / 20');
  assert.ok(await ev('document.querySelector(".sf-overlay .sf-step.sf-tile .sf-help").textContent.includes("Outstanding")'), 'Created, target and open quantity are shown.');
  assert.ok(await ev('document.querySelector(".sf-overlay .sf-warning").textContent.includes("2")'), 'Existing hints stay visible.');
  await click('.sf-overlay [data-stock-focus="result:itemUnit"]');
  assert.deepEqual(await lastArgs(), ['runOpen', 'itemUnit']);
  assert.equal(await ev('Boolean(document.querySelector(".sf-overlay"))'), true, 'Navigation keeps the overlay.');
  // live update: same nodes, changed values, overlay stays
  await ev('window.keepOverlay=document.querySelector(".sf-overlay");window.keepTile=document.querySelector(".sf-overlay .sf-step")');
  await redraw('window.fixture.steps[2].confirmed=30;window.fixture.steps[2].remaining=10;window.fixture.runStock.metrics[2].count=30;window.fixture.readAt="poll"');
  await until('document.querySelector(".sf-overlay .sf-step[data-render-key=\\"step:ITEM\\"] .sf-count").textContent==="30"');
  assert.equal(await ev('window.keepOverlay===document.querySelector(".sf-overlay")'), true, 'Overlay is patched, not rebuilt.');
  assert.equal(await ev('window.keepTile===document.querySelector(".sf-overlay .sf-step")'), true);
  assert.equal(await ev('getComputedStyle(document.querySelector(".sf-overlay-body")).overflowY'), 'auto', 'Long content scrolls inside the overlay.');
  assert.equal(await ev('getComputedStyle(document.querySelector("#controlAddIn")).overflowY'), 'auto', 'The add-in keeps its own scrollbar.');
  await ev('document.dispatchEvent(new KeyboardEvent("keydown",{key:"Escape"}))');
  assert.equal(await ev('document.querySelector(".sf-overlay")'), null, 'Escape closes.');
  assert.equal(await ev('document.activeElement.dataset.action'), 'module:master', 'Focus returns to the opener.');
  await click('[data-action="more:sales"]');
  await ev('document.querySelector(".sf-overlay").click()');
  assert.equal(await ev('document.querySelector(".sf-overlay")'), null, 'Click outside closes.');
  await click('[data-action="module:purchase"]');
  await click('.sf-overlay-close');
  assert.equal(await ev('document.querySelector(".sf-overlay")'), null, 'Close button closes.');
  await click('[data-action="module:warehouse"]');
  await redraw('window.fixture.readAt="x"');
  await redraw('window.fixture.readAt="y"');
  const oneClick = await calls();
  await click('.sf-overlay [data-stock-focus="result:warehouse/putaway"]');
  assert.equal(await calls(), oneClick + 1, 'Redraws never register a handler twice.');
  await ev('document.querySelector(".sf-overlay-close").click()');

  // ---- Filter and search appear only for many modules -------------------------------------------------------
  assert.equal(await ev('document.querySelector(".sf-filterbar")'), null, 'No filter bar for four modules.');
  const extra = ['projects/job', 'planning/line', 'manufacturing/order', 'service/order', 'assets/asset', 'contacts/contact', 'assembly/order', 'entries/bankEntry'];
  await redraw(`window.fixture.runStock.metrics.push(${extra.map(k => `{key:"${k}",caption:"${k.split('/')[1]}",count:3,canOpen:true}`).join(',')})`);
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 12);
  assert.equal(await ev('document.querySelector(".sf-filterbar .sf-search-input")!==null'), true);
  await click('[data-action="filter:done"]');
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 1);
  await click('[data-action="filter:all"]');
  await ev('(()=>{const i=document.querySelector("#sf-module-search");i.focus();i.value="plan";i.dispatchEvent(new Event("input"));})()');
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 1, 'Search matches module titles.');
  assert.equal(await ev('document.activeElement.id'), 'sf-module-search', 'Typing keeps the focus.');
  await redraw('window.fixture.readAt="z"');
  assert.equal(await ev('document.querySelector("#sf-module-search").value'), 'plan');
  await ev('(()=>{const i=document.querySelector("#sf-module-search");i.value="";i.dispatchEvent(new Event("input"));})()');

  // ---- Layout: columns and visible cards at 100 % -------------------------------------------------------------
  const columns = () => ev('getComputedStyle(document.querySelector(".sf-modules")).gridTemplateColumns.split(" ").length');
  assert.ok(await columns() >= 4, 'Four or more cards per row on wide areas.');
  const visible = await ev('[...document.querySelectorAll(".sf-module")].filter(e=>e.getBoundingClientRect().bottom<=innerHeight).length');
  assert.ok(visible >= 8, `At least eight cards visible at 1440x900, got ${visible}.`);
  await width(2200, 1000);
  assert.ok(await columns() >= 6, 'More columns on larger areas.');
  for (const [w, min, max] of [[1100, 3, 5], [768, 2, 3], [320, 1, 1]]) {
    await width(w);
    const n = await columns();
    assert.ok(n >= min && n <= max, `Columns at ${w}px: ${n}`);
    assert.equal(await ev('document.querySelector("#controlAddIn").scrollWidth<=document.querySelector("#controlAddIn").clientWidth'), true, `No horizontal overflow at ${w}px.`);
  }
  await width(1440);

  // ---- Switching views keeps everything -------------------------------------------------------------------------
  await ev('document.querySelector("#sf-tab-generation").focus()');
  await click('[data-action="filter:open"]');
  await ev('window.keepHero=document.querySelector(".sf-hero")');
  const switches = await calls();
  await click('#sf-tab-data');
  await until('window.calls.some(c=>c.args[0]==="view"&&c.args[1]==="data")');
  assert.equal(await ev('document.querySelector("#sf-tab-data").getAttribute("aria-selected")'), 'true');
  assert.equal(await ev('document.querySelector(".sf-hero")'), null);
  assert.equal(await calls(), switches + 1, 'A tab switch is one silent request without a busy lock.');
  assert.equal(await ev('document.querySelector("#controlAddIn").getAttribute("aria-busy")'), 'false');

  // ---- Company data: same cards, stock numbers only ---------------------------------------------------------
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 4);
  assert.equal(await ev('document.querySelectorAll(".sf-ring, .sf-module-meter, .sf-module-state").length'), 0, 'No progress or generation status for stock.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-chip[data-render-key=\\"chip:metric:customer\\"] .sf-count").textContent'), '25');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-sub").textContent'), 'Entities: 4');
  assert.equal(await ev('document.querySelector(".sf-scope").textContent'), texts.stockCompany);
  await click('.sf-mod-master .sf-chip[data-render-key="chip:metric:customer"]');
  assert.deepEqual(await lastArgs(), ['stockOpen', 'customer']);
  await click('.sf-mod-sales .sf-chip[data-render-key="chip:metric:sales/order"]');
  assert.deepEqual(await lastArgs(), ['stockOpen', 'sales/order'], 'Group-prefixed keys reach the server unchanged.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-chip[data-render-key=\\"chip:metric:vendor\\"]").tagName'), 'DIV', 'A zero count is shown but never routed.');
  await click('[data-action="module:master"]');
  assert.equal(await ev('document.querySelector(".sf-overlay [data-stock-focus=\\"metric:customer\\"]").tagName'), 'BUTTON');
  assert.equal(await ev('document.querySelector(".sf-overlay .sf-stock-status").textContent'), 'No access');
  assert.equal(await ev('document.querySelectorAll(".sf-overlay .sf-tile").length'), 4);
  await click('.sf-overlay [data-stock-focus="metric:item"]');
  assert.deepEqual(await lastArgs(), ['stockOpen', 'item']);
  await ev('document.querySelector(".sf-overlay-close").click()');
  // filters: scope and run keep their meaning and commands
  await ev('(()=>{const s=document.querySelector("select");s.value="generated";s.dispatchEvent(new Event("change"));})()');
  await idle();
  assert.deepEqual(await lastArgs(), ['stockScope', 'generated']);
  await redraw(`window.fixture.stock.entireCompany=false;window.fixture.stock.runId=${JSON.stringify(firstId)};window.fixture.stock.metrics.push({key:'planned',group:'master',caption:'Planned entity',noGenerator:true,status:'No executable generator'})`);
  assert.ok((await ev('document.querySelector(".sf-scope").textContent')).includes(texts.selectedRunScope));
  assert.equal(await ev('document.querySelectorAll("select").length'), 2, 'Scope and run filter are both available.');
  assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-sub").textContent'), 'Entities: 4', 'Entities without generator are not counted.');
  await click('[data-action="module:master"]');
  assert.equal(await ev('document.querySelector(".sf-overlay-missing h4").textContent.startsWith("' + texts.unavailableEntities.replaceAll('"', '\\"') + '")'), true);
  assert.equal(await ev('document.querySelector(".sf-overlay-missing .sf-stock-status").textContent'), 'No executable generator');
  assert.equal(await ev('document.querySelectorAll(".sf-overlay-missing button").length'), 0, 'No progress or navigation for a missing generator.');
  await ev('document.querySelector(".sf-overlay-close").click()');
  await ev('(()=>{const s=document.querySelectorAll("select")[1];s.value=' + JSON.stringify(secondId) + ';s.dispatchEvent(new Event("change"));})()');
  await idle();
  assert.deepEqual(await lastArgs(), ['stockRun', secondId]);
  // stock polling keeps nodes
  await ev('window.stableChip=document.querySelector(".sf-mod-master .sf-chip .sf-count");window.hold=false');
  await redraw('window.fixture.stock.metrics[0].count=26');
  await until('window.stableChip.textContent==="26"');
  assert.equal(await ev('window.stableChip===document.querySelector(".sf-mod-master .sf-chip .sf-count")'), true, 'Stock counters tween on the same node.');

  // ---- Runs: history list, selection opens the generation view -----------------------------------------------
  await click('#sf-tab-runs');
  assert.equal(await ev('document.querySelectorAll(".sf-run-row").length'), 2);
  assert.equal(await ev('document.querySelector(".sf-run-selected strong").textContent'), 'Wholesale · Demo 2026');
  assert.ok((await ev('document.querySelectorAll(".sf-run-row")[1].textContent')).includes('Failed'));
  assert.equal(await ev('document.querySelectorAll(".sf-run-row")[1].querySelector(".sf-pill-err strong").textContent'), '2');
  assert.equal(await ev('document.querySelectorAll(".sf-run-row")[1].querySelector(".sf-pill-warn strong").textContent'), '1');
  assert.ok(/^\d+:\d\d:\d\d$/.test(await ev('document.querySelector(".sf-run-row .sf-elapsed").textContent')), 'Runtime is shown per run.');
  assert.ok((await ev('document.querySelector(".sf-run-row .sf-run-sub").textContent')).includes('Unposted Documents'));
  for (const key of ['templates', 'runs', 'active']) {
    await click('[data-action="summary:' + key + '"]');
    assert.deepEqual(await lastArgs(), ['summary', key]);
  }
  assert.equal(await ev('document.querySelector(".sf-stat-review").tagName'), 'DIV', 'Zero has no unsupported action.');
  for (const [status, expectedText] of [[3, texts.primaryStart], [6, texts.primaryProgress], [9, texts.primaryResults], [11, texts.primaryErrors]]) {
    await redraw(`window.fixture.selected.statusCode=${status};window.fixture.selected.canStart=true`);
    assert.equal(await ev('document.querySelector("[data-action=primary]").textContent'), expectedText);
    await click('[data-action=primary]');
    assert.deepEqual(await lastArgs(), ['primary', firstId]);
  }
  await redraw('window.fixture.selected.statusCode=6');
  await click('.sf-run-row:not(.sf-run-selected)');
  await until('document.querySelector("#sf-tab-generation").getAttribute("aria-selected")==="true"');
  assert.deepEqual(await ev('window.calls.filter(c=>c.args[0]==="select").at(-1).args'), ['select', secondId]);
  assert.equal(await ev('document.querySelector(".sf-hero h2").textContent'), 'Training · Returns', 'The chosen run opens in the generation view.');
  assert.equal(await ev('document.querySelector("#sf-run-select").value'), secondId);

  assert.equal(await ev('document.querySelector("[data-action=\\"filter:open\\"]").getAttribute("aria-pressed")'), 'true', 'The module filter survives view switches and run changes.');
  await redraw('window.fixture.runStock.metrics=window.fixture.runStock.metrics.slice(0,7)');
  assert.equal(await ev('document.querySelectorAll(".sf-module").length'), 4, 'Few modules are never hidden by a stale filter.');
  assert.equal(await ev('document.querySelector(".sf-filterbar")'), null, 'The filter bar disappears when few modules remain.');
  // ---- Run situations ----------------------------------------------------------------------------------------------
  await redraw('window.fixture.selected.statusCode=11;window.fixture.selected.status="Failed";window.fixture.selected.failedBatches=2;window.fixture.selected.failedNodes=["VENDOR"];window.fixture.selected.currentNode=""');
  assert.equal(await ev('document.querySelector(".sf-hero").classList.contains("sf-tone-error")'), true);
  assert.equal(await ev('document.querySelector(".sf-pill-err strong").textContent'), '2');
  assert.equal(await ev('document.querySelectorAll(".sf-module-error").length'), 1, 'The failed module shows its error itself.');
  assert.equal(await ev('document.querySelector(".sf-feed-step")'), null, 'No current step after the run stopped.');
  await click('.sf-pill-err');
  assert.ok((await ev('document.querySelector(".sf-overlay .sf-issue-err").textContent')).includes('Vendors'));
  await ev('document.querySelector(".sf-overlay-close").click()');
  await redraw('window.fixture.selected.statusCode=10;window.fixture.selected.status="Completed with Warnings";window.fixture.selected.failedBatches=0;window.fixture.selected.failedNodes=[];window.fixture.selected.finishedIso=new Date().toISOString();window.fixture.selected.postingSkips="2 documents unposted: STOCK";window.fixture.selected.masterPool="Eligible 1/2 customers"');
  assert.equal(await ev('document.querySelector(".sf-hero").classList.contains("sf-tone-warn")'), true);
  assert.equal(await ev('document.querySelector(".sf-hero").textContent.includes("2 documents unposted")'), false, 'Long texts stay out of the hero.');
  await click('[data-action="issues:details"]');
  assert.ok((await ev('document.querySelector(".sf-overlay").textContent')).includes('2 documents unposted: STOCK'));
  assert.ok((await ev('document.querySelector(".sf-overlay").textContent')).includes('Eligible 1/2 customers'));
  await redraw('window.fixture.selected.postingSkips="<img src=x onerror=window.injected=true>"');
  assert.equal(await ev('document.querySelectorAll("img").length'), 0);
  await ev('document.querySelector(".sf-overlay-close").click()');
  await redraw('window.fixture.selected.postingSkips="";window.fixture.selected.masterPool="";window.fixture.selected.statusCode=9;window.fixture.selected.status="Completed";window.fixture.steps=window.fixture.steps.map(s=>({...s,confirmed:s.target,remaining:0,complete:true,skipped:0}))');
  assert.equal(await ev('document.querySelector(".sf-hero").classList.contains("sf-tone-done")'), true);
  assert.equal(await ev('document.querySelector(".sf-pill-ok").textContent.startsWith("4/4")'), true);
  assert.equal(await ev('document.querySelector(".sf-pill-run")'), null, 'Finished runs drop the running pill.');
  assert.equal(await ev('document.querySelector(".sf-hero .sf-elapsed").hasAttribute("data-end")'), true, 'The clock stops at completion.');
  assert.equal(await ev('document.querySelectorAll(".sf-module-done").length'), 4);
  assert.equal(await ev('document.querySelectorAll(".sf-meter-off").length'), 4);

  // ---- Completion confirmation only on a real change ------------------------------------------------------------------
  await redraw('window.fixture.selected.statusCode=6;window.fixture.selected.status="Running";window.fixture.selected.finishedIso="";window.fixture.steps[3].confirmed=0;window.fixture.steps[3].complete=false;window.fixture.steps[3].remaining=10');
  await pause(2600);
  await redraw('');
  assert.equal(await ev('document.querySelectorAll(".sf-celebrate").length'), 0);
  await redraw('window.fixture.steps[3].confirmed=10;window.fixture.steps[3].complete=true;window.fixture.steps[3].remaining=0');
  assert.equal(await ev('document.querySelectorAll(".sf-mod-sales.sf-celebrate.sf-module-done").length'), 1);
  assert.equal(await ev('document.querySelectorAll(".sf-mod-purchase.sf-celebrate").length'), 0);

  // ---- German UI, XSS, scrolling and background refresh -----------------------------------------------------------
  const germanBySource = JSON.parse(execFileSync('python3', ['-c', 'import json,xml.etree.ElementTree as E; n={"x":"urn:oasis:names:tc:xliff:document:1.2"};t=E.parse("Translations/BC Scenario Factory.de-DE.xlf"); print(json.dumps({u.find("x:source",n).text:u.find("x:target",n).text for u in t.findall(".//x:trans-unit",n)}))'], { cwd: root, encoding: 'utf8' }));
  // New labels have no compiler-generated XLIFF id before the first build; the reviewed language maps cover them.
  for (const name of ['sf041', 'sf044', 'sf052', 'sf053', 'sf054', 'sf055', 'sf057']) {
    const reviewed = JSON.parse(readFileSync(join(root, 'Translations', name + '.de.json'), 'utf8'));
    for (const [source, target] of Object.entries(reviewed)) germanBySource[source] ??= target;
  }
  const germanTexts = Object.fromEntries(Object.entries(texts).map(([key, value]) => [key, germanBySource[value]]));
  assert.ok(Object.values(germanTexts).every(Boolean), 'All labels have German targets.');
  for (const language of ['de-DE', 'de-AT', 'de-CH', 'de-LI', 'de-LU']) {
    await redraw(`window.fixture.language=${JSON.stringify(language)};window.fixture.locale='de-DE'`);
    assert.equal(await ev('[...document.querySelectorAll("[role=tab]")].map(e=>e.textContent).join("|")'), 'Generierung|Mandantendaten|Läufe');
    assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-title").textContent'), 'Stammdaten');
    assert.equal(await ev('document.querySelector(".sf-mod-master .sf-module-more").textContent.includes("Entitäten: 4")'), true);
    assert.equal(await ev('document.querySelector(".sf-link").textContent'), 'Alle Details');
  }
  await redraw(`window.fixture.texts=${JSON.stringify(germanTexts)};window.fixture.language='de-DE'`);
  assert.equal(await ev('document.querySelector(".sf-pill-ok .sf-pill-label").textContent'), germanTexts.moduleDone);
  await redraw('window.fixture.language="en-US";window.fixture.locale="de-DE";window.fixture.texts=' + JSON.stringify(texts));
  await redraw('window.fixture.selected.description="<img src=x onerror=window.injected=true>"');
  assert.equal(await ev('document.querySelectorAll("img").length'), 0);
  assert.equal(await ev('Boolean(window.injected)'), false);
  assert.equal(await ev('document.querySelector(".sf-hero h2").textContent'), '<img src=x onerror=window.injected=true>');
  await redraw('window.fixture.selected.description="Training · Returns"');
  await width(1440, 500);
  await ev('document.querySelector("#controlAddIn").scrollTop=100000');
  assert.equal(await ev('document.querySelector(".sf-footer").getBoundingClientRect().bottom<=501'), true, 'Everything stays reachable by scrolling.');
  const scroll = await ev('document.querySelector("#controlAddIn").scrollTop');
  assert.ok(scroll > 0);
  await redraw('window.fixture.readAt="scroll"');
  assert.equal(await ev('document.querySelector("#controlAddIn").scrollTop'), scroll, 'Refresh keeps the scroll position.');
  await click('[data-action="module:master"]');
  assert.equal(await ev('document.querySelector(".sf-overlay-panel").getBoundingClientRect().bottom<=500&&document.querySelector(".sf-overlay-panel").getBoundingClientRect().top>=0'), true, 'The overlay stays inside the visible area.');
  await ev('document.querySelector(".sf-overlay-close").click()');
  await width(1440);
  const shot = await cdp('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
  await writeFile(join(tmpdir(), 'BCSF-dashboard-generation.png'), Buffer.from(shot.data, 'base64'));

  // ---- Company wizard path, real one-second polling ----------------------------------------------------------------
  await redraw(`window.fixture.company={name:"Wholesale Sandbox",industry:"Wholesale",chart:"SKR04",status:"Company initialized",processMode:"Posted documents without payments",phase:"Company foundation",error:"",runId:${JSON.stringify(secondId)},hasJob:true}`);
  assert.equal(await ev('document.querySelectorAll(".sf-company").length'), 1);
  assert.equal(await ev('document.querySelector(".sf-toolbar [data-action=scenarios]")'), null);
  assert.equal(await ev('document.querySelector(".sf-hero .sf-run-meta").textContent.includes("Großhandel")||document.querySelector(".sf-hero .sf-run-meta").textContent.includes("Wholesale")'), true);
  await click('[data-action=workflow]');
  assert.deepEqual(await lastArgs(), ['workflow', '']);
  await redraw('window.fixture.company.error="<img src=x onerror=alert(1)>"');
  assert.equal(await ev('document.querySelector(".sf-company img")'), null);
  assert.equal(await ev('document.querySelector(".sf-company [role=alert]").textContent.includes("<img")'), true);
  await redraw('window.fixture.company.error=""');
  await ev('document.querySelector(".sf-experts").open=true');
  await click('[data-action=companyQueue]');
  assert.equal(await lastArgs().then(a => a[0]), 'companyQueue');
  await redraw('window.fixture.readAt="before"');
  await ev(`window.stableChip=document.querySelector(".sf-chip .sf-count");window.stableSelect=document.querySelector("#sf-run-select");window.stableExpert=document.querySelector(".sf-experts");window.fixture.runStock.metrics[0].count=21;window.fixture.steps[0].confirmed=21;window.fixture.readAt="after";window.hold=true;window.calls=[]`);
  await until('window.calls.some(call=>call.args[0]==="autoRefresh")');
  const autoCalls = await calls();
  assert.equal(await ev('document.querySelector("#controlAddIn").getAttribute("aria-busy")'), 'false');
  assert.equal(await ev('document.querySelector("[data-action=workflow]").disabled'), false);
  await pause(2200);
  assert.equal(await calls(), autoCalls, 'Slow polls never overlap.');
  await ev('window.hold=false;window.pending()');
  await until('document.querySelector(".sf-footer").textContent.includes("after")');
  assert.equal(await ev('window.stableSelect===document.querySelector("#sf-run-select")'), true, 'Run picker survives refresh.');
  assert.equal(await ev('window.stableExpert===document.querySelector(".sf-experts") && window.stableExpert.open'), true);
  await evaluate('window.failNext=true');
  await until('document.querySelector(".sf-feedback").textContent===window.fixture.texts.error');
  assert.equal(await ev('document.querySelector("[data-action=workflow]").disabled'), false);
  await click('[data-action=refresh]');
  assert.equal(await ev('document.querySelector(".sf-feedback").textContent'), '');
  await ev('window.SetDashboard(JSON.stringify({schemaVersion:99}))');
  assert.equal(await ev('document.querySelector(".sf-feedback").textContent'), texts.error);
  await redraw('window.fixture.hasSelection=false;window.fixture.runs=[];window.fixture.company.steps=[{node:"PURCHASE.ORDER",entityCode:"PURCHASE.ORDER",entity:"Purchase Orders",target:15,confirmed:15,remaining:0,complete:true,external:false}]');
  assert.equal(await ev('document.querySelector(".sf-mod-purchase .sf-chip-value").textContent'), '15 / 15', 'Company progress shows when no run is selected.');
  console.log('PASS: Live control center in three views: compact hero, status pills, live row, shared module cards, detail overlay (once per entity, live patched, Esc/click/close, focus), filters/search, company data scope/run/no-generator, run history and selection, DE/EN, XSS, columns/visible cards at 320-2200px, scroll, polling and error recovery. Client bridge only; no native BC execution.');
  console.log(`Synthetic preview: ${join(tmpdir(), 'BCSF-dashboard-generation.png')}`);
} finally {
  if (ws) ws.close();
  chrome.kill('SIGTERM');
  await new Promise(resolve => server.close(resolve));
  await pause(300);
  await rm(work, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
