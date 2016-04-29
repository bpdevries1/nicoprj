IF OBJECT_ID('dbo.aggr_tdc') IS NOT NULL BEGIN DROP TABLE dbo.aggr_tdc END

create table dbo.aggr_tdc (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[RunId] [int] NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[DatabaseName] [varchar](255) NOT NULL,
	[ChannelName] [varchar](255) NOT NULL,
	nelts_min bigint,
	nelts_max bigint,
	nelts_avg bigint,
	nelts_start bigint,
	nelts_end bigint
)

SELECT RunId, ServerName, DatabaseName, ChannelName, min(collectTimeStamp) ts_start, max(collectTimestamp) ts_end
INTO #startend
FROM [dbo].[ToeslagenDataCollector]
group by RunId, ServerName, DatabaseName, ChannelName

select tdc.runid, tdc.servername, tdc.DatabaseName, tdc.ChannelName, tdc.NumberOfElements nelts_start
into #startcount
from [dbo].[ToeslagenDataCollector] tdc join #startend se on tdc.CollectTimeStamp = se.ts_start and tdc.runid = se.runid
    and tdc.servername = se.servername and tdc.DatabaseName = se.databasename and tdc.channelname = se.channelname

select tdc.runid, tdc.servername, tdc.DatabaseName, tdc.ChannelName, tdc.NumberOfElements nelts_end
into #endcount
from [dbo].[ToeslagenDataCollector] tdc join #startend se on tdc.CollectTimeStamp = se.ts_end and tdc.runid = se.runid
    and tdc.servername = se.servername and tdc.DatabaseName = se.databasename and tdc.channelname = se.channelname

select tdc.RunId, tdc.ServerName, tdc.DatabaseName, tdc.ChannelName
  ,min(tdc.NumberOfElements) nelts_min
  ,max(tdc.NumberOfElements) nelts_max
  ,cast(round(avg(tdc.NumberOfElements), 0) as bigint) nelt_avg
into #stats
from [dbo].[ToeslagenDataCollector] tdc
group by tdc.RunId, tdc.ServerName, tdc.DatabaseName, tdc.ChannelName

delete from dbo.aggr_tdc

insert into dbo.aggr_tdc
select s.*, sc.nelts_start, nelts_end
from #stats s
join #startcount sc on sc.runid = s.runid and sc.servername = s.servername and sc.databasename = s.databasename and sc.channelname = s.channelname
join #endcount ec on ec.runid = s.runid and ec.servername = s.servername and ec.databasename = s.databasename and ec.channelname = s.channelname
	
drop table #startend
drop table #startcount
drop table #endcount
drop table #stats
