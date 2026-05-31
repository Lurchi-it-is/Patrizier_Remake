# Changelog

## 0.2.28-city-supply-visible - 2026-05-31

- Map Editor benennt die Versorgungsspalte als `Erzeugung/Zufluss`, damit Hinterland- und Handelszufluss nicht als lokale Produktion missverstanden wird.
- Luebeck erhaelt sichtbare Zuflusswerte fuer Getreide und weitere verbrauchte Waren, statt dort `0` anzuzeigen.

## 0.2.27-production-consumption-coverage - 2026-05-31

- Produktion und Handelszufluss der festen Startstaedte so angepasst, dass jede verbrauchte Ware regional mindestens gedeckt ist.
- Map-Editor-Defaults fuer Hanseorte auf besser skalierte Erzeugungs-/Zuflusswerte gegen gruppenbasierten Verbrauch angehoben.
- Validierung prueft nun die regionale Deckung von Produktion/Zufluss gegen Tagesverbrauch je Ware.

## 0.2.26-historical-units-production-balancing - 2026-05-31

- Warenkatalog um historische Spiel-Einheiten wie Last, Fass, Schiffspfund, Fuder, Ballen, Timmer und Kiste erweitert.
- Produktion der festen Spielstaedte und Map-Editor-Defaults auf diese groesseren Einheiten neu balanciert.
- Map Editor und Hauptspiel zeigen Warenpreise bzw. Produktionswerte mit Einheitshinweisen an.
- Validierung prueft, dass jede Ware Einheiten-Metadaten besitzt.

## 0.2.25-north-sea-trade-sites - 2026-05-31

- Primaere Nordsee-Handelsstandorte Hull, Boston, King's Lynn, Great Yarmouth, Kampen und Stade in den Hanseorte-Katalog aufgenommen.
- Hafen-/Gewaessermarker, historische Wasserwegsreferenzen und Routen fuer die neuen Nordsee-Standorte ergaenzt.
- Defaultwerte fuer Einwohner, Erzeugung und Verbrauch der neuen Standorte im Map Editor hinterlegt.

## 0.2.24-map-editor-population-groups - 2026-05-31

- Map Editor zeigt je Stadt die Verteilung auf Arme/Tageloehner, Handwerker/Gesellen, Buerger/Kaufleute und Patrizier/Reiche.
- Typische Einwohnerverteilungen werden je Stadttyp automatisch aus der Gesamtbevoelkerung berechnet und koennen pro Gruppe angepasst werden.
- Verbrauchswerte im Map Editor werden aus Einwohnergruppenbedarf plus Stadt-/Gewerbeverbrauch abgeleitet und als Tagesverbrauch angezeigt.
- Custom-Kartenexport schreibt `population_groups`, damit Simulation und exportierte Karten dieselbe Verbrauchslogik nutzen.

## 0.2.23-aalborg-bay-shore - 2026-05-31

- Aalborg-Marker von der westlichen Seite der Landzunge an den Ufersaum der Aalborg-Bucht verschoben.
- Aalborg-Wasserwegsreferenz auf Aalborg-Bucht/Limfjord aktualisiert.
- Kartengenerator, Kartenmetadaten und Hanse-Staedtedaten auf die neue Aalborg-Position synchronisiert.

## 0.2.22-koenigsberg-haff-shore - 2026-05-31

- Koenigsberg-Marker vom offenen Wasser auf den Kuestensaum am Frischen Haff verschoben.
- Kartengenerator, Kartenmetadaten und Hanse-Staedtedaten auf die neue Haffrandposition synchronisiert.

## 0.2.21-koenigsberg-frisches-haff - 2026-05-31

- Koenigsberg-Marker auf die Danzig/Elbing-Seite des Frischen Haffs verschoben.
- Kartengenerator und Hanse-Staedtedaten auf denselben neuen Wasserpunkt synchronisiert.

## 0.2.20-hanse-goods-population-needs - 2026-05-31

- Handelswarenkatalog um typische Hanse-Waren wie Stockfisch, Bier, Pech/Teer, Flachs, Wolle, Eisen, Wachs, Pelze, Wein und Gewuerze erweitert.
- Einwohnergruppen fuer Arme, Handwerker, Buerger/Kaufleute und Patrizier/Reiche mit eigenen Bedarfen und Verbrauchsraten ergaenzt.
- Feste Spielstaedte erhalten getrennte, historisch grob begruendete Erzeugungs-, Verbrauchs-, Lager- und Zielbestandsprofile.
- Simulation addiert gruppenbasierten Tagesverbrauch zum Stadtverbrauch; Validierung prueft Warenreferenzen, Gruppensummen und Stadtwirtschaft.

## 0.2.19-water-snapped-map-markers - 2026-05-31

- Stadtmarker im Kartengenerator auf sichtbare Wasserpixel der generierten Hanseregion-Karte eingerastet.
- Kartenbild, Kartenmetadaten, Hanse-Staedtedaten und feste Spielstadtpositionen auf dieselben Markerkoordinaten synchronisiert.
- Gezeichnete Stadtpunkte und Routen nutzen nun die wassernahe Markerposition statt abweichender historischer Stadtmitten.

## 0.2.18-start-command-in-tests - 2026-05-31

- AGENTS-Regel ergaenzt: Testanleitungen muessen immer den konkreten Startbefehl fuer die betroffene App oder Szene enthalten.
- Entwicklungsdokumentation um dieselbe Vorgabe erweitert.

## 0.2.17-coastal-trade-sites - 2026-05-31

- Weitere wichtige Kuesten- und Seehandelsorte nach Recherche ergaenzt: Malmoe, Skanor-Falsterbo, Helsingborg, Kalmar, Abo, Viborg, Narva, Elbing, Memel und Aalborg.
- Kartenmetadaten um historische Wasserwegs-/Handelsbegruendungen fuer die neuen Orte erweitert.
- Defaultwerte fuer Einwohner, Erzeugung und Verbrauch der neuen Standorte ergaenzt.

## 0.2.16-map-marker-agent-rule - 2026-05-31

- AGENTS-Regel ergaenzt: wassergebundene historische Handelsstaedte werden am sinnvoll nutzbaren Gewaesserzugang markiert.
- Festgelegt, dass historische `lon`/`lat`-Koordinaten erhalten bleiben und abweichende Karten-/Hafenmarker separat konsistent gepflegt werden.
- Dokumentationspflicht fuer recherchierte Wasserwege bei Staedten ohne klaren offenen Seeanschluss verankert.

## 0.2.15-water-aligned-city-markers - 2026-05-31

- Stadtmarker fuer wassergebundene Handelsorte auf Hafen-, Fluss- oder Kuestenzugangspunkte verschoben.
- London, Bremen und Stettin sowie weitere Fluss-/Hafenstaedte liegen nun auf dem genutzten Gewaesser statt nur auf der historischen Stadtmitte.
- Kartengenerator dokumentiert getrennte historische Koordinaten und Markerkoordinaten in den Kartenmetadaten.

## 0.2.14-map-river-visibility - 2026-05-31

- Laendergrenzen aus dem generierten Kartenasset entfernt.
- Fluesse breiter und wasserfarbener dargestellt, damit sie als befahrbare Wasserwege lesbarer sind.
- Hanseregion-Karte aus dem Generator neu erzeugt.

## 0.2.13-map-click-city-selection - 2026-05-31

- Stadtpunkte im Map Editor koennen direkt auf der Karte angeklickt werden.
- Kartenklick waehlt die Stadt aus, setzt bei Bedarf die Checkbox und aktualisiert das Grundwerte-Panel.
- Hover- und Klickerkennung beruecksichtigen Zoom und Pan.

## 0.2.12-city-hover-and-defaults - 2026-05-31

- Kartenansicht zeigt Stadtnamen als Mouseover-Tooltip auf sichtbaren Stadtpunkten.
- Map Editor erhaelt Defaultwerte fuer Einwohner, Erzeugung und Verbrauch je historischem Hanseort.
- Bestehende Spielstadtwerte bleiben priorisiert; Defaults fuellen nur bisher leere Editor-Orte.

## 0.2.11-map-view-zoom - 2026-05-31

- Kartenansicht um Mausrad-Zoom bis 500 Prozent erweitert.
- Gezoomte Karte kann per Ziehen verschoben werden und bleibt an den Kartenraendern begrenzt.
- Map-Editor-Legende zeigt den aktuellen Zoomfaktor.

## 0.2.10-historical-water-access - 2026-05-31

- Vorherige grobe Wasserzugangsdarstellung zurueckgerollt und durch recherchierte Wasserwege ersetzt.
- Themse, Zwin, Rhein, Weser, Elbe, Trave, Warnow, Ryck, Oder, Weichsel/Mottlau, Pregel, Duena und Volkhov/Ladoga/Neva als dezente Kartenwasserwege ergaenzt.
- Kartenmetadaten dokumentieren Typ, betroffene Stadt und historische Grundlage der Wasserwege.

## 0.2.9-map-editor-city-values - 2026-05-31

- Map Editor um ein Stadt-Grundwerte-Panel pro ausgewaehlter Stadt erweitert.
- Einwohner, Erzeugung und Verbrauch koennen je Stadt ueber Eingabefelder angepasst werden.
- Vorhandene Spielstadtwerte werden als Startwerte geladen; weitere Hanseorte erhalten Defaultwerte nach Stadttyp.
- Ausgewaehlte Custom-Staedte koennen inklusive Grundwerten als JSON gespeichert werden.

## 0.2.8-separated-executables - 2026-05-31

- Hauptspiel und Map Editor technisch in getrennte Szenen und Startskripte aufgeteilt.
- Launcher ergaenzt, der anhand der Export-Feature-Tags `main_game` und `map_editor` die passende Einstiegsszene laedt.
- Windows-Export-Presets fuer `HanseMainGame.exe` und `HanseMapEditor.exe` ergaenzt.
- Validierung prueft getrennte Startpunkte, Launcher und Export-Preset-Eintraege.

## 0.2.7-main-game-prototype - 2026-05-31

- Hauptgame-Prototyp startet mit fuenf festen Spielstaedten auf der Hanseregion-Karte.
- Simulationsdaten um Bremen und Danzig inklusive Produktion, Verbrauch, Bestaenden und Zielbestaenden ergaenzt.
- Kartenansicht zeichnet feste Spielstaedte und eine erste Hauptroute standardmaessig, unabhaengig vom Karteneditor.
- Architekturvorgabe dokumentiert: Hauptspiel und Map Editor werden als getrennte Exe-Dateien ausgeliefert.

## 0.2.6-foundation - 2026-05-31

- Karteneditor von Dropdown-Auswahl auf eine scrollbare Checkbox-Liste fuer alle historischen Hanseorte umgestellt.
- Auswahlsteuerung um kompakte Aktionen fuer alle/keine Orte ergaenzt.
- Kartenmarker kleiner und dezenter gestaltet, inklusive feinerem Ring und reduzierter Beschriftung.

## 0.2.5-foundation - 2026-05-31

- Karteneditor-Panel mit Selektor fuer historische Hanseorte hinzugefuegt.
- Separaten Hanseorte-Katalog mit Kartenpixeln aus dem aktuellen Hanseregion-Asset ergaenzt.
- Kartenansicht zeichnet ausgewaehlte Editor-Orte als skalierte Punkte und hebt die aktuelle Auswahl hervor.

## 0.2.4-foundation - 2026-05-31

- Arbeitsregel ergaenzt: Nach jedem abgeschlossenen Implementierungsschritt wird eine kurze Testanleitung mit Befehlen und erwarteten Pruefpunkten bereitgestellt.

## 0.2.3-foundation - 2026-05-31

- Hanseregion-Karte vorerst als neutralen geografischen Hintergrund ohne Stadtmarker, Stadtnamen und Handelsrouten ausgegeben.
- Godot-Kartenansicht so angepasst, dass Staedte und Handelsroute vorerst nicht ueber die Karte gezeichnet werden.

## 0.2.2-foundation - 2026-05-31

- Realitaetsnahes 1600x900-Karten-Asset der ehemaligen Hanseregion auf Basis von Natural-Earth-Geodaten hinzugefuegt.
- Kartengenerator mit reproduzierbaren Stadtpositionen, Handelsachsen und Metadaten ergaenzt.
- Godot-Kartenansicht auf das neue Karten-Asset umgestellt und Stadt-/Piratenzonenpositionen angepasst.

## 0.2.1-foundation - 2026-05-31

- Startszene von reiner Textausgabe zu einer sichtbaren Prototyp-Oberflaeche ausgebaut.
- Einfache Seekarte mit Staedten, Handelsroute, Schiffmarker und Piratenrisiko-Zonen hinzugefuegt.
- Dashboard mit Simulationstag, Marktpreisen und interaktivem Seeschlacht-Resolver ergaenzt.

## 0.2.0-foundation - 2026-05-31

- Godot-4-Projektfundament mit Startszene angelegt.
- Datenkataloge fuer Waren, Staedte, Schiffstypen und Piratenzonen erstellt.
- Erste Simulationsbausteine fuer Tages-Tick, Preisbildung und Seeschlacht-Auto-Resolver hinzugefuegt.
- Entwicklerdokumentation und lokales Validierungsskript ergaenzt.

## 0.1.1-planning - 2026-05-31

- Seeschlachten und Piraterie als Kernfeature im Projektplan verankert.
- MVP um Piratenrisiko und einfachen Seeschlacht-Auto-Resolver erweitert.
- Meilensteine, Datenmodell, Risiken, offene Entscheidungen und Quellen ergaenzt.

## 0.1.0-planning - 2026-05-31

- Projektplan fuer die hanseatische Warenwirtschaftssimulation erstellt.
- Management Summary, Recherche-Ergebnisse, MVP-Scope, Meilensteinplan, Technikempfehlung und Quellen dokumentiert.
- Initiale Projektversion in `VERSION` festgelegt.
