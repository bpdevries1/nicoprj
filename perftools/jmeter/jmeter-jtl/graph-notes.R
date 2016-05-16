# notes on graphing jtl data in sqlite
# zie ook graph-logboek.R, hier staan alle queries en R-calls in.

# aantal actieve threads (ingelogde users) niet uit een tscut te bepalen: kan zijn dat in deze 15 sec er niets gebeurt met
# de thread, maar wel meetellen.
# beter om per threadname de min- en max-time te bepalen, en dan op te tellen.
# ng en na velden mogelijk niet betrouwbaar bij loadtest.
# loadgen ook gebruiken (hn-veld)
[2012-11-01 11:56:25] door 2 oorzaken is onderstaande query niet betrouwbaar: 1) overlappende namen: combi van hn en tn komt meerdere keren voor, door meerdere JMeters op 1 machine.
[2012-11-01 11:57:09] en 2) samples ontbreken in JTL, bv P3740 pas vanaf 12:55 te zien, is ook om 10:30 gestart. Deze wel terug
[2012-11-01 11:57:41] te zien in access logs.

query voor min-max

select min(ts), max(ts), tn, hn
from httpsample
group by tn,hn
order by tn,hn;
# ok

# dan bij onderstaande wel wat verschillen.
Eerste caseload page ophalen|true|535|15060.7362226178|16329
Juiste page ophalen|true|859|14761.1711680597|16409
maxJM|true|346|3899.38891839264|48793
maxMom|true|396|10432.5819577565|775087
minJuridische Maatregel|true|342|974.01923673596|24102
minMoM|true|392|10428.321457024|775083

allen s=true

evt size versus R
avg(size) vs time (vgl andere grafiek)

sqlite> select count(*) from httpsample where lb='Inloggen';
36970
# ofwel zovaak ingelogd en dus iteraties gestart gedurende de hele test.

select count(*) from httpsample;
2674987

delen op elkaar: sqlite> select 2674987 / 36970 from httpsample limit 1;
72
# Ok, dus 72 webservice requests per iteratie.

ggsave("loadtest-resptimes-inloggen.png", width=11, height=9, dpi=100)

je ziet wel bepaalde 'banden'

# echte concurrency bepalen lijkt nu ook wel weer te doen, evt eerst ook alleen in deze periode, later geheel, vgl met andere plaat.
# => maar dit lukte dus niet voor de volledige test, nog eens naar kijken, performance van de analyse zelf, evt zelf dingen in andere tabellen zetten.
# moeten stukken van orde(N) of evt orde(NlogN, sorteren) zijn, maar niet hoger.

# in jtl bestanden hier zijn genoemde ts de ts-start!

Todo's:
* analyse ts-start en end, behoorlijk essentieel voor de rest.-> done, idd andersom.
* echte concurrency bepalen. -> lukt dus niet voor de hele test.
* jmeter log files, voor rampup -> done.

[2012-10-31 11:32:59] note: evt wat boeken op keten ondersteuning, niet per se alles op parnassia schrijven.
[2012-10-31 11:33:51] eog gaf segmentation fault, daardoor afgesloten...

# dan veel verticale 'kolommen' te zien met dezelfde kleuren, ofwel load niet evenwichtig verdeeld. Maar is vraag of dit klopt,
# of ts niet anders is.

# weet bijna zeker dat ts toch de ts-start is: 1) overlap gezien en 2), in 'small' grafiek paar requests die 'te vroeg' starten.
# als zeker is, niet meteen alles overboord, zou lang duren, maar wel even checken welke wel.
# mogelijk alleen maar de dingen per thread.

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen. => gaat goed, wel milliseconds ook.

# saven met grote y en ook iets grotere x
ggsave(filename="threads-rond-fout.png", width=13, height=90, dpi=100)
# [2012-10-31 11:16:33] grafiek ook goed, heeft dus half uur gekost om te maken.

cnt = make.count(df)
# deze duurt lang, R is single threaded hier. Mss specifieke functies voor multithreaded.
# pakt wel af en toe andere CPU, mss stappen in proces?


# @todo aantal vusers bepalen uit jmeter logfiles, want is overlap in thread-namen in combi met host: 3 jmeter processen per host, op diverse tijdstippen gestart.
# aantal vusers klopt sowieso niet in grafiek, maar niet alleen omdat er dubbele thread/host combi's zijn.
# om 11:00 zouden vanaf 3 machines totaal al 1300 threads moeten draaien, worden er 300 getoond.
# query lijkt niet zo fout, mss iets met sortering, dat cumsum hier last van heeft?
# query result is wel fout, bv voor host 3740 wordt 12:55 als minimale tijd voor thread 1-200 gegeven, moet vlak na 10:30 zijn.
# kan met foute jtl's te maken hebben, dat requests niet goed in log terecht gekomen zijn.
# eerste 10 reqs van deze thread laten zien:
select hn, tn, ts, t, lb, s from httpsample where hn='P3740-' and tn='Thread Group 1-200' order by ts limit 10;
P3740-|Thread Group 1-200|1350730502987|21014|Inloggen|false
P3740-|Thread Group 1-200|1350730524005|1014|Inloggen|true
P3740-|Thread Group 1-200|1350730525042|1116|Behandelaar ophalen|true
P3740-|Thread Group 1-200|1350730526480|1894|Aantal clienten ophalen|true
P3740-|Thread Group 1-200|1350730528884|1651|Eerste caseload page ophalen|true
P3740-|Thread Group 1-200|1350730550501|798|Zet rode draad|true
P3740-|Thread Group 1-200|1350730551306|1022|PatientService|true
P3740-|Thread Group 1-200|1350730552332|1207|minJuridische Maatregel|true
P3740-|Thread Group 1-200|1350730553542|1137|minMoM|true
P3740-|Thread Group 1-200|1350730554682|3911|Indicatiebesluit|true

% clock format 1350730502
Sat Oct 20 12:55:02 CEST 2012
# 't is dus echt zo.

# @todo in orig logs kijken.
# done, in bronbestanden ook pas laat gegevens van P3740. In file genaamd 1030 pas vlak voor 14:00 uur.
# 2 mogelijkheden: ofwel geen requests gedaan, ofwel niet/verkeerd in de logs terechtgekomen.
# sowieso aan te raden om volgende keer de threadgroup naam aan te passen, ofwel zorgen dat naast hostnaam nog ander ID wordt gelogd.
# response filename kun je ook loggen, zou dan goed moeten gaan.
# ook aan te raden of hostname ook in de logfile name op te nemen, if possible.
# idle time kun je ook saven, ook boeiend om Z te bepalen?
# sowieso OA toe te passen om validity te bepalen en welke van de opties hierboven genoemd waar is?
# mijn grafieken/analyse iig van de beschikbare data, kan zijn dat er meer throughput is, maar R's zullen wel ongeveer kloppen.

# analyse die nu draait: eerste was 10 min, hele is 4 hr, dus factor 4*6=24. Als 'ie kwartier bezig was, kan dat nu 6 uur duren, mits het lineair is.
# kan wel ondertussen ook andere sessie starten, db is al gelezen.

# uit server-log te bepalen wat load is?
# als Z te bepalen is, dan N ook. obv X en R. Als er reqs missen, is X ook lager, en N dan dus ook.
# ofwel uit puur jmeter data is het antwoord op deze vraag niet af te leiden, zo lijkt het.

[2012-10-31 19:32:13] access log ingelezen in db: ruim 700 MB, lijkt er goed in te staan.
[2012-10-31 19:34:28] doel: tps bepalen, in grafiek, vgl die van Jmeter.
[2012-10-31 19:35:15] andere R sessie voor conc threads detail nog steeds bezig. Nog steeds geen last van, kan tot morgen draaien.

[2012-10-31 19:41:08] ip is beschikbaar, dus kijken of van P3740=10.135.20.103 reqs aanwezig zijn.
[2012-10-31 19:42:21] en deze zit al bij de eerste 10: 2012-10-20 10:30:00|10.135.20.103|POST|/aselectserver/server|200|1
en ook: 2012-10-20 10:30:05|10.135.20.103|POST|/quarant-web-services/service/CaseloadService|200|16144

[2012-10-31 20:25:50] wel weer een goede dag zo, ondanks gebrek aan communicatie. Morgen nog jmeter.logs voor bepalen aantal vusers.

[2012-10-31 20:26:45] conclusie iig geval dat load wel gegenereerd is, maar dat in de jtl veel resultaten niet beschikbaar zijn.
[2012-10-31 20:28:28] zie andere R-sessie nu paar keer verspringen van CPU.

[2012-11-01 09:37:32] berekening van gisteren is er niet uitgekomen, afbreken.


