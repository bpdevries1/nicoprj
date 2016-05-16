package require ndv

set_log_global debug

proc main {argv} {
	lassign $argv logdir csvfile
	if {[file exists $csvfile]} {
		set fo [open $csvfile a]
	} else {
		set fo [open $csvfile w]
		puts $fo [join [list logfilename iteration sourcefile sourcelinenr loglinenr bio call socketfd] ","]
	}
	foreach logfilename [glob -directory $logdir -type f "*.log"] {
	  handle_file $logfilename $fo
	}
}

	

proc handle_file {logfilename fo} {
  log info "Handling: $logfilename"
  set fi [open $logfilename r]
  set iteration "<none>"
  set loglinenr 0
  while {[gets $fi line] >= 0} {
    incr loglinenr
    if {[regexp {Starting iteration (\d+)\.} $line z it]} {
      set iteration $it
    }
    # Login_cert_main.c(81): BIO[04FDBB48]:write(2812,251) - socket fd=2812
    # Login_cert_main.c(81): BIO[02E3B560]:write(616,215) - socket fd=616
    # lines after vuser terminated.
    # BIO[02EECA20]:write(692,37) - socket fd=692
    if {[regexp {^([^. ]+\.c)\((\d+)\): BIO\[([0-9A-F]+)\]:(.+)$} $line z sourcefile sourcelinenr bio call]} {
      if {[regexp {socket fd=(\d+)} $call z fd]} {
        set socketfd $fd
      } else {
        set socketfd ""
      }
      puts $fo [join [list [file tail $logfilename] $iteration $sourcefile $sourcelinenr $loglinenr $bio "\"$call\"" $socketfd] ","]
    } elseif {[regexp BIO $line]} {
      log error "line with BIO but not parsed: $line"
      breakpoint
    }
  }
  close $fi
}

main $argv
