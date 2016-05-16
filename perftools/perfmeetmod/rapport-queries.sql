Verhouding tussen hele scheduler en extractxml

select tr.name, s.sec_duration scheduler, e.sec_duration extractxml, lf.path
from task s, task e, testrun tr, logfile lf
where s.logfile_id = e.logfile_id
and s.taskname = 'file'
and e.taskname = 'extractxml'
and s.logfile_id = lf.id
and lf.testrun_id = tr.id

select s.dt_start s_start, s.dt_end s_end, s.sec_duration scheduler, 
       e.dt_start e_start, e.dt_end e_end, e.sec_duration extractxml, 
       tr.name, lf.path
from task s, task e, testrun tr, logfile lf
where s.logfile_id = e.logfile_id
and s.taskname = 'file'
and e.taskname = 'extractxml'
and s.logfile_id = lf.id
and lf.testrun_id = tr.id
order by s.dt_start;

-- test n concurrent voor scheduler
select s.dt_start s_start, s.dt_end s_end, s.sec_duration scheduler, count(*)
from task s, task sc, logfile l, logfile lc
where s.logfile_id = l.id
and sc.logfile_id = lc.id
and l.testrun_id = lc.testrun_id
and s.taskname = 'file'
and sc.taskname = 'file'
and s.threadname = 'scheduler'
and sc.threadname = 'scheduler'
and sc.dt_start < s.dt_end
and sc.dt_end > s.dt_start
group by 1,2,3
order by 1;

-- alleen beginmoment, anders wel max 7
select s.dt_start s_start, s.dt_end s_end, s.sec_duration scheduler, count(*)
from task s, task sc, logfile l, logfile lc
where s.logfile_id = l.id
and sc.logfile_id = lc.id
and l.testrun_id = lc.testrun_id
and s.taskname = 'file'
and sc.taskname = 'file'
and s.threadname = 'scheduler'
and sc.threadname = 'scheduler'
and sc.dt_start <= s.dt_start
and sc.dt_end >= s.dt_start
group by 1,2,3
order by 1;



