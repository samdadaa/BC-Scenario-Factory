/** Deterministic dashboard client/bridge smoke. Does not simulate BC records or ACLs. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const root = new Element('root');
const calls = [];
const view = { groups: [
  { key: 'master', caption: 'Master data' }, { key: 'sales', caption: 'Sales' },
  { key: 'purchase', caption: 'Purchasing' }, { key: 'entries', caption: 'Ledger entries' },
  { key: 'finance', caption: 'Finance and banking' }
], group: '', entireCompany: false, runId: '', metrics: [] };
const generated = [
  { key: 'customer', caption: 'Debitor', count: 2, canOpen: true },
  { key: 'vendor', caption: 'Kreditor', count: 0, canOpen: false },
  { key: 'item', caption: 'Artikel', status: 'No executable generator', canOpen: false },
  { key: 'bank', caption: 'Bankkonto', status: 'No access', canOpen: false }
];
const company = [{ key: 'invoice', caption: 'Invoices', count: 12, canOpen: true }];
const document = { createElement: tag => new Element(tag), documentElement: {}, getElementById: () => root };
const window = { Microsoft: { Dynamics: { NAV: { InvokeExtensibilityMethod(name, args, _skip, ok, failure) {
  calls.push([name, ...args]);
  if (name === 'Command') {
    const [key, value] = args;
    if (key === 'stockGroup') view.group = value;
    if (key === 'stockScope') {
      view.entireCompany = value === 'company';
      if (view.entireCompany) view.runId = '';
    }
    if (key === 'stockRun') view.runId = value;
    if (key === 'stockOpen' && value === 'rejected') {
      failure();
      return;
    }
  }
  view.metrics = view.group ? (view.entireCompany ? company : generated) : [];
  window.SetDashboard(JSON.stringify(payload));
  ok();
} } } } };
function Element(tag) {
  this.tag = tag; this.children = []; this.attrs = {}; this.dataset = {}; this.events = {};
  this.className = ''; this.textContent = '';
  this.setAttribute = (k, v) => this.attrs[k] = v;
  this.appendChild = x => this.children.push(x);
  this.prepend = x => this.children.unshift(x);
  this.replaceChildren = () => this.children = [];
  this.addEventListener = (event, handler) => this.events[event] = handler;
  this.focus = () => { document.activeElement = this; };
  this.querySelectorAll = s => {
    const tests = s.split(/,\s*/u).map(x => {
      if (x.startsWith('.')) return el => el.className.split(' ').includes(x.slice(1));
      if (x === '[data-stock-focus]') return el => Boolean(el.dataset.stockFocus);
      if (x === 'button[data-action]') return el => el.tag === 'button' && el.dataset.action;
      return el => el.tag === x;
    });
    return this.children.flatMap(el => [...(tests.some(test => test(el)) ? [el] : []), ...el.querySelectorAll(s)]);
  };
  this.querySelector = s => this.querySelectorAll(s)[0] || null;
}
const src = fs.readFileSync('src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al', 'utf8');
const labels = Object.fromEntries([...src.matchAll(/(\w+Lbl): Label '((?:[^']|'')*)';/gu)].map(m => [m[1], m[2].replaceAll("''", "'")]));
const texts = Object.fromEntries([...src.matchAll(/Texts\.Add\('([^']+)', (\w+Lbl)\)/gu)].map(m => [m[1], labels[m[2]]]));
const picked = '{BC9C1259-8DDF-4C14-9068-8F19996E1215}';
const payload = { schemaVersion: 1, language: 'de-DE', locale: 'de-DE', texts, readAt: '2026-11-19',
  summary: { templates: 1, runs: 1, active: 0, review: 0 }, hasSelection: false,
  runs: [{ id: picked, description: 'Kleine Sandbox', createdAt: '19.11.2026', profile: 'GENERAL' }], stock: view };
const context = vm.createContext({ window, document, Intl });
for (const file of ['translations.js', 'dashboard.js'])
  vm.runInContext(fs.readFileSync('src/Monitoring/Dashboard/' + file, 'utf8'), context);
const get = key => root.querySelectorAll('[data-stock-focus]').find(el => el.dataset.stockFocus === key);
window.BCSFStart();
assert.deepEqual(calls, [['Ready']], 'No eager metric call');
assert.equal(root.querySelector('.sf-stock').querySelector('h2').textContent, 'Daten im Mandanten');
assert.equal(root.querySelector('.sf-stock-list'), null);
assert.equal(get('stockScope').children[0].selected, true);
get('group:master').focus();
get('group:master').events.click();
assert.deepEqual(calls.at(-1), ['Command', 'stockGroup', 'master']);
assert.equal(document.activeElement, get('group:master'), 'Keyboard focus restored after redraw');
assert.equal(get('group:master').attrs['aria-pressed'], 'true');
assert.equal(get('metric:customer').textContent, '2');
assert.ok(get('metric:customer').attrs['aria-label'].includes('Standardliste öffnen'));
assert.equal(get('metric:vendor'), undefined);
assert.equal(root.querySelectorAll('.sf-stock-row')[1].querySelector('.sf-stock-number').textContent, '0');
assert.deepEqual(root.querySelectorAll('.sf-stock-status').map(el => el.textContent), ['Kein Generator verfügbar', 'Kein Zugriff']);
get('metric:customer').events.click();
assert.deepEqual(calls.at(-1), ['Command', 'stockOpen', 'customer'], 'No page, table, filter, company or count round-tripped');
get('stockRun').value = picked;
get('stockRun').events.change();
assert.deepEqual(calls.at(-1), ['Command', 'stockRun', picked]);
get('stockScope').value = 'company';
get('stockScope').events.change();
assert.deepEqual(calls.at(-1), ['Command', 'stockScope', 'company']);
assert.equal(get('stockRun'), undefined);
assert.equal(view.runId, '');
get('group:sales').events.click();
assert.equal(get('metric:invoice').textContent, '12');
get('group:finance').events.click();
assert.equal(root.querySelector('.sf-stock-extra').open, true);
view.metrics = [{ key: 'rejected', caption: 'Kreditor', count: 1, canOpen: true }];
window.SetDashboard(JSON.stringify(payload));
get('metric:rejected').events.click();
assert.ok(root.querySelector('.sf-feedback').textContent);
assert.equal(get('stockScope').disabled, false, 'Blocked navigation does not lock the UI');
console.log('PASS: SF-041 client and command bridge, lazy section, DE fallback, hidden counts, keyboard, scope, run and safe command payload.');
