proc main {} {
	# set dir {C:\PCC\Nico\Projecten\Calypso\taskforce april 2016\Logs-20160513}
	set dir {H:\Disciplines\Trim\99 PCC\Projecten\Calypso\taskforce april 2016\Logs-20160513}
	file mkdir [file join $dir 1line]
	foreach filename [glob -directory $dir *.gc] {
		handle_file $filename
	}
}

proc handle_file {filename} {
	if {[ignore_file $filename]} {
		return
	}
	# puts "Handling: $filename"
	set outfilename [file join [file dirname $filename] 1line [file tail $filename]]
	puts "Handling: $filename -> $outfilename"
	set fi [open $filename r]
	set fo [open $outfilename w]
	set firstline 1
	while {[gets $fi line] >= 0} {
		if {[start_line $line]} {
			if {$firstline} {
				set firstline 0
			} else {
				puts $fo ""
			}
		}
		puts -nonewline $fo $line
	}
	close $fi
	close $fo
}

proc ignore_file {filename} {
	set res 1
	if {[regexp {dataserver} $filename]} {
		return 0
	}
	if {[regexp {scheduling} $filename]} {
		return 0
	}
	return $res
}

# 2016-05-07 08:57:25 [745b5258] info    [native] Loading collector peer list from /appl/data/dynatrace-6.2/agent/conf/collectorlist.CalypsoPROD_data 
# 6.403: [GC [1 CMS-init
# [LOG|SYSTEM|07 May 2016 08:57:
set regexps {
  {^[0-9-]{10}}
  {^\d+\.\d{3}: }
  {^\[LOG\|}
}
proc start_line {line} {
	global regexps
	foreach re $regexps {
		if {[regexp $re $line]} {
			return 1
		}
	}
	return 0
}

main