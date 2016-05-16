#!/usr/bin/env tclsh86

# maybe keep very simple and robust, so no packages
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# @todo nanny.tcl othertcl.tcl params does not work, as exec does not use bash, so first line '#!/usr/bin/env tclsh' is not read/handled correctly.
# for now, nanny.tcl tclsh othertcl.tcl works.

if {0} {
# @todo:
./nanny.tcl tclsh ./scatter2db.tcl -nopost -continuous -moveread

vervangen kan worden door:

./nanny.tcl ./scatter2db.tcl -nopost -continuous -moveread

Door ofwel de exec via bash te doen (en bash mss afleiden uit parent proces van nanny.tcl, ofwel (vgl bash) zelf de eerste regel te lezen (en evt ook extensie van de file)

# @todo
Als dit process nanny.tcl wordt gesloten met ctrl-c, moeten ook child processes worden gekilled.
22-1-2014 Dit gebeurde tot voor kort wel, maar child wordt nu een orphan, en blijft draaien.

}

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
