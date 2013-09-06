#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv
# package require csv
package require uri

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {db.arg "c:/projecten/Philips/KN-dealer/testcases.db" "Location of target DB"}
    {srcdir.arg "c:/projecten/Philips/KNDL" "Source dir with Keynote API databases (keynotelogs.db)"}
    {srcpattern.arg "*" "Pattern for subdirs in srcdir to use"}
    {dropdb "Delete target DB before loading"}
    {latlong "Do lat-long query (after copy-table)"}
    {fillparams "Just fill params (target DB already filled before)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  set dbname [:db $dargv]
  if {[:dropdb $dargv]} {
    file delete $dbname
  }
  file mkdir [file dirname $dbname] 
  set existing_db [file exists $dbname]
  set db [dbwrapper new $dbname]
  prepare_db $db $existing_db
  if {[:fillparams $dargv]} {
    fill_params $db
  } elseif {[:latlong $dargv]} {
    fill_lat_long $db
  } else {
    handle_srcdirroot $db [:srcdir $dargv] [:srcpattern $dargv]
    fill_params $db
  }
  $db close
}

proc prepare_db {db existing_db} {
  $db add_tabledef testcase {id} {scriptname {number integer} {min_msec float} {max_msec float} {avg_msec float} {min_bytes float} {max_bytes float} {avg_bytes float} url groupid country productid catalogtype citypostalcode language {latitude float} {longitude float} min_date max_date}
  # set source to keynote for data directly from there, as daily average from the keynote raw/API data.
  if {!$existing_db} {
    log info "Create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
  } else {
    log info "Existing DB, don't create tables"
    # existing db, assuming tables/indexes also already exist. 
  }
  #$db prepare_insert_statements
  #$db exec "delete from stat where source in ('API', 'APIuser', 'check')"
}

proc handle_srcdirroot {db srcdir srcpattern} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    handle_srcdir $db $subdir
  }
}

proc handle_srcdir {db dir} {
  log info "handle_srcdir: $dir"
  set srcdbname [file join $dir "keynotelogs.db"]
  
  # then 'copy' data from srcdb to targetdb, ignore the last date, as it is probably not complete yet.
  # lassign [det_script_country_npages $dir] script country npages
  set scriptname [file tail $dir]
  $db exec "attach database '$srcdbname' as fromDB"
  $db exec "insert into testcase (scriptname, number, min_msec, max_msec, avg_msec, min_bytes, max_bytes, avg_bytes, url, min_date, max_date)
            select '$scriptname', count(*), min(1*element_delta), max(1*element_delta), avg(1*element_delta), 
                    min(1*content_bytes), max(1*content_bytes), avg(1*content_bytes), url, min(r.ts_cet), max(ts_cet)
            from pageitem i, scriptrun r
            where i.scriptrun_id = r.id 
            and url like '%retail_store_locator%' 
            and domain not like '%google%'
            and domain not like '%eloqua.com'
            and domain <> 'philips.112.2o7.net'
            and domain <> 'cts-log.channelintelligence.com'
            and not domain like 'm.philips%'
            group by 1,9"

  # en hoe vaak komt A.png voor, deze alleen als het goed is, is A met rondje en pijltje. Om een indruk te krijgen, hierna ook echte grafieken, vgl MyPhilips (en mobile CN)              
  $db exec "insert into testcase (scriptname, number, min_msec, max_msec, avg_msec, min_bytes, max_bytes, avg_bytes, url, min_date, max_date)
            select '$scriptname', count(*), min(1*element_delta), max(1*element_delta), avg(1*element_delta), 
                    min(1*content_bytes), max(1*content_bytes), avg(1*content_bytes), url, min(r.ts_cet), max(ts_cet)
            from pageitem i, scriptrun r
            where i.scriptrun_id = r.id 
            and url like '%/A.png%'
            and domain not like '%google%'
            and domain not like '%eloqua.com'
            and domain <> 'philips.112.2o7.net'
            and domain <> 'cts-log.channelintelligence.com'
            and not domain like 'm.philips%'
            group by 1,9"            
            
  $db exec "detach fromDB"
  
  log info "handle_srcdir finished: $dir"
}

proc fill_params {db} {
  log info "Fill_params: start"
  $db in_trans {
    # set res [$db query "select id, url from testcase where url like '%/retail_store_locator_results.jsp%'"]
    # 4-9-2013 try to handle all, fill as many details as possible.
    set res [$db query "select id, url from testcase"]
    foreach row $res {
      dict_to_vars $row ; # id, url
      lassign [det_params $url] groupid country productid catalogtype citypostalcode language
      # breakpoint
      $db exec "update testcase
                set groupid='$groupid', country='$country', productid='$productid',catalogtype='$catalogtype',citypostalcode='$citypostalcode',language='$language'
                where id=$id"
    }
  }
  log info "Fill_params: finished"
  
  $db exec "drop table if exists script"
  $db exec "create table script (scriptname, has_success integer)"
  $db exec "insert into script (scriptname, has_success)
            select distinct scriptname, 1
            from testcase
            where url like '%/retail_store_locator_results.jsp%'"
  $db exec "insert into script (scriptname, has_success)
            select distinct t.scriptname, 0
            from testcase t
            where not t.scriptname in (
              select distinct t2.scriptname
              from testcase t2
              where t2.url like '%/retail_store_locator_results.jsp%'
            )"
}

# groupId=SENSOTOUCH_3D_SHAVING_SU_FR_CONSUMER&country=fr&productId=RQ1250_22_FR_CONSUMER&catalogType=consumer&cityPostalCodeUsed=france&language=fr&buyLayerUsed=yes
proc det_params {url} {
  set res [dict create]
  set query [:query [uri::split $url]]
  foreach el [split $query "&"] {
    if {[regexp {^(.+)=(.*)$} $el z nm val]} {
      dict set res $nm $val 
    }
  }
  list [:groupId $res] [:country $res] [:productId $res] [:catalogType $res] [:cityPostalCodeUsed $res] [:language $res]
}

proc fill_lat_long {db} {
  log info "fill_lat_long: start"
  $db exec "update testcase set latitude = (select latitude from latlong_latlong l where l.postalcode = testcase.citypostalcode)"
  $db exec "update testcase set longitude = (select longitude from latlong_latlong l where l.postalcode = testcase.citypostalcode)"
  log info "fill_lat_long: finished"
}


main $argv

