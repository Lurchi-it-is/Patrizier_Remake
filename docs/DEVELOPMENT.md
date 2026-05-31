# Entwicklung

Version: 0.2.27-production-consumption-coverage

## Branch- und Worktree-Regel

Feature-Arbeit findet in einem eigenen Worktree statt. Aktuelle Feature-Branches folgen dem Praefix:

`codex/`

## Versionierung

Bei Projektanderungen muessen aktualisiert werden:

- `VERSION`
- `project.godot` unter `application/config/version`
- `CHANGELOG.md`
- betroffene Dokumentation mit Versionskopf, sofern vorhanden

## Lokaler Check

```powershell
powershell -ExecutionPolicy Bypass -File tools\validate_project.ps1
```

Der Check prueft:

- JSON-Syntax der Datenkataloge
- Warenreferenzen in Stadtwirtschaft und Einwohnergruppen
- Einheiten-Metadaten je Ware
- Einwohnergruppensummen je Stadt
- regionale Deckung von Erzeugung/Zufluss gegen Verbrauch der festen Startstaedte
- Versionskonsistenz zwischen `VERSION`, `project.godot`, `README.md`, `CHANGELOG.md` und Dokumentation
- Existenz der Godot-Startszene, der getrennten Hauptspiel-/Map-Editor-Szenen und der Windows-Export-Presets

Testanleitungen muessen immer den konkreten Startbefehl fuer die betroffene App oder Szene enthalten.

## Windows-Exports

Die zwei Exe-Dateien werden ueber getrennte Godot-Export-Presets erzeugt:

```powershell
godot --headless --path . --export-release "Windows Main Game" builds\HanseMainGame.exe
godot --headless --path . --export-release "Windows Map Editor" builds\HanseMapEditor.exe
```

Die Presets setzen unterschiedliche Feature-Tags. Der Launcher laedt dadurch beim Hauptspiel `res://scenes/main_game.tscn` und beim Map Editor `res://scenes/map_editor.tscn`.
