package require struct::list
package require fileutil
package require Tclx
package require ndv
package require math

::ndv::source_once check-files-lib.tcl
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]


proc main {argc argv} {
  global stderr argv0 log
  if {$argc != 2} {
    puts stderr "syntax: $argv0 <repo-dir-filelist> <svn-ontdubbel.bat>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-ontdubbel.log"  
  $log debug "argv: $argv"
  lassign $argv filename_repo_dir svn_ontdubbel
  read_dir_repo $filename_repo_dir 
  set fr [open $svn_ontdubbel w]
  
  # repo-dir.txt nu nog eens langslopen
  set f [open $filename_repo_dir r]
  while {![eof $f]} {
    gets $f filepath
    if {$filepath == ""} {
      continue 
    }
    if {[file isdirectory $filepath]} {
      continue 
    }
    set filename [file tail $filepath]
    if {[array names ar_filenames $filename] != {}} {
      # already handled
      continue
    }
    set ar_filenames($filename) 1
    set lst_same [det_lst_same_name $filename] ; # list of list: dirname, size, mtime (sec)
    if {[llength $lst_same] <= 1} {
      continue; # only one file with this name. 
    }
    set dir_to_keep [det_dir_to_keep $lst_same]
    $log info "File to keep: [file join $dir_to_keep $filename]"
    puts $fr "\nREM File to keep: [file join $dir_to_keep $filename]"
    foreach el $lst_same {
      set str_di [dirinfo_to_str $el $filename]
      if {[lindex $el 0] == $dir_to_keep} {
        $log info "Keep this file: $str_di" 
        puts $fr "REM Keep this file: $str_di"
        puts $fr "REM svn delete \"[file nativename [file join [lindex $el 0] $filename]]\""
      } else {
        $log info "Remove this file: $str_di"
        puts $fr "REM Remove this file: $str_di"
        puts $fr "svn delete \"[file nativename [file join [lindex $el 0] $filename]]\"" 
      }
    }
  }
  close $f
  close $fr
  $log close_file
}

proc dirinfo_to_str {di filename} {
  lassign $di dirname size mtime
  return "[file nativename [file join $dirname $filename]] $size [format_time [file join $dirname $filename]]"
}

proc det_dir_to_keep {lst_same} {
  # bepaal max van de timestamps, index 2 bij elk element.
  set max_time [::struct::list fold [::struct::list mapfor el $lst_same {lindex $el 2}] 0 ::math::max]
  # retourneer de dir van het eerste element wat qua tijd is gelijk aan dit maximum.
  return [lindex [::struct::list filterfor el $lst_same {
    [lindex $el 2] == $max_time
  }] 0 0]
}

main $argc $argv