# test database connection with perftoolset like CDatabase etc.
# 25-5-2010 versie waarbij alles in-place wordt aangepast.
#package require ndv
#package require Tclx

proc main {argc argv} {
  if {$argc != 1} {
    puts stderr "syntax: tclsh anon-logs.tcl <dir>; got: $argv" 
    exit 1
  }
  set input_dir [lindex $argv 0]
  handle_dir $input_dir
}

proc handle_dir {input_dir} {
  # handle files
  foreach filename [glob -type f -nocomplain -directory $input_dir -tails *] {
    handle_file $input_dir $filename 
  }
  
  # handle subdirs
  foreach subdir [glob -type d -nocomplain -directory $input_dir -tails *] {
    handle_dir [file join $input_dir $subdir] 
  }
}

proc handle_file {input_dir filename} {
  set fi [open [file join $input_dir $filename] r]
  set fo [open [file join $input_dir "$filename.__TEMP__"] w]
  while {![eof $fi]} {
    gets $fi line
    regsub -all {[0-9]{9,10}} $line "9999999999" line
    puts $fo $line
  }
  close $fi
  close $fo
  # zet modification time van nieuwe file gelijk aan orig.
  file mtime [file join $input_dir "$filename.__TEMP__"] [file mtime [file join $input_dir $filename]]
  file delete [file join $input_dir $filename]
  file rename [file join $input_dir "$filename.__TEMP__"] [file join $input_dir $filename] 
}

main $argc $argv
