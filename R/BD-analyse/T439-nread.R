library(ggplot2)
library(reshape2)
library(plyr)
library(RODBC)

main = function() {
  con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT439;Trusted_Connection=yes;")
  graph.nread(con)
  # 13-8-2014 19:43:03  13-8-2014 20:15:59

  # graph.huur(con, '2014-08-13 19:43:03', '2014-08-13 20:15:59', outdir="G:\\Testware\\_Results\\Test 439\\Analyse")
  test.start = "2014-08-13 17:22:22"
  test.end = "2014-08-13 20:29:43"
  ftsv = file("G:\\Testware\\_Results\\Test 439\\Analyse\\analyse.tsv", "w")

  graph.huur(con, test.start, "2014-08-13 19:43:03", "2014-08-13 20:15:59", outdir="G:\\Testware\\_Results\\Test 439\\Analyse\\CPUbound", ftsv, "cpubound")
  graph.huur(con, test.start, "2014-08-13 17:33:41", "2014-08-13 18:02:51", outdir="G:\\Testware\\_Results\\Test 439\\Analyse\\Diskbound", ftsv, "diskbound")
  graph.huur(con, test.start, test.start, test.end, outdir="G:\\Testware\\_Results\\Test 439\\Analyse\\Alles", ftsv, "alles")
  close(ftsv)
}

graph.huur = function(con, test.start, start, end, outdir=".", ftsv, part) {
  dir.create(outdir, recursive=TRUE)
  log = make.logger(paste0(outdir, "/analyse.txt"))
  log("Start of analysis")
  query = paste("SELECT 
    [DatabaseName]
    ,[ChannelName]
    ,[CollectTimeStamp]
    ,[NumberOfMessagesReadSinceLastTime] nread
    ,[NumberOfMessagesAddedSinceLastTime] nadded
    FROM [PerfTestResultsT439].[dbo].[ToeslagenDataCollector]
    where 1=1
    and ChannelName in ('ChannelInHuur')
    and RunId = 1
    and [CollectTimeStamp] between '", start, "' and '", end, "'
    order by collecttimestamp", sep="")
  
  df = sqlQuery(con, query)
  #log(paste0("Sum of nread: ", sum(df$nread)))
  #log(paste0("Sum of nadded: ", sum(df$nadded)))
  log("Sum of nread: ", sum(df$nread))
  log("Sum of nadded: ", sum(df$nadded))
  write.tsv(ftsv, part, "sum nread", sum(df$nread))
  write.tsv(ftsv, part, "sum nadded", sum(df$nadded))
  
  df$ts_psx = as.POSIXct(strptime(df$CollectTimeStamp, format="%Y-%m-%d %H:%M:%S"))
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = 60)
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  #df$nread2=strtoi(df$nread)
  #df$nadded2=strtoi(df$nadded)
  df2 = ddply(df, .(DatabaseName,ChannelName,ts_cut), 
              function(df) {c(nread=0.1*mean(df$nread), nadded=0.1*mean(df$nadded))})
  qplot(ts_cut,nread,data=df2,colour=DatabaseName, xlab="Time", ylab="read/sec")
  ggsave(paste0(outdir, "\\T439-nhuur.png"), width=10, height=8, dpi=100)

  # tracelog
  query = paste0("select Service, Tijdstip, berichttype, verwerkingstijd, verwerkingstype, server, threadid
    from [PerfTestResultsT439].[dbo].[TraceLogDuration]
    where berichttype like '%Process%'
    and service like '%Huur%'
    and verwerkingstype = 0  
    and [Tijdstip] between '", start, "' and '", end, "'")
  log("query: ", query)
  df = sqlQuery(con, query)
  nmsg = length(df$Service)
  log("#ES elements in time segment: ", nmsg)
  start.psx = as.POSIXct(strptime(start, format="%Y-%m-%d %H:%M:%S"))
  end.psx = as.POSIXct(strptime(end, format="%Y-%m-%d %H:%M:%S"))
  T = as.double(end.psx - start.psx, units="secs")
  X = 1.0 * nmsg / T
  R = mean(0.001*df$verwerkingstijd)
  N = X * R
  nServers = 6
  CPU.per.server = 2

  util.vars = graph.huur.proc.utilisation(con, test.start, start, end, outdir, log)
  avg.proc.util = util.vars[1]
  
  U = 0.01 * avg.proc.util 
  D = nServers * CPU.per.server * 1.0 * U / X
  procQT = R-D
  queue.length = procQT * X
  queue.length.per.server = queue.length / nServers
  log("time segment (sec): ", T)
  log("throughtput X (/sec): ", X)
  log("avg time (sec): ", R)
  log("#threads (N): ", N)
  log("Utilisation (U): ", U)
  log("Service Demand D (sec): ", D)
  log("(Processor) queueing time (sec): ", procQT)
  log("avg queue length: ", queue.length)
  log("avg queue length per server: ", queue.length.per.server)
  write.tsv(ftsv, part, "time segment (sec)", T)
  write.tsv(ftsv, part, "throughtput X (/sec)", X)
  write.tsv(ftsv, part, "avg time (sec)", R)
  write.tsv(ftsv, part, "#threads (N)", N)
  write.tsv(ftsv, part, "Utilisation (U)", U)
  write.tsv(ftsv, part, "Service Demand D (sec)", D)
  write.tsv(ftsv, part, "(Processor) queueing time (sec)", procQT)
  write.tsv(ftsv, part, "avg queue length", queue.length)
  write.tsv(ftsv, part, "avg queue length per server", queue.length.per.server)
  # plot queue lengths
  
  queue.vars = graph.huur.procqueue(con, test.start, start, end, outdir, log)
  avg.proc.queue.length = queue.vars[1]
  # log("avg processor queue length: ", avg.proc.queue.length)
  
  # log("avg processor utilisation (%): ", avg.proc.util)
  write.tsv(ftsv, part, "avg processor queue length", avg.proc.queue.length)
  write.tsv(ftsv, part, "avg processor utilisation", avg.proc.util )
  
  # close(fo)
  # log(NULL)
  log()

}


graph.huur.procqueue = function(con, test.start, seg.start, seg.end, outdir, log.param=NULL) {
  if (is.null(log.param)) {
    log = make.logger(paste0(outdir, "/analyse-proc-util.txt"))
  } else {
    log = log.param    
  }
  #test.start.psx = as.POSIXct(strptime(test.start, format="%Y-%m-%d %H:%M:%S"))
  #seg.start.psx = as.POSIXct(strptime(seg.start, format="%Y-%m-%d %H:%M:%S"))
  #seg.end.psx = as.POSIXct(strptime(seg.end, format="%Y-%m-%d %H:%M:%S"))
  #seg.start.sec = as.double(seg.start.psx - test.start.psx, units="secs")
  #eg.end.sec = as.double(seg.end.psx - test.start.psx, units="secs")
  seg.secs = segment.secs(test.start, seg.start, seg.end)
  
  query = paste0("with min_ts as (select min(sampleTimeStamp) min_ts from [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterSample])
          select cat.CategoryName, cat.MachineName system,
                 c.CounterName, i.InstanceName, (s.SampleTimeStamp-min_ts.min_ts) / 1e7 ts_sec,
               s.ComputedValue qlen
          from min_ts, [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterSample] s
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterInstance] i on s.InstanceId = i.InstanceId
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounter] c on i.CounterId = c.CounterId
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterCategory] cat on c.CounterCategoryId = cat.CounterCategoryId
          where cat.CategoryName = 'System'
          and cat.MachineName in ('ATZPRSW009','ATZPRSW010','ATZPRSW011','ATZPRSW012','ATZPRSW013','ATZPRSW014')
          and c.CounterName = 'Processor Queue Length'
          and (s.SampleTimeStamp-min_ts.min_ts) / 1e7 between ", seg.secs[1], " and ", seg.secs[2])
  log(query)
  df = sqlQuery(con, query)
  # df$timesec = (df$SampleTimeStamp - min(df$SampleTimestamp)) / 1e7
  # df$timesec = df$SampleTimeStamp / 1e7
  df2 = df.aggr(df, "ts_sec", "qlen", 20, c("system"), mean)
  qplot(ts_sec,qlen,data=df2,colour=system, xlab="Time (sec)", ylab="Processor queue length")
  ggsave(paste0(outdir, "/T439-huur-procqlen-system.png"), width=10, height=8, dpi=100)
  df2 = df.aggr(df, "ts_sec", "qlen", 20)
  qplot(ts_sec,qlen,data=df2,xlab="Time (sec)", ylab="Processor queue length")
  ggsave(paste0(outdir, "/T439-huur-procqlen-avg.png"), width=10, height=8, dpi=100)
  
  log("Avg processor queue length: ", mean(df2$qlen))

  if (is.null(log.param)) {
    log()
  } else {
    # nothing, keep log open.    
  }
  c(mean(df2$qlen))
}

graph.huur.proc.utilisation = function(con, test.start, seg.start, seg.end, outdir, log.param=NULL) {
  if (is.null(log.param)) {
    log = make.logger(paste0(outdir, "/analyse-proc-util.txt"))
  } else {
    log = log.param    
  }
  log("Calc and graph processor utilisations")
  seg.secs = segment.secs(test.start, seg.start, seg.end)
  query = paste0("with min_ts as (select min(sampleTimeStamp) min_ts from [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterSample])
          select 'T439', i.instanceID, cat.CategoryName, cat.MachineName system,
          c.CounterName, i.InstanceName inst, (s.SampleTimeStamp-min_ts.min_ts) / 1e7 ts_sec,
          s.ComputedValue util
          from min_ts, [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterSample] s
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterInstance] i on s.InstanceId = i.InstanceId
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounter] c on i.CounterId = c.CounterId
          join [LoadTest2010T439-1].[dbo].[LoadTestPerformanceCounterCategory] cat on c.CounterCategoryId = cat.CounterCategoryId
          where cat.CategoryName = 'Processor'
          and i.InstanceName = '_Total'
          and cat.MachineName in ('ATZPRSW009','ATZPRSW010','ATZPRSW011','ATZPRSW012','ATZPRSW013','ATZPRSW014')
          and c.CounterName = '% Processor Time'
          and (s.SampleTimeStamp-min_ts.min_ts) / 1e7 between ", seg.secs[1], " and ", seg.secs[2])
  df = sqlQuery(con, query)
  qplot(ts_sec,util,data=df,colour=system, xlab="Time (sec)", ylab="Processor Utilisation (%)")
  ggsave(paste0(outdir, "/T439-huur-proc-util.png"), width=10, height=8, dpi=100)
  
  df2 = df.aggr(df, "ts_sec", "util", 30)
  qplot(ts_sec,util,data=df2,xlab="Time (sec)", ylab="Processor Utilisation (%)")
  ggsave(paste0(outdir, "/T439-huur-proc-util-avg.png"), width=10, height=8, dpi=100)
  log("Avg processor utilisation (%): ", mean(df2$util))
  if (is.null(log.param)) {
    log()
  } else {
    # nothing, keep log open.    
  }
  c(mean(df2$util))
}  

graph.nread.old = function(con) {
  query = "SELECT 
    [DatabaseName]
    ,[ChannelName]
    ,[CollectTimeStamp]
    ,[NumberOfMessagesReadSinceLastTime]
    FROM [PerfTestResultsT439].[dbo].[ToeslagenDataCollector]
    where 1=1
    and ChannelName in ('ChannelInHuur', 'ChannelInZorg', 'ChannelInKinderOpvang', 'ChannelInKindGebondenBudget', 'ChannelInAwir', 'ChannelInFrsProcesVerwerkenMelding')
    and RunId = 1
    order by collecttimestamp"
  
  df = sqlQuery(con, query)
  df$ts_psx = as.POSIXct(strptime(df$CollectTimeStamp, format="%Y-%m-%d %H:%M:%S"))
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = 60)
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  df$nread=strtoi(df$NumberOfMessagesReadSinceLastTime)
  #df2 = ddply(df, .(DatabaseName,ChannelName,ts_cut), 
  #            function(df) {c(nread=0.1*mean(df$nread))})
  df2 = ddply(df, as.quoted(c("DatabaseName","ChannelName","ts_cut")), 
              function(df) {c(nread=0.1*mean(df$nread))})
  
  qplot(ts_cut,nread,data=df2,colour=DatabaseName, xlab="Time", ylab="read/sec")
  ggsave("G:\\Testware\\_Results\\Test 439\\Analyse\\T439-nread.png", width=10, height=8, dpi=100)
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
