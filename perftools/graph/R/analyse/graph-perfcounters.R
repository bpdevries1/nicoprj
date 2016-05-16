library(ggplot2)
library(reshape2)
library(plyr)
library(RODBC)
library(sqldf)

main = function() {
  con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=LoadTest2010T439-1;Trusted_Connection=yes;")
  graph.connections(con, outdir="G:\\Testware\\_Results\\Test 439\\Analyse")
}


graph.connections = function(con, outdir=".") {
  dir.create(outdir, recursive=TRUE)
  log = make.logger(paste0(outdir, "/graph-connections.txt"))
  query = paste0("SELECT SampleTimestamp/1e7 ts_sec, MachineName, CategoryName, 
        InstanceName, CounterName, ComputedValue
        FROM LoadTestPerformanceCounterCategory
      	INNER JOIN LoadTestPerformanceCounter
      	ON LoadTestPerformanceCounterCategory.LoadTestRunId=LoadTestPerformanceCounter.LoadTestRunId AND LoadTestPerformanceCounterCategory.CounterCategoryId=LoadTestPerformanceCounter.CounterCategoryId
      	INNER JOIN LoadTestPerformanceCounterInstance i
      	ON LoadTestPerformanceCounterCategory.LoadTestRunId = i.LoadTestRunId AND LoadTestPerformanceCounter.CounterId = i.CounterId
      	INNER JOIN LoadTestPerformanceCounterSample s ON s.InstanceId = i.InstanceId
      where countername like '%onn%'
      -- and countername in ('Connections Active', 'Connections Reset', 'xxConnections Established','xxConnection Failures', 'xxUser Connections')
      and (categoryname = 'TCPv4'
           or categoryname like '%sql%')
      and MachineName like '%GESW%'
      and not MachineName like 'ATZGESW%'
      and not MachineName like 'AXZGESW%'
      and not MachineName like 'ABZGESW%'
      and not MachineName like 'AFZGESW%'
      -- and MachineName = 'ATZGESW006'
      and 1=1")
  df = sqlQuery(con, query)
  # df2 om 'afgeleide' van bepaalde counters te bepalen.
  df2 = ddply(df, .(MachineName, CategoryName, InstanceName, CounterName), 
              function(dft) {
                dft$d = c(0,diff(dft$ComputedValue))
                dft$timediff = c(30, diff(dft$ts_sec))
                dft$dps = dft$d / dft$timediff
                dft})  
  dfa = df.aggr(df2, "ts_sec", "ComputedValue", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  dfa.afg = df.aggr(df2, "ts_sec", "dps", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  
  # eerst even alle waarden 'gewoon'
  dfa.act = sqldf("select * from dfa where CounterName in ('User Connections', 'Connections Established')")
  qplot(ts_sec, ComputedValue, data=dfa.act, colour=CounterName, xlab="Time", ylab="Counter") +
    facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "Connections")
  ggsave(paste0(outdir, "\\Connections.png"), width=10, height=10, dpi=100)
  # ggsave(paste0(outdir, "\\Connections.png"), width=10, height=8, dpi=100)
  
  # dfa.afg = sqldf("select * from dfa where CounterName not in ('User Connections', 'Connections Established')")
  qplot(ts_sec, dps, data=dfa.afg, colour=CounterName, xlab="Time", ylab="Counter") +
    facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "Connections derivative")
  
  ggsave(paste0(outdir, "\\Connections-deriv.png"), width=10, height=10, dpi=100)
  # ggsave(paste0(outdir, "\\Connections-deriv.png"), width=10, height=8, dpi=100)
}

tfn = function() {
df$d = c(0,diff(df$ComputedValue))
df$timediff = c(30, diff(df$ts_sec))
df$dps = df$d / df$timediff
# ts_sec, MachineName, CategoryName, InstanceName, CounterName, ComputedValue

df3 = ddply(df, .(MachineName, CategoryName, InstanceName, CounterName), 
            function(dft) {
              dft$d = c(0,diff(dft$ComputedValue))
              dft$timediff = c(30, diff(dft$ts_sec))
              dft$dps = dft$d / dft$timediff
              dft})

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

df.aggr = function(df, xcol, ycol, nsegments, extracols = c(), aggr.fn=mean) {
  # s = seq(min(df[,xcol]), max(df[,xcol]), length.out = nsegments)
  # bij cut opgeven labels=NULL?
  # df$cut_x = cut(df[,xcol], s)
  df$cut_x = cut(df[,xcol], nsegments,labels=FALSE)
  df2 = ddply(df, as.quoted(c("cut_x", extracols)), 
              function(df) {c(cut_x2 = min(df[,xcol]), calc_y=aggr.fn(df[,ycol]))})
  df2[,xcol] = df2$cut_x2
  df2[,ycol] = df2$calc_y
  # df2
  df2[,c(extracols, xcol, ycol)]
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
