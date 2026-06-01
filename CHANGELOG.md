# Changelog

## 0.2.49-city-marker-alignment - 2026-06-01

- Alle Stadtmarker auf der neuen illustrierten Hanseregion-Karte visuell nachgeprueft und an die sichtbaren Hafen-, Fluss-, Haff- und Kuestenzugaenge angepasst.
- Luebeck auf den oestlichen Trave-/Luebecker-Bucht-Zugang und Danzig auf die sichtbare Bucht-/Weichselmuendung verschoben.
- Visby auf Gotland statt auf Oeland oder die schwedische Festlandkueste gesetzt.
- Weitere deutliche Fehlpositionen wie Bergen sowie mehrere Nordsee-, Ostsee- und Haffstaedte korrigiert.
- Stadtkatalog, feste Startstadtdaten, Kartenmetadaten, Navigationsdaten und Generator-Overrides synchronisiert.
- Map Editor um einen Positionsmodus erweitert, mit dem Stadtmarker direkt auf der aktuellen Kartenillustration verschoben und als `user://hanse_city_positions.json` gespeichert werden koennen.
- Katalogloader nutzt gespeicherte Stadtpositions-Overrides aus `user://hanse_city_positions.json`.
- Navigations-Wassererkennung im Generator auf eine Bildanalyse der aktuellen Karten-PNG umgestellt, damit sie zu verschobenen illustrierten Kuestenlinien passt.
- Projektvalidierung um Positionsabgleiche zwischen Stadtkatalog, Kartenmetadaten, Navigationsdaten und Startstadtdaten erweitert.

## 0.2.48-illustrated-hanse-map - 2026-05-31

- Hanseregion-Weltkarte durch eine handgemalte, spieltaugliche Kartenillustration ersetzt.
- Kuestenlayout und sparsame Hauptwasserwege bleiben am bisherigen Kartenasset orientiert; neue Darstellung ergaenzt Waelder, Gebirge, Huegel, Marsch- und Kuestenbereiche.
- Topographie korrigiert: Norddeutsche Tiefebene, Daenemark und suedliche Ostseekueste bleiben flach; groessere Gebirge liegen nur in plausiblen Hochlandregionen wie Norwegen, Schottland und dem suedlichen Kartenrand.

## 0.2.47-trade-window-fit - 2026-05-31

- Handelsfenster gestrafft: Nachfrage-Anzeigen, Informationstext und unterer Abschlussbutton entfernt.
- Warentabelle nach dem Entfernen der Nachfrage-Spalte breiter ausgerichtet, damit Warennamen und Aktionen sauberer in die Spalten passen.
- Unbenutztes Pergament-UI-Asset aus der Projektvalidierung entfernt.

## 0.2.46-trade-quantity-controls - 2026-05-31

- Handelsfenster um Mengenumschaltung fuer `1x`, `5x`, `10x` und `Max` erweitert.
- Kauf- und Verkaufaktionen verwenden die aktive Mengenwahl und bleiben durch Kapital, Stadtbestand, Schiffsladung und Frachtraum begrenzt.
- Warentabelle im Handelsfenster mit klaren Kauf-/Verkauf-Spalten und horizontaler Skalierung fuer kleinere Fenster ueberarbeitet.

## 0.2.45-hanse-trade-window-style - 2026-05-31

- Handelsfenster visuell im hanseatisch-mittelalterlichen Holz-/Goldstil ueberarbeitet.
- Layout in Stadtinformationen, zentrale Warentabelle, ausgewaehlte Ware und untere Statusleiste gegliedert.
- Warentabelle zeigt Nachfrage, Stadtbestand, Preis, Schiffsladung und Durchschnittspreis in klar getrennten Spalten.

## 0.2.44-tempered-price-spread - 2026-05-31

- Preisformel abgeflacht: Lagerueberschuss und Mangel bewegen Preise nur noch moderat statt mit extremen Multiplikatoren.
- Validierung begrenzt die Startpreis-Spanne je Ware, damit offensichtliche Arbitrage durch reine Ueberschusskaeufe nicht das Spiel dominiert.

## 0.2.43-integer-goods-stock - 2026-05-31

- Stadtlager und Schiffsladung werden als ganze Wareneinheiten gefuehrt; Kauf, Verkauf und KI-Handel schneiden Mengen auf ganze Einheiten.
- Handelsfenster und Sidebar zeigen Warenbestaende ohne Nachkommastellen.
- Validierung prueft, dass feste Stadtlagerbestaende ganzzahlige Einheiten sind.

## 0.2.42-trade-window-columns - 2026-05-31

- Handelsfenster optisch ueberarbeitet: Schiffsbestand im Fenster ergaenzt und Warenhandel in saubere Spalten fuer Stadtbestand, Preis, Schiffsladung, Durchschnittspreis und Aktionen aufgeteilt.

## 0.2.41-stable-trade-window-input - 2026-05-31

- Crash-Ursache im Handelsfenster behoben: Das Fenster wird nicht mehr waehrend laufender Maus-Events oder pro Simulationsframe neu aufgebaut.
- Handelsaktionen und Schliessen werden deferred verarbeitet; das Handelsfenster wird nur beim Oeffnen und nach abgeschlossener Transaktion aktualisiert.

## 0.2.40-trade-window-input - 2026-05-31

- Handelsmenue wieder als separates zentriertes Handelsfenster umgesetzt.
- Handelsbuttons und Schliessen-Aktion verwenden direkte Maus-Input-Handler, damit Klicks im dynamisch aufgebauten Handelsfenster sicher verarbeitet werden.

## 0.2.39-ui-approval-rule - 2026-05-31

- AGENTS-Arbeitsregel ergaenzt: UI-Strukturen wie Fenster, Sidebars, Popups und Dialogplatzierungen duerfen nicht ohne ausdrueckliche Anfrage oder Rueckfrage verlegt, zusammengelegt oder ersetzt werden.

## 0.2.38-player-sidebar-capital - 2026-05-31

- Rechte Hauptspiel-Sidebar auf eine Spieleruebersicht reduziert, inklusive aktuellem Kapital, Position, Schiff und aktiver Ladung.
- Handelsfenster zeigt Kapital, Transaktionsfeedback und den durchschnittlich bezahlten Preis je geladener Ware.
- Spieler-Kauf-/Verkauf-Aktionen verrechnen nun Kapital, aktualisieren Fracht sichtbar und nutzen eindeutig gebundene Handelsbuttons.

## 0.2.37-player-ship-trading - 2026-05-31

- Spielerschiff startet in Luebeck und kann per Rechtsklick auf Wasser oder Staedte ueber Wasserpfade bewegt werden.
- Stadt-Rechtsklick am aktuellen Hafen oeffnet ein Handelsfenster mit Waren, Bestand, Preis und einfacher Kaufen-/Verkaufen-Aktion.
- Statusbereich zeigt Spielerschiff, Ladung und Restreisezeit; ein Button spult gezielt bis zur Ankunft am aktuellen Ziel vor.

## 0.2.36-hide-game-route-lines - 2026-05-31

- Hauptspiel blendet sichtbare Routelinien aus; Schiffe nutzen die Wasserpfade weiterhin intern fuer Bewegung und Reisezeit.
- Normale Simulationsgeschwindigkeit deutlich reduziert, damit Schiffsreisen lesbarer ablaufen.

## 0.2.35-detailed-land-terrain - 2026-05-31

- Landflaechen der Hanseregion-Weltkarte deutlich strukturierter gestaltet.
- Satellitenkarten-inspirierte Landschaftszonen ergaenzt: kultivierte Tieflander, dichtere Waldraeume im Norden/Osten, Feuchtgebiete und rauere Hochlandzonen.
- Darstellung historisch abstrahiert, ohne moderne Strassen, Stadtteppiche oder Laendergrenzen.
- Kartenmetadaten dokumentieren den detaillierten Landbedeckungsstil.

## 0.2.34-ai-trader-metrics - 2026-05-31

- Erste KI-Haendler im Hauptspiel implementiert, die Zielhaefen gewichtet waehlen, echte Stadtlager kaufen, reisen und am Ziel verkaufen.
- Balancing-Metriken fuer Stadtwaren, Haendlerereignisse und taegliche Haendlerzustaende werden als JSONL-Datenbankdatei nach `user://balance_metrics.jsonl` geschrieben.
- Simulationskern um Handelsmethoden fuer reale Stadtlagerbestaende erweitert.

## 0.2.33-natural-world-map - 2026-05-31

- Hanseregion-Weltkarte staerker als natuerliche Draufsicht statt als beschriftete Landkarte gestaltet.
- Kartentitel, Seegebietsbeschriftungen, Kompass und Gitternetz aus dem Hintergrundasset entfernt.
- Kartengenerator erzeugt nun zusammenhaengende Land-/Meertexturen ohne sichtbare Laendergrenzen.
- Kartenmetadaten dokumentieren den natuerlichen Weltkartenstil.

## 0.2.32-continuous-ship-travel - 2026-05-31

- Hauptspiel um einstellbare Simulationsgeschwindigkeit von Stop bis Fast Forward erweitert.
- Demo-Schiffe bewegen sich kontinuierlich entlang der Wasserpfade; Reisezeit entsteht aus Routenlaenge und Schiffsgeschwindigkeit.
- Wirtschaftstage laufen automatisch bei voller Simulationszeit weiter, wodurch Lagerbestaende und Marktpreise fortlaufend aktualisiert werden.

## 0.2.31-modern-hanse-map-style - 2026-05-31

- Hanseregion-Weltkarte visuell an den neuen Design Guide angelehnt: moderner Seekartenlook mit hanseatisch gedeckter Farbpalette.
- Kartengenerator um zentrale Stilfarben, ruhigeres Meer, waermere Landflaechen, dezente Kartenlinien und Kompassakzent erweitert.
- Kartenmetadaten dokumentieren den neuen visuellen Stil.

## 0.2.30-ai-trader-design - 2026-05-31

- KI-Haendlerkonzept fuer stabilisierenden, glaubwuerdigen Warenfluss dokumentiert.
- Globale Startsettings, unsichtbare Haendlerprofile, Zielwahl, Beladung, Verkauf und Marktinformationen der KI festgelegt.
- Stadt-, Preis-, Produktions-, Verbrauchs- und Bevoelkerungsannahmen fuer den ersten KI-Warenfluss zusammengefasst.

## 0.2.29-sea-navigation-data - 2026-05-31

- Kartengenerator erzeugt automatisch Navigationsdaten aus Landpolygonen, Flusslinien und Hafenmarkern.
- Navigationsdaten enthalten ein grobes Wasser-Raster, Hafenanker je Hanseort und vorberechnete Wasserpfade zwischen Hanseorten.
- Fernrouten laufen ueber offene Seezellen; Fluss- und Hafenzellen dienen nur noch als lokaler Zugang zum naechsten See-Gate.
- Kartenansicht zeichnet die Hauptspielroute und den Schiffsmarker ueber Wasserpfade statt ueber direkte Linien, mit Fallback bei fehlenden Routen.
- Validierung prueft, dass Navigationsdaten, Debug-Maske, Hafenanker und Routendaten vorhanden sind.

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
