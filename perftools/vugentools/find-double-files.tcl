proc main {} {
  set root "C:/PCC/Nico/VuGen/EnablingFarmers_UC2_post"
  
  set root_files [glob -tails -directory $root -type f *]
  set sub_files [det_subfiles $root]
  
  set f [open [file join $root "delete-files.bat"] w]
  puts $f "rem root_files: $root_files"
  puts $f "rem sub_files: $sub_files"
  puts $f "rem =================="
  foreach fn $root_files {
    if {[lsearch $sub_files $fn] > -1} {
      puts $f "del $fn"
    }
  }
  close $f
}

proc det_subfiles {root} {
  set dirs_todo [glob -directory $root -type d *]
  set res {}
  while {[llength $dirs_todo] > 0} {
    set dir [lindex $dirs_todo 0]
    set dirs_todo [lrange $dirs_todo 1 end]
    lappend dirs_todo {*}[glob -nocomplain -directory $dir -type d *]
    lappend res {*}[glob -nocomplain -directory $dir -type f -tails *]
  }
  return $res
}

main
