# Bedienkonzept, Seiten und Dashboard

**Aktueller Stand ab 1.0.2.0:** Der reale Bedienweg ist in [Mandanteneinrichtung und Vorlagenstart](COMPANY_INITIALIZATION.md) beschrieben. Ältere Angaben zu Finanzauswahl je Vorlage, Vorschaufenster, Wizard, parallelen Lauflisten und Dashboard-Host sind historische Nachweise. Entfernte Objekt-IDs bleiben unbenutzt.

**Status:** JavaScript-Dashboard mit eigenem Role-Center und wiederverwendbarer CardPart sowie fünfstufiger Wizard implementiert, **Zur Prüfung**. Fachgeneratoren und echte BC-Laufzeitabnahme ausstehend. Details: [MONITORING_WIZARD.md](MONITORING_WIZARD.md).

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

SF-009/SF-010: Laufkarte → „Einrichtungsvorprüfung anzeigen“ zeigt aktuelle Blocker/Einrichtungsmaßnahmen; „Synthetische Eingangswerte anzeigen“ zeigt ein lesendes Beispiel aus eingefrorenen Regeln. Keine Freigabe-/Start-/Apply-Wirkung. [SETUP_SEED.md](SETUP_SEED.md).

SF-011/SF-012 ergänzen auf der Laufkarte „Ausführungspakete vorbereiten“, „Vorbereitete Ausführung planen“ mit Startdialog/Bestätigung sowie persistente Ausführungs-/Paket-/Ergebnislisten. Erfasster Anfangsstatus und aktueller Ausführungsstatus sind ausdrücklich getrennt. Der Browser kann nach erfolgreichem Queue-Start geschlossen werden; wirkliche Queue-Laufzeitprüfung steht aus und aktuelle fachliche Startblocker bleiben wirksam. [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md).

SF-013: Laufkarte mit „Pause anfordern“, „Abbruch anfordern“, „Ausstehende Anforderungen anwenden“ und „Ab Checkpoints fortsetzen“, dazu sichtbare Anforderungsflags getrennt vom aktuellen Status. Paketliste mit Einplanungszähler/Voraufgabe, „Nicht übernommenes Fehlerpaket wiederholen“, „Unterbrochene Übernahme prüfen“ und „Bestätigten Checkpoint abgleichen“. Bestätigungen erläutern Grenzen; Abbruch nimmt keine Ergebnisse zurück, Reconciliation ist kein erneuter Generatorlauf. [RECOVERY.md](RECOVERY.md).

## Implementiert SF-014/SF-015 – 16.11.2026

BC-Suche → Scenario Factory Dashboard; Run auswählen, FactBox lesen, Schrittfortschritt/Pakete/Statushistorie/Standardprotokolle öffnen. Keine Ausführung beim Öffnen. Vorlagenliste → Neues Szenario mit Assistent bzw. Mit Assistent planen → fünf Schritte → explizit erfassen → Plan und Setup prüfen → Prüfplan speichern → frühesten Start und Sandboxfreigabe wählen → bestätigen. Start bleibt bei aktuellen Generator-/Setupblockern gesperrt. Schließen bewahrt gespeicherte Vorlagen und erfasste Läufe. Gesamtqualität ausdrücklich ausstehend bis SF-016. [Vertrag und Grenzen](MONITORING_WIZARD.md), **Zur Prüfung**.

## Aktueller zentraler Einstieg – 16.11.2026

Nach separat freizugebender Installation Profil BC Scenario Factory wählen → JS-Dashboard im App-Role-Center. Neues Szenario startet die explizite Vorlagenanlage mit Wizard. Acht Navigationseinstiege und 19 Runaktionen stehen direkt bereit. Bestehende Laufkarten-/Wizardlinks öffnen denselben JS-Arbeitsplatz als große Hostseite mit Runkontext. Weitere erweiterbare Role-Center erhalten dieselbe CardPart per PageExtension; Personalisierung allein kann keinen bislang nicht deklarierten Part einfügen. [Vertrag, Einbau und Grenzen](DASHBOARD_EMBEDDING.md). Status **Zur Prüfung**, echte BC-Abnahme offen.


## SF-016/SF-017 – 18.11.2026

Die Laufübersicht zeigt die gespeicherte Qualität; deren Drilldown öffnet rungefilterte Befunde mit Pflichtkennzeichen und Soll-/Istzahlen. Ohne Summary „Nicht validiert“. Pflichtfehler verhindern Completed, Warnungen bleiben sichtbar.

Factory-Einrichtung → „Finanzeinrichtung prüfen“ → Modus auswählen → Vorschau → ausschließlich bei freier Vorschau „Testpaket anwenden“ bestätigen. Im Szenario oder im Wizard-Schritt 4 denselben Finanzmodus wählen; erfasster Modus/Jahr/Version auf der Laufkarte lesbar. Apply erzeugt keine Firma/Belege/Jobs. [Bedienvertrag und Standardbuchungs-Abnahme](VALIDATION_FINANCE.md).


## SF-018 – 18.11.2026

Szenariokarte bzw. Wizard-Schritt 3 → „Synthetische Partner“: vorhandenes Land, bei Existing explizite Buchungsgruppen, Zahlungsbedingungen je Klasse/B2C, B2C-Prozent und Kreditlimits auswählen. SKR-Testpakete verwenden ihre Paketgruppen und unterstützen in diesem Vertrag DE. Danach neuer Snapshot, neuer Plan, Einrichtungsvorprüfung und vorhandene explizite Queuefreigabe. Alte blockierte Pläne werden nicht verändert. Reine Kunden-/Lieferantenläufe haben nun echte Implementierungen; weitere Fachziele können weiterhin blockiert sein. [Bedienung, Standardkontakte und offene Abnahme](PARTNER_GENERATION.md).


## SF-044 – aktueller Dashboardweg

**Daten** zeigt den gewählten Bestand im Kachelraster, **Läufe** die Laufwahl mit Fortschrittskacheln und nächster Aktion. Die Filter beider Ansichten bleiben unabhängig. Vorlagen sind je Reiter einmal direkt erreichbar. Diagnose bleibt eingeklappt. [Bedienung und Sandbox-Prüfschritte](DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026), Status **Zur Prüfung**. Frühere Tabellen-/Seitenleistenbeschreibungen dieses Dokuments sind historische Planstände.
