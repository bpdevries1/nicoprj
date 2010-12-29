package provide ndv 0.1.1

namespace eval ::ndv {
  namespace export source_once
  variable sources
  array set sources {}

  proc source_once {file} {
    # Remaining exercise for the next reader.  Adapt argument
    # processing to support the -rsrc and -encoding options
    # that [::source] provides (or will in Tcl 8.5)
    variable sources
    
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

