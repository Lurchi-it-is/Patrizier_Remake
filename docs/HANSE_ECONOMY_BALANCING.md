# Hanse-Wirtschaftsbalancing

Version: 0.2.24-map-editor-population-groups

## Recherchebasis

Die Warenliste ist eine spielbare Verdichtung typischer Hansehandelswaren. Historische Quellen nennen fuer den Ostseeraum und die Hanse besonders Getreide, Holz, Pech/Teer, Flachs/Hanf, Wachs, Honig, Felle/Pelze, Salz, Hering/Fisch, Tuch, Metalle, Bier, Wein und Gewuerze. Daraus entstehen im Spiel die Waren:

- Grundversorgung: Getreide, Salz, Hering, Stockfisch, Bier
- Bau, Schiffbau und Gewerbe: Holz, Pech und Teer, Flachs, Wolle, Eisen, Wachs
- Wohlstand und Fernhandel: Pelze, Tuch, Wein, Gewuerze

Quellen:

- Britannica, Hanseatic League: https://www.britannica.com/topic/Hanseatic-League
- Hanse.org, The origins: https://www.hanse.org/en/the-medieval-hanseatic-league/the-origins
- Kalmar Laens Museum, Trade and merchandise: https://medeltiden.kalmarlansmuseum.se/en/society/the-hanseatic-league/trade-and-merchandise/
- Encyclopedia.com, Hanseatic League: https://www.encyclopedia.com/history/encyclopedias-almanacs-transcripts-and-maps/hanseatic-league
- ZPE, Inhabitants of medieval cities: https://zpe.gov.pl/a/inhabitants-of-medieval-cities/DdLIQ3ljf
- Encyclopedia.com, Patricians and Artisans: https://www.encyclopedia.com/history/news-wires-white-papers-and-books/patricians-and-artisans

## Einwohnergruppen

Die Simulation unterscheidet vier Stadtgruppen. Die Werte sind bewusst grobe Tagesraten pro 1000 Einwohner, damit die Wirtschaft in Spieltagen balancierbar bleibt und trotzdem plausible Prioritaeten zeigt.

- Arme und Tageloehner: hoher Anteil an Getreide, Hering, Salz und einfachem Bier.
- Handwerker und Gesellen: Grundnahrung plus Tuch, Holz und Eisen fuer Haushalt und Werkstatt.
- Buerger und Kaufleute: mehr Bier, Tuch, Wein, Wachs und kleine Gewuerzmengen.
- Patrizier und Reiche: ueberproportionaler Bedarf an Tuch, Wein, Wachs, Pelzen und Gewuerzen.

Der Map Editor nutzt typische Verteilungen nach Stadttyp:

- Kernstadt: 40 Prozent Arme, 35 Prozent Handwerker, 20 Prozent Buerger, 5 Prozent Patrizier.
- Kontor: 35 Prozent Arme, 25 Prozent Handwerker, 30 Prozent Buerger, 10 Prozent Patrizier.
- Hansestadt: 48 Prozent Arme, 35 Prozent Handwerker, 14 Prozent Buerger, 3 Prozent Patrizier.
- Handelsort: 55 Prozent Arme, 30 Prozent Handwerker, 13 Prozent Buerger, 2 Prozent Patrizier.

## Stadtprofile

- Luebeck: Salz- und Umschlagsschwerpunkt mit Bier, Tuch und Schiffbaumaterial; konsumiert viele Import- und Gewerbewaren.
- Hamburg: Getreide- und Bierprofil mit Elbhandel; braucht Salz, Fisch, Textilrohstoffe und Metall.
- Bremen: Getreide, Bier, Wolle und Tuch aus Nordsee-/Weserhandel; moderater Importbedarf bei Salz und Fisch.
- Visby: Ostseeinsel mit Hering, Holz, Pech/Teer und Wachs; hoher Importbedarf bei Getreide und Salz.
- Danzig: starker Export von Getreide, Holz, Flachs, Pech/Teer und Wachs; importiert Salz, Fisch, Tuch, Wein und Metall.

Die Validierung prueft je Stadt:

- alle Warenreferenzen gegen `data/goods.json`
- alle Einwohnergruppen gegen `data/population_groups.json`
- Summe der Einwohnergruppen gegen `population`
- Zielbestaende fuer alle verbrauchten Waren inklusive gruppenbasiertem Verbrauch
