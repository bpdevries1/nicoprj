#!/usr/bin/env tclsh86

# curl-get-headers-parallel.tcl

# @todo parallel advanced: max N per domain (instead max N total).

package require tdbc::sqlite3
package require Tclx
package require ndv
package require textutil

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

source curl-generator.tcl

proc main {argv} {
  set root_folder [det_root_folder] ; # based on OS.
  set db_name [file join $root_folder "aaa/akamai.db"]

  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  # @note 6-5-2013 NdV even curlgetheader2, want loopt thuis ook nog, weer mergen morgen.
  set table_def [make_table_def curlgetheader ts_start ts fieldvalue param exitcode \
      resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype \
      maxage cachekey akamaiserver domain httpresultcode]
  #set src_table_defs [list [dict create table embedded field url] \
  #                         [dict create table embedded field embed]]
  set src_table_defs [list [dict create table firebug field url] \
                           [dict create table firebug field embedded_url]]

  set ts_start [det_now]
  set ts_treshold [det_ts_treshold $ts_start 3600]
  set drop_table 0
  set nparallel 5 ; # to test.                      
  
  lassign $argv settingsfile
  if {$settingsfile != ""} {
    log info "Source settings from $settingsfile"
    source $settingsfile
  } else {
    log warn "No settings file: using defaults" 
  }

  log info "Opening database: $db_name"
  # exit
  set conn [open_db $db_name]
  create_table $conn $table_def $drop_table ; # 1: first drop the table.
  lookup_entries_parallel $conn $table_def $src_table_defs $ts_start $ts_treshold $nparallel
}

proc lookup_entries_parallel {conn table_def src_table_defs ts_start ts_treshold nparallel} {
  foreach src_table_def $src_table_defs {
    lookup_entries_parallel_src $conn $table_def $src_table_def $ts_start $ts_treshold $nparallel
  }
}

# @todo? dit is volledig coordinated (itt pre-emptive) multitasking: als een curl blijft hangen, blijft het hele proces uiteindelijk hangen.
proc lookup_entries_parallel_src {conn table_def src_table_def ts_start ts_treshold nparallel} {
  global ndone finished jobs_running
  set max_rows 100
  # set max_rows 5
  set total_todo [det_total_todo $conn $src_table_def $table_def $ts_treshold]
  log info "Total to do for $src_table_def: $total_todo"
  set gen [gen_urls $conn $src_table_def $table_def $max_rows $ts_treshold]
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  set akamai_env "prod"
  set global_values [vars_to_dict conn stmt_insert ts_start akamai_env total_todo gen]
  set ndone 0
  set jobs_running 0
  db_eval $conn "begin transaction"
  foreach url [generator takeList $nparallel $gen] {
    log info "First start job for: $url"
    start_job [make_job $url] $global_values
  }
  if {$jobs_running > 0} {
    set finished 0
    vwait finished
  } else {
    log info "No jobs started, finished immediately" 
  }
  log info "Finished (1)"
  db_eval $conn "commit"
}

proc make_job {url} {
  set res {}
  foreach iter {0 1} {
    lappend res [dict create iter $iter url $url] 
  }
  return $res
}

proc start_job {job global_values} {
  start_job_part [lindex $job 0] [lrange $job 1 end] $global_values
}

proc start_job_part {job_part rest global_values} {
  global job_output jobs_running
  dict_to_vars $job_part
  set f [open "|curl -IXGET -H \"Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no\" -L --connect-timeout 20 --max-time 30 \"$url\"" r]
  set job_output($f) ""
  fconfigure $f -blocking 0
  set job_info [dict create msec_start [clock milliseconds]]
  fileevent $f readable [list cb_job $f $job_part $rest $global_values $job_info]
  incr jobs_running
  log info "Set #jobs_running to: $jobs_running"
}

proc cb_job {f job_part rest global_values job_info} {
  global job_output finished jobs_running
  append job_output($f) [read $f]
  if {[eof $f]} {
    set data $job_output($f)
    unset job_output($f)
    fileevent $f readable {}
    close $f
    incr jobs_running -1
    handle_job_output $job_part $data $global_values $job_info
    if {[llength $rest] > 0} {
      start_job_part [lindex $rest 0] [lrange $rest 1 end] $global_values
    } else {
      set gen [dict get $global_values gen]
      generator next $gen url
      # generator geeft lege string als 'ie klaar is, geen hasNext functie.
      if {$url == ""} {
        log info "Finished (2)" 
        # set finished 1
        if {$jobs_running <= 0} {
          log info "All jobs done, set global finished to 1"
          set finished 1 
        }
      } else {
        start_job [make_job $url] $global_values
      }
    }
  } else {
    # nothing, continue executing and reading output 
  }
  
}

# @note this proc (and all others) is single threaded.
proc handle_job_output {job_part data global_values job_info} {
  global ndone
  dict_to_vars $global_values
  dict_to_vars $job_part
  dict_to_vars $job_info ; # msec_start
  
  set exitcode 0
  set resulttext $data
  set fieldvalue $url
  foreach dct [split_resulttext $url $data] {
    dict_to_vars $dct ; # url2 and resulttext 
    set param $url2
    set domain [det_domain $url2]
    foreach varname {cacheheaders cacheable expires expiry cachetype maxage cachekey akamaiserver httpresultcode} {
      set $varname [det_$varname $resulttext] 
    }
    set ts [det_now]
    set msec_end [clock milliseconds]
    set msec [expr $msec_end - $msec_start]
    set dct_insert [vars_to_dict ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage cachekey akamaiserver domain httpresultcode]
    stmt_exec $conn $stmt_insert $dct_insert
  }
  
  if {$iter == 1} {
    incr ndone 
    log info "total so far=$ndone/$total_todo, [format %.2f [expr 100.0 * $ndone / $total_todo]]% done"
    log info "ETA: [det_eta $ts_start $ndone $total_todo]"
  }
  if {$ndone % 100 == 0} {
     db_eval $conn "commit"
     db_eval $conn "begin transaction"
     log info "Started new transaction: $ndone"
  }
}

# if redirect happened, make a list of url/resulttext pairs (in dictionary). If not, return param url2 and data in list.
proc split_resulttext {url data} {
  set res {}
  set url2 $url
  foreach part [textutil::splitx $data {\n\n}] {
    if {[string trim $part] == ""} {
      continue 
    }
    lappend res [dict create url2 $url2 resulttext $part]
    if {[regexp {\nLocation: ([^\n]+)} $part z u]} {
      set url2 $u 
    } else {
      set url2 "<none>" 
    }
  }
  return $res
}

# @note this proc (and all others) is single threaded.
proc handle_job_output_old {job_part data global_values job_info} {
  global ndone
  dict_to_vars $global_values
  dict_to_vars $job_part
  dict_to_vars $job_info ; # msec_start
  set fieldvalue $url
  set param $url
  set domain [det_domain $url]
  set exitcode 0
  set resulttext $data
  foreach varname {cacheheaders cacheable expires expiry cachetype maxage cachekey akamaiserver httpresultcode} {
    set $varname [det_$varname $resulttext] 
  }
  set ts [det_now]
  set msec_end [clock milliseconds]
  set msec [expr $msec_end - $msec_start]
  set dct_insert [vars_to_dict ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage cachekey akamaiserver domain httpresultcode]
  stmt_exec $conn $stmt_insert $dct_insert
  if {$iter == 1} {
    incr ndone 
    log info "total so far=$ndone/$total_todo, [format %.2f [expr 100.0 * $ndone / $total_todo]]% done"
    log info "ETA: [det_eta $ts_start $ndone $total_todo]"
  }
  if {$ndone % 100 == 0} {
     db_eval $conn "commit"
     db_eval $conn "begin transaction"
     log info "Started new transaction: $ndone"
  }
}

proc main_test {argv} {
  global finished
  log info "temp main for testing"
  set url "http://www.philips.nl/c/"
  set f [open "|curl -IXGET -H \"Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no\" -L --connect-timeout 20 --max-time 30 \"$url\"" r]
  log info "Opened file handle to curl process"
  
  set finished 0
  fconfigure $f -blocking 0
  fileevent $f readable [list curl_ready $f]
  log info "Issued file event"
  
  if {0} {
    while {![eof $f]} {
      gets $f line
      log debug "exec line: $line"
    }
    log debug "eof found"
    fconfigure $f -blocking 0 
    close  $f
  }
  vwait finished
  # log info "Waiting for finished done!"
  while {!$finished} {
    log info "Now waiting for file events"
    update
    after 1000  
  }
  
  log info "Finished (3)"
}

proc curl_ready {f} {
  global finished
  set data [read $f]
  log debug "\[[string length $data]\]: $data"
  if {[eof $f]} {
    fileevent $f readable {}
    # fconfigure $f -blocking 0 
    close  $f
    set finished 1
  }  
}

proc det_total_todo {conn src_table_def table_def ts_treshold} {
  log debug "src_table_def: $src_table_def"
  lassign [dict_get_multi $src_table_def table field where] src_table_name src_field where
  if {$where == ""} {
    set where_clause "1=1" 
  } else {
    set where_clause $where
  }
  dict_to_vars $table_def
  set query "select count(distinct t.$src_field) aantal
             from $src_table_name t
             where $where_clause
             and not exists (
               select 1
               from $table c
               where c.fieldvalue = t.$src_field
               and c.ts_start >= '$ts_treshold'
             )"
  set dct [lindex [db_query $conn $query] 0]
  dict get $dct aantal
}

# @param ts_start sqlite formatted
proc det_eta {ts_start ndone total_todo} {
  set sec_start [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"]
  set sec_now [clock seconds]
  set sec_diff [expr $sec_now - $sec_start]
  if {$sec_diff > 0} {
    set npersec [expr 1.0 * $ndone / $sec_diff]
    if {$npersec > 0} {
      set sec_end [expr round($sec_start + ($total_todo / $npersec))]
      return [clock format $sec_end -format "%Y-%m-%d %H:%M:%S"]
    } else {
      return "<unknown>"
    }
  } else {
    return "<unknown>"
  }
}

# determine treshold time based on starttime and offset.
# example: ts_start = 12:00, sec_offset = 600.
# idea is to re-curl everything that was last done before 11:50.
proc det_ts_treshold {ts_start sec_offset} {
  set sec [expr [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"] - $sec_offset]
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

proc det_cacheheaders {resulttext} {
  set l [split $resulttext "\n"]
  set res {}
  foreach el $l {
    if {[regexp -nocase {cache} $el]} {
      lappend res $el 
    }
  }
  join $res "\n"
}

# Last-Modified: Tue, 16 Apr 2013 08:37:30 GMT
# Cache-Control: max-age=86400
# Date: Thu, 02 May 2013 14:12:30 GMT
# Expires: Tue, 09 Apr 2013 01:22:45 GMT
# X-Cache: TCP_HIT from a195-10-36-81.deploy.akamaitechnologies.com (AkamaiGHost/6.11.2.2-10593690) (-)
# X-Check-Cacheable: YES

proc det_cacheable {resulttext} {
  det_header_field $resulttext "X-Check-Cacheable"
}

proc det_expires {resulttext} {
  set res [det_header_field $resulttext "Expires"]
  if {$res == "<none>"} {
    return $res 
  } else {
    set sec -1
    catch {set sec [clock scan $res]}
    if {$sec == -1} {
      return "<unable to parse: $res>" 
    } else {
      return [clock format $sec -format "%Y-%m-%d %H:%M:%S" -gmt 1]
    }
  }
}

proc det_expiry {resulttext} {
  set exp [det_header_field $resulttext "Expires"]
  set now [det_header_field $resulttext "Date"]
  if {($exp == "<none>") || ($now == "<none>")} {
    return "<none>" 
  } else {
    set sec_exp -1
    set sec_now -1
    catch {set sec_exp [clock scan $exp]}
    catch {set sec_now [clock scan $now]}
    if {$sec_exp == -1} {
      return "<unable to parse Expires: $exp>" 
    } elseif {$sec_now == -1} {
      return "<unable to parse Date: $now>"
    } else {
      set sec_diff [expr $sec_exp - $sec_now]
      if {$sec_diff < 0} {
        return "past" 
      } elseif {$sec_diff <= 3600} {
        return "<1hr" 
      } else {
        return ">1hr" 
      }
    }
  }
}

# X-Cache: TCP_HIT from a195-10-36-81.deploy.akamaitechnologies.com (AkamaiGHost/6.11.2.2-10593690) (-)
proc det_cachetype {resulttext} {
  set res [det_header_field $resulttext "X-Cache"]
  if {$res == "<none>"} {
    return $res 
  } else {
    if {[regexp {^([^ ]+)} $res z tp]} {
      return $tp 
    } else {
      return $res 
    }
  }
}

# Cache-Control: max-age=86400
proc det_maxage {resulttext} {
  set res [det_header_field $resulttext "Cache-Control"]
  if {$res == "<none>"} {
    return $res 
  } else {
    if {[regexp {max-age=([^\n]+)} $res z age]} {
      return $age 
    } else {
      return "<none>" 
    }
  }
}

proc det_cachekey {resulttext} {
  if {[regexp {X-Cache-Key: ([^\n]+)} $resulttext z ck]} {
    set cachekey $ck 
  } else {
    set cachekey "<none>" 
  }
  return $cachekey  
}

proc det_akamaiserver {resulttext} {
  if {[regexp { from ([^ ]+)} $resulttext z aksrv]} {
    set akamaiserver $aksrv    
  } else {
    set akamaiserver "<none>" 
  }
  return $akamaiserver  
}

proc det_httpresultcode {resulttext} {
  if {[regexp {HTTP/[^ ]+ ([0-9]+)} $resulttext z httpresultcode]} {
    return $httpresultcode 
  } else {
    return "<none>" 
  }
}

proc det_header_field {resulttext fieldname} {
  set re "$fieldname: (\[^\\n\]+)"
  if {[regexp $re $resulttext z value]} {
    return $value 
  } else {
    return "<none>" 
  }
}

proc det_domain {url} {
  if {[regexp {https?://([^/]+)} $url z domain]} {
    return $domain 
  } else {
    return "<none>" 
  }
}

# c:/aaa on windows, ~/aaa on linux
proc det_root_folder {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/" 
  } else {
    return "~/" 
  }
}
  
main $argv

