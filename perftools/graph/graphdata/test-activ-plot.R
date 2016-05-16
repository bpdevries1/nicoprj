# activity plot, horizontal lines for tasks

library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

ts.seq = seq(from=strptime("2011-09-13", format = "%Y-%m-%d"), to=strptime("2011-09-14", format = "%Y-%m-%d"), length.out=25)
min30 = (ts.seq[2] - ts.seq[1]) / 2

df = data.frame(start=ts.seq, end=ts.seq + min30, y = 1)

sec1 = min30 / 1800

# df is source
df2 = ddply(df, .(start), function (df) {
  data.frame(ptype = c('start', 'end', 'NA'), ts = c(df$start, df$end, df$end + sec1), y = c(1, 1, NA))
})

qplot(ts, y, data=df2, geom="line", xlab="Tijd", ylab="Activity")

# => dit werkt!

# nog een kolom met activity, deze kleur en teken geven en evt ook andere y-waarde
# ywaarde evt weer met factors. Factors zijn dan groepen zoals door make-report bepaald.
# en duidelijk onderscheid tussen activ-window teken (lijn) en file-actie teken (point)
# dit zijn dan mogelijk verschillende lagen (aes, aesthetic?) in de graph.

# voor opan/Pim is de y de user/thread die het uitvoert, gewoon een extra kolom in de input-data.

# todo
# * meerdere threads
# * kleuren voor verschillende activities.
# * sec1 wat directer bepalen? evt msec1 doen?

# keuze
# * LR raw data gebruiken, waarin individuele reqs incl vuser staat/
# * eerst een voorbeeld datafile, evt in een sqlite.

df = read.csv("resp.csv")
df$ts.start = as.POSIXct(strptime(df$start, format = "%H:%M:%S"))
df$ts.end = as.POSIXct(strptime(df$end, format = "%H:%M:%S"))
df2 = ddply(df, .(thread,ts.start,soort), function (df) {
  data.frame(ptype = c('start', 'end', 'NA'), ts = c(df$ts.start, df$ts.end, df$ts.end + sec1), y = c(df$thread, df$thread, NA))
})

qplot(ts, y, data=df2, geom="line", xlab="Tijd", ylab="Vuser") +
  scale_y_continuous(breaks=1:3)
  
ggsave("opan-reqs.png", width=3, height=2, dpi=100)  
ggsave("opan-reqs.png", width=3.5, height=1.5, dpi=100)

# met soort -> kleur:
qplot(ts, y, data=df2, geom="line", xlab="Tijd", ylab="Vuser", colour=soort) +
  scale_y_continuous(breaks=1:3)

# met geom_segment

qplot(ts.start, thread, xend=ts.end, yend=thread, data=df, geom="segment", xlab="Tijd", ylab="Vuser", colour=soort) +
  scale_y_continuous(breaks=1:3)
=> nu ook ok, met POSIXct!

qplot(ts.start, thread, xend=ts.end, yend=thread, data=df, geom="segment", xlab="Tijd", ylab="Vuser", colour=soort, size = I(5)) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))

# ook even rect(angle)

qplot(xmin=ts.start, ymin=thread, xmax=ts.end, ymax=thread, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort, fill=soort, size = I(5)) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))
  
wel ok, beetje vaag.

qplot(xmin=ts.start, ymin=thread, xmax=ts.end, ymax=thread, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort, size = I(5)) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))

qplot(xmin=ts.start, ymin=thread, xmax=ts.end, ymax=thread, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))
  
qplot(xmin=ts.start, ymin=thread-0.05, xmax=ts.end, ymax=thread+0.05, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))

qplot(xmin=ts.start, ymin=thread-0.05, xmax=ts.end, ymax=thread+0.05, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort, fill=soort) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))
=> ok, fill wel nodig om niet alleen contouren, maar ook de vulling met kleur te regelen.  
  
qplot(xmin=ts.start, ymin=thread-0.1, xmax=ts.end, ymax=thread+0.1, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))


qplot(xmin=ts.start, ymin=thread-0.1, xmax=ts.end, ymax=thread+0.1, data=df, geom="rect", xlab="Tijd", ylab="Vuser", colour=soort, fill=manual(soort)) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))
=> fout, manual niet gevonden.

# Functioneel gezien lijkt segment hier de beste oplossing, niet echt pattern in de rechthoek nodig, size is genoeg.

# aardige FP vraag: heb dergelijke graph al meer, en om overlap goed weer te geven, doe ik offset van y met beperkte waarde. Deze offset nu imperatief bepaald, met bijhouden wat al gebruikt is. Hoe zou je dit doen met FP?

#De laatste die ik wil gebruiken dus: (simpel maar doeltreffend) 
qplot(ts.start, thread, xend=ts.end, yend=thread, data=df, geom="segment", xlab="Tijd", ylab="Vuser", colour=soort, size = I(5)) +
  scale_y_continuous(breaks=1:3, limits=c(0.8, 3.2))

