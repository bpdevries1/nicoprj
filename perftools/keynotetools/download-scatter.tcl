#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

set script_dir [file dirname [info script]]
ndv::source_once download-check.tcl libslotmeta.tcl libkeynote.tcl
ndv::source_once [file join [info script] .. .. .. lib CExecLimit.tcl]

# @todo curl.exe path now hardcoded for windows. This will fail on linux, so make platform dependent.

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files"}
    {config.arg "" "Config file name. If empty, use slotmeta-domains.db"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaded file: json or xml"}
    {exitatok "Exit when one loop returns ok (instead of quota reached"}
    {fromdate.arg "" "Set a date (2013-08-21) from which data should be downloaded (inclusive!)"}
    {untildate.arg "" "Set a date (2013-08-29) until which data should be downloaded (non-inclusive!)"}
    {checkfile.arg "" "Checkfile for nanny process"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  # put this in a loop, to start again at the whole next hour: either for newer data, 
  # or because the quota has been used for the Keynote API
  set exitatok [:exitatok $dargv]
  while {1} {
    set res [download_keynote_main $dargv]
    log info "Download keynote main finished with return code: $res"
    if {($res == "ok") && $exitatok} {
      break 
    }
    wait_until_next_time [:checkfile $dargv]
  }
  log info "Exiting, result = ok, and exitatok"
}

# Start each run each half an hour.
proc wait_until_next_time {checkfile} {
  set finished 0
  update_checkfile $checkfile
  while {!$finished} {
    set minute [scan [clock format [clock seconds] -format "%M"] %d]
    log info "Time: [clock format [clock seconds]]"
    if {[expr $minute % 30] == 0} {
      log info "Finished waiting, starting the next batch of downloads"
      set finished 1 
    } else {
      log info "Wait another (small) minute, until minute is 0 or 30" 
    }
    after 55000
    update_checkfile $checkfile
    # after 5000
  }
}

proc download_keynote_main {dargv} {
  global dl_check exec_limit
  
  set root_dir [:dir $dargv]  
  log info "download_keynote_main: Downloading items to: $root_dir"
  
  if {[:config $dargv] == ""} {
    set dctl_config [query_config $root_dir [det_hostname] [two_weeks_ago]]
  } else {
    # allow old way of specifying for now, when just a part needs to be downloaded quickly.
    # could also use a copy of the database and change something there.
    set dctl_config [csv2dictlist [file join $root_dir [:config $dargv]] ";"]
  }
  set checkfile [:checkfile $dargv]
  
  make_subdirs $root_dir $dctl_config
  
  # start with current time minus 4 hours, so Keynote has time to prepare the data.
  # also start on a whole hour.
  # set sec_start [clock scan [clock format [expr [clock seconds] - 4 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1]
  
  # 26-8-2013 Stel huidige tijd is 10:30 CET, dus 8:30 GMT. Dan laatste sec_start is 7:00 GMT, omdat er een uur bij op wordt geteld, zodat van 7-8 wordt opgehaald.
  # om 10:00 CET, is 8:00 GMT, zal ook alles van 7-8 worden opgehaald, dit is wellicht iets te snel. Voor de zekerheid dan nog een uur eraf.  
  # @note sec_start is actually the most recent time, and sec_end the oldest time. This is because the download happens backward: first the most recent, then older until no more data 
  # available.
  if {[:untildate $dargv] != ""} {
    # do not use GMT here (but default CET in NL), as dashboards are presented by CET date.
    set sec_end [clock scan [:untildate $dargv] -format "%Y-%m-%d" -gmt 0]
  } else {
    # auto/default: until most recent.
    # set sec_end [clock scan [clock format [expr [clock seconds] - 2 * 3600] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1]
    # @note now set to current minus 1.5 hours, so at eg 8.30 the data from 7.00-8.00 can be downloaded.
    set sec_end [clock scan [clock format [expr round([clock seconds] - 1.5 * 3600)] -format "%Y-%m-%d %H" -gmt 1] -format "%Y-%m-%d %H" -gmt 1]    
  }
  if {[:fromdate $dargv] != ""} {
    # do not use GMT here (but default CET in NL), as dashboards are presented by CET date.
    set sec_start [clock scan [:fromdate $dargv] -format "%Y-%m-%d" -gmt 0]
  } else {
    if {[:test $dargv]} {
      set sec_start [expr $sec_end - (4 * 60 * 60)]
    } else {
      # 3-9-2013 6 weeks is long enough, and no detail data more than 6 weeks back.
      set sec_start [expr $sec_end - (6 * 7 * 24 * 60 * 60)]
    }
  }
  set nerrors 0
  set api_key [det_api_key [:apikey $dargv]]
  
  set dl_check [DownloadCheck new $root_dir]

  # for executing curl in a controlled way, with maximum time. When nog using this, either Curl or Tcl may hang.  
  set exec_limit [CExecLimit #auto]
  # $exec_limit set_saveproc_filename "saveproc.txt"
  
  # @todo determine sec_start for each script - later, some possible issues where holes can occur, if one download fails but the next succeeds. Normally a failed one would be retried the next time. Also, downloading normally takes a lot more time than checking the DB.
  # @todo determine sec_end each time again, to download data ASAP.
  # @note this order also means that important scripts (placed at the start of the config) will be handled first.
  # breakpoint
  foreach el_config $dctl_config {
    log info "Handling config element: $el_config"
    # set sec_ts $sec_start
    set sec_ts_slot [det_slot_start $sec_start $el_config]
    set sec_end_slot [det_slot_end $sec_end $el_config]
    while {$sec_ts_slot <= $sec_end_slot} {
      set res [download_keynote $root_dir $el_config $sec_ts_slot $api_key [:format $dargv]]
      if {$res == "quota"} {
        log warn "Quota has been used completely, wait until next hour"
        return $res
      } elseif {$res == "limit"} {
        log warn "Limit of 60 reqs/minute is exceeded, wait one minute now."
        after 60000
      }
      set sec_ts_slot [expr $sec_ts_slot + 3600]  
      update_checkfile $checkfile
    }
  }  
  $dl_check close
  $dl_check destroy 
  return "ok"
}

#    set sec_ts_slot [det_slot_start $sec_start $el_config]
# @return seconds of date where download for this config slot item should start
# the minimum is always sec_start, don't start before this value
proc det_slot_start {sec_start el_config} {
  # use :start_date, allow 2 days slack
  set sec_slot [clock add [clock scan [:start_date $el_config] -gmt 1 -format "%Y-%m-%d"] -2 days]
  expr max($sec_slot, $sec_start)
}

#    set sec_end_slot [det_slot_end $sec_end $el_config]
# @return seconds of date where download for this config slot item should end
# the maximum is always sec_end, don't end after this value
proc det_slot_end {sec_end el_config} {
  # use :end_date, allow 2 days slack
  set sec_slot [clock add [clock scan [:end_date $el_config] -gmt 1 -format "%Y-%m-%d"] 2 days]
  expr min($sec_slot, $sec_end)
}

# @return date of 2 weeks ago from now, formatted Y-m-d
proc two_weeks_ago {} {
  clock format [clock add [clock seconds] -2 weeks] -format "%Y-%m-%d"
}

# @return a list of dict elements, same as csv-config before: dirname, slotids, npages
proc query_config {root_dir hostname checkdate} {
  set db [get_slotmeta_db [file join $root_dir "slotmeta-domains.db"]]
  $db query "select dirname, slot_id slotids, npages, start_date, end_date
             from slot_download
             where download_pc = '$hostname'
             and end_date >= '$checkdate'
             order by download_order, dirname"
}

proc make_subdirs {root_dir dctl_config} {
  foreach el $dctl_config {
    file mkdir [file join $root_dir [:dirname $el]] 
  }
}

# @param sec_ts - based on GMT/UTC and rounded to whole hour (using format/scan).
# @param sec_ts - denoted start of period the data should be downloaded. An hour will be added for the end.
proc download_keynote {root_dir el_config sec_ts api_key format } {
  global dl_check exec_limit
  set filename [det_filename $root_dir $el_config $sec_ts $format]
  if {[$dl_check read? $filename]} {
    # log info "Already have $filename, continuing" ; # or stopping?
    return 
  }
  
  # use tempname to download to, then in one 'atomic' action rename to the right name, 
  # so a possibly running scatter2db.tcl does not interfere.
  set tempfilename "$filename.temp[expr rand()]"  

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
  # set cmd [list curl --sslv3 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]

  # 24-12-2013 ook hier timeout waarden instellen, lijkt af en toe voor te komen dat 'ie blijft hangen. Wel relatief grote waarden, kijken wat 'ie doet.
  # 2-3-2014 curl van cygwin doet het plots niet meer (na upgrade), dus losse curl gebruiken (=64 bits)
  # set cmd [list c:/util/curl/curl.exe --sslv3 --connect-timeout 60 --max-time 120 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]

  set cmd [list [curl_path] --sslv3 --connect-timeout 60 --max-time 120 -o $tempfilename "https://api.keynote.com/keynote/api/getgraphdata?api_key=$api_key\&format=$format\&slotidlist=$slotidlist\&graphtype=scatter\&timemode=absolute\&timezone=UTC\&absolutetimestart=$start\&absolutetimeend=$end\&transpagelist=$transpagelist"]

  log debug "cmd: $cmd"

  if {1} {
    try_eval {
      # log info "Exec Curl: $cmd"
      # execute for a maximum of 5 minutes (300 seconds) 
      # exec $rbinary $script
      # @todo is saveproc name reset, so need to set again and again?
      # $exec_limit set_saveproc_filename "saveproc.txt"
      set exit_code [$exec_limit exec_limit $cmd 300 result res_stderr]
      log info "Exec Curl finished, exitcode = $exit_code, len(result)=[string length $result], len(stderr) = [string length $res_stderr]"
      # 8-3-2014 NdV curious what stderr holds: really an error or just info?
      if {[string length  $res_stderr] > 0} {
        log info "stderr: $res_stderr"
      }
    } {
      log error "Error while executing Curl"
      # continue?
    }  
    # breakpoint
  }
  if {0} {
    try_eval {
      set res [exec -ignorestderr {*}$cmd]
      log debug "res: $res"
    } {
      log warn "$errorResult $errorCode $errorInfo, continuing"   
    }
  }
  
  try_eval {
    file rename -force $tempfilename $filename
  } {
    log_error "Downloaded temp file could not be renamed, continue." 
  }
  set status [check_errors $filename]
  $dl_check set_read $filename $status
  return $status
}

proc det_filename {root_dir el_config sec_ts format} {
  file join $root_dir [:dirname $el_config] "[:dirname $el_config]-[clock format $sec_ts -format "%Y-%m-%d--%H-%M" -gmt 1].$format"
}

proc det_api_key {api_key_loc} {
  string trim [read_file $api_key_loc]
}

# wat proberen met slots/pages, want krijg veel dubbele dingen met MyPhilips (my Mobile niet opgevallen, maar daar maar 1 page)
# @note 2013-08-03 Keynote API seems to be fixed, no need to repeat slot-id anymore in slotidlist param when you want >1 page, now as expected:
# slotidlist: 1
# pages: 1:1, 1:2, 1:3.
# 25-1-2014 add 5 to the number of pages, because the number may change sometimes, don't want to miss pages.
# test showed that nothing extra is downloaded for non existing pages.
proc det_slots_pages {el_config} {
  foreach slotid [split [:slotids $el_config] ","] {
    lappend slotidlist $slotid
    for {set i 1} {$i <= [expr [:npages $el_config] + 5]} {incr i} {
      lappend transpagelist "$slotid:$i"
    }
  }
  # 26-1-2014 deze optie gezien in interactieve gebeuren, blijkt ook hier te werken, wel zo gemakkelijk.
  # vanaf 26-1-2014 13:30 deze methode gebruiken.
  # list [join $slotidlist ","] [join $transpagelist ","]
  list [join $slotidlist ","] "ALL"
}

# @note 30-10-2013 when an known 'error' occurs, just remove the file.
proc check_errors {filename} {
  set res "unknown"
  if {[file exists $filename]} {
    if {[file size $filename] < 500} {
      set text [read_file $filename]
      if {[regexp {hourly request allowed} $text]} {
        log warn "Quota have been used"
        # file rename -force $filename "$filename.quota[expr rand()]"
        file delete -force $filename
        set res "quota"
      } elseif {[regexp {Request blocked} $text]} {
        # Request blocked. Exceeded 60 requests/minute limit.    
        log warn "Request blocked. Exceeded 60 requests/minute limit."
        # file rename -force $filename "$filename.limit[expr rand()]"
        file delete -force $filename
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
