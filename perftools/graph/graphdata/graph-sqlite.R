# Make plot from typeperf data

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

# @todo for now constants, need to read from cmdline.
show_minmax = 0
use_ggplot = 1 # only for single lines now.

# Add own functions at the top.
# idx: 2..ncolumns
det_scale_factor = function(idx) {
   # mx = max(100, max(graphdata[[idx]], na.rm=TRUE))
   mx = max(graphdata[[idx]], na.rm=TRUE)
   if (mx <= 0) {
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

print(commandArgs())

# datetime_format = "%d-%m-%y %H:%M:%S"
# datetime_format = "%d-%m-%Y %H:%M:%S"

db = dbConnect(dbDriver("SQLite"), db_name)
# datetime_format = dbGetQuery(db, paste("select datetimeformat from columndef where tabname='", datetime_table, "' and isdatetime = 1", sep=""))
# datetime_format = dbGetQuery(db, paste("select datetimeformat from columndef where tabname='", datetime_table, "' and isdatetime = 1", sep=""))$datetimeformat

# 7-9-2011 NdV datetime_format waarde bevat het oorspronkelijke formaat in de flatfile, in de sqlite.db is alles naar std formaat gezet.
datetime_format = "%Y-%m-%d %H:%M:%S"

# graphdata <- read.csv(db_name, header=T, sep="\t")
graphdata = dbGetQuery(db, data_query)

# legend_data <- read.csv(legend_query, header=T, sep="\t")
legend_data = dbGetQuery(db, legend_query)

# op win2003 kan blijkbaar lege regel (als 2e, direct na de header) voorkomen
# graphdata = subset(graphdata ,subset=(!is.na(graphdata[2])))

#print(graphdata[2])

#print(summary(graphdata))

# psx_timestamp = strptime(graphdata[[1]], format="%H:%M")


psx_timestamp = strptime(graphdata[[1]], format=datetime_format)
print(5)
print(summary(graphdata[[1]]))

# niet te veel points, anders melding dat x en y lengths differ
npoints = min(npoints_max, length(graphdata[[2]]))

print(6)
print(warnings())

ncolumns = length(graphdata)
nlines = ncolumns - 1 ; # graph lines, not lines in 'datafile'

png(filename=graphfile_name, width = 1024, height = 768)

# divide data in chunks for plotting.
print(8)
print(summary(psx_timestamp))
seq_timestamp = seq(from=min(psx_timestamp, na.rm=TRUE), to=max(psx_timestamp, na.rm=TRUE), length.out=npoints)
print(9)
print(warnings())

cut_timestamp = cut(psx_timestamp, seq_timestamp)

print(10)

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

# min y = -0.25 * max, room voor legend
# @todo still too much double code, try if within an expression?
if (scale == 1) {
  plot(c(min(seq_timestamp, na.rm=TRUE), max(seq_timestamp, na.rm=TRUE)),
    c(-0.25 * usage.max, usage.max),
    # main = paste("Server resource usage on: ", machine_name,sep=""),
    # main = datafile_name,
    main = strwrap(graph_title, width=100),
    xlab="date/time",
    ylab="data (scaled)",
    type="n",
    xaxt="n")
} else {
  plot(c(min(seq_timestamp, na.rm=TRUE), max(seq_timestamp, na.rm=TRUE)),
    c(-0.25 * usage.max, usage.max),
    main = strwrap(graph_title, width=100),
    xlab="date/time",
    ylab="data",
    type="n",
    xaxt="n")
}

print(12)
print(warnings())

# 2. labels apart toevoegen. (axis.date werkt niet goed).
# axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format="%H:%M")
# @todo replace space with newline.

# headers = gsub(".*(Percentage.*)", "\\1", headers)
# axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format=datetime_format)
axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format=gsub(" ", "\n", datetime_format))

# legend.labels = headers[2:ncolumns]
legend.labels = legend_data[[1]]
# remove first label: timestamp
legend.labels = legend.labels[2:length(legend.labels)]
if (scale == 1) {
  legend.labels = sapply(1:length(legend.labels), add_scale)
}

print(legend.labels)
print(warnings())

# legend.labels
legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 2)

# if only one data column, plot the mean, min and max values.
if (ncolumns == 2) {
    if (scale == 1) {
      fct = det_scale_factor(2)
    } else {
      fct = 1.0 
    }
    print(13)
    print(warnings())
    mean_counter = tapply(graphdata[[2]], cut_timestamp, mean, na.rm=TRUE)
    print(14)
    print(warnings())
    lines(seq_timestamp[-length(seq_timestamp)], mean_counter / fct, type="p", col = 1, pch = 1)
    min_counter = tapply(graphdata[[2]], cut_timestamp, min, na.rm=TRUE)
    print(15)
    print(warnings())
    lines(seq_timestamp[-length(seq_timestamp)], min_counter / fct, type="p", col = 2, pch = 2)
    print(16)
    print(warnings())
    max_counter = tapply(graphdata[[2]], cut_timestamp, max, na.rm=TRUE)
    lines(seq_timestamp[-length(seq_timestamp)], max_counter / fct, type="p", col = 3, pch = 3)
    print(17)
    print(warnings())
} else {
  for(i in 2:ncolumns) {
    # mean_counter = tapply(graphdata[[i]], cut_timestamp, mean)
    # 10-8-2011 na.rm needed for big datasets with many NA's (eg. TK/VLOS)
    mean_counter = tapply(graphdata[[i]], cut_timestamp, mean, na.rm=TRUE)
    if (scale == 1) {
      fct = det_scale_factor(i)
    } else {
      fct = 1.0 
    }
    lines(seq_timestamp[-length(seq_timestamp)],
      mean_counter / fct,
      type="p",
      col = i-1,
      pch = i-1)
  }
  print(18)
  print(warnings())
}

print(20)
print(warnings())

d = dev.off() # close png

print(warnings())

print(999)

# bla # to generate a failure

