package require ndv

set_log_global info

proc main {} {
  set dir {C:\PCC\Nico\projecten-no-sync\scrittura\scrit-logs-2016-07-05-pat}
  set fi [open [file join $dir xacache.tsv] r]
  set fo [open [file join $dir xacache-min.tsv] w]
  gets $fi header
  puts $fo "ts\tcaches_size"
  set linenr 0
  set prev_size -1
  while {[gets $fi line] >= 0} {
    incr linenr
	lassign [split $line "\t"] z z ts z z z z caches_size
	if {$caches_size != ""} {
		if {$caches_size != $prev_size} {
			regsub -all "," $ts "." ts
			puts $fo "$ts\t$caches_size"	
			set prev_size $caches_size
		}
	}
	if {$linenr % 10000 == 0} {
	  log info "Read line: $linenr"
	}
  }
  
  close $fi
  close $fo
}


main
