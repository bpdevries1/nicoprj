#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global nerrors
  
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaden file: json or xml"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  # put this in a loop, to start again at the whole next hour: either for newer data, 
  # or because the quota has been used for the Keynote API
  while {1} {
    set res [download_keynote_main $dct_argv]
    log info "Download keynote main finished with return code: $res"
    wait_until_next_hour 
  }
}

proc wait_until_next_hour {} {
  set finished 0
  set start_hour [clock format [clock seconds] -format "%H"]
  while {!$finished} {
    set hour [clock format [clock seconds] -format "%H"]
    log info "Time: [clock format [clock seconds]]"
    if {$hour != $start_hour} {
      log info "Finished waiting, starting the next batch of downloads"
      set finished 1 
    } else {
      log info "Wait another 5 minutes, until hour != $start_hour" 
    }
    after 300000
    # after 5000
  }
}

proc download_keynote_main {dct_argv} {
  set root_dir [:dir $dct_argv]  
  log info "download_keynote_main: Downloading items to: $root_dir"
  
  set dct_config [csv2dictlist [file join $root_dir config.csv] ";"]
  make_subdirs $root_dir $dct_config
  
  # start with current time minus 4 hours, so Keynote has time to prepare the data.
  # also start on a whole hour.
  set sec_start [clock scan [clock format [expr [clock seconds] - 4 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1] 
  if {[:test $dct_argv]} {
    set sec_end [expr $sec_start - (4 * 60 * 60)]
  } else {
    set sec_end [expr $sec_start - (8 * 7 * 24 * 60 * 60)]
  }
  set nerrors 0
  set api_key [det_api_key [:apikey $dct_argv]]
  
  set sec_ts $sec_start
  while {$sec_ts >= $sec_end} {
    foreach el_config $dct_config {
      set res [download_keynote $root_dir $el_config $sec_ts $api_key [:format $dct_argv]]
      if {$res == "quota"} {
        log warn "Quota has been used completely, wait until next hour"
        return $res
      }
    }
    set sec_ts [expr $sec_ts - 3600] 
  }
  return "ok"
}

proc make_subdirs {root_dir dct_config} {
  foreach el $dct_config {
    file mkdir [file join $root_dir [:dirname $el]] 
  }
}

proc download_keynote {root_dir el_config sec_ts api_key format } {
  set filename [det_filename $root_dir $el_config $sec_ts $format]
  if {[file exists $filename]} {
    # log info "Already have $filename, continuing" ; # or stopping?
    return
  }
  lassign [det_slots_pages $el_config] slotidlist transpagelist
  
  log info "Download Keynote data for [clock format $sec_ts] => $filename"
  log info "slots/pages: $slotidlist/$transpagelist"
  
  # absolutetimestart=2013-JUN-16%2012:00%20PM&absolutetimeend=2013-JUN-16%2001:00%20PM
  set fmt "%Y-%b-%d%%20%I:%M%%20%p"
  # string toupper needed because %b gives Jun, while JUN is needed.
  set start [string toupper [clock format $sec_ts -format $fmt -gmt 1]]
  set end [string toupper [clock format [expr $sec_ts + 3600] -format $fmt -gmt 1]]
  # @note check if it works with just giving transpagelist, not slotidlist -> NO, this does not work!
  set cmd [list curl --sslv3 -o $filename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]
  log debug "cmd: $cmd"
  try_eval {
    set res [exec -ignorestderr {*}$cmd]
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"   
  }
  log debug "res: $res"
  return [check_errors $filename]
}

proc det_filename {root_dir el_config sec_ts format} {
  # file join $root_dir "keynote-mobile-[clock format $sec_ts -format "%Y-%m-%d--%H-%M" -gmt 1].$format"
  file join $root_dir [:dirname $el_config] "[:dirname $el_config]-[clock format $sec_ts -format "%Y-%m-%d--%H-%M" -gmt 1].$format"
}

proc det_api_key {api_key_loc} {
  # string trim [read_file [file join ~ .config keynote api-key.txt]]
  # string trim [read_file "~/.config/keynote/api-key.txt"]
  string trim [read_file $api_key_loc]
}

proc det_slots_pages {el_config} {
  foreach slotid [split [:slotids $el_config] ","] {
    for {set i 1} {$i <= [:npages $el_config]} {incr i} {
      lappend slotidlist $slotid
      lappend transpagelist "$slotid:$i"
    }
  }
  list [join $slotidlist ","] [join $transpagelist ","]
}

proc check_errors {filename} {
  set res "unknown"
  if {[file exists $filename]} {
    if {[file size $filename] < 500} {
      set text [read_file $filename]
      if {[regexp {hourly request allowed} $text]} {
        log warn "Quota have been used: check file and do a good text-check on this"
        file rename -force $filename $filename.quota
        set res "quota"
      } else {
        log warn "Unknown error with too small file"
        file rename -force $filename "$filename.toosmall[expr rand()]"
        set res "toosmall"
      }      
    } else {
      if {[file_complete $filename]} {
        set res "ok"
      } else {
        log warn "jsonxml downloaded is not complete, rename and try again next hour"
        file rename -force $filename $filename.incomplete
        set res "incomplete"
      }
    }
  } else {
    log warn "Downloaded file doesn't exist: $filename"
    set res "noexist"
  }
  return $res
}

proc file_complete {filename} {
  set text [string trim [last_chars $filename 10]]
  if {[file extension $filename] == ".json"} {
    if {[regexp {\]\]$} $text]} {
      return 1 
    } else {
      return 0 
    }
  } elseif {[file extension $filename] == ".xml"} {
    if {[regexp {>$} $text]} {
      return 1 
    } else {
      return 0 
    }
  } else {
    error "Unknown extension for filename: $filename" 
  }
}

# return last nchars from textfile 
proc last_chars {filename nchars} {
  set f [open $filename r]
  seek $f -10 end
  set res [read $f]  
  close $f
  return $res
}

main $argv
