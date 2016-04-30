source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\HTMLlib.R")

#source("~/nicoprj/R/lib/ndvlib.R")
#source("~/nicoprj/R/RABO/perflib.R")

load.def.libs()

main = function () {
  # load.def.libs()
  dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev-20150818"
  # dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev"
  filename = "odbccalls.db"
  make.action.graphs(dir, filename)
  make.report(dir, filename)
}

# and u.id in (4,6)


make.action.graphs = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)
  # niet alle callnames, om aantal kleuren te verminderen.
  # desc(ending) in query heeft geen zin voor volgorde op y-as in grafiek.
  query = "select u.id useraction_id, u.description, u.ncalls, u.resptime, q.title, c.odbcquery_id, c.callname, 
                  c.ts_cet_enter, c.ts_cet_exit, c.calltime
           from odbccall c 
           join odbcquery_do q on c.odbcquery_id = q.odbcquery_id
           join useraction u on u.id = q.start_useraction_id
           where q.query != ''
           and q.start_useraction_id between 1 and 500
           and u.resptime > 2
           and c.callname not in ('SQLAllocStmt', 'SQLFreeStmt', 'SQLBindCol', 'SQLBindParameter', 
             'SQLDescribeCol', 'SQLNumResultCols', 'SQLPrepare', 'SQLRowCount', 'SQLSetParam', 'SQLSetPos', 'SQLSetStmtOption')
           order by 1, q.odbcquery_id"  
  
  df = db.query.dt(db, query)
  df$ts.enter.psx = as.POSIXct(strptime(df$ts_cet_enter, format="%Y-%m-%d %H:%M:%OS"))
  df$ts.exit.psx  = as.POSIXct(strptime(df$ts_cet_exit,  format="%Y-%m-%d %H:%M:%OS"))

  d_ply(df, .(useraction_id), function(dft) {
    qplot(x=ts.enter.psx, xend=ts.exit.psx, y=title, yend=title, colour = callname, lwd=10, data=dft, 
          geom="segment", xlab = NULL, ylab=NULL,
          main = sprintf("%d: %s (#calls: %d, runtime: %.3f sec)",
                         dft$useraction_id[1], dft$description[1],
                         dft$ncalls[1], dft$resptime[1])) +
      scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
      scale_y_discrete(limits = rev(levels(as.factor(dft$title)))) + # neemt alle queries, ook van andere user actions.
      # scale_y_reverse() + # alleen voor continuous scale.
      guides(lwd=FALSE) +
      theme(legend.position="bottom")
    fn.graph = sprintf("useraction-%04d.png", dft$useraction_id[1])
    ggsave(filename=fn.graph, width=12, height=det.height(dft), dpi=100)
  })
  db.close(db)
}

det.height = function(df) {
  nq = length(ddply(df, .(title), function(dft) {c(n=1)})$title)
  2 + 0.20 * nq
  #9
}

make.report(dir, filename)

make.report = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)


  query = "select u.id, u.description, u.ts_cet_first Start, 
           u.ts_cet_last End, u.resptime 'Resp.time', 
           u.thinktime_before 'TT before', u.thinktime_after 'TT after',
           u.ncalls '#calls'
           from useraction u
           where u.ncalls > 0
           order by id"    


  
  df = db.query.dt(db, query)

  filename = "odbccalls-report.html"
  fo = file(filename, "w")
  html.header(fo, "User actions and ODBC calls")
  
  # write.html.table.useractions(fo, df, "id")
  write.html.table(fo, df, "id")
  
  d_ply(df, .(id), function(dft) {
    # html.heading(fo, 3, concat("User Acion: ", dft$description[1]))
    html.heading(fo, 3, sprintf("User Action: %s (%d)", dft$description[1], dft$id[1]))
    graph.filename = sprintf("useraction-%04d.png", dft$id[1])
    if (file.exists(graph.filename)) {
      html.img(fo, graph.filename)  
    }
    writeLines("<br/>", fo)
    
    write.html.table.actionqueries(db, fo, dft$id[1])
    
    writeLines("<br/>", fo)
    
#    dfs.db = subset(dfs, DatabaseName == dft$DatabaseName)
#    print("before write.html.table.count")
#    write.html.table.count(fo, dfs.db)
  })  

  html.footer(fo)
  close(fo)
  
  db.close(db)  
}


make.report(dir, filename)


# @todo determine fields/data types/formats dynamically.
# @useraction_id als param meegegeven. Eigenlijk helemaal niet, table moet as-is door ddply behandeld worden, elke row omzetten naar html
write.html.table.useractions.old2 = function(fo, df, idfield) {
  df2 = ddply(df, as.quoted(idfield), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per useraction_id only one record exists.
    c(tr=html.table.row2(dfp1))
  })
  # log.df(log, df2, "table rows:")
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row2(df),
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}

# @todo determine fields/data types/formats dynamically.
write.html.table.useractions.old = function(fo, df) {
  df2 = ddply(df, .(useraction_id), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per useraction_id only one record exists.
    #c(tr = html.table.row(dfp1$useraction_id, dfp1$description, dfp1$ts_cet_first, dfp1$ts_cet_last, dfp1$resptime,
    #                      dfp1$thinktime_before, dfp1$thinktime_after, f1000(dfp1$ncalls)))
    c(tr= html.table.row2(dfp1))
  })
  # log.df(log, df2, "table rows:")
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row("id", "Description", "Start", "End", "Resp.time", 
                                          "TT before", "TT after", "#calls"),
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}

# ts_cet_start, ts_cet_end, 
write.html.table.actionqueries = function(db, fo, useraction_id) {
  query = sprintf("select odbcquery_id id, query_elapsed Elapsed,
                   query_servertime Servertime, nbindcol '#bindcol', 
                   nfetch '#fetch', nsqlgetdata '#sqlgetdata', 
                   ncalls '#calls', query
                   from odbcquery_do
                   where start_useraction_id=%d", useraction_id)

  df = db.query.dt(db, query)
  write.html.table(fo, df, "id")
}

write.html.table.actionqueries.old = function(db, fo, useraction_id) {
  query = sprintf("select odbcquery_id id, query_elapsed,
                   query_servertime, nbindcol, nfetch, nsqlgetdata, ncalls, query
                  from odbcquery_do
                  where start_useraction_id=%d", useraction_id)
  
  df = db.query.dt(db, query)
  write.html.table(fo, df, "id")
  
  
  df2 = ddply(df, .(id), function(dfp) {
    r = dfp[1,] # only need first record of dataframe: per useraction_id only one record exists.
    c(tr = html.table.row(r$id, r$query_elapsed,
                          r$query_servertime, f1000(r$nbindcol), f1000(r$nfetch), 
                          f1000(r$nsqlgetdata), f1000(r$ncalls), r$query))
  })
  # log.df(log, df2, "table rows:")
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row("id", "Elapsed",
                                          "Servertime", "#bindcol", "#fetch", 
                                          "#sqlgetdata", "#calls", "query"),
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}

test3 = function () {
  df2 = ddply(df, .(useraction_id), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per useraction_id only one record exists.
    #c(tr = html.table.row(dfp1$decription, dfp1$ts_cet_first, dfp1$ts_cet_last, dfp1$resptime,
    #                      dfp1$thinktime_before, dfp1$thinktime_after, f1000(dfp1$ncalls)))
    c(tr = html.table.row(dfp1$description, dfp1$ts_cet_first, dfp1$ts_cet_last, dfp1$resptime,
                          dfp1$thinktime_before, dfp1$thinktime_after, f1000(dfp1$ncalls)))
    # c(tr = "1")
  })
  
  
}

test1 = function() {
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



test2 = function() {
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

make.user_naccts = function(db) {
  db.exec(db, "drop table if exists user_naccts")
  db.exec(db, "create table user_naccts (user, naccts int)")
  db.exec(db, "insert into user_naccts
               select distinct user, naccts
               from retraccts")
}


main()
