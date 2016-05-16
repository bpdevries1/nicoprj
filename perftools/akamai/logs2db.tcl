#!/usr/bin/env tclsh86

# logs2db - convert Akamai logs to a sqlite db.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require uri

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  if {$argv == ""} {
    set root_dir "~/aaa/akamai/logs/WAF/136606_Mobile/test" 
  } else {
    lassign $argv root_dir
  }
  set db_name [file join $root_dir "akamailogs.db"]
  set conn [open_db $db_name]
  set td_logfile [make_table_def_keys logfile {id} {path}]
  
  set td_log [make_table_def_keys log {id} {logfile_id linenr ipnr x1 ts ts_utc method url domain extension http_version httpresult size referer useragent cookies x3}]
  
  create_table $conn $td_logfile 1
  create_table $conn $td_log 1
  set is_logfile [prepare_insert_td_proc $conn $td_logfile]
  set is_log [prepare_insert_td_proc $conn $td_log]
  # @todo maybe unpack .gz first. Maybe delete logfile after reading, then orig .gz should be saved (default is to delete this one)
  handle_dir_rec $root_dir "*" [list read_logfile $conn $is_logfile $is_log]
  create_indices $conn
  # close_db $conn
  $conn close
}

proc read_logfile {conn is_logfile is_log logfilename rootdir} {
  log info "Reading logfile: $logfilename" 
  if {[file extension $logfilename] == ".db"} {
    log info "Ignoring db file: $logfilename"
    return
  }
  if {[file extension $logfilename] == ".errors"} {
    log info "Ignoring errors file: $logfilename"
    return
  }
  set logfile_id [$is_logfile [dict create path $logfilename] 1]
  log debug "fileid: $logfile_id"
  
  # See fp-ideeen for alternatives.
  # @todo is it visible in log if it's HTTP or HTTPS, or port?
# 90.210.153.225 - - [12/Jul/2013:17:00:53 +0000] "GET /m.philips.co.uk/consumerfiles/mobile/js/libs/jquery-ui-1.8.14.custom.min.js HTTP/1.1" 200 26445 "http://m.philips.co.uk/m/" "Mozilla/5.0 (Linux; U; Android 4.1.2; en-gb; HTC_One Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30" "-" "GEN0_4914||"
# 90.210.153.225 - - [12/Jul/2013:17:00:53 +0000] "GET /m.philips.co.uk/consumerfiles/mobile/js/global.min.js HTTP/1.1" 200 15784 "http://m.philips.co.uk/m/" "Mozilla/5.0 (Linux; U; Android 4.1.2; en-gb; HTC_One Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30" "-" "GEN0_4914||"
# 90.210.153.225 - - [12/Jul/2013:17:00:53 +0000] "GET /m.philips.co.uk/consumerfiles/mobile/js/libs/jquery-1.5.1.min.js HTTP/1.1" 200 30021 "http://m.philips.co.uk/m/" "Mozilla/5.0 (Linux; U; Android 4.1.2; en-gb; HTC_One Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30" "-" "GEN0_4914||"
# 90.210.153.225 - - [12/Jul/2013:17:00:53 +0000] "GET /m.philips.co.uk/consumerfiles/pageitems/master/navigation/groupimages/sound_and_vision_gr_mobile.jpg HTTP/1.1" 200 2051 "http://m.philips.co.uk/m/" "Mozilla/5.0 (Linux; U; Android 4.1.2; en-gb; HTC_One Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30" "-" "GEN0_4914||"
  set f [open $logfilename r]
  set fe [open "$logfilename.errors" w]
  db_in_trans $conn {
    set linenr 0
    while {![eof $f]} {
      gets $f line
      incr linenr
      if {[string trim $line] == ""} {
        continue 
      } 
      if {[expr $linenr % 10000] == 0} {
        log info "Handled $linenr records, start a new transaction"
        db_eval $conn "commit"
        db_eval $conn "begin transaction"
      }
      # cookies can contain a double "" in the string, so regexp fails on this.
      # options:
      # - first replace a double "" with something else, replace it again after regexp has been done.
      # - more difficult RE which copes with double ""
      # so choose option 1, replace with single quote ' and don't replace at the end, not so important
      # @note there is a risk that "" means an empty string...
      # also can have 3 """ in a row, then not clear if it's start or end of quoted string, for now, replace with single "
      regsub -all {\42\42\42} $line "\"" line2
      regsub -all {\42\42} $line2 "'" line3
      if {[regexp {^([^ ]+) -([^\-]+)- \[([^\]\[]+)\] \42([^ ]+) ([^ ]+) ([^\42]+)\42 (\d+) (\d+) \42([^\42]+)\42 \42([^\42]+)\42 \42([^\42]+)\42 \42([^\42]+)\42$} $line3 z \
                  ipnr x1 ts_str method url http_version httpresult size referer useragent cookies x3]} {
        lassign [det_timestamps $ts_str] ts ts_utc
        set url [det_url $url]
        #set domain [det_domain $url]
        #set extension [det_extension $url]
        lassign [dict_get_multi [uri::split $url] host path] domain path
        set extension [file extension $path]
        set d [vars_to_dict logfile_id linenr ipnr x1 ts ts_utc method url domain extension http_version httpresult size referer useragent cookies x3]
        $is_log $d
      } else {
        # breakpoint
        puts $fe "line $linenr: $line"
      }
    }
  }
  close $f
  close $fe
}

# @param ts_str 12/Jul/2013:17:00:53 +0000
proc det_timestamps {ts_str} {
  set ts [clock scan $ts_str -format "%d/%b/%Y:%H:%M:%S %z"]
  set ts_utc [clock format $ts -format "%Y-%m-%d %H:%M:%S"]
  list $ts $ts_utc
}

# @param url /m.philips.co.uk/consumerfiles/pageitems/maste...
# @result http://m.philips.co.uk/consumerfiles/pageitems/maste...
# @note/@todo not sure if https is also possible here.
proc det_url {url} {
  return "http:/$url" 
}

proc create_indices {conn} {
  db_eval $conn "create index ix_log_ts on log (ts)"
  db_eval $conn "create index ix_log_ipnr on log (ipnr)"
}

main $argv


