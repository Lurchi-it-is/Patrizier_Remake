# KI-Haendler und Warenfluss

Version: 0.2.61-ship-horizontal-direction-flip

## Zielbild

Die KI-Haendler sollen den Warenfluss im Spiel beleben und stabilisieren. Sie sind zuerst keine perfekten Gegner, sondern glaubwuerdige Marktteilnehmer, die Staedte versorgen, Chancen erzeugen und die Welt lebendig wirken lassen.

Das Spiel fokussiert sich auf Schiffshandel. Andere Schiffe und Haendler zeigen dem Spieler nicht sichtbar, was sie transportieren, wohin sie fahren oder nach welcher Strategie sie handeln. Von aussen sind nur Schiff, Name/Flagge und Bewegung sichtbar.

## Startumfang

- Eine Schiffsart fuer Spieler und KI.
- Feste Schiffskapazitaet in Schiffspfund.
- Warenpreise gelten pro Schiffspfund.
- KI-Haendler haben vorerst kein Kapital.
- KI wird durch Hafenbestand, Schiffskapazitaet, Routenwahl und Profilverhalten begrenzt.
- KI-Haendler bleiben immer im Spiel und gehen nicht pleite.
- Jede Reise ist ein einzelner Trip von einem Hafen zum naechsten.
- Schiffe bewegen sich sichtbar ueber vorberechnete Wasserpfade.
- Keine Politik, Fraktionen, Zoelle oder Reputation im ersten Warenfluss.

## Markt- und Stadtmodell

KI und Spieler handeln auf denselben Stadtlagern. Es gibt keinen separaten KI-Markt und keine reservierten Warenmengen.

- Stadtlager je Ware sind die zentrale Wahrheit.
- Produktion, Verbrauch, Spielerhandel und KI-Handel veraendern dieselben Bestaende.
- Staedte haben unbegrenzte Lagerkapazitaet.
- Staedte haben unbegrenztes Geld fuer Ankaeufe.
- Freier Markt: KI darf Waren komplett aufkaufen, wenn Preis, Bestand und Entscheidung dazu fuehren.
- Schutz vor Engpaessen entsteht ueber steigende Preise, nicht ueber harte Mindestbestaende.

Preise entstehen aus dem Verhaeltnis von aktuellem Lagerbestand zu Sollbestand:

- Jede Ware hat Mindestpreis, Basispreis und Hoechstpreis.
- Bei Sollbestand liegt der Preis nahe am Basispreis.
- Je weiter der Bestand vom Sollbestand abweicht, desto staerker schlaegt der Preis nicht-linear aus.
- Niedriger Bestand erhoeht Preise.
- Hoher Bestand senkt Preise.
- Bei `0` Bestand wird trotzdem ein Preis angezeigt, der als Nachfrage-/Marktsignal dient.
- Kaufen ist nur moeglich, wenn realer Bestand vorhanden ist.
- Verkaufen ist immer moeglich, auch bei Ueberfluss, aber dann zu niedrigerem Preis.

## Produktion, Verbrauch und Bevoelkerung

Die Wirtschaft laeuft taeglich.

- Buerger verbrauchen feste Warenmengen pro Einwohner und Tag.
- Wenn Bedarf nicht gedeckt ist, wird nur der verfuegbare Anteil verbraucht.
- Nicht gedeckter Bedarf senkt die Zufriedenheit.
- Grundnahrung und wichtige Basiswaren wiegen staerker als Luxusgueter.
- Das Lager darf nie negativ werden.
- Niedrige Zufriedenheit kann sofort Bevoelkerung kosten.
- Bevoelkerungsverlust verlaeuft nicht-linear: anfangs langsam, bei starkem Mangel schneller.
- Hohe Zufriedenheit kann Bevoelkerungswachstum ausloesen.
- Wachstum und Schrumpfung haben harte taegliche Grenzen.
- Ein neutraler Zufriedenheitsbereich verhindert staendige Mini-Aenderungen.
- Wohnraum-/Kapazitaetsgrenzen kommen spaeter, nicht im ersten Schritt.

Betriebe produzieren ebenfalls taeglich:

- Produktion wird als Output pro Tag gerechnet.
- Betriebe koennen Rohstoffe verbrauchen und daraus Waren erzeugen.
- Grundrohstoffe wie Holz, Getreide oder Hopfen koennen ohne Input entstehen.
- Produktionsketten sollen ein geschlossenes System bilden.
- Bei fehlenden Inputs produziert ein Betrieb anteilig.
- Der knappste Input begrenzt den Output.
- Verbraucht werden nur die proportional zur tatsaechlichen Produktion benoetigten Inputs.

Beispiel:

- Brauerei plant `10` Schiffspfund Getreide und `5` Schiffspfund Hopfen zu verbrauchen.
- Hopfen reicht nur fuer `40%`.
- Die Brauerei produziert `40%` Bier.
- Sie verbraucht `40%` Getreide und den vorhandenen Hopfenanteil.

## Sichtbarkeit fuer den Spieler

Der Spieler soll Marktzustaende lesen koennen, aber nicht die KI-Absicht einzelner Schiffe.

Sichtbar:

- Stadtzufriedenheit.
- Konkrete Lagerbestaende und Preise im aktuellen Hafen.
- Historische Lager-/Preiswerte aus zuletzt besuchten Haefen, mit ihrem damaligen Stand.
- Durchschnittlicher Einkaufspreis je Warenart in der eigenen Ladung.
- Andere Schiffe auf der Karte.

Nicht sichtbar:

- Ladung anderer KI-Schiffe.
- Ziel anderer KI-Schiffe.
- Haendlerprofil.
- konkrete KI-Entscheidungsgruende.

## Marktinformation der KI

Alle Haendler kennen:

- alle Staedte,
- welche Waren in Staedten produziert werden,
- grobe Preisbereiche je Ware,
- ungefaehre Produktions-/Verbrauchslogik.

Konkrete Marktinformationen sind begrenzt:

- Ein KI-Haendler speichert konkrete Preise aus zuletzt besuchten Haefen.
- Diese Daten altern und koennen dadurch unzuverlaessig werden.
- Geruechte und Marktinfos koennen zusaetzliche Hinweise liefern.
- Geruechte sind zuerst nur interne KI-Daten, kein Spielerfeature.
- Eine aehnliche Marktinfo-Mechanik fuer den Spieler ist spaeter moeglich.

## Globale Startsettings

Die Einstellungen werden vor Spielstart gewaehlt und gelten global fuer die Simulation.

### KI-Effizienz

Stufen: `Niedrig`, `Mittel`, `Hoch`

- Niedrig: KI handelt schlechter, vorsichtiger und langsamer. Sie akzeptiert suboptimale Ziele, nutzt aeltere/ungenauere Infos und streut Entscheidungen breiter.
- Mittel: normale Bewertung und normale Zufallsstreuung.
- Hoch: KI bewertet mehr Optionen, tendiert staerker zu besseren Zielen und nutzt Kapazitaet effizienter.

### Schwierigkeit Handel

Stufen: `Niedrig`, `Mittel`, `Hoch`

Diese Einstellung beschreibt die Gewinnmargen, nicht die KI-Staerke.

- Niedrig: niedrige Margen, Handel ist schwieriger.
- Mittel: normale Margen.
- Hoch: hohe Margen, Handel ist leichter.

### Marktunsicherheit

Stufen: `Niedrig`, `Mittel`, `Hoch`

- Niedrig: geringe Schwankungen.
- Mittel: normale Schwankungen.
- Hoch: staerkere Preis- und Nachfrageschwankungen.

Die Marktunsicherheit bedeutet primaer mehr Schwankung im Markt, nicht nur ungenauere Geruechte.

### Anzahl KI-Haendler

Stufen: `Niedrig`, `Mittel`, `Hoch`

- Die Haendlerzahl skaliert mit der Kartengroesse bzw. Hafenanzahl.
- Mehr KI-Haendler stabilisieren die Versorgung staerker.
- Mehr KI-Haendler erzeugen zugleich mehr Konkurrenz und Preisdruck fuer den Spieler.

## Unsichtbare Haendlerprofile

Haendler sollen nicht als feste sichtbare Typen erscheinen. Intern erhalten sie kontinuierliche Profilwerte, aus denen unterschiedliches Verhalten entsteht.

Empfohlene Werte:

- Effizienz: Wie gut der Haendler Routen, Preise und Ladung bewertet.
- Risikobereitschaft: Wie eher er lange oder unsichere Fahrten fuer bessere Chancen akzeptiert.
- Geduld: Ob er schnell mit Gewinn verkauft oder auf bessere Haefen wartet.
- Versorgungsfokus: Wie stark Engpaesse als wirtschaftliche Chance priorisiert werden.
- Regionalitaet: Ob er nahe Regionen bevorzugt oder weiter streut.
- Produktionsfokus vs. Marktfokus: Ob er eher Produktions-/Verbrauchslogik oder aktuelle Marktinfos nutzt.
- Auslastungsneigung: Ob er eher vorsichtig teilbeladen oder effizient voll beladen faehrt.

Die globalen Settings verschieben diese Profilwerte fuer alle Haendler.

## Zielwahl

Die KI kennt alle Staedte, bewertet aber nicht jedes Mal perfekt global.

- Pro Reise waehlt die KI zuerst einen Zielhafen.
- Danach entscheidet sie, welche Waren fuer dieses Ziel geladen werden.
- Die Zielwahl erfolgt aus einer begrenzten Kandidatenliste.
- Kandidatenliste und Bewertung haengen von Profil und globaler KI-Effizienz ab.
- Regionale Haendler bevorzugen nahe Kandidaten.
- Risikofreudige Haendler erhalten eher entfernte Kandidaten.
- Produktionsfokussierte Haendler bevorzugen Produktions-/Verbrauchsbeziehungen.
- Marktfokussierte Haendler bevorzugen aktuelle Preise, Geruechte und Engpaesse.

Beispiel fuer Kandidatenanzahl:

- KI-Effizienz niedrig: `2-4` Zielhaefen.
- KI-Effizienz mittel: `4-7` Zielhaefen.
- KI-Effizienz hoch: `7-12` Zielhaefen.

Aus der Kandidatenliste wird nicht zwingend der beste Hafen genommen. Die KI waehlt gewichtet zufaellig:

- Hohe Effizienz tendiert staerker zum besten Ziel.
- Niedrige Effizienz streut breiter.
- Dadurch entstehen verschiedene Ergebnisse und nicht jede KI wirkt gleich.

Entfernung und Reisezeit wirken als Nachteil in der Zielbewertung. Fuer die KI gibt es im ersten Schritt keine Reisekosten, aber weite Strecken sind trotzdem weniger attraktiv. Dieser Entfernungsnachteil haengt vom Profil ab: regionale/vorsichtige Haendler vermeiden lange Strecken staerker als risikofreudige Haendler.

## Beladung

Nach der Zielwahl prueft die KI Waren im aktuellen Hafen.

- Ein Schiff darf `0-5` Warenarten laden.
- `0` bedeutet Leerfahrt, soll aber selten sein.
- Leerfahrten passieren vor allem bei schlechten Chancen oder unsicherer Lage.
- Historisch/plausibel sollen Haendler eher selten leer fahren.
- Die KI kann gemischt laden.
- Verteilung ist zufaellig, aber nach Attraktivitaet gewichtet.
- Bessere Waren erhalten meist mehr Laderaum, aber nicht immer.
- Die KI darf nur kaufen, was im Hafen wirklich vorhanden ist.
- Das Schiff wird nicht automatisch immer voll beladen.

Auslastung haengt ab von:

- Haendlerprofil,
- erwarteter Handelschance,
- KI-Effizienz,
- Unsicherheit der Informationen.

Beispiele:

- vorsichtige Haendler fahren eher mit `40-70%`,
- effiziente Haendler eher mit `80-100%`,
- bei sehr attraktiven Chancen wird mehr geladen,
- bei unsicherer Lage weniger.

## Verkauf

Die KI speichert wie der Spieler durchschnittliche Einkaufspreise pro Warenart.

Beim Verkauf gilt:

- Die KI darf verkaufen, wenn Preis ueber Durchschnittseinkauf plus gewuenschter Marge liegt.
- Die KI darf manchmal auch mit kleinem Verlust verkaufen, um Laderaum freizubekommen.
- Verlustverkaeufe haengen vom Profil ab.
- Ungeduldige Haendler verkaufen eher mit Verlust.
- Geduldige Haendler halten Ware laenger.
- Ein Haendler kann bei Ankunft verkaufen oder weiter auf bessere Chancen warten; das Verhalten entsteht aus Profil und Zufallsgewichtung.

## Stabilisierung

Die KI soll Engpaesse priorisieren, aber nicht extrem.

Wichtig:

- Die KI handelt rein wirtschaftlich.
- Sie betrachtet Stadtzufriedenheit nicht direkt.
- Engpaesse werden indirekt ueber hohe Preise und Lagerknappheit attraktiv.
- Dadurch stabilisiert die KI die Wirtschaft, ohne Sonderregeln fuer Versorgung zu brauchen.

## Navigation und Bewegung

Schiffsbewegung muss sichtbar ueber Wasser laufen.

- Any-to-Any-Verbindungen zwischen Haefen sind erforderlich.
- Direkte Linien ueber Land sind nicht akzeptabel.
- Fernrouten sollen ueber offene See laufen.
- Fluesse und Hafenzugaenge dienen nur als lokale Zubringer.
- Andere Schiffe zeigen weder Ziel noch Ladung.

Der aktuelle technische Unterbau:

- `assets/maps/hanse_navigation_1600x900.json` enthaelt ein Wasser-/See-Raster, Hafenanker, See-Gates und vorberechnete Routen.
- `scripts/ui/map_view.gd` kann sichtbare Routen und Schiffspositionen entlang dieser Polylines zeichnen.
- `user://balance_metrics.jsonl` speichert Entwicklungsmetriken fuer Stadtbestaende, Preise und KI-Haendlerereignisse.

## MVP-Implementierungsreihenfolge

Empfohlene naechste Schritte:

1. KI-Haendlerdatenmodell mit Profilwerten anlegen.
2. Eine aktive Schiffsart/Kapazitaet fuer KI verwenden.
3. Startsettings fuer KI-Effizienz, Schwierigkeit Handel, Marktunsicherheit und KI-Anzahl definieren.
4. KI-Haendler beim Simulationsstart skalierend pro Karte erzeugen.
5. Zielwahl ueber Kandidatenliste und gewichtete Zufallswahl implementieren.
6. Beladung nach Zielwahl implementieren.
7. Bewegung entlang vorhandener Navigationsrouten starten.
8. Bei Ankunft verkaufen, Marktinfo aktualisieren und naechsten Trip planen.
9. Debug-Ausgabe fuer KI-Entscheidungen ergaenzen, aber nur fuer Entwicklung.
10. Balancing mit wenigen Haendlern und wenigen Waren testen.

## Offene Detailannahmen fuer die erste Umsetzung

- Eine generische Handelskogge oder ein neutraler Startfrachter reicht als erste Schiffsart.
- KI startet verteilt auf vorhandene Haefen.
- KI-Geschwindigkeit nutzt den einen Schiffstyp.
- KI reagiert taeglich oder bei Hafenankunft, nicht in jedem Frame.
- Geruechte koennen zuerst als einfache zufaellige Marktinfo-Eintraege implementiert werden.
- Der Spieler erhaelt diese Geruechte spaeter, nicht im ersten KI-Schritt.
- Keine KI-Kampf-, Piraten-, Versicherungs- oder Politiklogik im ersten Warenfluss.
