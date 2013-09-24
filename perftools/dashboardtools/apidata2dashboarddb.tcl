#!/usr/bin/env tclsh86

# @note NOT use libpostproclogs.tcl library, separate scripts now.
# @note this one just copies/aggregates the already post-processed origin data
#       to a single DB.

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
    {srcpattern.arg "*" "Pattern for subdirs in srcdir to use"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set dir [from_cygwin [:dir $dargv]]
  file mkdir $dir
  set db_name [file join $dir "dashboards.db"]
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  prepare_db $db $existing_db
  handle_srcdirroot $db [from_cygwin [:srcdir $dargv]] [:srcpattern $dargv]
  $db close
  log info "Finished updating: $db_name"
}

proc prepare_db {db existing_db} {
  $db add_tabledef logfile {id} {path date}
  # set source to keynote for data directly from there, as daily average from the keynote raw/API data.
  $db add_tabledef stat {id} {logfile_id source date scriptname country totalpageavg respavail {value float} {nmeas integer}}
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
  $db exec "delete from stat where source in ('API', 'APIuser', 'check')"
}

proc create_indexes {db} {
  $db exec_try "create index ix_stat_1 on stat(logfile_id)"
} 

proc handle_srcdirroot {db srcdir srcpattern} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    handle_srcdir $db $subdir
    # exit ; # for test
  }
}

proc handle_srcdir {db dir} {
  log info "handle_srcdir: $dir"
  set srcdbname [file join $dir "keynotelogs.db"]
  
  set srcdb [dbwrapper new $srcdbname]
  lassign [det_script_country_npages $dir $srcdb] script country npages
  if {$script == "<none>"} {
    log warn "Could not determine script and country from $dir, ignore this dir and continue"
    return
  }
  set checkrun_fields [det_checkrun_fields $srcdb]
  $srcdb close

  $db exec "attach database '$srcdbname' as fromDB"

  fill_checkrun_counts $db $script $checkrun_fields
  log start_stop fill_error_status_counts $db $script
  log start_stop fill_error404_status_counts $db $script
  fill_stat_from_src $db $dir $srcdbname $script $country $npages
  
  $db exec "detach fromDB"
  
  log info "handle_srcdir finished: $dir"
}

proc fill_stat_from_src {db dir srcdbname script country npages} {
  
  # 'copy' data from srcdb to targetdb, ignore the last date, as it is probably not complete yet.
  
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value, nmeas)
            select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'avail', 1.0 * sum(task_succeed)/(count(*)) avail, count(*) nmeas
            from fromDB.scriptrun r
            where r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
            group by 2"

  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value, nmeas)
            select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'resp', 0.001 * avg(r.delta_user_msec)/$npages resp, count(*) nmeas
            from fromDB.scriptrun r
            where task_succeed = 1
            and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
            group by 2"
  
  # Include data from checkrun table
  log info "Inserting data from checkrun table, country=$country"
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value, nmeas)
            select 'check', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'avail', 1.0 * sum(c.real_succeed)/(count(*)) avail, count(*) nmeas
            from fromDB.scriptrun r, fromDB.checkrun c
            where r.id = c.scriptrun_id
            and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
            group by 2"
  # now just delta_user_msec, delta_msec not useful.
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value, nmeas)
            select 'check', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'resp', 0.001 * avg(r.delta_user_msec)/$npages resp, count(*) nmeas
            from fromDB.scriptrun r, fromDB.checkrun c
            where r.id = c.scriptrun_id
            and c.real_succeed = 1
            and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
            group by 2"
  
}

proc det_checkrun_fields {srcdb} {
  [$srcdb get_conn] columns checkrun 
}

# copied from libfp.tcl, not included in ndv.tcl yet.
proc str {args} {
  join $args ""
}

# @todo should use filter here, but not yet easy to use in libfp, this is another testcase.
proc det_fields {checkrun_fields} {
  set res {}
  foreach field [dict keys $checkrun_fields] {
    if {[regexp {succeed$} $field]} {
      lappend res $field 
    } elseif {[regexp {^has_} $field]} {
      lappend res $field 
    }
  }
  return $res
}

proc fill_checkrun_counts {db script checkrun_fields} {
  # det if checkrun_count already exists. If not, get fieldnames from src, and make a table with more-or-less those fields. 
  set fields [det_fields $checkrun_fields]
  set field_defs [lmap el $fields {str $el " integer"}]
  if {[[$db get_conn] tables checkrun_count] == {}} {
    $db exec "create table checkrun_count (runcount, scriptname, [join $field_defs ", "])" 
  }
  $db exec "delete from checkrun_count where scriptname = '$script'"
  set query "insert into checkrun_count
             select count(*), '$script', [join $fields ", "]
             from fromDB.checkrun
             group by [join [range 2 [expr [llength $fields] + 3]] ", "]" 
  # log debug $query
  $db exec $query
  # breakpoint
}

proc fill_error_status_counts {db script} {
  set fields {topdomain error_code status_code}
  set i_fields [lmap el $fields {str "i.$el"}]
  set tablename "error_status_count"
  create_count_table $db $tablename $fields ; # no integer fields here, so fields=field_defs
  $db exec "delete from $tablename where scriptname = '$script'"
  set query "insert into $tablename
             select count(*), min(r.ts_cet), max(r.ts_cet), '$script', [join $i_fields ", "]
             from fromDB.pageitem i join scriptrun r on r.id = i.scriptrun_id
             group by [join [range 4 [expr [llength $fields] + 5]] ", "]" 
  # log debug $query
  $db exec $query
}

# @todo tabel die 404 (en andere?) results opslaat. Ook eerste en laatste datum dat het voorkomt.
# met urlnoparams hier.
proc fill_error404_status_counts {db script} {
  set fields {topdomain urlnoparams error_code status_code}
  set i_fields [lmap el $fields {str "i.$el"}]
  set tablename "error404_status_count"
  create_count_table $db $tablename $fields ; # no integer fields here, so fields=field_defs
  $db exec "delete from $tablename where scriptname = '$script'"
  set query "insert into $tablename
             select count(*), min(r.ts_cet), max(r.ts_cet), '$script', [join $i_fields ", "]
             from fromDB.pageitem i join scriptrun r on r.id = i.scriptrun_id
             where i.error_code = '404'
             group by [join [range 4 [expr [llength $fields] + 5]] ", "]" 
  # log debug $query
  $db exec $query
}


proc create_count_table {db tablename field_defs} {
  if {[[$db get_conn] tables $tablename] == {}} {
    $db exec "create table $tablename (statcount integer, first_ts, last_ts, scriptname, [join $field_defs ", "])" 
  }
}

proc make_indexes_old {db} {
  $db exec_try "create index ix_page_1 on page (scriptrun_id)"
  $db exec_try "create index ix_pageitem_1 on pageitem (scriptrun_id)"
  $db exec_try "create index ix_pageitem_2 on pageitem (page_id)"
}

proc make_ip_locations_old {db} {
  # ipad: IP Addresses
  $db exec_try "create table ipad as
                select count(*) number, domain, ip_address
                from pageitem
                group by 2,3
                order by 2,3" 
}

# @todo npages bepalen voor andere typen scripts. Mss kan die voor Dealer locator wel generiek gebruikt worden.
# @todo check if npages is fixed for a script: are there successful runs with a different number of pages? Cause may be a changed script.
proc det_script_country_npages {dir db} {
  if {[regexp -nocase {myphilips} $dir]} {
    if {[regexp {^([^\-_]+)[\-_]([^\-_]+)$} [file tail $dir] z script country]} {
      return [list $script $country 3]
    } else {
      # error "Could not determine script and country from: $dir"
      return "<none>"
    }
  } else {
    # just dealer locator for now.
    if {[regexp {^CBF-([^-]+)-(.+)$} [file tail $dir] z country script]} {
      set res [$db query "select max(1*page_seq) npages from page"]
      set npages [:npages [lindex $res 0]]
      log info "#pages for [file tail $dir]: $npages"
      return [list $script $country $npages]
    }
  }
}

#######################
# libfp functions
#######################

# lib function, could also use struct::list repeat
proc repeat {n x} {
  set res {}
  for {set i 0} {$i < $n} {incr i} {
    lappend res $x 
  }
  return $res
}

# Returns a list of nums from start (inclusive) to end
# (exclusive), by step, where step defaults to 1
# also copied from clojure def.
proc range {start end {step 1}} {
  set res {}
  for {set i $start} {$i < $end} {incr i $step} {
    lappend res $i 
  }
  return $res
}

main $argv

