select count(*) geteld, play_count, path
from played p, musicfile m
where p.musicfile = m.id
group by play_count, path
having geteld <> play_count

select count(*) geteld, musicfile, datetime
from played
group by musicfile, datetime
having geteld > 1


update musicfile
set play_count = (select count(*) from played where musicfile=musicfile.id)

-- dubbele
select t1.filename, t1.path path_1, t2.path path_2
from temp_filename t1, temp_filename t2
where t1.filename = t2.filename
and t1.path < t2.path
    
-- <unknown> setten en resetten
update musicfile set artist=null, trackname=null where artist = '<unknown>';

select * from musicfile where artist is null;

select * from musicfile where artist regexp '^[0-9]{2}\. '
update musicfile set artist=null, trackname=null where artist regexp '^[0-9]{2}\. '


-- check if seconds are really different for same songs
select m1.artist, m1.trackname, m1.seconds, m1.bitrate, m1.filesize,m2.seconds, m2.bitrate, m2.filesize, m1.path, m2.path  
from musicfile m1, musicfile m2
where m1.artist = m2.artist
and m1.trackname = m2.trackname
and m1.seconds > m2.seconds + 10
order by m1.artist, m1.trackname, m1.seconds;

-- check if A, B exist, such that A.bitrate > B.bitrate and A.filesize < B.filesize
select m1.artist, m1.trackname, m1.seconds, m1.bitrate, m1.filesize,m2.seconds, m2.bitrate, m2.filesize, m1.path, m2.path  
from musicfile m1, musicfile m2
where m1.artist = m2.artist
and m1.trackname = m2.trackname
and m1.bitrate > m2.bitrate
and m1.filesize < m2.filesize
order by m1.artist, m1.trackname, m1.bitrate;

-- zelfde artist, trackname en filesize: summary
select count(*), artist, trackname, filesize
from musicfile
group by 2,3,4
having count(*) > 1
order by 2,3,4;
=> 109

-- zelfde artist, trackname en filesize: details
select m1.artist, m1.trackname, m1.seconds, m1.bitrate, m1.filesize,m2.seconds, m2.bitrate, m2.filesize, m1.path, m2.path  
from musicfile m1, musicfile m2
where m1.artist = m2.artist
and m1.trackname = m2.trackname
and m1.filesize = m2.filesize
and m1.path < m2.path
order by m1.artist, m1.trackname, m1.filesize;

-- zelfde size, andere artist etc
select m1.artist, m1.trackname, m2.artist, m2.trackname, m1.seconds, m1.bitrate, m1.filesize,m2.seconds, m2.bitrate, m2.filesize, m1.path, m2.path  
from musicfile m1, musicfile m2
where m1.filesize = m2.filesize
and m1.path < m2.path
order by m1.artist, m1.trackname, m1.filesize;

-- zelfde artist, trackname, seconds ongeveer gelijk, bitrate anders
-- order by filesizes, ascending, om niet probleem te hebben dat omhangen-naar er niet meer is.
select m1.artist, m1.trackname, m1.seconds, m1.bitrate, m1.filesize,m2.seconds, m2.bitrate, m2.filesize, m1.path, m2.path  
from musicfile m1, musicfile m2
where upper(m1.artist) = upper(m2.artist)
and upper(m1.trackname) = upper(m2.trackname)
and abs(m1.seconds - m2.seconds) <= 5
and m1.filesize >= m2.filesize
and m1.id <> m2.id
order by m1.artist, m1.trackname, m1.filesize, m2.filesize;

-- 'live' wel in path, niet in trackname, of andersom
select m1.path, m1.trackname, m1.artist
from musicfile m1
where m1.path like '%live%'
and not m1.trackname like '%live%'

-- 30-1-2010 generic table toegevoegd: vullen en f.keys omhangen.
alter table generic add musicfile_id integer;

insert into generic (gentype, musicfile_id, freq, freq_history, play_count)
select 'musicfile', id, freq, freq_history, play_count
from musicfile;

update musicfile
set generic = (select id from generic where musicfile_id = musicfile.id);

-- cross check
select * from musicfile m, generic g
where m.generic = g.id
and g.musicfile_id <> m.id

alter table generic drop musicfile_id;

update played
set generic = (select m.generic from musicfile m where played.musicfile = m.id);

update property
set generic = (select m.generic from musicfile m where property.musicfile = m.id);

-- problemen met velden verwijderen, dus even wat hacken.
CREATE TABLE  `music`.`property2` (
  `id` int(11) NOT NULL auto_increment,
  `musicfile` int(11) default NULL,
  `name` varchar(50) default NULL,
  `value` varchar(255) default NULL,
  `generic` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `musicfile__idx` (`musicfile`),
  KEY `generic__idx` (`generic`),
  CONSTRAINT `property2_ibfk_1` FOREIGN KEY (`musicfile`) REFERENCES `musicfile` (`id`) ON DELETE CASCADE,
  CONSTRAINT `property2_ibfk_2` FOREIGN KEY (`generic`) REFERENCES `generic` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2115 DEFAULT CHARSET=utf8;

insert into property2 select * from property;

ALTER TABLE property DROP FOREIGN KEY property_ibfk_1;
ALTER TABLE property DROP musicfile;
ALTER TABLE property ADD musicfile integer;


--straks bij played: proberen alleen de f.key te verwijderen en de rest door web2py te laten doen. -> ging idd goed.

-- mgroup en member (group is reserved word)
insert into mgroup (name) values ('Singles');

insert into member (mgroup, generic)
select 1, g.id
from generic g;

-- view als combi van album en generic, kijken of deze te updaten is.
create view albumgen
as select a.*, g.id g_id, g.play_count, g.freq, g.freq_history, g.gentype
from album a, generic g
where a.generic = g.id

update albumgen
set freq_history = 1
where id = 1
--> dit werkt.
