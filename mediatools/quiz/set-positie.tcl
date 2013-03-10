#!/home/nico/bin/tclsh8.6

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global conn stmts
  set db_name "/media/Iomega HDD/media/Music/Quiz/Top 2000 2012/top2000-2012.db"
  set conn [open_db $db_name]

  set stmts(update_positie) [$conn prepare "update track set positie = :positie where id = :id"]
  set_posities $conn
  $conn close
}

proc open_db {db_name} {
  set conn [tdbc::sqlite3::connection create db $db_name]
  return $conn
}

proc set_posities {conn} {
  set lst_tracks [$conn allrows -as dicts "select * from track"]
  $conn begintransaction
  foreach track $lst_tracks {
    set_positie $track 
  }
  $conn commit
}

proc set_positie {track} {
  global stmts
  set positie [det_positie $track]
  dict set track positie $positie
  $stmts(update_positie) execute $track
}

proc det_positie {track} {
  set filename [file tail [dict get $track path]]
  if {[regexp {^0*(\d+)} $filename z pos]} {
    return $pos 
  } else {
    error "cannot find positie from: $filename" 
  }
}

proc db_eval {conn query} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
}

main $argv
