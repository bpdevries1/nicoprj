drop view scriptrun;
drop table scriptrun;
create table scriptrun (run_id integer primary key autoincrement, path, testtype, ts_utc_run, run_sec real, nactions integer);

insert into scriptrun (path, testtype, ts_utc_run, run_sec, nactions)
select j.path, case when j.path like '%-m%' then 'minimal' else 'sequential' end testtype,
       s.ts_utc_run, 0.001*sum(s.t) run_sec, count(*) nactions
from jtlfile j join httpsample s on s.jtlfile_id = j.id
where s.level = 0
group by 1,2,3
order by 3,2;

-- other ordering, so items from one testtype can be graphed as well.
create table scriptrun2 (run_id integer primary key autoincrement, path, testtype, ts_utc_run, run_sec real, nactions integer);
insert into scriptrun2 (path, testtype, ts_utc_run, run_sec, nactions)
select j.path, case when j.path like '%-m%' then 'minimal' else 'sequential' end testtype,
       s.ts_utc_run, 0.001*sum(s.t) run_sec, count(*) nactions
from jtlfile j join httpsample s on s.jtlfile_id = j.id
where s.level = 0
group by 1,2,3
order by 2,3;

drop view page;
create view page as
select r.testtype, s.ts_utc_run, s.ts_utc, s.id page_id, s.lb useraction, 0.001*s.t loadtime_sec
from httpsample s join scriptrun r on r.ts_utc_run = s.ts_utc_run
where s.level = 0
and lb like '0_-%'
order by 2, 3;

select r.testtype, r.ts_utc_run, count(*) nitems, 0.001*sum(i.by) nkbytes
from scriptrun r 
  join httpsample p on p.ts_utc_run = r.ts_utc_run
  join httpsample i on i.parent_id = p.id
group by 1,2;

create view page_stats as  
select r.testtype, r.ts_utc_run, p.useraction, count(*) nitems, 0.001*sum(i.by) nkbytes
from scriptrun r 
  join page p on p.ts_utc_run = r.ts_utc_run
  join httpsample i on i.parent_id = p.page_id
group by 1,2,3;

select testtype, useraction, min(nitems) min_nitems, max(nitems) max_nitems, min(nkbytes) min_nkbytes, max(nkbytes) max_nkbytes
from page_stats
group by 1,2
order by 1,2;

CREATE VIEW page_stats_ct as  
select r.testtype, r.ts_utc_run, r.run_id, p.useraction, i.extension, count(*) nitems, 0.001*sum(i.by) nkbytes, 0.001*sum(t) loadtime_sec
from scriptrun2 r 
  join page p on p.ts_utc_run = r.ts_utc_run
  join httpsample i on i.parent_id = p.page_id
group by 1,2,3,4,5;

drop view page_stats_ctc;
CREATE VIEW page_stats_ctc as  
select r.testtype, r.ts_utc_run, r.run_id, lower(i.extension) extension, i.maxage, count(*) nitems, 0.001*sum(i.by) nkbytes, 0.001*sum(t) loadtime_sec
from scriptrun2 r 
  join page p on p.ts_utc_run = r.ts_utc_run
  join httpsample i on i.parent_id = p.page_id
group by 1,2,3,4,5;