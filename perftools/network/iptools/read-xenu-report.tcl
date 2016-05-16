#!/usr/bin/env tclsh86

# read-xenu-report.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "read-xenu-export.log"

proc main {argv} {
  set conn [open_db "~/aaa/akamai/xenureport2.db"]
  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  set table_def [make_table_def xenurep url link errorcode linenr status]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  read_log $conn $table_def "~/aaa/akamai/TGH7EB1.htm"
  db_eval $conn "create index ix_xenurep on xenurep (url)"
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
  set expected_lines 1391407
  gets $f line ; # header
  incr linenr
  set ts_start [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set url "<none>"
  set link "<none>"
  while {![eof $f]} {
    gets $f line
    incr linenr
    
    if {0} {
<pre><a href="http://nl.youtube.com/watch?v=SAm16eOJ0gA" TARGET=_blank>http://nl.youtube.com/watch?v=SAm16eOJ0gA</a>
        <a href="http://www.youtube.com/watch?v=SAm16eOJ0gA&gl=NL&hl=nl" TARGET=_blank>http://www.youtube.com/watch?v=SAm16eOJ0gA&gl=NL&hl=nl</a>
          \_____ error code: 404 (not found)

<a href="http://www.philips.nl/c/" TARGET=_blank>http://www.philips.nl/c/</a>
        <a href="https://secure.philips.nl/myphilips/landing.jsp?language=nl&country=NL&catalogType=CONSUMER" TARGET=_blank>https://secure.philips.nl/myphilips/landing.jsp?language=nl&country=NL&catalogType=CONSUMER</a>
          \_____ error code: 503 (temporarily overloaded)
        <a href="http://www.philips.nl/c/catalog/catalog_selector.jsp?country=NL&catalogType=CONSUMER&language=nl" TARGET=_blank>http://www.philips.nl/c/catalog/catalog_selector.jsp?country=NL&catalogType=CONSUMER&language=nl</a>
          \_____ error code: 500 (server error)
    }
    if {[regexp {^(<pre>)?<a href=\42([^\42]+)} $line z z u]} {
      set url [det_url $u] 
    } elseif {[regexp {^[ \t]+<a href=\42([^\42]+)} $line z l]} {
      set link [det_url $l]
    } elseif {[regexp {empty URL} $line]} {
      set link "empty URL"
    } elseif {[regexp {a href} $line]} {
      # breakpoint
    } elseif {[regexp {_____ (.+)$} $line z errorcode]} { 
      set status ""
      if {($url == "<none>") || ($link == "<none>")} {
        breakpoint 
      }
      set dct_insert [vars_to_dict url link errorcode linenr status]
      stmt_exec $conn $stmt_insert $dct_insert
      set link "<none>"
      incr i_trans
      if {$i_trans >= 10000} {
        db_eval $conn "commit"
        db_eval $conn "begin transaction"
        set i_trans 0
        log info "Handled #lines: $linenr ([format %2.2f [expr 100.0 * $linenr / $expected_lines]]%)"
        log info "ETA: [det_eta $ts_start $linenr $expected_lines]"
      }
    }
    
  }
  close $f
  db_eval $conn "commit"
}

proc det_url {url_orig} {
  # rd/nl/;jsessionid=C897969DA51BB403B3982D08F359E11C.app102-drp2?t=specifi
  # => rd/nl/?t=specifi
  regsub {;jsessionid=[^?]+} $url_orig "" url
  return $url
}

# @param ts_start sqlite formatted
proc det_eta {ts_start ndone total_todo} {
  set sec_start [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"]
  set npersec [expr 1.0 * $ndone / ([clock seconds] - $sec_start)]
  set sec_end [expr round($sec_start + ($total_todo / $npersec))]
  clock format $sec_end -format "%Y-%m-%d %H:%M:%S"
}

main $argv

