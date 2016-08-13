#!/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

# TODO: move this lib to a more central place: perftools/logreader?
ndv::source_once ../../loadrunner/vugentools/vuserlog/liblogreader.tcl
ndv::source_once ahk_parsers_handlers.tcl

# [2016-07-09 10:09] for parse_ts and now:
use libdatetime

# set_log_global debug
set_log_global info

# Note:
# [2016-02-08 11:13:55] Bug - when logfile contains 0-bytes (eg in Vugen output.txt with log webregfind for PDF/XLS), the script sees this as EOF and misses transactions and errors. [2016-07-09 10:12] this should be solved by reading as binary.

proc main {argv} {
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {db.arg "auto" "SQLite DB location (auto=create in dir)"}
    {deletedb "Delete DB before reading"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]

  set logdir [:dir $opt]
  # lassign $argv logdir
  puts "logdir: $logdir"
  if {[:db $opt] == "auto"} {
    set dbname [file join $logdir "ahklog.db"]
  } else {
    set dbname [:db $opt]
  }
  if {[:deletedb $opt]} {
    delete_database $dbname
  }

  read_logfile_dir $logdir $dbname
}

proc read_logfile_dir {logdir dbname} {
  # [2016-08-06 12:09] main is not always entry-point, so call define here.
  define_logreader_handlers
  
  # TODO mss pubsub nog eerder zetten als je read-vuserlogs-dir.tcl gebruikt.
  set db [get_results_db $dbname]
  # $db insert read_status [dict create ts [now] status "starting"]
  add_read_status $db "starting"
  set nread 0
  set db [get_results_db $dbname]
  set logfiles [concat [glob -nocomplain -directory $logdir *.log] \
                    [glob -nocomplain -directory $logdir *.txt]]
  set pg [CProgressCalculator::new_instance]
  $pg set_items_total [:# $logfiles]
  $pg start
  foreach logfile $logfiles {
    # TODO: implement!
    readlogfile_ahk $logfile $db
    incr nread
    $pg at_item $nread
  }

  # $db insert read_status [dict create ts [now] status "complete"]
  add_read_status $db "complete"
  log info "set read_status, closing DB"
  $db close
  log info "closed DB"
  log info "Read $nread logfile(s) in $logdir"
}

proc add_read_status {db status} {
  $db insert read_status [dict create ts [now] status $status]
}

proc readlogfile_ahk {logfile db} {
  # some prep with inserting record in db for logfile, also do with handler?
  if {[is_logfile_read $db $logfile]} {
    return
  }
  set vuserid 0
  set ts [clock format [file mtime $logfile] -format "%Y-%m-%d %H:%M:%S"]
  
  set dirname [file dirname $logfile]
  set filesize [file size $logfile]
  lassign [det_project_runid_script $logfile] project runid script

  $db in_trans {
    set logfile_id [$db insert logfile [vars_to_dict logfile dirname ts \
                                            filesize runid project script]]
    # call proc in liblogreader.tcl
    readlogfile_coro $logfile [vars_to_dict db logfile_id vuserid]  
  }
}

proc is_logfile_read {db logfile} {
  # if query returns 1 record, return 1=true, otherwise 0=false.
  :# [$db query "select 1 from logfile where logfile='$logfile'"]
}

# [2016-08-12 21:18] still used?
proc det_project_runid_script {logfile} {
  # [-> $logfile {file dirname} {file dirname} {file tail}]
  set project [file tail [file dirname [file dirname $logfile]]]
  set runid 0
  set script $project
  list $project $runid $script
}

# deze mogelijk in libdb:
# args needed for call from vugen vuser_report proc.
proc get_results_db {db_name args} {
  global pubsub
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  #breakpoint
  return $db
}

# [2016-08-12 21:21] define as similar as possible to vugen log db.
proc define_tables {db} {
  # [2016-07-31 12:01] sec_ts is a representation of a timestamp in seconds since the epoch
  $db def_datatype {sec_ts resptime} real
  $db def_datatype {.*id filesize .*linenr.* trans_status iteration.*} integer
  
  # default is text, no need to define, just check if it's consistent
  # [2016-07-31 12:01] do want to define that everything starting with ts is a time stamp/text:
  $db def_datatype {status ts.*} text

  $db add_tabledef read_status {id} {ts status}
  
  $db add_tabledef logfile {id} {logfile dirname ts filesize \
                                     runid project script}

  set logfile_fields {logfile_id logfile vuserid}
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  set trans_fields {transname user resptime trans_status usecase
    revisit transid transshort searchcrit}
  
  # 17-6-2015 NdV transaction is a reserved word in SQLite, so use trans as table name
  $db add_tabledef trans_line {id} [concat $logfile_fields $line_fields $trans_fields]
  $db add_tabledef trans {id} [concat $logfile_fields $line_start_fields \
                                   $line_end_fields $trans_fields]
  
  $db add_tabledef error {id} [concat $logfile_fields $line_fields \
                                   srcfile srclinenr user errornr errortype details \
                                   line]

  # [2016-08-13 18:48] resource like images, but also html, js, css
  $db add_tabledef resource {id} [concat $logfile_fields $line_fields user transname resource]
  
}

proc delete_database {dbname} {
  log info "delete database: $dbname"
  # error nietgoed
  set ok 0
  catch {
    file delete $dbname
    set ok 1
  }
  if {!$ok} {
    set db [dbwrapper new $dbname]
    foreach table {error trans trans_line logfile read_status} {
      # $db exec "delete from $table"
      $db exec "drop table $table"
    }
    $db close
  }
}

# return 1 iff either old user or old iteration differs from new one in row
proc new_user_iteration?_old {row user iteration} {
  if {($user != [:user $row]) || ($iteration != [:iteration $row])} {
    return 1
  }
  return 0
}

# TODO: move to libdict:
# rename fields in lfrom to lto and return new dict.
proc dict_rename {d lfrom lto} {
  set res $d
  foreach f $lfrom t $lto {
    # [2016-08-02 13:38:19] could be keys in from are not available.
    dict set res $t [dict_get $d $f]
    dict unset res $f
  }
  return $res
}

if {[this_is_main]} {
  set_log_global perf {showfilename 0}
  log debug "This is main, so call main proc"
  set_log_global debug {showfilename 0}  
  main $argv  
} else {
  log debug "This is not main, don't call main proc"
}

