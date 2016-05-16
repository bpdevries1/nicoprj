# Make plot from typeperf data

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

print("setting options(error = recover)")
options(error = recover)

# for testing
if (FALSE) {
  db_name = "sar.db"
  data_query = "select meas_time, val2 from sar"
  npoints_max = 200
  # legend_query = commandArgs()[idx];            idx=idx+1; 
  datetime_table = "sar"
  graphfile_name = "sar-graphs/val2.png" 
  scale = 0
  graph_title = "Val2 resource usage"
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
# @todo use the legend_data for the axes.
# legend_data = dbGetQuery(db, legend_query)

ncolumns = length(graphdata)
nlines = ncolumns - 1 ; # graph lines, not lines in 'datafile'
npoints = min(npoints_max, length(graphdata[[2]]))

graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), length.out=npoints)
graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")

resusage = ddply(graphdata, .(tscut), function (df) {
  data.frame(stattype = c('min', 'avg', 'max'),  
    value = c(min(df[[2]], na.rm = TRUE), mean(df[[2]], na.rm = TRUE), max(df[[2]], na.rm = TRUE)))
})

wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")

qplot(tscut, value, data=resusage, geom="point", colour=stattype, shape=stattype, xlab="Time", ylab="Resource usage") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
  opts(title = wrapper(graph_title, width = 80))

# size will be 1100x900: 11 inch * 100 dots-per-inch
ggsave(filename=graphfile_name, width=11, height=9, dpi=100)

# bla # to generate a failure

