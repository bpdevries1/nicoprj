select * from func_entry
where linenr_end > linenr_start

select count(*) from ssl_entry

select * from func_entry
where entry like '%securepat01.rabobank.com%'
and not entry like '%Closed connection%'
and not entry like '%Closing connection%'
and not entry like '%Already connected%'
and not entry like '%headers%'
and not entry like '%Found resource%'
and not entry like '%Parameter Substitution:%'
and not entry like '%Request done%'
and not entry like '%SSL protocol error%'

select * from ssl_entry
where functype like '%protocol%'

select * from func_entry
where functype = 'unknown'

select * from func_entry
where functype like '%error%' 

drop table ssl_data

create table ssl_data as
select distinct ssl data, 'ssl' col
from ssl_entry
union
select distinct ctx data, 'ctx' col
from ssl_entry
union
select distinct sess_address data, 'sess_addressssl' col
from ssl_entry
union
select distinct socket data, 'socket' col
from ssl_entry
union
select distinct address data, 'bio' col
from bio_entry

select *
from ssl_data s1, ssl_data s2
where s1.data = s2.data
and s1.col <> s2.col

select * from bio_entry
where address = '02E4F368' 
order by linenr_start;

select * from ssl_entry
where sess_address = '02E4F368' 
order by linenr_start;

select logfile_id, count(*)
from bio_entry
where functype = 'free'
group by 1;

select * from func_entry
where entry like '%Closed connection%'

select logfile_id, count(*)
from func_entry
where functype = 'closed_conn'
group by 1;

select logfile_id, functype, count(*)
from bio_entry
group by 1,2
order by 1,2;

select logfile_id, call, count(*)
from bio_entry
where functype = 'ctrl'
group by 1,2
order by 1,2;

select * from func_entry
where functype like '%error%'


select count(*), logfile_id, domainport, sess_id
from ssl_entry
group by 2,3,4;


select b1.linenr_start, b1.call, b2.linenr_start, b2.call, b1.address, b2.address
from bio_entry b1, bio_entry b2
where b1.vuserid = b2.vuserid
and b1.address = b2.address
and b1.functype = 'free'
and b2.functype <> 'free'
and b1.linenr_start < b2.linenr_start;

select * from bio_block
where address = '02E55160'

select * from bio_entry
where address ='02EBEEB0'
and functype = 'free'

select * from bio_block
where address ='02EBEEB0'

select * from bio_block
where linenr_start = 490


select *
from bio_entry e
where not exists (
  select 1
  from bio_block b
  where e.linenr_start >= b.linenr_start
  and e.linenr_end <= b.linenr_end
);

select * from func_entry
where entry like '%connect%'

select distinct domain_port, ip_port
from func_entry

select * 
from func_entry
where domain_port not like '%:%'
and domain_port <> ''


select * 
from func_entry
where conn_nr = '8'

select * from func_entry
where entry like '%t=65815ms:%'

select * from conn_block
order by nreqs



select * from func_entry
where functype = 'resp_headers'


deze nog goed voor file=2, regelnr = 2619-2644
https://securepat01.rabobank.com/wps/myportal/rcc/!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNHL0dDZ28DbwNfN1dDRzNAnwMvb2MjIJNzYEKIoEKDHAARwNC-gtyQxUB6Pi80Q!!/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_6AKA1BK0K0MGE0A6PL1KJ22SD7/res/id=externalRatesCss/c=cacheLevelPage/=/

Op line 2067:
Login_cert_main.c(81): Error -27762: Request "https://securepat01.rabobank.com/wps/myportal/rcc/!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNHL0dDZ28DbwNfN1dDRzNAnwMvb2MjIJNzYEKIoEKDHAARwNC-gtyQxUB6Pi80Q!!/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_6AKA1BK0K0MGE0A6PL1KJ22ST6/res/id=externalRatesCss/c=cacheLevelPage/=/" failed  	[MsgId: MERR-27762]

Het is idd ook een externalRatesCss, maar wel een andere: D7/res/id vs T6/res/id

select * from func_entry
where entry like '%externalRatesCss%'



select * from ssl_entry
where socket_id <> '';

select count(*), logfile_id, functype, ctx, domain_port
from ssl_entry
where functype <> 'cert_error'
and ctx <> ''
group by 2,3,4,5

select logfile_id, entry, functype, domain_port, ssl, sess_address, sess_id, socket, socket_id
from ssl_entry

select * from ssl_entry
where entry like '%reused%'
and not entry like '%not reused%'

select * from ssl_entry
where functype = 'conn_info'

select * from ssl_entry

		name      : /C=NL/ST=Utrecht/L=Utrecht/O=Rabobank Nederland/CN=wwwpat.rabobank.com
		version   : 00.02
		public key: 2048 bits
	Session information:
		master key: (length 48): 248E7FA54041F9281FE7AA8B1B6F3A99A49AD47092B1FD005290F3C0FFF9BD13A92CD3A5C9537A871D84814F64776159
		session id: (length 32): AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A


select * from ssl_entry
where sess_id = 'AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A'

kan het zijn dat LR sessions idd door elkaar haalt, dat sess_id voor zowel securepat als cdnpat wordt gebruikt? En dat dit dan vaak/soms toch goed gaat toevallig, maar ook wel eens fout dus.

Server bepaalt de session id. Of kan het zijn dat er communicatie tussen beide servers is (via CRAS?) en dat ze dan op hetzelfde ID uitkomen?
Want dit verklaart nog niet waarom bij nconc=1 het wel (altijd) goed gaat.

Het ging al fout bij de handshake? Of nog eerder, bij TCP connectie maken?

Wat is een sessie, looptijd van een sessie, ofwel de scope?

Login_cert_main.c(81): [SSL:] Freeing the global SSL session in a callback, connection=securepat01.rabobank.com:443, session address=02E4F368, ID (length 32): AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A  	[MsgId: MMSG-26000]

Login_cert_main.c(81): [SSL:] Freeing the global SSL session in a callback, connection=securepat01.rabobank.com:443, session address=02E4F368, ID (length 32): AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A  	[MsgId: MMSG-26000]

select * from func_entry
where entry like '%SSL protocol%'

select * from conn_block
where linenr_start < 2067
and linenr_end > 2067
and logfile_id = 2


select * from bio_block
where linenr_start < 2067
and linenr_end > 2067
and logfile_id = 2

select 'bio' tp, logfile_id, id, linenr_start, linenr_end
from bio_block
where linenr_start < 2067
and linenr_end > 2067
and logfile_id = 2
union
select 'conn' tp, logfile_id, id, linenr_start, linenr_end
from conn_block
where linenr_start < 2067
and linenr_end > 2067
and logfile_id = 2
order by logfile_id, tp, id

select * from conn_block
where id = 35

create table conn_bio_block (bio_block_id, conn_block_id, reason);

insert into conn_bio_block
select b.id, c.id, 'linenr_end 1 diff'
from bio_block b, conn_block c
where b.logfile_id = c.logfile_id
and b.linenr_end + 1 = c.linenr_end

select * from conn_block
where id = 16

select * from bio_block
where id = 16


select *
from bio_block
order by logfile_id, socket_fd

select count(*), logfile_id
from conn_block
group by 2

select * from func_entry
where conn_nr = '5'
and logfile_id = 2

select * from conn_block where id = 27

select * from bio_block where id = 27

select * from bio_entry where address = '031CBC78'

=> levert connecting (943), connected socket (1733) en closed (2075). Op TCP niveau lijkt de verbinding dus wel goed.
2067 gaf fout.

select * from conn_block where id =24

select * from func_entry
where conn_nr = '0'
and logfile_id = 2

select * from bio_block where id = 24

select  *
from bio_entry
where address= '031CBC78'
and logfile_id = 2

write 247
ctrl6->0
reads, eerste -1, nog niet klaar, daarna 6x ok.
write 7->7
ctrl 11 -> 1
error msg
ctrl 7->0
free


select * from bio_entry
where call like '%ctrl(11)%'

socket iets: 03135D88
socket_id = 8
logfile=2, line 2220.

select * from conn_block
where conn_nr = 8
cdnpat, 1 req, id =35

select * from func_entry
where conn_nr = '8'

select * from bio_block where id = 35
address = 031C0030, dus niet gelijk aan socket iets.

select * from ssl_entry
where socket_id <> ''

select * from ssl_entry
where socket_id = '5'
and logfile_id = 2

select * from ssl_entry
where logfile_id = 2
and ssl = '031CC1E8'

select * from ssl_entry
where sess_id = 'B1C73633E1EBBC738DAB080255A0E3A7A6C930762AABA6B31500741187BDFB71'


select * from ssl_entry
where functype like '%global%'
and logfile_id = 1

select * from ssl_entry
where socket_id <> ''

select * from conn_block
where conn_nr = 0

select * from func_entry
where socket_id <> ''

drop table newssl_conn_block

create table newssl_conn_block as
select s.logfile_id, s.linenr_start newssl_linenr, s.conn_nr, c.linenr_start, c.linenr_end, s.id ssl_entry_id, c.id conn_block_id,
  s.domain_port domain_port, s.ssl ssl, s.ctx ctx, s.socket socket, c.nreqs nreqs
from ssl_entry s, conn_block c
where s.conn_nr <> ''
and s.functype = 'new_ssl'
and s.logfile_id = c.logfile_id
and s.linenr_start between c.linenr_start and c.linenr_end
and s.conn_nr = c.conn_nr
order by 1,2,3


select s.domain_port, s.ssl, s.ctx, s.socket, c.nreqs, *
from ssl_entry s, conn_block c
where s.conn_nr <> ''
and s.functype = 'new_ssl'
and s.logfile_id = c.logfile_id
and s.linenr_start between c.linenr_start and c.linenr_end
and s.conn_nr = c.conn_nr
order by 1,2,3


select * from conn_block
where not id in (
  select conn_block_id
  from ssl_conn_block
)

select * from ssl_entry
where conn_nr <> ''
and not id in (
  select ssl_entry_id
  from ssl_conn_block
)

select count(*), ssl_entry_id, conn_block_id
from ssl_conn_block
group by 2,3
having count(*) = 1

select * from conn_block
where id <> ''

drop view newssl_entry

select count(*), functype from ssl_entry
group by 2
order by 1 desc


select * from ssl_entry
where functype = 'cb_handshake_completion'


is combi sess_adr/sess_id wel fixed?

drop table if exists sess_addr_id

-- ook iterations hierbij:
create table sess_addr_id as
select count(*) cnt, logfile_id, sess_address, sess_id, min(linenr_start) min_linenr, max(linenr_end) max_linenr, min(iteration) min_iteration, max(iteration) max_iteration
from ssl_entry
where sess_address <> ''
and sess_id <> ''
group by 2,3,4
order by 2,5;

select * from ssl_entry
where sess_address <> ''
and sess_id <> ''


select count(*), sess_address
from sess_addr_id
group by 2
having count(*) > 1

select count(*), sess_id
from sess_addr_id
group by 2
having count(*) > 1

r511 en r520 een handshake completion op ssl = 02E54F78. Vuserid=45, log1.

select count(*), ssl
from
(select count(*) cnt, conn_nr, ssl
from newssl_conn_block
group by 2,3
order by 3,2)
group by 2
having count(*) > 1

02E54F78
03174F78

deze 2 ssl komen voor met verschillende conn nrs.

select * from newssl_conn_block
where ssl = '02E54F78'

select * from newssl_conn_block
where ssl = '03174F78'


select * from ssl_entry
where entry like '%global%'

select logfile_id, sess_address, sess_id, min(linenr_start) min_line, max(linenr_end) max_line
from ssl_entry
where sess_id <> ''
group by 1,2,3
order by 1,4

select *
from global_sess_addr_id g1, global_sess_addr_id g2
where g1.logfile_id = g2.logfile_id
and g1.min_linenr < g2.min_linenr
and g2.min_linenr <= g1.max_linenr

-- een overlap is er wel: melding van een nieuwe, oude moet hierna gesloten worden.
select *
from sess_addr_id g1, sess_addr_id g2
where g1.logfile_id = g2.logfile_id
and g1.min_linenr < g2.min_linenr
and g2.min_linenr < g1.max_linenr-1

logfile_id = 1:
02E4F368 -> 1499 t/m 2018 "AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A"
02F01E70 -> 1942 t/m 2007 "B1C73633E1EBB9018DAB080255A0E2A7997A957F151803F31500741187BDFB6A"

select * from ssl_entry
where sess_id = 'AA7126FDB9EFD7368CDA12490AAF02F7D709A2E2D28FCB8B3CE8954F1C2A2D0A'
or sess_id = 'B1C73633E1EBB9018DAB080255A0E2A7997A957F151803F31500741187BDFB6A'








ssl_session tabel, met:
logfile_id, startline, endline, iteration start/end, sess_id
lijst van: sess_address (maar 1), ssl, ctx, domain_port

einde bij "freeing_global_ssl"


select * from ssl_entry
where sess_id <> ''


B1C73633E1EBBC7E8DAB080255A0E3A7A6C930762AABA68D1500741187BDFB6E 
B1C73633E1EBC1198DAB080255A0E1A72C807F56A0E2FDA81500741187BDFB68

select * from ssl_entry
where sess_id = 'B1C73633E1EBBC7E8DAB080255A0E3A7A6C930762AABA68D1500741187BDFB6E'

select * from ssl_entry
where sess_id = 'B1C73633E1EBC1198DAB080255A0E1A72C807F56A0E2FDA81500741187BDFB68'

Login_cert_main.c(81): [SSL:] Considering establishing the above as a new global SSL session: bSslRessionReuseGlobal=1, _ptSSL=02E54F78, bSslRessionReuseGlobal=02E55F58, ptConnectedSslSession=00000000. Global session (_ptGlobalSslSession=02E13500): no session  	[MsgId: MMSG-26000]
Login_cert_main.c(81): [SSL:] Established a global SSL session  	[MsgId: MMSG-26000]

tweede regel als cont. zien, dan check hierop bij block_ssl, en veld zetten, bv estab_global_linenrs, kan >1x voorkomen.

verder isglobal flag, zetten als je free_ssl ziet, dus normale patroon.
aan het einde geen errors, maar bestaande keys afsluiten, met global=0.

select * from req_block where http_code like '%302%'

select count(*) from logfile

select min(ts_cet), max(ts_cet) from trans;

select * from conn_block where id <> '' and not id in (select conn_block_id from conn_bio_block)

select * from bio_block where vuserid = 231

select count(*), logfile_id, sess_address from sess_addr_id group by logfile_id, sess_address having count(*) > 1

"66"	"04B42F88"

select * from sess_addr_id
where logfile_id = 66
and sess_address = '04B42F88'

select * from logfile where id = 66

Op addr "04B42F88" 2 sessions, met linenrs:
"568"	"586"
"629"	"799"

Bij sess_ids kijken welke addresses gebruikt worden:

select rowid, * from sess_addr_id where logfile_id = 66 and sess_id in (
'B1C73633E1E913828DAB080255A0E2A7997F189D151D90FC15007411878FA873',
'B1C73633E1E919C48DAB080255A0E3A7A6CFB9442AAD32EF15007411878FA873')
order by sess_id, min_linenr

Deze beide sess_ids hebben elk maar 1 sess_address

select * from ssl_entry
where logfile_id=66
and sess_id in (
'B1C73633E1E913828DAB080255A0E2A7997F189D151D90FC15007411878FA873',
'B1C73633E1E919C48DAB080255A0E3A7A6CFB9442AAD32EF15007411878FA873')
order by linenr_start

select count(*) cnt, logfile_id, sess_address, sess_id, rowid entry_rowid, min(linenr_start) min_linenr, max(linenr_end) max_linenr, min(iteration) min_iteration, max(iteration) max_iteration
  from ssl_entry
  where sess_address <> ''
  and sess_id <> ''
  and logfile_id = 66
  group by 2,3,4,5
  order by 2,5,6


  check_overlap sess_addr_id {logfile_id sess_address} sess_id

select *
from sess_addr_id sa1, sess_addr_id sa2
where sa1.logfile_id = sa2.logfile_id
and sa1.sess_address = sa2.sess_address
and sa1.sess_id <> sa2.sess_id
and sa1.min_linenr between sa2.min_linenr and sa2.max_linenr


select count(*), logfile_id, sess_address from global_sess_addr_id group by logfile_id, sess_address having count(*) > 1


select * from sess_addr_id
where logfile_id=192
and sess_address = "0CEE2DD8"


and sess_id in (
'B1C73633E1E913828DAB080255A0E2A7997F189D151D90FC15007411878FA873',
'B1C73633E1E919C48DAB080255A0E3A7A6CFB9442AAD32EF15007411878FA873')
order by linenr_start

select * from ssl_session
order by logfile_id, linenr_start

alter table ssl_session add max_linenr
alter table ssl_session drop linenr_start



update ssl_session set min_linenr = linenr_start, max_linenr = linenr_end

select *
  from ssl_session t1, ssl_session t2
  where t1.logfile_id = t2.logfile_id
  and t1.id <> t2.id
  and t1.min_linenr+2 between t2.min_linenr and t2.max_linenr


select * from ssl_session
where logfile_id = 1
order by linenr_start

select * from newssl_conn_block
where logfile_id = 1





select * from logfile where id = 1

select * from ssl_conn_block
where iteration_start = 1
order by min_linenr

select *
  from ssl_conn_block t1, ssl_conn_block t2
  where t1.logfile_id = t2.logfile_id
  and t1.id <> t2.id
  and t1.min_linenr+0 between t2.min_linenr and t2.max_linenr

select * from ssl_entry
where linenr_start in (610, 778)
or linenr_end in (801, 810, 811)

"08AF88A0"
wanneer deze ssl afgesloten, 
bij welke sess_id hoort ie?

select * from ssl_entry
where ssl = '08AF88A0'

bij sess_id = "B1C73633E1E91A6E8DAB080255A0E0A744DDCA91C8BF21CD15007411878FA9AA"

start/einde van deze sess_id:

select * from ssl_entry
where sess_id = 'B1C73633E1E91A6E8DAB080255A0E0A744DDCA91C8BF21CD15007411878FA9AA'


"08AFDD88"
"B1C73633E1E91C198DAB080255A0E1A72C86E0C6A0E477D915007411878FA9AA"
wanneer deze combi afgesloten?

select * from ssl_entry
where ssl = '08AFDD88'

select * from ssl_entry
where sess_id = 'B1C73633E1E91C198DAB080255A0E1A72C86E0C6A0E477D915007411878FA9AA'

select * from ssl_entry
where linenr_start in (810, 824)



