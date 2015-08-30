#!/usr/bin/env tclsh
# edited remote with emacs.

set DEBUG 0
set LOGROOT "/home/pi/log"
# set LOGROOT .

proc main {argv} {
  wrap_delete check_and_delete
  wrap_delete check_and_delete_wrap
}

proc main_old {argv} {
  log "delete-played-symlinks: start"
  catch {
    check_and_delete
  } msg
  # info errorstack werkt hier niet, mss nieuw in tcl 8.6?
  # set ies [info errorstack]
  if {$msg != ""} {
    log "main catch: result: $msg"
  }
  # log "info error stack: $ies"
  log "delete-played-symlinks: finished"
}

proc wrap_delete {procname} {
  log "delete-played-symlinks - $procname: start"
  catch {
    # check_and_delete
    $procname
  } msg
  # info errorstack werkt hier niet, mss nieuw in tcl 8.6?
  # set ies [info errorstack]
  if {$msg != ""} {
    log "main catch: result: $msg"
  }
  # log "info error stack: $ies"
  log "delete-played-symlinks - $procname: finished"
  
}

proc check_and_delete {} {
  global LOGROOT
  #set tempname "/home/pi/log/omxplayer-temp.log"
  #set temp2name "/home/pi/log/omxplayer-temp2.log"
  set tempname [file join $LOGROOT "omxplayer-temp.log"]
  set temp2name [file join $LOGROOT "omxplayer-temp2.log"]
  
  # Eerst check of temp2 niet bestaat en temp wel, dan renamen.
  if {([file exists $tempname]) && (![file exists $temp2name])} {
   # zonder -force, doel bestand bestaat niet.
   # log "temp exists, temp2 not, so rename to temp2"
   file rename $tempname $temp2name
  }

  # Hierna werken met temp2
  if {[file exists $temp2name]} {
    # log "temp2 exists now, process it"
    set f [open $temp2name r]
    while {![eof $f]} {
      gets $f line
      logd "got line: $line"
      # ignore cmdline options, starting with - but also something behind it, like -o local. So start with first /
      if {[regexp {^[0-9 :-]+: .*/usr/bin/omxplayer.bin [^/]+ (/.+)$} $line z path]} {
        logd "matched regexp: ***${path}***"
        if {[is_link $path]} {
          # remove symlink, it has been played
          log "file is link - delete: $path"
          file delete $path
        } else {
          # log "not a link, leave it: $path"
        }
      } else {
        logd "did not match regexp: $line"
      }
    }
    close $f
    file delete $temp2name
  }
}

proc check_and_delete_wrap {} {
  global LOGROOT
  #set tempname "/home/pi/log/omxplayer-temp.log"
  #set temp2name "/home/pi/log/omxplayer-temp2.log"
  set tempname [file join $LOGROOT "wrapomxplayer-temp.log"]
  set temp2name [file join $LOGROOT "wrapomxplayer-temp2.log"]
  
  # Eerst check of temp2 niet bestaat en temp wel, dan renamen.
  if {([file exists $tempname]) && (![file exists $temp2name])} {
   # zonder -force, doel bestand bestaat niet.
   # log "temp exists, temp2 not, so rename to temp2"
   file rename $tempname $temp2name
  }

  # Hierna werken met temp2
  if {[file exists $temp2name]} {
    # log "temp2 exists now, process it"
    set f [open $temp2name r]
    while {![eof $f]} {
      gets $f line
      logd "got line: $line"
      if {[regexp {Finished: (.+) \(subs: (.*)\)} $line z video subs]} {
        logd "matched regexp: ***${video}***${subs}***"
        foreach path [list $video $subs] {
          if {[is_link $path]} {
            # remove symlink, it has been played
            log "file is link - delete: $path"
            file delete $path
          } else {
            logd "not a link, leave it: $path"
          }
        }
      } else {
        logd "did not match regexp: $line"
      }
    }
    close $f
    file delete $temp2name
  }
}

proc is_link {path} {
  # log "is_link started: $path"
  if {$path == ""} {
    return 0
  }
  set islink 0
  catch {
    set res [file readlink $path]
    # if path is not a link, the file readlink statement will throw an exception, and the next statement is not reached.
    set islink 1
  } res
  # log "is_link catch result: $res"
  # log "is_link result: $islink"
  return $islink
}

proc log {str} {
  global LOGROOT
  # set f [open "/home/pi/log/delete-played-symlinks.log" a]
  set f [open [file join $LOGROOT "delete-played-symlinks.log"] a]
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  puts $f "\[$ts\] $str"
  close $f
}

proc logd {str} {
  global DEBUG
  if {$DEBUG} {
    log $str
  }
}

main $argv

