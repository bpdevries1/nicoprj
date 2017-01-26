# std packages
package require Tclx
package require csv
package require struct::list
package require struct::matrix
package require math

# eigen package
package require ndv

use libfp
require libio io

proc main {argc argv} {
  # global env ar_argv
  set options {
    {dir.arg "" "Directory with SQLite DB with read typeperf files."}
    {db.arg "perfmon.db" "Database name"}
    {config.arg "stats.tcl" "Config file (relative to dir) with time segments to use etc."}
    {loglevel.arg "info" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # array set ar_argv [::cmdline::getoptions argv $options $usage]
  set opt [getoptions argv $options $usage]
  # array set ar_argv $opt
  set_log_global [:loglevel $opt]
  
  # check_params $argc $argv
  # set root_dir [lindex $argv 0]
  set root_dir [:dir $opt]
  # regsub -all {\\} $root_dir "/" root_dir
  set root_dir [file normalize $root_dir]
  # puts "root_dir: $root_dir"
  # for_recursive_glob filename $root_dir "*typeperf*.csv" {}
  set dbname [file join $root_dir [:db $opt]]
  set db [dbwrapper new $dbname]
  $db load_percentile

  report_stats $db $root_dir $opt 
  $db close
}

proc report_stats {db root_dir opt} {
  set config_file [file join $root_dir [:config $opt]]
  # segments and counters read from config.
  if {[file exists $config_file]} {
    source $config_file
  } else {
    log warn "Config file not found: $config_file"
    return
  }
  io/with_file f [open [file join $root_dir report-stats.html] w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "Resource logging statistics" 0
    foreach segment $segments {
      write_segment_stats $db $hh $segment $counters
    }
    $hh write_footer
  }
}

proc write_segment_stats {db hh segment counters} {
  $hh heading 1 "Stats for: [segment->string $segment]"
  foreach counter $counters {
    write_segment_counter_stats $db $hh $segment $counter
  }
}

proc segment->string {segment} {
  lassign $segment start end name
  return "$name \[$start -> $end\]"
}

proc write_segment_counter_stats {db hh segment counter} {
  lassign $counter counter_spec treshold_show treshold_error
  set spec_str [string trim $counter_spec "%"]
  lassign $segment _ _ segm_name
  $hh heading 2 "Stats for $spec_str"
  $hh table {
    $hh table_header Computer Object Instance Counter Minimum Average "95%" Maximum
    set query "select c.computer, c.object, c.instance, c.counter,
                      s.min_val, s.avg_val, s.p95_val, s.max_val
               from stats s
               join countername c on c.tablename = s.tablename
                  and c.fieldname = s.fieldname
               where c.csvfield like '$counter_spec'
               and s.segm_name = '$segm_name'
               and s.avg_val $treshold_show"
    
    log debug "query: $query"
    foreach row [$db query $query] {
      $hh table_row_start
      foreach field {computer object instance counter} {
        $hh table_data [:$field $row]
      }
      foreach field {min_val avg_val p95_val max_val} {
        set value [:$field $row]
        set class ""
        # see if this works with treshold as ">80"
        if {[expr $value $treshold_error]} {
          set class "class=\"Failure\"" 
        }
        $hh table_data [format %.3f $value] 0 $class
      }
      $hh table_row_end
    }
  }
  
}

main $argc $argv

