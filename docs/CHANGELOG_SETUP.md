# Aufbereitung der AL-Agentura-ZIP – 10.11.2026

- Vorhandene Struktur von AL Agentura gelesen, insbesondere `AGENTS.md`, `TODO.md`, `docs/CONVENTIONS.md`, `docs/SECURITY.md`, `docs/TESTS.md`.
- 336 **leere** AL-Objekttyp-Unterordner unter 24 Modulen entfernt; `src/<Modul>/.gitkeep` hält die fachlichen Verzeichnisse im ZIP fest.
- Keine AL-Dateien vorhanden, daher keine AL-Objekte verschoben, umbenannt oder gelöscht; keine AL-Implementierung erzeugt.
- Vorhandene Konfigurationen `app.json`, `.vscode/launch.json`, `.gitignore`, `.altestrunner/config.json` nicht verändert.
- Bestehende Agentenregeln beibehalten und um ausdrücklich bestätigte Produktleitplanken ergänzt.
- Vorhandenes `TODO.md` als kanonische Aufgabenliste mit `AL-001` erhalten und um 36 detaillierte `SF-`-Tickets erweitert. `Todos.md` ist ein Verweis, keine zweite parallele Aufgabenliste.
- Architektur-, Produkt-, Branchen-, Daten-, Hintergrund-, UI-, Sicherheits- und Testdokumente aktualisiert oder ergänzt; 24 Modulspezifikationen erstellt.
- Keine BC-Verbindung, Build, AL-Tests, Publish, Codeausführung oder XERJ-Integration durchgeführt.
- `50100..50149`, `Default Publisher` und eventuelle Versions-/Sandbox-Differenzen sind offene Setup-Fragen.
