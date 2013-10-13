-- two queries needed.

drop table if exists page_td1;

create table page_td1 as
select p.scriptrun_id scriptrun_id, p.id page_id, 1*p.page_seq page_seq, p.ts_cet ts_cet,
  round(0.001*p.delta_user_msec,3) page_sec, round(min(0.001*i.start_msec),3) start_sec_td,
  count(*) nelt_td, round(sum(0.001*i.element_delta),3) sec_elt_td,
  round(0.001 * p.delta_user_msec - min(0.001*i.start_msec),3) sec_overhead_max
from page p join pageitem i on i.page_id = p.id
where p.ts_cet > '2013-09-30'
and i.topdomain = 'tradedoubler.com'
group by 1,2,3,4,5;

create index ix_page_td1 on page_td1 (page_id);

drop table if exists page_td2;

create table page_td2 as
select t1.*, 
  round(sum(0.001*i.element_delta),3) sec_elt_after_td,
  round(max(0, sec_overhead_max - sum(0.001*i.element_delta)),3) sec_no_network_after_td_min 
from page_td1 t1
  join pageitem i on i.page_id = t1.page_id
where 0.001*i.start_msec >= t1.start_sec_td
group by t1.page_id;

