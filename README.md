**SF-055 / SF-056 · Zur Prüfung (24.11.2026):** Projekte (Stammdaten, Aufgaben, Planungszeilen, Verbrauch über Projektbuchblatt, ungebuchte/teil-/vollgebuchte Abrechnung) und Planungsvorschläge über die Standard-Dispositionsengine im Folgeprozess, mit Vorprüfung, dokumentiertem Skip, additiver Foundation und Dashboardmodulen. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [SF-055](docs/review/SF055_PRUEFBERICHT.md), [SF-056](docs/review/SF056_PRUEFBERICHT.md).

**SF-054 · Zur Prüfung (23.11.2026):** Montage im Folgeprozess für gebuchte Einkäufe: synthetischer Montageartikel mit Stückliste (und Ressource), ungebuchter sowie voll/teilweise gebuchter Montageauftrag über Standard-Posting, Vorprüfung mit kontrolliertem Skip, additive Foundation (Montageeinrichtung, Herkunftscodes, Matrix ohne Geschäftsbuchungsgruppe). App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](docs/review/SF054_PRUEFBERICHT.md).

**SF-053 · Zur Prüfung (23.11.2026):** Lagerbewegungen ohne WMS im Folgeprozess für alle Artikelzeilen gebuchter Einkäufe: Zugang/Abgang per Artikelbuchblatt, Inventurdifferenz und Umlagerung über Transitlager, mit Vorprüfung (freier, nicht reservierter Bestand, Dimensionen), kontrolliertem Skip und Bestandsprüfung je Lagerort/Datum. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](docs/review/SF053_PRUEFBERICHT.md).

**SF-052 / SF-039-Teil · Erledigt, Teilumfang (nativ abgenommen 24.11.2026):** Gutschriften (ungebucht, gebucht teil/voll) zu gebuchten Rechnungen im Folgeprozess sowie ein synthetisches Bankkonto pro neu angelegtem Debitor/Kreditor. App-Version unverändert. **Nativ vom Nutzer getestet und abgenommen (24.11.2026).** [Bericht und Prüffälle](docs/review/SF052_PRUEFBERICHT.md).

**SF-051 · App 1.0.12.0 · Erledigt, Teilumfang (nativ abgenommen 24.11.2026):** Neue Zahlungsstufe-Captures planen je gebuchter Rechnung deterministisch: vollständig (≈55 %), zwei Raten mit Ausgleich (≈20 %), Teilzahlung mit offenem Rest (≈15 %) oder bewusst offen (≈10 %). Zahlungsrabatt/-toleranz, Gutschriften und Sammelausgleich sind **nicht** umgesetzt. Nativ vom Nutzer getestet und abgenommen (24.11.2026). [Bericht und native Prüffälle](docs/review/SF051_PRUEFBERICHT.md).

**SF-050 · App 1.0.11.0 · Zur Prüfung (23.11.2026):** Neue Belegläufe isolieren je Geschäftsvorfall; unbekannte Buchungsergebnisse bleiben NeedsReview, unabhängige Pending-Vorgänge können weiterlaufen. No-write-Skips, Qualitäts-/Dashboardbilanz und fehlende technische Existing-Einrichtung sind integriert. Native BC-Abnahme durch den Nutzer offen. SF-051–SF-053 nicht umgesetzt. [Vertrag, Paket und native Prüffälle](docs/review/SF050_PRUEFBERICHT.md).

**Historischer Teilstand SF-049/SF-050 · App 1.0.10.0 · In Arbeit:** Neuer modulabhängiger Mandantenpool ohne pauschale Zwei-Lieferanten-Pflicht; Fehlbestandsbelege erhalten einen ausdrücklichen STOCK-Nachweis und Dashboard-/Qualitätswarnung. Sichere Isolation unerwarteter Buchungsfehler und native Abnahme offen. SF-051–SF-053 noch nicht implementiert. [Teilstand und Prüfung](docs/review/SF049_SF050_PRUEFBERICHT.md).

# BC Scenario Factory

**SF-048 – App 1.0.9.0:** Im vorhandenen Unternehmensassistenten Komplett, nur Stammdaten oder nur Bewegungsdaten wählen. Einkauf/Verkauf können geprüfte Stammdaten desselben Mandanten wiederverwenden, auch aus fehlgeschlagenen Läufen mit vollständig bestätigten Stammdatenpaketen. [Bedienung und Quellenvertrag](docs/MODULAR_GENERATION.md), [Build und offene Sandboxabnahme](docs/review/SF048_PRUEFBERICHT.md). **Zur Prüfung**.

**SF-047 · Korrektur 1.0.8.5 · Zur Prüfung:** Zahlungsvalidierung für gebuchte Einkaufs-/Verkaufsrechnungen mit Ausgleich unterdrückt Standard-Zwischencommits. Bestehender TRADE/6-Ausbau bleibt erhalten. App und Test-App lokal kompiliert; native Prüfung auf BC 29.1 und acht bestehende Analyzer-Formatbefunde offen. [Prüfbericht und Paketnachweis](docs/review/SF047_PRUEFBERICHT.md#zahlungskorrektur-1085--commit-bei-ausgleichsvalidierung).

**SF-022 · Datumszeitraum · Version 1.0.7.3 · Zur Prüfung:** In der Unternehmensinitialisierung unter **Daten und Prozesse** das Feld **Daten erzeugen ab** wählen. Ende ist **gestern**, unabhängig vom BC-Arbeitsdatum. Neue Beleg- und Buchungsdaten werden reproduzierbar im eingefrorenen Zeitraum verteilt; Wareneingang liegt spätestens vor dem zugehörigen Verkauf, Zahlung frühestens am Rechnungsdatum. Technische Erstellzeitstempel bleiben tatsächlich aktuell. [Umsetzung, Grenzen und native Prüfung](docs/INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073).

**SF-022 · Modulauswahl · Version 1.0.7.2 · Zur Prüfung:** Der bestehende Unternehmensassistent enthält nach der Branche einen Modulschritt: **Kontenplan → Großhandel → Module → Größe → Prozessstufe → Zusammenfassung/Start**. Verkauf, Einkauf, Artikel und Finanzbasis sind vorgewählt und erforderlich. Weitere Module lassen sich als **nur geplant, ohne Datenerzeugung** markieren. Zusammenfassung, Hintergrundrequest, Snapshot und Dashboard erhalten die Auswahl. Vorhandene Zahlungen mit vollständigem Ausgleich bleiben unverändert; Teilzahlungen, Gutschriften und Retouren bleiben offen. [Vertrag und native Prüfschritte](docs/INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072).

**SF-045 / SF-020 / SF-022 · Version 1.0.7.1 · Zur Prüfung:** Der normale Einstieg ist jetzt ein Assistent in der vorhandenen Einrichtung: **Kontenplan → Großhandel → Klein/Mittel/Groß → Stammdaten / ungebuchte / gebuchte Belege / Zahlungsausgleich → Start**. Ein Hintergrundjob bereitet die gemeinsame Einrichtung vor; die vorhandene Batchengine erzeugt anschließend zusammenhängende Partner, Artikel und Einkaufs-/Verkaufsbelege. Keine zusätzliche Vorlagenwahl. [Bedienung und echte Prüfgrenzen](docs/INDUSTRY_INITIALIZATION.md), [vollständiger Architektur-Audit](docs/ARCHITECTURE_AUDIT_SF045.md).

**Nicht nativ abgenommen:** Frische SKR03-/SKR04-Firma, Hintergrundbetrieb, Wiederanlauf und Upgrade. Gebuchte Beschaffung und Zahlungen/Ausgleich sind implementiert; native Standardbuchungs-/Rechteabnahme ist offen. Weitere Branchen bleiben gesperrt. Das Dashboard aktualisiert sich alle zwei Sekunden im Hintergrund; Herkunftskennzahlen haben keine 150er-Grenze mehr, Einkauf/Verkauf sind eindeutig bezeichnet und die Zahlungsprozessstufe ist sichtbar. Bestehende Läufe und eigene Vorlagen werden erhalten. Die folgenden Ticketabschnitte dokumentieren frühere Zwischenstände und sind keine alternative aktuelle Einrichtungsanleitung.

**Aktueller Einstieg ab 1.0.2.0:** Einrichtung öffnen, Mandant einmal mit SKR03/SKR04 oder vorhandener BC-Einrichtung initialisieren, danach eine Vorlage direkt in der Job Queue starten. [Mandanteneinrichtung und Vorlagenstart](docs/COMPANY_INITIALIZATION.md). Die nachfolgenden Ticketvermerke sind historische Zwischenstände.

**Status: Grundlagen, Qualitätsabschluss, Finanztestpakete, Partner-/Artikelstammdaten und Verkaufsprozess (SF-021) implementiert, zur Prüfung; weitere Fachgeneratoren und native BC-End-to-End-Abnahme ausstehend.** Ein AL-Projekt für synthetische, fachlich zusammenhängende Business-Central-Demo-, Schulungs-, Funktions- und Lasttestumgebungen. Nicht nur Mengen generieren, sondern realistische Unternehmensdaten mit konfigurierbaren Szenarien, unterschiedlichen Geschäftsvorfällen, Abhängigkeiten und optional vollständig gebuchten Prozessen.

## Zielgruppen und Nutzen

| Rolle | Ziel | Beispiel |
| --- | --- | --- |
| BC-Berater | Vorführbare Prozesse ohne manuelle Vorbereitung | Handelsunternehmen mit Einkauf → Wareneingang → Verkauf → Zahlung |
| Schulung/Key User | Wiederholbare Lernfälle | Überfällige Rechnung, Retouren, offene und ausgeglichene Posten |
| AL-Entwickler/Tester | Valide, reproduzierbare Daten und Regression | Varianten mit fehlenden Dimensionen ausschließlich als **gezielte Negativtests** |
| Performance/QA | Einstellbare Last und überprüfbare Durchläufe | 1.000 / 10.000 / 50.000 / 100.000 führende Datensätze, fachabhängig gebatcht |

## Leitbild

1. **Branche** auswählen (zunächst Handel), dann benötigte **Module** und **Datenmengen pro Entität** definieren.
2. **Umfang** auswählen: (A) Einrichtungen + Stammdaten, (B) zusätzlich ungebuchte Dokumente, (C) gebuchte Bewegungen, (D) vollständige Folgeprozesse wie Zahlungen und Ausgleich.
3. **Vorbedingungen** prüfen; vorhandene BC-Standardkonfiguration kontrolliert nutzen, fehlende Einrichtungen nur mit Freigabe anlegen; niemals produktive Einstellungen still verändern.
4. **Reale fachliche Relationen** und variierende Werte erzeugen: Rollen, Zeiträume, Preise, Buchungsstatus, Bestände und offene Posten müssen plausibel und prüfbar sein.
5. **Aufgabenwarteschlange** führt große Läufe in wiederaufnehmbaren, protokollierten Verarbeitungspaketen aus; BC kann weiter benutzt werden.
6. **Dashboard** zeigt Gesamtstatus, pro Modul erzeugte Datensätze, laufende/fehlgeschlagene Pakete, Prüfungen und eventuelle offene Schritte.
7. **Ergebnisse** sind nachprüfbar, bei Bedarf als Szenario erneut erzeugbar; technische Grenzen und Bereinigung sind explizit.

## Wichtige Abgrenzungen

- Keine echten Kunden- oder Mitarbeiterdaten. Namen/Adressen etc. sind **synthetisch**; keine echten personenbezogenen Identitäten nachbilden.
- **Sandbox/Testmandanten**, keine automatischen Massenbuchungen in Produktion. Ein Produktions-Blocker ist verbindlicher Teil des ersten MVP.
- Kein direktes Insert in Standard-Postentabellen: Buchungen über freigegebene BC-Standardprozesse.
- Branchenprofile sind **Parameter/Regelsets für wiederverwendbare Fachgeneratoren**, nicht Kopien der Fachlogik.
- **XERJ wird nur lokal als Entwicklerwerkzeug für Codex getestet; es ist keine Abhängigkeit, Schnittstelle oder Laufzeitkomponente dieser AL-App.**
- Der neue Auftrag umfasst eine frische Sandbox-Firma für den begrenzten Großhandelsfall. Die native Abnahme steht aus; keine universelle Zusage für beliebige BC-Prozesse.

## Stand und Installation

`app.json` enthält bereits App-ID, `application: 28.0.0.0`, `runtime: 17.0` und ID-Bereich `90100–90999`, aber der Publisher ist noch `Default Publisher`. Der Nutzer hat den Objektbereich anschließend auf `90100–90999` geändert und für SF-002 bestätigt (900 ID-Werte); Ziel ist `Playground` im Entwicklungsmodus. **Versionswerte stammen aus der gelieferten ZIP und sind nicht als funktionsfähig validiert.** Publisher, Zielversion/Lokalisierung, Testfirma, externe ID-Konflikte und Build-/Sandbox-Zugriff bleiben zu prüfen.

1. Projekt in VS Code mit der Microsoft AL Language Extension öffnen.
2. `app.json` und `.vscode/launch.json` mit der vorgesehenen Sandbox abgleichen; keine produktive Umgebung verwenden.
3. AL-Symbole erst nach bestätigter BC-Version laden; keine Kompilierung behaupten.
4. `AGENTS.md`, `docs/PROJECT.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` und `TODO.md` lesen.
5. In Codex **genau ein vom Menschen ausgewähltes Ticket** beauftragen; vor Codeänderungen einen Plan und Testweg verlangen.

## Struktur

Seit dem Nutzerauftrag vom 16.11.2026 gilt `src/<Modul>/<Objekttyp>/`, beispielsweise `src/Core/Tables/` und `src/Core/Codeunits/`. AL-Dateien liegen in `Tables`, `Pages`, `PageExtensions`, `Codeunits`, `Enums`, `PermissionSets`, `Interfaces`, `ControlAddIns` oder `Profiles`, jeweils nur für vorhandene Objekte. Die 13 Module ohne AL-Code behalten vorerst ihren Modulmarker. Dashboard-JavaScript und -CSS bleiben unter `src/Monitoring/Dashboard/`. [Konventionen](docs/CONVENTIONS.md) und [Modulindex](docs/modules/INDEX.md) beschreiben die Zuordnung.

## Dokumente

- [Startanleitung](GETTING_STARTED.md) · [Architektur](docs/ARCHITECTURE.md) · [Fachkonzept](docs/REQUIREMENTS.md)
- [Szenarien & Branchen](docs/SCENARIOS.md) · [Generierungsregeln](docs/DATA_MODEL.md) · [Hintergrundjobs](docs/BACKGROUND_PROCESSING.md)
- [UI und Dashboard](docs/UI_WORKFLOWS.md) · [Teststrategie](docs/TESTS.md) · [Sicherheit](docs/SECURITY.md)
- [Szenarien und Sprachen](docs/SCENARIO_CONFIGURATION.md) · [Setup und Sicherheitsvertrag](docs/FOUNDATION.md) · [Objektplan](docs/OBJECT_PLAN.md) · [Modulindex](docs/modules/INDEX.md) · [Entscheidungen](docs/DECISIONS.md) · [Umsetzungs-Tickets](TODO.md)

## Lizenz / Support

Urheberrechte, kommerzielle Lizenz, Supportkanal und Veröffentlichungsweg: **Zu prüfen**. Es wurde keine Lizenz eingeräumt.

## Implementierter Stand SF-003/SF-004

Neun AL-Objekte für firmenbezogenes Setup, Enums, GUID-/Statushilfen, Permission Set und Environment Guard. Die Setup-Seite initialisiert nur auf ausdrückliche Aktion; Generierung und Posting sind standardmäßig aus. Noch keine Fachgeneratoren oder Queue-Worker. Lokaler Build inklusive CodeCop/UICop gegen vorhandene BC-28.5-/DE-Symbole (Runtime 17) erfolgreich; Sandbox- und Berechtigungstests stehen aus. Bedienung, Grenzen und Prüfnachweise: [FOUNDATION.md](docs/FOUNDATION.md), [TESTS.md](docs/TESTS.md).


## Szenarien und Sprachen (SF-005/SF-006)

Über „Scenario Factory Scenarios“ / „Scenario-Factory-Szenarien“ Vorlagen anlegen, kopieren, Module und Entitätsmengen/Quoten konfigurieren. Ein Lauf-Snapshot friert die gesamte aktuelle Konfiguration als Entwurf ein; spätere Vorlagenänderungen haben darauf keinen Einfluss. Noch keine Daten-/Queue-Ausführung.

Die Setup-Aktion „Anzeigesprache ändern“ öffnet die BC-Spracheinstellungen. XLIFF deckt alle 443 App-Texteinheiten auf Deutsch (DE/AT/CH/LI/LU) und Englisch ab. Die Datensprache ist separat als Automatisch/Deutsch/Englisch einstellbar: Automatisch erkennt jede deutsche BC-Sprachregion, sonst Englisch. Sprache und Textkatalogversion werden je Lauf eingefroren; synthetische Namensvorschauen auf Vorlage und Lauf verwenden diesen Vertrag. Vorhandene Texte werden beim Sprachwechsel nicht nachträglich geändert.

56 AL-Objekte gegen lokale BC-28.5-/Runtime-17-Symbole mit CodeCop/UICop gebaut; UI-/Rechte-/Snapshot-Laufzeittests stehen aus. Neue Texte nach vollständigem Build im deutschen XLIFF-Master pflegen, regionale Dateien mit `python3 scripts/check_translations.py --sync` ableiten und mit `python3 scripts/check_translations.py` prüfen. Details: [SCENARIO_CONFIGURATION.md](docs/SCENARIO_CONFIGURATION.md).


## Registry und Laufplanung (SF-007/SF-008)

Generator-Katalog mit zwei lesenden Vertragsproben, versionierter interner Schnittstelle und Selbstprüfung. Laufkarte um Graphvorschau, unveränderliche Planschritte und blockierende Startprüfung ergänzt. Fehlende Generatoren, externe Setup-/Bestandsnachweise und Zyklen verhindern den Start. Noch keine echte Datengenerierung oder Queue. Bedienung, Sicherheitsgrenzen und ausstehende Sandbox-Prüfungen: [GENERATOR_PLANNING.md](docs/GENERATOR_PLANNING.md). **Zur Prüfung**.

## Setupprüfung und Seed-Engine (SF-009/SF-010)

Auf der Laufkarte stehen eine lesende Einrichtungsvorprüfung mit Maßnahmenplan sowie eine synthetische Werte-Vorschau bereit. Neue Snapshots frieren Engine-/Regelversion, Klassenquoten und Preisbereiche ein. Gleiches Profil, Seed und logische Schlüssel liefern dieselben Eingangswerte unabhängig von Lauf-ID und Batchreihenfolge. Keine Standarddatenanlage oder automatische Setupänderung; konkrete Generatorbindungen bleiben blockierend. Vertrag und Grenzen: [SETUP_SEED.md](docs/SETUP_SEED.md). **Zur Prüfung**; BC-Laufzeitabnahme offen.

## Herkunft und Queue-Grundlage (SF-011/SF-012)

Unveränderliche Herkunftseinträge verbinden logische Einheiten und Belegketten mit tatsächlichen SystemIds. Laufkarte und persistente Listen zeigen einen separaten Ausführungsstatus, Batches und Ergebnisse. Dispatcher und begrenzter Standard-Job-Queue-Worker sind implementiert; vorhandene Generator-/Setupblocker verhindern weiterhin reale Starts. Keine automatische Wiederholung unsicherer Arbeit. Vertrag, Bedienung und Grenzen: [EXECUTION_REGISTRY.md](docs/EXECUTION_REGISTRY.md). **Zur Prüfung**, keine BC-Laufzeitabnahme.

## Checkpoints und Wiederaufnahme (SF-013)

Pausen-/Abbruchanforderungen wirken an sicheren Paketgrenzen. Bestätigte technische Checkpoints sichern vorhandene Ergebnisse. Nur nie übernommene Fehlerpakete dürfen nach erneuten Prüfungen begrenzt wiederholt werden; unklare Arbeit bleibt ohne passenden Checkpoint gesperrt. Steueraktionen auf der Laufkarte und in der Paketliste. [RECOVERY.md](docs/RECOVERY.md), **Zur Prüfung**; Unterbrechungs-/Queue-Laufzeittests offen.

## Dashboard und geführte Planung (SF-014/SF-015)

„Scenario Factory Dashboard“ zeigt gespeicherte Ausführung, bestätigte Pakete, offene Ziele je Schritt, Zeitpunkte und Statushistorie mit Queue-Protokollzugriff. Gesamtqualität wird durch SF-016 nach vollständiger Pflichtprüfung ermittelt. „Neues Szenario mit Assistent“ bzw. „Mit Assistent planen“ führt durch fünf Schritte bis zur expliziten Erfassung, Vorprüfung und terminierten Freigabe. Bestehende Generator-/Setupblocker bleiben wirksam; keine Branchenpresets oder Postingfreigabe vorgetäuscht. [Bedienung und Grenzen](docs/MONITORING_WIZARD.md), **Zur Prüfung**; BC-Laufzeitabnahme offen.

## Zentraler JavaScript-Arbeitsplatz und App-Rolle

Das Profil **BC Scenario Factory** öffnet das eigene App-Role-Center mit JavaScript-Dashboard. Szenarien lassen sich dort direkt anlegen; Vorlagen, Läufe, Planung/Vorprüfung, Ausführung, Pakete/Wiederaufnahme, Herkunft, Generatorkatalog und Einrichtung sind zentral erreichbar. Die gleiche **BCSF Dashboard Part** kann per PageExtension in weitere erweiterbare Role-Center eingebaut werden. [Bedienung und Einbau](docs/DASHBOARD_EMBEDDING.md). 104 AL-Objekte und 978 Texte lokal geprüft, Status **Zur Prüfung**; tatsächliche BC-Role-Center-/Profil-/Dialogabnahme offen.


## Qualitätsabschluss und Finanztestpakete (SF-016/SF-017)

Pflichtprüfungen gleichen Mengen, Herkunft, Generatorergebnisse sowie registrierte Rechnungen/Gutschriften mit tatsächlichen Posten ab. Nur erfolgreiche Pflichtprüfungen erlauben Completed; optionale Befunde führen zu Warnungen. Befunde sind unveränderlich und in der Laufübersicht erreichbar.

In der Factory-Einrichtung „Finanzeinrichtung prüfen“ öffnen: vorhandene Einrichtung lesend prüfen oder SKR03-/SKR04-Testpaket 2026/1.0.0 nach Vorschau ausdrücklich anwenden. Die Pakete enthalten 14 Konten, Buchungsgruppen/-matrizen und je Bilanz/GuV; keine vollständigen DATEV-Kontenrahmen. Finanzmodus anschließend auf Szenario/Wizard wählen; Jahr und Version werden eingefroren. [Bedienung, Grenzen und Buchungsbeispiel](docs/VALIDATION_FINANCE.md). 116 AL-Dateien und 1.071 Texte lokal geprüft; tatsächliche BC-Buchungs-/Berichtsabnahme offen. **Zur Prüfung**.


## Debitoren und Kreditoren (SF-018)

Zwei echte Stammdatengeneratoren verwenden die vorhandene Queue, Seed-Engine und Herkunftsregistry. Synthetische Firmen/Privatkunden, fiktive Regionen, klassenspezifische Zahlungsbedingungen, Kreditlimits und Lieferantenprioritäten sind unterstützt. In der Szenariokarte oder im Wizard unter „Synthetische Partner“ die konkrete Einrichtung wählen, dann neuen Snapshot/Plan erstellen. Reine Debitoren-/Kreditorenläufe werden anhand ihrer tatsächlichen Voraussetzungen geprüft; Artikel-/Beleg-/Buchungsgeneratoren bleiben ausstehend. [Bedienung und Grenzen](docs/PARTNER_GENERATION.md). 121 AL-Dateien, Runtime 17; **Zur Prüfung**, kein bestätigter Sandboxlauf.

## Startvorlagen, Schnellstart und Szenariopakete

In der freigegebenen Playground-Sandbox werden bei Installation/Upgrade Startvorlagen angelegt. Für reine Partner-Vorlagen gibt es einen bestätigten Schnellstart mit optionaler Minimal-Testeinrichtung. Die Szenarienliste unterstützt außerdem gemeinsamen JSON-Export der Auswahl und gemeinsamen Import in einen anderen Testmandanten. Beleg- und Folgeprozess-Vorlagen bleiben Planung. [Bedienung, Grenzen und Tests](docs/STARTER_TEMPLATES.md).


## Aktueller Normalpfad (SF-037)

**Scenario-Factory-Szenarien → Startvorlagen laden → Partner-Vorlage wählen → Partnerszenario ausführen → bestätigen → Ergebnisse öffnen.** Queue, Plan und Checkpoints werden intern bedient. Die Laufkarte zeigt den aktuellen Ausführungsstatus, bestätigte Pakete, Abschlussprüfung und genau diesem Lauf zugeordnete Partner. Bei Fehlern führt **Fehler anzeigen** zum ursprünglichen Standardprotokoll bzw. zum fehlenden Nachweis. Technische Aktionen liegen unter **Diagnose**.

Startvorlagen werden ausschließlich über die UI geladen, nicht beim Publishing. Unveränderte Standardnamen wechseln mit der Sitzungssprache; eigene Namen bleiben erhalten. Ausgewählte unbenutzte Vorlagen können gelöscht, verwendete archiviert werden. Erneutes Laden holt absichtlich entfernte/archivierte Starter nicht zurück. [Aktuelle Testanleitung](docs/review/TESTANLEITUNG.md), [echte lokale Prüfungen und offene Sandboxfälle](docs/TESTS.md#sf-037--reparatur-vorlage-bis-ergebnis-18112026). Status **Zur Prüfung**.


## SF-038 / SF-039 – aktueller Reparaturstand

Gemeinsamer bestätigter Finance-Pfad ohne Zwei-Konten-Fallback, neue SKR-Teilpakete 2.0.0 und versionierte natürliche Partnerwerte einschließlich Liefer-/Bestelladressen sind implementiert, **Zur Prüfung**. Alte Pakete/Läufe werden nicht migriert. Zahlungsbereitschaft ohne freigegebene synthetische Bankdaten bleibt gesperrt. [Umfang und Grenzen](docs/STABILIZATION_FINANCE_PARTNERS.md), [Prüfanleitung](docs/review/TESTANLEITUNG.md).


## Kompaktes Dashboard (SF-044)

Die Reiter **Daten** und **Läufe** trennen Bestandsfilter und Laufwahl. Einheitliche klickbare Kacheln zeigen den berechtigten Datenbestand bzw. den Fortschritt direkt bei der Entität; technische Details liegen unter Diagnose. [Bedienung und offene BC-Abnahme](docs/DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026), [lokale Prüfungen](docs/TESTS.md#sf-044--kompaktes-dashboard-und-direkte-kennzahlen). **Zur Prüfung**.

## Artikel und technischer Großhandel (SF-019)

Zwei zusätzliche Vorlagen erzeugen ein technisches Sortiment mit Kategorien/Merkmalen, Artikel-Einheiten, zwei angebotenen Kugelhahnvarianten, Referenzen/Bezugsquellen, Ersatzpaar und einer gezielten SKU. Wahlweise einfaches Lager ohne oder mit Platzführung; keine Bestände oder Buchungen. Der bestehende Vorlagenstart bleibt erhalten. Bei älterer initialisierter SKR-Firma kann die bestehende Einrichtung über **Stammdatenbasis ergänzen** vervollständigt werden.

[Bedienung und Sandbox-Smoke](docs/INVENTORY_GENERATION.md), [Prüfstand einschließlich korrigiertem Item-Vendor-Schlüsselfehler](docs/TESTS.md#sf-019--artikelsortiment-und-lagerbasics-20112026). **Zur Prüfung**, reale Korrekturabnahme offen.

## Verkaufsprozess (SF-021, Version 1.0.5.0)

Vorlagen laden → **Verkauf – Angebote, Aufträge und Rechnungen** öffnen → abgeschlossenen synthetischen Quelllauf auswählen → **Vorlage ausführen**. Standardmäßig entstehen nur offene Belege. Gebuchte/teilweise Verkäufe benötigen vorhandenen Bestand sowie die ausdrückliche Freigabe auf Vorlage und Einrichtung. Standard-Angebotsumwandlung, Lieferung, Rechnung und offene Debitorenposten bleiben über Herkunft und Dashboard prüfbar. Kein automatischer Einkauf oder Zahlungslauf.

[Bedienung, Grenzen und native Prüfschritte](docs/SALES_PROCESS.md), [lokale Prüfungen](docs/TESTS.md#sf-021--verkaufsprozess-20112026). **Zur Prüfung**, native BC-Abnahme offen. SF-019-Checkliste gemäß belegtem Stand aktualisiert; offene Laufzeit-/Abnahmehäkchen bleiben offen.

### Vorlagenkorrektur 1.0.5.1

Nach dem Paketupdate einmal **Startvorlagen laden** wählen: erkennbare unveränderte Branchen-Belegstarter werden auf Verkauf aktualisiert, eine gemischte Verkaufsvorlage kommt hinzu. Neue Szenarien haben ein kleines ausführbares Stammdatenziel; Start liefert konkrete fehlende Voraussetzungen, Löschen ist direkt sichtbar und bewahrt benutzte Historie durch Archivierung. Der maximale Umfang begrenzt die tatsächlichen Ziele; gebuchte Vorlagen enthalten unterschiedliche ungebuchte/teilgebuchte/gebuchte Quoten. Eigene Konfigurationen und gespeicherte Läufe bleiben geschützt. [Umfang und native Abnahme](docs/SALES_PROCESS.md#ergebnis-der-vorlagenkorrektur-1051). **Zur Prüfung**.


## Vollständiger Geschäftsdatenexport (SF-046, 1.0.8.1)

Installation/Upgrade baut seit 1.0.8.1 keine Konfigurationspakete mehr in allen Firmen auf. In der gewünschten Sandboxfirma im Dashboard **Datenexportpaket vorbereiten** wählen: Die Aktion erstellt/ergänzt **BCSF-ALL-DATA** ausschließlich dort. Anschließend auf der Standardkarte **Nach Excel exportieren** wählen. 128 Tabellen umfassen Stämme, Einrichtung, Belegköpfe/-zeilen, Buchungsposten und Standardbeziehungen. Vollständiger Tabelleninhalt einschließlich vorhandener Fremddaten, unabhängig vom Dashboardfilter. Gebuchte Posten dienen der Auswertung und sind kein RapidStart-Wiederimport. [Tabellen-IDs, Bedienung und Grenzen](docs/CONFIG_EXPORT.md). **Zur Prüfung**, native Installation/Exportabnahme offen.

**Optionale Module (SF-028–SF-033, 24.11.2026):** Lager, Fertigung, Montage, Projekte, Service, Anlagen, CRM und Planung sind in der Einrichtung wählbar und erzeugen im Folgeprozess eigene Daten. Nativ getestet und abgenommen (24.11.2026); weitere Branchen (SF-032) bleiben gesperrt. [Bericht](docs/review/SF028_SF033_PRUEFBERICHT.md).
