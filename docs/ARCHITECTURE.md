# Architektur

Version: 0.2.32-continuous-ship-travel

## Leitidee

Die Wirtschaftssimulation soll datengetrieben und testbar bleiben. Godot rendert UI, Karte und Interaktion; Waren, Staedte, Schiffe, Preise und Piratenrisiken werden als Daten modelliert.

## Module

- `data/`: JSON-Kataloge fuer Balancing, historische Spielwerte, Einwohnergruppen und Karteneditor-Orte.
- `docs/HANSE_ECONOMY_BALANCING.md`: Recherche- und Balancingnotizen fuer Handelswaren, Einwohnergruppen und Stadtprofile.
- `docs/AI_TRADER_DESIGN.md`: Konzept fuer KI-Haendler, Warenfluss, globale Settings, Profile und MVP-Umsetzung.
- `scripts/data/`: Laden und Validieren der Kataloge zur Laufzeit.
- `scripts/simulation/`: Engine-nahe, aber UI-unabhaengige Simulationslogik.
- `scripts/ui/`: Prototyp-Visualisierung fuer realitaetsnahes Karten-Asset, feste Hauptgame-Staedte, klickbare Karteneditor-Punkte, Mouseover-Namen, Stadt-Grundwerte, Zoom/Pan, Piratenrisiko und Status.
- `assets/maps/`: generierte neutrale Hanseregion-Karte im modernen Hanse-Seekartenstil ohne Laendergrenzen, mit Metadaten, breiter lesbaren Wasserwegen und automatisch erzeugten Navigationsdaten fuer Wasserpfade.
- `scenes/`: Godot-Szenen fuer Einstieg, Karte und spaetere UI.
- `tools/`: lokale Validierung und Projektpflege.

## Build-Ziele

- Das Hauptspiel und der Map Editor werden als getrennte Exe-Dateien ausgeliefert.
- Das Hauptspiel startet in die regulare Handels- und Wirtschaftssimulation.
- Der Map Editor startet direkt in die Custom-Karten-Erstellung und bleibt als eigenstaendiges Tool vom Hauptspiel-Build getrennt.
- Der Map Editor verwaltet Stadt-Grundwerte im Editorzustand und exportiert ausgewaehlte Custom-Staedte als JSON unter `user://custom_map_city_values.json`.
- Fuer historische Hanseorte ohne feste Spieldaten liefert der Editor Startwerte fuer Einwohner, Produktion und Verbrauch aus einer lokalen Balancing-Tabelle.
- Der Map Editor fuehrt Einwohnergruppen je Stadt mit und leitet den sichtbaren Tagesverbrauch aus Gruppenbedarf plus Stadt-/Gewerbeverbrauch ab.
- Stadtmarker koennen getrennte Karten-/Hafenpositionen nutzen, damit wassergebundene Handelsorte auf dem tatsaechlich genutzten Gewaesserzugang liegen.
- Schiffsbewegung nutzt vorberechnete Navigationspfade aus `assets/maps/hanse_navigation_1600x900.json`; direkte Linien dienen nur als Fallback, falls eine Route fehlt.
- Das Hauptspiel fuehrt einen kontinuierlichen Simulations-Takt mit einstellbarer Geschwindigkeit; Wirtschaftstage werden bei vollen Simulationstagen abgearbeitet, Schiffspositionen werden fortlaufend interpoliert.
- Der Hanseorte-Katalog priorisiert Kuesten-, Sund-, Haff- und Hafenstandorte, wenn weitere Handelsorte ergaenzt werden.
- `scenes/launcher.tscn` ist der technische Godot-Projektstart und waehlt anhand des Export-Feature-Tags `main_game` oder `map_editor` die eigentliche Einstiegsszene.
- `scenes/main_game.tscn` nutzt `scripts/main_game.gd`; `scenes/map_editor.tscn` nutzt `scripts/map_editor.gd`.
- `export_presets.cfg` definiert die Windows-Ziele `builds/HanseMainGame.exe` und `builds/HanseMapEditor.exe`.

## Erste Simulationsgrenzen

- Ein Simulations-Tag ist der kleinste regulare Wirtschaftstick.
- Preise werden aus Basispreis, Stadtbestand und Zielbestand berechnet.
- Stadtverbrauch besteht aus explizitem Stadt-/Gewerbeverbrauch plus Bedarfen der Einwohnergruppen; diese Logik gilt fuer feste Staedte und exportierte Map-Editor-Staedte.
- Produktions- und Verbrauchswerte laufen pro Tag in der jeweiligen Wareneinheit aus `data/goods.json`.
- `production` steht in den Stadtprofilen fuer lokale Erzeugung plus gesicherten Tageszufluss aus dem direkten Hinterland oder Kontorhandel und wird im Map Editor als `Erzeugung/Zufluss` angezeigt.
- Wasser-/Landnavigation wird aus Natural-Earth-Landpolygonen, Flusslinien und den wassergebundenen Hafenmarkern abgeleitet und im Generator als grobes Raster plus Hafenanker gespeichert.
- Piratenrisiko wird pro Seezone modelliert.
- Seeschlachten starten mit einem Auto-Resolver und koennen spaeter um einen manuellen taktischen Modus erweitert werden.

## Naechste technische Schritte

1. Godot-Import pruefen und Startszene visuell verifizieren.
2. Getrennte Exports fuer Hauptspiel und Map Editor in der Build-Pipeline pruefen.
3. Kauf-/Verkauf-Aktionen an `SimulationState` anbinden.
4. Debug-Ansicht fuer Lager, Tagesverbrauch und Preisentwicklung ergaenzen.
