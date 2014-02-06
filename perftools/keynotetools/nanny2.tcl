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
  
  set options {
    {checkfile.arg "" "Check a file for changes. If it is not changed for too long, kill the process and start again"}
    {timeout.arg "0" "Timeout value in seconds for checkfile. If <= 0, the file is not checked"}
    {checkinterval.arg "10" "Interval in seconds to check if process is still running"}
  }
  set usage ": [file tail [info script]] \[options] cmd:"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]

  nanny_cmd $argv $dargv
}

proc nanny_cmd {argv dargv} {
  log info "argv: $argv"
  log info "dargv: $dargv"
  # exit
  set checkinterval_msec [expr 1000 * [:checkinterval $dargv]]
  set checkfile [:checkfile $dargv]
  set timeout [:timeout $dargv]
  dict_to_vars $dargv
  set checkinterval_msec [expr 1000 * $checkinterval]
  set stop 0
  while {!$stop} {
    log info "Exec: $argv"
    # try_eval here?
    set pid [exec {*}$argv >&@ stdout &]
    # set ch [open "| $argv 2>@ $f_stderr" r+]
    #set ch [open "| $argv >&@ stdout" r+]
    #set pid [pid $ch]
    #log debug "Channel id of started process: $ch"
    #log debug "PID (via Channel) of started process: $pid"
    log debug "PID of started process: $pid"
    # fileevent $ch readable [itcl::code $this read_output $ch]
    set ts_started [clock seconds]
    set ts_still_ok $ts_started
    set status "running"
    while {$status == "running"} {
      after $checkinterval_msec
      # bepaal of process nog draait => eigenlijk niet eens nodig, kijken naar (log)file is genoeg. Als process gestopt is, wordt 
      # logfile ook niet aangevuld...
      # bepaal last mtime van de checkfile. Als checkfile niet bestaat (na 10 sec), is het normaal ook wel fout.
      set mtime [file mtime $checkfile]
      if {[clock seconds] - [file mtime $checkfile] > $timeout} {
        log warn "TIMEOUT: $checkfile has not been updated for too long. [clock seconds] - [file mtime $checkfile] > $timeout"
        # kill process, also check if it has really stopped, otherwise try a few times more.
        process_kill $pid
        set status "killed"
      }
      if {[process_status $pid] != "running"} {
        log warn "STOPPED: Process has stopped running, restart"
        set status "stopped"
      }
      log debug "Everything is looking fine"
    }
    log info "Process should be stopped here, start again in the next loop"
      
    if {0} {  
      set run_status $STARTED
      # after [expr $limit_seconds * 1000] [list cancel_cmd $ch $cmd]
      set after_id [after [expr $limit_seconds * 1000] [itcl::code $this cancel_cmd $ch $cmd]]
      vwait [itcl::scope run_status]
      catch {close $ch} ; # catch kan fout gaan als child process gekilled is.
      catch {close $f_stderr} ; # catch kan fout gaan als child process gekilled is.
      log info "Exec $argv finished with result: $res"
      # @todo maybe do something based on result and/or exitcode.
    }  
  }

}

# exec TASKLIST /FI "PID eq $pid"
# get_process_commandline PID => no such process
# end_process PID options
# options: -force 

main $argv
