#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require generator
package require ndv

generator define gen_urls {conn src_table_def dest_table_def max_rows ts_treshold} {
  lassign [dict_get_multi $src_table_def table field where] src_table_name src_field where
  lassign [dict_get_multi $dest_table_def table] dest_table
  if {$where == ""} {
    set where_clause "1=1" 
  } else {
    set where_clause $where
  }
  set query "select distinct t.$src_field 
             from $src_table_name t 
             where $where_clause
             and not exists (
               select 1
               from $dest_table c
               where c.fieldvalue = t.$src_field
               and c.ts_start >= '$ts_treshold'
             )
             limit $max_rows"
  log info "Query: $query"             
  set have_results 1
  while {$have_results} {
    log debug "next query loop: $query"
    set i 0
    foreach dct [db_query $conn $query] {
      incr i
      generator yield [dict get $dct $src_field]
    }
    if {$i == 0} {
      set have_results 0 
    }
  }
}

proc test_generator {argv} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    set root_folder "c:/" 
  } else {
    set root_folder "~/" 
  }
  
  set db_name [file join $root_folder "aaa/akamai-parallel.db"]
  
  set conn [open_db $db_name]
  set src_table_def [dict create table "xenu" field "url" where "inscope='yes'"]
  set dest_table_def [make_table_def curlgetheader ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage]
  set max_rows 10
  set gen [gen_urls $conn $src_table_def $dest_table_def $max_rows "2013-05-17 12:00:00"]
  generator next $gen url1
  puts "url1: $url1"
  set i 1
  generator foreach url $gen {
    incr i
    puts "url: $url"
    if {$i == [expr $max_rows + 1]} {
      if {$url1 == $url} {
        puts "Ok, url11=url1" 
      } else {
        puts "Nok, urls differ." 
      }
      break 
    }
  }
}

# comment out when tested.
# test_generator $argv


