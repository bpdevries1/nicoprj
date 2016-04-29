#!/usr/bin/env tclsh86

# logs2db - convert BD Tracelogs to a sqlite db.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  if {$argv == ""} {
    set root_dir "c:/Nico/aaa/tracelogs" 
  } else {
    lassign $argv root_dir
  }
  set db_name [file join $root_dir "tracelogs.db"]
  set conn [open_db $db_name]
  set td_logfile [make_table_def_keys logfile {id} {path}]
  # 2014-09-09 13:20:09.302 IN 2332 Feitenregistratie.Proces.VerwerkenMelding.ServiceHost MeldingBurgerVraagtToeslagAan 393d79ecc3bf47b695c01be8fddb1b35 LazyWriter.Write
  # ServiceHost MeldingBurgerVraagtToeslagAan   00:00:04.8707583
  set td_log [make_table_def_keys log {id} {logfile_id {linenr int} ts_utc ts_cet {ts_sec float} logtype threadid {resptime_sec float}}]
  create_table $conn $td_logfile 1
  create_table $conn $td_log 1
  set is_logfile [prepare_insert_td_proc $conn $td_logfile]
  set is_log [prepare_insert_td_proc $conn $td_log]
  handle_dir_rec $root_dir "*" [list read_logfile $conn $is_logfile $is_log]
  create_indices $conn
  $conn close
}

proc read_logfile {conn is_logfile is_log logfilename rootdir} {
  log info "Reading logfile: $logfilename" 
  if {[file extension $logfilename] == ".db"} {
    log info "Ignoring db file: $logfilename"
    return
  }
  if {[file extension $logfilename] == ".errors"} {
    log info "Ignoring errors file: $logfilename"
    return
  }
  set logfile_id [$is_logfile [dict create path $logfilename] 1]
  log debug "fileid: $logfile_id"
  
  set f [open $logfilename r]
  set fe [open "$logfilename.errors" w]
  db_in_trans $conn {
    set linenr 0
    while {![eof $f]} {
      gets $f line
      incr linenr
      if {[string trim $line] == ""} {
        continue 
      } 
      if {[expr $linenr % 10000] == 0} {
        log info "Handled $linenr records, start a new transaction"
        db_eval $conn "commit"
        db_eval $conn "begin transaction"
      }
    
  # 2014-09-09 13:20:09.302 IN 2332 Feitenregistratie.Proces.VerwerkenMelding.ServiceHost MeldingBurgerVraagtToeslagAan 393d79ecc3bf47b695c01be8fddb1b35 LazyWriter.Write
  # ServiceHost MeldingBurgerVraagtToeslagAan   00:00:04.8707583
  #   set td_log [make_table_def_keys log {id} {logfile_id linenr ts_utc ts_cet {ts_sec float} logtype threadid line resptime_sec {float}}]

      lassign $line date time logtype threadid
      if {[lsearch {BS RS ES} $logtype] >= 0} {
        lassign [det_timestamps "$date $time"] ts_utc ts_cet ts_sec
        if {[regexp { +([0-9:.]+)$} $line z duration]} {
          set resptime_sec [to_sec $duration]
        } else {
          set resptime_sec 0
        }
        set d [vars_to_dict logfile_id linenr ts_utc ts_cet ts_sec logtype threadid resptime_sec]
        $is_log $d    
      }
    }
  }
  close $f
  close $fe
}

# @param ts_str 2014-09-09 13:40:57.631 (this is a UTC/GMT time w/o DLST)
proc det_timestamps {ts_str} {
  if {[regexp {^(.+)(\.\d+)$} $ts_str z ts_str_sec ts_msec]} {
    set ts [clock scan $ts_str_sec -format "%Y-%m-%d %H:%M:%S" -gmt 1]
    set ts_utc [clock format $ts -format "%Y-%m-%d %H:%M:%S" -gmt 1]
    set ts_cet [clock format $ts -format "%Y-%m-%d %H:%M:%S" -gmt 0]
    set sec [expr $ts + $ts_msec]
    list $ts_utc $ts_cet $sec
  } else {
    log warn "Cannot parse timestamp: $ts_str"
    list "" "" -1
  }
}

# @param duration 00:00:04.8707583
proc to_sec {duration} {
  if {[regexp {^(\d\d):(\d\d):(\d\d)(\.\d*)} $duration z hr mn sec msec]} {
    expr $hr * 3600 + $mn * 60 + $sec + $msec
  } else {
    log warn "Cannot parse duration: $duration"
    expr -1
  }
}

proc create_indices {conn} {
  db_eval $conn "create index ix_log_ts on log (ts_utc)"
}

main $argv


