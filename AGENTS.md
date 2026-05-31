# AGENTS.md

## Repository

Dieses Projekt gehoert verbindlich zu folgendem GitHub-Repository:

https://github.com/Lurchi-it-is/Patrizier_Remake.git

Es muss immer in diesem Repository gearbeitet werden.

## Projektkontext

- Der Map Editor ist nur ein Feature des Spiels, um Custom-Karten zu erzeugen.
- Das Hauptspiel und der Map Editor muessen als zwei getrennte Exe-Dateien ausgeliefert werden.

## Arbeitsregeln

- Wenn eine neue Feature-Entwicklung angefragt wird, muss dafuer ein eigener Worktree erstellt werden.
- Nach Fertigstellung und Freigabe eines Features wird der Worktree in `origin/main` in der Cloud gemerged und anschliessend geloescht.
- Nach jeder Implementierung muss vor `push` und Loeschen des Worktrees eine Freigabe eingeholt werden. Dafuer wird eine kurze Zusammenfassung der Aenderungen bereitgestellt.
- Es darf nicht mehr als ein Worktree gleichzeitig betrieben werden.
- Zusammenhaengende Features duerfen im selben Worktree entwickelt werden.
- Bei Aenderungen am Projekt muss die Versionsnummer immer dokumentiert und gepflegt werden.
- Nach jedem abgeschlossenen Implementierungsschritt muss eine kurze Testanleitung bereitgestellt werden, inklusive konkret ausfuehrbarer Befehle und erwarteter Pruefpunkte.
