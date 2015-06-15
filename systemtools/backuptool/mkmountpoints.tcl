#!/home/nico/bin/tclsh86

# set nr of hours to less than 3 days, want backup every 3 days.
# 27-4-2015 use setting in .prf file.
# set BACKUP_INTERVAL_HOURS 60

proc main {argv} {
  set unison_dir "/home/nico/.unison"
  lassign $argv prj
  set f [open [file join $unison_dir $prj.prf] r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^root = (.+)$} $line z mnt]} {
      set fn [file join $mnt mountpoint.txt]
      puts "Touching: $fn"
      exec touch $fn
    }
  }
  close $f
}

main $argv

