proc graph_combined_default {r dargv period} {
  # daily averages.
  # number of items - per run
  if {[period2days $period] >= 7} {  
    # 2 total average queries for loadtime and availability.
    # @todo: also add min, mag, perc90. But would need to calculate daily
    $r query "select date_cet date, avg(page_time_sec) page_time_sec, avg(avail) avail
              from aggr_run
              where date_cet > '[period2startdate $period]'
              and datacount > 0
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
              from aggr_run 
              where avail >= 0 
              and date_cet > '[period2startdate $period]'
              and datacount > 0"
    # voor onderstaand legend.avg even weg, want sqldf werkt niet meer goed met date columns lijkt het.
    # legend.avg 3 
    $r qplot title "Availability - C - $period" \
              x date y avail \
              xlab "Date" ylab "Availability" \
              geom line-point colour scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.06 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
              
    $r qplot title "Availability - F - $period" \
              x date y avail \
              xlab "Date" ylab "Availability" \
              geom line facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7
  
    $r query "select scriptname, date_cet date, page_time_sec, avg_nkbytes, avg_nitems 
              from aggr_run
              where date_cet > '[period2startdate $period]'
              and datacount > 0"
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
              from aggr_run 
              where page_time_sec >= 0 
              and date_cet > '[period2startdate $period]'
              and datacount > 0"
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
              
    # also summarised over scripts.
    # 8-1-2014: avg() is ok here. If script has no data, times should not be lower.
    $r query "select date_cet date, avg(1.0*page_time_sec) page_time_sec, avg(1.0*page_ttip_sec) page_ttip_sec, 
                     avg(1.0*(page_time_sec - page_ttip_sec)) async_sec
              from aggr_run 
              where page_time_sec >= 0 
              and date_cet > '[period2startdate $period]'
              and datacount > 0
              group by 1"
    $r melt {page_time_sec page_ttip_sec async_sec}
    $r qplot title "Total and TTIP times averaged per script - $period" \
              x date y value \
              xlab "Date" ylab "Time (seconds)" \
              geom line-point colour variable \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal
    
  }              
}

#* facet=script, x=date, y=loadtime, colour = 3 lijnen
#* geen facet, x=date, y=loadtime, colour = 3 lijnen. Gebruik weer query van graph1 en group by gebruiken.
proc graph_combined_pageload3 {r dargv period} {
  if {[period2days $period] >= 7} {  
    # @note where clause to not get R warnings like 1: Removed 3 rows containing missing values (geom_point). 
    $r query "select scriptname, date_cet date, fullpage, ttip, pageload_avg
              from pageload_all3 
              where fullpage >= 0 
              and date_cet > '[period2startdate $period]'"
    $r melt {fullpage ttip pageload_avg}
    $r qplot title "Page loading times measured in 3 ways by script - $period" \
              x date y value \
              xlab "Date" ylab "Time (seconds)" \
              geom line-point colour variable \
              facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              hline 3.0 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal
              
    $r query "select date_cet date, avg(fullpage) fullpage, avg(ttip) ttip, avg(pageload_avg) pageload_avg
              from pageload_all3
              where fullpage >= 0
              and date_cet > '[period2startdate $period]'
              group by 1"
    $r melt {fullpage ttip pageload_avg}
    $r qplot title "Page loading times measured in 3 ways per script - $period" \
              x date y value \
              xlab "Date" ylab "Time (seconds)" \
              geom line-point colour variable \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              hline 3.0 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction horizontal
  }
}

proc graph_combined_aggrsub {r dargv period} {
  # @todo check which keytypes occur in aggrsub, make graphs for each of those.
  # als je het ook maakt voor andere types, dan leteen op ':' in keytype/values, kan niet in filenames. Maar mss geen last van, als keytype simpel is.

  foreach keytype {topdomain extension domain content_type basepage aptimized cntype_apt domain_gt_100k domain_dynamic phys_loc phys_loc_type akh_expiry domain_phys_loc_type} {
    graph_combined_aggrsub_keytype $r $dargv $period $keytype
  }
  graph_combined_aggrsub_keytype $r $dargv $period is_dynamic_url "and 1*s.keyvalue = 1"
  graph_combined_aggrsub_keytype $r $dargv $period status_code_type "and s.keyvalue <> 'ok'"
  graph_combined_aggrsub_keytype $r $dargv $period disable_domain "and 1*s.keyvalue = 1"
  graph_combined_aggrsub_keytype $r $dargv $period akh_cache_control "and s.keyvalue <> 'nseconds'"
  graph_combined_aggrsub_keytype $r $dargv $period akh_x_check_cacheable "and s.keyvalue <> 'YES'"

  # with domain and another field and extra where-clause  
  graph_combined_aggrsub_keytype $r $dargv $period domain_is_dynamic "and s.keyvalue like '%:1'"
  graph_combined_aggrsub_keytype $r $dargv $period domain_result "and s.keyvalue not like '%:ok'"
  graph_combined_aggrsub_keytype $r $dargv $period domain_disable_domain "and s.keyvalue like '%:1'"
  graph_combined_aggrsub_keytype $r $dargv $period domain_cacheable "and s.keyvalue not like '%:YES'"
}

proc graph_combined_aggrsub_keytype {r dargv period keytype {where_extra ""}} {
  if {[period2days $period] >= 7} {
    $r query "select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/r.npages loadtime,
                     1.0*sum(s.avg_nitems) nitems, 1.0*sum(s.avg_nkbytes) nkbytes
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = '$keytype' $where_extra
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per $keytype averaged per page by script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nitems per $keytype averaged per page by script - $period" \
              x date y nitems xlab "Date/time" ylab "#Items" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nkbytes per $keytype averaged per page by script - $period" \
              x date y nkbytes xlab "Date/time" ylab "#kbytes" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    $r query "select c.date, c.$keytype, sum(c.loadtime)/n.number loadtime2, sum(c.nitems)/n.number nitems2,
                     sum(c.nkbytes)/n.number nkbytes2
              from (              
                select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/r.npages loadtime,
                       1.0*sum(s.avg_nitems) nitems, 1.0*sum(s.avg_nkbytes) nkbytes
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = '$keytype' $where_extra
                and s.date_cet > '[period2startdate $period]'
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              group by 1,2"
    $r qplot title "Sum of load times per $keytype averaged per page and script - $period" \
              x date y loadtime2 xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    
    $r qplot title "Sum of nitems per $keytype averaged per page and script - $period" \
              x date y nitems2 xlab "Date/time" ylab "#items" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nkbytes per $keytype averaged per page and script - $period" \
              x date y nkbytes2 xlab "Date/time" ylab "#kbytes" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    # 2014-02-22 also #items and nkbytes here
    
  }
}

proc graph_combined_aggrsub_keytype_old {r dargv period keytype} {
  if {[period2days $period] >= 7} {
    $r query "select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/r.npages loadtime,
                     1.0*sum(s.avg_nitems) nitems, 1.0*sum(s.avg_nkbytes) nkbytes
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
              where s.keytype = '$keytype'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2,3"
    $r qplot title "Sum of load times per $keytype averaged per page by script - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nitems per $keytype averaged per page by script - $period" \
              x date y nitems xlab "Date/time" ylab "#Items" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nkbytes per $keytype averaged per page by script - $period" \
              x date y nkbytes xlab "Date/time" ylab "#kbytes" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    $r query "select c.date, c.$keytype, sum(c.loadtime)/n.number loadtime2, sum(c.nitems)/n.number nitems2,
                     sum(c.nkbytes)/n.number nkbytes2
              from (              
                select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/r.npages loadtime,
                       1.0*sum(s.avg_nitems) nitems, 1.0*sum(s.avg_nkbytes) nkbytes
                from aggr_sub s join aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
                where s.keytype = '$keytype'
                and s.date_cet > '[period2startdate $period]'
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              group by 1,2"
    $r qplot title "Sum of load times per $keytype averaged per page and script - $period" \
              x date y loadtime2 xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    
    $r qplot title "Sum of nitems per $keytype averaged per page and script - $period" \
              x date y nitems2 xlab "Date/time" ylab "#items" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r qplot title "Sum of nkbytes per $keytype averaged per page and script - $period" \
              x date y nkbytes2 xlab "Date/time" ylab "#kbytes" \
              geom line-point colour $keytype \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              maxcolours 10 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
    # 2014-02-22 also #items and nkbytes here
    
  }
}

# goal: show time per domain and per content-type for (only) dealer locator pages.
# maybe later for all pagetypes en keytype's, but could be a lot.
proc graph_combined_dealerlocator {r dargv period} {
  if {[period2days $period] >= 7} {
    set pagetype "dealerloc"
    
    # overview dealerloc pages per script - one colour per script
    $r query "select date_cet date, scriptname, sum(avg_time_sec) avg_time_sec
              from aggr_page 
              where date_cet > '[period2startdate $period]'
              and datacount > 0
              and page_type = '$pagetype'
              group by 1,2
              order by 1,2"
    $r qplot title "Average daily page loading for $pagetype by script - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour scriptname \
              width 11 height 7 \
              legend {avgtype avg avgdec 3 position right direction vertical}
    
    foreach keytype {domain content_type} {
      $r query "select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec) loadtime,
                       1.0*sum(s.avg_nitems) nitems, 1.0*sum(s.avg_nkbytes) nkbytes
                from aggr_sub s 
                  join aggr_page p on p.date_cet = s.date_cet and p.scriptname = s.scriptname and p.page_seq = s.page_seq
                where s.keytype = '$keytype'
                and p.page_type = '$pagetype'
                and s.date_cet > '[period2startdate $period]'
                group by 1,2,3"
                
      set ylabs [dict create loadtime "Load time (sec)" nitems "#Items" nkbytes "#kbytes"]                
      foreach valuetype {loadtime nitems nkbytes} {
        $r qplot title "Sum of $valuetype per $keytype for $pagetype by script - $period" \
                  x date y $valuetype xlab "Date/time" ylab [dict_get $ylabs $valuetype] \
                  geom line-point colour $keytype facet scriptname \
                  width 11 height {min 7 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                  maxcolours 10 \
                  legend {avgtype avg avgdec 3 position right direction vertical}
      }
    }
    
    # slow items. Binnen paar sec klaar, staat 1 URL op www.philips.com.cn: wrb_retail_...
    $r query "select m.scriptname, m.date_cet date, substr(m.keyvalue,1,100) url, 1.0*sum(m.avg_page_sec) loadtime
              from aggr_slowitem m 
                join aggr_page p on p.date_cet = m.date_cet and p.scriptname = m.scriptname and p.page_seq = m.page_seq
              where m.keytype = 'urlnoparams'
              and p.page_type = '$pagetype'
              and m.date_cet > '[period2startdate $period]'
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                  join aggr_page p on p.date_cet = m2.date_cet and p.scriptname = m2.scriptname and p.page_seq = m2.page_seq
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                and p.page_type = '$pagetype'
                group by 1
                having 1.0*sum(m2.avg_page_sec)/
                    ((select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
              )
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Slow URLs for $pagetype by script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical    
    
    # slow items only www.philips.com.cn
    # query duurt heel lang, wel vaag, zou net zo moeten gaan als orig query
    set domain "www.philips.com.cn"
    $r query "select m.scriptname, m.date_cet date, substr(m.keyvalue,1,100) url, 1.0*sum(m.avg_page_sec) loadtime
              from aggr_slowitem m 
                join aggr_page p on p.date_cet = m.date_cet and p.scriptname = m.scriptname and p.page_seq = m.page_seq
              where m.keytype = 'urlnoparams'
              and p.page_type = '$pagetype'
              and m.date_cet > '[period2startdate $period]'
              and m.keyvalue like '%${domain}%'
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                  join aggr_page p on p.date_cet = m2.date_cet and p.scriptname = m2.scriptname and p.page_seq = m2.page_seq
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                and p.page_type = '$pagetype'
                and m2.keyvalue like '%${domain}%'
                group by 1
                having 1.0*sum(m2.avg_page_sec)/
                    ((select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
              )
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Slow URLs for $pagetype by script for $domain - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical    
              
     # zelfde graph zonder pagetype te gebruiken, nog niet goed gevuld voor andere landen.
     # dan wel URL specifiek checken.
    set domain "www.philips.com.cn"
    #set url1 "http://www.philips.com.cn/c/locators/location.form"
    #set url2 "http://www.philips.com.cn/c/locators/wrb_retail_store_locator_results.jsp?"
    set url1 "/c/locators/location.form"
    set url2 "/c/locators/wrb_retail_store_locator_results.jsp?"
    
    $r query "select m.scriptname, m.date_cet date, substr(m.keyvalue,1,100) url, 1.0*sum(m.avg_page_sec) loadtime
              from aggr_slowitem m 
              where m.keytype = 'urlnoparams'
              and m.date_cet > '[period2startdate $period]'
              and m.keyvalue like '%${domain}%'
              and (m.keyvalue like '%$url1' or m.keyvalue like '%$url2')
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                and m2.keyvalue like '%${domain}%'
                group by 1
                having 1.0*sum(m2.avg_page_sec)/
                    ((select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
              )
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Slow URLs for $pagetype by script for $domain - $period (2)" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical    
     
              
  }  
}

proc graph_combined_dealerlocator2 {r dargv period} {
  if {[period2days $period] >= 7} {
    set pagetype "dealerloc"
    # set domain "www.philips.com.cn"
    set domain [:domain $dargv]
    set url1 "/c/locators/location.form"
    set url2 "/c/locators/wrb_retail_store_locator_results.jsp?"
    
    $r query "select m.scriptname, m.date_cet date, substr(m.keyvalue,1,100) url, 1.0*sum(m.avg_page_sec) loadtime
              from aggr_slowitem m 
              where m.keytype = 'urlnoparams'
              and m.date_cet > '[period2startdate $period]'
              and m.keyvalue like '%${domain}%'
              and (m.keyvalue like '%$url1' or m.keyvalue like '%$url2')
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                and m2.keyvalue like '%${domain}%'
                and (m2.keyvalue like '%$url1' or m2.keyvalue like '%$url2')
                group by 1
              )
              group by 1,2,3
              order by m.date_cet"
              
    $r qplot title "Slow URLs for $pagetype by script for $domain - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical    
  }
}  
  

proc graph_combined_peritem {r dargv period} {
  set keytype "domain"
  set keyvalue "images.philips.com"
  if {[period2days $period] >= 7} {
    $r dbexec "drop view if exists vaggr_loadtime_per_item"
    $r dbexec "create view vaggr_loadtime_per_item as
               select s.scriptname, s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/sum(s.avg_nitems) loadtime_item,
                      1.0*sum(s.avg_time_sec)/sum(s.avg_nkbytes) loadtime_kbyte
               from aggr_sub s 
               where s.keytype = '$keytype'
               and s.keyvalue = '$keyvalue'
               and s.date_cet > '[period2startdate $period]'
               group by 1,2,3"

    $r query "select * from vaggr_loadtime_per_item"
    $r qplot title "Load time per item for $keytype averaged per page by script - $period" \
              x date y loadtime_item xlab "Date/time" ylab "Load time per item (seconds)" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
    $r qplot title "Load time per kbyte for $keytype averaged per page by script - $period" \
              x date y loadtime_kbyte xlab "Date/time" ylab "Load time per kbyte (seconds)" \
              geom line-point colour $keytype facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical

    # view heeft voor summary hier minder zin, weer oorspronkelijke data gebruiken.
    $r query "select s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/sum(s.avg_nitems) loadtime_item,
                      1.0*sum(s.avg_time_sec)/sum(s.avg_nkbytes) loadtime_kbyte
               from aggr_sub s 
               where s.keytype = '$keytype'
               and s.keyvalue = '$keyvalue'
               and s.date_cet > '[period2startdate $period]'
               group by 1,2"
    $r qplot title "Load time per item for $keytype averaged per page per script - $period" \
              x date y loadtime_item xlab "Date/time" ylab "Load time per item (seconds)" \
              geom line-point colour $keytype \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
    $r qplot title "Load time per kbyte for $keytype averaged per page per script - $period" \
              x date y loadtime_kbyte xlab "Date/time" ylab "Load time per kbyte (seconds)" \
              geom line-point colour $keytype \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
  }
  # @todo:
  # width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 
  # ook kunnen opgeven als:
  # width 11 height {min 7 max 20 base 3.4 percolour 0.24 perfacet 1.7}
  # dit dan vertalen naar bovenstaande, dus door puntjes erbij. Soort with-statement wordt het dan.
  # voor legend iets vergelijkbaars.
              
}

proc graph_combined_slowitem {r dargv period} {
  #$db add_tabledef aggr_slowitem {id} {date_cet scriptname {page_seq int} keytype keyvalue {seqnr int} \
  # {avg_page_sec real} {avg_loadtime_sec real} {nitems int}} 

  if {[period2days $period] >= 7} {  
    # @todo 24-11-2013 toch iets met temp tables: huidige oplossing is te monolitisch, niet DRY en te complex.
    # temp table maken met iets als onderstaands:
    # keuze tables in R of in Tcl maken.
    # * tcl: voordeel: weet hoe het moet, nadeel: andere DB connectie.
    # * R: nog even uitzoeken, maar dan wel in dezelfde connectie dus.
    # rs <- dbSendQuery(con, "delete * from PURGE as p where p.wavelength<0.03")
    # @note 24-11-2013 noodzaak nu iets minder, want beide onderstaande tabellen geven wel hetzelfde resultaat in de legend-values.
    #$r execquery "drop table if exists temp1"
    #$r execquery "create table temp1 as                   subselect"
    
    # @todo nog eens count(distinct) met nscripts doen, staat nu alleen in having clause, dus niet zo belangrijk.
    $r query "select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
              from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
              where m.keytype = 'urlnoparams'
              and m.date_cet > '[period2startdate $period]'
              and 1*m.avg_page_sec > 0
              and 1*r.npages > 0
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                  join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                group by 1
                having 1.0*sum(m2.avg_page_sec)/
                    (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
              )
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Slow URLs averaged per page by script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical maxchars 120} \
              maxcolours 15
              
    # use the main query above as a subquery here to aggregate over all scripts.
    # @todo nog eens count(distinct) met nscripts doen, staat nu alleen in having clause, dus niet zo belangrijk.
    $r query "select c.date, c.url url, sum(c.loadtime)/n.number loadtime2 from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
                from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
                and m.date_cet > '[period2startdate $period]'
                and 1*m.avg_page_sec > 0
                and 1*r.npages > 0
                and m.keyvalue in (
                  select keyvalue
                  from aggr_slowitem m2 
                    join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                  where m2.date_cet > '[period2startdate $period]'
                  and m2.keytype = 'urlnoparams'
                  group by 1
                  having 1.0*sum(m2.avg_page_sec)/
                      (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
                  )
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              where 1*c.loadtime > 0
              and 1*n.number > 0
              group by 1,2
              order by date"

    # legend.avg 3 => add averages of values to legend-colours rounded to 3 decimals.
    $r qplot title "Slow URLs averaged per page and script - $period" \
              x date y loadtime2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical maxchars 120} \
              maxcolours 15
              
    # 27-1-2014 temporary also graphs for landing page and (other) ATG items wrt 2 MyPhilips changes.
    $r query "select c.date, c.url url, sum(c.loadtime)/n.number loadtime2 from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
                from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
                and m.date_cet > '[period2startdate $period]'
                and 1*m.avg_page_sec > 0
                and 1*r.npages > 0
                and m.keyvalue in (
                  select keyvalue
                  from aggr_slowitem m2 
                    join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                  where m2.date_cet > '[period2startdate $period]'
                  and m2.keytype = 'urlnoparams'
                  and m2.keyvalue like '%secure.philips.%'
                  group by 1
                  having 1.0*sum(m2.avg_page_sec)/
                      (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
                  )
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              where 1*c.loadtime > 0
              and 1*n.number > 0
              group by 1,2
              order by date"

    # legend.avg 3 => add averages of values to legend-colours rounded to 3 decimals.
    $r qplot title "Slow URLs averaged per page and script - ATG - $period" \
              x date y loadtime2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical maxchars 120} \
              maxcolours 15
    
  }
}

proc graph_combined_slowitem_old {r dargv period} {
  #$db add_tabledef aggr_slowitem {id} {date_cet scriptname {page_seq int} keytype keyvalue {seqnr int} \
  # {avg_page_sec real} {avg_loadtime_sec real} {nitems int}} 

  if {[period2days $period] >= 7} {  
    # @todo 24-11-2013 toch iets met temp tables: huidige oplossing is te monolitisch, niet DRY en te complex.
    # temp table maken met iets als onderstaands:
    # keuze tables in R of in Tcl maken.
    # * tcl: voordeel: weet hoe het moet, nadeel: andere DB connectie.
    # * R: nog even uitzoeken, maar dan wel in dezelfde connectie dus.
    # rs <- dbSendQuery(con, "delete * from PURGE as p where p.wavelength<0.03")
    # @note 24-11-2013 noodzaak nu iets minder, want beide onderstaande tabellen geven wel hetzelfde resultaat in de legend-values.
    #$r execquery "drop table if exists temp1"
    #$r execquery "create table temp1 as                   subselect"
    
    # @todo nog eens count(distinct) met nscripts doen, staat nu alleen in having clause, dus niet zo belangrijk.
    $r query "select m.scriptname, m.date_cet date, substr(m.keyvalue,1,120) url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
              from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
              where m.keytype = 'urlnoparams'
              and m.date_cet > '[period2startdate $period]'
              and 1*m.avg_page_sec > 0
              and 1*r.npages > 0
              and m.keyvalue in (
                select keyvalue
                from aggr_slowitem m2 
                  join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                where m2.date_cet > '[period2startdate $period]'
                and m2.keytype = 'urlnoparams'
                group by 1
                having 1.0*sum(m2.avg_page_sec)/
                    (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
              )
              group by 1,2,3
              order by m.date_cet"
    $r qplot title "Slow URLs averaged per page by script - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet scriptname \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical} \
              maxcolours 15
              
    # use the main query above as a subquery here to aggregate over all scripts.
    # @todo nog eens count(distinct) met nscripts doen, staat nu alleen in having clause, dus niet zo belangrijk.
    $r query "select c.date, substr(c.url,1,120) url, sum(c.loadtime)/n.number loadtime2 from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
                from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
                and m.date_cet > '[period2startdate $period]'
                and 1*m.avg_page_sec > 0
                and 1*r.npages > 0
                and m.keyvalue in (
                  select keyvalue
                  from aggr_slowitem m2 
                    join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                  where m2.date_cet > '[period2startdate $period]'
                  and m2.keytype = 'urlnoparams'
                  group by 1
                  having 1.0*sum(m2.avg_page_sec)/
                      (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
                  )
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              where 1*c.loadtime > 0
              and 1*n.number > 0
              group by 1,2
              order by date"

    # legend.avg 3 => add averages of values to legend-colours rounded to 3 decimals.
    $r qplot title "Slow URLs averaged per page and script - $period" \
              x date y loadtime2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical} \
              maxcolours 15
              
    # 27-1-2014 temporary also graphs for landing page and (other) ATG items wrt 2 MyPhilips changes.
    $r query "select c.date, substr(c.url,1,120) url, sum(c.loadtime)/n.number loadtime2 from (
                select m.scriptname, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec)/r.npages loadtime
                from aggr_slowitem m join aggr_run r on m.date_cet = r.date_cet and m.scriptname = r.scriptname
                where m.keytype = 'urlnoparams'
                and m.date_cet > '[period2startdate $period]'
                and 1*m.avg_page_sec > 0
                and 1*r.npages > 0
                and m.keyvalue in (
                  select keyvalue
                  from aggr_slowitem m2 
                    join aggr_run r on m2.date_cet = r.date_cet and m2.scriptname = r.scriptname
                  where m2.date_cet > '[period2startdate $period]'
                  and m2.keytype = 'urlnoparams'
                  and m2.keyvalue like '%secure.philips.%'
                  group by 1
                  having 1.0*sum(m2.avg_page_sec)/
                      (r.npages*(select count(distinct scriptname) from aggr_run)*(select count(distinct date_cet) from aggr_run where date_cet > '[period2startdate $period]')) > 0.05
                  )
                group by 1,2,3) c join nscripts n on n.date_cet = c.date
              where 1*c.loadtime > 0
              and 1*n.number > 0
              group by 1,2
              order by date"

    # legend.avg 3 => add averages of values to legend-colours rounded to 3 decimals.
    $r qplot title "Slow URLs averaged per page and script - ATG - $period" \
              x date y loadtime2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url \
              width 11 height {min 5 max 20 base 3.4 perfacet 1.7 percolour 0.24} \
              legend {avgdec 3 avgtype sum position bottom direction vertical} \
              maxcolours 15
    
  }
}
proc graph_combined_gt3 {r dargv period} {
  if {[period2days $period] >= 7} {  
    if {[period2days $period] <= 50} {  
      # first the general one.
      $r query "select a.date date, a.topdomain topdomain, sum(a.avg_page_sec) / n.number avg_page_sec2
                from (select i.date_cet date, topdomain, i.scriptname, 0.001*sum(i.element_delta)/(r.datacount*r.npages) avg_page_sec,
                  0.001*sum(i.element_delta), r.datacount, r.npages
                from pageitem_gt3 i join aggr_run r on r.date_cet = i.date_cet and r.scriptname = i.scriptname
                where i.date_cet >= '[period2startdate $period]'
                group by 1,2,3) a join nscripts n on n.date_cet = a.date
                group by 1,2
                having avg_page_sec2 > 0.1"
      $r qplot title "Items longer than 3 sec averaged per page and script by topdomain - $period" \
              x date y avg_page_sec2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour topdomain \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
      $r query "select a.date date, a.extension extension, sum(a.avg_page_sec) / n.number avg_page_sec2
                from (select i.date_cet date, extension, i.scriptname, 0.001*sum(i.element_delta)/(r.datacount*r.npages) avg_page_sec,
                  0.001*sum(i.element_delta), r.datacount, r.npages
                from pageitem_gt3 i join aggr_run r on r.date_cet = i.date_cet and r.scriptname = i.scriptname
                where i.date_cet >= '[period2startdate $period]'
                group by 1,2,3) a join nscripts n on n.date_cet = a.date
                group by 1,2
                having avg_page_sec2 > 0.1"
      $r qplot title "Items longer than 3 sec averaged per page and script by extension - $period" \
              x date y avg_page_sec2 xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour extension \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

      $r query "select a.date, a.functiontype, sum(a.avg_page_sec) / n.number avg_page_sec2
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
                group by 1,2,3) a join nscripts n on n.date_cet = a.date
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

# Show influence of different pagetypes (mostly useful for CBF scripts
proc graph_combined_pagetype {r dargv period} {
  if {[period2days $period] >= 7} {  
    $r query "select a.date_cet date, a.page_type, sum(a.avg_time_sec) / n.number avg_time_sec
              from aggr_page a join nscripts n on n.date_cet = a.date_cet
              where a.date_cet > '[period2startdate $period]'
              and a.datacount > 0
              group by 1,2
              order by 1,2"
    $r qplot title "Average daily page loading per pagetype and script - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour page_type \
              width 11 height.min 7 height.max 20 height.base 3.4 height.percolour 0.24 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r query "select date_cet date, scriptname, page_type, sum(avg_time_sec) avg_time_sec
              from aggr_page 
              where date_cet > '[period2startdate $period]'
              and datacount > 0
              group by 1,2,3
              order by 1,2,3"
    $r qplot title "Average daily page loading per pagetype by script - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour page_type facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    
    $r query "select date_cet date, scriptname, page_seq || '-' || page_type page_type, sum(avg_time_sec) avg_time_sec
              from aggr_page 
              where date_cet > '[period2startdate $period]'
              and datacount > 0
              group by 1,2,3
              order by 1,2,3"
    $r qplot title "Average daily page loading per pagetype (seq) by script - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour page_type facet scriptname \
              width 11 height.min 7 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
  }
}
