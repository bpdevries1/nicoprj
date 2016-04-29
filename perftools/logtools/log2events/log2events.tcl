#!/usr/bin/env tclsh861

# convert ODBC log file with timestamps to a log with events more suitable to analysis with Splunk
# vanaf 2015-07-31 13:22:21.257 echte tijden, hiervoor dummy.
# nu wel een file met overal timestamps, vanaf het begin dat sessie wordt opgebouwd.
package require ndv
package require tdbc::sqlite3

ndv::source_once fillevent.tcl filltables.tcl checks.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

proc main {argv} {
  global log db filename seqnr_global
  lassign $argv logfilepath

  set dbname [file join [file dirname $logfilepath] "odbccalls.db"]
  if {1} {
    catch {file delete $dbname} ; # while testing delete the sqlite db first. Not possible if open in SQLiteSpy
    set db [get_db $dbname]
    $db function timediff
    empty_tables $db
    if {0} {                     
      test_select $db        
      test_hex $db            
      $db close               
      exit                  
    }                       
  
    read_log $logfilepath $db
    fill_calls $db
    # 19-8-2015 indexes pas aanmaken nadat tabel gevuld is.
    create_indexes_odbccall $db
    fill_queries $db
    fill_userthink $db
    fill_useraction $db
  } else {                       
    set db [get_db $dbname]
    $db function timediff      
  };                             

  
  fill_odbcquery_do $db
  
  do_checks $db

  $db close
}

proc test_select {db} {
  log info "test select:"
  $db exec "delete from odbccall"
  $db insert odbccall [dict create callname testje]
  set res [$db query "select * from odbccall"]
  puts "res: $res"
  log info "finished test select"
}




proc get_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs.
  # $db create_tables 1 ; # 1: do drop tables first. Always do create, eg for new table defs.
  
  # 19-8-2015 NdV lijkt alleen maar langzamer te worden met indexen, na 10 min nog niet klaar, zonder in 2.5 min
  # create_indexes $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc define_tables {db} {
  $db add_tabledef event {id} {{seqnr int} filename {linenr int} ts_cet enterexit callname HENV HDBC HSTMT query {returncode int} returnstr lines}
  $db add_tabledef odbccall {id} {filename {seqnr_enter int} {seqnr_exit int} {linenr_enter int} {linenr_exit}
    ts_cet_enter ts_cet_exit {calltime real} callname HENV HDBC HSTMT query {returncode int} returnstr {odbcquery_id int}}
  $db add_tabledef odbcquery {id} {filename {seqnr_start int} {seqnr_end int} {linenr_start int} {linenr_end int}
    ts_cet_start ts_cet_end {query_elapsed real} {query_servertime real} HENV HDBC HSTMT query}

  # versie van odbcquery met alleen 'echte' acties, dus niet alloc en free (en mss nog anderen)
  $db add_tabledef odbcquery_do {id} {{odbcquery_id int} filename {seqnr_start int} {seqnr_end int} {linenr_start int} {linenr_end int}
    ts_cet_start ts_cet_end {query_elapsed real} {query_servertime real} HENV HDBC HSTMT query
    {start_useraction_id int} {end_useraction_id int} title {nbindcol int} {nfetch int} {nsqlgetdata int} {ncalls int}}
  
  $db add_tabledef userthink {id} {filename {seqnr_before int} {seqnr_after int} ts_cet_before ts_cet_after {thinktime real}}
  $db add_tabledef useraction {id} {filename description {seqnr_first int} {seqnr_last int} ts_cet_first ts_cet_last {resptime real}
    {thinktime_before real} {thinktime_after real} {ncalls int}}
}

proc create_indexes {db} {
  create_indexes_odbccall $db
}

proc create_indexes_odbccall {db} {
  # $db exec "create index ix_"
  foreach field {HDBC HSTMT filename seqnr_enter seqnr_exit odbcquery_id} {
    create_index $db odbccall $field  
  }
}

proc create_index {db table field} {
  # mss met catch of check
  # ook variant voor meerdere fields.
  $db exec "create index ix_${table}_${field} on $table ($field)"
}

proc timediff {t1 t2} {
  format %.3f [expr [to_sec $t2] - [to_sec $t1]]
}

# ts: timestamp including milliseconds
proc to_sec {ts} {
  regexp {^([^.]+)(\.\d+)$} $ts z ts_sec msec
  return "[clock scan $ts_sec -format "%Y-%m-%d %H:%M:%S"]$msec"
}

# puts "starting main:"

main $argv


