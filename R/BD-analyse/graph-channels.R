setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
load.def.libs()
source("graph-channels-lib.R")


main = function() {
  options(warn=-1)
  define.channel.groups()
  testnr = commandArgs()[6]
  runid = commandArgs()[7]
  channel.group = commandArgs()[8]
  # write(concat("testnr: ", testnr, ", runid:", runid, ", channels: ", channel.group), "")
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con = odbcDriverConnect(connection=connstring)
  graph.dc(con, outdir, channel.group, runid, "2010-01-01 00:00", "2016-01-01 00:00")
  # graph.queuecount(con, outdir=outdir, testnr, "2014-01-01 00:00", "2016-01-01 00:00")
  # graph.dc1(con, outdir=outdir, "ChannelInHuur", runid)
  odbcClose(con)
  #w = warnings()
  #last.warning = NULL
}

test = function() {
  testnr = "452"
  runid = "1"
  chgroup = "diff1000"
  part = chgroup
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con = odbcDriverConnect(connection=connstring)
  start = "2014-09-16 00:00"
  end = "2016-09-16 23:00"
  npoints = 60
  width = 12
  # graph.dc(con, outdir, channel.group, runid, "2014-01-01 00:00", "2016-01-01 00:00")
  # odbcClose(con)
  df2 = sqldf("select * from df where ChannelName = 'ChannelInvalidMessageKlantbeeld'")
  df3 = df.add.dt(sqldf(concat("select min(ts) ts from df2 where nelts != ", df2$nelts[1])))
  df4 = df.add.dt(sqldf(concat("select max(ts) ts from df2 where nelts != ", df2$nelts[length(df2$nelts)])))
  ts.diff = as.double(df4$ts_psx - df3$ts_psx, units="secs")  
  nps = abs(df2$nelts[1] - df2$nelts[length(df2$nelts)]) / ts.diff
  # df4$ts_psx - df3$ts_psx

  # pre: df is gevuld: alle counts voor alle channels.
  
  # deze zowel voor DB tabel als CSV
  df.aggr = calc.aggr.count(df)
  df.aggr$min_ts_psx = as.POSIXct(strptime(df.aggr$min_ts, format="%Y-%m-%d %H:%M:%S"))
  df.aggr$min_ts_psx2 = as.POSIXct(df.aggr$min_ts)
  str(df$min_ts)
  str(df3)
  df.table = det.df.tablename(runid, chgroup, "count")

  # sqlSave(con, df.aggr, df.table, rownames=FALSE, test=TRUE)
  sqlQuery(con, concat("drop table ", df.table))

  # varTypes = c(timestamp="datetime")
  varTypes = c(min_ts="datetime", max_ts="datetime", active_min_ts="datetime", active_max_ts="datetime")
  
  
  sqlSave(con, df.aggr, df.table, rownames=FALSE, varTypes=varTypes)
  
  write.csv(df.aggr, file = concat(outdir, "\\", df.table, ".csv"), row.names = FALSE)
  
  # library(xlsx)
  
  xlsFile <- odbcConnectExcel2007(concat(outdir, "\\", "Test.xlsx"), readOnly = FALSE)
  sqlSave(xlsFile,newdat, append=FALSE)
  odbcCloseAll()
  
  # typeInfo, varTypes, sqlSave, RODBC, R
  
  # post: df.aggr is gevuld met per channel:
  # - min, max, avg, first, last.
  # - min_ts, max_ts
  # - active_min_ts, active_max_ts
  # - active_nps
 
  df2.aggr = calc.aggr.count(df2)
}






# voor testen/debuggen:
if (FALSE) {
  con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT452;Trusted_Connection=yes;")
  outdir="G:\\Testware\\_Results\\Test 452\\Analyse"
  part = "diff100000"
  start = "2014-09-16 00:00"
  end = "2016-09-16 23:00"
  npoints = 60
  width = 12
  runid = "1"
  odbcClose(con)
  
  
}

graph.dc = function(con, outdir=".", part, runid, start, end, npoints = 60, width = 12) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/analyse-log.txt"))
  log("Start of analysis")
  # @todo named query parameters.
  diff = regmatches(part, regexec("^diff(\\d+)$", part))[[1]][2]
  if (is.na(diff)) {
    query = channel.query.chgroup(part, runid, start, end)
  } else {
    query = channel.query.diff(diff, runid, start, end)
  }
  # print(query)
  log(query)
  # df = sqlQuery(con, query)
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
  
  log("before qplot nread")
  
  graph.dc.counts(dfaggr, outdir, runid, part, width, log)
  graph.dc.speed(dfaggr, outdir, runid, part, width, log)
  
  log("finished")
  log()
  
}


# kleine grafiek maken, om in (HTML) report op te nemen.
graph.dc1 = function(con, outdir=outdir, channel, runid, npoints = 30, width = 5) {
  dir.create(outdir, recursive=TRUE)
  log = make.logger(paste0(outdir, "/analyse-log.txt"))
  log("Start of analysis")
  query = paste0("SELECT 
     [DatabaseName]
     ,[ChannelName]
     ,[CollectTimeStamp]
     ,[NumberOfMessagesReadSinceLastTime] nread
     ,[NumberOfMessagesAddedSinceLastTime] nadded
     ,[NumberOfElements] nelts
     FROM [dbo].[ToeslagenDataCollector]
     where ChannelName = '", channel, "'
    and RunId = ", runid, "
    and [NumberOfElements] > 0
    -- soms grote outliers
    -- and [NumberOfMessagesReadSinceLastTime] < 1000
    order by collecttimestamp")

  log(query)
  df = sqlQuery(con, query)
  log("query executed")
  log(summary(df))
  df$ts_psx = as.POSIXct(strptime(df$CollectTimeStamp, format="%Y-%m-%d %H:%M:%S"))
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = npoints)
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  df2 = ddply(df, .(DatabaseName,ChannelName,ts_cut), 
              function(df) {c(nread=1.0*mean(df$nread) / 30, nelts=max(df$nelts))})
  log("before qplot nread")
  
  # qplot(ts_cut,nread,data=df2,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="read/sec") +
  qplot(ts_cut,nread,data=df2, ylab=NULL, xlab=NULL) +
    #scale_shape_manual(name="Channel", values=rep(1:25,10)) +
    #scale_colour_discrete(name="Channel") +
    scale_x_datetime(labels = date_format("%H:%M"))
  
  ggsave(paste0(outdir, "\\", runid, "-", channel, "-channels-read.png"), width=3, height=1, dpi=100)
  
  
}

graph.queuecount = function(con, outdir=".", testnr, start, end, npoints = 60, width = 12) {
  dir.create(outdir, recursive=TRUE)
  log = make.logger(paste0(outdir, "/analyse-log.txt"))
  connstring.pt = det.connstring.PT(testnr)
  
  query = concat("WITH min_event (minCEventID) as (select min(CEventID) from [dbo].[queuecount])
      SELECT cur_ts
      ,queue
      ,CEventID
      ,aantal
      FROM [dbo].[queuecount], min_event
      where minCEventID = CEventID
      and [cur_ts] between '", start, "' and '", end, "'
      order by cur_ts")
  df = sqlQuery(con, query)
  df$ts_psx = as.POSIXct(strptime(df$cur_ts, format="%Y-%m-%d %H:%M:%S"))
  df_aggr = calc.df.aggr.ts(df, "ts_psx", "aantal", npoints, c("queue", "CEventID"), mean)
  # df_deriv_aggr = calc.df.aggr.ts(df.deriv, "ts_psx", "dps", 60, c("queue", "CEventID"), mean)
  
  g = guide_legend("queue", ncol = 2)
  qplot(ts_psx, aantal, data=df_aggr, ylab="Aantal", xlab="Datum/tijd", colour=queue, shape=queue) +
    scale_shape_manual(name="queue", values=rep(1:25,10)) +
    scale_colour_discrete(name="queue") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", "queue-count.png"), width=width, height=8, dpi=100)
  
  # ook afgeleide, toename/afname per seconde.
  df.deriv = ddply(df, .(queue, CEventID), 
                   function(dft) {
                     dft$d = abs(c(0,diff(dft$aantal)))
                     # dft$timediff = c(30, diff(dft$ts_sec))
                     # nu elke 5 minuten een meting ongeveer
                     dft$timediff = 300
                     # @todo? absolute waarde berekenen?
                     dft$dps = dft$d / dft$timediff
                     # dft$dpmin = 60 * dft$dps
                     dft})  
  df_deriv_aggr = calc.df.aggr.ts(df.deriv, "ts_psx", "dps", npoints, c("queue", "CEventID"), mean)
  
  qplot(ts_psx, dps, data=df_deriv_aggr, colour=queue, shape=queue, xlab="Time", ylab="#msg/sec") +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter") +
    # facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "#messages derivative") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  # ggsave(paste0(outdir, "\\", part, "-", "Connections-deriv.png"), width=10, height=10, dpi=100)
  ggsave(paste0(outdir, "\\", "queue-count-deriv.png"), width=width, height=8, dpi=100)
}

main()
