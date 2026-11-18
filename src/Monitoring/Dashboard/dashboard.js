/* Bundled, dependency-free Business Central control add-in. All UI text comes from AL/XLIFF. */
(function () {
  "use strict";
  let root;
  let model;
  let busy = false;
  let failed = false;
  const navigation = ["scenarios", "runs", "executions", "allBatches", "allRecords", "catalog", "setup", "monitor"];
  const groups = {
    planGroup: ["run", "scenario", "wizard", "plan", "savePlan", "readiness", "preflight", "synthetic"],
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
    invoke("Command", [action, runId], () => setBusy(false), () => {
      failed = true;
      if (model) render();
      setBusy(false);
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
    append(section, head, node("div", "sf-run-meta", [run.profile, run.processMode, run.id].join(" · ")));
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
    append(section, facts, node("p", "sf-quality", run.quality || text("quality")));
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
      append(identity, node("strong", "", step.entity), node("span", "sf-cell-sub", step.module));
      row.appendChild(identity);
      [step.external ? null : step.target, step.external ? null : step.confirmed, step.external ? null : step.remaining, step.external ? null : step.artifacts].forEach(value => row.appendChild(node("td", "sf-number", value === null ? "—" : number(value))));
      const status = node("td", "sf-step-state");
      append(status, node("span", "", step.external ? text("external") : localized(step.state)));
      if (!step.external) {
        const progress = node("progress", "sf-progress");
        progress.max = 100;
        progress.value = Math.max(0, Math.min(100, step.percent));
        progress.setAttribute("aria-label", step.entity + " · " + text("confirmed"));
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
    Object.entries(groups).forEach(([key, commands]) => {
      const group = node("div", "sf-action-group");
      append(group, node("h3", "", text(key)));
      const actions = node("div", "sf-buttons");
      commands.forEach(command => actions.appendChild(button(command, command === "cancel" ? "sf-button sf-danger" : "sf-button", command, model.selected.id)));
      group.appendChild(actions);
      section.appendChild(group);
    });
    return section;
  }
  function render() {
    if (!root || !model) return;
    const focused = document.activeElement && document.activeElement.dataset.action;
    const scrollTop = root.scrollTop;
    root.replaceChildren();
    root.className = "sf-dashboard";
    root.setAttribute("aria-label", text("title"));
    const hero = node("header", "sf-hero");
    const title = node("div");
    append(title, node("p", "sf-eyebrow", text("eyebrow")), node("h1", "", text("title")), node("p", "sf-subtitle", text("subtitle")));
    const heroActions = node("div", "sf-hero-actions");
    append(heroActions, button("new", "sf-button sf-primary", "new"), button("refresh", "sf-button sf-refresh", "refresh"));
    append(hero, title, heroActions);
    const shell = node("div", "sf-shell");
    const main = node("main", "sf-main");
    main.appendChild(summaryPanel());
    if (model.hasSelection) append(main, selector(), runPanel(), stepPanel(), actionPanel());
    else {
      const empty = node("section", "sf-empty");
      append(empty, node("h2", "", text("empty")), button("new", "sf-button sf-primary", "new"));
      main.appendChild(empty);
    }
    append(shell, navigationPanel(), main);
    const footer = node("footer", "sf-footer");
    const feedback = node("div", "sf-feedback");
    feedback.setAttribute("role", "status");
    feedback.setAttribute("aria-live", "polite");
    append(footer, feedback, node("span", "sf-help", text("updated") + " " + model.readAt));
    append(root, hero, shell, footer);
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
          (incoming.hasSelection && (!incoming.selected || !Array.isArray(incoming.steps)))) throw new Error("schema");
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
