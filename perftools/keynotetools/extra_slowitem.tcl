# updatemaxitem.tcl - called by libextraprocessing.tcl

# @todo volgens nieuwe spec: daily update, maxitems per dag.
proc extra_update_slowitem {db dargv subdir} {
  set minsec [:minsec $dargv]
  log info "minsec: $minsec"
  set scriptname [file tail $subdir]
  check_do_daily $db "slowitem" aggr_slowitem {
    # date_cet is set for each day to handle.
    log info "Determining slowitem values for: $date_cet"
    
    # @note NOT: @todo 23-11-2013 bugfix/workaround: delete items from target table for the working-date. Should've been done in check_do_daily
    # @note 23-11-2013 only aggr_run,page had the bug, reason was found: aggr_slowitem also used there.
    # $db exec2 "delete from aggr_slowitem where date_cet = '$date_cet'"
    
    # @note 23-11-2013 add_tabledef not needed here, because $db insert not used here.
    #$db add_tabledef aggr_slowitem {id} {date_cet scriptname {page_seq int} keytype keyvalue {seqnr int} \
    # {avg_page_sec real} {avg_loadtime_sec real} {nitems int}} 

    $db exec2 "drop table if exists temp_slowitem"
    $db exec2 "create table temp_slowitem as
               select i.urlnoparams urlnoparams, 1*i.page_seq page_seq, round(1.0*sum(0.001*i.element_delta)/(r.datacount),3) avg_page_sec, 
                      round(avg(0.001*i.element_delta),3) avg_loadtime_sec, count(i.id) nitems
               from pageitem i join aggr_run r on r.date_cet = i.date_cet
               where i.date_cet = '$date_cet'
               group by 1,2
               having avg_page_sec > $minsec
               order by 3 desc" -log
               
    # pas in tweede stuk de rowid van de temptable gebruiken.
    # hierdoor ook steeds temp table deleten, zodat rowid steeds met 1 begint.
    $db exec2 "insert into aggr_slowitem (date_cet, scriptname, page_seq, keytype, keyvalue, seqnr, avg_page_sec, avg_loadtime_sec, nitems)
               select '$date_cet' date_cet, '$scriptname' scriptname, page_seq, 'urlnoparams' keytype, urlnoparams keyvalue,
                      rowid seqnr, avg_page_sec, avg_loadtime_sec, nitems
               from temp_slowitem" -log
    
    $db exec2 "drop table if exists temp_slowitem"              
  }
}
