-- doel: id's aan track toevoegen, en hierna tracks hernoemen, zowel in db als op filesystem.
-- PK achteraf toevoegen lijkt me niet te kunnen, dus maak nieuwe tabel.
-- eerst backup

-- huidige db:
CREATE TABLE track (path, seconds, frames, nright, nwrong);
CREATE TABLE track_test (path, ts, start_sec, stop_sec, result);
CREATE TABLE track_value (path, ts, value);

create table track2 (path, seconds, frames, nright, nwrong);
insert into track2 select * from track;

drop table track;

alter table track add year; -- gaat goed.
CREATE TABLE track (id integer primary key autoincrement, path, seconds, frames, nright, nwrong, path2, year);

insert into track (path, seconds, frames, nright, nwrong, path2)
select path, seconds, frames, nright, nwrong, path
from track2;

drop table track2;
drop table track_value; -- gebruik ik toch niet nu.

CREATE TABLE track_test2 (path, ts, start_sec, stop_sec, result);
insert into track_test2 select * from track_test;

drop table track_test;

create table testgroup (id integer primary key autoincrement, name);
create table testgroup_item (testgroup_id, track_id);
create table session (id integer primary key autoincrement, testgroup_id, ts_start, ts_end); 
-- evt ook stats in session, maar can calculated worden.

CREATE TABLE track_test (session_id, track_id, ts, start_sec, stop_sec, result);

insert into track_test (track_id, ts, start_sec, stop_sec, result)
select tr.id, tst.ts, tst.start_sec, tst.stop_sec, tst.result
from track tr, track_test2 tst
where tr.path = tst.path;

-- ook nr in lijst toevoegen.
alter table track add positie;

-- Ok, structuur weer goed:
CREATE TABLE session (id integer primary key autoincrement, testgroup_id, ts_start, ts_end);
CREATE TABLE testgroup (id integer primary key autoincrement, name);
CREATE TABLE testgroup_item (testgroup_id, track_id);
CREATE TABLE track (id integer primary key autoincrement, path, seconds, frames, nright, nwrong, path2, year, positie);
CREATE TABLE track_test (session_id, track_id, ts, start_sec, stop_sec, result);
CREATE TABLE track_test2 (path, ts, start_sec, stop_sec, result);


