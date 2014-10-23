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
  
  # ff niet:
  # graph.tlg(con, outdir=outdir, "all", "2014-01-01 00:00", "2016-01-01 00:00")
  
  # graph.tlg(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tracelog-gap", "part1", "2014-09-11 12:00", "2014-09-12 15:00")
  # graph.tlg(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tracelog-gap", "part2", "2014-09-14 12:00", "2014-09-17 12:00")
  graph.thread.details(con,outdir=outdir,"1hour", "2014-10-11 20:00", "2014-10-11 21:00")
}

if (FALSE) {
  con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT446;Trusted_Connection=yes;")
  outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tracelog-gap"
  part = "all"
  start = "2014-09-16 00:00"
  end = "2014-09-16 24:00"
  npoints = 60
  width = 12
  
}

graph.tlg = function(con, outdir=".", part, start, end, npoints = 60, width = 12, treshold = 120) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/analyse-workerthreads.txt"))
  log("Start of analysis")
  query = concat("SELECT server, tijdstip, aantal
      from dbo._temp_workerthreads
    where tijdstip between '", start, "' and '", end, "'
    order by server, tijdstip")
  
  log(query)
  df = sqlQuery(con, query)
  log("query executed, df summary:")
  log(summary(df))
  log("end of summary.")
  log("if df is empty, check table _temp_workerthreads, create with analysis - number of worker threads.sql")
  print("if df is empty, check table _temp_workerthreads, create with analysis - number of worker threads.sql")
  df$ts_psx = as.POSIXct(strptime(df$tijdstip, format="%Y-%m-%d %H:%M:%S"))
  
  #qplot.dt(df$ts_psx,df$aantal, xlab="Time", ylab="Aantal workerthreads", colour=df$server, 
  #         title = concat("workerthreads-",part))

  #qplot(ts_psx,aantal, data=df,xlab="Time", ylab="Aantal workerthreads", colour=server, shape=server,
  #         main = concat("workerthreads-",part)) +
  #  scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  
  #ggsave(paste0(outdir, "\\", part, "-", "workerthreads.png"), width=width, height=6, dpi=100)
  
  df_aggr = calc.df.aggr.ts(df, "ts_psx", "aantal", npoints, c("server"), mean)  
  qplot(ts_psx,aantal, data=df_aggr,xlab="Time", ylab="Aantal workerthreads", colour=server, shape=server,
           main = concat("workerthreads-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", "workerthreads.png"), width=width, height=6, dpi=100)
  
  log("finished")
  log()
}

graph.thread.details = function(con, outdir=".", part, start, end, npoints = 60, width = 12, treshold = 120) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/analyse-workerthreads.txt"))
  log("Start of analysis")
  query = "SELECT ThreadId
    ,timediff
    ,ES_Tijdstip
    ,ES_Service
    ,ES_BerichtType
    ,ES_Verwerkingstijd
    ,BS_Tijdstip
    FROM _temp_tracelog_gap
    where server = 'atzprsw030'
    and es_berichttype = 'Process()'
    and (es_tijdstip between '2014-10-11 20:00' and '2014-10-11 21:00'
         or  bs_tijdstip between '2014-10-11 20:00' and '2014-10-11 21:00')"
  df = sqlQuery(con, query)
  df$ts_psx_es = as.POSIXct(strptime(df$ES_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ts_psx_bs = as.POSIXct(strptime(df$BS_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ThreadId = as.factor(df$ThreadId)
  qplot(x=ts_psx_es, xend=ts_psx_bs, y=ThreadId, yend=ThreadId, data=df,xlab="Time", 
        ylab="ThreadId", geom="segment",
        main = concat("workerthreads-gaps-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(concat(outdir, "\\", part, "-", "workerthreads-gap-details.png"), width=width, height=6, dpi=100)

  # andere periode dat het beter gaat:
  query = "SELECT ThreadId
    ,timediff
    ,ES_Tijdstip
    ,ES_Service
    ,ES_BerichtType
    ,ES_Verwerkingstijd
    ,BS_Tijdstip
    FROM _temp_tracelog_gap
    where server = 'atzprsw030'
    and es_berichttype = 'Process()'
    and timediff < 120
    and (es_tijdstip between '2014-10-08 11:00' and '2014-10-08 12:00'
         or  bs_tijdstip between '2014-10-08 11:00' and '2014-10-08 12:00')"
  df = sqlQuery(con, query)
  df$ts_psx_es = as.POSIXct(strptime(df$ES_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ts_psx_bs = as.POSIXct(strptime(df$BS_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ThreadId = as.factor(df$ThreadId)
  qplot(x=ts_psx_es, xend=ts_psx_bs, y=ThreadId, yend=ThreadId, data=df,xlab="Time", 
        ylab="ThreadId", geom="segment",
        main = concat("workerthreads-gaps-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(concat(outdir, "\\", part, "-", "workerthreads-gap-details-beter.png"), width=width, height=6, dpi=100)
  
  
  # en van BS->ES
  query = "SELECT ThreadId
    ,timediff
    ,ES_Tijdstip
    ,ES_Service
    ,ES_BerichtType
    ,ES_Verwerkingstijd
    ,BS_Tijdstip
    FROM _temp_tracelog_verw
    where server = 'atzprsw030'
    and es_berichttype = 'Process()'"
#and (es_tijdstip between '2014-10-11 20:00' and '2014-10-11 21:00'
#     or  bs_tijdstip between '2014-10-11 20:00' and '2014-10-11 21:00')"
  df = sqlQuery(con, query)
  df$ts_psx_bs = as.POSIXct(strptime(df$BS_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ts_psx_es = as.POSIXct(strptime(df$ES_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  df$ThreadId = as.factor(df$ThreadId)
  qplot(x=ts_psx_bs, xend=ts_psx_es, y=ThreadId, yend=ThreadId, data=df,xlab="Time", 
        ylab="ThreadId", geom="segment", arrow = arrow(length = unit(0.5, "cm")),
        main = concat("workerthreads-verwerking",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(concat(outdir, "\\", part, "-", "workerthreads-verwerking-details.png"), width=width, height=6, dpi=100)
  
  
}

main()

