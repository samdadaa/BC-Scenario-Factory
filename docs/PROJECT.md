# Projektfakten und bestätigter Plan

## Beobachteter technischer Bestand (ZIP vom 10.11.2026)

| Feld | Ist |
| --- | --- |
| Name | BC Scenario Factory |
| App-ID | `618c08c6-601b-430a-90d2-55f96866bfa4` |
| Publisher | `Default Publisher` (Platzhalter) |
| Version | `1.0.0.0` |
| Application | `28.0.0.0` (aus app.json; Laufzeit-Kompatibilität ungetestet) |
| Runtime | `17.0` (aus app.json; Kompatibilität ungetestet) |
| IDs | `50100..50149` (50 IDs; voraussichtlich zu wenig) |
| Abhängigkeiten | `[]` |
| AL-Objekte | **0**, noch nicht implementiert |
| Module | 24 geplante Verzeichnisse unter `src/`, noch ohne Code |

`app.json`, `.vscode/launch.json`, `.gitignore` und sonstige bestehende technische Konfiguration wurden im Dokumentationsschritt **nicht geändert**. `.vscode/launch.json` enthält zwei Sandbox-Profile (Playgrund/Playground), deren Richtigkeit vor Debugging zu überprüfen ist.

## Bestätigtes Produktziel

Wiederverwendbare **AL-Extension** zur Erstellung kontrollierter, konsistenter, realistischer und synthetischer BC-Umgebungen für Demo, Schulung, Prozess-/Regressionstest und Performance. Branchenprofile definieren Datenverteilungen und Prozessmuster; Fachgeneratoren implementieren die Logik. Umfang: Setup+Stammdaten / zusätzlich ungebuchte Belege / gebuchte Belege und Posten / optional Folgevorgänge einschließlich Zahlung und Ausgleich. Per Entität einstellbare Mengen; langfristig auch 100.000+ Datensätze, ohne Durchsatzgarantie. Längere Erzeugungen über Job Queue mit Dashboard, Checkpoints, Wiederanlauf und Validierung.

## Produktphasen

- **MVP / P1:** Core + Scenario Management, Profiles/Registry, Dependency/Setup, Data/Process, Queue/Monitoring, Validation/Lifecycle, Finanz-Grundlagen, Verkauf, Einkauf, Artikel/Lagerbestand; **Handelsprofil**.
- **P2:** Lagerprozesse, Fertigung, Montage, Projekte, Service, Anlagen; Zahlung/Retouren/komplexe Belegketten vertiefen.
- **P3:** CRM/Beziehungsmanagement, Planung, weitere Branchenprofile, Erweiterungs-API, Schulungsszenarien mit definierbaren Lernzielen.

## Was noch entschieden werden muss

ID-Bereich und Publisher, geeignete Sandbox/Versionen und verwendbare BC-Basisdaten; Länder-/Lokalisierungsumfang (DE zuerst als Vorschlag), Branchenwerte/Kataloge, Test-App-Struktur, rechtlich zulässige Namens-/Adressgeneratoren, Umgang mit Vorhanden-/Neuaufbau-Setups, Sicherheitsfreigabe bei Massenbuchungen, Aufbewahrungs-/Bereinigungsstrategie. Siehe `docs/DECISIONS.md` und die Tickets.
