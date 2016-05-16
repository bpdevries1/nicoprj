#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# @todo officieel csv read gebruiken, dan ook quoted dingen aankunnen.
# @todo ook input sepchar met de hand op kunnen geven

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {sepchar.arg "\t" "Separation character for output file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_stdin $ar_argv(sepchar)
  $log info "Finished"
}

proc handle_stdin {sepchar} {
  gets stdin line
  set in_sepchar [det_sepchar $line]
  puts [join [split $line $in_sepchar] $sepchar]
  while {![eof stdin]} {
     puts [join [split [gets stdin] $in_sepchar] $sepchar]
  }
}

proc det_sepchar {line} {
  if {[regexp {\t} $line]} {
    return "\t" 
  } elseif {[regexp ";" $line]} {
    return ";" 
  } elseif {[regexp "," $line]} {
    return "," 
  }
  
}

main $argc $argv
