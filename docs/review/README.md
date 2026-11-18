# BC Scenario Factory – Review und Testhandbuch

**Geprüfter Stand:** `BC Scenario Factory(4).zip`, Quellstand bis SF-018, Review 18.11.2026. Das ZIP enthält neue Markdown-Dateien. Beim Entpacken im Projektstamm entsteht `docs/review/`; vorhandene Projektdateien werden nicht ersetzt.

| Einstieg | Was du dort findest |
| --- | --- |
| [Testanleitung](TESTANLEITUNG.md) | In der Sandbox 12 Debitoren und 7 Kreditoren erzeugen und die Ergebnisse prüfen |
| [Funktionsstand](FUNKTIONSSTAND.md) | Was tatsächlich im Code steckt, was manuell möglich und was noch geplant ist |
| [Architektur und Diagramme](ARCHITEKTUR-DIAGRAMME.md) | Von Szenario über Plan und Queue bis zu Ergebnis und Validierung |
| [Dashboard-Review](DASHBOARD-REVIEW.md) | Was heute klickbar ist, warum die Oberfläche unübersichtlich wirkt und wie ich sie vereinfachen würde |
| [Modul- und Objektinventar](MODULINVENTAR.md) | Alle 24 Modulordner und alle 121 AL-Objekte zum Nachschlagen |

## Kurzurteil

Die App bewegt sich technisch in die richtige Richtung. **Die Oberfläche zeigt heute aber die Architektur statt des Nutzerziels.** Für den ersten echten Nutzen reicht „Testpartner anlegen, prüfen, Ergebnisse öffnen“. Vor weiteren fachlichen Modulen würde ich diesen Weg in einer Sandbox abnehmen und das Dashboard auf diesen Einstieg reduzieren. Die Prüfungen, Snapshot-Grenzen und Recovery-Regeln sollten dabei bleiben.

Wichtig für den ersten Test: **Die im Upload enthaltene `.app` ist nicht auf dem Stand der Quellen.** Im Paket fehlen Customer Generator, Vendor Generator und Partner Rules. Beim Testen aus den aktuellen Quellen neu bauen und erst dann veröffentlichen.

## Pflege für Agents

- Code und tatsächlich beobachtetes BC-Verhalten zuerst prüfen. Ältere Kapitel in der vorhandenen Projektdoku sind historische Stände. Bei Konflikten die Abweichung festhalten statt lautlos zu vermischen.
- Bei einem neuen Generator die Funktionsmatrix, den Primärpfad im Diagramm und die Testanleitung gemeinsam aktualisieren. In der Testanleitung bestehende Fall-IDs beibehalten und neue Fälle ergänzen.
- Testfall mit Startzustand, Aktion, Soll, Ist und Nachweis pflegen. Unausgeführtes bleibt **offen**. Ticketstatus nur mit belegtem Stand und nach Projektregeln ändern.
- Neue Navigationsziele und Begriffe immer in DE und EN sowie mit Tastatur testen. Erklärungen aus User-Sicht vor interne Labels stellen. Quellbelege als relative Links angeben.
