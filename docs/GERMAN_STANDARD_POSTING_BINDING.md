# BC-Standardmandant (DE): feste Buchungsgruppen für Factory-Großhandel

Stand: 23.11.2026. Gilt ausschließlich für den aktuellen Initialisierungsmodus „vorhandene gültige BC-Einrichtung verwenden“ mit den bestätigten deutschen BC-Standardcodes. **Keine** automatische Zuordnung individueller Kundeneinrichtungen.

- Debitorenbuchungsgruppe `INLAND` → Debitorensammelkonto `1202`.
- Kreditorenbuchungsgruppe `INLAND` → Kreditorensammelkonto `3301`.
- Geschäftsbuchungsgruppe und MwSt.-Geschäftsbuchungsgruppe: `INLAND`.
- Artikel-Produktbuchungsgruppe `HANDEL`, Artikel-MwSt.-Produktbuchungsgruppe `VAT19` (reguläre deutsche Handelsware, 19 %).
- `INLAND/HANDEL` und `INLAND/VAT19` müssen gültige Buchungsmatrizen mit verwendbaren Konten enthalten; `INLAND/VAT19` muss Normal-MwSt. 19 % sein.
- Bei Initialisierung wird **ausschließlich** bei den bestätigten Sammelkonten `1202` und `3301` `Direktbuchung = Nein` gesetzt, und nur wenn `INLAND` tatsächlich darauf verweist. Die Vorschau zeigt die Änderung; vorhandene sonstige Kontierungen bleiben unverändert.
- Erneute Initialisierung ist hinsichtlich dieser Kontenänderung idempotent. Es erfolgt keine alphabetische Fallback-Suche nach `AUSLAND`, `EU`, `OHNE MWST` usw. Bei fehlender oder abweichender Standardzuordnung wird verständlich abgebrochen.
- Bereits generierte Stammdaten werden **nicht** nachträglich geändert. Neues Szenario nach erfolgreicher Initialisierung starten.

Ausstehend: Individuelle Fremdmandanten mit anderen Kontenplänen/Buchungsgruppen bleiben als separate spätere Erweiterung offen. Es wurde kein nativer BC-/AL-Buildtest durchgeführt.

## Zahlungsfolgeprozess (23.11.2026)

Nur für `Existing` mit bestätigter deutscher BC-Standardeinrichtung: Der synthetische interne Bankdatensatz `BCSF-PAY` verwendet die **vorhandene** Bankkontobuchungsgruppe `GIROKONTO` mit Sachkonto `1810`. Das Sachkonto bleibt `Direktbuchung = Nein`; der Zahlungsprozess bucht ausschließlich über die BC-Standardbuchungsroutine. Für den unveränderlichen Zahlungssnapshot wird die vorhandene allgemeine Buchblattvorlage `ALLGEMEIN` mit Buchblattname `STANDARD` verwendet. Kein alphabetischer oder mehrdeutiger Gruppen-/Buchblatt-Fallback. Fehlende oder abweichende finanzielle Zuordnungen werden nicht überschrieben, sondern melden einen Fehler. Es erfolgt keine Bankübertragung. SKR03/SKR04 sowie alle Modi ohne Zahlung/Ausgleich sind von dieser punktuellen Anpassung nicht betroffen.

Abnahme in der BC-Sandbox ausstehend: neuer Existing-Lauf im Zahlungs-/Ausgleichsmodus einschließlich Debitoren- und Kreditorenzahlungen, offenen/ausgeglichenen Posten, anschließend Regressionen für SKR03, SKR04 und Existing ohne Zahlungen.
