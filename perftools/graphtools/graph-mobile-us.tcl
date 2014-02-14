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
    {dir.arg "c:/projecten/Philips/KNDL/Mobile-landing-US" "Directory that contains db and to put graphs"}
    {db.arg "keynotelogs.db" "DB path (relative to dir)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_graphs $dargv
}

proc make_graphs {dargv} {
  set r [Rwrapper new $dargv]
  $r init [:dir $dargv] [:db $dargv] [:Rfileadd $dargv]
  # $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]
  graph_all $r "2014-02-10" "2014-02-13"
  graph_all $r "2014-01-10" "2014-01-13"
  graph_count_time $r
  $r doall
  $r cleanup
  $r destroy
}

# op run niveau, sommeer pages, sec_overhead_max per dag
# @todo replace strftime('%Y-%m-%d', r.ts_cet) date with something more convenient.
# @todo per page neerzetten, dus delen door 11.
proc graph_all {r from to} {
  $r query "select r.ts_cet ts, 0.001*r.delta_user_msec page_sec, r.agent_inst instance, 1*r.signal_strength strength, 
            r.network, r.no_of_resources, 0.001*p.page_bytes page_kbytes
            from scriptrun r join page p on p.scriptrun_id = r.id
            where r.ts_cet between '$from' and '$to'"
  $r qplot title "Load time by instance and time - $from - $to" \
          x ts y page_sec xlab "Date/time" ylab "Load time (seconds)" \
          geom point colour instance \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Load time by instance - $from - $to" \
          x instance y page_sec xlab "Instance" ylab "Load time (seconds)" \
          geom point colour instance \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
          
  $r qplot title "Load time by signal strength - $from - $to" \
          x strength y page_sec xlab "strength" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Load time by network - $from - $to" \
          x network y page_sec xlab "network" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Load time by number of resources - $from - $to" \
          x no_of_resources y page_sec xlab "no_of_resources" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Load time by page kbytes - $from - $to" \
          x page_kbytes y page_sec xlab "page_kbytes" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Load time by time and network - $from - $to" \
          x ts y page_sec xlab "Date/time" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  $r qplot title "Signal strength by time and network - $from - $to" \
          x ts y strength xlab "Date/time" ylab "Signal Strength" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical

  # instance vs netwerk
  $r qplot title "Load time by instance and network - $from - $to" \
          x instance y page_sec xlab "Instance" ylab "Load time (seconds)" \
          geom point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
  
# in waterfall #items en #bytes te zien?
            
}

proc graph_count_time {r} {
  # aantal per network per dag.
  # avg loadtime per network per dag.  
  $r query "select date_cet date, network, count(*) number, 0.001*avg(delta_user_msec) loadtime
            from scriptrun
            where ts_cet > '2014-01-01'
            group by 1,2"
  
  $r qplot title "Avg load time by network and day" \
          x date y loadtime xlab "Date" ylab "Load time (seconds)" \
          geom line-point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.avg 3 \
          legend.position right \
          legend.direction vertical
  $r qplot title "Count by network and day" \
          x date y number xlab "Date" ylab "Count" \
          geom line-point colour network \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.avg 3 \
          legend.position right \
          legend.direction vertical

}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
