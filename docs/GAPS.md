# Offene Punkte / Bestandsprüfung

**Aktualisierung SF-003/SF-004, 11.11.2026:** Die nachfolgende ZIP-Bestandsaufnahme ist historisch. Aktuell gelten `90100..90999`, neun implementierte Grundlagenobjekte und fünf lokale Microsoft-Symbolpakete. Build/CodeCop/UICop gegen BC 28.5 erfolgreich; keine Sandbox-Laufzeittests. Publisher, Testfirma, tatsächliche Sandbox-Rechte und unbekannte Fremd-App-Kollisionen bleiben offen. Aktueller Vertrag und Grenzen: [FOUNDATION.md](FOUNDATION.md), tatsächliche Prüfnachweise: [TESTS.md](TESTS.md).

**Stand der bereitgestellten ZIP:** 24 leere fachlich benannte Modulordner, keine AL-Dateien in `src`; `app.json`, VS-Code-Konfiguration und generische AL-Agentura-Dokumentation vorhanden. Keine AL-Kompilierung oder Sandbox-Tests ausgeführt.

## Blocker vor produktiver AL-Implementierung

1. **ID-Range:** `50100..50149` (50 IDs) voraussichtlich unzureichend; Nutzungs-/Veröffentlichungsziel klären und Range explizit freigeben.
2. **Publisher:** `Default Publisher` ist Platzhalter.
3. **BC-Version:** `application: 28.0.0.0`, `runtime: 17.0` aus ZIP, aber keine Symbole/Compilerprüfung; Sandbox-Profilnamen überprüfen.
4. **Umgebung/Lokalisierung:** zulässige Sandbox- und Firmenstrategie, DE-Setup, verfügbare Standardfunktionen, Rechte.
5. **Setup-Strategie:** vorbefüllte Demofirma vs. komplett leere Firma ist noch ungeklärt; automatischer Leeraufbau nicht zugesagt.
6. **Validierungs-/Postingstrategie:** konkrete Standard-BC-Codeunits pro Modul erst nach versionsbezogener Analyse festlegen.
7. **Bereinigung:** für Ledgerposten nicht generell möglich; sichere Wiederherstellungs-/Reset-Strategie festlegen.
8. **Testprojekt:** keine AL-Test-App vorhanden; im Ticket planen und ausdrücklich freigeben.
9. **Modulreife:** alle 24 Module sind nur strukturelle Ziele, kein vorhandener fachlicher Code.
10. **Umsetzung:** TODO-Tickets sind Plan, sämtliche Tests/Builds/Benchmarks noch offen.

Die Dokumentation darf Codex nicht zu unüberprüften Annahmen über BC-APIs, Branchenprofile, Datenmodelle oder Resultate verleiten.

**Aktueller Zusatz SF-005/SF-006:** 32 AL-Objekte, Szenariokonfiguration und 285 vollständig erfasste XLIFF-Einheiten in Englisch und fünf deutschen Regionen. Wirkliche UI-Sprachauflösung, Rechte, atomare Persistenz/Konkurrenz und Snapshot-Rekonstruktion sind weiterhin in BC zu prüfen. Noch keine Fachgeneratoren/Queue. Aktueller Vertrag: [SCENARIO_CONFIGURATION.md](SCENARIO_CONFIGURATION.md).
