#! /usr/bin/env tclsh

# Show todo items for all .org files in given dirs
# Similar to Ctrl-c a d in emacs/org-mode itself.
# First goal is just to trigger doing Ctrl-c a d manually, tend to forget this.

package require ndv

require libio io

use libfp

set_log_global info

# TODO: later:
# show items #days in the future.
# show some random items, which don't have a Scheduled item.
# which context to show: org-filename, parent todos for nested items, text within todo.
# filename: none, just name, full path.
# show topic
# popup items (compare log-errors and test-errors) to run within gosleep.
# -> maybe just pipe results to specific script.
# sort items, oldest first. Requires more functional approach, returning items.
# -> maybe just pipe results to sort.
proc main {argv} {
  set options {
    {paths.arg "~/Dropbox/org" "; separated list of paths to search for org files and also specific org files"}
    {dirfile.arg "" "TBD - file with newline separated list of dirs/files"}
    {futuredays.arg "0" "Show items up to # days into the future"}
    {showfile.arg "name" "Which part of filename to show (name, full, none)"}
    {debug "Set loglevel to debug"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    $log set_log_level debug
  }

  show_todos $opt;              # to be able to call from another script.
}

proc show_todos {opt} {
  global today future_date
  set today [clock format [clock seconds] -format "%Y-%m-%d"]
  set future_date [clock format [+ [clock seconds] [* 86400 [:futuredays $opt]]] -format "%Y-%m-%d"]
  set paths [split [:paths $opt] ";"]
  foreach path $paths {
    show_todos_path $path $opt
  }
}

# path is dir or org file
proc show_todos_path {path opt} {
  if {[file isfile $path]} {
    show_todos_file $path $opt
  }
  if {[file isdirectory $path]} {
    foreach filename [lsort [glob -nocomplain -directory $path -type f *.org]] {
      show_todos_file $filename $opt
    }
    foreach subdir [lsort [glob -nocomplain -directory $path -type d *]] {
      show_todos_path $subdir $opt
    }
  }
}

# ** TODO org check automatisch
# SCHEDULED: <2017-04-03 vr>

proc show_todos_file {path opt} {
  global today future_date
  # puts "$filename:"
  # {showfile.arg "name" "Which part of filename to show (name, full, none)"}
  switch [:showfile $opt] {
    name {set filename " ([file tail $path])"}
    full {set filename " ([file normalize $path])"}
    none {set filename ""}
    default {error "Unknown -showfile value: [:showfile $opt]"}
  }

  io/with_file f [open $path r] {
    set title ""
    while {[gets $f line] >= 0} {
      if {[regexp {^\*+ ((TODO|WAITING) .+)$} $line z tt]} {
        set title $tt
      } elseif {[regexp {^SCHEDULED: <([0-9-]+)} $line z date]} {
        if {$date <= $future_date} {
          if {$date <= $today} {
            puts "<$date> $title$filename"  
          } else {
            puts "FUTURE <$date> $title$filename"
          }
        } else {
          # puts "FUTURE <$date> $title ($filename)"
        }
        set title ""
      }
    }
  }
}

main $argv

