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
    {dir.arg "c:/projecten/Philips/KNDL/CorpLanding-US" "Directory that contains db and to put graphs"}
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
  # make_graphs $dargv
  make_graphs_de $dargv
}

proc make_graphs {dargv} {
  set r [Rwrapper new $dargv]
  $r init [:dir $dargv] [:db $dargv] [:Rfileadd $dargv]
  # $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]
  graph_all $r "2014-01-01"
  $r doall
  $r cleanup
  $r destroy
}

proc make_graphs_de {dargv} {
  set dargv [dict merge $dargv [dict create dir "c:/projecten/Philips/KNDL/CBF-DE-55PFL6007K"]]
  set r [Rwrapper new $dargv]
  $r init [:dir $dargv] [:db $dargv] [:Rfileadd $dargv]
  # $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]
  graph_all_de $r "2014-01-01" 4 "http://assets.pinterest.com/js/pinit_main.js"
  $r doall
  $r cleanup
  $r destroy
}

proc graph_all {r from} {
  $r query "select r.date_cet date, page_time_sec reported, page_ttip_sec ttip,
                   0.001*avg(i.start_msec+i.element_delta) atf
            from aggr_run r join pageitem i on i.date_cet = r.date_cet
            where  r.date_cet >= '$from'
            and i.url = 'http://www.usa.philips.com/content/dam/corporate/homepage-articles/master/DisneyLivingColors/Disney-LivingColors_BG.jpg'
            group by 1,2,3"
  $r melt {reported ttip atf}
  $r qplot title "Reported Load times, ttip and atf averaged per day since $from" \
          x date y value xlab "Date" ylab "Load time (seconds)" \
          geom line-point colour variable \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
}

proc graph_all_de {r from page_seq atf_url} {
  $r query "select p.date_cet date, p.avg_time_sec reported, p.avg_ttip_sec ttip,
                   0.001*avg(i.start_msec+i.element_delta) atf
            from aggr_page p join pageitem i on i.date_cet = p.date_cet
            where  p.date_cet >= '$from'
            and 1*p.page_seq = $page_seq
            and i.url = '$atf_url'
            group by 1,2,3"
  $r melt {reported ttip atf}
  $r qplot title "Reported Load times, ttip and atf averaged per day since $from" \
          x date y value xlab "Date" ylab "Load time (seconds)" \
          geom line-point colour variable \
          width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24  \
          legend.position right \
          legend.direction vertical
}

main $argv
