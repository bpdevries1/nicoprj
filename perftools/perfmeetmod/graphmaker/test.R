test.R:


test:
df=dbGetQuery(con, "select id, value from test where name='a'")
> df
  id value
1  1    10
2  2    20
3  3    30
> qplot(id, value, data=df, geom="point")
goed

df=dbGetQuery(con, "select id, name, value from test order by id, name")
qplot(id, value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = c(0.2,0.9))

query = "SELECT r.dt, r.dec_dt, r.name, r.value
FROM resusage r, logfile l
where r.logfile_id = l.id
and l.path = 'I:/Klanten/IND/Performance/input/logging-erik-20091229/20091228-1/meting_28122009_run1.csv'
order by dt, name"

df=dbGetQuery(con, query)
    
qplot(dt, value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none")
  
qplot(dec_dt, value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none")

  
query = "SELECT r.dt, r.dec_dt, r.name, r.value
FROM resusage r, logfile l
where r.logfile_id = l.id
and l.path = 'I:/Klanten/IND/Performance/input/logging-erik-20091229/20091228-1/meting_28122009_run1.csv'
and r.dec_dt < 20091228100458
order by dt, name"

df=dbGetQuery(con, query)

qplot(dt, value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none")

qplot(dt, value, data=df, geom="line", colour=name, shape=name) +
  opts(legend.position = "none")
  
psx_timestamp = strptime(typeperf_data[[1]], format="%m/%d/%Y %H:%M:%S")
psx_dt = strptime(df$dt, format="%Y-%m-%d %H:%M:%S")

qplot(psx_dt, value, data=df, geom="line", colour=name, shape=name) +
  opts(legend.position = "none")

qplot(dt2, value, data=df, geom="line", colour=name, shape=name) +
  opts(legend.position = "none")
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none")
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none") + 
  scale_x_datetime(format = "%Y-%m-%d %H:%M:%S")
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "none") + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = c(0.2,0.9)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")
  
theme_set(theme_bw())  
theme_set(theme_grey())

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position = "bottom", legend.justification=c(0,0)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.justification=c(0,0)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.justification=c(1,1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position=c(0.95, 0.95), legend.justification = c(1, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")
=> rechtsboven, waarbij rechterbovenhoek van legend op .95,.95 staat

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=name, shape=name) +
  opts(legend.position=c(0.1, 0.95), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")

====== na resname ========
theme_set(theme_bw())  

con = dbConnect(MySQL(), user="perftest", password="perftest", dbname="testmeetmod", host="localhost")

query = "SELECT r.dt, r.dec_dt, n.graphlabel resource, r.value
FROM resusage r, logfile l, resname n
where r.logfile_id = l.id
and r.resname_id = n.id
and l.path = 'I:/Klanten/IND/Performance/input/logging-erik-20091229/20091228-1/meting_28122009_run1.csv'
order by r.dt, n.graphlabel"

df=dbGetQuery(con, query)

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")
  
=== scaling ===
theme_set(theme_bw())  

con = dbConnect(MySQL(), user="perftest", password="perftest", dbname="indmeetmod", host="localhost")

query = "SELECT r.dt, r.dec_dt, t.label resource, r.value / t.fct value
FROM resusage r, logfile l, tempgraph t
where r.logfile_id = l.id
and t.resname_id = r.resname_id
and l.path = 'I:/Klanten/IND/Performance/input/logging-erik-20091229/20091228-1/meting_28122009_run1.csv'
order by r.dt, t.label"

df=dbGetQuery(con, query)

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource, main="Resource usage", xlab="Time", ylab="Usage") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S")

=== meer dan 6 ===
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S") +
  scale_shape_manual(value=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14))

qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S") +
  scale_shape_manual(value=0:25)

graph_start = "2009-12-28 10:20:00"
graph_end = "2009-12-28 10:30:00"
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", limits=c(as.POSIXct(graph_start), as.POSIXct(graph_end))) +
  scale_shape_manual(value=0:25)
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", major="2 min", minor="20 sec") +
  scale_shape_manual(value=0:25)
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", minor="20 sec") +
  scale_shape_manual(value=0:25)
  
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource) +
  opts(legend.position=c(0.1, 0.99), legend.justification = c(0, 1)) + 
  scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", minor="2 sec") +
  scale_shape_manual(value=0:25)  
