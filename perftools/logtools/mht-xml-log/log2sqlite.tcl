#!/home/nico/bin/tclsh

package require Tclx
package require sqlite3
package require tdom

# own package
package require ndv

#::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
#::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc log {args} {
  global log
  $log {*}$args
}

proc main {} {
  set tmp_db "/tmp/mht.db"
  set src_dir "/media/nas/aaa/rws/mht"
  make_db $tmp_db
  read_data [file join $src_dir log.xml]
  db close
  file delete [file join $src_dir mht.db]
  file rename $tmp_db [file join $src_dir mht.db]
}

proc make_db {tmp_db} {
  sqlite3 db $tmp_db
  db eval "drop table if exists quser"
  db eval "create table quser (id integer primary key autoincrement, 
            urlmain, urlquery, start, end, duration, nqdb)"
  db eval "drop table if exists qdb"
  db eval "create table qdb (id integer primary key autoincrement, 
            quser_id, opertype, urlquery, restype, start, end, duration)"
  db eval "delete from qdb"
  db eval "delete from quser"  
}

proc read_data {filename} {
  set f [open $filename r]
  set doc [dom parse -channel $f]
  set root [$doc documentElement]
  # $root nodeName
  set reqs [$root selectNodes {/html/body/table/tbody/tr}]
  set quser_id ""
  set last_req ""
  set qdb_datetime_start ""
  set date ""
  set nqdb 0
  set i 0
  foreach req $reqs {
    if {[$req @class none] == "script"} {
      # user query 
      # handle previous quser with last qdb
      handle_last_qdb $quser_id $last_req $qdb_datetime_start $date $nqdb
      lassign [insert_quser $req] quser_id date
      set qdb_datetime_start ""
      set nqdb 0
    } else {
      # underlying db query
      set datetime [insert_qdb $req $quser_id $date]
      if {$qdb_datetime_start == ""} {
        set qdb_datetime_start $datetime 
      }
      incr nqdb
    }
    set last_req $req
    incr i
    if {$i % 100 == 0} {
      log debug "Handled reqs: $i" 
    }
  }
  close $f
}

# @return list: quser_id, date (dd-mm-yyyy)
proc insert_quser {req} {
  if {[regexp {^([0-9\-]+) ([^\?]+)(\?(.*))?$} [string trim [[$req selectNode td] asText]] z dt urlmain urlquery]} {
    set date [clock format [clock scan $dt -format "%d-%m-%Y"] -format "%Y-%m-%d"]
    db eval {insert into quser (urlmain, urlquery) values ($urlmain, $urlquery)}  
    set quser_id [db last_insert_rowid]
  } else {
    error "Could not parse user query: [[$req selectNode td] asText]" 
  }
  list $quser_id $date
}

# @return dt_start 
proc insert_qdb {req quser_id date} {
  lassign [det_time_opertype [string trim [[$req selectNodes {td[1]}] asText]] $date] dt_start opertype
  if {$dt_start == ""} {
    return "" 
  }
  set query [string trim [[$req selectNodes {td[2]}] asText]]
  # td[3] could be empty, no object
  lassign [det_duration_result $req] duration_ms queryresult
  set dt_end [calc_datetime_end $dt_start $duration_ms]
  # quser_id, opertype, urlquery, restype, start, end, duration
  db eval {insert into qdb (quser_id,  opertype,  urlquery, restype,      start,      end,    duration) values
                           ($quser_id, $opertype, $query,   $queryresult, $dt_start, $dt_end, $duration_ms)}
  return $dt_start  
}

# todo handle cases with 0, 1 or more underlying db queries.
# 0: no end time to be noted, check in db, but not so interesting.
# 1: should be ok
# >1: should be ok.
proc handle_last_qdb {quser_id last_req qdb_datetime_start date nqdb} {
  if {$quser_id == ""} {
    return 
  }
  lassign [det_time_opertype [string trim [[$last_req selectNodes {td[1]}] asText]] $date] qdb_last_datetime_start z
  lassign [det_duration_result $last_req] duration_ms z
  set datetime_end [calc_datetime_end $qdb_last_datetime_start $duration_ms]
  # urlmain, urlquery, start, end, duration)
  # @todo also calc duration? or do in DB or R.
  set duration [expr int(1000 * ([parse_datetime $datetime_end] - [parse_datetime $qdb_datetime_start]))]
  db eval {update quser
           set start = $qdb_datetime_start, 
               end   = $datetime_end,
               duration = $duration,
               nqdb = $nqdb
           where id = $quser_id}
}

# @param str: 12:43:50.288 or 12:43:50.288 .. {opertype}
# @return list: datetime, opertype
proc det_time_opertype {str date} {
  if {[regexp {^([0-9:\.]+)([^\{]+\{([^\}]+)\})?$} $str z time z opertype]} {
    list "$date $time" $opertype 
  } elseif {[regexp {Logging was reset} $str]} {
    list "" ""
  } else {
    error "Cannot determine time and optional opertype from: $str" 
  }
}

# @param str: 123ms => list 123 ok
# @param str: blanco => list 0 blank
# @param str: 16ms\nN/R => list 16 N/R
# @param str: <1ms => list 0 <1ms, optional N/R also
# @param str: instead of N/R, #P# is also possible,
# @return list: duration, result
proc det_duration_result {req} {
  set td3 [$req selectNodes {td[3]}]
  if {$td3 == ""} {
    return [list 0 "blank"]
  } 

  set str [string trim [$td3 asText]]
  if {$str == ""} {
    list 0 blank 
  } elseif {[regexp {^([0-9]+)ms(.*)$} $str z msec code]} {
    set code [string trim $code]
    if {$code == ""} {
      list $msec ok 
    } else {
      list $msec $code 
    }
  } elseif {[regexp {^<1ms(.*)$} $str z code]} {
    set code [string trim $code]
    if {$code == ""} {
      list 0 "<1ms" 
    } else {
      list 0 "<1ms;$code" 
    }
  } else {
    error "Could not parse duration/result from: $str" 
  }
}

proc calc_datetime_end {dt_start duration_ms} {
  # @todo implement correctly
  # return $dt_start
  format_datetime [expr [parse_datetime $dt_start] + 0.001 * $duration_ms]
}

# parse a time with fractional seconds
proc parse_datetime {str} {
  if {![regexp {^(.+)(\..+)$} $str z whole frac]} {
    set whole $str
    set frac 0.0
  }
  expr [clock scan $whole -format "%Y-%m-%d %H:%M:%S"] + $frac 
}

# format a time with fractional seconds
proc format_datetime {sec} {
  set whole [expr int($sec)]
  set msec [expr int(($sec - $whole) * 1000)]
  return "[clock format $whole -format "%Y-%m-%d %H:%M:%S"].[format %03d $msec]"
}

main

