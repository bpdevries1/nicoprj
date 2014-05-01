-- CQ5 physical location script
-- run after AllScripts.aggr_connect_time has been updated.
-- possibly run with dbscript.tcl

-- tables used, so have, create or attach.
-- cn_curr_domains -> done
-- cq5_curr_domains -> done
-- phys_loc -> done
-- meta -> done
-- min_min_conn -> done.

attach 'c:/projecten/Philips/KNDL/slotmeta-domains.db' as meta;

drop view if exists min_min_conn;
create view min_min_conn as
select a.date_cet, a.ip_address, a.topdomain, a.domain, min(a.min_conn_msec) min_min_msec
from aggr_connect_time a
where a.date_cet >= '2014-02-16'
and a.ip_address <> '0.0.0.0'
group by 1,2,3,4;

drop table if exists cn_curr_domains;
create table cn_curr_domains as
select distinct s.scriptname, s.keyvalue domain, s.date_cet
from aggr_sub s 
  join meta.slot_download md on s.scriptname = md.dirname
  join meta.slot_meta mt on md.slot_id = mt.slot_id
where s.keytype = 'domain'
and mt.agent_name like '%Beijing%'
and s.date_cet >= '2014-02-16';

drop table if exists cq5_curr_domains;
create table cq5_curr_domains as
select distinct s.scriptname, s.keyvalue domain, s.date_cet
from aggr_sub s 
where s.keytype = 'domain'
and (s.scriptname like 'CBF-US%' or s.scriptname like 'CBF-UK%' or s.scriptname like 'CBF-DE%')
and s.date_cet >= '2014-02-16';

drop table if exists phys_loc;
create table phys_loc as
select mc.date_cet, mc.ip_address, mc.topdomain, mc.domain, mc.min_min_msec, a.scriptname, mt.agent_name
from min_min_conn mc 
  join aggr_connect_time a on a.date_cet = mc.date_cet and a.ip_address = mc.ip_address and a.topdomain = mc.topdomain and a.domain = mc.domain
  join meta.slot_download md on a.scriptname = md.dirname
  join meta.slot_meta mt on md.slot_id = mt.slot_id
where mc.min_min_msec = a.min_conn_msec;

drop table if exists cq5_domain;
create table cq5_domain (cn_domain, cq5_domain, domain, cn_curr int, cq5_curr int, inscope int, notes, nearest_location, conn_min, phys_loc, loc_code);

insert into cq5_domain (cn_domain, cq5_domain, nearest_location, conn_min)
select cn.domain cn_domain, cq5.domain cq5_domain, pa.agent_name, min(pa.min_min_msec) min_min_msec
from cn_curr_domains cn
  join phys_loc pc on pc.date_cet = cn.date_cet and pc.domain = cn.domain
  join phys_loc pa on pc.ip_address = pa.ip_address and pc.date_cet = pa.date_cet
  left outer join cq5_curr_domains cq5 on cn.domain = cq5.domain
where pc.agent_name like '%Beijing%'
group by 1,2,3;

insert into cq5_domain (cq5_domain)
select distinct cq5.domain
from cq5_curr_domains cq5
where not domain in (
  select distinct domain
  from cn_curr_domains
);

update cq5_domain
set cn_curr = 1, domain = cn_domain
where cn_domain is not null;

update cq5_domain
set cn_curr = 0
where cn_domain is null;

update cq5_domain
set cq5_curr = 1, domain = cq5_domain
where cq5_domain is not null;

update cq5_domain
set cq5_curr = 0
where cq5_domain is null;

-- set phys_loc and loc_code.
update cq5_domain
set phys_loc = nearest_location
where conn_min < 10;

update cq5_domain
set loc_code = 'cn'
where conn_min < 10
and (nearest_location like '%Beijing%' or nearest_location like '%Mainland China%');

-- determine if 10 and 30 msec are good tresholds.
update cq5_domain
set loc_code = 'near'
where loc_code is null
and conn_min between 10 and 30
and (nearest_location like '%Beijing%' or nearest_location like '%Mainland China%');

update cq5_domain
set loc_code = 'far'
where loc_code is null
and conn_min > 30;

