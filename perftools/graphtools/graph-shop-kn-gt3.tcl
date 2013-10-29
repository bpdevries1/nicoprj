#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
source [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  # global log
  log debug "argv: $argv"
  set options {
    {rootdir.arg "c:/projecten/Philips/KNDL" "Directory that contains db and to put graphs"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_graphs $dargv
}

proc make_graphs {dargv} {
  set rootdir [:rootdir $dargv] 
  foreach dir [glob -directory $rootdir -type d "Shop*"] {
    make_graphs_dir $dargv $dir
    # exit ; # for test
  }
}

proc make_graphs_dir {dargv dir} {
  set r [Rwrapper new $dargv]
  $r init $dir keynotelogs.db
  # graph_kn3 $r
  graph_hour $r
  $r doall
  $r cleanup
  $r destroy
}

# op run niveau, sommeer pages, sec_overhead_max per dag
# @todo replace strftime('%Y-%m-%d', r.ts_cet) date with something more convenient.
# @todo per page neerzetten, dus delen door 11.
proc graph_kn3 {r} {
  $r query "select ts_cet ts, 0.001*element_delta loadtime
            from pageitem_gt3
            where url like '%login.jsp%'"
  $r qplot {title "Load times login.jsp"
            x ts y loadtime xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point
            width 11 height 7}
  $r query "select date_cet date, count(element_delta) number
            from pageitem_gt3
            where url like '%login.jsp%'
            group by 1"
  $r qplot {title "Daily count of high load times login.jsp"
            x date y number xlab "Date/time" ylab "Count"
            ymin 0 geom point
            width 11 height 7}
  $r query "select date_cet date, count(element_delta) number
            from pageitem_gt3
            where domain like '%philips%'
            group by 1"
  $r qplot {title "Daily count of high load times all Philips domain"
            x date y number xlab "Date/time" ylab "Count"
            ymin 0 geom point
            width 11 height 7}
  $r query "select date_cet date, content_type, count(element_delta) number
            from pageitem_gt3
            where domain like '%philips%'
            group by 1,2"
  $r qplot {title "Daily count of high load times all Philips domain per type"
            x date y number xlab "Date/time" ylab "Count"
            ymin 0 geom point colour content_type
            width 11 height 7}
}

proc graph_hour {r} {
  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*delta_user_msec)/11 loadtime
            from scriptrun
            where ts_cet > '2013-09-17'
            and 1*task_succeed_calc = 1
            group by 1"
  $r qplot {title "Average page loadtime by hour of day"
            x hour y loadtime xlab "Hour" ylab "Load time (sec)"
            ymin 0 geom point 
            width 11 height 7}

if {1} {     
  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*element_delta) loadtime
            from pageitem
            where ts_cet > '2013-09-17'
            and url like '%login.jsp%'
            and domain like '%philips%'
            group by 1"
  $r qplot {title "Average login.jsp loadtime by hour of day"
            x hour y loadtime xlab "Hour" ylab "Load time (sec)"
            ymin 0 geom point 
            width 11 height 7}
}          
  
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
