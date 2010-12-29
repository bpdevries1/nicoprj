-- checks
-- wedstrijd waarvoor geen scheids (kan_wedstrijd_fluiten) te vinden is.

select * from wedstrijd w
where scheids_nodig = 1
and not exists (
  select 1
  from kan_wedstrijd_fluiten kwf
  where kwf.wedstrijd = w.id
);
==> 14-9-2010 komt niet voor.

-- test: alle wedstrijden in 2011 eerst weg
delete from wedstrijd
where datumtijd > '2011-01-01';

-- wie scheids er geen wedstrijd?
select * from persoon p
where not exists (
  select 1
  from scheids s
  where s.scheids = p.id
)
order by p.naam;

-- @todo zijn er wedstrijden waarbij een zelfdedag te vinden is, maar met totaal op deze dag niet genoeg scheidsen heeft?
-- 19-9-2010 voorlopig niet nodig gehad.

-- geneste left join, want vanaf tabel A naar B en alles deze er is, ook C.
-- scheids_nodig is 1 hier niet, want wil ook H1/D1 wedstrijden zien.
select date(w.datumtijd) datum, time(w.datumtijd) tijd
       , w.opmerkingen, sch.naam, sch.speelt_zelfde_dag
from wedstrijd w
left join (
   select s.wedstrijd, p.naam, s.speelt_zelfde_dag
   from scheids s, persoon p
   where s.scheids = p.id
   and s.status = 'voorstel'
) as sch on sch.wedstrijd = w.id
where w.lokatie = 'thuis'
and w.datumtijd < '2011-01-01'
order by 1, 2, 3;

select p.*, t.naam  team from persoon p, team t, persoon_team pt
where p.id = pt.persoon
and t.id = pt.team
and pt.soort = 'speler'
order by p.naam

select p.*, t.naam team 
from persoon p left join (
  select t.naam, pt.persoon
  from team t, persoon_team pt
  where t.id = pt.team
  and pt.soort = 'speler'
) t on t.persoon = p.id
order by p.naam
             
-- toon bij wedstrijd alternatieve scheidsen, nu eerst voor Baukelien.
select concat(w.naam, ' ', ps.naam) wedstrijd, p.naam alternatief, kw.speelt_zelfde_dag, w.datumtijd
from wedstrijd w, kan_wedstrijd_fluiten kw, persoon p, persoon ps, scheids s
where w.id = kw.wedstrijd
and kw.scheids = p.id
and w.id = s.wedstrijd
and s.scheids = ps.id
order by w.datumtijd, w.naam

-- niet selecteren als er al een wedstrijd is.
select concat(w.naam, ' ', ps.naam) wedstrijd, p.naam alternatief, kw.speelt_zelfde_dag, w.datumtijd
from wedstrijd w, kan_wedstrijd_fluiten kw, persoon p, persoon ps, scheids s
where w.id = kw.wedstrijd
and kw.scheids = p.id
and w.id = s.wedstrijd
and s.scheids = ps.id
and not exists (
  select 1
  from scheids s2, wedstrijd w2
  where s2.wedstrijd = w2.id
  and s2.scheids = p.id
  and date(w2.datumtijd) = date(w.datumtijd)
)
and w.datumtijd < '2011-01-01'
order by w.datumtijd, w.naam

select concat(w.naam, ' ', ps.naam) wedstrijd, p.naam alternatief, kw.speelt_zelfde_dag, w.datumtijd
from wedstrijd w, kan_wedstrijd_fluiten kw, persoon p, persoon ps, scheids s, scheids s2, wedstrijd w2
where w.id = kw.wedstrijd
and kw.scheids = p.id
and w.id = s.wedstrijd
and s.scheids = ps.id
and exists (
  select 1
  from 
  where s2.wedstrijd = w2.id
  and date(w2.datumtijd) = date(w.datumtijd)
)
order by w.datumtijd, w.naam

-- persoon en zeurfactor
select *
from persoon p, zeurfactor z
where p.id = z.persoon
order by p.naam, z.speelt_zelfde_dag;

