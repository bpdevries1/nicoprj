-- 41, 9 en 70 verder verklaren:

drop table if exists lost_fb;

create table lost_fb as
select g.ts_cet ts_cet, g.msgid msgid, p.template template, t.STP STP, t.FXDERV FXDERV, t.Channel Channel, t.MM MM 
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Mail'
and t.MM = 'Current'
and not g.msgid in (
  select msgid
  from mqget gm
  where gm.status = 'Match'
);
-- [2016-04-01 12:50:09] ok, staan 34 in.

drop table if exists lost_26;

create table lost_26 as
select g.ts_cet ts_cet, g.msgid msgid, p.template template, p.STP STP, p.FXDERV FXDERV, p.Channel Channel, p.MM MM
from mqget g join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Mail'
and t.MM = 'Current'
and not g.msgid in (
  select msgid from outlrepl
);

-- check of lost_26 allemaal in lost_db zitten:
select * from lost_26
where msgid not in (
  select msgid from lost_fb
)
-- [2016-04-01 12:55:45] ok, klopt voor 24-3.
drop table if exists lost_912;

create table lost_912 as
select * from xmlfw
where msgid <> '<none>'
and msgid > '20160324'
and not msgid in (
  select msgid from mqget 
  where status = 'Match'
);

-- geen overlap tussen 26 en 912?
select * from lost_26
where msgid in (
  select msgid from lost_912
);
-- [2016-04-01 13:04:09] ok, geen result 24-3.

-- alles van fb zit ook in 26 of 912?
select * from lost_fb
where not msgid in (
  select msgid from lost_912
)
and not msgid in (
  select msgid from lost_26
);
-- [2016-04-01 13:05:12] ok, ook geen result.

-- welke nog extra in 912, zijn dit unrecognised en/of proposed match?
-- of uit een vorige test?

-- in 912 en in fb (verwachting = 32):
select * from lost_912
where msgid in (
  select msgid from lost_fb
)
-- [2016-04-01 13:14:28] ok, idd 32.

-- en dan de extra:
select * from lost_912
where not msgid in (
  select msgid from lost_fb
)
-- idd 38 stuks.
-- 38 stuks waarvoor geldt:
-- wel in 9, niet in 12.
-- niet in (wel in f (1), niet in b (12))
-- dus sowieso niet in 12.
-- maar wel in zowel 1 als 9.


1 vd 38:
ts_cet	msgid	uuid	xmlfile
2016-03-24 15:35:05	20160324_152831_123	f1d9203d126915c3ccba46652fa7cb45	/appl/scritturadropbox/tmp/n1of43mj.xml

deze zou dus niet in mqget/ack zitten:

select * from mqget
where msgid = '20160324_152831_123';

Deze is er dus wel:
ts_cet	timediff_sec	msgid	status	getfilename
2016-03-24 15:29:21	50	20160324_152831_123	Ack	20160324_152921_325_GET

dan vraag welke template, en verwacht je deze wel in deze fases van het proces?

select * from mqget
where msgid = '20160324_152831_123';

select *
from mqget g 
join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.msgid = '20160324_152831_123'
-- is STP, Swift, Current, FX.

-- omdat het een swift is, verwacht ik geen verdere processing?

Geldt dit voor alle 38, dat het om swift berichten gaat?

select g.msgid, t.Channel, * from lost_912 g
join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where not g.msgid in (
  select msgid from lost_fb
)
-- [2016-04-01 13:44:39] idd allemaal swift berichten.
-- deze dus langsgekomen bij dropbox xml forwarder.

-- zijn er swift berichten die nog verder zijn gekomen, ofwel ook een match bericht?
select g.msgid, t.Channel, t.FXDERV, t.MM, t.STP, t.template, * 
from mqget g
join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Swift'
and g.msgid in (
  select msgid from mqget g2
  where g2.status = 'Match'
);
-- 67 stuks ook. Dit heeft dus niets met UUID's te maken.
-- mogelijk een bepaald template?
-- allemaal combi van Swift, FX, Current, STP.

templates:
2 van FXMM_FXNDF_swift_with_conf_41926842.xml
54 van FXMM_FXSPOT_swift_with_conf_41877126.xml
11 van FXMM_FXSWAP_swift_with_conf_41943108.xml
-- wel dus een naam als 'with conf'.

select * from template
where template like '%with_conf%'

-- nog andere templates 'with conf'?
-- [2016-04-01 13:58:57] alleen deze 3.

-- frequenties van deze 'with conf'?
-- 12, 35 en 27, totaal dus 74 ( per uur)

-- hoe verhoudt zich dit tot de andere frequenties waarbij een Match wordt verwacht?
select * from template
where Channel = 'Mail'

select sum(freq), MM from template
where Channel = 'Mail'
group by 2;

sum(freq)	MM
221	Current
500	MM

-- [2016-04-01 14:11:00] dus wel invloed op het totaal, maar niet heel veel: 74/721 = 10% erbij nog.

-- fax berichten waarbij toch een conf is binnen gekomen?
select g.msgid, t.Channel, t.FXDERV, t.MM, t.STP, t.template, * 
from mqget g
join mqput p on g.msgid = p.msgid
join template t on t.template = p.template
where g.status = 'Ack'
and t.Channel = 'Fax'
and g.msgid in (
  select msgid from mqget g2
  where g2.status = 'Match'
);
-- [2016-04-01 14:12:12] Nee, geen.

-- waar zijn deze berichten verder langsgekomen? Eerst met 1 beginnen.

select * from mqget
where msgid = '20160324_152831_123';
-- alleen een Ack, geen Match.

-- 6: Outlook reply (outlrepl, msgid)
select * from outlrepl
where msgid = '20160324_152831_123';
-- ja: FX SWAP Confirmation (Rabobank Ref. 20160324_152831_123 / 20160324_152831_123)

-- 7: Exchange connector (exchconn, msgid)
select * from exchconn
where msgid = '20160324_152831_123';
-- ja

-- 8: Connector framework (connfw, msgid)
select * from connfw
where msgid = '20160324_152831_123';
-- ja

-- 9: XML Forwarder (xmlforw, msgid)
select * from xmlfw
where msgid = '20160324_152831_123';
-- ja

-- deze berichten gaan dus ook het hele proces door. Het is dus Swift, maar ook Mail.

-- Voor dezen channel op 'SwiftMail' zetten en berekeningen opnieuw.
update template
set channel = 'SwiftMail'
where template like '%with_conf%';



-- PUT messages without an Ack
-- find messages where ack is expected but not found:
select ts_cet, template, msgid, take
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
-- kan in theorie alleen voorkomen in de Scrittura logs, als er iets mee mis is.
-- evt het bericht zelf nog bekijken.
-- lijkt wel een goed XML bericht.

-- [2016-04-01 14:32:41] zoek in scrittura log: gevonden in de .16:

2016-03-24 16:37:25,698 [[ACTIVE] ExecuteThread: '32' for queue: 'weblogic.kernel.Default (self-tuning)'] INFO  com.ipicorp.docmgr.docmgrinterface.impl.DocmgrFolderLocalImpl  - Unable to retrieve folder with parent id 355097 and name Calypso20160324_163317_604
2016-03-24 16:37:25,698 [[ACTIVE] ExecuteThread: '32' for queue: 'weblogic.kernel.Default (self-tuning)'] DEBUG com.ipicorp.docmgr.ejb.ResourceBean  - SELECT ID FROM DOCMGR_RESOURCE WHERE PARENTID=? AND RESOURCETYPE=? AND INDEX0=?
	[1:355097]
	[1:1]
	[1:Calypso20160324_163317_604] 
	
	2016-03-24 16:37:25,702 [[ACTIVE] ExecuteThread: '32' for queue: 'weblogic.kernel.Default (self-tuning)'] INFO  com.ipicorp.docmgr.ejb.ResourceBean  - Created Folder: parent=355097 id=1334633 etype=Deal title=Calypso20160324_163317_604 user=admin 
	
	2016-03-24 16:37:26,059 [[ACTIVE] ExecuteThread: '27' for queue: 'weblogic.kernel.Default (self-tuning)'] DEBUG com.ipicorp.scrittura.prodinst.ProductInstanceBeanBMPImpl  - 
	[1:Calypso20160324_163317_604]
	[2:1]
	[3:FXSPOT]
	[4:1334633]
	[5:-1]
	[6:3]
	[7:admin]
	[8:1970-01-01 01:00:00.0]
	[9: ]
	[10:486353]
	[11:Calypso20160324_163317_604] 
	
	deze dan evt ook naar csv zetten: 
	* bewaar regels die met timestamp beginnen.
	* als je een regel ziet die aan msgid formaat voldoet:
	maak csv regel met orig regel (ts+tekst) en nieuwe regel (regel+msgid).
	
	kan zijn dat voor deze minder regels voorkomen dan voor andere messages.
	
	Weblogic: alleen in JMSlog: produced, consumed van berichten. Dit voegt weinig toe tov PUT/GET logging.
	
	
	








-- per template bepalen waar je berichten verwacht, evt ook obv 10% attachment vervanging (rest is strikt bepaald, deterministisch)
-- en deze 10% dan concreet bepalen uit de mail-reply logs.








