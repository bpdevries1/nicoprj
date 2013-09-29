#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# @todo eg Mobile-Android: new script, so no data before certain date, continuously we get zero result. In this case, should stop downloading
# this data. How to determine?

# @todo use stdlib to determine status of each file?
# 15-9-2013 added 'read' subdir to move files to after scatter2db has read them. Needed to change download and check-progress as well.
# can imagine using eg one subdir per month, because number of file in each dir grows. One month is about 30*24=720 files, that's ok.
# noticed that scatter2db was never finished, so possibly checking if a file has been read takes quite some time.

# @todo handle: Request blocked. Exceeded 60 requests/minute limit.

proc main {argv} {
  # global nerrors
  
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files"}
    {config.arg "config.csv" "Config file name"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaded file: json or xml"}
    {exitatok "Exit when one loop returns ok (instead of quota reached"}
    {fromdate.arg "" "Set a date (2013-08-21) from which data should be downloaded (inclusive!)"}
    {untildate.arg "" "Set a date (2013-08-29) until which data should be downloaded (non-inclusive!)"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]

  # put this in a loop, to start again at the whole next hour: either for newer data, 
  # or because the quota has been used for the Keynote API
  set exitatok [:exitatok $dargv]
  while {1} {
    set res [download_keynote_main $dargv]
    log info "Download keynote main finished with return code: $res"
    if {($res == "ok") && $exitatok} {
      break 
    }
    wait_until_next_hour 
  }
  log info "Exiting, result = ok, and exitatok"
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

proc download_keynote_main {dargv} {
  set root_dir [:dir $dargv]  
  log info "download_keynote_main: Downloading items to: $root_dir"
  
  # set dct_config [csv2dictlist [file join $root_dir config.csv] ";"]
  set dct_config [csv2dictlist [file join $root_dir [:config $dargv]] ";"]
  make_subdirs $root_dir $dct_config
  
  # start with current time minus 4 hours, so Keynote has time to prepare the data.
  # also start on a whole hour.
  # set sec_start [clock scan [clock format [expr [clock seconds] - 4 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1]
  
  # 26-8-2013 Stel huidige tijd is 10:30 CET, dus 8:30 GMT. Dan laatste sec_start is 7:00 GMT, omdat er een uur bij op wordt geteld, zodat van 7-8 wordt opgehaald.
  # om 10:00 CET, is 8:00 GMT, zal ook alles van 7-8 worden opgehaald, dit is wellicht iets te snel. Voor de zekerheid dan nog een uur eraf.  
  # @note sec_start is actually the most recent time, and sec_end the oldest time. This is because the download happens backward: first the most recent, then older until no more data 
  # available.
  if {[:untildate $dargv] != ""} {
    # do not use GMT here (but default CET in NL), as dashboards are presented by CET date.
    set sec_start [clock scan [:untildate $dargv] -format "%Y-%m-%d" -gmt 0]
  } else {
    # auto: until most recent.
    set sec_start [clock scan [clock format [expr [clock seconds] - 2 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1]
  }
  if {[:fromdate $dargv] != ""} {
    # do not use GMT here (but default CET in NL), as dashboards are presented by CET date.
    set sec_end [clock scan [:fromdate $dargv] -format "%Y-%m-%d" -gmt 0]
  } else {
    if {[:test $dargv]} {
      set sec_end [expr $sec_start - (4 * 60 * 60)]
    } else {
      # 3-9-2013 6 weeks is long enough, and no detail data more than 6 weeks back.
      set sec_end [expr $sec_start - (6 * 7 * 24 * 60 * 60)]
    }
  }
  set nerrors 0
  set api_key [det_api_key [:apikey $dargv]]
  
  set sec_ts $sec_start
  while {$sec_ts >= $sec_end} {
    foreach el_config $dct_config {
      set res [download_keynote $root_dir $el_config $sec_ts $api_key [:format $dargv]]
      if {$res == "quota"} {
        log warn "Quota has been used completely, wait until next hour"
        return $res
      } elseif {$res == "limit"} {
        log warn "Limit of 60 reqs/minute is exceeded, wait one minute now."
        after 60000
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
  set filename_read [file join [file dirname $filename] read [file tail $filename]] 
  # use tempname to download to, then in one 'atomic' action rename to the right name, 
  # so a possibly running scatter2db.tcl does not interfere.
  set tempfilename "$filename.temp[expr rand()]"  
  
  if {[file exists $filename]} {
    # log info "Already have $filename, continuing" ; # or stopping?
    return
  }
  # 15-9-2013 Filename can also exist in the 'read' subdirectory.
  if {[file exists $filename_read]} {
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
  # set cmd [list curl --sslv3 -o $filename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]
  set cmd [list curl --sslv3 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]
  log debug "cmd: $cmd"
  try_eval {
    set res [exec -ignorestderr {*}$cmd]
    log debug "res: $res"
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"   
  }
  try_eval {
    file rename -force $tempfilename $filename
  } {
    log_error "Downloaded temp file could not be renamed, continue." 
  }
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

# wat proberen met slots/pages, want krijg veel dubbele dingen met MyPhilips (my Mobile niet opgevallen, maar daar maar 1 page)
# @note 2013-08-03 Keynote API seems to be fixed, no need to repeat slot-id anymore in slotidlist param when you want >1 page, now as expected:
# slotidlist: 1
# pages: 1:1, 1:2, 1:3.
# @todo 2013-08-03 15:30 all MyPhilips downloads before this time are 3 times the size, so remove and download again when all the rest has been done.
proc det_slots_pages {el_config} {
  foreach slotid [split [:slotids $el_config] ","] {
    lappend slotidlist $slotid
    for {set i 1} {$i <= [:npages $el_config]} {incr i} {
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
        log warn "Quota have been used"
        file rename -force $filename "$filename.quota[expr rand()]"
        set res "quota"
      } elseif {[regexp {Request blocked} $text]} {
        # Request blocked. Exceeded 60 requests/minute limit.    
        log warn "Request blocked. Exceeded 60 requests/minute limit."
        file rename -force $filename "$filename.limit[expr rand()]"
        set res "limit"
      } elseif {[regexp {^[\[\],]+$} $text]} {
        log info "Empty contents, but this can happen, is ok"
        set res "ok"
      } elseif {[regexp {invalid slotid list} $text]} {
        log info "Invalid slotid list, probably script is not active, is ok"
        set res "ok"
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
        file rename -force $filename "$filename.incomplete[expr rand()]"
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
