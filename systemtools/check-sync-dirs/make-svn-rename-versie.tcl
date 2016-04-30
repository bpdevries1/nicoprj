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
    puts stderr "syntax: $argv0 <repo-dir-filelist> <svn-rename-versie.bat>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-rename-versie.log"  
  $log debug "argv: $argv"
  lassign $argv filename_repo_dir svn_rename_versie
  set fr [open $svn_rename_versie w]
  
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
    set new_filename [det_new_filename $filename]
    if {$filename != $new_filename} {
      set target_path [file join [file dirname $filepath] $new_filename]
      if {[file exists $target_path]} {
        puts $fr "REM Cannot rename \"[file nativename $filepath]\" => \"[file nativename $target_path]\", file exists"
        $log warn "Cannot rename \"[file nativename $filepath]\" => \"[file nativename $target_path]\", file exists"
      } else {
        puts $fr "svn rename \"[file nativename $filepath]\" \"[file nativename $target_path]\""
      }
    }
  }
  close $f
  close $fr
  $log close_file
}

proc det_new_filename {filename} {
  set rootname [file rootname $filename]
  set ext [file extension $filename]
  regsub -nocase { v(ersie ?)?[0-9]+[ ._][0-9]+} $rootname "" rootname
  regsub -nocase { vs ?[0-9]+[ ._][0-9]+} $rootname "" rootname
  regsub { [0-9]+[ ._][0-9]+$} $rootname "" rootname
  return "[string trim $rootname]$ext"
}

main $argc $argv