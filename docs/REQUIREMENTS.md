# Fachliche Anforderungen und nichtfunktionale Ziele

**Quelle:** Gemeinsam festgelegte Produktvision; alle konkreten technischen Implementierungsdetails sind Planung, nicht implementierter Bestand.

## Nutzergruppen und Use Cases

1. **Berater / Vertrieb:** In einer Sandbox ein vorführbares Branchenunternehmen mit plausiblen Kontakten, Preisen, Warenbeständen, offenen Vorgängen und nachvollziehbaren Belegketten erzeugen.
2. **Trainer / Key User:** Fest definierte Trainingsfälle mit unterschiedlichen Rollen, Bearbeitungsständen, Fehlersituationen und einer Anleitung mit Soll-Ergebnis erzeugen; Fall kann wiederholt werden.
3. **Entwickler / Test:** Konsistente Stammdaten und Standardbelege erzeugen, um neue Erweiterungen gegen realistische Konstellationen zu prüfen; Seed und Profilversion dokumentiert.
4. **QA / Performance:** Große Mengen pro Entität, steuerbare Buchungsintensität, fortschrittsgeprüfte Hintergrundläufe, belastbare Mess- und Fehlerprotokolle.

## Funktionale Anforderungen

| ID | Anforderung | Definition of Done (fachlich) |
| --- | --- | --- |
| FR-01 | Branchenprofil wählen | Profil zeigt kompatible Module, Standardmengen, Parameter und Datenverteilungen |
| FR-02 | Module wählen | Benutzer kann Module an-/abwählen; zwingende Abhängigkeiten werden erklärt |
| FR-03 | Mengen je Entität | Mindestens pro Debitor, Kreditor, Artikel, Belegtyp separate Zielwerte; Vorschau abhängiger Mengen |
| FR-04 | Verarbeitungsmodus | Nur Setup+Stamm / +ungebuchte Dokumente / +gebuchte Dokumente / +Folgeprozesse |
| FR-05 | Geschäftsszenarien | Realistische Kontingente: offene/abgeschlossene Fälle, Zeiträume, Kundenklassen, Lagerzustände |
| FR-06 | Preflight und Vorschau | Fehlende Einrichtung, Rechte, Umgebungsblocker und voraussichtliche Arbeit sichtbar vor Start |
| FR-07 | Kontrollierte Einrichtung | Nur genehmigte fehlende Einrichtungswerte ergänzen; bestehende Konfiguration schützen |
| FR-08 | Background-Jobs | Großer Lauf ist nicht von aktiver UI-Sitzung abhängig; Queue-Status und Job-Verfügbarkeit sichtbar |
| FR-09 | Batch-Wiederaufnahme | Nach Fehler keine doppelt erstellten Objekte oder Buchungen; nicht sichere Fälle manuell prüfen |
| FR-10 | Dashboard | Pro Modul/Schritt Soll, Ist, Status, Fehler und Prüfqualität sichtbar |
| FR-11 | Validierung | Mengen, Schlüsselbeziehungen, Setup und erwartete Posting-Ergebnisse geprüft; Abweichungen berichtet |
| FR-12 | Audit und Datenherkunft | Lauf, Profil, Seed, Ersteller, Zeit, betroffene Datensätze und Zielumgebung nachvollziehbar |
| FR-13 | Bereinigung/Lifecycle | Nicht gebuchte Testobjekte nur mit konkretem Sicherheitsplan; keine blind destruktiven Löschungen gebuchter Ledger |
| FR-14 | Erweiterungsfähigkeit | Neue Fachgeneratoren/Branchenprofile ohne Fork zentraler Engine integrierbar |
| FR-15 | Wiederverwendbare Vorlagen | Vorlagen speichern, duplizieren, versionieren; Konfiguration je Run eingefroren |
| FR-16 | Zielgruppen-Modi | Demo/Training/Functional/Performance liefern unterschiedliche Datenmuster statt nur Mengen |

## Realismus: zwingende Anforderungen

- Synthetische, sprach-/landesabhängig plausible Stammdaten; eindeutige, wiedererkennbare Testmarker.
- Unterschiedliche Unternehmenstypen, Auftragswerte, Artikelkategorien, Kreditlimits, Zahlungsziele, Mengen, Preise, Belegstatus, Fakturierungs- und Leistungszeiträume.
- Zusammenhängende Datenketten: etwa Kreditor → Einkauf → Wareneingang → Artikelbestand → Verkauf → Faktura → Debitorenposten → optional Zahlung/Ausgleich.
- Plausible Datenverteilungen statt uniformer Zufallswerte; **negativ/fehlerhaft absichtlich nur in klar gekennzeichneten Tests**.
- Gleiches Profil+Seed+Eingabedaten ermöglicht deterministische **Eingangsszenarien**; automatisch zugeteilte Nummern und Plattformkonkurrenz können Ergebnisse abweichen lassen.

## NFR / Rahmenbedingungen

- Nur Sandbox/isolierte Testumgebungen; Produktsperre und Rechteprüfung vor mutierenden Aktionen.
- Längere Jobs dürfen UI nicht blockieren; keine festen Durchsatzzusagen oder unbegrenzte Parallelität.
- Fehlertoleranz, Wiederanlauf nach Serviceunterbrechung, vollständige Laufhistorie und datensparsame Protokollierung.
- Performance- und Fehlerstatus technisch messbar; valide Standard-Buchungslogik verwenden.
- Keine echte personenbezogene Identität; kein Versand von E-Mails/Bankdateien aus synthetischen Testfällen.
- Versions-/Lokalisierungsabhängigkeiten explizit ermitteln; Unit-/Integrationstest-App für belastbare Prüfungen planen.

## Außerhalb des initialen MVP

Vollständige Einrichtung eines völlig leeren Firmenmandanten ohne verfügbare Basisdaten, beliebige Dritthersteller-Extensions, sämtliche Industriesektoren, sichere Löschung gebuchter Ledgerposten, garantiert identische Postings auf jeder Umgebung, autonomes Produktionstuning, XERJ-Laufzeitanbindung.
