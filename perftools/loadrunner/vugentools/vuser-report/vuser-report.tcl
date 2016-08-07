#!/usr/bin/env tclsh

# create html report based on vuser results read into sqlite DB.
# TODO: call directly, for PC/ALM tests.
# first only based on output.txt in vugen script dir.

require libio io

proc vuser_report {dir dbname opt} {
  puts "TODO - make report in dir: $dir with opt: $opt"
  if {[:all $opt]} {
    set opt [dict merge $opt [dict create full 1 summary 1]]
  }
  set report_made 0
  set db [get_results_db $dbname [:ssl $opt]]
  if {[:full $opt]} {
    vuser_report_full $db $dir
    set report_made 1
  }
  if {!$report_made} {
    puts "No report made, specify an option (or help)"
  }
}

# create full report where every transaction and error is visible in the report.
# maybe one html per vuser, possible TODO:
# maybe use user/script definitions for report, eg which fields to use as result of
# split_trans. Could also check which fields have more than 1 different value, or are
# not empty. Also (with eg newuser/revisit) could check if value varies during this
# block/iteration: if so, make a column. If not, add above table.
proc vuser_report_full {db dir} {
  set html_name [file join $dir "report-full.html"]
  if {[file exists $html_name]} {
    # return ; # or maybe a clean option to start anew
  }
  io/with_file f [open $html_name w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "Vuser log report" 0
    set query "select vuserid, iteration_start, usecase, user,
               min(ts_start) ts_min, max(ts_end) ts_max
               from trans
               group by 1,2,3,4
               order by 1,2,5"
    foreach row [$db query $query] {
      vuser_report_iter_user $db $row $hh
    }
    $hh write_footer
  }
}

proc vuser_report_iter_user {db row hh} {
  $hh heading 1 "Iteration: [:iteration_start $row] / usecase: [:usecase $row] / user: [:user $row][vuser_str $row]"
  $hh line "[:ts_min $row] => [:ts_max $row]"
  # $hh table body ook leuk? Ook vgl clojure/hiccup.
  $hh table_start
  $hh table_header Transaction Result Resp.time Start End
  # [2016-08-02 13:40:10] + 0 if var is empty
  set query "select transshort, trans_status, resptime, ts_start, ts_end
             from trans
             where vuserid = [:vuserid $row] + 0
             and iteration_start = [:iteration_start $row] + 0
             and user = '[:user $row]'
             order by ts_start"
  log debug "Query: $query"
  foreach trow [$db query $query] {
    $hh table_row_class [vuser_row_class $trow] [:transshort $trow] \
        [status_text $trow] \
        [format "%.3f" [:resptime $trow]] \
        [time_part [:ts_start $trow]] [time_part [:ts_end $trow]]
  }
  $hh table_end

  # Check if there were errors in this iteration
  # [2016-08-02 13:41:59] + 0 for when fields are empty.
  set query "select ts, line
             from error
             where vuserid = [:vuserid $row] + 0
             and iteration = [:iteration_start $row] + 0
             and user = '[:user $row]'
             order by ts"
  set res [$db query $query]
  if {[:# $res] > 0} {
    $hh table_start
    $hh table_header Time Message
    foreach erow $res {
      # $hh set_colour red - dan wel ook bij andere dingen dan table te doen.
      # of algemeen een set-option.
      $hh table_row_class Failure [time_part [:ts $erow]] [:line $erow]
      # $hh reset_colour
    }
    $hh table_end
  }
}

proc vuser_row_class {trow} {
  if {[:trans_status $trow] == 0} {
    return ""
  } elseif {[:trans_status $trow] == 4} {
    return "Warning"
  } else {
    return "Failure"
  }
}

proc vuser_str {row} {
  if {[:vuserid $row] != -1} {
    return " / vuser: [:vuserid $row]"  
  }
  return ""
}

proc status_text {trow} {
  set st [:trans_status $trow]
  switch $st {
    -1 {
      set res "Error"
    }
    0 {
      set res "Ok"
    }
    1 {
      set res "Fail"
    }
    4 {
      set res "Warning"
    }
    default {
      set res "Unknown"
    }
  }
  return "$res ($st)"
}

proc time_part {ts} {
  lindex [split $ts " "] 1
}
