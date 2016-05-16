-- ook voor netstat --

-- bron: netstat tabel
-- doel: netstat_runtime vullen, met van elk proces de start- en eindtijd.

create index ix_netstat1 on netstat (computer, datetime, localad, localport, foreignad, foreignport);

create table times1 (computer, curr_dt);

insert into times1
select distinct computer, datetime
from netstat;

create table times (computer, curr_dt, next_dt);

insert into times 
select t1.computer, t1.curr_dt, min(t2.curr_dt)
from times1 t1, times1 t2
where t1.computer = t2.computer 
and t1.curr_dt < t2.curr_dt
group by t1.computer, t1.curr_dt;

create index ix_times1 on times (computer, curr_dt, next_dt);

create table ns_firsts (computer, dt_first, localad, localport, foreignad, foreignport);

insert into ns_firsts
select p.computer, p.datetime, p.localad, p.localport, p.foreignad, p.foreignport
from netstat p
where not exists (
  select 1
  from times t, netstat p2
  where t.curr_dt = p2.datetime
  and t.next_dt = p.datetime
  and t.computer = p.computer
  and p2.computer = p.computer
  and p2.localad = p.localad
  and p2.localport= p.localport
  and p2.foreignad = p.foreignad
  and p2.foreignport = p.foreignport
);


create index ix_ns_first1 on ns_firsts (computer, dt_first, localad, localport, foreignad, foreignport);

create table ns_first_next (computer, dt_first, dt_next, localad, localport, foreignad, foreignport);

insert into ns_first_next
select f1.computer, f1.dt_first, min(f2.dt_first), f1.localad, f1.localport, f1.foreignad, f1.foreignport
from ns_firsts f1, ns_firsts f2
where f2.dt_first > f1.dt_first
and f2.computer = f1.computer
and f2.localad = f1.localad
and f2.localport= f1.localport
and f2.foreignad = f1.foreignad
and f2.foreignport = f1.foreignport
group by f1.computer, f1.dt_first, f1.localad, f1.localport, f1.foreignad, f1.foreignport;

-- [2012-12-03 14:08:35] bovenstaande duurt vrij lang.
-- [2012-12-03 14:10:35] nog steeds bezig.
-- [2012-12-03 14:29:55] nu wel klaar, mss al veel eerder.

-- ook items zonder opvolger
insert into ns_first_next
select f1.computer, f1.dt_first, '9999-12-31', f1.localad, f1.localport, f1.foreignad, f1.foreignport
from ns_firsts f1
where not exists (
  select 1
  from ns_firsts f2 
  where f2.dt_first > f1.dt_first
  and f2.computer = f1.computer
  and f2.localad = f1.localad
  and f2.localport= f1.localport
  and f2.foreignad = f1.foreignad
  and f2.foreignport = f1.foreignport
);

create index ix_ns_first_next on ns_first_next (pname, dt_first, localad, localport, foreignad, foreignport);

create table ns_runtime (computer, dt_first, dt_last, localad, localport, foreignad, foreignport);

insert into ns_runtime
select fn.computer, fn.dt_first, max(p.datetime), fn.localad, fn.localport, fn.foreignad, fn.foreignport
from ns_first_next fn, netstat p
where p.computer = fn.computer
and p.datetime >= fn.dt_first
and p.datetime < fn.dt_next
and p.localad = fn.localad
and p.localport= fn.localport
and p.foreignad = fn.foreignad
and p.foreignport = fn.foreignport
group by 1,2,4,5,6,7;
-- duurt ook wel lang.
-- [2012-12-03 15:09:27] bezig.

