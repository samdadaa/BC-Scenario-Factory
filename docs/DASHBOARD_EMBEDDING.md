# JavaScript-Dashboard und Role-Center – SF-014

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
