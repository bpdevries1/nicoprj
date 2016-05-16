setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
load.def.libs()

main = function() {
  testnr = commandArgs()[6]
  print(testnr)
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  print(connstring)
  print(outdir)
  con = odbcDriverConnect(connection=connstring)
  graph.tlg(con, outdir=outdir, "all", "2014-01-01 00:00", "2016-01-01 00:00")
}

if (FALSE) {
  testnr = "450"
  print(testnr)
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  print(connstring)
  print(outdir)
  con = odbcDriverConnect(connection=connstring)
  part = "all"
  start = "2014-09-16 00:00"
  end = "2016-09-16 0:00"
  npoints = 60
  width = 12
  
}

graph.tlg = function(con, outdir=".", part, start, end, npoints = 60, width = 12, treshold = 120) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/analyse-tracelog-errors.txt"))
  log("Start of analysis")
  query = concat("SELECT dayhour ts, sum(sum_sec) sum_sec
      from _temp_trace_errors
      where verwerkingstype = 2
      and dayhour between '", start, "' and '", end, "'
      group by dayhour")
  
  df = query.with.log(con, query, log)
  print("if df is empty, check table _temp_trace_errors, create with tracelog-errors.sql")
  log("if df is empty, check table _temp_trace_errors, create with <TODO>")
  # df$ts_psx = as.POSIXct(strptime(df$ES_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df = df.add.dt(df)
  log.df(log, df, "df with posix timestamp:")
  qplot(ts_psx, sum_sec, data=df, xlab="Time (per hour)", ylab="Time in retries/errors (sec)",
        main = "Time in retries") +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", "tracelog-errors-time.png"), width=width, height=6, dpi=100)
  
  # en ook per server:
  query = concat("SELECT server, dayhour ts, sum(sum_sec) sum_sec
      from _temp_trace_errors
      where verwerkingstype = 2
      and dayhour between '", start, "' and '", end, "'
      group by server, dayhour")
  
  df = df.add.dt(query.with.log(con, query, log))
  log.df(log, df, "df with posix timestamp:")
  qplot(ts_psx, sum_sec, data=df, xlab="Time (per hour)", ylab="Time in retries/errors (sec)",
        main = "Time in retries", colour=server, shape=server) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter")
    
  ggsave(paste0(outdir, "\\", part, "-", "tracelog-errors-time-server.png"), width=width, height=8, dpi=100)
  
  # tijden in fout/retry als percentage van het totaal
  query =  "with sum_sec_both (dayhour, sum_sec) as (
              select dayhour, sum(sum_sec)
              from _temp_trace_errors
              group by dayhour
            )
            select tte.dayhour ts, 100.0 * sum(tte.sum_sec)/sum(ssb.sum_sec) perc
            from sum_sec_both ssb join _temp_trace_errors tte on ssb.dayhour = tte.dayhour
            where tte.verwerkingstype = 2
            group by tte.dayhour"
  df = df.add.dt(query.with.log(con, query, log))
  log.df(log, df, "df with posix timestamp:")
  qplot(ts_psx, perc, data=df, xlab="Time (per hour)", ylab="Percentage time in retries/errors",
        main = "Percentage time in retries") +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", "tracelog-errors-time-perc.png"), width=width, height=6, dpi=100)
  
  log("finished")
  log()
}

main()

