#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL/CBF-CN-SCF683" "Directory to make graphs for/in (in daily/graphs)"}
    {dbname.arg "keynotelogs.db" "DB name within dir to use"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set r [Rwrapper new $dargv]
  $r main {
    graph_all_cachehit $r $dargv
    graph_all_nslowitems_both $r $dargv
    foreach domain {images.philips.com www.philips.com.cn} {
      graph_all_network $r $dargv $domain
      graph_all_nips $r $dargv $domain
      graph_all_distr $r $dargv $domain
      graph_all_nslowitems $r $dargv $domain
      graph_spec_loadtimes $r $dargv $domain
    }
  }
}

# @todo mss domain-dynamic gebruiken, en deze er dan juist vanaf trekken. Wil alleen static items.
proc graph_all_cachehit {r dargv} {
  $r dbexec "drop view if exists s7_nitems_all"
  $r dbexec "create view s7_nitems_all as
              select date_cet, sum(avg_nitems) avg_nitems_all from aggr_sub
              where keyvalue = 'images.philips.com'
              and keytype = 'domain'
              group by 1"
  $r dbexec "drop view if exists s7_nitems_fast"
  # Deze 30 msec heb ik wel meer gebruikt, is wel ok.
  $r dbexec "create view s7_nitems_fast as
              select r.date_cet, 1.0*count(i.id)/r.datacount avg_nitems_fast
              from pageitem i join aggr_run r on r.date_cet = i.date_cet
              where i.domain = 'images.philips.com'
              and 1*i.first_packet_delta <= 30
              group by 1"
  $r query "select a.date_cet date, a.avg_nitems_all, f.avg_nitems_fast, 100.0*f.avg_nitems_fast/a.avg_nitems_all cachehit
            from s7_nitems_all a join s7_nitems_fast f on a.date_cet = f.date_cet
            where a.date_cet < date('now')
            order by 1"
  $r qplot title "Scene7 cachehit ratio" \
            x date y cachehit xlab "Date" ylab "Cache hit ratio (%)" \
            geom line \
            width 11 height 6
}

proc graph_all_network {r dargv domain} {
  $r query "select i.date_cet date, 
              avg(0.001*i.element_delta) loadtime,
              avg(0.001*i.dns_delta) dnstime,
              avg(0.001*i.connect_delta) connecttime,
              avg(0.001*i.ssl_handshake_delta) ssltime,
              avg(0.001*i.request_delta) reqtime,
              avg(0.001*i.first_packet_delta) ttfb,
              avg(0.001*i.remain_packets_delta) ttlb,
              avg(0.001*system_delta) clienttime
              from pageitem i
              where i.domain = '$domain'
              and date_cet < date('now')
              and i.url not like '%&_=13%'
              group by 1
              order by 1"
  $r melt {loadtime dnstime connecttime ssltime reqtime ttfb ttlb
           clienttime}
  $r qplot title "Network times $domain by network part" \
                x date y value xlab "Date" ylab "Network time (seconds)" \
                geom line-point colour variable \
                width 11 height 8 \
                legend.avg 3 \
                legend.position right \
                legend.direction vertical
}

proc graph_all_nips {r dargv domain} {
  $r query "select i.date_cet date, count(distinct i.ip_address) nips
            from pageitem i
            where i.domain = '$domain'
            and date_cet < date('now')
            and i.url not like '%&_=13%'
            group by 1
            order by 1"
  $r qplot title "Number of different $domain IP addresses per day" \
                x date y nips xlab "Date" ylab "#different IP addresses" \
                geom line  \
                width 11 height 6
            
}

proc graph_all_distr {r dargv domain} {
  $r query "select i.ts_cet ts, 0.001*element_delta loadtime_sec
            from pageitem i
            where i.domain = '$domain'
            and i.date_cet < date('now')
            and i.url not like '%&_=13%'
            order by 1"
  # $r boxplot "...."
  $r myplot title "Distribution of $domain item loadtimes" \
    xlab "Date" ylab "Load time (sec, log-scale)" \
    width 11 height 9 \
    cmds "p = ggplot(df.plot, aes(x=ts_psx, y = loadtime_sec, group = round_any(ts_psx, 86400, floor))) + geom_boxplot() + scale_y_log10()"
  
}

proc graph_all_nslowitems {r dargv domain} {
  foreach treshold {0.5 1.0} {
    # wat uitschieters af en toe: per URL aantal keren dat 'ie boven de hele of halve seconde zit.
    $r query "select date_cet date, count(*) ntimes
              from pageitem
              where domain = '$domain'
              and 0.001*element_delta > $treshold
              and date_cet < date('now')
              and url not like '%&_=13%'
              group by 1"
    $r qplot title "#times loading time more than $treshold sec per day for all $domain items" \
                x date y ntimes xlab "Date" ylab "#times above $treshold sec." \
                geom line \
                width 11 height 8
  }                  
}

proc graph_all_nslowitems_both {r dargv} {
  foreach treshold {0.5 1.0} {
    # wat uitschieters af en toe: per URL aantal keren dat 'ie boven de hele of halve seconde zit.
    $r query "select date_cet date, domain, count(*) ntimes
              from pageitem
              where domain in ('images.philips.com', 'www.philips.com.cn')
              and 0.001*element_delta > $treshold
              and date_cet < date('now')
              and url not like '%&_=13%'
              group by 1,2"
    $r qplot title "#times loading time more than $treshold sec per day for all items in 2 domains" \
                x date y ntimes xlab "Date" ylab "#times above $treshold sec." \
                colour domain \
                geom line-point \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction horizontal} \
  }                  
}

# @todo niet huidige dag meenemen, vertekent het beeld.
proc graph_spec_loadtimes {r dargv domain} {
  $r query "select date_cet date, urlnoparams url, avg(0.001*element_delta) loadtime_sec, avg(0.001*content_bytes) nkbytes
            from pageitem
            where domain = '$domain'
            and date_cet < date('now')
            and url not like '%&_=13%'
            group by 1,2"
  $r qplot title "Loading times $domain top items" \
                x date y loadtime_sec xlab "Date" ylab "Load time (seconds)" \
                geom line-point colour url \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction vertical} \
                maxcolours 15
  $r qplot title "Item sizes $domain top items" \
                x date y nkbytes xlab "Date" ylab "#kilobytes" \
                geom line-point colour url \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction vertical} \
                maxcolours 15

  $r query "select date_cet date, url url, avg(0.001*element_delta) loadtime_sec, avg(0.001*content_bytes) nkbytes
            from pageitem
            where domain = '$domain'
            and date_cet < date('now')
            and url not like '%&_=13%'
            group by 1,2"
  $r qplot title "Loading times $domain top items (2)" \
                x date y loadtime_sec xlab "Date" ylab "Load time (seconds)" \
                geom line-point colour url \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction vertical} \
                maxcolours 15
  $r qplot title "Item sizes $domain top items (2)" \
                x date y nkbytes xlab "Date" ylab "#kilobytes" \
                geom line-point colour url \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction vertical} \
                maxcolours 15
                
  foreach treshold {0.5 1.0} {
    # wat uitschieters af en toe: per URL aantal keren dat 'ie boven de hele of halve seconde zit.
    $r query "select date_cet date, urlnoparams url, count(*) ntimes
              from pageitem
              where domain = '$domain'
              and 0.001*element_delta > $treshold
              and date_cet < date('now')
              and url not like '%&_=13%'
              group by 1,2"
    $r qplot title "#times loading time more than $treshold sec per day for specific $domain items" \
                x date y ntimes xlab "Date" ylab "#times above $treshold sec." \
                geom line-point colour url \
                width 11 height 8 \
                legend {avgtype avg avgdec 3 position bottom direction vertical} \
                maxcolours 15
  }                  
}

main $argv
