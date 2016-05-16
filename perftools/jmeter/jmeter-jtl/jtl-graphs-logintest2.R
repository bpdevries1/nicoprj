library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(plyr, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

make.graphs = function() {
  # make.graphs.db("logintest1.db", "Login test 1")
  
  # 19-11-2012 already have those.
  # make.graphs.db("logintest2.db", "Login test 2")
  
  # make.graphs.db("loadtest.db", "Load test")
  # make.graphs.db("loadtest1300.db", "Load test 1300")
  
  # 19-11-2012 new:
  # db = dbConnect(dbDriver("SQLite"), "~/Ymor/Parnassia/Resultaten/jmeterlogs.db")
  # make.graph.nvusers.jmeterlogs(db, "logintest2", "~/Ymor/Parnassia/logintest2")
  
  # db = dbConnect(dbDriver("SQLite"), "~/Ymor/Parnassia/logintest2/accesslog.db")
  # make.graphs.accesslog.throughput(db, "logintest2", "~/Ymor/Parnassia/logintest2")
  
  db = dbConnect(dbDriver("SQLite"), "~/Ymor/Parnassia/logintest2/logintest2.db")
  make.graphs.jtl.specific(db, "logintest2", "~/Ymor/Parnassia/logintest2")
}

make.graphs.db = function(db_name, title.prefix) {
  print(paste("Creating graphs: ", title.prefix))
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = make.graph.R(db, title.prefix)
  make.graph.Ravg(db, title.prefix, df)
  make.graph.X(db, title.prefix, df)
  make.graph.Xbytes(db, title.prefix)
  make.graph.nconc(db, title.prefix, df)
  make.graph.nvusers(db, title.prefix)
  # @todo evt later ook nog per label/transactie of bepaalde tijdspanne.
  # @todo titles en assen wel meteen?
  dbDisconnect(db)
}

# @todo ook versie met per 'cut' een waarde, niet alles.
make.graph.R = function(db, title.prefix) {
  print(paste("Creating graph: ", title.prefix, "Response time"))
  query = "select 0.001*ts ts, 0.001*t t, s success from httpsample"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = wrapper(paste(title.prefix, "resptime"), width = 80)) +
    scale_y_continuous(limits=c(0, max(df$t)))
  ggsave(filename=paste(title.prefix, "-resptime.png", sep=""), width=11, height=9, dpi=100)
  df
}

make.graph.Ravg = function(db, title.prefix, df) {
  print(paste("Creating graph: ", title.prefix, "Response time (avg)"))

  ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
  df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

  avg = ddply(df, .(tscut, success), function (df) {
    data.frame(Ravg = mean(df$t, na.rm=TRUE))  
  })

  qplot(tscut, Ravg, data=avg, geom="line", colour=success, shape=success, xlab="Time", ylab="Response time avg (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = wrapper(paste(title.prefix, "Response time average"), width = 80)) +
    scale_y_continuous(limits=c(0, max(avg$Ravg)))
    
  ggsave(filename=paste(title.prefix, "-resptime-avg.png", sep=""), width=11, height=9, dpi=100)
}

make.graph.X = function(db, title.prefix, df) {
  print(paste("Creating graph: ", title.prefix, "Throughput"))
  ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
  cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
  df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

  cnt = ddply(df, .(tscut, success), function (df) {
    data.frame(tps = length(df$ts) / cut.diff.secs)  
  })

  qplot(tscut, tps, data=cnt, geom="line", colour=success, shape=success, xlab="Time", ylab="Througput (trans/sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = wrapper(paste(title.prefix, "throughput"), width = 80)) +
    scale_y_continuous(limits=c(0, max(cnt$tps)))
  ggsave(filename=paste(title.prefix, "-throughput.png", sep=""), width=11, height=9, dpi=100)    
}

make.graph.Xbytes = function(db, title.prefix) {
  print(paste("Creating graph: ", title.prefix, "Throughput bytes"))
  query = "select 0.001*ts ts, by bytes from httpsample"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  
  ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
  cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
  df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))

  bps = ddply(df, .(tscut), function (df) {
    data.frame(bps = sum(df$bytes, na.rm=TRUE) / cut.diff.secs)  
  })

  qplot(tscut, bps, data=bps, geom="line", xlab="Time", ylab="Througput (bytes/sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = wrapper(paste(title.prefix, "throughput-bytes"), width = 80)) +
    scale_y_continuous(limits=c(0, max(bps$bps)))
  ggsave(filename=paste(title.prefix, "-throughput-bytes.png", sep=""), width=11, height=9, dpi=100)    
}

make.graph.nconc = function(db, title.prefix, df) {
  print(paste("Creating graph: ", title.prefix, "#concurrent request"))
  ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
  cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
  df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))
  
  # met avg(R) ook concurrent reqs te bepalen: N=X*R
  cnt = ddply(df, .(tscut), function (df) {
    data.frame(tps = length(df$ts) / cut.diff.secs,
               r.avg = mean(df$t, na.rm=TRUE),
               conc = length(df$ts) / cut.diff.secs * mean(df$t, na.rm=TRUE))  
  })
  
  qplot(tscut, conc, data=cnt, geom="line", xlab="Time", ylab="#Concurrent requests (R*X)") +
    opts(title = wrapper(paste(title.prefix, "#Concurrent requests"), width = 80)) +
    scale_y_continuous(limits=c(0, max(cnt$conc)))
  ggsave(filename=paste(title.prefix, "-nconc.png", sep=""), width=11, height=9, dpi=100)  
}

make.graph.nvusers = function(db, title.prefix) {
  print(paste("Creating graph: ", title.prefix, "#vusers"))
  query = "select min(0.001*ts) ts_start, max(0.001*ts) ts_end, hn || ':' || tn threadname from httpsample group by tn,hn order by tn,hn"
  df = dbGetQuery(db, query)
  cnt = make.count(df)
  qplot(data=cnt, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#vusers") +
    opts(title = wrapper(paste(title.prefix, "#Vusers"), width = 80)) +
    scale_y_continuous(limits=c(0, max(cnt$count)))
  ggsave(filename=paste(title.prefix, "-nvusers.png", sep=""), width=11, height=9, dpi=100)  
}

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

wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")

make.graph.nvusers.jmeterlogs = function(db, testname, outputdir) {
  query1 = paste("select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='", testname, "' and startstop='started'", sep="") 
  df1 = dbGetQuery(db, query1)
  df1$ts_psx = strptime(df1$ts, format="%Y-%m-%d %H:%M:%S")
  
  # query2 = "select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='loadtest' and startstop='finished'" 
  query2 = paste("select ts, threadname, ip, pcname, testname, logfilename, startstop from logline where testname='", testname, "' and startstop='finished'", sep="")
  df2 = dbGetQuery(db, query2)
  df2$ts_psx = strptime(df2$ts, format="%Y-%m-%d %H:%M:%S")
  
  df.step1 = ddply(df1, .(ts_psx), function (df) {data.frame(step=length(df$ts_psx))})
  df.step2 = ddply(df2, .(ts_psx), function (df) {data.frame(step=-length(df$ts_psx))})
  
  df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts_psx,step)) 
  df.steps = arrange(ddply(df.step, .(ts_psx), function(df) {c(step=sum(df$step))}), ts_psx)
  df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
  qplot(data=df.steps, x=ts_psx, y=count, geom="step", xlab = "Time", ylab = "#vusers") +
    opts(title = paste(testname, "#Vusers (jmeter.log)")) +
    scale_y_continuous(limits=c(0, max(df.steps$count)))
  ggsave(filename=paste(outputdir, "jmeterlog-nvusers.png", sep="/"), width=11, height=9, dpi=100)  
}

make.graphs.accesslog.throughput = function(db, testname, outputdir) {
  query = "select ts, 0.001*t t, ip, url, rc from logline"
  df = dbGetQuery(db, query)
  df$ts_psx = strptime(df$ts, format="%Y-%m-%d %H:%M:%S")
  
  ts.seq = seq(from=min(df$ts_psx, na.rm=TRUE), to=max(df$ts_psx, na.rm=TRUE), length.out=100)
  cut.diff.secs = as.numeric(ts.seq[2] - ts.seq[1], units="secs")
  df$tscut = as.POSIXct(cut(df$ts_psx, ts.seq))
  
  cnt = ddply(df, .(tscut, rc), function (df) {
    data.frame(tps = length(df$ts) / cut.diff.secs)  
  })
  
  # iets als factor levels.
  qplot(tscut, tps, data=cnt, geom="line", colour=as.factor(rc), xlab="Time", ylab="Througput (trans/sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    scale_colour_discrete(name = "Resultcode") +  
    opts(title = "Access log throughput (trans/sec)") +
    scale_y_continuous(limits=c(0, max(cnt$tps)))
  # beter!
  ggsave(filename=paste(outputdir, "accesslog-throughput.png", sep="/"), width=11, height=9, dpi=100)
  
  # goed, ook avg.R en nconc als berekening erbij.
  avg = ddply(df, .(tscut, rc), function (df) {
    data.frame(Ravg = mean(df$t, na.rm=TRUE))  
  })
  
  qplot(tscut, Ravg, data=avg, geom="line", colour=as.factor(rc), xlab="Time", ylab="Response time avg (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    scale_colour_discrete(name = "Resultcode") +  
    opts(title = "Access log response times (sec)") +
    scale_y_continuous(limits=c(0, max(avg$Ravg)))
  ggsave(filename=paste(outputdir, "accesslog-resptime-avg.png", sep="/"), width=11, height=9, dpi=100)  
  
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
  ggsave(filename=paste(outputdir, "accesslog-nconc.png", sep="/"), width=11, height=9, dpi=100)  
  
}  

make.graphs.jtl.specific = function(db, testname, outputdir) {
  query = "select 0.001*ts ts, 0.001*t t, lb, by bytes from httpsample where s='true' and lb in ('Eerste caseload page ophalen', 'Juiste page ophalen', 'maxJM', 'maxMom', 'minJuridische Maatregel', 'minMoM')"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  
  # bytes vs R
  qplot(bytes, t, data=df, colour=lb, shape=lb, xlab="Size (bytes)", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response time vs response size")) +
    scale_y_continuous(limits=c(0, max(df$t))) +
    scale_x_continuous(limits=c(0, max(df$bytes)))
  ggsave(paste(outputdir, "resptime-respsize.png", sep="/"), width=11, height=9, dpi=100) 
    
  # dan met log-scale op x en y
  qplot(bytes, t, data=df, colour=lb, shape=lb, xlab="Size (bytes)", ylab="Response time (sec)", log="xy") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response time vs response size"))
  ggsave(paste(outputdir, "resptime-respsize-logxy.png", sep="/"), width=11, height=9, dpi=100) 
  
  # Dan size tov tijd:
  qplot(ts_psx, bytes, data=df, colour=lb, shape=lb, xlab="Time", ylab="Size (bytes)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response sizes for selected transactions")) +
    scale_y_continuous(limits=c(0, max(df$bytes))) +
    geom_point(alpha=0.00001)
  ggsave(paste(outputdir, "respsizes-selected.png", sep="/"), width=11, height=9, dpi=100)
  
  # van deze selected ook de resptime weergeven.
  qplot(ts_psx, t, data=df, colour=lb, shape=lb, xlab="Time", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response times for selected transactions")) +
    scale_y_continuous(limits=c(0, max(df$t))) +
    geom_point(alpha=0.00001)
  ggsave(paste(outputdir, "resptimes-selected.png", sep="/"), width=11, height=9, dpi=100)

  query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host, tn || ':' || hn threadname from httpsample where s='true' and lb in ('Inloggen') order by threadname"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  qplot(ts_psx, threadname, data=df, colour=host, shape=host, xlab="Time", ylab="Thread") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Inloggen per thread")) +
    geom_point(alpha=1/10) +
    scale_y_discrete()
  ggsave(paste(outputdir, "inloggen-thread.png", sep="/"), width=11, height=9, dpi=100)
  
  query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host from httpsample where s='true' and lb in ('Inloggen')"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  
  qplot(ts_psx, t, data=df, colour=host, shape=host, xlab="Time", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response times for Inloggen per host")) +
    scale_y_continuous(limits=c(0, max(df$t))) +
    geom_point(alpha=1/10)
  ggsave(paste(outputdir, "resptimes-inloggen-host.png", sep="/"), width=11, height=9, dpi=100)

  query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success from httpsample where s='true' and lb in ('Inloggen')"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  
  qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response times for Inloggen")) +
    scale_y_continuous(limits=c(0, max(df$t))) +
    geom_point(alpha=1/10)
  ggsave(paste(outputdir, "resptimes-inloggen.png", sep="/"), width=11, height=9, dpi=100)

  query = "select 0.001*ts ts, 0.001*t t, lb, by bytes, s success, hn host, tn || ':' || hn threadname from httpsample order by threadname"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(df$ts, origin="1970-01-01 01:00:00")
  
  # max-y nu op 400, daardoor niets te zien. Ofwel op 20 zetten, ofwel log-scale.
  # eerst log-scale:
  qplot(ts_psx, t, data=df, colour=success, shape=success, xlab="Time", ylab="Response time (sec)", log="y") +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +  
    opts(title = paste(testname, "Response times per label")) +
    facet_grid(lb ~ .)
  # ziet er op het scherm niet uit, niet genoeg y positie, dus saven naar grote y:
  ggsave(paste(outputdir, "label-resptime-log.png", sep="/"), width=11, height=90, dpi=100)

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
    opts(title = paste(testname, "Response time average per label")) +
    facet_grid(lb ~ .)
  ggsave(paste(outputdir, "label-avg-resptime-log.png", sep="/"), width=11, height=90, dpi=100)
  
}
  
# main
make.graphs()

