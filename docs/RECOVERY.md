# Checkpoints, Retry und Laufsteuerung – SF-013

## Plan vor Implementierung – 15.11.2026

Ziel: bestätigte Batchresultate als unveränderliche, datensparsame Checkpoints sichern; Pause/Abbruch an sicheren Paketgrenzen; Wiederaufnahme nur nach erneuten aktuellen Prüfungen und ohne Wiederholung bestätigter Einheiten. Ein Retry ist ausschließlich für nachweislich noch nie übernommene fehlgeschlagene Batches erlaubt und auf drei Einplanungen begrenzt. Unklare übernommene Arbeit bleibt NeedsReview; fehlende Herkunft allein beweist keine fehlende Buchung.

Betroffen: BackgroundProcessing-Recovery-Codeunit 90304, neue Kontroll-/Checkpoint-Persistenz und Guards in lokal freien IDs ab 90313, vorhandene Batch-/Ausführungsregeln, Worker/Runner/Dispatcher/Fehlerhandler, Steueraktionen in bestehenden Listen/Laufkarte, deklarative Rechte und Übersetzungen. Der gemeinsame Core-Statusgraph wird nur um die für sicheren Halt/Wiederaufnahme nötigen Übergänge ergänzt. Header, Snapshot, Steps, Herkunft und Standardfachdaten bleiben unverändert. Keine Folge-Tickets, kein Deployment.

Risiken: konkurrierende Stopanforderung und nächste Einplanung, aktive Worker-/Scheduler-Sessions, unklarer Commit, veraltete Checkpoints oder Generatorversionen, fehlende effektive Rechte. Stopanforderungen müssen unabhängig von der langen fachlichen Header-Sperre gespeichert werden können; danach sichere Grenzprüfung. Kein Leasetimeout als Beweis für einen toten Worker, kein blindes ExecuteBatch/Generator.Resume für NeedsReview. Aktive Sessiondaten werden ausschließlich auf technische IDs geprüft, keine Benutzer-/Kundendaten kopiert.

Testweg: XERJ nur bcsf-docs und lokale Quellen/Symbole; voller Cloud-Build mit CodeCop/UICop gegen vorhandene BC-28.5-/Runtime-17-Symbole, XLIFF-/Inventar-/Diff-/Schreibpfadprüfungen. Unterbrechungs-, Queue-, Parallelitäts-, Berechtigungs- und Postingfälle ausdrücklich als BC-Testplan dokumentieren, solange keine freigegebene Laufzeitumgebung verfügbar ist. Keine erfundenen Simulationserfolge und keine neuen AL-Testobjekte ohne ausdrücklichen Testobjektauftrag.

## Implementierter Stand – 16.11.2026

Vier neue Objekte: 90304 Batch Recovery, 90313 Run Control, 90314 Batch Checkpoint und 90315 Recovery Rules. Der BackgroundProcessing-Bestand steigt auf 16, das Projekt auf 85 AL-Objekte. Bestehende Workflows und Guards wurden gezielt erweitert; Manifest/Runtime/Dependencies, Header, Snapshots, Steps und Herkunftstabellen bleiben unverändert.

### Checkpoint und Wiederaufnahme

Der Runner speichert erst nach vollständiger Herkunftsabdeckung und erfolgreichem ValidateOutput einen Checkpoint in derselben commitfreien Transaktion wie Fachresultate und Batchabschluss. Die Zusammenfassung ist Schema 1 und enthält exakt acht technische Werte: generatorCode, runId, batchKey, processedUnits, createdRecords, dataLanguage, completed und contractProbe. Zusätzliche Ergebnis-Nutzdaten werden nicht kopiert. Generatoren müssen ValidateOutput auch aus dieser technischen Zusammenfassung plus eingefrorenem Kontext und registrierten Ergebnissen ausführen können. Unveränderliche Datenbankguards verhindern nachträgliches Anlegen für nicht laufende Batches sowie Änderung/Löschung/Umbenennung.

Bei jeder Wiederaufnahme werden vollständige Planbereiche, alle bereits abgeschlossenen Checkpoints, Ergebnis-SystemIds, aktuelle Generator-/Vertragsversionen und Outputvalidierung geprüft. Aktuelle Start-/Setup-/Umgebungs-/Freigabeprüfungen bleiben zwingend. Nur noch Pending-Arbeit wird neu eingeplant; abgeschlossene Einheiten werden nicht erneut ausgeführt. Der Core-Graph erhält Ready → Paused und ResumePending → CompletedWithWarnings für den Halt vor dem ersten Job bzw. den rein nachweisenden Abschluss bereits vollständig bestätigter Arbeit. Operative Übergänge bleiben zusätzlich durch die strengeren BackgroundProcessing-Guards begrenzt.

Ein alter abgeschlossener Batch ohne neuen Checkpoint wird nicht rückwirkend als sicher bestätigt. Ein historischer, nie übernommener Fehlerjob zählt bei seiner ersten Stilllegung als ein Versuch. Fehlende technische Workeridentitäten verhindern die automatische Inaktivitätsfreigabe für alte übernommene Batches. Kein stilles Nachladen oder Erfinden von Checkpoints.

### Retry, Sitzungsnachweis und NeedsReview

„Nicht übernommenes Fehlerpaket wiederholen“ ist nur für Failed mit Started At=0, ohne Workerübernahme, ohne Herkunft und ohne Checkpoint zulässig. Der alte Job muss sicher stillgelegt oder bereits entfernt sein. Dann bleiben Batch-ID, logische Bereiche, Generatorbindung und Plan unverändert; die alte Job-ID wird als vorheriger Job festgehalten und ausschließlich ein neuer eindeutig gebundener Job geplant. Maximal drei Einplanungen insgesamt je Batch, einschließlich erster Einplanung und Stop-/Wiederaufnahmezyklen; kein automatischer Standard-Job-Retry. Zähler sind monoton und durch DB-Guards abgesichert. Sichtbar ist die letzte Voraufgabe; ein vollständiges eigenes Versuchsjournal wird nicht eingeführt. Ältere Standardprotokolle unterliegen der BC-Aufbewahrung.

Der Claim speichert Sitzung, Dienstinstanz und eindeutige Sitzungs-GUID. Die Workerabfrage lädt gezielt technische Sitzungsfelder. „Unterbrochene Übernahme prüfen“ darf Running nur nach nachgewiesenem Ende exakt dieser Sitzung in NeedsReview überführen. Fehlende Rechte oder fehlende historische GUID sind kein Inaktivitätsnachweis. Es gibt keinen Timeout, der alleine einen Claim freigibt.

„Bestätigten Checkpoint abgleichen“ benötigt einen existierenden Checkpoint, denselben inaktiven Worker, einen gestoppten Job, vollständige vorhandene Ergebnisse und erfolgreiche erneute Validierung. Es bestätigt nur bereits existierende Resultate und korrigiert Abschlusszähler. Weder ExecuteBatch noch Generator.Resume werden in Recovery aufgerufen. Ohne Checkpoint oder bei Teilresultaten/fehlenden SystemIds bleibt die Arbeit prüfpflichtig. Ein manueller Freigabeknopf, der fehlende Buchungen oder Rollback-Sicherheit behauptet, existiert nicht. Nach Abbruch darf ein belegtes Ergebnis noch abgeglichen werden, der Run bleibt dabei Cancelled und kann nicht neu gestartet werden.

**Zu prüfen:** Wie weisen zukünftige konkrete Postinggeneratoren Standard-Beleg-/Postenketten bei einem Commit ohne Checkpoint nach? Dafür ist weiterhin ein versionspassender fachlicher Reconciliationvertrag erforderlich; Produktion und nicht ausdrücklich genehmigte Postingausführung bleiben gesperrt. Registry-Abwesenheit beweist niemals, dass nicht gebucht wurde.

### Pause und Abbruch

Steuerungsanforderungen liegen in einer separaten Tabelle. RequestStop speichert und committed ausschließlich den UI-Steuerungsauftrag, bevor es bei nicht laufendem Status versucht, den Eltern-/Ausführungslock zu nehmen. Diese interne Methode darf deshalb nur als eigenständige Steuerungsaktion ohne fremde ungespeicherte Transaktion verwendet werden. Ein laufender Batch wird nicht beendet; während seiner fachlichen Transaktion benötigt die Anforderung keinen langen Header-Update-Lock. Ein kurzer ReadUncommitted-Zugriff dient nur der Entscheidung, ob ein sofortiger Anwendungsversuch sinnvoll ist, niemals einer Ausführungsfreigabe.

Der Worker prüft Anforderungen vor Claim, der Dispatcher vor der nächsten Einplanung. Nach laufender Arbeit werden fachliche Ergebnisse und Checkpoint vollständig bestätigt, bevor an der nächsten Grenze gehalten wird. Ausstehende Anforderungen sind auf der Laufkarte getrennt vom aktuellen Execution-Status sichtbar. Bei einem Rennen mit einer bereits gestarteten Standardaufgabe bleibt die Anforderung erhalten und wirkt am nächsten sicheren Punkt; „Ausstehende Anforderungen anwenden“ kann erneut aufgerufen werden.

Nur nicht übernommene Standardjobs werden über die geprüfte CancelTask-Rückgabe stillgelegt. Ein In-Process-Job wird von einer fremden Steuerung nicht beendet; lediglich der eigene Worker darf vor seinem Claim den gebundenen noch ungestarteten Batch freigeben und erfolgreich zurückkehren. Standardrollenrechte bleiben erforderlich, es gibt kein eigenes Standardtabellen-Permissions-Upgrade.

Abbruch ist dauerhaft: Pending/ungeclaimte Failed-Arbeit wird Cancelled; bestätigte Ergebnisse und NeedsReview-Arbeit bleiben erhalten. Cancel Requested kann nicht zurückgesetzt werden, Cancelled hat keinen Wiederaufnahmeweg. Der Status behauptet keine Rücknahme von Buchungen. Ist noch ein Running-Claim vorhanden, bleibt der Auftrag ausstehend, bis der Worker die sichere Grenze erreicht oder eine nachweislich beendete Sitzung als unterbrochen klassifiziert wurde.

### Rechte, Transaktionen und Grenzen

ADMIN bekommt nur eigene Tabellenrechte (Control Rim, Checkpoint Ri) und Objektausführung; feste Writer besitzen eng begrenzte IM/I/M-Rechte. Acht neue Pflichtsubscriber schützen Control/Checkpoint auch ohne RunTrigger. Die neuen Batchfelder für Versuche, Voraufgabe und Workeridentität sind nur bei ihren zulässigen Übergängen veränderbar. Standard-Queue-, Task-Scheduler- und technische Active-Session-Leserechte sind separat erforderlich und tatsächlich in BC zu prüfen. Es werden keine Benutzerkennungen oder fachlichen Ergebnisnutzdaten in Checkpoints kopiert.

Der frühere Claim-Commit bleibt erhalten; hinzu kommt ausschließlich der absichtlich dauerhafte Steuerungsauftrag. Retry, Resume, Reconciliation und Checkpointschreiben verwenden CommitBehavior::Error. Keine TryFunction-Schreibpfade, keine Standard-Ledger-Inserts, keine wirkliche Sessionbeendigung, keine Posting-Wiederholung. Implizite Commitgrenzen fremder Generatoren werden weiterhin nicht pauschal als sicher erklärt. Vorhandene echte Generator-/externe Setupblocker bleiben bestehen, daher weiterhin kein behaupteter erfolgreicher End-to-End-Lauf.

## Prüfung

Lokaler Cloud-Build mit CodeCop/UICop, Übersetzungsprüfung und statische Guard-/ID-/Scopeprüfungen werden in [TESTS.md](TESTS.md) protokolliert. Unterbrechungen während tatsächlicher Datenerstellung oder Buchung wurden mangels freigegebener BC-Laufzeit und echter Generatoren nicht simuliert. Die konkrete Fault-/Parallelitätsmatrix steht dort als offen. Keine neue Test-App oder Testobjekte, kein Deployment. Status SF-013: **Zur Prüfung**.

## SF-037 – Checkpoint-BLOB und JSON-Lesepfad

Gespeicherte Ergebnis-BLOBs werden nach `Get()` explizit mit `CalcFields` geladen. `ReadStoredResult` übernimmt Laden und Lesen; `VerifyCheckpoint` lädt vor dem gemeinsamen Validator. `ReadResult` ist dagegen der Leser des aktuellen Speicherinhalts, damit der Insert-Validator einen noch nicht gespeicherten Checkpoint prüfen kann. Reconciliation und Abschlussprüfung verwenden den gespeicherten Leser. Leere/ungültige JSON-Ergebnisse bleiben mit paketbezogener Fehlermeldung blockiert. Die Trennung ändert weder die atomare Ergebnis-/Checkpointgrenze noch die Wiederanlaufberechtigung. [Nachweis und offene BC-Fälle](TESTS.md#sf-037--nachtrag-zum-json-fehler-im-partnerlauf).
