#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set DEBUG 0

proc main {argv} {
  global prj_dir
  lassign $argv prj_dir
  try_eval {
	  foreach c_filename [lsort -nocase [glob -directory $prj_dir *.c]] {
		if {![ignore_file [file tail $c_filename]]} {
			handle_c_file $c_filename
		}
	  }
  } {
    # when an error occurs, close the output file
	puts "errorresult: $errorResult"
	puts "errorCode: $errorCode"
	puts "errorInfo: $errorInfo"
	puts "An error occured, close the file"
  }
}

proc ignore_file {c_filename} {
  set ft [file tail $c_filename]
  if {$ft == "pre_cci.c"} {
    return 1
  }
  if {$ft == "vuser_end.c"} {
    return 1
  }
  if {$ft == "vuser_init.c"} {
    return 1
  }
  if {[regexp "^combined" $ft]} {
    return 1
  }
  return 0
}

proc handle_c_file {c_filename} {
  puts "handling $c_filename"
  set ft [file tail $c_filename]
  # put warning when:
  # - in concurrent section
  # - web_reg_save defined
  set in_concurrent 0
  set f [open $c_filename r]
  set linenr 0
  while {![eof $f]} {
    gets $f line
	incr linenr
    if {[regexp "web_concurrent_start" $line]} {
      # web_concurrent_start(NULL);
	  set in_concurrent 1
    } elseif {[regexp "web_concurrent_end" $line]} {
	  # web_concurrent_end(NULL);
      set in_concurrent 0    
    }
	
	if {$in_concurrent} {
	  if {[regexp "web_reg_save" $line]} {
	    puts "$ft/#$linenr: web_reg_save in concurrent section"
	  }
	}
	
  }
  close $f
}

main $argv
