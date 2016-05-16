library(ggplot2)
library(reshape2)
library(plyr)
library(RODBC)
library(sqldf)

main = function() {
  con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=LoadTest2010T446;Trusted_Connection=yes;")
  
  if (TRUE) {
    graph.connections(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tcp-conn", "all", "2014-09-11 12:00", "2014-09-18 15:00")
  }
  graph.connections(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tcp-conn", "opi", "2014-09-15 03:00", "2014-09-15 09:00")
  # graph.connections(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tcp-conn", "part2", "2014-09-14 12:00", "2014-09-17 12:00")
  
  
}

graph.connections = function(con, outdir=".", part, start, end, npoints = 60, width = 12) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/graph-connections.txt"))
  query = paste0("SELECT SampleTimestamp/1e7 ts_sec
               , convert(datetime, 1e-7*(sampletimestamp/86400) - 109206.918) ts_cet
               , MachineName, CategoryName, 
                 InstanceName, CounterName, ComputedValue
                 FROM LoadTestPerformanceCounterCategory
                 INNER JOIN LoadTestPerformanceCounter
                 ON LoadTestPerformanceCounterCategory.LoadTestRunId=LoadTestPerformanceCounter.LoadTestRunId AND LoadTestPerformanceCounterCategory.CounterCategoryId=LoadTestPerformanceCounter.CounterCategoryId
                 INNER JOIN LoadTestPerformanceCounterInstance i
                 ON LoadTestPerformanceCounterCategory.LoadTestRunId = i.LoadTestRunId AND LoadTestPerformanceCounter.CounterId = i.CounterId
                 INNER JOIN LoadTestPerformanceCounterSample s ON s.InstanceId = i.InstanceId
                 where countername like '%onn%'
                 and (categoryname = 'TCPv4'
                 or categoryname like '%sql%')
                 and MachineName like '%GESW%'
                 and not MachineName like 'ATZGESW%'
                 and not MachineName like 'AXZGESW%'
                 and not MachineName like 'ABZGESW%'
                 and not MachineName like 'AFZGESW%'
                 and sampletimestamp/1e7 between convert(numeric(15,6), convert(datetime, '", start, "')) * 86400 + 9435477720
                                             and convert(numeric(15,6), convert(datetime, '", end, "'))   * 86400 + 9435477720
                 -- and MachineName = 'ATZGESW006'
                 and 1=1
                 order by MachineName, CategoryName, InstanceName, CounterName, sampletimestamp")
  df = sqlQuery(con, query)
  df$ts_psx = as.POSIXct(strptime(df$ts_cet, format="%Y-%m-%d %H:%M:%S"))
  # df.deriv om 'afgeleide' van bepaalde counters te bepalen.
  df.deriv = ddply(df, .(MachineName, CategoryName, InstanceName, CounterName), 
              function(dft) {
                dft$d = c(0,diff(dft$ComputedValue))
                dft$timediff = c(30, diff(dft$ts_sec))
                dft$dps = dft$d / dft$timediff
                dft$dpmin = 60 * dft$dps
                dft})  
  # df_aggr = calc.df.aggr.ts(df.deriv, "ts_psx", "ComputedValue", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  df_aggr = calc.df.aggr.ts(df, "ts_psx", "ComputedValue", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  # df_deriv_aggr = calc.df.aggr.ts(df.deriv, "ts_psx", "dps", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  df_deriv_aggr = calc.df.aggr.ts(df.deriv, "ts_psx", "dpmin", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  
  # eerst even aantal waarden 'gewoon'. sqldf snapt geen data.frames met punten in de naam.
  dfa.act = sqldf("select * from df_aggr where CounterName in ('User Connections', 'Connections Established')")
  
  g = guide_legend("Counter", ncol = 4)
  qplot(ts_psx, ComputedValue, data=dfa.act, colour=CounterName, shape=CounterName, xlab="Time", ylab="Counter") +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter") +
    facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "Connections") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g)
  ggsave(paste0(outdir, "\\", part, "-", "Connections.png"), width=10, height=10, dpi=100)
  
  # dan afgeleide
  df_deriv_aggr.sel = sqldf("select * from df_deriv_aggr where CounterName not in ('User Connections', 'Connections Established')")
  
  qplot(ts_psx, dpmin, data=df_deriv_aggr.sel, colour=CounterName, shape=CounterName, xlab="Time", ylab="Counter deriv / min") +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter") +
    facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "Connections derivative") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g)
  ggsave(paste0(outdir, "\\", part, "-", "Connections-deriv.png"), width=10, height=10, dpi=100)
  
}

make.logger = function(filename) {
  fo = file(filename, "w")
  fn = function(...) {
    # logstr = paste0(list(...))
    logstr = paste0(...)
    if (length(logstr) == 0) {
      close(fo) 
    } else {
      writeLines(logstr, fo)
    }
  }
  fn  
}

calc.df.aggr = function(df, xcol, ycol, nsegments, extracols = c(), aggr.fn=mean) {
  df$cut_x = cut(df[,xcol], nsegments,labels=FALSE)
  df.ply = ddply(df, as.quoted(c("cut_x", extracols)), 
              function(df) {c(cut_x2 = min(df[,xcol]), calc_y=aggr.fn(df[,ycol]))})
  df.ply[,xcol] = df.ply$cut_x2
  df.ply[,ycol] = df.ply$calc_y
  df.ply[,c(extracols, xcol, ycol)]
}

calc.df.aggr.ts = function(df, xcol, ycol, nsegments, extracols = c(), aggr.fn=mean) {
  s = seq(min(df[,xcol]), max(df[,xcol]), length.out = nsegments)
  df$cut_x = cut(df[,xcol], s)
  df$ts_cut = as.POSIXct(strptime(df$cut_x, format="%Y-%m-%d %H:%M:%S"))
  df.ply = ddply(df, as.quoted(c("cut_x", extracols)), 
              function(df) {c(calc_y=aggr.fn(df[,ycol]))})
  
  df.ply[,xcol] = as.POSIXct(strptime(df.ply$cut_x, format="%Y-%m-%d %H:%M:%S"))
  df.ply[,ycol] = df.ply$calc_y
  df.ply[,c(extracols, xcol, ycol)]
}

segment.secs = function(test.start, seg.start, seg.end) {
  test.start.psx = as.POSIXct(strptime(test.start, format="%Y-%m-%d %H:%M:%S"))
  seg.start.psx = as.POSIXct(strptime(seg.start, format="%Y-%m-%d %H:%M:%S"))
  seg.end.psx = as.POSIXct(strptime(seg.end, format="%Y-%m-%d %H:%M:%S"))
  seg.start.sec = as.double(seg.start.psx - test.start.psx, units="secs")
  seg.end.sec = as.double(seg.end.psx - test.start.psx, units="secs")
  c(seg.start.sec, seg.end.sec)  
}

write.tsv = function(ftsv, part, name, value) {
  writeLines(paste(part, name, value, sep="\t"), ftsv)
}
