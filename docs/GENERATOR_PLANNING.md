# Generator-Vertrag und Laufplanung – SF-007/SF-008

Stand 11.11.2026: implementiert, **Zur Prüfung**. 56 AL-Objekte (55 numerische IDs und ein Interface), davon 24 in diesem Auftrag ergänzt. Keine Veröffentlichung oder Sandbox-Ausführung.

## Vertrag und Registrierung

`BCSF Generator` ist ein internes Interface mit sieben Methoden: `DescribeCapabilities`, `CheckPrerequisites`, `GetDependencies`, `PlanBatches`, `ExecuteBatch`, `ValidateOutput` und `Resume`. Vollständige Signaturen stehen in `src/ModuleRegistry/BCSFGenerator.Interface.al`. Keine Default-Methoden; Manifest und Runtime 17 bleiben unverändert. Eine erweiterbare Enum bindet Implementierungen statisch. Die Registry enumeriert deren Werte; zentrale Auflösung enthält keine Fallunterscheidung pro Generator. Fehlende/unbekannte Bindungen schlagen über eine explizite Ersatzimplementierung fehl. Eine frei beschreibbare Registrierungstabelle oder dynamische Codeunit-Ausführung wird nicht verwendet. Ereignisbasierte Registrierung wurde wegen schwerer überprüfbarer Vollständigkeit/Duplikate nicht gewählt. Eine öffentliche Drittanbieter-API bleibt SF-034.

Capabilities sind temporär und enthalten Generator-/Entitäts-/Modulcode, Implementierung, Version, Vertragsversion, Modusgrenzen, maximale Batchgröße und das Kennzeichen Vertragsprobe. Doppelte Identitäten, ungültige Grenzen und mehrdeutige Auswahl führen zu Fehlern. Versionscodes sind opake Identitäten; Vertrag 1 und Textkatalog 1 werden geprüft. Eine Änderung des Generatorverhaltens erfordert einen neuen Versionscode.

Kontext ist ein JSON-Objekt mit `schemaVersion`, `runId`, `companyName`, `dataLanguage`, `nameCatalogVersion`, `seed`, `processMode`, `batchSize`, `maximumBatchSize` und `maximumRecordsPerEntity`. Das Ziel enthält `entityCode`, `moduleCode`, `quantity` und `processMode`. Grenzen und Typen werden vor Verwendung geprüft. Datensprache 1/2 ist bereits beim Snapshot festgelegt; die Worker-Sprache darf sie nicht ersetzen. Aufrufgrenzen klonen JSON durch Serialisieren/Einlesen, weil JSON in AL Referenzsemantik besitzt.

Capabilities, Vorbedingungen, Abhängigkeiten, Batchplanung und Ergebnisvalidierung müssen ohne Datenbankänderungen arbeiten. Deklarierte Abhängigkeiten enthalten Vorgängercode, Pflicht-/Optional-/Extern-Art und Modusgrenzen (siehe Parser im Planner). Festgestellte Vorbedingungen blockieren die Planung. Batchplanung ist paginiert: höchstens 100 Batches je Aufruf, logische Schlüssel ab 1, begrenzt durch Menge und Batchgröße. Wiederaufnahme verwendet denselben Batchschlüssel und Run-Kontext. Das Interface allein garantiert noch keine sichere Wiederholung realer Buchungen; Checkpoints und Ergebnisabgleich gehören SF-011–SF-013.

`PROBE.CUSTOMER` und `PROBE.VENDOR` sind zwei getrennte normale Codeunits, keine AL-Testobjekte und keine echten Fachgeneratoren. Sie implementieren alle Methoden und erzeugen ausschließlich JSON-Ergebnisse mit `createdRecords = 0`. Wiederaufnahme liefert dieselben logischen Schlüssel. Der Debitor-Probe deklariert den Kreditor als Voraussetzung. Der produktive Planer schließt beide durch `Contract Probe` ausdrücklich aus. Die Probe-Ausführung ist auf diese Kennzeichnung beschränkt und zusätzlich über einen verpflichtenden Lifecycle-Subscriber an Sandbox-/Firmen-/Konfigurationsrechte gebunden.

## Graph und eingefrorener Plan

Der Planner liest ausschließlich eingefrorene Ziele/Module eines vorhandenen Run-Snapshots. Positive Mengen bilden Entitätsknoten; ausgeschaltete Module, fehlende oder nicht moduskompatible echte Generatoren blockieren. Nullmengen werden nicht zu Generierungsaufträgen. Metadaten werden deterministisch ausgewählt und Generatorcode/-version sowie Vertragsversion im Step gespeichert.

Finanzeinrichtung ist eine zunächst **ungeprüfte externe Voraussetzung**. Debitor, Kreditor und Artikel folgen ihr. Belege benötigen ihre Stammdaten; fehlen diese in den Zielmengen, entstehen externe Referenzprüfungen, keine erfundenen Generierungsmengen. Für tatsächlich gebuchte/teilgebuchte Verkaufsmengen wird ein Bestandsprüfknoten eingeplant; vorhandene gebuchte Einkaufsziele liegen davor. Das ersetzt keine künftige konkrete Setup-/Bestandsprüfung oder prozessspezifische Generatorregeln. Aktuell sind diese externen Nachweise und alle echten Fachgeneratoren noch nicht vorhanden; reale Läufe sind deshalb blockiert.

Die topologische Sortierung nutzt deterministische Auswahl nach Knotencode. Vorhandene optionale Vorgänger ordnen die Ausführung; fehlende optionale Vorgänger sind erlaubt. Fehlende Pflichtvorgänger blockieren. Verbleibende unsortierbare Knoten werden als zyklisch oder von einem Zyklus abhängig ausgewiesen. Meldungen werden aus stabilen Fehlercodes in der aktuellen Anzeigesprache dargestellt.

Die Laufkarte erhält über eine PageExtension die Aktionen Vorschau, Plan speichern und Startfähigkeit prüfen sowie eine Liste gespeicherter Steps. Vorschau ist temporär und verwendet den aktuellen kompilierten Katalog. Speichern schreibt Planversion 1 atomar und sperrt den Run Header zur Serialisierung konkurrierender Speicherungen. Wiederholtes Speichern erhält einen bereits vorhandenen Plan. Ein geänderter Katalog ersetzt gespeicherte Versionen nicht; dafür ist ein neuer Run aufzunehmen. Der Run Header bleibt unverändert im Entwurf. Step-Änderung, -Löschung und -Umbenennung sind gesperrt, auch ohne Tabellentrigger. Persistierte Blocker bleiben erhalten.

Startprüfung verlangt einen gespeicherten blockerfreien Plan, passende aktuelle Bindung/Version/Modus, keine Vertragsprobe und den Status Ready sowie den Lifecycle-Guard. Dieser prüft tatsächliche Umgebung/Firma, aktuelle Freigaben und Limits; eine Postingfreigabe wird hier nicht automatisch erteilt. Es gibt noch keinen Ready-Übergang, Queue-Start, Worker oder fachliche Ausführung. SF-012/SF-013 müssen diese Prüfung beim späteren Start erneut anwenden und Status-/Claim-/Checkpoint-Persistenz ergänzen.

## Modul- und Sicherheitsgrenzen

Core enthält gemeinsame JSON-/Fehler-/Abhängigkeitstypen; ModuleRegistry referenziert nur Core. DependencyManager referenziert Core, Registry und ScenarioManagement. Die PageExtension liegt im DependencyManager, sodass ScenarioManagement keinen ausführbaren Rückverweis zum Planer bekommt. Lifecycle bindet die Guard-Ereignisse; das Core-Permission-Set aggregiert die eigenen Objektrechte lediglich deklarativ.

`BCSF Plan Writer` erhält ausschließlich Insert auf die eigene Run-Step-Tabelle; Anwender indirektes Insert und Lesen. Vier verpflichtende Datenbank-Subscriber sichern persistente Steps, zwei weitere Subscriber Probe-Ausführung und Startprüfung. Temporäre Vorschauen schreiben keine SQL-Steps. Keine Standarddatenrechte, Ledger-Inserts, TryFunction-Schreibpfade, zusätzlichen App-Abhängigkeiten oder expliziten Commits.

## Prüfung und offene Abnahme

Compiler/CodeCop/UICop mit Warnungen als Fehlern: 56 Dateien erfolgreich; drei AW0006-Informationsmeldungen für bewusst nicht separat suchbare Karten/Vorschau. XLIFF-Prüfung: 443 Einheiten in fünf deutschen Kulturen und en-US vollständig. Namen, lokale IDs, Objektplan und Konfigurations-/Ticketgrenzen werden lokal geprüft; Details in [TESTS.md](TESTS.md).

Über den Generator-Katalog ist eine lesende Vertrags-Selbstprüfung aufrufbar; über die Vorschau eine Graph-Selbstprüfung mit Finance→Stamm→Einkauf→Bestand→Verkauf, fehlendem Pflichtvorgänger, optional fehlendem Vorgänger und absichtlichem Zyklus. Beide normalen Codeunits sind kompiliert, **nicht in BC ausgeführt**. Eine separate Test-App wird hier nicht angelegt.

Nach freigegebener Installation in Playground manuell prüfen: beide Katalogeinträge/Dispatch/Resume, Vorschau und Plan speichern, identisches wiederholtes Speichern, unveränderte Steps nach Vorlagenänderung, klare Blocker, direkter Schreibversuch ohne Trigger, fehlende Rechte, falsche Firma/Umgebung sowie Deutsch/Englisch. Prüfen, dass keine Debitoren/Kreditoren/Artikel/Buchungen entstehen und kein Lauf startet. Runtime-, Berechtigungs-, Parallelitäts- und UI-Abnahme bleiben offen; SF-001-Fragen zu Publisher/Testfirma/reeller Zielumgebung werden nicht als gelöst erklärt.
