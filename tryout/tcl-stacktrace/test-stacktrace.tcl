#! /usr/bin/env tclsh

package require ndv
package require Tclx

proc main {} {
  stacktrace_init;              # of vlak voor main call, of nog boven de includes, even testen, ervaring opdoen.
  try_eval {
    proc1 4 5 6
  } {
    #puts "Caught error: $errorResult"
    #puts "errorInfo: $errorInfo"; # deze bevat stack trace.
    #puts "errorCode: $errorCode"
    stacktrace_info $errorResult $errorCode $errorInfo
  }
  
}

proc proc1 {x y z} {
  proc2 1 2 3
}

proc proc2 {a b c} {
  error "Generate error"
}

# read procs of current file (check both [info script] and $argv0)
proc stacktrace_init {} {
  global argv0 _stacktrace_files _stacktrace_procs
  set _stacktrace_files [dict create]
  set _stacktrace_procs [dict create]
  stacktrace_read_source [info script]
  stacktrace_read_source $argv0
}

proc stacktrace_read_source {filename} {
  global _stacktrace_procs _stacktrace_files
  set filename [file normalize $filename]; # full path
  if {[dict_get $_stacktrace_files $filename] != ""} {
    puts "Already read: $filename"
    return;                     # already read
  }
  dict set _stacktrace_files $filename 1
  set lines [split [read_file $filename] "\n"]
  set linenr 1
  foreach line $lines {
    if {[regexp {proc ([^ ]+)} [string trim $line] z procname]} {
      dict lappend _stacktrace_procs $procname [dict create filename $filename linenr $linenr]
    }
    incr linenr
  }
  # breakpoint
}

proc stacktrace_info {errorResult errorCode errorInfo} {
  puts stderr "$errorResult (code = $errorCode)"
  puts stderr [stacktrace_add_info $errorInfo]
}

proc stacktrace_add_info {errorInfo} {
  global _stacktrace_procs
  set lines [split $errorInfo "\n"]
  set i 0
  set res [list]
  foreach line $lines {
    #  (procedure "proc2" line 2)
    if {[regexp {procedure \"([^ \"]+)\" line (\d+)} $line z procname linenr]} {
      set lst [dict_get $_stacktrace_procs $procname]
      if {$lst != {}} {
        foreach el $lst {
          lappend res "$line \[[:filename $el]:[expr [:linenr $el] + $linenr - 1]\]"
        }
      } else {
        # info not found
        lappend res "$line (proc info not read)"
      }

    } else {
      lappend res "$line"  
    }
    
    
    incr i
  }
  join $res "\n"
}

main
