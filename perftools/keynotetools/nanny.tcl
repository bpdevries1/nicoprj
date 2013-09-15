#!/usr/bin/env tclsh86

# maybe keep very simple and robust, so no packages
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# @todo nanny.tcl othertcl.tcl params does not work, as exec does not use bash, so first line '#!/usr/bin/env tclsh' is not read/handled correctly.
# for now, nanny.tcl tclsh othertcl.tcl works.

proc main {argv} {
  global stdout
  set stop 0
  while {!$stop} {
    log info "Exec: $argv"
    try_eval {
      set res "<none>"
      set res [exec {*}$argv >&@ stdout]
    } {
      log_error "Error executing: $argv" 
    }
    log info "Exec $argv finished with result: $res"
    # @todo maybe do something based on result and/or exitcode.
  }
}

main $argv
