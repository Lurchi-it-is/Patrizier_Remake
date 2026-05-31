# Projektplan: Hanseatische Warenwirtschaftssimulation

Version: 0.2.0-foundation  
Datum: 2026-05-31  
Repo: https://github.com/Lurchi-it-is/Patrizier_Remake.git

## Management Summary

Ziel ist eine eigenstaendige PC-Warenwirtschaftssimulation im Hanse-Setting des 13. bis 15. Jahrhunderts. Das Spiel soll die Faszination klassischer Handels- und Aufbausimulationen aufnehmen: Schiffe kaufen, Waren zwischen Staedten handeln, Produktionsketten aufbauen, Konvois automatisieren, politischen Einfluss gewinnen und mit Piraten, Krisen und Konkurrenz umgehen. Seeschlachten und Piraterie sind dabei ein Kernfeature, nicht nur ein spaeter Zufallsfaktor.

Wichtig ist die klare Abgrenzung zu bestehenden Marken wie `Patrician` / `Patrizier`: Setting, historische Hanse und Wirtschaftssimulation sind nutzbar, konkrete Namen, UI, Assets, Texte, Missionen und exakte Regelwerke duerfen nicht kopiert werden. Das Projekt sollte daher unter einem eigenen Arbeitstitel und mit eigenem Design auftreten.

Empfohlener Ansatz: erst ein enges, spielbares MVP bauen, nicht direkt die komplette historische Welt. Das MVP sollte 8 bis 12 Staedte, 8 bis 12 Waren, einfache Schiffe, dynamische Preise, manuelle Handelsfahrten, Lagerhaeuser, erste automatische Handelsrouten und einen ersten Piraten-/Seeschlacht-Prototyp enthalten. Danach werden Produktion, Stadtentwicklung, Politik, Piratenfraktionen, Ereignisse, Balancing und moderne Grafik ausgebaut.

Technisch ist fuer ein kleines bis mittleres Team Godot 4.x eine gute Standardempfehlung: freie MIT-Lizenz, gute 2D/2.5D-Faehigkeiten, schnelle Iteration und niedrige laufende Kosten. Unity bleibt eine valide Alternative mit groesserem Asset- und Hiring-Oekosystem; Unreal ist fuer diese Art datenlastiger Wirtschaftsstrategie nur dann sinnvoll, wenn fotorealistische 3D-Praesentation im Vordergrund steht.

## Recherche-Ergebnisse

### Historischer Rahmen

- Die Hanse war ein Netzwerk norddeutscher und nordeuropaeischer Handelsstaedte, besonders aktiv im Nord- und Ostseeraum. Der Schwerpunkt lag im Spaetmittelalter, vor allem zwischen dem 13. und 15. Jahrhundert.
- Luebeck war ein zentraler Knoten. Bedeutende Handelsraeume und Kontore lagen unter anderem in Bergen, London, Bruegge und Nowgorod.
- Geeignete Spielwaren sind Getreide, Salz, Fisch bzw. Stockfisch, Hering, Holz, Eisen, Felle, Wachs, Tuch, Bier, Wein, Fleisch, Wolle, Flachs und Gewuerze.
- Historische Spielstaedte fuer einen ersten Umfang: Luebeck, Hamburg, Bremen, Rostock, Wismar, Stralsund, Stettin, Danzig, Koenigsberg, Riga, Reval/Tallinn, Visby, Stockholm, Bergen, Oslo/Toensberg, London, Bruegge, Nowgorod.
- Piraterie passt historisch stark in das Setting. Die Vitalienbrueder/Victual Brothers begannen als Kaperfahrer und wurden im spaeten 14. Jahrhundert zu einer grossen Bedrohung fuer den Ostseehandel.
- Die Kogge war ein zentrales Hanse-Schiff fuer Handel und konnte bei Bedrohung auch militaerisch genutzt werden. Mittelalterliche Seekaempfe sollten frueh eher Entern, Besatzung, Moral und Beute betonen als spaetneuzeitliche Breitseiten-Schlachten.

### Spielerische Referenz

- Der Kern erfolgreicher Hanse-Handelsspiele ist nicht nur Kaufen und Verkaufen, sondern ein Gesamtsystem aus Angebot, Nachfrage, Stadtwachstum, Produktion, Lagerhaltung, Konvois, Politik, Risiko und Konkurrenz.
- Automatische Handelsrouten sind ein Schluesselfeature. Ohne sie wird das Spiel spaeter zu kleinteilig; mit ihnen entsteht der Aufbaucharakter eines Handelsimperiums.
- Ein typisches Langzeitproblem des Genres ist, dass optimale Routen irgendwann geloest sind. Das neue Spiel sollte deshalb variable Nachfrage, Ereignisse, saisonale Effekte, politische Stoerungen, Konkurrenzverhalten und Stadtentwicklung frueh mitdenken.

### Technische Recherche

- Godot ist unter MIT-Lizenz verfuegbar und damit fuer kommerzielle Spiele ohne Runtime-Fee oder Umsatzbeteiligung attraktiv.
- Unity hat die Runtime Fee offiziell gestrichen, bleibt aber ein abonnement- und paketbasiertes Oekosystem.
- Unreal verlangt fuer Spiele typischerweise erst ab hoeherem Umsatz eine Royalty, ist aber fuer datengetriebene 2D/2.5D-Strategie schwergewichtiger.
- Steam Direct verlangt aktuell eine App-Gebuehr von 100 USD je Spiel-App. Das ist fuer die spaetere Releaseplanung einzuplanen.

## Produktvision

Ein ruhiges, tiefes Handels- und Aufbauspiel, in dem der Spieler als Kaufmann in einer Hanse-Stadt startet und ueber Handel, Produktion, Lagerlogistik, Beziehungen und Stadtpolitik zum einflussreichsten Handelsfuersten des Nordens aufsteigt.

Designprinzipien:

- Systemtiefe vor Missionsskripten.
- Datengetriebene Simulation statt harter Sonderregeln.
- Lesbare moderne UI statt nostalgischer Nachbildung.
- Historische Plausibilitaet vor vollstaendiger Simulation.
- Seeschlachten muessen wirtschaftlich relevant sein: Fracht, Versicherung, Eskorte, Ruf und Versorgungssicherheit haengen direkt daran.
- Jede grosse Komfortfunktion muss die strategische Entscheidung erhalten, nicht ersetzen.

## Zielplattform und Technik

Empfohlener Start:

- Engine: Godot 4.x
- Sprache: GDScript fuer UI/Gameplay, optional C# fuer komplexe Simulationsteile
- Zielplattform: Windows zuerst, Linux optional, macOS spaeter
- Grafikstil: 2.5D-Karte mit stilisierten 3D/Render-Assets oder hochwertiger 2D-Illustration
- Datenformat: JSON, TOML oder Godot Resources fuer Staedte, Waren, Schiffe, Gebaeude, Ereignisse
- Savegames: versionierte JSON/binaere Saves mit Migrationen
- Tests: Simulation als engine-armer Kern testbar halten

Alternative:

- Unity, falls C#-Workflow, groesserer Asset Store oder spaetere Mobile/Console-Pipeline wichtiger sind.
- Unreal nur bei starker 3D-Fokussierung und ausreichender Erfahrung im Team.

## Kernsysteme

### 1. Weltkarte

- Nord- und Ostsee als navigierbare Karte
- Staedte als Handelsplaetze mit Hafenstatus, Einwohnern, Produktion, Verbrauch und politischer Lage
- Seerouten mit Distanz, Risiko, Wetterzonen und Reisezeit
- Tagesbasierter Simulations-Tick

### 2. Waren und Preise

- Jede Stadt hat Bestand, Verbrauch, Produktion, Zielreserve und Preisspanne pro Ware
- Preise entstehen aus Reichweite in Tagen: niedriger Bestand erhoeht Preise, Ueberfluss senkt Preise
- Warenklassen: Grundbedarf, Bauwaren, Luxuswaren, Produktionsinput
- Spaeter: Verderblichkeit, Saison, Embargos, Krisen

### 3. Schiffe und Konvois

- Schiffstypen mit Frachtraum, Geschwindigkeit, Tiefgang, Besatzung, Kampfwert und Unterhaltskosten
- Konvois als spaetere Verwaltungseinheit
- Kapitaene mit einfachen Boni
- Reparatur, Ausbau, Bewaffnung, Versicherungs-/Risikosystem spaeter

### 4. Handel und Lager

- Manueller Kauf/Verkauf im Stadtmarkt
- Kontor/Lagerhaus pro Stadt
- Lagerkosten und lokale Verwalter
- Automatische Handelsrouten mit Preislimits, Mindestbestaenden und Lade-/Entladeregeln

### 5. Produktion und Stadtentwicklung

- Betriebe produzieren Waren und verbrauchen Inputs, Arbeit und Geld
- Staedte wachsen, wenn Grundversorgung, Arbeit und Wohnraum stabil sind
- Stadtwohlstand beeinflusst Nachfrage, Steuern, politische Stimmung und Bauauftraege

### 6. Konkurrenz und KI

- KI-Haendler handeln nach einfachen Gewinn- und Versorgungszielen
- Konkurrenz kann Preise bewegen, Chancen blockieren und Routen stoeren
- Spaeter: Familien, Handelsgesellschaften, Sabotage, Bieterwettbewerbe

### 7. Politik und Karriere

- Ruf in jeder Stadt, Gesamtprestige, Vermoegen und Versorgungserfolge
- Raenge vom einfachen Kaufmann bis zum Ratsmitglied/Buergermeister/Aeltesten
- Stadtauftraege, Bauprojekte, Ratsentscheidungen, Privilegien

### 8. Seeschlachten und Piraterie

Seeschlachten und Piraten sind ein Kernsystem. Sie sollen nicht nur als zufaellige Verlustmeldung erscheinen, sondern als spielbare Risiko- und Machtprojektion auf der Handelskarte.

Kernziele:

- Handelsrouten brauchen Sicherheitsentscheidungen: schnell und billig fahren, bewaffnen, Konvoi bilden, Eskorte kaufen oder Risiko meiden.
- Piraten greifen nicht beliebig an, sondern bevorzugen wertvolle, schlecht geschuetzte oder bekannte Handelsrouten.
- Der Spieler kann defensiv handeln, Piraten jagen, Praemien verdienen, Geleitschutz anbieten oder spaeter selbst Kaper-/Schmuggelmechaniken nutzen.
- Kampfentscheidungen muessen kurz bleiben, damit die Wirtschaftssimulation nicht staendig unterbrochen wird.

MVP-Umfang:

- Piratenrisiko pro Seezone und Route
- automatische Begegnungspruefung bei Reisen
- einfacher Auto-Resolver mit Schiffswerten, Besatzung, Bewaffnung, Moral, Wetter und Frachtwert
- optionaler taktischer Mini-Kampf fuer wichtige Begegnungen
- Ergebnisse: Flucht, Beschaedigung, Frachtverlust, Schiffseroberung, Gefangene, Rufverlust oder Kopfgeld

Ausbau:

- Piratenverstecke und regionale Piratenanfuhrer
- Eskorten- und Konvoisystem
- manuelle taktische Seeschlachten mit Wind, Positionierung, Entern, Fernwaffen und Moral
- Stadtauftraege zur Piratenjagd
- politische Folgen von Kaperfahrt, Schmuggel und Angriffen unter falscher Flagge
- Versicherungen, Schutzbriefe, Hafensperren und Geleitvertraege

### 9. Risiken und Ereignisse

- Piraten, Stuerme, Eis, Seuchen, Kriege, Blockaden, Ernteausfaelle
- Ereignisse muessen wirtschaftliche Antworten erzeugen, nicht nur zufaellige Strafen
- Fruehe Version: einfache regionale Modifikatoren, Piratenbegegnungen und Seeschlacht-Auto-Resolver

## MVP-Scope

Das erste spielbare MVP soll beweisen, dass die Wirtschaftsschleife funktioniert.

Enthalten:

- 8 bis 12 Staedte
- 8 bis 12 Waren
- 3 Schiffstypen
- manuelles Handeln
- einfache Preisbildung ueber Angebot/Nachfrage
- Warenproduktion und Verbrauch pro Tag
- Spieler-Konto, Schiff, Laderaum, Lagerhaus
- Karte mit Reisezeiten
- erstes UI fuer Markt, Schiff, Stadt, Kontor und Handelsroute
- Piratenrisiko auf Seerouten
- einfacher Seeschlacht-Auto-Resolver
- Speichern/Laden
- einfache automatische Route

Nicht im MVP:

- vollstaendige Politik
- komplexe Piratenfraktionen
- vollstaendige manuelle Seeschlacht-KI
- Multiplayer
- modifizierbare Steam-Workshop-Struktur
- vollstaendige historische Karte
- fortgeschrittene 3D-Hafenszenen

## Meilensteinplan

### Phase 0: Projektfundament, 1 bis 2 Wochen

- Remote `origin` auf das festgelegte GitHub-Repo setzen
- Branch-/Worktree-Regeln pruefen
- Engine-Projekt anlegen
- Versionierung, Changelog, CI-Grundlage
- Datenmodell fuer Waren, Staedte, Schiffe definieren
- Coding- und Asset-Konventionen dokumentieren

Ergebnis: lauffaehiges leeres Projekt mit Versionsnummer und Datenstruktur.

### Phase 1: Vertikaler Prototyp, 4 bis 6 Wochen

- 3 Staedte, 5 Waren, 1 Schiff
- Karte, Reise, Kauf/Verkauf, dynamische Preise
- Tages-Tick und einfache Stadtproduktion
- Piratenbegegnung als text-/ui-basierter Auto-Resolver
- Minimal-UI
- erstes Savegame

Ergebnis: Spieler kann Profit durch Handel zwischen Staedten erzielen.

### Phase 2: Wirtschafts-MVP, 6 bis 8 Wochen

- 8 bis 12 Staedte, 8 bis 12 Waren
- Kontore/Lager
- erste automatische Handelsroute
- einfache Produktionsbetriebe
- Piratenrisiko pro Seezone und erste Eskorte/Bewaffnung
- Grundbalancing und Debug-Ledger

Ergebnis: tragende Wirtschaftsschleife ist spielbar und messbar.

### Phase 3: Aufbau und Skalierung, 8 bis 10 Wochen

- mehrere Schiffe und Konvois
- Kapitaene und Unterhalt
- Konvoi-Sicherheit, Fluchtchance und Kampfbereitschaft
- Stadtwachstum durch Versorgung
- Produktionsketten und Baukosten
- KI-Haendler als Marktdruck

Ergebnis: aus Einzelhandel entsteht ein wachsendes Handelsnetz.

### Phase 4: Karriere und Politik, 6 bis 8 Wochen

- Ruf, Prestige, Raenge
- Ratsauftraege und Stadtprojekte
- einfache Wahlen/Ernennungen
- Privilegien und Sanktionen

Ergebnis: wirtschaftlicher Erfolg bekommt politische Bedeutung.

### Phase 5: Seeschlachten, Piraten und Ereignisse, 6 bis 8 Wochen

- manuelle taktische Seeschlachten fuer wichtige Begegnungen
- Piratenverstecke, Kopfgelder und Stadtauftraege
- Eskorten, Bewaffnung und Reparaturkosten
- Wetter-/Saisonereignisse
- regionale Krisen und Nachfrageimpulse
- Versicherungs-/Risikokosten oder Sicherheitsausbau

Ergebnis: Handelsrouten bleiben dynamisch, Piraten sind ein strategischer Gegner, und Seeschlachten sind wirtschaftlich bedeutsam.

### Phase 6: Alpha/Beta, 8 bis 12 Wochen

- modernes UI/UX-Polishing
- Grafikstil finalisieren
- Audio, Musik, Feedback
- Tutorial und Onboarding
- Balancing, Performance, Bugfixes
- Steam-Seite, Demo oder Playtest-Build

Ergebnis: oeffentlich testbare Version.

## Datenmodell-Entwurf

Minimal benoetigte Entitaeten:

- `Good`: Name, Kategorie, Volumen, Basispreis, Verderblichkeit, Luxusfaktor
- `City`: Name, Region, Koordinaten, Einwohner, Lagerbestaende, Produktionsprofile, Verbrauchsprofile
- `ShipType`: Kapazitaet, Geschwindigkeit, Unterhalt, Crew, Waffenplaetze
- `Ship`: Typ, Zustand, Standort, Ladung, Auftrag
- `CombatStats`: Rumpf, Segel, Besatzung, Moral, Waffen, Enterwert, Fluchtwert
- `PirateBand`: Versteck, Schiffe, Aggressivitaet, Zielrouten, Bekanntheit, Kopfgeld
- `Route`: Stopps, Kaufregeln, Verkaufsregeln, Mindestbestaende, Preislimits
- `Building`: Stadt, Eigentuemer, Input, Output, Arbeiter, Unterhalt
- `Company`: Geld, Ruf, Schiffe, Lager, Betriebe
- `Event`: Region, Dauer, Modifikatoren, Bedingungen

## Preis- und Wirtschaftskonzept

Empfohlene Formel fuer den Start:

- Jede Stadt hat je Ware einen Tagesverbrauch und einen Zielbestand.
- `stock_ratio = aktueller Bestand / Zielbestand`
- Preis steigt stark unter 1.0 und sinkt moderat ueber 1.0.
- Produktion laeuft nur, wenn Input, Arbeiter und Betriebskosten vorhanden sind.
- Bevoelkerung waechst, wenn Grundwaren ueber mehrere Wochen stabil verfuegbar sind.

Das ist einfach genug fuer ein MVP, aber tief genug fuer spaeteres Balancing.

## Moderne Grafik und UI

Empfohlene Richtung:

- Hauptkarte: klare 2.5D-Nord-/Ostseekarte mit animierten Schiffen, Wetterlagen, Handelsrouten und Stadtstatus
- Stadtansicht: stilisierte Hafen- und Stadtsilhouette, keine komplexe Echtzeitstadt im MVP
- UI: dichte Tabellen, Filter, Preisgraphen, Routenplanung, Warnungen
- Feedback: Handelsentscheidungen muessen sofort sichtbar sein: Gewinn, Lagerreichweite, Preisentwicklung, Stadtzufriedenheit
- Seeschlacht-UI: klare Gefahreneinschaetzung vor dem Kampf, kurze Ergebniszusammenfassung nach Auto-Resolve, taktische Ansicht nur fuer ausgewaehlte wichtige Begegnungen

Wichtig: Moderne Grafik darf die Lesbarkeit der Wirtschaftsdaten nicht verschlechtern.

## Rechtliche und kreative Abgrenzung

- Nicht `Patrizier` / `Patrician` als finalen Titel verwenden.
- Keine Originalgrafiken, Musik, Texte, Icons, Kartenlayouts oder UI-Strukturen kopieren.
- Keine exakten Missionsnamen, Charaktere oder proprietaeren Spielbegriffe uebernehmen.
- Historisches Setting, Hanse-Staedte, Handel, Warenarten und allgemein uebliche Genre-Systeme sind als eigene Umsetzung verwendbar.
- Frueh einen eigenen visuellen Stil, eigene Namen und eigene Progression definieren.

Moegliche Arbeitstitel:

- `Hanseatische Kontore`
- `Nordmeer Handel`
- `Kaufmann der Hanse`
- `League of Merchants`
- `Hanseatic Ledger`

## Risiken

- Scope Creep: Das Genre verleitet zu vielen Systemen. Gegenmassnahme: MVP strikt klein halten.
- Balancing: Wirtschaft kann kippen oder geloest werden. Gegenmassnahme: Debug-Tools, Simulationstests, Preisgraphen.
- Seeschlacht-Scope: Taktische Kaempfe koennen das Projekt stark vergroessern. Gegenmassnahme: zuerst Auto-Resolver, dann nur ein schlanker manueller Kampfmodus.
- UI-Komplexitaet: Tabellenlastige Spiele brauchen gute Bedienung. Gegenmassnahme: UI frueh bauen, nicht am Ende.
- Rechtliches Risiko: Zu nah an existierenden Marken. Gegenmassnahme: eigenes Branding und keine Asset-/Text-/Regelkopien.
- Technikrisiko: Simulation eng mit Engine gekoppelt. Gegenmassnahme: Simulationskern moeglichst getrennt und testbar halten.

## Offene Entscheidungen

- Engine final: Godot oder Unity?
- Grafikstil: 2D-Illustration, 2.5D oder vollstaendige 3D-Karte?
- Ziel: Hobbyprojekt, Early Access oder kommerzielle Vollversion?
- Teamgroesse und verfuegbare Wochenstunden?
- Soll der erste Fokus eher Handelssimulation, Stadtaufbau oder Politik sein?
- Wie tief sollen manuelle Seeschlachten werden: schneller taktischer Modus oder umfangreiches separates Kampfsystem?
- Darf der Spieler selbst Piraterie/Kaperfahrt betreiben, oder bleibt Piraterie zuerst ein Gegner- und Auftragssystem?

## Quellen

- Britannica: Hanseatic League, historischer Ueberblick und Handelsnetz: https://www.britannica.com/topic/Hanseatic-League
- Die Hanse / hanse.org: Urspruenge, Luebeck, Nowgorod und Handelswaren: https://www.hanse.org/en/the-medieval-hanseatic-league/the-origins
- Die Hanse / hanse.org: Kontore in Nowgorod, London, Bruegge und Bergen: https://www.hanse.org/en/the-medieval-hanseatic-league/die-kontore
- Kalmar Laens Museum: Handelswaren der Hanse: https://medeltiden.kalmarlansmuseum.se/en/society/the-hanseatic-league/trade-and-merchandise/
- Steam: Patrician IV Feature-Beschreibung als Genre-Referenz: https://store.steampowered.com/app/57620/Patrician_IV/
- Steam: Patrician III Feature-Beschreibung als Genre-Referenz: https://store.steampowered.com/app/33570/Patrician_III/
- GameSpot: Patrician II Review, Hinweise zu dynamischen Preisen und Spielmix: https://www.gamespot.com/reviews/patrician-ii-review/1900-2819467/
- GameSpot: Patrician III Review, Hinweise zu Automatisierung und Endgame-Systemen: https://www.gamespot.com/reviews/patrician-iii-review/1900-6086007/
- GameSpot: Kalypso uebernahm Rechte an Ascaron-Franchises inkl. The Patrician: https://www.gamespot.com/articles/ex-sacred-2-devs-form-gaming-minds-studios/1100-6212292/
- Die Hanse / hanse.org: Die Kogge als zentrales Hanse-Schiff: https://www.hanse.org/en/the-medieval-hanseatic-league/the-cog
- Britannica: Hanseatische Kriegs- und Machtpolitik im Ostseeraum: https://www.britannica.com/topic/Hanseatic-League/The-League-at-its-outset
- Godot Docs: MIT-Lizenz und Lizenzhinweise: https://docs.godotengine.org/en/stable/about/complying_with_licenses.html
- Unity: Runtime Fee gestrichen und Pricing-Updates: https://unity.com/products/pricing-updates
- Unreal Engine: Lizenzmodell und Royalty-Hinweise: https://www.unrealengine.com/license
- Steamworks: Steam Direct App-Gebuehr: https://partner.steamgames.com/doc/gettingstarted/appfee
