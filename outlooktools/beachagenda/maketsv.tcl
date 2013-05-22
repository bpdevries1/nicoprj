# make tsv from beach dates
package require tdbc::sqlite3
package require Tclx
package require ndv

proc main {argv} {
  lassign $argv dirname
  set db_name [file join $dirname beachen.db]
  set conn [open_db $db_name]
  set f [open [file join $dirname "beachdates.tsv"] w]
  puts $f [join [list datum hoog 3e-div 2e-div] "\t"]
  foreach rec [db_query $conn "select distinct(datum) from beach order by datum"] {
    set datum [dict get $rec datum]
    set row [list $datum]
    foreach niveau {Hoog {3e divisie} {2e divisie}} {
      set cell [det_cell $conn $datum $niveau]
      lappend row $cell
    }
    puts $f [join $row "\t"]
  }
  $conn close
  close $f
}

proc det_cell {conn datum niveau} {
  set lokaties {}
  foreach rec [db_query $conn "select lokatie from beach where datum='$datum' and niveau='$niveau'"] {
    set lokatie [dict get $rec lokatie]
    lappend lokaties $lokatie
  }
  return [join $lokaties "/"]
}

main $argv

