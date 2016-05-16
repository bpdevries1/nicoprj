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
	
	legend("bottom", c("TotC", "TotE","ActualMSU", "WLM Softcap", "JMeter test"), col=1:5, pch = 1:5, cex = 0.8, ncol = 5)
	
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
	col_v = draw.itmdata(9, col_v, psx_start, psx_end)
	col_v = draw.msudata(10, col_v)
	col_v = draw.jmeterdata(11, col_v, psx_start, psx_end, npoints)
	
	# Aan het einde, png afsluiten.
	d = dev.off() # close png
}

draw.itmdata = function(i_arg, col_v, psx_start, psx_end) {
	input_filename = commandArgs()[i_arg] # geeft de eerste, via rterm.exe etc.
	itmdata = read.csv(input_filename, header=T, sep="\t")
	attach(itmdata)
	
	psx_timestamp = strptime(timestamp, format="%Y%m%d-%H%M%S",tz="Eur1")
	
	# normaliseren tot max 100, alleen voor periode dat geplot wordt.
	
	totc.max = max(TOTC[!is.na(TOTC) & (psx_timestamp > psx_start) & (psx_timestamp < psx_end)])
	totc.factor = 100.0 / totc.max
	TOTC = TOTC * totc.factor
	TOTE = 100.0 * TOTE / max(TOTE[!is.na(TOTE) & (psx_timestamp > psx_start) & (psx_timestamp < psx_end)])
	
	lines(psx_timestamp, TOTC, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp, TOTE, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	
	detach(itmdata)
	# print("itmdata: end")
	col_v
}

draw.msudata = function(i_arg, col_v) {
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
	lines(psx_timestamp, Actual.MSUs, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	lines(psx_timestamp, WLM.Soft.Capping..Y2.Axis., type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	detach(msudata)
	# print("msudata: end")
	col_v
}

draw.jmeterdata = function(i_arg, col_v, psx_start, psx_end, npoints) {

	# Hier verder met JMeter start- en stoptijden, overzich in results2008.3
	input_filename = commandArgs()[i_arg] 
	jmdata = read.csv(input_filename, header=T, sep=",", dec=".")
	# summary(jmdata)
	attach(jmdata)
	# 2008-10-17 16:02:04
	psx.jmstart = strptime(jmeter_startdatetime, format="%Y-%m-%d %H:%M:%S",tz="Eur1")
	psx.jmend = strptime(jmeter_enddatetime, format="%Y-%m-%d %H:%M:%S",tz="Eur1")
	seq.jmtimes = seq(psx_start, psx_end, length.out=npoints*10)
	
	ntests.function = function(psx.tsparam) {
		# Allemaal wat onhandig: sum en subset(1, ..) niet te gebruiken.
		# Rechtstreeks length(ss) levert 9 op, waarschijnlijk 9 velden in een posix timestamp
		# Versie in servtimes.R werkt wel, omdat deze msec gebruikt, gewoon een integer, geen datetime
		ss = subset(psx.jmstart, subset=((psx.jmstart <= psx.tsparam) & (psx.tsparam <= psx.jmend)))
		str.ss = format(ss, format="%Y-%m-%d %H:%M:%S")
		length(str.ss)	
	}
	
	ntests = sapply(seq.jmtimes, ntests.function)
	
	lines(seq.jmtimes, ntests * 100, type="l", col=col_v, pch=col_v) ; col_v = col_v + 1
	
	col_v
}

main()
