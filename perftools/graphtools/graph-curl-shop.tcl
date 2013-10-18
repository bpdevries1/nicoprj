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
    {dir.arg "~/Ymor/Philips/Shop/curltest" "Directory that contains db and to put graphs"}
    {db.arg "curltest.db" "DB path (relative to dir)"}
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
  set r [Rwrapper new $dargv]
  $r init [:dir $dargv] [:db $dargv]
  graph_all $r
  $r doall
  $r cleanup
  $r destroy
}

# op run niveau, sommeer pages, sec_overhead_max per dag
# @todo replace strftime('%Y-%m-%d', r.ts_cet) date with something more convenient.
# @todo per page neerzetten, dus delen door 11.
proc graph_all {r} {
  $r query "select ts_cet ts, url, akserver, server, serverstore, server||'-'||serverstore serv_store, time_total from curltest"
  $r qplot {title "Load times Shop"
            x ts y time_total xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point colour url
            legend.position bottom
            width 11 height 7}
  $r qplot {title "Load times Shop per Akamai server"
            x ts y time_total xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point colour akserver facet url
            width 14 height 7}
  $r qplot {title "Load times Shop per ATG server"
            x ts y time_total
            xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point colour server facet url
            width 11 height 7}
  $r qplot {title "Load times Shop per ATG server/store"
            x ts y time_total
            xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point colour serv_store facet url
            legend.nrow 6
            width 11 height 10}
            
  $r query "select ts_cet ts, url, akserver, server, serverstore, server||'-'||serverstore serv_store, time_total from curltest where ts_cet between '2013-10-16 00:00' and '2013-10-16 07:00'"
  $r qplot {title "Load times Shop in timeframe"
            x ts y time_total xlab "Date/time" ylab "Load time (seconds)"
            ymin 0 geom point colour url
            legend.position bottom
            width 11 height 7}
            
#            legend.direction horizontal
#            legend.position bottom
# @todo? legend ook als legend {position bottom direction horizontal ncol8}
# soort 'with' wordt het dan.
            
  $r query "select ts_cet ts, url, akserver, server, serverstore, server||'-'||serverstore serv_store, time_pretransfer, time_starttransfer, time_total from curltest"
  $r melt {time_pretransfer time_starttransfer time_total}
  $r qplot {title "Network times Shop"
            x ts y value
            xlab "Date/time" ylab "Time (seconds)"
            ymin 0 geom point colour variable facet url
            legend.position bottom
            legend.direction horizontal
            width 11 height 10}            
  
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
