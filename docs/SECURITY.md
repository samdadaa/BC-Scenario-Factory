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


## SF-016/SF-017 – 18.11.2026

Validation Result und Finance Package jeweils mit vier verpflichtenden Before-DB-Subscribern: Sandbox-/Firmenbindung vor Insert, Modify/Delete/Rename gesperrt, auch ohne Tabellentrigger. Validation prüft vollständige und aktuelle Pflichtnachweise; Summary kann ohne alle abgeschlossenen Batches und deren Befunde nicht eingefügt werden. Paketvermerk erst nach vollständiger konsistenter Einrichtung. Vorhandene Ri-Anwenderrechte und enges I im jeweiligen Writer erhalten; keine zusätzlichen Standardrechte.

Apply bleibt ausdrücklich bestätigte Aktion mit CommitBehavior::Error, erneuter Konfliktprüfung und ausschließlich Inserts fehlender Standard-Einrichtungen. Geprüfte Standard-Insert-Trigger können reguläre BC-Nebenwirkungen wie Dimensionspflege auslösen; keine direkten Standardposten-Inserts. SecurityFiltering::Disallowed für Paket-/Konten-/Matrix-/Berichtsvergleich sowie Foundation-/Nummernseriennachweise. Bestehende Einrichtung wird durch Existing nicht verändert. Produktion, Paketwechsel und initiale Anwendung in bebuchter Firma blockiert. [Vertrag und offene Rechte-/Parallelitätsfälle](VALIDATION_FINANCE.md). Keine Sandbox- oder Security-Filter-Laufzeitabnahme behauptet.


## SF-018 – 18.11.2026

Erste schreibende Fachgeneratoren: ausschließlich Customer/Vendor über Standard-Validate/Insert(true), nach Pflichtprüfung von tatsächlicher Sandbox/Firma/Generationserlaubnis, unverändertem Snapshot und eindeutig gebundenem laufendem Standard-Queuejob/Batch/Worker. Keine zusätzlichen Standard-TableData-Rechte im ADMIN-Set oder Codeunit-Permissions. Standardrollen einschließlich Number Series, Marketing Setup und ggf. Contact/Contact Business Relation bleiben erforderlich. Kontext und Schlüsselbereiche dürfen nicht vom Client ersetzt werden.

Keine echten personenbezogenen Identitäten, Telefon-/USt.-/Bankdaten oder Versandaktionen. Feldwerte sind markiert synthetisch, E-Mail nur example.invalid. Standardkontakte können gemäß aktueller, erfasster CRM-Bindung entstehen. Vorhandene Partner werden nicht wiederverwendet/geändert; Herkunft und führender Datensatz bleiben atomar. Nur lesende Prerequisite-TryFunctions, Fehlertexte ausschließlich in temporären Setupbefunden; keine persistente Kopie in eigenes Audit. [Sicherheitsvertrag und noch offene BC-Fälle](PARTNER_GENERATION.md). Keine behauptete Sandbox-/Berechtigungs-/Drittanbieter-Commitabnahme.

## SF-021 – explizite Verkaufsbuchung

Globaler Buchungsschalter bleibt erforderlich. Neue Vorlagenzustimmung standardmäßig aus, bei Kopie/Import zurückgesetzt; nur im unveränderlichen salesSetup-Snapshot und für exakt gespeicherte SALES.DOCUMENT-Version-1-Steps wirksam. Start-, Hintergrund- und Herkunftsguards prüfen dieselbe enge Zustimmung sowie aktuellen Sandbox-/Mandantenkontext und globale Freigabe. Andere Generatoren/alte Snapshots erhalten keine Zustimmung. Keine zusätzlichen Standardtabledata-Rechte. Frische atomare Beleganlage/Standardbuchung ohne booleschen Codeunit.Run, ohne Schreib-TryFunction und ohne eigene Commits. Fehlende Rechte/Quelle/Bestand oder Fremdcommits brechen ab; unsicheres Posting bleibt ohne Retry. Keine Veröffentlichung ausgeführt. [Vertrag und negative Prüffälle](SALES_PROCESS.md).

## SF-045 – Unternehmensjob

Expliziter Start autorisiert die angezeigte fehlende Foundation und ungebuchte Daten. Der Job prüft tatsächliche Sandbox/Firma, effektive Rechte und gespeicherte Standardjob-/Sitzungsidentität erneut. Requestdaten werden auch bei Modify(false) gegen den gespeicherten Vorzustand geschützt; vorhandene Anfrage blockiert Doppelstart. CommitBehavior::Error umschließt Vorbereitung und spätere fachliche Batches. Autoretry 0; keine Veröffentlichung, Rechteerhöhung, Fremdskriptinstallation oder Standard-Ledger-Inserts. Standardfehler werden nur lesend aus der aktuellen Queue angezeigt, nicht in neue Logs kopiert. Native Sicherheits-/Parallelitätsabnahme offen.


## 1.0.7.0 – indirekte Standardbuchungsrechte

Gebuchte Tabellen werden durch BC-Standardcodeunits geschrieben. Environment Guard prüft effektive zugewiesene Insertrechte Yes/Indirect, bei Ausgleich zusätzlich Modify sowie Leserecht und Standard-Codeunit-Ausführungsrecht. Keine direkte WritePermission-Pflicht auf gebuchten Tabellen, keine neuen Ledgerrechte in BCSF ADMIN. Ungebuchte Belege benötigen weiterhin direkte Schreibrechte. Explizite separate Buchungsfreigaben werden beim Kopieren/Import zurückgesetzt; paymentSetup bindet nur synthetische Bank ohne externe Kennungen. Laufzeit-/Sandbox-/Claim-/Transaktionsgrenzen gelten auch im Hintergrund. [Gemeldeter Fehler und Korrektur](INDUSTRY_INITIALIZATION.md#gemeldeter-berechtigungsfehler-und-korrektur). Rechteprüfung mit realen Standardrollen noch offen.


## 1.0.7.1 – Dashboardlisten

Keine neue Standard-TableData-Berechtigung. Mappingseite 90370 erfordert Page-X und vorhandene Tabellenleserechte, ist nicht editierbar und verbietet Insert/Modify/Delete. Herkunftszählung basiert weiter auf sichtbaren eindeutigen SystemIds; Dokument-/Zuständigkeits-/Securityfilter bleiben beim Markieren und typisierten Listentransfer erhalten. Klick prüft aktuelle Zahl/Rechte erneut, kein unbeschränkter Fallback. Native Standardseitentrigger und Rollenabnahme offen.

## SF-022 – Auswahl im Unternehmensrequest 1.0.7.2

Kanonische Planungsmodulcodes vor Einplanung und vor Hintergrundvorbereitung validieren; eingefrorenes Setupfeld 27 auch über den vorhandenen OnBeforeModifyEvent-Subscriber bei Modify(false) schützen. Optionale Module erzeugen keine Ziele, Daten oder Rechte. Temporäre historische Modulansicht bleibt feldweise nicht editierbar; Auswahlmodus ist intern und schreibt nur temporäre Zeilen. Keine neuen Standardtabellenrechte, externen Dienste oder Buchungsfreigaben. [Umsetzung/offene native Sicherheitsprüfung](INDUSTRY_INITIALIZATION.md#sf-022--modulauswahl-1072).

## SF-022 – Datumsrequest 1.0.7.3

Startdatum und additives Enddatumsfeld 28 nach Einplanung unveränderlich, auch bei Modify(false). Start prüft gefüllten Zeitraum mit Ende gestern, Hintergrund übernimmt die gespeicherte Grenze. Keine automatische Erweiterung von Buchungsperioden, Benutzerrechten oder Nummernserien. Historische Captures ohne Datumsmarker behalten ihre Regel; neue verwenden versionierten Vertrag, unbekannte Versionen werden abgewiesen. Technische BC-Auditzeitpunkte bleiben tatsächlich aktuell. [Vertrag/native Prüfung](INDUSTRY_INITIALIZATION.md#sf-022--datumszeitraum-1073).
