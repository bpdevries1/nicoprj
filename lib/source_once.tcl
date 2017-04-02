package require Tclx

package provide ndv 0.1.1

namespace eval ::ndv {
  namespace export source_once source_once_file
  variable sources
  variable _stacktrace_files
  variable _stacktrace_procs
  
  array set sources {}

  set _stacktrace_files [dict create]
  set _stacktrace_procs [dict create]

  puts "set _stacktrace_files: $_stacktrace_files"

  # @param one or more filenames to source.
  proc source_once {args} {
    foreach filename $args {
      source_once_file $filename 2 ; # uplevel 2: 1 for the caller, and 1 for the called sub-function (source_once_file)
      # source_once $filename 2
    }
  }
  
  # @param file: relative or absolute path. If relative, then relative to [info script], not the current directory!
  proc source_once_file {file {uplevel 1}} {
    # Remaining exercise for the next reader.  Adapt argument
    # processing to support the -rsrc and -encoding options
    # that [::source] provides (or will in Tcl 8.5)
    variable sources
    set res ""
    # debugging info
    # puts "source_once: info script: [info script]"
    # [2016-08-19 12:59] ok, put whole path in sources list/array.
    set file_norm [file normalize [file join [file dirname [info script]] $file]]
    
    if {![info exists sources($file_norm)]} {
      # don't catch errors, since that may indicate we failed to load it...?
      #     Extra challenge:  Use the techniques outlined in TIP 90
      #     to catch errors, then re-raise them so the [uplevel] does
      #     not appear on the stack trace.
      # We don't know what command is [source] in the caller's context,
      # so fully qualify to get the [::source] we want.
      # uplevel 1 [list ::source $file_norm]
      set res [uplevel $uplevel [list ::source $file_norm]]
      # mark it as loaded since it was source'd with no error...
      set sources($file_norm) 1

      # and read proc names for stacktrace.
      # [2017-04-02 15:16] alternative may be to override proc, and use [info sourceline???], then special handling for eg task would not be needed.
      stacktrace_read_source $file_norm
    }
    return $res
  }

  proc stacktrace_read_source {filename} {
    # global _stacktrace_procs _stacktrace_files
    variable _stacktrace_procs
    variable _stacktrace_files; # variable decl's should be on separate lines!
    
    set filename [file normalize $filename]; # full path
    if {[dict exists $_stacktrace_files $filename]} {
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
      if {[regexp {task ([^ ]+)} [string trim $line] z procname]} {
        # [2017-04-02 15:21] apparently for task items need to add 1 to linenr.
        dict lappend _stacktrace_procs task_$procname [dict create filename $filename linenr [expr $linenr + 1]]
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
    variable _stacktrace_procs
    set lines [split $errorInfo "\n"]
    set i 0
    set res [list]
    foreach line $lines {
      #  (procedure "proc2" line 2)
      if {[regexp {procedure \"([^ \"]+)\" line (\d+)} $line z procname linenr]} {
        set lst [dict_get $_stacktrace_procs $procname]
        if {$lst != {}} {
          foreach el $lst {
            # could have the same proc name in different namespaces, or procs overwriting each other.
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


  # ininialise when this source is read:
  
  stacktrace_read_source [info script]
  stacktrace_read_source $argv0
  


}

