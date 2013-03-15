#!/home/nico/bin/tclsh
# log currently active window to a file, every 5 seconds.

package require ndv
package require Tclx
package require sqlite3

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]
# $log set_file "[file tail [info script]].log"
# $log set_file "[info script].log"

if {$tcl_platform(platform) == "windows"} {
  package require twapi
}

# met {none} en vorige << huidige - interval is duidelijk wanneer screensaver en suspend zijn.

# 'starting point': timestamp_end of previous line equals timestart_start of current line.
# {NONE} get_window_title returned empty hwnd and title. Probably screensaver active.
# {NO INFO} the system was not active, get_window_title not called during period, system probably suspended.
# {STARTED} activity logging was started.

proc main {argv iter} {
	global LOGFILE INTERVAL tcl_platform f log

  set options {
    {i.arg "5" "Interval in seconds"}
    {l.arg "activitylog" "Logfile name basename/prefix"}
    {dir.arg "c:/projecten" "Directory to monitor for changes (empty for none)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

	set logfile $ar_argv(l)
  set sec_interval $ar_argv(i)
	set msec_interval [expr $sec_interval * 1000]

  # logfile in same dir as sqlite files.
  set logfilename "[file join [file dirname $logfile] [file tail [info script]]].log"
  $log set_file $logfilename
  $log info "Set log output file to: $logfilename"
  $log info "Iteration: $iter"
	# breakpoint
  init_filechanges $ar_argv(dir)
	
  # dynamic procedure name:
  set get_active_window_title get_active_window_title_$tcl_platform(platform) 
	
	#set title_prev "{unknown}"
	#set ts_prev -1
	#set ts_started_title -1
	# set f [open $logfile a]
	set prev_timestamp_day "<unknown>"
	while {1} {
		set init_vars 0
		set title [$get_active_window_title]
		set timestamp [clock seconds]
		set timestamp_day [det_timestamp_day $timestamp]
		if {$timestamp_day != $prev_timestamp_day} {
		  # catch {close $f}
		  catch {db close}
		  # set f [open [det_logfile_name $logfile $timestamp_day] a]
		  create_db [det_logfile_name $logfile $timestamp_day]
		  set prev_timestamp_day $timestamp_day
		  set ts_prev -1
		  set ts_started_title -1
		  set title_prev "{unknown}"
		}
		if {$ts_prev == -1} {
			# eerste keer, set vars
			puts_logline $timestamp $timestamp "{STARTED}"
			set init_vars 1
		} else {
			if {$timestamp > [expr $ts_prev + (12 * $sec_interval)]} {
				# tijdje niet gelogd: put vorige en re-init
				# 8-9-2009 toch maar op 12 ipv 2 gezet, zodat er 60 seconden respijt is. CPU blijkt soms erg druk, merk dit vooral
				# wanneer in Firefox een PDF wordt gesloten.
				puts_logline $ts_started_title $ts_prev $title_prev
				# ook suspended time loggen
				puts_logline $ts_prev $timestamp "{NO INFO}"
				set init_vars 1
			} else {
				# gewoon event, na normale interval
				if {$title == $title_prev} {
					# nog dezelfde, niets loggen
					set ts_prev $timestamp
				} else {
					# nieuwe app, loggen
					# puts_logline $ts_started_title $ts_prev $title_prev
					# vorige loggen t/m huidige timestamp, zodat geen gaten ontstaan en totalen kloppen.
					puts_logline $ts_started_title $timestamp $title_prev
					set init_vars 1
				}
			}
		}
		if {$init_vars} {
			set ts_prev $timestamp
			set ts_started_title $timestamp
			set title_prev $title
		}
		after $msec_interval
		update ; # handle file changes in c:\projecten
	}
	# close $f ; # never reached.
	db close; # never reached.
}

# @param timestamp: resultaat van [clock seconds]
proc det_timestamp_day {timestamp} {
  return [clock format $timestamp -format "%Y-%m-%d"]
}

# @param logfile: activitylog
# @param timestamp_day: 2010-07-26
proc det_logfile_name {logfile timestamp_day} {
  # return "$logfile-$timestamp_day.tsv"
  return "$logfile-$timestamp_day.db"
}

proc create_db {db_name} {
  sqlite3 db $db_name
  db function regexp regexp ; # make regexp available in queries.
  db eval "create table if not exists event (id integer primary key autoincrement, ts_start, ts_end, time, title)"  
}

proc puts_logline {ts_start ts_end title} {
	if {$ts_start <= 0} {
		puts "Error: timestamp start not valid: $ts_start"
		log error "Error: timestamp start not valid: $ts_start"
		exit 1
	}
	if {$ts_end <= 0} {
		puts "Error: timestamp end not valid: $ts_end"
		log error "Error: timestamp end not valid: $ts_end"
		exit 1
	}

	# puts $f [join [list [format_ts $ts_start] [format_ts $ts_end] [expr $ts_end - $ts_start] $title] "\t"]
	# db eval "insert into event (ts_start, ts_end, time, title) values ('[format_ts $ts_start]', '[format_ts $ts_end]', [expr $ts_end - $ts_start], '$title')"
	# @note 24-12-2011 NdV cannot call Tcl proc within sqlite query, need braces to convert quotes etc.
	set fmt_ts_start [format_ts $ts_start]
	set fmt_ts_end [format_ts $ts_end]
	set duration [expr $ts_end - $ts_start]
	
	# db eval {insert into event (ts_start, ts_end, time, title) values ([format_ts $ts_start], [format_ts $ts_end], [expr $ts_end - $ts_start], $title)}
	db eval {insert into event (ts_start, ts_end, time, title) values ($fmt_ts_start, $fmt_ts_end, $duration, $title)}
	
	# flush $f
}

proc format_ts {ts} {
	if {$ts <= 0} {
		puts "Error: timestamp not valid: $ts"
		log error "Error: timestamp not valid: $ts"
		exit 1
	}
	return [clock format $ts -format "%Y-%m-%d %H:%M:%S"]	
}

proc get_active_window_title_windows {} {
	try_eval {
	  set hwnd [twapi::get_foreground_window]
    if {$hwnd == ""} {
      return "{NONE}"
    } else {
      return [twapi::get_window_text $hwnd]
    }
  } {
    log warn "Could not get active_window_title: $errorResult"
    return "{NONE}"
  }
}

proc get_active_window_title_unix {} {
  try_eval {
    set res [exec xprop -root]
    if {[regexp {_NET_ACTIVE_WINDOW\(WINDOW\): window id # (0x[0-9a-fA-F]+)[^0-9a-fA-F]} $res z id]} {
      set res2 [exec xwininfo -id $id]
      if {[regexp {xwininfo: Window id: .+"(.*)"\n} $res2 z title]} {
        return $title 
      }
    }
  } {
    return "{NONE}"
  }
  return "{NONE}"
}

proc init_filechanges {dir} {
  global tcl_platform
  if {$dir == ""} {
    return 
  }
  if {$tcl_platform(platform) != "windows"} {
    return 
  }
  set mon_id [twapi::begin_filesystem_monitor $dir dir_change_cb -access 1 -size 1 -subtree 1 -write 1 -create 1 -dirname 1 -filename 1]
}

set last_ts_end -1
set last_main_dir "<none>"

proc dir_change_cb {args} {
  global f last_ts_end last_main_dir
  set ts_end [clock seconds]
  set ts_start [expr $ts_end - 5]
  foreach arg $args {
    lassign $arg action path
    if {[regexp {~.*\.tmp} $path]} {
      continue; # temp file creation in word etc. 
    }
    set main_dir [lindex [file split $path] 0]
    if {($ts_end == $last_ts_end) && ($main_dir == $last_main_dir)} {
      # nothing, same timestamp and same dir 
    } else {
      puts_logline $ts_start $ts_end "dirchange: $action: $path"
      set last_ts_end $ts_end
      set last_main_dir $main_dir
    }
  }
}

set i 0
while {$i < 10} {
  incr i
  try_eval {
    $log info "Starting main proc, i=$i..."
    main $argv $i
    $log info "Finished main proc."
  } {
    $log error "$errorResult" 
  }
  after 60000
}
