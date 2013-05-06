#!/usr/bin/env tclsh86

# read-webcheck-log.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "read-webcheck-log.log"

proc main {argv} {
  set conn [open_db "~/aaa/akamai/webcheck.db"]
  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  set table_def [make_table_def webcheck url name value linenr]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  read_log $conn $table_def "~/aaa/akamai/webcheck.dat.20130503b"
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
  set expected_lines 22452816
  while {![eof $f]} {
    gets $f line
    incr linenr
    incr i_trans
    if {$i_trans >= 10000} {
      db_eval $conn "commit"
      db_eval $conn "begin transaction"
      set i_trans 0
      log info "Handled #lines: $linenr ([format %2.2f [expr 100.0 * $linenr / $expected_lines]]%)"
    }
    if {[regexp {^\[(.+)\]$} $line z u]} {
      set url $u 
    } elseif {[regexp {^(.+) = (.+)$} $line z name value]} {
      if {($name == "anchor") || ($name == "pageproblem")} {
        continue 
      }
      if {[regexp {^\42(.+)\42$} $value z v]} {
        set value $v 
      }
      if {($name == "child") || ($name == "embed")} {
        set value [htmlparse::mapEscapes $value] 
      }

      set dct_insert [vars_to_dict url name value linenr]
      stmt_exec $conn $stmt_insert $dct_insert
    } else {
      # nothing 
    }
  }
  close $f
  db_eval $conn "commit"
}

main $argv

