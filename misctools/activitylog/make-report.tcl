#!/home/nico/bin/tclsh

# make report based on activity log
# @todo bij title een extra kolom om de group in te zetten.

package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# lst_group_regexps: list of elements, where each element is a list of two elements: regexp and groupname
# (wanted to do something with regsub, to determine group more dynamically, but cannot find a use for it now (5-9-09)
# (Idea was to determine everything after last dash (-) and use this as a group, but don't do this now)
# init code, subject to change, therefore on top of file.
proc init_group_regexps {} {
	global lst_group_regexps
	set lst_group_regexps {}

	# as soon as one regexp returns true, the search is stopped, so the most detailed should be first.
	# @todo (maybe later) add a start and end date for the regexp's, as projects also have a start and end date.
	# @todo vaak nog wel een filename in de title-bar, maar niet de directory-naam, een find uitvoeren duurt erg lang, evt alleen in c:\projecten
	# kijken. Of is current-dir nog aan een app te vragen?
	
	add_re RWS RWS
	add_re rws RWS
	add_re Facilitor RWS 
	add_re Rijkswaterstaat RWS
	
	add_re ERI Ericsson
	add_re Ericsson Ericsson 
	add_re {Site.?.andler} Ericsson
	
	add_re TWE TweedeKamer
	add_re {Tweede Kamer} TweedeKamer 
	add_re {VLOS} TweedeKamer 
	add_re {vlos} TweedeKamer 
	
	add_re CAP CAP 
	
	# PA-Rol
	add_re {HPM2011} YmorPA 
	add_re {Ymor PA} YmorPA
	
	# General tools, not able to determine which (client) project.
	add_re {^Add Thoughts$} General
	add_re {^ThinkingRock } General
	add_re {^Total Commander} General
	add_re { - Microsoft Outlook$} Outlook
	add_re { - Bericht} Outlook
	add_re { - Vergadering} Outlook
	add_re { - Afspraak} Outlook

	# protege
	# lappend lst_group_regexps [list {} ]

  # default, system regexps	
  add_re {Herinnering} Screensaver
  add_re {\{NONE\}} Screensaver
	
}

proc add_re {re group} {
  global lst_group_regexps
  lappend lst_group_regexps [list $re $group]
}

proc main {argc argv} {
	global lst_records ar_time_title ar_time_group ar_n_title ar_n_group ar_time_unknown ar_n_unknown ar_time_first ar_time_last ar_argv log
	
  set options {
    {l.arg "activitylog" "Logfile basename"}
    {r.arg "activreport" "Report basename"}
    {tr.arg "60" "Minimum time treshold in seconds"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  
	# check_params $argc $argv
	init_group_regexps
	set logfilename $ar_argv(l)
	set reportfilename $ar_argv(r)
	$log debug "glob pattern: $logfilename*"
	# set lst_filenames [lsort [glob -nocomplain "$logfilename*"]]
	set lst_filenames [lsort [glob -nocomplain -directory [file dirname $logfilename] "[file tail $logfilename]*"]]
	$log debug "lst_filenames: $lst_filenames"
	foreach filename $lst_filenames {
	  handle_logfile $filename $reportfilename
	}

	# archive all but the last logfile, this one is still active.
	foreach filename [lrange $lst_filenames 0 end-1] {
	  archive_logfile $filename
	}
}	

proc handle_logfile {logfilename reportfilename} {
	global lst_records ar_time_title ar_time_group ar_n_title ar_n_group ar_time_unknown ar_n_unknown ar_time_first ar_time_last ar_argv log
	$log debug "handle_logfile: $logfilename"
  set fin [open $logfilename r]
	# set prev_date "<unknown>"
	# set filename_date "<unknown>"
	set block_start_date "<unknown>"
	# set fout "<unknown>"
	# set fout [open $reportfilename w]
	init_vars
	while {![eof $fin]} {
		gets $fin line
		# log $line
		set lst [split $line "\t"]
		if {[llength $lst] != 4} {
			log "Not 4 items in line (#[llength $lst]): $line" 
			continue
		}
		foreach {ts_start ts_end duration title} $lst {
			set title [normalise_title $title]
		  if {[is_new_time_group $title]} {
				log "new time group, report previous block"
				report_time_group $reportfilename $block_start_date
				init_vars
			} else {
				if {$lst_records == {}} {
					set block_start_date [det_date $ts_start]
				}
				# 19-11-2009 NdV (deel)lijst adden, niet line.
				# lappend lst_records $line
        lappend lst_records $lst
				set group [det_group $title]
				incr ar_time_title($title) $duration
				incr ar_n_title($title)
        if {$ar_n_title($title) == 1} {
          set ar_time_first($title) $ts_start 
        }
        set ar_time_last($title) $ts_end
				incr ar_time_group($group) $duration
				incr ar_n_group($group)
        if {$ar_n_group($group) == 1} {
          set ar_time_first($group) $ts_start 
        }
        set ar_time_last($group) $ts_end
        
				if {$group == "Unknown"} {
					incr ar_time_unknown($title) $duration
					incr ar_n_unknown($title)
				}
			}
		}
	}
	
	report_time_group $reportfilename $block_start_date 1 ; # also report last group, with no ending line
	# puts_footer $fout
	close $fin
	# close $fout
}

# remove 'modified from title, and maybe later also other things
proc normalise_title {title} {
  if {[regexp {^(.*) \(modified\)(.*)$} $title z str_before str_after]} {
    set title "$str_before$str_after"
  }
  return $title 
}

# move file to a subdirectory 'archive' of the file's directory
proc archive_logfile {filename} {
  global log
	$log debug "archive_logfile: $filename"
  file mkdir [file join [file dirname $filename] archive]
  # 17-6-2011 NdV delete target file first
  file delete [file join [file dirname $filename] archive [file tail $filename]]
  file rename $filename [file join [file dirname $filename] archive]
}

proc det_date {ts} {
	string range $ts 0 9
}

proc check_params {argc argv} {
	global stderr argv0
	if {$argc != 2} {
		puts stderr "syntax: [info nameofexecutable] $argv0 <logfile> <report.html>"
		exit 1
	}
}

proc is_new_time_group {title} {
	set result 0
	# {NONE} is screensaver, report in group
	# if {$title == "{NONE}"} {set result 1}
	if {$title == "{NO INFO}"} {set result 1}
	if {$title == "{STARTED}"} {set result 1}
	return $result	
}

proc init_vars {} {
	global lst_records ar_time_title ar_time_group ar_n_title ar_n_group ar_time_unknown ar_n_unknown ar_time_first ar_time_last
	set lst_records {}
	array unset ar_time_title
	array unset ar_n_title
	array unset ar_time_group
	array unset ar_n_group
	array unset ar_time_unknown
	array unset ar_n_unknown
  array unset ar_time_first
  array unset ar_time_last
}

proc det_group {title} {
	global lst_group_regexps
	if {[regexp {Tools} $title]} {
		log "Determining group of: $title"
	}
	set result "Unknown"
	foreach el $lst_group_regexps {
		# nu niet foreach, dan werkt break niet goed
		lassign $el re group
		if {[regexp $re $title]} {
			set result $group
			break
		}
	}
	return $result
}

proc puts_header {f} {
	puts $f "<html><head><title>Activity Log Report</title>
	
  <style type=\"text/css\">
  				body {
  					font:normal 68% verdana,arial,helvetica;
  					color:#000000;
  				}
  				table tr td, table tr th {
  					font-size: 68%;
  				}
  				table.details tr th{
  					font-weight: bold;
  					text-align:left;
  					background:#a6caf0;
  				}
  				table.details tr td{
  					background:#eeeee0;
  					white-space: nowrap;
  				}
  				h1 {
  					margin: 0px 0px 5px; font: 165% verdana,arial,helvetica;display: inline;
  				}
  				h2 {
  					margin-top: 1em; margin-bottom: 0.5em; font: bold 125% verdana,arial,helvetica;display: inline;
  				}
  				h3 {
  					margin-bottom: 0.5em; font: bold 115% verdana,arial,helvetica
  				}
  				.Failure {
  					font-weight:bold; color:red;
  				}
					.collapsable {
							margin: 1em;
							padding: 1em;
							border: 1px solid black;
					} 					
  			</style>	
	<script type='text/javascript' src='collapse.js'></script> 	
	</head><body>"
}

proc puts_footer {f} {
	puts $f "</body></html>"
}

set file_date "<unknown>"
proc report_time_group {reportfilename block_start_date {is_last 0}} {
	global lst_records ar_time_title ar_time_group ar_n_title ar_n_group ar_time_unknown \
    ar_n_unknown file_date log ar_time_first ar_time_last
	puts "block_start_date: $block_start_date"
	if {[llength $lst_records] > 0} {
		if {$block_start_date == $file_date} {
			set f [open "$reportfilename-$file_date.html" a]
		} else {
			# eerst vorige even openen en afsluiten 
			if {$file_date != "<unknown>"} {
				set f [open "$reportfilename-$file_date.html" a]
				puts_footer $f
				close $f
			}
			# dan nieuwe starten
			set file_date $block_start_date
			set f [open "$reportfilename-$file_date.html" w]
			puts_header $f
		}
		#$log debug "lines: $lst_records"
    #$log debug "last line: [lindex $lst_records end]"
    set ts_start [lindex [lindex $lst_records 0] 0]
		set ts_end [lindex [lindex $lst_records end] 1]
		set h1 "<H1>From [det_time_part $ts_start] to [det_time_part $ts_end] ([det_date $ts_start])</H1>"
		# set h1 "<H1>From $ts_start to $ts_end</H1>"
		regsub -all "_" $h1 " " h1
		puts $f $h1
		report_time_array $f "Title groups" ar_time_group ar_n_group
		report_time_array $f "Titles" ar_time_title ar_n_title
		report_time_array $f "Unknown" ar_time_unknown ar_n_unknown
		puts $f "<div class='collapsable'><H2>Time lines</H2><p>"
		
		set sec_total_all 0
		# <pre> and collapsable don't work together, so don't use <pre>
		#puts $f "<pre>"
		foreach record $lst_records {
			# puts $f "$line<br/>"
			puts $f "[join $record "\t"]<br/>"
			# incr sec_total_all [lindex [split $line "\t"] 2]
			incr sec_total_all [lindex $record 2]
		}
		#puts $f "</pre>"
		
		puts $f "Total: [format_secs $sec_total_all]"
		puts $f "</p></div>"
		
		if {$is_last} {
			puts_footer $f
		}
		close $f
	} else {
		# empty group, nothing to report
	}
}

# datum en tijd gescheiden door spatie
proc det_time_part {ts} {
	#puts "ts: $ts"
	#bla
	return [lindex [split $ts "_"] 1]
}

proc det_date_part {ts} {
	return [lindex [split $ts "_"] 0]
}

proc report_time_array {f array_title time_name n_name} {
	global ar_time_first ar_time_last ar_argv
  upvar $time_name ar_time
	upvar $n_name ar_n
	puts $f "<div class='collapsable'><H2>$array_title</H2><p>"
	# convert to list to sort, cannot use array get, is a flatlist
	set lst {}
	foreach {nm val} [array get ar_time] {
		lappend lst [list $nm $val] 
	}
	
	puts $f "<table cellspacing=\"2\" cellpadding=\"5\" border=\"0\" class=\"details\">"
	# puts $f "<tr><th>Name</th><th>Total time</th><th>#times</th><th>Avg time</th></tr>"
	puts $f "<tr><th>Name</th><th>Total time</th><th>#times</th><th>Avg time</th><th>Time first</th><th>Time last</th></tr>"
	set sec_total_all 0
	foreach el [lsort -decreasing -integer -index 1 $lst] {
		set title [lindex $el 0]
		set sec_total [lindex $el 1]
		incr sec_total_all $sec_total
		set n $ar_n($title)
		set sec_avg [expr $sec_total / $n]
		if {$sec_total >= $ar_argv(tr)} {
			# puts $f "<tr><td>$title</td><td>[format_secs $sec_total]</td><td>$n</td><td>[format_secs $sec_avg]</td></tr>"
			puts $f "<tr><td>$title</td><td>[format_secs $sec_total]</td><td>$n</td><td>[format_secs $sec_avg]</td><td>[time_only $ar_time_first($title)]</td><td>[time_only $ar_time_last($title)]</td></tr>"
		}
	}
	
	puts $f "</table>"
	puts $f "Total: [format_secs $sec_total_all]<br/></p></div>"
}

proc time_only {date_time} {
  if {[regexp {_(.+)$} $date_time z res]} {
    return $res 
  } else {
    return $date_time 
  }
}

proc format_secs {sec} {
	# need -gmt, otherwise 3700 seconds will become 2 hours (1 too many)
	return [clock format $sec -format "%H:%M:%S" -gmt true]	
}

proc log {str} {
	puts $str
}

main $argc $argv
