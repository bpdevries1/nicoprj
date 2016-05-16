package require tclodbc
package require ndv
package require Tclx

::ndv::source_once lib_analysis.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# @param args: logdir andir ts1 ts2
proc handle_force_file_logs {args} {
  handle_rentelogic {*}$args
  handle_asplog {*}$args
}

proc handle_rentelogic {logdir andir ts1 ts2 lst_writers} {
  global log
  $log debug "Looking for logfiles in $logdir"
  foreach logfile [glob -nocomplain -directory $logdir *RENTELOGIC*] {
    set fi [open $logfile r]
    do_writers $lst_writers open_file [file tail $logfile]
    file_block_splitter $fi {^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d{3} \[\d+\] } time_filter_logblock $ts1 $ts2 handle_rentelogic_logblock $lst_writers
    close $fi
    do_writers $lst_writers close_file
  }
}

proc time_filter_logblock {block ts1 ts2 callbackproc args} {
  if {[regexp {^([^ ]+ [^ ,]+)} $block z ts]} {
    if {($ts >= $ts1) && ($ts <= $ts2)} {
      $callbackproc $block {*}$args
    }
  }
}

proc handle_rentelogic_logblock {block lst_writers} {
  if {[regexp {^([^ ]+) ([^ ,]+)(.*) in ([0-9]+) ms\.} $block z date time msg ms]} {
    do_writers $lst_writers write_line -dt_start "$date $time" -omschrijving [convert_msg $msg] \
      -ms_elapsed $ms -ms_subtime 0.0
  } else {
    # $log debug "no RE match"
    if {[regexp {ms\.} $block]} {
      # breakpoint
    }
  }
}

proc det_logfilename {andir ts1 ts2} {
  regsub -all " " $ts1 "-" ts1
  regsub -all ":" $ts1 "-" ts1
  regsub -all " " $ts2 "-" ts2
  regsub -all ":" $ts2 "-" ts2
  # set now [clock format [clock seconds] -format "%Y-%m-%d-%H-%M-%S"]
  file join $andir "SLARequest-$ts1-$ts2.csv"
}

proc convert_msg {msg} {
	# : AANVRAAG renteberekening gereed voor propositie 1005238 
  if {[regexp {: ([^:]+)$} $msg z msg]} {
    regsub -all {[0-9]+} $msg 0 msg
    return [string trim $msg]
  } elseif {[regexp { - ([^-]+)$} $msg z msg]} {
    # 2010-08-12 18:05:55,627 [6] INFO  Quion.Event.Workflow.EventAction.Klantpropositie.ProductAfspraakBepalingEventAction [(null)] - Afspraak bepaling gereed voor propositie 1005238 in 70 ms.
    regsub -all {[0-9]+} $msg 0 msg
    return [string trim $msg]
  } else {
    breakpoint
  }
  return [string trim $msg]
}

# @todo toch alleen specifieke dir
# @todo filteren op ingangsdatum/tijd.
proc handle_asplog {logdir andir ts1 ts2 lst_writers} {
  global log
  $log debug "Looking for asp logfiles in $logdir"
  # file mkdir $andir
  # kan niet sorteren op volgnummers, want log.txt.10 komt ook voor, en zou dan voor log.txt.2 komen.
  set lst_files [lsort -command compare_file_time [glob -nocomplain -directory $logdir *ASP-log*]]
  # output filenaam afhankelijk van nieuwste (en dus laatste in lijst) logfile.
  set anfile_rootname [file tail [lindex $lst_files end]]
  do_writers $lst_writers open_file $anfile_rootname
  foreach logfile $lst_files {
    set fi [open $logfile r]
    # split op regels die met date/time entry beginnen.
    file_block_splitter $fi {^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d{3} \[\d+\] } time_filter_logblock $ts1 $ts2 handle_asp_logblock $lst_writers
    close $fi
  }
  do_writers $lst_writers close_file
}

proc compare_file_time {file1 file2} {
  if {[file mtime $file1] < [file mtime $file2]} {
    return -1
  } else {
    return 1
  }
}

proc handle_asp_logblock {block lst_writers} {
  if {[regexp {^([^ ]+) ([^ ,]+)(.*) in ([0-9]+) ms\.} $block z date time msg ms]} {
    do_writers $lst_writers write_line -dt_start "$date $time" -omschrijving [convert_msg $msg] \
      -ms_elapsed $ms -ms_subtime 0.0
  }
if {0} {
2010-08-12 18:05:58,767 [6] DEBUG Force.Core.Web.HttpPerformanceMonitorModule [(null)] - 
@@Request took: 1,5786207 seconds.
 Memory in use at start request was: 249,6796875 Mbytes.
 Memory in use at end request was: 251,73828125 MBytes.
 The difference was: 2,05859375 Mbytes memory for Page http://10.87.0.65/WebForms/Aanvraagadministratie/Contractantscherm.aspx
}
  if {[regexp {^([^ ]+) ([^ ,]+).*@@Request took: ([0-9.,]+) seconds\..*Page ([^ ]+)} $block z date time sec url]} {
    regsub "," $sec "." sec
    do_writers $lst_writers write_line -dt_start "$date $time" -omschrijving [convert_url $url] \
      -ms_elapsed [expr 1000.0 * $sec] -ms_subtime 0.0
  } else {
    if {[regexp {@@Request took} $block]} {
      breakpoint
    }
  }
}

proc convert_url {url} {
  set url [string trim [file tail $url]]
  regsub {\?(.*)$} $url "" url
  return $url
}

if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}