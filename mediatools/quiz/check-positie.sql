-- posities toegevoegd, hoe te checken dat ze van 1..2000 lopen, zonder overlap en zonder gaten.

-- eerst min en max
select min(0+positie), max(0+positie) from track;
1|2000

-- ok, dan geen overlap:
select t1.positie, t1.path, t2.path from track t1, track t2
where t1.positie = t2.positie
and t1.path < t2.path
limit 10;



