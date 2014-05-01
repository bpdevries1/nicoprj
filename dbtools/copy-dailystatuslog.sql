attach 'c:/projecten/Philips/scat-an/scat-an.db' as scat;

CREATE TABLE if not exists scat.dailystatuslog (scriptname, ts_start_cet , ts_end_cet , datefrom_cet , dateuntil_cet , notes );

insert into scat.dailystatuslog (scriptname, ts_start_cet , ts_end_cet , datefrom_cet , dateuntil_cet , notes )
select (select scriptname from main.aggr_run limit 1) scriptname, s.ts_start_cet , s.ts_end_cet , s.datefrom_cet , s.dateuntil_cet , s.notes 
from main.dailystatuslog s;

detach scat;

