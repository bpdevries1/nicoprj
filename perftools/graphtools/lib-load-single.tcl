proc graph_dashboard {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {  
    $r query "select date_cet date, page_time_sec, avg_nkbytes, avg_nitems 
              from aggr_run
              where date_cet > '[period2startdate $period]'
              and datacount > 0"
    # one generic graph per datatype, all in one graph with lines.
    $r qplot title "$scriptname - Average daily page loading times - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line \
              width 11 height 7 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
                          
    $r qplot title "$scriptname - Average daily #kilobytes - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              geom line \
              width 11 height 7 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "$scriptname - Average daily #items - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              geom line \
              width 11 height 7 
              
    # per page
    $r query "select date_cet date, 1*page_seq page_seq, avg_time_sec, avg_nkbytes, avg_nitems 
              from aggr_page
              where date_cet > '[period2startdate $period]'"
    # one generic graph per datatype, all in one graph with lines.
    # ymin 0 
    $r qplot title "$scriptname - Average daily page loading times by page - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              geom line-point colour page_seq \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
                          
    $r qplot title "$scriptname - Average daily #kilobytes by page - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              geom line-point colour page_seq \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical

    $r qplot title "$scriptname - Average daily #items by page - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              geom line-point colour page_seq \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
  } else {
    log debug "Period smaller than 1 week, no dashboard graphs"
    # @todo? show scatterplot instead, like Keynote does.
  }
}

proc graph_slowitem {r dir period} {
  log warn "slowitem: TODO"
}

proc graph_maxitem_old {r dir period} {
  # @todo use period
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    if {[period2days $period] <= 42} {
      # std maxitem graph vanuit aggr_maxitem tabel. Alleen items die in top20 van laatste dag vallen.
      # @todo? maybe better to create view, now have non-DRY code.
      $r query "select date_cet date, keyvalue url, avg_time_sec loadtime, 1*page_seq page_seq
                from aggr_maxitem m 
                where m.keytype = 'urlnoparams'
                and m.keyvalue in (
                  select a2.keyvalue
                  from aggr_maxitem a2
                  where a2.date_cet = (select max(date_cet) from aggr_run)
                  and a2.keytype = 'urlnoparams'
                )
                and m.date_cet > '[period2startdate $period]'
                order by m.date_cet"
      #  ymin 0
      $r qplot title "$scriptname - Max URLs by page - $period" \
                x date y loadtime xlab "Date" ylab "Load time (seconds)" \
                geom line-point colour url facet page_seq \
                width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.24 \
                legend.avg 3 \
                legend.position bottom \
                legend.direction vertical    
    
      # en deze ook averaged per page: zelf sum/npages doen, anders fout, als item op maar bv 2 pages staat.
      $r query "select m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
                from aggr_maxitem m 
                  join aggr_run r on m.date_cet = r.date_cet
                where m.keytype = 'urlnoparams'
                and m.keyvalue in (
                  select a2.keyvalue
                  from aggr_maxitem a2
                  where a2.date_cet = (select max(date_cet) from aggr_run)
                  and a2.keytype = 'urlnoparams'
                  and a2.seqnr <= 10
                )
                and m.date_cet > '[period2startdate $period]'
                group by 1,2
                order by url desc, m.date_cet"
      $r qplot title "$scriptname - Max URLs averaged per page - $period" \
                x date y loadtime xlab "Date" ylab "Load time (seconds)" \
                geom line-point colour url \
                width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 \
                legend.avg 3 \
                legend.position bottom \
                legend.direction vertical    
    
      # network times (connection, SSL) for max items
      # ssl_handshake_delta
      $r query "select i.date_cet date, i.page_seq page_seq, i.urlnoparams url, 
              avg(0.001*i.element_delta) loadtime,
              avg(0.001*i.dns_delta) dnstime,
              avg(0.001*i.connect_delta) connecttime,
              avg(0.001*i.ssl_handshake_delta) ssltime,
              avg(0.001*i.request_delta) reqtime,
              avg(0.001*i.first_packet_delta) firstpackettime,
              avg(0.001*i.remain_packets_delta) remainpacketstime,
              avg(0.001*system_delta) clienttime
              from pageitem i
                join aggr_maxitem m on i.urlnoparams = m.keyvalue
                       and m.page_seq = i.page_seq
              where m.date_cet = (select max(date_cet) from aggr_run)
              and i.date_cet > '[period2startdate $period]'
              group by 1,2,3
              order by 1,2,3"
      $r melt {loadtime dnstime connecttime ssltime reqtime firstpackettime 
               remainpacketstime clienttime}
      # NOT:url's op x-as, tijden op y-as, kleuren zijn netwerk-componenten.
      # data van meerdere dagen, dus dag op x, tijd op y. Kleur en facet gebruiken.
      # facet = component, is minder lang.
      # kleur = url
      $r qplot title "$scriptname - Network times Max URLs by network part - $period" \
                x date y value xlab "Date" ylab "Network time (seconds)" \
                geom point colour url facet variable \
                width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
                legend.avg 3 \
                legend.position bottom \
                legend.direction vertical
    } else {
      log debug "No max item graphs for period >6w"
    }
  } else {
    # max period 1 week: all points
    # @todo2 geeft deze nu de goede hoogte? vermoeden dat met geen facets deze mss op 0 staat en dan mss 1.7 eraf.
    $r query "select i.urlnoparams url, i.ts_cet ts, 0.001*i.element_delta loadtime
              from pageitem i 
                join aggr_maxitem m on i.urlnoparams = m.keyvalue
                     and m.page_seq = i.page_seq
              where m.date_cet = (select max(date_cet) from aggr_run)
              and i.date_cet > '[period2startdate $period]'"
              
    $r qplot title "$scriptname - Max URLs - $period" \
              x ts y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom point colour url \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 0.0 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
    $r qplot title "$scriptname - Max URLs by URL - $period" \
              x ts y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom point facet url \
              width 11 height 20
    # zelfde als vorige, maar dan alle punten.
    $r query "select i.ts_cet ts, i.urlnoparams url, 
            0.001*i.element_delta loadtime,
            0.001*i.dns_delta dnstime,
            0.001*i.connect_delta connecttime,
            0.001*i.ssl_handshake_delta ssltime,
            0.001*i.request_delta reqtime,
            0.001*i.first_packet_delta firstpackettime,
            0.001*i.remain_packets_delta remainpacketstime,
            0.001*system_delta clienttime
            from pageitem i
              join aggr_maxitem m on i.urlnoparams = m.keyvalue
                     and m.page_seq = i.page_seq
            where m.date_cet = (select max(date_cet) from aggr_run)
            and i.date_cet > '[period2startdate $period]'            
            order by 1,2"
    $r melt {loadtime dnstime connecttime ssltime reqtime firstpackettime 
             remainpacketstime clienttime}
    # NOT:url's op x-as, tijden op y-as, kleuren zijn netwerk-componenten.
    # data van meerdere dagen, dus dag op x, tijd op y. Kleur en facet gebruiken.
    # facet = component, is minder lang.
    # kleur = url
    $r qplot title "$scriptname - Network times Max URLs by URL - $period" \
              x ts y value xlab "Date/time" ylab "Network time (seconds)" \
              geom point colour url facet variable \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position bottom \
              legend.direction vertical
              
    # @note 13-11-2013 log-scale geeft nu foutmelding, dus even niet.            
              # extra "scale_y_log10()"
    # scale_y_log10(limits = c(1,1e8))            
  }
} 

# @todo bij facet: bepalen hoeveel facets er zijn en obv hiervan de hoogte van de graph: hight = constant1 + constant2 * #facets.
# @todo:
# - period => date > x opnemen.
# - als period < 1w (of in days uitgedrukt), dan niet summary per dag, maar scatterplot van alles.
# @note 23-11-2013 checked calc of times in graph wrt data in aggr_sub table, should be good: by page graph shows time for each page, 
#                  per page == by run shows divided by #pages.
proc graph_topdomain {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    $r query "select date_cet date, page_seq, keyvalue topdomain, avg_time_sec loadtime
              from aggr_sub
              where keytype = 'topdomain'
              and date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Sum of load times per topdomain by page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour topdomain facet page_seq \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    # ook summary over alles in 1 graph:
    $r query "select s.date_cet date, s.keyvalue topdomain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet
              where s.keytype = 'topdomain'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2"
    $r qplot title "$scriptname - Sum of load times per topdomain averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour topdomain \
              width 11 height 8 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    
  } else {
    log warn "TODO: make topdomain graph for individual measurements"
  }
}

proc graph_extension {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    $r query "select date_cet date, page_seq, keyvalue extension, avg_time_sec loadtime
              from aggr_sub
              where keytype = 'extension'
              and date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Sum of load times per extension by page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour extension facet page_seq \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
    
    $r query "select s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet
              where s.keytype = 'extension'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2"
    $r qplot title "$scriptname - Sum of load times per extension averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour extension \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
  } else {
    log warn "TODO: make extension graph for individual measurements"
  }
}

proc graph_aggrsub {r dir period} {
  # @todo check which keytypes occur in aggrsub, make graphs for each of those.
  # als je het ook maakt voor andere types, dan leteen op ':' in keytype/values, kan niet in filenames. Maar mss geen last van, als keytype simpel is.

  foreach keytype {topdomain extension domain content_type basepage aptimized cntype_apt domain_gt_100k domain_dynamic} {
    graph_aggrsub_keytype $r $dir $period $keytype
  }
}

proc graph_aggrsub_keytype {r dir period keytype} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    $r query "select date_cet date, page_seq, keyvalue $keytype, avg_time_sec loadtime
              from aggr_sub
              where keytype = '$keytype'
              and date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Sum of load times per $keytype by page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype facet page_seq \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              maxcolours 15 \
              legend {avgdec 3 avgtype sum position right direction vertical}
    
    $r query "select s.date_cet date, s.keyvalue $keytype, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet
              where s.keytype = '$keytype'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2"
    $r qplot title "$scriptname - Sum of load times per $keytype averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour $keytype \
              width 11 height 7 \
              maxcolours 15 \
              legend {avgdec 3 avgtype sum position right direction vertical}
  }
}

proc graph_ttip {r dir period} {
  set scriptname [file tail $dir]
  # breakpoint
  if {[period2days $period] >= 7} {  
    # @note where clause to not get R warnings like 1: Removed 3 rows containing missing values (geom_point). 
    $r query "select date_cet date, page_seq, avg_time_sec, avg_ttip_sec, avg_time_sec - avg_ttip_sec async_sec
              from aggr_page where avg_time_sec >= 0 and date_cet > '[period2startdate $period]'"
    $r melt {avg_time_sec avg_ttip_sec async_sec}
    $r qplot title "$scriptname - Total and TTIP times by page - $period" \
              x date y value \
              xlab "Date" ylab "Time (seconds)" \
              geom line-point colour variable \
              facet page_seq \
              legend.position right \
              legend.direction vertical \
              legend.avg 3 \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.0
  } else {
    # a scatterplot of all datapoints
    $r query "select ts_cet ts, 1.0*page_seq page_seq, 0.001 * delta_user_msec time_sec, 0.001 * time_to_interactive_page ttip_sec,
                0.001 * delta_user_msec - 0.001 * time_to_interactive_page async_sec
              from page
              where 0.001 * delta_user_msec >= 0
              and ts_cet > '[period2startdate $period]'"
    $r melt {time_sec ttip_sec async_sec}
    $r qplot title "$scriptname - Total and TTIP times - $period" \
              x ts y value \
              xlab "Date/time" ylab "Time (seconds)" \
              geom point colour variable \
              facet page_seq \
              legend.position right \
              legend.direction vertical \
              legend.avg 3 \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.0
    $r qplot title "$scriptname - Total and TTIP times - $period (logscale)" \
              x ts y value \
              xlab "Date/time" ylab "Time (seconds)" \
              geom point colour variable \
              facet page_seq \
              legend.position right \
              legend.direction vertical \
              legend.avg 3 \
              width 11 height.min 5 height.max 20 height.base 3.4 height.perfacet 1.7 height.percolour 0.0 \
              extra "scale_y_log10()"
  }
}

proc graph_domain {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    $r query "select date_cet date, page_seq, keyvalue domain, avg_time_sec loadtime
              from aggr_sub
              where keytype = 'domain'
              and date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Sum of load times per domain by page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour domain facet page_seq \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              legend {avgdec 3 avgtype sum position right direction vertical}
    # ook summary over alles in 1 graph:
    $r query "select s.date_cet date, s.keyvalue domain, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet
              where s.keytype = 'domain'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2"
    $r qplot title "$scriptname - Sum of load times per domain averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              geom line-point colour domain \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              legend {avgdec 3 avgtype sum position right direction vertical}
  } else {
    log warn "TODO: make domain graph for individual measurements"
  }
}

proc graph_slowitem {r dir period} {
  set scriptname [file tail $dir]
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
    $r query "select m.page_seq, m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_page_sec) loadtime
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
    $r qplot title "$scriptname - Slow URLs averaged by page - $period" \
              x date y loadtime xlab "Date" ylab "Load time (seconds)" \
              geom line-point colour url facet page_seq \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              maxcolours 10 \
              legend {avgdec 3 avgtype avg position bottom direction vertical maxchars 120}
  }
}

# voor testscripts soms nodig graphs te maken van tijd in het verleden.
# kan ook max tijd pakken en hier de period van af trekken.
# opties: 
# * einddatum meegeven.
# * einddatum zelf bepalen: hoe? scriptrun werkt altijd.
#
# dan hoe in query:
# * Eerst vanuit Tcl bepalen: kan zeker, mss nu goede aanleiding.
# * query wat ingewikkelder, en sqlite date-functies gebruiken.
proc graph_mobile {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] <= 3} {  
    $r query "select p.page_seq page, 0.001*page_bytes nkbytes, 0.001*delta_user_msec load_msec, 1*element_count nelts
              from page p, (select max(ts_cet) ts_cet_max from scriptrun) m
              where ts_cet > datetime(m.ts_cet_max, '[period2sqlite $period]')
              and 1*error_code=200
              and 1*content_errors = 0
              and 1*page_succeed = 1"
    $r qplot title "$scriptname - page load time vs page_bytes - $period" \
              x nkbytes y load_msec xlab "#kbytes" ylab "Load time (sec)" \
              geom point colour nelts facet page \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              legend {avgdec 3 avgtype avg position bottom direction vertical maxchars 120}

    $r query "select p.page_seq page, p.ts_cet ts, 0.001*p.page_bytes nkbytes, 0.001*p.delta_user_msec load_msec, r.agent_inst, r.profile_id, r.network
              from page p join scriptrun r on r.id = p.scriptrun_id, (select max(ts_cet) ts_cet_max from scriptrun) m
              where p.ts_cet > datetime(m.ts_cet_max, '[period2sqlite $period]')
              and 1*p.error_code=200
              and 1*p.content_errors = 0
              and 1*p.page_succeed = 1"
              
    foreach colour {agent_inst profile_id network} {
      $r qplot title "$scriptname - page load time vs page_bytes per $colour - $period" \
                x nkbytes y load_msec xlab "#kbytes" ylab "Load time (sec)" \
                geom point colour $colour facet page \
                width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                legend {avgdec 3 avgtype avg position bottom direction vertical maxchars 120}
      $r qplot title "$scriptname - page load time per $colour - $period" \
                x ts y load_msec xlab "Date/time" ylab "Load time (sec)" \
                geom point colour $colour facet page \
                width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                legend {avgdec 3 avgtype avg position bottom direction vertical maxchars 120}
    }
    $r qplot title "$scriptname - page weight per network - $period" \
              x ts y nkbytes xlab "Date/time" ylab "#kbytes" \
              geom point colour network facet page \
              width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
              legend {avgdec 3 avgtype avg position bottom direction vertical maxchars 120}
   
    # load times for all runs, not just the ones without errors
    $r query "select p.page_seq page, p.ts_cet ts, 0.001*p.page_bytes nkbytes, 0.001*p.delta_user_msec load_msec, r.agent_inst, r.profile_id, r.network
              from page p join scriptrun r on r.id = p.scriptrun_id, (select max(ts_cet) ts_cet_max from scriptrun) m
              where p.ts_cet > datetime(m.ts_cet_max, '[period2sqlite $period]')"
              
    foreach colour {agent_inst profile_id network} {
      $r qplot title "$scriptname - All - page load time vs page_bytes per $colour - $period" \
                x nkbytes y load_msec xlab "#kbytes" ylab "Load time (sec)" \
                geom point colour $colour facet page \
                width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                legend {avgtype avg avgdec 3 position right direction vertical}
      $r qplot title "$scriptname - All - page load time per $colour - $period" \
                x ts y load_msec xlab "Date/time" ylab "Load time (sec)" \
                geom point colour $colour facet page \
                width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                legend {avgtype avg avgdec 3 position right direction vertical}
    }
  }  
 
}

proc graph_avail_network {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {  
    $r query "select date_cet date, rs.network, round(1.0*count(rs.ts_cet)/
                (select count(ra.ts_cet)
                 from scriptrun ra 
                 where ra.date_cet = rs.date_cet
                 and ra.network = rs.network), 3) avail
              from scriptrun rs
              where 1*rs.task_succeed_calc = 1
              group by 1,2"
    $r qplot title "$scriptname - Availability per network - $period" \
                x date y avail xlab "Date" ylab "Availability" \
                geom line-point colour network \
                width 11 height {min 5 max 20 base 3.4 percolour 0.24 perfacet 1.7} \
                legend {avgtype avg avgdec 3 position right direction vertical}
  }
}
