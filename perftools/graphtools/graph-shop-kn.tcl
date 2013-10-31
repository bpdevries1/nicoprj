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
    {rootdir.arg "c:/projecten/Philips/KNDL" "Directory that contains db"}
    {outrootdir.arg "c:/projecten/Philips/Shop/daily/graphs" "Directory for output graphs"}
    {outformat.arg "all" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {combineddb.arg "c:/projecten/Philips/Shop/daily/daily.db" "DB with combined data from all shops"}
    {actions.arg "all" "List of actions to execute (comma separated)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_graphs $dargv
}

proc make_graphs {dargv} {
  set rootdir [:rootdir $dargv] 
  foreach dir [glob -directory $rootdir -type d "Shop*"] {
    make_graphs_dir $dargv $dir
    # exit ; # for test
  }
  make_combined_graphs $dargv
}

proc make_graphs_dir {dargv dir} {
  set r [Rwrapper new $dargv]
  $r init $dir keynotelogs.db
  $r set_outputroot [file normalize [from_cygwin [:outrootdir $dargv]]]
  $r set_outformat [:outformat $dargv]
  if {[:actions $dargv] == "all"} {
    # set actions [list kn3 hour ttip]
    # @todo actions weer kn3 laten includen. Doet het [2013-10-31 12:57:46] niet, omdat tabel niet bestaat.
    set actions [list hour ttip]
  } else {
    set actions [split [:actions $dargv] ","] 
  }
  foreach action $actions {
    graph_$action $r $dir 
  }
  # graph_kn3 $r
  # graph_hour $r
  # graph_ttip $r $dir
  $r doall
  $r cleanup
  $r destroy
}

proc graph_kn3 {r dir} {
  set scriptname [file tail $dir]  
  $r query "select ts_cet ts, 0.001*element_delta loadtime
            from pageitem_gt3
            where url like '%login.jsp%'"
  $r qplot title "$scriptname - Load times login.jsp" \
            x ts y loadtime xlab "Date/time" ylab "Load time (seconds)" \
            ymin 0 geom point \
            width 11 height 7
  $r query "select date_cet date, count(element_delta) number
            from pageitem_gt3
            where url like '%login.jsp%'
            group by 1"
  $r qplot title "$scriptname - Daily count of high load times login.jsp" \
            x date y number xlab "Date/time" ylab "Count" \
            ymin 0 geom point \
            width 11 height 7
  $r query "select date_cet date, count(element_delta) number
            from pageitem_gt3
            where domain like '%philips%'
            group by 1"
  $r qplot title "$scriptname - Daily count of high load times all Philips domain" \
            x date y number xlab "Date/time" ylab "Count" \
            ymin 0 geom point \
            width 11 height 7
  $r query "select date_cet date, content_type, count(element_delta) number
            from pageitem_gt3
            where domain like '%philips%'
            group by 1,2"
  $r qplot title "$scriptname - Daily count of high load times all Philips domain per type" \
            x date y number xlab "Date/time" ylab "Count" \
            ymin 0 geom point colour content_type \
            width 11 height 7
}

proc graph_hour {r dir} {
  set scriptname [file tail $dir]
  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*delta_user_msec)/11 loadtime
            from scriptrun
            where ts_cet > '2013-10-24'
            and 1*task_succeed_calc = 1
            group by 1"
  $r qplot title "$scriptname - Average page loadtime by hour of day" \
            x hour y loadtime xlab "Hour" ylab "Load time (sec)" \
            ymin 0 geom point \
            width 11 height 7

  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*element_delta) loadtime
            from pageitem
            where ts_cet > '2013-10-24'
            and url like '%login.jsp%'
            and domain like '%philips%'
            group by 1"
  $r qplot title "$scriptname - Average login.jsp loadtime by hour of day" \
            x hour y loadtime xlab "Hour" ylab "Load time (sec)" \
            ymin 0 geom point \
            width 11 height 7
}

proc graph_ttip {r dir} {
  set scriptname [file tail $dir]
  # @note where clause to not get R warnings like 1: Removed 3 rows containing missing values (geom_point). 
  $r query "select date_cet date, page_time_sec, page_ttip_sec, page_time_sec - page_ttip_sec async_sec
            from aggr_run where page_time_sec >= 0"
  $r melt {page_time_sec page_ttip_sec async_sec}
  $r qplot title "$scriptname - Total and TTIP times" \
            x date y value \
            xlab "Date" ylab "Time (seconds)" \
            ymin 0 geom line-point colour variable \
            legend.position bottom \
            legend.direction horizontal \
            width 11 height 8

  # @todo met line-point en geen colour gaat het fout: shape=as.factor() e.d.            
  $r query "select date_cet date, avail
            from aggr_run where avail >= 0"
  $r qplot title "$scriptname - Availability" \
            x date y avail \
            xlab "Date" ylab "Availability" \
            ymin 0 geom line \
            width 11 height 8
}

proc make_combined_graphs {dargv} {
  set r [Rwrapper new $dargv]
  $r init [file dirname [:combineddb $dargv]] [file tail [:combineddb $dargv]]
  $r set_outputroot [file normalize [from_cygwin [:outrootdir $dargv]]]
  $r set_outformat [:outformat $dargv]
  graph_ttip_combined $r
  $r doall
  $r cleanup
  $r destroy  
}

proc graph_ttip_combined {r} {
  # @note where clause to not get R warnings like 1: Removed 3 rows containing missing values (geom_point). 
  $r query "select scriptname, date_cet date, page_time_sec, page_ttip_sec, page_time_sec - page_ttip_sec async_sec
            from aggr_run where page_time_sec >= 0"
  $r melt {page_time_sec page_ttip_sec async_sec}
  $r qplot title "Shops - Total and TTIP times - 1" \
            x date y value \
            xlab "Date" ylab "Time (seconds)" \
            ymin 0 geom line-point colour variable \
            facet scriptname \
            legend.position bottom \
            legend.direction horizontal \
            width 11 height 20
            
  # @todo met line-point en geen colour gaat het fout: shape=as.factor() e.d.            
  $r query "select scriptname, date_cet date, avail
            from aggr_run where avail >= 0"
  $r qplot title "Shops - Availability - 1" \
            x date y avail \
            xlab "Date" ylab "Availability" \
            ymin 0 geom line facet scriptname \
            width 11 height 14
  $r qplot title "Shops - Availability - 2" \
            x date y avail \
            xlab "Date" ylab "Availability" \
            ymin 0 geom line-point colour scriptname \
            width 11 height 8 \
            legend.position bottom \
            legend.direction horizontal \
            legend.ncol 4
}

main $argv
