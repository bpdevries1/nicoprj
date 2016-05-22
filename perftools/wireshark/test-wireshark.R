library(ggplot2)
library(RSQLite)

plot.network = function(db_name, ipsrc = "10.16.16.205") {
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where ipsrc = '", ipsrc, "'", sep = ""))
  dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum")
  ggplot(x=time, y=segment) + 
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S")
  ggsave(paste(db_name, ".png", sep=""), width = 10, height = 8, dpi=100)
}


db_name = "1109a.db"
db = dbConnect(dbDriver("SQLite"), db_name)

# df = dbGetQuery(db, "select tcpstream, first, last, portdst from tcpstream where ipdst = '10.17.224.130'")
df = dbGetQuery(db, "select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where ipsrc = '10.16.16.205'")

#qplot(data=df, x=first, y=tcpstream, xend = last, yend = tcpstream, geom="segment", colour = as.factor(dest))  +
# opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
 
 
qplot(data=df, x=first, y=tcpstream, xend = last, yend = tcpstream, geom="segment", colour = as.factor(dest))  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
 scale_x_datetime(format="%H:%M:%S")
 
# zie wel meer dan 2 connecties, ook al was (volgens mij) dit op mijn laptop eerst niet ingesteld.
# verder http get/post en antwoorden laten zien, automatisch disconnect na 20 sec niets?

# TODO:
# zelfde graph voor andere client opnames, ook alleen dingen naar de server.

dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum")

qplot(data=dfr, x=req, y=stream, xend = resp, yend = stream, geom="segment", size=I(2))  +
 scale_x_datetime(format="%H:%M:%S")
 

dfr120 =  dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and r.stream=120")

qplot(data=dfr120, x=req, y=stream, xend = resp, yend = stream, geom="segment")  +
 scale_x_datetime(format="%H:%M:%S")

qplot(data=dfr120, x=req, y=stream, xend = resp, yend = stream, geom="segment", size=I(2))  +
 scale_x_datetime(format="%H:%M:%S")

 p <- ggplot(df, aes(x=x, y=y)) +
     geom_point() +
     geom_segment(aes(xend=c(tail(x, n=-1), NA), yend=c(tail(y, n=-1), NA)),
                  arrow=arrow(length=unit(0.3,"cm")))

qplot(data=dfr120, x=req, y=stream, xend = resp, yend = stream, geom="segment", size=I(2))  +
 scale_x_datetime(format="%H:%M:%S") +
 arrow(length=unit(0.3, "cm"))
                  
qplot(data=dfr120, x=req, y=stream, xend = resp, yend = stream, geom="segment", size=I(2), arrow.len=10)  +
 scale_x_datetime(format="%H:%M:%S")
 
 arrow.len=.05
 
ggplot(dfr120, aes(x=time, y=stream)) +
  geom_segment(aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))
 
ggplot(dfr, aes(x=time, y=stream)) +
  geom_segment(aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))
# ok
  
qplot(data=df, x=first, y=tcpstream, xend = last, yend = tcpstream, geom="segment", colour = as.factor(dest))  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
 scale_x_datetime(format="%H:%M:%S") +
 geom_segment(aes(x=dfr$req, y=dfr$stream, xend = dfr$resp, yend = dfr$stream), arrow=arrow(length=unit(0.1,"cm")))
# fout

off = c(0, 2000, 4000, 6000, 25, 3000, 6050, 9000)
tim = c( 0, -100, -200, -300, -25, -125, -225, -325)
col = c( 1, 1, 1, 1, 2, 2, 2, 2)
dataf = data.frame(off, tim, col)
p = ggplot(dataf, aes(off, tim, color=col)) + geom_point() + geom_line()
p

ggplot(dataf, aes(off, tim, color=factor(col))) + geom_point() + geom_line()

p = qplot(data=df, x=first, y=tcpstream, xend = last, yend = tcpstream, geom="segment", colour = as.factor(dest))  +
 opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
 scale_x_datetime(format="%H:%M:%S")

p2 = p + geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))

df1 = data.frame(c11 = c(1:5), c12 = c(1:5))
df2 = data.frame(c21 = c(1:5), c22 = (c(1:5))^0.5)
df3 = data.frame(c31 = c(1:5), c32 = (c(1:5))^2)
p <- ggplot() + geom_line(data=df1, aes(x=c11, y = c12)) + 
     geom_line(data=df2, aes(x=c21,y=c22)) + 
     geom_line(data=df3, aes(x=c31, c32))

p = ggplot() + 
  geom_segment(data=df, x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest)) +
  opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
  scale_x_datetime(format="%H:%M:%S")
  
p = ggplot() + 
  geom_segment(data=df, x=df$first, y=df$tcpstream, xend = df$last, yend = df$tcpstream, colour = as.factor(df$dest))  
  
p = ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest)))  
# ok

p = ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))
# ok

ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest)), size=I(1.5)) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
  opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
  scale_x_datetime(format="%H:%M:%S")

# stel dat ik where in tcpstream even weghaal:
df = dbGetQuery(db, "select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream")
# dan geen touw meer aan vast te knopen!

# andersom, ook alleen pijltjes -> nee, laat maar.

# size weg:
ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
  opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
  scale_x_datetime(format="%H:%M:%S")

t1 = min(df$first)
t2 = max(df$first)
t13 = .3 * (t2 - t1) + t1
dftrans = data.frame(start = c(t1, t13+100), stop = c(t13, t2), name=c('start', 'login'))

ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
  geom_rect(data=dftrans, aes(xmin=start, ymin = 0, xmax=stop, ymax=150, colour = name), alpha=I(.1)) +
  opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
  scale_x_datetime(format="%H:%M:%S")

# colours nu samengevoegd en beetje doorgestreept, niet goed.
ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
  geom_rect(data=dftrans, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
  scale_x_datetime(format="%H:%M:%S")
# ok

# met text
ggplot() + 
  geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
  geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
  geom_rect(data=dftrans, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dftrans, aes(x=start, y=0, label=name, hjust=1, vjust=1, angle=90)) +
  opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
  scale_x_datetime(format="%H:%M:%S")

# tekst van sitescope log uitlezen
dfs = read.csv("site-1500.csv")
dfs1 = dfs[1:8,]
# eerst log, tijden kloppen ook niet.
ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=0, label=transaction, hjust=1, vjust=1, angle=90)) +
  scale_x_datetime(format="%H:%M:%S")
  
# tekst beneden afgekapt.
ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=0, label=transaction, hjust=1, vjust=0, angle=90)) +
  scale_x_datetime(format="%H:%M:%S")
# nog steeds beneden, en nu links van de lijn.
ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=0, label=transaction, hjust=0, vjust=1, angle=90)) +
  scale_x_datetime(format="%H:%M:%S")
# lijkt goed

# verticale strepen als scheiding
ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=0, label=transaction, hjust=0, vjust=1, angle=90)) +
  geom_vline(data=dfs1, aes(x=start)) +
  scale_x_datetime(format="%H:%M:%S")
# doet raar, segment proberen.

ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=0, label=transaction, hjust=0, vjust=1, angle=90)) +
  geom_segment(data=dfs1, aes(x=start, y=0, xend = start, yend = 150)) +
  scale_x_datetime(format="%H:%M:%S")
  
# tekst eens van boven, wel verticaal:
ggplot() +
  geom_rect(data=dfs1, aes(xmin=start, ymin = 0, xmax=stop, ymax=150), alpha=I(.1)) +
  geom_text(data=dfs1, aes(x=start, y=150, label=transaction, hjust=1, vjust=1, angle=90)) +
  geom_segment(data=dfs1, aes(x=start, y=0, xend = start, yend = 150)) +
  scale_x_datetime(format="%H:%M:%S")
# werkt prima!

select p2.timestamp - p1.timestamp dur, p1.*, p2.*
from packet p1, packet p2, roundtrip r
where r.stream = 2
and r.req_num = p1.packetnum
and r.resp_num = p2.packetnum
order by p2.timestamp - p1.timestamp desc;

df = dbGetQuery(db, "select p2.timestamp - p1.timestamp dur, p1.*, p2.*
from packet p1, packet p2, roundtrip r
where r.stream = 2
and r.req_num = p1.packetnum
and r.resp_num = p2.packetnum
order by p2.timestamp - p1.timestamp desc")


plot.network.trans2 = function(db_name, ipsrc = "10.16.16.205", transfile) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where tcpstream = 2 and ipsrc = '", ipsrc, "'", sep = ""))
  dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and r.stream = 2")
  print(dfr)
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  dfs = read.csv(transfile)
  # dfs$maxs = maxs
  dfs$maxs = max(df$tcpstream)
  
  ggplot(x=time, y=segment) + 
    # geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
    geom_rect(data=dfs, aes(xmin=start, ymin = 0, xmax=stop, ymax=maxs), alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs, label=transaction, hjust=0, vjust=0)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec")

  ggsave(paste(db_name, ".png", sep=""), width = 10, height = 8, dpi=100)
  dbDisconnect(db)
}

# 14-2-2012 nu word add in traces bekijken.
show.ips("/media/nas/aaa/kg-word-addin/capture01.db")
  count(*)         ipsrc
1     9273 10.17.224.130
2     6906   10.16.19.49
3      648  10.17.224.38
4      277  10.17.224.35
5       44   10.17.224.7

Dus 10.16.19.49 is idd client PC IP address.

# eerst zonder trans:
plot.network("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49")
# doet het wel, maar start- en eindtijden (trans) zijn wel essentieel.
# ofwel trans bestand maken en evt optie voor start en eindtijd, of de hele query.

plot.network.trans("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-laptop-ndv-trans.csv")

# lijkt het wel te doen, alleen nu veel te veel.

[2012-02-10 11:09:02.495] [1] brieven en verslagen.
[2012-02-10 11:10:07.587] [2] brieven en verslagen.
[2012-02-10 11:10:09.130] [3] brieven en verslagen.


db_name = "/media/nas/aaa/kg-word-addin/capture01.db" 
ipsrc="10.16.19.49"
transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv"
starttime=1328868542.01
endtime=1328868608.6450002

# queries geven lege resultset.
select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream s where s.ipsrc = '10.16.19.49' and s.first between 1328872142.01 and 1328872208.6450002 limit 5;

sqlite> select min(first), max(first) from tcpstream;
1328868380.33475|1328868965.7539

plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002)

[1] 7
Error in eval(expr, envir, enclos) : object 'req' not found

# dfr is nog steeds leeg.

select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and s.tcpstream=r.stream and s.first between 1328868542.01 and 1328868608.6450002 limit 5;
# zijn er idd niet.

select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and s.tcpstream=r.stream limit 5;
# zijn er wel.

select min(p1.timestamp), max(p1.timestamp) from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and s.tcpstream=r.stream limit 5; 
# 
min: 1328868405.80533
sta: 1328868542.01
end: 1328868608.6450002
max: 1328868965.75614

sta/end wel tussen min/max.

select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and s.tcpstream=r.stream order by s.first limit 500;


sqlite> select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum and r.resp_num = p2.packetnum and s.tcpstream=r.stream order by s.first limit 500;
12|1328868407.22694|1328868407.22785
12|1328868407.84674|1328868407.84934
23|1328868426.48256|1328868427.79037

sta: 1328868542.01
end: 1328868608.6450002

291|1328868835.93826|1328868835.93911
291|1328868835.94283|1328868835.97346
291|1328868835.97484|1328868835.9762

Feitelijk klopt het dus, geen roundtrips tussen de tijden. Kan zijn dat er geen http request zijn (req/resp) waar ik op check. Kan goed, want alleen word add-in.

plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002)




scale_x_continuous(limits = c(-5000, 5000))
=> hiermee idd datapunten weg, zoals ik nu zie.
or

coord_cartesian(xlim = c(-5000, 5000))
+ xlim(-5000,5000) + ylim(-5000,5000)
=> hiermee alleen aanpassing van de asses, wat ik wil.

oud: , limits=c(starttime, endtime)) +

db_name = "/media/nas/aaa/kg-word-addin/capture01.db" 
ipsrc="10.16.19.49"
transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv"
starttime=1328868542.01
endtime=1328868608.6450002

plot.network.trans.startend("/media/nas/aaa/kg-word-addin/test-alles-ignore6439.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeer")

# 2e snelle keer, nog voor herstart
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/test-alles-ignore6439.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-2ekeer.csv", starttime=1328868764, endtime=1328868778, outbasename="/media/nas/aaa/kg-word-addin/2ekeer")

# 3e keer ook sneller, na inloggen weer denk ik.
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/test-alles-ignore6439.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-3ekeer.csv", starttime=1328868897, endtime=1328868911, outbasename="/media/nas/aaa/kg-word-addin/3ekeer")
# lege result.

# ofwel andere db:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-3ekeer.csv", starttime=1328868897, endtime=1328868911, outbasename="/media/nas/aaa/kg-word-addin/3ekeer")

# ziet er best anders uit dan 2e keer, dus 2e keer nogmaals met ook deze .db:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-2ekeer.csv", starttime=1328868764, endtime=1328868778, outbasename="/media/nas/aaa/kg-word-addin/2ekeer")
# ziet er toch wel wat anders uit, waarsch doordat andere (test) db niet alles heeft.

# dan dus eerste ook nog een keer:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeer")

# capture02, take 4 en 5:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-4ekeer.csv", starttime=1328869609, endtime=1328869649, outbasename="/media/nas/aaa/kg-word-addin/4ekeer")
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-5ekeer.csv", starttime=1328869727, endtime=1328869745, outbasename="/media/nas/aaa/kg-word-addin/5ekeer")

# inloggen na reboot eerste keer ook ruim 10 sec:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-inloggen.csv", starttime=1328869540, endtime=1328869555, outbasename="/media/nas/aaa/kg-word-addin/inloggen")

# query voor bepalen aantallen en sizes per server:port en tijdsperiode.
# bv eerst take 5:
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328869728.9172
and s.first < 1328869743.5911999
and p.timestamp between 1328869728.9172 and 1328869743.5911999
group by dest;

=>
2469|2194689|10.17.224.130:81
2|122|10.17.224.30:139
1117|233487|10.17.224.30:445

en take 4 (1e keer na inloggen, dus meer):
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328869610.8622
and s.first < 1328869647.7922
and p.timestamp between 1328869610.8622 and 1328869647.7922
group by dest;

2406|2168559|10.17.224.130:81
3|178|10.17.224.151:139
58|12824|10.17.224.151:445
12|4024|10.17.224.151:88
8|888|10.17.224.20:135
17|5709|10.17.224.20:49155
2|122|10.17.224.30:139
4527|1091242|10.17.224.30:445
2|114|10.19.224.52:139

=> idd meer, vooral naar andere servers toe, hoewel meeste verkeer nog steeds naar 2 servers: 130:81 en 30:445. Van de 30:445 nog niet bekend wat dit is, Michel weer vragen.

# Dan ook take 1-3 van eerste db:
# take 1:
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328868542.01
and s.first < 1328868608.6450002
and p.timestamp between 1328868542.01 and 1328868608.6450002
group by dest;

2558|2180469|10.17.224.130:81
3|178|10.17.224.152:139
21|5210|10.17.224.152:445
3|178|10.17.224.35:139
427|390343|10.17.224.35:445
18|1610|10.17.224.5:82
7|406|10.17.224.5:8445
6|418|10.19.224.100:139
37|10612|10.19.224.100:445

=> hier dus de 35:445, vermoed iets vergelijkbaars als de 30:445. naar horizon vergelijkbaar aantal, naar deze 35 dus iets minder. Rest is echt veel minder.

# take 2
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328868764.4980001
and s.first < 1328868776.5730002
and p.timestamp between 1328868764.4980001 and 1328868776.5730002
group by dest;

2509|2195997|10.17.224.130:81
4|228|10.17.224.151:135
4|228|10.17.224.152:135
2|114|10.17.224.7:139
2|114|10.19.224.52:139

# dan dus helemaal niets van file server, we zitten hier nog wel in dezelfde browser sessie.

# take 3 is na afsluiten browser:
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328868898.0010002
and s.first < 1328868909.4910002
and p.timestamp between 1328868898.0010002 and 1328868909.4910002
group by dest;

2430|2194484|10.17.224.130:81
10|540|10.17.224.38:80
2|114|10.17.224.7:139

# hier dus eigenlijk ook alleen maar horizon server. Wel zo dat van 38:80 de lijnen stoppen, andere lijnen op horizon weer doorgaan.

# wil http export doen, dan wel nodig bepaalde packets te 'ignoren', hoe deze in huidige db te vinden:
# zoek tcpstreams met veel packets:
select count(*), tcpstream
from packet
group by tcpstream
having count(*) > 1000;

# dan de laatste(n) per stream:
select * from packet
where tcpstream = 162
order by packetnum desc
limit 10;

select * from packet
where tcpstream = 264
order by packetnum desc
limit 10;

select * from packet
where tcpstream = 373
order by packetnum desc
limit 10;

# ook voor capture02:

# gedaan, streams 94 en 71, packets 9597 en 18453 resp.

# met capture01http-3ignore nog eens grafieken, is dit hetzelfde?
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01http-3ignore.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeer-http")

# 15-2-2012 NdV na hele tijd nu ook van packet 4384 bekend dat het een POST-REQ is, kijken of grafieken er nu anders uitzien, ook de pijltjes grafieken doen.
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeerc")

# dan met de pijltjes, plot.network.trans.startend.http wat aangepast, ook outbasename
plot.network.trans.startend.http("/media/nas/aaa/kg-word-addin/capture01c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeerc-http")

# test (eerst in oude) of er in een stream een response is zonder request. Evt kun je dit in roundtrip markeren als een pijl vanaf het begin van de stream tot de respons.
select * from packet presp
where presp.outerreqresp='OUTERRESP'
and not exists (
  select 1
  from packet preq
  where preq.tcpstream = presp.tcpstream
  and preq.packetnum < presp.packetnum
  and preq.outerreqresp = 'OUTERREQ'
) limit 20;

and presp.tcpstream = 159;

# andersom, REQ zonder resp?
select * from packet preq
where preq.outerreqresp='OUTERREQ'
and not exists (
  select 1
  from packet presp
  where preq.tcpstream = presp.tcpstream
  and preq.packetnum < presp.packetnum
  and presp.outerreqresp = 'OUTERRESP'
) limit 100;

plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-eerstekeer.csv", starttime=1328868542.01, endtime=1328868608.6450002, outbasename="/media/nas/aaa/kg-word-addin/1ekeerc")
# zowaar in een keer goed, nog wel leesbaar.

# dan ook de andere 4:


plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-2ekeer.csv", starttime=1328868764, endtime=1328868778, outbasename="/media/nas/aaa/kg-word-addin/2ekeerc")
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture01c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-3ekeer.csv", starttime=1328868897, endtime=1328868911, outbasename="/media/nas/aaa/kg-word-addin/3ekeerc")



select r.*, p2.timestamp-p1.timestamp 
from roundtrip r, packet p1, packet p2 
where r.stream=240
and r.req_num = p1.packetnum
and r.resp_num = p2.packetnum
limit 10;
=> 1.7 sec

select r.*, p2.timestamp-p1.timestamp 
from roundtrip r, packet p1, packet p2 
where r.stream=240
and r.req_num=8948
and r.req_num = p1.packetnum
and 10960 = p2.packetnum
limit 10;

# wat zit ertussen?
select * from packet
where packetnum between 10961 and 10996;

# alle roundtrips groter dan 1 seconde:
select r.*, p2.timestamp-p1.timestamp dur 
from roundtrip r, packet p1, packet p2 
where r.req_num = p1.packetnum
and r.resp_num = p2.packetnum
and dur > 1
limit 10;

# eerst export vanuit linux van deel2:
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-4ekeer.csv", starttime=1328869609, endtime=1328869649, outbasename="/media/nas/aaa/kg-word-addin/4ekeerc")
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-5ekeer.csv", starttime=1328869727, endtime=1328869745, outbasename="/media/nas/aaa/kg-word-addin/5ekeerc")
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-inloggen.csv", starttime=1328869540, endtime=1328869555, outbasename="/media/nas/aaa/kg-word-addin/inloggenc")

# 4e en 5e even breed door end-start gelijk te stellen, beide bv 30 sec, zit toch wel speling in
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-4ekeer.csv", starttime=1328869609, endtime=1328869639, outbasename="/media/nas/aaa/kg-word-addin/4ekeerc2")
plot.network.trans.startend("/media/nas/aaa/kg-word-addin/capture02c.db", ipsrc="10.16.19.49", transfile="/media/nas/aaa/kg-word-addin/stopwatch-5ekeer.csv", starttime=1328869727, endtime=1328869757, outbasename="/media/nas/aaa/kg-word-addin/5ekeerc2")


select * from packet
where tcpstream < 20
and details <> ''
and details like '%log%'
limit 20;


# Dan ook take 1-3 van eerste db, hier herhaald:
# take 1:
select count(*), sum(p.packetsize), s.ipdst||':'||s.portdst dest 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328868542.01
and s.first < 1328868608.6450002
and p.timestamp between 1328868542.01 and 1328868608.6450002
group by dest;

# alle REQs laten zien:
select s.ipdst||':'||s.portdst dest, p.tsfmt, p.details 
from packet p, tcpstream s
where p.tcpstream = s.tcpstream
and s.ipsrc = '10.16.19.49' 
and s.last > 1328868542.01
and s.first < 1328868608.6450002
and p.timestamp between 1328868542.01 and 1328868608.6450002
and p.outerreqresp='OUTERREQ';

# 16-2-2012
# verwijder alles met 10.17.187.155, is de sentinel

tcpstream, packet, roundtrip

# eerst packet, dan rest als geen link meer is.
select count(*) from packet;
# 10536.

delete from packet
where ipsrc = '10.17.187.155' or ipdst = '10.17.187.155';
# 874 records over, best weinig.

delete from tcpstream where ipsrc = '10.17.187.155' or ipdst = '10.17.187.155';
Dan 45 streams over.

delete from roundtrip 
where not exists (
  select 1
  from packet p
  where p.packetnum = roundtrip.req_num
);
# eerst 99 in roundtrip
select count(*) from roundtrip;
# en hierna nog steeds, kan best, als vanaf sentinel geen http verkeer wordt gedaan.

# dan de plot:
plot.network.trans.startend("/media/nas/aaa/kg-soetekouw/cap16.db", ipsrc="10.17.187.139", outbasename="/media/nas/aaa/kg-soetekouw/cap16")

select * from packet where outerreqresp='OUTERREQ';

select count(*) from packet where outerreqresp='OUTERREQ';
# dit zijn er 99, net zoveel als roundtrip dus.

select tsfmt, ipdst, details from packet where outerreqresp='OUTERREQ';

plot.network.trans.startend("/media/nas/aaa/kg-soetekouw/cap01.db", ipsrc="10.17.187.139", outbasename="/media/nas/aaa/kg-soetekouw/cap01")

select tsfmt, ipdst, portdst, details from packet where outerreqresp='OUTERREQ';

select tsfmt, ipdst, portdst, details from packet where outerreqresp='OUTERREQ' and details like '%load%';
# geen load in deze periode.

select packetnum, tsfmt, ipdst, portdst, details from packet where portdst=7030;

select timestamp, tsfmt, ipdst, portdst, details from packet where outerreqresp='OUTERREQ' and details like '%LOGIN%';


1328771543

plot.network.trans.startend("/media/nas/aaa/kg-soetekouw/cap01.db", ipsrc="10.17.187.139", starttime=1328771443, endtime=1328772043, outbasename="/media/nas/aaa/kg-soetekouw/login")
