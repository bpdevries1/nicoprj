# 2016-06-23 14:00:00,326 [[ACTIVE] ExecuteThread: '30' for queue: 'weblogic.kernel.Default (self-tuning)'] DEBUG com.ipicorp.tools.cache.XACache  - Size after START 1035641
# 2016-06-23 14:00:00,326 [[ACTIVE] ExecuteThread: '30' for queue: 'weblogic.kernel.Default (self-tuning)'] DEBUG com.ipicorp.tools.cache.XACache  - 
# Size after START 1035641

proc main {} {
  set logname {C:\PCC\Nico\Projecten\Scrittura\Troubleshoot-2016\xacache-logs\xacache.log}
  set outname "$logname.csv"
  set fi [open $logname r]
  set fo [open $outname w]
  puts $fo [join {ts tp size} "\t"]
  while {[gets $fi line] >= 0} {
	if {[regexp {^([0-9 :-]+),\d+ \[\[.*Size after (.+) (\d+)$} $line z ts tp n]} {
		puts $fo [join [list $ts $tp $n] "\t"]
	}
  }
  
  close $fi
  close $fo
}

main
