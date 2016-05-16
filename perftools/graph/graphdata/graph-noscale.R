# Make plot from typeperf data

# TODO:
# * more than 1 line, based on more than 1 columns (eg. 1 line for each extra column after first time column)

# for biomet test
datafile_name = "db-req-time.tsv";
npoints_max = 200;
legend_name = "db-req-time.tsv.legend";

datafile_name = commandArgs()[6] # geeft de eerste, via rterm.exe etc.
npoints_max = as.integer(commandArgs()[7]) # geeft max aantal te plotten points.
legend_name = commandArgs()[8]
# startend_name = commandArgs()[9]
datetime_format = commandArgs()[9]
graphfile_name = commandArgs()[10]

graphdata <- read.csv(datafile_name, header=T, sep="\t")

# legend_data <- read.csv(legend_name, header=T, sep="\t")$legend
legend_data <- read.csv(legend_name, header=T, sep="\t")

# op win2003 kan blijkbaar lege regel (als 2e, direct na de header) voorkomen
# graphdata = subset(graphdata ,subset=(!is.na(graphdata[2])))

#print(graphdata[2])

#print(summary(graphdata))

# psx_timestamp = strptime(graphdata[[1]], format="%H:%M")
psx_timestamp = strptime(graphdata[[1]], format=datetime_format)

print(5)

# niet te veel points, anders melding dat x en y lengths differ
npoints = min(npoints_max, length(graphdata[[2]]))

print(6)

ncolumns = length(graphdata)
nlines = ncolumns - 1

# png(filename=paste(datafile_name, ".png",sep=""), width = 640, height = 480) 
# png(filename=paste(datafile_name, ".png",sep=""), width = 1024, height = 768)
png(filename=graphfile_name, width = 1024, height = 768)

# divide data in chunks for plotting.
print(8)
# seq_timestamp = seq(from=min(psx_timestamp), to=max(psx_timestamp), length.out=npoints)
seq_timestamp = seq(from=min(psx_timestamp, na.rm=TRUE), to=max(psx_timestamp, na.rm=TRUE), length.out=npoints)
print(9)

cut_timestamp = cut(psx_timestamp, seq_timestamp)

print(10)

# det max usage, but use a minimum in graph of 100.
# 20110701 NdV in these graphs only one line, so no scaling.
# 23-7-2011 NdV want max over all columns
# max can be less than 100, for unscaled graph.
# usage.max = max(100, max(graphdata[2], na.rm=TRUE))
usage.max = max(graphdata[2:length(graphdata)], na.rm=TRUE)

print(usage.max)
print(11)
# kolom 2 was de logical disk, maar nu netwerk verkeer, dus andere max.
# usage.max = max(100, max(graphdata[3]))
# usage.max = 100

# print(usage.max)

# min y = -0.25 * max, room voor legend
plot(c(min(seq_timestamp), max(seq_timestamp)),
	c(-0.25 * usage.max, usage.max),
	# main = paste("Server resource usage on: ", machine_name,sep=""),
	# main = datafile_name, # @todo split the name with newlines if it is too big. wordwrap
	main = strwrap(datafile_name, width=100),
	xlab="date/time",
	ylab="data",
 	type="n",
	xaxt="n")

# 2. labels apart toevoegen. (axis.date werkt niet goed).
# axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format="%H:%M")
axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format=datetime_format)


# legend.labels = headers[2:ncolumns]
legend.labels = legend_data[[1]]
# remove first label: timestamp
legend.labels = legend.labels[2:length(legend.labels)]
print(legend.labels)

# legend.labels
legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 2)

for(i in 2:ncolumns) {
	mean_counter = tapply(graphdata[[i]], cut_timestamp, mean)
  lines(seq_timestamp[-length(seq_timestamp)],
		mean_counter,
		type="p",
		col = i-1,
		pch = i-1)
}

d = dev.off() # close png

