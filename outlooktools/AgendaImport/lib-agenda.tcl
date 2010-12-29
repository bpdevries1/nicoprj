package provide agenda 0.1

namespace eval ::agenda {

	# Exported APIs
	namespace export calc_eindtijd det_toekomst_datum

	proc calc_eindtijd {begintijd} {
		if {[regexp {^(.*):(.*)$} $begintijd z uur minuut]} {
			set einduur [expr $uur + 2]
			if {$einduur >= 24} {
				set einduur 23
			}
			return "$einduur:$minuut"
		} else {
			puts stderr "Cannot parse time: $begintijd"
			return "*$begintijd*"
		}
	}
	
	proc det_toekomst_datum {dag maandnr} {
		set current_dat [clock format [clock seconds] -format "%Y-%m-%d"]
		set year 2000
		while {"$year-[format %02d $maandnr]-[format %02d $dag]" < $current_dat} {
			incr year
		}
		return "[format %02d $dag]-[format %02d $maandnr]-$year"
	}

}
