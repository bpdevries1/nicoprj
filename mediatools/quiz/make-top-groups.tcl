#!/usr/bin/env tclsh86

# !/home/nico/bin/tclsh8.6

# make-top-groups.tcl

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global conn stmt
  lassign $argv db_name
  set conn [open_db $db_name]

  #CREATE TABLE testgroup (id integer primary key autoincrement, name);
  #CREATE TABLE testgroup_item (testgroup_id, track_id);
  
  set td_tg [make_table_def_keys testgroup {id} {name}]
  set td_tgi [make_table_def_keys testgroup_item {} {testgroup_id track_id}]
  
  set stmt(insert_tg) [prepare_insert_td $conn $td_tg]
  set stmt(insert_tgi) [prepare_insert_td $conn $td_tgi]
  
  #set stmts(set_seconds_frames) [$conn prepare "update track set seconds = :seconds, frames = :frames where id = :id"]
  #set stmts(update_nright_nwrong) [$conn prepare "update track set nright = :nright, nwrong = :nwrong where id = :id"]
  #set stmts(insert_test) [$conn prepare "insert into track_test (track_id, ts, result, start_sec, stop_sec) values (:track_id, :ts, :result, :start_sec, :stop_sec)"]

  make_groups $conn
  $conn close
}

proc make_groups {conn} {
  set i 100
  while {$i <= 2000} {
    make_top_group $conn $i
    incr i 100
  }
}

proc make_top_group {conn ntop} {
  global stmt
  db_eval $conn "begin transaction"
  set grp_id [stmt_exec $conn $stmt(insert_tg) [dict create name "Top $ntop"] 1]
  foreach dct [db_query $conn "select id from track where 1.0*positie <= $ntop order by 1.0 * positie"] {
    stmt_exec $conn $stmt(insert_tgi) [dict create testgroup_id $grp_id track_id [dict get $dct id]]
  }
  db_eval $conn "commit"
}

main $argv
