/* Bundled, dependency-free Business Central control add-in. All UI text comes from AL/XLIFF. */
(function () {
  "use strict";
  let root;
  let model;
  let busy = false;
  let failed = false;
  let stockFocus = "";
  let pollTimer;
  let polling = false;
  let queuedAction;
  let pendingView;
  let keyBound = false;
  const refreshInterval = 1000;
  const listen = (element, event, handler) => {
    element.sfHandlers = element.sfHandlers || {};
    element.sfHandlers[event] = handler;
    element.addEventListener(event, handler);
  };
  // View state lives in the client: switching tabs, filters, search and the overlay never rebuild the add-in.
  const tabKeys = ["generation", "data", "runs"];
  let activeTab = "generation";
  const tabScroll = { generation: 0, data: 0, runs: 0 };
  let genFilter = "all";
  let genQuery = "";
  let dataQuery = "";
  let overlay = null;                  // { kind: "module" | "issues", tab, id }
  let overlayOpener = "";
  const groups = {
    planGroup: ["run", "scenario", "plan", "savePlan", "readiness", "preflight", "synthetic"],
    executeGroup: ["prepare", "schedule", "pause", "cancel", "apply", "resume"],
    resultGroup: ["progress", "batches", "history", "records", "queue"]
  };
  const localized = (value) => {
    const language = (model.language || "").toLowerCase().split("-")[0];
    const catalog = window.BCSFDashboardTranslations && window.BCSFDashboardTranslations[language];
    return catalog && Object.hasOwn(catalog, value) ? catalog[value] : value;
  };
  const text = (key) => localized(model.texts[key]);
  const node = (tag, className, value) => {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (value !== undefined && value !== null) element.textContent = String(value);
    return element;
  };
  const number = (value) => new Intl.NumberFormat(model.locale || document.documentElement.lang || undefined).format(value);
  const append = (parent, ...children) => { children.forEach(child => parent.appendChild(child)); return parent; };
  const button = (key, className, action, runId) => {
    const element = node("button", className, text(key));
    element.type = "button";
    element.dataset.action = action || key;
    element.disabled = busy;
    listen(element, "click", () => request(action || key, runId || ""));
    return element;
  };
  function setBusy(value) {
    busy = value;
    if (!root) return;
    root.setAttribute("aria-busy", String(value));
    root.querySelectorAll("button, select").forEach(element => { if (!element.hasAttribute("data-always")) element.disabled = value; });
    const feedback = root.querySelector(".sf-feedback");
    if (feedback && model) feedback.textContent = value ? text("busy") : failed ? text("error") : "";
  }
  function invoke(event, args, success, failure) {
    const nav = window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV;
    if (!nav || typeof nav.InvokeExtensibilityMethod !== "function") { failure(); return; }
    try {
      nav.InvokeExtensibilityMethod(event, args, false, success, failure);
    } catch (_) { failure(); }
  }
  function request(action, runId, done) {
    if (polling) { queuedAction = [action, runId, done]; return; }
    if (busy) return;
    failed = false;
    setBusy(true);
    if (action.startsWith("stock") || action === "runOpen")
      stockFocus = document.activeElement?.dataset?.stockFocus || "";
    invoke("Command", [action, runId], () => {
      setBusy(false);
      restoreStockFocus();
      if (done) done();
      flushView();
    }, () => {
      failed = true;
      if (model) render();
      setBusy(false);
      restoreStockFocus();
      flushView();
    });
  }
  // Tab changes tell the server which data to build. They run like a poll: no busy lock, last request wins.
  function silent(action, argument) {
    if (busy || polling) { pendingView = [action, argument]; return; }
    polling = true;
    invoke("Command", [action, argument], () => finishPoll(false), () => finishPoll(true));
  }
  function flushView() {
    if (!pendingView || busy || polling) return;
    const [action, argument] = pendingView;
    pendingView = undefined;
    silent(action, argument);
  }
  function scheduleRefresh() {
    clearTimeout(pollTimer);
    pollTimer = setTimeout(() => {
      scheduleRefresh();
      tickElapsed();
      if (!model || busy || polling || document.hidden || ["SELECT", "INPUT"].includes(document.activeElement?.tagName)) return;
      polling = true;
      invoke("Command", ["autoRefresh", ""], () => finishPoll(false), () => finishPoll(true));
    }, refreshInterval);
  }
  function finishPoll(error) {
    polling = false;
    if (error) {
      failed = true;
      const feedback = root?.querySelector(".sf-feedback");
      if (feedback && model) feedback.textContent = text("error");
    }
    if (queuedAction) {
      const [action, runId, done] = queuedAction;
      queuedAction = undefined;
      request(action, runId, done);
    } else flushView();
  }
  // Keep live nodes, focus, open details and selection stable. Only changed attributes/text are written.
  function domKey(element) {
    if (element.nodeType !== 1) return "";
    return element.dataset.renderKey || element.id || element.dataset.stockFocus || element.dataset.action ||
      (element.tagName === "OPTION" ? "option:" + element.value : element.tagName + ":" + element.className);
  }
  function patchNode(current, next) {
    if (current.nodeType !== next.nodeType || current.nodeName !== next.nodeName) {
      current.replaceWith(next); return next;
    }
    if (current.nodeType === 3) {
      if (current.nodeValue !== next.nodeValue) current.nodeValue = next.nodeValue;
      return current;
    }
    const open = current.tagName === "DETAILS" ? current.open : undefined;
    for (const attribute of Array.from(current.attributes))
      if (!next.hasAttribute(attribute.name)) current.removeAttribute(attribute.name);
    for (const attribute of Array.from(next.attributes))
      if (current.getAttribute(attribute.name) !== attribute.value) current.setAttribute(attribute.name, attribute.value);
    for (const [event, handler] of Object.entries(current.sfHandlers || {})) current.removeEventListener(event, handler);
    current.sfHandlers = next.sfHandlers || {};
    for (const [event, handler] of Object.entries(current.sfHandlers)) current.addEventListener(event, handler);
    // Animated counters own their text; animateCounts() writes it after the patch.
    if (!next.hasAttribute("data-count")) patchChildren(current, Array.from(next.childNodes));
    if (current.tagName === "OPTION") current.selected = next.selected;
    if (["SELECT", "INPUT"].includes(current.tagName) && current.value !== next.value) current.value = next.value;
    if ("disabled" in next) current.disabled = next.disabled;
    if (open !== undefined) current.open = open;
    return current;
  }
  function patchChildren(parent, children) {
    // Deterministic non-browser test doubles can still exercise the command bridge.
    if (!parent.childNodes) { parent.replaceChildren(...children); return; }
    const available = Array.from(parent.childNodes);
    let cursor = parent.firstChild;
    for (const next of children) {
      const key = domKey(next);
      const match = available.find(candidate => candidate.nodeType === next.nodeType &&
        candidate.nodeName === next.nodeName && domKey(candidate) === key);
      const child = match ? patchNode(match, next) : next;
      if (match) available.splice(available.indexOf(match), 1);
      if (child !== cursor) parent.insertBefore(child, cursor);
      cursor = child.nextSibling;
    }
    for (const obsolete of available) obsolete.remove();
  }
  function summaryPanel() {
    const summary = node("section", "sf-summary sf-tile-grid");
    [["templateCount", "templates"], ["runCount", "runs"], ["activeCount", "active"], ["reviewCount", "review"]].forEach(([label, key]) => {
      const metric = model.summaryViews?.[key];
      const canOpen = metric?.canOpen && Number.isSafeInteger(model.summary[key]) && model.summary[key] > 0;
      const card = node(canOpen ? "button" : "div", "sf-tile sf-stat sf-stat-" + key);
      append(card, node("span", "sf-stat-label", text(label)),
        node("strong", "sf-stat-value", Number.isSafeInteger(model.summary[key]) ? number(model.summary[key]) : "—"));
      if (canOpen) {
        card.type = "button";
        card.dataset.action = "summary:" + key;
        card.disabled = busy;
        listen(card, "click", () => request("summary", key));
      }
      if (metric?.status) card.appendChild(node("span", "sf-help", localized(metric.status)));
      summary.appendChild(card);
    });
    return summary;
  }
  function metricTile(metric, action) {
    const hasCount = Number.isSafeInteger(metric.count) && metric.count >= 0;
    // Zero is not routed: current stock service does not promise an empty native view.
    const canOpen = metric.canOpen && hasCount && metric.count > 0;
    const card = node(canOpen ? "button" : "div", "sf-tile sf-stock-row");
    card.dataset.renderKey = action + ":" + metric.key;
    const caption = localized(metric.caption);
    append(card, node("span", "sf-stock-label", caption),
      node("strong", "sf-stock-number", hasCount ? number(metric.count) : "—"));
    if (canOpen) {
      card.type = "button";
      card.title = text("stockOpen");
      card.dataset.stockFocus = (action === "stockOpen" ? "metric:" : "result:") + metric.key;
      card.disabled = busy;
      card.setAttribute("aria-label", caption + " · " + number(metric.count) + " · " + text("stockOpen"));
      listen(card, "click", () => request(action, metric.key));
    }
    if (metric.status) card.appendChild(node("span", "sf-help sf-stock-status", localized(metric.status)));
    return card;
  }
  function restoreStockFocus() {
    if (!root || !stockFocus) return;
    const inOverlay = Array.from(root.querySelectorAll(".sf-overlay [data-stock-focus]"));
    const selected = inOverlay.concat(Array.from(root.querySelectorAll("[data-stock-focus]")))
      .find(element => element.dataset.stockFocus === stockFocus);
    stockFocus = "";
    if (selected && !selected.disabled) selected.focus({ preventScroll: true });
  }

  function stockSelect(labelKey, command, options, selected) {
    const label = node("label", "sf-stock-field");
    label.appendChild(node("span", "sf-help", text(labelKey)));
    const select = node("select", "sf-select");
    select.setAttribute("aria-label", text(labelKey));
    select.dataset.stockFocus = command;
    select.disabled = busy;
    options.forEach(([value, caption]) => {
      const option = node("option", "", caption);
      option.value = value;
      option.selected = value === selected;
      select.appendChild(option);
    });
    listen(select, "change", (event) => request(command, event.currentTarget.value));
    return append(label, select);
  }

  function selector() {
    const section = node("section", "sf-run-picker");
    const label = node("label", "sf-section-label", text("recent"));
    label.htmlFor = "sf-run-select";
    const select = node("select", "sf-select");
    select.id = "sf-run-select";
    select.disabled = busy;
    select.setAttribute("aria-label", text("choose"));
    const runs = model.runs.slice();
    if (model.hasSelection && !runs.some(run => run.id === model.selected.id)) runs.push(model.selected);
    runs.forEach(run => {
      const option = node("option", "", run.description + " · " + run.profile + " · " + run.createdAt + " · " + run.id.slice(-7, -1));
      option.value = run.id;
      option.selected = model.hasSelection && run.id === model.selected.id;
      select.appendChild(option);
    });
    listen(select, "change", (event) => request("select", event.currentTarget.value));
    append(section, label, select);
    return section;
  }
  // ---- Shared components: icons, counters, rings, module cards, overlay ----------------------------------------
  const SVG = "http://www.w3.org/2000/svg";
  const reducedMotion = window.matchMedia ? window.matchMedia("(prefers-reduced-motion: reduce)") : { matches: false };
  const lastStates = new Map();        // module id -> last state, to detect a real completion
  const celebrating = new Map();       // module id -> timestamp of the confirmed completion
  let lastRunId = "";
  let cache = { runs: [], all: null };
  const iconPaths = {
    master: "M4 6c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3Zm0 0v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6",
    sales: "M3 17l6-6 4 4 8-8M15 7h6v6",
    purchase: "M3 4h2l2.4 10.2a1 1 0 0 0 1 .8h8.8a1 1 0 0 0 1-.8L20 8H6M9 20h.01M17 20h.01",
    inventory: "M21 8l-9-5-9 5v8l9 5 9-5V8ZM3 8l9 5 9-5M12 13v8",
    assembly: "M14.7 6.3a4 4 0 0 0-5 5L3 18l3 3 6.7-6.7a4 4 0 0 0 5-5l-2.4 2.4-2.6-.6-.6-2.6 2.6-2.2Z",
    projects: "M4 7h16v12H4ZM9 7V5h6v2M4 13h16",
    planning: "M4 6h16v14H4ZM4 10h16M8 3v4M16 3v4",
    warehouse: "M3 21V9l9-5 9 5v12M7 21v-7h10v7M7 17h10",
    manufacturing: "M3 21V10l6 3V10l6 3V6h6v15ZM3 21h18",
    service: "M4 14v-2a8 8 0 0 1 16 0v2M4 14h3v5H4ZM17 14h3v5h-3ZM20 19c0 1.5-2 2-5 2",
    assets: "M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18",
    crm: "M16 20v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1M9.5 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7ZM21 20v-1a4 4 0 0 0-3-3.9M15 4.1a3.5 3.5 0 0 1 0 6.8",
    finance: "M4 5h16v14H4ZM4 10h16M8 15h3",
    banking: "M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18",
    other: "M4 4h6v6H4ZM14 4h6v6h-6ZM4 14h6v6h-6ZM14 14h6v6h-6Z",
    chevron: "M9 6l6 6-6 6",
    check: "M5 13l4 4L19 7",
    activity: "M3 12h4l3-8 4 16 3-8h4",
    wait: "M12 7v5l3 2M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
    error: "M12 8v5M12 16.5h.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
    warn: "M12 4l9 16H3ZM12 10v4M12 17h.01",
    bolt: "M13 3L5 14h6l-1 7 8-11h-6Z",
    list: "M4 6h16M4 12h16M4 18h10",
    search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14ZM21 21l-5-5",
    close: "M6 6l12 12M18 6L6 18",
    timer: "M12 8v5l3 2M9 2h6M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z"
  };
  // Central module definitions. A new module needs one entry: id, title label, accent, icon, the result keys it claims
  // (generation view), the stock groups it shows (company data view) and its preferred headline figures.
  const moduleDefinitions = [
    { id: "master", title: "moduleMaster", color: "#0e9aa7", icon: "master", entities: ["CUSTOMER", "VENDOR", "ITEM"],
      match: key => !key.includes("/"), primary: ["customer", "vendor", "item"] },
    { id: "sales", title: "moduleSales", color: "#2f80ed", icon: "sales", entities: ["SALES.QUOTE", "SALES.BLANKET", "SALES.ORDER", "SALES.INVOICE"],
      match: key => key.startsWith("sales/") || ["entries/customerEntry", "entries/customerPayment", "entries/customerCredit"].includes(key),
      primary: ["sales/order", "sales/postedInvoice", "sales/quote", "entries/customerPayment"] },
    { id: "purchase", title: "modulePurchase", color: "#4b57d1", icon: "purchase", entities: ["PURCHASE.ORDER"],
      match: key => key.startsWith("purchase/") || ["entries/vendorEntry", "entries/vendorPayment", "entries/vendorCredit"].includes(key),
      primary: ["purchase/order", "purchase/postedInvoice", "entries/vendorPayment"] },
    { id: "inventory", title: "moduleInventory", color: "#e5892b", icon: "inventory", entities: [],
      match: key => key.startsWith("inventory/") || ["entries/itemEntry", "entries/valueEntry"].includes(key) },
    { id: "assembly", title: "moduleAssembly", color: "#9b6b3f", icon: "assembly", entities: [], match: key => key.startsWith("assembly/") },
    { id: "projects", title: "moduleProjects", color: "#5b7c99", icon: "projects", entities: [], match: key => key.startsWith("projects/") },
    { id: "planning", title: "modulePlanning", color: "#b04fa0", icon: "planning", entities: [], match: key => key.startsWith("planning/") },
    { id: "warehouse", title: "moduleWarehouse", color: "#c96a2e", icon: "warehouse", entities: [], match: key => key.startsWith("warehouse/") },
    { id: "manufacturing", title: "moduleManufacturing", color: "#7c4dcc", icon: "manufacturing", entities: [], match: key => key.startsWith("manufacturing/") },
    { id: "service", title: "moduleService", color: "#8a9a2e", icon: "service", entities: [], match: key => key.startsWith("service/") },
    { id: "assets", title: "moduleAssets", color: "#7a6a58", icon: "assets", entities: [], match: key => key.startsWith("assets/") },
    { id: "crm", title: "moduleCrm", color: "#c0457a", icon: "crm", groups: ["contacts"], entities: [], match: key => key.startsWith("contacts/") },
    { id: "finance", title: "moduleFinance", color: "#4a5568", icon: "finance", groups: ["entries"], entities: [], match: key => key.startsWith("entries/") },
    { id: "banking", title: "moduleFinance", color: "#3f6f8f", icon: "banking", groups: ["finance"], entities: [], match: () => false },
    { id: "other", title: "moduleOther", color: "#8c96a3", icon: "other", entities: [], match: () => true }
  ];
  const definitionForGroup = key => moduleDefinitions.find(item => (item.groups || [item.id]).includes(key)) || moduleDefinitions.at(-1);
  const stepResultKey = entityCode => ({ "CUSTOMER": "customer", "VENDOR": "vendor", "ITEM": "item", "SALES.QUOTE": "sales/quote", "SALES.BLANKET": "sales/blanket",
    "SALES.ORDER": "sales/order", "SALES.INVOICE": "sales/invoice", "PURCHASE.ORDER": "purchase/order" })[entityCode] || "";
  const svgIcon = (name, className) => {
    const element = document.createElementNS(SVG, "svg");
    element.setAttribute("class", className);
    element.setAttribute("viewBox", "0 0 24 24");
    element.setAttribute("aria-hidden", "true");
    const path = document.createElementNS(SVG, "path");
    path.setAttribute("d", iconPaths[name] || iconPaths.other);
    element.appendChild(path);
    return element;
  };
  // Numbers that tween only when the real value changes (see animateCounts); first display is immediate.
  const countNode = (value, suffix) => {
    const element = node("span", "sf-count", number(value) + (suffix || ""));
    element.dataset.count = String(value);
    if (suffix) element.dataset.suffix = suffix;
    return element;
  };
  function animateCounts() {
    if (!root) return;
    root.querySelectorAll("[data-count]").forEach(element => {
      const target = Number(element.dataset.count);
      if (!Number.isFinite(target)) return;
      const suffix = element.dataset.suffix || "";
      const draw = value => { element.textContent = number(Math.round(value)) + suffix; };
      if (element.sfTarget === target && element.sfSuffix === suffix) return;
      cancelAnimationFrame(element.sfFrame);
      const from = element.sfCurrent;
      element.sfTarget = target;
      element.sfSuffix = suffix;
      if (from === undefined || from === target || reducedMotion.matches || document.hidden) { element.sfCurrent = target; draw(target); return; }
      const started = performance.now();
      const duration = 700;
      const tick = now => {
        const progress = Math.min(1, (now - started) / duration);
        element.sfCurrent = from + (target - from) * (1 - Math.pow(1 - progress, 3));
        draw(element.sfCurrent);
        if (progress < 1) element.sfFrame = requestAnimationFrame(tick);
      };
      element.sfFrame = requestAnimationFrame(tick);
    });
  }
  function ring(percent, className) {
    const wrap = node("span", "sf-ring " + (className || ""));
    const canvas = document.createElementNS(SVG, "svg");
    canvas.setAttribute("viewBox", "0 0 36 36");
    canvas.setAttribute("aria-hidden", "true");
    ["sf-ring-track", "sf-ring-bar"].forEach(name => {
      const circle = document.createElementNS(SVG, "circle");
      circle.setAttribute("class", name);
      circle.setAttribute("cx", "18"); circle.setAttribute("cy", "18"); circle.setAttribute("r", "15.9155");
      circle.dataset.renderKey = name;
      if (name === "sf-ring-bar") circle.setAttribute("style", "stroke-dasharray:" + (percent === null ? 0 : percent) + " 100");
      canvas.appendChild(circle);
    });
    wrap.appendChild(canvas);
    const label = percent === null ? node("span", "", "–") : countNode(percent, "%");
    label.classList.add("sf-ring-label");
    wrap.appendChild(label);
    return wrap;
  }
  const elapsedText = (start, end) => {
    const from = Date.parse(start);
    if (!Number.isFinite(from)) return "—";
    const to = end ? Date.parse(end) : Date.now();
    const seconds = Math.max(0, Math.floor(((Number.isFinite(to) ? to : Date.now()) - from) / 1000));
    const pad = value => String(value).padStart(2, "0");
    return Math.floor(seconds / 3600) + ":" + pad(Math.floor(seconds / 60) % 60) + ":" + pad(seconds % 60);
  };
  function tickElapsed() {
    if (!root) return;
    root.querySelectorAll(".sf-elapsed[data-start]:not([data-end])").forEach(element => {
      const value = elapsedText(element.dataset.start);
      if (element.textContent !== value) element.textContent = value;
    });
  }
  const timeText = iso => {
    const stamp = new Date(iso);
    return Number.isNaN(stamp.getTime()) ? "" : stamp.toLocaleTimeString(model.locale || undefined);
  };
  // Status pill used by the hero, the run list and the filters.
  function pill(kind, icon, value, label, title, action) {
    const element = node(action ? "button" : "span", "sf-pill sf-pill-" + kind);
    if (action) { element.type = "button"; element.dataset.action = action; element.disabled = busy; }
    element.dataset.renderKey = "pill:" + (action || kind + ":" + label);
    if (title) element.title = title;
    append(element, svgIcon(icon, "sf-pill-icon"), value, node("span", "sf-pill-label", label));
    return element;
  }
  function searchBox(value, onInput) {
    const label = node("label", "sf-search");
    const input = node("input", "sf-search-input");
    input.type = "search";
    input.id = "sf-module-search";
    input.value = value;
    input.placeholder = text("moduleSearch");
    input.setAttribute("aria-label", text("moduleSearch"));
    input.dataset.always = "";
    listen(input, "input", event => { onInput(event.currentTarget.value); render(); });
    return append(label, svgIcon("search", "sf-search-icon"), input);
  }
  // ---- Entries: one shape for steps (generation) and stock metrics (company data) -------------------------------
  function stepEntry(step, results) {
    const key = stepResultKey(step.entityCode);
    const metric = results.find(item => item.key === key);
    // Posted document chains legitimately reduce the number of open documents, so opening needs a surviving record only.
    const canOpen = Boolean(metric?.canOpen && metric.count > 0);
    return { id: "step:" + step.entityCode, key, caption: localized(step.entity), count: step.confirmed, target: step.target,
      step, metric, action: "runOpen", openKey: canOpen ? key : "" };
  }
  function metricEntry(metric, action) {
    const hasCount = Number.isSafeInteger(metric.count) && metric.count >= 0;
    return { id: "metric:" + metric.key, key: metric.key, caption: localized(metric.caption), count: hasCount ? metric.count : undefined,
      metric, action, noGenerator: Boolean(metric.noGenerator), openKey: metric.canOpen && hasCount && metric.count > 0 ? metric.key : "" };
  }
  const focusKey = entry => (entry.action === "stockOpen" ? "metric:" : "result:") + entry.openKey;
  function pickHeadline(definition, entries) {
    const usable = entries.filter(entry => !entry.noGenerator);
    let headline = (definition.primary || []).map(key => usable.find(entry => entry.key === key)).filter(Boolean).slice(0, 4);
    if (headline.length < 2)
      headline = usable.slice().sort((a, b) => (b.count || 0) - (a.count || 0)).slice(0, 3);
    return headline;
  }
  function moduleState(steps, entries, allStepsDone, finished, runActive, failedNodes, current) {
    if (steps.some(step => failedNodes.includes(step.node))) return "error";
    if (steps.some(step => step.reviewUnits > 0)) return "review";
    if (steps.length) {
      if (steps.every(step => step.complete)) return "done";
      return current || steps.some(step => step.confirmed > 0) ? "open" : "waiting";
    }
    // Modules fed by the purchase flow or the whole run finish together with it.
    if (allStepsDone && finished) return "done";
    return runActive && entries.some(entry => entry.count > 0) ? "open" : "waiting";
  }
  // Generation view: one pass over the existing payload. Skipped or unconfirmed units never count as created.
  function analyse(view) {
    const run = view.selected;
    const results = view.runStock?.metrics || [];
    const ownSteps = view.steps.filter(step => !step.external);
    const allStepsDone = ownSteps.length > 0 && ownSteps.every(step => step.complete);
    const finished = run.statusCode === undefined || [9, 10].includes(run.statusCode);
    const runActive = [4, 5, 6, 8].includes(run.statusCode);
    const failedNodes = run.failedNodes || [];
    const matched = new Set();
    const claimed = new Set();
    const modules = [];
    moduleDefinitions.forEach(definition => {
      const steps = ownSteps.filter(step => definition.entities.includes(step.entityCode));
      const entries = steps.map(step => {
        const entry = stepEntry(step, results);
        if (entry.metric && entry.metric.count > 0) matched.add(entry.key);
        return entry;
      });
      // A metric belongs to the first module that claims it; matched step results are not repeated.
      results.forEach(metric => {
        if (claimed.has(metric.key) || matched.has(metric.key) || !definition.match(metric.key)) return;
        if (!(metric.count >= 0 || (!Number.isSafeInteger(metric.count) && !metric.noGenerator))) return;
        claimed.add(metric.key);
        entries.push(metricEntry(metric, "runOpen"));
      });
      if (!entries.length) return;
      const target = steps.reduce((sum, step) => sum + (step.target || 0), 0);
      const confirmed = steps.reduce((sum, step) => sum + Math.min(step.confirmed || 0, step.target || 0), 0);
      const current = Boolean(run.currentNode) && steps.some(step => step.node === run.currentNode);
      const state = moduleState(steps, entries, allStepsDone, finished, runActive, failedNodes, current);
      let percent = null;
      if (steps.length && target > 0) percent = Math.round(100 * confirmed / target);
      else if (state === "done") percent = 100;
      modules.push({ id: definition.id, definition, title: text(definition.title), mode: "run", steps, entries,
        headline: pickHeadline(definition, entries), state, percent, current,
        issues: steps.filter(step => step.skipped > 0 || step.reviewUnits > 0).length });
    });
    const planned = ownSteps.reduce((sum, step) => sum + (step.target || 0), 0);
    const created = ownSteps.reduce((sum, step) => sum + Math.min(step.confirmed || 0, step.target || 0), 0);
    let percent = null;
    if (planned > 0) percent = Math.round(100 * created / planned);
    else if (run.totalBatches > 0) percent = Math.round(100 * run.completedBatches / run.totalBatches);
    const count = state => modules.filter(module => module.state === state).length;
    const issueSteps = ownSteps.filter(step => step.skipped > 0 || step.reviewUnits > 0).length;
    let errors = (run.failedBatches || 0) + (run.qualityCode === 2 ? 1 : 0);
    if ([11, 13].includes(run.statusCode) && errors === 0) errors = 1;
    const warnings = (issueSteps || run.reviewBatches || 0) + (run.qualityCode === 1 ? 1 : 0);
    const analysis = { modules, runActive, percent, errors, warnings, total: modules.length, done: count("done"),
      running: runActive ? count("open") : 0, waiting: count("waiting") + (runActive ? 0 : count("open")) };
    if (run.id) trackCompletions(run.id, modules);
    return analysis;
  }
  // Company data view: one card per stock group; counts are the records that exist for the chosen scope and run.
  function analyseStock(stock) {
    const modules = [];
    stock.groups.forEach(group => {
      const metrics = stock.metrics.filter(metric => (metric.group || "master") === group.key);
      if (!metrics.length) return;
      const definition = definitionForGroup(group.key);
      const entries = metrics.map(metric => metricEntry(metric, "stockOpen"));
      modules.push({ id: group.key, definition, title: localized(group.caption), mode: "stock", steps: [], entries,
        headline: pickHeadline(definition, entries), state: null, percent: null, current: false, issues: 0 });
    });
    return modules;
  }
  function trackCompletions(runId, modules) {
    if (runId !== lastRunId) { lastRunId = runId; lastStates.clear(); celebrating.clear(); }
    modules.forEach(module => {
      const before = lastStates.get(module.id);
      if (before && before !== "done" && module.state === "done") celebrating.set(module.id, Date.now());
      lastStates.set(module.id, module.state);
    });
  }
  const stateLabel = state => text({ done: "moduleDone", review: "moduleReview", error: "moduleFailed", open: "moduleOpen", waiting: "moduleWaiting" }[state]);
  const entityCount = module => module.entries.filter(entry => !entry.noGenerator).length;
  const entityCountText = module => text("entitiesCount").replace("%1", number(entityCount(module)));
  function matchesQuery(module, query) {
    const needle = query.trim().toLowerCase();
    return !needle || module.title.toLowerCase().includes(needle) || module.entries.some(entry => entry.caption.toLowerCase().includes(needle));
  }
  // ---- Module card (both views) --------------------------------------------------------------------------------
  function chip(entry) {
    const open = Boolean(entry.openKey);
    const element = node(open ? "button" : "div", "sf-chip");
    element.dataset.renderKey = "chip:" + entry.id;
    const value = node("strong", "sf-chip-value");
    if (entry.count === undefined) value.textContent = "—";
    else value.appendChild(countNode(entry.count));
    if (entry.target > 0) value.appendChild(node("span", "sf-chip-target", " / " + number(entry.target)));
    append(element, node("span", "sf-chip-label", entry.caption), value);
    if (open) {
      element.type = "button";
      element.title = text("stockOpen");
      element.dataset.stockFocus = focusKey(entry);
      element.disabled = busy;
      element.setAttribute("aria-label", entry.caption + " · " + number(entry.count) + " · " + text("stockOpen"));
      listen(element, "click", () => request(entry.action, entry.openKey));
    }
    return element;
  }
  function stepCard(entry) {
    const step = entry.step;
    const metric = entry.metric;
    const safe = Boolean(entry.openKey);
    const card = node(safe ? "button" : "div", "sf-tile sf-step");
    card.dataset.renderKey = "step:" + step.entityCode;
    const value = node("strong", "sf-step-value");
    append(value, countNode(step.confirmed), node("span", "", " / " + number(step.target)));
    append(card, node("span", "sf-stock-label", localized(step.entity)), value,
      node("span", "sf-help", text("created") + " / " + text("target") + " · " + text("remaining") + " " + number(step.remaining)),
      node("span", "sf-step-state", step.complete ? text("completed") : localized(step.state)));
    if (step.skipped > 0)
      card.appendChild(node("span", "sf-warning", text("skippedUnits") + " · " + number(step.skipped)));
    if (step.reviewUnits > 0)
      card.appendChild(node("span", "sf-warning", text("reviewUnits") + " · " + number(step.reviewUnits)));
    if (safe && metric.count !== step.confirmed)
      card.appendChild(node("span", "sf-help", text("stockOpen") + " · " + number(metric.count)));
    if (safe) {
      card.type = "button";
      card.dataset.stockFocus = "result:" + entry.key;
      card.title = text("stockOpen");
      card.disabled = busy;
      listen(card, "click", () => request("runOpen", entry.key));
    }
    return card;
  }
  const entityTile = entry => entry.step ? stepCard(entry) : metricTile(entry.metric, entry.action);
  function openOverlay(kind, id, opener) {
    overlay = { kind, tab: activeTab, id };
    overlayOpener = opener || "";
    render();
    root.querySelector(".sf-overlay-close")?.focus({ preventScroll: true });
  }
  function closeOverlay() {
    if (!overlay) return;
    overlay = null;
    render();
    const opener = overlayOpener && Array.from(root.querySelectorAll("button[data-action]")).find(element => element.dataset.action === overlayOpener);
    if (opener && !opener.disabled) opener.focus({ preventScroll: true });
  }
  function moduleCard(module) {
    const definition = module.definition;
    const run = module.mode === "run";
    const stamp = celebrating.get(module.id);
    const classes = ["sf-module", "sf-mod-" + definition.id, run ? "sf-module-" + module.state : "sf-module-stock"];
    if (module.current) classes.push("sf-running");
    if (stamp && Date.now() - stamp < 2500) classes.push("sf-celebrate");
    const card = node("section", classes.join(" "));
    card.dataset.renderKey = "module:" + module.id;
    card.style.setProperty("--sf-accent", definition.color);
    card.setAttribute("aria-label", [module.title, run ? stateLabel(module.state) : entityCountText(module)].join(" · "));
    const toggle = node("button", "sf-module-toggle");
    toggle.type = "button";
    toggle.dataset.action = "module:" + module.id;
    toggle.title = text("toggleDetails");
    toggle.disabled = busy;
    toggle.setAttribute("aria-haspopup", "dialog");
    listen(toggle, "click", () => openOverlay("module", module.id, "module:" + module.id));
    const bubble = node("span", "sf-module-icon");
    bubble.appendChild(svgIcon(definition.icon, "sf-icon"));
    const heading = node("span", "sf-module-heading");
    heading.appendChild(node("span", "sf-module-title", module.title));
    if (run) {
      const badge = node("span", "sf-module-state");
      append(badge, module.state === "done" ? svgIcon("check", "sf-check") : node("span", "sf-module-dot"), node("span", "", stateLabel(module.state)));
      heading.appendChild(badge);
    } else heading.appendChild(node("span", "sf-module-sub", entityCountText(module)));
    append(toggle, bubble, heading);
    if (run) toggle.appendChild(ring(module.percent, "sf-ring-small"));
    toggle.appendChild(svgIcon("chevron", "sf-chevron"));
    card.appendChild(toggle);
    if (run) {
      // The bar slot stays reserved so finishing a module never moves the card content.
      const meter = node("div", "sf-module-meter" + (module.state === "done" || module.percent === null ? " sf-meter-off" : ""));
      meter.setAttribute("role", "progressbar");
      meter.setAttribute("aria-label", module.title);
      meter.setAttribute("aria-valuemin", "0");
      meter.setAttribute("aria-valuemax", "100");
      if (module.percent !== null) meter.setAttribute("aria-valuenow", String(module.percent));
      const bar = node("span", "sf-module-bar");
      bar.setAttribute("style", "width:" + (module.percent === null ? 0 : module.percent) + "%");
      meter.appendChild(bar);
      card.appendChild(meter);
    }
    const chips = node("div", "sf-chips");
    module.headline.forEach(entry => chips.appendChild(chip(entry)));
    card.appendChild(chips);
    const more = node("button", "sf-module-more");
    more.type = "button";
    more.dataset.action = "more:" + module.id;
    more.disabled = busy;
    more.setAttribute("aria-haspopup", "dialog");
    listen(more, "click", () => openOverlay("module", module.id, "more:" + module.id));
    append(more, node("span", "", run ? entityCountText(module) : text("allDetails")));
    if (module.issues > 0) {
      const warning = node("span", "sf-more-warn", "⚠ " + number(module.issues));
      warning.title = text("warningsLabel");
      more.appendChild(warning);
    }
    more.appendChild(node("span", "sf-more-link", run ? text("allDetails") : ""));
    card.appendChild(more);
    return card;
  }
  function moduleGrid(modules, empty) {
    const grid = node("div", "sf-modules");
    if (!modules.length) return append(grid, node("p", "sf-help sf-empty-filter", empty));
    modules.forEach(module => grid.appendChild(moduleCard(module)));
    return grid;
  }
  // ---- Detail overlay: inside the add-in, patched like everything else, never moves the cards -----------------
  function overlayShell(title, accent, icon) {
    const backdrop = node("div", "sf-overlay");
    backdrop.id = "sf-overlay";
    listen(backdrop, "click", event => { if (event.target === backdrop) closeOverlay(); });
    const panel = node("div", "sf-overlay-panel");
    panel.setAttribute("role", "dialog");
    panel.setAttribute("aria-modal", "true");
    panel.setAttribute("aria-label", title);
    if (accent) panel.style.setProperty("--sf-accent", accent);
    const head = node("header", "sf-overlay-head");
    const bubble = node("span", "sf-module-icon");
    bubble.appendChild(svgIcon(icon, "sf-icon"));
    const heading = node("div", "sf-overlay-heading");
    heading.appendChild(node("h3", "sf-overlay-title", title));
    const close = node("button", "sf-overlay-close");
    close.type = "button";
    close.dataset.always = "";
    close.setAttribute("aria-label", text("closeLabel"));
    close.title = text("closeLabel");
    close.appendChild(svgIcon("close", "sf-icon"));
    listen(close, "click", closeOverlay);
    append(head, bubble, heading, close);
    const body = node("div", "sf-overlay-body");
    return { backdrop, panel, heading, body, assemble: () => append(backdrop, append(panel, head, body)) };
  }
  function moduleOverlay(module) {
    const shell = overlayShell(module.title, module.definition.color, module.definition.icon);
    const run = module.mode === "run";
    const meta = node("div", "sf-overlay-meta");
    if (run) {
      const badge = node("span", "sf-module-state sf-state-" + module.state);
      append(badge, module.state === "done" ? svgIcon("check", "sf-check") : node("span", "sf-module-dot"), node("span", "", stateLabel(module.state)));
      meta.appendChild(badge);
      if (module.percent !== null) meta.appendChild(ring(module.percent, "sf-ring-small"));
    }
    meta.appendChild(node("span", "sf-module-sub", entityCountText(module)));
    shell.heading.appendChild(meta);
    const grid = node("div", "sf-tile-grid sf-overlay-grid");
    module.entries.filter(entry => !entry.noGenerator).forEach(entry => grid.appendChild(entityTile(entry)));
    shell.body.appendChild(grid);
    const missing = module.entries.filter(entry => entry.noGenerator);
    if (missing.length) {
      // Entities without an executable generator stay visible but never show progress.
      const section = node("section", "sf-overlay-missing");
      section.appendChild(node("h4", "", text("unavailableEntities") + " · " + number(missing.length)));
      const list = node("div", "sf-tile-grid sf-overlay-grid");
      missing.forEach(entry => list.appendChild(entityTile(entry)));
      shell.body.appendChild(append(section, list));
    }
    return shell.assemble();
  }
  function issuesOverlay(analysis) {
    const run = model.selected;
    const shell = overlayShell(run.description, "#d64545", "warn");
    const body = shell.body;
    const list = node("ul", "sf-issue-list");
    const add = (kind, value) => { const item = node("li", "sf-issue sf-issue-" + kind, value); item.dataset.renderKey = "issue:" + list.children.length + value; list.appendChild(item); };
    (run.failedNodes || []).forEach(code => {
      const step = model.steps.find(item => item.node === code);
      add("err", (step ? localized(step.entity) : code) + " · " + text("moduleFailed"));
    });
    if (run.failedBatches > 0) add("err", text("errorsLabel") + " · " + number(run.failedBatches));
    model.steps.filter(step => !step.external).forEach(step => {
      if (step.skipped > 0) add("warn", localized(step.entity) + " · " + text("skippedUnits") + " · " + number(step.skipped));
      if (step.reviewUnits > 0) add("warn", localized(step.entity) + " · " + text("reviewUnits") + " · " + number(step.reviewUnits));
    });
    if (run.reviewBatches > 0) add("warn", text("warningsLabel") + " · " + number(run.reviewBatches));
    if (run.postingSkips) add("warn", run.postingSkips);
    if (run.masterPool) add("info", run.masterPool);
    if (run.pauseRequested) add("info", text("pauseRequested"));
    if (run.cancelRequested) add("warn", text("cancelRequested"));
    body.appendChild(node("p", "sf-quality" + qualityTone(run), localized(run.quality) || text("quality")));
    if (list.children.length) body.appendChild(list);
    return shell.assemble();
  }
  const qualityTone = run => run.qualityCode === 0 ? " sf-success" : run.qualityCode === 1 ? " sf-warning" : run.qualityCode === 2 ? " sf-error" : "";
  function overlayPanel(modules, analysis) {
    if (!overlay || overlay.tab !== activeTab) return null;
    if (overlay.kind === "issues") return analysis && model.hasSelection ? issuesOverlay(analysis) : null;
    const module = modules.find(item => item.id === overlay.id);
    return module ? moduleOverlay(module) : null;
  }
  // ---- Views ---------------------------------------------------------------------------------------------------
  const toneOf = code => [11, 13].includes(code) ? "error" : code === 10 ? "warn" : code === 9 ? "done" : code === 6 ? "run" : "wait";
  function switchTab(key) {
    if (busy || key === activeTab) return;
    tabScroll[activeTab] = root.scrollTop;
    overlay = null;
    activeTab = key;
    render();
    root.scrollTop = tabScroll[key];
    root.querySelector("#sf-tab-" + key)?.focus({ preventScroll: true });
    silent("view", key);
  }
  function tabBar() {
    const list = node("div", "sf-tabs");
    list.setAttribute("role", "tablist");
    list.setAttribute("aria-label", text("navigation"));
    const captions = { generation: ["generationTab", "bolt"], data: ["companyDataTab", "master"], runs: ["runsTab", "list"] };
    tabKeys.forEach((key, index) => {
      const tab = node("button", "sf-tab");
      tab.type = "button";
      tab.id = "sf-tab-" + key;
      tab.setAttribute("role", "tab");
      tab.setAttribute("aria-controls", "sf-tab-panel");
      tab.setAttribute("aria-selected", String(activeTab === key));
      tab.tabIndex = activeTab === key ? 0 : -1;
      tab.disabled = busy;
      append(tab, svgIcon(captions[key][1], "sf-tab-icon"), node("span", "", text(captions[key][0])));
      listen(tab, "click", () => switchTab(key));
      listen(tab, "keydown", event => {
        if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
          event.preventDefault();
          const next = event.key === "Home" ? 0 : event.key === "End" ? tabKeys.length - 1 :
            (index + (event.key === "ArrowRight" ? 1 : tabKeys.length - 1)) % tabKeys.length;
          root.querySelectorAll(".sf-tab")[next].click();
        }
      });
      list.appendChild(tab);
    });
    return list;
  }
  function companyPanel() {
    const company = node("section", "sf-company");
    append(company, node("strong", "", [model.company.name, localized(model.company.industry)].filter(Boolean).join(" · ")),
      node("span", "sf-help", [model.company.chart, localized(model.company.processMode || ""), localized(model.company.status)].filter(Boolean).join(" · ")));
    if (model.company.period) company.appendChild(node("span", "sf-help", model.company.period));
    if (model.company.modules) company.appendChild(node("span", "sf-help", model.company.modules));
    if (model.company.error) {
      const error = node("div", "sf-error", localized(model.company.phase) + ": " + model.company.error);
      error.setAttribute("role", "alert");
      company.appendChild(error);
    }
    return company;
  }
  function eventLine(entry) {
    const step = entry.node ? model.steps.find(item => item.node === entry.node) : undefined;
    const status = localized(entry.status);
    let line = entry.node ? [step ? localized(step.entity) : entry.node, status] : [text("status"), status];
    if (entry.node && entry.units > 0) line = line.concat(text("confirmed") + " " + number(entry.units));
    return line.join(" · ");
  }
  // The newest activity and the current step are visible without opening; the full list opens on demand.
  function feedPanel(run, analysis) {
    const events = run.events || [];
    const feed = node("details", "sf-feed");
    const summary = node("summary", "sf-feed-summary");
    const current = run.currentNode && model.steps.find(step => step.node === run.currentNode);
    if (analysis.runActive) {
      const step = node("span", "sf-feed-step");
      append(step, node("span", "sf-feed-label", text("currentStepLabel")),
        node("strong", "", current ? localized(current.entity) : run.currentNode || text("noCurrentStep")));
      summary.appendChild(step);
    }
    const last = node("span", "sf-feed-last");
    append(last, svgIcon("activity", "sf-pill-icon"), node("span", "sf-feed-label", text("activityTitle")),
      node("span", "sf-feed-text", events.length ? timeText(events[0].at) + " · " + eventLine(events[0]) : text("noActivity")));
    summary.appendChild(last);
    feed.appendChild(summary);
    const list = node("ul", "sf-feed-list");
    events.forEach(entry => {
      const item = node("li", "sf-feed-item");
      item.dataset.renderKey = "event:" + entry.at + ":" + entry.node + ":" + entry.status;
      append(item, node("time", "sf-feed-time", timeText(entry.at)), node("span", "", eventLine(entry)));
      list.appendChild(item);
    });
    feed.appendChild(list);
    return feed;
  }
  // Compact overall status: one title row, one row of status pills, one live row.
  function heroPanel(analysis) {
    const run = model.selected;
    const code = run.statusCode;
    const tone = toneOf(code);
    const section = node("section", "sf-run sf-hero sf-tone-" + tone);
    const gauge = ring(analysis.percent, "sf-ring-hero");
    gauge.setAttribute("role", "img");
    gauge.setAttribute("aria-label", text("overallProgress"));
    gauge.title = text("overallProgress");
    const body = node("div", "sf-hero-body");
    const top = node("div", "sf-hero-top");
    const industry = model.company?.industry ? localized(model.company.industry) : run.profile;
    append(top, node("h2", "", run.description), node("span", "sf-status sf-status-" + tone, localized(run.status)),
      node("span", "sf-run-meta", [text("hdrIndustry") + ": " + industry, localized(run.processMode)].join(" · ")),
      node("span", "sf-quality" + qualityTone(run), localized(run.quality) || text("quality")));
    if (run.pauseRequested) top.appendChild(node("span", "sf-flag", text("pauseRequested")));
    if (run.cancelRequested) top.appendChild(node("span", "sf-flag sf-warning", text("cancelRequested")));
    const details = node("button", "sf-button sf-link", text("allDetails"));
    details.type = "button";
    details.dataset.action = "issues:details";
    details.dataset.always = "";
    listen(details, "click", () => openOverlay("issues", "", "issues:details"));
    top.appendChild(details);
    const pills = node("div", "sf-hero-pills");
    pills.appendChild(pill("ok", "check", append(node("strong"), countNode(analysis.done, "/" + analysis.total)), text("moduleDone"), text("modulesDone")));
    if (analysis.runActive || analysis.running > 0)
      pills.appendChild(pill("run", "activity", append(node("strong"), countNode(analysis.running)), text("moduleOpen"), text("modulesRunning")));
    if (analysis.waiting > 0)
      pills.appendChild(pill("wait", "wait", append(node("strong"), countNode(analysis.waiting)), text("moduleWaiting"), text("modulesWaiting")));
    [["err", "error", analysis.errors, "errorsLabel"], ["warn", "warn", analysis.warnings, "warningsLabel"]].forEach(([kind, icon, value, key]) => {
      if (value <= 0) return;
      const element = pill(kind, icon, append(node("strong"), countNode(value)), text(key), text(key), "issues:" + kind);
      element.dataset.always = "";
      element.disabled = false;
      listen(element, "click", () => openOverlay("issues", "", "issues:" + kind));
      pills.appendChild(element);
    });
    const elapsed = node("strong", "sf-elapsed", elapsedText(run.startedIso, run.finishedIso));
    if (run.startedIso) elapsed.dataset.start = run.startedIso;
    if (run.startedIso && run.finishedIso) elapsed.dataset.end = run.finishedIso;
    pills.appendChild(pill("time", "timer", elapsed, "", text("elapsedLabel")));
    append(body, top, pills);
    if ([4, 5].includes(code) && run.earliest) body.appendChild(node("span", "sf-run-meta", text("earliest") + " · " + run.earliest));
    body.appendChild(feedPanel(run, analysis));
    return append(section, gauge, body);
  }
  const passes = (module, filter) => filter === "all" || (filter === "warn" ? module.issues > 0 || module.state === "review" :
    module.state === filter);
  function filterBar(modules) {
    if (modules.length < 5) { if (genFilter !== "all") genFilter = "all"; if (genQuery) genQuery = ""; return null; }
    const bar = node("div", "sf-filterbar");
    const chips = node("div", "sf-fchips");
    [["all", "filterAll"], ["open", "moduleOpen"], ["done", "moduleDone"], ["waiting", "moduleWaiting"], ["warn", "filterWarnings"], ["error", "filterErrors"]].forEach(([key, label]) => {
      const total = modules.filter(module => passes(module, key)).length;
      if (!total && key !== "all" && genFilter !== key) return;
      const chipButton = node("button", "sf-fchip");
      chipButton.type = "button";
      chipButton.dataset.action = "filter:" + key;
      chipButton.dataset.always = "";
      chipButton.setAttribute("aria-pressed", String(genFilter === key));
      append(chipButton, node("span", "", text(label)), node("strong", "", number(total)));
      listen(chipButton, "click", () => { genFilter = key; render(); });
      chips.appendChild(chipButton);
    });
    bar.appendChild(chips);
    if (modules.length >= 9) bar.appendChild(searchBox(genQuery, value => { genQuery = value; }));
    return bar;
  }
  function modulePanel(view, analysis, filtered) {
    const section = node("section", "sf-steps");
    if (view.companyProgress)
      append(section, node("h3", "", text("companyProgress")), node("p", "sf-scope", text("selectedRunScope") + " · " + view.selected.description));
    if (!view.steps.length) return append(section, node("p", "sf-help", text("noSteps")));
    const shown = filtered || analysis.modules;
    return append(section, moduleGrid(shown, text("noMatch")));
  }
  function generationView(main) {
    if (model.company) main.appendChild(companyPanel());
    if (!model.hasSelection) {
      if (model.company?.steps) {
        const view = { selected: { description: model.company.industry }, steps: model.company.steps, companyProgress: true, runStock: { metrics: [] } };
        const analysis = analyse(view);
        shownModules = analysis.modules;
        main.appendChild(modulePanel(view, analysis));
        return analysis;
      }
      main.appendChild(node("section", "sf-empty", text("empty")));
      return undefined;
    }
    const analysis = analyse(model);
    shownModules = analysis.modules;
    append(main, selector(), heroPanel(analysis));
    const bar = filterBar(analysis.modules);
    if (bar) main.appendChild(bar);
    const filtered = analysis.modules.filter(module => passes(module, genFilter) && matchesQuery(module, genQuery));
    append(main, modulePanel(model, analysis, filtered), actionPanel());
    return analysis;
  }
  function dataView(main) {
    const stock = model.stock;
    const section = node("section", "sf-stock");
    if (!stock) return main.appendChild(section);
    const bar = node("div", "sf-data-bar");
    const scope = stock.entireCompany ? "company" : "generated";
    bar.appendChild(stockSelect("stockScope", "stockScope", [["generated", text("stockGenerated")], ["company", text("stockCompany")]], scope));
    if (!stock.entireCompany && model.runs.length) {
      const options = [["", text("stockAllRuns")]];
      const runs = model.runs.slice();
      if (model.hasSelection && !runs.some(run => run.id === model.selected.id)) runs.push(model.selected);
      runs.forEach(run => options.push([run.id, run.description + " · " + run.createdAt + " · " + run.id.slice(-7, -1)]));
      if (stock.runId && !runs.some(run => run.id === stock.runId)) options.push([stock.runId, stock.runId]);
      bar.appendChild(stockSelect("stockRun", "stockRun", options, stock.runId));
    }
    const modules = stock.all ? analyseStock(stock) : [];
    shownModules = modules;
    if (modules.length >= 9) bar.appendChild(searchBox(dataQuery, value => { dataQuery = value; }));
    else dataQuery = "";
    const scopeText = stock.entireCompany ? text("stockCompany") :
      stock.runId ? text("selectedRunScope") + " · " + (model.runs.find(run => run.id === stock.runId)?.description || stock.runId) :
      text("stockGenerated") + " · " + text("stockAllRuns");
    append(section, bar, node("p", "sf-scope", scopeText));
    if (!stock.all) section.appendChild(node("p", "sf-help", text("dataLoading")));
    else section.appendChild(moduleGrid(modules.filter(module => matchesQuery(module, dataQuery)), text("noMatch")));
    main.appendChild(section);
    return undefined;
  }
  function pickRun(id) {
    const finish = () => {
      activeTab = "generation";
      overlay = null;
      render();
      root.scrollTop = 0;
      silent("view", "generation");
    };
    if (model.hasSelection && model.selected.id === id) { switchTab("generation"); return; }
    request("select", id, finish);
  }
  function runList() {
    const section = node("section", "sf-run-list");
    const runs = model.runs.slice();
    if (model.hasSelection && !runs.some(run => run.id === model.selected.id)) runs.push(model.selected);
    runs.forEach(run => {
      const selected = model.hasSelection && run.id === model.selected.id;
      const row = node("button", "sf-run-row" + (selected ? " sf-run-selected" : ""));
      row.type = "button";
      row.dataset.action = "pick:" + run.id;
      row.dataset.renderKey = "run:" + run.id;
      row.disabled = busy;
      if (selected) row.setAttribute("aria-current", "true");
      const main = node("span", "sf-run-main");
      const industry = model.company?.runId === run.id && model.company.industry ? localized(model.company.industry) : run.profile;
      const setup = model.company?.runId === run.id ? model.company.chart : "";
      append(main, node("strong", "", run.description),
        node("span", "sf-run-sub", [industry, localized(run.processMode), setup].filter(Boolean).join(" · ")));
      const tone = toneOf(run.statusCode);
      const started = run.startedIso ? new Date(run.startedIso).toLocaleString(model.locale || undefined) : run.createdAt;
      const clock = node("span", "sf-run-clock");
      const elapsed = node("span", "sf-elapsed", elapsedText(run.startedIso, run.finishedIso));
      if (run.startedIso) elapsed.dataset.start = run.startedIso;
      if (run.startedIso && run.finishedIso) elapsed.dataset.end = run.finishedIso;
      append(clock, node("span", "sf-run-when", (run.startedIso ? text("started") + " " : "") + started), elapsed);
      const marks = node("span", "sf-run-marks");
      if (run.failedBatches > 0) marks.appendChild(pill("err", "error", append(node("strong"), countNode(run.failedBatches)), "", text("errorsLabel")));
      if (run.reviewBatches > 0) marks.appendChild(pill("warn", "warn", append(node("strong"), countNode(run.reviewBatches)), "", text("warningsLabel")));
      append(row, main, node("span", "sf-status sf-status-" + tone, localized(run.status)), clock, marks);
      listen(row, "click", () => pickRun(run.id));
      section.appendChild(row);
    });
    return section;
  }
  function runsView(main) {
    if (model.company) main.appendChild(companyPanel());
    if (!model.company) main.appendChild(summaryPanel());
    if (model.hasSelection || model.runs.length) append(main, runList());
    else append(main, node("section", "sf-empty", text("empty")));
    if (model.hasSelection) main.appendChild(actionPanel());
  }
  function actionPanel() {
    const section = node("section", "sf-action-groups");
    const run = model.selected;
    let primary = "run";
    if ([11, 13].includes(run.statusCode)) primary = "primaryErrors";
    else if ([4, 5, 6, 8].includes(run.statusCode)) primary = "primaryProgress";
    else if ([9, 10].includes(run.statusCode)) primary = "primaryResults";
    else if (run.canStart && (!run.hasExecution || run.statusCode === 3)) primary = "primaryStart";
    section.appendChild(button(primary, "sf-button sf-primary", primary === "run" ? "run" : "primary", run.id));
    const diagnostics = node("details", "sf-diagnostics");
    diagnostics.appendChild(node("summary", "sf-section-label", text("diagnostics")));
    Object.entries(groups).forEach(([key, commands]) => {
      const group = node("div", "sf-action-group");
      append(group, node("h3", "", text(key)));
      const actions = node("div", "sf-buttons");
      commands.forEach(command => {
        const status = model.selected.statusCode;
        const hasExecution = model.selected.hasExecution;
        const meaningful = command === "prepare" ? !hasExecution :
          command === "schedule" ? hasExecution && status === 3 :
          ["pause", "cancel", "apply"].includes(command) ? hasExecution && [3, 4, 5, 6].includes(status) :
          command === "resume" ? hasExecution && (status === 7 || model.selected.canResume) : true;
        if (meaningful) actions.appendChild(button(command, command === "cancel" ? "sf-button sf-danger" : "sf-button", command, model.selected.id));
      });
      if (actions.children.length) {
        group.appendChild(actions);
        diagnostics.appendChild(group);
      }
    });
    const facts = node("dl", "sf-facts");
    [["completedBatches", number(run.completedBatches) + " / " + number(run.totalBatches)],
      ["started", run.started], ["finished", run.finished]].forEach(([key, value]) => {
      if (value) facts.appendChild(append(node("div"), node("dt", "", text(key)), node("dd", "", value)));
    });
    diagnostics.appendChild(facts);
    model.steps.forEach(step => {
      if (step.external) diagnostics.appendChild(node("p", "sf-help", localized(step.entity) + " · " + text("external") + " · " + localized(step.state)));
      else diagnostics.appendChild(node("p", "sf-help", localized(step.entity) + " · " + text("artifacts") + " " + number(step.artifacts)));
    });
    section.appendChild(diagnostics);
    return section;
  }
  let shownModules = [];
  function render() {
    if (!root || !model) return;
    const focused = document.activeElement && document.activeElement.dataset.action;
    const scrollTop = root.scrollTop;
    root.className = "sf-dashboard";
    root.setAttribute("aria-label", text("title"));
    const toolbar = node("div", "sf-toolbar");
    const links = node("div", "sf-buttons");
    if (!model.company && (activeTab !== "runs" || !model.summaryViews?.templates?.canOpen))
      links.appendChild(button("scenarios", "sf-button", "scenarios"));
    if (model.company) links.appendChild(button("workflow", "sf-button sf-primary", "workflow"));
    else links.appendChild(button("setup", "sf-button", "setup"));
    links.appendChild(button("exportPackage", "sf-button", "exportPackage"));
    append(toolbar, tabBar(), links, button("refresh", "sf-button sf-refresh", "refresh"));
    const main = node("main", "sf-main");
    main.id = "sf-tab-panel";
    main.dataset.renderKey = "main:" + activeTab;
    main.setAttribute("role", "tabpanel");
    main.setAttribute("aria-labelledby", "sf-tab-" + activeTab);
    shownModules = [];
    let analysis;
    if (activeTab === "generation") analysis = generationView(main);
    else if (activeTab === "data") dataView(main);
    else runsView(main);
    if (model.company) {
      const experts = node("details", "sf-experts");
      append(experts, node("summary", "", text("expertTools")), button("setup", "sf-button", "setup"), button("scenarios", "sf-button", "scenarios"), button("runs", "sf-button", "runs"));
      if (model.company.hasJob) experts.appendChild(button("companyQueue", "sf-button", "companyQueue"));
      main.appendChild(experts);
    }
    const footer = node("footer", "sf-footer");
    const feedback = node("div", "sf-feedback");
    feedback.setAttribute("role", "status");
    feedback.setAttribute("aria-live", "polite");
    append(footer, feedback, node("span", "sf-help", text("updated") + " " + model.readAt));
    const layer = overlayPanel(shownModules, analysis);
    if (overlay && !layer) overlay = null;
    patchChildren(root, layer ? [toolbar, main, footer, layer] : [toolbar, main, footer]);
    animateCounts();
    setBusy(busy);
    if (focused && !(overlay && !root.querySelector(".sf-overlay :focus"))) {
      const target = Array.from(root.querySelectorAll("button[data-action]")).find(element => element.dataset.action === focused);
      if (target && !target.disabled && document.activeElement !== target) target.focus({ preventScroll: true });
    }
    root.scrollTop = scrollTop;
  }
  // Server payloads only carry what the active view needs; keep the last result of the other views.
  function mergeCache(incoming) {
    const previous = model;
    if (incoming.view && incoming.view !== "generation" && incoming.hasSelection && !incoming.runStock && previous?.selected?.id === incoming.selected.id)
      incoming.runStock = previous.runStock;
    if (incoming.stock && incoming.view !== "data" && !incoming.stock.all && cache.all && previous?.stock?.entireCompany === incoming.stock.entireCompany &&
        previous?.stock?.runId === incoming.stock.runId) {
      incoming.stock.metrics = cache.all;
      incoming.stock.all = true;
    }
    if (incoming.stock?.all) cache.all = incoming.stock.metrics;
    if (incoming.view && incoming.view !== "runs" && previous)
      incoming.runs.forEach(run => {
        const old = previous.runs.find(item => item.id === run.id);
        if (old && run.failedBatches === undefined && old.failedBatches !== undefined)
          ["failedBatches", "reviewBatches", "statusCode", "startedIso", "finishedIso"].forEach(key => { if (run[key] === undefined) run[key] = old[key]; });
      });
  }
  window.SetDashboard = function (payload) {
    try {
      const incoming = JSON.parse(payload);
      if (incoming.schemaVersion !== 1 || !incoming.texts || !incoming.summary || !Array.isArray(incoming.runs) ||
          (incoming.hasSelection && (!incoming.selected || !Array.isArray(incoming.steps))) ||
          (incoming.stock && (!Array.isArray(incoming.stock.groups) || !Array.isArray(incoming.stock.metrics)))) throw new Error("schema");
      mergeCache(incoming);
      model = incoming;
      if (model.language) document.documentElement.lang = model.language;
      failed = false;
      render();
    } catch (_) {
      failed = true;
      setBusy(false);
    }
  };
  window.AutoRefreshFailed = function () {
    failed = true;
    const feedback = root?.querySelector(".sf-feedback");
    if (feedback && model) feedback.textContent = text("error");
  };
  window.BCSFStart = function () {
    root = document.getElementById("controlAddIn");
    if (!root) return;
    root.tabIndex = 0;
    root.setAttribute("role", "region");
    root.setAttribute("aria-busy", "true");
    busy = true;
    clearTimeout(pollTimer);
    // One document listener for the whole page lifetime, even if BC recreates the add-in.
    if (!keyBound) {
      keyBound = true;
      document.addEventListener("keydown", event => { if (event.key === "Escape" && overlay) { event.preventDefault(); closeOverlay(); } });
    }
    invoke("Ready", [], () => { setBusy(false); scheduleRefresh(); }, () => { failed = true; setBusy(false); scheduleRefresh(); });
  };
}());
