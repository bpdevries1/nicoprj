#!/home/nico/bin/tclsh8.6

# lees top2000.txt in, voor vgl met posities en title/artiest

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  lassign $argv db_name top2000_name
  set conn [open_db $db_name]
  db_eval $conn "create table if not exists top2000text (id integer primary key autoincrement, positie, titel, artiest, jaar)"  
  set stmts(insert) [$conn prepare "insert into top2000text (positie, titel, artiest, jaar) values (:positie, :titel, :artiest, :jaar)"]
  db_eval $conn "begin transaction"
  set f [open $top2000_name r]
  while {![eof $f]} {
    gets $f line
    set l [split $line "\t"]
    lassign $l positie titel artiest jaar
    if {[llength $l] == 4} {
      if {[string is integer $positie] && ($positie != "")} {
        [$stmts(insert) execute [dict create positie $positie titel $titel artiest $artiest jaar $jaar]] close
      }
    }
  }
  close $f
  db_eval $conn "commit"
  $conn close
}

proc open_db {db_name} {
  set conn [tdbc::sqlite3::connection create db $db_name]
  return $conn
}

proc db_eval {conn query} {
  set stmt [$conn prepare $query]
  # [2016-07-10 09:24] close resultset
  [$stmt execute] close
  # [2016-07-10 09:24] close statement
  $stmt close
}

main $argv
