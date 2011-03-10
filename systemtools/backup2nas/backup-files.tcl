#!/home/nico/bin/tclsh

package require ndv ; # logging
package require cmdline 
package require struct::list
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

set BACKUPDATETIME "backupdatetime.txt"
set 4NT_EXE "c:\\util\\4nt\\4nt.exe"

# @todo
# backuppen duurt nu best lang, ook al valt er bijna niets te backuppen, het checken duurt lang. Opties:
## als het halverwege wordt gestopt, bijhouden waar je bent, soort van sync-points.
## iets met balanced line, vgl music-db met echte files.
## => doe een dir /s, waarbij de padnamen en datums zichtbaar zijn. Parse deze en backup gebaseerd op deze. <=
## deze dir kun je feitelijk al doen zonder dat de backup schijf beschikbaar is. Ook het bepalen welke gebackupped moeten worden
## kan al eerder.
## kan niet de datums van directories gebruiken; kan zijn dat deze ouder zijn terwijl bestanden nieuwer zijn.
## of een soort listener zetten op de hele schijf, vergelijk dropbox, die naar een todo-lijst schrijft.
## of de directory-set om te backuppen erg verkleinen, alle progs dingen eruit, zoals windows, programming files, develop. 
# evt retry op de failed: aan het einde.
# evt met handle kijken welk process de file gelocked houdt.
# -w: eigenlijk alleen backuppen als het nieuwer is dan de vorige backup start.

# DONE
# ignore list gebruiken.
# test met outlook-folder, want deze is gelocked.
# geen symlinks volgen: al automatisch, volgens doc.
# results-file anders: failed items noteren + oorzaak
# alleen bestanden nieuwer dan een week.
# Eerst kopieren naar een temp-file, als dit gelukt is een delete en rename uitvoeren. Vooral bij grote files verkleint dit het risico op corrupte files.

::ndv::CLogger::set_logfile "backup2nas.log"

proc main {argc argv} {
  global log fres fstash lst_ignore_regexps BACKUPDATETIME 
  $log info START
  $log debug "argv: $argv"
  set options {
    {settingsdir.arg "~/.backup2nas" "Dir with settings (paths.txt, ignoreregexps.txt, results.txt"}
    {paths.arg  "paths.txt"  "use file with paths (relative to settingsdir)"}
    {ignoreregexps.arg  "ignoreregexps.txt"  "use file with paths to ignore (relative to settingsdir)"}
    {r.arg  "results.txt" "write results to file (relative to settingsdir)"}
    {t.arg  ""  "backup to target dir"}
    {p "Only backup new files and files changed since previous succesful backup (uses backupdatetime.txt (relative to settingsdir))"}
    {w "Only backup if less than a week old"}
    {tempext.arg ".__TEMPQQQ__" "Extension used for creating temp files"}
    {use4nt "Use 4NT dir command to determine if files need to be updated"}
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
  if {[check_target $target]} {
    $log debug "check_target failed, exiting"
    exit 1
  }
  set lst_ignore_regexps [::struct::list filterfor el \
    [split [read_file [file join $params(settingsdir) $params(ignoreregexps)]] "\n"] {[string trim $el] != ""}] 
  set lst_paths [::struct::list filterfor el \
    [split [read_file [file join $params(settingsdir) $params(paths)]] "\n"] {[string trim $el] != ""}] 
  set fres [open [file join $params(settingsdir) $params(r)] a] ; # append mode.
  if {$params(w)} {
    set time_treshold [expr [clock seconds] - (7 * 24 * 60 * 60)] 
  } elseif {$params(p)} {
    # use backupdatetime.txt in current directory
    if {[file exists [file join $params(settingsdir) $BACKUPDATETIME]]} {
      set time_treshold [clock scan [read_file [file join $params(settingsdir) $BACKUPDATETIME]] -format "%Y-%m-%d %H:%M:%S"] 
    }
  } else {
    set time_treshold 0 
  }
  set start_time [clock seconds]
  
  set totalfiles 0
  set totalbytes 0.0
  set stashfilename [file join $params(settingsdir) filestobackup.txt]
  set fstash [open $stashfilename a]
  foreach path $lst_paths {
    if {$params(use4nt)} {
      lappend res [backup_path_4nt $path $target $params(tempext) $time_treshold]
    } else {
      lassign [backup_path $path $target $params(tempext) $time_treshold] nfiles nbytes
      incr totalfiles $nfiles
      set totalbytes [expr $totalbytes + $nbytes] 
    }
  }
  close $fres
  close $fstash
  handle_stashed_files $stashfilename  
  
  # pas hier de tijd schrijven, pas hier is (volledige) backup gelukt.
  set f [open [file join $params(settingsdir) $BACKUPDATETIME] w]
  puts $f [clock format $start_time -format "%Y-%m-%d %H:%M:%S"]
  close $f

  $log info "Total files backed up: $totalfiles"
  $log info "Total Megabytes backed up: [format %7.0f [expr $totalbytes / 1024 / 1024]]"  
  $log info FINISHED
}

# @todo ga eerst uit van windows
# @note backup all files within path, not just less than 7 days old.
# @note if a copy fails, notify with log.
# @note files will be puth in [file join $target [drive $path] $path
proc backup_path {path target tempext time_treshold} {
  global log fres 
  $log debug "Backup up $path => $target"
  if {[ignore_file $path]} {
    return [list 0 0] 
  }
  set target_path [det_target_path $path $target]
  if {[file isfile $target_path]} {
    # vroeger een file, nu een dir: file delete
    file delete $target_path
  }
  file mkdir $target_path
  set totalfiles 0
  set totalbytes 0.0
  foreach filepattern {* .*} {
    foreach filename [glob -nocomplain -directory $path -type f $filepattern] {
      lassign [handle_file $filename $target $tempext $time_treshold] nfiles nbytes
      incr totalfiles $nfiles
      set totalbytes [expr $totalbytes + $nbytes] 
    }
    foreach dirname [glob -nocomplain -directory $path -type d $filepattern] {
      set tail [file tail $dirname]
      if {($tail == ".") || ($tail == "..")} {
        continue
      }
      lassign [backup_path $dirname $target $tempext $time_treshold] nfiles nbytes
      incr totalfiles $nfiles
      set totalbytes [expr $totalbytes + $nbytes] 
    }
  }
  list $totalfiles $totalbytes
}

# @note if a copy fails, notify with log.
# @note files will be puth in [file join $target [drive $path] $path
proc backup_path_4nt_old {path target tempext time_treshold} {
  global log fres 4NT_EXE
  $log debug "Backup up $path => $target"
  try_eval {
    file delete 4nt.dir
    exec $4NT_EXE /c dir [file nativename $path] /s /a /r /h /m >4nt.dir 
  } {
    $log error "Failed to exec 4NT dir. errorResult: $errorResult"
    # toch doorgaan, wel child process exited abnormally, maar alles lijkt goed en file is aangemaakt.
    # error "Failed to exec 4NT dir; errorResult: $errorResult"
  }
  set last_dir_created "<none>"
  set f [open 4nt.dir r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^ Directory of (.*)\\\*$} $line z dirname]} {
      set current_dir [string trim $dirname] 
      set dirname "<none>"
    } elseif {[regexp {^([^ ]+ +[^ ]+) +([^ ]+) +(.+)$} $line z datetime filesize filename]} {
      if {$filesize == "<DIR>"} {
        continue 
      }
      set sec [clock scan $datetime -format "%d-%m-%y  %H:%M"]
      if {$sec < $time_treshold} {
        continue 
      }
      set filepath [file join $current_dir $filename]
      if {[ignore_file $filepath]} {
        continue 
      }
      # 17-10-2010 bij ignorefiles nu /~ opgenomen, file join denkt dat een ~ de homedir is, en is op windows niet zo.
      if {$current_dir != $last_dir_created} {
        file mkdir [det_target_path $current_dir $target]
        set last_dir_created $current_dir
      }
      backup_file $filepath $target $tempext
    }
  }
  close $f
}

# @return list of [1, size of file copied in bytes]
# @rturn list [0,0] if file not copied (to ignore or too old)
proc handle_file {filename target tempext time_treshold} {
  global log
  # nu even debug om bug te vinden.
  $log debug "handling: $filename"
  if {[ignore_file $filename]} {
    return [list 0 0]
  }
  if {[file mtime $filename] < $time_treshold} {
    # file is older than a week.
    return [list 0 0]
  }
  stash_backup_file $filename $target $tempext
}

proc stash_backup_file {filename target tempext} {
  global fstash
  puts $fstash "$filename\t$target\t$tempext"
  list 1 [file size $filename]
}

proc handle_stashed_files {stashfilename} {
  global log
  $log info "Copy stashed files: start"
  set f [open $stashfilename r]
  while {![eof $f]} {
    gets $f line
    # lassign [split $line "\t"]
    if {[string trim $line] != ""} {
      backup_file {*}[split $line "\t"] ; # filename target tempext
    }
  }
  # remove stash file when all went well
  file delete $stashfilename
  $log info "Copy stashed files: finished"  
}  

# @return list of [1, size of file copied in bytes]
proc backup_file {filename target tempext} {
  global log fres
  $log debug "backing up: $filename"
  set target_path [det_target_path $filename $target]
  # file mkdir [file dirname $target_path]
  try_eval {
    set temp_target "$target_path$tempext"
    file copy $filename $temp_target ; # force niet nodig hier.
    file delete $target_path
    file rename $temp_target $target_path
    set ext [file extension $filename]
    if {($ext == ".ost") || ($ext == ".pst")} {
      # outlook files altijd loggen.
      puts $fres "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\t$filename\tBackup succeeded"
      $log info "$filename: ok"
    }
  } {
   set res $errorResult 
    $log warn $res
    puts $fres "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\t$filename\t$res"
  }
  list 1 [file size $filename]
}

# path: d:/nico/nicoprj/test.txt
# target: w:/backups/delltest
# result: w:/backups/delltest/d/nico/nicoprj/test.txt
proc det_target_path {path target} {
  global log
  set lst [file split $path]
  # $log debug $lst
  set res [file join $target [det_from_drive $path] {*}[lrange [file split $path] 1 end]]
  #$log info "res: $res"
  #exit
  return $res
}

# @todo bij draaien op linux werkt dit niet.
proc det_from_drive {path} {
  if {[regexp {^([a-z]):} [string tolower $path] z drive]} {
    return $drive 
  } elseif {[regexp {^([a-z]):} [pwd] z drive]} {
    return $drive
  } elseif {[regexp {^/} $path]} {
    # waarschijnlijk linux
    return ""
  } else {
    error "Cannot determine drive from $path (pwd=[pwd])" 
  }
}

proc ignore_file {filename} {
  global lst_ignore_regexps
  foreach re $lst_ignore_regexps {
    if {[regexp -nocase -- $re $filename]} {
      return 1 
    }
  }
  return 0
}

# @note check if path is writable, by creating and deleting a dummy file.
# @result if it's not writable, an error is automatically generated.
proc check_target {path} {
  global log
  $log info "Checking target path: $path"
  try_eval {
    file mkdir $path
    set DUMMY "__dummy__.txt"
    set f [open [file join $path $DUMMY] w]
    puts $f "file: $DUMMY"
    close $f
    file delete $DUMMY
    $log info "Target path: $path is writable"
  } {
    $log error "errorResult: $errorResult"
    return 1
  }
  return 0
}

main $argc $argv

