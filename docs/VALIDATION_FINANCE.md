# SF-016 / SF-017 – Umsetzung und Prüfvertrag

**Aktueller Stand ab 1.0.2.0:** Der reale Bedienweg ist in [Mandanteneinrichtung und Vorlagenstart](COMPANY_INITIALIZATION.md) beschrieben. Ältere Angaben zu Finanzauswahl je Vorlage, Vorschaufenster, Wizard, parallelen Lauflisten und Dashboard-Host sind historische Nachweise. Entfernte Objekt-IDs bleiben unbenutzt.

## Arbeitsplan vom 18.11.2026

Beide Tickets sind ausdrücklich gemeinsam beauftragt. Ausgangsbestand: 116 AL-Dateien; bereits vorhandene, noch nicht dokumentierte Ansätze für Qualitätsabschluss und Finanzpakete. Keine Bestandsobjekte ersetzen oder verschieben, keine Folgetickets implementieren.

Ziel SF-016: unveränderliche, firmengebundene Pflicht-/Warnbefunde, Abschluss nur mit vollständiger Batchprüfung; vorhandenen Generator-ValidateOutput-Vertrag wiederverwenden und registrierte Rechnungen/Gutschriften mit ihren wirklichen Partner- und Sachposten verknüpfen. Betroffen: Validation Manager/Result, Run Quality/Execution Rules, Monitoring.

Ziel SF-017: vorhandene Paketvorschau und explizite Sandbox-Anwendung absichern, Paketidentität schützen, Finanzmodus vollständig in der Szenariobedienung zugänglich machen. Betroffen: Finance Package Mgt/Table/Pages, Scenario Policy/Wizard, Permission Set, Übersetzungen und Objektdokumentation. Bestehende BC-Einrichtung bleibt lesend; kein Standardposteninsert.

Risiken: fremde Subscriber und implizite Commits, effektive Standardrechte/Security-Filter, parallele Setupänderungen, BC-28.0- gegenüber lokalen 28.5-Symbolen. Keine Rechteerhöhung auf Standardtabellen. Paket ist ein begrenzter Inland-19%-Testkontenplan, kein vollständiger DATEV-Rahmen; weitere Steuer-/Prozessfälle bleiben außerhalb des Umfangs. Reale Testfirma, Sandbox-Version und fachliche Abnahme sind **Zu prüfen**.

Testweg: vollständiger lokaler Cloud-Build mit CodeCop/UICop, XLIFF-Abdeckung, Dashboardregression, Objekt-/ID-/Pfad- und Diffprüfung. Sandboxfälle für Pflichtfehler, Warnungen, Paketkonflikte, Wiederholung und drei Standardbuchungen je Kontenrahmen mit erwarteten Berichtssummen dokumentieren. Keine neuen AL-Testobjekte, kein Deployment ohne Auftrag.

## SF-016 – realer Datenfluss

Der letzte erfolgreiche Batch bzw. die Wiederaufnahme vollständig bestätigter Arbeit ruft `BCSF Run Quality.FinalizeRun` auf. Pflichtprüfung `REQUIRED-OUTPUT` je Batch: Completed-Zustand, exakte Mengen-/Schlüsselabdeckung, gespeicherter Checkpoint samt Zählern/Versionen/Sprache, aktuelle SystemId-Existenz und erneut `Generator.ValidateOutput`. Elternartefakte müssen im selben Run bestehen. Keine neue Generatorbindung oder Ausführung von `Resume`.

Für registrierte Verkaufs-/Einkaufsrechnungen und Gutschriften wird zusätzlich der tatsächliche Partnerposten über die Standard-Kopfverknüpfung geprüft: Belegnummer/-art, Partner, Buchungsdatum und ursprünglicher Betrag in Belegwährung. Sämtliche Sachposten mit derselben Transaktionsnummer/Belegnummer/-art/Datum müssen als dieselbe logische Einheit registriert sein und in Mandantenwährung auf null saldieren. Ein bloß vorhandener fremder Posten reicht nicht. Andere Prozessarten und modulspezifische Relationen bleiben Aufgabe des jeweiligen `ValidateOutput`; dies ist kein universeller Nachweis für alle zukünftigen Zahlungs-/Lagerprozesse.

Optionale lesende Subscriber an `OnCheckOptionalOutput` liefern höchstens 20 eindeutige technische `WARN-*`-Codes. Ein Fehler im optionalen Vertrag wird `OPTIONAL-CHECK-FAILED`, niemals ein bestandener Pflichtcheck. Pflichtfehler → `ValidationFailed`; ausschließlich Warnungen → `CompletedWithWarnings`; vollständige bestandene Pflichtprüfungen ohne Warnungen → `Completed`. Ohne Summary zeigt Monitoring „Nicht validiert“. Die Ergebnisliste kennzeichnet Pflichtprüfungen ausdrücklich.

Ergebnisse sind append-only: vier verpflichtende Datenbanksubscriber schützen auch Trigger-false-/RecordRef-Pfade. Sandbox/Firma und Run werden geprüft, der Elternkopf wird gesperrt. BackgroundProcessing prüft per Pflichtsubscriber Batchbindung, erlaubten Ausführungszustand, Soll-/Istzählwerte und Summaryvollständigkeit/-severity. Ein als bestanden angehängter Pflichtbefund wird erneut gegen den aktuellen Output geprüft. `BCSF ADMIN` erhält weiterhin nur Ri auf Befunde; direkte Insert-Rechte hat nur der feste Validation Manager. Keine neuen Standardrechte. Die lesenden TryFunctions sind keine Rollbackgrenze; Subscriber müssen lesend bleiben. Abschlussbefunde, Ausführungsstatus und letzter Batch teilen die vorhandene commitfreie Transaktion.

## SF-017 – Pakete und Bedienung

Setup → „Finanzeinrichtung prüfen“ → vorhandene Einrichtung / SKR03 / SKR04 auswählen → Vorschau. Nur „Testpaket anwenden“ mit Bestätigung wendet ein Paket an. Im Szenario und im Wizard-Schritt 4 denselben Finanzmodus auswählen. Die Firma wird zuvor mit BC-Standardmitteln angelegt und grundlegend eingerichtet; die App legt keine Firma an. SF-009 bleibt lesend.

Pakete `SKR03 / 2026 / 1.0.0` und `SKR04 / 2026 / 1.0.0` verwenden dieselben fachlichen Rollen und Berichtsgruppen. Grundlage: [DATEV-Standardkontenrahmen 2026, Hilfe-Dokument 0907817](https://www.datev.de/web/de/berufsgruppenuebergreifend/service-und-support/wichtige-informationen-zum-jahreswechsel/jahreswechsel-rechnungswesen/anpassungen-in-den-programmen/DATEV-Kontenrahmen), [SKR03 Art. 11174](https://www.datev.de/web/de/shop/produkt-details/kontenrahmen-datev-skr-03-11174), [SKR04 Art. 11175](https://www.datev.de/web/de/shop/produkt-details/kontenrahmen-datev-skr-04-11175), Bezugsstand Januar 2026. Eigenständige schlanke Testauswahl mit BC-spezifischen Interimskonten und eigener Berichtsanordnung; kein vollständiger DATEV-Kontenrahmen, DATEV-Export oder gesetzlicher Abschluss. Fachliche Abnahme der Kontenzuordnung und Werte ist **Zu prüfen**.

| Rolle | SKR03 | SKR04 | BC-Kategorie |
| --- | --- | --- | --- |
| BANK | 1200 | 1800 | Assets |
| AR | 1400 | 1200 | Assets |
| AP | 1600 | 3300 | Liabilities |
| STOCK | 3980 | 1140 | Assets |
| INPUTVAT | 1576 | 1406 | Assets |
| OUTPUTVAT | 1776 | 3806 | Liabilities |
| EQUITY | 0800 | 2900 | Equity |
| SALES | 8400 | 4400 | Income |
| PURCHASES | 3400 | 5400 | Cost of Goods Sold |
| COST | 3960 | 5880 | Cost of Goods Sold |
| EXPENSE | 4900 | 6300 | Expense |
| OFFICE | 4930 | 6815 | Expense |
| INTERIMSTOCK | BCSF-INT | BCSF-INT | Assets |
| ACCRUAL | BCSF-ACCR | BCSF-ACCR | Liabilities |

Kontonummern sind Code[20], `0800` bleibt erhalten. BANK/EQUITY/EXPENSE/OFFICE erlauben direkte Standardbuchblattbuchungen; andere Rollen sind für indirekte Standardbuchungswege vorgesehen. Bilanz-/GuV-Zuordnung erfolgt über Account Category und Income/Balance. Namen werden in der Sitzungssprache angelegt und beim erneuten Anwenden nicht umbenannt.

`BCSF03` bzw. `BCSF04` ist der gemeinsame Code für Debitoren-, Kreditoren-, Lager-, allgemeine und MwSt.-Buchungsgruppen. Matrizen enthalten Inland-Normal-MwSt. 19 %, Erlös-/Einkaufs-/Wareneinsatz-/Rabatt-/Interimskonten sowie eine allgemeine Kombination mit leerer Geschäftsgruppe für reine Lagerkorrekturen. Lagerbuchungseinrichtung für leeren Lagerort und bei Lagerortpflicht vorhandene Nicht-Transit-Lagerorte. Spätere Generatoren beziehen den Gruppencode über `GetTestPostingGroup` und verwenden keine SKR-Kontonummern.

Standard-Finanzberichte: `SF03-BS`/`SF04-BS` mit Stichtagsbestand und `SF03-PL`/`SF04-PL` mit Periodenbewegung, eigene Zeilen-/Spaltendefinitionen. Bilanz enthält Aktiva, Verbindlichkeiten, Steuer, Eigenkapital und laufendes Ergebnis. GuV enthält Erlöse, Wareneinsatz, Betriebskosten und Ergebnis. **Soll positiv, Haben negativ**, auch in Summen-/Formelzeilen. Kontenlisten statt Nummernbereiche verhindern das unbemerkte Einbeziehen fremder Konten. Zusätzliche Zeilen/Spalten in den Paketdefinitionen blockieren Wiederverwendung.

Voraussetzungen: Standard-Finanz-/Verkaufs-/Einkaufs-/Lagereinrichtung, verwendbare Nummernserien zum Arbeitsdatum, Zahlungsbedingungen, allgemeine Buchblattvorlage und ggf. Lagerort. Rechnungsrundung wird im Testpaket nicht unterstützt und muss deaktiviert sein. Keine stillen Änderungen dieser Einrichtungen. Fehlendes wird konkret in der Vorschau gemeldet; keine automatische Nummernserien-/Zahlungsbedingungenanlage. Weitere Steuersätze, Ausland, Skonto, Währungen und komplexe Warehouseprozesse sind nicht Bestandteil des Paketvertrags.

Apply prüft die Sandbox/Firma erneut, sperrt den Paketvermerk und prüft jeden Wiederverwendungsdatensatz unter Schreibsperre erneut auf relevante Konfliktfelder. Es legt ausschließlich fehlende Datensätze an; keine Modify-/Delete-/Rename-Operationen auf Standarddaten. Jede Konfliktausnahme bricht die commitfreie Gesamttransaktion ab. Ein Paketwechsel ist blockiert. Initiale Anwendung bei vorhandenen Sachposten ist blockiert; bei bereits erfasstem identischem Paket ist nach Buchungen nur vollständige Wiederverwendung erlaubt, keine Reparatur durch Neuanlage. Der Paketvermerk ist erst nach vollständiger Einrichtung einfügbar und danach unveränderlich, über vier verpflichtende DB-Subscriber geschützt. Keine erhöhten Standardtabellenrechte.

Snapshots Schema 1 halten optional `financeMode`, `financeYear`, `financeVersion`; Existing verwendet Jahr 0 und leere Version. Altsnapshots ohne Finanzfelder bleiben lesbar. Der Vorprüfungs-Subscriber vergleicht erfasste Paketidentität und aktuelle Einrichtung, fehlende Datensätze bleiben Startblocker. Nachträgliche Vorlagenänderung verändert keine historischen Snapshots.

## BC-Abnahme – noch nicht ausgeführt

Für **jede** Variante getrennte frische Sandbox-Testfirma mit Standardgrundsetup, EUR, Datum im selben offenen Geschäftsjahr, ohne andere Buchungen. Beide Pakete vor Buchungen zweimal anwenden: identische Anzahl/Konten/Gruppen/Berichte. Existing-Modus vor/nach auf unveränderte Standarddaten und Nummernserienzähler prüfen. Inkonsistentes Konto/Matrix/Berichtszeile, fehlende Rechte, Security-Filter, Produktion/falsche Firma und parallele Änderungen müssen ohne Teilpaket abbrechen. Nach vollständiger Anwendung mit Sachposten muss Wiederverwendung gelingen, fehlende Paketdaten müssen blockieren.

Konkretes **erwartetes Beispiel**, keine beobachteten Buchungen:

1. Allgemeines Standardbuchblatt: Bank +1.000, Eigenkapital −1.000 als Anfangsausstattung; dazu unabhängig von Einkauf/Verkauf Bürobedarf +20, Bank −20, ohne MwSt.-Buchungsart. Keine Rabatte, Rundung oder Fremdwährung.
2. Standardartikel mit Paketgruppen: Einkaufsrechnung 10 Stück zu 10 netto, 19 % MwSt. Erwartet Bestand +100, Vorsteuer +19, Verbindlichkeit −119 nach Lagerkostenbuchung; Einkaufs-/Direktkostenverrechnung saldiert auf null.
3. Verkaufsrechnung 5 Stück zu 30 netto, 19 % MwSt. Erwartet Forderung +178,50, Erlös −150, Umsatzsteuer −28,50; Wareneinsatz +50 und Bestand −50 nach Standardkostenregulierung/-buchung. Nötigenfalls BC-Standard „Lagerregulierung fakt. Einstandspreise“ und „Lagerregulierung buchen“ ausführen; Paket ändert deren Einstellungen nicht.
4. Alle Sachposten/Kostenregulierung mit den Paketrollen abgleichen; Berichtdatum auf diese Buchungen setzen. Bilanz und GuV müssen folgende Werte aus tatsächlichen Posten liefern. Bericht ohne Buchungsdaten genügt nicht.

| Berichtszeile | Erwarteter Betrag EUR |
| --- | ---: |
| Bilanz BANK | 980,00 |
| Bilanz AR | 178,50 |
| Bilanz STOCK einschließlich Interim | 50,00 |
| Bilanz INVAT | 19,00 |
| Bilanz ASSETS | 1.227,50 |
| Bilanz AP einschließlich Abgrenzung | −119,00 |
| Bilanz OUTVAT | −28,50 |
| Bilanz EQUITY | −1.000,00 |
| Bilanz RESULT | −80,00 |
| Bilanz TOTAL | −1.227,50 |
| GuV SALES | −150,00 |
| GuV COGS | 50,00 |
| GuV OPEX | 20,00 |
| GuV RESULT | −80,00 |

Weitere SF-016-Fälle: tatsächlicher vollständiger Output → Completed; fehlende/gelöschte Identität, falscher Partnerposten/Betrag/Transaktion, unvollständige Sachpostenregistrierung, ungültiger Elternbezug oder Generatorbefund → ValidationFailed; nur WARN-* → CompletedWithWarnings; fehlerhafter optionaler Subscriber → sichtbare Warnung; ohne alle Pflichtbefunde kein Summary/Completed. Trigger-false-Änderung/Löschung von Befunden und Paketvermerk wird abgewiesen. Legacy ohne Checkpoint bleibt blockiert. Effektive Rechte und parallele Sitzungen separat prüfen. Aktuell fehlen echte Fachgeneratoren; für Queue-End-to-End ist deren spätere Implementierung erforderlich, keine Vertragsprobe in echte Pläne einschleusen.


## SF-038 – Nachfolgevertrag

Für Neuinstallation gilt Paket 2.0.0: 15 Buchungskonten plus 3 Summenkonten, INLAND03/04, Bankbuchungsgruppe, Standard-Sachkontenzeilen und bestätigte Foundation-Ergänzung. Die obigen 1.0.0-Angaben bleiben historische Dokumentation. Keine automatische Migration; reale Standardbuchungen weiter offen. [Aktuelle Rollen, Grenzen und Altbestand](STABILIZATION_FINANCE_PARTNERS.md#paketumfang-200--bezugsjahr-2026).
