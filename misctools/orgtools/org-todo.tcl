#! /home/nico/bin/tclsh

# [2017-04-14 12:25] onderstaande werkt blijkbaar niet vanuit gosleep.tcl

# #! /usr/bin/env tclsh

# Show todo items for all .org files in given dirs
# Similar to Ctrl-c a d in emacs/org-mode itself.
# First goal is just to trigger doing Ctrl-c a d manually, tend to forget this.

package require ndv

require libio io

use libfp

set_log_global info

# TODO: later:
# * show some random items, which don't have a Scheduled item.
# * which context to show: org-filename, parent todos for nested items, text within todo.
# * show topic

# Notes:
# popup items (compare log-errors and test-errors) to run within gosleep.
# -> just pipe results to specific script.
# sort items, oldest first. Requires more functional approach, returning items.
# -> just pipe results to sort.
proc main {argv} {
  global log
  # [2017-04-14 20:13] put default dirs both for PC and laptop:
  set options {
    {paths.arg "~/Dropbox/org;~/Documents/journal;c:/PCC/nico/raboprj/org" "; separated list of paths to search for org files and also specific org files"}
    {dirfile.arg "" "TBD - file with newline separated list of dirs/files"}
    {futuredays.arg "0" "Show items up to # days into the future"}
    {showfile.arg "name" "Which part of filename to show (name, full, none)"}
    {countonly "Only show a count of all open todo's"}
    {debug "Set loglevel to debug"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    # $log set_log_level debug
    set_log_global debug
  }

  show_todos $opt;              # to be able to call from another script.
}

proc show_todos {opt} {
  global today future_date nitems
  set today [clock format [clock seconds] -format "%Y-%m-%d"]
  set future_date [clock format [+ [clock seconds] [* 86400 [:futuredays $opt]]] -format "%Y-%m-%d"]
  set paths [split [:paths $opt] ";"]
  # breakpoint
  set nitems 0
  foreach path $paths {
    show_todos_path $path $opt
  }
  if {$nitems > 0} {
    puts "#open TODO items: $nitems"    
  }
}

# path is dir or org file
proc show_todos_path {path opt} {
  log debug "Handling path: $path"
  if {[file isfile $path]} {
    show_todos_file $path $opt
  }
  if {[file isdirectory $path]} {
    foreach filename [lsort [glob -nocomplain -directory $path -type f *]] {
      if {[org_file? $filename] && ![ignore_file? $filename]} {
        show_todos_file $filename $opt  
      }
    }
    foreach subdir [lsort [glob -nocomplain -directory $path -type d *]] {
      show_todos_path $subdir $opt
    }
  }
}

proc org_file? {filename} {
  if {[file extension $filename] == ".org"} {
    return 1
  }
  if {[regexp {^\d{8}$} [file tail $filename]]} {
    return 1;                   # org journal file, just a date with 8 digits
  }
  return 0
}

proc ignore_file? {filename} {
  foreach re {backups -old-} {
    if {[regexp -- $re $filename]} {
      return 1
    }
  }
  return 0
}

# ** TODO org check automatisch
# SCHEDULED: <2017-04-03 vr>

proc show_todos_file {path opt} {
  global today future_date nitems
  log debug "$path:"
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
    set linenr 0
    set done 0
    # set nitems 0;               # global var, no init here.
    while {[gets $f line] >= 0} {
      incr linenr
      # not all DONE items have CLOSED on the same line as SCHEDULED
      if {[regexp {^\*+ (.+)$} $line z tt]} {
        set title $tt
        set done [regexp {^DONE} $title]
      } elseif {[regexp {^SCHEDULED: <([0-9-]+)} $line z date]} {
        if {($date <= $future_date) && !$done} {
          if {[:showfile $opt] == "full"} {
            set filename " ([file normalize $path]:$linenr)"
          }
          if {$date <= $today} {
            puts_item "<$date> $title$filename" $opt
            incr nitems
          } else {
            puts_item "FUTURE <$date> $title$filename" $opt
            incr nitems
          }
        } else {
          # puts "FUTURE <$date> $title ($filename)"
        }
        set title ""
      }
    }
  }

}

proc puts_item {str opt} {
  if {![:countonly $opt]} {
    puts $str
  }
}

main $argv

