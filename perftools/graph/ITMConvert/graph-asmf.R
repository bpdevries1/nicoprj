main = function() {

	str_start = commandArgs()[6]
	str_end = commandArgs()[7]
	psx_start = strptime(str_start, format="%Y%m%d-%H%M%S",tz="Eur1")
	psx_end = strptime(str_end, format="%Y%m%d-%H%M%S",tz="Eur1")
	
	Y.max = 100 ; # maximaal MSU

	# Algemene graph dingen
	output.base = commandArgs()[8]
	png_filename = paste(output.base,"-",str_start,"-",str_end,".png", sep="")
	png(filename=png_filename, width = 1500, height = 1100) 
	 
	plot(c(psx_start, psx_end),
		c(-0.1 * Y.max, Y.max),
		# c(0.0001, Y.max),
		main="Performance tests and Resource usage",
		xlab="Timestamp",
		ylab="MSU",
		type="n", 
		xaxt="n"
		#,log="y"
	) 
	
	# legend.titles = c("TotC", "TotE","ActualMSU", "WLM Softcap", "JMeter test", "WL.Total", "WL.Monitor", "WL.Monitor+Broker")
	# legend.titles = c("JMeter test", "ActualMSU", "WLM Softcap","WL.Total", "WL.Broker", "WL.Broker + WL.Monitor", "TotC", "TotE", "ITM.MSU")
	legend.titles = c("JMeter test", "ActualMSU", "WLM Softcap","WL.Total", "WL.Broker", "WL.Broker + WL.Monitor", "ITM.MSU")
	# kleur 7 is lichtgeel, moeilijk te zien.
	legend.colours = c(1,2,3,4,5,6,8,9,10,11)[1:length(legend.titles)]

	legend("bottom", legend.titles, col=legend.colours, pch = 1:length(legend.titles), cex = 0.8, ncol = min(length(legend.titles), 8))
	
	# td1: time difference of 1 hour, minimum for time-sequence.
	td1 = difftime(strptime("12:00:00", format="%H:%M:%S"), strptime("11:00:00", format="%H:%M:%S"), units="hours")
	npoints = 35
	by_hours = max(td1, round( difftime(psx_end, psx_start, units="hours") / npoints ))
	seq_axis_timestamp = seq(trunc(psx_start, "hour"), trunc(psx_end, "hour"), by = by_hours)

	axis.POSIXct(1, at=seq_axis_timestamp, format="%d-%m\n%H:%M")
	axis(2, at=seq(0, 100, 10))
	
	abline(h=seq(0, 100, 10), col = "lightgray", lty=3) ; # horizontal grid lines
	abline(v=seq_axis_timestamp, col = "lightgray", lty=3) ; # vertical grid lines on whole hours.
	
	col_v = 1
	col_v = draw.jmeterdata(11, col_v, legend.colours, psx_start, psx_end, npoints)
	col_v = draw.msudata(10, col_v, legend.colours)
	col_v = draw.workloaddata(12, col_v, legend.colours)
	col_v = draw.itmdata(9, col_v, legend.colours, psx_start, psx_end)
	# Aan het einde, png afsluiten.
	d = dev.off() # close png
}

draw.itmdata = function(i_arg, col_v, legend.colours, psx_start, psx_end) {
	MSU_TOTAL = 170; # 170 MSU te leveren door 2 CPU's.
	
	input_filename = commandArgs()[i_arg] # geeft de eerste, via rterm.exe etc.
	itmdata = read.csv(input_filename, header=T, sep="\t")
	attach(itmdata)
	
	# psx_timestamp = strptime(timestamp, format="%Y%m%d-%H%M%S",tz="Eur1")
	psx_timestamp_writetime = strptime(TIMESTAMP_WRITETIME, format="%Y%m%d-%H%M%S",tz="Eur1")
	psx_timestamp_end = strptime(TIMESTAMP_END, format="%Y%m%d-%H%M%S",tz="Eur1")
	psx_timestamp_start = strptime(TIMESTAMP_START, format="%Y%m%d-%H%M%S",tz="Eur1")
	runtime = difftime(psx_timestamp_end, psx_timestamp_start, units = "secs");
	MSU = (TOTC / as.numeric(runtime)) * MSU_TOTAL
	
	# normaliseren tot max 100, alleen voor periode dat geplot wordt.
	
	totc.max = max(TOTC[!is.na(TOTC) & (psx_timestamp_writetime > psx_start) & (psx_timestamp_writetime < psx_end)])
	totc.factor = 100.0 / totc.max
	TOTC = TOTC * totc.factor
	TOTE = 100.0 * TOTE / max(TOTE[!is.na(TOTE) & (psx_timestamp_writetime > psx_start) & (psx_timestamp_writetime < psx_end)])
	
	# lines(psx_timestamp_writetime, TOTC, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	# lines(psx_timestamp_writetime, TOTE, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp_writetime, MSU, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	
	detach(itmdata)
	# print("itmdata: end")
	col_v
}

draw.msudata = function(i_arg, col_v, legend.colours) {
	# print("msudata: start")
	# Hier verder met MSU data
	input_filename = commandArgs()[i_arg] 
	msudata = read.csv(input_filename, header=T, sep="\t", dec=",")
	# summary(msudata)
	attach(msudata)
	psx_timestamp = strptime(Time, format="%m/%d/%Y-%H.%M.%S",tz="Eur1")
	
	#length(psx_timestamp2)
	#psx_timestamp2
	#length(Actual.MSUs)
	lines(psx_timestamp, Actual.MSUs, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp, WLM.Soft.Capping..Y2.Axis., type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	detach(msudata)
	# print("msudata: end")
	col_v
}

draw.jmeterdata = function(i_arg, col_v, legend.colours, psx_start, psx_end, npoints) {

	# Hier verder met JMeter start- en stoptijden, overzich in results2008.3
	input_filename = commandArgs()[i_arg] 
	jmdata = read.csv(input_filename, header=T, sep=",", dec=".")
	# summary(jmdata)
	attach(jmdata)
	# 2008-10-17 16:02:04
	psx.jmstart = strptime(jmeter_startdatetime, format="%Y-%m-%d %H:%M:%S",tz="Eur1")
	psx.jmend = strptime(jmeter_enddatetime, format="%Y-%m-%d %H:%M:%S",tz="Eur1")
	seq.jmtimes = seq(psx_start, psx_end, length.out=npoints*20)
	
	ntests.function = function(psx.tsparam) {
		# Allemaal wat onhandig: sum en subset(1, ..) niet te gebruiken.
		# Rechtstreeks length(ss) levert 9 op, waarschijnlijk 9 velden in een posix timestamp
		# Versie in servtimes.R werkt wel, omdat deze msec gebruikt, gewoon een integer, geen datetime
		ss = subset(psx.jmstart, subset=((psx.jmstart <= psx.tsparam) & (psx.tsparam <= psx.jmend)))
		str.ss = format(ss, format="%Y-%m-%d %H:%M:%S")
		length(str.ss)	
	}
	
	ntests = sapply(seq.jmtimes, ntests.function)
	
	lines(seq.jmtimes, ntests * 100, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	
	col_v
}

draw.workloaddata = function(i_arg, col_v, legend.colours) {
	# print("msudata: start")
	# Hier verder met MSU data
	input_filename = commandArgs()[i_arg] 
	workloaddata = read.csv(input_filename, header=T, sep="\t", dec=".")
	# print(summary(workloaddata))
	attach(workloaddata)
	psx_timestamp = strptime(DATETIME, format="%d-%m-%Y-%H:%M",tz="Eur1")
	
	#length(psx_timestamp2)
	#psx_timestamp2
	#length(Actual.MSUs)
	
	# vreen00, 27-11-08: kolommen met _R zijn dubbelop, dus verwijderd uit waarden. Factor 8.09 zou nu weer moeten kloppen.
	MSU_FACTOR = 8.09 ; # obv gegevens Michael Kok.
	# MSU_FACTOR = 16.0
	
	lines(psx_timestamp, TOTAL / MSU_FACTOR, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp, BROKER / MSU_FACTOR, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp, (MONITOR + BROKER) / MSU_FACTOR, type="l", col=legend.colours[col_v], pch=col_v) ; col_v = col_v + 1

	# plot(psx_timestamp, TOTAL / MSU_FACTOR)

	detach(workloaddata)
	# print("msudata: end")
	col_v
}


main()
