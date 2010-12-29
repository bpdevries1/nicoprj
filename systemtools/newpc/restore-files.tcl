package require ndv ; # logging
package require cmdline 
package require struct::list
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log fres
  
  $log debug "argv: $argv"
  set options {
      {p.arg  "paths.txt"  "use file with paths"}
      {r.arg  "results.txt" "write results to file"}
      {s.arg  ""  "restore from source dir"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set params [::cmdline::getoptions argv $options $usage]
  if {$params(s) == ""} {
    puts [::cmdline::usage $options $usage]
    exit 1
  }
  $log debug "paths: $params(p)"
  $log debug "source: $params(s)"
  
  set source $params(s)
  set lst_paths [::struct::list filterfor el [split [read_file $params(p)] "\n"] {([string trim $el] != "") && (![regexp {^#} $el])}] 
  set fres [open $params(r) w]
  foreach path $lst_paths {
    restore_path $path $source
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
# @note restore all files within path, not just less than 7 days old.
# @note if a copy fails, notify with log.
# @note files will be puth in [file join $source [drive $path] $path
proc restore_path {path source} {
  global log fres
  $log info "Restore $path => $source"
  
  # exec echo R | cmd /c copy /A: /S /U /V [to_bs $path/*.*] [to_bs [file join $source $from_drive]] 
  set source_dir [det_source_dir $path $source]
  
  try_eval {
    # file mkdir [file join $source $from_drive]
    # file mkdir $source_dir
    file mkdir $path ; # mogelijk fout bij i en j schijf
    # vraag of slashes goed gaan.
    # $log debug [exec echo R  cmd /c copy /A: /S /U /V [to_bs $path/*.*] [to_bs [file join $source $from_drive]]]
    # set res [exec -ignorestderr echo R | C:\\util\\4nt\\4NT.EXE /c copy /Q /A: /S /U /V [to_bs $path/*.*] [to_bs $source_dir] 2>@1] 
    
    set res ""
    $log debug "Restore from $source_dir => $path"
    set res [exec -ignorestderr echo R | C:\\util\\4nt\\4NT.EXE /c copy /Q /A: /S /U /V [to_bs $source_dir/*.*] [to_bs $path] 2>@1] 
    $log debug "res: $res"
  } {
    set res $errorResult
    $log debug $res
  }
# "D:\nico\nicoprj\misctools\newpc\.svn\props\*.*"
#4DOS/NT: Er zijn geen bestanden meer.

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

proc det_source_dir {path source} {
  global log
  set lst [file split $path]
  $log debug $lst
  set res [file join $source [det_from_drive $path] {*}[lrange [file split $path] 1 end]]
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

main $argc $argv

