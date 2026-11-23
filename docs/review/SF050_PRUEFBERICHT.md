# SF-050 – isolierte Geschäftsvorfälle und vorhandene Mandanteneinrichtung

**23.11.2026 · App 1.0.11.0 · Test-App 1.7.0.0 · Zur Prüfung.** Umsetzung ausschließlich SF-050 plus ausdrücklich nachbeauftragter Fehler im Pfad „Vorhandene gültige BC-Einrichtung“. Der Nutzer übernimmt die native BC-Abnahme. SF-049 behält seine benannten offenen Teile; **SF-051 bis SF-053 werden nicht umgesetzt**. Nach diesem Auftrag endet die Agentenarbeit.

## Ziel, Dateien und Risiken

Vorhandene Queue, Claim, Registry, Checkpoints und Standardbuchungen verwenden. Ein einzelner fehlerhafter Geschäftsvorfall darf unabhängige Vorgänge nicht pauschal zurückhalten, ein unbestätigter Vorgang darf niemals automatisch erneut gebucht werden. Fehlende technische Unternehmensvoraussetzungen im vorhandenen bestätigten Sandboxpfad ergänzen. Keine neue Engine, Seite, Tabelle, zusätzliche Git-Aktion oder Veröffentlichung.

Betroffene Dateien liegen in BackgroundProcessing (Dispatcher, Worker, Failure, Runner, Recovery, Rules, Quality, Batch und bestehende Paketliste), DataGeneration (Partner Rules und Quellendienst), Sales/Purchasing (lesende Vorgangsprüfung), ScenarioManagement (Snapshot), Core (Contract JSON und bestehende Einrichtungskarte), Monitoring (temporäre Kennzahlen und Dashboard), Finance (vorhandene Foundation-/Paket-/Prüfdienste), IndustryProfiles (bestehendes Unternehmenspaket/Refresh), Übersetzungen, Vertrags-/Clienttests und dem vorhandenen Testobjekt 90700. Die Änderungen bauen auf dem erhaltenen Teilstand 1.0.10.0 auf.

Wesentliche Risiken: Standard-/Fremdextension-Commits, Dienstunterbrechungen, Rechteänderungen beim Folgejob, gleichzeitige Bestandsänderungen, kopierte unvollständige Einrichtung und finanzielle Rollen, die sich aus keinem vorhandenen Mapping ableiten lassen. Der lokale Nachweis erfolgt mit Compiler/Analyzern, bestehenden Sicherheitsverträgen, Test-App-Kompilierung, Sprachen, Chromium-Bridge und Paketvergleich. Native Buchungs-, Rollback-, Rechte- und Upgradeprüfung bleibt beim Nutzer.

## Ausführung und Fehlergrenzen

Neue Snapshots ergänzen **`executionPolicyVersion = 1`** im unveränderten Wurzelschema 1. Fehlender Marker bewahrt den bisherigen Batch-/Reihenfolgevertrag; unbekannte Versionen werden gesperrt. Vorhandene Snapshots und gespeicherte Batchpläne werden nicht verändert.

Neue SALES.QUOTE, SALES.ORDER, SALES.INVOICE und PURCHASE.ORDER werden in **Einzelpakete mit genau einem logischen Geschäftsvorfall** aufgeteilt. Stammdaten behalten ihre erfasste Batchgröße. Die bestehende Grenze von insgesamt 10.000 Paketen je Lauf gilt weiterhin; eine darüber liegende Anforderung wird konkret abgelehnt. Mehr Jobs bedeuten keine garantierte Laufzeit-/Durchsatzverbesserung.

Der Worker speichert weiterhin zuerst seinen unverwechselbaren Claim und führt danach den commitgeschützten Runner aus. Standardbuchung, Herkunft, Checkpoint, Abschluss und Folgejob bleiben in dessen vorgesehener atomarer Arbeit. Keine neuen fachlichen Commits, kein boolescher Posting-Run und kein Schreib-TryFunction. Insbesondere bleiben Payment-Tolerance-Commitunterdrückung und Postingfreigaben erhalten.

Eine unerwartete Ausnahme verlässt den Runner und geht an den bestehenden **BC-Standard-Job-Fehlerhandler**. Dieser markiert den bereits übernommenen Vorgang als `NeedsReview`. Der neue Folgejob verarbeitet ausschließlich **Pending-Arbeit mit neuer eigener Identität**. Er wiederholt den Fehlerauftrag nicht und erklärt dessen Rollback oder Buchungsergebnis nicht nachträglich als bewiesen. `NeedsReview` bleibt ohne gesicherten vorhandenen Checkpoint nicht replaybar.

Dispatcher und Worker prüfen dieselbe Reihenfolgeregel: keine parallele Running-Arbeit, bestätigte Vorgänger gemäß eingefrorenem Generatorvertrag, keine vorab übersprungenen Vorgänger als Liefer-/Stammnachweis. Unabhängige Belege desselben Moduls können nach einem Fehler weiterlaufen. Benötigt ein späteres Modul den fehlerhaften Vorgänger, bleibt es Pending und ungebucht. Nach Ende der ausführbaren unabhängigen Arbeit wird der Lauf bei unbestätigter/abhängig blockierter Arbeit **Failed**, niemals Completed.

Setup- und Queueberechtigungen werden vor der Fortsetzung rein lesend erneut geprüft. Fehlen sie, bleibt der Lauf fehlgeschlagen. Ein Fehler erst beim tatsächlichen Erzeugen des Folgejobs kann die Standard-Fehlerhandlertransaktion verhindern; dann bleibt der dauerhafte Running-Claim weiterhin konservativ gesperrt und muss nach nachgewiesenem Sitzungsende über die vorhandene Unterbrechungsprüfung klassifiziert werden. Es gibt auch hierbei keinen automatischen Retry oder Scheinerfolg.

## Lesende Vorprüfung und Ergebnisbilanz

Vor einem neuen isolierten Vorgang prüfen lesende Subscriber die tatsächlich ausgewählten Kunden/Lieferanten/Artikel und ihre verwendeten Gruppen, Einheiten, Konto-/Dimensionsvoraussetzungen. Fehlende/gesperrte/geänderte Kandidaten führen vor Geschäftsdatenänderungen zu einem **expliziten Skip** mit `CUSTOMER`, `VENDOR`, `ITEM`, `DIMENSION` oder `SOURCE` als stabilem Prüfgrund. Fehlertexte mit Geschäftsdaten werden nicht in neue App-Logs kopiert. Unbekannte Buchungsfehler nach Eintritt in die schreibende Arbeit werden nicht hier abgefangen.

Der Batch erhält additiv:

| Feld | Bedeutung |
| --- | --- |
| 19 `Skipped Units` | Genau 1 für einen lesend übersprungenen isolierten Vorgang, sonst 0. |
| 20 `Skip Reason Code` | Stabile ablehnende Prüfphase; kein Erfolg und keine fingierte RecordId. |

Ein solcher Skip darf weder Geschäftsdatenherkunft noch erstellte/gebuchte Arbeit behaupten. Der Checkpoint behält seine acht technischen Ergebnisfelder und bestätigt `processedUnits = 0`, `createdRecords = 0`. Persistenzprüfung verlangt tatsächliche Sandbox, ursprünglichen Claimbesitz einschließlich aktiver Session-GUID/Standardjob, Einzelbereich und leere Herkunft. Der Grund wird nach dem ersten Schreiben unveränderlich; er kann nicht zum nachträglichen Freigeben unklarer Buchungen benutzt werden. Abschlussprüfung und Reconciliation prüfen diesen besonderen No-write-Vertrag ausdrücklich.

Bei reinen Stammreferenzen wird nicht mehr vor jedem unabhängigen Beleg der gesamte heutige Kandidatenpool erneut als startfähige Gesamtheit verlangt. Identitäten und Einkaufs-Lieferantenzuordnung bleiben im Snapshot eingefroren; die Prüfung des tatsächlich verwendeten Kandidaten erfolgt unmittelbar am Vorgang. Verkäufe vergleichen den verwendeten Stammfingerabdruck; die vorgesehene Lieferantenauswahl arbeitet auf den erfassten Zuordnungen, nicht auf einer stillen Neusortierung geänderter Artikel. Für Factory-Quellen bleibt der Nachweis bestätigter Stammdatenpakete verpflichtend.

**STOCK bleibt ein anderer Fall:** Ein angelegter, mangels Bestand nicht gebuchter Verkaufsbeleg bleibt als tatsächlicher ungebuchter Beleg registriert. Sein vorhandener `Posting Skipped`-/STOCK-Nachweis ist von einem Skip **ohne Beleganlage** getrennt. Beide Fälle führen bei ansonsten gültigen Pflichtnachweisen zu Qualitätswarnungen, nicht zu einer fälschlich gebuchten Rechnung.

Monitoring zeigt erstellte/bestätigte, vor Anlage übersprungene und unbestätigte Einheiten getrennt. Pro Schritt gilt:

`Angefordert = bestätigt/angelegt + vor Anlage übersprungen + noch unbestätigt/ausstehend`

Prüfpflichtige Einheiten sind ein Teil der ausstehenden Menge und werden nicht doppelt addiert. Bei retained STOCK-Belegen ist die Anlage bestätigt, die angeforderte Buchung aber separat ausgelassen. Offene/teilgebuchte Aufträge, Rechnungen und tatsächliche Posten bleiben über die vorhandenen passenden Standardlisten erreichbar; Skipgründe und Originalfehler über Paketliste/Herkunft/Standard-Queueprotokoll. Keine Gleichheitsbedingung zwischen bestätigten Einheiten und heute noch vorhandenen Live-Belegen.

## Zusatzauftrag: importierte Produktions-Einrichtungsdaten in einer Testfirma

Der gemeldete Lagerortfehler ist im Code nachvollziehbar: Existing initialisierte bislang nicht dieselbe technische Basis, und neue interne Vorlagen erwarteten bei leeren Artikelzuordnungen teilweise genau einen Lagerort bzw. eine Buchungsgruppe. Der erste gemeldete Wortlaut belegt diese fehlende/mehrdeutige Zuordnung. Die weitere verschwundene Fehlermeldung ist **nicht rekonstruiert**; daraus wird keine unbekannte konkrete Ursache erfunden.

„Vorhandene gültige BC-Einrichtung“ und die vorhandene Ergänzungsaktion verwenden nun denselben bestätigten Foundationpfad auch für fehlende technische Einrichtung. Die Zusammenfassung erklärt dies vor dem Start; der Hintergrund prüft Sandbox/Firma/Rechte erneut.

- Fehlende gemeinsame Tabellenzeilen/Leerbindungen und benötigte Nummernserien einschließlich einer fehlenden Serienzeile ergänzen; bestehende verwendbare Nummernserien beibehalten. Nicht nutzbare, manuelle, erschöpfte oder datumsinkompatible bestehende Serien werden nicht still umkonfiguriert.
- Benötigte vorhandene/fehlende Herkunftscodes, Standard-Einheiten, Zahlungsbedingungen und allgemeines Buchblatt mit Batch über den bestehenden Dienst bereitstellen. Vorhandene gleichnamige Zahlungsbedingungen werden im Existing-Modus erhalten.
- Einen geeigneten einfachen Lagerort wählen; fehlt er, einen fehlenden MAIN bzw. BCSF-MAIN anlegen. Vorhandene WMS-/Lagerortkonfigurationen bleiben unverändert.
- Fehlende Buchungsgruppencodes aus **bereits vorhandenen verwendbaren Matrizen** ergänzen. Eine fehlende Lagerort-/Lagerbuchungsgruppen-Zuordnung darf die vorhandene nachgewiesene Lagerkontenrolle eines anderen Mappings übernehmen. Bestehende Zeilen werden nicht überschrieben.
- Die neue interne Komplettvorlage explizit an eine kompatible vorhandene General-/VAT-/Lager-/Debitoren-/Kreditorenzuordnung binden. Mehrere gültige Kandidaten allein sind kein Grund mehr für den alten Eindeutigkeitsfehler. Explizit vorhandene, auch historisch gleichnamige Gruppen werden bei der Snapshotauflösung im Existing-Modus erhalten.
- Bankeinrichtung ist nur Voraussetzung der tatsächlich angeforderten Zahlung, nicht pauschal jedes ungebuchten oder buchenden Beleglaufs.

**Grenzen:** Es werden keine neuen Sachkonten, Steuersätze, Forderungs-/Verbindlichkeitsrollen oder bloß aus Kontennamen erratene Finanzmappings erfunden. Fehlt jede verwendbare finanzielle Ausgangszuordnung, wird genau diese Rolle als Blocker gemeldet. Nichtleere widersprüchliche Einstellungen, vorhandene Buchungsperioden und eine bereits bebuchte abweichende Kostenbuchungspolitik werden nicht still verändert. Der bestehende Foundation-Vertrag verwendet EUR für seine Defaultbasis; andere Währungen/abweichende Länderfälle sind keine hier behauptete Universalabdeckung. Fremderweiterungen können zusätzliche, separat zu prüfende Voraussetzungen besitzen.

## Kompatibilität, Workflow und Vorlagen

145 Main-Objekte, keine neue Objekt-ID/Tabelle/Seite oder App-Abhängigkeit. App-Identität, Publisher, Runtime 17 und Bereich 90100–90999 bleiben erhalten. Zwei additive persistente Batchfelder und zwei zusätzliche ausschließlich temporäre Step-Metric-Felder 20/21. Bestehende Registry-Ergänzungen aus 1.0.10.0 bleiben erhalten. Keine ForceSync-Anforderung, kein Löschen oder Umbenennen vorhandener Ergebnisse.

Einrichtung → bestehender Unternehmensassistent → vorhandenes Großhandelspaket → Queue → Dashboard bleibt der einzige Normalweg. Vorhandene Starter, Quoten und Freigaben bleiben gültig. **Neu erfasste** Starterläufe erhalten die neue Ausführungspolitik automatisch; alte Captures nicht. Eigene Namen, Mengen, entfernte/archivierte Starter und gespeicherte Läufe bleiben geschützt. Es gibt keinen neuen Fachgenerator und deshalb keine neue scheinbar ausführbare SF-051/052/053-Vorlage.

## Native Testanleitung für den Nutzer – noch nicht ausgeführt

Nur in der freigegebenen BC-Test-/Sandboxfirma; bei Test-App-Methoden einen Runner mit isolierten, rückrollbaren Testtransaktionen verwenden. Publisher/Version der tatsächlich installierten Pakete prüfen. Fachfälle mit Rollback-/Fehlerdiagnose und Standardlisten/Posten belegen, nicht nur mit einem grünen Dashboard.

| Fall | Schritte und erwarteter Nachweis |
| --- | --- |
| N01 – dein importierter Einrichtungsstand | Neue Testfirma mit den Produktions-Einrichtungsdaten, ohne Geschäftsdaten. Existing wählen; zunächst Klein/Stammdaten, danach neue ungebuchte/gebuchte Läufe. Fehlenden/mehrdeutigen einfachen Lagerort, Einheiten, Serien/Leerbindungen und Matrizen vor/nach dokumentieren. Kein manueller Artikel-Lagerortzwang; neue Vorlage hält konkrete verwendete Zuordnungen. Bestehende Finanzwerte unverändert. |
| N02 – Wiederholung/Abgrenzung | Erneut Basis ergänzen bzw. neuen Komplettlauf starten: keine doppelten Setupzeilen. Bestehende individuelle Zahlungsbedingung/Serienbindung/WMS-Standorte erhalten. Fehlende eindeutig ableitbare Gruppen werden ergänzt, fehlende finanzielle Ausgangsrolle bleibt konkreter Blocker statt Ersatzkonto. |
| N03 – Safe Skip | Ungebuchten Bewegungslauf mit mehreren Belegen aus vorhandenem Pool erfassen, vor Ausführung einen ausgewählten Kunden sperren bzw. einen ausgewählten Artikel löschen/sperren. Betroffene Einzelpakete: Completed mit Skipped Units 1, Created/Processed 0, konkretem Prüfgrund und Checkpoint; keine Geschäftsbelege dafür. Andere gültige Kunden/Artikel liefern weiterhin echte Ergebnisse. Abschluss höchstens CompletedWithWarnings. |
| N04 – echter Standardfehler/Isolation | In isolierter Testfirma eine ungültige Dimensionskombination für einen Teil der Kunden-/Artikelpaare vorbereiten, während die Einzelwerte gültig bleiben; ausreichend realen Bestand bereitstellen. Mehrere gebuchte Verkäufe mit 100-%-Quote anfordern. Ein erst in Standardbelegvalidierung/Posting auftretender Fehler bleibt NeedsReview mit Standardfehler/Stack, spätere unabhängige Belege werden tatsächlich gebucht. Keine Behauptung eines Rollbacks anhand der App-Zähler: tatsächliche Belege/Posten abgleichen. Gesamtlauf bleibt Failed, solange Arbeit unbestätigt ist. |
| N05 – Abhängigkeit und kein Replay | Einkaufsfehler provozieren: unabhängige weitere Einkäufe können fertig werden; die davon abhängige Verkaufsphase bleibt Pending. Beim fehlerhaften Paket Schedule Attempts 1; RetryUnclaimed darf NeedsReview nicht freigeben. Reconciliation ausschließlich mit bereits vorhandenem gültigem Checkpoint und nachgewiesenem Ende des Workers; keine erneute Lieferung/Rechnung/Zahlung. |
| N06 – R08/R09 | Kein/teilweiser/voller stichtagsbezogener unreservierter Bestand, wiederholte Artikel und Teilquoten: keine falsche Rechnung, STOCK-Beleg getrennt vom No-write-Skip. Mit/ohne Zahlung testen; Standard-Toleranz/Applies-to-Validierung bei Zahlung muss commitgeschützt bleiben. Ohne Zahlungsmodus entstehen keine Zahlungen. Debitoren-/Kreditoren-/Bank-/Sach-/Artikel-/Wertposten abgleichen. |
| N07 – R10/R11 | Zwei Starts gleichzeitig/aktiver Job/terminal fehlgeschlagener Initialisierungsjob; aktiven Request schützen, terminalen nicht dauerhaft sperren. Nach Buchung/Umwandlung/fehlenden Live-Ergebnissen weiterhin korrekte Standardlisten öffnen; Live-Anzahl muss nicht gleich bestätigter Einheiten sein. |
| N08 – Unterbrechung/Rechte/Upgrade | Browser schließen, Worker beenden, Rechte für Folgejob entziehen, unbekannte Arbeit prüfen. Kein Autoretry; unbekannter Running-Claim erst nach tatsächlichem Sitzungsende klassifizieren. Alte Captures/Checkpoints weiter lesen; additive Aktualisierung ohne ForceSync; SKR03/SKR04/Existing sowie DE/EN prüfen. |

Fünf neue Methoden im **bestehenden** Testobjekt 90700 (kompiliert, nicht ausgeführt): `IsolatedDocumentPlansKeepLegacyMasterBatches`, `MissingDocumentSourceIsReadOnlySkip`, `CompletedPreflightSkipsHaveNoBusinessEvidence`, `UncertainDocumentIsNotRetriedWhileOthersFinish`, `ExistingFoundationAddsTechnicalSetupIdempotently`. Die beiden Laufnachweise benötigen jeweils den passenden tatsächlich ausgeführten Referenzlauf als aktuellen Firmenlauf. Der Foundationtest benötigt einen vorhandenen verwendbaren finanziellen Ausgangsstand.

## Lokale Prüfergebnisse und Pakete

Tatsächlich ausgeführt am **23.11.2026**:

| Prüfung | Ergebnis / Grenze |
| --- | --- |
| `python3 scripts/build_sf019.py --output /tmp/bcsf-sf050-delivery-final2` | **PASS**: App mit 145 AL-Objekten und getrennte Test-App mit 73 Testmethoden kompiliert. AL-Compiler 18.1.43.24897, vorhandene BC-28.5-DE-Symbole, Cloud/Runtime 17. Enthält die bestehenden Inventory-/Sales-/Purchase-/Template-/Export-/Modular-Quellenvertragsprüfungen einschließlich neuer SF-050-Sicherheitskontrollen. Keine Testmethode ausgeführt. |
| Derselbe Build mit `--analyzers` | **Nicht grün**: CodeCop/UICop mit Warnungen als Fehler melden genau acht bestehende AA0018-Formatbefunde in unverändertem `BCSFItemCatalog.Codeunit.al:173–180`; keine zusätzlichen Fehler im finalen Lauf. Informative Analyzerhinweise sind im Log enthalten. |
| `node scripts/check_dashboard.mjs` | **PASS**: Chromium-Clientregression einschließlich Live-/Bestätigt-Abweichung, getrennten Skip-/Reviewzählern, DE/EN, Drilldown-Bridge, XSS, Polling und Layout. Keine native Standardlisten-/Rechteprüfung. |
| `node scripts/check_dashboard_stock.mjs` | **PASS**: bestehende Bestandsansicht/Bridge und DE-Fallback. |
| `python3 scripts/check_partner_catalog.py` | **PASS**: 28 gesperrte Datenpools, Feldgrenzen und Verteilungs-/Katalogkontrollen; keine native Validierung. |
| `python3 scripts/check_translations.py` | **PASS**: 1.472 Einheiten in fünf deutschen Kulturen und en-US, IDs/Quelltexte/Platzhalter vollständig. |
| `python3 scripts/build_dashboard_translations.py --check` | **PASS**: Dashboardfallback entspricht XLIFF. |
| `python3 scripts/check_package.py …/BCScenarioFactory.app` | **PASS**: Identität/Version, alle 145 aktuellen AL-Quellen, sieben XLIFF-Dateien und vier aktuelle Dashboardassets stimmen mit dem Workspace überein. |
| `git diff --check` | **PASS**: keine Whitespacefehler. |
| Native BC-Test-App, Standardbuchung, Queuefehler, Rechte, Upgrade und Fälle N01–N08 | **Nicht ausgeführt**. Nutzer prüft in seiner BC-Testumgebung; insbesondere gemeldeter BC-29.1-Stand ist lokal nicht als Runtime getestet. |

Die erste strenge Schlussprüfung fand zusätzlich drei AA0202-Namenskonflikte in einer neu ergänzten Hilfsmethode. Diese wurden korrigiert; die finale Normal- und Analyzerkompilierung verwendet den korrigierten Stand. Ein Aufruf des nicht vorhandenen Dateinamens `check_partner_catalog.mjs` scheiterte; anschließend wurde das tatsächlich vorhandene Python-Prüfskript erfolgreich ausgeführt.

Pakete wurden lokal bereitgestellt, **nicht veröffentlicht oder installiert**. Frühere Pakete bleiben erhalten.

- [BCScenarioFactory-1.0.11.0-SF050.app](../../artifacts/BCScenarioFactory-1.0.11.0-SF050.app) — SHA-256 `4f45b2f183834f311978c30d52f512d7e5f36fbd9ef7399187ef674b95951e06`
- [BCScenarioFactory-Tests-1.7.0.0-SF050.app](../../artifacts/BCScenarioFactory-Tests-1.7.0.0-SF050.app) — SHA-256 `076bc8899ff7ab30798af2eebf72461f49cf4388186e98f179d847dd6f4dd4f5`

Nachweise: [App-Build](../../artifacts/BCScenarioFactory-1.0.11.0-SF050-build.log), [Test-App-Build](../../artifacts/BCScenarioFactory-Tests-1.7.0.0-SF050-build.log), [Quellenverträge und Gesamtbuild](../../artifacts/BCScenarioFactory-1.0.11.0-SF050-contracts-build.log), [Analyzer](../../artifacts/BCScenarioFactory-1.0.11.0-SF050-analyzers.log), [Chromium](../../artifacts/BCScenarioFactory-1.0.11.0-SF050-dashboard.log).

**Status: Zur Prüfung.** Dashboard, gemeinsamer Workflow, Stammdatenreferenzen, Einrichtung und DE/EN sind gemeinsam berücksichtigt. Die genannten nativen Prüfungen und menschliche Abnahme bleiben offen. Keine weitere Bearbeitung von SF-051–SF-053.

