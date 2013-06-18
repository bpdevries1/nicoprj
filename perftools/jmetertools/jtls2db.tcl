#!/usr/bin/env tclsh86

# jtls2db.tcl - convert jtl's (csv) to a sqlite3 db, add fields: id, filename, ts_fmt, sec_delta, TTL (from akamai cachekey)

# @todo nieuwe run bevat akserver_remote en cachetype_remote, oude dus niet, dus flexibel inrichten.

package require tdbc::sqlite3
package require Tclx
package require ndv

proc main {argv} {
  lassign $argv jtl_dir
  if {0} {
    set db_dir [copy_jtl_to_db_dir $jtl_dir]
    call_excel2db $db_dir
  } else {
    set db_dir [file join $jtl_dir jtldb] 
  }
  merge_tables $db_dir  
}

proc copy_jtl_to_db_dir {jtl_dir} {
  set db_dir [file join $jtl_dir jtldb]
  file mkdir $db_dir
  foreach filename [glob -nocomplain -directory $db_dir *] {
    file delete $filename 
  }
  foreach filename [glob -directory $jtl_dir "*.jtl" -type f] {
    if {[regexp {latest} $filename]} {
      continue 
    }
    set target_name [file join $db_dir "[file tail [file rootname $filename]].csv"]
    log info "Copying file: $filename"
    file copy $filename $target_name
  }
  return $db_dir
}

# @pre symlink with excel2db.tcl exists in current (jmetertools) dir.
proc call_excel2db {db_dir} {
  # @todo? evt deze sources, dan main aanroepen.
  exec -ignorestderr ./excel2db.tcl $db_dir
}

proc merge_tables {db_dir} {
  set conn [open_db [find_db $db_dir]]
  # breakpoint
  set tables [det_tables $conn]
  set fields [det_fields $conn [lindex $tables 0]]
  set target_table reqs
  # set tabledef [make_table_def $target_table {*}[concat {id} $fields {origtable ts_fmt sec_delta ttl}]]
  set tabledef [make_table_def_keys $target_table {id} [concat $fields {origtable ts_utc sec_delta_req sec_delta_reqsrv ttl}]]
  # sec_delta_req: time since last same request, possible different akamai server; 
  # sec_delta_reqsrv: time since last same request handled by same akamai server.
  create_table $conn $tabledef 1
  # log info "check created table: $tabledef"
  
  [$conn getDBhandle] function det_ttl det_ttl
  
  foreach table $tables {
    insert_table $conn $table $target_table $fields
  }
  # @todo: sec_delta: met 1) query/subselect of 2) in tcl oplossen. Voorkeur voor (1).
  # breakpoint
  # set h [$conn getDBhandle]
  # $h function det_ttl det_ttl

  # db_eval $conn "update reqs set ttl = det_ttl(cachekey)"
  # X-Cache-Remote: TCP_MEM_HIT from a82-96-58-44.deploy.akamaitechnologies.com (AkamaiGHost/6.11.2.2-10593690) (-)
  fill_deltas $conn $target_table
}

proc find_db {db_dir} {  
  lindex [glob -directory $db_dir "*.db"] 0 
}

proc det_tables {conn} {
  lmap el [dict keys [$conn tables]] {expr {
    [regexp {^cache1d} $el] ? $el : [continue]  
  }}
}

proc det_fields {conn tablename} {
  dict keys [$conn columns $tablename] 
}

proc insert_table {conn table target_table fields} {
  set query "insert into $target_table (origtable, ts_utc, ttl, [join $fields ", "]) 
             select '$table', datetime(0.001 * timestamp, 'unixepoch'), det_ttl(cachekey), [join $fields ", "] from $table"
  log debug "query: $query"
  db_in_trans $conn {
    db_eval $conn $query
  }
}

proc det_ttl {cachekey} {
  # /L/1177/153890/1d/www.philips.nl/c/
  if {[regexp {^/[A-Z]+/\d+/\d+/([^/]+)/} $cachekey z ttl]} {
    return $ttl 
  } else {
    return "<unknown>"
  }
}

# timestamp in milliseconds.
# to fill: sec_delta_req sec_delta_reqsrv
# sec_delta_req: time since last same request, possible different akamai server; 
# sec_delta_reqsrv: time since last same request handled by same akamai server.
proc fill_deltas {conn target_table} {
  set query "update $target_table
             set sec_delta_req = 0.001 * (timestamp - (
               select max(t2.timestamp)
               from $target_table t2
               where t2.url = $target_table.url
               and t2.timestamp < $target_table.timestamp               
             ))"
  db_eval $conn $query

  set query "update $target_table
             set sec_delta_reqsrv = 0.001 * (timestamp - (
               select max(t2.timestamp)
               from $target_table t2
               where t2.url = $target_table.url
               and t2.akserver = $target_table.akserver
               and t2.timestamp < $target_table.timestamp               
             ))"
  db_eval $conn $query
}

main $argv

