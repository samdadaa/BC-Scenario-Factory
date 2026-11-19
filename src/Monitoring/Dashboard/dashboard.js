/* Bundled, dependency-free Business Central control add-in. All UI text comes from AL/XLIFF. */
(function () {
  "use strict";
  let root;
  let model;
  let busy = false;
  let failed = false;
  let stockFocus = "";
  const navigation = ["scenarios", "monitor", "setup"];
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
    element.addEventListener("click", () => request(action || key, runId || ""));
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
    if (busy) return;
    failed = false;
    setBusy(true);
    if (action.startsWith("stock"))
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
  function navigationPanel() {
    const nav = node("nav", "sf-nav");
    nav.setAttribute("aria-label", text("navigation"));
    append(nav, node("div", "sf-nav-title", text("navigation")));
    navigation.forEach((key, index) => {
      const item = button(key, "sf-nav-link", key);
      const count = node("span", "sf-nav-index", String(index + 1).padStart(2, "0"));
      item.prepend(count);
      item.title = text(key + "Hint");
      nav.appendChild(item);
    });
    append(nav, node("p", "sf-nav-note", text("requirements")));
    return nav;
  }
  function summaryPanel() {
    const summary = node("section", "sf-summary");
    [["templateCount", "templates"], ["runCount", "runs"], ["activeCount", "active"], ["reviewCount", "review"]].forEach(([label, key]) => {
      const card = node("div", "sf-stat sf-stat-" + key);
      append(card, node("div", "sf-stat-label", text(label)), node("div", "sf-stat-value", number(model.summary[key])));
      summary.appendChild(card);
    });
    return summary;
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
    select.addEventListener("change", () => request(command, select.value));
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
      group.addEventListener("click", () => request("stockGroup", entry.key));
      (index < 4 ? topGroups : extraGroups).appendChild(group);
    });
    const extra = node("details", "sf-stock-extra");
    extra.appendChild(node("summary", "sf-section-label", text("stockMore")));
    extra.appendChild(extraGroups);
    const loading = node("span", "sf-help sf-stock-loading");
    loading.setAttribute("role", "status");
    append(section, title, toolbar, loading, topGroups, extra);
    if (!stock.group) return append(section, node("p", "sf-help", text("stockChoose")));

    const list = node("ul", "sf-stock-list");
    list.setAttribute("aria-label", localized(stock.groups.find(group => group.key === stock.group)?.caption || ""));
    stock.metrics.forEach(metric => {
      const row = node("li", "sf-stock-row");
      const caption = localized(metric.caption);
      const hasCount = Number.isSafeInteger(metric.count) && metric.count >= 0;
      const value = hasCount ? number(metric.count) : "";
      row.appendChild(node("span", "sf-stock-label", caption));
      if (metric.canOpen && hasCount && metric.count > 0) {
        const open = node("button", "sf-button sf-stock-number", value);
        open.type = "button";
        open.title = text("stockOpen");
        open.dataset.stockFocus = "metric:" + metric.key;
        open.disabled = busy;
        open.setAttribute("aria-label", caption + " · " + value + " · " + text("stockOpen"));
        open.addEventListener("click", () => request("stockOpen", metric.key));
        row.appendChild(open);
      } else if (hasCount) {
        const count = node("span", "sf-stock-number", value);
        count.setAttribute("aria-label", text("stockCount") + " · " + value);
        row.appendChild(count);
      }
      if (metric.status) row.appendChild(node("span", "sf-help sf-stock-status", localized(metric.status)));
      list.appendChild(row);
    });
    return append(section, list);
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
    select.addEventListener("change", () => request("select", select.value));
    append(section, label, select, node("p", "sf-help", text("window")));
    return section;
  }
  function runPanel() {
    const section = node("section", "sf-run");
    const run = model.selected;
    const head = node("div", "sf-run-heading");
    const heading = node("div");
    append(heading, node("div", "sf-section-label", text("choose")), node("h2", "", run.description));
    append(head, heading, node("span", "sf-status", localized(run.status)));
    append(section, head, node("div", "sf-run-meta", [run.profile, localized(run.processMode)].join(" · ")));
    const flags = node("div", "sf-flags");
    if (run.pauseRequested) flags.appendChild(node("span", "sf-flag", text("pauseRequested")));
    if (run.cancelRequested) flags.appendChild(node("span", "sf-flag sf-warning", text("cancelRequested")));
    section.appendChild(flags);
    const facts = node("dl", "sf-facts");
    [["completedBatches", number(run.completedBatches) + " / " + number(run.totalBatches)], ["earliest", run.earliest], ["started", run.started], ["finished", run.finished]].forEach(([key, value]) => {
      const fact = node("div");
      append(fact, node("dt", "", text(key)), node("dd", "", value || text("notRecorded")));
      facts.appendChild(fact);
    });
    append(section, facts, node("p", "sf-quality", localized(run.quality) || text("quality")));
    return section;
  }
  function stepPanel() {
    const section = node("section", "sf-steps");
    append(section, node("h3", "", text("steps")));
    if (!model.steps.length) return append(section, node("p", "sf-help", text("noSteps")));
    const scroll = node("div", "sf-table-scroll");
    scroll.tabIndex = 0;
    scroll.setAttribute("role", "region");
    scroll.setAttribute("aria-label", text("steps"));
    const table = node("table", "sf-table");
    const thead = node("thead");
    const heading = node("tr");
    ["entity", "target", "confirmed", "remaining", "artifacts", "status"].forEach(key => {
      const th = node("th", "", text(key)); th.scope = "col"; heading.appendChild(th);
    });
    thead.appendChild(heading);
    const tbody = node("tbody");
    model.steps.forEach(step => {
      const row = node("tr");
      const identity = node("td");
      append(identity, node("strong", "", localized(step.entity)), node("span", "sf-cell-sub", localized(step.module)));
      row.appendChild(identity);
      [step.external ? null : step.target, step.external ? null : step.confirmed, step.external ? null : step.remaining, step.external ? null : step.artifacts].forEach(value => row.appendChild(node("td", "sf-number", value === null ? "—" : number(value))));
      const status = node("td", "sf-step-state");
      append(status, node("span", "", step.external ? text("external") : localized(step.state)));
      if (!step.external) {
        const progress = node("progress", "sf-progress");
        progress.max = 100;
        progress.value = Math.max(0, Math.min(100, step.percent));
        progress.setAttribute("aria-label", localized(step.entity) + " · " + text("confirmed"));
        progress.textContent = number(step.percent) + "%";
        status.appendChild(progress);
      }
      row.appendChild(status);
      tbody.appendChild(row);
    });
    append(table, thead, tbody);
    scroll.appendChild(table);
    return append(section, scroll);
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
      group.appendChild(actions);
      diagnostics.appendChild(group);
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
    root.replaceChildren();
    root.className = "sf-dashboard";
    root.setAttribute("aria-label", text("title"));
    const hero = node("header", "sf-hero");
    const title = node("div");
    append(title, node("p", "sf-eyebrow", text("eyebrow")), node("h1", "", text("title")), node("p", "sf-subtitle", text("subtitle")));
    const heroActions = node("div", "sf-hero-actions");
    const firstAction = model.initialized ? "scenarios" : "setup";
    append(heroActions, button(firstAction, "sf-button sf-primary", firstAction), button("refresh", "sf-button sf-refresh", "refresh"));
    append(hero, title, heroActions);
    const shell = node("div", "sf-shell");
    const main = node("main", "sf-main");
    main.appendChild(summaryPanel());
    if (model.stock) main.appendChild(stockPanel(model.stock));
    if (model.hasSelection) append(main, selector(), runPanel(), stepPanel(), actionPanel());
    else {
      const empty = node("section", "sf-empty");
      append(empty, node("h2", "", text("empty")), button(firstAction, "sf-button sf-primary", firstAction));
      main.appendChild(empty);
    }
    append(shell, navigationPanel(), main);
    const footer = node("footer", "sf-footer");
    const feedback = node("div", "sf-feedback");
    feedback.setAttribute("role", "status");
    feedback.setAttribute("aria-live", "polite");
    append(footer, feedback, node("span", "sf-help", text("updated") + " " + model.readAt));
    append(root, hero, shell, footer);
    const diagnostics = root.querySelector(".sf-diagnostics");
    if (diagnostics) diagnostics.open = diagnosticsOpen;
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
  window.BCSFStart = function () {
    root = document.getElementById("controlAddIn");
    if (!root) return;
    root.tabIndex = 0;
    root.setAttribute("role", "region");
    root.setAttribute("aria-busy", "true");
    busy = true;
    invoke("Ready", [], () => setBusy(false), () => { failed = true; setBusy(false); });
  };
}());
