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
    {dir.arg "c:/projecten/Philips/KNDL/CBF-US-RQ12-CN-PL-CQ5-Test" "Directory to make graphs for/in (in daily/graphs)"}
    {dbname.arg "keynotelogs.db" "DB name within dir to use"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {date.arg "2014-02-13" "Date of items to show info of"}
    {url.arg "http://images.philips.com/is/image/PhilipsConsumer/IM130930_TRANSPARENT_IMAGE-DTO-global-001?$pnglarge$" "URL to show info of"}
    {urlshort.arg "IM130930_TRANSPARENT_IMAGE-DTO" "Short name to use in graph filename/title"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set r [Rwrapper new $dargv]
  $r main {
    prepare_db $r $dargv "images.philips.com"
    graph_url_network $r $dargv
    graph_url_network $r [dict merge $dargv [dict create url "http://images.philips.com/is/image/PhilipsConsumer/RQ12_52-IMS-en_US?wid=460&hei=335&\$pngsmall\$" urlshort "RQ12_52-IMS-en_US"]]
    graph_allurls_network $r $dargv "images.philips.com"
    unprepare_db $r $dargv
    
    prepare_db $r $dargv "www.usa.philips.com"
    graph_allurls_network $r $dargv "www.usa.philips.com"
    unprepare_db $r $dargv
  }
  
}

proc prepare_db {r dargv domain} {
  set date [:date $dargv]
  set url [:url $dargv]
  $r dbexec "attach 'c:/projecten/Philips/KNDL/CBF-US-RQ12-DE-PL-CQ5-Test/keynotelogs.db' as de"
  $r dbexec "attach 'c:/projecten/Philips/KNDL/CBF-US-RQ12/keynotelogs.db' as us"
  $r dbexec "drop table if exists pageitem_combined"
  $r dbexec "create table pageitem_combined as
             select scriptname, date_cet, ts_cet, url, element_delta, dns_delta, connect_delta, ssl_handshake_delta, request_delta, first_packet_delta, remain_packets_delta, system_delta from pageitem
             where domain = '$domain'
             and date_cet = '$date'
             union all
             select scriptname, date_cet, ts_cet, url, element_delta, dns_delta, connect_delta, ssl_handshake_delta, request_delta, first_packet_delta, remain_packets_delta, system_delta from de.pageitem
             where domain = '$domain'
             and date_cet = '$date'
             union all
             select scriptname, date_cet, ts_cet, url, element_delta, dns_delta, connect_delta, ssl_handshake_delta, request_delta, first_packet_delta, remain_packets_delta, system_delta from us.pageitem
             where domain = '$domain'
             and date_cet = '$date'"
  
}

proc unprepare_db {r dargv} {
  $r dbexec "detach de"
  $r dbexec "detach us"
}

proc graph_url_network {r dargv} {
  # CBF-US-RQ12-CN-PL-CQ5-Test
  set date [:date $dargv]
  set url [:url $dargv]

  $r query "select i.scriptname scriptname, i.ts_cet ts, i.url url, 
            0.001*i.element_delta loadtime,
            0.001*i.dns_delta dnstime,
            0.001*i.connect_delta connecttime,
            0.001*i.ssl_handshake_delta ssltime,
            0.001*i.request_delta reqtime,
            0.001*i.first_packet_delta firstpackettime,
            0.001*i.remain_packets_delta remainpacketstime,
            0.001*system_delta clienttime
            from pageitem_combined i
            where i.date_cet = '$date'
            and url = '$url'
            order by 1,2,3"
  $r melt {loadtime dnstime connecttime ssltime reqtime firstpackettime 
           remainpacketstime clienttime}

  $r qplot title "Network times [:urlshort $dargv] by network part - $date" \
            x ts y value xlab "Date/time" ylab "Network time (seconds)" \
            geom point colour scriptname facet variable \
            width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
            legend.avg 3 \
            legend.position bottom \
            legend.direction vertical

}                

proc graph_allurls_network {r dargv domain} {
  set date [:date $dargv]
  set url [:url $dargv]

  $r query "select i.scriptname scriptname, i.ts_cet ts, 
            0.001*i.element_delta loadtime,
            0.001*i.dns_delta dnstime,
            0.001*i.connect_delta connecttime,
            0.001*i.ssl_handshake_delta ssltime,
            0.001*i.request_delta reqtime,
            0.001*i.first_packet_delta firstpackettime,
            0.001*i.remain_packets_delta remainpacketstime,
            0.001*system_delta clienttime
            from pageitem_combined i
            where i.date_cet = '$date'
            order by 1,2,3"
  $r melt {loadtime dnstime connecttime ssltime reqtime firstpackettime 
           remainpacketstime clienttime}

  $r qplot title "Network times all $domain by network part - $date" \
            x ts y value xlab "Date/time" ylab "Network time (seconds)" \
            geom point colour scriptname facet variable \
            width 11 height.min 5 height.max 20 height.base 3.4 height.percolour 0.24 height.perfacet 1.7 \
            legend.avg 3 \
            legend.position bottom \
            legend.direction vertical
}

main $argv
