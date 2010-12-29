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
    puts stderr "syntax: $argv0 <repo-dir-filelist> <svn-delete.bat>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-delete.log"  
  $log debug "argv: $argv"
  lassign $argv filename_repo_dir svn_delete
  set fr [open $svn_delete w]
  
  set f [open $filename_repo_dir r]
  while {![eof $f]} {
    gets $f filepath
    if {$filepath == ""} {
      continue 
    }
    if {[file isdirectory $filepath]} {
      # lege directories verwijderen
      if {[llength [glob -nocomplain -directory $filepath *]] == 0} {
        puts $fr "REM empty dir, remove: $filepath"
        puts $fr "svn delete \"[file nativename $filepath]\""
      }
    } else {
      # $log debug "filepath: $filepath"
      if {[regexp -nocase {\\oud} $filepath]} {
        puts $fr "REM oud in filepath, remove: $filepath"
        puts $fr "svn delete \"[file nativename $filepath]\""
      }
      $log debug "file size van $filepath: [file size $filepath]"
      if {[file size $filepath] == 0} {
        puts $fr "REM leeg bestand, remove: $filepath"
        puts $fr "svn delete \"[file nativename $filepath]\""
      }
    }
  }
  close $f
  close $fr
  $log close_file
}

main $argc $argv