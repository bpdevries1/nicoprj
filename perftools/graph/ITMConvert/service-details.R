main = function() {
	# dirname = "C:\\nico_share\\ITM-data"
	# jmeter.filename = "C:\\vreen00_CxR_Int2\\CxR_IKT\\Performance\\Service-Performance-Testen\\2008.3\\analyse-services.tsv"
	dirname = commandArgs()[6]
	jmeter.filename = commandArgs()[7]
	
	details.filename = paste(dirname, "KQITASMF.details.csv", sep = "\\")
	write.table("ASMF en ASND details for testruns", col.names=FALSE, row.names=FALSE, file=details.filename, append=FALSE)
	
	df.asmf = make.df.asmf(dirname)
	df.asnd = make.df.asnd(dirname)
		
	jmeter.data =  read.csv(jmeter.filename, header=T, sep="\t", dec=",")
	
	for(i in 1:length(jmeter.data$run)) {
		# details.test(jmeter.data[i,], df.asmf, details.filename)
		details.test(jmeter.data[i,], df.asmf, df.asnd, details.filename)
	}
}

make.df.asmf = function(dirname) {
	asmf.filename = paste(dirname, "KQITASMF.all.tsv", sep = "\\")
	asmfdata =  read.csv(asmf.filename, header=T, sep="\t")
	
	# Moet psx timestamp waarden naar numeric omzetten om vervolgens sapply te kunnen doen, anders wordt vector als soort matrix gezien.
	psx_timestamp_wt = sapply(as.numeric(strptime(as.character(floor(asmfdata$WRITETIME.char.1.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	psx_timestamp_st = sapply(as.numeric(strptime(as.character(floor(asmfdata$SDTTM.char.5.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	psx_timestamp_et = sapply(as.numeric(strptime(as.character(floor(asmfdata$EDTTM.char.6.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	
	df.asmf = data.frame(psx_timestamp_wt, psx_timestamp_st, psx_timestamp_et, 
		msgflow = asmfdata$MSG_FLOW.char.15.32., 
		tote = 0.000001 * sapply(asmfdata$TOTE.int.20.4., to.unsigned32), 
		totc = 0.000001 * asmfdata$TOTC.int.23.4., 
		totm = asmfdata$TOTM.int.28.4.) 
	
	df.asmf
}

make.df.asnd = function(dirname) {
	asnd.filename = paste(dirname, "KQITASND.all.tsv", sep = "\\")
	asnddata =  read.csv(asnd.filename, header=T, sep="\t")
	
	# Moet psx timestamp waarden naar numeric omzetten om vervolgens sapply te kunnen doen, anders wordt vector als soort matrix gezien.
	psx_timestamp_wt = sapply(as.numeric(strptime(as.character(floor(asnddata$WRITETIME.char.1.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	psx_timestamp_st = sapply(as.numeric(strptime(as.character(floor(asnddata$SDTTM.char.5.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	psx_timestamp_et = sapply(as.numeric(strptime(as.character(floor(asnddata$EDTTM.char.6.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")), itm.addoffset)
	
	df.asnd = data.frame(psx_timestamp_wt, psx_timestamp_st, psx_timestamp_et, 
		msgflow = asnddata$MSG_FLOW.char.11.32., 
		nodename = asnddata$NODE_LABEL.char.12.32.,
		tote = 0.000001 * sapply(asnddata$TOTE.int.14.4., to.unsigned32), 
		totc = 0.000001 * asnddata$TOTC.int.17.4.) 
	
	df.asnd
}


details.test = function(jmeter.row, df.asmf, df.asnd, details.filename) {
	psx_start = strptime(jmeter.row$start.tijd, format="%d-%m-%Y %H:%M",tz="Eur1")
	psx_end = strptime(jmeter.row$eind.tijd, format="%d-%m-%Y %H:%M",tz="Eur1")
	nservcalls = jmeter.row$nservcalls
	
	df.asmf.s_et = subset(df.asmf, subset=((df.asmf$psx_timestamp_et >= psx_start) & (df.asmf$psx_timestamp_st <= psx_end) & (df.asmf$totm > 0)))
	write.csv(df.asmf.s_et, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)

	df.asnd.s_et = subset(df.asnd, subset=((df.asnd$psx_timestamp_et >= psx_start) & (df.asnd$psx_timestamp_st <= psx_end)))
	write.csv(df.asnd.s_et, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	
	
	write.csv(jmeter.row, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	
	print.subset.asmf("\nASMF Totals between start time and endtime:\n", df.asmf.s_et, nservcalls, details.filename)
	print.subset.asnd("\nASND Totals between start time and endtime:\n", df.asnd.s_et, details.filename)
	
	cat("======================= \n", file = details.filename, append=TRUE)

}

print.subset.asmf = function(title, df.asmf.s, nservcalls, details.filename) {
	ta.totm = tapply(df.asmf.s$totm, df.asmf.s$msgflow, sum, na.rm = TRUE)
	ta.totc = tapply(df.asmf.s$totc, df.asmf.s$msgflow, sum, na.rm = TRUE)
	ta.avgm = ta.totm / nservcalls
	
	df.ta = data.frame(ta.totm, ta.totc, ta.avgm)
	cat(title, file = details.filename, append=TRUE)
	write.csv(df.ta, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	
}

print.subset.asnd = function(title, df.asnd.s, details.filename) {
	# ta.totc = tapply(df.asnd.s$totc, df.asnd.s$msgflow, sum, na.rm = TRUE)
	ta.totc = tapply(df.asnd.s$totc, paste(df.asnd.s$msgflow, df.asnd.s$nodename,sep="/"), sum, na.rm = TRUE)
	
	df.ta = data.frame(ta.totc)
	cat(title, file = details.filename, append=TRUE)
	write.csv(df.ta, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
}

to.unsigned32 = function(val) {
	if (val < 0) {
		val + 2^32
	} else {
		val
	}
}

# bereken offset om bij timestamp op te tellen.
# @returns psx_ts als de datum voor 2-11-2008 ligt, en psx_ts + 3600 als de datum hierna ligt.
itm.addoffset = function(psx_ts) {
	# print(paste("add: mode of psx_ts: ",mode(psx_ts), sep = " "))
	# print(paste("add: value of psx_ts: ",psx_ts, sep = " "))
	if (is.na(psx_ts)) {
		NA
	} else {
		if (psx_ts < strptime("1081102000000", format="1%y%m%d%H%M%S",tz="Eur1")) {
			psx_ts
		} else {
			psx_ts + 3600
		}
	}
}

main()

warnings()

