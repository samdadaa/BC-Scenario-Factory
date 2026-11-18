# Architekturdiagramme – Stand SF-018

Die Diagramme zeigen den vorhandenen Quellstand, nicht den kompletten geplanten Produktumfang. Dargestellt sind fachliche Daten- und Steuerflüsse, keine vollständige Auflistung der AL-Imports. Die Mermaid-Blöcke bleiben als Markdown editierbar.

## 1 · Vom Szenario zum Ergebnis

```mermaid
flowchart TD
    UI["Assistent oder Szenariokarte"] --> Draft["Editierbare Vorlage"]
    Draft --> Cap["Lauf unveränderlich erfassen"]
    Cap --> Plan["Abhängigkeiten prüfen und Plan speichern"]
    Cap --> Pre["Einrichtung und Bindungen prüfen"]
    Plan --> Gate{"Plan und Prüfungen gültig?"}
    Pre --> Gate
    Gate -->|Nein| Fix["Blocker anzeigen"]
    Fix -->|Eingaben korrigiert| Draft
    Gate -->|Ja, explizit freigegeben| Queue["Pakete vorbereiten und Job einplanen"]
    Queue --> Gen["Debitoren- oder Kreditorengenerator"]
    Gen --> Confirm["Standardpartner, Herkunft und Checkpoint"]
    Confirm --> Check["Laufabschluss prüfen"]
    Check --> View["Status, Befunde und Ergebnisse"]
```

Vorschau und Plan starten nichts. Nur reine positive Debitoren-/Kreditorenziele können den aktuell ausgeführten Fachpfad nutzen. Die Generatorbindung wird gegen den gespeicherten Plan erneut geprüft. Bei Änderung erfasster Eingaben neu erfassen.

Quellen: [Snapshot Writer](../../src/ScenarioManagement/Codeunits/BCSFSnapshotWriter.Codeunit.al), [Plan Writer](../../src/DependencyManager/Codeunits/BCSFPlanWriter.Codeunit.al), [Setup Manager](../../src/SetupManager/Codeunits/BCSFSetupManager.Codeunit.al).

## 2 · Queue und Transaktionsgrenzen

```mermaid
sequenceDiagram
    participant D as Dispatcher
    participant Q as BC-Aufgabenwarteschlange
    participant W as Batch Worker und Runner
    participant G as Partnergenerator
    participant V as Herkunft und Validierung
    D->>Q: Nächsten Job einplanen
    Q->>W: Geplantes Paket aufrufen
    W->>W: Guard, Jobbesitz und Claim prüfen
    Note over W: Claim wird vor Facharbeit gespeichert
    W->>G: Erfassten Schlüsselbereich ausführen
    G->>G: Nummernserie, Validate und Insert
    G->>V: System-ID und Rolle registrieren
    G-->>W: Ergebnis mit Zählern
    W->>V: Output prüfen und Checkpoint speichern
    alt Weitere Arbeit ohne Stopanforderung
        W->>D: Nächstes Paket einplanen
    else Alle Pakete bestätigt und Abschluss möglich
        W->>V: Abschlussprüfung und Laufsummary
    else Stopanforderung an Paketgrenze
        W->>W: Pause oder Abbruch anwenden
    end
```

Der Claim hat eine eigene Persistenzgrenze. Danach sollen Standarddaten, Herkunft, Checkpoint, bestätigter Paketstatus und der Folgeschritt gemeinsam persistieren. Ein fehlgeschlagener übernommener Batch kann zur Prüfung markiert werden. Kein blindes Replay. Standardtrigger/Fremderweiterungen und realer Queue-Betrieb sind gesondert in der Sandbox zu testen. `BCSF.SER` ist die Queue-Kategorie.

Quellen: [Worker](../../src/BackgroundProcessing/Codeunits/BCSFBatchWorker.Codeunit.al), [Runner](../../src/BackgroundProcessing/Codeunits/BCSFBatchRunner.Codeunit.al), [Dispatcher](../../src/BackgroundProcessing/Codeunits/BCSFQueueDispatcher.Codeunit.al), [Recovery](../RECOVERY.md).

## 3 · Persistente Daten

```mermaid
erDiagram
    VORLAGE ||--o{ MODULWAHL : konfiguriert
    VORLAGE ||--o{ ENTITAETSZIEL : definiert
    VORLAGE ||--o{ LAUFKOPF : wird_erfasst_als
    LAUFKOPF ||--|| SNAPSHOT : friert_ein
    LAUFKOPF ||--o{ PLANSCHRITT : speichert
    LAUFKOPF ||--o| AUSFUEHRUNG : besitzt
    AUSFUEHRUNG ||--o{ PAKET : verarbeitet
    PLANSCHRITT ||--o{ PAKET : zerlegt
    PAKET ||--o| CHECKPOINT : bestaetigt
    PAKET ||--o{ HERKUNFT : erfasst
    LAUFKOPF ||--o{ PRUEFBEFUND : dokumentiert
    HERKUNFT }o--|| STANDARDPARTNER : referenziert
```

Logische Beziehungen, keine SQL-Fremdschlüsselbehauptung. Der erfasste Kopf behält seinen Anfangszustand. Der operative Status kommt aus `BCSF Run Execution`, die Abschlussqualität aus dem Befund. Herkunft referenziert Standardpartner über System-ID. Finanzpaket und App-Setup sind mandantenbezogen. Paketidentität und Partnerregeln stehen als Werte im Snapshot.

Quellen: [ScenarioManagement-Tabellen](../../src/ScenarioManagement/Tables), [Ausführungstabellen](../../src/BackgroundProcessing/Tables), [Herkunft](../../src/DataGeneration/Tables/BCSFGeneratedRecord.Table.al), [Befund](../../src/Validation/Tables/BCSFValidationResult.Table.al).

## 4 · Laufstatus aus Anwendersicht

```mermaid
stateDiagram-v2
    [*] --> Erfasst
    Erfasst --> Bereit: gültiger Plan und Vorbereitung
    Bereit --> Wartet: ausdrücklich eingeplant
    Wartet --> Laeuft: erster Claim
    Wartet --> Pausiert: vor einem Claim
    Laeuft --> Pausiert: sichere Paketgrenze
    Pausiert --> Wartet: geprüft fortsetzen
    Laeuft --> Abgebrochen: Abbruchgrenze erreicht
    Laeuft --> Fehler: Ausführung fehlgeschlagen
    Laeuft --> Abgeschlossen: alle Pflichtchecks bestanden
    Laeuft --> Warnungen: Pflichtchecks bestanden
    Laeuft --> ValidierungFehlgeschlagen: Pflichtbefund negativ
```

Vereinfachte Ansicht, keine vollständige Transitionstabelle. **Erfasst** heißt ohne vorbereitete Ausführung, **Wartet** fasst eingeplant und wartend zusammen. Fehler und fehlgeschlagene Validierung haben unterschiedliche Ursachen, nicht automatisch wiederholen. Abbruch beendet ein laufendes Paket nicht sofort und löscht keine Ergebnisse.

Quellen: [Status-Enum](../../src/Core/Enums/BCSFRunStatus.Enum.al), [Ausführungsregeln](../../src/BackgroundProcessing/Codeunits/BCSFExecutionRules.Codeunit.al), [Laufabschluss](../../src/BackgroundProcessing/Codeunits/BCSFRunQuality.Codeunit.al).

## 5 · Dashboard und native Navigation

```mermaid
flowchart TD
    Surface["Role Center oder Dashboardseite"] --> Part["AL Dashboard Part"]
    Part --> Addin["JS Control Add-in"]
    Addin -->|Listenwahl oder Klick| Cmd["AL Dashboard Commands"]
    Cmd --> Nav{"Welche Aktion?"}
    Nav -->|Lesen und öffnen| Pages["Native Lauf-, Setup- und Ergebnislisten"]
    Nav -->|Änderung| Gate["Bestätigung und serverseitige Prüfpunkte"]
    Gate --> Service["Plan, Dispatcher oder Recovery"]
    Part --> Projection["Dashboard Data liest gespeicherten Zustand"]
    Projection -->|JSON| Addin
```

JS zeigt Daten und meldet Aktionscodes. AL entscheidet über zulässige Ausführung. Die native Laufkarte ist als Diagnoseweg geeignet, wenn im JS ein Drilldown fehlt.

Quellen: [Dashboard Part](../../src/Monitoring/Pages/BCSFDashboardPart.Page.al), [Commands](../../src/Monitoring/Codeunits/BCSFDashboardCommands.Codeunit.al), [Datenprojektion](../../src/Monitoring/Codeunits/BCSFDashboardData.Codeunit.al).

## Pflege beim nächsten Ticket

Nur betroffene Diagramme ändern. Neue Konfiguration, persistierte Ausführung und ausgeliefertes UI getrennt kennzeichnen. Bei einem neuen Generator den tatsächlich eingeführten fachlichen Pfad ergänzen. Modulzuordnung und AL-IDs stehen im [Inventar](MODULINVENTAR.md).
