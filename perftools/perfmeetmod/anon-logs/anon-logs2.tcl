# test database connection with perftoolset like CDatabase etc.
# 25-5-2010 versie waarbij je input en output-dir opgeeft.
#package require ndv
#package require Tclx

proc main {argc argv} {
  if {$argc != 2} {
    puts stderr "syntax: tclsh anon-logs.tcl <input-dir> <output_dir>; got: $argv" 
    exit 1
  }
  set input_dir [lindex $argv 0]
  set output_dir [lindex $argv 1]
  handle_dir $input_dir $output_dir
}

proc handle_dir {input_dir output_dir} {
  file mkdir $output_dir
  
  # handle files
  foreach filename [glob -type f -nocomplain -directory $input_dir -tails *] {
    handle_file $input_dir $output_dir $filename 
  }
  
  # handle subdirs
  foreach subdir [glob -type d -nocomplain -directory $input_dir -tails *] {
    handle_dir [file join $input_dir $subdir] [file join $output_dir $subdir] 
  }
}

proc handle_file {input_dir output_dir filename} {
  set fi [open [file join $input_dir $filename] r]
  set fo [open [file join $output_dir $filename] w]
  while {![eof $fi]} {
    gets $fi line
    regsub -all {[0-9]{9,10}} $line "9999999999" line
    puts $fo $line
  }
  close $fi
  close $fo
}

main $argc $argv
