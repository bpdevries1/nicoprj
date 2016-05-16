-- 1k en 10k naast elkaar zetten met verhoudingen, voor runs van 22-1-2010
select t1.details, t1.sec_duration sec1, t10.sec_duration sec10, t10.sec_duration / t1.sec_duration factor 
from logfile l1, logfile l10, task t1, task t10
where l1.id = t1.logfile_id
and l10.id = t10.logfile_id
and l1.path like '%-1k/Scheduler.Times.log'
and l10.path like '%-10k/Scheduler.Times.log'
and t1.details = t10.details
and t1.taskname = t10.taskname
order by t10.sec_duration desc;

-- voor de runs van 29-1-2010, logs in subdir van 1k en 10k.
select t1.details, t1.sec_duration sec1, t10.sec_duration sec10, t10.sec_duration / t1.sec_duration factor
from logfile l1, logfile l10, task t1, task t10
where l1.id = t1.logfile_id
and l10.id = t10.logfile_id
and l1.path like '%-1k%Scheduler.Times.log'
and l10.path like '%-10k%Scheduler.Times.log'
and t1.details = t10.details
and t1.taskname = t10.taskname
order by t10.sec_duration desc

-- testrunprop vullen met default waarden
insert into testrunprop (testrun_id, name, value)
select t.id, 'n_input', '1000'
from testrun t
where not t.name like '%k';

insert into testrunprop (testrun_id, name, value)
select t.id, 'n_input', '1000'
from testrun t
where t.name like '%-1k';

insert into testrunprop (testrun_id, name, value)
select t.id, 'n_input', '5000'
from testrun t
where t.name like '%-5k';

insert into testrunprop (testrun_id, name, value)
select t.id, 'n_input', '10000'
from testrun t
where t.name like '%-10k';

insert into testrunprop (testrun_id, name, value)
select t.id, 'n_input', '50000'
from testrun t
where t.name like '%-50k';

-- query voor R om graphs te maken afh van size
select p.value n_input, t.details, t.sec_duration
from logfile l, task t, testrunprop p
where t.logfile_id = l.id
and l.testrun_id = p.testrun_id
and p.name = 'n_input'
and l.kind = 'schedulertimes'
order by t.details, 0+p.value

=> kan ook kruistabel met Excel maken!
