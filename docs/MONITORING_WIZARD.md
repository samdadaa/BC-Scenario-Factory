# SF-014 / SF-015 – Monitoring und geführte Planung

**Aktuell nach Nutzerpräzisierung:** JavaScript-ControlAddIn, eigenes Role-Center und wiederverwendbare CardPart sind ergänzt. Maßgebliche aktuelle Bedienung, Einbau und Grenzen: [DASHBOARD_EMBEDDING.md](DASHBOARD_EMBEDDING.md). Die anfängliche ausschließlich native Entscheidung unten ist historischer Umsetzungsstand.

## Plan vor Änderungen, 16.11.2026

Ausdrücklich beide Tickets beauftragt, Umsetzung nacheinander, keine weiteren Tickets.
Ziel SF-014: native lesende Übersicht aus Run Header, Snapshot, Steps, Execution und Batches; Statushistorie über verpflichtende Datenbanksubscriber in derselben Transaktion. Keine fachliche Gesamtvalidierung vor SF-016 behaupten. Keine historische Ereignisrekonstruktion aus Vermutungen.
Ziel SF-015: fünf geführte Schritte auf bestehenden Vorlagen; Snapshot explizit erstellen, danach unveränderlichen Run planen/vorprüfen und nur über den vorhandenen Dispatcher freigeben/terminieren. Kein neuer Generator und kein automatisches Setup.

Dateien: neue Objekte in Monitoring und ScenarioManagement, Navigationsaktionen auf Vorlagen/Laufkarte, Core-Permission-Set, XLIFF, Objektplan sowie Projekt-/Architektur-/Test-/Moduldokumentation und ausschließlich SF-014/SF-015 in TODO. Keine Bestandsverschiebung, Manifest-/Launchänderung oder Test-Codeunit.

Risiken: Doppelzählung von Artefakten als Entitäten, unbestätigte Claims, fehlende globale Qualitätsprüfung, alte Läufe ohne Ereignisse, fehlende Standard-Queue-Rechte, UI-Snapshot-Veraltung. Gegenmaßnahmen: bestätigte Mengen je Schritt, separate Artefakte/Qualität, immutable Historie ohne Fehlernutzdaten, bestehende Gates bei Vorbereitung und Scheduling, Wizard nach Snapshot sperren.

Zu prüfen: reale Sandbox-/Firmen-/Lizenz-/Security-Filter-/UI-Laufzeitprüfung; vollständige Branchenprofile (SF-023/SF-032), Generatorbindungen und Qualitätsgate (SF-016). Profilcode/-version bleiben Planungsmetadaten; keine erfundenen Branchenpresets.

Testweg: vollständiger Cloud-Build mit vorhandenen BC-28.5-/DE-Symbolen, Runtime 17, CodeCop/UICop und warnaserror; XLIFF-Abdeckung DE/EN; Objekt-ID-/Namens-/Scope-/Diffprüfung; Codeprüfung der Filter, Zähler, Schreib-/Commitgrenzen und Queue-Gates. BC-Fälle einschließlich Wiederöffnung, unvorbereitetem Lauf, Teilfehler, fehlenden Rechten, Cancel/Retry, Wizard-Abbruch und verweigerter Freigabe separat als nicht ausgeführt dokumentieren.

## Implementierter Vertrag

### SF-014: Anzeige und Datenmodell

`BCSF Factory Dashboard` (90351) bleibt als native Laufliste mit FactBox erhalten und trägt jetzt die Caption Scenario Factory Run Monitor. Der neue zentrale JavaScript-Arbeitsplatz samt Role-Center ist im [aktuellen Vertrag](DASHBOARD_EMBEDDING.md) beschrieben. Lauf/Profil/Nutzungsziel/Zeitraum sind nativ filterbar; der Link „Ausführungen filtern“ bietet den persistenten operativen Statusfilter. Erstellerfilter ist nicht implementiert: Es wird kein zusätzlicher Personenbezug erhoben.

- Dashboard und Laufkarte zeigen aktuellen Ausführungsstatus, Pause-/Abbruchanforderung, Queuezustand, gespeicherte Zeitpunkte, verstrichene Kalenderzeit und letzte erfasste Aktivität. Letztere ist kein Worker-Heartbeat; keine ETA-/Durchsatzzusage.
- Die Schrittübersicht rekonstruiert ohne Plan die positiven Ziele aus dem eingefrorenen Snapshot. Mit gespeichertem Plan liest sie dessen unveränderliche Steps einschließlich externer Voraussetzungen und konkreter Blockererläuterung.
- Je Schritt getrennt: Ziel, bestätigte logische Einheiten, offene Einheiten, Herkunftsartefakte sowie Gesamt-/Completed-/Running-/Review-/Cancelled-Pakete. Bestätigung ausschließlich aus `Batch.Status=Completed`. Versuche/Claims/Fehler erhöhen das Ist nicht. Offene Einheiten = Ziel minus bestätigt; Abbruch löscht den Rest nicht. Prozent nur je nicht-externer Entität. Externe Voraussetzungen sind ausdrücklich gekennzeichnet, keine generierten Entitäten. Keine Summe heterogener Entitäten als globale Erfolgsquote.
- „Pakete bestätigt“ verlangt alle Pakete abgeschlossen und die Zielmenge exakt bestätigt. Gesamtqualität bleibt ausdrücklich ausstehend bis SF-016. Artefakte können mehrere Records je Einheit umfassen; sie sind kein gebuchter oder fachlich global validierter Zähler.
- Alle Monitoring-Lesewege sind mutationsfrei. Aktualisieren liest erneut; kein Polling/Retry/Start beim Öffnen. Filter auf Run und Step vor Batchzugriff; Aggregation einmal je ausgewähltem Run. Keine pro Batch ausgeführten Standarddatensatz-Existenzprüfungen in der Anzeige. Effektive Leserechte/Sicherheitsfilter gelten weiter; fachliche vollständige Sicht ist mit realen Rollen noch zu prüfen.

### Persistente Statushistorie

Tabelle `BCSF Run Event` ist firmenbezogen, append-only, ohne rohe Fehlertexte/Benutzerkennungen/Namen/Adressen. GUID-Eintrag, Run/optional Batch/Step, Zeitpunkt, typbezogener Status, Job-ID und bestätigte technische Zähler. Ausführungseinträge besitzen keine Paketmengen; Anzeige wählt den passenden Run- oder Batchstatus anhand der Batch-ID.

Vier verpflichtende After-Subscriber auf Insert/Modify von Execution/Batch zeichnen initiale Zustände, Statuswechsel und bei Batches Jobbindungswechsel auf. Speicherung teilt die auslösende Transaktion: kein Commit, kein TryFunction, kein Netzwerk. Kein eigener Lock/Gesamtzähler über alle Runs. Gleichzeitige Ereignisse mit gleichem Zeitstempel besitzen keine zugesicherte kausale Gesamtreihenfolge. Alte Läufe werden nicht rückwirkend mit erfundenen Ereignissen aufgefüllt.

Vier verpflichtende Before-Subscriber prüfen persistente Inserts gegen die aktuelle Ausführung/das aktuelle Paket plus Sandbox-/Firmen-Guard und sperren Modify/Delete/Rename auch bei `RunTrigger=false`. `BCSF ADMIN` erhält nur Ri auf Ereignisse; nur der feste Writer direkte Insert-Berechtigung. Fehlende Monitoringrechte/Guardfehler lassen den zugehörigen Übergang fehlschlagen, statt ihn ohne Historie zu bestätigen. Keine neuen Standarddatenrechte. Retention/Löschung bleibt SF-027; Mehrkosten der Ereignisspeicherung sind noch nicht gemessen.

Fehlerdetails bleiben in den berechtigungsgeschützten BC-Standardprotokollen. Paketdrilldown filtert aktuelle/vorherige Job-ID plus Worker; Historie führt zu früher aufgezeichneten Job-IDs. Fehlende/entfernte Jobs werden nicht neu angelegt. Fehlende Standardrechte erzeugen den normalen Berechtigungsfehler; bereits bereinigte Standardprotokolle können leer sein.

### SF-015: Bedienung und Startgrenze

Vorlagenliste → „Neues Szenario mit Assistent“ erstellt ausdrücklich eine Vorlage; „Mit Assistent planen“ öffnet eine vorhandene Vorlage auch von der Karte. Fünf Schritte:

1. Beschreibung, beabsichtigte Branchenprofilkennung/-version, Nutzungsziel. Vollständige Branchenpresets sind noch nicht verfügbar; Profilcodes sind Planungsmetadaten, kein Capability-Nachweis.
2. Module aktivieren; Voraussetzungen werden erklärt. Fehlende Module/Entitäten werden nicht still ergänzt.
3. Entity-Ziele, Quoten/Modi, Seed, Datumsspanne, Datensprache und Batchgröße. Vorhandene Policy und Datenbankguards bleiben maßgeblich.
4. Maximaler Prozessumfang und Buchungshinweis. Für Belegziele bei bisherigem Stammdatenmaximum hier erhöhen und zu Schritt 3 zurückgehen; vor Senken zuerst Zielmodi anpassen. Diese Reihenfolge respektiert die bestehende sofortige Validierung.
5. Explizit zur Prüfung erfassen; danach bleibt dieser Wizard gesperrt. Ein Run je Wizardinstanz. Abhängigkeiten/Graph und Einrichtungsvorprüfung separat öffnen, unveränderlichen Prüfplan speichern, frühesten Start wählen und Sandboxausführung ausdrücklich freigeben.

Kein Schreiben beim bloßen Öffnen; Vorlagenänderungen werden beim Navigieren gespeichert. Schließen verwirft gespeicherte Vorlagen/erfasste Läufe nicht und startet keine Arbeit. Nach Erfassung verwendet jeder Plan-/Preflight-/Startaufruf die festgehaltene Run-ID; spätere Vorlagenänderungen verändern sie nicht. Eine weitere Konfiguration erfordert eine neue Wizardinstanz/einen neuen Run. DE/EN-Captions und Tooltips, native BC-Tastatur-/Screenreaderbedienung vorgesehen; praktische UI-Abnahme offen.

Der Wizard liegt in ScenarioManagement, Ausführungsintegration als PageExtension in Monitoring. Somit keine neue ausführbare Rückreferenz ScenarioManagement → Execution/Planner. Monitoring darf zusätzlich DependencyManager, SetupManager und Lifecycle für vorhandene Prüfungen bzw. den Guard referenzieren. Ausführung selbst referenziert Monitoring nicht direkt; die Datenbanksubscriber binden die Historie.

„Freigeben und einplanen“ verlangt Checkbox und Bestätigung (Default Nein); danach SavePlan, ggf. Prepare und Schedule über den bestehenden Dispatcher. Jede Vorbereitung/Einplanung prüft aktuelle Gates erneut. Keine neuen Commits, keine Standard-Queue-Rechteerhöhung, PostingApproved bleibt im bestehenden Vertrag false. Fehler blockieren den Start. Wiederholte Einplanung einer bereits geplanten Ausführung wird vom bestehenden Status-/Jobvertrag abgewiesen. Generator-/Setupblocker bleiben aktuell bestehen. Die Freigabecheckbox ist UI-Zustand, keine dauerhafte Posting-/Setupgenehmigung.

## Kompatibilität und offene Abnahme

Manifest unverändert: App-ID `618c08c6-601b-430a-90d2-55f96866bfa4`, Version 1.0.0.0, Application 28.0.0.0, Runtime 17, Range 90100–90999, keine Dependencies. Lokal gegen vorhandene BC-28.5-/DE- und System-28.0-Symbole gebaut; keine Zusage für andere Versionen oder unbekannte Fremd-App-IDs. Standard-Queue-Logfelder/Seite aus lokalen Microsoft-Symbolen geprüft. Keine Testobjekte, keine Datenanlage/Veröffentlichung in BC.

Status beider Tickets: **Zur Prüfung**. Tatsächliche Prüfungen und noch offene BC-Fälle: [TESTS.md](TESTS.md). Objekt-/Dateiliste: [OBJECT_PLAN.md](OBJECT_PLAN.md).

## Geänderte Implementierungsdateien

Neu: `src/Monitoring/Tables/BCSFRunEvent.Table.al`, `BCSFStepMetric.Table.al`, `BCSFMonitoringMgt.Codeunit.al`, `BCSFRunEventWriter.Codeunit.al`, `BCSFFactoryDashboard.Page.al`, `BCSFRunOverview.Page.al`, `BCSFStepProgress.Page.al`, `BCSFRunEvents.Page.al`, `BCSFRunMonitoring.PageExt.al`, `BCSFBatchDiagnostics.PageExt.al`, `BCSFWizardExecution.PageExt.al` sowie `src/ScenarioManagement/Pages/BCSFScenarioWizard.Page.al`. Die verkürzten Dateinamen dieser Liste liegen seit der Strukturumstellung unter `src/Monitoring/Tables/`, `Codeunits/`, `Pages/` bzw. `PageExtensions/` gemäß ihrem Objekttyp.

Bestehende AL-Dateien: `src/Core/PermissionSets/BCSFADMIN.PermissionSet.al`, `src/ScenarioManagement/Pages/BCSFScenarioList.Page.al`, `src/ScenarioManagement/Pages/BCSFScenarioCard.Page.al`. Zusätzlich alle sieben XLIFF-Dateien in `Translations/`, README/TODO, die relevanten Projekt-/Architektur-/Konventions-/Sicherheits-/UI-/Test-/Entscheidungs-/Objektplandokumente und Modulindex/-nachweise aktualisiert. Keine ausführbare bestehende Queue-/Recovery-/Snapshotlogik verändert.

## Präzisierter Auftrag SF-014 – vor Erweiterung, 16.11.2026

Nutzer verlangt ausdrücklich JavaScript-ControlAddIn, eigenes App-Role-Center und zentrale Navigation einschließlich Szenarioanlage; Dashboard soll als wiederverwendbare CardPart in andere erweiterbare Role-Center einbaubar sein. Diese Vorgabe ersetzt die anfängliche Entscheidung für ausschließlich native Dashboardliste ohne Role-Center.

Umsetzung: bestehende Listenansicht 90351 als kompatible Detailansicht erhalten; neuer ControlAddIn, wiederverwendbare Dashboard-CardPart, vollflächige Hostseite, eigenes Role-Center und Profil sowie enger AL-Service für Leseprojektion und erlaubte Navigation/Aktionen. Neue numerische IDs ausschließlich aus freien Monitoringwerten 90362–90366; ControlAddIn und Profil ohne numerische ID, 90361 bleibt frei. Keine automatische Profilzuweisung oder ungefragte Änderung aller Standard-Role-Center; Einbau der wiederverwendbaren Part mittels dokumentierter PageExtension je gewünschtem Role-Center. Links zur Appnavigation auf vorhandenen Dashboard-Einstiegen ergänzen.

Dateien: neue Monitoring-AL-Objekte plus gebündelte JS-/CSS-Ressourcen, ADMIN-Permissions, vorhandene Dashboard-/Wizardnavigation, Übersetzungen, Objektplan, SF-014 und relevante Dokumentation. Bestehende Daten-/Queue-/Securityverträge bleiben erhalten. Risiko: Clientdaten als vertrauenswürdig behandeln, beliebige Objektaufrufe, XSS, doppelte asynchrone Aufrufe und unbeschränkte Payloads. Gegenmaßnahmen: feste serverseitige Aktionsliste, Guid/Get-Prüfung, vorhandene Guard-/Freigabewege, textContent statt HTML aus Daten, keine externen Bibliotheken/CDNs/Netzwerkaufrufe, begrenzte Laufprojektion, serialisierte Benutzeraktionen. Bestehende Branchen-/Generator-/Qualitätsblocker offen.

Testweg: vollständiger AL-Cloud-Build mit CodeCop/UICop, Übersetzungsprüfung und Paketressourcenprüfung, lokale JavaScript-/DOM-/Bedienprüfung soweit Werkzeug verfügbar; reale BC-Iframe-/Role-Center-/Rechte-/Dialog-/Profil-/Queueprüfung als separat offen dokumentieren. Kein Deployment und keine neuen AL-Testobjekte.
