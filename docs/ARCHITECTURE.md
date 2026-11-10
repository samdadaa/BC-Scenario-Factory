# Zielarchitektur (Planung – noch nicht implementiert)

**Status:** Entwurfsarchitektur aus bestätigter Produktidee; keine technischen Komponenten sind in AL bereits umgesetzt. `docs/modules/INDEX.md` kennzeichnet alle Module als geplant.

## End-to-End

```text
Wizard / Scenario Card / Dashboard
         |
Scenario Configuration (Branche, Module, Mengen je Entität, Seed, Zeitraum, Umfang)
         |
Environment Guard + Preflight + Permission Checks
         |
Profile Resolver -> Module Registry -> Dependency Graph -> Setup Plan
         |
Generation Plan (Schritte, Reihenfolge, geschätzte Arbeitspakete)
         |
Job Queue Dispatcher / Worker / Batch Ledger / Checkpoints
         |
Data Generation Engine   -> Stammdaten und konsistente Beziehungen
Process Engine           -> Dokumente / optionale Standardbuchungen / Zahlungen
         |
Validation / Quality     -> Soll-Ist, Beziehungen, Ledger, Business Rules
         |
Run History / Monitoring / Exporte / Lifecycle & Safety
```

## Schichten

- **Fachkonfiguration:** Unveränderlicher Lauf-Snapshot; erkennbarer Szenario-Typ (Demo, Training, Functional, Performance), Branchenprofil mit Versionsstand, Mengen je Entität, Datenverteilung, Zeitfenster und Seed.
- **Planner:** Dependency Manager prüft gerichteten Abhängigkeitsgraph, erkennt Zyklen, unterscheidet zwingende Vorbedingungen, optionale Schritte und externe Abhängigkeiten. Setup Manager erzeugt einen **Preview-/Freigabeplan** für erforderliche Einrichtungen.
- **Engines:** Data Generation Engine erzeugt semantisch valide Stammdaten/Beziehungen. Process Engine erzeugt wahlweise ungebuchte Dokumente oder verwendet **Standard-BC-Posting-Codeunits** nach Prüfung der konkreten API/Version; keine Inserts direkt in Ledger Entries.
- **Execution:** Background Processing plant verarbeitbare, idempotent ausgelegte Batches. Dashboard liest persistente Statusdaten; keine Abhängigkeit von offener Browser-Sitzung.
- **Validation/Guard:** Vergleicht Ziele mit tatsächlich erzeugten Daten, prüft Posten/Konsistenz und verhindert produktive/destruktive Aktionen.

## Geplante zentrale Persistenz (logische Entitäten, keine festgelegten AL-Objektnamen)

| Entität | Inhalt / Primärbeziehung |
| --- | --- |
| Factory Setup | Globale Defaults, zulässige Sandbox-/Mandantenstrategie, Limits |
| Scenario Definition | Wiederverwendbare Vorlage, Branche, Seed, Datumsspanne |
| Scenario Module Selection | Welche Generatoren und Modi pro Szenario |
| Scenario Data Target | Gewünschte Menge **je Entität** statt globaler unklarer Zahl |
| Scenario Profile Rule | Parameter, Datenverteilungen, realistische Geschäftswahrscheinlichkeiten |
| Run Header | Snapshotted Konfiguration, Owner, Zustand, Start/Ende |
| Run Step | Modul/Generator, Abhängigkeit, Soll/Ist, Zustand |
| Batch | Eindeutige Batch-ID, Zustandsmaschine, Versuche, Checkpoint, Fehler |
| Generated Record Registry | Zuordnung `Run/Step/Entity/LogicalKey` zu erzeugten Records und Herkunft |
| Validation Result | Prüfregel, Objekt-/Datensatzbezug, Schweregrad, Ergebnis |
| Run Event / Metrics | Zeit, Mengen, Fortschritt, knappe Fehlertypen |

**Entwurfsregel:** Für Referenzen auf standardmäßige Posting-Ergebnisse einen geeigneten stabilen Schlüssel/Verknüpfungsweg ermitteln; RecordId allein ist keine über alle Folgeprozesse passende universelle Kennung. Datenmodell und Aufbewahrung müssen vor dem Coding konkretisiert werden.

## Generatorschnittstelle (Konzept, keine festgelegte AL-Signatur)

- `DescribeCapabilities`: unterstützte Entitäten, Modi, benötigte Module/Versionen.
- `CheckPrerequisites`: liest Setup/Abhängigkeiten, meldet Blocker.
- `PlanBatches`: zerlegt Ziel in deterministische, nicht überlappende Arbeitsbereiche.
- `ExecuteBatch`: erstellt Daten nach den Constraints, protokolliert Erfolg/Fehler.
- `ValidateOutput`: prüft erwartete fachliche Beziehungen und Mengen.
- `Resume`: verarbeitet nur nachweislich fehlende/incomplete Einheiten.

AL-Interfaces, Enums/Registrierungsstrategie, Übergabeparameter und Datenbanktransaktionsgrenzen müssen **vor Implementierung** im Ticket freigegeben und anhand der BC-Version überprüft werden. Keine generischen dynamischen Inserts, die Validierung und Business-Logik umgehen.

## Transaktions- und Wiederaufnahmestrategie

**Laufzustände:** Draft → Preflight → Ready → Queued → Running → Completed / CompletedWithWarnings / Failed / Cancelled. Unterbrochene Läufe können Paused / ResumePending werden (konkrete AL-Zustände noch zu definieren).

**Batchzustände:** Pending → Claimed/Running → Completed bzw. Failed/RetryPending. Checkpoints nur nach tatsächlich persistierten fachlichen Ergebnissen. Sperren/Leases und konkurrierende Queue-Sessions prüfen. Bei unklaren Commit-Ausgängen zuerst erzeugte Datensätze recherchieren, **nicht blind erneut buchen**. Wiederholung ist je Generator nachzuweisen, nicht pauschal vorauszusetzen. Kontrollierte Fehlerisolation (nicht jeder Fehler darf zum Abbruch des gesamten Laufs führen) und Dead-Letter-/manuelle Prüfung für dauerhafte Fehler.

Für unterschiedliche Arbeitsarten variable Batchgrößen (Stammdaten ≠ Buchungsprozesse), Laufzeitbudgets und Queue-Last. Gesamtlaufzeit nicht garantieren. Keine Annahme, dass parallele Jobs in einer BC-SaaS-Umgebung beliebig skalieren.

## Abhängigkeitsmuster (Handel)

Finanz-Grundsetup (Buchungsgruppen, Nummernserien, Steuer-/MWSt.-Kontext, Zahlungsbedingungen, Dimensionen, Bank/Lager-Setup) → Debitoren, Kreditoren, Artikel/Lagerorte → Einkauf/Wareneingang/Lagerbestand → Verkauf/Lieferung/Rechnung → optional Zahlung/Ausgleich. Je nach Beleg- und Bestandsmodus einzelne Vorbedingungen zusätzlich erforderlich.

## Erweiterbarkeit und Grenzen

Neue Industrieprofile konfigurieren die vorhandenen Fachgeneratoren. Weitere ISV-/Branchen-Generatoren können **erst nach festgelegtem Interfacevertrag** registriert werden. Nicht jedes Standard-BC-Modul ist in jeder Lizenz/Lokalisierung vorhanden; Features zur Laufzeit geprüft. XERJ/Codex sind Entwicklungswerkzeuge außerhalb von BC und **nicht Bestandteil** der Extension.
