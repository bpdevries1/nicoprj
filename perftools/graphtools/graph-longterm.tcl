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
    {dir.arg "c:/projecten/Philips/Shop-KN-longterm" "Directory that contains db and to put graphs"}
    {db.arg "history.db" "DB path (relative to dir)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
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
  graph_longterm $r
  $r doall
  $r cleanup
  $r destroy
}

# op run niveau, sommeer pages, sec_overhead_max per dag
# @todo replace strftime('%Y-%m-%d', r.ts_cet) date with something more convenient.
# @todo per page neerzetten, dus delen door 11.
proc graph_longterm {r} {
  # total times divided by 11
  $r query "select country, date, run_sec / 11 page_sec
            from runstat
            where 1*run_sec > 0"
  $r qplot {title "Average daily pageload time per country - 1"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line-point
            colour country
            width 11 height 7}
  $r qplot {title "Average daily pageload time per country - 2"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line
            facet country
            width 11 height 9}
            
  $r query "select date, avg(run_sec/11) page_sec
            from runstat
            where 1*run_sec > 0
            group by 1"
  $r qplot {title "Daily average pageload time"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line
            width 11 height 7}

  # page details
  $r query "select date, country, page_seq, page_sec
            from pagestat
            where 1*page_sec > 0"
  $r qplot {title "Daily pageload time per page and country"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line
            colour country
            facet page_seq
            width 11 height 12}
              
  $r query "select date, page_seq, avg(page_sec) page_sec
            from pagestat
            where 1*page_sec > 0
            group by 1,2"
  $r qplot {title "Daily average pageload time per page - 1"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line
            facet page_seq
            width 11 height 12}
  $r qplot {title "Daily average pageload time per page - 2"
            x date y page_sec
            ylab "Pageload (sec)"
            ymin 0
            geom line-point
            colour page_seq
            width 11 height 9}
            
  foreach country {NL DE FR UK US} {
    $r query "select date, country, page_seq, page_sec
              from pagestat
              where 1*page_sec > 0
              and country = '$country'"
    $r qplot [list title "Daily pageload time per page - $country" \
              x date y page_sec \
              ylab "Pageload (sec)" \
              ymin 0 \
              geom line \
              facet page_seq \
              width 11 height 12]
  }    
}

main $argv
