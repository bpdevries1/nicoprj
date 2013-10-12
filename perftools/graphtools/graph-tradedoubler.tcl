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
    {dir.arg "~/Ymor/Philips/Shop" "Directory that contains db and to put graphs"}
    {db.arg "dashboards.db" "DB path (relative to dir)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
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
  set r [Rwrapper new $dargv]
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
  #$r query "select p.scriptname, strftime('%Y-%m-%d', p.ts_cet) date, 
  #  sum(p.sec_overhead_max)/(n.nruns * 11) overhead
  #  from page_td2 p
  #    join nruns n on n.date = strftime('%Y-%m-%d', p.ts_cet) and n.scriptname = p.scriptname
  #  group by 1,2"
  $r qplot {query "select p.scriptname, strftime('%Y-%m-%d', p.ts_cet) date, 
                    sum(p.sec_overhead_max)/(n.nruns * 11) overhead
                    from page_td2 p
                      join nruns n on n.date = strftime('%Y-%m-%d', p.ts_cet) and n.scriptname = p.scriptname
                    group by 1,2" 
            title "Average daily Tradedoubler maximum overhead per country per page"
            x date y overhead
            ylab "Overhead (seconds)"
            ymin 0
            geom line-point
            colour scriptname
            width 11 height 7}
  $r query "select p.scriptname, strftime('%Y-%m-%d', p.ts_cet) date, 
    sum(p.sec_overhead_max)/(n.nruns * 11) overhead,  
    sum(p.sec_elt_td)/(n.nruns * 11) tradedoubler,
    sum(p.sec_elt_after_td)/(n.nruns * 11) after_td,
    sum(p.sec_no_network_after_td_min)/(n.nruns * 11) no_network
    from page_td2 p
      join nruns n on n.date = strftime('%Y-%m-%d', p.ts_cet) and n.scriptname = p.scriptname
    group by 1,2"
  $r qplot {title "Average daily Tradedoubler related times per country per page"
            melt {overhead tradedoubler after_td no_network}
            x date 
            ylab "Times (seconds)"
            ymin 0
            geom line-point
            facet scriptname
            width 11 height 12}
  
  foreach country {NL DE FR UK} {            
    $r query "select p.scriptname, p.page_seq page_seq, strftime('%Y-%m-%d', p.ts_cet) date, 
      sum(p.sec_overhead_max)/(n.nruns) overhead,  
      sum(p.sec_elt_td)/(n.nruns) tradedoubler,
      sum(p.sec_elt_after_td)/(n.nruns) after_td,
      sum(p.sec_no_network_after_td_min)/(n.nruns) no_network
      from page_td2 p
        join nruns n on n.date = strftime('%Y-%m-%d', p.ts_cet) and n.scriptname = p.scriptname
      where p.scriptname like '%-$country-%'
      group by 1,2,3"
    # list en backslash nodig vanwege $country, anders in {} niet expanded...
    $r qplot [list title "Average daily Tradedoubler related times per country by page - $country" \
              melt {overhead tradedoubler after_td no_network} \
              x date \
              ylab "Times (seconds)" \
              ymin 0 \
              geom line-point \
              facet page_seq \
              width 11 height 20]
  }            
            
}

# @todo
# runs on windows?
# other graphs: other fields.
# longer period: then run queries again...

main $argv
