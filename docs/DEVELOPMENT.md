# Entwicklung

Version: 0.2.0-foundation

## Branch- und Worktree-Regel

Feature-Arbeit findet in einem eigenen Worktree statt. Der aktuelle Phase-0-Worktree ist:

`codex/phase-0-foundation`

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
- Versionskonsistenz zwischen `VERSION`, `project.godot`, `README.md`, `CHANGELOG.md` und Dokumentation
- Existenz der Godot-Startszene
