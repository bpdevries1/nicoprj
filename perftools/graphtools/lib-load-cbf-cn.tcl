# specific graph to determine dynamicity of imagelist content/calls. Only used for CBF-CN.
proc graph_combined_imagelist {r dargv period} {
  # daily averages.
  # number of items - per run
  if {[period2days $period] >= 7} { 
    # first average content_bytes per day per script.
    $r query "select scriptname, date_cet date, avg(1*content_bytes) avg_content_bytes
              from pageitem_topic
              where topic = 'CN-imagelist'
              and date_cet > '[period2startdate $period]'
              and status_code = '200'
              group by 1,2"
    $r qplot title "Daily average size of imagelist - $period" \
              x date y avg_content_bytes xlab "Date" ylab "Average content bytes" \
              geom line-point colour scriptname ymin 0 \
              width 11 height 7

    # also: min/max content_bytes, to show lack of variability, facet per script, line per min/max (avg?)
    $r query "select scriptname, date_cet date, avg(1*content_bytes) avg_content_bytes,
                     min(1*content_bytes) min_content_bytes, max(1*content_bytes) max_content_bytes
              from pageitem_topic
              where topic = 'CN-imagelist'
              and date_cet > '[period2startdate $period]'
              and status_code = '200'
              group by 1,2"
    $r melt {avg_content_bytes min_content_bytes max_content_bytes}              
    $r qplot title "Daily min-avg-max size of imagelist - $period" \
              x date y value xlab "Date" ylab "Average content bytes" \
              geom line-point colour variable facet scriptname ymin 0 \
              width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.0 height.perfacet 1.7 \
              legend.position bottom \
              legend.direction horizontal
              
    # 27-11-2013 extra aggr tabel met echte overhead hiervan, stelling is (vanuit CN) dat het asynchroon is en dus niet uitmaakt.
    $r query "select scriptname, date_cet date, per_page_sec
              from aggr_specific
              where date_cet > '[period2startdate $period]'
              and topic = 'imagelist-overhead'"
    $r qplot title "Daily average overhead of imagelist by script - $period" \
              x date y per_page_sec xlab "Date" ylab "Average overhead (sec)" \
              geom line-point colour scriptname ymin 0 \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r query "select 'all' scriptname, a.date_cet date, sum(a.per_page_sec)/n.number per_page_sec
              from aggr_specific a join nscripts n on n.date_cet = a.date_cet
              where a.date_cet > '[period2startdate $period]'
              and a.topic = 'imagelist-overhead'
              group by 1,2"
    $r qplot title "Daily average overhead of imagelist per script - $period" \
              x date y per_page_sec xlab "Date" ylab "Average overhead (sec)" \
              geom line-point colour scriptname ymin 0 \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical

    $r query "select a.topic, a.date_cet date, sum(a.per_page_sec)/n.number per_page_sec
              from aggr_specific a join nscripts n on n.date_cet = a.date_cet
              where a.date_cet > '[period2startdate $period]'
              and a.topic <> 'imagelist-overhead'
              group by 1,2"
    $r qplot title "Daily average loading time of misc topics per script - $period" \
              x date y per_page_sec xlab "Date" ylab "Average overhead (sec)" \
              geom line-point colour topic ymin 0 \
              width 11 height 7 \
              legend.avg 3 \
              legend.position right \
              legend.direction vertical
              
  }
}

