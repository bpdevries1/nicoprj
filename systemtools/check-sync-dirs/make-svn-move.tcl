package require struct::list
package require fileutil
package require Tclx
package require ndv

::ndv::source_once check-files-lib.tcl
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]


proc main {argc argv} {
  global stderr argv0 log
  if {$argc != 5} {
    puts stderr "syntax: $argv0 <repo-dir-filelist> <temp-to-dir> <real-to-dir> <svn-rename.bat> <svn-mkdir.bat>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-move.log"  
  $log debug "argv: $argv"
  lassign $argv filename_repo_dir temp_to_dir real_to_dir svn_rename svn_mkdir
  read_dir_repo $filename_repo_dir 
  set fr [open $svn_rename w]
  set fm [open $svn_mkdir w]
  for_recursive_glob filename [list $temp_to_dir] * {
    if {[file isdirectory $filename]} {
      continue 
    }
    if {[regexp {\.svn} $filename]} {
      $log debug "Ignoring: $filename"
      continue 
    }
    set lst_same [det_lst_same_name $filename] ; # list of list: dirname, size, mtime (sec)
    set same_file [det_same_file_lst $filename $lst_same]
    if {$same_file} {
      if {[llength $lst_same] != 1} {
         $log warn "More than 1 source file found for $filename: $lst_same"
      }
      set src_name [file join [lindex $lst_same 0 0] [file tail $filename]]
      if {[regexp -- "_deleted" $filename]} {
        puts $fr "svn delete \"[file nativename $src_name]\"" 
      } else {
        set real_target_name [det_real_target_name $temp_to_dir $real_to_dir $filename]
        if {[file nativename $src_name] != [file nativename $real_target_name]} {
          puts $fm "mkdir /s \"[file nativename [file dirname $real_target_name]]\""
          puts $fr "svn move \"[file nativename $src_name]\" \"[file nativename $real_target_name]\""
        } else {
          $log debug "Source and target are the same, don't move" 
        }
      }
    } else {
      $log warn "Not a same file found in src_dir for $filename" 
    }
  }
  close $fr
  close $fm
  $log close_file
}

# @param filename is filename in temp_to_dir
# @result filename in target_to_dir
proc det_real_target_name {temp_to_dir real_to_dir filename} {
  return [file join $real_to_dir {*}[lrange [file split $filename] [llength [file split $temp_to_dir]] end]] 
}

main $argc $argv