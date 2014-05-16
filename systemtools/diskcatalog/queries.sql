DDL
===
create index ix_file_1 on file (filesize);
create index ix_file_2 on file (filename);

alter table file add md5 varchar;
alter table file add goal varchar;
alter table file add importance varchar;
alter table file add computer varchar;
alter table file add srcbak varchar;
alter table file add action varchar;

update file set computer = 'nico-MS-7760';

-- find doubles
-- both name and size and srcbak 'type'
-- and also same md5
select f1.filename, f1.filesize, f1.srcbak, f1.folder, f2.folder, f1.ts_cet, f2.ts_cet
from file f1, file f2
where f1.filename = f2.filename
and f1.filesize = f2.filesize
and f1.md5 = f2.md5
and (f1.srcbak = f2.srcbak or f1.srcbak is null or f2.srcbak is null)
and f1.id < f2.id;

-- specific one book.
select f1.filename, f1.filesize, f1.folder, f2.folder, f1.ts_cet, f2.ts_cet
from file f1, file f2
where f1.filename = f2.filename
and f1.filesize = f2.filesize
and (f1.srcbak = f2.srcbak or f1.srcbak is null or f2.srcbak is null)
and f1.id < f2.id
and f1.filename like '%The Grammar of Graphics%';

-- only name
select f1.filename, f1.filesize, f2.filesize, f1.folder, f2.folder, f1.ts_cet, f2.ts_cet
from file f1, file f2
where f1.filename = f2.filename
and f1.filesize <> f2.filesize
and f1.id < f2.id;
--> best veel, o.a. veel keynotelogs.db

-- only size
select f1.filename, f2.filename, f1.filesize, f1.folder, f2.folder, f1.ts_cet, f2.ts_cet
from file f1, file f2
where f1.filename <> f2.filename
and f1.filesize = f2.filesize
and f1.id < f2.id;
--> wel wat, kan dubbel zijn als naam deels overeenkomt.
--> kan zinvol zijn voor deze MD5 te bepalen.
--> ook /home/nico/.aerofs.aux.86a6f5 met grote files, backup van bv wonder years, kunnen dus weg.
--> mogelijk .svn (en mss ook git) dingen in backup, naast eigenlijk files: kan ook weg.
--> /media/nico/Iomega HDD/backups/OrdinaHPLaptop/d/DB2/home/ahfs/DATA1 => kan geen backup meer zijn, want orig is weg, dus hooguit naar archief (met daar dan evt weer backup van).
--> mstk-yvhh_1.oj2005.r01 in /media/nico/Iomega HDD/media/Cabaret/Youp van 't Hek/Youp van t Hek Oudejaarsconference 2005 TVRip XviD, ofwel uitpakken als het kan, anders weg.

-- =========================================================
-- =========================================================
-- =========================================================


-- actions required
-- find doubles
-- both name and size and srcbak 'type'
-- and also same md5
select f1.filename, f1.filesize, f1.srcbak, f1.folder, f2.folder, f1.ts_cet, f2.ts_cet
from file f1, file f2
where f1.filename = f2.filename
and f1.filesize = f2.filesize
and f1.md5 = f2.md5
and f1.srcbak = 'source'
and f2.srcbak = 'temp';
--> dit levert nu maar 1 op: yEd, de 'temp' versie mag weg.
--> als je hier script voor maakt, dan zowel fysieke delete doen als delete uit DB.
--> delete kan ofwel op deze manier, heb een andere dezelfde file.
--> maar kan ook op zichzelf, dat file niet meer nodig is: te oud, te groot, in bepaalde dir?

TODO: delete-unwanted.clj maken.


