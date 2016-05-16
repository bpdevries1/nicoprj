insert into testrunprop (testrun_id, name, value) 
select id, 'n_input', 1000
from testrun
where not exists (
  select 1
  from testrunprop t2
  where t2.testrun_id = testrun.id
);

-- 3-5-2010 job 7 zorgt voor vroege starttijd, maar met alleen check op threadnr ben je er niet, want gaat om file-record.
update testrun
set dt_start = (
  select min(dt_start)
  from task t, logfile f
  where f.testrun_id = testrun.id
  and t.logfile_id = f.id
  and t.taskname = 'file'
  -- and t.threadnr <> 7
)
where dt_start is null;

update testrun
set dt_end = (
  select max(dt_end)
  from task t, logfile f
  where f.testrun_id = testrun.id
  and t.logfile_id = f.id
  and t.taskname = 'file'
  -- and t.threadnr <> 7
)
where dt_end is null;
