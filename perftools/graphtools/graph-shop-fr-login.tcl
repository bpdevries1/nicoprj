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
    {dir.arg "c:/projecten/Philips/KNDL/Shop-Browsing-Flow-FR-SC2002" "Directory that contains db and to put graphs"}
    {db.arg "keynotelogs.db" "DB path (relative to dir)"}
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
  #$r query "select strftime('%Y-%m-%d %H', ts_cet)||':00:00' ts, avg(element_delta)"

  $r query "select date_cet date, 1*strftime('%H', ts_cet) hour, avg(0.001*element_delta) loadtime
            from pageitem
            where url like 'https://www.philips-shop.fr/store/checkout/login.jsp%'
            and ts_cet between '2013-09-12 00:00' and '2013-09-20 00:00'
            group by 1,2
            order by 1,2"
  $r qplot {title "Average hourly loading time of login.jsp"
            x hour y loadtime xlab "Hour" ylab "Load time (sec)"
            ymin 0 geom point
            facet date
            width 11 height 12}
            
  # ook nog alleen per uur, dan wel tijd voor en na 16-9.
  # doe maar erna, na 18-9
  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*element_delta) loadtime
            from pageitem
            where url like 'https://www.philips-shop.fr/store/checkout/login.jsp%'
            and ts_cet between '2013-09-18 00:00' and '2013-09-29 00:00'
            group by 1
            order by 1"
  $r qplot {title "Average hourly loading time of login.jsp after week 38."
            x hour y loadtime xlab "Hour" ylab "Load time (sec)"
            ymin 0 geom point
            width 11 height 7}
            
  # aantallen dat 'ie boven de 5 seconden zit.
  $r query "select date_cet date, 1*strftime('%H', ts_cet) hour, count(element_delta) number
            from pageitem
            where url like 'https://www.philips-shop.fr/store/checkout/login.jsp%'
            and ts_cet between '2013-09-12 00:00' and '2013-09-20 00:00'
            and 0.001 * element_delta > 5
            group by 1,2
            order by 1,2"
  $r qplot {title "Daily and hourly count of items having loadtime higher than 5 seconds for login.jsp"
            x hour y number xlab "Hour" ylab "#items"
            ymin 0 geom point
            facet date
            width 11 height 12}
            
  # ook nog alleen per uur, dan wel tijd voor en na 16-9.
  # doe maar erna, na 18-9
  $r query "select 1*strftime('%H', ts_cet) hour, count(element_delta) number
            from pageitem
            where url like 'https://www.philips-shop.fr/store/checkout/login.jsp%'
            and ts_cet between '2013-09-18 00:00' and '2013-09-29 00:00'
            and 0.001 * element_delta > 5
            group by 1
            order by 1"
  $r qplot {title "Hourly avg count of items having loadtime higher than 5 seconds for login.jsp"
            x hour y number xlab "Hour" ylab "avg #items"
            ymin 0 geom point
            width 11 height 7}
  
  # naar totale scripttijd kijken per uur.
  $r query "select 1*strftime('%H', ts_cet) hour, avg(0.001*delta_user_msec) loadtime
            from scriptrun
            where ts_cet between '2013-09-18 00:00' and '2013-09-29 00:00'
            group by 1
            order by 1"
  $r qplot {title "Hourly avg total loading time"
            x hour y loadtime xlab "Hour" ylab "Avg total loading time"
            ymin 0 geom point
            width 11 height 7}
  
  
}


main $argv
