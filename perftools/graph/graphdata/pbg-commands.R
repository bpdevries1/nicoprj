setwd("~/Ymor/Parnassia/Resultaten")

openlibs()

db = opendb("appserverlog.db")

# eerst busy servers zien.
query = "select ts, value from logline where name = 'Busy Servers'"
df = openquery(db, query)
head(df)
qplot(tspsx, value, data=df)

#13:08 Broker Name                    : ggztst
#13:08 Operating Mode                 : Stateless
#13:08 Broker Status                  :  ACTIVE 
#13:08 Broker Port                    : 3194
#13:08 Broker PID                     : 29154

query = "select ts, name, value from logline where name not like 'Broker%' and name not like 'Operating%'"
df = openquery(db, query)
head(df)

qplot(tspsx, value, data=df) +
  facet_grid(name ~ .)

# independent y-axis en/of in groepen doen.
# servers, client, requests, _ms
plotmulti(db, query)
plotmulti(db, "select ts, name, value from logline where name like '%Servers%'", title="Servers")
plotmulti(db, "select ts, name, value from logline where name like '%Client%'", title="Clients")
plotmulti(db, "select ts, name, value from logline where name like '%_ms%'")

# kijken of counts van AVAILABLE en SENDING dezelfde zijn als total count in de log.
plotmulti(db, "select ts, value name, count(*) value from processline where name='state' group by 1,2 order by 1,2", title="ProcessCounts")
# inderdaad dus, dus op process niveau weinig extra info.

# qperf ingelezen, geen headerline, dus valX genoemd. Deze alle plotten.
plotmulti(db, "select ts, name, value from qperfline", title="QPerf", height=30)

# authentication0, aantal logins per timestamp.
db = opendb("appserverlog.db")
df = openquery(db, "select ts, count(*) aantal from auth group by ts")
head(df)

plotsingle(db, "select ts, count(*) value from auth group by ts", title = "AuthPerSecond")
# zie je ook nog wel verder toenemen, dus dit lijkt niet beperkende factor te zijn.

# per minuut en plotten.
ts.seq = seq(from=min(df$tspsx, na.rm=TRUE), to=max(df$tspsx, na.rm=TRUE), by = as.difftime(1, units="mins"))
head(ts.seq)
df$tscut=cut(df$tspsx, ts.seq)
head(df)
df2 = ddply(df, .(tscut), function(df) {
  data.frame(aantal = sum(df$aantal))
})
head(df2)
summary(df2)

df2$tspsx = strptime(df2$tscut, format="%Y-%m-%d %H:%M:%S")

qplot(tspsx, aantal, data=df2)

plot.single.tsgrp(db, "select ts, count(*) aantal from auth group by ts", title="Logins-per-minute")

# de '20' bestanden
db = opendb("log20.db")
plot.multi(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001", title="Garbage collection")

# jmx8181
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%jmx8181/20' and length(value) < 20 and 1.0*value >= 0.001", title="JMX8181")

qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%ldap/20' and length(value) < 20 and 1.0*value >= 0.001", title="LDAP")
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%mem/20' and length(value) < 20 and 1.0*value >= 0.001", title="Mem(ory)")
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%psyodbc/20' and length(value) < 20 and 1.0*value >= 0.001", title="psyodbc")
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%qweb/20' and length(value) < 20 and 1.0*value >= 0.001", title="qweb")
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%thr/20' and length(value) < 20 and 1.0*value >= 0.001", title="Thr(eads)")
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%zorg/20' and length(value) < 20 and 1.0*value >= 0.001", title="Zorg")

# lange regels uit garb nu uitgesplits (wel wat werk), opnieuw plotten, veel dubbele waarden waarsch.
open.libs()
db = open.db("log20.db")
plot.multi(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001", title="Garbage collection")
# nog best veel, nu alleen beginnen met *
plot.multi(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001 and name not like '*%'", title="Garbage collection")
plot.multi(db, "select ts, name, 1.0*value value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001 and name like '*%'", title="Garbage collection Details")

plot.multi(db, "select ts, name, 1.0*value value from tab20 where filename like '%mem/20' and length(value) < 20 and 1.0*value >= 0.001 and name like '*%'", title="Mem(ory) Details")

db = open.db("prgperf.db")
plot.multi(db, "select ts, name, value from prgperf where filename like '%epd.txt'", title="Epd.txt")
plot.multi(db, "select ts, name, value from prgperf where filename like '%gks.txt'", title="Gks.txt")
# plot.multi(db, "select ts, name, value from prgperf where filename like '%mem.txt'", title="Mem.txt")
plot.multi(db, "select ts, name, value from prgperf where filename like '%pal.txt'", title="Pal.txt")
plot.multi(db, "select ts, name, value from prgperf where filename like '%psy.txt'", title="Psy.txt")

