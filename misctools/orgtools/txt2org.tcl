#! /usr/bin/env tclsh

# convert .txt files to .org files, using a few heuristics:
# * lines ending with ':' will become a first-level bullet
# * lines starting with some spaces and a bullet will be a second or further level bulleted item.
# * remove empty lines
# * trim other lines

# Show todo items for all .org files in given dirs
# Similar to Ctrl-c a d in emacs/org-mode itself.
# First goal is just to trigger doing Ctrl-c a d manually, tend to forget this.

package require ndv

require libio io

use libfp

set_log_global info

proc main {argv} {
  global opt;                   # used in convert_file
  set options {
    {paths.arg "." "; separated list of paths to search for txt files and also specific txt files"}
    {patterns.arg "*.txt" "; separated list of glob patterns to convert"}
    {f "Force, overwrite target files (with warning)"}
    {debug "Set loglevel to debug"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    set_log_global debug
  }
  convert_paths $opt
}

proc convert_paths {opt} {
  set patterns [split [:patterns $opt] ";"]
  foreach path [split [:paths $opt] ";"] {
    log debug "path: $path"
    if {[file isfile $path]} {
      convert_file $path ""
    }
    if {[file isdirectory $path]} {
      foreach pattern $patterns {
        log debug "handle_dir_rec $path $pattern convert_file"
        handle_dir_rec $path $pattern convert_file
      } 
    }
  }
}

#proc handle_dir_rec {dir globpattern actionproc {rootdir ""}}

proc convert_file {filename rootdir} {
  global opt
  set orgfile "[file rootname $filename].org"
  log debug "convert file: $filename -> $orgfile"
  if {[file exists $orgfile]} {
    if {[:f $opt]} {
      log warn "Overwriting: $orgfile"
    } else {
      log warn "File already exists, do nothing: $orgfile"
      return
    }
  }
  set fi [open $filename r]
  set fo [open $orgfile w]
  while {[gets $fi line] >= 0} {
    if {[regexp {^( *)\* (.+)$} $line z spaces text]} {
      set text [string trim $text]
      if {[regexp {^([^,.;:()]+)[,.;:()] *(.+)$} $text z header rest]} {
        puts $fo "[stars $spaces] $header\n$rest"
      } else {
        puts $fo "[stars $spaces] $text"  
      }
    } elseif {[regexp {^(.+):\s*$} $line z b1]} {
      # check this one second, could have both stars and :
      puts $fo "* $b1:"
    } else {
      set line2 [string trim $line]
      if {$line2 != ""} {
        puts $fo [string trim $line]  
      }
    }
  }
  close $fo
  close $fi
}

# convert #starting spaces to #stars
proc stars {spaces} {
  string repeat "*" [+ 2 [/ [string length $spaces] 2]]
}

main $argv

