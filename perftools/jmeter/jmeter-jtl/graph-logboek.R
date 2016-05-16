# notes on graphing jtl data in sqlite

> ms=1350719101537
> s=ms*0.001
> s
[1] 1350719102
> s=0.001*ms
> s
[1] 1350719102
> as.POSIXct(s, origin="1970-01-01")
[1] "2012-10-20 08:45:01 CEST"

[2012-10-30 09:47:56] soort van ok, nu eerst wat plotten.

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db_name = "logintest2.db"
db = dbConnect(dbDriver("SQLite"), db_name)
# goed, in goede dir dus.
query = "select ts, t from httpsample limit 100"
df = dbGetQuery(db, query)

# niets, toch verkeerde db, mss nieuw gemaakt.
dbDisconnect(db)

setwd('~/Ymor/Parnassia/Resultaten')

qplot(ts, t, data=df)
# wel ok, maar geen timeformat
qplot(ts, t, data=df) +
  scale_x_datetime(format="%Y-%m-%d %H:%M:%S")
# fout
qplot(as.POSIXct(ts, origin="1970-01-01"), t, data=df) +
  scale_x_datetime(format="%Y-%m-%d %H:%M:%S")
# ook fout, dus in df erbij zetten.
# is hier uurtje off, dus nu even zo, met CEST, UTC en GMT werkt het niet.
df$ts_psx = as.POSIXct(0.001 * df$ts, origin="1970-01-01 01:00:00")

# lijkt iets van overflow bij inlezen, ts's nu heel anders, dus in query al oplossen:
query = "select 0.001*ts ts, t from httpsample limit 100"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
# oppassen: in query de column renamen naar ts.qplot(ts_pdx, t, data=df)

qplot(ts_psx, t, data=df)
# ok, maar idd als 8:45 getoond terwijl 't 9:45 moet zijn.

# opgelost bij convert van sec -> ts.
# even alles inlezen, lukt dit nog?
query = "select 0.001*ts ts, t from httpsample"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")

# gaat hier nog prima, bij logintest2.
# ook voor loadtest?
db = dbConnect(dbDriver("SQLite"), "loadtest.db")
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
qplot(ts_psx, t, data=df)
# inlezen prima, psx ook, plotten duurt wel wat langer (ordegrootte 1 minuut). responstijden tot 500 seconden.

# voor rest terug naar logintest2

db = dbConnect(dbDriver("SQLite"), "logintest2.db")

# todo: tps/tph en #vusers
# eerst tph
# 25 minuten, 100 delen, dus elke 15 sec 1
ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
# df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq), format="%Y-%m-%d %H:%M:%S")
# format bij cut niet zo nodig.
df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

cnt = ddply(df, .(tscut), function (df) {
  data.frame(stattype = c('count'),  
    value = c(length(df$ts, na.rm = TRUE)))
})
# ddply niet gevonden, raar, zou bij ggplot in moeten zitten.

library(plyr)

cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
cnt = ddply(df, .(tscut), function (df) {
  data.frame(stattype = c('count', 'tps', 'tph'),  
    value = c(length(df$ts), length(df$ts) / cut.diff.secs, 3600 * length(df$ts) / cut.diff.secs))
})

cnt = ddply(df, .(tscut), function (df) {
  data.frame(tps = length(df$ts) / cut.diff.secs)  
})

qplot(tscut, tps, data=cnt)

# met avg(R) ook concurrent reqs te bepalen: N=X*R
cnt = ddply(df, .(tscut), function (df) {
  data.frame(tps = length(df$ts) / cut.diff.secs,
             r.avg = 0.001*mean(df$t, na.rm=TRUE),
             conc = length(df$ts) / cut.diff.secs * 0.001* mean(df$t, na.rm=TRUE))  
})

qplot(tscut, conc, data=cnt)

# aantal actieve threads (ingelogde users) niet uit een tscut te bepalen: kan zijn dat in deze 15 sec er niets gebeurt met
# de thread, maar wel meetellen.
# beter om per threadname de min- en max-time te bepalen, en dan op te tellen.
# ng en na velden mogelijk niet betrouwbaar bij loadtest.
# loadgen ook gebruiken (hn-veld)

query voor min-max

select min(ts), max(ts), tn, hn
from httpsample
group by tn,hn
order by tn,hn;
# ok

# gebruik functies van ~/perftoolset/tools/loadmodel: 
maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 180, 110, 10, rampevery=re), 3600, time2show = 1000, random=FALSE))$count)
})

iter = make.iter(make.df("test", 180, 110, 10, rampevery=10), 3600, time2show = 1000, random=FALSE)
cnt =  make.count(iter)

# iets van: per 'cut' de step bepalen, met cumsum dan bijhouden.
iter heeft vorm die ook uit min/max query komt.

query = "select min(0.001*ts) ts_start, max(0.001*ts) ts_end, hn || ':' || tn threadname from httpsample group by tn,hn order by tn,hn"
df = dbGetQuery(db, query)

make.count = function(df) {
  # step1: hoeveel komen erbij, step2: hoeveel gaan ervan af.
  df.step1 = ddply(df, .(ts_start), function (df) {data.frame(ts=df$ts_start[1], step=length(df$ts_start))})
  df.step2 = ddply(df, .(ts_end), function (df) {data.frame(ts=df$ts_end[1], step=-length(df$ts_end))})
  df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 
  
  # eerst samenvoegen, dan arrange
  df.steps = arrange(ddply(df.step, .(ts), function(df) {c(step=sum(df$step))}), ts)
  df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
  df.steps$ts_psx = as.POSIXct(df.steps$ts, origin="1970-01-01 01:00:00")
  df.steps
}

cnt = make.count(df)
cnt$ts_psx = as.POSIXct(cnt$ts, origin="1970-01-01 01:00:00")

qplot(ts_psx, count, data=cnt)

plot.count = function(df.count) {
  qplot(data=df.count, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#vusers")
}

plot.count(cnt)

# gaat weer goed met logintest2, ook weer met loadtest.
db = dbConnect(dbDriver("SQLite"), "loadtest.db")
query = "select min(0.001*ts) ts_start, max(0.001*ts) ts_end, hn || ':' || tn threadname from httpsample group by tn,hn order by tn,hn"
df = dbGetQuery(db, query)
[2012-10-30 11:47:29] query duurt ong 10 sec (mss 20)

cnt = make.count(df)
# ok, snel

plot.count(cnt)
# ok, opvallend is dat #vusers om 12:10 ineens omhoog schiet, eerder wel rampup te zien.

# @todo: functie die tps maakt van een query/df.
# waarsch ts-end in de database, evt ook ts_start bepalen.
query = "select min(0.001*(ts-t)) ts_start, max(0.001*ts) ts_end, hn || ':' || tn threadname from httpsample group by tn,hn order by tn,hn"
df = dbGetQuery(db, query)
cnt = make.count(df)
plot.count(cnt)
# werkt, maar geeft hetzelfde beeld.


  qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = wrapper(paste(title.prefix, "resptime"), width = 80)) +
    scale_y_continuous(limits=c(0, max(df$t)))
    

# specifiek per soort req de min, max, avg    
select lb, s, min(by), avg(by), max(by)
from httpsample
group by lb,s 
order by lb,s;

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

db = dbConnect(dbDriver("SQLite"), "loadtest.db")
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes from httpsample where s='true' and lb in ('Eerste caseload page ophalen', 'Juiste page ophalen', 'maxJM', 'maxMom', 'minJuridische Maatregel', 'minMoM')"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")

# bytes vs R
qplot(bytes, t, data=df, colour=lb, shape=lb, xlab="Size (bytes)", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response time vs response size") +
  scale_y_continuous(limits=c(0, max(df$t))) +
  scale_x_continuous(limits=c(0, max(df$bytes)))
ggsave("loadtest-resptime-respsize.png", width=11, height=9, dpi=100) 
  
# dan met log-scale op x en y
qplot(bytes, t, data=df, colour=lb, shape=lb, xlab="Size (bytes)", ylab="Response time (sec)", log="xy") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response time vs response size")
ggsave("loadtest-resptime-respsize-logxy.png", width=11, height=9, dpi=100) 

# alleen log op x:
qplot(bytes, t, data=df, colour=lb, shape=lb, xlab="Size (bytes)", ylab="Response time (sec)", log="x") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response time vs response size")
# minder.

# met alpha geprobeerd, maar zie weinig verschil, is eerst wel goed zo.

# Dan size tov tijd:
qplot(ts_psx, bytes, data=df, colour=lb, shape=lb, xlab="Time", ylab="Size (bytes)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response sizes for selected transactions") +
  scale_y_continuous(limits=c(0, max(df$bytes))) +
  geom_point(alpha=0.00001)
ggsave("loadtest-respsizes-selected.png", width=11, height=9, dpi=100)

# van deze selected ook de resptime weergeven.
qplot(ts_psx, t, data=df, colour=lb, shape=lb, xlab="Time", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times for selected transactions") +
  scale_y_continuous(limits=c(0, max(df$t))) +
  geom_point(alpha=0.00001)
ggsave("loadtest-resptimes-selected.png", width=11, height=9, dpi=100)

sqlite> select count(*) from httpsample where lb='Inloggen';
36970
# ofwel zovaak ingelogd en dus iteraties gestart gedurende de hele test.

select count(*) from httpsample;
2674987

delen op elkaar: sqlite> select 2674987 / 36970 from httpsample limit 1;
72
# Ok, dus 72 webservice requests per iteratie.

db = dbConnect(dbDriver("SQLite"), "loadtest.db")
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success from httpsample where s='true' and lb in ('Inloggen')"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")

qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times for Inloggen") +
  scale_y_continuous(limits=c(0, max(df$t))) +
  geom_point(alpha=1/10)
ggsave("loadtest-resptimes-inloggen.png", width=11, height=9, dpi=100)

je ziet wel bepaalde 'banden'

per host:
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host from httpsample where s='true' and lb in ('Inloggen')"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")

qplot(ts_psx, t, data=df, colour=host, shape=host, xlab="Time", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times for Inloggen per host") +
  scale_y_continuous(limits=c(0, max(df$t))) +
  geom_point(alpha=1/10)
ggsave("loadtest-resptimes-inloggen-host.png", width=11, height=9, dpi=100)

# threadname/host op y-as?
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host, tn || ':' || hn threadname from httpsample where s='true' and lb in ('Inloggen') order by threadname"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
qplot(ts_psx, threadname, data=df, colour=host, shape=host, xlab="Time", ylab="Thread") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Inloggen per thread") +
  geom_point(alpha=1/10) +
  scale_y_discrete()
ggsave("loadtest-inloggen-thread.png", width=11, height=9, dpi=100)

# test 1 facet per host
qplot(ts_psx, t, data=df, colour=host, shape=host, xlab="Time", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times for Inloggen per host") +
  scale_y_continuous(limits=c(0, max(df$t))) +
  geom_point(alpha=1/10) +
  facet_grid(host ~ .)
# gaat best goed, nu een per label
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host, tn || ':' || hn threadname from httpsample order by threadname"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")

qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times per label") +
  facet_grid(lb ~ .)
# ziet er op het scherm niet uit, niet genoeg y positie, dus saven naar grote y:
ggsave("loadtest-label-resptime.png", width=11, height=90, dpi=100)

# max-y nu op 400, daardoor niets te zien. Ofwel op 20 zetten, ofwel log-scale.
# eerst log-scale:
qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)", log="y") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response times per label") +
  facet_grid(lb ~ .)
# ziet er op het scherm niet uit, niet genoeg y positie, dus saven naar grote y:
ggsave("loadtest-label-resptime-log.png", width=11, height=90, dpi=100)

# ook per label de avg resp time in facets:
[2012-10-31 10:22:06] 
query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host, tn || ':' || hn threadname from httpsample order by threadname"
df = dbGetQuery(db, query)
df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

avg = ddply(df, .(tscut, lb, success), function (df) {
  data.frame(Ravg = mean(df$t, na.rm=TRUE))  
})

qplot(tscut, Ravg, data=avg, geom="line", colour=success, shape=success, xlab="Time", ylab="Response time avg (sec)", log="y") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Response time average per label") +
  facet_grid(lb ~ .)
ggsave("loadtest-label-avg-resptime-log.png", width=11, height=90, dpi=100)

> s
[1] 1350719102
> as.POSIXct(s, origin="1970-01-01 01:00:00")
[1] "2012-10-20 08:45:01 CEST"

as.POSIXct(1350719102, origin="1970-01-01 01:00:00")

> as.POSIXct(1350719102-302+7200, origin="1970-01-01 01:00:00")
[1] "2012-10-20 11:40:00 CEST"
> 1350719102-302+7200
[1] 1350726000 (=11:40)

> as.POSIXct(1350719102-302+7200+900, origin="1970-01-01 01:00:00")
[1] "2012-10-20 11:55:00 CEST"
> 1350719102-302+7200+900
[1] 1350726900 (=11:55)

# stats in goede periode van 11:40-11:55
select lb, s, min(t), cast(round(avg(t)) as integer), max(t), count(t)
from httpsample
where 0.001*ts between 1350726000 and 1350726900
group by lb, s
order by lb, s;

# perc fouten per label in goede periode van 11:40-11:55
create table samplecount (lb, typ, value);

insert into samplecount (lb, typ, value)
select lb, 'total', count(*)
from httpsample
where 0.001*ts between 1350726000 and 1350726900
group by lb;

insert into samplecount (lb, typ, value)
select lb, s, count(*)
from httpsample
where 0.001*ts between 1350726000 and 1350726900
group by lb,s;

# perc fout: als niet in lijst, dan 0
select s1.lb, cast(round(100.0 * s1.value / s2.value) as integer)
from samplecount s1, samplecount s2
where s1.lb = s2.lb
and s1.typ = 'false'
and s2.typ = 'total'
order by s1.lb;

# en tegenhanger: perc success:
select s1.lb, cast(round(100.0 * s1.value / s2.value) as integer)
from samplecount s1, samplecount s2
where s1.lb = s2.lb
and s1.typ = 'true'
and s2.typ = 'total'
order by s1.lb;

[2012-10-31 10:49:11] # lastige: per thread de requests tonen rond 12:10. 12:05-12:15
1350726900 = 11:55
1350726900 + 600 = 12:05
1350726900 + 1200 = 12:15

1350727500 -> 1350728100

eerst proberen met bv alleen inloggen:
select hn||':'||tn thread, lb, s, t, 0.001*(ts-t) ts_start, 0.001*ts ts_end
from httpsample
where 0.001*ts between 1350727500 and 1350728100
and lb = 'Inloggen'
order by thread;

query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts-t) ts_start, 0.001*ts ts_end from httpsample where 0.001*ts between 1350727500 and 1350728100 and lb = 'Inloggen' order by thread" 
df = dbGetQuery(db, query)

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen.
df$ts_start_psx = as.POSIXct(df$ts_start, origin="1970-01-01 01:00:00")
df$ts_end_psx = as.POSIXct(df$ts_end, origin="1970-01-01 01:00:00")
> df$ts_end_psx[1] - df$ts_start_psx[1]
Time difference of 0.1860001 secs
> 
# so far, so good.
qplot(data=df, x=ts_start_psx, y=thread,  xend = ts_end_psx, yend = thread, 
  geom="segment", colour = s, xlab = "Time", ylab = "(v)user")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

# saven met grote y en ook iets grotere x
ggsave(filename="threads-inloggen-rond-fout.png", width=13, height=90, dpi=100)

# [2012-10-31 11:12:38]  grafiek op zich goed, door grote y wel lastige analyse. Eerst alles er neerzetten nu.
query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts-t) ts_start, 0.001*ts ts_end from httpsample where 0.001*ts between 1350727500 and 1350728100 order by thread" 
df = dbGetQuery(db, query)

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen.
df$ts_start_psx = as.POSIXct(df$ts_start, origin="1970-01-01 01:00:00")
df$ts_end_psx = as.POSIXct(df$ts_end, origin="1970-01-01 01:00:00")
> df$ts_end_psx[1] - df$ts_start_psx[1]
Time difference of 0.1860001 secs
> 
# so far, so good.
qplot(data=df, x=ts_start_psx, y=thread,  xend = ts_end_psx, yend = thread, 
  geom="segment", colour = s, xlab = "Time", ylab = "(v)user")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

# saven met grote y en ook iets grotere x
ggsave(filename="threads-rond-fout.png", width=13, height=90, dpi=100)
# [2012-10-31 11:16:33] grafiek ook goed, heeft dus half uur gekost om te maken.

# eigenlijk lijkt het een veel te korte rampup geweest te zijn, ook al in andere grafieken te zien.

# nu kleur per label:
qplot(data=df, x=ts_start_psx, y=thread,  xend = ts_end_psx, yend = thread, 
  geom="segment", colour = lb, xlab = "Time", ylab = "(v)user")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

# saven met grote y en ook iets grotere x
ggsave(filename="threads-rond-fout-labels.png", width=13, height=90, dpi=100)

# echte concurrency bepalen lijkt nu ook wel weer te doen, evt eerst ook alleen in deze periode, later geheel, vgl met andere plaat.

# ook twijfel of ts wel de end is, bij 3704-286 lijkt er overlap te zijn, deze nog eens anders plotten.
# of data plotten er vanuitgaande dat ts de ts_start is.
# Vraag of ik jmeter log files heb, hier iets van ramup uit af te leiden?

# uit label-colours lijkt ook wel overlap te blijken bij 3704-286, deze dus eens verder bekijken.

Todo's:
* analyse ts-start en end, behoorlijk essentieel voor de rest.-> done, idd andersom.
* echte concurrency bepalen.
* jmeter log files, voor rampup

[2012-10-31 11:32:59] note: evt wat boeken op keten ondersteuning, niet per se alles op parnassia schrijven.
[2012-10-31 11:33:51] eog gaf segmentation fault, daardoor afgesloten...

R-plaat ook in gewoon formaat saven, dan andere patronen te zien:
ggsave(filename="threads-rond-fout-labels-small.png", width=13, height=10, dpi=100)

# dan veel verticale 'kolommen' te zien met dezelfde kleuren, ofwel load niet evenwichtig verdeeld. Maar is vraag of dit klopt,
# of ts niet anders is.

# weet bijna zeker dat ts toch de ts-start is: 1) overlap gezien en 2), in 'small' grafiek paar requests die 'te vroeg' starten.
# als zeker is, niet meteen alles overboord, zou lang duren, maar wel even checken welke wel.
# mogelijk alleen maar de dingen per thread.

select hn||':'||tn thread, lb, s, t, 0.001*(ts-t) ts_start, 0.001*ts ts_end
from httpsample
where 0.001*ts between 1350727500 and 1350728100
and hn = 'P3704'
and tn = 'Thread Group 1-286'
order by lb;

query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts-t) ts_start, 0.001*ts ts_end from httpsample where 0.001*ts between 1350727500 and 1350728100 and hn = 'P3704' and tn = 'Thread Group 1-286' order by lb"
df = dbGetQuery(db, query)

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen.
df$ts_start_psx = as.POSIXct(df$ts_start, origin="1970-01-01 01:00:00")
df$ts_end_psx = as.POSIXct(df$ts_end, origin="1970-01-01 01:00:00")
qplot(data=df, x=ts_start_psx, y=lb,  xend = ts_end_psx, yend = lb, 
  geom="segment", colour = s, xlab = "Time", ylab = "label")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
 
=> minMoM overlapt alles, kijk of dit bij andere interpretatie ook zo is.
wel opletten dat deze er nog bij zit, kan door where-clause gelijk te laten.
nog meer overlap te zien.

query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts+t) ts_end, 0.001*ts ts_start from httpsample where 0.001*ts between 1350727500 and 1350728100 and hn = 'P3704' and tn = 'Thread Group 1-286' order by lb"
df = dbGetQuery(db, query)

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen.
df$ts_start_psx = as.POSIXct(df$ts_start, origin="1970-01-01 01:00:00")
df$ts_end_psx = as.POSIXct(df$ts_end, origin="1970-01-01 01:00:00")
qplot(data=df, x=ts_start_psx, y=lb,  xend = ts_end_psx, yend = lb, 
  geom="segment", colour = s, xlab = "Time", ylab = "label")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
=> ziet er stukken beter uit, dus dit is 'em.

[2012-10-31 13:02:20] paar dingen overnieuw dus.

query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts+t) ts_end, 0.001*ts ts_start from httpsample where 0.001*ts between 1350727500 and 1350728100 order by thread" 
df = dbGetQuery(db, query)

# beetje raar: bij tonen lijkt het op integers afgerond, maar als je start van end aftrekt, gaat het wel goed.
# vraag hoe het bij conversie naar timestamps gaat, evt als getallen blijven behandelen.
df$ts_start_psx = as.POSIXct(df$ts_start, origin="1970-01-01 01:00:00")
df$ts_end_psx = as.POSIXct(df$ts_end, origin="1970-01-01 01:00:00")
# so far, so good.
qplot(data=df, x=ts_start_psx, y=thread,  xend = ts_end_psx, yend = thread, 
  geom="segment", colour = s, xlab = "Time", ylab = "(v)user")  +
  opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
# ook 'small' bewaren.
ggsave(filename="threads-rond-fout-small.png", width=13, height=10, dpi=100)
  
# saven met grote y en ook iets grotere x
ggsave(filename="threads-rond-fout.png", width=13, height=90, dpi=100)
# [2012-10-31 11:16:33] grafiek ook goed, heeft dus half uur gekost om te maken.

# eigenlijk lijkt het een veel te korte rampup geweest te zijn, ook al in andere grafieken te zien.

# nu kleur per label:
qplot(data=df, x=ts_start_psx, y=thread,  xend = ts_end_psx, yend = thread, 
  geom="segment", colour = lb, xlab = "Time", ylab = "(v)user")  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

ggsave(filename="threads-rond-fout-labels-small.png", width=13, height=10, dpi=100)

# saven met grote y en ook iets grotere x
ggsave(filename="threads-rond-fout-labels.png", width=13, height=90, dpi=100)

# voor nconcurrent deze data ook te gebruiken, later nog over hele linie doen.
# vgl code voor nvusers.
make.count = function(df) {
  # step1: hoeveel komen erbij, step2: hoeveel gaan ervan af.
  df.step1 = ddply(df, .(ts_start), function (df) {data.frame(ts=df$ts_start[1], step=length(df$ts_start))})
  df.step2 = ddply(df, .(ts_end), function (df) {data.frame(ts=df$ts_end[1], step=-length(df$ts_end))})
  df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 
  
  # eerst samenvoegen, dan arrange
  df.steps = arrange(ddply(df.step, .(ts), function(df) {c(step=sum(df$step))}), ts)
  df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
  df.steps$ts_psx = as.POSIXct(df.steps$ts, origin="1970-01-01 01:00:00")
  df.steps
}

cnt = make.count(df)
# deze duurt lang, R is single threaded hier. Mss specifieke functies voor multithreaded.
# pakt wel af en toe andere CPU, mss stappen in proces?

qplot(data=cnt, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#nconcurrent") +
  opts(title = "Loadtest #concurrent requests") +
  scale_y_continuous(limits=c(0, max(cnt$count)))
ggsave(filename="loadtest-conc-requests-rond-fout.png", width=11, height=9, dpi=100)

# nu wel grafiek, duurde vrij lang, toch proberen voor de hele testrun te doen.
query = "select hn||':'||tn thread, lb, s, t, 0.001*(ts+t) ts_end, 0.001*ts ts_start from httpsample" 
df = dbGetQuery(db, query)
cnt = make.count(df)
# deze duurt lang, R is single threaded hier. Mss specifieke functies voor multithreaded.
# pakt wel af en toe andere CPU, mss stappen in proces?

qplot(data=cnt, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#nconcurrent") +
  opts(title = "Loadtest #concurrent requests") +
  scale_y_continuous(limits=c(0, max(cnt$count)))
ggsave(filename="loadtest-conc-requests.png", width=11, height=9, dpi=100)

[2012-10-31 13:54:29] alle commando's ineens gegeven, kijken hoe lang het duurt.



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

db = dbConnect(dbDriver("SQLite"), "accesslog.db")
query = "select ts, 0.001*t t, ip, url, rc from logline"
df = dbGetQuery(db, query)
# df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
df$ts_psx = strptime(df$ts, format="%Y-%m-%d %H:%M:%S")

ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

cnt = ddply(df, .(tscut, rc), function (df) {
  data.frame(tps = length(df$ts) / cut.diff.secs)  
})

qplot(tscut, tps, data=cnt, geom="line", colour=rc, xlab="Time", ylab="Througput (trans/sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  opts(title = "Access log throughput (trans/sec)") +
  scale_y_continuous(limits=c(0, max(cnt$tps)))

# todo mss: bij inlezen naar db: in url cijfers door code vervangen, als ik hier op wil graphen etc.

# rc als continuous var gezien hier, niet goed, moeten discrete waarden zijn.
# ook rare grafiek, even zonder rc tonen.
qplot(tscut, tps, data=cnt, geom="line", xlab="Time", ylab="Througput (trans/sec)") +
  opts(title = "Access log throughput (trans/sec)") +
  scale_y_continuous(limits=c(0, max(cnt$tps)))

# ziet er nog steeds vaag uit, komt omdat rc's er nog in staan.
# iets als factor levels.
qplot(tscut, tps, data=cnt, geom="line", colour=as.factor(rc), xlab="Time", ylab="Througput (trans/sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
  scale_colour_discrete(name = "Resultcode") +  
  opts(title = "Access log throughput (trans/sec)") +
  scale_y_continuous(limits=c(0, max(cnt$tps)))
# beter!
ggsave(filename="accesslog-throughput.png", width=11, height=9, dpi=100)

# goed, ook avg.R en nconc als berekening erbij.
avg = ddply(df, .(tscut, rc), function (df) {
  data.frame(Ravg = mean(df$t, na.rm=TRUE))  
})

qplot(tscut, Ravg, data=avg, geom="line", colour=as.factor(rc), xlab="Time", ylab="Response time avg (sec)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  scale_colour_discrete(name = "Resultcode") +  
  opts(title = "Access log response times (sec)") +
  scale_y_continuous(limits=c(0, max(avg$Ravg)))
ggsave(filename="accesslog-resptime-avg.png", width=11, height=9, dpi=100)  

# en nconc als berekening.
cnt = ddply(df, .(tscut, rc), function (df) {
  data.frame(tps = length(df$ts) / cut.diff.secs,
             r.avg = mean(df$t, na.rm=TRUE),
             conc = length(df$ts) / cut.diff.secs * mean(df$t, na.rm=TRUE))  
})

qplot(tscut, conc, data=cnt, geom="line", colour=as.factor(rc), xlab="Time", ylab="#Concurrent requests (R*X)") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
  scale_colour_discrete(name = "Resultcode") +  
  opts(title = "Access log #Concurrent requests") +
  scale_y_continuous(limits=c(0, max(cnt$conc)))
ggsave(filename="accesslog-nconc.png", width=11, height=9, dpi=100)  

[2012-10-31 20:25:50] wel weer een goede dag zo, ondanks gebrek aan communicatie. Morgen nog jmeter.logs voor bepalen aantal vusers.

[2012-10-31 20:26:45] conclusie iig geval dat load wel gegenereerd is, maar dat in de jtl veel resultaten niet beschikbaar zijn.
[2012-10-31 20:28:28] zie andere R-sessie nu paar keer verspringen van CPU.

select count(*), ip, pcname, testname, logfilename, startstop
from logline
where testname='loadtest'
group by 2,3,4,5,6
order by 2,3,4,5,6;

[2012-10-31 22:13:22] data nu dus in db, morgen grafiek van maken, ook weer met counts en cumsum.
[2012-11-01 09:37:32] berekening van gisteren is er niet uitgekomen, afbreken.

[2012-11-01 09:43:24] nieuwe sessie in Resultaten dir.
library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(plyr, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db = dbConnect(dbDriver("SQLite"), "jmeterlogs.db")
query = "select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='loadtest'" 
df = dbGetQuery(db, query)
df$ts_psx = strptime(df$ts, format="%Y-%m-%d %H:%M:%S")
 
[2012-11-01 09:46:26] dan iets vgl make.count, wel iets anders: 2 df's, 1 voor start en een voor stop.

query1 = "select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='loadtest' and startstop='started'" 
df1 = dbGetQuery(db, query1)
df1$ts_psx = strptime(df1$ts, format="%Y-%m-%d %H:%M:%S")

query2 = "select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='loadtest' and startstop='finished'" 
df2 = dbGetQuery(db, query2)
df2$ts_psx = strptime(df2$ts, format="%Y-%m-%d %H:%M:%S")

df.step1 = ddply(df1, .(ts_psx), function (df) {data.frame(step=length(df$ts_psx))})
df.step2 = ddply(df2, .(ts_psx), function (df) {data.frame(step=-length(df$ts_psx))})

df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts_psx,step)) 
df.steps = arrange(ddply(df.step, .(ts_psx), function(df) {c(step=sum(df$step))}), ts_psx)
df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
qplot(data=df.steps, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#vusers") +
  opts(title = "Loadtest #Vusers (jmeter.log)") +
  scale_y_continuous(limits=c(0, max(df.steps$count)))
ggsave(filename="jmeterlog-nvusers.png", width=11, height=9, dpi=100)  

====== Extra grafieken op aanvraag van Karel-Henk =======
[2012-11-19 16:20:05] te beginnen met freq/density plot. 

[2012-11-19 16:20:50] inloggen alleen, hele test, facet op success.

db = dbConnect(dbDriver("SQLite"), "loadtest.db")
query = "select 0.001*t t, lb, s success from httpsample where lb in ('Inloggen')"
df = dbGetQuery(db, query)
testname = "loadtest"
outputdir = "~/Ymor/Parnassia/loadtest"
  
qplot(t, data=df, geom="density", colour=success, xlab="Response time (sec)", ylab="Frequency") + 
  facet_grid(success ~ .) +
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1))
ggsave(paste(outputdir, "Inloggen-density-success-failed.png", sep="/"), width=11, height=9, dpi=100)

[2012-11-19 16:39:48] alleen succesvol nu:
query = "select 0.001*t t, lb, s success from httpsample where lb in ('Inloggen') and success='true'"
df = dbGetQuery(db, query)

qplot(t, data=df, geom="density", colour=success, xlab="Response time (sec)", ylab="Frequency") + 
  facet_grid(success ~ .) +
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1))
ggsave(paste(outputdir, "Inloggen-density-success-failed.png", sep="/"), width=11, height=9, dpi=100)

qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1))
ggsave(paste(outputdir, "Inloggen-density-success-all.png", sep="/"), width=11, height=9, dpi=100)
# max op zo'n 3000

qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
  scale_x_continuous(limits=c(0.1, max(df$t)))
ggsave(paste(outputdir, "Inloggen-density-success-min-0.1sec.png", sep="/"), width=11, height=9, dpi=100)

qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
  scale_x_continuous(limits=c(15, max(df$t)))
ggsave(paste(outputdir, "Inloggen-density-success-min-15sec.png", sep="/"), width=11, height=9, dpi=100)


qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
  opts(title = paste(testname, "Response time frequencies for Inloggen")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
  scale_x_continuous(limits=c(1, max(df$t)))
ggsave(paste(outputdir, "Inloggen-density-success-min-1sec.png", sep="/"), width=11, height=9, dpi=100)

plot.density = function(df, testname, outputdir, label) {
  qplot(t, data=df, geom="density", colour=success, xlab="Response time (sec)", ylab="Frequency") + 
    facet_grid(success ~ .) +
    opts(title = paste(testname, "Response time frequencies for", label)) +
    opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1))
  ggsave(paste(outputdir, "/", label, "-density-facet.png", sep=""), width=11, height=9, dpi=100)
  
  qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
    opts(title = paste(testname, "Response time frequencies for", label)) +
    opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1))
  ggsave(paste(outputdir, "/", label, "-density.png", sep=""), width=11, height=9, dpi=100)
  # max op zo'n 3000
  
  qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
    opts(title = paste(testname, "Response time frequencies for", label)) +
    opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
    scale_x_continuous(limits=c(0.1, max(df$t)))
  ggsave(paste(outputdir, "/", label, "-density-min-0.1sec.png", sep=""), width=11, height=9, dpi=100)
  
  qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
    opts(title = paste(testname, "Response time frequencies", label)) +
    opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
    scale_x_continuous(limits=c(15, max(df$t)))
  ggsave(paste(outputdir, "/", label, "-density-min-15sec.png", sep=""), width=11, height=9, dpi=100)
  
  qplot(t, data=df, geom="histogram", binwidth=0.01, colour=success, xlab="Response time (sec)", ylab="Number") + 
    opts(title = paste(testname, "Response time frequencies for", label)) +
    opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
    scale_x_continuous(limits=c(1, max(df$t)))
  ggsave(paste(outputdir, "/", label, "-density-min-1sec.png", sep=""), width=11, height=9, dpi=100)
}

# Voor alles:

query = "select 0.001*t t, lb, s success from httpsample"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success-failure")

query = "select 0.001*t t, lb, s success from httpsample where success='true'"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success")

# Alles, facet per soort, kleur per success/failure.
query = "select 0.001*t t, lb, s success from httpsample"
df = dbGetQuery(db, query)

qplot(t, data=df, geom="density", colour=success, xlab="Response time (sec)", ylab="Frequency") + 
  facet_grid(lb ~ .) +
  opts(title = paste(testname, "Response time frequencies for all labels")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
  scale_x_continuous(limits=c(0, 25))
label = "perlabel"
ggsave(paste(outputdir, "/", label, "-density-success-failure-all.png", sep=""), width=11, height=90, dpi=100)

# en alleen succes weer.
query = "select 0.001*t t, lb, s success from httpsample where success='true'"
df = dbGetQuery(db, query)

qplot(t, data=df, geom="density", colour=success, xlab="Response time (sec)", ylab="Frequency") + 
  facet_grid(lb ~ .) +
  opts(title = paste(testname, "Response time frequencies for all labels")) +
  opts(legend.position=c(0.96, 0.96), legend.justification = c(1, 1)) +
  scale_x_continuous(limits=c(0, 25))
label = "perlabel"
ggsave(paste(outputdir, "/", label, "-density-success-all.png", sep=""), width=11, height=90, dpi=100)
ggsave(paste(outputdir, "/", label, "-density-success-all-small.png", sep=""), width=11, height=9, dpi=100)

# dit zijn wel alle de frequencies over de hele test, wil ook nog wel eens zien voordat het fout gegaan is.

# [2012-11-20 10:47:49] nu alles tot 12.00 uur, eerst 12.00 vinden als epoch-seconds.

eerste ts: 1350721798299, minus laatste 3: 1350721798, in tcl: 10:29 (nu wel, eerder niet, wintertijd?), 12:00
is dan deze tijd + 90 min = 90*60*1000 msec = 5400000. Ofwel 1350721798299+5400000=1350727198299
clock format 1350727198 = 11:59:58, dus ok.

db = dbConnect(dbDriver("SQLite"), "~/Ymor/Parnassia/Resultaten/loadtest.db")

outputdir = "~/Ymor/Parnassia/loadtest-tot1200" 
query = "select 0.001*t t, lb, s success, 0.001*ts ts from httpsample where 0.001*ts < 1350727198"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success-failure")

query = "select 0.001*t t, lb, s success from httpsample where success='true' and 0.001*ts < 1350727198"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success")

# loadtest all nog een keer
outputdir = "~/Ymor/Parnassia/loadtest" 
query = "select 0.001*t t, lb, s success, 0.001*ts ts from httpsample"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success-failure")

query = "select 0.001*t t, lb, s success from httpsample where success='true'"
df = dbGetQuery(db, query)
plot.density(df, "Loadtest", outputdir, "All-success")

