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
              geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7
    $r qplot title "Availability - C - $period" \
              x date y avail \
              xlab "Date" ylab "Availability" \
              geom line-point colour scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.06 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
  
    $r query "select scriptname, date_cet date, page_time_sec, avg_nkbytes, avg_nitems 
              from aggr_run
              where date_cet > '[period2startdate $period]'"
    # one generic graph per datatype, all in one graph with lines.
    # ymin 0
    $r qplot title "Average daily page loading times - C - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.06 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily page loading times - F - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7
              
    $r qplot title "Average daily #kilobytes - C - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              geom line-point colour scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.06 \
              legend.avg 1 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily #kilobytes - F - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7
              
    $r qplot title "Average daily #items - C - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              geom line-point colour scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.06 \
              legend.avg 1 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "Average daily #items - F - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7
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
              geom line-point colour variable \
              facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal
  }              
}
 
proc graph_combined_topdomain {r dargv period} {
  if {[period2days $period] >= 7} {  
    $r query "select s.scriptname, s.date_cet date, s.keyvalue topdomain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = 'topdomain'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per topdomain averaged per page by script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour topdomain facet scriptname \
              width 11 height.min 9 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    # @todo maybe replace having loadtime2 > 0.1 with a subselect check: avg of this domain for the whole period should be more than 0.1 sec.
    # @note currently, if one day only has domain > 0.1s, it will appear in the graph, with a low avg noted in the legend.
    $r query "select date, topdomain, sum(loadtime)/(select count(distinct scriptname) from aggr_run) loadtime2 from (              
                select s.scriptname, s.date_cet date, s.keyvalue topdomain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = 'topdomain'
                and s.date_cet > '[period2startdate $period]'
                group by 1,2,3)
              group by 1,2
              having loadtime2 > 0.1"
    # ymin 0
    $r qplot title "Sum of load times per topdomain averaged per page and script - $period" \
              x date y loadtime2 xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour topdomain \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.0  \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    $r qplot title "Sum of load times per topdomain averaged per page and script - $period (logscale)" \
              x date y loadtime2 xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour topdomain \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.0 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical \
              extra "scale_y_log10()"
  }
}

proc graph_combined_extension {r dargv period} {
  if {[period2days $period] >= 7} {
    $r query "select s.scriptname, s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = 'extension'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per extension averaged per page by script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour extension facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    $r query "select date, extension, sum(loadtime)/(select count(distinct scriptname) from aggr_run) loadtime2 from (              
                select s.scriptname, s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = 'extension'
                and s.date_cet > '[period2startdate $period]'
                group by 1,2,3)
              group by 1,2
              having loadtime2 > 0.1"
    $r qplot title "Sum of load times per extension averaged per page and script - $period" \
              x date y loadtime2 xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour extension \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.0 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
  }
}

proc graph_combined_maxitem_new_old {r dargv period} {
  if {[period2days $period] >= 7} {  

if {0} {
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
}              
      $r query "select m.scriptname, m.date_cet date, a.avgtimeurl url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
                from aggr_maxitem m 
                  join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                  join (select keyvalue url, '\[' || round(avg(avg_time_sec), 3) || 's\] ' || keyvalue avgtimeurl
                        from aggr_maxitem m3
                        where m3.keytype = 'urlnoparams'
                        and m3.keyvalue in (
                          select a2.keyvalue
                          from aggr_maxitem a2
                          where a2.date_cet = (select max(date_cet) from aggr_run)
                          and a2.keytype = 'urlnoparams'
                          and a2.seqnr <= 5
                        )
                        and m3.date_cet > '[period2startdate $period]'
                        and m3.seqnr <= 5
                        group by 1) a on a.url = m.keyvalue
                where m.keytype = 'urlnoparams'
                and m.keyvalue in (
                  select a3.keyvalue
                  from aggr_maxitem a3
                  where a3.date_cet = (select max(date_cet) from aggr_run)
                  and a3.keytype = 'urlnoparams'
                  and a3.seqnr <= 5
                )
                and m.date_cet > '[period2startdate $period]'
                and m.seqnr <= 5
                group by 1,2
                order by url desc, m.date_cet"
              
    $r qplot title "Slow URLs averaged per page by script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
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
    $r qplot title "Slow URLs averaged per page and script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height 9 \
              legend.position bottom \
              legend.direction vertical    
  }
}

proc graph_combined_maxitem {r dargv period} {
  if {[period2days $period] >= 7} {  
    $r query "select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
              from aggr_maxitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
              where m.keytype = 'urlnoparams'
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
    $r qplot title "Slow URLs averaged per page by script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical    
    # use the main query above as a subquery here to aggregate over all scripts.
    $r query "select date, url, avg(loadtime) loadtime from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
                from aggr_maxitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
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
    # legend.avg 3 => add averages of values to legend-colours rounded to 3 decimals.
    $r qplot title "Slow URLs averaged per page and script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
  }
}

proc graph_combined_gt3 {r dargv period} {
  if {[period2days $period] >= 7} {  
    if {[period2days $period] <= 50} {  
      # first the general one.
      $r query "select a.date date, a.topdomain topdomain, sum(a.avg_page_sec) / 
                      (select count(distinct scriptname) from aggr_run) avg_page_sec2
                from (select i.date_cet date, topdomain, i.scriptname, 0.001*sum(i.element_delta)/(r.datacount*r.npages) avg_page_sec,
                  0.001*sum(i.element_delta), r.datacount, r.npages
                from pageitem_gt3 i join aggr_run r on r.date_cet = i.date_cet and r.scriptname = i.scriptname
                where i.date_cet >= '[period2startdate $period]'
                group by 1,2,3) a
                group by 1,2
                having avg_page_sec2 > 0.1"
      $r qplot title "Items longer than 3 sec averaged per page and script by topdomain - $period" \
              x date y avg_page_sec2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour topdomain \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
      $r query "select a.date date, a.extension extension, sum(a.avg_page_sec) / 
                      (select count(distinct scriptname) from aggr_run) avg_page_sec2
                from (select i.date_cet date, extension, i.scriptname, 0.001*sum(i.element_delta)/(r.datacount*r.npages) avg_page_sec,
                  0.001*sum(i.element_delta), r.datacount, r.npages
                from pageitem_gt3 i join aggr_run r on r.date_cet = i.date_cet and r.scriptname = i.scriptname
                where i.date_cet >= '[period2startdate $period]'
                group by 1,2,3) a
                group by 1,2
                having avg_page_sec2 > 0.1"
      $r qplot title "Items longer than 3 sec averaged per page and script by extension - $period" \
              x date y avg_page_sec2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour extension \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

      $r query "select a.date, a.functiontype, sum(a.avg_page_sec) / 9 avg_page_sec2
                from (select i.date_cet date, 
                CASE 
                WHEN (i.urlnoparams like '%flash%' or extension = 'swf') THEN 'Flash'
                WHEN i.url like '%locator%jsp%' THEN 'DealerLocator'
                WHEN i.extension in ('png','gif','jpg') THEN 'Image'
                WHEN i.extension in ('eot') THEN 'Font'
                WHEN i.extension in ('css') THEN 'CSS'
                WHEN i.extension in ('js') THEN 'JS'
                WHEN i.url like '%/cat/' THEN 'Category'
                WHEN i.url like '%/prd/' THEN 'PDP'
                ELSE 'Other'
                END AS functiontype, 
                i.scriptname, 0.001*sum(i.element_delta)/(r.datacount*r.npages) avg_page_sec
                from pageitem_gt3 i join aggr_run r on r.date_cet = i.date_cet and r.scriptname = i.scriptname
                where i.date_cet >= '[period2startdate $period]'
                group by 1,2,3) a
                group by 1,2
                having avg_page_sec2 > 0.1"
      $r qplot title "Items longer than 3 sec averaged per page and script by functiontype - $period" \
              x date y avg_page_sec2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour functiontype \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    } else {
      log info "No GT3 graphs for more than 50 days"
    }
  } else {
    log info "TODO: GT3 graphs for 2 days"
  }

}
