# Architektur

Version: 0.2.0-foundation

## Leitidee

Die Wirtschaftssimulation soll datengetrieben und testbar bleiben. Godot rendert UI, Karte und Interaktion; Waren, Staedte, Schiffe, Preise und Piratenrisiken werden als Daten modelliert.

## Module

- `data/`: JSON-Kataloge fuer Balancing und historische Spielwerte.
- `scripts/data/`: Laden und Validieren der Kataloge zur Laufzeit.
- `scripts/simulation/`: Engine-nahe, aber UI-unabhaengige Simulationslogik.
- `scenes/`: Godot-Szenen fuer Einstieg, Karte und spaetere UI.
- `tools/`: lokale Validierung und Projektpflege.

## Erste Simulationsgrenzen

- Ein Simulations-Tag ist der kleinste regulare Wirtschaftstick.
- Preise werden aus Basispreis, Stadtbestand und Zielbestand berechnet.
- Piratenrisiko wird pro Seezone modelliert.
- Seeschlachten starten mit einem Auto-Resolver und koennen spaeter um einen manuellen taktischen Modus erweitert werden.

## Naechste technische Schritte

1. Godot-Import pruefen und Startszene visuell verifizieren.
2. Erste Karte mit drei Staedten und Route bauen.
3. Kauf-/Verkauf-Aktionen an `SimulationState` anbinden.
4. Debug-Ansicht fuer Lager, Tagesverbrauch und Preisentwicklung ergaenzen.
