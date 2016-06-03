select load_extension('c:/PCC/nico/nicoprj/lib/sqlite-functions/percentile');

drop table if exists trans_lat_aggr;

create table trans_lat_aggr as
select 2*p.latency_msec roundtrip_msec, t.transshort, 
  min(resptime) min_resptime, avg(resptime) avg_resptime, 
  percentile(resptime,95) perc95_resptime,
  max(resptime) max_resptime, count(*) cnt
from testphase p join trans t on t.iteration between p.iter_start and p.iter_end
and t.status = 0
and t.resptime > 0
-- and (p.phase <= 4 or p.phase >= 15)
group by 1,2
order by 2,1;

