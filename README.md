# Hanseatische Warenwirtschaftssimulation

Eigenstaendige Warenwirtschaftssimulation im Hanse-Setting des Spaetmittelalters.

## Status

Version: `0.2.6-foundation`

Das Projektfundament enthaelt:

- Godot-4-Projektdatei und Startszene
- sichtbare Prototyp-Oberflaeche mit realitaetsnaher Hanseregion-Karte und Dashboard
- Karteneditor-Auswahl fuer historische Hanseorte mit scrollbarer Checkbox-Liste und punktgenauer Platzierung auf dem Kartenasset
- datengetriebene Beispielkataloge fuer Waren, Staedte, Schiffstypen und Piratenzonen
- erste Simulationsbausteine fuer Preisbildung, Tages-Tick und Seeschlacht-Auto-Resolver
- lokale Validierung fuer JSON-Daten und Versionskonsistenz

## Start

1. Godot 4.x installieren.
2. Dieses Verzeichnis in Godot importieren.
3. Szene `res://scenes/main.tscn` starten.

## Validierung

```powershell
powershell -ExecutionPolicy Bypass -File tools\validate_project.ps1
```
