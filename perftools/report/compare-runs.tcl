#!/usr/bin/env tclsh

# Main entry point to read/report a whole dir of performance results, for different
# types of tools (eg AHK and Vugen/Loadrunner)

package require ndv

set_log_global perf {showfilename 0}
# set_log_global debug {showfilename 0}

# source read-vuserlogs-db.tcl
# ndv::source_once vuser-report.tcl

# this scripts knows the readers:
# first in global namespace:
set perftools_dir [file normalize [file join [file dirname [info script]] ..]]
# puts "perftools_dir: $perftools_dir"
ndv::source_once report-run-dir.tcl

proc main {argv} {
  global argv0 log
  log info "$argv0 called with options: $argv"
  set options {
    {rootdir.arg "" "Directory with subdirs with vuserlog files and sqlite db's"}
    {dirs.arg "" "List of subdirs (separated by :) to compare, relative to rootdir"}
    {todir.arg "" "Result/compare subdirectory, relative to rootdir"}
    {debug "set loglevel debug"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]

  if {[:debug $opt]} {
    $log set_log_level debug  
  }

  compare_dirs $opt
}

proc compare_dirs {opt} {
  set rootdir [:rootdir $opt]
  set todir [file join $rootdir [:todir $opt]]
  file mkdir $todir
  set db [get_compare_db [file join $todir "run-compare.db"] $opt]
  $db exec "delete from summary"
  $db exec "delete from testrun"
  set compare_order 0
  foreach dir [split [:dirs $opt] ":"] {
    incr compare_order
    copy_run_data $db [file join $rootdir $dir] $compare_order
  }
  # TODO: make summary html with all results.
  report_compare_summary_html $db $todir
}

proc copy_run_data {db fromdir compare_order} {
  # attach other db.
  set fromdbname [file join $fromdir testrunlog.db]
  $db exec "attach database '$fromdbname' as fromDB"
  $db in_trans {
    set table summary
    set run [file tail $fromdir]
    log info "Copying table $table"
    # TODO: fields afleiden uit tabledef van todb.
    set fields "usecase, resulttype, transshort, min_ts, resptime_min, resptime_avg, resptime_max, resptime_p95, npass, nfail"
    $db exec "insert into $table (run, $fields) select '$run' run, $fields from fromDB.$table"
    $db insert testrun [vars_to_dict run compare_order]    
  }
  $db exec "detach database fromDB"
}

proc get_compare_db {db_name opt} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables_compare $db $opt
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  $db load_percentile
  return $db
}

proc define_tables_compare {db opt} {
  # [2016-07-31 12:01] sec_ts is a representation of a timestamp in seconds since the epoch, no timezone influence.
  $db def_datatype {sec_ts resptime} real
  $db def_datatype {.*id filesize .*linenr.* trans_status iteration.* compare_order} integer
  # default is text, no need to define, just check if it's consistent
  # [2016-07-31 12:01] do want to define that everything starting with ts is a timestamp/text:
  $db def_datatype {status ts.*} text
  
  # summary table, per usecase and transaction. resptime fields already defined als real.
  $db def_datatype {npass nfail} integer
  $db add_tabledef summary {id} {run usecase resulttype transshort min_ts resptime_min resptime_avg resptime_max resptime_p95 npass nfail}
  $db add_tabledef testrun {id} {run compare_order}
}

proc report_compare_summary_html {db dir} {
  set html_name [file join $dir "report-compare-summary.html"]
  if {[file exists $html_name]} {
    # return ; # or maybe a clean option to start anew
  }
  io/with_file f [open $html_name w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "Performance test comparison report" 0
    set query "select usecase, min(min_ts) min_ts from summary group by 1 order by 2"
    foreach row [$db query $query] {
      report_compare_summary_html_usecase $db $hh $row
    }
    $hh write_footer
  }
}

proc report_compare_summary_html_usecase {db hh row} {
  set usecase [:usecase $row]
  $hh heading 1 "Usecase: $usecase"
  $hh table_start
  $hh table_header Transaction Run Minimum Average 95% Maximum Pass Fail "Fail%"

  # first select transactions ordered by min_ts. Then for each, select data from all runs.
  set query "select distinct transshort from summary order by resulttype, min_ts"
  foreach trow [$db query $query] {
    set query "select s.run, resptime_min, resptime_avg, resptime_p95, resptime_max, npass, nfail
             from summary s join testrun t on s.run = t.run
             where usecase = '[:usecase $row]'
             and transshort = '[:transshort $trow]'
             order by t.compare_order"
    log debug "Query**: $query"
    set trres [$db query $query]
    set firstrow [:0 $trres]
    set atfirst 1
    foreach trrow $trres {
      log debug "summary trrow: $trrow"
      $hh table_row_start
      $hh table_data [:transshort $trow]
      $hh table_data [:run $trrow]
      if 0 {
        $hh table_data [:resptime_min $trrow]
        $hh table_data [format %.3f [:resptime_avg $trrow]]
        set clazz [p95_class [:transshort $trrow] [:resptime_p95 $trrow]]
        $hh table_data [format %.3f [:resptime_p95 $trrow]] 0 "class=\"$clazz\""
        $hh table_data [:resptime_max $trrow]
        $hh table_data [:npass $trrow] 
        $hh table_data [:nfail $trrow]
      } else {
        foreach key {:resptime_min :resptime_avg :resptime_p95 :resptime_max} {
          table_data_comp $hh $atfirst $key $firstrow $trrow
        }
        $hh table_data [:npass $trrow] 
        $hh table_data [:nfail $trrow]
      }
      $hh table_data {*}[perc_failed [:npass $trrow] [:nfail $trrow]]      
      $hh table_row_end
      set atfirst 0
    }
  }
  $hh table_end
}

proc table_data_comp {hh atfirst key firstrow row} {
  set clazz [p95_class [:transshort $row] [$key $row]]
  set fval [format %.1f [$key $row]]
  if {$atfirst} {
    set str $fval
  } else {
    if {$fval <= 0.0} {
      set str $fval
    } else {
      set str "$fval ([calc_diff $key $firstrow $row])"
    }
  }
  $hh table_data $str 0 "class=\"$clazz\""
  # $hh table_data [$key $row]
}

proc calc_diff {key firstrow row} {
  set firstval [$key $firstrow]
  set val [$key $row]
  set diff [expr $val - $firstval]
  format "%+.1f" $diff
}

proc p95_class {transshort resptime_p95} {
  switch $transshort {
    "Do_upload" {
      if {$resptime_p95 > 45} {
        return Failure
      } else {
        return ""
      }
    }
    default {
      if {$resptime_p95 > 3} {
        return Failure
      } else {
        return ""
      }
    }
  }
}

proc perc_failed {npass nfail} {
  set total [expr $npass + $nfail]
  if {$total <= 0} {
    return [list "0%" 0 ""]
  }
  set perc [expr 100.0 * $nfail / ($npass + $nfail)]
  if {$perc >= 5.0} {
    set clazz Failure
  } else {
    set clazz ""
  }
  list [format "%.1f%%" $perc] 0 "class=\"$clazz\""
}

if {[this_is_main]} {
  main $argv
}
