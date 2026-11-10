# Teststrategie und Evidenz — BC Scenario Factory

## Regel für Coding-Agenten

Keine Tests, Compilerläufe oder Sandbox-Effekte als erfolgreich melden, wenn sie nicht wirklich ausgeführt wurden. **Neue Test-Codeunits nur bei ausdrücklichem Ticketauftrag erzeugen**; bestehende Tests und manuelle Prüfschritte nach Möglichkeit anwenden. Das Testniveau richtet sich nach Risiko und Änderung.

## Teststufen

| Stufe | Inhalt | Was als Nachweis zählt |
| --- | --- | --- |
| Codeprüfung | ID-Bereiche, Naming, Abhängigkeiten, Events, Rechte | Betroffene Dateien, konkrete Erkenntnisse |
| Compile / Analyzer | AL Language, richtige Symbols/BC-Version, projektkonfigurierte Analyzer | Tatsächliches Kommando/IDE-Aktion und Ergebnis |
| Unit-/Integrationstests | AL Test Codeunits, Setup, Fehlerpfade, Rechte | Test-ID, Umgebung, Resultat |
| Fachliche Prüfung | Ist-/Soll-Verhalten inkl. Sonderfälle | Eingaben, Schritte, erwartete und beobachtete Ergebnisse |
| Regression / Last | Vorheriges Verhalten, Massenverarbeitung, Locking | Realistische Datenmengen, Messzeit, Vergleich und Einschränkungen |

## Projektstruktur App/Test

Bei **AL-Go** und getrennten Projekten:
- `App/` für Anwendungscode, `Test/` für Testobjekte, je eigenes `app.json`.
- `Test` referenziert `App`, nicht umgekehrt.
- Testordner entlang fachlicher Features strukturieren, gemeinsam genutzte Testhelfer separat.
- Nicht ohne Auftrag ein Testprojekt erzeugen oder vorhandene Projektstruktur umbauen.

Im **einzelnen AL-Projekt** ist eine getrennte Test-App optional bzw. von vorhandener Architektur abhängig. Nicht automatisch AL-Go voraussetzen.

## Prüfprotokoll für ein Ticket

| Feld | Eintrag |
| --- | --- |
| Ticket / Änderung | Zu prüfen |
| Getestete AL-Objekte | Zu prüfen |
| BC-Version / Runtime | Zu prüfen |
| Umgebung, nur nicht-sensible Bezeichnung | Zu prüfen |
| Testdaten, anonymisiert | Zu prüfen |
| Ausgeführt am / durch | Zu prüfen |
| Build/Analyzer | Nicht ausgeführt |
| Automatisierte Tests | Nicht ausgeführt |
| Manuelle Szenarien | Nicht ausgeführt |
| Ergebnis und Fehler | Zu prüfen |
| Offene Risiken / Regressionen | Zu prüfen |

## Mindestfälle für fachliche Änderungen

- Erfolgsfall (Happy Path), leerer/ungültiger Input, fehlende Berechtigung, wiederholte Ausführung (Doppelverarbeitung), Teilfehler, Datums-/Rundungsgrenzen, bestehende Daten; Massendaten nur, wenn relevant.
- Bei Buchungen zusätzlich gebuchte/ungebuchte Belege, Ausgleich, Storno, Mehrwertsteuer, Dimensionswerte, Fehlerabbruch und Recovery prüfen, soweit fachlich zutreffend.
- Bei Events zusätzlich Subscriber-Kombinationen und Erweiterbarkeit; bei APIs Fehlantworten, idempotente Wiederholung und Authentifizierung.

Quelle: https://alguidelines.dev/docs/agentic-coding/vibe-coding-rules/al-testing/


## Projektbezogene Testmatrix (Plan; alles noch offen)

| Testfall | Erwartung |
| --- | --- |
| Sandbox vs. Produktion | Mutation nur in freigegebener Testumgebung; Produktion blockiert |
| Setup vorgefüllt vs. unvollständig | Preflight zeigt präzise Differenz; überschreibt nichts ungefragt |
| Nur Stammdaten | Keine Belege/Posten |
| Ungebucht | Vollständige Stammdaten und Dokumente, keine Buchungsposten aus diesen Dokumenten |
| Gebucht | Resultate ausschließlich via Standardbuchung; Ledger-/Belegbeziehungen stimmen |
| Voller Prozess | Lieferung/Rechnung/Zahlung/Ausgleich im freigegebenen Umfang korrekt |
| Branche/Seed | Plausible Variationen; reproduzierbare Eingangsdaten je gleicher Konfiguration |
| 1.000/10.000/50.000/100.000 | Pro Entität gemessene Verarbeitung, Soll-Ist, Fehler und Ressourcen beachten |
| Ausfall während des N-ten Batches | Fortsetzung ohne doppelte Stammdaten und vor allem ohne Doppelbuchung |
| Zwei parallele Jobs | Kein mehrfach geclaimter/gebuchter Batch |
| Falsche Dimension/MwSt./No.Series | Blocker oder gezielter Negativtest, kein stiller Datenfehler |
| Abgebrochener/pausierter Lauf | Status konsistent, abhängige Schritte warten, keine falsche Erfolgsmeldung |
| Dashboard-Summen | Soll/erstellt/validiert/gebucht differenziert, nachvollziehbare Drilldowns |
| Test- und Schulungsfälle | Erwartete Lernziele und Belegzustände fachlich überprüfbar |

**Evidenz:** Lauf-ID, Konfiguration/Snapshot, BC-Version, Testergebnis, reale Messwerte und Abweichungen dokumentieren. Keine Performancezahl oder Testbestehen ohne tatsächlichen Lauf behaupten.
