setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
load.def.libs()

define.channel.groups = function() {
  channel.group.defs <<- NULL
  add.channel.group("Huur-KOT-In",     "
      and (ChannelName like '%Huur%' or ChannelName like '%KinderOpvang%')
      and Channelname like '%ChannelIn%'")
  add.channel.group("Huur-KOT-Zorg-BT-In",     "
      and (ChannelName like '%Huur%' or ChannelName like '%KinderOpvang%' or ChannelName like '%Zorg%' or ChannelName like '%Betalen%')
      and Channelname like '%ChannelIn%'")
  add.channel.group("ChannelInZorg",     "
      and Channelname = 'ChannelInZorg'")
  add.channel.group("ChannelOutTsb",     "
      and Channelname = 'ChannelOutTsb'")
  add.channel.group("Zorg-BT-In",     "
      and (ChannelName like '%Zorg%' or ChannelName like '%Betalen%')
      and Channelname like '%ChannelIn%'")  
  add.channel.group("Huur-KOT-Zorg-BT-Awir-In",     "
      and (ChannelName like '%Huur%' or ChannelName like '%KinderOpvang%' or ChannelName like '%Zorg%' or ChannelName like '%Betalen%' or ChannelName like '%Awir%')
      and Channelname like '%ChannelIn%'")
  add.channel.group("Zorg-BT-Awir",     "
      and ChannelName in ('ChannelInFormeelBeschikkenZorgQueue', 'ChannelInZorg', 'ChannelInBetalenToeslagen', 'ChannelInAwir', 'ChannelOutTsb')")

  add.channel.group("SC-In",     "
      and (ChannelName like '%ParkeerPlaatsDocOne%' or ChannelName like '%TodoLijstBeschikkingNietVerstuurd%')
      and Channelname like '%ChannelIn%'")
  
#  -- Indexeren:
#  -- and ChannelName in ('ChannelInAwir', 'ChannelInHuur', 'ChannelInZorg', 'ChannelInKinderopvang', 'ChannelInKindgebondenBudget', 'ChannelInFrsProcesVerwerkenMelding', 'ChannelInWerkvoorraadIndexeringItem', 'ChannelOutAwir')
#  -- and ChannelName not in ('ChannelInFrsProcesVerwerkenMelding', 'ChannelInWerkvoorraadIndexeringItem')
# -- HL en VD 1:
#  -- and (ChannelName in ('ChannelInAwir', 'ChannelInHuur', 'ChannelInZorg', 'ChannelInKinderopvang', 'ChannelInKindgebondenBudget', 'ChannelInFrsProcesVerwerkenMelding', 'ChannelInWerkvoorraadIndexeringItem')
#            --   or ChannelName like '%FormeelBeschikken%'
#            --   or ChannelName like '%Herberekenen%'
#           --   or ChannelName like '%VrijgaveDraagkracht%'
#            --   or ChannelName like '%WFMStarterSet%'
#            --   or ChannelName like '%Worklistitem%'
#            -- )

}

main = function() {
  options(warn=-1)
  define.channel.groups()
  testnr = commandArgs()[6]
  runid = commandArgs()[7]
  channel.group = commandArgs()[8]
  write(concat("testnr: ", testnr, ", runid:", runid, ", channels: ", channel.group), "")
  #print(testnr)
  #print(runid)
  #print(channel.group)
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  #print(connstring)
  #print(outdir)
  con = odbcDriverConnect(connection=connstring)
  graph.dc(con, outdir, channel.group, runid, "2014-01-01 00:00", "2016-01-01 00:00")
  # graph.dc(con, outdir, channel.group, runid, "2014-10-11 19:00", "2014-10-16 09:00")
  # graph.queuecount(con, outdir=outdir, testnr, "2014-01-01 00:00", "2016-01-01 00:00")
  # graph.dc1(con, outdir=outdir, "ChannelInHuur", runid)
  odbcClose(con)
  #w = warnings()
  #last.warning = NULL
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
}

graph.dc = function(con, outdir=".", part, runid, start, end, npoints = 60, width = 12) {
  dir.create(outdir, recursive=TRUE)
  log = make.logger(paste0(outdir, "/analyse-log.txt"))
  log("Start of analysis")
  # @todo named query parameters.
  diff = regmatches(part, regexec("^diff(\\d+)$", part))[[1]][2]
  if (is.na(diff)) {
    query = channel.query.part(part, runid, start, end)
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

channel.query.part = function(part, runid, start, end) {
  concat("SELECT 
    [DatabaseName]
    ,[ChannelName]
    ,[CollectTimeStamp] ts
    ,[NumberOfMessagesReadSinceLastTime] nread
    ,[NumberOfMessagesAddedSinceLastTime] nadded
    ,[NumberOfElements] nelts
    FROM [dbo].[ToeslagenDataCollector]
    where 1=1 ", det.channel.group(part), "
    and [CollectTimeStamp] between '", start, "' and '", end, "'
    and RunId = ", runid, "
    -- and [NumberOfElements] > 0
    -- soms grote outliers
    -- and [NumberOfMessagesReadSinceLastTime] < 1000
    order by collecttimestamp")
}

channel.query.diff = function(ndiff, runid, start, end) {
  concat("WITH dbch (runid, servername, databasename, channelname, mincount, maxcount) as (
      select runid, servername, databasename, channelname, min(numberofelements), max(numberofelements)
      from dbo.ToeslagenDataCollector
      where CollectTimeStamp between '", start, "' and '", end, "'
      and runid = ", runid, "
      group by runid, servername, databasename, channelname
    ),
    dbchsel (runid, servername, databasename, channelname, mincount, maxcount) as (
      select * from dbch
      where abs(mincount-maxcount) > ", ndiff, " 
    )
    SELECT tdc.DatabaseName, tdc.ChannelName, tdc.CollectTimeStamp ts, tdc.NumberOfMessagesReadSinceLastTime nread
          ,tdc.NumberOfMessagesAddedSinceLastTime nadded, tdc.NumberOfElements nelts
    FROM dbo.ToeslagenDataCollector tdc
      join dbchsel s on tdc.databasename = s.databasename and tdc.channelname = s.channelname
    where 1=1 
    and tdc.CollectTimeStamp between '", start, "' and '", end, "'
    and tdc.RunId = ", runid, "
    -- and tdc.NumberOfElements > 0
    -- soms grote outliers
    -- and [NumberOfMessagesReadSinceLastTime] < 1000
    order by tdc.collecttimestamp")
}

det.graphname = function(outdir, runid, part, title) {
  concat(outdir, "\\", runid, "-", part, "-", title, ".png")
}

graph.dc.counts = function(dfaggr, outdir, runid, part, width, log) {
  g = guide_legend("Channel", ncol = 2)
  
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", 
           filename=det.graphname(outdir, runid, part, "channels-nmessages"))

  if (FALSE) {
    qplot(ts_cut,nelts,data=dfaggr,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="#messages") +
      scale_shape_manual(name="Channel", values=rep(1:25,10)) +
      scale_colour_discrete(name="Channel") +
      facet_grid(DatabaseName ~ ., scales='free_y', labeller=label_wrap_gen3(width=25)) +
      # labs(title = part) +
      theme(legend.position="bottom") +
      theme(legend.direction="horizontal") +
      guides(colour = g, shape = g) +
      scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
      scale_y_continuous(labels = comma)
    
    height = det.height(facets = dfaggr$DatabaseName, colours=dfaggr$ChannelName)
    ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-nmessages-facet-db.png"), width=12, height=height, dpi=100)
  }
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", facets = DatabaseName~.,
           filename=det.graphname(outdir, runid, part, "channels-nmessages-facet-db"))
  
  
  qplot(ts_cut,nelts,data=dfaggr,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="#messages") +
    scale_shape_manual(name="Channel", values=rep(1:25,10)) +
    scale_colour_discrete(name="Channel") +
    facet_grid(ChannelName ~ ., scales='free_y', labeller=label_wrap_gen3(width=25)) +
    # labs(title = part) +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_y_continuous(labels = comma)
  
  height = det.height(facets=dfaggr$ChannelName, colours=dfaggr$ChannelName)  
  ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-nmessages-facet-channel.png"), width=12, height=height, dpi=100)
  
}


graph.dc.speed = function(dfaggr, outdir, runid, part, width, log) {
  # g = guide_legend("Channel", ncol = 4)
  g = guide_legend("Channel", ncol = 2)
  
  # @todo copy/paste code opschonen.
  
  # dfaggr_nread = sqldf("select * from dfaggr where nread is not null")
  # dfaggr_nread = subset(dfaggr, !is.na(nread))
  dfaggr_nread = na.omit(dfaggr)
  log.df(log, dfaggr_nread, "dfaggr with nread is not null")
  
  qplot(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="read/sec") +
    scale_shape_manual(name="Channel", values=rep(1:25,10)) +
    scale_colour_discrete(name="Channel") +
    # labs(title = part) +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_y_continuous(labels = comma)
  
  log("before ggsave nread")
  height = det.height(colours=dfaggr_nread$ChannelName)
  ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-read.png"), width=width, height=height, dpi=100)
  
  log("before qplot nread facet")
  qplot(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="read/sec") +
    scale_shape_manual(name="Channel", values=rep(1:25,10)) +
    scale_colour_discrete(name="Channel") +
    facet_grid(DatabaseName ~ ., scales='free_y', labeller=label_wrap_gen3(width=25)) +
    # labs(title = part) +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_y_continuous(labels = comma)
  
  log("before ggsave nread facet")
  height = det.height(facets=dfaggr_nread$DatabaseName, colours=dfaggr_nread$ChannelName)
  ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-read-facet-db.png"), width=width, height=height, dpi=100)
  
  log("before qplot nread facet")
  qplot(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, shape=ChannelName, xlab="Time", ylab="read/sec") +
    scale_shape_manual(name="Channel", values=rep(1:25,10)) +
    scale_colour_discrete(name="Channel") +
    facet_grid(ChannelName ~ ., scales='free_y', labeller=label_wrap_gen3(width=25)) +
    # labs(title = part) +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_y_continuous(labels = comma)
  
  height = det.height(facets=dfaggr_nread$ChannelName, colours=dfaggr_nread$ChannelName)
  ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-read-facet-channel.png"), width=width, height=height, dpi=100)

  # graph met facet per channel (dus niet te veel) en zowel nadded als nread plot
  df.ar = sqldf("select ts_cut, ChannelName, nread nps, 'nread' direction
                 from dfaggr_nread
                 union
                 select ts_cut, ChannelName, nadded nps, 'nadded' direction
                 from dfaggr_nread")
  
  g = guide_legend("direction", ncol = 2)
  qplot(ts_cut,nps,data=df.ar,colour=direction, shape=direction, xlab="Time", ylab="#msg/sec") +
    scale_shape_manual(name="direction", values=rep(1:25,10)) +
    scale_colour_discrete(name="direction") +
    facet_grid(ChannelName ~ ., scales='free_y', labeller=label_wrap_gen3(width=25)) +
    # labs(title = part) +
    theme(legend.position="bottom") +
    theme(legend.direction="horizontal") +
    guides(colour = g, shape = g) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    scale_y_continuous(labels = comma)
  
  height = det.height.log(facets=df.ar$ChannelName, colours=df.ar$direction, log=log)
  ggsave(paste0(outdir, "\\", runid, "-", part, "-channels-read-added-facet-channel.png"), width=12, height=height, dpi=100)
  
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

add.channel.group = function(group, sql.part) {
  channel.group.defs[[group]] <<- sql.part
}

det.channel.group = function(group) {
  channel.group.defs[[group]]
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
