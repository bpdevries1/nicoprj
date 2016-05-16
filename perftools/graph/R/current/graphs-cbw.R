#source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
#source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")

source("~/nicoprj/R/lib/ndvlib.R")
source("~/nicoprj/R/RABO/perflib.R")

load.def.libs()
# melding: Error: package ‘RSQLite.extfuns’ was built before R 3.0.0: please re-install it 
# vraag of deze spannend is.

main = function () {
  load.def.libs()
  #make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run206", "2015-06-10 09:00", "2015-06-10 12:30")
  #make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run208", "2015-06-10 09:00", "2015-06-10 19:30")
  # make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run212", "2015-06-17 07:00", "2015-06-17 19:30")
  # make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run227", "2015-06-14 00:00", "2015-06-25 23:00")
  # make.load.graphs("/home/ymor/RABO/CashBalance/run218-endurance", "2015-06-22 16:00", "2015-06-22 17:00")
  make.load.graph.test("/home/ymor/RABO/CashBalance/run218-endurance", "2015-06-22 16:00", "2015-06-22 17:00")
}

make.load.graphs = function(dir, mintime, maxtime) {
  setwd(dir)
  db = db.open("vuserlog.db")

  make.load.graphs.part(db, "2015-01-01","2020-01-01", "all")
  make.load.graphs.part(db, mintime, maxtime, "sel")
  
  db.close(db)
}

# TODO's

make.load.graph.test = function(dir, mintime, maxtime) {
  setwd(dir)
  db = db.open("vuserlog.db")
  
  # 1 hour segment
  mintime = "2015-06-22 16:00"
  maxtime = "2015-06-22 17:00"
  
  # all
  mintime = "2015-06-14 00:00" 
  maxtime = "2015-06-28 23:00"
  
  
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime, 'get accounts' trans
         from retraccts
         where 1.0*resptime < 10.0
         and ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  qplot.dt(ts_psx, resptime, data=df, colour=trans, ylab="Response time (sec)", filename=paste0("resptime-in-time-", tp, ".png"))
  
  # heatgraph - eerst x en y in 100 stukken verdelen.
  
  seq_timestamp = seq(from=min(df$ts_psx), to=max(df$ts_psx), length.out=200)
  df$time = as.POSIXct(cut(df$ts_psx, seq_timestamp), format="%Y-%m-%d %H:%M:%S")
  seq_y = seq(from=min(df$resptime), to=max(df$resptime), length.out=100)
  df$cut_y = cut(df$resptime, seq_y, labels=seq_y[1:length(seq_y)-1])
  df$resp.time = as.numeric(levels(df$cut_y))[df$cut_y]
  
  df2 = ddply(df, .(time), function(dfp) {
    #  c(n=length(dfp$time))
    ddply(dfp, .(resp.time), function(dfp2) {
      c(n=length(dfp2$resp.time) / length(dfp$time), 
        y=mean(dfp$resptime, na.rm=TRUE))
    })
  })

  df3 = ddply(df2, .(time), function(dfp) {
    ddply(dfp,.(resp.time, n, y), function(dfp2) {
      c(frac=dfp2$n / max(dfp$n))
    })
  })

# show #items/total #items for time-segment.  
#  ggplot(df2 , aes(x=time,y=resp.time, z=n)) + geom_tile(aes(fill=n)) + 
#    scale_fill_gradient(low="lightblue", high="red") + theme_bw() +
#    geom_line(aes(x=time, y=y))

# show #items/max #items for time-segment, so for each timestamp at least one tile is red.
  ggplot(df3 , aes(x=time,y=resp.time, z=frac)) + geom_tile(aes(fill=frac)) + 
    scale_fill_gradient(low="lightblue", high="red") + theme_bw() +
    geom_line(aes(x=time, y=y))
  
  db.close(db)
}

test = function() {
  dir = "/home/ymor/RABO/CashBalance/run218-endurance"
  mintime = "2015-06-14 00:00" 
  maxtime = "2015-06-28 23:00"
  setwd(dir)
  db = db.open("vuserlog.db")
  tp = "sel"
  
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime, 'get accounts' trans
         from retraccts
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  qplot.dt(ts_psx, resptime, data=df, colour=trans, ylab="Response time (sec)", filename=paste0("resptime-in-time-", tp, ".png"))
  qplot.gen(naccts, resptime, data=df, colour=trans, title = paste0("Response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("resptime-per-naccts-", tp, ".png"))
  
  db.close(db)
  
}

make.load.graphs.part = function(db, mintime, maxtime, tp) {
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime, 'get accounts' trans
         from retraccts
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  qplot.dt(ts_psx, resptime, data=df, colour=trans, ylab="Response time (sec)", filename=paste0("resptime-in-time-", tp, ".png"))
  qplot.gen(naccts, resptime, data=df, colour=trans, title = paste0("Response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("resptime-per-naccts-", tp, ".png"))
  
  query = paste0("select 1*naccts naccts, avg(1.0*resptime) avg_resptime, 'get accounts' trans
         from retraccts
         where ts_cet between '", mintime, "' and '", maxtime, "'
         group by 1")
  df = db.query.dt(db, query)
  # TODO deze hieronder geeft foutmelding, waarsch op labs(title=)
  # p = qplot.gen(naccts, avg_resptime, data=df, colour=trans, labs(title = paste0("Average response time by #accounts (", tp, ")")), xlab = "#Accounts", ylab="Average response time (sec)", filename=paste0("resptime-avg-per-naccts-", tp, ".png"))
  qplot.gen(naccts, avg_resptime, data=df, colour=trans, title = paste0("Average response time by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Average response time (sec)", filename=paste0("resptime-avg-per-naccts-", tp, ".png"))
  
  make.user_naccts(db)
  
  # facets = DatabaseName~.
  query = paste0("select ts_cet ts, 1.0*resptime resptime, transname, u.naccts
         from trans t
         join user_naccts u on u.user = t.user
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  qplot.dt(ts_psx, resptime, data=df, colour=transname, ylab="Response time (sec)", filename=paste0("trans-resptime-in-time-", tp, ".png"))
  # qplot.gen(naccts, resptime, data=df, colour=transname, title = paste0("Response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("trans-resptime-per-naccts-", tp, ".png"))
  qplot.gen(naccts, resptime, data=df, colour=transname, facets=transname~. , title = paste0("Response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("trans-resptime-per-naccts-", tp, ".png"))
  
  query = paste0("select ts_cet ts, avg(1.0*resptime) avg_resptime, transname, u.naccts naccts
         from trans t
         join user_naccts u on u.user = t.user
         where ts_cet between '", mintime, "' and '", maxtime, "'
         group by transname,naccts")
  df = db.query.dt(db, query)
  qplot.gen(naccts, avg_resptime, data=df, colour=transname, facets=transname~. , title = paste0("Average response times by #accounts (", tp, ")"), xlab = "#Accounts", ylab="Response time (sec)", filename=paste0("trans-avg-resptime-per-naccts-", tp, ".png"))
  # tp kent 'ie hieronder niet, mogelijk iets met verlate evaluatie van de expressie in een andere scope/stacklevel.
  qplot.gen.ff(naccts, avg_resptime, data=df, colour=transname, file.facets="transname", title = paste0("Average response times by #accounts"), xlab = "#Accounts", ylab="Response time (sec)", filename.prefix=paste0("trans-avg-resptime-per-naccts-"))
}

make.user_naccts = function(db) {
  db.exec(db, "drop table if exists user_naccts")
  db.exec(db, "create table user_naccts (user, naccts int)")
  db.exec(db, "insert into user_naccts
               select distinct user, naccts
               from retraccts")
}

main()
