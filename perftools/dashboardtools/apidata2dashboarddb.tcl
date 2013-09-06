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
  file mkdir $dir
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
  
  # first update task_succeed field
  set srcdb [dbwrapper new $srcdbname]
  lassign [det_script_country_npages $dir $srcdb] script country npages
  if {$script == "<none>"} {
    log warn "Could not determine script and country from $dir, ignore this dir and continue"
    return
  }
  
  make_indexes $srcdb
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
                
  make_run_check $srcdb $dir                

  make_ip_locations $srcdb

  
  
  $srcdb close

  # then 'copy' data from srcdb to targetdb, ignore the last date, as it is probably not complete yet.
  $db exec "attach database '$srcdbname' as fromDB"
  $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value, nmeas)
            select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'avail', 1.0 * sum(task_succeed)/(count(*)) avail, count(*) nmeas
            from fromDB.scriptrun r
            where r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
            group by 2"
  # $db exec "insert into stat (source, date, scriptname, country, totalpageavg, respavail, value)
  #           select 'API', strftime('%Y-%m-%d', r.ts_cet) date, '$script', '$country', 'pageavg', 'resp', 0.001 * avg(r.delta_msec)/$npages resp
  #           from fromDB.scriptrun r
  #           where task_succeed = 1
  #           and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
  #           group by 2"
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

  $db exec "detach fromDB"
  
  log info "handle_srcdir finished: $dir"
}

proc make_indexes {db} {
  $db exec_try "create index ix_page_1 on page (scriptrun_id)"
  $db exec_try "create index ix_pageitem_1 on pageitem (scriptrun_id)"
  $db exec_try "create index ix_pageitem_2 on pageitem (page_id)"
}

# @todo make more generic when eg CN needs to be checked.
proc make_run_check {db srcdir} {
  if {[regexp -nocase {myphilips} $srcdir]} {
    make_run_check_myphilips $db
  } else {
    make_run_check_dealer_locator $db
  }
}

proc make_run_check_myphilips {db} {
  $db exec_try "drop table checkrun"
  $db exec "create table checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, has_home_jsp integer, has_error_code integer, has_prodreg integer)"
  $db exec "create index ix_checkrun_1 on checkrun (scriptrun_id)"
  # first insert all scriptruns
  $db exec "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, has_home_jsp, has_error_code, has_prodreg)
            select id, ts_cet, task_succeed, 0, 0, 0, 0
            from scriptrun"
  # then update each item: update where id in () seems the quickest.
  $db exec "update checkrun set has_home_jsp = 1 where scriptrun_id in (
              select distinct p.scriptrun_id
              from page p, pageitem i
              where p.id = i.page_id
              and 1*p.page_seq = 2
              and i.url like '%home.jsp%'
              and i.domain != 'philips.112.2o7.net'
            )"
  # error 4006 is not serious and happens quite a lot: Cannot set WinInet status callback for synchronous sessions. Support for Java Applets download measurements
  $db exec "update checkrun set has_error_code = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.domain != 'philips.112.2o7.net' 
              and i.error_code <> ''
              and i.error_code <> '4006'
            )"
  $db exec "update checkrun set has_prodreg = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%prodreg%'
              and i.domain like 'secure.philips%'
            )"
  $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_home_jsp = 1 and has_error_code = 0 and has_prodreg = 0"
}

# @todo find generic stuff between this proc and make_run_check_myphilips => put in generic proc
proc make_run_check_dealer_locator {db} {
  $db exec_try "drop table checkrun"
  $db exec "create table checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png integer, has_error_code integer)"
  $db exec "create index ix_checkrun_1 on checkrun (scriptrun_id)"
  # first insert all scriptruns
  $db exec "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png, has_error_code)
            select id, ts_cet, task_succeed, 0, 0, 0, 0, 0, 0
            from scriptrun"
  # then update each item: update where id in () seems the quickest.
  # check for the existence of the three jsp pages.
  
  $db exec "update checkrun set has_wrb_jsp = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%/wrb_retail_store_locator_results.jsp%'
            )"
  $db exec "update checkrun set has_results_jsp = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%/retail_store_locator_results.jsp%'
            )"
  $db exec "update checkrun set has_error_jsp = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%/retail_store_locator.jsp%'
            )"
  
  $db exec "update checkrun set has_a_png = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%/A.png%'
            )"
  # error 4006 is not serious and happens quite a lot: Cannot set WinInet status callback for synchronous sessions. Support for Java Applets download measurements
  # more domains are excluded, ip address is set to 0.0.0.0 or NA.
  # @todo check if runs do have an A.png, but also errors, and marked (real_succeed) as not successful.
  $db exec "update checkrun set has_error_code = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.domain != 'philips.112.2o7.net' 
              and i.error_code <> ''
              and i.error_code <> '4006'
              and i.ip_address != '0.0.0.0'
              and i.ip_address != 'NA'
            )"
  # $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_a_png = 1 and has_error_code = 0"
  # 28-8-2013 for now, just check for existence of A.png, don't look at other errors, that may or may not be blocking/real errors.
  # 28-8-2013 the existence of A.png should correlate 100% with the existence of /retail_store_locator_results.jsp and 0% with retail_store_locator.jsp.
  # @todo do some manual checks for this.
  $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_a_png = 1"
}

proc make_ip_locations {db} {
  # ipad: IP Addresses
  $db exec_try "create table ipad as
                select count(*) number, domain, ip_address
                from pageitem
                group by 2,3
                order by 2,3" 
}

# @todo npages bepalen voor andere typen scripts. Mss kan die voor Dealer locator wel generiek gebruikt worden.
# @todo check if npages is fixed for a script: are there successful runs with a different number of pages?
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

# old
proc is_read_old {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where path='$filename'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

main $argv

