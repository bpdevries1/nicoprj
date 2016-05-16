#!/usr/bin/env tclsh86

# download-longterm.tcl

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
# source [file join $script_dir download-check.tcl]

proc main {argv} {
  # global nerrors
  
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL-longterm" "Directory to put downloaded keynote files"}
    {config.arg "config.csv" "Config file name"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaded file: json or xml"}
    {fromdate.arg "2012-01-01" "Set a date (2013-08-21) from which data should be downloaded (inclusive!)"}
    {untildate.arg "" "Set a date (2013-08-29) until which data should be downloaded (non-inclusive!). Empty means until now."}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]

  # put this in a loop, to start again at the whole next hour: either for newer data, 
  # or because the quota has been used for the Keynote API
  set res [download_keynote_main $dargv]
  log info "res: $res"
}

proc download_keynote_main {dargv} {
  set root_dir [:dir $dargv]  
  log info "download_keynote_main: Downloading items to: $root_dir"
  
  # set dct_config [csv2dictlist [file join $root_dir config.csv] ";"]
  set dct_config [csv2dictlist [file join $root_dir [:config $dargv]] ";"]
  make_subdirs $root_dir $dct_config
  set api_key [det_api_key [:apikey $dargv]]
  
  foreach el_config $dct_config {
    set res [download_keynote $root_dir $el_config $api_key [:format $dargv] $dargv]
    # exit ; # for test.
    if {$res == "quota"} {
      log warn "Quota has been used completely, wait until next hour"
      return $res
    } elseif {$res == "limit"} {
      log warn "Limit of 60 reqs/minute is exceeded, wait one minute now."
      after 60000
    }
  }
  return "ok"
}

proc make_subdirs {root_dir dct_config} {
  foreach el $dct_config {
    file mkdir [file join $root_dir [:dirname $el]] 
  }
}

proc download_keynote {root_dir el_config api_key format dargv} {
  global dl_check
  set filename [det_filename $root_dir $el_config $format]
  if {[file exists $filename]} {
    log info "Already read, returning: $filename"
    return
  }
  # use tempname to download to, then in one 'atomic' action rename to the right name, 
  # so a possibly running scatter2db.tcl does not interfere.
  set tempfilename "$filename.temp[expr rand()]"  

  lassign [det_slots_pages $el_config] slotidlist transpagelist
  
  log info "Download Longterm Keynote data => $filename"
  log info "slots/pages: $slotidlist/$transpagelist"
  
  # absolutetimestart=2013-JUN-16%2012:00%20PM&absolutetimeend=2013-JUN-16%2001:00%20PM
  set fmt "%Y-%b-%d"
  # string toupper needed because %b gives Jun, while JUN is needed.
  set start [string toupper [clock format [clock scan [:fromdate $dargv] -format "%Y-%m-%d" -gmt 1] -format $fmt -gmt 1]]
  if {[:untildate $dargv] == ""} {
    set end [string toupper [clock format [clock seconds] -format $fmt -gmt 1]]
  } else {
    set end [string toupper [clock format [clock scan [:untildate $dargv] -format "%Y-%m-%d" -gmt 1] -format $fmt -gmt 1]]
  }
  
  # set cmd [list curl --sslv3 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]
  # example longterm: curl --sslv3 -o test.xml "https://api.keynote.com/keynote/api/getgraphdata?api_key=<apikey>&format=xml&slotidlist=1098839&graphtype=time&timemode=absolute&timezone=UTC&absolutetimestart=2012-JAN-01&absolutetimeend=2013-DEC-31&transpagelist=1098839:1,1098839:2,1098839:3,1098839:4,1098839:5,1098839:6,1098839:7,1098839:8,1098839:9,1098839:10,1098839:11&longterm=Y"
  set day [expr 24*3600]
  set cmd [list curl --sslv3 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=time\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist\&longterm=Y\&bucket=$day"]

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
  set status [check_errors $filename]
  return $status
}

proc det_filename {root_dir el_config format} {
  file join $root_dir [:dirname $el_config] "[:dirname $el_config]-[clock format [clock seconds] \
    -format "%Y-%m-%d" -gmt 1].$format"
}

proc det_api_key {api_key_loc} {
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
  if {[regexp {\}$} $text]} {
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
