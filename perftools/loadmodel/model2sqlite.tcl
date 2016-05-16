#!/home/nico/bin/tclsh

package require ndv
package require sqlite3

proc main {argv} {
  set dir [lindex $argv 0]
  split_berekening $dir
  # 15-10-2011 NdV catch needed, otherwise script will not continue after exec.
  catch {exec ../graphdata/data2sqlite.tcl -path [file join $dir script.tsv] -db [file join $dir model]}
  puts "script.tsv loaded"
  catch {exec ../graphdata/data2sqlite.tcl -path [file join $dir globals.tsv] -db [file join $dir model]}
  puts "globals.tsv loaded"
}

proc split_berekening {dir} {
  set f [open [lindex [glob -directory $dir *Berekening.tsv] 0] r]
  set fo [open [file join $dir script.tsv] w]
  while {![eof $f]} {
    gets $f line
    # puts "[llength [split $line "\t"]]: $line"
    if {[regexp {^Totaal} $line]} {
      break 
    }
    puts $fo $line
  }
  close $fo
  gets $f line ; # lege regel
  set fo [open [file join $dir globals.tsv] w]
  puts $fo "Name\tValue"
  while {![eof $f]} {
    set l [split [gets $f] "\t"]
    lassign $l name value
    if {$name == ""} {
      break 
    }
    puts $fo "$name\t$value"
  }
  close $fo
  close $f
}

main $argv
