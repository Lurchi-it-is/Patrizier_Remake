# Hanse-Wirtschaftsbalancing

Version: 0.2.50-tempered-price-signals

## Recherchebasis

Die Warenliste ist eine spielbare Verdichtung typischer Hansehandelswaren. Historische Quellen nennen fuer den Ostseeraum und die Hanse besonders Getreide, Holz, Pech/Teer, Flachs/Hanf, Wachs, Honig, Felle/Pelze, Salz, Hering/Fisch, Tuch, Metalle, Bier, Wein und Gewuerze. Daraus entstehen im Spiel die Waren:

- Grundversorgung: Getreide, Salz, Hering, Stockfisch, Bier
- Bau, Schiffbau und Gewerbe: Holz, Pech und Teer, Flachs, Wolle, Eisen, Wachs
- Wohlstand und Fernhandel: Pelze, Tuch, Wein, Gewuerze

## Wareneinheiten

Alle Produktions-, Verbrauchs-, Lager- und Zielbestandswerte sind Tageswerte in der jeweiligen Wareneinheit. Die historischen Masse waren regional unterschiedlich; die Simulation nutzt deshalb gerundete Spiel-Einheiten:

- Getreide: Last Getreide, etwa 2000 kg.
- Salz: Salzfass, etwa 201,5 l Fassvolumen.
- Hering: Heringsfass, etwa 1000 Heringe.
- Stockfisch, Flachs, Eisen und Wachs: Schiffspfund, grob 150 kg.
- Bier, Wein und Pech/Teer: Fass, grob 120 l.
- Holz: Fuder Bauholz, grob 1000 kg.
- Wolle und Tuch: Ballen, grob 100 bis 150 kg.
- Pelze: Timmer, 40 Felle.
- Gewuerze: Kiste, grob 25 kg.

Die groesseren Einheiten machen kleine Dezimalwerte bei hochwertigen oder schweren Waren plausibler: Eine Produktion von `0.5` Wachs bedeutet kein halbes Stueck, sondern etwa ein halbes Schiffspfund pro Tag. Stadtlager bleiben im Spiel ganzzahlig; solche Tagesbruchteile werden intern gesammelt, bis sie eine ganze Lagereinheit erzeugen oder verbrauchen.

`production` wird im Balancing als lokale Erzeugung plus gesicherter Tageszufluss aus direktem Hinterland oder Kontorhandel verstanden. Im Map Editor wird das deshalb als `Erzeugung/Zufluss` angezeigt. Dadurch koennen Getreide in Luebeck oder reine Importwaren wie Wein, Gewuerze, Stockfisch oder Pelze in Hafenstaedten als Zufluss erscheinen, ohne dass sie dort lokal angebaut oder gefangen werden.

## Preisbalancing

Die aktuelle Preislogik orientiert sich spielmechanisch an klassischen Hanse-Handelsspielen, ohne deren konkrete Formeln zu kopieren:

- Stadtpreise werden aus Basispreis, Warengruppe, Bestand, Zielbestand und Tagesverbrauch als Lagerreichweite berechnet.
- Kaufpreis und Verkaufspreis sind getrennt. Die Stadt verkauft Waren mit Aufschlag und kauft Waren mit Abschlag.
- Groessere Transaktionen werden als Durchschnitt ueber die Bestandsveraenderung abgerechnet. Eine grosse Kaufmenge verteuert sich dadurch schrittweise, weil der Stadtbestand sinkt; eine grosse Verkaufsmenge wird schrittweise schlechter bezahlt, weil der Stadtbestand steigt.
- Grundversorgung bleibt mengenstark mit kleiner Marge. Luxuswaren koennen groessere Ausschlaege haben, werden aber bewusst gedaempft, damit Stadtunterschiede Hinweise statt eindeutige Gewinnanweisungen sind.
- Die Validierung prueft, dass Startpreise positiv sind, Kaufpreise ueber Verkaufspreisen liegen und die Startpreisstreuung nicht ausserhalb des Balancingrahmens liegt.

Historisch bleiben reale Preise nur grobe Orientierung: regionale Masse, Muenzwerte und Quellenlage schwanken stark. Fuer das Spiel wichtiger ist die relative Ordnung: Getreide, Bier, Holz und Hering als Massenwaren; Salz, Eisen, Wachs, Tuch, Wein, Pelze und Gewuerze als staerker entfernung-, import- oder wohlstandsgetriebene Gueter.

Quellen:

- Britannica, Hanseatic League: https://www.britannica.com/topic/Hanseatic-League
- Hanse.org, The origins: https://www.hanse.org/en/the-medieval-hanseatic-league/the-origins
- Kalmar Laens Museum, Trade and merchandise: https://medeltiden.kalmarlansmuseum.se/en/society/the-hanseatic-league/trade-and-merchandise/
- Encyclopedia.com, Hanseatic League: https://www.encyclopedia.com/history/encyclopedias-almanacs-transcripts-and-maps/hanseatic-league
- Patrician 3 Manual, dynamische Marktpreise und Stadtversorgung: https://cdn.akamai.steamstatic.com/steam/apps/33570/manuals/manual-patrician3.pdf
- P3 Modding, rekonstruierte Preis- und Bestandsschwellenlogik als spielmechanische Referenz: https://p3modding.github.io/towns/ware-prices/buying-price.html
- Luebeck Hanseschiff-Blog, Lueneburger Salzfass-Masse: https://www.luebeck.de/de/stadtleben/kultur/archaeologie-und-denkmalpflege/archaeologie/hanseschiff/bergungslogbuch/en/18-07-2025-salzfass.html
- Sizes.com, Last als historische Schuettgut-/Frachtmasseinheit: https://www.sizes.com/units/last.htm
- Sizes.com, Heringsfass: https://www.sizes.com/units/barrel_herring.htm
- Sizes.com, Schiffspfund: https://www.sizes.com/units/Schiffspfund.htm
- Sizes.com, Timmer als Pelzzaehlmass: https://www.sizes.com/units/timber.htm
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
- regionale Deckung der festen Startkarte: jede verbrauchte Ware muss durch Produktion/Zufluss mindestens gedeckt sein
