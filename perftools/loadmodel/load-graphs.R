library(ggplot2)
library(RSQLite)

db_name = "model.db"
db = dbConnect(dbDriver("SQLite"), db_name)
  


# graphdata <- read.csv(db_name, header=T, sep="\t")
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script")
looptijd = dbGetQuery(db, "select val1 looptijd from globals where val0 like '%looptijd%'")$looptijd

# choice: make/plot segments or line with points. Points seems easiest.
# want to give 'looptijd' to the inner lambda function
dfr = ddply(df, .(script), looptijd = looptijd, function(df, looptijd = NULL) {
  data.frame(script = rep(df$script, 3), time = c(0, df$secrampup, looptijd), vusers = c(df$vusersper, df$vusers, df$vusers))
})

qplot(time, vusers, data = dfr, colour = script, geom="line")

# works, 7 horizontal lines are shown, should be 14, so have some overlap to handle.
# also want the legend at the bottom of the graph.

qplot(time, vusers, data = dfr, colour = script, geom="line") +
  opts(legend.position="bottom")
  
# this works, now want the legend in two or three columns. Not possible
# in the graph, on the right
qplot(time, vusers, data = dfr, colour = script, geom="line") +
 opts(legend.position=c(0.8, 0.6), legend.justification=c(1,1))
=> hiermee nog onder de 28-lijn, en 11 nog net te zien, 12 niet.

qplot(time, vusers, data = dfr, colour = script, geom="line") +
 opts(legend.position=c(0.8, 0.7), legend.justification=c(1,1))
=> dan inderdaad wat hoger.

qplot(time, vusers, data = dfr, colour = script, geom="line") +
 opts(legend.position=c(0.8, 0.95), legend.justification=c(1,1))
=> dan past het, nog meer naar rechts:

qplot(time, vusers, data = dfr, colour = script, geom="line") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

# ok 

# notes
# grouping maybe a good idea, to reduce number of lines, but calculation and scripts will become more complex.
# maybe don't show entire runtime, but limit to twice the max rampup?

# twice max rampup:
time2show = min(looptijd, 2*max(df$secrampup))
dfr2 = ddply(df, .(script), looptijd = time2show, function(df, looptijd = NULL) {
  data.frame(script = rep(df$script, 3), time = c(0, df$secrampup, looptijd), vusers = c(df$vusersper, df$vusers, df$vusers))
})

qplot(time, vusers, data = dfr2, colour = script, geom="line") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

qplot(time, vusers, data = dfr2, colour = script, shape=script, geom="line") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
 scale_shape_manual(value=0:25)

qplot(time, vusers, data = dfr2, colour = script, geom="line") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
 
qplot(time, vusers, data = dfr2, colour = script, geom="line", position="jitter") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
=> werkt wel sort-of, maar nu geen horizontale lijnen meer.
# jitter toch vooral voor 1-dimensionaal.

# met step.
qplot(time, vusers, data = dfr2, colour = script, geom="step") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
# werkt prima, moet dan alleen zelf te tussenliggende waarden berekenen.

seq - by
seq - number

dfr3 = ddply(df, .(script), looptijd = time2show, function(df, looptijd = NULL) {
  data.frame(script = rep(df$script, df$vusers / df$vusersper + 1), time = append(seq(0, df$secrampup, df$rampevery), looptijd), vusers = append(seq(df$vusersper, df$vusers, df$vusersper), df$vusers))
})
 
qplot(time, vusers, data = dfr3, colour = script, geom="step") +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
# is mooi!

# dfr3 bevat nu bijna een record voor elke vuser, alleen niet als meerdere tegelijk worden gestart, maar deze gedragen zich dan wel hetzelfde, dan zeker wat random iteratie/pacing nodig.
# bv std random waarde tussen .9 en 1.1 van de pacing maken?

# wil voor elke user het startmoment, bij meerdere per rampup wordt dit: 0,0,0,0,4,4,4,4,8,8,8,8
# is dit met combi van rep en seq te doen? evt ook flatten?
# evt eerst seq, en deze rep, dan sort?

> sort(rep(seq(0,20,5), 2))
 [1]  0  0  5  5 10 10 15 15 20 20

# vusernr: eerst binnen de groep, wil hierna ook een absoluut nr. 
vu.start = ddply(df, .(script, itersec, pacing), function(df) {
  data.frame(script = rep(df$script, df$vusers), vu.nr = 1:df$vusers, start = sort(rep(seq(0, df$secrampup, df$rampevery), df$vusersper)))     
})

vu.start = ddply(df, .(script, itersec, pacing), function(df) {
  data.frame(vu.nr = 1:df$vusers, start = sort(rep(seq(0, df$secrampup, df$rampevery), df$vusersper)))     
})


# absolute nr is row.name
vu.start$vu.nra = row.names(vu.start)
# werkt, is wel een R specifiek trucje, hoe dit in FP te doen?
# denk toch vergelijkbaar, door met een zip/combine gewoon een lijst 1:n te genereren, en deze erbij te plakken.

# met pacing en iteratie tijd nu input voor segementen te maken voor alle request, evt best veel.
    itersec pacing                script vu.nr start vu.nra
1       110    144         01_I2F_MB1B.c     1     0      1
2       110    144         01_I2F_MB1B.c     2     4      2
3       110    144         01_I2F_MB1B.c     3     8      3
4       110    144         01_I2F_MB1B.c     4    12      4

# misschien meerdere grafieken tonen, een per group/script? Is dan facet.
iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
  data.frame(start = seq(df$start, looptijd, df$pacing), end = seq(df$start + df$itersec, looptijd + df$itersec, df$pacing))
})

iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
  data.frame(start = seq(df$start, looptijd, df$pacing), end = seq(df$start + df$itersec, looptijd + df$itersec, df$pacing))
})

# ok, dan segment plot
qplot(data=iter, x=start, y=vu.nra,  xend = end, yend = vu.nra, geom="segment", colour = script)  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))

# wel ongeveer wat ik wil, maar vage dingen, beter om het eerst per script te doen.
# lijkt ook y-overlap tussen scripts te zijn.
# voor vanavond is het goed zo (23:34)

# Vanaf het begin, voor segmenten per iteratie.

library(ggplot2)
library(RSQLite)

db_name = "model.db"
db = dbConnect(dbDriver("SQLite"), db_name)

# graphdata <- read.csv(db_name, header=T, sep="\t")
# df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script")
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")

# alleen de dingen zonder overlap: pacing > itersec
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where pacing > itersec")


looptijd = dbGetQuery(db, "select val1 looptijd from globals where val0 like '%looptijd%'")$looptijd

vu.start = ddply(df, .(script, itersec, pacing), function(df) {
  data.frame(vu.nr = 1:df$vusers, start = sort(rep(seq(0, df$secrampup, df$rampevery), df$vusersper)))     
})
vu.start$vu.nra = row.names(vu.start)

time2show = min(looptijd, 2*max(df$secrampup))

iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
  data.frame(start = seq(df$start, looptijd, df$pacing), end = sapply(seq(df$start + df$itersec, looptijd + df$itersec, df$pacing), function (val) {min(c(val, looptijd))}))
})

time2show = looptijd

# 23-10-2011 met random pacing variatie, +/- 10, nu nog hardcoded.
iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
  # per vuser, eerste random value is 0
  cumsum.rnd = c(0, cumsum(runif((looptijd - df$start) / df$pacing, -10, 10)))
  data.frame(start = seq(df$start, looptijd, df$pacing) + cumsum.rnd, end = sapply(seq(df$start + df$itersec, looptijd + df$itersec, df$pacing) + cumsum.rnd, function (val) {min(c(val, looptijd))}))
})

# ok, dan segment plot
qplot(data=iter, x=start, y=as.integer(vu.nra),  xend = end, yend = as.integer(vu.nra), geom="segment", colour = script)  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
 scale_x_continuous(limits=c(0, time2show))

# alleen de dingen met overlap: pacing < itersec
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where pacing < itersec")



maxtijd van elke vuser
ddply(iter, .(vu.nra), function(df) {
  c(maxtime = max(df$end)) 
})

# bug/feature van de segment plot, dingen niet laten zien als ze deels erbuiten vallen.
# of is dit optie die je kan zetten?

# qplot zegt nu ook niet dat 'ie punten removed heeft.
# opties:
# * niets aan doen, en endtime is zo groot in verhouding tot pacing dat het niet zo opvalt.
# * functie ergens ertussen, die waardes groter dan enttime op endtime zet.



# iets met random pacing, bv 60 sec +/- 10 sec
# dan looptijd wel max 60-10 = 50 sec, of evt max van waarde en looptijd nemen.

s = seq(0, 600, 60)
r = runif(10, min=-10, max = 10)

qplot(1:100, cumsum(runif(100, -10, 10)))

werkt wel, best gevarieerd, blijft lang niet altijd rond de 0 hangen.

de cumsum . runif moet er eigenlijk gewoon bij opgeteld worden.

test vectoren optellen, waarbij ze niet even lang zijn.

cs100 = cumsum(runif(100, -10, 10))

s = seq(0, 600, 60)

s + head(cs100, length(s))
dan wordt de korte herhaald, niet wat je wilt.

of bij genereren al length(s) waarden genereren.

# keuze: 1) eerst iter data.frame maken en dan randomizen, of 2) dit doen in de ddply die iter aanmaakt.
# eerst optie 2:

iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
  # per vuser, eerste random value is 0
  cumsum.rnd = c(0, cumsum(runif((looptijd - df$start) / df$pacing, -10, 10)))
  data.frame(start = seq(df$start, looptijd, df$pacing) + cumsum.rnd, end = sapply(seq(df$start + df$itersec, looptijd + df$itersec, df$pacing) + cumsum.rnd, function (val) {min(c(val, looptijd))}))
})

# vanuit deze beetje random data terug naar concurrent iterations.

# voorbeeld waarbij rampup en pacing niet op elkaar aansluiten: zowel met als zonder random.

# met combi van deze 2 is probleem te zien.

df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd)

# te snelle rampup: zowel rampevery als secrampup aanpassen.
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, 1 rampevery, 39 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")


# concurrent, eerst voorbeeld
df = data.frame(start = c(0,4,7,10), end = c(10,8,12,11))

# step functie van maken
df.step1 = ddply(df, .(start), function (df) {data.frame(ts=df$start[1], step=length(df$start))})
df.step2 = ddply(df, .(end), function (df) {data.frame(ts=df$end[1], step=-length(df$end))})
df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 

# eerst samenvoegen, dan arrange
df.steps = arrange(ddply(df.step, .(ts), function(df) {c(step=sum(df$step))}), ts)
df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.

qplot(data=df.steps, x=ts, y=count, geom="step", xlab = "Time", ylab = "#vusers")
# yes, nice.  


# dan op 1 script toepassen:
# df lezen, make.iter(full=TRUE) toepassen.
iter = make.iter(df, looptijd, full=TRUE)

> head(iter)
         script vu.nra vu.nr    start      end
1 01_I2F_MB1B.c      1     1   0.0000 110.0000
2 01_I2F_MB1B.c      1     1 142.8573 252.8573
3 01_I2F_MB1B.c      1     1 295.1063 405.1063
4 01_I2F_MB1B.c      1     1 432.3692 542.3692
5 01_I2F_MB1B.c      1     1 579.7417 689.7417
6 01_I2F_MB1B.c      1     1 723.0894 833.0894

df.step1 = ddply(iter, .(start), function (df) {data.frame(ts=df$start[1], step=length(df$start))})
df.step2 = ddply(iter, .(end), function (df) {data.frame(ts=df$end[1], step=-length(df$end))})
df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 

# eerst samenvoegen, dan arrange
df.steps = arrange(ddply(df.step, .(ts), function(df) {c(step=sum(df$step))}), ts)
df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.

qplot(data=df.steps, x=ts, y=count, geom="step", xlab = "Time", ylab = "#vusers")

df.count = make.count(iter)

qplot(data=df.count, x=ts, y=count, geom="line", xlab = "Time", ylab = "#vusers")

# maken en saven, iets langere looptijd:
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 1000, random=FALSE)
plot.count(make.count(iter))
# met random tussen 25 en 35, zonder tussen 27 en 32, grootste stuk op 32 steeds.
ggsave("rampup4-regular.png")

# dan deze testen met te snelle rampup:
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, 1 rampevery, 39 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 1000, random=FALSE)
plot.count(make.count(iter))
ggsave("rampup1-regular.png")
# dan tussen 6 en 40, helft van de tijd op 40.

# beide met random
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 1000, random=TRUE)
plot.count(make.count(iter))
# met random tussen 25 en 35, zonder tussen 27 en 32, grootste stuk op 32 steeds.
ggsave("rampup4-random.png")

df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, 1 rampevery, 39 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 1000, random=TRUE)
plot.count(make.count(iter))
ggsave("rampup1-random.png")

# weer tussen 6 en 40, dal komt wel steeds hoger, nogmaals met volledige looptijd
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, 1 rampevery, 39 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 7000, random=TRUE)
plot.count(make.count(iter))
ggsave("rampup1-random-7000.png")

# op het laatst tussen 28 en 35, trekt dan dus weer bij. Mooie grafiek wel.
plot.iter(iter)
# niets uit af te leiden, alleen hoop streepjes.

# dit was te snelle rampup, ook nog een te trage:
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, 10 rampevery, 390 secrampup, val2 itersec, val8 pacing from script where val0 like '01%'")
iter = make.iter(df, looptijd, time2show = 7000, random=TRUE)
plot.count(make.count(iter))
ggsave("rampup10-random-7000.png")
=> dat lijkt wel goed.

iter = make.iter(df, looptijd, random=TRUE)
plot.iter(iter)
ggsave("rampup10-random-iter.png")

# 1-11-2011 count graphs vanuit nieuwe model.db, met verschillende rampup's

# source load-graphs-functions
# deze in rampup-dir
db = init()
looptijd = dbGetQuery(db, "select val1 looptijd from globals where val0 like '%looptijd%'")$looptijd
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 = 'ramp12'")
iter = make.iter(df, looptijd, time2show = 7000, random=FALSE)
# iter = make.iter(df, looptijd, time2show = 7000, random=TRUE)
plot.count(make.count(iter))
ggsave("rampup10-random-7000.png")

# deze in pacing-dir
db = init()
looptijd = dbGetQuery(db, "select val1 looptijd from globals where val0 like '%looptijd%'")$looptijd
df = dbGetQuery(db, "select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 = 'ramp3.6'")
iter = make.iter(df, looptijd, time2show = 7000, random=FALSE)
# iter = make.iter(df, looptijd, time2show = 7000, random=TRUE)
plot.count(make.count(iter))
ggsave("rampup10-random-7000.png")

make.plot.count = function(db, script, time2show, random=FALSE) {
  looptijd = dbGetQuery(db, "select val1 looptijd from globals where val0 like '%looptijd%'")$looptijd
  df = dbGetQuery(db, paste("select val0 script, val7 vusers, val9 vusersper, val10 rampevery, val11 secrampup, val2 itersec, val8 pacing from script where val0 = '", script, "'",sep=""))
  iter = make.iter(df, looptijd, time2show = time2show, random=random)
  # iter = make.iter(df, looptijd, time2show = 7000, random=TRUE)
  plot.count(make.count(iter))
}

make.df = function(script, scenph, itersec, vu, scenps = scenph/3600, rampevery=1/scenps, pacing=vu/scenps, secrampup=rampevery*(vu-1)) {
  data.frame(script=script, vusers=vu, vusersper=1, rampevery=rampevery, secrampup=secrampup, itersec=itersec, pacing=pacing) 
}

df = make.df("test", 300, 30, 5)
df2 = make.df("test", 300, 30, 5, rampevery=10)

seq = 10:14
iter = make.iter(df, 3600, time2show = 500, random=FALSE)
cnt = make.count(iter)
> max(cnt$count)
[1] 3

maxconc = max(make.count(make.iter(make.df("test", 300, 30, 5, rampevery=10), 3600, time2show = 500, random=FALSE))$count)

maxconc = max(make.count(make.iter(make.df("test", 300, 30, 5, rampevery=seq), 3600, time2show = 500, random=FALSE))$count)
=> not

> sapply(seq, function(val) {val*10})
[1] 100 110 120 130 140

maxconc = sapply(seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 300, 30, 5, rampevery=re), 3600, time2show = 500, random=FALSE))$count)
})

allemaal 3, niet boeiend.

re.seq = c(3.6,1:25)

maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 1000, 110, 40, rampevery=re), 3600, time2show = 1000, random=FALSE))$count)
})

qplot(re.seq, maxconc)

maxconc = sapply(1:13, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 1000, 110, 40, rampevery=re), 3600, time2show = 500, random=FALSE))$count)
})

maxconc = max(make.count(make.iter(make.df("test", 1000, 110, 40, rampevery=13), 3600, time2show = 1000, random=FALSE))$count)
df = make.df("test", 1000, 110, 40, rampevery=25)

df.plot=data.frame(re=re.seq, maxconc=maxconc)

> qplot(data=df.plot,x=re,y=maxconc)
Error in get(x, envir = this, inherits = inh)(this, ...) : 
  attempt to apply non-function
=> ligt eraan dat ik nog een seq variabele heb, botst ergens met seq-functie.

# tot 50
re.seq = c(3.6,1:50)
maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 1000, 110, 40, rampevery=re), 3600, time2show = 2000, random=FALSE))$count)
})
qplot(re.seq, maxconc)

calc.int = trunc(re.seq / 3.6)
calc.frac = re.seq / 3.6 - calc.int 

X11() # om nieuw window te openen.
qplot(re.seq, calc.frac) 
# doet het wel, niet een relatie te zien.

# net andersom?
calc.int = trunc(3.6 / re.seq)
calc.frac = 3.6 / re.seq - calc.int 
# => zeker niet.

# nadenken?
# iets van itersec / re: de 1e iter van vu-1 draait. Hoeveel starten er verder in deze periode?
calc.frac = 110 / re.seq
calc.frac = pmin(40, 110 / re.seq)
qplot(re.seq, calc.frac) +
  scale_y_continuous(limits = c(30, 40))

Voor de eersten klopt het dan wel: 1,2,3,3.6. Bij 3 op 37 afgerond.

# Voor testen iets van 10 doen?

iter = make.iter(make.df("test", 180, 110, 10), 3600, time2show = 500, random=FALSE)


plot.iter(iter)
X11()
plot.count(make.count(iter))

# calc=20, test 25
iter = make.iter(make.df("test", 180, 110, 10, rampevery=25), 3600, time2show = 500, random=FALSE)

ook hier een serie.
re.seq = 1:80
maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 180, 110, 10, rampevery=re), 3600, time2show = 1000, random=FALSE))$count)
})

# make.df("test", 180, 110, 10, rampevery=60)
# voor alle re's kleiner dan re.calc
df = make.df("test", 180, 110, 10)
=> re.calc=20
maxconc.calc = pmin(ceiling(110/re.seq), 10)

df.check = data.frame(re=re.seq, maxconc=maxconc, maxconc.calc=maxconc.calc)
# ok, tot 20 klopt het precies.
# bij 21 ook nog ok, maar bij 22 6/5 en bij 23 7/5.

# neem 23 als testcase
iter23 = make.iter(make.df("test", 180, 110, 10, rampevery=23), 3600, time2show = 1000, random=FALSE)
cnt23 = make.count(make.iter(make.df("test", 180, 110, 10, rampevery=23), 3600, time2show = 1000, random=FALSE))

# rond de 210 op max van 7, verder rond de 6 en af en toe naar 5 en 4.
# 2 sec overlap van 7, van 292 sec tot 294 sec.
qplot(re.seq, maxconc)

try1 = 110 - (maxconc.calc - 1) * re.seq

voor overlap 2e en 1e iteratie, ga uit van maxconc.calc (is overlap binnen iteratie).


try2 = (9 * re.seq + 110) - ((maxconc.calc - 1) * re.seq + 200)

try3 = ceiling(try2 / re.seq)
try4 = pmax(0, try3)
try5 = try4 + maxconc.calc

df.try5 = data.frame(re = re.seq, maxconc=maxconc, try5=try5, maxconc.calc=maxconc.calc)
# dit gaat goed tot en met 34, bij 35 fout.
qplot(re.seq, df.try5$try5)

make.plots.iter = function(re) {
  iter.re = make.iter(make.df("test", 180, 110, 10, rampevery=re), 3600, time2show = 1000, random=FALSE)
  cnt.re = make.count(make.iter(make.df("test", 180, 110, 10, rampevery=23), 3600, time2show = 1000, random=FALSE))
  #X11()
  #plot.iter(iter.re)
  #X11()
  #plot.count(cnt.re)
  c(iter.re, cnt.re)
}
# werkt niet zo, even los. Komt omdat de eerste x11() leeg blijft, misschien een wait-cmd erin?
# make.plots.iter(34)

iter.re = make.iter(make.df("test", 180, 110, 10, rampevery=34), 3600, time2show = 1000, random=FALSE)
cnt.re = make.count(make.iter(make.df("test", 180, 110, 10, rampevery=23), 3600, time2show = 1000, random=FALSE))

# 2 benaderingswijzen:
# * ofwel met kleine #vu, dan discreet benaderen.
# * ofwel met groot #vu (bv 100), dan continue benaderen, vgl binomiaal vs poisson?

# Verder met series, met veel combi's de data + grafieken maken, kijken of hier verband te ontdekken is.
# eerst dus 'continue' aanpakken, met 100 users.
# wil varieren met rampevery, en itersec, dan hou ik pacing constant: N/X = 100 / (1800/3600) = 200.
re.seq = 1:80
maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 1800, 110, 100, rampevery=re), 3600, time2show = 1000, random=FALSE))$count)
})

df=make.df("test", 360, 110, 100)
iter=make.iter(df, 3600, time2show = 3600, random=FALSE)
cnt = make.count(iter) 
# rechte lijn op 11,re = 10, pacing=1000

df1 = make.df("test", 360, 110, 100, rampevery=1)
iter1=make.iter(df1, 3600, time2show = 3600, random=FALSE)
cnt1 = make.count(iter1) 
max(cnt1$count)

> make.df("test", 3600, 950, 100, rampevery=80)
  script vusers vusersper rampevery secrampup itersec pacing
1   test    100         1        80      7920     950    100

looptijd op 20.000 gezet, om met rampup van 7920 ook nog lang genoeg te hebben.

calc.maxconc = function(itersecperc=0.75, re.seq=1:80, xph=360, xps = xph/3600, nvu=100) {
  # re.seq = 1:80
  # re.seq = 1:5
  pacing = nvu / xps
  itersec = itersecperc * pacing
  df1 = make.df("test", xph, itersec, nvu)
  print(df1)
  # todo: re als factor op re.def.
  maxconc = sapply(re.seq, function(re) {
    print(paste(itersec,"-",re,":",Sys.time()))
    df = make.df("test", xph, itersec, nvu, rampevery=re)
    print(df)
    runtime = df$secrampup * 3
    maxconc = max(make.count(make.iter(df, runtime, time2show = runtime, random=FALSE))$count)
  })
  qplot(re.seq, maxconc, main=paste("itersec-",itersec,sep=""))
  ggsave(paste("maxconc-itersec-",itersec,".png",sep=""), dpi=100, width=8, height=6)
  df.out = data.frame(rampevery=re.seq, maxconc=maxconc)
  print(df.out)
  write.csv(df.out, file=paste("maxconc-itersec-", itersec, ".csv", sep=""), row.names=FALSE)
}

calc.maxconc.itersecs = function() {
  for (i in .05 * 1:19) {
    print(i)
    calc.maxconc(i,1:120)
  }
}

# ook uitzetten met rampup-total, pacing en itersec, mogelijk in een grid-graph, steeds 2 aan 2.
# maar toch is maxconc afhankelijk van meer dan 1 ding.

# test bij itersec=600 en re=1
calc.maxconc(600, 1:1)

# pacing is hier 100, dus dan fout met itersec van 600.

# test met oorspronkelijke:
re.seq = 1:80
re.seq = 1:2
maxconc = sapply(re.seq, function(re) {
  maxconc = max(make.count(make.iter(make.df("test", 180, 110, 10, rampevery=re), 3600, time2show = 1000, random=FALSE))$count)
})

maar dan wel met nieuwe functie:
calc.maxconc(110/200, 1:40,xph=180,nvu=10)


# @todo vergelijkbaar correlatie onderzoek als bij Aegon, van welke params is het afhankelijk.
# bij berekening: ofwel naar Clojure omzetten, ofwel kijken naar periode dat rampup klaar is.
# beetje raar: als je lange rampup wil (van de hele looptijd), is de concurrency gedurende de rampup ook belangrijk. Eigenlijk wil je de actuele concurrency tov de verwachte en aantal vusers op dat moment weten.
# als tijdens de lange rampup de concurrency erg varieert, wil je 1) niet en 2) weten.

# Spelen hier meerdere aspecten: 1) gewoon boeiend, hoe het gedraagt het zich en 2) praktisch, waar moet je rekening mee houden bij verschillende soorten tests? Dus dan weer de 10 mogelijkheden van input en ook dat rmpevery
# minder strikt van pacing en nvu afhangt.

# en nu alleen nog maar over iteraties, straks/later ook de transacties binnen een iteratie erbij.

# De berekende rampevery hier is 10 seconden, totale rampup daardoor 1000 seconden, pacing is ook 1000 seconden, logisch.
# goede r.e.'s lijken dan 10 * (1 + 2 * 1:10) te zijn, ofwel 10, 30 ,50 , 70 sec etc. Wel opvallend dat soms waarden hier vlakbij wel hoge conc's opleveren. Ook eens kijken met random, hoe het dan gaat.

