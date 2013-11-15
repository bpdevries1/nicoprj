# updatemaxitem.tcl - called by libextraprocessing.tcl

# @todo volgens nieuwe spec: daily update, maxitems per dag.
proc extra_update_maxitem {db dargv subdir} {
  if {0} {
    # OLD: specifiek hier: vorige datum op uiterlijk een week geleden zetteen (tov max(r.date_cet))
    set sec_prev_dateuntil [det_prev_dateuntil $db "maxitem"]
    set prev_dateuntil [clock format $sec_prev_dateuntil -format "%Y-%m-%d"]
    set last_week [det_last_week $db]
    if {$prev_dateuntil < $last_week} {
      update_daily_status_db $db "maxitem" $prev_dateuntil $last_week "" "" 
    }
  }
  
  set max_urls [:maxitem $dargv]
  log info "max_urls: $max_urls"
  set scriptname [file tail $subdir]
  check_do_daily $db "maxitem" aggr_maxitem {
    # date_cet is set for each day to handle.
    log info "Determining maxitem values for: $date_cet"
    $db exec2 "drop table if exists temp_maxitem"
    $db exec2 "create table temp_maxitem as
               select i.urlnoparams urlnoparams, i.page_seq page_seq, avg(0.001*i.element_delta) loadtime
               from pageitem i
               where i.status_code between '200' and '399'
               and i.date_cet = '$date_cet'
               group by 1,2
               order by 3 desc
               limit $max_urls" -log
    # pas in tweede stuk de rowid van de temptable gebruiken.
    # hierdoor ook steeds temp table deleten, zodat rowid steeds met 1 begint.
    $db exec2 "insert into aggr_maxitem (date_cet, scriptname, keytype, keyvalue, seqnr, avg_time_sec, page_seq)
               select '$date_cet' date_cet, '$scriptname' scriptname, 'urlnoparams' keytype, urlnoparams keyvalue,
                      rowid seqnr, loadtime avg_time_sec, page_seq
               from temp_maxitem" -log
    
    $db exec2 "drop table if exists temp_maxitem"              
  }
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

