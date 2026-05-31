# Architektur

Version: 0.2.8-separated-executables

## Leitidee

Die Wirtschaftssimulation soll datengetrieben und testbar bleiben. Godot rendert UI, Karte und Interaktion; Waren, Staedte, Schiffe, Preise und Piratenrisiken werden als Daten modelliert.

## Module

- `data/`: JSON-Kataloge fuer Balancing, historische Spielwerte und Karteneditor-Orte.
- `scripts/data/`: Laden und Validieren der Kataloge zur Laufzeit.
- `scripts/simulation/`: Engine-nahe, aber UI-unabhaengige Simulationslogik.
- `scripts/ui/`: Prototyp-Visualisierung fuer realitaetsnahes Karten-Asset, feste Hauptgame-Staedte, Karteneditor-Punkte, Piratenrisiko und Status.
- `assets/maps/`: generierte neutrale Hanseregion-Karte mit Metadaten fuer spaetere source-pixelgenaue Overlays.
- `scenes/`: Godot-Szenen fuer Einstieg, Karte und spaetere UI.
- `tools/`: lokale Validierung und Projektpflege.

## Build-Ziele

- Das Hauptspiel und der Map Editor werden als getrennte Exe-Dateien ausgeliefert.
- Das Hauptspiel startet in die regulare Handels- und Wirtschaftssimulation.
- Der Map Editor startet direkt in die Custom-Karten-Erstellung und bleibt als eigenstaendiges Tool vom Hauptspiel-Build getrennt.
- `scenes/launcher.tscn` ist der technische Godot-Projektstart und waehlt anhand des Export-Feature-Tags `main_game` oder `map_editor` die eigentliche Einstiegsszene.
- `scenes/main_game.tscn` nutzt `scripts/main_game.gd`; `scenes/map_editor.tscn` nutzt `scripts/map_editor.gd`.
- `export_presets.cfg` definiert die Windows-Ziele `builds/HanseMainGame.exe` und `builds/HanseMapEditor.exe`.

## Erste Simulationsgrenzen

- Ein Simulations-Tag ist der kleinste regulare Wirtschaftstick.
- Preise werden aus Basispreis, Stadtbestand und Zielbestand berechnet.
- Piratenrisiko wird pro Seezone modelliert.
- Seeschlachten starten mit einem Auto-Resolver und koennen spaeter um einen manuellen taktischen Modus erweitert werden.

## Naechste technische Schritte

1. Godot-Import pruefen und Startszene visuell verifizieren.
2. Getrennte Exports fuer Hauptspiel und Map Editor in der Build-Pipeline pruefen.
3. Kauf-/Verkauf-Aktionen an `SimulationState` anbinden.
4. Debug-Ansicht fuer Lager, Tagesverbrauch und Preisentwicklung ergaenzen.
