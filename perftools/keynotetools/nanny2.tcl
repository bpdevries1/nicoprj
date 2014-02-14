#!/usr/bin/env tclsh86

# maybe keep very simple and robust, so no packages
package require Tclx
package require ndv
package require twapi

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# $log set_file "[file tail [info script]].log"
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

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
    {checkfile.arg "" "Check a file (if given) for changes. If it is not changed for too long, kill the process and start again"}
    {timeout.arg "3600" "Timeout value in seconds for checkfile. If <= 0, the file is not checked"}
    {checkinterval.arg "60" "Interval in seconds to check if process is still running"}
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
  #set checkinterval_msec [expr 1000 * [:checkinterval $dargv]]
  #set checkfile [:checkfile $dargv]
  #set timeout [:timeout $dargv]
  dict_to_vars $dargv
  set checkinterval_msec [expr 1000 * $checkinterval]
  set stop 0
  while {!$stop} {
    log info "Exec: $argv"
    # try_eval here?
    set pid [exec {*}$argv >&@ stdout &]
    log debug "PID of started process: $pid"
    set ts_started [clock seconds]
    set ts_still_ok $ts_started
    set status "running"
    while {$status == "running"} {
      after $checkinterval_msec
      # bepaal of process nog draait => eigenlijk niet eens nodig, kijken naar (log)file is genoeg. Als process gestopt is, wordt 
      # logfile ook niet aangevuld...
      # maar mss geen logfile opgegeven, dan moet 'oude' manier ook nog werken.
      # bepaal last mtime van de checkfile. Als checkfile niet bestaat (na 10 sec), is het normaal ook wel fout.
      if {$checkfile != ""} {
        set mtime [file mtime $checkfile]
        if {[clock seconds] - [file mtime $checkfile] > $timeout} {
          log warn "TIMEOUT: $checkfile has not been updated for too long. [format_dt [clock seconds]] - [format_dt [file mtime $checkfile]] > $timeout"
          log warn "TIMEOUT: kill process, wait 10 seconds and restart"
          # kill process, also check if it has really stopped, otherwise try a few times more.
          process_kill $pid
          set status "killed"
          after 10000 ; # don't restart process too soon.
        }
      } else {
        # nothing.
      }
      if {[process_status $pid] != "running"} {
        log warn "STOPPED: Process has stopped running, restart"
        set status "stopped"
      } else {
        log debug "Everything is looking fine"
      }
    }
    log info "Process should be stopped here, start again in the next loop"
  }
}

proc format_dt {sec} {
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

proc process_status {pid} {
  set status [twapi::process_exists $pid]
  log debug "process_exists $pid: $status"
  if {$status} {
    return "running"
  } else {
    return "stopped"
  }
}

proc process_kill {pid} {
  foreach i {1 2 3 4 5} {
    if {[process_status $pid] == "running"} {
      try_eval {
        log warn "Process running, so calling end_process $pid -force"
        twapi::end_process $pid -force
      } {
        log warn "end_process failed: $errorResult"
      }
      after 5000
    } else {
      break
    }
  }  
  if {[process_status $pid] == "running"} {
    error "Cannot kill process: $pid"    
  }
}

main $argv
