package require ndv

proc main {argv} {
  global f
  lassign $argv root_dir
  set f [open [file join $root_dir "_files-[clock format [clock seconds] -format "%Y-%m-%d-%H-%m"].tsv"] w]
  puts $f [join [list path date] "\t"]
  handle_dir_rec $root_dir "*" handle_file
  close $f
}

proc handle_file {filename rootdir} {
  global f
  if {[regexp {_files} $filename]} {
    return 
  }
  set rel_path [det_relative_path $filename $rootdir]
  set date [clock format [file mtime $filename] -format "%Y-%m-%d"]
  puts $f [join [list $rel_path $date] "\t"]
}

main $argv
