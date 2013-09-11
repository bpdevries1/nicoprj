# #!/usr/bin/env tclsh86
# this is a lib, no bash (env) start needed.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# general proc also usable in apidata2dashboard.
# entry proc
proc post_proc_srcdir {dir max_urls} {
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
                
  make_run_check $srcdb $dir $max_urls                

  $srcdb close  
}

proc make_indexes {db} {
  $db exec_try "create index ix_page_1 on page (scriptrun_id)"
  $db exec_try "create index ix_pageitem_1 on pageitem (scriptrun_id)"
  $db exec_try "create index ix_pageitem_2 on pageitem (page_id)"
}

# @todo make more generic when eg CN needs to be checked.
proc make_run_check {db srcdir max_urls} {
  make_run_check_generic $db $srcdir $max_urls
  if {[regexp -nocase {myphilips} $srcdir]} {
    make_run_check_myphilips $db
  } else {
    make_run_check_dealer_locator $db
  }
}

proc make_run_check_generic {db srcdir max_urls} {
  # those queries used to be in R script graphs-myphilips.R
  $db exec "drop table if exists runcount"
  $db exec "create table runcount as
            select strftime('%Y-%m-%d', r.ts_cet) date, count(*) number
            from scriptrun r, checkrun c
            where r.id = c.scriptrun_id
            and c.real_succeed = 1
            group by 1"

  # first set all non-dynamic items, so no need to check/calc afterwards.                  
  $db exec "update pageitem
            set scontent_type = url
            where not (url like '%?%' or url like '%;%')
            and scontent_type is null"
  
  # min works ok, but instr returns 0 when not found, and then min would be 0 as well: not good.
  # so first check only ?, then only ;, then both
  $db exec "update pageitem
            set scontent_type = substr(url, 1, instr(url, '?'))
            where url like '%?%'
            and not url like '%;%'
            and scontent_type is null"

  $db exec "update pageitem
            set scontent_type = substr(url, 1, instr(url, ';'))
            where url like '%;%'
            and not url like '%?%'
            and scontent_type is null"

  # both, use min.
  $db exec "update pageitem
            set scontent_type = substr(url, 1, min(instr(url, ';'), instr(url, '?')))
            where url like '%;%'
            and url like '%?%'
            and scontent_type is null"

  # helpers to show top 20 URL's (page items)
  $db exec "drop table if exists maxitem"
  
  $db exec "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq, loadtime)"

  set last_week [det_last_week $db]
  # and r.ts_cet > '2013-08-26'
  $db exec "insert into maxitem (url, page_seq, loadtime)
            select i.scontent_type, p.page_seq, avg(0.001*i.element_delta) loadtime
            from scriptrun r, page p, pageitem i, checkrun c
            where c.scriptrun_id = r.id
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and c.real_succeed = 1
            and r.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls"
}

# want to calc top 20 items from last week data. But use last moment of measurements in the DB, not current time.
proc det_last_week {db} {
  set res [$db query "select date(max(r.ts_cet), '-7 days') lastweek from scriptrun r"]
  :lastweek [lindex $res 0]
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
  $db exec "create table checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, has_store_page, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png integer, has_error_code integer)"
  $db exec "create index ix_checkrun_1 on checkrun (scriptrun_id)"
  # first insert all scriptruns
  $db exec "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, has_store_page, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png, has_error_code)
            select id, ts_cet, task_succeed, 0, 0, 0, 0, 0, 0, 0
            from scriptrun"
  # then update each item: update where id in () seems the quickest.
  # check for the existence of the three jsp pages.
  # if there is something with retail_store_locator in this script, then do the check for A.png.
  $db exec "update checkrun set has_store_page = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%retail_store_locator%'
            )"
  
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
  # if this script has no retail store pages, then don't check for A.png.
  $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_store_page = 0"
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
    # 10-9-2013 this should also work for CN scripts, also start with CBF.
    if {[regexp {^CBF-([^-]+)-(.+)$} [file tail $dir] z country script]} {
      set res [$db query "select max(1*page_seq) npages from page"]
      set npages [:npages [lindex $res 0]]
      log info "#pages for [file tail $dir]: $npages"
      return [list $script $country $npages]
    }
  }
}


