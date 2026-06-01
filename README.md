# Hanseatische Warenwirtschaftssimulation

Eigenstaendige Warenwirtschaftssimulation im Hanse-Setting des Spaetmittelalters.

## Status

Version: `0.2.59-route-target-position-overrides`

Das Projektfundament enthaelt:

- Godot-4-Projektdatei und Startszene
- sichtbare Hauptgame-Prototyp-Oberflaeche mit realitaetsnaher Hanseregion-Karte und Dashboard
- handgemalte Hanseregion-Weltkarte mit spielklarer Kuestenlinie, sparsamen Hauptwasserwegen, Waeldern, plausiblen Hochlandzonen und flacher Norddeutscher Tiefebene
- feste Startkarte mit fuenf geladenen Spielstaedten: Bremen, Hamburg, Luebeck, Visby und Danzig
- getrennte Startpunkte und Windows-Export-Presets fuer Hauptspiel und Map Editor
- Karteneditor-Auswahl fuer historische Hanseorte mit scrollbarer Checkbox-Liste und punktgenauer Platzierung auf dem Kartenasset
- Karteneditor-Grundwerte pro Stadt fuer Einwohner, Erzeugung und Verbrauch inklusive JSON-Export
- zoombare und verschiebbare Kartenansicht im Map Editor
- Stadtnamen werden auf der Karte per Mouseover angezeigt
- Stadtpunkte koennen direkt auf der Karte angeklickt und ausgewaehlt werden
- Stadtmarker historischer Wasserhandelsorte sitzen auf sichtbaren Wasserpixeln an Hafen-, Fluss- oder Kuestenzugangspunkten
- zusaetzliche wichtige Kuesten- und Seehandelsorte wie Malmoe, Skanor-Falsterbo, Kalmar, Abo, Viborg, Narva, Elbing, Memel, Aalborg sowie primaere Nordsee-Standorte wie Hull, Boston, King's Lynn, Great Yarmouth, Kampen und Stade
- sinnvolle Defaultwerte fuer Einwohner, Erzeugung und Verbrauch je Hanseort
- erweiterte Hanse-Handelswaren inklusive Stockfisch, Bier, Pech/Teer, Flachs, Wolle, Eisen, Wachs, Pelzen, Wein und Gewuerzen
- historische Spiel-Einheiten je Ware, z.B. Last, Fass, Schiffspfund, Ballen, Timmer und Kiste
- sichtbare Erzeugungs-/Zuflusswerte gegen Tagesverbrauch der festen Startstaedte
- Einwohnergruppen fuer Arme, Handwerker, Buerger und Patrizier mit eigenen Bedarfen und Tagesverbrauch
- sichtbare Einwohnergruppen-Verteilung im Map Editor; Verbrauchswerte werden daraus abgeleitet
- recherchierte, breiter lesbare Wasserwege ohne Laendergrenzen fuer historisch per Fluss, Muendung oder Lagune angelaufene Handelsstaedte
- automatisch erzeugte Navigationsdaten mit Wasser-Raster, Hafenankern und vorberechneten Wasserpfaden fuer sichtbare Schiffsrouten
- kontinuierliche Schiffbewegung mit Reisezeit aus Wasserpfadlaenge und einstellbarer Simulationsgeschwindigkeit
- erste KI-Haendler, die echte Stadtlager kaufen/verkaufen und Balancing-Metriken nach `user://balance_metrics.jsonl` schreiben
- rechte Hauptspiel-Sidebar mit Spieleruebersicht, Kapital und aktiver Schiffsladung
- Handelsfenster zeigt Schiffsbestand, saubere Handelsspalten und den durchschnittlich bezahlten Einkaufspreis je geladener Ware
- Handelsfenster nutzt einen hanseatisch-mittelalterlichen Holz-/Goldstil mit Stadtpanel, Warentabelle, Warendetails, Statusleiste und Mengenwahl fuer 1x/5x/10x/Max
- dokumentierte Designrichtlinie fuer modernes Hanse-UI, Kartenoverlays, Stadtansichten, Schiffe, Waren-Icons, Charaktere, Rangfortschritt und Asset-Pruefung
- transparentes 2.5D-Koggen-Icon als Schiffsasset fuer die Weltkarte inklusive 256px-Token-Version
- zweite, weniger comicartige Koggen-Variante mit gedeckterem, realistischeren Materialstil
- Koggen-Variante mit am Modellfoto orientierter Silhouette: schmales Vorkastell, breiteres Achterkastell
- korrigierte Koggen-Variante mit begehbarer Kastell-Logik und Ruder-Steuer auf dem Achterkastell
- Koggen-Icon ersetzt die bisherigen Schiff-Platzhalter auf der Hauptspiel-Weltkarte
- aus dem GLB-Modell gerenderte Richtungs-Sprites werden direkt in der Weltkarte genutzt, damit Schiffe ohne Auf-den-Kopf-Rotation in Fahrtrichtung wirken
- Warenbestaende und gehandelte Warenmengen werden als ganze Einheiten gefuehrt
- gedaempfte dynamische Preise, damit reine Ueberschusskaeufe keine exorbitanten Arbitragegewinne erzeugen
- dokumentiertes KI-Haendlerkonzept fuer stabilisierenden Warenfluss, Haendlerprofile, Settings und MVP-Umsetzung
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
