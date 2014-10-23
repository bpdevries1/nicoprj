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
  # graph.tlg(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tracelog-gap", "part1", "2014-09-11 12:00", "2014-09-12 15:00")
  # graph.tlg(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tracelog-gap", "part2", "2014-09-14 12:00", "2014-09-17 12:00")
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
  log = make.logger(paste0(outdir, "/analyse-log.txt"))
  log("Start of analysis")
  query = paste0("SELECT 
      [ES_Tijdstip]
      ,[timediff]
      ,0.001*[ES_verwerkingstijd] verw_tijd
      ,100.0 * (timediff / ([timediff] + 0.001*[ES_verwerkingstijd])) timediff_perc
    FROM [dbo].[_temp_tracelog_gap]
    where timediff < ", treshold, "
    and [ES_Tijdstip] between '", start, "' and '", end, "'
    and ES_BerichtType = 'Process()'
    order by ES_Tijdstip")
  
  log(query)
  df = sqlQuery(con, query)
  log("query executed, df summary:")
  log(summary(df))
  log("end of summary.")
  log("if df is empty, check table _temp_tracelog_gap, create with Analysis - tracelog - gaps.sql")
  print("if df is empty, check table _temp_tracelog_gap, create with Analysis - tracelog - gaps.sql")
  df$ts_psx = as.POSIXct(strptime(df$ES_Tijdstip, format="%Y-%m-%d %H:%M:%S"))
  
  qplot(ts_psx,timediff,data=df, xlab="Time", ylab="Time gap (sec)") +
    labs(title = paste0(treshold, "sec-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  
  qplot.dt(df$ts_psx,df$timediff,data=df, xlab="Time", ylab="Time gap (sec)", title = concat(treshold, "sec-",part))
  # item ts_psx niet gevonden, is veld van de dataframe df
  
  ggsave(paste0(outdir, "\\", part, "-", treshold, "sec-tracelog-gaps.png"), width=width, height=6, dpi=100)
  
  s = seq(min(df$ts_psx), max(df$ts_psx), length.out = npoints)
  df$cut_timestamp = cut(df$ts_psx, s)
  df$ts_cut = as.POSIXct(strptime(df$cut_timestamp, format="%Y-%m-%d %H:%M:%S"))
  df2 = ddply(df, .(ts_cut), 
              function(df) {c(gap_avg=mean(df$timediff), verw_avg=mean(df$verw_tijd),
                              gap_perc=mean(df$timediff_perc))})
  log("before qplot nread")
  
  qplot(ts_cut,gap_avg,data=df2, xlab="Time", ylab="Time gap avg (sec)") +
    labs(title = paste0(treshold, "sec-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", treshold, "sec-tracelog-gaps-avg.png"), width=width, height=6, dpi=100)

  qplot(ts_cut,verw_avg,data=df2, xlab="Time", ylab="Verwerkingstijd avg (sec)") +
    labs(title = paste0(treshold, "sec-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", treshold, "sec-tracelog-verwtijd-avg.png"), width=width, height=6, dpi=100)

  qplot(ts_cut,gap_perc,data=df2, xlab="Time", ylab="Time gap percentage") +
    labs(title = paste0(treshold, "sec-",part)) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", treshold, "sec-tracelog-gap-perc-avg.png"), width=width, height=6, dpi=100)
  
  log("finished")
  log()
}


main()

