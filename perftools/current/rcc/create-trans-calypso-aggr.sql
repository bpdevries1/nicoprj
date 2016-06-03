select load_extension('c:/PCC/nico/nicoprj/lib/sqlite-functions/percentile');

drop table if exists trans_aggr;

create table trans_aggr as
select t.transname, substr(user, -10) location,
  min(resptime) min_resptime, avg(resptime) avg_resptime, 
  percentile(resptime,95) perc95_resptime,
  max(resptime) max_resptime, count(*) cnt
from trans t 
where t.status = 0
and t.resptime > 0
group by 1,2
order by 1,2;


