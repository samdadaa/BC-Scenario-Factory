# Sicherheit und Berechtigungen — BC Scenario Factory

## Grundsätze

- Eine AL-Extension operiert in Business Central im Kontext von Benutzern, Rollen, Permission Sets, Tenant- und Umgebungskonfiguration. Effektive Berechtigungen sind zu prüfen; Rechte nicht allein aus erwarteter Rolle ableiten.
- Least Privilege: Lese-/Schreib-/Execute-Rechte nur soweit nötig. PermissionSets, Objekt-Properties und Tests für relevante Aktionen prüfen.
- Geschäfts- und personenbezogene Daten nur für definierten Zweck verarbeiten; Export, Debug-/Fehlertexte und Telemetry auf Datenminimierung prüfen.
- Keine Produktivdaten in Test- oder KI-Prompts; bei Bedarf anonymisierte/minimierte Testdaten.

## Geheimnisse und Konfiguration

- Keine Passwörter, Client Secrets, Tokens, Verbindungsschlüssel oder echte Tenant-Zugangsdaten in `AGENTS.md`, `TODO.md`, `launch.json`, AL-Code oder Git.
- Secrets in zugelassenen sicheren Mechanismen verwalten; konkrete Plattform-/API-Eignung und Richtlinien vor Einsatz prüfen.
- Sandbox und Production strikt unterscheiden. Deployment, Datenmigration, Batch-Korrekturen und Massenbuchungen nie ohne expliziten Auftrag.

## Agenten- und Supply-Chain-Sicherheit

- Coding-Agenten dürfen nicht eigenständig fremde Scripts installieren, Remote-Code ausführen, Repository-Einstellungen ändern oder sensible Inhalte an externe Dienste senden.
- Abhängigkeiten, Drittanbieter-Snippets und generierte AL-Objekte vor Übernahme auf Lizenz, API-Kompatibilität und mögliche Datenabflüsse prüfen.
- Git-Diff und Dateiliste vor Freigabe kontrollieren; keine unautorisierten Löschungen/Moves/Branch-Wechsel.

## Sicherheitsprüfplan für ein Ticket

- [ ] Betroffene Daten und Benutzerrollen identifiziert.
- [ ] Objekt- und TableData-Berechtigungen geprüft; keine unnötigen erweiterten Permissions.
- [ ] Eingaben validiert, Fehlermeldungen ohne Geheimnisse.
- [ ] API-Zugriffe, Webhooks, Outbound HTTP und Authentifizierung bewertet, falls vorhanden.
- [ ] Sandbox/Produktivgrenzen und Migration berücksichtigt.
- [ ] Sensible Logs, Tests und Dokumentation geprüft.

## Projektbezogene Angaben

| Thema | Freigegebene Festlegung | Stand |
| --- | --- | --- |
| Permission Sets / Rollen | Zu prüfen | Offen |
| Externe Schnittstellen | Zu prüfen | Offen |
| Secret-Verwaltung | Zu prüfen | Offen |
| Datenklassifizierung | Zu prüfen | Offen |
| Tenant / Mandant / Umgebungen | Zu prüfen | Offen |

AL-Kontext: https://alguidelines.dev/docs/agentic-coding/gettingstarted/setup/


## Spezifisch für BC Scenario Factory (Entwurfsanforderungen)

- Vor jeder Einrichtung, Generierung, Buchung und jedem Queue-Worker die **tatsächliche Umgebung** prüfen; Produktion sperren. Mandant/Firma, Umgebungstyp, erlaubte Operationen und ausführenden Benutzer verifizieren (nicht allein auf einen UI-Hinweis verlassen).
- User-Freigabe für Setup-Änderungen und Buchungen. Bei fehlenden Rechten **Preflight-Blocker**, kein stilles Ausweichen auf erhöhte Rechte.
- Alle Identitäten synthetisch; keine realen Kontakte, E-Mail-Versendung oder Zahlungsaufträge. Sicherstellen, dass Testdaten nicht versehentlich in produktive Integrationskanäle gelangen.
- Cleanup unterscheidet eigene ungebuchte Daten, gebuchte Dokumente und Ledgerposten. Gebuchte Daten niemals per pauschalem Delete entfernen; Reset durch neue Firma/Sandbox als Standardoption prüfen.
- Auch bei Job-Queue-Start aus Hintergrundsitzung Environment Guard und explizite Lauferlaubnis erneut prüfen.
- **XERJ** ist lokale Entwicklerhilfe und keine BC-Laufzeitanbindung. Kundencode/Datensätze nur bei vorliegender Berechtigung lokal indizieren; keine personenbezogenen Daten in den XERJ-Index übernehmen.


## Implementierte Foundation-Grenzen SF-003 (11.11.2026)

Guard 90375 prüft bei jeder Anfrage tatsächliches SaaS/Sandbox/Production-Merkmal, Umgebungsnamen, aktuelle/erlaubte Firma, Setup-Rechte, Generation-/Postingfreigabe und Mengenlimits. Die Before-Events für alle vier Setup-Schreiboperationen sind ohne Skip-Option gebunden und abhängig weder von GUI noch RunTrigger. Keine Sicherheitscache-, Test-/IsHandled- oder TryFunction-Umgehung. Core ruft Lifecycle nicht direkt auf; das Permission Set bündelt nur deklarativ dessen Execute-Recht. Tabelle/Codeunits sind Internal, was ausdrücklich keine Sicherheitsgrenze ersetzt.

`BCSF ADMIN`: nur Setup RIM und notwendige Table/Page/Codeunit-Ausführung; keine Delete- oder Standardbuchungsrechte und keine automatische Rollenzuweisung. Setup wird nur explizit und deaktiviert angelegt. Firma ist OrganizationIdentifiableInformation; keine Benutzerkennungen protokolliert. Produktroutine erzeugt derzeit keine Standard-BC-Daten. Künftige Generatoren/Worker müssen vor jeder Mutation den Guard erneut aufrufen und die konkreten Zielrechte/Freigaben prüfen. Der aktuelle Schutz bezieht sich auf die tatsächlich vorhandene Setup-Tabelle, keine behauptete Absicherung zukünftigen Codes. Vollständiger Vertrag: [FOUNDATION.md](FOUNDATION.md).

Build und statische Verdrahtung geprüft, aber keine Produktions-, Sandbox-, Rechte-, Security-Filter- oder Background-Laufzeittests durchgeführt. Diese Fälle stehen mit erwarteten Ergebnissen in [TESTS.md](TESTS.md).


## Erweiterung SF-005/SF-006

Vorlagen-/Zielschreiben bleibt sandboxgebunden, erlaubt aber Planung ohne aktivierte Generation/Buchung. Alle fünf neuen Tabellen besitzen verpflichtende Before-Sicherheitsereignisse. Zusätzliche Inhaltsevents verhindern direkte Persistenz ungültiger Mengen/Modi und jede Mutation erfasster Laufköpfe/Snapshots. Neue temporäre Anzeige-DTOs überspringen nur persistente Schreibprüfungen, haben keine Datenbankwirkung. Die bestehenden Setup-Events und der explizite Generierungs-Guard werden nicht gelockert.

Das ADMIN-Set erweitert sich um Konfigurationsrechte; Run Header/Snapshot lediglich R plus indirektes i. Nur Snapshot Writer hat direkte Insert-Rechte auf diese eigenen Tabellen. Keine Modify-/Delete-Rechte, kein beliebiger JSON-Eingabeparameter, keine Standard-BC-Schreibrechte und kein Commit. Fremde TryFunction-Aufrufer dürfen keine pauschale Rollback-Sicherheit unterstellen. Transaktions-/Sprach-/Datenklassifizierungsgrenzen: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md).

XLIFF-Dateien, Katalog und Tests enthalten ausschließlich App-Texte/synthetische Beispiele; keine Geheimnisse, Kundendaten oder Benutzerkennungen. Keine Sprachpräferenzen oder Server-/Tenant-Einstellungen automatisch geändert, keine Übersetzungsdienste aufgerufen.


## Aktueller Stand SF-007/SF-008 – 11.11.2026

Persistente Steps nur durch den Plan Writer mit eigener enger Insert-Berechtigung und indirektem Anwender-Insert. Vier verpflichtende Before-Datenbankereignisse prüfen Sandbox/Firma/Entwurf und sperren Modify/Delete/Rename. Zwei weitere Pflicht-Subscriber sichern Vertragsproben und Startprüfung. Vorschauen/Graph/Capabilities sind temporär; Probe-Generatoren erzeugen keine Geschäftsdaten. Aktuelle fehlende echte Generatoren/externe Nachweise verhindern Start. Keine zusätzlichen Standarddatenrechte oder automatischen Postingfreigaben.

Vertrag und Grenzen: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md). Status: **Zur Prüfung**, kein Deployment oder BC-Laufzeittest.

## SF-009/SF-010 – 15.11.2026

Setup-Diff ausschließlich temporär; Standarddaten nur gelesen. ADMIN vergibt zusätzliche Objekt-Ausführung, keine Standardtabellenrechte oder Rechteerhöhung. Fehlende Leserechte/blockierte Voraussetzungen bleiben sichtbar; das vorhandene Start-Gate bleibt geschlossen. Keine automatische Setupänderung oder persistierte Freigabe ohne konkrete Sollwerte. Die Seed-Engine liefert markierte synthetische Eingangswerte mit example.invalid, ohne Telefon-/Bankdaten und ohne Versand. Snapshot-Regeln bleiben unter dem bestehenden Schreibguard. Kein Laufzeitnachweis effektiver Rechte oder Sicherheitsfilter. Vollständige Grenzen: [SETUP_SEED.md](SETUP_SEED.md).

## SF-011/SF-012 – 15.11.2026

Neue eigene Tabellen: Herkunft nur Ri für Anwender und Insert im festen Registry Writer; Ausführung/Batches Rim für Anwender und begrenzte IM/M-Rechte in festen Writern. Keine neuen Standardtabellen-/Posting-/Jobrollenrechte im ADMIN-Set. Standardrollen, Lizenz und Task-Scheduler-Rechte sind separat erforderlich. Neue Pflichtsubscriber prüfen Sandbox/Firma, unveränderliche Identitäten, erlaubte Zustände, Batchbesitz und lückenlose Herkunft. Keine RunTrigger-/GUI-/IsHandled-Sicherheitsausnahme für Persistenz. Worker akzeptiert nur den gebundenen Standardjob und keinen manuellen Vordergrundaufruf.

BCSF.SER verwendet die Standard-Kategoriesemaphore; regulär ein aktiver Queue-Worker pro Firma, ein Job pro Run und ein Batch pro Job. Job-Autoretry ist 0, Recurring=false; PostingApproved bleibt false. Dauerhafter Claim vor Generatorausführung und NeedsReview bei gemeldetem Fehler verhindern blinden Wiederanlauf. Keine Namen/Adressen/rohen Fehlertexte im eigenen Audit, aber minimale RecordId/SystemId-Ergebnisbezüge als CustomerContent. Herkunftsmetadaten beweisen allein keine fachliche Postingbeziehung. Laufzeit-/Rechte-/Parallelitätsnachweise offen. [EXECUTION_REGISTRY.md](EXECUTION_REGISTRY.md).

## SF-013 – 16.11.2026

Kontrollanforderung und Checkpoint besitzen acht neue verpflichtende Datenbanksubscriber. Keine Standardtabellenrechte ergänzt; Active-Session-Metadaten müssen mit effektiven Standardrechten lesbar sein. Kein Session-Kill, keine arbeitsfreigebende Lease-Zeitgrenze, keine Wiederholung aufgrund fehlender Registry allein. Retryzähler/Jobbindung/Workeridentität sind an zulässige Übergänge gebunden. Checkpoints enthalten nur eingefrorene technische Identifikatoren, Sprache und bestätigte Zähler. Cancelanforderungen und Checkpoints sind nicht lösch- oder überschreibbar; Reconciliation führt keine fachliche Erstellung/Buchung aus. [RECOVERY.md](RECOVERY.md), echte Rechte-/Parallelitätsprüfung offen.

## SF-014/SF-015 – 16.11.2026

Monitoring-Lesen ohne Mutation oder automatische Wiederholung. Statusereignisse enthalten ausschließlich technische Metadaten und bestätigte Zähler; keine Fehlernutzdaten oder Benutzerkennungen. Vier verpflichtende Insert-/Modify-/Delete-/Rename-Prüfsubscriber, Ri im ADMIN-Set und I ausschließlich im festen Event-Writer; unveränderte Standardrechte. Historie und Übergang teilen die Transaktion. Wizardfreigabe gilt für den erfassten Run und führt durch bestehende aktuelle Start-Gates; keine Setup-/Postingfreigabe oder neuer Commit. Echte Rechte-/Security-Filter-/Produktions-/UI-Prüfung offen. [Vertrag und Grenzen](MONITORING_WIZARD.md), **Zur Prüfung**.

## SF-014 – JavaScript-Bedienoberfläche – 16.11.2026

Eigene gebündelte Ressourcen ohne externe Requests/Dependencies, kein innerHTML/eval/Clientstorage. Clientkommando wird über feste AL-Liste geprüft, Run-GUID begrenzt/geparst und aktuell per Get aufgelöst. Keine neuen erhöhten Codeunit- oder Standardtabellenrechte. Schreib-/Startaktionen verlangen die vorhandenen Guards sowie serverseitige Bestätigung; JS kann keine Postingfreigabe/Seiten-ID/Firma liefern. Neue Profilrolle ist keine Berechtigungsrolle und wird nicht automatisch zugewiesen. Keine automatischen Schreib-/Startaktionen beim Öffnen/Aktualisieren. [Vertrag, Einbau und Grenzen](DASHBOARD_EMBEDDING.md). Status **Zur Prüfung**, echte BC-Abnahme offen.
