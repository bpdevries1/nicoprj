-- Add fields to pure path DB for better analysis.
alter table report
add iowait_time_ms float;

update report
set iowait_time_ms = round(duration__ms_ - (CPU_Sum__ms_ + Sync_Sum__ms_ + Wait_sum__ms_ + Suspension_sum__ms_));

alter table report
add wait_type varchar(20);

update report
set wait_type = 'cpu'
where wait_type is null
and cpu_sum__ms_ / duration__ms_ > 0.5;

update report
set wait_type = 'sync'
where wait_type is null
and sync_sum__ms_ / duration__ms_ > 0.5;

update report
set wait_type = 'wait'
where wait_type is null
and wait_sum__ms_ / duration__ms_ > 0.5;

update report
set wait_type = 'susp'
where wait_type is null
and suspension_sum__ms_ / duration__ms_ > 0.5;

update report
set wait_type = 'iowait'
where wait_type is null
and iowait_time_ms / duration__ms_ > 0.5;

update report
set wait_type = 'mixed'
where wait_type is null;

-- indexen op start en endtime
create index ix_rep_1 on report(start_time);
create index ix_rep_2 on report(end_time);

create table longreq as
select * from report
where agent like 'Scrittura_Prod%'
and response_time__ms_ > 5000;

-- maar 418 records hier, 418 grafieken natuurlijk wel wat veel.
create index ix_lr_1 on longreq(start_time);
create index ix_lr_2 on longreq(end_time);


