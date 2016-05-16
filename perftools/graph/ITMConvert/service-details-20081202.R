main = function() {
	# dirname = "C:\\nico_share\\ITM-data"
	# jmeter.filename = "C:\\vreen00_CxR_Int2\\CxR_IKT\\Performance\\Service-Performance-Testen\\2008.3\\analyse-services.tsv"
	dirname = commandArgs()[6]
	jmeter.filename = commandArgs()[7]
	
	itm.filename = paste(dirname, "KQITASMF.all.tsv", sep = "\\")
	# itm.filename = paste(dirname, "KQITASMF.all-test.tsv", sep = "\\")
	details.filename = paste(dirname, "KQITASMF.details.csv", sep = "\\")
	
	write.table("ASMF details for testruns", col.names=FALSE, row.names=FALSE, file=details.filename, append=FALSE)
	
	itmdata =  read.csv(itm.filename, header=T, sep="\t")
	# attach(itmdata)
	# psx_timestamp = strptime(floor(WRITETIME.char.1.16. / 1000), format="1%y%m%d-%H%M%S",tz="Eur1")
	
	# td1 = difftime(strptime("12:00:00", format="%H:%M:%S"), strptime("11:00:00", format="%H:%M:%S"), units="hours")
	# blijkbaar gewoon seconden opgeven bij optellen bij een posix tijd.
	# td1 = 3600
	
	psx_timestamp_wt = strptime(as.character(floor(itmdata$WRITETIME.char.1.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")
	psx_timestamp_st = strptime(as.character(floor(itmdata$SDTTM.char.5.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")
	psx_timestamp_et = strptime(as.character(floor(itmdata$EDTTM.char.6.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1")

	# Tel 1 uur op bij de ITM datums.
	# psx_timestamp_wt = strptime(as.character(floor(itmdata$WRITETIME.char.1.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1") + td1
	# psx_timestamp_st = strptime(as.character(floor(itmdata$SDTTM.char.5.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1") + td1
	# psx_timestamp_et = strptime(as.character(floor(itmdata$EDTTM.char.6.16. / 1000)), format="1%y%m%d%H%M%S",tz="Eur1") + td1
	
	to.unsigned32 = function(val) {
		if (val < 0) {
			val + 2^32
		} else {
			val
		}
	}

	df = data.frame(psx_timestamp_wt, psx_timestamp_st, psx_timestamp_et, 
		msgflow = itmdata$MSG_FLOW.char.15.32., 
		tote = 0.000001 * sapply(itmdata$TOTE.int.20.4., to.unsigned32), 
		totc = 0.000001 * itmdata$TOTC.int.23.4., 
		totm = itmdata$TOTM.int.28.4.) 

	jmeter.data =  read.csv(jmeter.filename, header=T, sep="\t", dec=",")
	# details.test(jmeter.data[1,], df, details.filename)
	
	for(i in 1:length(jmeter.data$run)) {
		details.test(jmeter.data[i,], df, details.filename)
	}
}

details.test = function(jmeter.row, df.itm, details.filename) {
	# psx_start = strptime("2008-11-03 15:06", format="%Y-%m-%d %H:%M")
	# psx_end = strptime("2008-11-03 16:06", format="%Y-%m-%d %H:%M")
	psx_start = strptime(jmeter.row$start.tijd, format="%d-%m-%Y %H:%M",tz="Eur1")
	psx_end = strptime(jmeter.row$eind.tijd, format="%d-%m-%Y %H:%M",tz="Eur1")
	nservcalls = jmeter.row$nservcalls
	
	td1 = 3600 ; # 1 uur
	
	# attach(df.itm)
	# itmdata.s = subset(itmdata, subset=((psx_timestamp_wt >= psx_start) & (psx_timestamp_st <= psx_end) & (TOTM.int.28.4. > 0)))
	# selecteer alle ITM records die qua tijd helemaal of deels binnen de test looptijd vallen.
	
	# both: zowel records zonder 1 uur op te schuiven als de records met 1 uur opgeschoven.
	df.s_both = subset(df.itm, subset=((df.itm$psx_timestamp_et + td1 >= psx_start) & (df.itm$psx_timestamp_st <= psx_end) & (df.itm$totm > 0)))
	
	
	df.s_et = subset(df.itm, subset=((df.itm$psx_timestamp_et >= psx_start) & (df.itm$psx_timestamp_st <= psx_end) & (df.itm$totm > 0)))
	df.s_etp1 = subset(df.itm, subset=((df.itm$psx_timestamp_et + td1 >= psx_start) & (df.itm$psx_timestamp_st + td1 <= psx_end) & (df.itm$totm > 0)))

	write.csv(df.s_both, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)

	write.csv(jmeter.row, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	
	# print.subset("\nTotals between start time and writetime:\n", df.s_wt, nservcalls, details.filename)
	print.subset("\nTotals between start time and endtime:\n", df.s_et, nservcalls, details.filename)
	print.subset("\nTotals between start time + 1 hr and endtime + 1 hr:\n", df.s_etp1, nservcalls, details.filename)
	
	cat("======================= \n", file = details.filename, append=TRUE)
	# detach(df.itm)
	
}

print.subset = function(title, df.s, nservcalls, details.filename) {
	ta.totm = tapply(df.s$totm, df.s$msgflow, sum, na.rm = TRUE)
	ta.totc = tapply(df.s$totc, df.s$msgflow, sum, na.rm = TRUE)
	ta.avgm = ta.totm / nservcalls
	
	df.ta = data.frame(ta.totm, ta.totc, ta.avgm)
	cat(title, file = details.filename, append=TRUE)
	# write.csv(data.frame(psx_start, psx_end), row.names=FALSE, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	write.csv(df.ta, file = details.filename, append=TRUE); cat("\n", file = details.filename, append=TRUE)
	
}


main()

