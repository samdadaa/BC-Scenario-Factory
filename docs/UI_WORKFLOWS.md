# Bedienkonzept, Seiten und Dashboard

**Status:** Entwurf, noch keine AL-Pages vorhanden.

## Navigation (sechs Bereiche)

1. **Dashboard:** laufende/historische Runs, Mengen, Status, Fehler und Validierung.
2. **Szenarien:** neue Vorlagen, Kopie, Versionierung, Detailkonfiguration.
3. **Branchenprofile:** auswählbare Profile, Erklärung von Regeln und Voraussetzungen.
4. **Generatoren:** Module, Entitäten, Zielmengen, Generatorstatus, Abhängigkeiten.
5. **Verarbeitungsläufe:** Queue-Einträge, Steps/Batches, Retry/Resume, Protokolle.
6. **Datenprüfung:** Soll/Ist, Beziehungen, fachliche Checks, Warnungen, Berichte.

## Wizard (5 Schritte)

1. **Branche + Nutzungsziel:** z. B. Handel/Demo, Schulung, Functional, Performance; Erklärung des Profils.
2. **Module:** Finance, Sales, Purchasing, Inventory; Abhängigkeiten automatisch sichtbar und begründet (kein stillschweigendes Einrichten).
3. **Mengen + Regeln:** pro Entität eingeben; Presets; Zeitraum, Werte-/Kundenprofile, Seed, Variationsregeln, Quote offener Fälle.
4. **Prozessumfang:** Setup+Stamm; +ungebuchte Belege; +gebuchte Belege; +Folgeprozesse; Risiken von Buchungen deutlich darstellen.
5. **Preflight + Zeitplanung:** Setup-Diff, Rechte und Sandbox, voraussichtliche Entitäten/Batches, Freigaben; sofort oder terminierter Queue-Start.

## Dashboard – Sollwerte

**Kacheln:** Laufstatus; Datensätze Soll/Ist; Schritte fertig/gesamt; Fehl-/Warnbatches; letzte Aktivität/Startzeit. **Modultabelle:** Modul, Entität, Soll, Ist (validiert vs. erstellt!), Zustand, letzte Fehlermeldung, Link zum Schritt. **Detail:** Queue/Batchhistorie, Validierungsbefunde, Fehlerklassifikation und Aktionen. Filter auf Run, Profil, Branche, Status und Ersteller.

## Benutzeraktionen und Schutz

- Alle destruktiven/geschäftlich wirksamen Aktionen verlangen Preflight und explizite Bestätigung.
- Kein 'Fertig' anzeigen, wenn nur Daten erzeugt, aber die Validierung noch nicht abgeschlossen ist.
- Retry darf nur fehlgeschlagene/ungeklärte Batches bearbeiten, ohne doppelte Buchungen zu riskieren.
- Bereits gebuchte Daten nicht pauschal löschen; neue Sandbox/Firma als bevorzugter Reset-Pfad.
- BC-Standardschrift, native Page/FactBox/Action-Muster statt unnötigem JS-ControlAddIn; Accessibility, Labels, Tooltips.

## Erstes durchgängiges Nutzungsszenario

Berater erstellt 'Großhandel – Demo', wählt Finance+Sales+Purchasing+Inventory, 100 Debitoren, 40 Kreditoren, 120 Artikel, 70 Einkaufs- und 150 Verkaufsaufträge. Entscheidet 'gebuchte Belege', führt Preflight aus und startet über Queue. Dashboard zeigt Schritt für Schritt die Erzeugung, erklärt Blocker und weist nach Abschluss zugehörige Rechnungen/Posten nach. Werte sind Beispiele, keine standardmäßig zugesicherten Mengen.
