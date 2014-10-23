setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
load.def.libs()

main = function() {
  testnr = commandArgs()[6]
  fase = commandArgs()[7]
  print(testnr)
  print(fase)
  graph.main(testnr, fase)
}  

main.test = function() {
  testnr = "449"
  fase = NA
  
}

graph.main = function(testnr, fase) {
  connstring = det.connstring.LT(testnr, fase)
  outdir = det.outdir(testnr)
  print(connstring)
  print(outdir)
  
  # con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=LoadTest2010T446;Trusted_Connection=yes;")
  con = odbcDriverConnect(connection=connstring)
  graph.cpu(con, outdir=outdir, "all", "2014-01-01 00:00", "2016-01-01 00:00")
  # graph.connections(con, outdir="G:\\Testware\\_Results\\Test 446\\Analyse\\tcp-conn", "part2", "2014-09-14 12:00", "2014-09-17 12:00")
  
  
}

if (FALSE) {
  # test:
  part = "all"
  start = "2014-01-01 00:00" 
  end = "2016-01-01 00:00"
  npoints = 60
  width = 12
}

graph.cpu = function(con, outdir=".", part, start, end, npoints = 60, width = 12) {
  dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
  log = make.logger(paste0(outdir, "/graph-cpu.txt"))
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
                 where 1=1
                 -- and countername = '% Processor Time'
                 and countername = 'Thread Count'
                 -- and categoryname = 'Processor'
                 -- and InstanceName = '_Total'
                 -- and categoryname = 'Processor'
                 and InstanceName = 'Zorg.ServiceHost'
                 -- and MachineName like 'ATZPRSW%'
                 and sampletimestamp/1e7 between convert(numeric(15,6), convert(datetime, '", start, "')) * 86400 + 9435477720
                                             and convert(numeric(15,6), convert(datetime, '", end, "'))   * 86400 + 9435477720
                 -- and MachineName = 'ATZPRSW010'
                 --and (machinename between 'ATZPRSWx009' and 'ATZPRSWx014'
                  -- or machinename between 'ATZPRSW021' and 'ATZPRSW026')
                 order by MachineName, CategoryName, InstanceName, CounterName, sampletimestamp")
  log(query)
  df = sqlQuery(con, query)
  log(summary(df))
  log(head(df))
  log(tail(df))
  df$ts_psx = as.POSIXct(strptime(df$ts_cet, format="%Y-%m-%d %H:%M:%S"))
  df_aggr = calc.df.aggr.ts(df, "ts_psx", "ComputedValue", 60, c("MachineName", "CategoryName", "InstanceName", "CounterName"), mean)
  
  # eerst even aantal waarden 'gewoon'. sqldf snapt geen data.frames met punten in de naam.
  # dfa.act = sqldf("select * from df_aggr where CounterName in ('User Connections', 'Connections Established')")
  dfa.act = df_aggr
  
  g = guide_legend("Counter", ncol = 4)
  qplot(ts_psx, ComputedValue, data=dfa.act, colour=CounterName, shape=CounterName, xlab="Time", ylab="Counter") +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter") +
    facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "CPU") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", "CPU-facet.png"), width=10, height=10, dpi=100)
  
  qplot(ts_psx, ComputedValue, data=dfa.act, colour=MachineName, shape=MachineName, xlab="Time", ylab="Counter") +
    scale_shape_manual(name="Counter", values=rep(1:25,10)) +
    scale_colour_discrete(name="Counter") +
    # facet_grid(MachineName ~ ., scales='free_y') +
    labs(title = "Zorg thread count") +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M"))
  ggsave(paste0(outdir, "\\", part, "-", "Zorg-threadcount-colour.png"), width=10, height=7, dpi=100)
  
  
  log()
}

main()
