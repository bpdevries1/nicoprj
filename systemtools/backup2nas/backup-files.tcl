#!/home/nico/bin/tclsh86

package require ndv ; # logging
package require cmdline 
package require struct::list
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

set 4NT_EXE "c:\\util\\4nt\\4nt.exe"

# @todo (per 20-3-2011)
# * kan zijn dat een van beide filesystems (bron of target) even niet beschikbaar is. Dan fouten opnemen in apart tekstbestand,
# en deze volgende keer eerst proberen te doen. Als het dan weer niet lukt, is het echt fout.
# * merk dat backuppen via laptop van NAS naar 2TB erg traag gaat, nu (20-3-2011) ook niet duidelijk hoe lang het gaat duren
# * de balanced line van bron en target lijkt best wel een aardig alternatief. Door met 4NT een dir /s te doen.

# 26-3-2011: gemaakt, testen
# * op kunnen geven hoe veel levels diep je wilt checken: bij archief bv komt er normaal gesproken alleen wat bij op het hoogste 
# niveau, als ik er een afgerond project naartoe verplaats. Lijkt het meest logisch dit in paths.txt als extra kolom op te nemen.
# dus ook checken of een dir nieuw is. If so, dan alles gewoon behandelen, dus in recursie max weer op -1 (bv) zetten.

# @todo
# backuppen duurt nu best lang, ook al valt er bijna niets te backuppen, het checken duurt lang. Opties:
## als het halverwege wordt gestopt, bijhouden waar je bent, soort van sync-points.
## iets met balanced line, vgl music-db met echte files.
## => doe een dir /s, waarbij de padnamen en datums zichtbaar zijn. Parse deze en backup gebaseerd op deze. <=
## deze dir kun je feitelijk al doen zonder dat de backup schijf beschikbaar is. Ook het bepalen welke gebackupped moeten worden
## kan al eerder.
## kan niet de datums van directories gebruiken; kan zijn dat deze ouder zijn terwijl bestanden nieuwer zijn.
## of een soort listener zetten op de hele schijf, vergelijk dropbox, die naar een todo-lijst schrijft.
## of de directory-set om te backuppen erg verkleinen, alle progs dingen eruit, zoals windows, program files, develop. 
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
# 22-3-2011 (untested yet) bij fouten en afbreken wordt de volgende keer de tobackup.txt ingelezen en afgehandeld. Als dit klaar is, kun je
# de backupdatetime vullen met de start van de oorspronkelijk check, die je bv in deze tobackup.txt kunt opnemen. Als eerste
# regel met keyword lijkt het handigst.

proc main {argc argv} {
  global log fres params
  set options {
    {settingsdir.arg "~/.backup2nas" "Dir with settings (paths.txt, ignoreregexps.txt, results.txt)"}
    {paths.arg  "paths.txt"  "use file with paths (relative to settingsdir)"}
    {ignoreregexps.arg  "ignoreregexps.txt"  "use file with paths to ignore (relative to settingsdir)"}
    {r.arg  "results.txt" "write results to file (relative to settingsdir)"}
    {b.arg "backupdatetime.txt" "File to store the last backup date/time in (relative to settingsdir)"}
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
  puts "Normalised path to settingsdir: [file normalize $params(settingsdir)]"
  # ::ndv::CLogger::set_logfile [file join $params(settingsdir) "backup2nas.log"]
  $log set_file [file join $params(settingsdir) "backup2nas.log"]
  
  $log info START
  $log info "argv: $argv"
  $log info "paths: $params(p)"
  $log info "target: $params(t)"
  $log info "settingsdir: $params(settingsdir)" 
  backup_main
  
  $log info FINISHED
}

proc backup_main {} {
  global log params fres fstash lst_ignore_regexps max_path
  set target $params(t)
  if {[check_target $target]} {
    $log debug "check_target failed, exiting"
    exit 1
  }
  signal trap SIGINT handle_signal
  lock_backup
  set totalfiles 0
  set totalbytes 0
  try_eval {
    lassign [set_params] lst_ignore_regexps lst_paths time_treshold
    
    set start_time [clock seconds]
    $log info "time treshold: $time_treshold"
    set max_path [det_max_path] ; # max path length dependent on OS.
    set stashfilename [file join $params(settingsdir) filestobackup.txt]
  
    # 20-3-2011 if something went wrong the previous time, the stashed file still exists.
    # handle this first.
    handle_stashed_files $stashfilename -1 1  
  
    # 20-3-2011 NdV nuttig om met append te doen?, bij fouten delete ik de file steeds.
    # set fstash [open $stashfilename a]
    lassign [fill_stash $stashfilename $lst_paths $target $time_treshold $start_time] totalfiles totalbytes 
    handle_stashed_files $stashfilename $totalfiles 
  
    # pas hier de tijd schrijven, pas hier is (volledige) backup gelukt.
    puts_backup_time $start_time
  } {
    $log error "Backup failed: $errorResult" 
  }
  $log info "Unlock backup, also if an error occurred"
  unlock_backup
  
  $log info "Total files backed up: $totalfiles"
  $log info "Total Megabytes backed up: [format %7.0f [expr $totalbytes / 1024 / 1024]]"  
}

# 20-3-2011 NdV Check/make file should be atomic, but this will work ok most of the time
proc lock_backup {} {
  global params log
  set lockname [file join $params(settingsdir) ".backuplock.lck"]
  if {[file exists $lockname]} {
    $log error "lock file already exists, exiting: $lockname"
    exit 1
  }
  set f [open $lockname w]
  puts $f "locked"
  close $f
}

proc unlock_backup {} {
  global params log
  set lockname [file join $params(settingsdir) ".backuplock.lck"]
  file delete $lockname
}

proc set_params {} {
  global params log
  #set lst_ignore_regexps [::struct::list filterfor el \
  #  [split [read_file [file join $params(settingsdir) $params(ignoreregexps)]] "\n"] {[string trim $el] != ""}] 
  # 10-2-2013 Also ignore lines starting with '#'.
  set lst_ignore_regexps [::struct::list filterfor el \
    [split [read_file [file join $params(settingsdir) $params(ignoreregexps)]] "\n"] {([string trim $el] != "") && ![regexp {^#} $el]}] 
  set lst_paths [::struct::list filterfor el \
    [split [read_file [file join $params(settingsdir) $params(paths)]] "\n"] {[string trim $el] != ""}] 
  # ignore path-lines starting with #
  # breakpoint
  set lst_paths [listc {$el} el <- $lst_paths {![regexp {^#} $el]}]
  
  if {$params(w)} {
    set time_treshold [expr [clock seconds] - (7 * 24 * 60 * 60)] 
  } elseif {$params(p)} {
    # use backupdatetime.txt in settings directory
    if {[file exists [file join $params(settingsdir) $params(b)]]} {
      set time_treshold [clock scan [read_file [file join $params(settingsdir) $params(b)]] -format "%Y-%m-%d %H:%M:%S"] 
    } else {
      $log info "No [file join $params(settingsdir) $params(b)] found, backup everything!"
      set time_treshold 0 
    }
  } else {
    $log info "No -w or -p given, backup everything!"
    set time_treshold 0 
  }
  $log info "lst_ignore_regexps: $lst_ignore_regexps"
  $log info "lst_paths: $lst_paths"
  $log info "time_treshold: $time_treshold"
  $log info "time_treshold as time: [clock format $time_treshold]"
  list $lst_ignore_regexps $lst_paths $time_treshold
}

proc fill_stash {stashfilename lst_paths target time_treshold start_time} {
  global params log fstash

  set fstash [open $stashfilename w]
  chan configure $fstash -encoding "utf-8"
  puts $fstash "backupdatetime: $start_time"
  set totalfiles 0
  set totalbytes 0.0
  foreach path_spec $lst_paths {
    lassign [split $path_spec "\t"] path max_level_check ; # if max_level_check not given, it will be an empty string.
    lassign [backup_path $path $target $params(tempext) $time_treshold 1 $max_level_check] nfiles nbytes
    incr totalfiles $nfiles
    set totalbytes [expr $totalbytes + $nbytes] 
  }
  close $fstash  
  list $totalfiles $totalbytes 
} 


proc puts_backup_time {start_time} {
  global params log
  set f [open [file join $params(settingsdir) $params(b)] w]
  puts $f [clock format $start_time -format "%Y-%m-%d %H:%M:%S"]
  close $f
}

# @todo ga eerst uit van windows
# @note backup all files within path, not just less than 7 days old.
# @note if a copy fails, notify with log.
# @note files will be puth in [file join $target [drive $path] $path
# @param max_level_check only check until max_level_check if files/dirs have changed. 
#        return if max level reached without finding a changed file.
#        if we find a change, check the whole tree again.
#        if param is empty, there is no max.
proc backup_path {path target tempext time_treshold reclevel max_level_check} {
  global log fres 
  # $log debug "Backup up $path => $target"
  if {[ignore_file $path]} {
    return [list 0 0] 
  }
  if {($max_level_check != "") && ($reclevel > $max_level_check)} {
    # 10-2-2013 NdV max level reached log removed.
    # $log info "max level reached ($reclevel > $max_level_check) without finding a change. Path: $path, returning..."
    return [list 0 0]
  } 
  if {$reclevel <= 3} {
    # log only if not ignored.
    $log info "Checking $path"
  }
  set target_path [det_target_path $path $target]
  if {[ignore_file $target_path 1]} {
    return [list 0 0] 
  }
  set totalfiles 0
  set totalbytes 0.0
  if {[file isfile $path]} {
    lassign [handle_file $path $target $tempext $time_treshold] nfiles nbytes
    incr totalfiles $nfiles
    set totalbytes [expr $totalbytes + $nbytes]
  }
  foreach filepattern {* .*} {
    # TODO try_eval omheen zetten.
    try_eval {
      set filenames {}
      set filenames [glob -nocomplain -directory $path -type f $filepattern]
    } {
      $log warn "Could not read directory files: $path"
    }
    foreach filename $filenames {
      lassign [handle_file $filename $target $tempext $time_treshold] nfiles nbytes
      incr totalfiles $nfiles
      set totalbytes [expr $totalbytes + $nbytes] 
    }
    # TODO try_eval omheen zetten.
    try_eval {
      set dirnames {}
      # TODO klopt het dat dit hier ook filepattern moet zijn, en niet gewoon *
      set dirnames [glob -nocomplain -directory $path -type d $filepattern]
    } {
      $log warn "Could not read directory subdirs: $path"
    }
    foreach dirname $dirnames {
      set tail [file tail $dirname]
      if {($tail == ".") || ($tail == "..")} {
        continue
      }
      lassign [backup_path $dirname $target $tempext $time_treshold [expr $reclevel + 1] \
          [new_max_level_check $max_level_check $dirname $time_treshold]] nfiles nbytes
      incr totalfiles $nfiles
      set totalbytes [expr $totalbytes + $nbytes] 
    }
  }
  list $totalfiles $totalbytes
}

proc new_max_level_check {max_level_check dirname time_treshold} {
  if {[file mtime $dirname] < $time_treshold} {
    return $max_level_check ; # too old, max_level_check stays the same
  } else {
    return "" ; # new file, checks are of. 
  }
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
    # file is older than a week or previous backup date/time.
    return [list 0 0]
  }
  stash_backup_file $filename $target $tempext
}

proc stash_backup_file {filename target tempext} {
  global fstash
  puts $fstash "$filename\t$target\t$tempext"
  list 1 [file size $filename]
}

proc handle_stashed_files {stashfilename totalfiles {start 0}} {
  global log
  if {![file exists $stashfilename]} {
    if {!$start} {
      $log error "Stash file does not exist"
      return
    } else {
      $log debug "Stash file does not exist at start."
      return ; # without log. 
    }
  }
  $log info "Copy stashed files (#$totalfiles): start"
  set f [open $stashfilename r]
  chan configure $f -encoding "utf-8"
  gets $f line
  if {[regexp {backupdatetime: (.+)$} $line z st]} {
    set start_time $st
  } else {
    set start_time "<unknown>" 
    close $f ; # reopen file.
    set f [open $stashfilename r]
    chan configure $f -encoding "utf-8"
  }
  set nfiles 0
  while {![eof $f]} {
    gets $f line
    # lassign [split $line "\t"]
    if {[string trim $line] != ""} {
      try_eval {
        backup_file {*}[split $line "\t"] ; # filename target tempext
      } {
        $log warn "Backup failed for $line, $errorResult" 
      }
    }
    incr nfiles
    if {[expr $nfiles % 100] == 0} {
      $log info "Handled $nfiles of $totalfiles files ($line)" 
    }
  }
  close $f
  # remove stash file when all went well
  file delete $stashfilename
  if {$start_time != "<unknown>"} {
    puts_backup_time $start_time
  }
  $log info "Copy stashed files: finished"  
}  

# @return list of [1, size of file copied in bytes]
proc backup_file {filename target tempext} {
  global log fres
  $log debug "backing up: $filename"
  set target_path [det_target_path $filename $target]
  #puts "$filename => $target_path" ; # ook tijdelijk.
  #breakpoint ; # om deze te tonen
  set target_dir [file dirname $target_path]
  # acties op target path pas bij echt kopieren, handle_stashed 
  try_eval {
    if {[file isfile $target_dir]} {
      # vroeger een file, nu een dir: file delete
      file delete $target_dir
    }
    file mkdir $target_dir
    if {[files_equal $filename $target_path]} {
      $log info "Target file is already the same as source, no need to copy: $target_path"
      return [list 0 0]
    }
    # file mkdir [file dirname $target_path]
    set filesize 0
    set filesize [file size $filename]
    set temp_target "$target_path$tempext"
    # 06-06-2014 vorige keer mss niet gelukt om backup te verwijderen en hierna rename van temp->backup.
    # 06-06-2014 volgende keer moet het dan opnieuw.
    file copy -force $filename $temp_target ; # 06-06-2014 force toch nodig hier.
    file delete $target_path
    file rename $temp_target $target_path
    # set target datetime to same as source
    file mtime $target_path [file mtime $filename]
    set ext [file extension $filename]
    if {($ext == ".ost") || ($ext == ".pst")} {
      # outlook files altijd loggen.
      # puts $fres "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\t$filename\tBackup succeeded"
      $log info "$filename: ok"
    }
  } {
    set res $errorResult 
    $log warn $res
    #puts $fres "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\t$filename\t$res"
  }
  list 1 $filesize
}

# return 1 if files are equal, that is, both exist and have the same date/time.
proc files_equal {src target} {
  if {[file exists $target]} {
    if {[file mtime $src] == [file mtime $target]} {
      return 1 
    } else {
      return 0
    }
  } else {
    return 0
  } 
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

# 12-3-2011 also ignore if filename is a link (symlink or hardlink on linux, junction on windows)
# 19-3-2011 if reading the file failes, log this and return 1 (true).
proc ignore_file {filename {istarget 0}} {
  global lst_ignore_regexps max_path log
  if {[string length $filename] > $max_path} {
    $log warn "Filename bigger than $max_path: $filename, cannot perform backup!"
    return 1 
  }
  if {$istarget} {
    return 0 ; # with target only check the filename length, it does not exist yet. 
  }
  set filetype "none"
  catch {set filetype [file type $filename]}
  if {$filetype == "none"} {
    $log warn "Cannot determine filetype of: $filename, returning"
    return 1 
  }
  if {$filetype == "link"} {
    $log debug "Filetype($filename) == link, returning"
    return 1 
  }
  if {[has_invalid_characters $filename]} {
    $log warn "Invalid characters in: $filename, returning..."
    return 1
  }
  foreach re $lst_ignore_regexps {
    if {[regexp -nocase -- $re $filename]} {
      return 1 
    }
  }
  # special case: ? in filename: kan niet op windows, misschien ook nog andere chars.
  if {[regexp {\?} $filename]} {
    $log warn "? in filename, ignoring: $filename"
    return 1 
  }
  return 0
}

proc has_invalid_characters {filename} {
  if {[regexp {\?} $filename]} {
    return 1 
  } else {
    return 0 
  }
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

proc det_max_path {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return 255
  } else {
    return 32000 ; # not verified on linux! 
  }
}

proc handle_signal {} {
  puts "ctrl-c detected, going into debug mode... (exit to exit)"
  breakpoint
  # handle_best_solution
  # exit 1 ; # wel nodig, anders blijft 'ie erin.
}

main $argc $argv

