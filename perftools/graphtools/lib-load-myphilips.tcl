proc make_graphs_myphilips {dargv} {
  make_graphs_myphilips_dir [file join [:rootdir $dargv] "MyPhilips-BR"] $dargv
}
  
proc make_graphs_myphilips_dir {dir dargv} {  
  # cloudfront, only for BR now.
  set scriptname [file tail $dir]
  set r [Rwrapper new $dargv]
  $r init $dir keynotelogs.db
  $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]

  # @note 2013-10-01 was even voor Hakim.
  # and date_cet >= '2013-10-01'
  $r query "select i.date_cet date, l.location location, count(*) number, avg(0.001*i.element_delta) loadtime, avg(0.001*(i.element_delta-i.system_delta)) loadtime_nc
            from pageitem i 
              left join location l on i.ip_address like l.ip_range
            where i.topdomain = 'cloudfront.net'
            and i.ts_cet < (select max(date_cet) from scriptrun)
            and 1*i.page_seq = 1
            group by 1, 2"

  $r qplot title "$scriptname - Average loadtime for Cloudfront elements per location" \
            x date y loadtime xlab "Date" ylab "Load time (seconds)" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal
            
  $r qplot title "$scriptname - Average loadtime (excl client time) for Cloudfront elements per location" \
            x date y loadtime_nc xlab "Date" ylab "Load time (seconds)" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal

  $r qplot title "$scriptname - Daily #items for Cloudfront elements per location" \
            x date y number xlab "Date" ylab "Daily #items" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal

  $r doall
  $r cleanup
  $r destroy  
  
}
