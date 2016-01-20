#!/usr/bin/env tclsh861

package require csv
package require ndv

proc main {argv} {
  # set root "/home/nico/media/tijdelijk"
  # set root "/media/home.old/nico/media/tijdelijk"
  lassign $argv root
  set root [file normalize $root]
  set sec_timeout 60
  while {1} {
    set res [call_inotify $root $sec_timeout]
    if {[:0 $res] == "change"} {
      set filename [:1 $res]
      if {$filename != ""} {
        handle_change $root $filename  
      }
    }
    #if {$res == "series"} {
    #  sync_series
    #}
  }
}

# @return: timeout, series, <something else>
proc call_inotify {root sec_timeout} {
  # check both stdout and exitcode?
  # log "exec inotifywait..."
  log "call_inotify: start"
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
    return [list change $path]
  }
}

proc handle_change {root filename} {
  log "File has changed: $filename in $root"
  # eerst simpel houden: als er een _ in de naam staat, dan een touch van het deel voor
  # de _
  if {[regexp {^(.+)_(.+)(.clj)$} $filename z base detail ext]} {
    set basename [file join $root "$base$ext"]
    exec touch $basename
    log "Touched: $basename"
  } else {
    log "No _ found, not touching anything"
  }
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
  set f [open "/home/nico/log/watch-clojure.log" a]
  puts $f "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] $str"
  close $f
  if {$LOG_STDOUT} {
    puts "\n***$str***"
  }
}

main $argv
