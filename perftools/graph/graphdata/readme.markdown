Plot a data file with performance data as automatically as possible.

<link href="http://kevinburke.bitbucket.org/markdowncss/markdown.css" rel="stylesheet"></link>

Graphdata
=========

Goal
----
Plot a data file with performance data as automatically as possible.

Linux
-----
Make an alias in your ~/.bashrc:
alias graphdata='~/perftoolset/tools/graphdata/graphdata.tcl'

Windows
-------
4NT: alias graphdata tclsh c:\perftoolset\tools\graphdata\graphdata.tcl

TODO
====
* std graph: min, avg, max: nu nog met plot, wil ook met qplot/ggplot2.
* Nog andere filters om helemaal geen grafiek te tonen, als bv Process Processor Time niet boven de 5 of 10 uitkomt.
* Ergens start- en eindtijdstip van de graphs meegeven: cmdline naar tcl, dan ook naar R, of opslaan in een DB, uitlezen in R. Dan ook de queries en andere defs hierin (aantal points), zodat je
  op cmdline naar R alleen de db naam en de graphdef hoeft op te geven.
* det_timestamp_format_value: onderscheid tussen dd/mm en mm/dd bepalen. In typeperf komt eerst de mm. Uiteraard kun je ook eerst preprocessen, maar dit is juist niet de bedoeling.
* Perf: importing data on windows is a factor 10 slower than on linux. 
* R: source-function: have function which reads the spec-ed file from script-dir, not current dir. Put this in first.R? or in a package?
* typeperf: als geen meting, dan veelal een -1. Als graph flatline is en paar keer -1, is het ook niet boeiend.
* als extensie .txt is, dus niet sep te bepalen, dan eerste regel met data lezen en aantal tabs, komma's en puntkomma's tellen. Waar je de meeste van hebt, heeft gewonnen.
* compare to filter-column: give a re-param, and make (also) a graph with only the labels that satisfy the pattern. Maybe give a list of patterns, or put them in a file.
* Maybe something in between showing al columns and only showing one. It could be 'randomly' split into 5 or 10 columns each, still scaled.
* Add helper lines (horizontal), or combine this with 'tufte' graph format.
* TK/VLOS/Verslaglegging: upload max van 6 seconden niet getoond, wel als maxwaarde in graph. Als er weinig datapunten zijn, dan alle tonen.
* datetime format for plot: determine relevant pieces: only date and hour if the diff is more than a few days, only the time if all on the same day.
* sqlite bulk insert, bij ongeveer 1200 kolommen nu ongeveer 100 rijen per 2 seconden ge-insert. Is eigenlijk nog best snel.
* Als er maar 1 COL wordt getoond: naast de mean (avg) ook de min en vooral max tonen. Max wordt wel voor de as gebruikt, soms hier geen waarden in de buurt.
* Soort rule base engine gebruiken om obv graph title en waarden te bepalen of dit een spannende is, of evt ook een std graph die je altijd moet gebruiken. 
  Bv CPU als het gemiddeld boven de 50% is, of als de 90% boven de 80% is. Voor disk en netwerk verder naar aantal bytes kijken, melden als bv meer dan 1 MB/sec. 
* groeperen: ofwel per resoure (cpu, disk) en dan alle waarden hiervan, ofwel een meetwaarde (bv queue-length) van een groep van gelijke resources. Misschien in orig sitescope data
  wel te bepalen welk type resource het is, met info uit de def file.
* Met Sitescope vaak dezelfde typen resource meten, met dezelfde naamgeving. Hieruit wel rules te bepalen wat boeiend is. Even onderscheid tussen zeker boeiend, zeker niet boeiend en er tussenin.
* Heb nu bij 1 datakolom ook min en max waarden erbij, samen met mean (avg) dan 3 'lijnen'. Vraag of je dit altijd wilt, bij spannende graphs beide versies bekijken. Voor analyse wel handig, maar
  in rapport misschien te moeilijk, maar dan soms ook alleen max presenteren ipv mean.
* Kan ook een paar graphs in een grid tonen, niet per se meerdere lijnen in 1 graph: dan wat kleinere graphs, evt op doorklikken om groter te maken.
* Test: weer even ggplot2 gebruiken: ziet het er echt veel beter uit? En bv tijd-as met ronde tijden? en legenda beter, zonder negatieve y-as?
* Eerst: Gebruik graphdata/R voor analyse, maar LR analyser voor grafieken, toch wel mooi.
* Warnings in R: heb >50 warnings op min() functie, maar nu wel overal na.rm=TRUE gedaan, krijg de warnings ook ineens, niet duidelijk bij welke call, nog eens interactief uitvoeren. Maar als ik met
  ggplot ga werken, dan misschien wel helemaal weg, dus prio laag nu.
* Warnings ggplot: Loading required package: plyr en Attaching package: 'reshape'. Misschien te vermijden door packages hardcoded te laden, met silent=TRUE.
* Check doHtml graphs: do I have/want all of them with R/ggplot?

TODO Activity Log
=================
* Deze data ook hierin lezen, dan ander script om graph vgl IND te plotten, zie todo in deze dir? Dit is wel een specifieke graph, niet direct met gnuplot of R te doen, specifiek
  met arrows in gnuplot. Arrows ook laatst nog gebruikt voor TK-VLOS.
* 14-9-2011 eerste opzetje van horizontale lijnen gemaakt, werkt goed. Dan kleuren, verdelen in groepen (volgens make-report), lijnen voor windows, punten voor file-access.
* Per groep: specifieke title ook zichtbaar: verschillende kleur, hoogte. Want steeds wisselen duidt op activiteit, lange tijd hetzelfde op lezen of elders bezig zijn.

Multi graph
===========
* ipv scaling/meerdere lijnen: meerdere grafieken boven elkaar met zelfde x-as maar dus andere y-as.
* Iets met transform(eu, time=time(...))
* Of iets met facets.
* Learning R blog: goede artikelen.
* Met ggplot2 kan dit blijkbaar wel.

ggplot
======
* first 1 column, rename the R file to ...-1col
* Now have min, avg, max in 3 colours, maybe a box/whiskers is better?
* Then the multi-column, just means.
* Filter out non-numeric columns (eg sar data)
* Als tijdframe kort genoeg is (-start en -end), dan zijn er ook punten genoeg, en zijn min,max en avg gelijk. De std grafiek voldoet dan wel, dan min/max niet meer nodig.
  Kan dus checken of er meer waarnemingen dan maxpoints zijn, en hiermee een keus voor de soort grafiek maken. Evt wel zorgen dat deze default keuze aangepast kan worden of 
  allebei maken.
* geom() for other things than scatterplots. geom = "boxplot" produces a box-and-whisker plot to summarise the distribution of a set of points, § 2.5.2.

Windows
=======
* Perf van inlezen is factor 10 trager dan op linux, hoe kan dit en kan het beter, bv met batch insert? CPU is niet druk.
* BEGIN TRANSACTION lijkt te helpen, wordt op linux nog sneller.
* Eerst in een TEMPORARY table kan helpen, dan geen journal file aangemaakt.
* Of db copy replace values temp_file

TODO YMonitor Ericsson data
===========================
* Zijn veel melted tabellen, kijken of ik dit meteen met ggplot wil printen, of met queries in oorspronkelijk formaat wil doen.
* Graphs: defs opslaan in tabellen, maar ook stukjes hiervan: from/to timestamp, aantal lijnen combineren, losse lijnen def, melted data als lijnen def-en.
* Graphs: soort vgl LR Analysis: lijnen aan en uit kunnen zetten, timeframe def-en.
* Graphs: hier weer de vraag: zijn er interactieve tools?
* Melted data: hiermee aantal grafieken maken, met elke combi van bronwaardes 1, bv sentinel+transactie.

Loadrunner data
===============
* Kan wel ook transdata en user data points eerst omzetten naar een tsv in hetzelfde formaat als sitescope data, maar mis dan wel info.
* Beter misschien om de data as-is naar een data.db om te zetten en dan een andere query naar graph-sqlite.R te sturen, of zelfs een andere R-file.
* Want anders in Tcl allerlei 'queries' te maken, wat veel beter in SQL kan.
* Voorbeelden zijn dingen van biomet: aantallen transacties per tijd (group by, count), alleen login-tijden (where clause), per loadgenerator (andere kolom, platslaan).
* Nog steeds wel probleem om data te combineren van verschillende databases/files.
* Vraag of je elapsed-time (in sec/msec) in de raw-data om wilt zetten naar wallclocktime, of evt een extra veld erbij.
* Rawdata vaak ook niet gesorteerd op tijd, maar maakt niet zo veel uit, order by gebruiken, evt index toevoegen.
* Als ik import van data naar sqlite toch los wil trekken, kan ik dit ook voor sitescope/std data doen. Dan mogelijkheid om dbnaam, datatabel en legendtabel op te geven.
  Of evt te checken of tabel al bestaat, en dan een nieuwe te kiezen. Zijn ook niet heel veel tabellen, dus een simpel volgnummer lijkt genoeg. Speciale LR tabellen dan ook een speciale naam
  geven.
* In theorie vervolgens een query op te geven die over meerdere tabellen gaat. Een voorbeeld:
  * Wil aantal LR transacties per minuut uitzetten tegen userdatapoint 60 / interval, evt ook alleen de markeren-transacties
  
  * Wil DB connecties en/of conn/sec uitzetten tegen #LR trans.
  * Dit soort dingen kan te combineren zijn in een query, maar misschien wel zo gemakkelijk meerdere queries/dataframes in een grafiek te zetten. Met lines-cmd toch steeds opnieuw
    de x-as en y-as op te geven. Wel moeilijker dit via de cmdline op te geven dan, specs moeten dan in een file staan, of in een metatabel in dezelfde DB? Ook vraag wat dan met scaling te doen.
    Met een enkele query gaat dit nu al automatisch.
  * Maar dan vraag hoe zo'n query er uit moet zien, kan het met een union en sort?
  
Stel tabel1: timestamp, val1 waarbij col1 de conn/secs op de DB is.
Stel tabel2: timestamp, val1 waarbij val1 de interval is, wil frequentie ofwel 60/interval

select timestamp, val1 conns_sec, '' freq
from tabel1
union
select timestamp, '' conns_sec, 60 / val1 freq
from tabel2
order by timestamp

in legend tabel (enkele tabel, verwijzing naar data-tabel?) een record voor freq opnemen en deze in de legend-query mee-selecteren, naast timestamp en conns_sec

maak tabel3 obv tabel1 met het totale aantal LR transacties per seconde, kijk naar de eindtijd/elapsed van de transactie:

insert into tabel3 (timestamp, tr_count)
select timestamp, count(elapsed)
from tabel1
group by timestamp

hier ook entries in legend-tabel voor maken, dit is een soort meta-tabel. Andere meta-tabellen later om grafieken in vast te houden, deze evt via een web of andere interface te beheren.

 
    

Done
====
* Handle pkts.tsv
* Put graphs in new subdir
* Auto-show with eog/irfanview
* Handle (current) directory.
* db-req-time: scaled and unscaled: nu fout: geen melding meer in R, maar er wordt een lege graph getoond, interactief proberen. 21-7-2011 werkt nu ineens wel...
* db-req-time: shorten legend-labels
* For unscaled graph with more than 1 column: take the max-value of all columns, not just the second one.
* Handle SAP-Resptime.tsv - it has too many columns for R. split-columns integrated.
* Make work first on linux, than windows.
* Auto-show with irfanview (eog done)
* [2011-08-04 22:15:02] graph-scale.R en graph-noscale.R integreren, veel overlappende code.
* [2011-08-04 22:15:20] completed reading data into a sqlite file and making graphs from this sqldata. No intermediary files (split) needed anymore. 
* [2011-09-03 22:35:32] can also read YMonitor raw data, converted from excel to csv/tsv: other timestamp format, csv with text, timestamp not as first column.

Design choices
==============
* give sepchar as param to R, or always make a new datafile as TSV, and make graph based on this.
  - always make new datafile.
* also for date time format: give as param or always make the most of it:
  - as a param for this one.
  
Ander graph package
===================
* Zoals Clojure/Incanter of Python/?
* Eisen aan graphing:
** multiline met tekens en kleuren
** x-as als timeline
** legend op een goede plek (beter dan in R?). Of lange legend als aparte file (text of graph).
** tijd-as-tics op logische plek (hele uren, minuten)
** Output formaat: PNG of scalable?
  
Verdere scripts
===============
* Zie nicoprjbb/perftools/Diversen/graphdata.
