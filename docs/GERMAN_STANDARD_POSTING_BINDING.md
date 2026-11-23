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
