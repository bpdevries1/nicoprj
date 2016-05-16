source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
load.def.libs()

main = function () {
  load.def.libs()
  make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run206", "2015-06-10 09:00", "2015-06-10 12:30")
  make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run208", "2015-06-10 09:00", "2015-06-10 19:30")
}

make.load.graphs = function(dir, mintime, maxtime) {
  setwd(dir)
  db = db.open("vuserlog.db")

  make.load.graphs.part(db, "2015-01-01","2020-01-01", "all")
  make.load.graphs.part(db, mintime, maxtime, "sel")
  
  db.close(db)
}

if (FALSE) {
  df = df.add.dt(sqlQuery(con, query))
  log.df(log,df,"query executed")
  # df$ts_psx = as.POSIXct(strptime(df$CollectTimeStamp, format="%Y-%m-%d %H:%M:%S"))
  # 22-10-2014 Ndv calc.df.aggr.ts niet te gebruiken hier, want meer dan 1 waarde berekend.
  
  interval.sec = det.interval.sec(df, c("DatabaseName", "ChannelName"))
  
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = npoints)
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  dfaggr = ddply(df, .(DatabaseName,ChannelName,ts_cut), 
                 function(df) {c(nread=1.0*mean(df$nread) / interval.sec, 
                                 nadded=1.0*mean(df$nadded) / interval.sec, 
                                 nelts=max(df$nelts))})  
  
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", 
           filename=det.graphname(outdir, runid, part, "channels-nmessages"))
}

make.load.graphs.part = function(db, mintime, maxtime, tp) {
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime, 'get accounts' trans
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  qplot.dt(ts_psx, resptime, data=df, colour=trans, ylab="Response time (sec)", filename=paste0("resptime-in-time-", tp, ".png"))
  qplot.gen(naccts, resptime, data=df, colour=trans, title = paste0("Response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("resptime-per-naccts-", tp, ".png"))
  
  query = paste0("select 1*naccts naccts, avg(1.0*resptime) avg_resptime, 'get accounts' trans
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'
         group by 1")
  df = db.query.dt(db, query)
  # TODO deze hieronder geeft foutmelding, waarsch op labs(title=)
  # p = qplot.gen(naccts, avg_resptime, data=df, colour=trans, labs(title = paste0("Average response time by #accounts (", tp, ")")), xlab = "#Accounts", ylab="Average response time (sec)", filename=paste0("resptime-avg-per-naccts-", tp, ".png"))
  p = qplot.gen(naccts, avg_resptime, data=df, colour=trans, title = paste0("Average response time by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Average response time (sec)", filename=paste0("resptime-avg-per-naccts-", tp, ".png"))
}

make.load.graphs.part.old = function(db, mintime, maxtime, tp) {
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  p = qplot(ts_psx, resptime, data=df)
  ggsave(paste0("resptime-in-time-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
  p = qplot(naccts, resptime, data=df)
  ggsave(paste0("resptime-per-naccts-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
  
  query = paste0("select 1*naccts naccts, avg(1.0*resptime) avg_resptime
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'
         group by 1")
  df = db.query.dt(db, query)
  p = qplot(naccts, avg_resptime, data=df)
  ggsave(paste0("resptime-avg-per-naccts-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
}

main()
