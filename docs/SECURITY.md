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
