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


graph.dc.counts = function(dfaggr, outdir, runid, part, width, log) {
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", 
           filename=det.graphname(outdir, runid, part, "channels-nmessages"))
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", facets = DatabaseName~.,
           filename=det.graphname(outdir, runid, part, "channels-nmessages-facet-db"))
  qplot.dt(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", facets = ChannelName~.,
           filename=det.graphname(outdir, runid, part, "channels-nmessages-facet-channel"))
}

graph.dc.counts.ff = function(dfaggr, outdir, runid, part, width, log) {
  # note mss filename.prefix eerst bepalen.
  dfdb = qplot.dt.ff(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", file.facets = "DatabaseName",
           filename.prefix=det.graphname.ff(outdir, runid, part, "channels-nmessages-ff-db-"))
  #log("after qplot.dt.ff")
  #log.df(log, df, "dfdb, result of qplot.dt.ff")
  dfdb
}


graph.dc.speed = function(dfaggr, outdir, runid, part, width, log) {
  # g = guide_legend("Channel", ncol = 2)
  
  dfaggr_nread = na.omit(dfaggr)
  log.df(log, dfaggr_nread, "dfaggr with nread is not null")
  
  qplot.dt(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, ylab="read/sec",
           filename=det.graphname(outdir, runid, part, "channels-read"))
  
  qplot.dt(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, ylab="read/sec", facets=DatabaseName ~ .,
           filename=det.graphname(outdir, runid, part, "channels-read-facet-db"))
  
  qplot.dt(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, ylab="read/sec", facets=ChannelName ~ .,
           filename=det.graphname(outdir, runid, part, "channels-read-facet-channel"))
  
  df.ar = sqldf("select ts_cut, ChannelName, nread nps, 'nread' direction
                 from dfaggr_nread
                 union
                 select ts_cut, ChannelName, nadded nps, 'nadded' direction
                 from dfaggr_nread")
  qplot.dt(ts_cut,nps,data=df.ar,colour=direction, ylab="#msg/sec", facets=ChannelName~.,
           filename=det.graphname(outdir, runid, part, "channels-read-added-facet-channel"))
}

graph.dc.speed.ff = function(dfaggr, outdir, runid, part, width, log) {
  # g = guide_legend("Channel", ncol = 2)
  
  dfaggr_nread = na.omit(dfaggr)
  log.df(log, dfaggr_nread, "dfaggr with nread is not null")
  
  dfdb = qplot.dt.ff(ts_cut,nread,data=dfaggr_nread,colour=ChannelName, ylab="read/sec", 
                     file.facets = "DatabaseName",
           filename.prefix=det.graphname.ff(outdir, runid, part, "channels-read-ff-db-"))

  dfdb
}

graph.dc.speed.ff2 = function(dfaggr, outdir, runid, part, width, log) {
  # g = guide_legend("Channel", ncol = 2)
  
  dfaggr_nread = na.omit(dfaggr)
  df.ar = sqldf("select ts_cut, DatabaseName, ChannelName, nread nps, 'nread' direction
                 from dfaggr_nread
                 union
                 select ts_cut, DatabaseName, ChannelName, nadded nps, 'nadded' direction
                 from dfaggr_nread")
  
  dfdb = qplot.dt.ff(ts_cut,nps,data=df.ar,colour=direction, ylab="#msg/sec", facets=ChannelName~.,
                     file.facets = "DatabaseName",
                     filename.prefix=det.graphname.ff(outdir, runid, part, "channels-read-added-ff-db-"))
  dfdb
}


# @note meting-channels zijn niet boeiend (toch?)
channel.query.diff = function(ndiff, runid, start, end) {
  concat("WITH dbch (runid, servername, databasename, channelname, mincount, maxcount, maxnread) as (
      select runid, servername, databasename, channelname, min(numberofelements), max(numberofelements)
         ,max(NumberOfMessagesReadSinceLastTime)
      from dbo.ToeslagenDataCollector
      where CollectTimeStamp between '", start, "' and '", end, "'
      and runid = ", runid, "
      and channelname not like '%Meting%'
      group by runid, servername, databasename, channelname
    ),
    dbchsel (runid, servername, databasename, channelname, mincount, maxcount, maxnread) as (
      select * from dbch
      where (abs(mincount-maxcount) > ", ndiff, " )
             -- or maxnread > 0) -- @todo later nog eens kijken, nu te veel false positives.
    )
    -- tdc.DatabaseName + ' ' + tdc.ChannelName ChannelName
    SELECT tdc.ServerName, tdc.DatabaseName, tdc.ChannelName, tdc.CollectTimeStamp ts, tdc.NumberOfMessagesReadSinceLastTime nread
          ,tdc.NumberOfMessagesAddedSinceLastTime nadded, tdc.NumberOfElements nelts
    FROM dbo.ToeslagenDataCollector tdc
      join dbchsel s on tdc.servername = s.servername and tdc.databasename = s.databasename and tdc.channelname = s.channelname
    where 1=1 
    and tdc.CollectTimeStamp between '", start, "' and '", end, "'
    and tdc.RunId = ", runid, "
    order by tdc.collecttimestamp")
}

channel.query.chgroup = function(part, runid, start, end) {
  concat("SELECT ServerName,
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

add.channel.group = function(group, sql.part) {
  channel.group.defs[[group]] <<- sql.part
}

det.channel.group = function(group) {
  channel.group.defs[[group]]
}

det.graphname = function(outdir, runid, part, title) {
  concat(outdir, "\\", runid, "-", part, "-", title, ".png")
}

det.graphname.ff = function(outdir, runid, part, title) {
  concat(outdir, "\\", runid, "-", part, "-", title)
}


det.df.tablename = function(runid, chgroup, type="count") {
  concat("tdc_summary_", runid, "_", chgroup, "_", type)
}
