# test cmds for sqlite3 and ggplot2

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2)

db_name = "data.db"  
data_query = "select meas_time, val1 from flatdata"
# npoints_max = as.integer(commandArgs()[idx]); idx=idx+1;  # geeft max aantal te plotten points.
legend_query = "select fullname from legend where id in (0,1)" 
datetime_format = "%H:%M" 
graphfile_name = "test.png" 
scale = 0
graph_title = "Test title"
npoints = 200

db = dbConnect(dbDriver("SQLite"), db_name)
graphdata = dbGetQuery(db, data_query)
legend_data = dbGetQuery(db, legend_query)

psx_timestamp = strptime(graphdata[[1]], format=datetime_format)
seq_timestamp = seq(from=min(psx_timestamp, na.rm=TRUE), to=max(psx_timestamp, na.rm=TRUE), length.out=npoints)
cut_timestamp = cut(psx_timestamp, seq_timestamp)

i = 2
mean_counter = tapply(graphdata[[i]], cut_timestamp, mean, na.rm=TRUE)

# resource is kolom in dataset.
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource, main=title, xlab="Time", ylab="Usage") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

det_scale_x_datetime = function () {
  scale_x_datetime(format = "%H:%M", minor="5 min")
}

  
qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", colour="value 1", shape="value 1", main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)
  
qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", colour="value 1", shape="value 1", main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="bottom", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)
  
qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", colour="value 1", shape="value 1", main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="none", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)
  
qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="none", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

# todo: 2 lijnen tonen, dan melt nodig?

data_query = "select meas_time, val1, val2 from flatdata"
graphdata = dbGetQuery(db, data_query)
em = melt(graphdata, id = "meas_time")

qplot(psx_timestamp, value, data=em, geom="point", colour=variable, shape=variable, main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="bottom", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

qplot(psx_timestamp, value, data=em, geom="point", colour=variable, shape=variable, main=graph_title, xlab="Time", ylab="Data")
-> fout

qplot(meas_time, value, data=em, geom="point", colour=variable, shape=variable, main=graph_title, xlab="Time", ylab="Data")
-> ok

qplot(meas_time, value, data=em, geom="point", colour=variable, shape=variable, main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="bottom", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

  
det_scale_x_datetime = function () {
  scale_x_datetime(format = "%H:%M:%S", minor="5 min")
}
  
usage.max = max(graphdata[2:length(graphdata)], na.rm=TRUE)

qplot(psx_timestamp, value, data=em, geom="point", colour=variable, shape=variable, main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="bottom", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

  
# deze voor single line:
det_scale_x_datetime = function () {
  # scale_x_datetime(format = "%H:%M:%S", minor="5 min")
  scale_x_datetime(format = "%H:%M:%S")
}


qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", main=graph_title, xlab="Time", ylab="Data") +
  opts(legend.position="none", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", main=graph_title, xlab="Time", ylab="Data", ylim=c(0, usage.max)) +
  opts(legend.position="none", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", main=graph_title, xlab="Time", ylab="Data", ylim=c(-1000, usage.max)) +
  opts(legend.position="none", legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)
  
# 16-9-2011 test boxplots for resource graphs
qplot(tscut, val2, data=graphdata, geom="boxplot", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80))
# this shows an empty grid, everything except the data points.

qplot(stattype, value, data=resusage, geom="boxplot", xlab="Stat type", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80))
# die doet het wel.

# de x moet echt een category zijn, dus factor of levels gebruiken?
# en eerst wat minder points?

# eerst npoints = 10 gezet.

graphdata$tscutstr = cut(graphdata$psx_timestamp, ts.seq)

qplot(tscut, val2, data=graphdata, geom="boxplot", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80))
# still nothing
  
qplot(tscutstr, val2, data=graphdata, geom="boxplot", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80))
# shows something, also NA column

qplot(as.factor(tscut), val2, data=graphdata, geom="boxplot", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80))
# this works, now a bit more values

ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), length.out=50)
graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")

# 50 is ok for the boxes, but not for the labels below.
qplot(as.factor(tscut), val2, data=graphdata, geom="boxplot", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))

# of zelf een soort box/whiskers, maar dan veel simpeler: lichte lijn tussen min en max, met avg als point hierop.
# of toch iets met smoothing.

qplot(psx_timestamp, val2, data=graphdata, geom="smooth", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))

qplot(x=psx_timestamp, y=val2, data=graphdata, geom="smooth", xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))

qplot(x=psx_timestamp, y=val2, data=graphdata, geom=c("point", "smooth"), xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))
  
qplot(x=psx_timestamp, y=val2, data=graphdata, geom=c("point"), xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))

qplot(psx_timestamp, val2, data=graphdata, geom=c("point"), xlab="Time", ylab="Resource usage") +
  opts(title = wrapper(graph_title, width = 80)) +
  scale_x_datetime(format = gsub(" ", "\n", datetime_format))
  
plot(tscut, value, data=resusage, geom=c("point", "smooth"))
# deze doet het wel! maar is vrij meaningless.

ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), length.out=length(graphdata$psx_timestamp))
graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")


resusage = ddply(graphdata, .(tscut), function (df) {
  c(value=mean(df[[2]]))
})

plot(tscut, mean, data=resusage, geom=c("point", "smooth"))

> plot(tscut, mean, data=resusage)
Error in plot(tscut, mean, data = resusage) : object 'tscut' not found
> str(head(resusage))
'data.frame':	6 obs. of  2 variables:
 $ tscut: POSIXct, format: "2011-08-29 00:10:01" "2011-08-29 00:22:57" ...
 $ mean : num  1.1 0.99 1.15 0.985 2.81 ...

plot(resusage$tscut, resusage$mean)
# doet het dus wel

> plot(tscut, value, data=resusage)
not

plot(resusage$tscut, value, data=resusage)
moet je wel qplot gebruiken!

qplot(tscut, value, data=resusage, geom=c("point", "smooth"))

# ok deze doet het, maar zegt me niet zo veel.

# met qplot nog even de graphdata

qplot(psx_timestamp, val2, data=graphdata)

Error in if (length(range) == 1 || diff(range) == 0) { : 
  missing value where TRUE/FALSE needed

# vage dingen dus, lijkt dat ik beter altijd eerst ddply kan doen, ook al wil ik gewoon de waarden houden.

