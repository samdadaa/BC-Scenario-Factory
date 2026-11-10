# BC Scenario Factory

**Status: Architektur und Planung, noch keine AL-Implementierung.** Ein neues AL-Projekt für synthetische, fachlich zusammenhängende Business-Central-Demo-, Schulungs-, Funktions- und Lasttestumgebungen. Nicht nur Mengen generieren, sondern realistische Unternehmensdaten mit konfigurierbaren Szenarien, unterschiedlichen Geschäftsvorfällen, Abhängigkeiten und optional vollständig gebuchten Prozessen.

## Zielgruppen und Nutzen

| Rolle | Ziel | Beispiel |
| --- | --- | --- |
| BC-Berater | Vorführbare Prozesse ohne manuelle Vorbereitung | Handelsunternehmen mit Einkauf → Wareneingang → Verkauf → Zahlung |
| Schulung/Key User | Wiederholbare Lernfälle | Überfällige Rechnung, Retouren, offene und ausgeglichene Posten |
| AL-Entwickler/Tester | Valide, reproduzierbare Daten und Regression | Varianten mit fehlenden Dimensionen ausschließlich als **gezielte Negativtests** |
| Performance/QA | Einstellbare Last und überprüfbare Durchläufe | 1.000 / 10.000 / 50.000 / 100.000 führende Datensätze, fachabhängig gebatcht |

## Leitbild

1. **Branche** auswählen (zunächst Handel), dann benötigte **Module** und **Datenmengen pro Entität** definieren.
2. **Umfang** auswählen: (A) Einrichtungen + Stammdaten, (B) zusätzlich ungebuchte Dokumente, (C) gebuchte Bewegungen, (D) vollständige Folgeprozesse wie Zahlungen und Ausgleich.
3. **Vorbedingungen** prüfen; vorhandene BC-Standardkonfiguration kontrolliert nutzen, fehlende Einrichtungen nur mit Freigabe anlegen; niemals produktive Einstellungen still verändern.
4. **Reale fachliche Relationen** und variierende Werte erzeugen: Rollen, Zeiträume, Preise, Buchungsstatus, Bestände und offene Posten müssen plausibel und prüfbar sein.
5. **Aufgabenwarteschlange** führt große Läufe in wiederaufnehmbaren, protokollierten Verarbeitungspaketen aus; BC kann weiter benutzt werden.
6. **Dashboard** zeigt Gesamtstatus, pro Modul erzeugte Datensätze, laufende/fehlgeschlagene Pakete, Prüfungen und eventuelle offene Schritte.
7. **Ergebnisse** sind nachprüfbar, bei Bedarf als Szenario erneut erzeugbar; technische Grenzen und Bereinigung sind explizit.

## Wichtige Abgrenzungen

- Keine echten Kunden- oder Mitarbeiterdaten. Namen/Adressen etc. sind **synthetisch**; keine echten personenbezogenen Identitäten nachbilden.
- **Sandbox/Testmandanten**, keine automatischen Massenbuchungen in Produktion. Ein Produktions-Blocker ist verbindlicher Teil des ersten MVP.
- Kein direktes Insert in Standard-Postentabellen: Buchungen über freigegebene BC-Standardprozesse.
- Branchenprofile sind **Parameter/Regelsets für wiederverwendbare Fachgeneratoren**, nicht Kopien der Fachlogik.
- **XERJ wird nur lokal als Entwicklerwerkzeug für Codex getestet; es ist keine Abhängigkeit, Schnittstelle oder Laufzeitkomponente dieser AL-App.**
- Eine verbindliche Aussage, dass ein kompletter *leerer* Mandant automatisch initialisiert werden kann, ist **nicht** getroffen; siehe `docs/DECISIONS.md`.

## Stand und Installation

`app.json` enthält bereits App-ID, `application: 28.0.0.0`, `runtime: 17.0` und ID-Bereich `50100–50149`, aber der Publisher ist noch `Default Publisher`. **Diese Werte wurden aus der gelieferten ZIP übernommen, nicht als funktionsfähig validiert.** Zielversion, Publisher, Objektbereich, Build-/Sandbox-Umgebung müssen vor der ersten Implementierung geprüft werden.

1. Projekt in VS Code mit der Microsoft AL Language Extension öffnen.
2. `app.json` und `.vscode/launch.json` mit der vorgesehenen Sandbox abgleichen; keine produktive Umgebung verwenden.
3. AL-Symbole erst nach bestätigter BC-Version laden; keine Kompilierung behaupten.
4. `AGENTS.md`, `docs/PROJECT.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` und `TODO.md` lesen.
5. In Codex **genau ein vom Menschen ausgewähltes Ticket** beauftragen; vor Codeänderungen einen Plan und Testweg verlangen.

## Struktur

`src/<Modul>/` enthält genau einen Modulordner, **ohne** vorgefertigte Objekt-Unterordner. AL-Objekte dürfen später direkt im Modul liegen oder nur bei echtem Bedarf in fachliche Featureordner gruppiert werden; vor einer Änderung die Konventionen lesen. `docs/modules/` beschreibt alle 24 geplanten Module.

## Dokumente

- [Startanleitung](GETTING_STARTED.md) · [Architektur](docs/ARCHITECTURE.md) · [Fachkonzept](docs/REQUIREMENTS.md)
- [Szenarien & Branchen](docs/SCENARIOS.md) · [Generierungsregeln](docs/DATA_MODEL.md) · [Hintergrundjobs](docs/BACKGROUND_PROCESSING.md)
- [UI und Dashboard](docs/UI_WORKFLOWS.md) · [Teststrategie](docs/TESTS.md) · [Sicherheit](docs/SECURITY.md)
- [Modulindex](docs/modules/INDEX.md) · [Entscheidungen](docs/DECISIONS.md) · [Umsetzungs-Tickets](TODO.md)

## Lizenz / Support

Urheberrechte, kommerzielle Lizenz, Supportkanal und Veröffentlichungsweg: **Zu prüfen**. Es wurde keine Lizenz eingeräumt.
