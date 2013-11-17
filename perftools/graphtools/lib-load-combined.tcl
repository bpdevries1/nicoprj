proc graph_combined_default {r dargv period} {
  # daily averages.
  # number of items - per run
  if {[period2days $period] >= 7} {  
    # 2 total average queries for loadtime and availability.
    # @todo: also add min, mag, perc90. But would need to calculate daily
    $r query "select date_cet date, avg(page_time_sec) page_time_sec, avg(avail) avail
              from aggr_run
              where date_cet > '[period2startdate $period]'
              group by 1
              order by 1"
    $r qplot title "Average daily page loading times averaged - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line \
              width 11 height 7
    $r qplot title "Average daily availability averaged - $period" \
              x date y avail xlab "Date/time" ylab "Availability" \
              geom line \
              width 11 height 7
  
    # @todo met line-point en geen colour gaat het fout: shape=as.factor() e.d.            
   
    $r query "select scriptname, date_cet date, avail
              from aggr_run where avail >= 0 and date_cet > '[period2startdate $period]'"
    $r qplot title "Availability - F - $period" \
              x date y avail \
              xlab "Date" ylab "Availability" \
              ymin 0 geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 1 height.perfacet 1.0
    $r qplot title "Availability - C - $period" \
              x date y avail \
              xlab "Date" ylab "Availability" \
              ymin 0 geom line-point colour scriptname \
              width 11 height 8 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
  
    $r query "select scriptname, date_cet date, page_time_sec, avg_nkbytes, avg_nitems 
              from aggr_run
              where date_cet > '[period2startdate $period]'"
    # one generic graph per datatype, all in one graph with lines.
    $r qplot title "Average daily page loading times - C - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              ymin 0 geom line-point colour scriptname \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily page loading times - F - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              ymin 0 geom line facet scriptname \
              width 11 height 12 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
              
    $r qplot title "Average daily #kilobytes - C - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              ymin 0 geom line-point colour scriptname \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily #kilobytes - F - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              ymin 0 geom line facet scriptname \
              width 11 height 12 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
              
    $r qplot title "Average daily #items - C - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              ymin 0 geom line-point colour scriptname \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily #items - F - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              ymin 0 geom line facet scriptname \
              width 11 height 12 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
  }
  # all datapoints? - not available in combined DB.
  
}

proc graph_combined_ttip {r dargv period} {
  if {[period2days $period] >= 7} {  
    # @note where clause to not get R warnings like 1: Removed 3 rows containing missing values (geom_point). 
    $r query "select scriptname, date_cet date, page_time_sec, page_ttip_sec, page_time_sec - page_ttip_sec async_sec
              from aggr_run where page_time_sec >= 0 and date_cet > '[period2startdate $period]'"
    $r melt {page_time_sec page_ttip_sec async_sec}
    $r qplot title "Total and TTIP times - $period" \
              x date y value \
              xlab "Date" ylab "Time (seconds)" \
              ymin 0 geom line-point colour variable \
              facet scriptname \
              legend.position bottom \
              legend.direction horizontal \
              width 11 height 20
  }              
}
 
proc graph_combined_topdomain {r dargv period} {
  if {[period2days $period] >= 7} {  
    $r query "select s.scriptname, s.date_cet date, s.keyvalue topdomain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = 'topdomain'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per topdomain averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour topdomain facet scriptname \
              width 11 height 20 \
              legend.position right \
              legend.direction vertical
              
    $r query "select date, topdomain, avg(loadtime) loadtime from (              
                select s.scriptname, s.date_cet date, s.keyvalue topdomain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = 'topdomain'
                and s.date_cet > '2013-10-01'
                group by 1,2,3)
              group by 1,2"
    $r qplot title "Sum of load times per topdomain averaged per page and script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour topdomain \
              width 11 height 7 \
              legend.position right \
              legend.direction vertical
  }
}

proc graph_combined_extension {r dargv period} {
  if {[period2days $period] >= 7} {
    $r query "select s.scriptname, s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = 'extension'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per extension averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour extension facet scriptname \
              width 11 height 20 \
              legend.position right \
              legend.direction vertical
    $r query "select date, extension, avg(loadtime) loadtime from (              
                select s.scriptname, s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = 'extension'
                and s.date_cet > '2013-10-01'
                group by 1,2,3)
              group by 1,2"
    $r qplot title "Sum of load times per extension averaged per page and script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour extension \
              width 11 height 7 \
              legend.position right \
              legend.direction vertical
  }
}

proc graph_combined_maxitem {r dargv period} {
  if {[period2days $period] >= 7} {  
    $r query "select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
              from aggr_maxitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
              where m.keytype = 'urlnoparams'
              and m.seqnr <= 2
              and m.keyvalue in (
                select a2.keyvalue
                from aggr_maxitem a2
                where a2.date_cet = (select max(date_cet) from aggr_run)
                and a2.keytype = 'urlnoparams'
                and a2.seqnr <= 2
              )
              and m.date_cet > '[period2startdate $period]'
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Max items averaged per page - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour url facet scriptname \
              width 11 height 20 \
              legend.position bottom \
              legend.direction vertical    
    # use the main query above as a subquery here to aggregate over all scripts.
    $r query "select date, url, avg(loadtime) loadtime from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
                from aggr_maxitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
                and m.seqnr <= 2
                and m.keyvalue in (
                  select a2.keyvalue
                  from aggr_maxitem a2
                  where a2.date_cet = (select max(date_cet) from aggr_run)
                  and a2.keytype = 'urlnoparams'
                  and a2.seqnr <= 2
                )
                and m.date_cet > '[period2startdate $period]'
                group by 1,2,3) 
              group by 1,2"                
    $r qplot title "Max items averaged per page and script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour url \
              width 11 height 9 \
              legend.position bottom \
              legend.direction vertical    
  }
}