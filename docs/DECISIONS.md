# Architekturentscheidungen und offene Fragen

> Status: **Bestätigt** = durch den Nutzer im Gespräch festgelegt; **Vorschlag** = Designidee ohne Implementierungsfreigabe; **Zu prüfen** = erfordert technische/fachliche Entscheidung. Keine Entscheidung hier autorisiert automatisch Codeänderungen.

| ID | Status | Thema | Vereinbarung / offene Frage |
| --- | --- | --- | --- |
| ADR-01 | Bestätigt | Produktziel | Branchenabhängige, fachlich echte, synthetische Demo-/Schulungs-/Test-/Performance-Daten statt gleichförmiger Massendatensätze |
| ADR-02 | Bestätigt | Auswahl | Branche, Module, Datenmengen, Buchungs-/Prozessmodus konfigurierbar |
| ADR-03 | Bestätigt | Background | Generierung über Aufgabenwarteschlange mit Dashboard, Fortschritt und Kontrolle auch ohne aktive Browser-Sitzung |
| ADR-04 | Bestätigt | Struktur | `src/<Modul>/` ohne leere Typ-Unterordner; Dokumentation & AGENTS-Regeln erhalten |
| ADR-05 | Bestätigt | XERJ | XERJ nur lokal mit Codex nutzen/testen, **keine BC-Integration** |
| ADR-06 | Vorschlag | Branchenstart | Großhandel als erstes Profil, Finance/Sales/Purchasing/Inventory als MVP-Fachmodule |
| ADR-07 | Vorschlag | SDK | Generator-Interface + Registry + Dependency Graph; tatsächliche AL-Signatur zu prüfen |
| ADR-08 | Zu prüfen | Zielumgebung | Business Central SaaS Sandbox, Version und Lokalisierung, notwendige Lizenzen/Permissions |
| ADR-09 | Zu prüfen | Setup | Bestehende Demo-Konfiguration zuerst nutzen oder leere Firma selbst aufbauen? Hybrid-Preflight vorgeschlagen |
| ADR-10 | Zu prüfen | IDs | `50100..50149` bietet nur 50 Objekt-IDs; Projektgröße erfordert neue, bestätigte Range; ggf. AppSource-/PTE-Ziel klären |
| ADR-11 | Zu prüfen | Publisher | `Default Publisher` ersetzen, aber nur nach ausdrücklicher Festlegung |
| ADR-12 | Vorschlag | Sicherheit | Sandbox-only für alle mutierenden Abläufe; Blockade produktiver Umgebungen und keine direkten Ledger-Inserts |
| ADR-13 | Vorschlag | Test-Apps | Test-Codeunits in separater AL-Test-App vorsehen; Aufbau nach Ziel-Workspace klären |
| ADR-14 | Zu prüfen | Länder | DE-Fokus als mögliche erste Lokalisierung; Steuer-/Währungs-/Adressregeln nicht erfinden |
| ADR-15 | Zu prüfen | Bereinigung | Umgang mit bereits gebuchten Testdaten; neue Firma/Sandbox oder standardkonforme Gegenbuchung je Szenario |
| ADR-16 | Zu prüfen | Parallelität | Unterstützte Queue-Batching-/Lock-Strategie und zulässige Laufzeiten in Zielversion testen |
