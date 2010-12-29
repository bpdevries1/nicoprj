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
    puts stderr "syntax: $argv0 <repo-dir-filelist> <svn-move-historie.bat>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-move-historie.log"  
  $log debug "argv: $argv"
  lassign $argv filename_repo_dir svn_ontdubbel
  set fr [open $svn_ontdubbel w]
  set fm [open "svn-mkdir.bat" w]
  
  set f [open $filename_repo_dir r]
  while {![eof $f]} {
    gets $f filepath
    if {$filepath == ""} {
      continue 
    }
    if {[file isdirectory $filepath]} {
      if {[regexp -nocase "historie" $filepath]} {
        puts $fr "svn delete \"[file nativename $filepath]\""
      }
      continue 
    }
    if {[regexp -nocase "historie" $filepath]} {
      set target_path [det_target_path $filepath]
      puts $fm "mkdir /s \"[file nativename [file dirname $target_path]]\""
      puts $fr "svn move \"[file nativename $filepath]\" \"[file nativename $target_path]\""
    }
  }
  close $f
  close $fr
  $log close_file
}

# D:/ITX/Remote/svn/odmsdocs/trunk/docs/10 Planning/05 ISO 27001
# vanaf elt 7: vanaf 10 Planning
proc det_target_path {filepath} {
  return [file join "D:/ITX/Remote/svn/odmsdocs/trunk/docs/90 Historie" {*}[lrange [file split $filepath] 7 end]] 
}

main $argc $argv