#!/usr/bin/env tclsh86

# read-xenu-export.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "read-xenu-export.log"

proc main {argv} {
  set conn [open_db "~/aaa/akamai.db"]
  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  set table_def [make_table_def xenu url_orig url domain inscope linenr]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  read_log $conn $table_def "~/aaa/akamai/xenu-export-all.txt"
  db_eval $conn "create index ix_xenu on xenu (url)"
}

proc read_log {conn table_def logname} {
  log info "read_log: $logname"
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  
  set f [open $logname r]
  set linenr 0
  set i_trans 0
  db_eval $conn "begin transaction"
  set url "<none>"
  set expected_lines 615392
  gets $f line ; # header
  incr linenr
  set ts_start [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  while {![eof $f]} {
    gets $f line
    incr linenr
    incr i_trans
    if {$i_trans >= 10000} {
      db_eval $conn "commit"
      db_eval $conn "begin transaction"
      set i_trans 0
      log info "Handled #lines: $linenr ([format %2.2f [expr 100.0 * $linenr / $expected_lines]]%)"
      log info "ETA: [det_eta $ts_start $linenr $expected_lines]"
    }
    lassign [split $line "\t"] url_orig
    set url [det_url $url_orig]
    set domain [det_domain $url]
    set inscope ""
    set dct_insert [vars_to_dict url_orig url domain inscope linenr]
    stmt_exec $conn $stmt_insert $dct_insert
  }
  close $f
  db_eval $conn "commit"
}

# remove jsession_id things and possibly other cookies
proc det_url {url_orig} {
  # rd/nl/;jsessionid=C897969DA51BB403B3982D08F359E11C.app102-drp2?t=specifi
  # => rd/nl/?t=specifi
  regsub {;jsessionid=[^?]+} $url_orig "" url
  return $url
}

proc det_domain {url} {
  if {[regexp {://([^/]+)} $url z domain]} {
    return $domain 
  } else {
    return $url 
  }
}

# @param ts_start sqlite formatted
proc det_eta {ts_start ndone total_todo} {
  set sec_start [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"]
  set npersec [expr 1.0 * $ndone / ([clock seconds] - $sec_start)]
  set sec_end [expr round($sec_start + ($total_todo / $npersec))]
  clock format $sec_end -format "%Y-%m-%d %H:%M:%S"
}

main $argv

