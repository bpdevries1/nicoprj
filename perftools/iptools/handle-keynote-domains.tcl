#!/usr/bin/env tclsh86

# handle-keynote-domains.tcl
# convert ppt/excel in sqlite db info to seperate fields.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

source lib-iptools.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# $log set_file "read-xenu-export.log"

proc main {argv} {
  #set root_folder [det_root_folder] ; # based on OS.
  #set db_name [file join $root_folder "aaa/akamai.db"]
  set db_name "~/Dropbox/Philips/akamai/philips-domains/philips-domains.db"
  set conn [open_db $db_name]
  set table_def [make_table_def keynote flow page domain protocol stagingip]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  # read_html $conn $table_def "~/aaa/Luna Control Center.html"
  # db_eval $conn "create index ix_xenurep on xenurep (url)"
  handle_table $conn $table_def
}

proc handle_table {conn table_def} {
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  db_eval $conn "begin transaction"
  foreach dct [db_query $conn "select * from akamai_staging_keynote_Sheet1"] {
    # Flow, Page, Domain, field4
    dict_to_vars $dct
    set flow $Flow
    set page $Page
    set Domain [string trim $Domain]
    if {[regexp {([a-z]+)://(.+)$} $Domain z protocol val]} {
      # just domain, or (<ip>) or <ip>
      if {[regexp {^([^ ]+) (.*)$} $val z domain val2]} {
        if {[regexp {([0-9.]+)} $val2 z ip]} {
          set stagingip $ip 
        } else {
          log warn "Space, but no staging ip"
          breakpoint
        }
      } else {
        set domain $val
        set stagingip ""
      }
      set dct_insert [vars_to_dict flow page domain protocol stagingip]
      stmt_exec $conn $stmt_insert $dct_insert
      
    } else {
      log warn "No protocol"
      breakpoint 
    }
  }
  db_eval $conn "commit"
}

main $argv

