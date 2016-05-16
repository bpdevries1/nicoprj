-- [2012-12-03 10:40:19] det-regions.sql: queries om gebieden wanneer processen en connecties actief zijn, te vullen.

-- bron: pslist tabel
-- doel: ps_runtime vullen, met van elk proces de start- en eindtijd.

create index ix_pslist1 on pslist (pid, pname, computer, datetime);

create table times1 (computer, curr_dt);

insert into times1
select distinct computer, datetime
from pslist;

create table times (computer, curr_dt, next_dt);

insert into times 
select t1.computer, t1.curr_dt, min(t2.curr_dt)
from times1 t1, times1 t2
where t1.computer = t2.computer 
and t1.curr_dt < t2.curr_dt
group by t1.computer, t1.curr_dt;

create index ix_times1 on times (computer, curr_dt, next_dt);

create table ps_firsts (pid, pname, computer, dt_first);

insert into ps_firsts
select p.pid, p.pname, p.computer, p.datetime
from pslist p
-- where p.pname = 'w3wp'
where p.pname not in ('Idle', 'pauze')
and not exists (
  select 1
  from times t, pslist p2
  where t.curr_dt = p2.datetime
  and t.next_dt = p.datetime
  and t.computer = p.computer
  and p2.pid = p.pid
  and p2.pname = p.pname
  and p2.computer = p.computer
);

create index ix_ps_first1 on ps_firsts (pid, pname, computer, dt_first);

create table ps_first_next (pid, pname, computer, dt_first, dt_next);

insert into ps_first_next
select f1.pid, f1.pname, f1.computer, f1.dt_first, min(f2.dt_first)
from ps_firsts f1, ps_firsts f2
where f2.dt_first > f1.dt_first
and f2.pid = f1.pid
and f2.pname = f1.pname
and f2.computer = f1.computer
group by f1.pid, f1.pname, f1.computer, f1.dt_first;

-- ook items zonder opvolger
insert into ps_first_next
select f1.pid, f1.pname, f1.computer, f1.dt_first, '9999-12-31'
from ps_firsts f1
where not exists (
  select 1
  from ps_firsts f2 
  where f2.dt_first > f1.dt_first
  and f2.pid = f1.pid
  and f2.pname = f1.pname
  and f2.computer = f1.computer
);

create index ix_ps_first_next on ps_first_next (computer, pid, pname, dt_first);

create table ps_runtime (pid, pname, computer, dt_first, dt_last);

insert into ps_runtime
select fn.pid, fn.pname, fn.computer, fn.dt_first, max(p.datetime)
from ps_first_next fn, pslist p
where p.pid = fn.pid
and p.pname = fn.pname
and p.computer = fn.computer
and p.datetime >= fn.dt_first
and p.datetime < fn.dt_next
group by 1,2,3,4;


