#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
source [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "~/Ymor/Philips/Shop" "Directory that contains db and to put graphs"}
    {db.arg "dashboards.db" "DB path (relative to dir)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  prepare_db $dargv
  make_graphs $dargv
}

proc prepare_db {dargv} {
  set db [dbwrapper new [file join [:dir $dargv] [:db $dargv]]]
  $db exec2 "create table if not exists nruns as
             select strftime('%Y-%m-%d', ts_cet) date, scriptname, count(*) nruns
             from page_td2
             group by 1,2" -log
  $db close             
}

proc make_graphs {dargv} {
  set r [Rwrapper new]
  $r init [:dir $dargv] [:db $dargv]
  graph_overhead_run $r
  
  $r doall
  $r cleanup
  $r destroy
}

# op run niveau, sommeer pages, sec_overhead_max per dag
# @todo replace strftime('%Y-%m-%d', r.ts_cet) date with something more convenient.
# @todo per page neerzetten, dus delen door 11.
proc graph_overhead_run {r} {
  $r query "select p.scriptname, strftime('%Y-%m-%d', p.ts_cet) date, sum(p.sec_overhead_max)/(n.nruns * 11) overhead
    from page_td2 p
      join nruns n on n.date = strftime('%Y-%m-%d', p.ts_cet) and n.scriptname = p.scriptname
    group by 1,2"
  $r qplot {title "Average daily Tradedoubler maximum overhead per country per page"
            x date y overhead
            ylab "Overhead (seconds)"
            ymin 0
            geom line-point
            colour scriptname
            width 11 height 7}
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
