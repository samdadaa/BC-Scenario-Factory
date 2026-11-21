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
  const refreshInterval = 2000;
  const listen = (element, event, handler) => {
    element.sfHandlers = element.sfHandlers || {};
    element.sfHandlers[event] = handler;
    element.addEventListener(event, handler);
  };
  let activeTab = "data";
  const tabScroll = { data: 0, runs: 0 };
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
    root.querySelectorAll("button, select").forEach(element => { element.disabled = value; });
    const feedback = root.querySelector(".sf-feedback");
    if (feedback && model) feedback.textContent = value ? text("busy") : failed ? text("error") : "";
    const stockLoading = root.querySelector(".sf-stock-loading");
    if (stockLoading && model) stockLoading.textContent = value ? text("busy") : "";
  }
  function invoke(event, args, success, failure) {
    const nav = window.Microsoft && window.Microsoft.Dynamics && window.Microsoft.Dynamics.NAV;
    if (!nav || typeof nav.InvokeExtensibilityMethod !== "function") { failure(); return; }
    try {
      nav.InvokeExtensibilityMethod(event, args, false, success, failure);
    } catch (_) { failure(); }
  }
  function request(action, runId) {
    if (polling) { queuedAction = [action, runId]; return; }
    if (busy) return;
    failed = false;
    setBusy(true);
    if (action.startsWith("stock") || action === "runOpen")
      stockFocus = document.activeElement?.dataset?.stockFocus || "";
    invoke("Command", [action, runId], () => {
      setBusy(false);
      restoreStockFocus();
    }, () => {
      failed = true;
      if (model) render();
      setBusy(false);
      restoreStockFocus();
    });
  }
  function scheduleRefresh() {
    clearTimeout(pollTimer);
    pollTimer = setTimeout(() => {
      scheduleRefresh();
      if (!model || busy || polling || document.hidden || document.activeElement?.tagName === "SELECT") return;
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
      const [action, runId] = queuedAction;
      queuedAction = undefined;
      request(action, runId);
    }
  }
  // Keep live nodes, focus, open details and selection stable. Only changed attributes/text are written.
  function domKey(element) {
    if (element.nodeType !== 1) return "";
    return element.id || element.dataset.renderKey || element.dataset.stockFocus || element.dataset.action ||
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
    patchChildren(current, Array.from(next.childNodes));
    if (current.tagName === "OPTION") current.selected = next.selected;
    if (current.tagName === "SELECT" && current.value !== next.value) current.value = next.value;
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
  function tabs() {
    const list = node("div", "sf-tabs");
    list.setAttribute("role", "tablist");
    list.setAttribute("aria-label", text("navigation"));
    ["data", "runs"].forEach((key, index) => {
      const tab = node("button", "sf-tab", text(key === "data" ? "dataTab" : "runsTab"));
      tab.type = "button";
      tab.id = "sf-tab-" + key;
      tab.setAttribute("role", "tab");
      tab.setAttribute("aria-controls", "sf-tab-panel");
      tab.setAttribute("aria-selected", String(activeTab === key));
      tab.tabIndex = activeTab === key ? 0 : -1;
      tab.disabled = busy;
      listen(tab, "click", () => {
        if (busy) return;
        tabScroll[activeTab] = root.scrollTop;
        activeTab = key;
        render();
        root.scrollTop = tabScroll[key];
        root.querySelectorAll(".sf-tab")[index].focus({ preventScroll: true });
      });
      listen(tab, "keydown", event => {
        if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
          event.preventDefault();
          const next = event.key === "Home" ? 0 : event.key === "End" ? 1 : 1 - index;
          root.querySelectorAll(".sf-tab")[next].click();
        }
      });
      list.appendChild(tab);
    });
    return list;
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
    const selected = Array.from(root.querySelectorAll("[data-stock-focus]"))
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

  function stockPanel(stock) {
    const section = node("section", "sf-stock");
    const title = node("h2", "", text("stockTitle"));
    title.id = "sf-stock-heading";
    section.setAttribute("aria-labelledby", title.id);
    const toolbar = node("div", "sf-stock-toolbar");
    const scope = stock.entireCompany ? "company" : "generated";
    toolbar.appendChild(stockSelect("stockScope", "stockScope", [
      ["generated", text("stockGenerated")],
      ["company", text("stockCompany")]
    ], scope));
    if (!stock.entireCompany && model.runs.length) {
      const options = [["", text("stockAllRuns")]];
      const runs = model.runs.slice();
      if (model.hasSelection && !runs.some(run => run.id === model.selected.id)) runs.push(model.selected);
      runs.forEach(run => options.push([run.id,
        run.description + " · " + run.createdAt + " · " + run.id.slice(-7, -1)]));
      if (stock.runId && !runs.some(run => run.id === stock.runId))
        options.push([stock.runId, stock.runId]);
      toolbar.appendChild(stockSelect("stockRun", "stockRun", options, stock.runId));
    }
    const topGroups = node("div", "sf-stock-groups");
    const extraGroups = node("div", "sf-stock-groups");
    stock.groups.forEach((entry, index) => {
      const group = node("button", "sf-button sf-stock-group", localized(entry.caption));
      group.type = "button";
      group.dataset.stockFocus = "group:" + entry.key;
      group.setAttribute("aria-pressed", String(stock.group === entry.key));
      group.disabled = busy;
      listen(group, "click", () => request("stockGroup", entry.key));
      (index < 4 ? topGroups : extraGroups).appendChild(group);
    });
    const extra = node("details", "sf-stock-extra");
    extra.appendChild(node("summary", "sf-section-label", text("stockMore")));
    extra.appendChild(extraGroups);
    const loading = node("span", "sf-help sf-stock-loading");
    loading.setAttribute("role", "status");
    append(section, title, toolbar, loading, topGroups, extra);
    if (!stock.group) return append(section, node("p", "sf-help", text("stockChoose")));

    const scopeText = stock.entireCompany ? text("stockCompany") :
      stock.runId ? text("selectedRunScope") + " · " +
        (model.runs.find(run => run.id === stock.runId)?.description || stock.runId) :
        text("stockGenerated") + " · " + text("stockAllRuns");
    const scopeLabel = node("p", "sf-scope", scopeText);
    const list = node("div", "sf-stock-list sf-tile-grid");
    list.setAttribute("aria-label", localized(stock.groups.find(group => group.key === stock.group)?.caption || ""));
    const unavailable = node("details", "sf-stock-unavailable");
    const missing = stock.metrics.filter(metric => !stock.entireCompany && metric.noGenerator);
    unavailable.appendChild(node("summary", "", text("unavailableEntities") + " · " + number(missing.length)));
    const missingList = node("div", "sf-tile-grid");
    stock.metrics.forEach(metric => {
      (missing.includes(metric) ? missingList : list).appendChild(metricTile(metric, "stockOpen"));
    });
    append(section, scopeLabel, list);
    if (missing.length) section.appendChild(append(unavailable, missingList));
    return section;
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
  function runPanel() {
    const section = node("section", "sf-run");
    const run = model.selected;
    const head = node("div", "sf-run-heading");
    const heading = node("div");
    append(heading, node("h2", "", run.description));
    const tone = [11, 13].includes(run.statusCode) ? " sf-error" : run.statusCode === 9 ? " sf-success" : run.statusCode === 10 ? " sf-warning" : "";
    append(head, heading, node("span", "sf-status" + tone, localized(run.status)));
    append(section, head, node("div", "sf-run-meta", [run.profile, localized(run.processMode)].join(" · ")));
    const flags = node("div", "sf-flags");
    if (run.pauseRequested) flags.appendChild(node("span", "sf-flag", text("pauseRequested")));
    if (run.cancelRequested) flags.appendChild(node("span", "sf-flag sf-warning", text("cancelRequested")));
    section.appendChild(flags);
    if ([4, 5].includes(run.statusCode) && run.earliest)
      section.appendChild(node("p", "sf-scope", text("earliest") + " · " + run.earliest));
    const quality = node("p", "sf-quality" + (run.qualityCode === 0 ? " sf-success" :
      run.qualityCode === 1 ? " sf-warning" : run.qualityCode === 2 ? " sf-error" : ""), localized(run.quality) || text("quality"));
    section.appendChild(quality);
    return section;
  }
  function stepPanel(view = model) {
    const section = node("section", "sf-steps");
    append(section, node("h3", "", text(view.companyProgress ? "companyProgress" : "steps")),
      node("p", "sf-scope", text("selectedRunScope") + " · " + view.selected.description));
    if (!view.steps.length) return append(section, node("p", "sf-help", text("noSteps")));
    const grid = node("div", "sf-tile-grid");
    const results = view.runStock?.metrics || [];
    const matched = new Set();
    view.steps.filter(step => !step.external).forEach(step => {
      const key = step.entityCode === "CUSTOMER" ? "customer" : step.entityCode === "VENDOR" ? "vendor" : step.entityCode === "ITEM" ? "item" : step.entityCode === "SALES.QUOTE" ? "sales/quote" : step.entityCode === "SALES.ORDER" ? "sales/order" : step.entityCode === "SALES.INVOICE" ? "sales/invoice" : step.entityCode === "PURCHASE.ORDER" ? "purchase/order" : "";
      const metric = results.find(item => item.key === key);
      const safe = metric?.canOpen && metric.count > 0 && metric.count === step.confirmed;
      if (metric && metric.count === step.confirmed) matched.add(key);
      const card = node(safe ? "button" : "div", "sf-tile sf-step");
      card.dataset.renderKey = "step:" + step.entityCode;
      append(card, node("span", "sf-stock-label", localized(step.entity)),
        node("strong", "sf-step-value", number(step.confirmed) + " / " + number(step.target)),
        node("span", "sf-help", text("created") + " / " + text("target") + " · " + text("remaining") + " " + number(step.remaining)),
        node("span", "sf-step-state", step.complete ? text("completed") : localized(step.state)));
      if (safe) {
        card.type = "button";
        card.dataset.stockFocus = "result:" + key;
        card.title = text("stockOpen");
        card.disabled = busy;
        listen(card, "click", () => request("runOpen", key));
      }
      grid.appendChild(card);
    });
    // Live result counts are separate from confirmed work. Never relabel artifact totals as addresses.
    results.filter(metric => !matched.has(metric.key) &&
      (metric.count >= 0 || (!Number.isSafeInteger(metric.count) && !metric.noGenerator)))
      .forEach(metric => grid.appendChild(metricTile(metric, "runOpen")));
    section.appendChild(grid);
    return section;
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
  function render() {
    if (!root || !model) return;
    const focused = document.activeElement && document.activeElement.dataset.action;
    const scrollTop = root.scrollTop;
    const diagnosticsOpen = root.querySelector(".sf-diagnostics")?.open || false;
    const extraStockOpen = root.querySelector(".sf-stock-extra")?.open || false;
    const unavailableOpen = root.querySelector(".sf-stock-unavailable")?.open || false;
    root.className = "sf-dashboard";
    root.setAttribute("aria-label", text("title"));
    const toolbar = node("div", "sf-toolbar");
    const links = node("div", "sf-buttons");
    if (!model.company && (activeTab === "data" || !model.summaryViews?.templates?.canOpen))
      links.appendChild(button("scenarios", "sf-button", "scenarios"));
    if (model.company) links.appendChild(button("workflow", "sf-button sf-primary", "workflow"));
    else links.appendChild(button("setup", "sf-button", "setup"));
    append(toolbar, tabs(), links, button("refresh", "sf-button sf-refresh", "refresh"));
    const main = node("main", "sf-main");
    main.id = "sf-tab-panel";
    main.setAttribute("role", "tabpanel");
    main.setAttribute("aria-labelledby", "sf-tab-" + activeTab);
    if (model.company) {
      const company = node("section", "sf-company");
      append(company, node("strong", "", [model.company.name, localized(model.company.industry)].filter(Boolean).join(" · ")),
        node("span", "sf-help", [model.company.chart, localized(model.company.processMode || ""), localized(model.company.status)].filter(Boolean).join(" · ")));
      if (model.company.error) {
        const error = node("div", "sf-error", localized(model.company.phase) + ": " + model.company.error);
        error.setAttribute("role", "alert");
        company.appendChild(error);
      }
      main.appendChild(company);
    }
    if (activeTab === "data") {
      if (model.company?.steps)
        main.appendChild(stepPanel({ selected: {description: model.company.industry}, steps: model.company.steps,
          companyProgress: true, runStock: model.selected?.id === model.company.runId ? model.runStock : {metrics: []} }));
      else if (model.company?.runId && model.selected?.id === model.company.runId)
        main.appendChild(stepPanel());
      if (model.stock) main.appendChild(stockPanel(model.stock));
    } else {
      if (!model.company) main.appendChild(summaryPanel());
      if (model.hasSelection) append(main, selector(), runPanel(), stepPanel(), actionPanel());
      else append(main, node("section", "sf-empty", text("empty")));
    }
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
    patchChildren(root, [toolbar, main, footer]);
    const diagnostics = root.querySelector(".sf-diagnostics");
    if (diagnostics) diagnostics.open = diagnosticsOpen;
    const unavailable = root.querySelector(".sf-stock-unavailable");
    if (unavailable) unavailable.open = unavailableOpen;
    const extraStock = root.querySelector(".sf-stock-extra");
    if (extraStock) extraStock.open = extraStockOpen ||
      model.stock.groups.slice(4).some(group => group.key === model.stock.group);
    setBusy(busy);
    if (focused) {
      const target = Array.from(root.querySelectorAll("button[data-action]")).find(element => element.dataset.action === focused);
      if (target && !target.disabled) target.focus({ preventScroll: true });
    }
    root.scrollTop = scrollTop;
  }
  window.SetDashboard = function (payload) {
    try {
      const incoming = JSON.parse(payload);
      if (incoming.schemaVersion !== 1 || !incoming.texts || !incoming.summary || !Array.isArray(incoming.runs) ||
          (incoming.hasSelection && (!incoming.selected || !Array.isArray(incoming.steps))) ||
          (incoming.stock && (!Array.isArray(incoming.stock.groups) || !Array.isArray(incoming.stock.metrics)))) throw new Error("schema");
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
    invoke("Ready", [], () => { setBusy(false); scheduleRefresh(); }, () => { failed = true; setBusy(false); scheduleRefresh(); });
  };
}());
