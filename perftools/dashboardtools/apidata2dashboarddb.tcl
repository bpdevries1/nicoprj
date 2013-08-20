#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {dir.arg "c:/projecten/Philips/Dashboards" "Directory where target DB is (dashboards.db)"}
    {srcdir.arg "c:/projecten/Philips/KN-analysis" "Source dir with Keynote API databases (keynotelogs.db)"}
    {srcpattern.arg "MyPhilips*" "Pattern for subdirs in srcdir to use"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]   
  set dir [:dir $dargv]
  set db_name [file join $dir "dashboards.db"]
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  prepare_db $db $existing_db
  handle_srcdirroot $db [:srcdir $dargv] [:srcpattern $dargv]
  $db close
}

proc prepare_db {db existing_db} {
  $db add_tabledef logfile {id} {path date}
  # set source to keynote for data directly from there, as daily average from the keynote raw/API data.
  $db add_tabledef stat {id} {logfile_id source date scriptname country totalpageavg respavail {value float}}
  # $db insert logfile_date [dict create logfile_id $logfile_id date $date]
  $db add_tabledef logfile_date {id} {logfile_id date}
  if {!$existing_db} {
    log info "Create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
  } else {
    log info "Existing DB, don't create tables"
    # existing db, assuming tables/indexes also already exist. 
  }
  $db prepare_insert_statements
}

proc create_indexes {db} {
  $db exec_try "create index ix_stat_1 on stat(logfile_id)"
} 

proc handle_srcdirroot {db srcdir srcpattern} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    handle_srcdir $db $subdir
  }
}

proc handle_srcdir {db dir} {
  set srcdbname [file join $dir "keynotelogs.db"]
  
  # first update task_succeed field
  set srcdb [dbwrapper new $srcdbname]
  $srcdb exec "update scriptrun
                set task_succeed = 0
                where task_succeed = '<none>'
                and id in (
                  select scriptrun_id
                  from page p
                  where p.error_code <> ''
                )"
  $srcdb exec "update scriptrun
                set task_succeed = 1
                where task_succeed = '<none>'"
  $srcdb close

  # then 'copy' data from srcdb to targetdb
  lassign [det_script_country_npages $dir] script country npages
  $db exec "attach database '$srcdbname' as fromDB"
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value)
            select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'avail', 1.0 * sum(task_succeed)/(count(*)) avail
            from fromDB.scriptrun r
            group by 2"
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value)
            select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'resp', 0.001 * avg(r.delta_msec)/$npages resp
            from fromDB.scriptrun r
            where task_succeed = 1
            group by 2"
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value)
            select 'APIuser', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'resp', 0.001 * avg(r.delta_user_msec)/$npages resp
            from fromDB.scriptrun r
            where task_succeed = 1
            group by 2"
  $db exec "detach fromDB"
}

# @todo npages bepalen voor andere typen scripts.
proc det_script_country_npages {dir} {
  if {[regexp {^([^\-_]+)[\-_]([^\-_]+)$} [file tail $dir] z script country]} {
    list $script $country 3
  } else {
    error "Could not determine script and country from: $dir" 
  }
}

# old
proc is_read {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where path='$filename'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

main $argv

