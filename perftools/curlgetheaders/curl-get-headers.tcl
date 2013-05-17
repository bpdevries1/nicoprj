#!/usr/bin/env tclsh86

# curl-get-headers.tcl

# @todo add fields cachekey and akamaiserver and fill them.
# @todo parallel processing: fileevent, vwait, open "|curl xyz", queues, signals, generator (Tcl 8.6), clj pmap.
# @todo parallel advanced: max N per domain (instead max N total).

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {argv} {
  set wait_after 1000
  # set conn [open_db "~/aaa/akamai.db"]
  set root_folder [det_root_folder] ; # based on OS.
  set db_name [file join $root_folder "aaa/akamai.db"]

  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  # @note 6-5-2013 NdV even curlgetheader2, want loopt thuis ook nog, weer mergen morgen.
  set table_def [make_table_def curlgetheader2 ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage]
  #set src_table_defs [list [dict create table embedded field url] \
  #                         [dict create table embedded field embed]]
  set src_table_defs [list [dict create table firebug field url] \
                           [dict create table firebug field embedded_url]]

  set ts_start [det_now]
  set ts_treshold [det_ts_treshold $ts_start 3600]
  set drop_table 0
                           
  lassign $argv settingsfile
  if {$settingsfile != ""} {
    log info "Source settings from $settingsfile"
    source $settingsfile
  } else {
    log warn "No settings file: using defaults" 
  }

  log info "Opening database: $db_name"
  set conn [open_db $db_name]
  create_table $conn $table_def $drop_table ; # 1: first drop the table.
                           
  # lookup_entries $conn $table_def "firebug" $wait_after
  lookup_entries $conn $table_def $src_table_defs $wait_after $ts_start $ts_treshold
}

proc lookup_entries {conn table_def src_table_defs wait_after ts_start ts_treshold} {
  foreach src_table_def $src_table_defs {
    lookup_entries_src $conn $table_def $src_table_def $wait_after $ts_start $ts_treshold
  }
}

proc lookup_entries_src {conn table_def src_table_def wait_after ts_start ts_treshold} {
  set res 1
  set totalcount 0
  # set ts_start [det_now]
  set total_todo [det_total_todo $conn $src_table_def $table_def $ts_treshold]
  log info "Total to do for $src_table_def: $total_todo"
  while {$res > 0} {
    # set res [lookup_entries_iter $conn $table_def $src_table_name $wait_after $ts_start $totalcount]
    set res [lookup_entries_iter $conn $table_def $src_table_def $wait_after $ts_start $totalcount $total_todo $ts_treshold]
    incr totalcount $res
    log info "Items handled for $src_table_def: $totalcount"
    # exit
  }
}

proc det_total_todo {conn src_table_def table_def ts_treshold} {
  if {[llength [dict keys $src_table_def where]] == 1} {
    lassign [dict_get_multi $src_table_def table field where] src_table_name src_field where
  } else {
    lassign [dict_get_multi $src_table_def table field] src_table_name src_field
    set where ""
  }
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

proc lookup_entries_iter {conn table_def src_table_def wait_after ts_start totalcount total_todo ts_treshold} {
  # decision: don't use explicit transaction, so every insert will be committed at once.
  set max_rows 100
  # set max_rows 2

  if {[llength [dict keys $src_table_def where]] == 1} {
    lassign [dict_get_multi $src_table_def table field where] src_table_name src_field where
  } else {
    lassign [dict_get_multi $src_table_def table field] src_table_name src_field
    set where ""
  }
  if {$where == ""} {
    set where_clause "1=1" 
  } else {
    set where_clause $where
  }
  dict_to_vars $table_def
             
  # lassign [dict_get_multi $src_table_def table field] src_table_name src_field
  
  log info "Lookup max $max_rows entries (nslookup) for $src_table_name.$src_field"
  dict_to_vars $table_def
  # set stmt_insert [prepare_insert $conn curlgetheader ts fieldvalue param exitcode resulttext msec cacheheaders]
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  # set ts_treshold [det_ts_treshold $ts_start 600]
             
  set query "select distinct t.$src_field 
             from $src_table_name t 
             where $where_clause
             and not exists (
               select 1
               from $table c
               where c.fieldvalue = t.$src_field
               and c.ts_start >= '$ts_treshold'
             )
             limit $max_rows"
  log info "Query: $query"             
  set i 0
  foreach dct [db_query $conn $query] {
    incr i
    # set fieldvalue [dict get $dct embedded_url]
    set fieldvalue [dict get $dct $src_field]
    set ts [det_now]
    set param $fieldvalue
    # return dict with exitcode and resulttext
    set akamai_env "prod"
    if {$akamai_env == "origin"} {
      set max_iter 1
    } else {
      set max_iter 2
    }
    for {set iter 0} {$iter < $max_iter} {incr iter} {
      set dct_res [do_curlget $akamai_env $param]
      dict_to_vars $dct_res
      set cacheheaders [det_cache_headers $resulttext]
      # cacheable expires expiry cachetype maxage
      foreach varname {cacheable expires expiry cachetype maxage} {
        set $varname [det_$varname $resulttext] 
      }
      set dct_insert [vars_to_dict ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage]
      stmt_exec $conn $stmt_insert $dct_insert
      set ndone [expr $totalcount + $i]
      log info "iter=$i, total so far=$ndone/$total_todo, [format %.2f [expr 100.0 * $ndone / $total_todo]]% done"
      log info "ETA: [det_eta $ts_start $ndone $total_todo]"
      log info "wait msec: $wait_after"
      after $wait_after
    }
  }
  return $i
}

# @param ts_start sqlite formatted
proc det_eta {ts_start ndone total_todo} {
  set sec_start [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"]
  set npersec [expr 1.0 * $ndone / ([clock seconds] - $sec_start)]
  set sec_end [expr round($sec_start + ($total_todo / $npersec))]
  clock format $sec_end -format "%Y-%m-%d %H:%M:%S"
}

# determine treshold time based on starttime and offset.
# example: ts_start = 12:00, sec_offset = 600.
# idea is to re-curl everything that was last done before 11:50.
proc det_ts_treshold {ts_start sec_offset} {
  set sec [expr [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"] - $sec_offset]
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

# @param akamai_type: prod, staging, origin
proc do_curlget {akamai_env url} {
  set resulttext ""
  set exitcode -1
  log info "exec curlget $url"
  set msec_start [clock milliseconds]
  try {
    # curl -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -i -L --connect-timeout 20 --max-time 30 http://www.philips.nl
    # bij hieronder melding dat quote-html niet supported is
    # set resulttext [exec -ignorestderr curl -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "\"$url\""]
    
    set resulttext [exec -ignorestderr curl -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
    #if {$akamai_env != "origin"} {
    #  # curl again, as cache is filled by previous call
    #  set resulttext [exec -ignorestderr curl -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
    #}
    set exitcode 0
  } trap CHILDSTATUS {results options} {
    set exitcode [lindex [dict get $options -errorcode] 2]
  }
  set msec_end [clock milliseconds]
  set msec [expr $msec_end - $msec_start]
  log info "result (exitcode=$exitcode): $resulttext"
  dict create exitcode $exitcode resulttext $resulttext msec $msec
}

proc det_cache_headers {resulttext} {
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

proc det_header_field {resulttext fieldname} {
  set re "$fieldname: (\[^\\n\]+)"
  if {[regexp $re $resulttext z value]} {
    return $value 
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

