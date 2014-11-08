setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
source("HTMLlib.R")

load.def.libs()

source("graph-channels-lib.R")

main = function() {
  options(warn=-1) # set to 0 to display warnings. @todo make cmdline param.
  # options(warn=1) # warnings will be displayed as they occur (with 0 they will be collected and printed at the end)
  testnr = commandArgs()[6]
  runid = commandArgs()[7]
  chgroup = commandArgs()[8]
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con = odbcDriverConnect(connection=connstring)
  define.channel.groups()
  # suppressMessages werkt niet om qplot meldingen te onderdrukken.
  # suppressMessages(make.report(con, outdir, runid, chgroup))
  make.report(con, outdir, testnr, runid, chgroup)
  # stats2csv(con, outdir, runid)
  odbcClose(con)
  # warnings()
  # options(warn=-1)
  # print("end of main()")
}

test = function() {
  testnr = "452"
  runid = "1"
  chgroup = "diff1000"
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con = odbcDriverConnect(connection=connstring)
  start="2010-01-01"
  end="2099-12-31"
  part = chgroup
  width = 12
  make.report(con, outdir, testnr, runid, chgroup)
  odbcClose(con)
}

make.report = function(con, outdir, testnr, runid, chgroup, start="2010-01-01", end="2099-12-31") {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(concat(outdir, "/report-log.txt"))
  log("Start of analysis")
  
  # make html with graphs included. For now only for channels where nelts_start != nelts_end
  filename = concat(outdir, "\\", testnr, "-", runid, "-", chgroup, "-report.html")
  fo = file(filename, "w")
  html.header(fo, concat("Channel report, testnr-runid = ", testnr, "-", runid, ", group = ", chgroup))

  write.graph.html(fo, con, outdir, runid, chgroup, log, start, end)
  
  html.footer(fo)
  close(fo)
  log()
}

write.graph.html = function(fo, con, outdir, runid, chgroup, log, start, end) {
  # @todo named query parameters.
  diff = regmatches(chgroup, regexec("^diff(\\d+)$", chgroup))[[1]][2]
  if (is.na(diff)) {
    query = channel.query.chgroup(chgroup, runid, start, end)
  } else {
    query = channel.query.diff(diff, runid, start, end)
  }
  print(query)
  log(query)
  # df = sqlQuery(con, query)
  df = df.add.dt(sqlQuery(con, query, stringsAsFactors=FALSE))
  log.df(log,df,"query executed")
  # print(summary(df)) met deze wel df column headers.
  print("before calc.df.aggregate")
  dfaggr = calc.df.aggregate(df, log=log)
  print("before graph.dc.counts")
  # zowel counts in een enkele graph (graph.dc.counts) als ook een graph per database (graph.dc.counts.ff)
  graph.dc.counts(dfaggr, outdir, runid, chgroup, 12, log)
  dfdb = graph.dc.counts.ff(dfaggr, outdir, runid, chgroup, 12, log)
  log("after graph.dc.counts.ff, now logging dfdb:")  
  log.df(log, dfdb, "file.facets:")
  # print(summary(dfdb))
  # several graphs created. For now only include facet-db variant.
  html.heading(fo, 2, "Channel message counts (graph per DB)")
  # html.img(fo, det.graphname.rel(runid, chgroup, "channels-nmessages-facet-db"))
  print("before calc.summary.count")
  dfs = calc.summary.count(df)
  d_ply(dfdb, .(DatabaseName), function(dft) {
    html.heading(fo, 3, concat("Database: ", dft$DatabaseName))
    html.img(fo, dft$filename)
    writeLines("<br/>", fo)
    dfs.db = subset(dfs, DatabaseName == dft$DatabaseName)
    print("before write.html.table.count")
    write.html.table.count(fo, dfs.db)
  })
  
  print("before write.sql.table")
  write.sql.table(con, dfs, runid, chgroup, "count")
  write.csv.table(outdir, dfs, runid, chgroup, "count")

  html.heading(fo, 2, "Channel message read speeds (graph per DB)")
  graph.dc.speed(dfaggr, outdir, runid, chgroup, 12, log)
  dfdb = graph.dc.speed.ff(dfaggr, outdir, runid, chgroup, 12, log)
  print("before calc.summary.speed")
  dfs = calc.summary.speed(df)
  d_ply(dfdb, .(DatabaseName), function(dft) {
    html.heading(fo, 3, concat("Database: ", dft$DatabaseName))
    html.img(fo, dft$filename)
    writeLines("<br/>", fo)
    dfs.db = subset(dfs, DatabaseName == dft$DatabaseName)
    print("before write.html.table.count")
    write.html.table.speed(fo, dfs.db)
  })
  
  html.heading(fo, 2, "Channel message speed (added/read) per DB")
  #html.img(fo, det.graphname.rel(runid, chgroup, "channels-read-facet-db"))
  
  dfdb = graph.dc.speed.ff2(dfaggr, outdir, runid, chgroup, 12, log)
  d_ply(dfdb, .(DatabaseName), function(dft) {
    html.heading(fo, 3, concat("Database: ", dft$DatabaseName))
    html.img(fo, dft$filename)
    writeLines("<br/>", fo)
    dfs.db = subset(dfs, DatabaseName == dft$DatabaseName)
    print("before write.html.table.count")
    write.html.table.speed(fo, dfs.db)
  })
  
  #html.heading(fo, 2, "Channel message added/read per channel")
  #html.img(fo, det.graphname.rel(runid, chgroup, "channels-read-added-facet-channel"))
  #print("before write.html.table.speed")
  #write.html.table.speed(fo, dfs)
  #print("after write.html.table.speed")
  write.sql.table(con, dfs, runid, chgroup, "speed")
  write.csv.table(outdir, dfs, runid, chgroup, "speed")
}

calc.df.aggregate = function(df, npoints = 60, log=NULL) {
  interval.sec = det.interval.sec(df, c("DatabaseName", "ChannelName"))
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = npoints)
  if (!is.null(log)) {
    log("calc.df.aggregate")
    log(concat("interval.sec: ", interval.sec))
    log(concat("seq s: ", s))
  }
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  ddply(df, .(ServerName,DatabaseName,ChannelName,ts_cut), 
        function(df) {c(nread=1.0*mean(df$nread) / interval.sec, 
                        nadded=1.0*mean(df$nadded) / interval.sec, 
                        nelts=max(df$nelts))})
}

calc.summary.count = function(df) {
  ddply(df, .(ServerName,DatabaseName, ChannelName), function(dft) {
    df.ts.first = df.add.dt(sqldf(concat("select min(ts) ts from dft where nelts != ", head(dft$nelts,1))))
    df.ts.last  = df.add.dt(sqldf(concat("select max(ts) ts from dft where nelts != ", tail(dft$nelts,1))))
    active_min_ts = head(df.ts.first$ts,1)
    active_max_ts = head(df.ts.last$ts,1)
    active_period_sec = as.double(active_max_ts - active_min_ts, units="secs")
    if (!is.na(active_period_sec) && (active_period_sec > 0)) {
    # if (active_period_sec > 0) {
      active_nps = abs(head(dft$nelts,1) - tail(dft$nelts,1)) / active_period_sec  
    } else {
      active_nps = 0
    }
    data.frame(min = min(dft$nelts),
               avg = round(mean(dft$nelts)),
               max = max(dft$nelts),
               first = head(dft$nelts,1),
               last = tail(dft$nelts,1),
               min_ts = head(dft$ts,1),
               max_ts = tail(dft$ts,1),
               active_min_ts = active_min_ts,
               active_max_ts = active_max_ts,
               active_period_sec = active_period_sec,
               active_nps = active_nps)
  })
}

# @todo determine fields/data types/formats dynamically.
write.html.table.count = function(fo, df) {
  # df2 = ddply(df, .(ChannelName), function(dfp) {
  df2 = ddply(df, .(ServerName,DatabaseName, ChannelName), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per channel only one record exists.
    
    c(tr = html.table.row(dfp1$DatabaseName, dfp1$ChannelName, f1000(dfp1$min), 
                          f1000(dfp1$avg), f1000(dfp1$max), f1000(dfp1$first), 
                          f1000(dfp1$last), 
                          format(dfp1$active_min_ts), format(dfp1$active_max_ts),
                          f1000(dfp1$active_period_sec),
                          f1000(dfp1$active_nps)))
  })
  # log.df(log, df2, "table rows:")
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row("DatabaseName","ChannelName","min","avg", "max","first",
                                          "last","active_min_ts","active_max_ts","active_period_sec",
                                          "active_nps"), 
                    # concat.list(df2$tr), 
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}

calc.summary.speed = function(df) {
  interval.sec = det.interval.sec(df, c("DatabaseName", "ChannelName"))
  ddply(df, .(ServerName,DatabaseName, ChannelName), function(dft) {
    #print(dft$ChannelName[1])
    df.ts.first = df.add.dt(sqldf("select min(ts) ts from dft where nread > 0"))
    df.ts.last  = df.add.dt(sqldf("select max(ts) ts from dft where nread > 0"))
    active_min_ts = head(df.ts.first$ts,1) # @todo should be one interval.sec less, read/added are about the previous time segment.
    active_max_ts = head(df.ts.last$ts,1)
    active_period_sec = as.double(active_max_ts - active_min_ts, units="secs")
    #print(active_period_sec)
    if (!is.na(active_period_sec) && (active_period_sec > 0)) {
      # active_readps = head(dft$nelts,1) - tail(dft$nelts,1)) / active_period_sec  
      active_readps = sum(dft$nread) / active_period_sec
      active_addedps = sum(dft$nadded) / active_period_sec
    } else {
      active_readps = 0
      active_addedps = 0
    }
    d = data.frame(min_readps = min(dft$nread) / interval.sec,
               avg_readps = mean(dft$nread) / interval.sec,
               max_readps = max(dft$nread) / interval.sec,
               min_ts = head(dft$ts,1),
               max_ts = tail(dft$ts,1),
               active_min_ts = active_min_ts,
               active_max_ts = active_max_ts,
               active_period_sec = active_period_sec,
               active_readps = active_readps,
               active_addedps = active_addedps)
    #print("Created dataframe")
    d
  })
}

write.html.table.speed = function(fo, df) {
  df2 = ddply(df, .(ServerName,DatabaseName,ChannelName), function(dfp) {
    dfp1 = dfp[1,] # only need first record of dataframe: per channel only one record exists.
    c(tr = html.table.row(dfp1$DatabaseName, dfp1$ChannelName, f1000(dfp1$min_readps), 
                          f1000(dfp1$avg_readps), f1000(dfp1$max_readps), 
                          format(dfp1$active_min_ts), format(dfp1$active_max_ts),
                          f1000(dfp1$active_period_sec),
                          f1000(dfp1$active_readps),
                          f1000(dfp1$active_addedps)))
  })
  # log.df(log, df2, "table rows:")
  writeLines(concat("<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">", 
                    html.table.header.row("DatabaseName","ChannelName","min","avg", "max",
                                          "active_min_ts","active_max_ts","active_period_sec",
                                          "active_readps", "active_addedps"), 
                    # concat.list(df2$tr), 
                    concat(df2$tr, collapse="\n"), 
                    "</table>"), fo)
}


# this one should already be dataframe independent. Just add items to VarTypes for more datatime columns.
write.sql.table = function(con, dfs, runid, chgroup, type="count") {
  df.tablename = det.df.tablename(runid, chgroup, type)
  sqlQuery(con, concat("drop table ", df.tablename))
  # @todo determine datetime columns dynamically (preferably based on actual data types, otherwise on column names)
  varTypes = c(min_ts="datetime", max_ts="datetime", active_min_ts="datetime", active_max_ts="datetime")
  sqlSave(con, dfs, df.tablename, rownames=FALSE, varTypes=varTypes)
}

write.csv.table = function(outdir, dfs, runid, chgroup, type="count") {
  df.tablename = det.df.tablename(runid, chgroup, type)
  write.csv(dfs, file = concat(outdir, "\\", df.tablename, ".csv"), row.names = FALSE)  
}

det.graphname.rel = function(runid, part, title) {
  concat(runid, "-", part, "-", title, ".png")
}


f1000 = function(val) {
  format(round(val, digits=3), big.mark="'", scientific=FALSE)
}

main()
