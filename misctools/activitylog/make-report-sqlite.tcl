#!/home/nico/bin/tclsh

# make report based on activity log
# @todo bij title een extra kolom om de group in te zetten.

package require ndv
package require Tclx
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

ndv::source_once group_regexps.tcl
ndv::source_once db_functions.tcl

proc main {argc argv} {
	# global lst_records ar_time_title ar_time_group ar_n_title ar_n_group ar_time_unknown ar_n_unknown ar_time_first ar_time_last ar_argv log
	global R_binary env
	
  set options {
    {l.arg "activitylog" "Logfile basename"}
    {r.arg "activreport" "Report basename"}
    {tr.arg "60" "Minimum time treshold in seconds"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  set R_binary [find_R "/usr/bin/Rscript" "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ":"]]
  
	init_group_regexps
	
	set logfilename $ar_argv(l)
	set report_basename $ar_argv(r)
	log debug "glob pattern: $logfilename*"
	
	set lst_filenames [lsort [glob -nocomplain -directory [file dirname $logfilename] "[file tail $logfilename]*.db"]]
	log debug "lst_filenames: $lst_filenames"
	
	# 2013-03-15 NdV also handle all but the last.
	foreach filename [lrange $lst_filenames 0 end-1] {
	  handle_logfile $filename $report_basename
	}
	
	# 2013-03-15 NdV @todo? copy last to temp, then make report?
	
	# archive all but the last logfile, this one is still active.
	foreach filename [lrange $lst_filenames 0 end-1] {
	  archive_logfile $filename
	}
}	

proc handle_logfile {dbfilename report_basename} {
  open_db $dbfilename
  insert_timegroups
  insert_eventinfo
  make_graphs $dbfilename $report_basename
  make_report $report_basename
}  
  
proc open_db {dbfilename} {
  sqlite3 db $dbfilename
  db function is_new_time_group is_new_time_group
  db function det_group det_group
  
  # @todo det_group title
} 

proc insert_timegroups {} {
  db eval {create table if not exists timegroup (id integer primary key autoincrement, ts_start, ts_end)}
  db eval {delete from timegroup}
  set l [db eval {select ts_start from event where is_new_time_group(title) = 1 order by ts_start}]
  set prev_el "1990"
  foreach el $l {
    # need dummy a column for group by and having, remove this with nested select.
    db eval {insert into timegroup (ts_start, ts_end) 
             select min_ts, max_ts from (select 1 a, min(e1.ts_start) min_ts, max(e2.ts_end) max_ts
             from event e1, event e2
             where e1.ts_start > $prev_el
             and e2.ts_end < $el 
             group by a
             having min(e1.ts_start) is not null)}
    set prev_el $el
  }
  # now everything after the last new time group, prev_el has last time group
  db eval {insert into timegroup (ts_start, ts_end) 
           select min_ts, max_ts from (select 1 a, min(e1.ts_start) min_ts, max(e2.ts_end) max_ts
           from event e1, event e2
           where e1.ts_start > $prev_el
           group by a
           having min(e1.ts_start) is not null)}
}

proc insert_eventinfo {} {
  db eval {create table if not exists eventinfo (id integer primary key autoincrement, event_id, group_name, timegroup_id)}
  db eval {delete from eventinfo}
  db eval {insert into eventinfo (event_id, group_name, timegroup_id)
           select e.id, det_group(e.title), tg.id
           from event e, timegroup tg
           where e.ts_start >= tg.ts_start
           and e.ts_start <= tg.ts_end}
  
}

proc make_graphs {dbfilename report_basename} {
  global R_binary
  set graph_basename [file join [file dirname $report_basename] "group-"]
  set r_script_path [file join [file dirname [info script]] "graphactivities.R"]
  try_eval {
    exec $R_binary $r_script_path $dbfilename $graph_basename
  } {
    log error "Error during R processing: $errorResult"
  }
}

proc make_report {report_basename} {
  set date [db eval {select strftime('%Y-%m-%d', ts_start) from timegroup limit 1}]
  set f [open "$report_basename-$date.html" w]
  # puts_header $f
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "Activity Log Report [det_date_part [lindex [db eval {select min(tg.ts_start) from timegroup tg}] 0]]" 0
  
  add_prev_next_links $hh [det_date_part [lindex [db eval {select min(tg.ts_start) from timegroup tg}] 0]]
  
  foreach {tg_id ts_start ts_end} [db eval {select id, ts_start, ts_end from timegroup order by ts_start}] {
    report_time_group $hh $tg_id $ts_start $ts_end 
  }  
  # puts_footer $f
  $hh write_footer
  close $f
}

proc add_prev_next_links {hh date} {
  log info "Add_prev_next_links for date: $date"
  if {$date == ""} {
    $hh href "Empty date!" "Emptydate.html" 
  } else {
    set day [expr 24 * 60 * 60]
    set prev_date [clock format [expr [clock scan $date -format "%Y-%m-%d"] - $day] -format "%Y-%m-%d"]  
    set next_date [clock format [expr [clock scan $date -format "%Y-%m-%d"] + $day] -format "%Y-%m-%d"]
    $hh href "\[$prev_date\]" "report-$prev_date.html"
    $hh href "\[$next_date\]" "report-$next_date.html"
  }
}

proc report_time_group {hh tg_id tg_start tg_end} {
  # global log
  log info "time group start: $tg_start"
  #set h1 "<H1>From [det_time_part $tg_start] to [det_time_part $tg_end] ([det_date_part $tg_start])</H1>"
  # set h1 "<H1>From $ts_start to $ts_end</H1>"
  # regsub -all "_" $h1 " " h1
  #puts $f $h1
  
  $hh heading 1 "From [det_time_part $tg_start] to [det_time_part $tg_end] ([det_date_part $tg_start])"
  
  $hh text [$hh get_img "group-[det_date_part $tg_start]-$tg_id.png"] 
  
  # title groups
  table_start_header $hh "Title groups"
  foreach {groupname totaltime ntimes ts_first ts_last} \
      [db eval {select i.group_name, sum(e.time), count(i.group_name), min(e.ts_start), max(e.ts_end)
                from eventinfo i, event e
                where i.event_id = e.id
                and i.timegroup_id = $tg_id
                group by i.group_name
                order by sum(e.time) desc}] {
    set avgtime [format_secs [expr round($totaltime / $ntimes)]]
    $hh table_row $groupname [format_secs $totaltime] $ntimes $avgtime [det_time_part $ts_first] [det_time_part $ts_last]
  }
  $hh table_end
    
  # titles
  # table_start_header $hh "Titles"
  $hh text "<div class='collapsable'><H2>Titles</H2><p>"
  $hh table_start
  $hh table_header Name Group "Total time" "#times" "Avg time" "Time first" "Time last"
  
  foreach {title groupname totaltime ntimes ts_first ts_last} \
      [db eval {select e.title, i.group_name, sum(e.time), count(i.group_name), min(e.ts_start), max(e.ts_end)
                from eventinfo i, event e
                where i.event_id = e.id
                and i.timegroup_id = $tg_id
                group by e.title, i.group_name
                having sum(e.time) >= 60
                order by sum(e.time) desc}] {
    set avgtime [format_secs [expr round($totaltime / $ntimes)]]
    $hh table_row $title $groupname [format_secs $totaltime] $ntimes $avgtime [det_time_part $ts_first] [det_time_part $ts_last]
  }
  $hh table_end
  
  # unknown
  table_start_header $hh "Unknown"
  foreach {title totaltime ntimes ts_first ts_last} \
      [db eval {select e.title, sum(e.time), count(i.group_name), min(e.ts_start), max(e.ts_end)
                from eventinfo i, event e
                where i.event_id = e.id
                and i.timegroup_id = $tg_id
                and i.group_name = 'Unknown'
                group by e.title
                having sum(e.time) >= 60
                order by sum(e.time) desc}] {
    set avgtime [format_secs [expr round($totaltime / $ntimes)]]
    $hh table_row $title [format_secs $totaltime] $ntimes $avgtime [det_time_part $ts_first] [det_time_part $ts_last]
  }
  $hh table_end
  
  # timelines
  
}

proc table_start_header {hh title} {
  $hh text "<div class='collapsable'><H2>$title</H2><p>"
  $hh table_start
  $hh table_header Name "Total time" "#times" "Avg time" "Time first" "Time last"
}

# move file to a subdirectory 'archive' of the file's directory
proc archive_logfile {filename} {
  #global log
	log debug "archive_logfile: $filename"
  file mkdir [file join [file dirname $filename] archive]
  # 17-6-2011 NdV delete target file first
  file delete [file join [file dirname $filename] archive [file tail $filename]]
  file rename $filename [file join [file dirname $filename] archive]
}

proc det_date_old {ts} {
	string range $ts 0 9
}

proc check_params {argc argv} {
	global stderr argv0
	if {$argc != 2} {
		puts stderr "syntax: [info nameofexecutable] $argv0 <logfile> <report.html>"
		exit 1
	}
}

# datum en tijd gescheiden door spatie
proc det_time_part {ts} {
	return [lindex [split $ts " "] 1]
}

proc det_date_part {ts} {
	return [lindex [split $ts " "] 0]
}

proc format_secs {sec} {
	# need -gmt, otherwise 3700 seconds will become 2 hours (1 too many)
	return [clock format $sec -format "%H:%M:%S" -gmt true]	
}

proc log {args} {
  global log
	# puts $str
	$log {*}$args
}

proc find_R {args} {
  foreach path $args {
    if {[file exists $path]} {
      return $path 
    }
  }
  # return "Rscript.exe"
  return "Rscript" ; # first make it work on linux, then windows, use os-info, see use of eog/irfanview in a perftoolset script.
}

main $argc $argv
