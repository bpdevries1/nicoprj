drop table if exists factor_fp_ttip;
create table factor_fp_ttip (page_seq int, fct_fp real, fct_ttip real);
insert into factor_fp_ttip values (1, 1.0, 0.0);
insert into factor_fp_ttip values (2, 1.0, 0.0);
insert into factor_fp_ttip values (3, 0.5, 0.5);
insert into factor_fp_ttip values (4, 0.5, 0.5);
insert into factor_fp_ttip values (5, 0.5, 0.5);
insert into factor_fp_ttip values (6, 0.5, 0.5);
insert into factor_fp_ttip values (7, 0.5, 0.5);

-- eerst aggr_page2, waarbij page_seq bij de key hoort. Nu niet altijd, omdat pagetype anders kan zijn.
drop view if exists aggr_page2;
create view aggr_page2 as
select date_cet, scriptname, page_seq, avg(avg_time_sec) avg_time_sec, avg(avg_ttip_sec) avg_ttip_sec
from aggr_page
group by 1,2,3;

drop view if exists pageload_avg ;
create view pageload_avg as
select p.scriptname, p.date_cet, round((sum(p.avg_time_sec * f.fct_fp) + sum(p.avg_ttip_sec * f.fct_ttip)) / r.npages,3) pageload_avg
from aggr_run r 
  join aggr_page2 p on p.scriptname = r.scriptname and p.date_cet = r.date_cet
  join factor_fp_ttip f on f.page_seq = p.page_seq
group by 1,2;

drop view if exists pageload_all3;
create view pageload_all3 as
select p.scriptname, p.date_cet, avg(p.avg_time_sec) fullpage, avg(p.avg_ttip_sec) ttip,
       pa.pageload_avg
from aggr_page2 p
  join pageload_avg pa on pa.scriptname = p.scriptname and pa.date_cet = p.date_cet
group by 1,2,5;

