# SF-049 / SF-050 – lokaler Teilstand vom 22.11.2026

**App 1.0.10.0, Test-App 1.6.0.0. Status: In Arbeit. Keine native Abnahme.** Der Nutzer hat SF-049 bis SF-053 gemeinsam zur sequenziellen Umsetzung ausgewählt. Der neue Fahrplan bis TODO-Zeile 1040 und der vorhandene Nutzerdiff bleiben erhalten. SF-051–SF-053 sind in diesem Teilstand **nicht implementiert**.

## Ziel, Umfang und Risiken

Den vorhandenen lesenden Quellendienst, Snapshot, Mengenplaner und die vorhandene Queue weiterverwenden. Keine zweite Engine, kein Vorlagensystem, keine Stammduplikate und keine direkte Standardpostenanlage. Betroffen sind DataGeneration, ScenarioManagement, ProcessEngine, Sales, Purchasing, BackgroundProcessing und Monitoring sowie der bestehende Testhost und Übersetzungen.

Der erste Schritt beseitigt bei neuen Bewegungsläufen die pauschale Pflicht zu zwei Lieferanten mit je vier Artikeln. Zweiter Schritt ist ein überprüfbarer, atomar gespeicherter Nachweis für vor dem Posting ausgelassene Verkaufsbuchungen wegen Fehlbestand. Standardbuchungsfehler nach Eintritt in die Buchung sind ein anderer Fall und werden weiterhin nicht verschluckt oder automatisch wiederholt.

Risiken: Standardtrigger/Fremderweiterungen, tatsächliche Buchungs-/Rollbackgrenzen, große Kandidatenpools, unterschiedliche Standardbuchungsgruppen/Dimensionen und Änderungen zwischen Snapshot und Ausführung. Lokale Symbole BC 28.5/DE, gemeldete Zielversion BC 29.1. Ein Compilerlauf beweist keine native Rückabwicklung oder Rechteabnahme.

## Implementierter Teil von SF-049

- Neue bestehende-Mandanten-Bindung **Version 3**: positive Zielarten bestimmen, ob Kunden oder Lieferanten benötigt werden. Sales-only verlangt keinen Lieferanten, Purchase-only keinen Kunden. Ein geeigneter Lieferant reicht aus; dessen Sortiment darf kleiner oder größer als das anderer Lieferanten sein. Die neue Auswahl hat keine 500-Artikelgrenze und kürzt Sortimente nicht auf das kleinste Lieferantensortiment.
- Geeignete Artikel werden explizit per SystemId erfasst. Bei gemischten Verkaufsbuchungsgruppen wird deterministisch die erste Kundenauswahl mit dem größten kompatiblen Artikelsortiment und alle hierzu geeigneten Kunden gewählt. Weitere geprüfte Datensätze bleiben ausgeschlossen und werden nicht verändert. Das ist eine kompatible Auswahl, keine Zusage, sämtliche Mandantenstämme gemeinsam verwenden zu können.
- Verkaufs-/Einkaufssperren, Basiseinheit, einfacher Lagerort ohne Warehouse, Reservierungs-/Tracking-/Variantenbedingungen, Gruppen-/Kontenmatrix und gültige Standarddimensionswerte werden lesend berücksichtigt. Standardbelegvalidierung und bestehende Rechte-/Nummernserienprüfungen bleiben zusätzlich zwingend.
- Die Bindung hält ausgewählte Kunden/Lieferanten/Artikel, zugehörige Lieferanten-SystemIds, Lagerort sowie die geprüften Kandidatenzahlen. Verkauf erhält **dieselbe** einmalig erfasste Bindung aus dem internen Snapshot-Ereignis; keine zweite unabhängige Kandidatenauswahl.
- Laufende Prüfungen lesen nur die eingefrorenen Identitäten und den eingefrorenen Lagerort. Zusätzlich angelegte, nicht ausgewählte Mandantenstämme machen Version 3 nicht allein deshalb ungültig. Änderungen der gebundenen Artikel-/Lieferantenbeziehung sperren den Lauf.
- Einkaufspositionen werden innerhalb des tatsächlichen Sortiments ihres ausgewählten Lieferanten zyklisch gewählt. Mengen der neuen Geschäftsbelege bleiben unabhängig vom Stammdatenziel. Null-Run-ID wird als vorhandener Mandantenpool unterstützt. Bestätigte Factory-Quellen Version 1 sowie vorhandene Mandantenbindungen Version 2 behalten ihre bisherigen Auswahlverträge.
- Dashboard zeigt geeignet/geprüft je Stammart; ausgeschlossene Kandidaten sind die Differenz. Kein Wiederverwenden als neues Registry-Stammergebnis.

**Offener SF-049-Umfang:** Dokumentart-/Modusfeinheit aller Eignungsprüfungen (die neue Poolwahl bleibt bezüglich Konten konservativ), vollständige Dimensionskombinationen, große Poolmessungen und native Fälle 0/1/Grenzmenge, 40/400 Artikel, SKR03/SKR04/Bestandsfirma, Rechte und DE/EN. Keine Behauptung vollständiger SF-049-Erfüllung.

## Implementierter Teil von SF-050

Bei angeforderter Verkaufsbuchung mit referenzierten Stämmen wird der erforderliche stichtagsbezogene unreservierte Bestand **vor** Standardposting geprüft. Wiederholte Artikelpositionen werden kumuliert. Der ursprüngliche Teilbuchungsmodus bleibt während der gesamten Prüfung erhalten; erst danach wird bei Fehlbestand auf ungebucht entschieden. Der vorhandene Artikelpostenlock liegt vor dieser Prüfung.

Der tatsächlich angelegte ungebuchte Beleg erhält im selben Registry-Insert die additiven Felder 14 `Posting Skipped` und 15 `Skip Reason Code = STOCK`. Zulässig ist diese Kombination nur für Verkaufsauftrag/-rechnung und ein tatsächliches Sales-Header-Dokument. Es wird keine gebuchte Rechnung erfunden. Die bisherige Registry-Signatur bleibt als delegierender Overload erhalten, sämtliche Persistenzguards bleiben aktiv.

Neue Version-3-Ausgabevalidierung verlangt diesen konkreten Auslassungsnachweis, wenn eine geplante Rechnung nur ungebucht vorliegt. Historische Bindungen ohne diese neuen Felder werden nicht rückwirkend verändert. Der Qualitätsabschluss erzeugt `WARN-POSTING-SKIPPED` und damit `CompletedWithWarnings`, wenn alle Pflichtnachweise vorliegen. Dashboard nennt die Anzahl und den Grund; die bestehende Herkunftsliste zeigt beide Felder. Ungebuchte und gebuchte Standardlisten bleiben die tatsächlichen Datenquellen.

**Offener SF-050-Kernumfang:** Eine unerwartete Buchungsausnahme kann weiterhin den gesamten atomaren Batch zurückrollen und in NeedsReview führen. Es gibt noch keine neue isolierte pro-Vorgang-Standardbuchung mit nachgewiesenem Rollback und anschließender Fortsetzung unabhängiger Arbeit. Kein neuer Catch/Schreib-TryFunction/Boolean-Postingaufruf, kein Entfernen von CommitBehavior::Error, kein neuer Retry. Aktive/terminale Initialisierungsjobs und vorhandene Live-Drilldowns wurden geprüft, ihre bestehenden Korrekturen nicht erneut gebaut. Native R08–R11/R13 und Simultanstart/Recovery bleiben offen. Das ist **keine abgeschlossene Umsetzung von SF-050**.

## Kompatibilität und Vorlagen

145 Main-Objekte; keine neue Tabelle/Seite/Objekt-ID oder App-Abhängigkeit. App-ID, Publisher, Runtime 17, Application 28 und ID-Bereich 90100–90999 erhalten. Zwei additive Registryfelder; vorhandene Einträge haben false/leeren Grund. Snapshot-Wurzelschema bleibt 1. Keine Änderung bestehender Captures oder gespeicherter Läufe, kein ForceSync. Das interne Capture-Sales-Ereignis erhält die bereits erfasste Masterbindung als zusätzlichen Parameter; die einzige lokale Subscription wurde gemeinsam angepasst.

Die vorhandenen SF-048-Startvorlagen `...0006` (15 Bestellungen) und `...0007` (20 Aufträge) nutzen bei **neu erstelltem Snapshot mit leerer Quelle** den neuen Pool. Die gemeinsamen Großhandelsstarter behalten ihre Mischquoten und Freigaben. Ein Rechnungs-only-Fall wird über die vorhandenen vier Mengenfelder eingerichtet: Einkauf/Angebot/Auftrag 0, Rechnung 1. Kein zusätzlicher Starter und keine Migration eigener Namen, Werte, entfernter oder archivierter Vorlagen erforderlich. Die zuvor enthaltene historische Aussage „leere Quelle stoppt immer“ in MODULAR_GENERATION wird durch diesen Vertrag präzisiert.

## Prüfungen

Der finale lokale Nachweis wird unten ergänzt. Alle AL-Testmethoden sind bis zu einem tatsächlichen BC-Runnerlauf **nur kompiliert**.

Neue Methoden im bestehenden Testobjekt 90700:

- `SelectedPoolAllowsSalesWithoutVendors`: Rechnung-only 1, 100 %, keine Lieferanten-/Beschaffungsabhängigkeit, fehlende und außerhalb des Ziels liegende Schlüssel.
- `SelectedSupplierPoolsAllowUnequalCounts`: synthetische zurückzurollende Standardstamm-Fixture, Lieferantensortimente 2/5/3, voller Artikelraum, Lieferantentreue über 30 Bestellungen und vier Positionen, einzelner Lieferant, ungültige Schlüssel.
- `SkippedDocumentsHaveNoPostingEvidence`: benötigt tatsächlich erzeugten Fehlbestands-Referenzlauf; verlangt STOCK-Herkunft, echte ungebuchte Zeilen ohne fakturierte/gelieferte Menge und keine INVOICE-Identität.

## Noch erforderliche native Prüfung und folgende Tickets

| Fall | Erwarteter Nachweis |
| --- | --- |
| Verkaufsrechnung-only, 1/40/400 Artikel, ohne Source-ID | Keine neuen Stämme/Bestellungen; nur die angeforderte Belegart; realer Bestand bestimmt Buchbarkeit. |
| Einkauf-only, ein Lieferant, ungleiche Sortimente | Keine Kundenpflicht, keine fremden Lieferantenpositionen, korrekte Standardeingänge/Rechnungen. |
| Zweiter Lauf / zusätzlicher ungebundener Stamm | Neue Belege mit neuer Run-ID; alte Bindung bleibt bei unveränderten ausgewählten Stämmen verwendbar. |
| Gebundener Artikel/Lieferant geändert oder gelöscht | Konkrete Sperre, kein stiller Identitätswechsel und keine Neuregistrierung fremder Stämme. |
| Kein/teilweiser/voller Bestand, wiederholte Artikel, Teilbuchung | Fehlbestand bleibt ungebucht mit STOCK/Warnung; echte Standardposten nur für tatsächlich gebuchte Vorgänge. |
| Fehler innerhalb Standardposting, Sessionabbruch, Wiederanlauf | Unklare Arbeit bleibt gesperrt; sichere Isolation und Reconciliation sind vor Fortsetzung separat zu implementieren/nachzuweisen. |
| SKR03/SKR04/Bestandsmandant, normale/fehlende Rechte, DE/EN, additives Upgrade | Reale Standardlisten-/Postensummen, passende Befunde, geschützte Historie und korrekte Sprachen. |

SF-051 (Zahlungsmodi/Teilzahlungen), SF-052 (echte Retouren/Gutschriften) und SF-053 (Artikelbuchblätter/Inventur/Umlagerung) bleiben entsprechend ihrer Abhängigkeiten offen. Ihre Umsetzung darf den hier noch fehlenden Isolations-/Buchungsnachweis nicht durch pauschales TryFunction oder direkte Standardposteninserts ersetzen. Der angefragte bereits autorisierte native Testzugang ist in dieser Sitzung bisher nicht benannt; keine Veröffentlichung oder Anmeldung durchgeführt.


## Tatsächlich ausgeführter lokaler Abschlussnachweis

| Prüfung | Beobachtetes Ergebnis |
| --- | --- |
| `python3 scripts/build_sf019.py --output /tmp/bcsf-sf049-delivery3` | Exit 0: App 1.0.10.0 mit 145 Main-Objekten und separate Test-App 1.6.0.0 mit **68 Testmethoden** kompiliert. Compiler 18.1.43.24897, vorhandener .NET-10-Host, lokale BC-28.5-DE-/Systemsymbole, Cloud/Runtime 17. Kein AL-Runnerlauf. |
| Sechs bestehende Vertragsprüfer im Build | PASS: Inventory, Sales, Purchase, Templates, Config Export und modularer Quellenvertrag. SF-049 ergänzt Schutz gegen Live-Neuauswahl, falsche Capturekopien und fehlende Auslassungsnachweise. Quelle bleibt rein lesend; bestehende negative Kontrollen aktiv. |
| `node scripts/check_dashboard.mjs` | PASS mit lokalem Chromium und synthetischer BC-Brücke. Neue Pool-/STOCK-Anzeige, Entfernen dieser Hinweise bei Refresh und XSS-Gegenprobe; R11 öffnet 19 reale verbleibende Ergebnisse bei 20 bestätigten Einheiten, 0 bleibt ohne Aktion. Vorhandene Polling-/DOM-/DE-EN-/1440-768-320px-/Scrollprüfungen bestanden. Eine veraltete Erwartung auf deaktivierten Drilldown bei 19/20 wurde auf den aktuellen R11-Vertrag korrigiert und um den Leerfall ergänzt. Kein nativer Standardlistenbeweis. |
| `node scripts/check_dashboard_stock.mjs`, `python3 scripts/check_partner_catalog.py` | PASS: bestehende Bridge-/Filter-/Berechtigungsdarstellung und 28 synthetische Partnerkatalogpools. Keine BC-Feldvalidierung ausgeführt. |
| Übersetzungen / Dashboardfallback | PASS: **1.459 Compiler-IDs** in fünf deutschen Kulturen und en-US, Quellen/Platzhalter/Breiten und Fallback aktuell. Neue UI-Texte und im Ausgangsstand nicht passende Translation-Sources synchronisiert. |
| `--analyzers` gegen finalen Quellstand | **Nicht bestanden:** genau acht AA0018-Formatbefunde im unveränderten `BCSFItemCatalog.Codeunit.al`, Zeilen 173–180. Keine weiteren Analyzerfehler; keine Regelunterdrückung. Reine Kompilierung separat erfolgreich. |
| `check_package.py` gegen das abgelegte Paket | PASS: Identität/Version, alle 145 aktuellen AL-Quellen, sieben XLIFF-Dateien mit je 1.459 Einheiten und vier Dashboardressourcen. |
| `git diff --check` | PASS; keine Bestandsdatei gelöscht/verschoben, kein Branch/Commit/Push/Deployment. |
| XERJ ausschließlich `bcsf-docs` | Projektweite Suche, Definition, Codesuche und Memory geprüft. Historische/teilweise unpassende Treffer gegen aktuelle Dateien verifiziert. Codekorpus nicht indiziert, Memory ohne Treffer. Kein anderer Index und keine Laufzeitintegration. |

Reviewartefakte (ausdrücklich **Teilstand**, nicht die abgeschlossenen Tickets SF-049–SF-053):

- [App 1.0.10.0](../../artifacts/BCScenarioFactory-1.0.10.0-SF049-SF050-Partial.app), SHA256 `1e5828868893b3083ce569feed98242aee4da37b64aba2f06b64990b958b16d0`.
- [Test-App 1.6.0.0](../../artifacts/BCScenarioFactory-Tests-1.6.0.0-SF049-SF050-Partial.app), SHA256 `2976e22103a1d00ce441a77e8bd21789904f1df9201915e863dfac2e001d9e09`.
- [Main-Buildlog](../../artifacts/BCScenarioFactory-1.0.10.0-SF049-SF050-Partial-build.log), [Test-Buildlog](../../artifacts/BCScenarioFactory-Tests-1.6.0.0-SF049-SF050-Partial-build.log), [fehlgeschlagener strenger Analyzerlauf](../../artifacts/BCScenarioFactory-1.0.10.0-SF049-SF050-Partial-analyzers.log).

**Nicht ausgeführt:** Veröffentlichung/Installation, Upgrade, BC-29.x-AL-Testausführung, reale SKR03-/SKR04-/Bestandsfirmenläufe, Standardbuchungen/Postenabgleich, Rechte-/Rollback-/Session-/Queue-/Recovery-/Lastabnahme und menschliche Freigabe. Dashboard/Workflow, Stamm-/Einrichtungsabhängigkeiten, DE/EN und geschützte bestehende Starter wurden gemeinsam berücksichtigt. **SF-049 und SF-050 bleiben In Arbeit; SF-051 bis SF-053 offen.**
