# Make plot from typeperf data

# TODO:
# * more than 1 line, based on more than 1 columns (eg. 1 line for each extra column after first time column)

# datafile_name = "d:\\perftoolset\\toolset\\cruise\\checkout\\script\\servers\\test\\typeperf.csv"
# datafile_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv"
# datafile_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv.orig"
# legend_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv.legend"
# npoints_max = 40
# machine_name = "mach1"

# for biomet test
datafile_name = "pkts.tsv";
npoints_max = 200;
legend_name = "pkts.tsv.legend";
datetime_format = "%H:%M";
graph_filename = "pkts.png";
# machine_name = "machine";

datafile_name = commandArgs()[6] # geeft de eerste, via rterm.exe etc.
npoints_max = as.integer(commandArgs()[7]) # geeft max aantal te plotten points.
legend_name = commandArgs()[8]
# startend_name = commandArgs()[9]
# machine_name = commandArgs()[9]
datetime_format = commandArgs()[9]
graph_filename = commandArgs()[10]

graphdata <- read.csv(datafile_name, header=T, sep="\t")

legend_data <- read.csv(legend_name, header=T, sep="\t")

# op win2003 kan blijkbaar lege regel (als 2e, direct na de header) voorkomen
# 9-7-2011 nu alles behouden.
# graphdata = subset(graphdata ,subset=(!is.na(graphdata[2])))

#print(graphdata[2])

print(summary(graphdata))

# psx_timestamp = strptime(graphdata[[1]], format="%H:%M")
psx_timestamp = strptime(graphdata[[1]], format=datetime_format)
print("psx_timestamp summary:");
print(summary(psx_timestamp))
print("datatime_format:");
print(datetime_format);

# niet te veel points, anders melding dat x en y lengths differ
npoints = min(npoints_max, length(graphdata[[2]]))

print(5);

ncolumns = length(graphdata)
nlines = ncolumns - 1

# headers dan in headers[i], i in 1:4
# headers = graphdata[0,]
headers = names(graphdata)
headers = gsub(".*(Percentage.*)", "\\1", headers) ; # if header contains Percentage, only text including and after this will be shown.
# headers = gsub(".*(%.*)", "\\1", headers) ; # if header contains %, only text including and after this will be shown.
# kan niet op % zoeken, deze al vervangen door . (punt)
# \\S1123\Processor(_Total)\% Processor Time
headers = gsub(".*[.]+([^.]+.Time)", "\\1", headers) ; # if header contains Percentage, only text including and after this will be shown.

print(6);

# png(filename=paste(datafile_name, ".png",sep=""), width = 640, height = 480) 
# png(filename=paste(datafile_name, ".png",sep=""), width = 1024, height = 768)
png(filename=graph_filename, width = 1024, height = 768)

print(7);


# divide data in chunks for plotting.

print(8);
seq_timestamp = seq(from=min(psx_timestamp, na.rm=TRUE), to=max(psx_timestamp, na.rm=TRUE), length.out=npoints)
print(9);
cut_timestamp = cut(psx_timestamp, seq_timestamp)
print(10);
# det max usage, but use a minimum in graph of 100.
# usage.max = max(100, max(graphdata[2]))
# kolom 2 was de logical disk, maar nu netwerk verkeer, dus andere max.
# usage.max = max(100, max(graphdata[3]))
usage.max = 100

# print(usage.max)

print(11);

# min y = -0.25 * max, room voor legend
plot(c(min(seq_timestamp), max(seq_timestamp)),
	c(-0.25 * usage.max, usage.max),
	# main = paste("Server resource usage on: ", machine_name,sep=""),
	# main = datafile_name,
	main = strwrap(datafile_name, width=100),
	xlab="date/time",
	ylab="data (scaled)",
 	type="n",
	xaxt="n")

# 2. labels apart toevoegen. (axis.date werkt niet goed).
# axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format="%d-%m\n%H:%M")
axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format=datetime_format)

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

# legend.labels = headers[2:ncolumns]
legend.labels = legend_data[[1]]
# remove first label: timestamp
legend.labels = legend.labels[2:length(legend.labels)]

print(20);
legend.labels = sapply(1:length(legend.labels), add_scale)
print(21);

# legend.labels
legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 2)
# 19-3-2009 NdV grote labels, dus maar 1 kolom.
# 19-3-2009 NdV mogelijk
# legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 1)

# for(i in 2:ncolumns) {
# 	mean_counter = tapply(graphdata[[i]], cut_timestamp, mean)
# 	max.i = max(100, max(graphdata[i], na.rm=TRUE))
# 	lines(seq_timestamp[-length(seq_timestamp)],
# 		mean_counter * (100 / max.i),
# 		type="o",
# 		col = i-1,
# 		pch = i-1)
# }

for(i in 2:ncolumns) {
	mean_counter = tapply(graphdata[[i]], cut_timestamp, mean)
	fct = det_scale_factor(i)
  # max.i = max(100, max(graphdata[i], na.rm=TRUE))
	# lines(seq_timestamp[-length(seq_timestamp)],
  lines(seq_timestamp[-length(seq_timestamp)],
		mean_counter / fct,
		type="p",
		col = i-1,
		pch = i-1)
}


# startend erbij als 2 verticale lijnen, niet echt een legenda hiervoor nodig.
# 23-03-2009-15:04:09	100
#startend_data <- read.csv(startend_name, header=T, sep=",")
#se.psx_timestamp = strptime(startend_data[[1]], format="%d-%m-%Y-%H:%M:%S")
#print(se.psx_timestamp)
#print(startend_data[[2]])

#lines(se.psx_timestamp, startend_data[[2]], type="h", col=ncolumns)

d = dev.off() # close png

