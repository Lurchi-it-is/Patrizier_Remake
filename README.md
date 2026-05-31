# Hanseatische Warenwirtschaftssimulation

Eigenstaendige Warenwirtschaftssimulation im Hanse-Setting des Spaetmittelalters.

## Status

Version: `0.2.8-separated-executables`

Das Projektfundament enthaelt:

- Godot-4-Projektdatei und Startszene
- sichtbare Hauptgame-Prototyp-Oberflaeche mit realitaetsnaher Hanseregion-Karte und Dashboard
- feste Startkarte mit fuenf geladenen Spielstaedten: Bremen, Hamburg, Luebeck, Visby und Danzig
- getrennte Startpunkte und Windows-Export-Presets fuer Hauptspiel und Map Editor
- Karteneditor-Auswahl fuer historische Hanseorte mit scrollbarer Checkbox-Liste und punktgenauer Platzierung auf dem Kartenasset
- datengetriebene Beispielkataloge fuer Waren, Staedte, Schiffstypen und Piratenzonen
- erste Simulationsbausteine fuer Preisbildung, Tages-Tick und Seeschlacht-Auto-Resolver
- lokale Validierung fuer JSON-Daten und Versionskonsistenz

## Start

1. Godot 4.x installieren.
2. Dieses Verzeichnis in Godot importieren.
3. Projekt starten. Der Launcher laedt standardmaessig `res://scenes/main_game.tscn`.

## Build-Ziele

- Hauptspiel: `builds/HanseMainGame.exe`
- Map Editor: `builds/HanseMapEditor.exe`

## Validierung

```powershell
powershell -ExecutionPolicy Bypass -File tools\validate_project.ps1
```
