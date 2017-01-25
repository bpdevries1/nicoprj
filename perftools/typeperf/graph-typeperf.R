# Make plot from typeperf data

# TODO:
# * more than 1 line, based on more than 1 columns (eg. 1 line for each extra column after first time column)

# typeperf_name = "d:\\perftoolset\\toolset\\cruise\\checkout\\script\\servers\\test\\typeperf.csv"
# typeperf_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv"
# typeperf_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv.orig"
# legend_name = "c:\\aaa\\typeperf\\T24\\ba13-0306-typeperf.csv.legend"
# npoints_max = 40
# machine_name = "mach1"
typeperf_name = commandArgs()[6] # geeft de eerste, via rterm.exe etc.
npoints_max = as.integer(commandArgs()[7]) # geeft max aantal te plotten points.
legend_name = commandArgs()[8]
# startend_name = commandArgs()[9]
machine_name = commandArgs()[9]

typeperf_name = "C:/PCC/Nico/aaa/dms-typeperf/wsrv4275.csv"
npoints_max = 40
legend_name = "C:/PCC/Nico/aaa/dms-typeperf/wsrv4275.csv.legend"
# startend_name = commandArgs()[9]
machine_name = "wsrv4275"



typeperf_data <- read.csv(typeperf_name, header=T, sep=",")

legend_data <- read.csv(legend_name, header=T, sep=",")

# op win2003 kan blijkbaar lege regel (als 2e, direct na de header) voorkomen
typeperf_data = subset(typeperf_data ,subset=(!is.na(typeperf_data[2])))

#print(typeperf_data[2])

#print(summary(typeperf_data))

psx_timestamp = strptime(typeperf_data[[1]], format="%m/%d/%Y %H:%M:%S")

# niet te veel points, anders melding dat x en y lengths differ
npoints = min(npoints_max, length(typeperf_data[[2]]))

ncolumns = length(typeperf_data)
nlines = ncolumns - 1

# headers dan in headers[i], i in 1:4
# headers = typeperf_data[0,]
headers = names(typeperf_data)
headers = gsub(".*(Percentage.*)", "\\1", headers) ; # if header contains Percentage, only text including and after this will be shown.
# headers = gsub(".*(%.*)", "\\1", headers) ; # if header contains %, only text including and after this will be shown.
# kan niet op % zoeken, deze al vervangen door . (punt)
# \\S1123\Processor(_Total)\% Processor Time
headers = gsub(".*[.]+([^.]+.Time)", "\\1", headers) ; # if header contains Percentage, only text including and after this will be shown.

# png(filename=paste(typeperf_name, ".png",sep=""), width = 640, height = 480) 
png(filename=paste(typeperf_name, ".png",sep=""), width = 1024, height = 768)

# divide data in chunks for plotting.
seq_timestamp = seq(from=min(psx_timestamp), to=max(psx_timestamp), length.out=npoints)
cut_timestamp = cut(psx_timestamp, seq_timestamp)

# det max usage, but use a minimum in graph of 100.
# usage.max = max(100, max(typeperf_data[2]))
# kolom 2 was de logical disk, maar nu netwerk verkeer, dus andere max.
# usage.max = max(100, max(typeperf_data[3]))
usage.max = 100

# print(usage.max)

# min y = -0.25 * max, room voor legend
plot(c(min(seq_timestamp), max(seq_timestamp)),
	c(-0.25 * usage.max, usage.max),
	main = paste("Server resource usage on: ", machine_name,sep=""),
	xlab="time",
	ylab="resource usage (%)",
 	type="n",
	xaxt="n")

# 2. labels apart toevoegen. (axis.date werkt niet goed).
axis.POSIXct(1, at=seq_timestamp[-length(seq_timestamp)], format="%d-%m\n%H:%M")

# idx: 2..ncolumns
det_scale_factor = function(idx) {
   # mx = max(100, max(typeperf_data[[idx]], na.rm=TRUE))
   mx = max(typeperf_data[[idx]], na.rm=TRUE)
   # mx = mean(typeperf_data[[idx]], na.rm=TRUE)
   # afronden naar boven op een macht van 10 (10, 100, 1000)
   mx = 10^(ceiling(log10(mx)))
   if (mx <= 100) {
     1 
   } else {
     mx / 100 
   }
}

# idx: 1..length(labels)
add_scale = function(idx) {
	# mx = max(100, max(typeperf_data[[idx+1]], na.rm=TRUE))
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

# [2017-01-25 14:25:24] even weg.
# legend.labels = sapply(1:length(legend.labels), add_scale)

# legend.labels
legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 2)
# 19-3-2009 NdV grote labels, dus maar 1 kolom.
# 19-3-2009 NdV mogelijk
# legend("bottom", legend=legend.labels, col=1:nlines, pch = 1:nlines, cex = 0.8, ncol = 1)

# for(i in 2:ncolumns) {
# 	mean_counter = tapply(typeperf_data[[i]], cut_timestamp, mean)
# 	max.i = max(100, max(typeperf_data[i], na.rm=TRUE))
# 	lines(seq_timestamp[-length(seq_timestamp)],
# 		mean_counter * (100 / max.i),
# 		type="o",
# 		col = i-1,
# 		pch = i-1)
# }

for(i in 2:ncolumns) {
	mean_counter = tapply(typeperf_data[[i]], cut_timestamp, mean)
	fct = det_scale_factor(i)
  # max.i = max(100, max(typeperf_data[i], na.rm=TRUE))
	lines(seq_timestamp[-length(seq_timestamp)],
		mean_counter / fct,
		type="o",
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

