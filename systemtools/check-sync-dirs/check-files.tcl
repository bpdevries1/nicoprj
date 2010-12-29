package require struct::list
package require fileutil

::ndv::source_once check-files-lib.tcl

proc main {argc argv} {
  global stderr
  if {$argc != 2} {
    puts stderr "syntax: check-files.tcl <repo-dir-filelist> <check-files-list>; got: $argv" 
    exit 1
  }
  lassign $argv filename_repo_dir filename_check_files
  read_dir_repo $filename_repo_dir 
  # foreach filename [lsort [glob -type f *]] {}
  set f [open $filename_check_files r]
  while {![eof $f]} {
    gets $f filename
    if {[file isdirectory $filename]} {
      continue 
    }
    if {[string trim $filename] == ""} {
      continue 
    }
    set lst_same [det_lst_same_name $filename] ; # list of list: dirname, size, mtime (sec)
    set same_file [det_same_file_lst $filename $lst_same]
    puts "[same_file_char $same_file] $filename [file size $filename] [format_time $filename]"
    foreach dirname_info $lst_same {
      lassign $dirname_info dirname size mtime
      puts "  [same_file_char [det_same_file $filename $dirname]] [file nativename $dirname] $size [format_time [file join $dirname $filename]]"
    }
    if {$lst_same == {}} {
      puts "  NOT FOUND" 
    }
  }
}

main $argc $argv