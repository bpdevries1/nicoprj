proc graph_dashboard {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {  
    $r query "select date_cet date, page_time_sec, avg_nkbytes, avg_nitems 
              from aggr_run
              where date_cet > '[period2startdate $period]'"
    # one generic graph per datatype, all in one graph with lines.
    $r qplot title "$scriptname - Average daily page loading times - $period" \
              x date y page_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              ymin 0 geom line \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
                          
    $r qplot title "$scriptname - Average daily #kilobytes - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              ymin 0 geom line \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "$scriptname - Average daily #items - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              ymin 0 geom line \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
              
    # per page
    $r query "select date_cet date, 1*page_seq page_seq, avg_time_sec, avg_nkbytes, avg_nitems 
              from aggr_page
              where date_cet > '[period2startdate $period]'"
    # one generic graph per datatype, all in one graph with lines.
    $r qplot title "$scriptname - Average daily page loading times by page - $period" \
              x date y avg_time_sec xlab "Date/time" ylab "Page load time (seconds)" \
              ymin 0 geom line-point colour page_seq \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4
                          
    $r qplot title "$scriptname - Average daily #kilobytes by page - $period" \
              x date y avg_nkbytes xlab "Date/time" ylab "#kilobytes" \
              ymin 0 geom line-point colour page_seq \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4

    $r qplot title "$scriptname - Average daily #items by page - $period" \
              x date y avg_nitems xlab "Date/time" ylab "#items" \
              ymin 0 geom line-point colour page_seq \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 4  
  } else {
    log debug "Period smaller than 1 week, no dashboard graphs"
    # @todo? show scatterplot instead, like Keynote does.
  }
}

# @todo mss de netwerk grafieken alleen voor de laatste 2 weken doen, anders duurt het te lang en niet overzichtelijk.
# @todo '2013-11-01' and '2013-11-11' hardcoded now, change to 6w/2w/2d settings.
# moet soort tabel zijn met mapping welke grafieken voor welke periode wordt gemaakt.
# dan bv calls: make_graph_maxitem {all 6w 1w} 
proc graph_maxitem {r dir period} {
  # @todo use period
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    if {[period2days $period] <= 42} {
      # std maxitem graph vanuit aggr_maxitem tabel. Alleen items die in top20 van laatste dag vallen.
      $r query "select date_cet date, keyvalue url, avg_time_sec loadtime, 1*page_seq page_seq
                from aggr_maxitem
                where keytype = 'urlnoparams'
                and keyvalue in (
                  select a2.keyvalue
                  from aggr_maxitem a2
                  where a2.date_cet = (select max(date_cet) from aggr_run)
                  and a2.keytype = 'urlnoparams'
                )
                and date_cet > '[period2startdate $period]'
                order by date_cet"
      $r qplot title "$scriptname - Max items by page - $period" \
                x date y loadtime xlab "Date" ylab "Load time (seconds)" \
                ymin 0 geom line-point colour url facet page_seq \
                width 11 height 20 \
                legend.position bottom \
                legend.direction vertical    
    
      # en deze ook averaged per page: zelf sum/npages doen, anders fout, als item op maar bv 2 pages staat.
      $r query "select m.date_cet date, m.keyvalue url, 1.0*sum(m.avg_time_sec)/r.npages loadtime
                from aggr_maxitem m join aggr_run r on m.date_cet = r.date_cet
                where m.keytype = 'urlnoparams'
                and m.keyvalue in (
                  select a2.keyvalue
                  from aggr_maxitem a2
                  where a2.date_cet = (select max(date_cet) from aggr_run)
                  and a2.keytype = 'urlnoparams'
                )
                and m.date_cet > '[period2startdate $period]'
                group by 1,2
                order by m.date_cet"
      $r qplot title "$scriptname - Max items averaged per page - $period" \
                x date y loadtime xlab "Date" ylab "Load time (seconds)" \
                ymin 0 geom line-point colour url \
                width 11 height 8 \
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
      $r qplot title "$scriptname - Network times slow urls - 1 - $period" \
                x date y value xlab "Date" ylab "Network time (seconds)" \
                ymin 0 geom point colour url facet variable \
                width 11 height 20 \
                legend.position bottom \
                legend.direction vertical
    } else {
      log debug "No max item graphs for period >6w"
    }
  } else {
    # max period 1 week: all points
    $r query "select '\[' || round(avg_time_sec, 3) || 's\] ' || i.urlnoparams url, i.ts_cet ts, 0.001*i.element_delta loadtime
              from pageitem i 
                join aggr_maxitem m on i.urlnoparams = m.keyvalue
                     and m.page_seq = i.page_seq
              where m.date_cet = (select max(date_cet) from aggr_run)
              and i.date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Load times slow urls - 1 - $period" \
              x ts y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom point colour url \
              width 11 height 9 \
              legend.position bottom \
              legend.direction horizontal \
              legend.ncol 1
    $r qplot title "$scriptname - Load times slow urls - 2 - $period" \
              x ts y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom point facet url \
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
    $r qplot title "$scriptname - Network times slow urls - 2 - $period" \
              x ts y value xlab "Date/time" ylab "Network time (seconds)" \
              ymin 0 geom point colour url facet variable \
              width 11 height 20 \
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
proc graph_topdomain {r dir period} {
  set scriptname [file tail $dir]
  if {[period2days $period] >= 7} {
    $r query "select date_cet date, page_seq, keyvalue topdomain, avg_time_sec loadtime
              from aggr_sub
              where keytype = 'topdomain'
              and date_cet > '[period2startdate $period]'"
    $r qplot title "$scriptname - Sum of load times per topdomain by page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour topdomain facet page_seq \
              width 11 height 20 \
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
              ymin 0 geom line-point colour topdomain \
              width 11 height 8 \
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
              ymin 0 geom line-point colour extension facet page_seq \
              width 11 height 20 \
              legend.position right \
              legend.direction vertical
    
    $r query "select s.date_cet date, s.keyvalue extension, 1.0*sum(s.avg_time_sec)/r.npages loadtime
              from aggr_sub s join aggr_run r on s.date_cet = r.date_cet
              where s.keytype = 'extension'
              and s.date_cet > '[period2startdate $period]'
              group by 1,2"
    $r qplot title "$scriptname - Sum of load times per extension averaged per page - $period" \
              x date y loadtime xlab "Date/time" ylab "Load time (seconds)" \
              ymin 0 geom line-point colour extension \
              width 11 height 8 \
              legend.position right \
              legend.direction vertical
  } else {
    log warn "TODO: make extension graph for individual measurements"
  }
}
