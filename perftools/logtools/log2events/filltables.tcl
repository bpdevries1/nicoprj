# Library functions for log2events.tcl

#$db add_tabledef event {id} {{seqnr int} filename {linenr int} ts_cet enterexit callname HENV HDBC HSTMT query {returncode int} returnstr lines}
#$db add_tabledef odbccall {id} {filename {seqnr_enter int} {seqnr_exit int} {linenr_enter int} {linenr_exit} ts_cet_enter ts_cet_exit {calltime real} callname HENV HDBC HSTMT query {returncode int} returnstr}

proc fill_calls {db} {
  log info "Fill_calls - start"
  $db exec "insert into odbccall (filename, seqnr_enter, seqnr_exit,
            linenr_enter, linenr_exit, ts_cet_enter, ts_cet_exit, callname,
            HENV, HDBC, HSTMT, query, returncode, returnstr, calltime)
            select e2.filename, e1.seqnr, e2.seqnr, e1.linenr, e2.linenr,
            e1.ts_cet, e2.ts_cet, e2.callname, e2.HENV, e2.HDBC, e2.HSTMT, e2.query, e2.returncode, e2.returnstr,
            timediff(e1.ts_cet, e2.ts_cet)
            from event e1 join event e2 on e1.seqnr + 1 = e2.seqnr and e1.filename = e2.filename
            where e1.enterexit = 'ENTER'
            and e2.enterexit = 'EXIT'
            and ((e1.HDBC = e2.HDBC) or (e1.callname = 'SQLAllocConnect'))
            and e1.callname == e2.callname"
  log info "Fill_calls - finished"
}

# puts "before proc fill_queries"
# TODO: deze vooral traag, waarschijnlijk paar indexen toevoegen.
# 7-10-2015 voor odbc-prod (IM) was deze query 15 minuten bezig.
proc fill_queries {db} {
  log info "fill_queries - start"
  
  $db exec "insert into odbcquery (filename, seqnr_start, seqnr_end, linenr_start, linenr_end, 
ts_cet_start, ts_cet_end, query_elapsed, HENV, HDBC, HSTMT, query)
select o1.filename, o1.seqnr_enter, o2.seqnr_exit, o1.linenr_enter, o2.linenr_exit,
o1.ts_cet_enter, o2.ts_cet_exit, timediff(o1.ts_cet_enter, o2.ts_cet_exit), o2.HENV, o2.HDBC, o2.HSTMT, o2.query
from odbccall o1 join odbccall o2 on o1.HDBC = o2.HDBC and o1.HSTMT = o2.HSTMT and o1.filename = o2.filename
where o1.callname = 'SQLAllocStmt'
and o2.callname = 'SQLFreeStmt'
and o1.seqnr_enter < o2.seqnr_enter
and not exists (
                select 1
                from odbccall o3
                where o3.HDBC = o1.HDBC
                and o3.HSTMT = o1.HSTMT
                and o3.filename = o1.filename
                and o3.callname = 'SQLFreeStmt'
                and o3.seqnr_enter < o2.seqnr_enter
                and o3.seqnr_enter > o1.seqnr_enter
                )"

  log info "fill_queries - set odbcquery_id"
  $db exec "update odbccall
            set odbcquery_id = (
                                select id
                                from odbcquery q
                                where odbccall.seqnr_enter >= q.seqnr_start
                                and odbccall.seqnr_exit <= q.seqnr_end
                                and odbccall.HSTMT = q.HSTMT
                                and odbccall.filename = q.filename
                    )"

  log info "fill queries - set query_servertime"
  $db exec "update odbcquery
            set query_servertime = (
                        select printf('%.3f', sum(o.calltime))
                        from odbccall o
                        where o.odbcquery_id = odbcquery.id
                        and o.filename = odbcquery.filename
                        )"

  log info "fill_queries - finished"
}

proc fill_userthink {db} {
  # set USERTHINK_TRESHOLD 0.5
  log info "fill_userthink - start"

  $db exec "delete from userthink"
  
  $db exec "insert into userthink (filename, seqnr_before, seqnr_after, ts_cet_before, ts_cet_after, thinktime)
            select e1.filename, e1.seqnr, e2.seqnr, e1.ts_cet, e2.ts_cet, timediff(e1.ts_cet, e2.ts_cet)
            from event e1 join event e2 on e1.seqnr+1 = e2.seqnr and e1.filename = e2.filename
            where e1.enterexit = 'EXIT'
            and e2.enterexit = 'ENTER'"
  # 18-8-2015 NdV hier toch even alles in, elders bepalen wat een reele think time is.
  #           and 1.0*timediff(e1.ts_cet, e2.ts_cet) > $USERTHINK_TRESHOLD
  log info "fill_userthink - finished"
  
}

proc fill_useraction {db} {
  set USERTHINK_TRESHOLD 0.5
  set prev_seqnr 0
  set prev_thinktime 0.0
  $db exec "delete from useraction"
  # for each significant pause/thinktime, create useraction for all events up to this pause (and not in previous useraction)
  foreach rec [$db query "select * from userthink where thinktime > $USERTHINK_TRESHOLD"] {
    $db exec "insert into useraction (filename, seqnr_first, seqnr_last, ts_cet_first, ts_cet_last, thinktime_before, thinktime_after)
              select e.filename, min(e.seqnr), max(e.seqnr), min(e.ts_cet), max(e.ts_cet), $prev_thinktime, [:thinktime $rec]
              from event e
              where e.seqnr between $prev_seqnr+1 and [:seqnr_before $rec]
              group by 1"
    set prev_seqnr [:seqnr_after $rec]
    set prev_thinktime [:thinktime $rec]
  }
  # create useraction after last significant pause/thinktime
  $db exec "insert into useraction (filename, seqnr_first, seqnr_last, ts_cet_first, ts_cet_last, thinktime_before, thinktime_after)
            select e.filename, min(e.seqnr), max(e.seqnr), min(e.ts_cet), max(e.ts_cet), $prev_thinktime, 0.0
            from event e
            where e.seqnr >= $prev_seqnr+1
            group by 1"
  
  # calc resptime
  $db exec "update useraction
            set resptime = timediff(ts_cet_first, ts_cet_last)"

  # deze niet hier uitvoeren, dan ncalls = 0            
  #$db exec "update useraction set ncalls = (
  #            select count(*)
  #            from odbccall c
  #            join odbcquery_do q on q.odbcquery_id = c.odbcquery_id
  #            where q.start_useraction_id = useraction.id)"
  
}

# fill version of odbcquery without alloc and free statements.
# goal is to have more real response times of queries, and less overlap between queries.
proc fill_odbcquery_do {db} {
  log info "fill_odbcquery_do - start"
  $db exec "delete from odbcquery_do"
  $db exec "insert into odbcquery_do (odbcquery_id, filename, seqnr_start, seqnr_end, linenr_start, linenr_end,
    ts_cet_start, ts_cet_end, query_servertime, HENV, HDBC, HSTMT, query)
    select q.id, q.filename, min(o.seqnr_enter), max(o.seqnr_exit), min(o.linenr_enter), max(o.linenr_exit),
           min(o.ts_cet_enter), max(o.ts_cet_exit), printf('%.3f', sum(o.calltime)), q.HENV, q.HDBC, q.HSTMT, q.query
    from odbcquery q join odbccall o on o.odbcquery_id = q.id
    where o.callname not in ('SQLAllocStmt', 'SQLFreeStmt')
    group by q.id, q.filename, q.HENV, q.HDBC, q.HSTMT, q.query"

  $db exec "update odbcquery_do set query_elapsed = timediff(ts_cet_start, ts_cet_end)"

  # fill useraction corresponding to start and end of query, should be the same.
  $db exec "update odbcquery_do set start_useraction_id = (
              select u.id from useraction u
              where odbcquery_do.seqnr_start between u.seqnr_first and u.seqnr_last)"

  $db exec "update odbcquery_do set end_useraction_id = (
              select u.id from useraction u
              where odbcquery_do.seqnr_end between u.seqnr_first and u.seqnr_last)"

  $db exec "update odbcquery_do set nbindcol = (select count(*) from odbccall c where c.odbcquery_id = odbcquery_do.odbcquery_id and c.callname = 'SQLBindCol')"

  $db exec "update odbcquery_do set nfetch = (select count(*) from odbccall c where c.odbcquery_id = odbcquery_do.odbcquery_id and c.callname like 'SQLFetch%')"

  $db exec "update odbcquery_do set nsqlgetdata = (select count(*) from odbccall c where c.odbcquery_id = odbcquery_do.odbcquery_id and c.callname = 'SQLGetData')"

  $db exec "update odbcquery_do set ncalls = (select count(*) from odbccall c where c.odbcquery_id = odbcquery_do.odbcquery_id)"

  # 21-8-2015 breedte van 3 is voorlopig genoeg voor odbcquery_id
  $db exec "update odbcquery_do set title = printf('%03d: %s \[#%d\]', odbcquery_id, substr(query, 1, 20), ncalls)"

  # 7-10-2015 NdV deze als laatste. Bij eerder uitvoeren met 0-en gevuld.  
  $db exec "update useraction set ncalls = (
              select count(*)
              from odbccall c
              join odbcquery_do q on q.odbcquery_id = c.odbcquery_id
              where q.start_useraction_id = useraction.id)"
  
  
  log info "fill_odbcquery_do - finished"
}



