# convert MQput output to CSV.

# functions.c(335): [2016-03-24 14:52:11] [1458827531] trans=Scrittura_PUT_FXMM_FXSPOT_swift_no_conf_41948270.xml, user={user}, resptime=0.016, status=0, iteration=12

# output CSV:
# ts_cet
# trans
# template (deel van trans)
# resptime_sec
# iteration
# msgid

# msgId al eerder expliciet in de log?
# Fire_and_Forget.c(36): Notify: Saving Parameter "MsgId = 20160324_144654_1".

# msg filenaam: 20160324_145211_12_FXMM_FXSPOT_swift_no_conf_41948270.xml
# msg_id: 20160324_145211_12
proc main {argv} {
	lassign $argv infile outfile
	set indir [file dirname $infile]
	set fi [open $infile r]
	if {[file exists $outfile]} {
		set fo [open $outfile a]
	} else {
		set fo [open $outfile w]
		puts $fo [join {ts_cet trans template resptime_sec iteration msgid} ","]
	}
	set msgid "<none>"
	while {[gets $fi line] >= 0} {
		if {[regexp {Saving Parameter "MsgId = ([0-9_]+)".} $line z m]} {
			set msgid $m
		}
		# trans: Scrittura_PUT_FXMM_FXSPOT_swift_no_conf_41948270.xml
		if {[regexp {\[([0-9 :-]+)\] \[\d+\] trans=([^,]+), user=.user., resptime=([0-9.]+), status=0, iteration=(\d+)} \
		        $line z ts_cet trans resptime_sec iteration]} {
			regexp {^Scrittura_PUT_(.*)$} $trans z template
			if {$msgid == "<none>"} {
				set msgid [det_msgid $ts_cet $iteration $indir]
			}
			puts $fo [join [list $ts_cet $trans $template $resptime_sec $iteration $msgid] ","]
			set msgid "<none>"
		}
	}
	close $fo
	close $fi
}

# functions.c(335): [2016-03-31 10:13:44] [1459412024] trans=Scrittura_PUT_FXMM_FXNDF_silent_consent_41938699.xml, user={user}, resptime=0.013, status=0, iteration=1
# ts_cet: 2016-03-31 10:13:44
# iteration: 1
proc det_msgid {ts_cet iteration indir} {
  set msgid "[string map {- "" : "" " " "_"} $ts_cet]_$iteration"
  set lst [glob -nocomplain -directory $indir "$msgid*"]
  if {[llength $lst] > 0} {
	return $msgid
  } else {
    puts "WARN: No msg file found for: $msgid in $indir"
	return $msgid
  }
}

main $argv

