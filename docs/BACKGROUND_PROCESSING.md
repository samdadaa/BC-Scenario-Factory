# Hintergrundverarbeitung und Wiederaufnahme

**Status:** Zielbild. Die ZIP enthält noch keine Queue-Codeunits, Tabellen oder Session-Logik.

## Warum Batching?

Große Läufe dürfen die interaktive Sitzung nicht blockieren. Ein einzelner Job mit 80.000 Datensätzen ist fehleranfällig: einzelne Fehlfälle, Serviceunterbrechungen, Commit-Zustände, Locks und Timeouts. Deshalb Dispatcher → klar abgegrenzte Batch-Worker → Checkpoints → Validierung.

## Geplanter Ablauf

1. **Preflight** prüft Sandbox, Rechte, Abhängigkeiten, Mindest-Setup, verfügbare Module, Volumengrenzen.
2. **Plan einfrieren:** Szenario-Konfiguration versionieren und pro Modul/Entität nicht überlappende, deterministische Arbeitsbatches erzeugen.
3. **Queue:** Dispatcher startet kontrolliert einen/few Job Queue Entries. Parallelität nicht blind erhöhen; tatsächliche Plattform-/Tenant-Grenzen beachten.
4. **Claim:** Worker reserviert einen Batch atomar soweit BC erlaubt und ermittelt den letzten sicher persistierten Schritt.
5. **Execute:** Standardvalidierungen/-buchungen ausführen; Ergebnisse protokollieren; bei Batchende Commitstrategie nur nach Designprüfung.
6. **Checkpoint:** erst nach überprüfbar persistierten Ergebnissen auf `Completed` stellen; bei ungewisser Buchungsantwort `NeedsReview`.
7. **Recovery:** fehlgeschlagene Batches nach Analyse erneut ansetzen; keine blinde Doppelbuchung; wiederholte Fehlversuche mit Limit und manueller Freigabe.
8. **Validation:** Soll/Ist, Beziehungen und Buchungsergebnisse prüfen; erst dann Gesamtlauf abgeschlossen melden.

## Zustände und Aktionen

- Run: Draft, PreflightFailed, Ready, Scheduled, Running, Paused, Completed, CompletedWithWarnings, Failed, Cancelled (präzise AL-Enums noch festzulegen).
- Batch: Pending, Running, Completed, RetryPending, Failed, NeedsReview, Cancelled.
- Operator: Start, Pause/Resume, Retry Failed, View Errors, Cancel (wirkt auf *noch nicht gestartete* Arbeit); manuelle Freigabe für riskante Buchungswiederholung.

## Kritische Sonderfälle

| Situation | Verlangtes Verhalten |
| --- | --- |
| Queue-Job fällt nach 18.000/80.000 Datensätzen aus | 18.000 bestätigte Ergebnisse bleiben erhalten, übrige werden korrekt weiter geplant; keine Datensatzlücken/ Duplikate |
| Fehler in 1 von 1.000 Datensätzen | Nach Fehlerklasse isolieren und fortfahren bzw. gesamten Batch pausieren; die Fachregel bestimmt den Umgang |
| Buchung erfolgt, Statusspeicherung fällt aus | Nicht wieder buchen, zuerst gebuchte Ergebnisse per verlässlichem Belegbezug abgleichen |
| Zwei Worker claimen denselben Batch | Sperre/Zustandsübergang verhindert Doppelverarbeitung oder führt zur sicheren Prüfung |
| Benutzer stoppt Lauf | Keine neuen Batches; laufende Buchung nicht als vollständig rückgängig gemacht darstellen |
| Queue darf nicht starten (Permission/Setup) | Job bleibt sichtbar blockiert und zeigt konkretes Diagnosekriterium |
| Pausierter/fehlgeschlagener Schritt hat abhängige Schritte | Abhängige Schritte bleiben wartend, bis Voraussetzungen gültig sind |

## Monitoring und Messung

Run-/Batch-ID, Modul, Zielfortschritt, Istmenge, Versuchszahl, Start/Ende, Laufzeit, Queue Entry/Fehlerstatus, sachlicher Fehlercode, Validierungsergebnis. Prozentzahlen per gewichteter echter Arbeitseinheit oder getrennt pro Schritt – keine irreführende globale Summe. Datensparsamkeit und Lösch-/Aufbewahrungsregeln.

## Grenzen und Umsetzungshinweise

Kein 'über Nacht fertig' versprechen: Betriebsunterbrechungen, SaaS-Job-Limits, Verfügbarkeit des Background Scheduler, neue BC-Versionen und Buchungslogik können Laufzeit beeinflussen. Job Queue 'erzeugt alle Daten' nur mit vorher implementierter Wiederaufnahme/Idempotenz. `TryFunction` ist kein allgemeiner Rollback-Mechanismus. Vor Implementierung versionsgerechte Microsoft-APIs und Scheduler-Berechtigungen prüfen.


## Aktueller Stand SF-007/SF-008 – 11.11.2026

Planung und gespeicherte Steps sind vorhanden; Startprüfung ist ein blockierendes Gate ohne Statuswechsel/Queue-Eintrag. Der spätere Dispatcher/Worker muss CheckStart und die Umgebungs-/Freigabeprüfung erneut anwenden. Kein Checkpoint, Claim, Retry oder Posting-Ergebnisabgleich durch SF-007/SF-008 zugesichert.

Vertrag und Grenzen: [GENERATOR_PLANNING.md](GENERATOR_PLANNING.md). Status: **Zur Prüfung**, kein Deployment oder BC-Laufzeittest.
