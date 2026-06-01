# Designrichtlinie

Version: 0.2.59-route-target-position-overrides

## Zielbild

Das Spiel nutzt ein modernes, gut bedienbares UI mit hanseatisch-mittelalterlicher Material- und Motivsprache. Es soll nicht wie ein historisches Gemaelde wirken, sondern wie ein funktionales Handels- und Seefahrtsspiel, dessen Oberflaeche aus Kontorbuch, Pergament, Hafenschildern, Siegeln, Metallbeschlaegen und Seekarten abgeleitet ist.

Die aktuelle Hanseregion-Karte gibt die visuelle Grundstimmung vor: dunkles Nordmeer, kuehle Tiefen, tuerkis leuchtende Kuesten, moosig-gruene Landflaechen, goldene Hoehen und warme Kuestensaume. UI und Artwork sollen diese Karte ergaenzen, nicht ueberdecken.

## Designprinzipien

- Lesbarkeit vor Dekor, aber nicht vor Atmosphaere. Zahlen, Preise, Lagerbestaende und Risiken muessen sofort erfassbar sein.
- Historische Plausibilitaet statt strenger Rekonstruktion. Kleidung, Schiffe, Gebaeude und Waren duerfen eine romantisierte Spaetmittelalter-Vorstellung bedienen, solange sie glaubwuerdig bleiben.
- Hanse und Handel stehen im Vordergrund. Das UI wirkt zuerst wie Kaufmann, Kontor und Hafenverwaltung; spaetere Rang- und Politiksysteme duerfen mehr Wappen, Siegel, Ratssaal- und Amtsmotive einfuehren.
- Moderne Bedienmuster bleiben erhalten: klare Tabs, Tabellen, Filter, Tooltips, Statusfarben und direkte Rueckmeldung.
- Keine direkte Kopie von `Patrizier`, `Patrician` oder `Mount & Blade: Bannerlord`. Referenzen dienen nur als Stimmungs- und Qualitaetsanker.

## Visuelle Saeulen

### 1. Kontor und Kaufmann

Die Basis-UI ist haendlerisch: Pergamentflaechen, dunkle Tinte, feine Linien, Rechenbuch-Tabellen, Warenstempel, Wachssiegel und schmale Holz- oder Metallrahmen. Dieses Motiv eignet sich fuer Markt, Lager, Routen, Preise, Bilanz, Auftraege und Stadtversorgung.

### 2. Hafen und Seefahrt

Schiffe, Routen, Risiken und Wetter nutzen maritime Motive: Tauwerk, Segeltuch, Messing, Pech, nasses Holz, Kompassrosen, Windpfeile, Bojen, Hafenlaternen und Kartennadeln. Diese Motive sollen sparsam bleiben und Bedienflaechen nicht ueberfrachten.

### 3. Stadt und Rang

Mit hoeherem Rang darf die UI wuerdevoller werden: Siegel, Wappen, Ratsbrief, dunkleres Holz, Messingbeschlaege, Amtsketten, Ratsstuben-Licht, feine Stoffmuster. Der Rangaufstieg soll sichtbar sein, ohne Grundlayouts zu veraendern.

### 4. Gefahr und Krise

Piraterie, Krieg, Hunger, Sturm und Blockaden verwenden rauere Materialien: dunkleres Holz, gebrochene Siegel, kaltes Stahlgrau, rotes Wachs, nasse Kartenkanten, Warnbanner und reduzierte Beleuchtung. Gefahr soll auffallen, aber nicht wie ein Fantasy-Interface wirken.

## Farbpalette

Die Palette soll aus der Karte abgeleitet werden und mehrere Materialfamilien kombinieren.

| Zweck | Farbe | Hex | Einsatz |
| --- | --- | --- | --- |
| Tiefes Nordmeer | Dunkles Petrol | `#06323D` | Kartenwasser, nautische Paneele, dunkle Header |
| Kuestenlicht | Tuerkisgrau | `#2F7E83` | Route-Hover, Wasserzugang, aktive maritime Elemente |
| Landmoos | Olivgruen | `#566531` | positive Stadtversorgung, Agrarwaren, ruhige Akzente |
| Pergament | Warmes Papier | `#D8C38E` | Hauptflaechen fuer Dialoge, Listen und Briefe |
| Altes Pergament | Gedunkeltes Ocker | `#A88949` | Rahmen, Tabs, passive Flaechen, Tabellenlinien |
| Dunkles Holz | Braun-Schwarz | `#2B1D14` | Fensterrahmen, Leisten, Sidebar-Hintergruende |
| Messing | Altes Gold | `#B98A3D` | Rang, Auswahlrahmen, wichtige Buttons |
| Tinte | Fast Schwarz | `#1C1711` | Primaerer Text auf Pergament |
| Kreide | Warmes Elfenbein | `#EFE4C2` | Text auf dunklen Flaechen |
| Siegelrot | Hanserot | `#B8302A` | Stadtmarker, Warnungen, Siegel, kritische Hinweise |

Regeln:

- Rot bleibt ein starker Akzent fuer Stadtmarker, Warnungen, negative Ereignisse und offizielle Siegel.
- Gruen darf nicht als moderne Neon-Erfolgssprache erscheinen; es bleibt gedeckt und natuerlich.
- Gold/Messing markiert Wert, Rang, Auswahl und Autoritaet, nicht jede beliebige Hervorhebung.
- UI-Flaechen duerfen nicht monochrom beige werden. Pergament braucht Kontrast durch Holz, Tinte, Messing, Rot und Petrol.

## Typografie

- Primaere UI-Schrift: gut lesbare moderne Serif oder Humanist Sans mit historischem Ton. Sie muss Zahlen, Tabellen und kleine Labels sauber darstellen.
- Zierschrift nur fuer grosse Titel, Siegel, Kapitelueberschriften, Amtsbriefe und besondere Rangmeldungen.
- Tabellen, Preise und Lagerzahlen verwenden eine sehr klare Schrift mit tabellarischen Ziffern.
- Keine Fraktur als normale UI-Schrift. Sie ist maximal fuer Wappen, Siegel oder dekorative Kapitelmarken geeignet.

Empfehlung:

- UI-Text: moderne Serif oder Humanist Sans, mittlere Strichstaerke.
- Zahlen: gleiche Schriftfamilie mit tabellarischen Ziffern oder separate, sehr klare Zahlenschrift.
- Titel: leicht historisierte Serif, aber nicht schwer lesbar.

## UI-Struktur

Bestehende Fenster, Sidebars, Popups und Dialogplatzierungen duerfen nicht ohne ausdrueckliche Freigabe verlegt, zusammengelegt oder ersetzt werden. Neue Designs muessen daher zuerst innerhalb der vorhandenen Struktur funktionieren.

### Fenster

- Fenster wirken wie aufgeschlagene Kontorunterlagen auf einem stabilen Holz- oder Messingrahmen.
- Titelzeilen sind kompakt und eindeutig: Stadt, Markt, Lager, Schiff, Route, Rat, Auftrag.
- Primaere Aktionen sitzen konsistent unten oder rechts im jeweiligen Fenster.
- Schliessen, Zurueck, Kaufen, Verkaufen, Bestaetigen und Abbrechen muessen immer an erwartbarer Stelle bleiben.

### Sidebars

- Sidebars sind Arbeitsflaechen, keine dekorativen Poster.
- Informationen werden in klaren Gruppen gezeigt: Spieler, Schiff, Ort, Ladung, Warnungen, naechste Aktion.
- Icons duerfen Gruppen markieren, ersetzen aber keine wichtigen Zahlen.

### Tabellen

- Tabellen sind Kernbestandteil des Spiels und duerfen dicht sein.
- Jede Handelstabelle braucht klare Spalten fuer Ware, Stadtbestand, Preis, Schiffsladung, Durchschnittspreis und Aktion, sofern der Kontext sie benoetigt.
- Positive und negative Werte werden farblich und mit Richtungssymbolen unterstuetzt.
- Hover zeigt Erklaerungen: Preisgrund, Lagerreichweite, Bedarf, Produktionsquelle, erwarteter Gewinn.

### Tooltips

- Tooltips sind sachlich und kurz.
- Sie erklaeren Berechnung und Bedeutung, nicht die komplette Spielanleitung.
- Kritische Tooltips duerfen eine zweite Zeile mit Ursache enthalten, z.B. `Preis hoch: Lager reicht nur 3 Tage`.

## Kartenstil

Die Karte bleibt der visuelle Anker des Spiels. Alle darueberliegenden Elemente muessen sich in ihre Perspektive und Farbstimmung einfuegen.

- Stadtmarker bleiben klar sichtbar und nutzen Hanserot mit hellem Rand.
- Namen sind klein, kontrastreich und vermeiden harte schwarze Kaesten, sofern Lesbarkeit anders erreichbar ist.
- Routen sind keine modernen Neonlinien. Sie wirken wie fein gesetzte Seekartenlinien, Kielwasser, Fadenlinien oder Tintenrouten.
- Aktive Route: etwas heller, mit subtiler Bewegung oder Lichtkante.
- Gefaehrliche Route: roter oder dunkler gestrichelter Akzent, nicht vollflaechig.
- Wasserzugang, Hafenanker und Flussanbindung duerfen mit kleinen Hafen-/Ankerzeichen verdeutlicht werden.
- Wetter, Eis, Sturm und Piratenzonen muessen als halbtransparente Layer lesbar bleiben, ohne Landdetails zu verdecken.

## Stadtansichten

Stadtansichten sollen 2.5D oder stilisierte Layerbilder sein: Hafen vorne, Silhouette dahinter, Stadtmauer, Kirchturm, Speicher, Krane, Werft, Markt, Kontor.

Stadttypen:

- Hansestadt: Backstein, Giebelhaeuser, Speicher, Hafenkran, Stadttor, Ratskirche.
- Nordseehafen: flacheres Ufer, Werften, Salzluft, breitere Kaianlagen, dunklere Holzstege.
- Ostseehafen: Backstein, Speicherreihen, schmale Kaianlagen, Hafentore.
- Skandinavischer Hafen: mehr Holzbau, Felsufer, steilere Kuesten, dunklere Nadelwaelder.
- Binnen-/Flussstadt: Flusskai, Bruecken, Lastkaehne, Stadttor nah am Wasser.
- Kontorort: staerker fremde Architekturakzente, aber weiterhin in der gleichen UI-Sprache.

Stadtstatus soll sichtbar sein:

- Wohlstand: mehr Licht, volle Kais, reparierte Daecher, ordentliche Warenstapel.
- Mangel: leere Marktstaende, gedimmte Farben, Warteschlangen, geschlossene Laeden.
- Krise: Warnbanner, Rauch, Soldaten, gesperrte Tore, unruhige Hafenbilder.

## Gebaeude und Betriebe

Gebaeude-Icons und Stadtansichtselemente nutzen eindeutige Silhouetten statt kleinteiliger Detailflut.

- Kontor: Speicherhaus mit Siegel oder Kaufmannszeichen.
- Lagerhaus: breiter Speicher, Faesser/Kisten, Kran.
- Werft: Schiffsrumpf, Geruest, Saege, Pechfass.
- Brauerei: Kupferkessel, Fass, Fachwerk/Backstein.
- Salzsiederei: Pfannenhaus, Rauch, Salzkegel.
- Fischerei: Netze, Tonnen, kleiner Bootssteg.
- Weberei/Tuchmacher: Webrahmen, Ballen, gefaerbte Stoffe.
- Eisen/Schmiede: Amboss, dunkles Metall, Kohlefeuer.
- Rathaus: Backsteinfront, Wappen, Ratssiegel.
- Kirche: Kirchturm als Stadtsilhouette, nicht als dominantes Fantasy-Motiv.

## Schiffe

Schiffe sollen historisch plausibel und sofort unterscheidbar sein.

- Kogge: breiter Rumpf, einzelnes grosses Rahsegel, Kastelle, robust und hanseatisch.
- Holk: groesser, tragfaehiger, spaeterer Handelsschwerpunkt.
- Schnigge/Kleiner Frachter: schneller, kleiner, fuer fruehe Spielphase.
- Fluss-/Kuestenfahrzeug: flacher Tiefgang, fuer Fluss- und Haffzugaenge.
- Bewaffnete Variante: dezente Kastelle, Schilde, Armbrust-/Bogenschuetzen, keine Kanonenoptik als Standard.

Schiffs-UI:

- Zustand: Rumpf, Segel, Besatzung, Moral, Ladung, Bewaffnung.
- Gefahreneinschaetzung: klarer Balken oder Siegelstatus.
- Ladung: Kisten, Faesser, Ballen, Saecke und Metallbarren nach Warenklasse.

## Waren-Icons

Waren-Icons brauchen klare Formen, gedeckte Farben und einheitliche Perspektive. Sie sollen als kleine UI-Icons funktionieren, nicht als Mini-Gemaelde.

- Getreide: gebundene Aehren oder Sack mit Kornmarke.
- Salz: helle Salzkegel oder Salzsack.
- Hering/Stockfisch: Fischsilhouette, Fass oder getrockneter Fisch.
- Bier: Fass mit Zeichen, kein moderner Krug-Fokus.
- Holz: Balkenstapel.
- Pech/Teer: dunkles Fass mit kleinem Glanz.
- Flachs/Wolle: Faserbuendel oder Ballen.
- Eisen: Barren oder Rohklumpen.
- Wachs: gelbliche Barren/Kerzenbuendel.
- Pelze: gerolltes Fell.
- Tuch: farbiger Ballen.
- Wein: Fass mit rotem Siegel.
- Gewuerze: kleine Saeckchen oder Kiste mit farbigen Punkten.

## Charaktere und Portraits

Portraits sind sinnvoll, sollten aber nicht zu frueh verpflichtend werden. Es gibt drei gangbare Richtungen.

### Richtung A: Realistische Charakterportraits

Halbrealistische Brustbilder mit Kleidung, Licht und Materialqualitaet wie in einem modernen Mittelalterspiel. Gute Wahl fuer Rat, Rivalen, Kapitaene und Ereignisse.

Vorteile: hohe Bindung, starke Ereignisse, gute Ranginszenierung.
Risiken: hoher Produktionsaufwand, Stilbrueche bei schlechter Konsistenz.

### Richtung B: Stilisiertes Kontorbuch-Portrait

Reduzierte, tinten- und pergamentartige Portraits mit wenigen Farben, wie Miniaturen in einem Kaufmannsbuch. Moderne Linien, keine echte Buchmalerei.

Vorteile: guenstiger, stimmig zur UI, leichter konsistent.
Risiken: weniger emotional, Gefahr von zu starker Abstraktion.

### Richtung C: Hybrid

Wichtige Personen erhalten halbrealistische Portraits; generische Haendler, Kapitaene und Beamte nutzen stilisierte Kontorbuch-Portraits oder Silhouetten.

Empfehlung: Hybrid. Damit koennen zentrale Rivalen, Ratsmitglieder und Karriereereignisse stark wirken, waehrend die vielen Systempersonen bezahlbar und konsistent bleiben.

Charakterregeln:

- Kleidung orientiert sich grob am spaeten Mittelalter: Wollstoffe, Leinen, Pelzbesatz, Guertel, Hauben, Kappen, schlichte Schmuckstuecke.
- Reiche Figuren tragen bessere Stoffe und sauberere Farben, aber keine uebertriebene Fantasy-Ruestung.
- Kapitaene wirken wettergegerbt, praktisch gekleidet, mit Leder, Wolle und Seetuch.
- Ratsherren wirken ruhiger, schwerer, wuerdevoller: dunkle Stoffe, Siegelring, Pelzbesatz, Amtsketten.
- Piraten wirken gefaehrlich und pragmatisch, nicht wie karibische Piraten.

## Rang- und Fortschrittssystem

Der Fortschritt von Kaufmann zu einflussreicher Stadt- und Hansefigur soll visuell wachsen, ohne die Bedienung neu zu erfinden.

Rangstufen koennen ueber folgende Elemente sichtbar werden:

- Frueh: einfache Pergamentbriefe, schlichte Holzrahmen, wenige Siegel.
- Mittel: besseres Kontor, Messingakzente, eigenes Kaufmannszeichen, mehr Amtsdokumente.
- Hoch: Wappen, Ratsbrief, dunkles Edelholz, rote Wachssiegel, repraesentative Stadt- und Ratsmotive.
- Spitze: Hanseatische Autoritaet, offizielle Siegel, Ratsstube, grossere Wappenflaechen, aber weiterhin klare Tabellen und Funktionen.

Wichtig: Rangaufstieg aendert Ornamentik, Titel, Siegel und Prestigeanzeigen; er darf keine vertrauten Kernfunktionen verstecken.

## Buttons, Icons und Statussprache

- Primaeraktion: Messing/Gold auf dunklem Holz oder kraeftiger Pergamentflaeche.
- Sekundaeraktion: dunkle Tinte auf Pergament, dezenter Rahmen.
- Destruktiv/Gefahr: Hanserot, aber sparsam.
- Deaktiviert: ausgebleichtes Pergament, reduzierte Tinte, klarer Tooltip mit Grund.
- Ausgewaehlt: heller Messingrahmen oder kleines Siegel, nicht nur Farbwechsel.

Iconstil:

- einheitliche Strichstaerke oder einheitlicher gerenderter Stil.
- klare Silhouetten bei 16 bis 24 px.
- keine modernen Clipart- oder Emoji-Anmutungen.
- keine ueberladenen Ornamenticons fuer Standardaktionen.

## Animation und Feedback

Animationen sollen ruhig und funktional sein.

- Schiffbewegung: gleichmaessig, mit kleinem Kielwasser oder Segelimpuls.
- Handel: kurzer Wert-Impuls bei Geld, Ladung und Stadtbestand.
- Preisveraenderung: dezenter Pfeil, kein lauter Arcade-Effekt.
- Warnung: Siegel-/Bannerimpuls, kurze rote Markierung, danach ruhiger Status.
- Rangaufstieg: feierlicher, aber kurzer Moment mit Siegel, Brief, Glocke oder Ratsbanner.

## Sound- und Musikrichtung

Die Audiowelt soll Handel, Hafen und Nordmeer tragen.

- UI: Papier, Feder, Siegelwachs, Holz, Metallbeschlag, Muenzklang.
- Hafen: Moewen nur sparsam, Wasser, Tauwerk, Schritte auf Holz, entfernte Stimmen, Karren.
- Gefahr: Wind, Segelspannung, dumpfe Trommel, Metall, Alarmglocke.
- Musik: ruhige spaetmittelalterlich inspirierte Motive mit Laute, Drehleier, Floete, Trommel und Streichern, aber modern gemischt und nicht museal.

## Do / Do Not

Do:

- Pergament und Holz als Arbeitsmaterialien nutzen.
- Tabellen und Werte klarer machen als Dekor.
- Karte, UI und Icons farblich aufeinander abstimmen.
- Historisch plausible Formen bevorzugen.
- Fortschritt ueber Rang, Siegel, Materialqualitaet und Wappen sichtbar machen.

Do Not:

- UI wie ein Gemaelde oder eine Fantasy-Rollenspielkulisse behandeln.
- Fraktur oder Ornamentik fuer normale Bedienung verwenden.
- Neonfarben, moderne Glasoptik oder Sci-Fi-HUD-Elemente einsetzen.
- Piraten karibisch darstellen.
- Bestehende Fenster-/Sidebar-Strukturen ohne Freigabe verlegen.
- Original-Assets, exakte Layouts oder geschuetzte Gestaltung aus Referenzspielen kopieren.

## Asset-Checkliste

Jedes neue Asset soll vor Einbau diese Fragen bestehen:

- Passt es zur Karte in Helligkeit, Saettigung und Materialgefuehl?
- Ist es bei Zielgroesse im 16:9-Spielbild lesbar?
- Ist die Funktion innerhalb von einer Sekunde erkennbar?
- Verwendet es die zentrale Palette oder eine bewusst begruendete Erweiterung?
- Ist es historisch plausibel fuer ein romantisiertes spaetmittelalterliches Hanse-Setting?
- Stoert es keine bestehenden UI-Strukturen?
- Gibt es einen Tooltip oder eine Beschriftung, falls Bedeutung nicht eindeutig ist?

## Empfohlene naechste Schritte

1. UI-Style-Tokens fuer Farben, Textgroessen, Abstaende, Rahmen und Statusfarben in Godot zentralisieren.
2. Bestehendes Handelsfenster gegen diese Richtlinie pruefen und nur innerhalb seiner aktuellen Struktur angleichen.
3. Waren-Iconset als erstes konsistentes Assetpaket definieren.
4. Zwei Portrait-Prototypen erstellen: ein halbrealistischer Ratsherr und ein stilisiertes Kontorbuch-Portrait.
5. Rangvisualisierung fuer die ersten drei Stufen skizzieren: einfacher Kaufmann, etablierter Haendler, Ratsherr.
