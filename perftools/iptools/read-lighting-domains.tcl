#!/usr/bin/env tclsh86

# read-lighting-domains.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {argv} {
  set root_folder [det_root_folder] ; # based on OS.
  # 6-5-2013 NdV niet met 2 processen tegelijk op 1 database!
  set db_name [file join $root_folder "aaa/akamai.db"]
  log info "Opening database: $db_name"
  set conn [open_db $db_name]
  
  set src_db_name "~/Dropbox/Philips/akamai/lighting-domains/lighting-domains.db"
  set src_conn [open_db $src_db_name dbsrc]
  
  set table_def [make_table_def akamaidomains domain]
  create_table $conn $table_def 1 ; # 1: first drop the table.
  
  handle_src_db $src_conn $conn $table_def
}

proc handle_src_db {src_conn conn table_def} {
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  db_in_trans $conn {
    foreach src_table [db_tables $src_conn] {
      handle_src_table $src_conn $conn $table_def $src_table $stmt_insert 
    }
  }
}

proc handle_src_table {src_conn conn table_def src_table stmt_insert} {
  set query "select * from $src_table"
  foreach dct [db_query $src_conn $query] {
    dict for {key value} $dct {
      handle_src_cell $conn $stmt_insert $src_table $key $value       
    } 
  }
}

proc handle_src_cell {conn stmt_insert src_table key value} {
  # look in value: maybe a list of URL's, get domain from url and put in destination table
  if {[regexp {http} $value]} {
    # breakpoint
  }
  foreach {z domain} [regexp -inline -all {https?://([^ /?;\n]+)} $value] {
    stmt_exec $conn $stmt_insert [vars_to_dict domain]
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

# library function

proc open_db {db_name {db_cmd db}} {
  set conn [tdbc::sqlite3::connection create $db_cmd $db_name]
  return $conn
}

proc db_tables {conn} {
  set res {}
  foreach {t x} [$conn tables] {
    lappend res $t 
  }
  return $res
}

main $argv

