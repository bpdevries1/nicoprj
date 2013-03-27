#!/home/nico/bin/tclsh86

# combine databases from laptop and PC ubuntu. 
# kind of a one-off script.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set rootdir [file join ~ .backuptool]
  set destdb [file join $rootdir "all-backupinfo.db"]
  # for now: not anymore
  # file delete $destdb
  
  if {[file exists $destdb]} {
    log info "Destination file already exists, append it." 
  } else {
    file copy [file join $rootdir "backupinfo.db"] $destdb
  }
  set conn [open_db $destdb]  
  # connect_second $conn [file join $rootdir "laptop-backupinfo.db"]
  connect_second $conn [file join $rootdir "laptop-diskfree.db"]
  copy_tables $conn
  $conn close  
}

proc connect_second {conn dbname} {
  # ATTACH DATABASE 'laptop-backupinfo.db' AS db2
  db_eval $conn "ATTACH DATABASE '[file normalize $dbname]' AS db2" 
}

# @todo: if size_check has more than row, stop and determine what to do.
# @todo: ook df-output meenemen.
proc copy_tables {conn} {
  # @todo alleen records selecteren die nog niet in doel-db staan.
  set res [db_query $conn "select * from db2.size_check"]
  if {[llength $res] != 1} {
    error "Not precisely one row in db2.size_check: $res" 
  }
  set size_check_id [db_eval $conn "insert into size_check (hostname, ts) select ss2.hostname, ss2.ts from db2.size_check ss2" 1]
  puts "size_check_id: $size_check_id" ; # dit is een ID, geen lijst, zoals had gekund met >1 inserted row.
  
  # in size_check_dir 'gelukkig' geen link naar parent-dir, dan hell om id's om te zetten.
  db_eval $conn "insert into size_check_dir (size_check_id, path, size_mb, last_mod) select $size_check_id, ss2.path, ss2.size_mb, ss2.last_mod from db2.size_check_dir ss2" 0
  db_eval $conn "insert into diskfree (size_check_id, filesystem, total_mb, used_mb, free_mb, mounted) select $size_check_id, df2.filesystem, df2.total_mb, df2.used_mb, df2.free_mb, df2.mounted from db2.diskfree df2" 0
  
  log info "tables copied"
}

main $argv

