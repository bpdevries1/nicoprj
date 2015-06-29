#!/usr/bin/env tclsh861

package require ndv
package require tdbc::sqlite3

proc main {argv} {
  lassign $argv logdir
  puts "logdir: $logdir"
  set dbname [file join $logdir "vuserlog.db"]
  set db [get_results_db $dbname]
  foreach logfile [glob -directory $logdir *.log] {
    readlogfile $logfile $db
  }
}

proc readlogfile {logfilepath db} {
  puts "Reading: $logfilepath"
  # set ts_cet [clock format [file mtime $logfilepath] -format "%Y-%m-%d %H:%M:%S"]
  set logfile [file tail $logfilepath]
  set vuserid [det_vuserid $logfile]
  set fi [open $logfilepath r]
  $db in_trans {
	  while {![eof $fi]} {
      gets $fi line
      if {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] RetrieveAccounts - user: (\d+), naccts: (\d+), resptime: ([0-9.,]+)} $line z ts_cet sec_cet user naccts resptime]} {
        regsub -all {,} $resptime "." resptime
        $db insert retraccts [vars_to_dict logfile vuserid ts_cet sec_cet user naccts resptime]
      } elseif {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] trans: ([^ ]+) - user: (\d+), resptime: ([0-9.,]+)} $line z ts_cet sec_cet transname user resptime]} {
        regsub -all {,} $resptime "." resptime
        $db insert trans [vars_to_dict logfile vuserid ts_cet sec_cet transname user resptime]
      } elseif {[regexp {RetrieveAccounts} $line]} {
        breakpoint
      }
    }
  }
  close $fi
}

proc det_vuserid {logfile} {
  if {[regexp {_(\d+).log} $logfile z vuser]} {
    return $vuser
  } else {
    fail "Could not determine vuser from logfile: $logfile"
  }
}

proc get_results_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

if 0 {
functions.c(278): [2015-06-15 10:28:06] [1434356886] trans: CBW_01_Log_in_page - user: 3002161992, resptime: 1,055	[MsgId: MMSG-17999]
functions.c(278): [2015-06-15 10:28:14] [1434356894] trans: CBW_02A_CRAS_log_in_OK - user: 3002161992, resptime: 3,183	[MsgId: MMSG-17999]
functions.c(278): [2015-06-15 10:28:22] [1434356902] trans: CBW_03_Sprocket - user: 3002161992, resptime: 1,821	[MsgId: MMSG-17999]

}

proc define_tables {db} {
  $db add_tabledef retraccts {id} {logfile {vuserid int} ts_cet {sec_cet int} user {naccts int} {resptime real}}
  # 17-6-2015 NdV transaction is a reserved word in SQLite, so use trans as table name
  $db add_tabledef trans {id} {logfile {vuserid int} ts_cet {sec_cet int} transname user {resptime real}}
}

main $argv
