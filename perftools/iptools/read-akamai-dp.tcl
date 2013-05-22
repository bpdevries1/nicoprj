#!/usr/bin/env tclsh86

# read-akamai-dp.tcl
# read digital properties from html saved from Luna.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

source lib-iptools.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "read-xenu-export.log"

proc main {argv} {
  set root_folder [det_root_folder] ; # based on OS.
  set db_name [file join $root_folder "aaa/akamai.db"]
  
  set conn [open_db $db_name]
  set table_def [make_table_def digprop ts linenr property configfile]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  read_html $conn $table_def "~/aaa/Luna Control Center.html"
  # db_eval $conn "create index ix_xenurep on xenurep (url)"
}

proc read_html {conn table_def htmlname} {
  log info "read_html: $htmlname"
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  set f [open $htmlname r]
  set linenr 0
  db_eval $conn "begin transaction"
  set property "<none>"
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  while {![eof $f]} {
    gets $f line
    incr linenr
    if {[regexp {title=.Host Header. alt=..>([^<]+)</a>} $line z p]} {
      set property $p 
    } elseif {[regexp {\.xml$} [string trim $line]]} {
      set configfile [string trim $line]
      set dct_insert [vars_to_dict ts linenr property configfile]
      stmt_exec $conn $stmt_insert $dct_insert
    }
  }
  close $f
  db_eval $conn "commit"
}

main $argv

