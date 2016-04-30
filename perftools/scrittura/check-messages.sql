-- SQL queries to check if every PUT message is also GET with Ack and Match.
-- First fill some more helper tables/views

drop view if exists mqput;

create view mqput as
select 1 take, *
from mqput1
union
select 2 take, *
from mqput2
union
select 3 take, *
from mqput3;

-- fill noack table
drop table if exists noack;

create table noack as
select p.take take, p.template template, t.MM MM
from mqput p join template t on p.template = t.template
where not msgid in (
  select msgid
  from mqget
  where status = 'Ack'
)
group by 1,2,3
order by 1,2,3;

delete from noack
where take=3;

-- Want msgid in all tables:
alter table xmlfw add msgid;

update xmlfw
set msgid = (
  select msgid
  from connfw c
  where c.uuid = xmlfw.uuid
);

-- Verwijder alles van messages die oud zijn:
-- moet >= 20160401_104952_1 zijn.
-- en ts_cet >= '2016-04-01 10:45'
delete from connfw
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';

delete from docgen
where ts_cet < '2016-04-01 10:45';

delete from exchconn
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';

delete from mqget
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';

delete from outlrepl
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';

delete from pdfgenok
where ts_cet < '2016-04-01 10:45';

delete from pdfgensrc
where ts_cet < '2016-04-01 10:45';

delete from xmlfw
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';

delete from scrittura
where ts_cet < '2016-04-01 10:45'
or msgid = '<none>'
or msgid < '20160401_104952_1';


Cumulatief: ofwel in queries, ofwel in R.

Kan alle minuten in een nieuwe tabel stoppen, en bv alles weg wat niet een veelvoud van 5 minuten is. (of wel alle minuten houden).

Tabel maken en aanvullen met steeds per minuut het totale aantal MQput etc wat <= is aan deze minuut.

create table timestamps as
select distinct ts_cet
from scritconf
order by 1

create table allmsg (ts_cet, type, cnt);

insert into allmsg
select t.ts_cet, 'mqput', count(*)
from timestamps t, mqput p
where p.ts_cet <= t.ts_cet
group by 1,2;

insert into allmsg
select t.ts_cet, 'ack', count(*)
from timestamps t, mqget g
where g.ts_cet <= t.ts_cet
and g.status = 'Ack'
group by 1,2;

create table mailmsg (ts_cet, type, cnt);

insert into mailmsg
select t.ts_cet, 'mqput', count(*)
from timestamps t, mqput p join template t on p.template = t.template
where t.channel like '%Mail%'
and p.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'ack', count(*)
from timestamps t, mqget g join mqput p on g.msgid = p.msgid
join template t on p.template = t.template
where t.channel like '%Mail%'
and g.ts_cet <= t.ts_cet
and g.status = 'Ack'
group by 1,2;

insert into mailmsg
select t.ts_cet, 'match', count(*)
from timestamps t, mqget g 
and g.ts_cet <= t.ts_cet
and g.status = 'Match'
group by 1,2;

insert into mailmsg
select t.ts_cet, 'docgen', count(*)
from timestamps t, docgen g
where g.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'pdfgen', count(*)
from timestamps t, pdfgenok g
where g.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'outlrepl', count(*)
from timestamps t, outlrepl g
where g.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'exchconn', count(*)
from timestamps t, exchconn g
where g.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'connfw', count(*)
from timestamps t, connfw g
where g.ts_cet <= t.ts_cet
group by 1,2;

insert into mailmsg
select t.ts_cet, 'xmlfw', count(*)
from timestamps t, xmlfw g
where g.ts_cet <= t.ts_cet
group by 1,2;






-- Actual check queries below

-- PUT messages without an Ack
-- find messages where ack is expected but not found:
select ts_cet, template, msgid
from mqput p
where not msgid in (
  select msgid
  from mqget
  where status = 'Ack'
) and not exists (
  select 1
  from noack na
  where na.template = p.template
  and na.take = p.take
);
-- idd 1, ook nog bekijken:
-- ts_cet	template	msgid
-- 2016-03-24 16:33:17	FXMM_FXSPOT_swift_no_conf_41948270.xml	20160324_163317_604


-- zonder noack tabel, na 24-3-2016 niet meer nodig.
select ts_cet, template, msgid
from mqput p
where not msgid in (
  select msgid
  from mqget
  where status = 'Ack'
);
-- [2016-03-31 11:23:43] ok, overal een ack van, van alle 30 in de pretest1.


-- PUT messages without an Ack
-- oorzaak kan een fout input bericht zijn (zonder goed MsgId), afhankelijk van take en template.
select count(*), p.take, p.template, t.MM
from mqput p join template t on p.template = t.template
where not msgid in (
  select msgid
  from mqget
  where status = 'Ack'
)
group by 2,3,4
order by 2,3,4;


-- Other messages of this type do have an ack?
select ts_cet, template, msgid
from mqput p
where template = 'FXMM_FXSPOT_swift_no_conf_41948270.xml';
-- [2016-04-01 15:41:49] ja, idd, 1289 stuks.

-- Ack messages without PUT? (old?)
select *
from mqget
where status = 'Ack'
and not msgid in (
  select msgid
  from mqput
);
-- [2016-04-01 15:43:03] idd paar met msgid niet van mij.

-- Ack messages waarbij je (later) een match verwacht.

-- Ack messages without Match (and not Swift, but can be SwiftMail)
select *
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel like '%Mail%'
and t.MM = 'Current'
and not g.msgid in (
  select msgid
  from mqget gm
  where gm.status = 'Match'
);
-- [2016-04-01 15:44:12] dit zijn er nu 72 op 24-3, lost_fb dus.

-- Ack messages with a Match as expected (and not Swift)
select *
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Mail'
and t.MM = 'Current'
and g.msgid in (
  select msgid
  from mqget gm
  where gm.status = 'Match'
);


-- grouped by type
select count(*), t.template, t.FXDERV, t.STP
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Mail'
and t.MM = 'Current'
and not g.msgid in (
  select msgid
  from mqget gm
  where gm.status = 'Match'
)
group by 2,3,4
order by 2,3,4;
-- 41 stuks, deze verder verklaren.

-- in contrast: same overview where Match is received:
select count(*), t.template, t.FXDERV, t.STP
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Mail'
and t.MM = 'Current'
and g.msgid in (
  select msgid
  from mqget gm
  where gm.status = 'Match'
)
group by 2,3,4
order by 2,3,4;

-- xmlfw.msgid later toegevoegd. Overal een waarde?:
select * from xmlfw
where msgid is null or msgid = ''

-- als een item voorkomt in stap n+1, moet het ook voorkomen in stap n



-- stappen:
-- 1: MPQPUT (mgput tabel)
-- 2: MQGET-Ack (mqget tabel)
-- 3: To-be-drafted (bij niet-STP)
-- 4: DocGen (nu geen logs->csv)
-- 5: PdfGen (nu geen logs->csv)
-- 6: Outlook reply (outlrepl, msgid)
-- 7: Exchange connector (exchconn, msgid)
-- 8: Connector framework (connfw, msgid)
-- 9: XML Forwarder (xmlforw, msgid)
-- 10: Unrecognised (bij changed-att)
-- 11: Proposed Match
-- 12: MQGET-Match (na doorzetten in GUI, mqget tabel)

-- 2 vs 1 al eerder bekeken.

-- 6 vs 2 (stappen 3, 4 en 5 nu niet)
select * from outlrepl
where not msgid in (
  select msgid from mqget
  where status = 'Ack'
);
-- ok, niets

-- eerste bericht van mqput, take 1: 20160324_144654_1


-- 7 vs 6
select * from exchconn
where msgid >= '20160324_144654_1'
and not msgid in (
  select msgid from outlrepl
);
-- wel, nog steeds 15 stuks, raar, wel nieuwe berichten.
-- oa: 20160324_151527_22. Deze staat in dropbox-xml-2016-03-24--14-33-09.log.pretest, dus toch niet helemaal pretest.
-- [2016-03-31 09:00:49] nu wel leeg.

-- 7 vs 2 - dan nog niet 'verdwenen'?
select * from exchconn
where msgid >= '20160324_144654_1'
and not msgid in (
  select msgid from mqget
  where status = 'Ack'
);
-- deze leeg, mss mis ik een stuk log van de outlook replier, deze was wel gestopt ergens op 24-3...


-- 8 vs 7
select * from connfw
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from exchconn
);
-- met deze geen meer. Maar dit betekent wel dat exchange connector etc tijdens de test bezig zijn geweest met oude berichten!

-- 9 vs 8
select * from xmlfw
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from connfw
);
-- ok, leeg.

-- 12 vs 9
select * from mqget
where msgid <> '<none>'
and msgid > '20160324'
and status = 'Match'
and not msgid in (
  select msgid from xmlfw
);
-- ok, leeg.

-- Andersom: kijken waar items zijn blijven hangen, zou totaal op 41 moeten uitkomen.
-- 2 vs 6 (stappen 3, 4 en 5 nu niet, geen bruikbare logs)
select * from mqget
where status = 'Ack'
where not msgid in (
  select msgid from outlrepl
);
-- 2009 stuks, dus alleen Ack's pakken waarvan je verwacht dat ze doorgaan.

select * from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel like '%Mail%'
and t.MM = 'Current'
and not g.msgid in (
  select msgid from outlrepl
);
-- 9 stuks, zou kunnen.
-- [2016-04-01 15:46:33] nu nog 2 dus.

-- eerst verder, 6 vs 7:
select * from outlrepl
where msgid >= '20160324_144654_1'
and not msgid in (
  select msgid from exchconn
);
-- geen.

-- 7 vs 8
select * from exchconn
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from connfw
);
-- ook geen.

-- 8 vs 9
select * from connfw
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from xmlfw
);
-- en ook niets.


-- 9 vs 12
select * from xmlfw
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from mqget 
  where status = 'Match'
);
-- 70 stuks, raar.
-- [2016-04-01 15:47:07] nog steeds 70, maar nu dus wel verklaard.

