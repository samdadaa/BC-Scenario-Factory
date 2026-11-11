# Grundlagenvertrag – SF-003 und SF-004

**Foundation-Stand SF-003/SF-004, 11.11.2026:** Implementiert, zur Prüfung. Die nachfolgenden Angaben beschreiben diese ursprüngliche Basis. Erweiterungen aus SF-005/SF-006 (Sprachfeld, Konfigurationsguard, erweiterte ADMIN-Rechte und eng begrenzte Snapshot-Insert-Permissions) stehen in [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md). Der Nutzer hat beide Tickets ausdrücklich gemeinsam beauftragt; keine automatische Folgeimplementierung. Lokaler Build mit CodeCop/UICop gegen BC-28.5-Symbole, Runtime 17. Reale Sandbox-/Rechteverifikation noch offen.

## Ziel, Scope und Risiken vor Umsetzung

SF-003 schützt die aktuell vorhandenen Schreibpfade und stellt einen wiederholt aufrufbaren Guard für spätere Generatoren/Worker bereit. SF-004 liefert kleine Core-Objekte für Einstellungen, Modi, IDs und Run-Zustände. Betroffen: neun neue AL-Dateien unter Core/Lifecycle, Objektplan, zentrale Projekt-/Architektur-/Sicherheits-/Testdokumentation, Modulindex, Core-/Lifecycle-Spezifikationen, README und nur SF-003/SF-004 in TODO.

Keine vorhandenen AL-Objekte, Feldschemas oder Tests existierten vor Beginn. app.json und launch.json bleiben unverändert; keine Installation, kein Deployment. ID-Zuordnung aus dem SF-002-Plan, zwei zusätzliche Core-Codeunits aus freien Werten 90106/90107. Seed-Engine, Generatoren, Run-/Batch-Tabellen, Queue-Worker und Test-App sind nicht Teil dieser Änderung. Neue AL-Testobjekte werden hier nicht in die App eingeschleust. Prüfschritte: echte Symbol-API prüfen, kompilieren/Analyzer, ID-/Pfad-/Event-/Berechtigungsprüfung, Laufzeit-Prüffälle gesondert dokumentieren.

Offene fachliche Voraussetzungen aus SF-001: exakter Publisher, tatsächlich isolierte Testfirma, echte Umgebungs-/Rechteprüfung. Lokale Pakete weisen DE aus, bestätigen aber weder den Firmenzustand noch die tatsächliche Sandbox-Version. Keine unbekannten Firmen-/Kundendaten oder Zugangsdaten werden übernommen. Technische Defaults sind keine fachlichen Mengenzusagen.

## Einstellungen und Bedienung

`BCSF Factory Setup` ist ein firmenabhängiger Singleton mit Schlüssel `SETUP`. Die Setup-Card ist über die Suche als „Scenario Factory Setup“ erreichbar. Öffnen/Lesen initialisiert keine Daten. Die Aktion „Initialize Setup“ erzeugt erst nach Guard-Prüfung einen Datensatz; wiederholter Aufruf erhält bestehende Werte. Keine Install-/Upgrade-Schreiblogik.

Defaults: Generation aus, Posting aus, erlaubte Umgebung `Playground`, Firma der expliziten Initialisierung, Prozessmodus Setup/Stamm, Nutzung Demo, Seed 1, vorgeschlagene Batchgröße 100, maximale Batchgröße 1.000, Maximum je Entität 100.000. Alle Integer-Seeds sind erlaubt; SF-010 implementiert erst die Seed-Engine. Mengenlimits sind konfigurierbare technische Ausgangswerte, keine Laufzeitgarantie. Datenziele pro Entität und Zeiträume folgen SF-005/006, nicht als erfundene Felder dieser Tabelle.

Vor Nutzung eine isolierte Testfirma ausdrücklich prüfen, Einstellungen dort initialisieren und Generation bewusst aktivieren. Posting benötigt zusätzlich „Posting Enabled“ und eine Freigabe für den konkreten Aufruf. Änderungen bleiben firmenbezogen. Umbenennen und Löschen des Setups sind gesperrt; zum Stoppen Generation deaktivieren.

`ValidateSettings()` prüft den Singleton-Schlüssel, Pflichtangaben, positive Mengen, `Default Batch Size <= Maximum Batch Size <= Maximum Records per Entity`, gültige Prozess-/Nutzungsmodi und Posting-Erlaubnis für buchende Defaultmodi. Prüfung des gesamten Datensatzes bei Insert/Modify und in den Lifecycle-Datenbank-Events: direkte Feldzuweisung ohne `Validate()` bzw. `Insert(false)`/`Modify(false)` soll die Prüfung ebenso erreichen. Dieses Verhalten ist anhand der Event-Verträge implementiert, aber in BC noch zu verifizieren.

## Sicherheitsvertrag und Berechtigungen

`BCSF Environment Guard.EnsureCanGenerate(TargetCompanyName, ProcessMode, RequestedRecords, RequestedBatchSize, PostingApproved)` prüft bei jedem Aufruf:

1. tatsächliche Production/SaaS/Sandbox-Metadaten aus Microsofts `System.Environment.Environment Information`; Produktion, On-Premises und unbekannte Umgebungen werden abgewiesen;
2. explizites Zielunternehmen entspricht der Sitzung, keine Cross-Company-Verarbeitung;
3. effektive Read-/WritePermission auf das Setup und vorhandenen gültigen Setup-Datensatz;
4. tatsächlicher Umgebungsname und Firma entsprechen den gespeicherten Freigaben;
5. Generation ist aktiviert, Mengen/Batchgröße positiv und innerhalb der Limits, Batchgröße nicht größer als das Entitätsziel;
6. buchende Modi nur mit aktiviertem Posting und explizit übergebenem `PostingApproved`; unbekannte Modi werden abgewiesen.

Der Zustimmungsparameter ist keine automatische oder interaktive Zustimmung: spätere Worker müssen ihn aus dem genehmigten Run-Snapshot ableiten, den Guard erneut aufrufen und zusätzliche Rechte auf ihre konkreten BC-Zieltabellen prüfen. Als Zielunternehmen ist die tatsächliche `CurrentCompany()` des Zieldatensatzes zu übergeben, nicht blind der Sitzungsname. Die jetzige Berechtigungsprüfung gibt keine Standard-Postingrechte. Es existieren noch keine Generatoren/Queue-Worker, daher auch kein behaupteter Schutz noch nicht implementierter Pfade. Ein zukünftiger schreibender Einstieg darf den Guard nicht auslassen.

Setup-Insert/Modify werden durch `OnBeforeInsertEvent`/`OnBeforeModifyEvent` geschützt, Delete/Rename durch entsprechende Before-Events immer abgewiesen. Subscriber sind statisch gebunden, `SkipOnMissingLicense = false`, `SkipOnMissingPermission = false`; keine Ausnahme für GUI, Background, RunTrigger oder temporäre Records. Keine `TryFunction`, kein expliziter Commit, keine erhöhten Permissions, kein IsHandled-/Test-Bypass und kein gecachtes Sicherheitsergebnis.

`BCSF ADMIN` ist manuell zuzuweisen und enthält nur Setup-TableData RIM, Table/Page-Ausführung und Execute der drei Foundation-Codeunits. Kein Delete, keine Standard-BC-TableData-Rechte, keine Benutzer-/Rollenzuweisung und keine Berechtigungserhöhung im Code. Berechtigungsbezeichnung ist keine harte Rollenprüfung; wir prüfen die tatsächlich effektiven Rechte. BC-Sicherheitsfilter und die Datenbankberechtigungsprüfung bleiben wirksam; eine WritePermission-Prüfung ersetzt sie nicht. `Access = Internal` ist ausschließlich eine Compilezeitgrenze, kein Sicherheitsmechanismus. Firma wird als OrganizationIdentifiableInformation klassifiziert; keine persönlichen Benutzerkennungen gespeichert oder ausgegeben.

## IDs und Zustandsübergänge

`EnsureRunId(var Guid)` und `EnsureBatchId(var Guid)` vergeben nur für einen leeren GUID-Wert `CreateGuid()`. Nichtleere Werte bleiben erhalten. Aufrufer müssen IDs einmal persistieren und auf Retry wieder laden. Diese Helfer erstellen weder Lauf noch Batch und garantieren noch keine Idempotenz fachlicher Schreiboperationen.

`CanTransition`/`CheckTransition` prüfen nur den folgenden Graphen. Gleichbleibender gültiger Status ist ein zulässiger No-op, unbekannte Werte sind unzulässig. Die Funktionen schreiben nichts und genehmigen keinen Resume/Retry/Commit.

| Aktueller Status (Enumwert) | Erlaubte andere Zielzustände |
| --- | --- |
| Draft (0) | Preflight, Cancelled |
| Preflight (1) | Ready, PreflightFailed, Cancelled |
| PreflightFailed (2) | Draft, Preflight, Cancelled |
| Ready (3) | Preflight, Queued, Scheduled, Cancelled |
| Queued (4), Scheduled (5) | Running, Paused, Failed, Cancelled |
| Running (6) | Paused, Completed, CompletedWithWarnings, Failed, Cancelled |
| Paused (7), Failed (11) | ResumePending, Cancelled |
| ResumePending (8) | Preflight, Failed, Cancelled |
| Completed (9), CompletedWithWarnings (10), Cancelled (12) | Keine anderen Zustände |

Resume führt über Preflight; Failed kann nicht direkt zu Running wechseln. Completed erfordert später fachliche Validierung durch den Aufrufer. Cancelled bedeutet keine Rückabwicklung bereits gebuchter Ergebnisse. SF-005/012/013/016 setzen Zustandsübergänge und Claim-/Commit-/Validierungsregeln erst auf persistierten Datensätzen durch.

## Transaktionen und Kompatibilität

Initialisierung: LockTable, Existenzprüfung, Defaults, Insert(true), kein eigener Commit. Fehler vor Insert/Modify verhindern diese Operation; keine Zusage eines allgemeinen Rollbacks um externe Standardbuchungen. Core kennt ausführbar keine Lifecycle-Codeunit: Datenbankereignisse liefern die Sicherheitsbindung. Das Core-Permission-Set referenziert den Guard nur deklarativ und bildet die dokumentierte Ausnahme zur Modulabhängigkeit.

Initialer Compileraufruf über systemweites dotnet scheiterte: .NET 10 fehlt dort (.NET 8.0.8 vorhanden). Der bereits installierte VS-Code-Cache enthält .NET 10.0.15; darüber läuft AL Compiler 18.1.43.24897. Keine Installation nötig. Symbolpakete: System 28.0.57066.0, System Application/Base Application 28.5.54976.57342, Application/Business Foundation 28.5.54976.56550. Environment-APIs gegen diese lokalen Microsoft-Symbole/Quellen geprüft. app.json bleibt Application 28.0.0.0, Runtime 17.0, IDs 90100–90999. Das ist kein Nachweis gegen eine nicht lokal vorhandene ursprüngliche BC-28.0-Symbolversion.

Quellen: [Environment Information](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.environment.environment-information), [Before-Modify-Datenbankevent](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/events/table/devenv-onbeforemodifyevent-table-trigger), [WritePermission](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-writepermission-method), [Access-Grenzen](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-access-property), geprüft am 11.11.2026; maßgeblich für den Build sind die lokalen Pakete. Tatsächliche Tests und noch auszuführende BC-Fälle: [TESTS.md](TESTS.md).
