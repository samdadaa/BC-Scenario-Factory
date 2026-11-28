# JavaScript-Dashboard und Role-Center – SF-014

**SF-044 (19.11.2026):** Die aktuelle kompakte Ansicht mit Daten-/Laufreitern und Kacheln ist in [Daten im Mandanten](DASHBOARD_DATA_STOCK.md#sf-044--kompakter-arbeitsplatz-19112026) beschrieben. Frühere Titel-, Seitenleisten-, Tabellen- und Fortschrittsbalkenangaben unten sind historische Nachweise. Die Einbettung über die bestehende CardPart bleibt erhalten.

**Aktueller Stand ab 1.0.2.0:** Der reale Bedienweg ist in [Mandanteneinrichtung und Vorlagenstart](COMPANY_INITIALIZATION.md) beschrieben. Ältere Angaben zu Finanzauswahl je Vorlage, Vorschaufenster, Wizard, parallelen Lauflisten und Dashboard-Host sind historische Nachweise. Entfernte Objekt-IDs bleiben unbenutzt.

**Stand: 16.11.2026, Zur Prüfung.** Die präzisierte Nutzervorgabe ist umgesetzt: JavaScript-ControlAddIn als zentrales App-Dashboard, eigenes Role-Center mit Profil und wiederverwendbare Dashboard-CardPart. Die native frühere Dashboardliste bleibt als Laufmonitor erhalten.

## Einstieg und Bedienung

Nach einer separat freizugebenden Installation kann das Profil **BC Scenario Factory** unter „Meine Einstellungen“ als Rolle ausgewählt werden. Es wird nicht automatisch zugewiesen. Profil und Role-Center ändern keine fachlichen Berechtigungen: `BCSF ADMIN` plus ggf. BC-Standardrechte für Queue/Protokolle werden separat benötigt.

Das eigene Role-Center zeigt den vollständigen Arbeitsplatz. **Neues Szenario** öffnet nach ausdrücklicher Anlage den bestehenden Fünf-Schritt-Assistenten. Die Navigation führt zu Szenariovorlagen, erfassten Läufen, Ausführungen, Paketen/Wiederaufnahme, Herkunftseinträgen, Generatorkatalog, Einrichtung und nativem Laufmonitor. Diese Seiten bleiben ohne erneute Suche direkt erreichbar. Die Vorlagenkarte enthält Mengen/Module, Kopieren und Snapshot-Erfassung; der Katalog enthält die Vertragsprüfung; Paketdetails enthalten bestehende abgesicherte Retry-/Reconciliationaktionen.

Für den gewählten Lauf stehen 19 direkte Einstiege bereit:

- Laufkarte, Quellvorlage, Konfigurationsassistent, Abhängigkeitsvorschau, Plan speichern, Bereitschaft prüfen, Einrichtungsvorprüfung und synthetische Eingangsvorschau.
- Pakete vorbereiten, freigeben/einplanen, Pause/Abbruch anfordern, Anforderungen anwenden und ab Checkpoints fortsetzen.
- Schrittdetails, Pakete/Queueprotokolle, Statushistorie, Herkunftseinträge und aktueller Queueeintrag.

Die großen Zähler zeigen sichtbare Vorlagen/Läufe sowie aktive bzw. fehlgeschlagene Ausführungen. Es sind keine globalen Generierungs-/Qualitätsquoten. Die Laufwahl ist auf die 25 zuletzt erfassten Runs begrenzt, absteigend über einen neuen Leseschlüssel `Run Header.(Created At, Run Id)`. Die vollständige Historie ist über „Erfasste Läufe“ erreichbar. Ein explizit übergebener älterer Run bleibt auswählbar. Step-Soll/Ist, offene Einheiten und Artefakte verwenden den bestehenden SF-014-Vertrag; externe Voraussetzungen erhalten keinen Generierungsfortschrittsbalken.

Die vollständige Hostseite heißt in BC **Scenario Factory Dashboard**. Die ursprüngliche native Liste heißt jetzt **Scenario Factory Run Monitor**; Objektname/ID 90351 sind erhalten. Vorhandene Laufkarten-/Wizard-Dashboardlinks öffnen die neue Hostseite mit der zugehörigen Run-ID.

## Dasselbe Dashboard in weitere Role-Center einbauen

Wiederverwendbare öffentliche Seite: **Page 90362 `BCSF Dashboard Part`**. Sie ist eine eigenständige CardPart mit dem ControlAddIn und benötigt keine Hosttabelle. Einbettungen verwenden dieselbe UI, denselben Datenservice und dieselben Serveraktionen. Die optionale Page-Methode `SetRunId(Guid)` dient einer Hostseite mit bekanntem Laufkontext; das Role-Center benötigt keinen Prozeduraufruf.

Ein anderer **erweiterbarer** Role-Center erhält die Part über eine PageExtension. Dazu müssen eine freigegebene freie Objekt-ID, Namespace/Abhängigkeit und die tatsächliche Zielseite geprüft werden. Das folgende Schema enthält deshalb bewusst einen ID-Platzhalter und ist kein zusätzlich installiertes Objekt:

```al
// <freigegebene ID> vor Kompilierung anhand app.json und OBJECT_PLAN ersetzen.
// Die konkrete Zielseite und deren Namespace aus den Zielversionssymbolen prüfen.
pageextension <freigegebene ID> "BCSF Additional Role Dashboard" extends "Business Manager Role Center"
{
  layout
  {
    addlast(RoleCenter)
    {
      part(ScenarioFactoryWorkspace; "BCSF Dashboard Part")
      {
        ApplicationArea = All;
      }
    }
  }
}
```

Im selben App-Projekt den Monitoring-Namespace verwenden. In einer separaten Erweiterung `using BCScenarioFactory.Monitoring;` und eine reguläre Dependency auf diese App konfigurieren; diese App erhält dadurch selbst keine neue Abhängigkeit. Das ist die technische Wiederverwendung der UI, keine öffentliche Generator-API aus SF-034.

BC-Personalisierung kann vorhandene Teile anordnen/ausblenden. Sie kann keine bislang nicht deklarierte beliebige CardPart in irgendeine Seite einsetzen. Deshalb ist je gewünschter Role-Center-Seite eine passende PageExtension erforderlich; es gibt keine dynamische globale Einbauzusage für alle Standard- oder Fremd-Role-Center. Das eigene Profil und die vollständige Hostseite sind bereits im App-Code enthalten. Bestehende Standard-Role-Center wurden nicht ungefragt erweitert.

## Ressourcen, Sicherheit und Datenfluss

`ControlAddIn BCSF Dashboard` → `BCSF Dashboard Part` → Datenservice 90365 bzw. Aktionsservice 90366. Die Hostseite 90363 und das Role-Center 90364 verwenden dieselbe Part. ControlAddIn und Profil haben in AL keine numerische Objekt-ID; 90361 bleibt freie Monitoringreserve. Konkrete Zuordnungen im [Objektplan](OBJECT_PLAN.md).

- Ausschließlich gebündelte eigene Dateien `src/Monitoring/Dashboard/dashboard.js`, `startup.js`, `dashboard.css`. Keine Bibliotheksinstallation, CDN-, Font-, HTTP-, Telemetrie- oder Speicherzugriffe aus der UI. Keine externen Webinhalte oder WebPageViewer-Abkürzung.
- UI-Texte werden als AL-Labels/XLIFF zur aktuellen BC-Sitzungssprache geliefert. Technische Codes sind keine Übersetzungsschlüssel im Frontend. Zahlen über Intl, Zeitpunkte serverseitig formatiert. Übersetzungsumfang mit dem vorhandenen Prüfer validieren.
- Daten kommen ausschließlich aus den vorhandenen eigenen Tabellen bzw. der bestehenden temporären Step-Projektion; keine zusätzlichen Personen-/Fehler-/Standardfachdaten in den JSON-Daten. Leserechte/Sicherheitsfilter bleiben wirksam; sichtbare Teilbestände sind keine Zusage vollständiger globaler Datenabdeckung.
- Anzeigedaten werden mit `textContent` und DOM-Elementen aufgebaut. Kein `innerHTML`, HTML aus Beschreibung/Profil, `eval` oder beliebige URL-Navigation. Aktionscodes werden serverseitig über eine feste Liste auf konkrete Appfunktionen abgebildet. GUID wird begrenzt, geparst und per aktuellem Header.Get geprüft; keine vom Client gewählten Seiten-IDs, Tabellen, Firmen, Filter oder Freigabeparameter.
- Neue Szenarien entstehen nur auf Klick. Weitere mutierende Aktionen verlangen serverseitige Bestätigung (Default Nein). Terminierung verwendet den vorhandenen AL-Startdialog plus Bestätigung und Dispatcher. Guards, aktuelle Startprüfungen, indirekte Rechte und vorhandene Recovery-Commitgrenzen bleiben im bisherigen Backend. Keine neuen Codeunit-Permissions, kein neuer expliziter Commit, keine JavaScript-Buchungsfreigabe.
- Ready-Handshake vor erstem Payload, keine automatischen Start-/Retryaktionen beim Öffnen. Eine aktive Anfrage sperrt weitere Schaltflächen; Erfolgs-/Fehlercallback hebt die Sperre auf. Statusrückmeldung über aria-live. Responsive Darstellung, semantische Buttons/Labels/Tabellen/Progress, Tastaturfokus und reduzierte Animationen. Keine periodischen Refreshrequests; Aktualisieren ist ausdrücklich.

## Prüfung und Grenzen

`node scripts/check_dashboard.mjs` startet eine vorhandene Chromiuminstallation mit isoliertem temporärem Profil und einem lokalen Server. Node 22+ erforderlich, keine npm-Abhängigkeiten. Auf anderen Rechnern `CHROME_BIN` auf die vorhandene Chromiumdatei setzen. Die Prüfung verwendet echte gebündelte JS-/CSS-Dateien und ausschließlich synthetische Daten mit nachgebildeter BC-Nachrichtenschnittstelle. Kein BC-Login/Deployment und kein Ausführen der AL-Aktionen. Vorschau-PNG und temporäres Testprofil liegen außerhalb des Projekts; das Profil wird nach der Prüfung entfernt.

Der Browserprüfung zufolge funktionieren Handshake, Navigation, Run-ID-Übertragung, bestätigte/offene/Artefaktanzeige, Doppelklickschutz, Fehlerwiederholung, sicheres Rendern eines HTML-artigen Namens, Leerzustand und 320/768/1440-Pixelbreiten. Das ersetzt keine echte BC-Iframe-/Role-Center-/Profilauswahl-/Dialog-/Rechte-/Queue-/Tastatur-/Screenreaderabnahme. Der vollständige AL-Cloud-Build gegen die lokalen BC-28.5-/DE-Symbole mit Runtime 17 und Übersetzungs-/Paketprüfung sind in [TESTS.md](TESTS.md) nachgewiesen.

Vollständige Branchenprofile, echte Fachgenerator-/Setupbindungen und globale Qualitätsvalidierung fehlen weiterhin. Status **Zur Prüfung**, keine Veröffentlichung/Installation oder menschliche Abnahme behauptet.

## Microsoft-Quellen

Am 16.11.2026 geprüft: [ControlAddIn](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-addin-object), [asynchrone Kommunikation](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-addin-asynchronous-considerations), [InvokeExtensibilityMethod](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-invokeextensibility-method), [CardPart-Einbettung](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-designing-cardparts), [Profile](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-design-profiles) und [VerticalStretch](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-verticalstretch-property). AL-Syntax und verwendete App-Objekte zusätzlich lokal kompiliert; das Einbauschema ist bewusst kein kompiliertes zusätzliches Standard-Role-Center-Objekt.


## SF-014 – Scrollbereich und deutsche Anzeige, 17.11.2026

Das Dashboard besitzt einen eigenen, auf die verfügbare Iframehöhe begrenzten Scrollbereich (`#controlAddIn`, Höhe 100 %, overflow auto). HTML/Body erzeugen keinen konkurrierenden äußeren Scrollbereich. Die Region ist fokussierbar; PageDown/Tastaturnavigation erreichen untere Aktionen und Footer. Aktualisieren bewahrt die Scrollposition; Tabellen behalten ihren eigenen horizontalen Scrollbereich.

Die UI folgt weiterhin der vom Server gelieferten BC-Sitzungssprache (Meine Einstellungen), nicht der Datensprache des Szenarios oder allein der Zahlenregion. Falls bei deutscher Sitzung englische Dashboardlabels ankommen, übersetzt eine gebündelte eigene Ressource ausschließlich bekannte UI-Labels und technische Monitoring-Statusmeldungen. Bereits übersetzte Texte bleiben erhalten; Beschreibungen, Profil- und Entitätscodes werden nicht umgeschrieben. `translations.js` wird mit `python3 scripts/build_dashboard_translations.py` ausschließlich aus den geprüften de-DE-XLIFF-Einträgen der beiden Codeunits Dashboard Data und Monitoring Mgt erzeugt. Keine separaten handgepflegten Übersetzungen, externen Requests oder Browser-Spracherkennung. Nach XLIFF-Änderungen neu erzeugen; `--check` und der bestehende Browsertest verhindern veraltete Ableitungen. Die fünf deutschen Regionen verwenden den gemeinsamen deutschen Master, passend zu den vorhandenen identischen Regionaldateien. Englische UI mit deutscher Formatregion bleibt Englisch.

Die konkrete Ursache fehlender AL-Labelübersetzungen in der gemeldeten laufenden BC-Sitzung bleibt **Zu prüfen**; korrekte Dateien im lokalen Paket belegen nicht den dort installierten Stand. Microsoft weist darauf hin, dass [Incremental Build und RAD Publishing Übersetzungen ignorieren](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files). Für eine spätere autorisierte Installation einen vollständigen Build verwenden und das Dashboard anschließend neu öffnen. Dieser Korrekturauftrag enthält keine Veröffentlichung oder Installation. Echte BC-Sitzungs-/Role-Center-Abnahme steht aus; [Prüfergebnisse](TESTS.md#sf-014--scroll--und-sprachkorrektur-17112026). Status **Zur Prüfung**.

## Live Control Center (SF-057)

Dasselbe Control-Add-in, keine zweite Implementierung, keine zusätzliche BC-Seite. Aufbau der Läufe-Ansicht (und der Datenansicht, wenn der gewählte Lauf der Unternehmenslauf ist): **Laufstatus-Kopf → Modulkarten**.

- **Kopf:** Branche (Unternehmensbranche, sonst Profil), Status, Gesamtfortschrittskreis aus bestätigten Einheiten (`min(bestätigt, Ziel)` über Ziel; ohne Ziele Paketverhältnis), Module fertig/in Verarbeitung/wartend, Fehler, Warnungen, Laufzeit (aus `startedIso`/`finishedIso`, Uhr läuft clientseitig mit dem 1-s-Takt, endet bei Abschluss), aktueller Schritt (`currentNode` = laufendes Paket) und optional aufklappbarer Aktivitätsfeed. Übersprungene oder unbestätigte Einheiten zählen nie als erzeugt.
- **Fehler:** fehlgeschlagene Pakete plus Qualitätsstufe *Fehler*; bei Status Fehlgeschlagen/Validierung fehlgeschlagen mindestens 1. **Warnungen:** Entitäten mit übersprungenen/unbestätigten Einheiten (sonst Pakete *Prüfung erforderlich*) plus Qualitätswarnung. Modulstatus: Fehler (rot, über `failedNodes`) > Prüfung (orange) > fertig (grün) > in Verarbeitung (blau, nur mit bestätigten Einheiten oder laufendem Paket) > wartend (grau).
- **Modulkarten:** Module stammen aus `moduleDefinitions` (id, Titel, Akzentfarbe, Icon, beanspruchte Ergebnisschlüssel, bevorzugte Kennzahlen). Ein neues Modul braucht nur einen Eintrag; nicht zugeordnete Ergebnisse landen in *Weitere Ergebnisse*. Raster: höchstens vier Spalten (mind. 320 px), eine Spalte auf schmalen Breiten, Karten oben ausgerichtet, damit aufgeklappte Karten Nachbarn nicht vergrößern. Zugeklappt zwei bis vier klickbare Kennzahlen mit fester Mindesthöhe; Details enthalten jede bisherige Entitätskachel (erzeugt/Ziel/offen, Hinweise, Navigation `runOpen` zu den Standardlisten). Mehrere Karten gleichzeitig offen; Zustand liegt im Client (`expanded`) und überlebt jede Aktualisierung.
- **Animation:** Zähler zählen nur bei geänderten echten Werten hoch (Erstanzeige sofort), Ringe/Balken per CSS-Übergang, laufendes Modul pulsiert dezent, einmalige Abschlussmarkierung nur bei tatsächlichem Wechsel auf *fertig* innerhalb desselben Laufs. Keine simulierten Werte; `prefers-reduced-motion` schaltet alles ab. Modulfarbe (Akzent) und Statusfarben (grün/blau/grau/orange/rot) sind getrennt.
- **Aktivitätsfeed:** letzte 12 Zustandswechsel des gewählten Laufs aus der vorhandenen Tabelle *BCSF Run Event* (doppelte Zählerupdates desselben Zustands entfallen); ohne Leserecht auf die Tabelle bleibt der Feed leer. Statustexte nutzen vorhandene Enum-Übersetzungen.
- **Aktualisierung:** unverändert 1-s-Einzelabruf `autoRefresh`; zusätzliche AL-Kosten sind drei gefilterte Zählungen auf *Batch* und eine begrenzte Leseschleife auf *Run Event* je Abruf.

Prüfung: `node scripts/check_dashboard.mjs` (Chromium, synthetische Brücke) deckt jetzt zusätzlich Kopfzähler, Modulstatus, gleiche Kartenhöhe, 1–4 Spalten, Aufklappen ohne Nachbarwirkung, Zustandserhalt/Knotenwiederverwendung, Hochzählen, Navigation, einmalige Abschlussmarkierung, Fehlerstatus und Uhrstopp ab. Kein nativer BC-Lauf; AL-Änderung **nicht kompiliert**.

## Ansichten und Detail-Overlay (SF-058)

Das Add-in hat drei Tabs; nur die aktive Ansicht ist im DOM. Das Wechseln ist rein clientseitig plus ein stiller Befehl `view` (kein Sperrzustand, letzte Anfrage gewinnt), damit der Server nur baut, was die Ansicht braucht. Der Client hält die letzten Ergebnisse der anderen Ansichten (`mergeCache`), bis die Antwort eintrifft.

| Ansicht | Inhalt | Serverdaten je Abruf |
|---|---|---|
| Generierung | Laufauswahl, Kopf, Live-Zeile, Modulkarten, Aktionen/Diagnose | Schritte, Zähler, Ereignisse, Laufergebnisse (`BuildRunResults`) |
| Mandantendaten | Datenumfang-/Lauffilter, Modulkarten je Stockgruppe | alle Stockgruppen (`BuildView`), Schlüssel `Gruppe/Schlüssel`; keine Laufergebnisse |
| Läufe | Summenkacheln, Laufliste, Aktionen/Diagnose des gewählten Laufs | je Lauf Start/Ende und Fehler-/Prüfpakete |

- **Fachliche Trennung:** Generierung = Fortschritt des gewählten Laufs (bestätigte Einheiten). Mandantendaten = vorhandene Datensätze je Datenumfang/Lauffilter (Ring, Balken und Status entfallen). Läufe = Historie. Die Zahlen werden nicht angeglichen.
- **Modulkarte** (eine Komponente für beide Ansichten): Kopf (Icon, Titel, Status, Ring), reservierter Balkenplatz, 2–4 Kennzahlen (anklickbar → `runOpen`/`stockOpen`, unverändert), Fußzeile *Entitäten: n · Alle Details*. Kopf und Fußzeile öffnen das Overlay, die Kennzahlen nie (getrennte Elemente).
- **Overlay:** `position: fixed` im Frame des Add-ins (keine Manipulation der BC-Oberfläche), `role=dialog`, Escape/Klick außen/Schließen, Fokus hinein und zurück, Inhalt intern scrollbar. Es ist ein weiteres Kind der gepatchten Wurzel: Hintergrundaktualisierungen aktualisieren Zähler in denselben Knoten; Tab-Wechsel oder verschwundene Module schließen es. Entitäten ohne Generator stehen in einem eigenen Abschnitt ohne Fortschritt und Navigation.
- **Kopf:** Pillen (`3/4 abgeschlossen`, in Verarbeitung, wartend, Fehler, Warnungen, Laufzeit); Fehler/Warnungen und *Alle Details* öffnen ein Overlay mit Qualität, fehlgeschlagenen/zu prüfenden Entitäten, Buchungsübersprüngen und Stammdatenpool. Die letzte Aktivität steht in der Zusammenfassung des aufklappbaren Feeds.
- **Module:** `moduleDefinitions` (Titel, Farbe, Icon, beanspruchte Schlüssel, `groups`, Kennzahlen) ist die einzige Stelle für neue Module.

Prüfung: `node scripts/check_dashboard.mjs` (Chromium, synthetische Brücke) deckt Tabs, Hero, Karten, Overlay, Filter/Suche, Mandantendaten, Lauflisten, Zustände laufend/erfolgreich/Warnungen/fehlgeschlagen, DE/EN, Spalten bei 320–2200 px, Scrollverhalten und Polling ab. Nicht kompiliert, keine native BC-Prüfung. `scripts/check_dashboard_stock.mjs` ist für die frühere Gruppenoberfläche geschrieben und läuft gegen die neue Oberfläche nicht mehr.

## Kompaktes Control Center (26.11.2026)

Reine Darstellungsoptimierung im bestehenden Control Add-in (`dashboard.js`, `dashboard.css`; kein neues Objekt, keine fachliche Änderung, keine neuen Texte). **Zur Prüfung, nativ in BC nicht abgenommen.**

- **Kopf:** eine Zeile mit kleinem Logo (Symbol des vorhandenen `src/image/Logo.png`, in einem quadratischen CSS-Rahmen zentriert, Seitenverhältnis erhalten, kein Rahmen/Name), Tabs und Aktionen. Das Logo wird über die neue Eigenschaft `Images` des Control Add-ins und `GetImageResource` geladen; fehlt es, bleibt es einfach weg. Keine Überschrift „Arbeitsplatz“, keine Szenariobeschreibung, keine Modulauflistung.
- **Laufauswahl** ohne Beschriftung und ohne Laufkennung (Kurz-ID nur bei gleichnamigen Läufen), in einer Zeile mit Filtern/Suche.
- **Gesamtstatus** in einer Zeile: Fortschrittskreis, Szenario, ein Status, `5/5`-Module, Laufzeit, Fehler/Warnungen (klickbar), „Alle Details“. Live-Zeile (aktueller Schritt, letzte Aktivität) **nur während der Verarbeitung**. Szenario-, Branchen-, Kontenplan-, Prozessstufen-, Zeitraum- und Modulangaben sowie die vollständige Aktivitätsliste stehen in „Alle Details“.
- **Modulkarten:** eine Aktion (Kopfzeile) statt Pfeil plus „Alle Details“, kein doppelter Fortschrittsbalken, Entitätenzahl und Warnhinweis in der Unterzeile, Kennzahlen zweispaltig ohne Mindesthöhe, keine automatische Silbentrennung. Zentrale Maße als CSS-Variablen (`--sf-card-min`, `--sf-ring-s` …).
- **Detail-Overlay:** kleinerer Kopf, kompaktere Kacheln; ein fehlerfreier, vollständiger Eintrag zeigt nur Name und `20 / 20`. Offene Mengen, Hinweise, Überspringungen und Abweichungen bleiben sichtbar, die vollständige Aussage steht im Tooltip.
- **Mandantendaten:** gleiche Karten, Filter in einer Zeile, ohne wiederholten Geltungsbereichssatz.
- **Läufe:** flache Zeilen (Name/Branche/Modus/Kontenplan, Status, Datum, Laufzeit, Fehler/Warnungen) mit eigener Aktion „Ergebnisse öffnen“ / „Fortschritt“ / „Fehler anzeigen“ je Lauf; Start eines Laufs bleibt in der Diagnose des gewählten Laufs. Diagnose und Expertenwerkzeuge teilen sich eine Überschrift.
- **Grenzen:** Hell-/Dunkelmodus nicht geprüft; es gibt nur ein Logo und das Dashboard setzt weiterhin `color-scheme: light`. Die Mindestanzahl sichtbarer Karten (8) wurde im lokalen Chrome-Test bei 1440×900 mit 12 Modulen geprüft, nicht in BC.
