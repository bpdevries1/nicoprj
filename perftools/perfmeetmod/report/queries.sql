-- ovz per testrun
SELECT r.name, r.dt_start, r.dt_end, 
  time_to_sec(timediff(dt_end,dt_start)) sec_looptijd, 
  3600 * tp.value / (time_to_sec(timediff(dt_end,dt_start))) n_per_uur, 
  time_to_sec(timediff(dt_end,dt_start))/tp.value sec_per_stuk
FROM testrun r, testrunprop tp
where r.id = tp.testrun_id
and tp.name = 'n_input'
order by r.name;

-- per logfile in de testrun
select r.name testrun, f.path, t.threadname name, t.threadnr, t.taskname, tp.value aantal, t.dt_start, t.dt_end, sec_duration,
  3600 * tp.value / (time_to_sec(timediff(t.dt_end,t.dt_start))) n_per_uur, 
  time_to_sec(timediff(t.dt_end,t.dt_start))/tp.value sec_per_stuk
from testrun r, testrunprop tp, logfile f, task t
where r.id = tp.testrun_id
and r.id = f.testrun_id
and f.id = t.logfile_id
and tp.name = 'n_input'
and t.taskname = 'file'
order by r.name, f.path, t.threadname;

-- per task soort, hierna per testrun.
select r.name testrun, f.path, t.threadname name, t.threadnr, t.taskname, tp.value aantal, t.dt_start, t.dt_end, sec_duration,
  3600 * tp.value / (time_to_sec(timediff(t.dt_end,t.dt_start))) n_per_uur, 
  time_to_sec(timediff(t.dt_end,t.dt_start))/tp.value sec_per_stuk
from testrun r, testrunprop tp, logfile f, task t
where r.id = tp.testrun_id
and r.id = f.testrun_id
and f.id = t.logfile_id
and tp.name = 'n_input'
and t.taskname = 'file'
order by t.threadname, t.dt_start;

-- 6-5-2010 NdV met aantallen per logfile bepaald.
-- per logfile in de testrun
select r.name testrun, f.path, t.threadname name, t.threadnr, t.taskname, f.aantal aantal, t.dt_start, t.dt_end, sec_duration,
  3600 * f.aantal / (time_to_sec(timediff(t.dt_end,t.dt_start))) n_per_uur, 
  time_to_sec(timediff(t.dt_end,t.dt_start))/f.aantal sec_per_stuk
from testrun r, logfile f, task t
where r.id = f.testrun_id
and f.id = t.logfile_id
and t.taskname = 'file'
and f.aantal is not null
order by r.name, f.path, t.threadname;

-- per task soort, hierna per testrun.
select r.name testrun, f.path, t.threadname name, t.threadnr, t.taskname, f.aantal aantal, t.dt_start, t.dt_end, sec_duration,
  3600 * f.aantal / (time_to_sec(timediff(t.dt_end,t.dt_start))) n_per_uur, 
  time_to_sec(timediff(t.dt_end,t.dt_start))/f.aantal sec_per_stuk
from testrun r, logfile f, task t
where r.id = f.testrun_id
and f.id = t.logfile_id
and t.taskname = 'file'
and f.aantal is not null
order by t.threadname, t.dt_start;

