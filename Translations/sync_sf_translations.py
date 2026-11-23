#!/usr/bin/env python3
"""Bind the SF-016/SF-017 translations to the IDs emitted by the local AL compiler.

Run from the project with: python3 Translations/sync_sf_translations.py
The first AL package build must have regenerated the .g.xlf. Rebuild the package
after this script succeeds. It never guesses IDs or drops existing translations
for entries still present in the generated catalogue.
"""
from copy import deepcopy
from pathlib import Path
import re
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
NAME = "BC Scenario Factory"
NS = "urn:oasis:names:tc:xliff:document:1.2"
Q = lambda name: f"{{{NS}}}{name}"
ET.register_namespace("", NS)
CULTURES = ("de-DE", "de-AT", "de-CH", "de-LI", "de-LU", "en-US")

DE = {
    "The saved batch counts do not match the prepared run.": "Die gespeicherten Paketzahlen stimmen nicht mit dem vorbereiteten Lauf überein.",
    "A posted invoice or credit memo is missing its registered general ledger or partner ledger evidence.": "Für eine gebuchte Rechnung oder Gutschrift fehlen registrierte Sach-, Debitoren- oder Kreditorenposten.",
    "A generated result references a missing or invalid parent.": "Ein erzeugtes Ergebnis verweist auf einen fehlenden oder ungültigen übergeordneten Eintrag.",
    "An optional check returned an invalid or repeated warning code.": "Eine optionale Prüfung hat einen ungültigen oder doppelten Warnungscode zurückgegeben.",
    "Shows the persisted execution state, including the result of the final validation.": "Zeigt den gespeicherten Ausführungsstatus einschließlich des Ergebnisses der Abschlussprüfung.",
    "Use existing BC setup": "Vorhandene BC-Einrichtung verwenden",
    "SKR03 test chart": "SKR03-Testkontenplan",
    "SKR04 test chart": "SKR04-Testkontenplan",
    "Validation Failed": "Validierung fehlgeschlagen",
    "%1 / reference year %2 / package version %3": "%1 / Bezugsjahr %2 / Paketversion %3",
    "Based on DATEV standard charts 2026 (SKR03 article 11174, SKR04 article 11175).": "Basiert auf den DATEV-Standardkontenrahmen 2026 (SKR03 Art. 11174, SKR04 Art. 11175).",
    "For sandbox trade tests only. This is not a complete DATEV chart or statutory report.": "Nur für Handelstests in der Sandbox. Kein vollständiger DATEV-Kontenrahmen und kein gesetzlicher Abschluss.",
    "Required standard read or write permission is missing.": "Erforderliche Lese- oder Schreibrechte für die BC-Standardeinrichtung fehlen.",
    "Review the standard BC setup or permissions before applying. No existing setup will be overwritten.": "Prüfen Sie vor dem Anwenden die BC-Standardeinrichtung oder die Berechtigungen. Bestehende Einrichtung wird nicht überschrieben.",
    "A different chart or package version is already recorded in this company.": "Für diesen Mandanten ist bereits ein anderer Kontenrahmen oder eine andere Paketversion erfasst.",
    "The company already has G/L entries. Initial installation or creation of missing package records is blocked.": "Der Mandant hat bereits Sachposten. Eine Erstanwendung oder das Ergänzen fehlender Paketdatensätze ist gesperrt.",
    "Reuse existing record": "Vorhandenen Datensatz wiederverwenden",
    "No change": "Keine Änderung",
    "Existing record conflicts in field %1.": "Der vorhandene Datensatz hat einen Konflikt im Feld %1.",
    "Setup changed since review. %1 has a conflict in field %2. No package changes were kept.": "Die Einrichtung hat sich seit der Prüfung geändert. %1 hat einen Konflikt im Feld %2. Es wurden keine Paketänderungen gespeichert.",
    "The finance package cannot be applied. Reopen the preview and resolve the blocking findings.": "Das Finanzpaket kann nicht angewendet werden. Öffnen Sie die Vorschau erneut und beheben Sie die blockierenden Befunde.",
    "Create missing record": "Fehlenden Datensatz anlegen",
    "Create only when you explicitly apply the reviewed package.": "Wird erst angelegt, wenn Sie das geprüfte Paket ausdrücklich anwenden.",
    "The report definition contains additional rows or columns outside the package.": "Die Berichtsdefinition enthält zusätzliche Zeilen oder Spalten, die nicht zum Paket gehören.",
    "Required standard setup is missing, not visible or not usable on the selected date.": "Die erforderliche Standardeinrichtung fehlt, ist nicht sichtbar oder am gewählten Datum nicht verwendbar.",
    "Apply the selected finance test package in this company before capturing the run.": "Wenden Sie das gewählte Finanztestpaket in diesem Mandanten an, bevor Sie den Lauf erfassen.",
    "Scenario Factory domestic 19% test setup": "Scenario Factory Testeinrichtung Inland 19 %",
    "Total Assets": "Summe Aktiva",
    "Total Liabilities and Equity": "Summe Passiva einschließlich Eigenkapital",
    "Result (credit balance is negative)": "Ergebnis (Habensaldo ist negativ)",
    "Scenario Factory Test Balance Sheet": "Scenario Factory Testbilanz",
    "Scenario Factory Test Income Statement": "Scenario Factory Test-GuV",
    "Actual Amount": "Istbetrag",
    "Bank": "Bank",
    "Trade Receivables": "Forderungen aus Lieferungen und Leistungen",
    "Trade Payables": "Verbindlichkeiten aus Lieferungen und Leistungen",
    "Merchandise Inventory": "Warenbestand",
    "Input VAT 19%": "Vorsteuer 19 %",
    "Output VAT 19%": "Umsatzsteuer 19 %",
    "Share Capital": "Gezeichnetes Kapital",
    "Domestic Sales 19%": "Inlandserlöse 19 %",
    "Merchandise Purchases 19%": "Wareneingang 19 %",
    "Merchandise Cost and Stock Change": "Wareneinsatz und Bestandsveränderung",
    "Other Operating Expense": "Sonstiger betrieblicher Aufwand",
    "Office Supplies": "Bürobedarf",
    "Test Inventory Interim": "Test-Zwischenkonto Lagerbestand",
    "Test Inventory Accrual": "Test-Zwischenkonto Lagerabgrenzung",
    "Preview Finance Setup": "Finanzeinrichtung prüfen",
    "Reviews existing finance setup or previews a test chart and its posting setup before any changes.": "Prüft die bestehende Finanzeinrichtung oder zeigt den Testkontenplan und die Buchungseinrichtung vor Änderungen an.",
    "Captured Finance Setup": "Erfasste Finanzeinrichtung",
    "Shows the finance setup mode in the immutable run snapshot.": "Zeigt die Auswahl der Finanzeinrichtung aus der unveränderlichen Laufaufnahme.",
    "Finance Reference Year": "Bezugsjahr des Kontenplans",
    "Shows the captured test chart reference year. It is empty for existing BC setup.": "Zeigt das erfasste Bezugsjahr des Testkontenplans. Bei vorhandener BC-Einrichtung bleibt es leer.",
    "Finance Package Version": "Version des Finanzpakets",
    "Shows the version of the applied finance package at capture.": "Zeigt die Version des bei der Lauferfassung angewendeten Finanzpakets.",
    "Finance Setup Preview": "Vorschau Finanzeinrichtung",
    "Apply Test Package": "Testpaket anwenden",
    "Applies the reviewed package in the current approved sandbox company after confirmation and a fresh conflict check.": "Wendet das geprüfte Paket nach Bestätigung und erneuter Konfliktprüfung im aktuell freigegebenen Sandbox-Mandanten an.",
    "Apply %1 in the current company %2? Existing records will not be overwritten.": "%1 im aktuellen Mandanten %2 anwenden? Vorhandene Datensätze werden nicht überschrieben.",
    "Select Finance Setup": "Finanzeinrichtung auswählen",
    "Finance Setup": "Finanzeinrichtung",
    "Selects existing setup or a versioned test chart for the current test company.": "Wählt die bestehende Einrichtung oder einen versionierten Testkontenplan für den aktuellen Testmandanten aus.",
    "Applied Finance Package": "Angewendetes Finanzpaket",
    "Primary Key": "Primärschlüssel",
    "Finance Package": "Finanzpaket",
    "Reference Year": "Bezugsjahr",
    "Version": "Version",
    "Final validation is not recorded for this run.": "Für diesen Lauf ist keine Abschlussprüfung gespeichert.",
    "Batches confirmed": "Pakete bestätigt",
    "Shows the recorded result of final validation. Drill down to see individual checks.": "Zeigt das gespeicherte Ergebnis der Abschlussprüfung. Öffnen Sie die Details für die einzelnen Prüfungen.",
    "The selected finance package could not be captured. Review the applied package before creating a run.": "Das ausgewählte Finanzpaket konnte nicht erfasst werden. Prüfen Sie das angewendete Paket, bevor Sie einen Lauf anlegen.",
    "Specifies which finance setup the scenario expects. A test package must already be applied in this company.": "Gibt die für das Szenario erwartete Finanzeinrichtung an. Ein Testpaket muss in diesem Mandanten bereits angewendet sein.",
    "Not validated": "Nicht validiert",
    "Passed": "Bestanden",
    "Warning": "Warnung",
    "Error": "Fehler",
    "Validation Results": "Validierungsergebnisse",
    "Validation Result": "Validierungsergebnis",
    "Run Id": "Lauf-ID",
    "Specifies the captured run.": "Gibt den erfassten Lauf an.",
    "Batch Id": "Paket-ID",
    "Specifies the validated batch. An empty ID identifies the run summary.": "Gibt das validierte Paket an. Eine leere ID kennzeichnet die Zusammenfassung des Laufs.",
    "Rule Code": "Regelcode",
    "Specifies the stable technical validation rule.": "Gibt die stabile technische Validierungsregel an.",
    "Severity": "Schweregrad",
    "Specifies whether the check passed, issued a warning or failed.": "Gibt an, ob die Prüfung bestanden wurde, eine Warnung ausgegeben hat oder fehlgeschlagen ist.",
    "Node Code": "Schrittcode",
    "Specifies the planned step associated with the check.": "Gibt den geplanten Schritt an, zu dem die Prüfung gehört.",
    "Checked At": "Geprüft am",
    "Specifies when the check was recorded.": "Gibt an, wann die Prüfung gespeichert wurde.",
    "Expected Units": "Erwartete Einheiten",
    "Specifies the expected logical units for this batch.": "Gibt die erwarteten logischen Einheiten für dieses Paket an.",
    "Reported Units": "Gemeldete Einheiten",
    "Specifies the recorded logical units before this check.": "Gibt die vor dieser Prüfung gespeicherten logischen Einheiten an.",
}

def source(unit):
    return unit.findtext(Q("source"), "")

def note(unit):
    return next((n.text for n in unit.findall(Q("note")) if n.get("from") == "Xliff Generator"), "")

def sync():
    DE.update(json.loads((ROOT / "sf020.de.json").read_text(encoding="utf-8")))
    DE.update(json.loads((ROOT / "sf046.de.json").read_text(encoding="utf-8")))
    DE.update(json.loads((ROOT / "sf047.de.json").read_text(encoding="utf-8")))
    DE.update(json.loads((ROOT / "sf048.de.json").read_text(encoding="utf-8")))
    DE.update(json.loads((ROOT / "sf049.de.json").read_text(encoding="utf-8")))
    DE.update(json.loads((ROOT / "sf050.de.json").read_text(encoding="utf-8")))
    generated = ET.parse(ROOT / f"{NAME}.g.xlf")
    units = list(generated.iter(Q("trans-unit")))
    gen_ids = [u.attrib["id"] for u in units]
    if len(gen_ids) != len(set(gen_ids)):
        raise SystemExit("Duplicate compiler IDs. No translation files were changed.")
    has_finance = any("Enum BCSF Finance Mode - EnumValue SKR04" in (note(u) or "") or source(u) == "SKR04 test chart" for u in units)
    has_validation = any(source(u) == "An optional check returned an invalid or repeated warning code." for u in units)
    if not has_finance or not has_validation:
        raise SystemExit("Build the AL project first so the compiler emits the new SF-016 and SF-017 IDs. No translation files were changed.")
    master = ET.parse(ROOT / f"{NAME}.de-DE.xlf")
    original = {u.attrib["id"]: u for u in master.iter(Q("trans-unit"))}
    original_order = {uid: position for position, uid in enumerate(original)}
    german = {}
    missing = set()
    placeholders = re.compile(r"%[1-9]\d*")
    for u in units:
        uid = u.attrib["id"]
        text = source(u)
        old = original.get(uid)
        target = (old.findtext(Q("target")) if old is not None and source(old) == text else None) or DE.get(text)
        if not target:
            missing.add(text)
            continue
        if sorted(placeholders.findall(text)) != sorted(placeholders.findall(target)):
            raise SystemExit(f"Placeholder mismatch for {text!r}. No translation files were changed.")
        width = int(u.get("maxWidth", "0"))
        if width and max(len(text), len(target)) > width:
            raise SystemExit(f"Translation exceeds maxWidth for {text!r}. No translation files were changed.")
        german[uid] = target
    if missing:
        raise SystemExit("Untranslated compiler strings (no files changed):\n" + "\n".join(sorted(missing)))
    for culture in CULTURES:
        tree = deepcopy(generated)
        tree.find(Q("file")).set("target-language", culture)
        for u in tree.iter(Q("trans-unit")):
            previous = u.find(Q("target"))
            if previous is not None:
                u.remove(previous)
            target = ET.Element(Q("target"), {"state": "translated"})
            target.text = source(u) if culture == "en-US" else german[u.attrib["id"]]
            u.insert(1, target)
        if culture != "en-US":
            group = tree.find(f".//{Q('group')}")
            # Keep the maintained master's order to avoid unrelated compiler-order churn.
            generated_order = {u.get("id"): i for i, u in enumerate(group)}
            group[:] = sorted(group, key=lambda u: original_order.get(u.get("id"), len(original_order) + generated_order[u.get("id")]))
        ET.indent(tree, space="  ")
        if culture != "en-US":
            group = tree.find(f".//{Q('group')}")
            def content(unit):
                return unit.attrib, [(c.tag, c.attrib, c.text) for c in unit]
            for position, unit in enumerate(group):
                old = original.get(unit.get("id"))
                if old is not None and content(old) == content(unit):
                    group[position] = deepcopy(old)
        tree.write(ROOT / f"{NAME}.{culture}.xlf", xml_declaration=True, encoding="utf-8")
    print(f"{len(units)} compiler IDs synchronized across {len(CULTURES)} target languages.")

if __name__ == "__main__":
    sync()
