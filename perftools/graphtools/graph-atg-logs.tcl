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
    {dir.arg "c:/projecten/Philips/Shop-logs" "Directory that contains db and to put graphs"}
    {db.arg "atglogs.db" "DB path (relative to dir)"}
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
  $r query "select strftime('%Y-%m-%d %H:%M', substr(ts, 1, 19))||':00' ts, count(*) number
            from atglogs
            where message = 'Empty shoptype id is passed to the GetSitesPerShopTypeDroplet droplet'
            and ts between '2013-10-16 00:00' and '2013-10-16 07:00'
            group by 1"
  $r qplot {title "Number of empty shoptype messages per minute"
            x ts y number xlab "Date/time" ylab "#messages"
            ymin 0 geom point
            x.breaks hour
            width 11 height 7}
  $r query "select strftime('%Y-%m-%d %H:%M', substr(ts, 1, 19))||':00' ts, count(*) number
            from atglogs
            where message = 'Empty shoptype id is passed to the GetSitesPerShopTypeDroplet droplet'
            group by 1"
  $r qplot title "Number of empty shoptype messages per minute - all" \
            x ts y number xlab "Date/time" ylab "#messages" \
            ymin 0 geom point \
            x.breaks hour \
            width 11 height 7
  $r query "select strftime('%Y-%m-%d %H:%M', substr(ts, 1, 19))||':00' ts, server, count(*) number
            from atglogs
            where message = 'Empty shoptype id is passed to the GetSitesPerShopTypeDroplet droplet'
            group by 1,2"
  $r qplot title "Number of empty shoptype messages per minute - by server" \
            x ts y number xlab "Date/time" ylab "#messages" colour server \
            ymin 0 geom point \
            x.breaks hour \
            legend.position bottom \
            legend.direction horizontal \
            legend.ncol 4 \
            width 11 height 7            
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
