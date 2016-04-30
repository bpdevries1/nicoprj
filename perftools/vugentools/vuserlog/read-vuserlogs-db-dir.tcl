package require ndv

set_log_global info

source read-vuserlogs-db.tcl

# TODO:
# ook level dieper kijken, dat je meteen in alle subdirs van testruns kijkt, zowel RCC, Transact, etc.

proc main {argv} {
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {all "Do all subdirs, regardless of whether DB already exists"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set logdir [:dir $dargv]
  # lassign $argv logdir
  puts "logdir: $logdir"

  foreach subdir [glob -directory $logdir -type d *] {
    set dbname "$subdir.db"
    if {![file exists $dbname] || [:all $dargv]} {
      log info "New dir: read logfiles: $subdir"
      file delete $dbname
      read_logfile_dir $subdir $dbname
    } else {
      log info "DB already exists, so ignore: $subdir"
    }
  }
}

proc read_logfile_dir {subdir dbname} {
  set db [get_results_db $dbname]
  foreach logfile [glob -nocomplain -directory $subdir *.log] {
    readlogfile $logfile $db
  }
  # [2016-02-08 10:55:16] NdV kan ook van Vugen log zijn: output.txt.
  foreach logfile [glob -nocomplain -directory $subdir *.txt] {
    readlogfile $logfile $db
  }
}

if {[this_is_main]} {
  main $argv
}
