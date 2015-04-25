#!/usr/bin/env tclsh86

package require csv

proc main {argv} {
  # set root "/home/nico/media/tijdelijk"
  set root "/media/home.old/nico/media/tijdelijk"
  set sec_timeout 60
  while {1} {
    set res [call_inotify $root $sec_timeout]
    if {$res == "series"} {
      sync_series
    }
  }
}

# @return: timeout, series, <something else>
proc call_inotify {root sec_timeout} {
  # check both stdout and exitcode?
  # log "exec inotifywait..."
  set res "<error>"
  catch {set res [exec -ignorestderr inotifywait --csv --timeout $sec_timeout $root]} results options
  set exitcode [det_exitcode $options]
  if {$exitcode == 2} {
    return "timeout"
  } else {
    # only log if something else than a timeout
    log "res: <<<$res>>>"
    log "results: <<<$results>>>"
    log "options: <<<$options>>>"
    log "exitcode: <<<$exitcode>>>"
    
    set l [csv::split $res]
    # log_list $l
    set path [lindex $l 2]
    # TODO paden bepalen wat generieker.
    if {[regexp -nocase "grey" $path]} {
      return "series"
    } elseif {[regexp -nocase "thrones" $path]} {
      return "series"
    } else {
      return "<something else>"
    }
    return "unknown"
  }
}

proc sync_series {} {
  log "==> found SERIES change, call move and sync here"
  # /home/nico/nicoprj/mediatools/organise/organise-sync-cron.sh
  # niet bovenstaande, want wil exit-code van move gebruiken om te kijken of unison wel nodig is.
  # hier eerst alleen series, mss later ook films (in 2015/currentyear etc dir)
  log "Calling move-series.clj"
  catch {exec /home/nico/bin/lein exec /home/nico/nicoprj/mediatools/organise/move-series.clj}
  log "Calling unison series-rpi"
  catch {exec /home/nico/bin/unison -auto -batch series-rpi}
  log " Finished move and sync"
}

proc log_list {l} {
  set i 0
  foreach el $l {
    log "res list item $i => $el"
    incr i
  }
}

proc det_exitcode {options} {
  if {[dict exists $options -errorcode]} {
    set details [dict get $options -errorcode]
  } else {
    set details ""
  }
  if {[lindex $details 0] eq "CHILDSTATUS"} {
    set status [lindex $details 2]
    return $status
  } else {
    # No code, return -1
    return -1
  }
}

set LOG_STDOUT 1
proc log {str} {
  global LOG_STDOUT
  set f [open "/home/nico/log/watch-tijdelijk.log" a]
  puts $f "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] $str"
  close $f
  if {$LOG_STDOUT} {
    puts "\n***$str***"
  }
}

main $argv
