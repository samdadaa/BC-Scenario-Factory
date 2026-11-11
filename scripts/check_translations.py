#!/usr/bin/env python3
"""Check complete XLIFF coverage; optionally derive region variants and English from the maintained German master."""

import argparse
import copy
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "Translations"
APP_NAME = "BC Scenario Factory"
NAMESPACE = "urn:oasis:names:tc:xliff:document:1.2"
NS = {"x": NAMESPACE}
GERMAN_CULTURES = ("de-DE", "de-AT", "de-CH", "de-LI", "de-LU")
ET.register_namespace("", NAMESPACE)


def load(path):
    tree = ET.parse(path)
    units = tree.findall(".//x:trans-unit", NS)
    by_id = {unit.attrib["id"]: unit for unit in units}
    if len(units) != len(by_id):
        raise ValueError(f"Duplicate translation IDs in {path.name}")
    return tree, by_id


def source_text(unit):
    return "".join(unit.find("x:source", NS).itertext())


def validate(tree, units, generated, culture):
    file_element = tree.find("x:file", NS)
    if file_element.get("target-language") != culture or file_element.get("original") != APP_NAME:
        raise ValueError(f"Incorrect language or app identity: {culture}")
    if file_element.get("source-language") != "en-US":
        raise ValueError(f"Incorrect source language: {culture}")
    if units.keys() != generated.keys():
        raise ValueError(f"Translation IDs do not match generated source: {culture}")
    for unit_id, unit in units.items():
        source = source_text(unit)
        if source != source_text(generated[unit_id]):
            raise ValueError(f"Stale source in {culture}: {unit_id}")
        target = unit.find("x:target", NS)
        if target is None or not "".join(target.itertext()).strip():
            raise ValueError(f"Missing translation in {culture}: {source}")
        translated = "".join(target.itertext())
        if sorted(re.findall(r"%[1-9]\d*", source)) != sorted(re.findall(r"%[1-9]\d*", translated)):
            raise ValueError(f"Changed placeholders in {culture}: {source}")
        if target.get("state") != "translated":
            raise ValueError(f"Unreviewed translation state in {culture}: {source}")
        maximum = int(unit.get("maxWidth", "0"))
        if maximum and len(translated) > maximum:
            raise ValueError(f"Translation exceeds maximum width in {culture}: {source}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sync", action="store_true", help="Derive regional German files and en-US from the complete master.")
    args = parser.parse_args()
    generated_tree, generated = load(DIRECTORY / f"{APP_NAME}.g.xlf")
    german_tree, german = load(DIRECTORY / f"{APP_NAME}.de-DE.xlf")
    validate(german_tree, german, generated, "de-DE")
    if args.sync:
        for culture in GERMAN_CULTURES[1:]:
            tree = copy.deepcopy(german_tree)
            tree.find("x:file", NS).set("target-language", culture)
            ET.indent(tree, space="  ")
            tree.write(DIRECTORY / f"{APP_NAME}.{culture}.xlf", encoding="utf-8", xml_declaration=True)
        tree = copy.deepcopy(generated_tree)
        tree.find("x:file", NS).set("target-language", "en-US")
        for unit in tree.findall(".//x:trans-unit", NS):
            old = unit.find("x:target", NS)
            if old is not None:
                unit.remove(old)
            target = ET.Element(f"{{{NAMESPACE}}}target", {"state": "translated"})
            target.text = source_text(unit)
            unit.insert(1, target)
        ET.indent(tree, space="  ")
        tree.write(DIRECTORY / f"{APP_NAME}.en-US.xlf", encoding="utf-8", xml_declaration=True)
    for culture in (*GERMAN_CULTURES, "en-US"):
        tree, units = load(DIRECTORY / f"{APP_NAME}.{culture}.xlf")
        validate(tree, units, generated, culture)
        if culture.startswith("de-") and any(
            "".join(units[key].find("x:target", NS).itertext()) != "".join(german[key].find("x:target", NS).itertext())
            for key in units
        ):
            raise ValueError(f"Regional file differs from German master: {culture}; run --sync")
        if culture == "en-US" and any(
            "".join(unit.find("x:target", NS).itertext()) != source_text(unit) for unit in units.values()
        ):
            raise ValueError("English targets must equal the English source")
    print(f"PASS: {len(generated)} units fully covered in five German cultures and en-US; IDs, sources, placeholders and widths valid.")


if __name__ == "__main__":
    main()
