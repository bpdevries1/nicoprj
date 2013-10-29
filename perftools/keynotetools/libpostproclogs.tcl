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
  
  # 12-10-2013 removed some calls, data already put there in standard scatter2db.tcl.
  # log start_stop add_fields $db
  # log start_stop add_topdomain $db [:cleantopdomain $dargv]
   
  lassign [det_script_country_npages $dir $db] script country npages
  if {$script == "<none>"} {
    log warn "Could not determine script and country from $dir, ignore this dir and continue"
    return
  }
  
  # log start_stop make_indexes $db
  
  # 12-10-2013 don't set/update task_succeed anymore. At some point, postproc will be done on the
  # main DB's, we only want to add data there, not replace it (compare Datomic).
  # log start_stop set_task_succeed $db
  
  # @note checkrun table and run_avail have same keys, so could be combined.
  # @note for now first fill/update checkrun, then possibly use results in run_avail.
  # @todo nu even niet voor test, later weer aanzetten.
  # 12-10-2013 checkrun tabel filled in scatter2db.tcl.
  #if {1} {
  #  log start_stop make_run_check $db $dir $max_urls
  #}
  log start_stop make_daily_tables $db $dir $max_urls
  
  # log start_stop make_run_avail $db $dir $dargv
  # @todo log start_stop lijkt dargv plat te slaan, niet de bedoeling.
  make_run_avail $db $dir $dargv
  
  $db close  
}

# @todo not sure yet if this function is (too) slow.
# @todo drop table first seems slow.
proc make_daily_tables {db srcdir max_urls} {
  # those queries used to be in R script graphs-myphilips.R
  $db exec2 "drop table if exists runcount" -log
  $db exec2 "create table runcount as
            select strftime('%Y-%m-%d', r.ts_cet) date, count(*) number
            from scriptrun r, checkrun c
            where r.id = c.scriptrun_id
            and c.real_succeed = 1
            group by 1" -log

  log info "Dropped and created runcount"            
     
  # fill_urlnoparams $db
            
  # helpers to show top 20 URL's (page items)
  $db exec2 "drop table if exists maxitem" -log
  
  $db exec2 "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq, loadtime)" -log

  set last_week [det_last_week $db]
  log info "Determined last week as: $last_week (possibly old database)"
  $db exec2 "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, p.page_seq, avg(0.001*i.element_delta) loadtime
            from scriptrun r, page p, pageitem i, checkrun c
            where c.scriptrun_id = r.id
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and c.real_succeed = 1
            and r.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls" -log
            
  log info "Dropped, created and filled maxitem"            
}

# want to calc top 20 items from last week data. But use last moment of measurements in the DB, not current time.
proc det_last_week {db} {
  set res [$db query "select date(max(r.ts_cet), '-7 days') lastweek from scriptrun r"]
  :lastweek [lindex $res 0]
}

# @note also used in kn-migrations
proc has_db {el} {
  return "has_$el" 
}

# @note also used in kn-migrations
proc has_dbdef {el} {
  return "has_$el integer" 
}

# @param like_str should include %'s if needed, will not be added by this proc.
proc update_checkrun_url_like {db dbfield like_str} {            
  # distinct nu even weg, niet echt nodig, alleen trager.
  $db exec2 "update checkrun set $dbfield = 1 where scriptrun_id in (
              select i.scriptrun_id
              from pageitem i
              where i.url like '$like_str'
            )" -log
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

# create run_avail table, fill with task_succeed and underlying reasons for failure.
proc make_run_avail {db dir dargv} {
  log info "make_run_avail: start"
  if {[:clean $dargv]} {
    log info "Dropping table run_avail" 
    $db exec2 "drop table if exists run_avail" -log
  }
  set script [file tail $dir]
  # @note choice now to have just one table with max 2 error elements.
  # @todo drop table niet zo zinnig nog, als je toch items gaat toevoegen altijd.
  # @todo beter met query params te werken, of escapen van quotes in url. Nu even url niet meenemen, wel urlnp.
  # @todo komen nu dubbele items in: ofwel hier op checken, ofwel tabel eerst legen, evt met cmdline parameter.
  $db exec2 "create table if not exists run_avail (scriptname, scriptrun_id integer, 
               ts_cet, task_succeed, err_page_seq integer, err_page_id integer,
               known_error integer, known_error_type,
               pg_err_code, pg_bytes, pg_elts, 
               elt_id, elt_error_code, elt_status_code, elt_url, elt_urlnp, elt_domain, elt_topdomain,
               elt_id2, elt_error_code2, elt_status_code2, elt_url2, elt_urlnp2, elt_domain2, elt_topdomain2)" -log
  # @note below two fields added later.
  $db exec_try "alter table run_avail add known_error integer"
  $db exec_try "alter table run_avail add known_error_type"

  # @todo first idea (but wrong) if run_avail already existed and was 
  #       filled, keep ts_cet until it is already filled.
  # @todo better idea: run_avail should be filled during scatter2db, just as checkrun.
  $db exec2 "insert into run_avail (scriptname, scriptrun_id, ts_cet, task_succeed, err_page_seq,
                 err_page_id, pg_err_code, pg_bytes, pg_elts)
               select '$script', r.id, r.ts_cet, r.task_succeed, 0,
                 0, '0', 0, 0
               from scriptrun r
               where r.task_succeed = 1" -log
  
  $db exec2 "insert into run_avail (scriptname, scriptrun_id, ts_cet, task_succeed, err_page_seq,
                 err_page_id, pg_err_code, pg_bytes, pg_elts)
               select '$script', r.id, r.ts_cet, r.task_succeed, p.page_seq, p.id, p.error_code, 
                 p.page_bytes, p.element_count
               from scriptrun r join page p on p.scriptrun_id = r.id
               where task_succeed = 0
               and p.error_code <> ''" -log
               
  $db exec2 "create index if not exists ix_run_avail1 on run_avail (scriptrun_id)" -log
  $db exec2 "create index if not exists ix_run_avail2 on run_avail (err_page_id)" -log

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
         $db exec2 "update run_avail
                   set elt_id = 0, elt_error_code = '<none>',
                       elt_status_code = '<none>',
                       elt_urlnp = '<none>',
                       elt_domain = '<none>',
                       elt_topdomain = '<none>'
                   where err_page_id = $page_id" -log
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
         $db exec2 $query3 -log                  
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
  $db exec2 "update run_avail set known_error_type = 'mobile-redir' 
            where known_error_type is null 
            and scriptrun_id in (
              select i.scriptrun_id
              from pageitem i
              where i.domain like 'm.philips%'
            )" -log
            
  # navigation error with shavers
  if {[regexp -- {-RQ} $dir]} {
    log info "Shavers, check for shaver nav error"
    $db exec2 "update run_avail set known_error_type = 'shaver-nav' 
              where known_error_type is null 
              and scriptrun_id in (
                select distinct p.scriptrun_id
                from page p
                where p.error_code = '-1010'
              )" -log
  } else {
    log info "No shavers, no shaver nav error" 
  }
  
  # after known_error_type is filled, fill known_error with 0 or 1
  log info "known_error_type filled, now fill known_error field"
  $db exec2 "update run_avail
            set known_error = 1
            where known_error_type <> ''
            and known_error is null" -log
  $db exec2 "update run_avail
            set known_error = 0
            where known_error is null" -log
  
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
  $db exec2 "attach database '$src_name' as fromDB" -log
  set table "script_pages"
  # @note possibly the drop table works on fromDB.table, if this is the only one.
  # $db exec "drop table if exists $table"
  $db exec2 "create table $table as select * from fromDB.$table" -try -log
  $db exec2 "detach fromDB" -log
}

