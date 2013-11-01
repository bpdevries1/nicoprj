# updatemaxitem.tcl - called by libextraprocessing.tcl

# @todo volgens nieuwe spec: daily update, maxitems per dag.
proc extra_update_maxitem {db dargv subdir} {
  set sec_prev_dateuntil [det_prev_dateuntil $db "maxitem"]
  set sec_last_dateuntil [det_last_dateuntil]
  # wil voor maxitem voor max 7 dagen in het verleden de data bepalen.
  # kan evt door hier een check en update te doen, en dan een algemene functie aan te roepen, die
  # dan ook bovenstaande 2 waarden bepaalt. Dit is dan een trucje dat hier kan werken.
  
  
  log info "Recreate maxitem table"
  set max_urls [:maxitem $dargv]
  $db exec2 "drop table if exists maxitem" -log
  
  $db exec2 "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq int, loadtime real)" -log

  set last_week [det_last_week $db]
  log info "Determined last week as: $last_week (possibly old database)"
  log info "Max_urls to determine: $max_urls"
  
  # @todo per dag waarden bepalen: dan evt ook te zien of deze top20 nogal verandert (en of dit boeiend is, dwz hoge tijden).
  $db exec2 "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, i.page_seq, avg(0.001*i.element_delta) loadtime
            from pageitem i
            where i.status_code between '200' and '399'
            and i.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls" -log
  log info "Dropped, created and filled maxitem"        
}

# @pre we have a new day, and added some daily stats.
# @pre updatemaxitem cmdline param is given.
proc update_maxitem_old {db max_urls} {
  log info "Recreate maxitem table"
  $db exec2 "drop table if exists maxitem" -log
  
  $db exec2 "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq int, loadtime real)" -log

  set last_week [det_last_week $db]
  log info "Determined last week as: $last_week (possibly old database)"
  log info "Max_urls to determine: $max_urls"
  if {0} {
    $db exec2 "insert into maxitem (url, page_seq, loadtime)
              select i.urlnoparams, p.page_seq, avg(0.001*i.element_delta) loadtime
              from scriptrun r, page p, pageitem i
              where p.scriptrun_id = r.id
              and i.page_id = p.id
              and 1*r.task_succeed_calc = 1
              and r.ts_cet > '$last_week'
              group by 1,2
              order by 3 desc
              limit $max_urls" -log
  }            
  $db exec2 "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, i.page_seq, avg(0.001*i.element_delta) loadtime
            from pageitem i
            where i.status_code between '200' and '399'
            and i.ts_cet > '$last_week'
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

