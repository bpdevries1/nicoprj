package provide ndv 0.1.1

namespace eval ::ndv {
  namespace export source_once source_once_file
  variable sources
  array set sources {}

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
    
    # debugging info
    puts "source_once: info script: [info script]"
    set file_norm [file normalize [file join [file dirname [info script]] $file]]
    
    if {![info exists sources($file_norm)]} {
      # don't catch errors, since that may indicate we failed to load it...?
      #     Extra challenge:  Use the techniques outlined in TIP 90
      #     to catch errors, then re-raise them so the [uplevel] does
      #     not appear on the stack trace.
      # We don't know what command is [source] in the caller's context,
      # so fully qualify to get the [::source] we want.
      # uplevel 1 [list ::source $file_norm]
      uplevel $uplevel [list ::source $file_norm]
      # mark it as loaded since it was source'd with no error...
      set sources($file_norm) 1
    }
  }

  proc source_once_old {file} {
    # Remaining exercise for the next reader.  Adapt argument
    # processing to support the -rsrc and -encoding options
    # that [::source] provides (or will in Tcl 8.5)
    variable sources
    
    # debugging info
    puts "source_once: info script: [info script]"
    
    if {![info exists sources([file normalize $file])]} {
      # don't catch errors, since that may indicate we failed to load it...?
      #     Extra challenge:  Use the techniques outlined in TIP 90
      #     to catch errors, then re-raise them so the [uplevel] does
      #     not appear on the stack trace.
      # We don't know what command is [source] in the caller's context,
      # so fully qualify to get the [::source] we want.
      uplevel 1 [list ::source $file]
      # mark it as loaded since it was source'd with no error...
      set sources([file normalize $file]) 1
    }
  }


}

