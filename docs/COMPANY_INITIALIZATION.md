# Einmalige Mandanteneinrichtung und Vorlagenstart

**Stand:** 19.11.2026, Quellversion 1.0.2.0. **Zur Prüfung.** Der bisherige Finanzdialog pro Vorlage ist entfallen. Eine Einrichtung gehört zu einem Sandbox-Mandanten, nicht zu einer Vorlage.

## Bedienung

1. In einem leeren **BC-SaaS-Sandbox-Mandanten** die Erweiterung normal installieren. Die Installation ändert keine BC-Stammdaten. Das Profil **BC Scenario Factory** ist optional, die Einrichtung ist auch über die BC-Suche erreichbar.
2. **Scenario-Factory-Einrichtung** → **Mandant initialisieren** → **SKR03** oder **SKR04** auswählen. Die dritte Option prüft und übernimmt einen bereits fachlich eingerichteten BC-Mandanten ohne Finanzänderung. Abbrechen lässt die Einrichtung unverändert.
3. Im Dashboard **Szenariovorlagen** öffnen. Zum Einstieg die Vorlage **Allgemeines Unternehmen – Funktionstest: Debitoren und Kreditoren** wählen und **Vorlage ausführen**. Es wird kein Kontenplan- oder Vorschaufenster mehr geöffnet.
4. Die Aktion öffnet die Laufkarte. Dort beziehungsweise im **Laufmonitor** siehst du den wartenden, laufenden oder abgeschlossenen Job und öffnest die erzeugten Datensätze. Die Queue benötigt kein offenes Browserfenster.

Die Initialisierung ist ausdrücklich autorisiert und schaltet die Testdatengenerierung im aktuellen Sandbox-Mandanten frei. Bei einer neuen Firma bleibt die Buchungsfreigabe aus. Autorisierte Nutzer können die Generierung in der Einrichtung später wieder ausschalten. Ein Vorlagenstart schaltet sie nicht heimlich wieder ein.

## Was wo passiert

| Ebene | Verantwortlich für |
| --- | --- |
| Mandant | Wiederverwendbarer Basis-Kontenplan und Finanzberichte, gemeinsame Buchungsgruppen/Matrizen, Hauptbuch-, Verkaufs-, Einkaufs-, Lager- und Marketinggrundkonfiguration, Nummernserien für die vorhandene Partnergeneration und gängige Verkaufs-/Einkaufsbelege, Zahlungsbedingungen, gemeinsame Länder, Einheiten, Hauptlager bei fehlendem Standardlager, Überweisungs-Zahlungsform ohne Bankübermittlung, Herkunftscodes und allgemeines Buchblatt. Vorhandene kompatible Einrichtung wird wiederverwendet. |
| Vorlage | Profil, Typ, Zeitraum, Mengen, Sprache, Seed und fachliche Abweichungen. Bestehende Partnerprofile wählen realistische synthetische Namen, Adressen, Partnerklassen, kindbezogene Liefer-/Bestelladressen und prüfen referenzierte Einrichtung. Die Vorlage legt weder den Kontenrahmen noch allgemeines Setup neu an. |
| Ausführung | Sperrt und erfasst die Vorlage, übernimmt den tatsächlich angewendeten Kontenplan aus dem aktuellen Mandanten, prüft die relevanten Referenzen, erstellt den Plan und reiht die Arbeit ein. Die bisherigen Queue-, Fehler-, Validierungs- und Wiederanlaufregeln bleiben aktiv. |

SKR03/SKR04 bleiben die lokalen deutschen Teilkontenpläne, keine offiziellen DATEV-Vollpakete. Bei bestehender kompatibler Einrichtung werden leere Partnerzuordnungen möglichst aus dem tatsächlich vorhandenen Standard abgeleitet. Wenn keine geeignete Zuordnung existiert oder der Mandant mehrere fachliche Fälle unterscheidet, sind die expliziten Vorlagenfelder unter **Synthetische Partner** maßgeblich. Die Scope-Grenzen bleiben sichtbar. **Nur Debitoren und Kreditoren sind derzeit ausführbare Fachgeneratoren.** Andere Vorlagen sind Planungsbeispiele. Finanzstämme und Belegnummernserien sind eine Grundlage, keine Zusage für Fertigung, Service, Projekte, Partnerbankkonten oder automatische Buchungen.

## Was entfernt wurde

Sieben Seiten sind entfallen. Die Finanzauswahl und -vorschau, der Vorlagenassistent, der zweite Dashboard-Host, der Generatorkatalog als separate Seite und die doppelten Listen für Ausführungen und erfasste Läufe. Zwei dazugehörige PageExtensions und zwei leere Install-/Upgrade-Codeunits wurden ebenfalls entfernt. Im Standardweg bleiben Einrichtung, Vorlagen und ein Laufmonitor. Einstellungen einer Vorlage bleiben in ihrer Karte. Bestehende Diagnosen für Plan, Arbeitspakete, Fehler, Ergebnisse und Wiederaufnahme bleiben kontextbezogen verfügbar.

Die verbliebenen Tabellen haben aktive Aufgaben. Die einzige Schemaänderung ist ein zusätzliches Kennzeichen in der bestehenden **Factory Setup**. Keine Tabellen, Felder, gespeicherten Läufe, zugeschnittenen Vorlagen, Paketidentitäten oder Buchungsdaten werden gelöscht. Ältere, vor dem Wechsel erstellte Snapshots werden nicht neu geschrieben. Für neue Läufe auf einer aktualisierten Firma einmal **Mandant initialisieren** mit dem passenden Kontenplan wählen. Ein bereits angewendetes Paket bleibt identisch. Ein anderer Kontenrahmen erfordert eine neue Sandbox-Firma. Für normale Synchronisierung ist kein ForceSync vorgesehen.

## Bei einem Blocker

Die Aktion zeigt den ersten konkreten Einrichtungs- oder Berechtigungsbefund statt einer zweiten Seite. Bei fehlenden Standardrechten braucht die einrichtende Person Standard-Lese-/Insert-/Modify-Rechte entsprechend der Änderung, einschließlich der nötigen Lizenzrechte für den Mandanten. **BCSF ADMIN** allein erteilt keine Standardtabellenrechte. Bereits konfigurierte, widersprüchliche oder bebuchte Konten werden nicht überschrieben. In diesem Fall passende vorhandene Einrichtung übernehmen oder mit einer unbebuchten, leeren Sandbox-Firma beginnen.

## Sandbox-Abnahme

- Frisch je eine Firma für SKR03 und SKR04. Installation allein darf keinen Kontenplan oder Job anlegen. Auswahl abbrechen und erneut öffnen. Initialisierung ausführen und Kontenplan, Gruppen, Quellen, Nummernserien und Startervorlagen prüfen. Eine Wiederholung darf keine Duplikate erzeugen.
- Vor und nach Initialisierung für einen Vorlagenstart prüfen: vorher ein konkreter Hinweis, nachher kein Finanz- oder Bestätigungsdialog. Zwei Mengen-/Seed-Varianten ausführen und das Fenster während des Jobs schließen. Status, Debitoren-/Kreditorenmengen und Adressen im BC-Standard vergleichen.
- Eine bestehende Firma übernehmen, eine mit inkompatiblem Konto und einen Nutzer mit fehlenden Standardrechten prüfen. Keine teilweise dauerhafte Einspielung. Nach Abschalten der Generierung darf die Vorlage keinen neuen Job erzeugen.
- Eine Kopie des Altstands mit normalen Schema-Synchronisierungseinstellungen aktualisieren. Historischen Lauf und ausstehende Pakete kontrollieren. Kein ForceSync und kein Löschen der alten Firma. SF-038-Standardbuchungen und SF-039-Partnerstichproben bleiben separat zu protokollieren.
