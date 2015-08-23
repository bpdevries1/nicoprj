source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")

#source("~/nicoprj/R/lib/ndvlib.R")
#source("~/nicoprj/R/RABO/perflib.R")

load.def.libs()
# melding: Error: package ‘RSQLite.extfuns’ was built before R 3.0.0: please re-install it 
# vraag of deze spannend is.

# TODO:



# DONE:
* query in de graph? (of een deel?) -> nee, in losse tabel.
* Kleur per soort call
- kan wel, maar moeilijk zichtbaar.
- dikkere segmenten?
* Legenda aanpassen: niet 10-10 laten zien.
- door guides(lwd=FALSE)
* Graph per user-action: facet of file-facet.
* query-id + deel query in graph?
- in R geen printf functie, dus al eerder samenstellen. In tcl wel? zoniet, dan wel oplosbaar.
# Bij inlezen/TODO:
* per query het aantal kolommen en rijen opnemen (obv bindcol en fetch,res=0)
- SQLNumResultCols evt ook gebruiken? Naast aantal bindcol statements.
- heb ook describe column, maar in een call ook nog bindcol gebruikt, dus deze eerst maar doen.
- neem per query het aantal calls van bepaalde types op: bindcol, fetch%, getsqldata.


main = function () {
  load.def.libs()
  dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev-20150818"
  filename = "odbccalls.db"
  make.action.graphs(dir, filename)
}



make.action.graphs = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)
  # niet alle callnames, om aantal kleuren te verminderen.
  # printf kent 'ie hier niet.
  # printf('%05d: %s', q.odbcquery_id, substr(q.query, 1, 20)) title
  
  query = "select u.id useraction_id, u.description, u.ncalls, u.resptime, q.title, c.odbcquery_id, c.callname, 
                  c.ts_cet_enter, c.ts_cet_exit, c.calltime
           from odbccall c 
           join odbcquery_do q on c.odbcquery_id = q.odbcquery_id
           join useraction u on u.id = q.start_useraction_id
           where q.query != ''
           and q.start_useraction_id between 1 and 500
           and u.resptime > 3
           and c.callname not in ('SQLAllocStmt', 'SQLFreeStmt', 'SQLBindCol', 'SQLBindParameter', 
             'SQLDescribeCol', 'SQLNumResultCols', 'SQLPrepare', 'SQLRowCount', 'SQLSetParam', 'SQLSetPos', 'SQLSetStmtOption')"  
  df = db.query.dt(db, query)
  df$ts.enter.psx = as.POSIXct(strptime(df$ts_cet_enter, format="%Y-%m-%d %H:%M:%OS"))
  df$ts.exit.psx  = as.POSIXct(strptime(df$ts_cet_exit,  format="%Y-%m-%d %H:%M:%OS"))

  df$query.id = as.factor(df$odbcquery_id)
#  df$query.id = df$odbcquery_id
  df$query.id = as.factor(df$title)


  d_ply(df, .(useraction_id), function(dft) {
    qplot(x=ts.enter.psx, xend=ts.exit.psx, y=query.id, yend=query.id, colour = callname, lwd=10, data=dft, 
          geom="segment", xlab = NULL, ylab=NULL,
          main = concat(dft$useraction_id[1], ': ', dft$description[1],
                        ' (#calls: ', dft$ncalls[1], ', runtime: ', dft$resptime[1], ' sec)')) +
      scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
      guides(lwd=FALSE) +
      theme(legend.position="bottom")
    # ggsave(filename=concat("useraction-", dft$useraction_id[1], ".png"), width=12, height=det.height(dft), dpi=100)
    ggsave(filename=sprintf("useraction-%04d.png", dft$useraction_id[1]), width=12, height=det.height(dft), dpi=100)
    
    # deze nodig voor ddply
    # c(n=length(dft$useraction_id), height=det.height(dft))
  })


  
  # deze nog niet, eerst extra veld vullen.
#  qplot(x=ts.enter.psx, xend=ts.exit.psx, y=title, yend=title, colour = callname, lwd=10, data=df, xlab="Time", 
#        ylab="Query id", geom="segment",
#        main = "ODBC calls for Open Company") +
#    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS"))
  
  
  db.close(db)
  
}

det.height = function(df) {
  nq = length(ddply(df, .(query.id), function(dft) {c(n=1)})$query.id)
  2 + 0.20 * nq
  #9
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


test = function() {
  load.def.libs()
  dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev-20150818"
  filename = "odbccalls.db"
  ts.enter = df$ts_cet_enter[1]
  ts.exit = df$ts_cet_exit[1]
  df$ts_enter_psx = as.POSIXct(strptime(df$ts_cet_enter, format="%Y-%m-%d %H:%M:%OS"))
  df$ts_exit_psx  = as.POSIXct(strptime(df$ts_cet_exit,  format="%Y-%m-%d %H:%M:%OS"))
  psx.enter = df$ts_enter_psx[1]
  psx.exit = df$ts_exit_psx[1]
  
  qplot(x=ts.enter.psx, xend=ts.exit.psx, y=query.id, yend=query.id, colour = callname, lwd=10, data=df, xlab="Time", 
        ylab="Query id", geom="segment",
        main = "ODBC calls for Open Company") +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
    guides(lwd=FALSE)
  
  # met facets.
  qplot(x=ts.enter.psx, xend=ts.exit.psx, y=query.id, yend=query.id, colour = callname, lwd=10, data=df, xlab="Time", 
        ylab="Query id", geom="segment", 
        main = "ODBC calls for Open Company") +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
    guides(lwd=FALSE) +
    facet_grid(description ~ ., scales='free')
  
  qplot.dt(ts_psx, resptime, data=df, colour=trans, ylab="Response time (sec)", filename=paste0("resptime-in-time-", tp, ".png"))
  
  
  # met qplot.dt
  qplot.dt(x=ts.enter.psx, xend=ts.exit.psx, y=query.id, yend=query.id, colour = callname, lwd=10, data=df, xlab="Time", 
           ylab="Query id", geom="segment", 
           main = "ODBC calls for Open Company",
           filename = "ODBC calls for Open Company.png") +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
    guides(lwd=FALSE)
  
  # qplot.dt werkt hier niet, grafiek toch niet standaard genoeg. Zelf doen met ddply:
  
  ddply(df, .(useraction_id), function(dft) {
    qplot(x=ts.enter.psx, xend=ts.exit.psx, y=query.id, yend=query.id, colour = callname, lwd=10, data=dft, xlab="Time", 
          ylab="Query id", geom="segment", 
          main = "ODBC calls for Open Company") +
      scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
      guides(lwd=FALSE)
  })
  
  d2 = ddply(df, .(description), function(dft) {
    dft
  })
  
  d2 = ddply(df, .(query.id), function(dft) {
    dft
  })
  
  d2 = ddply(df, .(query.id), function(dft) {
    c(n=length(dft$query.id))
    
  })
  
  
}
