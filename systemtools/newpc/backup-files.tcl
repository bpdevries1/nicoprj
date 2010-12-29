package require ndv ; # logging
package require cmdline 
package require struct::list
package require Tclx

# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

::ndv::CLogger::set_logfile "backup2nas.log"

proc main {argc argv} {
  global log fres params
  
  $log debug "argv: $argv"
  set options {
      {p.arg  "paths.txt"  "use file with paths"}
      {r.arg  "results.txt" "write results to file"}
      {t.arg  ""  "backup to target dir"}
      {w "" "Only backup if less than a week old"} 
  }
  set usage ": [file tail [info script]] \[options] :"
  array set params [::cmdline::getoptions argv $options $usage]
  if {$params(t) == ""} {
    puts [::cmdline::usage $options $usage]
    exit 1
  }
  $log debug "paths: $params(p)"
  $log debug "target: $params(t)"
  
  set target $params(t)
  check_target $target
  set lst_paths [::struct::list filterfor el [split [read_file $params(p)] "\n"] {[string trim $el] != ""}] 
  set fres [open $params(r) w]
  foreach path $lst_paths {
    backup_path $path $target
  }
  close $fres
}

proc read_file {filename} {
  set f [open $filename r]
  set res [read $f]
  close $f
  return $res
}

# @todo ga eerst uit van windows
# @note backup all files within path, not just less than 7 days old.
# @note if a copy fails, notify with log.
# @note files will be puth in [file join $target [drive $path] $path
proc backup_path {path target} {
  global log fres params
  $log info "Backup up $path => $target"
  
  # exec echo R | cmd /c copy /A: /S /U /V [to_bs $path/*.*] [to_bs [file join $target $from_drive]] 
  set target_dir [det_target_dir $path $target]
  
  try_eval {
    # file mkdir [file join $target $from_drive]
    file mkdir $target_dir
    # vraag of slashes goed gaan.
    # $log debug [exec echo R  cmd /c copy /A: /S /U /V [to_bs $path/*.*] [to_bs [file join $target $from_drive]]]
    if {$params(w)} {
      # @todo xcopy gebruiken, want 4NT copy geeft segfault. (vanaf ongeveer 1-3-2010) 
      set res [exec -ignorestderr echo R | C:\\util\\4nt\\4NT.EXE /c copy /\[d-7\] /Q /A: /S /U /V [to_bs $path/*.*] [to_bs $target_dir] 2>@1]
      # @todo /d:01-03-2010
      # set res [exec -ignorestderr echo R | C:\\WINDOWS\\system32\\xcopy.EXE [to_bs $path/*.*] [to_bs $target_dir] /c /s /r /h /y       /\[d-7\] /Q /A: /S /U /V 2>@1]
    } else {
      set res [exec -ignorestderr echo R | C:\\util\\4nt\\4NT.EXE /c copy /Q /A: /S /U /V [to_bs $path/*.*] [to_bs $target_dir] 2>@1] 
    }
    $log debug "res: $res"
  } {
    set res $errorResult
    $log debug $res
  }

  set lst_res [::struct::list filterfor el [split $res "\n"] {
    ([string trim $el] != "") && (![regexp {\\\*\.\*\"$} $el]) &&
      (![regexp {Er zijn geen bestanden meer.$} $el]) &&
      (![regexp {\(Replace\) \(Y/N/R\)} $el]) &&
      (![regexp {child process exited abnormally} $el])
      }]
      
  # "
  set str [join $lst_res "\n"]
  if {$str != ""} {
    $log error $str
    puts $fres $str
  }
}

proc det_target_dir {path target} {
  global log
  set lst [file split $path]
  $log debug $lst
  set res [file join $target [det_from_drive $path] {*}[lrange [file split $path] 1 end]]
  $log debug "res: $res"
  # exit
  return $res
}

proc det_from_drive {path} {
  if {[regexp {^([a-z]):} [string tolower $path] z drive]} {
    return $drive 
  } elseif {[regexp {^([a-z]):} [pwd] z drive]} {
    return $drive
  } else {
    error "Cannot determine drive from $path (pwd=[pwd])" 
  }
}

proc to_bs {path} {
  regsub -all "/" $path {\\} path
  return $path
}

# @note check if path is writable, by creating and deleting a dummy file.
# @result if it's not writable, an error is automatically generated.
proc check_target {path} {
  global log
  $log info "Checking target path: $path"
  set DUMMY "__dummy__.txt"
  set f [open [file join $path $DUMMY] w]
  puts $f "file: $DUMMY"
  close $f
  file delete $DUMMY
  $log info "Target path: $path is writable"
}

main $argc $argv

