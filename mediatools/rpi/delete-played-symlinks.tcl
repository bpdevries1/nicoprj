#!/usr/bin/env tclsh
# edited remote with emacs.

proc main {} {
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

proc check_and_delete {} {
  set tempname "/home/pi/log/omxplayer-temp.log"
  set temp2name "/home/pi/log/omxplayer-temp2.log"

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
      # log "got line: $line"
      # ignore cmdline options, starting with - but also something behind it, like -o local. So start with first /
      if {[regexp {^[0-9 :-]+: .*/usr/bin/omxplayer.bin [^/]+ (/.+)$} $line z path]} {
        # log "matched regexp: ***${path}***"
        if {[is_link $path]} {
          # remove symlink, it has been played
          log "file is link - delete: $path"
          file delete $path
        } else {
          # log "not a link, leave it: $path"
        }
      } else {
        log "did not match regexp: $line"
      }
    }
    close $f
    file delete $temp2name
  }
}

proc is_link {path} {
  # log "is_link started: $path"
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
  set f [open "/home/pi/log/delete-played-symlinks.log" a]
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  puts $f "\[$ts\] $str"
  close $f
}

main



