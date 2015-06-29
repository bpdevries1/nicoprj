proc main {} {
  #set rootdir {C:\PCC\Nico\Projecten\IntelliMatch\UAT-results}
  set rootdir {C:\projecten\RABO\IntelliMatch\SQLIO}
  
  set fo [open [file join $rootdir summary.tsv] w]
  # Test	iops	MB/s	avg latency (msec)
  # Write, random, 8kb chunks	123.97	0.96	514

  puts $fo [join [list logfilename ts_cet ts_log test filename runtime iops mbps avg_latency_msec] "\t"]
  foreach logfilename [glob -directory $rootdir *.txt] {
    handle_file $logfilename $fo
  }
  close $fo
}

proc handle_file {logpathname fo} {
  set logfilename [file tail $logpathname]
  set lst_vars  {readwrite nkb accesstype filename seconds iops mbps avg_lat_msec}
  set f [open $logpathname r]
  set ts_cet [clock format [file mtime $logpathname] -format "%Y-%m-%d %H:%M:%S"]
  foreach var $lst_vars {
    set $var "<none>"
  }
  set ts_log "<none>"
  while {![eof $f]} {
    gets $f line
    if {[regexp {^(\d\d?:\d\d( [AP]M)?)$} $line z ts]} {
      set ts_log $ts
    }
    
#8 threads reading for 120 secs from file G:\TestFile.dat
#	using 8KB random IOs    
    if {[regexp {\d+ threads ([^ ]+) for (\d+) secs (from|to) file ([^ ]+)} $line z rw sc z fn]} {
      set readwrite $rw
      set seconds $sc
      set filename $fn
      gets $f line
      if {[regexp {using (\d+)KB ([^ ]+) IOs} $line z kb at]} {
        set nkb $kb
        set accesstype $at
      }
    }
    #    IOs/sec: 44373.12
    #MBs/sec:   346.66
    #Avg_Latency(ms): 0
    set_opt iops {IOs/sec: +([0-9.]+)} $line
    set_opt mbps {MBs/sec: +([0-9.]+)} $line
    set_opt avg_lat_msec {Avg_Latency\(ms\): +([0-9.]+)} $line
    if {[regexp {histogram:} $line]} {
      puts $fo [join [list $logfilename $ts_cet $ts_log "$readwrite-$nkb-$accesstype" $filename $seconds $iops $mbps $avg_lat_msec] "\t"]
      foreach var $lst_vars {
        set $var "<none>"
      }
    }
  }
  
  close $f
}

proc set_opt {varname re line} {
  upvar $varname var
  if {[regexp $re $line z v]} {
    set var $v
  }
}

main
