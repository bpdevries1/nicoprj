#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/CQ5-CN/Author" "Directory to make graphs for/in (in daily/graphs)"}
    {dbname.arg "jtldb.db" "DB name within dir to use"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set r [Rwrapper new $dargv]
  $r main {
    #graph_scriptrun $r $dargv
    #graph_page $r $dargv
    #graph_extension $r $dargv
    graph_slowitems $r $dargv
  }
}

proc graph_scriptrun {r dargv} {
  $r query "select ts_utc_run ts, run_id, testtype, run_sec
            from scriptrun"

  $r qplot title "Scriptrun times" \
            x ts y run_sec xlab "Date/time (UTC)" ylab "Total run time (sec)" \
            geom line-point colour testtype \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype avg avgdec 3 position bottom direction horizontal}
            
  $r qplot title "Scriptrun times (2)" \
            x run_id y run_sec xlab "run ID" ylab "Total run time (sec)" \
            geom line-point colour testtype \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype avg avgdec 3 position bottom direction horizontal}
            
}                

proc graph_page {r dargv} {
  $r query "select ts_utc_run ts, run_id, testtype, useraction, loadtime_sec
            from page"

  $r qplot title "Page times by user action" \
            x ts y loadtime_sec xlab "Date/time (UTC)" ylab "Page time (sec)" \
            geom line-point colour testtype facet useraction \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype avg avgdec 3 position bottom direction horizontal}

  $r qplot title "Page times by user action (2)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Page time (sec)" \
            geom point colour testtype facet useraction \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype avg avgdec 3 position bottom direction horizontal}
            
  $r qplot title "Page times by test type" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Page time (sec)" \
            geom line-point colour useraction facet testtype \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype avg avgdec 3 position right direction vertical}
            
}                

proc graph_extension {r dargv} {
  # only 'sequential' runs.
  # first per run
  $r query "select run_id, lower(extension) extension, sum(loadtime_sec) loadtime_sec from page_stats_ct
            where testtype = 'sequential'
            group by 1,2"
  $r qplot title "Sum of load times per extension" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour extension \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype sum avgdec 3 position right direction vertical}

  $r query "select run_id, lower(extension) extension, sum(loadtime_sec) loadtime_sec from page_stats_ctc
            where testtype = 'sequential'
            and maxage not in ('86400','432000')
            group by 1,2"
  $r qplot title "Sum of load times per extension (uncacheable)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour extension \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            legend {avgtype sum avgdec 3 position right direction vertical}
}

proc graph_slowitems {r dargv} {
  $r query "select r.run_id, s.lb url, round(0.001*avg(s.t),3) loadtime_sec 
            from httpsample s join scriptrun2 r on r.ts_utc_run = s.ts_utc_run
            where r.testtype = 'sequential'
            and s.level = 1
            group by 1,2"
  $r qplot title "Slowest page items (all, sequential)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

  graph_slowitems_sub $r $dargv "sequential"
  graph_slowitems_sub $r $dargv "minimal"
  graph_slowitems_sub $r $dargv "sequential" "cache=0"
  
  graph_slowitems_ttfb_sub $r $dargv "sequential"
  graph_slowitems_ttfb_sub $r $dargv "minimal"
  graph_slowitems_ttfb_sub $r $dargv "sequential" "cache=0"

  graph_slowitems_ttlb_sub $r $dargv "sequential"
  graph_slowitems_ttlb_sub $r $dargv "minimal"
  graph_slowitems_ttlb_sub $r $dargv "sequential" "cache=0"
}

proc graph_slowitems_sub {r dargv testtype {extra ""}} {
  if {$extra == ""} {
    set sqlextra ""
    set titleextra ""
  } else {
    if {$extra == "cache=0"} {
      set sqlextra "and s.maxage not in ('86400','432000')"
      set titleextra ", $extra"
    } else {
      error "Don't know how to handle: $extra"
    }
  }
  # per page
  $r query "select r.run_id, s.lb url, round(0.001*avg(s.t),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2"
  $r qplot title "Slowest page items (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

  # by page
  $r query "select r.run_id, p.useraction, s.lb url, round(0.001*avg(s.t),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2,3"
  $r qplot title "Slowest page items by page (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url facet useraction \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

}

proc graph_slowitems_ttfb_sub {r dargv testtype {extra ""}} {
  if {$extra == ""} {
    set sqlextra ""
    set titleextra ""
  } else {
    if {$extra == "cache=0"} {
      set sqlextra "and s.maxage not in ('86400','432000')"
      set titleextra ", $extra"
    } else {
      error "Don't know how to handle: $extra"
    }
  }
  # per page
  $r query "select r.run_id, s.lb url, round(0.001*avg(s.lt),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2"
  $r qplot title "Slowest page items TTFB (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

  # by page
  $r query "select r.run_id, p.useraction, s.lb url, round(0.001*avg(s.lt),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2,3"
  $r qplot title "Slowest page items by page TTFB (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url facet useraction \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

}

proc graph_slowitems_ttlb_sub {r dargv testtype {extra ""}} {
  if {$extra == ""} {
    set sqlextra ""
    set titleextra ""
  } else {
    if {$extra == "cache=0"} {
      set sqlextra "and s.maxage not in ('86400','432000')"
      set titleextra ", $extra"
    } else {
      error "Don't know how to handle: $extra"
    }
  }
  # per page
  $r query "select r.run_id, s.lb url, round(0.001*avg(s.t-s.lt),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2"
  $r qplot title "Slowest page items TTLB (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

  # by page
  $r query "select r.run_id, p.useraction, s.lb url, round(0.001*avg(s.t-s.lt),3) loadtime_sec 
            from httpsample s 
              join page p on s.parent_id = p.page_id
              join scriptrun2 r on r.ts_utc_run = p.ts_utc_run
            where r.testtype = '$testtype'
            and s.level = 1
            and p.useraction like '0_-%'
            $sqlextra
            group by 1,2,3"
  $r qplot title "Slowest page items by page TTLB (1-9, $testtype$titleextra)" \
            x run_id y loadtime_sec xlab "Run ID" ylab "Load time (sec)" \
            geom line-point colour url facet useraction \
            width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
            maxcolours 15 \
            legend {avgtype avg avgdec 3 position bottom direction vertical}

}

main $argv
