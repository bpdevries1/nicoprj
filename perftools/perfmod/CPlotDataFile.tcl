package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CPlotDataFile]] > 0} {
	return
}

# vooral bedoeld om input text van Lqn te parsen, om asymptoten te berekenen
itcl::class CPlotDataFile {

	private common log
	set log [CLogger::new_logger plotdatafile debug]

	public proc new_pdf {} {
		set result [uplevel {namespace which [CPlotDataFile #auto]}]
		return $result
	}

	private variable COLUMN
	private variable n_columns
	private variable lst_columns
	private variable filename
	private variable f
	
	private constructor {} {
		init
	}
	
	private method init {} {
		set n_columns 0
		set lst_columns {}
		set filename ""
		set f -1
	}
	
	public method set_columns {a_lst_columns} {
		$log debug "start"
		set lst_columns $a_lst_columns
		set n_columns [llength $lst_columns]
		set i 0
		foreach el $lst_columns {
			incr i
			# set COLUMN($i) $el
			set COLUMN($el) $i
		}
		$log debug "finished"
	}

	public method get_column {name} {
		return $COLUMN($name)
	}

	public method set_filename {a_filename} {
		set filename $a_filename
	}
	
	public method get_filename {} {
		return $filename
	}

	public method write_header {} {
		set f [open $filename w]
		puts -nonewline $f "# "
		puts $f [join $lst_columns "\t"]
	}
	
	public method write_line {lst} {
		puts $f [join $lst "\t"]
	}
	
	public method close {} {
		::close $f
	}
	
}
