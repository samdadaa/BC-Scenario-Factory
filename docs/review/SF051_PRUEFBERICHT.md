# SF-051 – Teilzahlungen, Raten und offene Posten (Teilumfang)

**23.11.2026 · App 1.0.12.0 · Test-App 1.8.0.0 · Zur Prüfung (Teilumfang).** Ausdrücklich gewähltes Ticket SF-051. Keine Commits, kein Deployment.

## Ausgangslage
`BCSF Payment Processor.Pay` buchte je gebuchter Rechnung genau eine Vollzahlung. Teilzahlungen, Restposten und unterschiedliche Zahlungstermine fehlten (Quellcode und `docs/INDUSTRY_INITIALIZATION.md`).

## Umsetzung (nur Finance/Payment Processor 90401)
- Neuer additiver Marker `paymentSetup.planVersion = 1` bei neuen Captures; fehlt er, bleibt exakt die bisherige Vollzahlung. Unbekannte Version stoppt (`Check`, `PlanAmounts`).
- `PlanAmounts` (seed-deterministisch, lauf-ID-unabhängig): 1–55 voll, 56–75 zwei Raten (30–70 % + Rest), 76–90 eine Teilzahlung mit offenem Rest, 91–100 bewusst offen. Zu kleine Rechnungen (<2 Rundungseinheiten je Teil) werden voll bezahlt. Vorzeichen für Debitoren/Kreditoren erhalten.
- Zweite Rate: `PaymentDateSecond` zwischen erstem Zahlungsdatum und Periodenende.
- Jede Rate über Standard `Gen. Jnl.-Post Line.RunWithCheck` mit temporärer Zeile, Commit-Unterdrückung und `Applies-to`; danach exakte Restbetragsprüfung (`CheckRemaining`). Herkunft `PAYMENT` / `PAYMENT-2`.
- `ValidatePayment` rekonstruiert den Plan aus Snapshot und Original-Betrag; offene Posten sind bei Plan 2/3 Soll, nicht Fehler.

## Nicht umgesetzt
Zahlungsrabatt, Zahlungstoleranz, Gutschriften/Retouren (SF-052), Sammelausgleich, Partnerbankstämme (SF-039), nutzerwählbare Modus-Quoten, Starter-/Dashboard-Sonderkacheln. Neue Captures der Zahlungsstufe (auch Starter) verwenden den Plan automatisch; ältere Captures/Läufe bleiben unverändert. Keine neuen UI-Texte, daher keine Übersetzungsänderung.

## Echte Prüfungen
- **Nicht ausgeführt:** AL-Kompilierung (installierter Compiler 18.1.x verlangt .NET 10, vorhanden nur 8.0.8), Analyzer, AL-Tests, native Sandbox. Der Code wurde nur manuell geprüft.
- `scripts/check_translations.py` scheitert unverändert auch ohne diese Änderung (`.g.xlf` veraltet; vor Änderung bestätigt).
- Neue Tests (nicht ausgeführt): `PaymentPlanIsDeterministicExactAndLegacySafe`, `UnknownPaymentPlanVersionIsRejected`.

## Native Prüffälle (Nutzer)
P01 Kleiner Zahlungslauf SKR03: Rechnungen mit allen vier Planarten; offene/teilbezahlte Debitoren-/Kreditorenposten und Restbeträge stimmen. P02 Existing-Firma (GIROKONTO/1810). P03 Zahlungstoleranz/-rabatt in Einrichtung aktiv: erwartet gesperrter Vorgang (NeedsReview), keine stille Anpassung, kein Commit-Fehler. P04 Wiederanlauf/Doppelstart ohne Doppelzahlung. P05 Rechte (nur Factory-Rolle). P06 Dashboard-Drilldowns Zahlungen/Posten, DE/EN. P07 Upgrade: alte Läufe unverändert.

Offene Risiken: BC-Standard-Teilanwendung mit Zahlungsrabattfenster; Rundung bei Mehrwertsteuerbeträgen; zweite Zahlung mit gleicher Belegnummer wie die erste.
