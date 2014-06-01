#!/usr/bin/env tclsh

# read-nagios-data.tcl

package require ndv
package require tdbc::sqlite3
package require Tclx

source configdata-db.tcl

proc main {argv} {
  global argv0
  if {[:# $argv] != 1} {
    puts "syntax: $argv0 <dir-with-db-from-excel>"
    exit 1
  }
  lassign $argv fromdir
  set db [get_config_db]
  lassign [det_from_db_table $fromdir] fromdbpath table columns
  # breakpoint
  $db exec2 "attach database '$fromdbpath' as excel"
  # @todo check of veld bestaat in bron/hoofd tabel, anders toevoegen
  foreach col $columns {
    puts "Update field: $col"
    $db exec2 "update mediq_machine
                set $col = (
                  select $col
                  from excel.$table o
                  where o.id = mediq_machine.id
                )
                where id in (
                  select id
                  from excel.$table o
                  where o.$col is not null
                )"
  }
  $db exec2 "detach database excel"
  $db close
}

# return list: fromdbpath table columns
proc det_from_db_table {fromdir} {
  puts "Finding db and table in: $fromdir"
  set paths [glob -directory $fromdir *.db]
  if {[:# $paths] != 1} {
    error "Not exactly one .db file in $fromdir: $paths"
  }
  set dbpath [:0 $paths]
  set dbo [dbwrapper new $dbpath]
  set conn [$dbo get_conn]
  set tables [dict keys [$conn tables "%mediq_machines%mediq_machines%"]]
  # set tables [listc {$t} t <- $tables {[regexp -nocase {mediq_machines} $t]}]
  if {[:# $tables] != 1} {
    breakpoint
    error "Not exactly one source table in db: $tables"
  }
  set table [:0 $tables]
  set cols [dict keys [$conn columns $table]]
  # breakpoint
  # quoting hell:
  set columns [listc {$el} el <- $cols {\"$el\" != "\"id\""}]
  $dbo close
  return [list $dbpath $table $columns]
}

main $argv
