# this is a lib, no bash (env) start needed.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# general proc also usable in apidata2dashboard.
# entry proc
# uitgangspunt: ofwel deel-acties doen niets, kosten weinig tijd als nogmaals aangeroepen;
#               ofwel via cmdline params te regelen dat actie niet wordt uitgevoerd.
#               bij functie noteren welke het is.
proc post_proc_srcdir {dir dargv} {
  set max_urls [:maxurls $dargv]
  set srcdbname [file join $dir "keynotelogs.db"]
  
  # first update task_succeed field
  set db [dbwrapper new $srcdbname]
  
  copy_script_pages $db
  
  log start_stop add_fields $db
  log start_stop add_topdomain $db [:cleantopdomain $dargv]
  
  # for test:
  if {0} {
    $db close
    log info "Added topdomain for $dir"
    exit
  }
  
  # for testing function def.
  if {0} {
    # set conn [$db get_conn]
    set handle [$db get_db_handle]
    $handle function lengte lengte  
    $db query "select url, lengte(url) from pageitem limit 10"
  }
   
  lassign [det_script_country_npages $dir $db] script country npages
  if {$script == "<none>"} {
    log warn "Could not determine script and country from $dir, ignore this dir and continue"
    return
  }
  
  log start_stop make_indexes $db
  log start_stop set_task_succeed $db
  
  # @note checkrun table and run_avail have same keys, so could be combined.
  # @note for now first fill/update checkrun, then possibly use results in run_avail.
  # @todo nu even niet voor test, later weer aanzetten.
  if {1} {
    log start_stop make_run_check $db $dir $max_urls
  }

  # log start_stop make_run_avail $db $dir $dargv
  # @todo log start_stop lijkt dargv plat te slaan, niet de bedoeling.
  make_run_avail $db $dir $dargv
  
  $db close  
}

proc lengte {str} {
  string length $str 
}

# @note this proc does not take a lot of time.
# @note this functionality has been added to scatter2db.tcl
proc make_indexes {db} {
  log debug "Creating indexes for: [$db get_dbname]"
  $db exec_try "create index ix_page_1 on page (scriptrun_id)"
  $db exec_try "create index ix_pageitem_1 on pageitem (scriptrun_id)"
  $db exec_try "create index ix_pageitem_2 on pageitem (page_id)"
}

proc set_task_succeed {db} {
  # log info "Setting task_succeed in scriptrun: start"
  $db exec2 "update scriptrun
                set task_succeed = 0
                where task_succeed = '<none>'
                and id in (
                  select scriptrun_id
                  from page p
                  where p.error_code <> ''
                )" -log
  $db exec2 "update scriptrun
                set task_succeed = 1
                where task_succeed = '<none>'" -log
  # log info "Setting task_succeed in scriptrun: finished"                
}

# @note this one also (only) used in scatter2db/kn-migrations.tcl
proc set_task_succeed_calc {db} {
  # log info "Setting task_succeed in scriptrun: start"
  $db exec2 "update scriptrun
             set task_succeed_calc = task_succeed
             where task_succeed_calc is null
             and task_succeed in ('0','1', 0, 1)" -log 
  $db exec2 "update scriptrun
                set task_succeed_calc = 0
                where task_succeed_calc is null
                and id in (
                  select scriptrun_id
                  from page p
                  where p.error_code <> ''
                )" -log
  $db exec2 "update scriptrun
                set task_succeed_calc = 1
                where task_succeed_calc is null" -log
  # log info "Setting task_succeed in scriptrun: finished"                
}

# @todo make more generic when eg CN needs to be checked.
# @todo not sure yet if this function is (too) slow.
proc make_run_check {db srcdir max_urls} {
  if {[regexp -nocase {myphilips} $srcdir]} {
    log start_stop make_run_check_myphilips $db
  } else {
    log start_stop make_run_check_dealer_locator $db $srcdir
  }
  # make_run_check_generic uses checkrun table, which is created by make_run_check_myphilips 
  log start_stop make_run_check_generic $db $srcdir $max_urls 
}

# @todo not sure yet if this function is (too) slow.
# @todo drop table first seems slow.
proc make_run_check_generic {db srcdir max_urls} {
  # those queries used to be in R script graphs-myphilips.R
  $db exec "drop table if exists runcount"
  $db exec "create table runcount as
            select strftime('%Y-%m-%d', r.ts_cet) date, count(*) number
            from scriptrun r, checkrun c
            where r.id = c.scriptrun_id
            and c.real_succeed = 1
            group by 1"

  log info "Dropped and created runcount"            
     
  fill_urlnoparams $db
  
        
            
  # helpers to show top 20 URL's (page items)
  $db exec "drop table if exists maxitem"
  
  $db exec "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq, loadtime)"

  set last_week [det_last_week $db]
  # and r.ts_cet > '2013-08-26'
  $db exec "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, p.page_seq, avg(0.001*i.element_delta) loadtime
            from scriptrun r, page p, pageitem i, checkrun c
            where c.scriptrun_id = r.id
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and c.real_succeed = 1
            and r.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls"
            
  log info "Dropped, created and filled maxitem"            
}

proc fill_urlnoparams {db} {
  # first set all non-dynamic items, so no need to check/calc afterwards.                  
  $db exec2 "update pageitem
            set urlnoparams = url
            where not (url like '%?%' or url like '%;%')
            and urlnoparams is null" -log
  
  # min works ok, but instr returns 0 when not found, and then min would be 0 as well: not good.
  # so first check only ?, then only ;, then both
  $db exec2 "update pageitem
            set urlnoparams = substr(url, 1, instr(url, '?'))
            where url like '%?%'
            and not url like '%;%'
            and urlnoparams is null" -log

  $db exec2 "update pageitem
            set urlnoparams = substr(url, 1, instr(url, ';'))
            where url like '%;%'
            and not url like '%?%'
            and urlnoparams is null" -log

  # both, use min.
  $db exec2 "update pageitem
            set urlnoparams = substr(url, 1, min(instr(url, ';'), instr(url, '?')))
            where url like '%;%'
            and url like '%?%'
            and urlnoparams is null" -log

  log info "Updated pageitem.urlnoparams (several queries)"      
}

# @note fill_urlnoparams is really slow on DB's (could take 30 minutes+ per DB), so try this one.
# @note add_topdomain is similar, takes 5 minutes (also a bit long).
proc fill_urlnoparams2 {db} {
  [$db get_db_handle] function det_urlnoparams det_urlnoparams

  set query "update pageitem
             set urlnoparams = det_urlnoparams(url)
             where urlnoparams is null"
  $db exec2 $query -log
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

# @note also used in kn-migrations
proc has_db {el} {
  return "has_$el" 
}

# @note also used in kn-migrations
proc has_dbdef {el} {
  return "has_$el integer" 
}

# @todo find generic stuff between this proc and make_run_check_myphilips => put in generic proc
proc make_run_check_dealer_locator {db dir} {
  $db exec_try "drop table checkrun"
  
  set has_fields {store_page wrb_jsp results_jsp error_jsp a_png error_code youtube addthis support_nav_error}
  set db_has_fields [lmap el $has_fields {has_db $el}]
  set dbdef_has_fields [lmap el $has_fields {has_dbdef $el}]
  set query "create table checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, [join $dbdef_has_fields ", "])"
  # $db exec "create table checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, has_store_page, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png integer, has_error_code integer)"
  $db exec $query
  $db exec "create index ix_checkrun_1 on checkrun (scriptrun_id)"
  # first insert all scriptruns
  #$db exec "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, has_store_page, has_wrb_jsp, has_results_jsp, has_error_jsp, has_a_png, has_error_code)
  #          select id, ts_cet, task_succeed, 0, 0, 0, 0, 0, 0, 0
  #          from scriptrun"

  set query "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, [join $db_has_fields ", "])
            select id, ts_cet, task_succeed, 0, [join [repeat [llength $has_fields] "0"] ", "]
            from scriptrun"
  # log info "query: $query"            
  $db exec $query          
  
  log info "Filled first pass of checkrun"
  # dezen niet per page, komt in tabel checkrun, op zelfde niveau als scriptrun

  # check for the existence of the three jsp pages.
  # if there is something with retail_store_locator in this script, then do the check for A.png.
  log start_stop update_checkrun_url_like $db has_store_page "%retail_store_locator%"            
            
  log start_stop update_checkrun_url_like $db has_wrb_jsp "%/wrb_retail_store_locator_results.jsp%"            
  log start_stop update_checkrun_url_like $db has_results_jsp "%/retail_store_locator_results.jsp%"            
  log start_stop update_checkrun_url_like $db has_error_jsp "%/retail_store_locator.jsp%"            
  log start_stop update_checkrun_url_like $db has_a_png "%/A.png%"            

  # for CN, should not contain youtube and addthis
  log start_stop update_checkrun_url_like $db has_youtube "%youtube%"            
  log start_stop update_checkrun_url_like $db has_addthis "%addthis%"            
  
  # error 4006 is not serious and happens quite a lot: Cannot set WinInet status callback for synchronous sessions. Support for Java Applets download measurements
  # more domains are excluded, ip address is set to 0.0.0.0 or NA.
  # @todo check if runs do have an A.png, but also errors, and marked (real_succeed) as not successful.
  log perf "set has_error_code: start"
  $db exec "update checkrun set has_error_code = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.domain != 'philips.112.2o7.net' 
              and i.error_code <> ''
              and i.error_code <> '4006'
              and i.ip_address != '0.0.0.0'
              and i.ip_address != 'NA'
            )"
  log perf "set has_error_code: finished"          
  # nav to support page goes to something else
  if {0} {
    # @todo support_page error goed vullen, 26-9-2013 voor availability/Andre nog niet zo belangrijk
    # lijkt op fout op:                   and not i.url like '%t=support%'
    set support_page_seq [det_support_page_seq $db $dir]
    if {$support_page_seq == 0} {
      log warn "Support page seq not found, don't look for errors on this page" 
    } else {
      log info "Support page seq: $support_page_seq"
      # @todo look for nav error not t=support found in (complete!) URL.
      set query "update checkrun set has_support_nav_error = 1' 
                where scriptrun_id in (
                  select distinct i.scriptrun_id
                  from pageitem i join page p on p.id = i.page_id
                  where i.basepage = 1
                  and p.page_seq = $support_page_seq
                  and not i.url like '%t=support%'
                )"
      log debug "query: $query"              
      $db exec $query              
      log info "Look for support-page errors finished"
    }
  }
  
  # $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_a_png = 1 and has_error_code = 0"
  # 28-8-2013 for now, just check for existence of A.png, don't look at other errors, that may or may not be blocking/real errors.
  # 28-8-2013 the existence of A.png should correlate 100% with the existence of /retail_store_locator_results.jsp and 0% with retail_store_locator.jsp.
  # @todo do some manual checks for this.
  log info "Updating real_succeed: start"
  $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_a_png = 1"
  # if this script has no retail store pages, then don't check for A.png.
  $db exec "update checkrun set real_succeed = 1 where task_succeed = 1 and has_store_page = 0"
  log info "Updating real_succeed: finished"
}

# @param like_str should include %'s if needed, will not be added by this proc.
proc update_checkrun_url_like {db dbfield like_str} {            
  # distinct nu even weg, niet echt nodig, alleen trager.
  $db exec "update checkrun set $dbfield = 1 where scriptrun_id in (
              select i.scriptrun_id
              from pageitem i
              where i.url like '$like_str'
            )"
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

# @note this one does not take a lot of time.
proc add_fields {db} {
  $db exec_try "alter table pageitem add topdomain"
  $db exec_try "alter table pageitem add urlnoparams"
}

# add a field topdomain to pageitem, fill it with topdomain based on domain.
# secure.philips.com -> philips.com
# crsc.philips.com.cn -> phlips.com.cn
# crsc.philips.co.uk -> philips.co.uk
# @note this one should only take (a lot of) time if topdomain is null.
# @note only if -clean is in cmdline, field will be cleared first.
# @note also used in migrations and scatter2db.
proc add_topdomain {db clean {checkfirst 1}} {
  [$db get_db_handle] function det_topdomain det_topdomain
  if {$clean} {
    log info "Clean field topdomain first before filling again"
    $db exec "update pageitem set topdomain = null" 
  }
  # @note update where is null still takes quite some time.
  # @note maybe keep list of actions (and time) in the DB, and only update
  #       records after this timestamp
  # @note for now: check if we can find one item with topdomain filled,
  #       if so, assume all are filled (as it is atomic action).
  # @note could also add an index on topdomain.
  if {$checkfirst} {
    set res [$db query "select id from pageitem where topdomain is not null limit 1"]
  } else {
    # don't check, do update directly
    set res {}    
  }
  if {[llength $res] > 0} {
    log info "Already one topdomain field filled, assume all are filled" 
  } else {
    log info "Not one topdomain filled, fill all now"
    set query "update pageitem
               set topdomain = det_topdomain(domain)
               where topdomain is null"
    $db exec2 $query -log
    log info "Filled all topdomains"
  }
}

# @note also used in migrations and scatter2db.
proc det_topdomain {domain} {
  # return $domain 
  # if it's something like www.xxx.co(m).yy, then return xxx.co(m).yy
  # otherwise if it's like www.xxx.yy, then return xxx.yy
  # maybe regexp isn't the quickest, try split/join first.
  set l [split $domain "."]
  set p [lindex $l end-1]
  if {($p == "com") || ($p == "co")} {
    join [lrange $l end-2 end] "." 
  } else {
    if {$domain == "images.philips.com"} {
      return "scene7" 
    } else {
      join [lrange $l end-1 end] "."
    }
  }  
}

proc det_urlnoparams {url} {
  # add ; or ? to the returned string.
  if {[regexp {^([^\? \;]*.)} $url z res]} {
    return $res 
  } else {
    return $url 
  }
}


# create run_avail table, fill with task_succeed and underlying reasons for failure.
proc make_run_avail {db dir dargv} {
  log info "make_run_avail: start"
  if {[:clean $dargv]} {
    log info "Dropping table run_avail" 
    $db exec "drop table if exists run_avail"
  }
  set script [file tail $dir]
  # @note choice now to have just one table with max 2 error elements.
  # @todo drop table niet zo zinnig nog, als je toch items gaat toevoegen altijd.
  # @todo beter met query params te werken, of escapen van quotes in url. Nu even url niet meenemen, wel urlnp.
  # @todo komen nu dubbele items in: ofwel hier op checken, ofwel tabel eerst legen, evt met cmdline parameter.
  $db exec "create table if not exists run_avail (scriptname, scriptrun_id integer, 
               ts_cet, task_succeed, err_page_seq integer, err_page_id integer,
               known_error integer, known_error_type,
               pg_err_code, pg_bytes, pg_elts, 
               elt_id, elt_error_code, elt_status_code, elt_url, elt_urlnp, elt_domain, elt_topdomain,
               elt_id2, elt_error_code2, elt_status_code2, elt_url2, elt_urlnp2, elt_domain2, elt_topdomain2)"
  # @note below two fields added later.
  $db exec_try "alter table run_avail add known_error integer"
  $db exec_try "alter table run_avail add known_error_type"
               
  $db exec "insert into run_avail (scriptname, scriptrun_id, ts_cet, task_succeed, err_page_seq,
                 err_page_id, pg_err_code, pg_bytes, pg_elts)
               select '$script', r.id, r.ts_cet, r.task_succeed, 0,
                 0, '0', 0, 0
               from scriptrun r
               where r.task_succeed = 1"
  
  $db exec "insert into run_avail (scriptname, scriptrun_id, ts_cet, task_succeed, err_page_seq,
                 err_page_id, pg_err_code, pg_bytes, pg_elts)
               select '$script', r.id, r.ts_cet, r.task_succeed, p.page_seq, p.id, p.error_code, 
                 p.page_bytes, p.element_count
               from scriptrun r join page p on p.scriptrun_id = r.id
               where task_succeed = 0
               and p.error_code <> ''"
               
  $db exec "create index if not exists ix_run_avail1 on run_avail (scriptrun_id)"
  $db exec "create index if not exists ix_run_avail2 on run_avail (err_page_id)"

if {0} {  
  Opties:
  - eerst alleen de eerste pageitem info vullen.
  
  Plan A:
  1. Alle page + run ids ophalen waar er fouten zijn.
  2. Voor elke page/run:
     - haal alle pageitems op met error, maar niet van de 3 domains.
     - als er geen is, dan van alle domains ophalen. -> hoeft niet, sowieso dan raar geval, maar even kijken hoe vaak dit voorkomt.
     - sowieso order by id (record_seq hier, id is wel algemener, moet normaal ook wel kloppen)
  3. update record in run_avail en zet item info. Dan wel index nodig.
  4. evt later ook info van 2e item, alleen als het significante aantallen betreft.

  Plan B:
  - in 1 query, dan ofwel met not exists zorgen dat je eerste hebt -> traag.
  - in 1 query, error meejoinen (wel left join), steeds eerste pakken. Met union bv 3 fout-domains erbij.
  - mss met special syntax en left join ook wel alleen de eerste te pakken.
}  
  log info "Update element fields where errors exists: start"
  set query "select err_page_id from run_avail where err_page_id > 0"
  set res [$db query $query]
  $db in_trans {
     foreach row $res {
       set page_id [:err_page_id $row]
       set query2 "select i.id, i.error_code, i.status_code, i.url, i.urlnoparams, i.domain, i.topdomain 
                  from pageitem i
                  where i.page_id = $page_id
                  and i.error_code <> ''
                  and not i.topdomain in ('2o7.net', 'livecom.net', 'adoftheyear.com') 
                  order by i.id"
       set res2 [$db query $query2]
       if {[llength $res2] == 0} {
         # elt_id, elt_error_code, elt_status_code, elt_url, elt_urlnp, elt_domain,
         $db exec "update run_avail
                   set elt_id = 0, elt_error_code = '<none>',
                       elt_status_code = '<none>',
                       elt_urlnp = '<none>',
                       elt_domain = '<none>',
                       elt_topdomain = '<none>'
                   where err_page_id = $page_id"
       } else {
         # use first item
         # breakpoint
         set d [lindex $res2 0]
         # elt_url = '[:url $d]',
         
         set query3 "update run_avail
                   set elt_id = [:id $d], elt_error_code = '[:error_code $d]',
                       elt_status_code = '[:status_code $d]',
                       elt_urlnp = '[:urlnoparams $d]',
                       elt_domain = '[:domain $d]',
                       elt_topdomain = '[:topdomain $d]'
                   where err_page_id = $page_id"
         # log debug "query3: $query3"
         # breakpoint
         $db exec $query3                   
       }
     }    
  }
  log info "Update element fields where errors exists: finished"
  
  fill_known_error $db $dir $dargv
  
  log info "make_run_avail: finished"
}

proc fill_known_error {db dir dargv} {
  log info "fill_known_error: start" 

  # mobile redirect
  log info "Check for mobile redirect"
  # removed distinct option.
  $db exec "update run_avail set known_error_type = 'mobile-redir' 
            where known_error_type is null 
            and scriptrun_id in (
              select i.scriptrun_id
              from pageitem i
              where i.domain like 'm.philips%'
            )"
            
  # navigation error with shavers
  if {[regexp -- {-RQ} $dir]} {
    log info "Shavers, check for shaver nav error"
    $db exec "update run_avail set known_error_type = 'shaver-nav' 
              where known_error_type is null 
              and scriptrun_id in (
                select distinct p.scriptrun_id
                from page p
                where p.error_code = '-1010'
              )"
  } else {
    log info "No shavers, no shaver nav error" 
  }
  
  # after known_error_type is filled, fill known_error with 0 or 1
  log info "known_error_type filled, now fill known_error field"
  $db exec "update run_avail
            set known_error = 1
            where known_error_type <> ''
            and known_error is null"
  $db exec "update run_avail
            set known_error = 0
            where known_error is null"
  
  log info "fill_known_error: finished"
}

proc det_support_page_seq {db dir} {
  set query "select page_seq
             from script_pages
             where scriptname = '[file tail $dir]'
             and page_type like '%support%'
             order by page_seq
             limit 1"
  set res [$db query $query]
  if {[llength $res] != 1} {
    log warn "Support page not found in script_pages for $dir"
    return 0
  }
  return [:page_seq [lindex $res 0]]
}

# copy table script_pages from 
proc copy_script_pages {db} {
  set src_name "c:/projecten/Philips/script-pages/script-pages.db"
  if {![file exists $src_name]} {
    error "Src db for script_pages does not exist" 
  }
  $db exec "attach database '$src_name' as fromDB"
  set table "script_pages"
  # @note possibly the drop table works on fromDB.table, if this is the only one.
  # $db exec "drop table if exists $table"
  $db exec_try "create table $table as select * from fromDB.$table"
  $db exec "detach fromDB"
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

