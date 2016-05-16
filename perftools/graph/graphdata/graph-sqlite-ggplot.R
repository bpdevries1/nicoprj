# Make plot from typeperf data

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

# @todo for now constants, need to read from cmdline.
show_minmax = 0
use_ggplot = 1 # only for single lines now.

# Add own functions at the top.
# idx: 2..ncolumns
det_scale_factor = function(idx) {
   # mx = max(100, max(graphdata[[idx]], na.rm=TRUE))
   mx = max(graphdata[[idx]], na.rm=TRUE)
   if (mx < 0) {
     1 
   } else {
     # mx = mean(graphdata[[idx]], na.rm=TRUE)
     # afronden naar boven op een macht van 10 (10, 100, 1000)
     mx = 10^(ceiling(log10(mx)))
     if (mx <= 100) {
       1 
     } else {
       mx / 100 
     }
   }
}

# idx: 1..length(labels)
add_scale = function(idx) {
	# mx = max(100, max(graphdata[[idx+1]], na.rm=TRUE))
	# fct = mx / 100
  fct = det_scale_factor(idx+1)
	if (fct == 1) {
		str = paste(legend.labels[idx],sep="")
	} else {
		str = paste(legend.labels[idx]," (*",format(fct, digits=2),")",sep="")
	}
	str
}

# TODO:
# * more than 1 line, based on more than 1 columns (eg. 1 line for each extra column after first time column)

# for biomet test
#datafile_name = "db-req-time.tsv";
#npoints_max = 200;
#legend_name = "db-req-time.tsv.legend";

# test
if (FALSE) {
  db_name = "sar.db"
  data_query = "select meas_time, val2 from sar"
}


# @todo queries could get big, maybe use a file instead of cmdline. 
# Could also use a query table and give the name of the query. Query table then has a name and query field. 
idx = 6; # first index of user parameter.
db_name = commandArgs()[idx];                 idx=idx+1;  
data_query = commandArgs()[idx];              idx=idx+1;
npoints_max = as.integer(commandArgs()[idx]); idx=idx+1;  # geeft max aantal te plotten points.
legend_query = commandArgs()[idx];            idx=idx+1; 
datetime_table = commandArgs()[idx];         idx=idx+1;
graphfile_name = commandArgs()[idx];          idx=idx+1; 
scale = as.integer(commandArgs()[idx]);       idx=idx+1;  # 1=scale, 0=noscale
graph_title = commandArgs()[idx];             idx=idx+1;

db = dbConnect(dbDriver("SQLite"), db_name)

# 7-9-2011 NdV datetime_format waarde bevat het oorspronkelijke formaat in de flatfile, in de sqlite.db is alles naar std formaat gezet.
datetime_format = "%Y-%m-%d %H:%M:%S"

graphdata = dbGetQuery(db, data_query)
legend_data = dbGetQuery(db, legend_query)

ncolumns = length(graphdata)
nlines = ncolumns - 1 ; # graph lines, not lines in 'datafile'
npoints = min(npoints_max, length(graphdata[[2]]))

# psx_timestamp = strptime(graphdata[[1]], format=datetime_format)
graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
# seq_timestamp = seq(from=min(psx_timestamp, na.rm=TRUE), to=max(psx_timestamp, na.rm=TRUE), length.out=npoints)
# cut_timestamp = cut(psx_timestamp, seq_timestamp)
ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), length.out=npoints)
graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")

resusage = ddply(graphdata, .(tscut), function (df) {
  # c(min = min(graphdata[[2]], na.rm = TRUE), avg = mean(graphdata[[2]], na.rm = TRUE), max = max(graphdata[[2]], na.rm = TRUE))
  # with the above, need to do a melt, should be possible in one go.
  data.frame(stattype = c('min', 'avg', 'max'),  
    value = c(min(graphdata[[2]], na.rm = TRUE), mean(graphdata[[2]], na.rm = TRUE), max(graphdata[[2]], na.rm = TRUE)))
})

# det max usage, but use a minimum in graph of 100.
# 20110701 NdV in these graphs only one line, so no scaling.
# 23-7-2011 NdV want max over all columns
# max can be less than 100, for unscaled graph.
# usage.max = max(100, max(graphdata[2], na.rm=TRUE))
print(scale)

if (scale == 1) {
  usage.max = 100 
} else {
  usage.max = max(graphdata[2:length(graphdata)], na.rm=TRUE)
}
# 30-7-2011 NdV data columns are strings in the sqlite db, convert to numbers
# as.double on a dataframe does not work, it works on a vector.
# usage.max = max(as.double(graphdata[2:length(graphdata)]), na.rm=TRUE)

print(usage.max)
print(11)

det_scale_x_datetime_old = function () {
  # scale_x_datetime(format = "%H:%M:%S", minor="5 min")
  # @todo vraag of minor=5 min in de weg gaat zitten.
  scale_x_datetime(format = gsub(" ", "\n", datetime_format), minor="5 min")
}


# mean_counter = tapply(graphdata[[2]], cut_timestamp, mean, na.rm=TRUE)

wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")

#my_title <- "This is a really long title of a plot that I want to nicely wrap and fit onto the plot without having to manually add the backslash n, but at the moment it does not"
#r + geom_smooth() + opts(title = wrapper(my_title, width = 20))
# geom_smooth: extra smooth lines om de punten heen, wil ik hier niet.

# qplot(seq_timestamp[-length(seq_timestamp)], mean_counter, geom="point", xlab="date/time", ylab="data", ylim=c(0, usage.max)) +
#   opts(legend.position="none", legend.justification = c(0, 1)) + 
#   # det_scale_x_datetime() +
#   scale_x_datetime(format = gsub(" ", "\n", datetime_format)) +
#   scale_shape_manual(value=0:25) +
#   opts(title = wrapper(graph_title, width = 80))

# qplot(tscut, value, data=resusage, geom="point", colour=resusage$stattype, shape=resusage$stattype, main=paste("Resource usage (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
qplot(tscut, value, data=resusage, geom="point", colour=stattype, shape=stattype, xlab="Time", ylab="Resource usage") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
  opts(title = wrapper(graph_title, width = 80))
  
  # scale_y_continuous(limits=c(0, 3.5)) +
  # labs(colour = group.by, shape = group.by)


# size will be 1100x900: 11 inch * 100 dots-per-inch
ggsave(filename=graphfile_name, width=11, height=9, dpi=100)

# bla # to generate a failure

