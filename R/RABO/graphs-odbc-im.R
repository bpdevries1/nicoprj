source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
# source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\HTMLlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\lib\\HTMLlib.R")
load.def.libs()

main = function () {
  # load.def.libs()
  dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev-20150818"
  # dir = "C:/PCC/Nico/Projecten/IntelliMatch/odbc-dev"
  filename = "odbccalls.db"
  make.action.graphs(dir, filename)
  make.report(dir, filename)
}

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
  write.html.table(fo, df, "id")
  d_ply(df, .(id), function(dft) {
    html.heading(fo, 3, sprintf("User Action: %s (%d)", dft$description[1], dft$id[1]))
    graph.filename = sprintf("useraction-%04d.png", dft$id[1])
    if (file.exists(graph.filename)) {
      html.img(fo, graph.filename)  
    }
    writeLines("<br/>", fo)
    write.html.table.actionqueries(db, fo, dft$id[1])
    writeLines("<br/>", fo)
  })  
  html.footer(fo)
  close(fo)
  db.close(db)  
}

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

main()
