#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global nerrors
  if {[llength $argv] == 0} {
    set root_dir "c:/aaa/keynote-mobile"
  } else {
    lassign $argv root_dir 
  }
  file mkdir $root_dir
  # start with current time minus 4 hours, so Keynote has time to prepare the data.
  set sec_start [clock scan [clock format [expr [clock seconds] - 4 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1] 
  if {1} {
    set sec_end [expr $sec_start - (8 * 7 * 24 * 60 * 60)]
  } else {
    # to test, just a few hours.
    set sec_end [expr $sec_start - (7 * 60 * 60)]
  }
  set sec_ts $sec_start
  set nerrors 0
  while {$sec_ts >= $sec_end} {
    download_keynote $root_dir $sec_ts
    if {$nerrors >= 10} {
      log error "#nerrors too high, exiting..."
      # @note when a clock-hour has passed, we may start again.
      # eg error on 16.55, we can restart at 17.01.
      exit 1
    }
    set sec_ts [expr $sec_ts - 3600] 
  }
}

proc download_keynote {root_dir sec_ts} {
  global nerrors
  set filename [det_filename $root_dir $sec_ts]
  if {[file exists $filename]} {
    log info "Already have $filename, continuing" ; # or stopping?
    # @todo check size of file, if too small, print contents and commandline that caused it.
    return
  }
  log info "Download Keynote data for [clock format $sec_ts] => $filename"
  # absolutetimestart=2013-JUN-16%2012:00%20PM&absolutetimeend=2013-JUN-16%2001:00%20PM
  set fmt "%Y-%b-%d%%20%I:%M%%20%p"
  # string toupper needed because %b gives Jun, while JUN is needed.
  set start [string toupper [clock format $sec_ts -format $fmt -gmt 1]]
  set end [string toupper [clock format [expr $sec_ts + 3600] -format $fmt -gmt 1]]
  set api_key [det_api_key]
  set cmd [list curl --sslv3 -o $filename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=json\&slotidlist=1060724,1060726,1138756\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=1060724:1,1060726:1,1138756:1"]
  log debug "cmd: $cmd"
  set res [exec -ignorestderr {*}$cmd]
  log debug "res: $res"
  
  if {[file exists $filename]} {
    if {[file size $filename] < 2000} {
      incr nerrors
    } else {
      # ok. 
    }
  } else {
    incr nerrors 
  }
}

proc det_filename {root_dir sec_ts} {
  file join $root_dir "keynote-mobile-[clock format $sec_ts -format "%Y-%m-%d--%H-%M" -gmt 1].json"
}

proc det_api_key {} {
  string trim [read_file [file join ~ .config keynote api-key.txt]]
}

main $argv
