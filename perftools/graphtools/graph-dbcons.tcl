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
    {dir.arg "~/Ymor/Philips/Shop/dbconns" "Directory that contains db and to put graphs"}
    {db.arg "dbcon.db" "DB path (relative to dir)"}
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
  $r query "select ts_cet ts, number
            from dbcon
            where machine = '<total>'
            and username = '<total>'
            order by ts_cet"
  $r qplot {title "Total #connections"
            x ts y number xlab "Date/time" ylab "#connections"
            ymin 0 geom point
            x.breaks hour
            width 11 height 7}
            
  $r query "select ts_cet ts, machine, number
            from dbcon
            where machine <> '<total>'
            and username = '<total>'
            order by ts_cet"
  $r qplot {title "Total #connections per machine"
            x ts y number xlab "Date/time" ylab "#connections"
            ymin 0 geom point
            colour machine
            x.breaks hour
            width 11 height 7}
  $r qplot {title "Total #connections per machine - facet"
            x ts y number xlab "Date/time" ylab "#connections"
            ymin 0 geom point
            facet machine
            x.breaks hour
            width 11 height 20}            

  $r query "select ts_cet ts, machine, machinegroup, number
            from dbcon
            where machine <> '<total>'
            and username = '<total>'
            order by ts_cet"
  $r qplot {title "Total #connections per machine-group"
            x ts y number xlab "Date/time" ylab "#connections"
            ymin 0 geom point
            colour machine
            facet machinegroup
            x.breaks hour
            width 11 height 14}
            
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
