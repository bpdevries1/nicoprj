# analyse.R

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db = dbConnect(dbDriver("SQLite"), "mht.db")
data = dbGetQuery(db, "select * from quser")

data = dbGetQuery(db, "select * from quser")
> summary(data)
       id         urlmain            urlquery            start          
 Min.   :1402   Length:57          Length:57          Length:57         
 1st Qu.:1418   Class :character   Class :character   Class :character  
 Median :1435   Mode  :character   Mode  :character   Mode  :character  
 Mean   :1435                                                           
 3rd Qu.:1451                                                           
 Max.   :1466                                                           
     end               duration          nqdb       
 Length:57          Min.   :   15   Min.   :  1.00  
 Class :character   1st Qu.:  118   1st Qu.:  1.00  
 Mode  :character   Median :  691   Median :  4.00  
                    Mean   : 3330   Mean   : 26.21  
                    3rd Qu.: 3185   3rd Qu.: 20.00  
                    Max.   :66776   Max.   :579.00  
> qplot(nqdb, duration, data=data)

even inzoomen

data2 = subset(data, data$nqdb < 50)
qplot(nqdb, duration, data=data2)

chdata = dbGetQuery(db, "select d1.start st1, d1.end end1, d2.start st2, d2.end end2
from qdb d1, qdb d2
where d1.id = d2.id - 1
and d1.quser_id = d2.quser_id
and d1.end > d2.start")


Dan nog 214 rijen over
chdata$diff = strptime(chdata$st2, format = "%Y-%m-%d %H:%M:%OS") - strptime(chdata$end1, format = "%Y-%m-%d %H:%M:%OS") 

Vind nu dingen van logging, had alleen quser verwijderd, nog niet qdb.

dan nog 207 over, dus.

data = dbGetQuery(db, "select u.id, u.duration, sum(q.duration) sum from quser u, qdb q where u.id = q.quser_id group by u.id")
qplot(duration, sum, data=data)
bij hele grote is het de helft, van de 65+ seconden is 30+ aan de queries te wijten.
bij de rest is het bijna 1-op-1.

data2 = subset(data, data$sum < 15000)

> lm(sum ~ duration, data=data2)

Call:
lm(formula = sum ~ duration, data = data2)

Coefficients:
(Intercept)     duration  
    23.8685       0.7994  

ofwel 80% van de tijd zit in de queries

Met alles mee:
> lm(sum ~ duration, data=data)

Call:
lm(formula = sum ~ duration, data = data)

Coefficients:
(Intercept)     duration  
   629.3251       0.4923  
   
Dan dus 50%, de paar zwaren hebben grote invloed.

hier ook percentile graph van te maken

data$ecdf = ecdf(data$duration)(data$duration) 

breaks <- as.vector(c(1, 2, 5) %o% 10^(1:5))

qplot(ecdf, duration, data = data, geom="line", xlab = "Percentiel", ylab = "Responsetijd (msec)") +
  scale_x_continuous(formatter="percent") +
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,100000))

data$ecdfsum = ecdf(data$sum)(data$sum) 

qplot(ecdfsum, sum, data = data, geom="line", xlab = "Percentiel", ylab = "Totale tijd queries (msec)") +
  scale_x_continuous(formatter="percent") +
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000))

Scatter van duration en sum, met groottes voor de aantallen queries.

data = dbGetQuery(db, "select u.id, u.duration, u.nqdb, sum(q.duration) sum from quser u, qdb q where u.id = q.quser_id group by u.id")

qplot(duration, sum, data=data)

logscalen beide:

qplot(duration, sum, data=data) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000)) 

eerst goed, maar later de scales weg.
  
qplot(duration, sum, data=data, size = nqdb) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000))   
  
qplot(duration, sum, data=data, colour = nqdb) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000))     
=> niet te zien.  

qplot(duration, sum, data=data, size = nqdb) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000)) +
  scale_size(name = "#queries", breaks = c(1,2,5,10,20,50,100), to = c(1,10))

breaks = 1:6

> exp(2*log(10))
[1] 100


qplot(duration, sum, data=data, size = log10(nqdb)) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000)) +
  scale_size(name = "#queries", breaks = c(1,2,5,10,20,50,100), to = c(1,10))  

assen zijn verdwenen.
qplot(duration, sum, data=data) +
  scale_x_log10(breaks = breaks, labels = breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = breaks, limits=c(10,50000))
  
assen nog steeds weg.

even opnieuw starten...

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db = dbConnect(dbDriver("SQLite"), "mht.db")
data = dbGetQuery(db, "select u.id, u.duration, u.nqdb, sum(q.duration) sum from quser u, qdb q where u.id = q.quser_id group by u.id")

axis.breaks <- as.vector(c(1, 2, 5) %o% 10^(-2:2))

qplot(duration, sum, data=data) +
  scale_x_log10(breaks = breaks, labels = axis.breaks, limits=c(10,100000)) +  
  scale_y_log10(breaks = breaks, labels = axis.breaks, limits=c(10,50000)) 

#size.breaks = 0:5 / 2
#size.labels = exp(size.breaks * log(10))
 
size.labels = c(1, 2, 5, 10, 20, 50, 100)
size.breaks = log10(size.labels)

qplot(duration / 1000, sum / 1000, data=data, size=log10(nqdb), xlab = "Responstijd (sec)", ylab = "Som van queries (sec)") +
  scale_x_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,100)) +  
  scale_y_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,50)) +
  scale_size(name = "#queries", breaks=size.breaks, labels=size.labels)

=> deze wel mooi, soort 3D grafiek, laat 3 waarden zien hier.
  
geom_point hier met alpha doet niets. kan zijn omdat 'ie dubbel is.
met alpha in de main plot wel, maar dan een extra legend erbij.

# ook:x = nq, y = R totaal

qplot(nqdb, duration / 1000, data=data, xlab = "#queries", ylab = "Responstijd (sec)") +
  scale_x_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,100)) +  
  scale_y_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,50))

# eerst zonder logschaal.
qplot(nqdb, duration / 1000, data=data, xlab = "#queries", ylab = "Responstijd (sec)")
# ook niet helder.

qplot(nqdb, duration / 1000, data=data, xlab = "#queries", ylab = "Responstijd (sec)") +
  scale_x_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(1,600)) +  
  scale_y_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,70))

# 10 request met hoogste responstijden
data10 = dbGetQuery(db, "select urlmain, start, duration, nqdb from quser order by duration desc limit 10")

# per stuk bekijken.

Eerste, met 579 queries: de bekende: met veel repeating, steeds ander melding_nr

Nr 2,3: eerst wat diverse queries, hierna ook steeds dezelfde, ook variatie alleen melding nr.

Nr 4: eigenlijk ook hetzelfde als 3.

Nr 5: mld_edit_melding_save.asp, 27 queries, ruim 8 seconden.

14:59:36.227
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 5, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	140ms
14:59:36.367
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 40, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	235ms
14:59:36.649
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 40, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	391ms
14:59:37.055
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 20, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	63ms
14:59:37.118
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 20, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	156ms
14:59:37.290
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 10, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	78ms
14:59:37.384
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 10, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836
	125ms
14:59:37.509
{_mld_stdmelding} 	
SELECT FAC.DatumTijdPlusUitvoerTijd(m.mld_melding_datum, 3, 'DAGEN') datum FROM mld_melding m WHERE mld_melding_key = 412836

Ofwel berekening in de DB die je waarschijnlijk veel sneller op appserver kan doen, en anders in 1 query al deze waarden. Ook aantal dubbele (40, 20, 10).

Nr 6:
appl\\mld\\mld_search.asp, wat anders dan appl\\mld\\mld_search_list.asp

SELECT mld_vrije_dagen_datum FROM mld_vrije_dagen => 688 milliseconden! app server draait gewoon, ook niet zo dat eerst cache gevuld moet worden.
Geen repeating queries, dus samenvoegen queries zal wat meer moeite kosten, maar is zeker mogelijk.

Nr 7-8:
Appl\\MLD\\mld_edit_melding.asp
Ook weer de DatumTijdPlusUitvoerTijd calls, weer dubbel. Verder geen repeating.

Nr 9:
appl\\fac\\fac_usrrap_list.asp

1 query "BEGIN xml.make_xml('rapport', 28 , 'RWSN', '568697700', 0, '32974#03-01-2011#31-08-2011'); END;" die 4362ms duurt. Mogelijk is dit acceptabel voor een XML rapport.

Nr 10:

15:02:51.464
{discx3d} 	
SELECT alg_regio_key FROM alg_v_my_region WHERE prs_perslid_key = 32974
	188ms
N/R
15:02:51.652
{discx3d} 	
SELECT alg_district_key FROM alg_v_my_district WHERE prs_perslid_key = 32974
	125ms
N/R
15:02:51.777
{discx3d} 	
SELECT alg_locatie_key FROM alg_v_my_location WHERE prs_perslid_key = 32974
	813ms
N/R
15:02:52.590
{discx3d} 	
SELECT alg_gebouw_key FROM alg_v_my_building WHERE prs_perslid_key = 32974
	297ms
N/R
15:02:52.902
{discx3d} 	
SELECT alg_verdieping_key FROM alg_v_my_floor WHERE prs_perslid_key = 32974
	47ms
N/R
15:02:52.949
{discx3d} 	
SELECT alg_ruimte_key FROM alg_v_my_room WHERE prs_perslid_key = 32974

Dit kan ook vrij gemakkelijk in 1 query.

